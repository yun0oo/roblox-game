--!nonstrict
local Config = require("../src/shared/Config")
local Rules = require("../src/shared/Rules")
local Recipes = require("../src/server/FusionData")
local passed = 0
local function check(condition, message) assert(condition, message); passed += 1 end
local function fresh() local p = Rules.NewProfile(Config); p.Money = 1e9; return p end
local profile = fresh()
profile.Animals.clownfish = 27
for _ = 1, 9 do check(Rules.Fuse(profile, Config, Recipes, { Kind = "Classic", Species = "clownfish", Grade = "Normal" }) ~= nil, "Normal fusion succeeds") end
for _ = 1, 3 do check(Rules.Fuse(profile, Config, Recipes, { Kind = "Classic", Species = "clownfish", Grade = "Gold" }) ~= nil, "Gold fusion succeeds") end
check(Rules.Fuse(profile, Config, Recipes, { Kind = "Classic", Species = "clownfish", Grade = "Diamond" }) ~= nil, "Diamond fusion succeeds")
check(Rules.SpeciesCount(profile, "clownfish") == 1 and profile.Variants.clownfish.Mythic == 1, "Twenty-seven originals become one Mythic")
check(Rules.Income(profile, Config) == 450, "Fusion multiplier changes actual income")
check(profile.Stats.Fusions == 13, "Fusion statistics track successful transactions only")
local funds = profile.Money
check(not Rules.Fuse(profile, Config, Recipes, { Kind = "Classic", Species = "clownfish", Grade = "Mythic" }), "Cannot exceed top grade")
check(not Rules.Fuse(profile, Config, Recipes, { Kind = "Classic", Species = "clownfish", Grade = "Normal" }), "Cannot fuse missing animals")
check(not Rules.Fuse(profile, Config, Recipes, { Kind = "Classic", Species = {}, Grade = "Normal" }), "Malformed species payload rejected")
check(profile.Money == funds and Rules.AnimalCount(profile) == 1, "Rejected fusion does not consume money or animals")
profile = fresh(); profile.Animals.shark = 1; profile.Animals.octopus = 1
local fused = Rules.Fuse(profile, Config, Recipes, { Kind = "Recipe", Ingredients = { "octopus", "shark" } })
check(fused and fused.AnimalId == "sharktopus", "Cross-species recipe ignores ingredient order")
check(profile.Animals.shark == nil and profile.Animals.octopus == nil and profile.Animals.sharktopus == 1, "Ingredients consumed exactly once")
check(profile.Discovered.sharktopus and profile.Recipes.sharktopus, "Discovery and recipe persisted")
check(not Rules.Fuse(profile, Config, Recipes, { Kind = "Recipe", Ingredients = { "octopus", "shark" } }), "Replayed recipe cannot duplicate output")
profile = fresh(); profile.Animals.clownfish = 2; profile.Animals.turtle = 1
funds = profile.Money
check(not Rules.Fuse(profile, Config, Recipes, { Kind = "Recipe", Ingredients = { "clownfish", "turtle" } }), "Unknown recipe rejected")
check(profile.Money == funds and profile.Animals.clownfish == 2 and profile.Animals.turtle == 1, "Unknown experiment has no cost")
profile.Money = 0; profile.Animals.shark = 1; profile.Animals.octopus = 1
check(not Rules.Fuse(profile, Config, Recipes, { Kind = "Recipe", Ingredients = { "shark", "octopus" } }), "Unfunded recipe rejected")
check(profile.Animals.shark == 1 and profile.Animals.octopus == 1, "Unfunded fusion keeps ingredients")
local visible = Rules.VisibleRecipes(Recipes, {})
check(#visible == 5, "Undiscovered secret recipes never enter a client snapshot")
visible[1].Ingredients[1] = "tampered"
check(Recipes[1].Ingredients[1] == "shark", "Public recipe view does not alias private recipe data")
for _, recipe in ipairs(Recipes) do
    local p = fresh()
    for _, id in ipairs(recipe.Ingredients) do p.Animals[id] = (p.Animals[id] or 0) + 1; check(Config.Animals[id] ~= nil, "Every recipe ingredient exists") end
    local result = Rules.Fuse(p, Config, Recipes, { Kind = "Recipe", Ingredients = recipe.Ingredients })
    check(result and result.AnimalId == recipe.Output and Config.Animals[result.AnimalId].FusionOnly, "Every configured recipe is executable")
    check(result.Secret == recipe.Secret, "Secret notification occurs on first discovery")
    local found = false; for _, item in ipairs(Rules.VisibleRecipes(Recipes, p.Recipes)) do if item.Id == recipe.Id then found = true end end
    check(found, "Discovered recipe becomes visible")
    for _, id in ipairs(recipe.Ingredients) do p.Animals[id] = (p.Animals[id] or 0) + 1 end
    result = Rules.Fuse(p, Config, Recipes, { Kind = "Recipe", Ingredients = recipe.Ingredients })
    check(result and not result.Secret, "Repeating a secret recipe does not rediscover it")
end
profile = fresh(); profile.Equipment.Suit = 20; profile.BaseLevel = 3
profile.Animals.shark = 2; profile.Variants.clownfish = { Gold = 1 }
profile.Discovered.shark = true; profile.Recipes.nautilux = true; profile.OwnedDecor.coral = true; profile.Palette = "coral"
profile.Eggs = { { Id = "secured", Floor = 1, Rarity = "Common", Name = "Œuf" } }
profile.MaxDepth = 1500; profile.Stats.Steals = 7; profile.XP = 400
check(Rules.Rebirth(profile, Config), "Eligible prestige succeeds")
check(profile.Prestige == 1 and profile.Money == 150 and profile.Equipment.Suit == 1 and profile.XP == 0, "Prestige resets spendable progress")
check(Rules.AnimalCount(profile) == 0 and #profile.Eggs == 0, "Prestige clears animals, variants, and incubator")
check(profile.Discovered.shark and profile.Recipes.nautilux and profile.OwnedDecor.coral and profile.Palette == "coral", "Prestige keeps discoveries and cosmetics")
check(profile.MaxDepth == 1500 and profile.Stats.Steals == 7, "Prestige keeps lifetime statistics")
profile.Animals.clownfish = 1
check(math.abs(Rules.Income(profile, Config) - 15) < 1e-6 and Rules.MaxOxygen(profile) == 105 and Rules.SwimSpeed(profile) > 20, "Permanent prestige and gallery bonuses affect real gameplay values")
check(profile.BaseLevel == 3, "Prestige retains the aquarium gallery upgrade")
check(Rules.PrestigeCost(profile) == 2000000, "Prestige target scales")
check(not Rules.Rebirth(profile, Config) and profile.Prestige == 1, "Repeated prestige requires new progression")
profile = Rules.NewProfile(Config); profile.Money = Config.Decorations.coral.Cost
check(Rules.Decorate(profile, Config, "coral") and profile.Palette == "coral" and profile.Money == 0, "Palette purchase charges configured price")
check(Rules.Decorate(profile, Config, "coral") and profile.Money == 0, "Owned decoration can be applied without paying twice")
check(not Rules.Decorate(profile, Config, "statue"), "Unaffordable decoration rejected")
check(not Rules.Decorate(profile, Config, {}), "Malformed customization rejected")
profile.Variants.shark = { Gold = 2, Diamond = 1 }; profile.Prestige = 3; profile.Recipes.nautilux = true
local restored = Rules.Sanitize(profile, Config)
check(restored.Prestige == 3 and restored.Variants.shark.Gold == 2 and restored.Variants.shark.Diamond == 1, "Variant and prestige state survive persistence sanitization")
check(restored.Recipes.nautilux and restored.Palette == "coral", "Recipes and customization survive sanitization")
check(restored.Discovered.shark, "Variant-only collections preserve species discovery")
profile.Animals.shark = 20000
restored = Rules.Sanitize(profile, Config)
check(Rules.AnimalCount(restored) <= Config.MaxAnimals, "Combined normal and variant capacity bounded")
for floor = 1, 6 do
    for i = 1, 100 do
        local rarity = Rules.PickWeighted(Rules.RarityWeights(Config, floor, "Legendary"), (i - 0.5) / 100)
        local id = Rules.RollAnimal(Config, { Floor = floor, Rarity = rarity }, 0.5)
        check(id and not Config.Animals[id].FusionOnly, "Fusion-only creatures never hatch from ordinary eggs")
    end
end
print(string.format("Progression: %d assertions passed", passed))
