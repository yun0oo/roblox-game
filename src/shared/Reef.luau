--!nonstrict
-- Pre-existing Poly Pizza and WebGL Aquarium meshes, bundled locally.
-- Source credits and licences: assets/CREDITS.md. No downloaded scripts.
local Reef = {}
Reef.Biomes = {
    { Sand = { 233, 211, 164 }, Rock = { 48, 155, 173 }, Wall = { 65, 143, 164 }, Plant = { 111, 211, 100 }, Coral = { 255, 142, 183 } },
    { Sand = { 207, 189, 145 }, Rock = { 76, 143, 153 }, Wall = { 73, 125, 148 }, Plant = { 90, 184, 137 }, Coral = { 255, 164, 102 } },
    { Sand = { 195, 220, 197 }, Rock = { 89, 167, 168 }, Wall = { 68, 137, 158 }, Plant = { 96, 211, 173 }, Coral = { 174, 160, 250 } },
    { Sand = { 148, 177, 186 }, Rock = { 83, 124, 167 }, Wall = { 65, 100, 143 }, Plant = { 83, 214, 199 }, Coral = { 219, 131, 245 } },
    { Sand = { 150, 166, 195 }, Rock = { 97, 117, 172 }, Wall = { 73, 91, 141 }, Plant = { 117, 184, 241 }, Coral = { 151, 189, 255 } },
    { Sand = { 182, 161, 193 }, Rock = { 121, 104, 171 }, Wall = { 99, 82, 143 }, Plant = { 179, 148, 245 }, Coral = { 252, 165, 224 } },
}
function Reef.Prop(parent, key, origin, scale, visuals, yaw, collidable)
    local data = require(game:GetService("ReplicatedStorage").Modules.ArtData)[key]
    assert(data and data.Kind == "environment", "Missing licensed scenery: " .. key)
    local dimensions = data.Full.Bounds
    local bounds = Vector3.new(dimensions[1], dimensions[2], dimensions[3])
    local stretch = type(scale) == "number" and Vector3.one * scale or scale
    local model = Instance.new("Model"); model.Name = "Décor importé · " .. key
    model:SetAttribute("ScenerySource", data.Source)
    local root = visuals.Part(nil, "Sculpture", bounds * stretch, CFrame.new(origin + Vector3.new(0, bounds.Y * stretch.Y / 2, 0)) * CFrame.Angles(0, yaw or 0, 0), Color3.new(1, 1, 1), nil, Enum.PartType.Ball)
    root.Transparency = 1
    root.CanCollide = collidable == true; root.CanQuery = collidable == true
    root:SetAttribute("ArtAsset", key); root:SetAttribute("ArtScale", stretch)
    root:SetAttribute("ArtEnvironment", true); root:SetAttribute("ArtDistance", 300)
    root.Parent = model; model.PrimaryPart = root; model.Parent = parent
    return model
