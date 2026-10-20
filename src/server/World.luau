--!nonstrict
local Workspace = game:GetService("Workspace")
local World = {}
World.__index = World

function World.Build(config, visuals)
    local self = setmetatable({ Config = config, Visuals = visuals, Bases = {}, Spawns = {}, Stations = {} }, World)
    for _, name in ipairs({ "Map", "Floors", "Bases", "EggSpawns", "Eggs", "Guardians", "NPCs", "Events" }) do
        local folder = Instance.new("Folder"); folder.Name = name; folder.Parent = Workspace; self[name] = folder
    end
    local terrain = Workspace.Terrain
    terrain.WaterColor = Color3.fromRGB(21, 165, 204)
    terrain.WaterTransparency = 0.65
    terrain.WaterReflectance = 0.3
    terrain.WaterWaveSize = 0.08
    terrain.WaterWaveSpeed = 4
    local lastFloor = config.Floors[config.ActiveFloors]
    local oceanBottom = lastFloor.Bottom - 16
    local oceanHeight = config.WaterTop - oceanBottom + 20
    local oceanCenter = (config.WaterTop + oceanBottom) / 2
    -- FallenPartsDestroyHeight is configured in the place file: Roblox only
    -- allows Studio/plugins to write it, so setting it here aborts the server.
    -- Keep each terrain edit below the engine's large-region voxel limits.
    for bottom = oceanBottom, 103, 128 do
        local height = math.min(128, 104 - bottom)
        terrain:FillBlock(CFrame.new(0, bottom + height / 2, 0), Vector3.new(960, height, 960), Enum.Material.Water)
        task.wait()
    end
    local function solid(parent, name, size, pos, color, material)
        local part = visuals.Part(parent, name, size, CFrame.new(pos), color, material or Enum.Material.Slate)
        part.CanCollide = true; part.CanQuery = true
        return part
    end
    local rock = Color3.fromRGB(35, 69, 79)
    for _, x in ipairs({ -445, 445 }) do solid(self.Map, "Falaise", Vector3.new(25, oceanHeight, 920), Vector3.new(x, oceanCenter, 0), rock) end
    for _, z in ipairs({ -445, 445 }) do solid(self.Map, "Falaise", Vector3.new(920, oceanHeight, 25), Vector3.new(0, oceanCenter, z), rock) end
    solid(self.Map, "Fond", Vector3.new(920, 20, 920), Vector3.new(0, oceanBottom, 0), rock)
    local rng = Random.new(41871)
    for _, floor in ipairs(config.Floors) do
        if floor.Id > config.ActiveFloors then continue end
        Workspace:SetAttribute("UnderwaterBootMessage", "Construction : " .. floor.Name)
        task.wait()
        local folder = Instance.new("Folder"); folder.Name = floor.Id .. "_" .. floor.ShortName; folder.Parent = self.Floors
        local color = visuals.Color(floor.Color)
        -- The central 150-stud shaft stays open between the active floors.
        if floor.Id < config.ActiveFloors then
            solid(folder, "Plateau ouest", Vector3.new(355, 12, 860), Vector3.new(-252.5, floor.Bottom, 0), rock)
            solid(folder, "Plateau est", Vector3.new(355, 12, 860), Vector3.new(252.5, floor.Bottom, 0), rock)
            solid(folder, "Plateau nord", Vector3.new(150, 12, 355), Vector3.new(0, floor.Bottom, -252.5), rock)
            solid(folder, "Plateau sud", Vector3.new(150, 12, 355), Vector3.new(0, floor.Bottom, 252.5), rock)
        end
        for side = -1, 1, 2 do
            visuals.Part(folder, "Guide de descente", Vector3.new(2, 2, 150), CFrame.new(side * 75, floor.Bottom + 8, 0), color, Enum.Material.Neon)
            visuals.Part(folder, "Guide de descente", Vector3.new(150, 2, 2), CFrame.new(0, floor.Bottom + 8, side * 75), color, Enum.Material.Neon)
        end
        local title = visuals.Part(folder, "Signal", Vector3.new(1, 1, 1), CFrame.new(0, floor.Top - 45, -82), color)
        title.Transparency = 1
        visuals.Label(title, string.format("%02d  /  %s\nCOMBINAISON CONSEILLÉE %d", floor.Id, string.upper(floor.Name), floor.MinLevel), color, 0, 240)
        self.Spawns[floor.Id] = {}
        for i = 1, 16 do
            local angle = i / 16 * math.pi * 2
            local radius = rng:NextNumber(135, 320)
            local pos = Vector3.new(math.cos(angle) * radius, floor.Bottom + rng:NextNumber(38, 120), math.sin(angle) * radius)
            local marker = visuals.Part(self.EggSpawns, "Nest_" .. floor.Id .. "_" .. i, Vector3.new(8, 1, 8), CFrame.new(pos - Vector3.new(0, 3, 0)), color, Enum.Material.Sand, Enum.PartType.Ball)
            marker.Transparency = 0.45
            table.insert(self.Spawns[floor.Id], { Id = floor.Id .. ":" .. i, Position = pos })
        end
        local stationPos = Vector3.new(105, floor.Bottom + 95, -45)
        local station = visuals.Part(self.NPCs, "Station oxygène " .. floor.Id, Vector3.new(9, 13, 9), CFrame.new(stationPos), Color3.fromRGB(92, 248, 205), Enum.Material.Neon, Enum.PartType.Cylinder)
        station.Transparency = 0.35
        visuals.Label(station, "O₂  RECHARGE\nApprochez-vous pour respirer", Color3.fromRGB(174, 255, 228), 10, 150)
        table.insert(self.Stations, stationPos)
        for _ = 1, 36 do
            local angle = rng:NextNumber(0, math.pi * 2)
            local radius = rng:NextNumber(100, 410)
            local pos = Vector3.new(math.cos(angle) * radius, floor.Bottom + 13, math.sin(angle) * radius)
            local stone = visuals.Part(folder, "Roche", Vector3.new(rng:NextNumber(8, 28), rng:NextNumber(9, 24), rng:NextNumber(8, 25)), CFrame.new(pos), rock:Lerp(color, 0.18), Enum.Material.Rock, Enum.PartType.Ball)
            stone.CanCollide = true; stone.CanQuery = true
            if floor.Id == 1 then
                local coralColor = rng:NextNumber() < 0.5 and Color3.fromRGB(249, 124, 143) or Color3.fromRGB(244, 192, 110)
                for branch = 1, 3 do
                    local a = pos + Vector3.new(branch * 2 - 4, 6, 0)
                    local b = a + Vector3.new(rng:NextNumber(-5, 5), rng:NextNumber(8, 18), rng:NextNumber(-4, 4))
                    visuals.Rod(folder, "Corail", a, b, 2, coralColor)
                    visuals.Part(folder, "Corail", Vector3.new(5, 5, 5), CFrame.new(b), coralColor, nil, Enum.PartType.Ball)
                end
            elseif floor.Id >= 3 then
                visuals.Part(folder, "Cristal", Vector3.new(3, 16, 3), CFrame.new(pos + Vector3.new(0, 14, 0)) * CFrame.Angles(0.15, 0, 0.3), color, Enum.Material.Neon)
                if floor.Id == 4 then
                    local top = pos + Vector3.new(rng:NextNumber(-12, 12), rng:NextNumber(35, 80), rng:NextNumber(-12, 12))
                    visuals.Rod(folder, "Arbre bioluminescent", pos, top, 2.5, Color3.fromRGB(60, 136, 140))
                    visuals.Part(folder, "Couronne abyssale", Vector3.new(18, 6, 18), CFrame.new(top), Color3.fromRGB(104, 237, 226), Enum.Material.Neon, Enum.PartType.Ball).Transparency = 0.45
                elseif floor.Id >= 5 then
                    local pillar = solid(folder, "Monolithe", Vector3.new(10, 90 + floor.Id * 6, 10), pos + Vector3.new(0, 45, 0), rock, Enum.Material.Basalt)
                    if floor.Id == 6 then
                        visuals.Rod(folder, "Veine interdite", pillar.Position - Vector3.new(0, 35, -6), pillar.Position + Vector3.new(0, 35, 6), 1.2, color, Enum.Material.Neon)
                    end
                end
            end
        end
        if floor.Id == 2 then
            local ship = Instance.new("Model"); ship.Name = "La Belle Noyée"; ship.Parent = folder
            local center = Vector3.new(-180, floor.Bottom + 40, -10)
            solid(ship, "Pont", Vector3.new(80, 8, 155), center, Color3.fromRGB(92, 69, 58), Enum.Material.WoodPlanks)
            for side = -1, 1, 2 do
                solid(ship, "Coque", Vector3.new(6, 40, 155), center + Vector3.new(side * 40, 13, 0), Color3.fromRGB(76, 63, 56), Enum.Material.WoodPlanks)
            end
            for i = -2, 2 do
                solid(ship, "Poutre", Vector3.new(5, 60, 5), center + Vector3.new(0, 28, i * 28), Color3.fromRGB(73, 62, 53), Enum.Material.Wood)
            end
            for i = 1, 6 do
                solid(ship, "Coffre", Vector3.new(9, 6, 6), center + Vector3.new(15, 8, i * 18 - 65), Color3.fromRGB(167, 122, 58), Enum.Material.WoodPlanks)
                visuals.Rod(ship, "Chaîne", center + Vector3.new(-15, 5, i * 18 - 65), center + Vector3.new(-20, 30, i * 18 - 65), 0.7, Color3.fromRGB(92, 112, 116), Enum.Material.Metal)
            end
        elseif floor.Id == 3 then
            local temple = Instance.new("Model"); temple.Name = "Sanctuaire d'Atlantis"; temple.Parent = folder
            local center = Vector3.new(190, floor.Bottom + 18, 70)
            solid(temple, "Esplanade", Vector3.new(135, 8, 120), center, Color3.fromRGB(91, 103, 127), Enum.Material.Marble)
            for x = -1, 1, 2 do
                for z = -1, 1, 2 do
                    local p = center + Vector3.new(x * 48, 35, z * 42)
                    local column = solid(temple, "Colonne", Vector3.new(12, 66, 12), p, Color3.fromRGB(130, 145, 155), Enum.Material.Marble)
                    column.Shape = Enum.PartType.Cylinder; column.CFrame *= CFrame.Angles(0, 0, math.pi / 2); column.Size = Vector3.new(66, 12, 12)
                    visuals.Part(temple, "Rune", Vector3.new(13, 2, 13), CFrame.new(p + Vector3.new(0, 29, 0)), color, Enum.Material.Neon)
                end
            end
            solid(temple, "Fronton", Vector3.new(128, 10, 110), center + Vector3.new(0, 72, 0), Color3.fromRGB(105, 118, 141), Enum.Material.Marble)
        elseif floor.Id >= 5 then
            local origin = Vector3.new(-175, floor.Bottom + 125, 60)
            for i = -3, 3 do
                local a = origin + Vector3.new(i * 18, -40, -55)
                local b = origin + Vector3.new(i * 18, 15, 0)
                local c = origin + Vector3.new(i * 18, -40, 55)
                visuals.Rod(folder, "Côte du titan", a, b, 5, Color3.fromRGB(135, 160, 173), Enum.Material.Limestone)
                visuals.Rod(folder, "Côte du titan", b, c, 5, Color3.fromRGB(135, 160, 173), Enum.Material.Limestone)
            end
            if floor.Id == 6 then
                local altar = solid(folder, "Trône interdit", Vector3.new(60, 8, 60), Vector3.new(190, floor.Bottom + 45, 90), color:Lerp(rock, 0.5), Enum.Material.Marble)
                for i = 1, 8 do
                    local angle = i * math.pi / 4
                    local p = altar.Position + Vector3.new(math.cos(angle) * 45, 38, math.sin(angle) * 45)
                    visuals.Part(folder, "Rune primordiale", Vector3.new(8, 60, 8), CFrame.new(p) * CFrame.Angles(0, angle, 0.15), color, Enum.Material.Neon)
                end
                visuals.Label(altar, "LA FOSSE INTERDITE\nLE RISQUE EST VOTRE RICHESSE", Color3.fromRGB(211, 178, 255), 90, 250)
            end
        end
    end
    require(script.Parent.Ship).Build(self, config, visuals)
    return self
