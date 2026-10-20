--!nonstrict
-- Pure domain rules: exercised by the standalone Luau suite, also used by the server.
local Rules = {}

function Rules.IsFinite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function integer(value, default, lo, hi)
    if not Rules.IsFinite(value) then return default end
    return math.clamp(math.floor(value), lo, hi)
end

function Rules.NewProfile(config)
    local equipment = {}
    for key in pairs(config.Upgrades) do equipment[key] = 1 end
    return { Version = config.Version, Money = 150, Equipment = equipment, Animals = {}, Variants = {}, Discovered = {},
        Eggs = {}, MaxDepth = 0, XP = 0, Prestige = 0, Recipes = {}, OwnedDecor = { lagoon = true }, Palette = "lagoon",
        Stats = { Steals = 0, Hits = 0, Hatches = 0, Secured = 0, Fusions = 0 } }
end

function Rules.Sanitize(raw, config)
    local clean = Rules.NewProfile(config)
    if type(raw) ~= "table" then return clean end
    clean.Money = integer(raw.Money, 150, 0, config.MaxMoney)
    clean.MaxDepth = integer(raw.MaxDepth, 0, 0, 10000)
    clean.XP = integer(raw.XP, 0, 0, 1e9)
    clean.Prestige = integer(raw.Prestige, 0, 0, 1e6)
    for key, spec in pairs(config.Upgrades) do
        clean.Equipment[key] = integer(type(raw.Equipment) == "table" and raw.Equipment[key], 1, 1, spec.Max)
    end
    local remaining = config.MaxAnimals
    for id in pairs(config.Animals) do
        local count = integer(type(raw.Animals) == "table" and raw.Animals[id], 0, 0, remaining)
        if count > 0 then clean.Animals[id] = count; remaining -= count end
        local variants = type(raw.Variants) == "table" and raw.Variants[id]
        if type(variants) == "table" then
            for _, grade in ipairs({ "Gold", "Diamond", "Mythic" }) do
                local amount = integer(variants[grade], 0, 0, remaining)
                if amount > 0 then
                    clean.Variants[id] = clean.Variants[id] or {}; clean.Variants[id][grade] = amount
                    remaining -= amount; clean.Discovered[id] = true
                end
            end
        end
        if count > 0 or (type(raw.Discovered) == "table" and raw.Discovered[id] == true) then clean.Discovered[id] = true end
    end
    if type(raw.Recipes) == "table" then
        local total = 0
        for id, found in pairs(raw.Recipes) do
            if total < 300 and type(id) == "string" and #id <= 64 and found == true then clean.Recipes[id] = true; total += 1 end
        end
    end
    for id in pairs(config.Decorations) do
        if type(raw.OwnedDecor) == "table" and raw.OwnedDecor[id] == true then clean.OwnedDecor[id] = true end
    end
    if type(raw.Palette) == "string" and clean.OwnedDecor[raw.Palette] and config.Decorations[raw.Palette].Kind == "Palette" then clean.Palette = raw.Palette end
    local seen = {}
    if type(raw.Eggs) == "table" then
        for _, egg in ipairs(raw.Eggs) do
            if #clean.Eggs >= config.MaxStoredEggs then break end
            if type(egg) == "table" and type(egg.Id) == "string" and #egg.Id <= 64 and not seen[egg.Id]
                and config.Floors[egg.Floor] and config.Rarities[egg.Rarity] and type(egg.Name) == "string" then
                table.insert(clean.Eggs, { Id = egg.Id, Floor = egg.Floor, Rarity = egg.Rarity, Name = egg.Name:sub(1, 100) })
                seen[egg.Id] = true
            end
        end
    end
    for key in pairs(clean.Stats) do clean.Stats[key] = integer(type(raw.Stats) == "table" and raw.Stats[key], 0, 0, 1e9) end
    return clean
end

function Rules.PickWeighted(entries, unit)
    local total = 0
    for _, entry in ipairs(entries) do total += math.max(0, entry.Weight) end
    assert(total > 0, "A probability table must have a positive total")
    local cursor = math.clamp(unit, 0, 0.999999999999) * total
    for _, entry in ipairs(entries) do
        cursor -= math.max(0, entry.Weight)
        if cursor < 0 then return entry.Value end
    end
    error("Invalid weighted table")
end

function Rules.RarityWeights(config, floorId, eventKey)
    local floor = config.Floors[floorId]
    local event = eventKey and config.Events[eventKey]
    local bonuses = event and event.Bonuses[floorId] or {}
    local supported = {}
    for _, animal in pairs(config.Animals) do if animal.Floor == floorId and not animal.FusionOnly then supported[animal.Rarity] = true end end
    local result = {}
    for _, rarity in ipairs(config.RarityOrder) do
        table.insert(result, { Value = rarity, Weight = supported[rarity] and ((floor.Weights[rarity] or 0) + (bonuses[rarity] or 0)) or 0 })
    end
    return result