end
function Reef.Coral(parent, origin, scale, style, visuals, _color)
    local keys = { "reef_fan", "reef_branch", "reef_anemone", "reef_lilac", "reef_fan", "reef_tubes" }
    return Reef.Prop(parent, keys[(style - 1) % #keys + 1], origin, scale, visuals, style * 1.37)
end
function Reef.Grass(parent, origin, scale, visuals, _color)
    return Reef.Prop(parent, "reef_meadow", origin, scale, visuals, origin.X * 0.13 + origin.Z * 0.17)
end
function Reef.Sponge(parent, origin, scale, visuals, _color)
    return Reef.Prop(parent, "reef_tubes", origin, scale, visuals, origin.X * 0.21)
end

function Reef.Floor(parent, floor, config, visuals, rng)
    local biome = Reef.Biomes[floor.Id]
    local sand = visuals.Color(biome.Sand)
    local coral = visuals.Color(biome.Coral)
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
                local key = column % 2 == 0 and "reef_boulder_a" or "reef_boulder_b"
                local data = require(game:GetService("ReplicatedStorage").Modules.ArtData)[key].Full.Bounds
                local size = xSide and Vector3.new(48, height / 3 + 25, 144) or Vector3.new(144, height / 3 + 25, 48)
                Reef.Prop(cliffs, key, p - Vector3.new(0, size.Y / 2, 0), Vector3.new(size.X / data[1], size.Y / data[2], size.Z / data[3]), visuals, 0, false)
                if column % 2 == 0 then
                    local shelf = Vector3.new(xSide and sign * 391 or lateral, y - height / 6 + 4, not xSide and sign * 391 or lateral)
                    Reef.Prop(cliffs, "reef_shelf", shelf - Vector3.new(0, 5, 0), 7, visuals, column * 0.4)
                    Reef.Coral(cliffs, shelf + Vector3.new(0, 3, 0), 2.2, (column + band) % 3 + 1, visuals, coral)
                end
            end
        end
    end
    local gardens = Instance.new("Folder"); gardens.Name = "Jardins de tout le palier"; gardens.Parent = parent
    local index = 0
    for x = -360, 360, 80 do
        for z = -360, 360, 80 do
            local p = Vector3.new(x + rng:NextNumber(-20, 20), floor.Bottom, z + rng:NextNumber(-20, 20))
            if Vector3.new(p.X, 0, p.Z).Magnitude < 140 then continue end
            index += 1
            local patch = Instance.new("Model"); patch.Name = "Jardin " .. index; patch.Parent = gardens
            local boulderKey = index % 2 == 0 and "reef_boulder_a" or "reef_boulder_b"
            Reef.Prop(patch, boulderKey, p - Vector3.new(0, 3, 0), rng:NextNumber(3.8, 5.2), visuals, index * 1.37, true)
            if index % 4 == 0 then Reef.Sponge(patch, p + Vector3.new(12, 0, 7), 4, visuals)
            else Reef.Coral(patch, p + Vector3.new(4, 4, 3), rng:NextNumber(3.3, 5.3), index % 6 + 1, visuals) end
            Reef.Grass(patch, p + Vector3.new(-20, 0, 11), rng:NextNumber(3, 4.8), visuals)
            Reef.Prop(patch, index % 3 == 0 and "reef_anemone" or "reef_kelp", p + Vector3.new(20, 0, -19), rng:NextNumber(2.2, 3.8), visuals, index * 2.4)
            if index % 5 == 0 and floor.Id >= 2 then
                if floor.Id == 2 then Reef.Prop(patch, "reef_chest", p + Vector3.new(0, 0, 23), 1.5, visuals, index)
                elseif floor.Id == 3 or floor.Id == 6 then
                    Reef.Prop(patch, index % 2 == 0 and "reef_arch" or "reef_columns", p + Vector3.new(4, 0, 20), floor.Id == 3 and 7 or 11, visuals, index * 0.7)
                elseif floor.Id == 4 then
                    Reef.Prop(patch, "reef_meadow", p + Vector3.new(10, 0, 18), 11, visuals, index)
                else Reef.Prop(patch, "reef_lilac", p + Vector3.new(7, 0, 10), 8, visuals, index) end
            end
            -- Soft sand reliefs and pebbles break up the continuous ground.
            visuals.Part(patch, "Dune de sable", Vector3.new(67, 5, 57), CFrame.new(p + Vector3.new(6, -1.8, 2)), sand:Lerp(Color3.new(1, 1, 1), 0.07), Enum.Material.Sand, Enum.PartType.Ball)
            if index % 7 == 0 then
                local emitter = Instance.new("ParticleEmitter"); emitter.Name = "Bulles du récif"; emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
                emitter.Rate = 1; emitter.Lifetime = NumberRange.new(4, 7); emitter.Speed = NumberRange.new(3, 5); emitter.Size = NumberSequence.new(0.3); emitter.Transparency = NumberSequence.new(0.65); emitter.Parent = patch:FindFirstChildOfClass("Model").PrimaryPart
            end
        end
        task.wait()
    end
    if not terminal then
        for i = 1, 20 do
            local a = i * math.pi / 10
            local p = Vector3.new(math.cos(a) * 119, floor.Bottom - 2, math.sin(a) * 119)
            Reef.Prop(parent, i % 2 == 0 and "reef_boulder_a" or "reef_boulder_b", p - Vector3.new(0, 7, 0), 4.1, visuals, a, false)
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
