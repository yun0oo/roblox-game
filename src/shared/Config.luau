--!nonstrict
-- All probabilities and balancing live here. Rolls and transactions run on the server.
local Config = {}

Config.Version = 1
Config.MaxPlayers = 8
Config.Bounds = 430
Config.WaterTop = 105
Config.SurfaceCeiling = 280
Config.BaseRadius = 62
Config.BaseHeight = 123
Config.ShipHalfWidth = 172
Config.ShipHalfLength = 326
Config.DiveHalfWidth = 30
Config.DiveHalfLength = 48
Config.BaseUpgrades = {
    { Name = "Explorateur", Cost = 0, Display = 4, IncomeBonus = 0 },
    { Name = "Océanographe", Cost = 600, Display = 6, IncomeBonus = 0.1 },
    { Name = "Sanctuaire", Cost = 2500, Display = 8, IncomeBonus = 0.2 },
    { Name = "Atlantide", Cost = 12500, Display = 10, IncomeBonus = 0.3 },
    { Name = "Palais des abysses", Cost = 60000, Display = 12, IncomeBonus = 0.4 },
}
Config.HatchTimes = { Common = 15, Rare = 40, Epic = 90, Legendary = 180, Mythic = 360, Secret = 720 }
Config.UndergearedSpeedBonus = 0.85
Config.UndergearedDamageBonus = 1.5
Config.MaxStoredEggs = 24
Config.MaxAnimals = 10000
Config.MaxMoney = 1e15
Config.SpawnInterval = 14
Config.EggsPerFloor = 6
Config.EggLifetime = 210
Config.DroppedEggLifetime = 75
Config.PickupDistance = 11
Config.SnapshotInterval = 0.7
Config.AutosaveInterval = 60
Config.SessionLease = 300
Config.AllowStudioOffline = true
Config.DataStoreName = "UnderwaterEgg_v1"

Config.RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
Config.Rarities = {
    Common = { Label = "COMMON", Color = { 183, 215, 218 }, Size = 4.2, Slow = 0.94, Power = 1 },
    Rare = { Label = "RARE", Color = { 62, 178, 255 }, Size = 5, Slow = 0.89, Power = 1.2 },
    Epic = { Label = "EPIC", Color = { 183, 117, 255 }, Size = 6, Slow = 0.82, Power = 1.5 },
    Legendary = { Label = "LEGENDARY", Color = { 255, 195, 74 }, Size = 7.2, Slow = 0.73, Power = 1.9 },
    Mythic = { Label = "MYTHIC", Color = { 255, 99, 141 }, Size = 8.4, Slow = 0.64, Power = 2.5 },
    Secret = { Label = "SECRET", Color = { 119, 255, 223 }, Size = 10, Slow = 0.55, Power = 3.5 },
}

Config.Floors = {
    {
        Id = 1, Name = "Récif corallien", ShortName = "RÉCIF", Top = 105, Bottom = -220,
        MinLevel = 1, Color = { 56, 201, 208 }, OxygenDrain = 1.1,
        EggNames = { "Œuf corallien", "Œuf nacré", "Œuf des anémones", "Œuf des marées" },
        Weights = { Common = 70, Rare = 26, Epic = 4 },
        Guardians = { "Petit requin", "Crabe géant", "Poisson territorial" },
        GuardianHealth = 38, GuardianDamage = 6, GuardianSpeed = 12, Detection = 43,
    },
    {
        Id = 2, Name = "Épave", ShortName = "ÉPAVE", Top = -220, Bottom = -510,
        MinLevel = 10, Color = { 69, 143, 176 }, OxygenDrain = 1.65,
        EggNames = { "Œuf du naufrage", "Œuf des pirates", "Œuf rouillé", "Œuf des chaînes" },
        Weights = { Rare = 57, Epic = 34, Legendary = 9 },
        Guardians = { "Requin mutant", "Anguille électrique géante", "Pieuvre agressive" },
        GuardianHealth = 130, GuardianDamage = 12, GuardianSpeed = 16, Detection = 58,
    },
    {
        Id = 3, Name = "Ruines englouties", ShortName = "RUINES", Top = -510, Bottom = -820,
        MinLevel = 20, Color = { 108, 115, 190 }, OxygenDrain = 2.25,
        EggNames = { "Œuf de l'oracle", "Œuf atlante", "Œuf du temple", "Œuf oublié" },
        Weights = { Epic = 62, Legendary = 36, Mythic = 2 },
        Guardians = { "Serpent marin", "Gardien des ruines", "Méduse géante" },
        GuardianHealth = 290, GuardianDamage = 20, GuardianSpeed = 20, Detection = 72,
    },
}

