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
    for _, egg in pairs(self.Eggs) do if egg.Floor == floor.Id then count += 1 end end
    if count >= ctx.Config.EggsPerFloor then return end
    for _, point in ipairs(ctx.World.Spawns[floor.Id]) do if not self.Occupied[point.Id] then table.insert(free, point) end end
    if #free == 0 then return end
    local point = free[ctx.Random:NextInteger(1, #free)]
    local rarity = forcedRarity or ctx.Rules.PickWeighted(ctx.Rules.RarityWeights(ctx.Config, floor.Id, ctx.Event and ctx.Event.Key), ctx.Random:NextNumber())
    local name = floor.EggNames[ctx.Random:NextInteger(1, #floor.EggNames)]
    local position = point.Position + Vector3.new(ctx.Random:NextNumber(-4, 4), ctx.Random:NextNumber(0, 5), ctx.Random:NextNumber(-4, 4))
    local egg = { Id = HttpService:GenerateGUID(false), Floor = floor.Id, Rarity = rarity, Name = name,
        State = "World", Home = position, PointId = point.Id, Expires = os.clock() + ctx.Config.EggLifetime }
    egg.Part = ctx.Visuals.Egg(ctx.World.Eggs, name, ctx.Config.Rarities[rarity], CFrame.new(position))
    egg.Part:SetAttribute("EggId", egg.Id)
    ctx.Visuals.Label(egg.Part, name .. "\n" .. string.upper(rarity) .. " · GARDÉ", ctx.Visuals.Color(ctx.Config.Rarities[rarity].Color), 5, 95)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Transporter"; prompt.ObjectText = name .. " · " .. rarity
    prompt.HoldDuration = 0.25; prompt.MaxActivationDistance = ctx.Config.PickupDistance
    prompt.RequiresLineOfSight = true; prompt.Parent = egg.Part
    egg.Prompt = prompt
    self.Eggs[egg.Id] = egg
    self.Occupied[point.Id] = true
    -- Every spawn has a guardian before it becomes interactable.
    egg.Guardian = ctx.Guardians:Spawn(egg, floor)
    prompt.Triggered:Connect(function(player) self:Pickup(player, egg.Id) end)
    for _, state in pairs(ctx.States) do
        if state.LastPosition and (state.LastPosition - position).Magnitude < 170 then
            ctx:Notify(state.Player, "🥚 NOUVEL ŒUF DÉTECTÉ !\n👹 Un gardien protège cet œuf.", rarity)
        end
    end
end

function EggSystem:RefreshForEvent()
    for _, floor in ipairs(self.Ctx.Config.Floors) do
        if floor.Id > self.Ctx.Config.ActiveFloors then continue end
        -- Replace only untouched wild eggs, never a carried or dropped player's egg.
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
    if not root or (root.Position - egg.Part.Position).Magnitude > ctx.Config.PickupDistance + 1 then return end
    if ctx.World:SafeBase(root.Position) then return end
    if #state.Profile.Eggs >= ctx.Config.MaxStoredEggs then ctx:Notify(player, "Faites éclore vos œufs : l'incubateur est plein.", "Warning"); return end
    -- Obstructions cannot be bypassed by triggering a prompt through a wall.
    local filter = RaycastParams.new(); filter.FilterType = Enum.RaycastFilterType.Exclude
    filter.FilterDescendantsInstances = { player.Character, ctx.World.Eggs, ctx.World.Guardians }; filter.IgnoreWater = true
    if workspace:Raycast(root.Position, egg.Part.Position - root.Position, filter) then return end
    if egg.DropReason == "Harpoon" and egg.PreviousCarrier and egg.PreviousCarrier ~= player.UserId then
        state.Profile.Stats.Steals += 1
        ctx:Broadcast("🔥 " .. player.DisplayName .. " a récupéré l'œuf !", egg.Rarity)
    end
    egg.State = "Carried"; egg.Carrier = player; egg.DropReason = nil
    state.Carrying = id; egg.Prompt.Enabled = false; egg.Part.CanQuery = false
    if egg.Part:FindFirstChild("Label") then egg.Part.Label.TextLabel.Text = egg.Name .. "\nTRANSPORT → VOTRE BASE" end
    ctx:Notify(player, "🥚 Ramenez l'œuf dans votre habitat !", egg.Rarity)
    if ctx.Config.Rarities[egg.Rarity].Power >= 1.9 then ctx:Broadcast("⚠ " .. player.DisplayName .. " transporte un œuf " .. string.upper(egg.Rarity) .. " !", egg.Rarity) end
end

function EggSystem:Remove(egg)
    if egg.Guardian then self.Ctx.Guardians:Remove(egg.Guardian) end
    if egg.Part then egg.Part:Destroy() end
    self.Occupied[egg.PointId] = nil
    self.Eggs[egg.Id] = nil
end

function EggSystem:Secure(state)
    local id = state.Carrying
    local egg = id and self.Eggs[id]
    local base = state.LastPosition and self.Ctx.World:SafeBase(state.LastPosition)
    if not egg or not base or not self.Ctx.Rules.CanSecure(egg.Carrier and egg.Carrier.UserId, state.Player.UserId, base.OwnerId, egg.State) then return false end
    egg.State = "Secured"
    table.insert(state.Profile.Eggs, { Id = egg.Id, Floor = egg.Floor, Rarity = egg.Rarity, Name = egg.Name })
    state.Profile.Stats.Secured += 1; state.Profile.XP += 10 * egg.Floor
    state.Carrying = nil
    self:Remove(egg)
    self.Ctx:Notify(state.Player, "🔒 ŒUF SÉCURISÉ !\nDéposez-le dans votre aquarium pour lancer l'incubation.", "Success")
    return true
end

function EggSystem:Drop(state, reason)
    local egg = state.Carrying and self.Eggs[state.Carrying]
    if not egg then return false end
    if self:Secure(state) then return false end
    local position = state.LastPosition or egg.Home
    local base = self.Ctx.World:SafeBase(position)
    if base then
        if reason == "Harpoon" or reason == "Manual" then return false end
        -- A disconnect/death in somebody else's bubble cannot create a steal inside it.
        local offset = position - base.Center
        position = base.Center + (offset.Magnitude > 0.1 and offset.Unit or Vector3.xAxis) * (self.Ctx.Config.BaseRadius + 7)
    end
    egg.State = "Dropped"; egg.PreviousCarrier = state.Player.UserId; egg.Carrier = nil
    egg.DropReason = reason; egg.Expires = os.clock() + self.Ctx.Config.DroppedEggLifetime
    egg.Part.CFrame = CFrame.new(position); egg.Part.CanQuery = true
    egg.Prompt.Enabled = true; state.Carrying = nil
    if egg.Part:FindFirstChild("Label") then egg.Part.Label.TextLabel.Text = egg.Name .. "\nŒUF TOMBÉ · " .. string.upper(egg.Rarity) end
    self.Ctx:Notify(state.Player, "🥚 L'ŒUF EST TOMBÉ !", "Warning")
    return true
end

function EggSystem:Hatch(state, id)
    if type(id) ~= "string" then return end
    if not self.Ctx:Validate(state) then return end
    local base = self.Ctx.World:SafeBase(state.LastPosition)
    if not base or base.OwnerId ~= state.Player.UserId then self.Ctx:Notify(state.Player, "Rejoignez votre île pour déposer un œuf.", "Warning"); return end
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
            local root = state and self.Ctx:Root(state)
            if root then
                egg.Part.CFrame = root.CFrame * CFrame.new(0, 1.5, 2.5)
                self:Secure(state)
            elseif state then self:Drop(state, "Death") else self:Remove(egg) end
        elseif now >= egg.Expires then self:Remove(egg) end
    end
end
return EggSystem