end

local function inside(position, box)
    return position.X >= box.Min.X and position.X <= box.Max.X and position.Y >= box.Min.Y and position.Y <= box.Max.Y
        and position.Z >= box.Min.Z and position.Z <= box.Max.Z
end

function World:SafeBase(position)
    for _, base in ipairs(self.Bases) do
        if base.Min then
            if inside(position, base) then return base end
        elseif (position - base.Center).Magnitude <= self.Config.BaseRadius then return base end
    end
    if self.SharedDeck and inside(position, self.SharedDeck) then return self.SharedDeck end
    return nil
end

function World:SegmentProtected(a, b)
    if not self.SafeRegions then return nil end
    for _, box in ipairs(self.SafeRegions) do
        local low, high = 0, 1
        for _, axis in ipairs({ "X", "Y", "Z" }) do
            local delta = b[axis] - a[axis]
            if math.abs(delta) < 0.0001 then
                if a[axis] < box.Min[axis] or a[axis] > box.Max[axis] then high = -1; break end
            else
                local t1, t2 = (box.Min[axis] - a[axis]) / delta, (box.Max[axis] - a[axis]) / delta
                low = math.max(low, math.min(t1, t2)); high = math.min(high, math.max(t1, t2))
            end
        end
        if low <= high then return true end
    end
    return false
