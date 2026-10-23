--!nonstrict
local Config = require("../src/shared/Config")
local Rules = require("../src/shared/Rules")
local passed = 0
local function check(condition, message)
    assert(condition, message)
    passed += 1
end
local function equal(actual, expected, message) check(actual == expected, (message or "Values differ") .. ": " .. tostring(actual) .. " / " .. tostring(expected)) end

local profile = Rules.NewProfile(Config)
local other = Rules.NewProfile(Config)
equal(profile.BaseLevel, 1, "New players receive their first aquarium gallery")
check(not Rules.PurchaseBaseUpgrade(profile, Config), "Unaffordable base upgrade is atomic")
equal(profile.Money, 150); equal(profile.BaseLevel, 1)
profile.Money = 10000
check(Rules.PurchaseBaseUpgrade(profile, Config), "Base upgrades can be purchased with gold")
equal(profile.BaseLevel, 2); equal(profile.Money, 9400)
profile.Animals.clownfish = 1
check(math.abs(Rules.Income(profile, Config) - 11) < 1e-6, "Base upgrade increases actual animal production")
equal(Rules.Sanitize(profile, Config).BaseLevel, 2, "Base upgrade persists through sanitization")
profile.BaseLevel = #Config.BaseUpgrades
check(not Rules.PurchaseBaseUpgrade(profile, Config), "Maximum base upgrade does not charge again")
profile = Rules.NewProfile(Config)
check(Rules.CrossesSurfaceOutsideDive(Config, 120, 100, 100, 0), "Outside edge cannot be used for diving")
check(Rules.CrossesSurfaceOutsideDive(Config, 100, 100, 120, 0), "Outside hull cannot be used for surfacing")
check(not Rules.CrossesSurfaceOutsideDive(Config, 120, 0, 100, 0), "Every player can dive through the shared opening")
check(not Rules.CrossesSurfaceOutsideDive(Config, 100, 0, 120, 0), "Every player can return through the shared opening")
profile.Equipment.Suit = 2
equal(other.Equipment.Suit, 1, "Profiles must not share equipment tables")
profile = Rules.NewProfile(Config)
local ok = Rules.PurchaseUpgrade(profile, Config, "Suit")
check(ok, "Affordable upgrade succeeds")
equal(profile.Equipment.Suit, 2)
equal(profile.Money, 115)
local before = profile.Money
check(not Rules.PurchaseUpgrade(profile, Config, "Admin"), "Unknown upgrades rejected")
check(not Rules.PurchaseUpgrade(profile, Config, {}), "Non-string upgrade payload rejected")
equal(profile.Money, before)
profile.Money = 0
check(not Rules.PurchaseUpgrade(profile, Config, "Suit"), "Unaffordable upgrade rejected")
equal(profile.Equipment.Suit, 2)
profile.Equipment.Suit = 75
check(not Rules.PurchaseUpgrade(profile, Config, "Suit"), "Maximum level cannot be exceeded")
for _, item in ipairs({ { -219, 1 }, { -221, 2 }, { -509, 2 }, { -511, 3 }, { -810, 3 } }) do equal(Rules.FloorAt(Config, item[1]).Id, item[2]) end
profile = Rules.NewProfile(Config)
check(Rules.IsPrepared(profile, Config.Floors[1]), "Starting reef equipment is sufficient")
check(not Rules.IsPrepared(profile, Config.Floors[2]), "Shipwreck recommendation warns new divers")
profile.Equipment.Suit = 10
check(Rules.IsPrepared(profile, Config.Floors[2]), "Level ten meets shipwreck recommendation")
check(not Rules.IsPrepared(profile, Config.Floors[3]), "Ruins recommend stronger equipment")
profile.Equipment.Suit = 20
check(Rules.IsPrepared(profile, Config.Floors[3]), "Level twenty meets ruins recommendation")
local lastSpeed, lastTime = 0, 0
for index, floor in ipairs(Config.Floors) do
    check(floor.GuardianSpeed > lastSpeed, "Guardians get faster on every deeper floor")
    lastSpeed = floor.GuardianSpeed
    profile.Equipment.Suit = 1
    local angrySpeed, angryDamage = Rules.GuardianThreat(profile, floor, Config)
    profile.Equipment.Suit = floor.MinLevel
    local preparedSpeed, preparedDamage = Rules.GuardianThreat(profile, floor, Config)
    equal(preparedSpeed, 1); equal(preparedDamage, 1)
    if index > 1 then check(angrySpeed > preparedSpeed and angryDamage > preparedDamage, "Poor equipment worsens a real chase and attack") end
