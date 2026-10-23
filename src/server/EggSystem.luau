--!nonstrict
local HttpService = game:GetService("HttpService")
local EggSystem = {}
EggSystem.__index = EggSystem

function EggSystem.new(context)
    return setmetatable({ Ctx = context, Eggs = {}, Occupied = {}, NextSpawn = 0, NextIncubation = 0 }, EggSystem)
end

function EggSystem:ActiveEventKey()
    local event = self.Ctx.Event
    if event and self.Ctx.Config.Events[event.Key] and self.Ctx.Rules.IsFinite(event.Ends) and event.Ends > os.clock() then return event.Key end
    return nil
end

function EggSystem:WildCount(floorId)
    local count = 0
    for _, egg in pairs(self.Eggs) do if egg.Floor == floorId and egg.State == "World" then count += 1 end end
    return count
end

function EggSystem:FillFloor(floor)
    -- Bounded even when a map has fewer nests or a service is unavailable.
    local missing = math.max(0, self.Ctx.Config.EggsPerFloor - self:WildCount(floor.Id))
    for _ = 1, missing do if not self:Spawn(floor) then break end end
end

function EggSystem:Spawn(floor, forcedRarity)
    local ctx = self.Ctx
    if floor.Id > ctx.Config.ActiveFloors or self:WildCount(floor.Id) >= ctx.Config.EggsPerFloor then return nil end
    local eventKey = self:ActiveEventKey()
    if forcedRarity and not ctx.Rules.CanSpawnRarity(ctx.Config, floor.Id, forcedRarity, eventKey) then return nil end
    local free = {}
    for _, point in ipairs(ctx.World.Spawns[floor.Id] or {}) do if not self.Occupied[point.Id] then table.insert(free, point) end end
    if #free == 0 then return nil end
    local point = free[ctx.Random:NextInteger(1, #free)]
    local rarity = forcedRarity or ctx.Rules.PickWeighted(ctx.Rules.RarityWeights(ctx.Config, floor.Id, eventKey), ctx.Random:NextNumber())
    local spec = ctx.Config.Rarities[rarity]
    local name = spec.EggName and (spec.EggName .. " · " .. floor.Name) or floor.EggNames[ctx.Random:NextInteger(1, #floor.EggNames)]
    local height = point.GroundY and (point.GroundY + 1.25 * spec.Size / 2 + 0.8 + ctx.Random:NextNumber(0, 0.5))
        or point.Position.Y + ctx.Random:NextNumber(0, 5)
    local position = Vector3.new(point.Position.X + ctx.Random:NextNumber(-4, 4), height, point.Position.Z + ctx.Random:NextNumber(-4, 4))
    local expires = os.clock() + ctx.Config.EggLifetime
    if spec.EventOnly then expires = math.min(expires, ctx.Event.Ends) end
    local egg = { Id = HttpService:GenerateGUID(false), Floor = floor.Id, Rarity = rarity, Name = name, Event = spec.EventOnly and eventKey or nil,
        State = "World", Home = position, PointId = point.Id, Expires = expires }
    self.Eggs[egg.Id] = egg; self.Occupied[point.Id] = true
    egg.Guardian = ctx.Guardians:Spawn(egg, floor)
    self:Show(egg, position)
    for _, state in pairs(ctx.States) do
        if state.LastPosition and (state.LastPosition - position).Magnitude < 170
            and (spec.EventOnly or spec.Power >= 1.9) and os.clock() >= (state.NextEggNotice or 0) then
            state.NextEggNotice = os.clock() + (spec.EventOnly and 4 or 12)
            ctx:Notify(state.Player, "🥚 NOUVEL ŒUF DÉTECTÉ !\n👹 Le boss de la zone surveille les nids.", rarity)
        end
    end
    return egg
end

function EggSystem:Show(egg, position)
    local ctx = self.Ctx
    egg.Part = ctx.Visuals.Egg(ctx.World.Eggs, egg.Name, ctx.Config.Rarities[egg.Rarity], CFrame.new(position))
    egg.Part:SetAttribute("EggId", egg.Id)
    local rarity = ctx.Config.Rarities[egg.Rarity]
    ctx.Visuals.Label(egg.Part, egg.Name .. "\n" .. rarity.Label .. " · GARDÉ", ctx.Visuals.Color(rarity.Color), 5, 95)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Ajouter à l’inventaire"; prompt.ObjectText = egg.Name .. " · " .. rarity.Label
    prompt.HoldDuration = 0.25; prompt.MaxActivationDistance = math.max(ctx.Config.PickupDistance, ctx.Config.Rarities[egg.Rarity].Size * 0.65 + 5)
    prompt.RequiresLineOfSight = true; prompt.Parent = egg.Part
    egg.Prompt = prompt
    prompt.Triggered:Connect(function(player) self:Pickup(player, egg.Id) end)
end

function EggSystem:RefreshForEvent()
    local ctx = self.Ctx
    local eventKey = self:ActiveEventKey()
    local event = eventKey and ctx.Config.Events[eventKey]
    local guarantees = event and event.GuaranteedEggs or {}
    for _, floor in ipairs(ctx.Config.Floors) do
        if floor.Id > ctx.Config.ActiveFloors then continue end
        local wild = {}
        for _, egg in pairs(self.Eggs) do if egg.Floor == floor.Id and egg.State == "World" then table.insert(wild, egg) end end
        table.sort(wild, function(a, b) return a.Expires == b.Expires and a.Id < b.Id or a.Expires < b.Expires end)
        -- Refresh only a small group of untouched nests, never pending/dropped loot.
        for index = 1, math.min(#wild, math.max(ctx.Config.EventRefreshCount, #guarantees)) do self:Remove(wild[index]) end
        for _, rarity in ipairs(guarantees) do self:Spawn(floor, rarity) end
        if ctx.Event and ctx.Event.Name == "ŒUF LÉGENDAIRE" and floor.Id == 2 then self:Spawn(floor, "Legendary") end
        self:FillFloor(floor)
    end
end

function EggSystem:EndEvent()
    local remove = {}
    for _, egg in pairs(self.Eggs) do
        if egg.State == "World" and self.Ctx.Config.Rarities[egg.Rarity].EventOnly then table.insert(remove, egg) end
    end
    for _, egg in ipairs(remove) do self:Remove(egg) end
    for _, floor in ipairs(self.Ctx.Config.Floors) do if floor.Id <= self.Ctx.Config.ActiveFloors then self:FillFloor(floor) end end
end

function EggSystem:Pickup(player, id)
    local ctx = self.Ctx
    local state, egg = ctx.States[player], self.Eggs[id]
    if not state or not egg or state.Carrying or (egg.State ~= "World" and egg.State ~= "Dropped") then return end
    -- A late prompt cannot collect an untouched nest after its expiry or the
    -- exact event boundary, even before the next maintenance heartbeat.
    if egg.State == "World" and (os.clock() >= egg.Expires or
        (ctx.Config.Rarities[egg.Rarity].EventOnly and not ctx.Rules.CanSpawnRarity(ctx.Config, egg.Floor, egg.Rarity, self:ActiveEventKey()))) then
        self:Remove(egg); self.NextSpawn = 0; return
    end
    if not ctx:Validate(state) then return end
    local root = ctx:Root(state)
    local reach = math.max(ctx.Config.PickupDistance, ctx.Config.Rarities[egg.Rarity].Size * 0.65 + 5)
    if not root or (root.Position - egg.Part.Position).Magnitude > reach + 1 then return end
    if ctx.World:SafeBase(root.Position) then return end
    if #state.Profile.Eggs >= ctx.Config.MaxStoredEggs then ctx:Notify(player, "Inventaire plein : déposez vos œufs dans l’aquarium.", "Warning"); return end
    local filter = RaycastParams.new(); filter.FilterType = Enum.RaycastFilterType.Exclude
    filter.FilterDescendantsInstances = { player.Character, ctx.World.Eggs, ctx.World.Guardians }; filter.IgnoreWater = true
    if workspace:Raycast(root.Position, egg.Part.Position - root.Position, filter) then return end
    -- Keep the pending egg in the server registry, but remove its world model.
    -- The snapshot includes it as an unsecured inventory slot, never as a pet
    -- or permanent saved egg before reaching the owner's gallery.
    if egg.DropReason == "Harpoon" and egg.PreviousCarrier ~= player.UserId then
        state.Profile.Stats.Steals += 1
        ctx:Broadcast("🔥 " .. player.DisplayName .. " a récupéré l’œuf !", egg.Rarity)
    end
    egg.State = "Carried"; egg.Carrier = player; egg.DropReason = nil
    state.Carrying = id; egg.Part:Destroy(); egg.Part = nil; egg.Prompt = nil
    if egg.PointId then self.Occupied[egg.PointId] = nil; egg.PointId = nil end
    self.NextSpawn = math.min(self.NextSpawn, os.clock() + 1)
    self:Highlight(state, egg)
    ctx:Notify(player, "🥚 ŒUF DANS L’INVENTAIRE · NON SÉCURISÉ\nRamenez-le à votre base et évitez les harpons !", egg.Rarity)
end

function EggSystem:Highlight(state, egg)
    local old = state.Aura
    if old then old:Destroy(); state.Aura = nil end
    local character = state.Player.Character
    if not egg or not character then return end
    local aura = Instance.new("Highlight"); aura.Name = "Transport · " .. egg.Rarity
    aura.Adornee = character; aura.FillColor = self.Ctx.Visuals.Color(self.Ctx.Config.Rarities[egg.Rarity].Color)
    aura.OutlineColor = aura.FillColor; aura.FillTransparency = 0.65; aura.OutlineTransparency = 0.02
    aura.DepthMode = Enum.HighlightDepthMode.Occluded; aura.Parent = character
    state.Aura = aura
end

function EggSystem:Remove(egg)
    if egg.Part then egg.Part:Destroy() end
    if egg.PointId then self.Occupied[egg.PointId] = nil end
    self.Eggs[egg.Id] = nil
end

function EggSystem:Secure(state)
    local egg = state.Carrying and self.Eggs[state.Carrying]
    local base = state.LastPosition and self.Ctx.World:SafeBase(state.LastPosition)
    if not egg or not base or not self.Ctx.Rules.CanSecure(egg.Carrier and egg.Carrier.UserId, state.Player.UserId, base.OwnerId, egg.State) then return false end
    if #state.Profile.Eggs >= self.Ctx.Config.MaxStoredEggs then return false end
    egg.State = "Secured"
    table.insert(state.Profile.Eggs, { Id = egg.Id, Floor = egg.Floor, Rarity = egg.Rarity, Name = egg.Name })
    state.Profile.Stats.Secured += 1; state.Profile.XP += 10 * egg.Floor
    state.Carrying = nil; self:Highlight(state, nil); self:Remove(egg)
    self.Ctx:Notify(state.Player, "🔒 ŒUF SÉCURISÉ !\nIl ne peut plus être volé. Déposez-le dans votre aquarium.", "Success")
    return true
end

function EggSystem:Drop(state, reason)
    local egg = state.Carrying and self.Eggs[state.Carrying]
    if not egg then return false end
    if self:Secure(state) then return false end
    local ctx = self.Ctx
    local position = state.LastPosition or egg.Home
    local base = ctx.World:SafeBase(position)
    if base then
        if reason == "Harpoon" or reason == "Manual" then return false end
        position = ctx.World.DiveWater or (base.Center + Vector3.xAxis * (ctx.Config.BaseRadius + 7))
    end
    egg.State = "Dropped"; egg.PreviousCarrier = state.Player.UserId; egg.Carrier = nil
    egg.DropReason = reason; egg.Expires = os.clock() + ctx.Config.DroppedEggLifetime
    state.Carrying = nil; self:Highlight(state, nil)
    self:Show(egg, position)
    ctx:Notify(state.Player, "🥚 L’ŒUF EST TOMBÉ !", "Warning")
    return true
end

function EggSystem:Hatch(state, id)
    if type(id) ~= "string" then return end
    if not self.Ctx:Validate(state) then return end
    local base = self.Ctx.World:SafeBase(state.LastPosition)
    if not base or base.OwnerId ~= state.Player.UserId then self.Ctx:Notify(state.Player, "Rejoignez votre galerie pour déposer un œuf.", "Warning"); return end
    local egg, message = self.Ctx.Rules.StartIncubation(state.Profile, self.Ctx.Config, id, os.time())
    if not egg then self.Ctx:Notify(state.Player, message, "Warning"); return end
    self.Ctx.World:RefreshIncubators(state)
    self.Ctx:Notify(state.Player, "🥚 ŒUF DÉPOSÉ DANS L'AQUARIUM !\nÉclosion dans " .. self.Ctx.Config.HatchTimes[egg.Rarity] .. " secondes.", egg.Rarity)
end

function EggSystem:FinishIncubation(state, id)
    -- Completion uses only the persisted server deadline, never a client timer.
    local animalId = self.Ctx.Rules.Hatch(state.Profile, self.Ctx.Config, id, self.Ctx.Random:NextNumber(), os.time())
    if not animalId then return false end
    self.Ctx.World:RefreshAnimals(state)
    self.Ctx.World:RefreshIncubators(state)
    self.Ctx.FX:FireClient(state.Player, "Hatch", { AnimalId = animalId, Position = state.Base.IncubationCenter or state.Base.TankCenter })
    self.Ctx:Notify(state.Player, "🎉 NOUVEL ANIMAL DANS L'AQUARIUM !\n" .. self.Ctx.Config.Animals[animalId].Name .. " produit des gold !", "Success")
    return true
end

function EggSystem:Step()
    local now = os.clock()
    if now >= self.NextIncubation then
        self.NextIncubation = now + 0.5
        for _, state in pairs(self.Ctx.States) do
            if self.Ctx.Data and self.Ctx.Data:IsClosing(state.Player) then continue end
            for index = #state.Profile.Eggs, 1, -1 do
                local egg = state.Profile.Eggs[index]
                if egg.ReadyAt and os.time() >= egg.ReadyAt then self:FinishIncubation(state, egg.Id) end
            end
        end
    end
    -- Remove expired world eggs first so a synchronized lifetime never empties
    -- a whole floor for another spawn interval. Carried loot has no expiry.
    local remove, vacancy = {}, false
    local eventKey = self:ActiveEventKey()
    for _, egg in pairs(self.Eggs) do
        if egg.State == "Carried" then
            local state = self.Ctx.States[egg.Carrier]
            if not state then self:Remove(egg)
            elseif self.Ctx:Root(state) then self:Secure(state)
            else self:Drop(state, "Death") end
        elseif now >= egg.Expires or (egg.State == "World" and self.Ctx.Config.Rarities[egg.Rarity].EventOnly
            and not self.Ctx.Rules.CanSpawnRarity(self.Ctx.Config, egg.Floor, egg.Rarity, eventKey)) then
            table.insert(remove, egg); vacancy = vacancy or egg.State == "World"
        end
    end
    for _, egg in ipairs(remove) do self:Remove(egg) end
    if vacancy or now >= self.NextSpawn then
        self.NextSpawn = now + self.Ctx.Config.SpawnInterval
        for _, floor in ipairs(self.Ctx.Config.Floors) do if floor.Id <= self.Ctx.Config.ActiveFloors then self:FillFloor(floor) end end
    end
end
return EggSystem
