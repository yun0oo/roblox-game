--!nonstrict
local HarpoonSystem = {}
HarpoonSystem.__index = HarpoonSystem
function HarpoonSystem.new(context) return setmetatable({ Ctx = context, Projectiles = {} }, HarpoonSystem) end

function HarpoonSystem:Fire(state, direction)
    local ctx = self.Ctx
    if typeof(direction) ~= "Vector3" or not ctx.Rules.IsFinite(direction.X) or not ctx.Rules.IsFinite(direction.Y)
        or not ctx.Rules.IsFinite(direction.Z) or direction.Magnitude < 0.5 or direction.Magnitude > 2 then return end
    if not ctx:Validate(state) then return end
    local root = ctx:Root(state)
    local spec = ctx.Config.Harpoons[state.Profile.Equipment.Harpoon]
    if not root or not spec or not state.Tool or state.Tool.Parent ~= state.Player.Character then return end
    if ctx.World:SafeBase(root.Position) then ctx:Notify(state.Player, "Le harpon est désactivé dans les habitats.", "Warning"); return end
    if os.clock() < (state.NextShot or 0) then return end
    state.NextShot = os.clock() + spec.Cooldown
    direction = direction.Unit
    local part = ctx.Visuals.HarpoonProjectile(ctx.World.Events, CFrame.lookAt(root.Position, root.Position + direction))
    local endpoint = Instance.new("Attachment"); endpoint.Parent = part
    local start = state.Tool.Handle:FindFirstChild("RopeOrigin")
    local beam = Instance.new("Beam"); beam.Attachment0 = start; beam.Attachment1 = endpoint
    beam.Width0 = 0.06; beam.Width1 = 0.04; beam.Color = ColorSequence.new(Color3.fromRGB(154, 216, 208)); beam.FaceCamera = true; beam.Parent = part
    table.insert(self.Projectiles, { Part = part, Direction = direction, Position = root.Position, Traveled = 0, Spec = spec,
        Damage = spec.Damage * (1 + state.Profile.Prestige * 0.05), Shooter = state })
    ctx.FX:FireAllClients("Shot", { Position = root.Position, UserId = state.Player.UserId })
end

local function crossesSafe(world, a, b)
    local protected = world:SegmentProtected(a, b)
    if protected ~= nil then return protected end
    local delta = b - a
    for _, base in ipairs(world.Bases) do
        local t = math.clamp((base.Center - a):Dot(delta) / math.max(delta:Dot(delta), 0.001), 0, 1)
        if (a + delta * t - base.Center).Magnitude <= world.Config.BaseRadius then return true end
    end
    return false
end

function HarpoonSystem:Step(dt)
    local ctx = self.Ctx
    for index = #self.Projectiles, 1, -1 do
        local shot = self.Projectiles[index]
        local distance = math.min(shot.Spec.Speed * dt, shot.Spec.Range - shot.Traveled)
        local nextPos = shot.Position + shot.Direction * distance
        local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { shot.Shooter.Player.Character, ctx.World.Eggs, ctx.World.Events }; params.IgnoreWater = true
        local result = workspace:Raycast(shot.Position, shot.Direction * distance, params)
        local finish = result and result.Position or nextPos
        local safe = crossesSafe(ctx.World, shot.Position, finish)
        local remove = safe or result ~= nil or shot.Traveled + distance >= shot.Spec.Range
        if result and not safe then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            if model and ctx.Guardians.Active[model] then
                ctx.Guardians:Damage(model, shot.Damage or shot.Spec.Damage, shot.Shooter.Player)
                ctx.FX:FireAllClients("Impact", { Position = result.Position })
            else
                local player = model and game:GetService("Players"):GetPlayerFromCharacter(model)
                local target = player and ctx.States[player]
                local targetRoot = target and ctx:Root(target)
                if targetRoot and ctx:Validate(target) then
                    local egg = target.Carrying and ctx.Eggs.Eggs[target.Carrying]
                    local allowed = ctx.Rules.CanIntercept({ HasHarpoon = shot.Shooter.Profile.Equipment.Harpoon >= 1,
                        CooldownReady = true, InRange = shot.Traveled + (result.Position - shot.Position).Magnitude <= shot.Spec.Range + 0.01,
                        Collision = true, ShooterSafe = ctx.World:SafeBase(shot.Shooter.LastPosition) ~= nil,
                        TargetSafe = ctx.World:SafeBase(targetRoot.Position) ~= nil, Carrying = egg ~= nil,
                        Secured = egg and egg.State == "Secured" })
                    if allowed and ctx.Eggs:Drop(target, "Harpoon") then
                        shot.Shooter.Profile.Stats.Hits += 1
                        ctx:Broadcast("🔱 " .. shot.Shooter.Player.DisplayName .. " a touché " .. player.DisplayName .. " !\n🥚 L'œuf est tombé !", "Warning")
                        ctx.FX:FireAllClients("Impact", { Position = result.Position })
                    end
                end
            end
        end
        shot.Position = finish; shot.Traveled += distance
        shot.Part.CFrame = CFrame.lookAt(finish, finish + shot.Direction)
        if remove then shot.Part:Destroy(); table.remove(self.Projectiles, index) end
    end
end
return HarpoonSystem
