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

-- Landmarks occupy their own clearing; nest routes never cross their footprint.
Reef.Landmarks = {
    { Position = { 238, -120 }, Radius = 76 },
    { Position = { -245, 62 }, Radius = 122 },
    { Position = { 235, -65 }, Radius = 98 },
    { Position = { -230, -65 }, Radius = 86 },
    { Position = { 230, 78 }, Radius = 94 },
    { Position = { 230, -65 }, Radius = 106 },
}
local function flatDistance(a, b)
    return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end
local function landmarkPosition(floor)
    local site = Reef.Landmarks[floor.Id]
    return Vector3.new(site.Position[1], floor.Bottom, site.Position[2]), site.Radius
end
function Reef.Nests(floor, rng)
    local points = {}
    local landmark, radius = landmarkPosition(floor)
    -- Staggered routes give forty separate clearings rather than sixteen plates
    -- floating high above the seabed. The server still chooses nests randomly.
    for ring = 1, 2 do
        for index = 1, 26 do
            local angle = index * math.pi * 2 / 26 + (ring == 2 and 0.11 or 0) + floor.Id * 0.31
            angle += rng:NextNumber(-0.025, 0.025)
            local distance = (ring == 1 and 175 or 325) + rng:NextNumber(-7, 7)
            local point = Vector3.new(math.cos(angle) * distance, floor.Bottom + 13, math.sin(angle) * distance)
            if flatDistance(point, landmark) < radius + 28 then continue end
            table.insert(points, { Id = floor.Id .. ":" .. (#points + 1), Position = point, GroundY = floor.Bottom })
            if #points == 40 then return points end
        end
    end
    assert(#points >= 32, "Not enough clear nest sites for this biome")
    return points
end
local function clearOfNests(points, position, radius)
    for _, point in ipairs(points) do
        if flatDistance(point.Position, position) < 25 + radius then return false end
    end
    return true
end
local function lamp(part, color, range, brightness)
    local light = Instance.new("PointLight"); light.Color = color; light.Range = range
    light.Brightness = brightness; light.Shadows = false; light.Parent = part
end
local function crystal(parent, origin, scale, visuals, color)
    local key = math.floor(origin.X + origin.Z) % 2 == 0 and "modern_crystals_a" or "modern_crystals_b"
    return Reef.Prop(parent, key, origin, scale, visuals, origin.X * 0.17 + origin.Z * 0.21)
end

function Reef.Floor(parent, floor, config, visuals, rng, nestPoints)
    local biome = Reef.Biomes[floor.Id]
    local sand, coral = visuals.Color(biome.Sand), visuals.Color(biome.Coral)
    local extent, radius, strip = 432, 92, 12
    local terminal = floor.Id == config.ActiveFloors
    local ground = Instance.new("Folder"); ground.Name = "Fond continu"; ground.Parent = parent
    local points = nestPoints or Reef.Nests(floor, rng)
    local landmark, landmarkRadius = landmarkPosition(floor)
    parent:SetAttribute("SeafloorY", floor.Bottom); parent:SetAttribute("DescentRadius", terminal and 0 or radius)
    parent:SetAttribute("Biome", floor.Name); parent:SetAttribute("ClearNestCount", #points)
    local function solid(folder, name, size, position, tint, material, shape)
        local part = visuals.Part(folder, name, size, CFrame.new(position), tint, material, shape)
        part.CanCollide = true; part.CanQuery = true
        return part
    end
    -- Exact continuous substrate remains under every exploration area, with a
    -- round opening connecting each depth. Nothing crosses the central shaft.
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
    -- Escarpments have depth, staggered ledges and planted shelves rather than
    -- exposing a uniform black wall behind a few giant decorations.
    local cliffs = Instance.new("Folder"); cliffs.Name = "Parois du biome"; cliffs.Parent = parent
    local height = floor.Top - floor.Bottom
    for side = 1, 4 do
        local xSide, sign = side <= 2, side % 2 == 1 and -1 or 1
        solid(cliffs, "Paroi habillée " .. side, xSide and Vector3.new(20, height, 864) or Vector3.new(864, height, 20), Vector3.new(xSide and sign * 430 or 0, (floor.Top + floor.Bottom) / 2, not xSide and sign * 430 or 0), visuals.Color(biome.Wall), Enum.Material.Sandstone)
        for band = 0, 2 do
            for column = -3, 3 do
                local lateral = column * 118 + math.sin(column * 2 + band + floor.Id) * 12
                local y = floor.Bottom + height * (band + 0.5) / 3
                local p = Vector3.new(xSide and sign * 422 or lateral, y, not xSide and sign * 422 or lateral)
                local key = column % 2 == 0 and "modern_rock" or "reef_boulder_b"
                local data = require(game:GetService("ReplicatedStorage").Modules.ArtData)[key].Full.Bounds
                local size = xSide and Vector3.new(48, height / 3 + 25, 144) or Vector3.new(144, height / 3 + 25, 48)
                Reef.Prop(cliffs, key, p - Vector3.new(0, size.Y / 2, 0), Vector3.new(size.X / data[1], size.Y / data[2], size.Z / data[3]), visuals, 0, false)
                if column % 2 == 0 then
                    local shelf = Vector3.new(xSide and sign * 391 or lateral, y - height / 6 + 4, not xSide and sign * 391 or lateral)
                    Reef.Prop(cliffs, "modern_rock", shelf - Vector3.new(0, 4, 0), Vector3.new(6.5, 2.5, 6), visuals, column * 0.4)
                    if floor.Id < 4 then Reef.Coral(cliffs, shelf + Vector3.new(0, 2, 0), 2.4, (column + band) % 3 + 1, visuals)
                    else crystal(cliffs, shelf + Vector3.new(0, 1, 0), 2.6, visuals, coral) end
                end
            end
        end
    end
    local gardens = Instance.new("Folder"); gardens.Name = "Jardins de tout le palier"; gardens.Parent = parent
    local index = 0
    local function garden(p, large)
        index += 1
        local patch = Instance.new("Model"); patch.Name = "Jardin " .. index; patch.Parent = gardens
        local size = large and rng:NextNumber(4.1, 5.5) or rng:NextNumber(2.2, 3.1)
        Reef.Prop(patch, index % 3 == 0 and "modern_pinnacle" or "modern_rock", p - Vector3.new(0, 2.5, 0), size, visuals, index * 1.37, false)
        if floor.Id <= 2 then
            if index % 4 == 0 then Reef.Sponge(patch, p + Vector3.new(5, 1, 2), size * 0.8, visuals)
            else Reef.Coral(patch, p + Vector3.new(4, 2, 2), size * 0.9, index % 6 + 1, visuals) end
            Reef.Grass(patch, p + Vector3.new(-10, 0, 7), size * 0.9, visuals)
        elseif floor.Id == 3 then
            Reef.Prop(patch, index % 2 == 0 and "reef_lilac" or "reef_anemone", p + Vector3.new(3, 1, 3), size, visuals, index)
            Reef.Grass(patch, p + Vector3.new(-9, 0, 8), size * 0.75, visuals)
        elseif floor.Id == 4 then
            Reef.Prop(patch, "reef_kelp", p + Vector3.new(7, 0, 4), size * 2.6, visuals, index * 1.4)
            if index % 2 == 0 then crystal(patch, p + Vector3.new(-8, 0, 2), size, visuals, coral)
            else Reef.Grass(patch, p + Vector3.new(-8, 0, 7), size * 1.3, visuals) end
        else
            crystal(patch, p + Vector3.new(3, 0, 3), size * 1.2, visuals, coral)
            if index % 3 == 0 then Reef.Prop(patch, "reef_kelp", p + Vector3.new(-8, 0, 7), size, visuals, index) end
        end
        if large then
            visuals.Part(patch, "Dune de sable", Vector3.new(53, 3.2, 41), CFrame.new(p - Vector3.new(0, 1.3, 0)), sand:Lerp(Color3.new(1, 1, 1), 0.045), Enum.Material.Sand, Enum.PartType.Ball)
        end
        if index % 11 == 0 then
            local emitter = Instance.new("ParticleEmitter"); emitter.Name = "Bulles du récif"; emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            emitter.Rate = 0.6; emitter.Lifetime = NumberRange.new(3, 6); emitter.Speed = NumberRange.new(2, 4); emitter.Size = NumberSequence.new(0.22); emitter.Transparency = NumberSequence.new(0.7); emitter.Parent = patch:FindFirstChildOfClass("Model").PrimaryPart
        end
    end
    -- Fringes frame every supported nest without burying the collectible in a
    -- model. Their centers stay at least forty studs from adjacent egg sites.
    for _, point in ipairs(points) do
        local radial = Vector3.new(point.Position.X, 0, point.Position.Z).Unit
        local p = Vector3.new(point.Position.X, floor.Bottom, point.Position.Z) + radial * (radial.X > 0 and 38 or -38)
        if clearOfNests(points, p, 10) and flatDistance(p, landmark) > landmarkRadius + 12 then garden(p, false) end
    end
    -- Natural banks occupy the spaces between the nest clearings. Positions
    -- near the landmark and central descent remain clear for pursuits.
    for x = -365, 365, 73 do
        for z = -365, 365, 73 do
            local p = Vector3.new(x + rng:NextNumber(-13, 13), floor.Bottom, z + rng:NextNumber(-13, 13))
            local distance = Vector3.new(p.X, 0, p.Z).Magnitude
            if distance < 147 or not clearOfNests(points, p, 31) or flatDistance(p, landmark) < landmarkRadius + 32 then continue end
            garden(p, true)
        end
        task.wait()
    end
    parent:SetAttribute("GardenCount", index)
    -- A scalloped natural rim marks the change of depth. The free radius of the
    -- opening remains ninety-two studs all the way down.
    if not terminal then
        for i = 1, 20 do
            local angle = i * math.pi / 10
            local p = Vector3.new(math.cos(angle) * 119, floor.Bottom - 9, math.sin(angle) * 119)
            Reef.Prop(parent, i % 2 == 0 and "modern_rock" or "reef_boulder_a", p + Vector3.new(0, 4, 0), Vector3.new(4.6, 2.2, 4.6), visuals, angle, false)
            if i % 5 == 0 then
                if floor.Id <= 3 then Reef.Coral(parent, p + Vector3.new(0, 9, 0), 1.4, 3, visuals)
                else crystal(parent, p + Vector3.new(0, 9, 0), 1.5, visuals, coral) end
            end
        end
        local marker = visuals.Part(parent, "Panneau de profondeur", Vector3.one, CFrame.new(0, floor.Bottom + 20, -117), coral)
        marker.Transparency = 1
        local nextFloor = config.Floors[floor.Id + 1]
        visuals.Label(marker, "↓ " .. nextFloor.Name:upper() .. " ↓\nCOMBI CONSEILLÉE " .. nextFloor.MinLevel, Color3.fromRGB(204, 253, 255), 4, 125)
    end
    -- Small shoals sit above the planting, preserving the visual cue from the
    -- supplied reef reference without flooding the view with particles.
    for group = 1, 6 do
        local angle = group * math.pi / 3
        for j = 1, 3 do
            local p = Vector3.new(math.cos(angle) * (255 + j * 13), floor.Bottom + 47 + group % 3 * 21 + j * 6, math.sin(angle) * (255 + j * 13))
            local bell = visuals.Part(gardens, "Méduse du jardin", Vector3.new(3, 1.7, 3), CFrame.new(p), coral, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
            bell.Transparency = 0.2
            for k = 1, 3 do
                local b = p + Vector3.new(math.cos(k * 2.094) * 0.8, -0.5, math.sin(k * 2.094) * 0.8)
                visuals.Rod(gardens, "Filament de méduse", b, b + Vector3.new(math.sin(k), -3.2, math.cos(k)), 0.09, coral, Enum.Material.Neon)
            end
        end
    end
end

function Reef.Station(parent, floor, visuals)
    local center = Vector3.new(110, floor.Bottom + 7, -50)
    local model = Instance.new("Model"); model.Name = "Station oxygène " .. floor.Id; model.Parent = parent
    local ivory, navy = Color3.fromRGB(226, 241, 246), Color3.fromRGB(24, 64, 98)
    local metal, cyan = Color3.fromRGB(155, 185, 194), Color3.fromRGB(90, 240, 224)
    local function piece(name, size, offset, color, material, shape, rotation)
        local part = visuals.Part(model, name, size, CFrame.new(center + offset) * (rotation or CFrame.new()), color, material, shape)
        return part
    end
    piece("Socle du relais", Vector3.new(18, 1.2, 14), Vector3.new(0, -6.2, 0), navy, Enum.Material.Metal).CanCollide = true
    piece("Armoire de régulation", Vector3.new(9, 11, 5), Vector3.new(0, 0, 1), ivory, Enum.Material.Metal)
    piece("Écran du relais", Vector3.new(6.5, 3.2, 0.2), Vector3.new(0, 2.4, -1.6), navy, Enum.Material.Glass)
    local led = piece("Lecture O₂", Vector3.new(5.6, 0.22, 0.25), Vector3.new(0, 1.5, -1.8), cyan, Enum.Material.Neon)
    lamp(led, cyan, 27, 1.1)
    for side = -1, 1, 2 do
        piece("Bouteille du relais", Vector3.new(9.5, 3.2, 3.2), Vector3.new(side * 6.7, -0.7, 1), ivory, Enum.Material.Metal, Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.pi / 2))
        for height = -3, 2, 5 do piece("Collier inox", Vector3.new(0.6, 3.6, 3.6), Vector3.new(side * 6.7, height, 1), metal, Enum.Material.Metal, Enum.PartType.Cylinder, CFrame.Angles(0, 0, math.pi / 2)) end
        visuals.Rod(model, "Conduite respiratoire", center + Vector3.new(side * 6.7, 4, 1), center + Vector3.new(side * 4, 4, 1), 0.7, metal, Enum.Material.Metal)
        piece("Vanne de secours", Vector3.new(0.4, 2, 2), Vector3.new(side * 3.8, 4, 1), cyan, Enum.Material.Metal, Enum.PartType.Cylinder)
    end
    local sign = piece("Panneau O₂", Vector3.new(10, 2.6, 0.3), Vector3.new(0, 7.6, 0.5), navy, Enum.Material.Metal)
    visuals.Label(sign, "O₂ · RECHARGE", cyan, 2, 100).TextSize = 15
    model.PrimaryPart = sign
    return center
end

-- The modular opening is framed with sculpted boulders and a broad rock shelf,
-- keeping its accessible tunnel while avoiding a giant exposed rectangular gate.
local function cavern(parent, origin, visuals, size)
    Reef.Prop(parent, "modern_cave", origin, Vector3.new(18, 12, 24) * size, visuals)
    for side = -1, 1, 2 do
        Reef.Prop(parent, side > 0 and "reef_boulder_a" or "reef_boulder_b", origin + Vector3.new(side * 47, -2, 1) * size, Vector3.new(7, 7, 7) * size, visuals, side * 0.4)
        Reef.Prop(parent, side > 0 and "reef_boulder_b" or "reef_boulder_a", origin + Vector3.new(side * 46, 34, 0) * size, Vector3.new(5.5, 5.5, 5.5) * size, visuals, side * -0.5)
    end
    Reef.Prop(parent, "reef_shelf", origin + Vector3.new(0, 61, -2) * size, Vector3.new(20, 5, 16) * size, visuals)
end

function Reef.Landmark(parent, floor, visuals)
    local origin = landmarkPosition(floor)
    local model = Instance.new("Model"); model.Name = "Panorama · " .. floor.Name; model.Parent = parent
    model:SetAttribute("Landmark", true)
    if floor.Id == 1 then
        cavern(model, origin, visuals, 1)
        for side = -1, 1, 2 do
            Reef.Prop(model, "modern_cliff", origin + Vector3.new(side * 42, -1, 35), Vector3.new(10, 2, 8), visuals, side * 0.2)
            Reef.Coral(model, origin + Vector3.new(side * 39, 12, 35), 7, 1, visuals)
            Reef.Grass(model, origin + Vector3.new(side * 52, 0, -20), 8, visuals)
            Reef.Prop(model, "reef_shelf", origin + Vector3.new(side * 34, 0, -31), 5, visuals, side * 0.4)
            Reef.Prop(model, side > 0 and "reef_boulder_a" or "reef_boulder_b", origin + Vector3.new(side * 51, 0, -34), 3.5, visuals, side)
        end
    elseif floor.Id == 2 then
        Reef.Prop(model, "modern_wreck", origin, 35, visuals, -0.25)
        Reef.Prop(model, "reef_wreck", origin + Vector3.new(69, 0, -44), 5, visuals, 0.4)
        for side = -1, 1, 2 do
            Reef.Prop(model, "modern_cannon", origin + Vector3.new(side * 37, 0, 40), 2.1, visuals, side * 0.8)
            for index = 1, 3 do
                Reef.Prop(model, "modern_barrel", origin + Vector3.new(side * 54, 0, index * 16 - 25), 1.2, visuals, index * 0.7)
            end
        end
        for i = 1, 6 do
            local p = origin + Vector3.new((i - 3.5) * 16, 0, 57)
            Reef.Prop(model, "reef_chest", p, 1.4, visuals, i * 0.6)
            Reef.Prop(model, "reef_kelp", p + Vector3.new(0, 0, 10), 4.5, visuals, i)
        end
    elseif floor.Id == 3 or floor.Id == 6 then
        local scale = floor.Id == 6 and 18 or 13
        Reef.Prop(model, "reef_arch", origin + Vector3.new(0, 0, -6), scale, visuals)
        Reef.Prop(model, "modern_arch", origin + Vector3.new(0, 0, -25), Vector3.new(3, 6, 3), visuals, math.pi / 2)
        for index = -1, 1 do
            Reef.Prop(model, "modern_stairs", origin + Vector3.new(0, 0, 40 + index * 15), 3.5, visuals, math.pi)
        end
        for side = -1, 1, 2 do
            for row = -1, 1 do
                local foot = origin + Vector3.new(side * 48, 0, row * 43)
                Reef.Prop(model, "modern_pillar", foot, Vector3.new(1.2, 1.2, 1.2), visuals, row * math.pi / 2)
                Reef.Prop(model, "reef_columns", foot + Vector3.new(0, 4, 0), Vector3.new(2.4, floor.Id == 6 and 10 or 8, 2.4), visuals, row * math.pi / 2)
            end
            if floor.Id == 6 then crystal(model, origin + Vector3.new(side * 36, 0, -37), 7, visuals) end
        end
        if floor.Id == 6 then
            local color = Color3.fromRGB(137, 218, 255)
            for i = 1, 6 do
                local a = i * math.pi / 3
                local p = origin + Vector3.new(math.cos(a) * 30, 5, math.sin(a) * 30 - 4)
                local socket = visuals.Part(model, "Lumière du sanctuaire", Vector3.new(2, 0.5, 2), CFrame.new(p), color, Enum.Material.Neon)
                if i % 2 == 0 then lamp(socket, color, 28, 0.7) end
            end
        end
    elseif floor.Id == 4 then
        cavern(model, origin, visuals, 0.95)
        for i = 1, 9 do
            local a = i * math.pi * 2 / 9
            local p = origin + Vector3.new(math.cos(a) * 48, 0, math.sin(a) * 48)
            Reef.Prop(model, "reef_kelp", p, 13 + i % 3, visuals, a)
            crystal(model, p + Vector3.new(-8, 0, 4), 3.7, visuals)
        end
    else
        cavern(model, origin, visuals, 1.15)
        for side = -1, 1, 2 do
            Reef.Prop(model, "modern_pinnacle", origin + Vector3.new(side * 46, -4, 0), Vector3.new(9, 16, 12), visuals, side * 0.4)
            crystal(model, origin + Vector3.new(side * 42, 0, 32), 5, visuals)
        end
    end
    for _, object in ipairs(model:GetDescendants()) do
        if object:GetAttribute("ArtAsset") then object:SetAttribute("ArtDistance", 430) end
    end
    return model
end
return Reef
