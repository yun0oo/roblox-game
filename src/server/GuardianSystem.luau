--!nonstrict
local GuardianSystem = {}
GuardianSystem.__index = GuardianSystem
function GuardianSystem.new(context) return setmetatable({ Ctx = context, Active = {} }, GuardianSystem) end

function GuardianSystem:Spawn(egg, floor)
    local ctx = self.Ctx
    local index = ctx.Random:NextInteger(1, #floor.Guardians)
    local name, style = floor.Guardians[index], floor.GuardianSkins[index]
    local power = ctx.Config.Rarities[egg.Rarity].Power
    local model = ctx.Visuals.Animal(ctx.World.Guardians, { Name = name, Style = style, Color = floor.Color },
        CFrame.new(egg.Home + Vector3.new(20, 3, 0)), floor.GuardianSize * (1 + power * 0.08), name)
    model.PrimaryPart.CanQuery = true
    model:SetAttribute("Guardian", true)
    model:SetAttribute("MythicSkin", style)
    model:SetAttribute("BaseSpeed", floor.GuardianSpeed)
    local record = { Model = model, Egg = egg, Floor = floor, Health = floor.GuardianHealth * power,
        MaxHealth = floor.GuardianHealth * power, Power = power, LastAttack = 0, Phase = ctx.Random:NextNumber(0, 6),
        NextAbility = os.clock() + 8, Ability = floor.Ability or (egg.Rarity == "Secret" and "Shock" or nil) }
    self.Active[model] = record
    self:UpdateLabel(record)
    return record
end

function GuardianSystem:UpdateLabel(record)
    record.Model:SetAttribute("Health", record.Health)
    local gui = record.Model.PrimaryPart:FindFirstChild("Label")
    if gui then gui.TextLabel.Text = record.Model.Name .. "\n" .. (record.Ability and "BOSS · " or "👹 ") .. math.ceil(record.Health) .. " / " .. math.ceil(record.MaxHealth) .. " PV" end
end

function GuardianSystem:Remove(record)
    self.Active[record.Model] = nil
    record.Model:Destroy()
    if record.Egg then record.Egg.Guardian = nil end
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
    for _, record in pairs(self.Active) do
        local model = record.Model
        local position = model:GetPivot().Position
        local egg = record.Egg
        local home = egg.State == "Dropped" and egg.Part.Position or egg.Home
        local target, nearest = nil, record.Floor.Detection
        for _, state in pairs(ctx.States) do
            local root, humanoid = ctx:Root(state)
            local detecting = state == record.Target and record.Floor.ChaseRadius or record.Floor.Detection
            if root and humanoid.Health > 0 and not ctx.World:SafeBase(root.Position) and (root.Position - home).Magnitude < record.Floor.ChaseRadius then
                local distance = (position - root.Position).Magnitude
                if distance < detecting and (not target or distance < nearest) then nearest = distance; target = state end
            end
        end
        record.Target = target
        local root = target and ctx:Root(target)
        local goal = root and root.Position or home + Vector3.new(math.cos(os.clock() * 0.5 + record.Phase) * 13, 4, math.sin(os.clock() * 0.5 + record.Phase) * 13)
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
            ctx.FX:FireAllClients("BossWarning", { Position = position, Radius = 30, Ability = record.Ability })
        end
        if record.Telegraph and os.clock() >= record.Telegraph then
            record.Telegraph = nil; record.NextAbility = os.clock() + 8
            for _, state in pairs(ctx.States) do
                local victim, humanoid = ctx:Root(state)
                if victim and (victim.Position - position).Magnitude < 30 and not ctx.World:SafeBase(victim.Position) then
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