-- Thirty individually named species. The asset-free visual generator uses Style and Color.
Config.Animals = {
    clownfish = { Name = "Poisson-clown", Floor = 1, Rarity = "Common", Income = 10, Weight = 36, Style = "fish", Color = { 255, 153, 62 } },
    seahorse = { Name = "Hippocampe", Floor = 1, Rarity = "Common", Income = 16, Weight = 28, Style = "seahorse", Color = { 255, 208, 97 } },
    crab = { Name = "Crabe", Floor = 1, Rarity = "Common", Income = 23, Weight = 21, Style = "crab", Color = { 255, 104, 87 } },
    butterflyfish = { Name = "Poisson-papillon", Floor = 1, Rarity = "Common", Income = 30, Weight = 15, Style = "fish", Color = { 249, 220, 96 } },
    jellyfish = { Name = "Méduse", Floor = 1, Rarity = "Rare", Income = 40, Weight = 36, Style = "jelly", Color = { 236, 145, 255 } },
    lobster = { Name = "Homard", Floor = 1, Rarity = "Rare", Income = 50, Weight = 29, Style = "crab", Color = { 229, 86, 72 } },
    pufferfish = { Name = "Poisson-globe", Floor = 1, Rarity = "Rare", Income = 60, Weight = 22, Style = "round", Color = { 244, 212, 139 } },
    sunfish = { Name = "Poisson-lune", Floor = 1, Rarity = "Rare", Income = 70, Weight = 13, Style = "round", Color = { 167, 203, 217 } },
    turtle = { Name = "Tortue marine", Floor = 1, Rarity = "Epic", Income = 85, Weight = 65, Style = "turtle", Color = { 95, 204, 152 } },
    stingray = { Name = "Raie", Floor = 1, Rarity = "Epic", Income = 100, Weight = 35, Style = "ray", Color = { 109, 164, 219 } },
    shark = { Name = "Requin", Floor = 2, Rarity = "Rare", Income = 100, Weight = 40, Style = "shark", Color = { 113, 158, 182 } },
    moray = { Name = "Murène", Floor = 2, Rarity = "Rare", Income = 135, Weight = 35, Style = "eel", Color = { 150, 168, 98 } },
    barracuda = { Name = "Barracuda", Floor = 2, Rarity = "Rare", Income = 170, Weight = 25, Style = "fish", Color = { 171, 197, 207 } },
    octopus = { Name = "Pieuvre", Floor = 2, Rarity = "Epic", Income = 210, Weight = 34, Style = "octopus", Color = { 218, 121, 144 } },
    swordfish = { Name = "Espadon", Floor = 2, Rarity = "Epic", Income = 260, Weight = 28, Style = "shark", Color = { 100, 164, 221 } },
    squid = { Name = "Calmar", Floor = 2, Rarity = "Epic", Income = 310, Weight = 22, Style = "squid", Color = { 209, 156, 189 } },
    electric_eel = { Name = "Anguille électrique", Floor = 2, Rarity = "Epic", Income = 355, Weight = 16, Style = "eel", Color = { 244, 229, 95 } },
    manta = { Name = "Raie manta", Floor = 2, Rarity = "Legendary", Income = 410, Weight = 46, Style = "ray", Color = { 72, 108, 156 } },
    hammerhead = { Name = "Requin-marteau", Floor = 2, Rarity = "Legendary", Income = 460, Weight = 34, Style = "hammerhead", Color = { 122, 174, 177 } },
    giant_turtle = { Name = "Tortue géante", Floor = 2, Rarity = "Legendary", Income = 500, Weight = 20, Style = "turtle", Color = { 76, 168, 121 } },
    tiger_shark = { Name = "Requin-tigre", Floor = 3, Rarity = "Epic", Income = 500, Weight = 30, Style = "shark", Color = { 172, 152, 123 } },
    marlin = { Name = "Marlin", Floor = 3, Rarity = "Epic", Income = 750, Weight = 27, Style = "shark", Color = { 87, 150, 217 } },
    grouper = { Name = "Mérou géant", Floor = 3, Rarity = "Epic", Income = 1000, Weight = 23, Style = "round", Color = { 177, 140, 105 } },
    beluga = { Name = "Béluga", Floor = 3, Rarity = "Epic", Income = 1400, Weight = 20, Style = "whale", Color = { 226, 237, 242 } },
    great_white = { Name = "Grand requin blanc", Floor = 3, Rarity = "Legendary", Income = 1900, Weight = 31, Style = "shark", Color = { 171, 195, 211 } },
    narwhal = { Name = "Narval", Floor = 3, Rarity = "Legendary", Income = 2400, Weight = 26, Style = "narwhal", Color = { 173, 190, 227 } },
    sperm_whale = { Name = "Cachalot", Floor = 3, Rarity = "Legendary", Income = 3000, Weight = 21, Style = "whale", Color = { 107, 132, 159 } },
    orca = { Name = "Orque", Floor = 3, Rarity = "Legendary", Income = 3600, Weight = 14, Style = "orca", Color = { 48, 65, 91 } },
    giant_squid = { Name = "Calmar géant", Floor = 3, Rarity = "Legendary", Income = 4200, Weight = 8, Style = "squid", Color = { 190, 107, 144 } },
    sea_serpent = { Name = "Serpent marin", Floor = 3, Rarity = "Mythic", Income = 5000, Weight = 1, Style = "eel", Color = { 116, 240, 215 } },
}