end

function Rules.RollAnimal(config, egg, unit)
    local candidates = {}
    local ids = {}
    for id, animal in pairs(config.Animals) do
        if animal.Floor == egg.Floor and animal.Rarity == egg.Rarity and not animal.FusionOnly then table.insert(ids, id) end
    end
    table.sort(ids)
    for _, id in ipairs(ids) do table.insert(candidates, { Value = id, Weight = config.Animals[id].Weight }) end
    if #candidates == 0 then return nil end
    return Rules.PickWeighted(candidates, unit)
end

function Rules.UpgradeCost(config, key, level)
    local spec = config.Upgrades[key]
    if not spec or level >= spec.Max then return nil end
    return math.floor(spec.BaseCost * spec.Growth ^ (level - 1))
end

function Rules.PurchaseUpgrade(profile, config, key)
    if type(key) ~= "string" or not config.Upgrades[key] then return false, "Amélioration inconnue." end
    local cost = Rules.UpgradeCost(config, key, profile.Equipment[key])
    if not cost then return false, "Niveau maximum atteint." end
    if profile.Money < cost then return false, "Pas assez d'argent." end
    profile.Money -= cost
    profile.Equipment[key] += 1
    return true, "Équipement amélioré !"
end

function Rules.AnimalCount(profile)
    local count = 0
    for _, amount in pairs(profile.Animals) do count += amount end
    for _, variants in pairs(profile.Variants or {}) do for _, amount in pairs(variants) do count += amount end end
    return count
end

function Rules.Income(profile, config)
    local total = 0
    for id, amount in pairs(profile.Animals) do
        if config.Animals[id] then total += config.Animals[id].Income * amount end
    end
    for id, variants in pairs(profile.Variants or {}) do
        if config.Animals[id] then
            for grade, amount in pairs(variants) do total += config.Animals[id].Income * amount * (config.Grades[grade] or 1) end
        end
    end
    return total * (1 + (profile.Prestige or 0) * 0.25)
end

function Rules.Hatch(profile, config, eggId, unit)
    if Rules.AnimalCount(profile) >= config.MaxAnimals then return nil, "Collection pleine." end
    for index, egg in ipairs(profile.Eggs) do
        if egg.Id == eggId then
            local animalId = Rules.RollAnimal(config, egg, unit)
            if not animalId then return nil, "Table d'éclosion indisponible." end
            table.remove(profile.Eggs, index)
            profile.Animals[animalId] = (profile.Animals[animalId] or 0) + 1
            profile.Discovered[animalId] = true
            profile.Stats.Hatches += 1
            profile.XP += 20 * egg.Floor
            return animalId
        end
    end
    return nil, "Cet œuf n'est plus disponible."
end

function Rules.MaxOxygen(profile) return 100 + (profile.Equipment.Oxygen - 1) * 18 + (profile.Prestige or 0) * 5 end
function Rules.SwimSpeed(profile) return 20 + (profile.Equipment.Swim - 1) * 2 + math.sqrt(profile.Prestige or 0) * 0.3 end
function Rules.DamageMultiplier(profile) return 1 - math.min(0.54, (profile.Equipment.Shield - 1) * 0.06) end
function Rules.PressureMultiplier(profile) return 1 / (1 + (profile.Equipment.Suit - 1) * 0.018) end

