--!nonstrict
-- Original Roblox-style gem armour inspired by the supplied merchant reference.
local Skins = {}
local roles = {
    Suit = { Skin = { 239, 186, 137 }, Hair = { 77, 43, 32 }, Armor = { 34, 116, 206 }, Role = "Capitaine des récifs" },
    Oxygen = { Skin = { 151, 95, 68 }, Hair = { 36, 29, 53 }, Armor = { 37, 175, 199 }, Role = "Alchimiste des bulles" },
    Swim = { Skin = { 219, 156, 105 }, Hair = { 85, 42, 88 }, Armor = { 64, 163, 103 }, Role = "Éclaireur des courants" },
    Shield = { Skin = { 193, 133, 94 }, Hair = { 198, 212, 229 }, Armor = { 70, 98, 193 }, Role = "Sentinelle d’Atlantis" },
    Lamp = { Skin = { 251, 216, 173 }, Hair = { 180, 100, 42 }, Armor = { 83, 135, 196 }, Role = "Mage des lanternes" },
    Thruster = { Skin = { 114, 76, 62 }, Hair = { 44, 37, 51 }, Armor = { 180, 65, 139 }, Role = "Artificière des marées" },
    Harpoon = { Skin = { 224, 176, 132 }, Hair = { 44, 55, 72 }, Armor = { 33, 139, 157 }, Role = "Maître des tridents" },
}
function Skins.Build(parent, key, spec, frame, visuals)
    local r = roles[key]
    local npc = Instance.new("Model"); npc.Name = spec.Name; npc:SetAttribute("MerchantRole", r.Role)
    local skin, hair, armor = visuals.Color(r.Skin), visuals.Color(r.Hair), visuals.Color(r.Armor)
    local gold, navy, cyan = Color3.fromRGB(240, 187, 76), Color3.fromRGB(24, 46, 85), Color3.fromRGB(84, 237, 255)
    local function part(name, size, position, tint, rotation, material, shape)
        local p = visuals.Part(npc, name, size, frame * CFrame.new(position) * (rotation or CFrame.new()), tint, material, shape)
        p.CastShadow = true
        return p
    end
    local function gem(name, p, size)
        local rotation = CFrame.Angles(0, 0, math.pi / 4)
        part(name .. " serti d’or", Vector3.new(size, size, 0.16), p, gold, rotation, Enum.Material.Metal)
        part(name, Vector3.new(size * 0.69, size * 0.69, 0.18), p + Vector3.new(0, 0, -0.13), cyan, rotation, Enum.Material.Glass)
        part("Reflet du cristal", Vector3.new(size * 0.25, size * 0.49, 0.025), p + Vector3.new(-size * 0.12, size * 0.06, -0.24), Color3.fromRGB(193, 255, 255), rotation)
    end
    local torso = part("Torso", Vector3.new(2.5, 2.6, 1.35), Vector3.new(0, 3.95, 0), navy)
    part("Head", Vector3.new(1.75, 1.8, 1.5), Vector3.new(0, 6.17, 0), skin)
    -- Face details remain visible: no mask hiding every merchant's identity.
    for side = -1, 1, 2 do
        part("Oreille", Vector3.new(0.22, 0.46, 0.4), Vector3.new(side * 0.91, 6.15, 0), skin, nil, nil, Enum.PartType.Ball)
        part("Œil", Vector3.new(0.15, 0.28, 0.07), Vector3.new(side * 0.35, 6.29, -0.79), navy, nil, nil, Enum.PartType.Ball)
        part("Sourcil", Vector3.new(0.4, 0.08, 0.07), Vector3.new(side * 0.35, 6.65, -0.8), hair, CFrame.Angles(0, 0, -side * 0.13))
    end
    part("Sourire", Vector3.new(0.48, 0.06, 0.06), Vector3.new(0.12, 5.77, -0.79), navy, CFrame.Angles(0, 0, 0.12))
    part("Chevelure", Vector3.new(1.85, 0.4, 1.6), Vector3.new(0, 7.05, 0.03), hair)
    for i = 1, 5 do
        local spike = Instance.new("WedgePart"); spike.Name = "Mèche sculptée"; spike.Size = Vector3.new(0.57, 0.6 + i % 2 * 0.2, 0.85)
        spike.CFrame = frame * CFrame.new((i - 3) * 0.37, 7.38 + math.sin(i) * 0.08, -0.16) * CFrame.Angles(0, i * 0.15, -0.25)
        spike.Color = hair; spike.Material = Enum.Material.SmoothPlastic; spike.Anchored = true; spike.CanCollide = false; spike.CanQuery = false; spike.CanTouch = false; spike.Parent = npc
    end
    part("Plastron doré", Vector3.new(2.36, 1.65, 0.21), Vector3.new(0, 4.29, -0.79), gold, nil, Enum.Material.Metal)
    part("Plastron émaillé", Vector3.new(2.1, 1.38, 0.19), Vector3.new(0, 4.31, -0.94), armor)
    gem("Cœur océanique", Vector3.new(0, 4.37, -1.09), 0.6)
    for side = -1, 1, 2 do
        part(side < 0 and "Left Arm" or "Right Arm", Vector3.new(1.05, 2.35, 1.1), Vector3.new(side * 1.78, 3.98, 0), navy)
        part("Épaulière royale", Vector3.new(1.46, 1.19, 1.6), Vector3.new(side * 1.74, 4.86, -0.03), gold, CFrame.Angles(0, 0, side * 0.17), Enum.Material.Metal)
        part("Émail de l’épaulière", Vector3.new(1.17, 0.9, 1.66), Vector3.new(side * 1.74, 4.95, -0.05), armor, CFrame.Angles(0, 0, side * 0.17))
        part("Gantelet doré", Vector3.new(1.17, 0.85, 1.25), Vector3.new(side * 1.78, 3.35, 0), gold, nil, Enum.Material.Metal)
        part("Gantelet émaillé", Vector3.new(1.2, 0.56, 1.29), Vector3.new(side * 1.78, 3.4, -0.03), armor)
        part("Main", Vector3.new(0.85, 0.65, 0.92), Vector3.new(side * 1.78, 2.81, -0.07), skin)
        part(side < 0 and "Left Leg" or "Right Leg", Vector3.new(1.05, 2.7, 1.15), Vector3.new(side * 0.64, 1.72, 0), navy)
        part("Cuissarde", Vector3.new(1.13, 1.05, 1.23), Vector3.new(side * 0.64, 2.35, 0), gold, nil, Enum.Material.Metal)
        part("Cuissarde émaillée", Vector3.new(0.94, 0.83, 1.28), Vector3.new(side * 0.64, 2.38, -0.06), armor)
        part("Grève dorée", Vector3.new(1.17, 1.48, 1.25), Vector3.new(side * 0.64, 1.06, -0.08), gold, nil, Enum.Material.Metal)
        part("Grève bleutée", Vector3.new(0.94, 1.24, 1.31), Vector3.new(side * 0.64, 1.08, -0.13), armor)
        gem("Cristal de genou", Vector3.new(side * 0.64, 1.65, -0.83), 0.37)
        part("Botte", Vector3.new(1.22, 0.38, 1.65), Vector3.new(side * 0.64, 0.37, -0.23), navy)
    end
    part("Ceinture", Vector3.new(2.65, 0.27, 1.48), Vector3.new(0, 2.95, 0), gold, nil, Enum.Material.Metal)
    gem("Boucle de ceinture", Vector3.new(0, 2.95, -0.86), 0.4)
    if key == "Suit" then
        part("Manteau de capitaine", Vector3.new(2.8, 3.1, 0.18), Vector3.new(0, 3.37, 0.86), navy)
        part("Bicorne de capitaine", Vector3.new(2.6, 0.43, 1.8), Vector3.new(0, 7.45, 0), navy)
        part("Couronne du bicorne", Vector3.new(1.5, 0.7, 1.4), Vector3.new(0, 7.8, 0.1), armor)
        gem("Insigne du capitaine", Vector3.new(0, 7.75, -0.69), 0.32)
    elseif key == "Oxygen" then
        for side = -1, 1, 2 do
            part("Bouteille nacrée", Vector3.new(2.9, 0.85, 0.85), Vector3.new(side * 0.65, 4.2, 1.12), cyan, CFrame.Angles(0, 0, math.pi / 2), Enum.Material.Metal, Enum.PartType.Cylinder)
            part("Vanne dorée", Vector3.new(0.55, 0.25, 0.55), Vector3.new(side * 0.65, 5.72, 1.12), gold)
        end
        part("Lunettes relevées", Vector3.new(1.8, 0.38, 0.25), Vector3.new(0, 7.13, -0.78), gold)
        part("Verre des lunettes", Vector3.new(1.52, 0.22, 0.15), Vector3.new(0, 7.13, -0.96), cyan, nil, Enum.Material.Glass)
    elseif key == "Swim" then
        for side = -1, 1, 2 do part("Palme de champion", Vector3.new(1.3, 0.15, 2.7), Vector3.new(side * 0.64, 0.16, -0.8), armor) end
        part("Bandeau des courants", Vector3.new(1.88, 0.19, 1.59), Vector3.new(0, 6.84, 0), gold)
        part("Écharpe", Vector3.new(0.7, 2.2, 0.18), Vector3.new(1.15, 4.1, 0.9), Color3.fromRGB(167, 241, 98), CFrame.Angles(0, 0, -0.3))
    elseif key == "Shield" then
        part("Bouclier d’Atlantis", Vector3.new(1.8, 2.4, 0.36), Vector3.new(2.36, 3.48, -0.9), gold, nil, Enum.Material.Metal)
        part("Face du bouclier", Vector3.new(1.52, 2.1, 0.38), Vector3.new(2.36, 3.48, -1.12), armor)
        gem("Cristal du bouclier", Vector3.new(2.36, 3.48, -1.36), 0.7)
        part("Crête du casque", Vector3.new(0.25, 0.85, 1.6), Vector3.new(0, 7.5, 0.15), gold)
    elseif key == "Lamp" then
        part("Bâton de lumière", Vector3.new(0.17, 6.1, 0.17), Vector3.new(-2.18, 3.1, -0.3), gold, nil, Enum.Material.Metal)
        local orb = part("Orbe des marées", Vector3.one * 0.95, Vector3.new(-2.18, 6.4, -0.3), cyan, nil, Enum.Material.Neon, Enum.PartType.Ball)
        local light = Instance.new("PointLight"); light.Color = cyan; light.Range = 10; light.Brightness = 0.8; light.Parent = orb
        for i = 1, 6 do
            local angle = i * math.pi / 3
            part("Rune de la lanterne", Vector3.new(0.13, 0.38, 0.13), Vector3.new(-2.18 + math.cos(angle) * 0.83, 6.4 + math.sin(angle) * 0.83, -0.3), gold, CFrame.Angles(0, 0, angle))
        end
    elseif key == "Thruster" then
        for side = -1, 1, 2 do
            part("Grand réacteur", Vector3.new(2.3, 1.1, 1.1), Vector3.new(side * 1.05, 4.1, 1.1), gold, CFrame.Angles(0, 0, math.pi / 2), Enum.Material.Metal, Enum.PartType.Cylinder)
            part("Turbine rose", Vector3.new(0.8, 0.2, 0.8), Vector3.new(side * 1.05, 2.86, 1.1), Color3.fromRGB(255, 113, 204), nil, Enum.Material.Neon)
        end
        part("Visière de mécanicienne", Vector3.new(1.95, 0.42, 0.45), Vector3.new(0, 7.03, -0.75), gold)
        part("Outil à la ceinture", Vector3.new(0.24, 0.9, 0.2), Vector3.new(1.25, 2.6, -0.78), Color3.fromRGB(189, 223, 234), CFrame.Angles(0, 0, -0.3), Enum.Material.Metal)
    else
        part("Hampe du trident", Vector3.new(0.17, 6.8, 0.17), Vector3.new(-2.23, 3.3, -0.45), gold, nil, Enum.Material.Metal)
        part("Traverse du trident", Vector3.new(1.3, 0.2, 0.22), Vector3.new(-2.23, 6.55, -0.45), gold)
        for i = -1, 1 do part("Pointe du trident", Vector3.new(0.18, 0.85 + (i == 0 and 0.5 or 0), 0.2), Vector3.new(-2.23 + i * 0.57, 7.02, -0.45), cyan, nil, Enum.Material.Neon) end
        part("Barbe du maître", Vector3.new(1.2, 0.42, 0.22), Vector3.new(0, 5.54, -0.76), hair)
    end
    local humanoid = Instance.new("Humanoid"); humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; humanoid.Parent = npc
    npc.PrimaryPart = torso; npc.Parent = parent
    return npc
end
return Skins