Config.Upgrades = {
    Oxygen = { Name = "Oxygène", Max = 15, BaseCost = 75, Growth = 1.55, Description = "+18 unités de réserve / niveau" },
    Swim = { Name = "Nage", Max = 10, BaseCost = 100, Growth = 1.7, Description = "+2 studs/s / niveau" },
    Suit = { Name = "Combinaison", Max = 75, BaseCost = 35, Growth = 1.16, Description = "Pression réduite · limite la rage des gardiens en profondeur" },
    Shield = { Name = "Protection", Max = 10, BaseCost = 90, Growth = 1.7, Description = "−6 % de dégâts / niveau" },
    Lamp = { Name = "Lampe", Max = 8, BaseCost = 60, Growth = 1.65, Description = "+8 studs de visibilité / niveau" },
    Thruster = { Name = "Propulseur", Max = 8, BaseCost = 150, Growth = 1.75, Description = "Accélération plus puissante · recharge 7 s" },
    Harpoon = { Name = "Harpon", Max = 3, BaseCost = 400, Growth = 4, Description = "Portée, cadence et dégâts aux gardiens" },
}
Config.UpgradeOrder = { "Suit", "Oxygen", "Swim", "Shield", "Lamp", "Thruster", "Harpoon" }
Config.Harpoons = {
    { Range = 25, Speed = 95, Cooldown = 5, Damage = 28 },
    { Range = 35, Speed = 120, Cooldown = 4, Damage = 55 },
    { Range = 45, Speed = 145, Cooldown = 3, Damage = 100 },
}
Config.Events = {
    Minor = { Interval = 300, Duration = 90, Warning = 30, Names = { "COURANTS SOUS-MARINS", "MIGRATION LUMINEUSE" }, Strength = 1.12, Current = 3,
        Bonuses = { { Rare = 18, Epic = 6 }, { Epic = 16, Legendary = 7 }, { Legendary = 16, Mythic = 3 } } },
    Major = { Interval = 900, Duration = 150, Warning = 30, Names = { "TSUNAMI", "TOURBILLON" }, Strength = 1.4, Current = 7,
        Bonuses = { { Rare = 32, Epic = 22 }, { Epic = 30, Legendary = 25 }, { Legendary = 35, Mythic = 12 } } },
}
-- Full-game expansion; set ActiveFloors to 3 for the original MVP playtest.
Config.ActiveFloors = 6
table.insert(Config.Floors, {
    Id = 4, Name = "Forêt abyssale", ShortName = "FORÊT ABYSSALE", Top = -820, Bottom = -1160,
    MinLevel = 35, Color = { 84, 95, 169 }, OxygenDrain = 2.9,
    EggNames = { "Œuf bioluminescent", "Œuf fantôme", "Œuf des racines", "Œuf abyssal" },
    Weights = { Legendary = 76, Mythic = 23.95, Secret = 0.05 },
    Guardians = { "Requin abyssal", "Créature tentaculaire", "Léviathan juvénile" },
    GuardianHealth = 520, GuardianDamage = 24, GuardianSpeed = 23, Detection = 80, Ability = "Siphon",
})
table.insert(Config.Floors, {
    Id = 5, Name = "Grande Abyss", ShortName = "GRANDE ABYSS", Top = -1160, Bottom = -1540,
    MinLevel = 50, Color = { 73, 74, 133 }, OxygenDrain = 3.7,
    EggNames = { "Œuf du Kraken", "Œuf du titan", "Œuf ancestral", "Œuf du vide" },
    Weights = { Mythic = 96, Secret = 4 },
    Guardians = { "Léviathan", "Kraken", "Titan des abysses" },
    GuardianHealth = 900, GuardianDamage = 30, GuardianSpeed = 26, Detection = 94, Ability = "Shock",
})
table.insert(Config.Floors, {
    Id = 6, Name = "Fosse interdite", ShortName = "FOSSE INTERDITE", Top = -1540, Bottom = -1980,
    MinLevel = 75, Color = { 137, 91, 181 }, OxygenDrain = 4.6,
    EggNames = { "Œuf primordial", "Œuf de Poséidon", "Œuf de l'éclipse", "Œuf interdit" },
    Weights = { Mythic = 83, Secret = 17 },
    Guardians = { "Kraken ancestral", "Léviathan primordial", "Charybde, dévoreuse d'océans" },
    GuardianHealth = 1600, GuardianDamage = 38, GuardianSpeed = 29, Detection = 110, Ability = "Vortex",
})
local extra = {
    { "megalodon", "Mégalodon", 4, "Legendary", 5000, "shark" },
    { "abyss_shark", "Requin abyssal", 4, "Legendary", 6500, "shark" },
    { "abyss_ray", "Raie abyssale", 4, "Legendary", 8000, "ray" },
    { "ghost_orca", "Orque fantôme", 4, "Legendary", 9500, "orca" },
    { "colossal_squid", "Calmar colossal", 4, "Legendary", 11500, "squid" },
    { "abyss_serpent", "Serpent des abysses", 4, "Mythic", 14000, "eel" },
    { "leviathan_young", "Léviathan", 4, "Mythic", 17000, "whale" },
    { "anglerfish", "Poisson abyssal", 4, "Legendary", 12500, "round" },
    { "giant_eel", "Anguille géante", 4, "Mythic", 21000, "eel" },
    { "luminara", "Luminara, spectre marin", 4, "Secret", 25000, "jelly" },
    { "kraken", "Kraken", 5, "Mythic", 25000, "octopus" },
    { "leviathan", "Léviathan des profondeurs", 5, "Mythic", 40000, "whale" },
    { "colossal_whale", "Cachalot colossal", 5, "Mythic", 60000, "whale" },
    { "ancient_megalodon", "Mégalodon ancestral", 5, "Mythic", 80000, "shark" },
    { "giant_serpent", "Serpent marin géant", 5, "Mythic", 100000, "eel" },
    { "ghost_shark", "Requin fantôme", 5, "Mythic", 125000, "shark" },
    { "abyss_orca", "Orque abyssale", 5, "Mythic", 150000, "orca" },
    { "titan_squid", "Calmar titan", 5, "Secret", 185000, "squid" },
    { "void_creature", "Néantide des profondeurs", 5, "Secret", 220000, "jelly" },
    { "sea_dragon", "Dragon marin", 5, "Secret", 250000, "eel" },
    { "ancient_kraken", "Kraken ancestral", 6, "Mythic", 250000, "octopus" },
    { "primordial_leviathan", "Léviathan primordial", 6, "Mythic", 400000, "whale" },
    { "scylla", "Scylla", 6, "Mythic", 550000, "octopus" },
    { "charybdis", "Charybde", 6, "Mythic", 700000, "jelly" },
    { "triton", "Triton", 6, "Mythic", 900000, "seahorse" },
    { "primordial_dragon", "Dragon marin primordial", 6, "Secret", 1200000, "eel" },
    { "divine_megalodon", "Mégalodon divin", 6, "Secret", 1500000, "shark" },
    { "ocean_serpent", "Serpent océanique", 6, "Secret", 1900000, "eel" },
    { "poseidon_echo", "Écho de Poséidon", 6, "Secret", 2400000, "narwhal" },
    { "asterion", "Astérion, cœur de l'océan", 6, "Secret", 3000000, "jelly" },
}
for i, row in ipairs(extra) do
    Config.Animals[row[1]] = { Name = row[2], Floor = row[3], Rarity = row[4], Income = row[5],
        Weight = math.max(2, 40 - ((i - 1) % 10) * 3), Style = row[6], Color = { 110 + (i * 17) % 130, 120 + (i * 11) % 130, 190 + (i * 7) % 65 } }