function Rules.FloorAt(config, y)
    for _, floor in ipairs(config.Floors) do if y >= floor.Bottom then return floor end end
    return config.Floors[#config.Floors]
end

function Rules.CanEnter(profile, floor) return profile.Equipment.Suit >= floor.MinLevel end

function Rules.CanIntercept(context)
    return context.HasHarpoon == true and context.CooldownReady == true and context.InRange == true
        and context.Collision == true and context.ShooterSafe ~= true and context.TargetSafe ~= true
        and context.Carrying == true and context.Secured ~= true
end

function Rules.CanSecure(carrierId, playerId, baseOwnerId, state)
    return state == "Carried" and carrierId == playerId and baseOwnerId == playerId
end

function Rules.SpeciesCount(profile, id)
    local total = profile.Animals[id] or 0
    for _, amount in pairs((profile.Variants or {})[id] or {}) do total += amount end
    return total
end

function Rules.VisibleRecipes(recipes, discovered)
    local visible = {}
    for _, recipe in ipairs(recipes) do
        if not recipe.Secret or discovered[recipe.Id] then
            table.insert(visible, { Id = recipe.Id, Ingredients = table.clone(recipe.Ingredients), Output = recipe.Output, Secret = recipe.Secret })
        end
    end
    return visible
end

function Rules.Fuse(profile, config, recipes, request)
    if type(request) ~= "table" then return nil, "Demande invalide." end
    if request.Kind == "Classic" then
        local id, grade = request.Species, request.Grade
        if type(id) ~= "string" or not config.Animals[id] then return nil, "Espèce inconnue." end
        local index = table.find(config.GradeOrder, grade)
        if not index or index >= #config.GradeOrder then return nil, "Fusion déjà maximale." end
        local count = grade == "Normal" and (profile.Animals[id] or 0) or ((profile.Variants[id] or {})[grade] or 0)
        if count < 3 then return nil, "Trois animaux de la même espèce et du même niveau sont nécessaires." end
        local cost = math.floor(config.Animals[id].Income * config.Grades[grade] * 0.5 / (1 + profile.Prestige * 0.03))
        if profile.Money < cost then return nil, "Pas assez d'argent pour la fusion." end
        profile.Money -= cost
        if grade == "Normal" then profile.Animals[id] = count - 3; if profile.Animals[id] == 0 then profile.Animals[id] = nil end
        else profile.Variants[id][grade] = count - 3 end
        local nextGrade = config.GradeOrder[index + 1]
        profile.Variants[id] = profile.Variants[id] or {}
        profile.Variants[id][nextGrade] = (profile.Variants[id][nextGrade] or 0) + 1
        profile.Recipes["classic_" .. id .. "_" .. nextGrade] = true
        profile.Stats.Fusions += 1
        return { AnimalId = id, Grade = nextGrade, Secret = false }
    elseif request.Kind == "Recipe" then
        local ingredients = request.Ingredients
        if type(ingredients) ~= "table" or #ingredients < 2 or #ingredients > 3 then return nil, "Sélectionnez deux ou trois espèces." end
        local chosen, need = {}, {}
        for _, id in ipairs(ingredients) do
            if type(id) ~= "string" or not config.Animals[id] then return nil, "Espèce inconnue." end
            table.insert(chosen, id); need[id] = (need[id] or 0) + 1
        end
        for id, amount in pairs(need) do if (profile.Animals[id] or 0) < amount then return nil, "Vous ne possédez pas tous les ingrédients en version normale." end end
        table.sort(chosen)
        for _, recipe in ipairs(recipes) do
            local expected = table.clone(recipe.Ingredients); table.sort(expected)
            if table.concat(chosen, ":") == table.concat(expected, ":") then
                local cost = math.floor(config.Animals[recipe.Output].Income * 0.4 / (1 + profile.Prestige * 0.03))
                if profile.Money < cost then return nil, "Pas assez d'argent pour cette fusion." end
                profile.Money -= cost
                for id, amount in pairs(need) do profile.Animals[id] -= amount; if profile.Animals[id] == 0 then profile.Animals[id] = nil end end
                profile.Animals[recipe.Output] = (profile.Animals[recipe.Output] or 0) + 1
                profile.Discovered[recipe.Output] = true
                local discovered = not profile.Recipes[recipe.Id]
                profile.Recipes[recipe.Id] = true; profile.Stats.Fusions += 1
                return { AnimalId = recipe.Output, Grade = "Normal", Secret = recipe.Secret and discovered }
            end
        end
        return nil, "Aucune recette ne correspond. Aucun animal n'a été consommé."
    end
    return nil, "Type de fusion inconnu."
end

function Rules.PrestigeCost(profile) return math.min(1e13, math.floor(1e6 * 2 ^ math.min(profile.Prestige, 24))) end
function Rules.Rebirth(profile, config)
    local cost = Rules.PrestigeCost(profile)
    if profile.Money < cost or profile.Equipment.Suit < 20 then return false, "Le prestige nécessite la combinaison 20 et " .. cost .. " $." end
    profile.Prestige += 1; profile.Money = 150; profile.XP = 0
    profile.Animals = {}; profile.Variants = {}; profile.Eggs = {}
    for key in pairs(config.Upgrades) do profile.Equipment[key] = 1 end
    return true, "PRESTIGE " .. profile.Prestige .. " ! Vos bonus permanents sont actifs."
end
function Rules.Decorate(profile, config, id)
    local item = type(id) == "string" and config.Decorations[id]
    if not item then return false, "Décoration inconnue." end
    if not profile.OwnedDecor[id] then
        if profile.Money < item.Cost then return false, "Pas assez d'argent." end
        profile.Money -= item.Cost; profile.OwnedDecor[id] = true
    end
    if item.Kind == "Palette" then profile.Palette = id end
    return true, "Habitat personnalisé !"
end

return Rules
