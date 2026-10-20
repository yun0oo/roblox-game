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
check(Rules.CanEnter(profile, Config.Floors[1]), "Starting reef accessible")
check(not Rules.CanEnter(profile, Config.Floors[2]), "Shipwreck gated")
profile.Equipment.Suit = 10
check(Rules.CanEnter(profile, Config.Floors[2]), "Level ten unlocks shipwreck")
check(not Rules.CanEnter(profile, Config.Floors[3]), "Ruins still gated")
profile.Equipment.Suit = 20
check(Rules.CanEnter(profile, Config.Floors[3]), "Level twenty unlocks ruins")
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
    if not animal.FusionOnly then check((Config.Floors[animal.Floor].Weights[animal.Rarity] or 0) > 0, "Animal reachable without an event: " .. id) end
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
local distribution = { { Value = "A", Weight = 70 }, { Value = "B", Weight = 30 }, { Value = "ZERO", Weight = 0 } }
local counts = { A = 0, B = 0 }
for i = 1, 1000 do local value = Rules.PickWeighted(distribution, (i - 0.5) / 1000); counts[value] += 1 end
equal(counts.A, 700); equal(counts.B, 300)
equal(Rules.PickWeighted(distribution, 1), "B", "Upper bound never selects zero weights")

profile = Rules.NewProfile(Config)
profile.Eggs = { { Id = "secured", Floor = 1, Name = "Œuf", Rarity = "Common" } }
local animal = Rules.Hatch(profile, Config, "secured", 0.3)
check(animal ~= nil, "A secured egg hatches")
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