end
local hybrids = {
    { "sharktopus", "Sharktopus", 2, "Mythic", 950, "octopus" },
    { "leviathan_squid", "Leviathan Squid", 3, "Mythic", 10500, "squid" },
    { "dolphark", "Dolphark", 2, "Legendary", 800, "shark" },
    { "kraken_shark", "Kraken Shark", 5, "Secret", 320000, "octopus" },
    { "orca_dragon", "Orca Dragon", 5, "Secret", 550000, "orca" },
    { "nautilux", "Nautilux, oracle des marées", 4, "Secret", 100000, "jelly" },
    { "eclipse_kraken", "Kraken de l'éclipse", 6, "Secret", 6500000, "octopus" },
    { "thalassor", "Thalassor, dieu du silence", 6, "Secret", 12000000, "whale" },
}
-- A real dolphin also makes the advertised Dolphark recipe discoverable.
Config.Animals.dolphin = { Name = "Dauphin", Floor = 2, Rarity = "Epic", Income = 280, Weight = 20, Style = "whale", Color = { 128, 201, 226 } }
for _, row in ipairs(hybrids) do Config.Animals[row[1]] = { Name = row[2], Floor = row[3], Rarity = row[4], Income = row[5], Weight = 0, Style = row[6], Color = { 161, 234, 227 }, FusionOnly = true } end
Config.Grades = { Normal = 1, Gold = 3.5, Diamond = 12, Mythic = 45 }
Config.GradeOrder = { "Normal", "Gold", "Diamond", "Mythic" }
Config.Decorations = {
    lagoon = { Name = "Lagon turquoise", Cost = 0, Color = { 96, 242, 206 }, Kind = "Palette" },
    coral = { Name = "Corail rose", Cost = 500, Color = { 255, 135, 160 }, Kind = "Palette" },
    abyss = { Name = "Nuit abyssale", Cost = 2500, Color = { 169, 136, 255 }, Kind = "Palette" },
    bubbles = { Name = "Fontaine de bulles", Cost = 700, Kind = "Effect" },
    aquarium = { Name = "Aquarium annexe décoratif", Cost = 2000, Kind = "Aquarium" },
    statue = { Name = "Statue du grand gardien", Cost = 5000, Kind = "Statue" },
}
Config.Events.Minor.Names = { "COURANTS SOUS-MARINS", "MIGRATION LUMINEUSE", "BROUILLARD MARIN" }
Config.Events.Major.Names = { "TSUNAMI", "OURAGAN SOUS-MARIN", "TOURBILLON", "INVASION DE CRÉATURES", "ŒUF LÉGENDAIRE" }
Config.Events.Legendary = { Interval = 2400, Duration = 210, Warning = 30, Names = { "ABYSSAL STORM" }, Strength = 1.8, Current = 11,
    Bonuses = { { Rare = 35, Epic = 36 }, { Epic = 35, Legendary = 50 }, { Legendary = 45, Mythic = 40 }, { Mythic = 70, Secret = 6 }, { Secret = 30 }, { Secret = 45 } } }