end
for _, rarity in ipairs(Config.RarityOrder) do
    check(Config.HatchTimes[rarity] > lastTime, "Rarer eggs take longer to incubate")
    lastTime = Config.HatchTimes[rarity]
end
profile.Equipment.Oxygen = 2
equal(Rules.MaxOxygen(profile), 118)
local pressure = Rules.PressureMultiplier(profile)
profile.Equipment.Suit += 1
check(Rules.PressureMultiplier(profile) < pressure, "Every suit upgrade reduces pressure consumption")
profile.Equipment.Shield = 10
check(math.abs(Rules.DamageMultiplier(profile) - 0.46) < 1e-6, "Protection has a bounded effect")

local floorCounts = { 0, 0, 0, 0, 0, 0 }
for id, animal in pairs(Config.Animals) do
    floorCounts[animal.Floor] += 1
    check(animal.Income > 0 and (animal.Weight > 0 or animal.FusionOnly), "Animal must be profitable and obtainable: " .. id)
    if not animal.FusionOnly and not animal.EventOnly then check((Config.Floors[animal.Floor].Weights[animal.Rarity] or 0) > 0, "Animal reachable without an event: " .. id) end
    if animal.EventOnly then
        check(Config.Rarities[animal.Rarity].EventOnly and Rules.CanSpawnRarity(Config, animal.Floor, animal.Rarity, "Legendary"), "Event creature has an obtainable server-gated egg: " .. id)
        equal(animal.Income, Config.Animals[animal.IncomeReference].Income * 10, "Each event rank earns exactly ten times its comparator")
    end
end
for i = 1, 6 do check(floorCounts[i] >= 10, "Ten species per floor") end
local function expectedRank(entries)
    local weighted, total = 0, 0
    for _, entry in ipairs(entries) do
        weighted += table.find(Config.RarityOrder, entry.Value) * entry.Weight
        total += entry.Weight
    end
    return weighted / total
end
for floorId = 1, 6 do
    local normal = Rules.RarityWeights(Config, floorId)
    local minor = Rules.RarityWeights(Config, floorId, "Minor")
    local major = Rules.RarityWeights(Config, floorId, "Major")
    local legendary = Rules.RarityWeights(Config, floorId, "Legendary")
    check(expectedRank(minor) > expectedRank(normal), "Minor event increases average rarity")
    check(expectedRank(major) > expectedRank(minor), "Major event increases average rarity further")
    check(expectedRank(legendary) > expectedRank(major), "Forty-minute storm increases rarity further")
    for i = 1, 1000 do
        local rarity = Rules.PickWeighted(major, (i - 0.5) / 1000)
        check(Rules.RollAnimal(Config, { Floor = floorId, Rarity = rarity }, 0.5) ~= nil, "Every event egg has an animal pool")
    end
end
for floorId = 1, #Config.Floors do
    for _, key in ipairs({ "none", "Minor", "Major", "Legendary", "made-up" }) do
        local eventKey = key ~= "none" and key or nil
        equal(Rules.CanSpawnRarity(Config, floorId, "Tempest", eventKey), key == "Major" or key == "Legendary", "Tempest is restricted to major and legendary events")
        equal(Rules.CanSpawnRarity(Config, floorId, "Celestial", eventKey), key == "Legendary", "Celestial is restricted to the forty-minute storm")
    end
    local baseline = Config.EventIncome.Floors[floorId]
    equal(Config.Animals["tempest_" .. floorId].Income, baseline.Normal * 10, "Tempest production is ten times the best ordinary species in its floor")
    equal(Config.Animals["celestial_" .. floorId].Income, baseline.Normal * 100, "Celestial production is ten times Tempest in the same floor")
    check(not Config.Animals[baseline.Reference].FusionOnly and (Config.Floors[floorId].Weights[Config.Animals[baseline.Reference].Rarity] or 0) > 0, "Income comparator is genuinely available from ordinary eggs")
