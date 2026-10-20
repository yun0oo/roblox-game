--!nonstrict
local GuardianSystem = {}
GuardianSystem.__index = GuardianSystem
function GuardianSystem.new(context)
    return setmetatable({ Ctx = context, Active = {}, ByFloor = {}, RespawnAt = {} }, GuardianSystem)
end

function GuardianSystem:Spawn(egg, floor)
    local existing = self.ByFloor[floor.Id]
    if existing then return existing end
    if os.clock() < (self.RespawnAt[floor.Id] or 0) then return nil end
    local ctx = self.Ctx
    local home = Vector3.new(0, floor.Bottom + 85, 0)
    local points = ctx.World.Spawns[floor.Id] or {}
    if #points > 0 then
        home = Vector3.zero
        for _, point in ipairs(points) do home += point.Position end
        home /= #points
        home += Vector3.new(0, 22, 0)
    elseif egg then home = egg.Home + Vector3.new(20, 3, 0) end
    local model = ctx.Visuals.Animal(ctx.World.Guardians,
        { Name = floor.BossName, Style = floor.BossStyle, Color = floor.Color },
        CFrame.new(home), floor.GuardianSize, floor.BossName)
    model.PrimaryPart.CanQuery = true
    if floor.BossStyle == "q_anglerfish" then
        local glow = Instance.new("PointLight"); glow.Color = Color3.fromRGB(73, 234, 255); glow.Brightness = 1.4; glow.Range = 45; glow.Parent = model.PrimaryPart
    end
    model:SetAttribute("Guardian", true); model:SetAttribute("FloorId", floor.Id)
    model:SetAttribute("MythicSkin", floor.BossStyle); model:SetAttribute("BaseSpeed", floor.GuardianSpeed)
    local record = { Model = model, Home = home, Floor = floor, Health = floor.BossHealth,
        MaxHealth = floor.BossHealth, Power = 1 + (floor.Id - 1) * 0.1, LastAttack = 0, Phase = ctx.Random:NextNumber(0, 6),
        NextAbility = os.clock() + 8, Ability = floor.Ability }
    self.Active[model] = record; self.ByFloor[floor.Id] = record
    self:UpdateLabel(record)
    return record
end

function GuardianSystem:UpdateLabel(record)
    record.Model:SetAttribute("Health", record.Health)
    local gui = record.Model.PrimaryPart:FindFirstChild("Label")
    if gui then gui.MaxDistance = 450; gui.TextLabel.Text = record.Model.Name .. "\n" .. "BOSS DE ZONE · " .. math.ceil(record.Health) .. " / " .. math.ceil(record.MaxHealth) .. " PV" end
end

function GuardianSystem:Remove(record)
    self.Active[record.Model] = nil
    record.Model:Destroy()
    self.ByFloor[record.Floor.Id] = nil
    self.RespawnAt[record.Floor.Id] = os.clock() + record.Floor.BossRespawn
end

function GuardianSystem:Damage(model, amount, player)
    local record = self.Active[model]
    if not record then return end
    record.Health -= amount
    if record.Health <= 0 then
        self:Remove(record)
        self.Ctx:Notify(player, "👹 Gardien vaincu ! La voie est libre.", "Success")
    else self:UpdateLabel(record) end
end

function GuardianSystem:Step(dt)
    local ctx = self.Ctx
    for _, floor in ipairs(ctx.Config.Floors) do
        if floor.Id <= ctx.Config.ActiveFloors then self:Spawn(nil, floor) end
    end
    for _, record in pairs(self.Active) do
        local model = record.Model
        local position = model:GetPivot().Position
        local home = record.Home
        local target, nearest = nil, math.huge
        for _, state in pairs(ctx.States) do
            local root, humanoid = ctx:Root(state)
            if root and humanoid.Health > 0 and not ctx.World:SafeBase(root.Position) and root.Position.Y <= record.Floor.Top and root.Position.Y > record.Floor.Bottom then
                local distance = (position - root.Position).Magnitude
                if distance < nearest then nearest = distance; target = state end
            end
        end
        record.Target = target
        local root = target and ctx:Root(target)
        local goal = root and root.Position or home + Vector3.new(math.cos(os.clock() * 0.16 + record.Phase) * 115, 12, math.sin(os.clock() * 0.16 + record.Phase) * 115)
        local delta = goal - position
        local strength = ctx.Event and ctx.Config.Events[ctx.Event.Key].Strength or 1
        local rageSpeed, rageDamage = 1, 1
        if target then rageSpeed, rageDamage = ctx.Rules.GuardianThreat(target.Profile, record.Floor, ctx.Config) end
        local chaseSpeed = record.Floor.GuardianSpeed * (1 + (record.Power - 1) * 0.08) * strength * rageSpeed
        model:SetAttribute("ChaseSpeed", chaseSpeed)
        if delta.Magnitude > 0.5 then
            local travel = delta.Unit * math.min(delta.Magnitude, chaseSpeed * dt)
            local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { ctx.World.Guardians, ctx.World.Eggs }; params.IgnoreWater = true
            local obstacle = workspace:Raycast(position, travel.Unit * (travel.Magnitude + 5), params)
            if obstacle and not (root and obstacle.Instance:IsDescendantOf(target.Player.Character)) then travel = Vector3.new(0, math.min(9 * dt, 2), 0) end
            local nextPosition = position + travel
            nextPosition = Vector3.new(nextPosition.X, math.clamp(nextPosition.Y, record.Floor.Bottom + 12, record.Floor.Top - 15), nextPosition.Z)
            if not ctx.World:SafeBase(nextPosition) then model:PivotTo(CFrame.lookAt(nextPosition, nextPosition + delta.Unit)) end
        end
        if root and nearest < record.Floor.AttackRange and os.clock() - record.LastAttack > record.Floor.AttackCooldown then
            record.LastAttack = os.clock()
            local _, humanoid = ctx:Root(target)
            if humanoid and not ctx.World:SafeBase(root.Position) then
                humanoid:TakeDamage(record.Floor.GuardianDamage * record.Power * strength * rageDamage * ctx.Rules.DamageMultiplier(target.Profile))
                ctx.FX:FireClient(target.Player, "Damage", {})
            end
        end
        if record.Ability and root and os.clock() >= record.NextAbility and not record.Telegraph then
            record.Telegraph = os.clock() + 1.2
            ctx.FX:FireAllClients("BossWarning", { Position = position, Radius = record.Floor.AttackRange * 1.8, Ability = record.Ability })
        end
        if record.Telegraph and os.clock() >= record.Telegraph then
            record.Telegraph = nil; record.NextAbility = os.clock() + 8
            for _, state in pairs(ctx.States) do
                local victim, humanoid = ctx:Root(state)
                if victim and (victim.Position - position).Magnitude < record.Floor.AttackRange * 1.8 and not ctx.World:SafeBase(victim.Position) then
                    local _, threatDamage = ctx.Rules.GuardianThreat(state.Profile, record.Floor, ctx.Config)
                    if record.Ability == "Siphon" then state.Oxygen = math.max(0, state.Oxygen - 22 * threatDamage)
                    elseif record.Ability == "Vortex" then state.SlowUntil = os.clock() + 3
                    else humanoid:TakeDamage(record.Floor.GuardianDamage * strength * threatDamage * ctx.Rules.DamageMultiplier(state.Profile)) end
                    ctx.FX:FireClient(state.Player, "Damage", {})
                end
            end
        end
    end
end
return GuardianSystem
