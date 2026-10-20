--!nonstrict
local HttpService = game:GetService("HttpService")
local EggSystem = {}
EggSystem.__index = EggSystem

function EggSystem.new(context)
    return setmetatable({ Ctx = context, Eggs = {}, Occupied = {}, NextSpawn = 0, NextIncubation = 0 }, EggSystem)
end

function EggSystem:Spawn(floor, forcedRarity)
    local ctx = self.Ctx
    if floor.Id > ctx.Config.ActiveFloors then return end
    local free, count = {}, 0
    for _, egg in pairs(self.Eggs) do if egg.Floor == floor.Id and egg.State == "World" then count += 1 end end
    if count >= ctx.Config.EggsPerFloor then return end
    for _, point in ipairs(ctx.World.Spawns[floor.Id]) do if not self.Occupied[point.Id] then table.insert(free, point) end end
    if #free == 0 then return end
    local point = free[ctx.Random:NextInteger(1, #free)]
    local rarity = forcedRarity or ctx.Rules.PickWeighted(ctx.Rules.RarityWeights(ctx.Config, floor.Id, ctx.Event and ctx.Event.Key), ctx.Random:NextNumber())
    local name = floor.EggNames[ctx.Random:NextInteger(1, #floor.EggNames)]
    local position = point.Position + Vector3.new(ctx.Random:NextNumber(-4, 4), ctx.Random:NextNumber(0, 5), ctx.Random:NextNumber(-4, 4))
    local egg = { Id = HttpService:GenerateGUID(false), Floor = floor.Id, Rarity = rarity, Name = name,
        State = "World", Home = position, PointId = point.Id, Expires = os.clock() + ctx.Config.EggLifetime }
    self.Eggs[egg.Id] = egg; self.Occupied[point.Id] = true
    egg.Guardian = ctx.Guardians:Spawn(egg, floor)
    self:Show(egg, position)
    for _, state in pairs(ctx.States) do
        if state.LastPosition and (state.LastPosition - position).Magnitude < 170 then
            ctx:Notify(state.Player, "🥚 NOUVEL ŒUF DÉTECTÉ !\n👹 Le boss de la zone surveille les nids.", rarity)
        end
    end
end

function EggSystem:Show(egg, position)
    local ctx = self.Ctx
    egg.Part = ctx.Visuals.Egg(ctx.World.Eggs, egg.Name, ctx.Config.Rarities[egg.Rarity], CFrame.new(position))
    egg.Part:SetAttribute("EggId", egg.Id)
    ctx.Visuals.Label(egg.Part, egg.Name .. "\n" .. string.upper(egg.Rarity) .. " · GARDÉ", ctx.Visuals.Color(ctx.Config.Rarities[egg.Rarity].Color), 5, 95)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Ajouter à l’inventaire"; prompt.ObjectText = egg.Name .. " · " .. egg.Rarity
    prompt.HoldDuration = 0.25; prompt.MaxActivationDistance = math.max(ctx.Config.PickupDistance, ctx.Config.Rarities[egg.Rarity].Size * 0.65 + 5)
    prompt.RequiresLineOfSight = true; prompt.Parent = egg.Part
    egg.Prompt = prompt
    prompt.Triggered:Connect(function(player) self:Pickup(player, egg.Id) end)
end

function EggSystem:RefreshForEvent()
    for _, floor in ipairs(self.Ctx.Config.Floors) do
        if floor.Id > self.Ctx.Config.ActiveFloors then continue end
        -- Refresh untouched wild eggs; preserve pending and dropped eggs.
        for _, egg in pairs(self.Eggs) do
            if egg.Floor == floor.Id and egg.State == "World" then self:Remove(egg); break end
        end
        self:Spawn(floor, self.Ctx.Event and self.Ctx.Event.Name == "ŒUF LÉGENDAIRE" and floor.Id == 2 and "Legendary" or nil)
    end
end

function EggSystem:Pickup(player, id)
    local ctx = self.Ctx
    local state, egg = ctx.States[player], self.Eggs[id]
    if not state or not egg or state.Carrying or (egg.State ~= "World" and egg.State ~= "Dropped") then return end
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
    self.Ctx.FX:FireClient(state.Player, "Hatch", { AnimalId = animalId, Position = state.Base.TankCenter })
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
    if now >= self.NextSpawn then
        self.NextSpawn = now + self.Ctx.Config.SpawnInterval
        for _, floor in ipairs(self.Ctx.Config.Floors) do self:Spawn(floor) end
    end
    for _, egg in pairs(self.Eggs) do
        if egg.State == "Carried" then
            local state = self.Ctx.States[egg.Carrier]
            if not state then self:Remove(egg)
            elseif self.Ctx:Root(state) then self:Secure(state)
            else self:Drop(state, "Death") end
        elseif now >= egg.Expires then self:Remove(egg) end
    end
end
return EggSystem