end
local ordinaryWeight = Config.Floors[1].Weights.Tempest
Config.Floors[1].Weights.Tempest = 1000000
check(not Rules.CanSpawnRarity(Config, 1, "Tempest"), "A mistaken normal probability cannot leak an event-only rarity")
check(not Rules.CanSpawnRarity(Config, 1, "Tempest", "Minor"), "A minor event cannot bypass exclusive-rarity gates")
Config.Floors[1].Weights.Tempest = ordinaryWeight
check(Rules.RollAnimal(Config, { Floor = 1, Rarity = "made-up" }, .5) == nil, "Unknown egg rarity never falls back to an event creature")
local distribution = { { Value = "A", Weight = 70 }, { Value = "B", Weight = 30 }, { Value = "ZERO", Weight = 0 } }
local counts = { A = 0, B = 0 }
for i = 1, 1000 do local value = Rules.PickWeighted(distribution, (i - 0.5) / 1000); counts[value] += 1 end
equal(counts.A, 700); equal(counts.B, 300)
equal(Rules.PickWeighted(distribution, 1), "B", "Upper bound never selects zero weights")

profile = Rules.NewProfile(Config)
profile.Eggs = { { Id = "secured", Floor = 1, Name = "Œuf", Rarity = "Common" } }
check(not Rules.Hatch(profile, Config, "secured", 0.3, 1000), "Secured eggs must be deposited first")
check(Rules.StartIncubation(profile, Config, "secured", 1000), "Deposit starts the incubation")
equal(profile.Eggs[1].ReadyAt, 1015)
check(not Rules.StartIncubation(profile, Config, "secured", 1001), "Repeated deposits cannot change the deadline")
equal(Rules.Sanitize(profile, Config).Eggs[1].ReadyAt, 1015, "Incubation survives saving and loading")
check(not Rules.Hatch(profile, Config, "secured", 0.3, 1014), "Early hatching is rejected")
local animal = Rules.Hatch(profile, Config, "secured", 0.3, 1015)
check(animal ~= nil, "Deposited egg hatches exactly at its deadline")
equal(#profile.Eggs, 0)
equal(profile.Animals[animal], 1)
check(profile.Discovered[animal], "Discovery recorded")
check(not Rules.Hatch(profile, Config, "secured", 0.3), "Replaying hatch cannot duplicate an animal")
equal(Rules.AnimalCount(profile), 1)
equal(Rules.Income(profile, Config), Config.Animals[animal].Income)
profile.Animals.clownfish = 3
equal(Rules.Income(profile, Config), Config.Animals[animal].Income + (animal == "clownfish" and 20 or 30))
local dirty = { Money = math.huge, Equipment = { Suit = 999, Oxygen = -1 }, Animals = { clownfish = -99, shark = 2, hack = 99 },
    Discovered = { shark = true, hack = true }, Eggs = { { Id = "a", Floor = 1, Rarity = "Common", Name = "Valid" },
        { Id = "a", Floor = 1, Rarity = "Common", Name = "Duplicate" }, { Id = "b", Floor = 99, Rarity = "Secret", Name = "Invalid" } } }
local clean = Rules.Sanitize(dirty, Config)
equal(clean.Money, 150)
equal(clean.Equipment.Suit, 75); equal(clean.Equipment.Oxygen, 1)
equal(clean.Animals.clownfish, nil); equal(clean.Animals.hack, nil); equal(clean.Animals.shark, 2)
equal(#clean.Eggs, 1); equal(clean.Discovered.hack, nil)
check(not Rules.IsFinite(0 / 0), "NaN rejected")
check(not Rules.IsFinite(math.huge), "Infinity rejected")
check(Rules.CanSecure(11, 11, 11, "Carried"), "Owner can secure at own base")
check(not Rules.CanSecure(11, 11, 12, "Carried"), "Other base cannot acquire ownership")
check(not Rules.CanSecure(11, 12, 12, "Carried"), "Other player cannot secure somebody's carry")
check(not Rules.CanSecure(11, 11, 11, "Secured"), "Securing cannot be replayed")
local hit = { HasHarpoon = true, CooldownReady = true, InRange = true, Collision = true, Carrying = true, ShooterSafe = false, TargetSafe = false, Secured = false }
check(Rules.CanIntercept(hit), "Actual valid collision intercepts")
for _, key in ipairs({ "HasHarpoon", "CooldownReady", "InRange", "Collision", "Carrying" }) do
    local invalid = table.clone(hit); invalid[key] = false; check(not Rules.CanIntercept(invalid), "Required interception condition: " .. key)
end
for _, key in ipairs({ "ShooterSafe", "TargetSafe", "Secured" }) do
    local invalid = table.clone(hit); invalid[key] = true; check(not Rules.CanIntercept(invalid), "Safe interception condition: " .. key)
end
print(string.format("Rules: %d assertions passed", passed))