end

function World:AtStation(position)
    if self:SafeBase(position) then return true end
    for _, pos in ipairs(self.Stations) do if (pos - position).Magnitude <= 17 then return true end end
    return false
end

function World:AssignBase(player)
    for _, base in ipairs(self.Bases) do
        if base.OwnerId == 0 then
            base.OwnerId = player.UserId
            base.Model:SetAttribute("OwnerId", player.UserId)
            base.Label.Text = player.DisplayName .. "\n@" .. player.Name
            base.Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
            return base
        end
    end
    return nil
end

function World:RefreshAnimals(state)
    local base = state.Base
    local level = state.Profile.BaseLevel or 1
    if base.Level ~= level then
        require(script.Parent.Ship).Aquarium(base, level, self.Config, self.Visuals)
        self:RefreshIncubators(state)
    end
    base.Display:ClearAllChildren()
    base.Swimmers = {}
    local sorted = {}
    local present = {}
    for id, count in pairs(state.Profile.Animals) do present[id] = count end
    for id, variants in pairs(state.Profile.Variants) do
        for _, count in pairs(variants) do present[id] = (present[id] or 0) + count end
    end
    for id, count in pairs(present) do table.insert(sorted, { Id = id, Count = count }) end
    table.sort(sorted, function(a, b) return self.Config.Animals[a.Id].Income > self.Config.Animals[b.Id].Income end)
    for i = 1, math.min(#sorted, self.Config.BaseUpgrades[level].Display) do
        local entry = sorted[i]; local spec = self.Config.Animals[entry.Id]
        local position = base.TankCenter + Vector3.new(((i - 1) % 4 - 1.5) * 11, 1 + math.floor((i - 1) / 4) * 3, (math.floor((i - 1) / 4) - 1) * 7)
        local grade, displaySpec = "Normal", table.clone(spec)
        for _, variant in ipairs({ "Gold", "Diamond", "Mythic" }) do if ((state.Profile.Variants[entry.Id] or {})[variant] or 0) > 0 then grade = variant end end
        if grade == "Gold" then displaySpec.Color = { 255, 204, 81 } elseif grade == "Diamond" then displaySpec.Color = { 166, 244, 255 } elseif grade == "Mythic" then displaySpec.Color = { 239, 133, 255 } end
        local model = self.Visuals.Animal(base.Display, displaySpec, CFrame.new(position), 1.2, spec.Name .. " ×" .. entry.Count .. "\n" .. string.upper(grade) .. " · " .. spec.Income .. " gold/min")
        table.insert(base.Swimmers, { Model = model, Origin = position, Phase = i * 1.7 })
    end
    self:ApplyCustomization(state)
end

function World:RefreshIncubators(state)
    local base = state.Base
    base.EggDisplay:ClearAllChildren(); base.Incubators = {}
    local index = 0
    for _, egg in ipairs(state.Profile.Eggs) do
        if not egg.ReadyAt then continue end
        index += 1
        local position = base.TankCenter + Vector3.new(((index - 1) % 6 - 2.5) * 7, -9, math.floor((index - 1) / 6) * 6 - 10)
        local part = self.Visuals.Egg(base.EggDisplay, egg.Name, self.Config.Rarities[egg.Rarity], CFrame.new(position))
        part.Size *= math.min(0.36, 4 / part.Size.Y); part.CanQuery = false
        local label = self.Visuals.Label(part, "INCUBATION", self.Visuals.Color(self.Config.Rarities[egg.Rarity].Color), 3, 100)
        table.insert(base.Incubators, { Egg = egg, Label = label })
    end
end

function World:StepAquariums(now)
    for _, base in ipairs(self.Bases) do
        for _, swimmer in ipairs(base.Swimmers) do
            local phase = now * 0.4 + swimmer.Phase
            swimmer.Model:PivotTo(CFrame.new(swimmer.Origin + Vector3.new(math.sin(phase) * 2.5, math.cos(phase) * 0.7, math.cos(phase) * 1.5)) * CFrame.Angles(0, math.cos(phase) * 0.4, 0))
        end
        for _, item in ipairs(base.Incubators) do
            local remaining = math.max(0, item.Egg.ReadyAt - os.time())
            item.Label.Text = string.upper(item.Egg.Rarity) .. string.format("\n%02d:%02d", math.floor(remaining / 60), remaining % 60)
        end
    end
end

function World:ApplyCustomization(state)
    local base, profile = state.Base, state.Profile
    local palette = self.Config.Decorations[profile.Palette] or self.Config.Decorations.lagoon
    local color = self.Visuals.Color(palette.Color)
    base.Core.Color = color
    local tank = base.Model:FindFirstChild("Aquarium géant")
    local bar = tank and tank:FindFirstChild("Rampe lumineuse")
    if bar then
        bar.Color = color
        local light = bar:FindFirstChildOfClass("PointLight")
        if light then light.Color = color end
    end
    base.Label.TextColor3 = color
    base.Label.Text = state.Player.DisplayName .. "\n@" .. state.Player.Name
    base.TierLabel.Text = self.Config.BaseUpgrades[profile.BaseLevel or 1].Name:upper() .. " · NIVEAU " .. (profile.BaseLevel or 1)
    local old = base.Model:FindFirstChild("Personnalisation")
    if old then old:Destroy() end
    local folder = Instance.new("Folder"); folder.Name = "Personnalisation"; folder.Parent = base.Model
    if profile.OwnedDecor.aquarium then
        local pos = base.Center + Vector3.new(32, -3, -19)
        local glass = self.Visuals.Part(folder, "Aquarium", Vector3.new(14, 11, 12), CFrame.new(pos), color, Enum.Material.Glass)
        glass.Transparency = 0.7
        self.Visuals.Animal(folder, self.Config.Animals.clownfish, CFrame.new(pos), 0.65)
    end
    if profile.OwnedDecor.statue then
        self.Visuals.Animal(folder, { Name = "Statue du gardien", Style = "shark", Color = { 213, 183, 102 } }, CFrame.new(base.Center + Vector3.new(-32, -3, -20)), 1.5)
    end
    if profile.OwnedDecor.bubbles or profile.Prestige > 0 then
        local emitter = Instance.new("ParticleEmitter")
        emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"; emitter.Color = ColorSequence.new(color)
        emitter.Rate = profile.Prestige > 0 and 10 or 5; emitter.Lifetime = NumberRange.new(2, 4); emitter.Speed = NumberRange.new(2, 4)
        local anchor = self.Visuals.Part(folder, "Source des bulles", Vector3.one, CFrame.new(base.Center - Vector3.new(0, 9, 0)), color)
        anchor.Transparency = 1; emitter.Parent = anchor
    end
end
return World
