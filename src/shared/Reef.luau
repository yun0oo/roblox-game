--!nonstrict
-- Original, self-contained reef sculptures. No remote models or scripts.
local Reef = {}
Reef.Biomes = {
    { Sand = { 233, 211, 164 }, Rock = { 48, 155, 173 }, Wall = { 65, 143, 164 }, Plant = { 111, 211, 100 }, Coral = { 255, 142, 183 } },
    { Sand = { 207, 189, 145 }, Rock = { 76, 143, 153 }, Wall = { 73, 125, 148 }, Plant = { 90, 184, 137 }, Coral = { 255, 164, 102 } },
    { Sand = { 195, 220, 197 }, Rock = { 89, 167, 168 }, Wall = { 68, 137, 158 }, Plant = { 96, 211, 173 }, Coral = { 174, 160, 250 } },
    { Sand = { 148, 177, 186 }, Rock = { 83, 124, 167 }, Wall = { 65, 100, 143 }, Plant = { 83, 214, 199 }, Coral = { 219, 131, 245 } },
    { Sand = { 150, 166, 195 }, Rock = { 97, 117, 172 }, Wall = { 73, 91, 141 }, Plant = { 117, 184, 241 }, Coral = { 151, 189, 255 } },
    { Sand = { 182, 161, 193 }, Rock = { 121, 104, 171 }, Wall = { 99, 82, 143 }, Plant = { 179, 148, 245 }, Coral = { 252, 165, 224 } },
}
function Reef.Coral(parent, origin, scale, style, visuals, color)
    local model = Instance.new("Model"); model.Name = "Corail vivant · " .. style; model.Parent = parent
    local palette = { { 255, 128, 172 }, { 197, 133, 245 }, { 255, 179, 111 }, { 98, 217, 215 } }
    local tint = color or visuals.Color(palette[(style - 1) % #palette + 1])
    local tip = tint:Lerp(Color3.new(1, 1, 1), 0.4)
    local function pos(x, y, z) return origin + Vector3.new(x, y, z) * scale end
    local function stem(a, b, width)
        visuals.Rod(model, "Branche calcaire", a, b, width * scale, tint)
        visuals.Part(model, "Pointe nacrée", Vector3.one * width * scale, CFrame.new(b), tip, nil, Enum.PartType.Ball)
    end
    if style % 3 == 1 then
        for i = 1, 4 do
            local angle = i * 2.4
            local fork = pos(math.cos(angle) * 2.2, 3.3 + i * 0.4, math.sin(angle) * 2.2)
            stem(pos(math.cos(angle) * 0.7, 0, math.sin(angle) * 0.7), fork, 0.72)
            for side = -1, 1, 2 do stem(fork, fork + Vector3.new(side * 1.4, 2.4, math.sin(i) * 1.2) * scale, 0.42) end
        end
    elseif style % 3 == 2 then
        stem(pos(0, 0, 0), pos(0, 3, 0), 0.7)
        for i = -3, 3 do
            local a, b = pos(0, 2, 0), pos(i * 1.5, 7.5 - math.abs(i) * 0.65, math.sin(i) * 0.4)
            stem(a, b, 0.3)
            stem(a:Lerp(b, 0.55), a:Lerp(b, 0.55) + Vector3.new(i * 0.3, 1.4, 0.2) * scale, 0.18)
        end
    else
        for i = 1, 3 do
            local center = pos(math.sin(i * 2) * 1.8, 0.8 + i * 1.4, math.cos(i * 2) * 1.3)
            local width = 8 - i * 0.8
            visuals.Part(model, "Plateau festonné", Vector3.new(width, 0.75, width * 0.8) * scale, CFrame.new(center), tip, nil, Enum.PartType.Ball)
            visuals.Part(model, "Disque de polypes", Vector3.new(width - 0.5, 0.36, width * 0.8 - 0.5) * scale, CFrame.new(center + Vector3.new(0, 0.3, 0) * scale), tint, nil, Enum.PartType.Ball)
            for polyp = 1, 6 do
                local a = polyp * math.pi / 3
                visuals.Part(model, "Polype", Vector3.new(0.4, 0.17, 0.4) * scale, CFrame.new(center + Vector3.new(math.cos(a) * width * 0.3, 0.49, math.sin(a) * width * 0.24) * scale), tip, nil, Enum.PartType.Ball)
            end
        end
    end
    return model
end
function Reef.Grass(parent, origin, scale, visuals, color)
    local model = Instance.new("Model"); model.Name = "Herbier rubané"; model.Parent = parent
    local green = color or Color3.fromRGB(111, 211, 100)
    for i = 1, 7 do
        local a = i * 2.4
        local height = (3.8 + i % 4 * 0.8) * scale
        local base = origin + Vector3.new(math.cos(a) * 1.2, 0, math.sin(a) * 1.2) * scale
        local bend = Vector3.new(math.sin(a) * height * 0.18, height * 0.72, math.cos(a) * height * 0.18)
        local leaf = visuals.Part(model, "Ruban d’algue", Vector3.new(0.18, height, 0.72 + i % 2 * 0.32) * Vector3.new(scale, 1, scale), CFrame.new(base + bend / 2) * CFrame.Angles(math.cos(a) * 0.26, a, math.sin(a) * 0.26), green:Lerp(Color3.fromRGB(205, 247, 139), i % 3 * 0.16), nil, Enum.PartType.Ball)
        leaf.CastShadow = false
        visuals.Part(model, "Pointe du ruban", Vector3.new(0.13 * scale, height * 0.53, 0.55 * scale), CFrame.new(base + bend + Vector3.new(math.sin(a), height * 0.08, math.cos(a)) * scale) * CFrame.Angles(math.cos(a) * 0.48, a, math.sin(a) * 0.48), green, nil, Enum.PartType.Ball)
    end
    return model
end
function Reef.Sponge(parent, origin, scale, visuals, tint)
    local model = Instance.new("Model"); model.Name = "Éponges tubulaires ouvertes"; model.Parent = parent
    tint = tint or Color3.fromRGB(51, 181, 208)
    for tube = 1, 3 do
        local center = origin + Vector3.new((tube - 2) * 3.5, 0, math.sin(tube * 2) * 2) * scale
        local height = (4 + tube * 1.7) * scale
        local radius = (1.1 + tube * 0.23) * scale
        for j = 1, 8 do
            local angle = j * math.pi / 4
            local p = center + Vector3.new(math.cos(angle) * radius, height / 2, math.sin(angle) * radius)
            -- Eight side walls and a recessed bottom leave a genuinely hollow mouth.
            visuals.Part(model, "Paroi de l’éponge", Vector3.new(radius * 0.85, height, 0.55 * scale), CFrame.new(p) * CFrame.Angles(0, -angle + math.pi / 2, 0), tint:Lerp(Color3.fromRGB(28, 107, 159), j % 3 * 0.12))
            visuals.Rod(model, "Lèvre turquoise", center + Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius), center + Vector3.new(math.cos(angle + math.pi / 4) * radius, height, math.sin(angle + math.pi / 4) * radius), 0.55 * scale, tint:Lerp(Color3.new(1, 1, 1), 0.22))
        end
        visuals.Part(model, "Fond intérieur", Vector3.new(radius * 1.8, 0.2 * scale, radius * 1.8), CFrame.new(center + Vector3.new(0, 0.2, 0)), Color3.fromRGB(30, 111, 150), nil, Enum.PartType.Ball)
    end
    return model
end

function Reef.Floor(parent, floor, config, visuals, rng)
    local biome = Reef.Biomes[floor.Id]
    local sand, rock = visuals.Color(biome.Sand), visuals.Color(biome.Rock)
    local plant, coral = visuals.Color(biome.Plant), visuals.Color(biome.Coral)
    local extent, radius, strip = 432, 92, 32
    local terminal = floor.Id == config.ActiveFloors
    local ground = Instance.new("Folder"); ground.Name = "Fond continu"; ground.Parent = parent
    parent:SetAttribute("SeafloorY", floor.Bottom); parent:SetAttribute("DescentRadius", terminal and 0 or radius)
    local function solid(folder, name, size, position, tint, material, shape)
        local p = visuals.Part(folder, name, size, CFrame.new(position), tint, material, shape)
        p.CanCollide = true; p.CanQuery = true
        return p
    end
    -- Every strip covers the full map outside a round descent opening. There
    -- are no gaps between terraces, and nothing crosses the central shaft.
    for z = -extent, extent - strip, strip do
        local width = math.min(strip, extent - z)
        local closest = z <= 0 and z + width >= 0 and 0 or math.min(math.abs(z), math.abs(z + width))
        local edge = not terminal and closest < radius and math.sqrt(radius ^ 2 - closest ^ 2) or 0
        if edge > 0 then
            for side = -1, 1, 2 do
                solid(ground, "Sable continu", Vector3.new(extent - edge, 14, width), Vector3.new(side * (extent + edge) / 2, floor.Bottom - 7, z + width / 2), sand, Enum.Material.Sand)
            end
        else
            solid(ground, "Sable continu", Vector3.new(extent * 2, 14, width), Vector3.new(0, floor.Bottom - 7, z + width / 2), sand, Enum.Material.Sand)
        end
    end
    local cliffs = Instance.new("Folder"); cliffs.Name = "Parois du biome"; cliffs.Parent = parent
    local height = floor.Top - floor.Bottom
    for side = 1, 4 do
        local xSide = side <= 2
        local sign = side % 2 == 1 and -1 or 1
        solid(cliffs, "Paroi habillée " .. side, xSide and Vector3.new(20, height, 864) or Vector3.new(864, height, 20), Vector3.new(xSide and sign * 430 or 0, (floor.Top + floor.Bottom) / 2, not xSide and sign * 430 or 0), visuals.Color(biome.Wall), Enum.Material.Sandstone)
        for band = 0, 2 do
            for column = -3, 3 do
                local lateral = column * 118 + math.sin(column * 2 + band) * 12
                local y = floor.Bottom + height * (band + 0.5) / 3
                local p = Vector3.new(xSide and sign * 422 or lateral, y, not xSide and sign * 422 or lateral)
                solid(cliffs, "Relief sculpté", xSide and Vector3.new(46, height / 3 + 28, 145) or Vector3.new(145, height / 3 + 28, 46), p, rock:Lerp(sand, band * 0.12), Enum.Material.Sandstone, Enum.PartType.Ball)
                if column % 2 == 0 then
                    local shelf = Vector3.new(xSide and sign * 391 or lateral, y - height / 6 + 4, not xSide and sign * 391 or lateral)
                    solid(cliffs, "Corniche corallienne", Vector3.new(38, 7, 38), shelf, rock, Enum.Material.Sandstone, Enum.PartType.Ball)
                    Reef.Coral(cliffs, shelf + Vector3.new(0, 3, 0), 2.2, (column + band) % 3 + 1, visuals, coral)
                end
            end
        end
    end
    local gardens = Instance.new("Folder"); gardens.Name = "Jardins de tout le palier"; gardens.Parent = parent
    local index = 0
    for x = -350, 350, 100 do
        for z = -350, 350, 100 do
            local p = Vector3.new(x + rng:NextNumber(-20, 20), floor.Bottom, z + rng:NextNumber(-20, 20))
            if Vector3.new(p.X, 0, p.Z).Magnitude < 140 then continue end
            index += 1
            local patch = Instance.new("Model"); patch.Name = "Jardin " .. index; patch.Parent = gardens
            local boulder = solid(patch, "Roche bleue", Vector3.new(rng:NextNumber(24, 45), rng:NextNumber(12, 23), rng:NextNumber(20, 38)), p + Vector3.new(0, 3, 0), rock, Enum.Material.Sandstone, Enum.PartType.Ball)
            if index % 4 == 0 then Reef.Sponge(patch, p + Vector3.new(8, 1, 0), 2.5, visuals, rock:Lerp(Color3.fromRGB(57, 219, 225), 0.4))
            else Reef.Coral(patch, boulder.Position + Vector3.new(0, 5, 0), rng:NextNumber(2.4, 3.7), index % 3 + 1, visuals, index % 2 == 0 and coral or nil) end
            Reef.Grass(patch, p + Vector3.new(-19, 0, 8), rng:NextNumber(2.8, 4.3), visuals, plant)
            Reef.Grass(patch, p + Vector3.new(15, 0, -17), rng:NextNumber(1.9, 3.3), visuals, plant)
            if index % 5 == 0 and floor.Id >= 2 then
                if floor.Id == 2 then
                    solid(patch, "Débris de l’épave", Vector3.new(25, 2.8, 6), p + Vector3.new(0, 2, 22), Color3.fromRGB(148, 115, 76), Enum.Material.WoodPlanks)
                    solid(patch, "Jarres des naufragés", Vector3.new(5, 7, 5), p + Vector3.new(12, 4, 22), Color3.fromRGB(204, 156, 109), Enum.Material.Sandstone, Enum.PartType.Ball)
                elseif floor.Id == 3 or floor.Id == 6 then
                    local columnHeight = floor.Id == 3 and 34 or 67
                    for side = -1, 1, 2 do
                        local column = p + Vector3.new(side * 18, columnHeight / 2, 20)
                        solid(patch, "Colonne du sanctuaire", Vector3.new(8, columnHeight, 8), column, sand, Enum.Material.Marble)
                        solid(patch, "Chapiteau", Vector3.new(12, 4, 12), column + Vector3.new(0, columnHeight / 2, 0), rock, Enum.Material.Marble)
                        visuals.Part(patch, "Inscription lumineuse", Vector3.new(0.8, columnHeight * 0.6, 0.3), CFrame.new(column + Vector3.new(0, 0, -4.1)), coral, Enum.Material.Neon)
                    end
                    solid(patch, "Arche engloutie", Vector3.new(46, 6, 12), p + Vector3.new(0, columnHeight + 3, 20), sand, Enum.Material.Marble)
                elseif floor.Id == 4 then
                    local top = p + Vector3.new(3, 62 + index % 3 * 8, 5)
                    visuals.Rod(patch, "Tronc de la forêt abyssale", p, top, 3.5, rock)
                    for branch = 1, 4 do
                        local a = branch * math.pi / 2
                        local tip = top + Vector3.new(math.cos(a) * 20, branch % 2 * 10, math.sin(a) * 20)
                        visuals.Rod(patch, "Branche bioluminescente", top - Vector3.new(0, 16, 0), tip, 1.5, plant)
                        local crown = visuals.Part(patch, "Canopée des abysses", Vector3.new(21, 6, 16), CFrame.new(tip), coral, Enum.Material.Neon, Enum.PartType.Ball)
                        crown.Transparency = 0.3
                    end
                else
                    for crystal = 1, 3 do
                        local position = p + Vector3.new(crystal * 6, 16 + crystal * 4, 16)
                        visuals.Part(patch, "Géode abyssale", Vector3.new(4, 26 + crystal * 5, 5), CFrame.new(position) * CFrame.Angles(0.14, crystal, 0.18), coral, Enum.Material.Glass)
                        visuals.Part(patch, "Cœur de la géode", Vector3.new(1.2, 20 + crystal * 4, 1.3), CFrame.new(position) * CFrame.Angles(0.14, crystal, 0.18), plant, Enum.Material.Neon)
                    end
                end
            end
            -- Soft sand reliefs and pebbles break up the continuous ground.
            visuals.Part(patch, "Dune de sable", Vector3.new(67, 5, 57), CFrame.new(p + Vector3.new(6, -1.8, 2)), sand:Lerp(Color3.new(1, 1, 1), 0.07), Enum.Material.Sand, Enum.PartType.Ball)
            if index % 7 == 0 then
                local emitter = Instance.new("ParticleEmitter"); emitter.Name = "Bulles du récif"; emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
                emitter.Rate = 1; emitter.Lifetime = NumberRange.new(4, 7); emitter.Speed = NumberRange.new(3, 5); emitter.Size = NumberSequence.new(0.3); emitter.Transparency = NumberSequence.new(0.65); emitter.Parent = boulder
            end
        end
        task.wait()
    end
    if not terminal then
        for i = 1, 20 do
            local a = i * math.pi / 10
            local p = Vector3.new(math.cos(a) * 119, floor.Bottom - 2, math.sin(a) * 119)
            solid(parent, "Lèvre rocheuse du passage", Vector3.new(28, 15, 28), p, rock, Enum.Material.Sandstone, Enum.PartType.Ball)
            if i % 4 == 0 then Reef.Coral(parent, p + Vector3.new(0, 6, 0), 1.5, 3, visuals, coral) end
        end
        local marker = visuals.Part(parent, "Panneau de profondeur", Vector3.one, CFrame.new(0, floor.Bottom + 20, -117), coral)
        marker.Transparency = 1
        local nextFloor = config.Floors[floor.Id + 1]
        visuals.Label(marker, "↓ " .. nextFloor.Name:upper() .. " ↓\nPASSAGE OUVERT · COMBI CONSEILLÉE " .. nextFloor.MinLevel, Color3.fromRGB(204, 253, 255), 4, 145)
    end
    -- Groups of little pink jellyfish echo the reference without obstructing travel.
    for group = 1, 8 do
        local a = group * math.pi / 4
        for j = 1, 3 do
            local p = Vector3.new(math.cos(a) * (270 + j * 15), floor.Bottom + 80 + group % 3 * 28 + j * 7, math.sin(a) * (270 + j * 15))
            local bell = visuals.Part(gardens, "Méduse du jardin", Vector3.new(4, 2.2, 4), CFrame.new(p), coral, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
            bell.Transparency = 0.15
            for k = 1, 4 do
                local b = p + Vector3.new(math.cos(k * 1.57) * 1.1, -0.7, math.sin(k * 1.57) * 1.1)
                visuals.Rod(gardens, "Filament de méduse", b, b + Vector3.new(math.sin(k), -4, math.cos(k)), 0.12, coral, Enum.Material.Neon)
            end
        end
    end
end
return Reef