Config.Events.Minor.Bonuses[4] = { Mythic = 16, Secret = 0.3 }; Config.Events.Minor.Bonuses[5] = { Secret = 2 }; Config.Events.Minor.Bonuses[6] = { Secret = 6 }
Config.Events.Major.Bonuses[4] = { Mythic = 40, Secret = 2 }; Config.Events.Major.Bonuses[5] = { Secret = 12 }; Config.Events.Major.Bonuses[6] = { Secret = 22 }
-- Recommended equipment is a survival target, never an access restriction.
local guardianNames = {
    { "Serpent des marées", "Kraken corallien", "Dragon du récif" },
    { "Léviathan des épaves", "Kraken pirate", "Scylla des naufrages" },
    { "Léviathan atlante", "Scylla des ruines", "Dragon de l'oracle" },
    { "Dragon abyssal", "Kraken spectral", "Scylla des ombres" },
    { "Léviathan titan", "Kraken des profondeurs", "Charybde" },
    { "Léviathan primordial", "Kraken ancestral", "Charybde, dévoreuse d'océans" },
}
for index, floor in ipairs(Config.Floors) do
    floor.Guardians = guardianNames[index]
    floor.GuardianSkins = index >= 5 and { "leviathan", "kraken", "charybdis" } or { "leviathan", "kraken", (index == 2 or index == 4) and "scylla" or "dragon" }
    floor.GuardianSpeed = ({ 14, 22, 28, 34, 40, 46 })[index]
    floor.Detection = 65 + index * 28
    floor.ChaseRadius = 150 + index * 35
    floor.GuardianSize = 2.5 + index * 0.65
    floor.AttackRange = 6 + index * 2.5
    floor.AttackCooldown = 1.6 - index * 0.1
end
return Config
