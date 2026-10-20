--!nonstrict
-- Report a boot failure to the client instead of leaving an empty scene.
workspace:SetAttribute("UnderwaterBootState", "Loading")
workspace:SetAttribute("UnderwaterBootMessage", "Chargement du jeu…")
local function start()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local Modules = ReplicatedStorage:WaitForChild("Modules")
    local Config = require(Modules.Config)
    local Rules = require(Modules.Rules)
    local Visuals = require(Modules.Visuals)
    local DataSystem = require(script.Parent.DataSystem)
    local World = require(script.Parent.World)
    local EggSystem = require(script.Parent.EggSystem)
    local GuardianSystem = require(script.Parent.GuardianSystem)
    local HarpoonSystem = require(script.Parent.HarpoonSystem)
    local EventSystem = require(script.Parent.EventSystem)
    local FusionData = require(script.Parent.FusionData)

    -- Keep Roblox's normal avatar spawning and respawning, including while the
    -- procedural ocean loads. A static SpawnLocation is bundled in the place.
    Players.CharacterAutoLoads = true
    local remotes = Instance.new("Folder"); remotes.Name = "RemoteEvents"; remotes.Parent = ReplicatedStorage
    local function remote(name)
        local value = Instance.new("RemoteEvent"); value.Name = name; value.Parent = remotes; return value
    end
    local ctx = { Config = Config, Rules = Rules, Visuals = Visuals, Random = Random.new(), States = {},
        Action = remote("Action"), Snapshot = remote("Snapshot"), Notice = remote("Notice"), FX = remote("FX"), ShuttingDown = false }
    ctx.Data = DataSystem.new(Config, Rules)
    workspace:SetAttribute("UnderwaterBootMessage", "Création de l'océan…")
    ctx.World = World.Build(Config, Visuals)

    function ctx:Notify(player, message, tone)
        if player.Parent == Players then self.Notice:FireClient(player, message, tone or "Common") end
    end
    function ctx:Broadcast(message, tone) self.Notice:FireAllClients(message, tone or "Common") end
    function ctx:Root(state)
        local character = state.Player.Character
        if not character then return nil end
        local root, humanoid = character:FindFirstChild("HumanoidRootPart"), character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then return nil end
        return root, humanoid
    end
    function ctx:Speed(state)
        local speed = Rules.SwimSpeed(state.Profile)
        if os.clock() < (state.BoostUntil or 0) then speed += 12 + state.Profile.Equipment.Thruster * 2 end
        local egg = state.Carrying and self.Eggs.Eggs[state.Carrying]
        if egg then speed *= Config.Rarities[egg.Rarity].Slow end
        if os.clock() < (state.SlowUntil or 0) then speed *= 0.6 end
        return speed
    end
    function ctx:Current(state)
        if not self.Event or self.World:SafeBase(state.LastPosition) then return Vector3.zero end
        local strength = Config.Events[self.Event.Key].Current * (0.8 + state.Floor * 0.2)
        return Vector3.new(math.cos(os.clock() * 0.08) * strength, 0, math.sin(os.clock() * 0.08) * strength)
    end
    function ctx:Teleport(state, position)
        local root = self:Root(state)
        if root then root.CFrame = CFrame.new(position); root.AssemblyLinearVelocity = Vector3.zero end
        state.LastPosition = position; state.LastMove = os.clock(); state.MoveCredit = 16
    end
    function ctx:Validate(state)
        if self.ShuttingDown or self.Data:IsClosing(state.Player) then return false end
        local root = self:Root(state)
        if not root then return false end
        local position, now = root.Position, os.clock()
        local dt = math.clamp(now - state.LastMove, 0, 0.8)
        state.LastMove = now
        local maxSpeed = self:Speed(state) + self:Current(state).Magnitude
        state.MoveCredit = math.min(32, state.MoveCredit + (maxSpeed * 1.25 + 2) * dt)
        local finite = Rules.IsFinite(position.X) and Rules.IsFinite(position.Y) and Rules.IsFinite(position.Z)
        local distance = finite and (position - state.LastPosition).Magnitude or math.huge
        if distance > state.MoveCredit then
            root.CFrame = CFrame.new(state.LastPosition); root.AssemblyLinearVelocity = Vector3.zero
            return false
        end
        state.MoveCredit -= distance
        local bottom = Config.Floors[Config.ActiveFloors].Bottom + 3
        if math.abs(position.X) > Config.Bounds or math.abs(position.Z) > Config.Bounds or position.Y > Config.SurfaceCeiling or position.Y < bottom then
            self:Teleport(state, Vector3.new(math.clamp(position.X, -420, 420), math.clamp(position.Y, bottom + 6, Config.SurfaceCeiling - 5), math.clamp(position.Z, -420, 420)))
            return false
        end
        local floor = Rules.FloorAt(Config, position.Y)
        if not Rules.IsPrepared(state.Profile, floor) and now > (state.NextGateWarning or 0) then
            state.NextGateWarning = now + 15
            self:Notify(state.Player, "⚠ PROFONDEUR DANGEREUSE\nCombinaison " .. floor.MinLevel .. " conseillée : les gardiens vous rattraperont !", "Warning")
        end
        state.LastPosition = position; state.Floor = floor.Id
        return true
    end

    ctx.Guardians = GuardianSystem.new(ctx)
    ctx.Eggs = EggSystem.new(ctx)
    ctx.Harpoons = HarpoonSystem.new(ctx)
    ctx.Events = EventSystem.new(ctx)

    local function equipTool(state, character)
        local tool = Instance.new("Tool")
        tool.Name = "Harpon"; tool.ToolTip = "Viser et tirer • les habitats sont protégés"
        tool.CanBeDropped = false; tool.RequiresHandle = true
        tool.Grip = CFrame.new(0, -0.35, 0.3)
        Visuals.Harpoon(tool, state.Profile.Equipment.Harpoon)
        tool.Parent = state.Player:WaitForChild("Backpack")
        state.Tool = tool
        character:FindFirstChildOfClass("Humanoid"):EquipTool(tool)
    end

    local function makeSnapshot(state)
        local profile = state.Profile
        local egg = state.Carrying and ctx.Eggs.Eggs[state.Carrying]
        local safe = ctx.World:SafeBase(state.LastPosition)
        local ranks = {}
        for _, other in pairs(ctx.States) do
            local rare, fusions = 0, 0
            for id, spec in pairs(Config.Animals) do if Config.Rarities[spec.Rarity].Power >= 1.9 then rare += Rules.SpeciesCount(other.Profile, id) end end
            for _ in pairs(other.Profile.Recipes) do fusions += 1 end
            table.insert(ranks, { Name = other.Player.DisplayName, UserId = other.Player.UserId, Money = math.floor(other.Profile.Money),
                Income = Rules.Income(other.Profile, Config), Steals = other.Profile.Stats.Steals, Depth = other.Profile.MaxDepth,
                Animals = Rules.AnimalCount(other.Profile), Rare = rare, Fusions = fusions,
                Value = Rules.Income(other.Profile, Config) / (1 + other.Profile.Prestige * 0.25) * 60 })
        end
        local recipes = Rules.VisibleRecipes(FusionData, profile.Recipes)
        local current = ctx:Current(state)
        local speed = ctx:Speed(state)
        state.Player:SetAttribute("SwimSpeed", speed)
        state.Player:SetAttribute("LampLevel", profile.Equipment.Lamp)
        state.Player:SetAttribute("CurrentX", current.X); state.Player:SetAttribute("CurrentZ", current.Z)
        return { Money = math.floor(profile.Money), Gold = math.floor(profile.Money), ServerTime = os.time(), Income = Rules.Income(profile, Config), Oxygen = state.Oxygen,
            MaxOxygen = Rules.MaxOxygen(profile), Health = select(2, ctx:Root(state)) and select(2, ctx:Root(state)).Health or 0,
            Depth = math.max(0, math.floor(Config.WaterTop - state.LastPosition.Y)), Floor = state.Floor,
            Equipment = profile.Equipment, Animals = profile.Animals, Discovered = profile.Discovered, Eggs = profile.Eggs,
            Variants = profile.Variants, Prestige = profile.Prestige, PrestigeCost = Rules.PrestigeCost(profile), Recipes = recipes,
            OwnedDecor = profile.OwnedDecor, Palette = profile.Palette,
            XP = profile.XP, Level = 1 + math.floor(math.sqrt(profile.XP / 30)), MaxDepth = profile.MaxDepth, Stats = profile.Stats,
            Carrying = egg and { Name = egg.Name, Rarity = egg.Rarity }, Safe = safe ~= nil,
            OwnBase = safe ~= nil and safe.OwnerId == state.Player.UserId, BasePosition = state.Base.Center,
            ShotRemaining = math.max(0, (state.NextShot or 0) - os.clock()), BoostRemaining = math.max(0, (state.NextBoost or 0) - os.clock()),
            Offline = state.Offline, SaveStatus = state.SaveStatus, Event = ctx.Events:Snapshot(), Rankings = ranks }
    end

    local function onCharacter(state, character)
        if state.Character == character then return end
        state.Character = character
        local root = character:WaitForChild("HumanoidRootPart", 12)
        local humanoid = character:WaitForChild("Humanoid", 12)
        if not root or not humanoid or ctx.States[state.Player] ~= state or state.Player.Character ~= character then return end
        ctx:Teleport(state, state.Base.Spawn)
        state.Oxygen = Rules.MaxOxygen(state.Profile)
        humanoid.WalkSpeed = Rules.SwimSpeed(state.Profile)
        humanoid.JumpPower = 50
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        humanoid.Died:Connect(function()
            ctx.Eggs:Drop(state, "Death")
        end)
        equipTool(state, character)
        ctx.World:RefreshAnimals(state)
        ctx.World:RefreshIncubators(state)
        character:SetAttribute("UnderwaterReady", true)
        ctx.Snapshot:FireClient(state.Player, makeSnapshot(state))
    end

    local loading = {}
    local function onPlayer(player)
        if loading[player] or ctx.States[player] then return end
        loading[player] = true
        local profile, reason, offline = ctx.Data:Load(player)
        if not player.Parent then if profile then ctx.Data:Save(player, true) end; loading[player] = nil; return end
        if not profile then player:Kick(reason); loading[player] = nil; return end
        local base = ctx.World:AssignBase(player)
        if not base then ctx.Data:Save(player, true); player:Kick("Les huit habitats sont occupés. Rejoignez un autre serveur."); return end
        local state = { Player = player, Profile = profile, Base = base, Oxygen = Rules.MaxOxygen(profile), Floor = 1,
            LastPosition = base.Center, LastMove = os.clock(), MoveCredit = 20, Offline = offline,
            SaveStatus = offline and "STUDIO · NON SAUVEGARDÉ" or "Sauvegarde active", Tokens = 18, TokenTime = os.clock() }
        ctx.States[player] = state; loading[player] = nil
        local leaderstats = Instance.new("Folder"); leaderstats.Name = "leaderstats"; leaderstats.Parent = player
        for _, key in ipairs({ "Gold", "Animaux", "Profondeur" }) do local value = Instance.new("IntValue"); value.Name = key; value.Parent = leaderstats end
        player.CharacterAdded:Connect(function(character) onCharacter(state, character) end)
        -- The automatic avatar may already exist by the time the world/profile loads.
        if player.Character then task.spawn(onCharacter, state, player.Character) end
        ctx:Notify(player, "Bienvenue sur votre île !\nTrouvez un œuf, évitez son gardien, puis déposez-le dans votre aquarium en surface.", "Success")
        if offline then ctx:Notify(player, "MODE STUDIO HORS LIGNE\nDataStore indisponible : cette session ne sera pas sauvegardée.", "Warning") end
    end

    for _, base in ipairs(ctx.World.Bases) do
        base.HatchPrompt.Triggered:Connect(function(player)
            local state = ctx.States[player]
            if state and base.OwnerId == player.UserId and ctx:Validate(state) and (state.LastPosition - base.Core.Position).Magnitude <= 13 then
                local egg
                for _, stored in ipairs(state.Profile.Eggs) do if not stored.ReadyAt then egg = stored; break end end
                if egg then ctx.Eggs:Hatch(state, egg.Id) else ctx:Notify(player, "Rapportez un œuf ou consultez les incubations dans votre aquarium.") end
            end
        end)
        base.UpgradePrompt.Triggered:Connect(function(player)
            local state = ctx.States[player]
            if state and base.OwnerId == player.UserId and ctx:Validate(state) and (state.LastPosition - base.Bench.Position).Magnitude <= 13 then ctx.FX:FireClient(player, "OpenUpgrades", {}) end
        end)
    end

    ctx.Action.OnServerEvent:Connect(function(player, action, payload)
        local state = ctx.States[player]
        if not state or type(action) ~= "string" or #action > 24 or ctx.ShuttingDown or ctx.Data:IsClosing(player) then return end
        local now = os.clock()
        state.Tokens = math.min(18, state.Tokens + (now - state.TokenTime) * 10); state.TokenTime = now
        if state.Tokens < 1 then return end
        state.Tokens -= 1
        if action == "Fire" then ctx.Harpoons:Fire(state, payload)
        elseif action == "Hatch" then
            if now < (state.NextHatch or 0) then return end
            state.NextHatch = now + 0.8; ctx.Eggs:Hatch(state, payload)
        elseif action == "Upgrade" then
            if not ctx:Validate(state) then return end
            local base = ctx.World:SafeBase(state.LastPosition)
            if not base or base.OwnerId ~= player.UserId then ctx:Notify(player, "Les améliorations s'achètent dans votre habitat.", "Warning"); return end
            local success, message = Rules.PurchaseUpgrade(state.Profile, Config, payload)
            if success then state.Oxygen = math.min(Rules.MaxOxygen(state.Profile), state.Oxygen + 18) end
            ctx:Notify(player, message, success and "Success" or "Warning")
        elseif action == "Fuse" or action == "Prestige" or action == "Decorate" then
            if not ctx:Validate(state) then return end
            local base = ctx.World:SafeBase(state.LastPosition)
            if not base or base.OwnerId ~= player.UserId then ctx:Notify(player, "Cette action nécessite votre habitat.", "Warning"); return end
            if action == "Fuse" then
                if now < (state.NextFusion or 0) then return end
                state.NextFusion = now + 0.8
                local result, message = Rules.Fuse(state.Profile, Config, FusionData, payload)
                if not result then ctx:Notify(player, message, "Warning"); return end
                ctx.World:RefreshAnimals(state)
                ctx.FX:FireClient(player, "Hatch", { AnimalId = result.AnimalId, Grade = result.Grade, Position = base.Core.Position + Vector3.new(0, 7, 0) })
                if result.Secret then ctx:Broadcast("🚨 " .. player.DisplayName .. " A DÉCOUVERT UNE FUSION SECRÈTE !", "Secret")
                else ctx:Notify(player, "🧬 FUSION RÉUSSIE !", "Success") end
            elseif action == "Prestige" then
                if state.Carrying then ctx:Notify(player, "Sécurisez d'abord votre œuf.", "Warning"); return end
                local success, message = Rules.Rebirth(state.Profile, Config)
                if success then
                    state.Oxygen = Rules.MaxOxygen(state.Profile)
                    ctx.World:RefreshAnimals(state); ctx.World:RefreshIncubators(state)
                end
                ctx:Notify(player, message, success and "Success" or "Warning")
            else
                local success, message = Rules.Decorate(state.Profile, Config, payload)
                if success then ctx.World:ApplyCustomization(state) end
                ctx:Notify(player, message, success and "Success" or "Warning")
            end
        elseif action == "Boost" then
            if not ctx:Validate(state) or now < (state.NextBoost or 0) then return end
            state.NextBoost = now + 7; state.BoostUntil = now + 1.4
        elseif action == "Drop" then
            if ctx:Validate(state) then ctx.Eggs:Drop(state, "Manual") end
        elseif action == "Return" then
            if not ctx:Validate(state) then return end
            if state.Carrying then ctx:Notify(player, "Le retour rapide est interdit avec un œuf !", "Warning"); return end
            if state.Returning then return end
            state.Returning = true
            ctx:Notify(player, "Retour à l'habitat dans 4 secondes. Aucun œuf ne peut voyager avec vous.")
            task.delay(4, function()
                state.Returning = false
                if ctx.States[player] == state and not state.Carrying and ctx:Root(state) then ctx:Teleport(state, state.Base.Spawn) end
            end)
        elseif action == "Sync" then ctx.Snapshot:FireClient(player, makeSnapshot(state)) end
    end)

    local accumulator, snapshots = 0, 0
    RunService.Heartbeat:Connect(function(dt)
        if ctx.ShuttingDown then return end
        -- Swept collision runs each physics frame, including at low frame rates.
        ctx.Harpoons:Step(dt)
        accumulator += dt; snapshots += dt
        if accumulator < 0.12 then return end
        local step = math.min(accumulator, 0.5); accumulator = 0
        ctx.Events:Step()
        for _, state in pairs(ctx.States) do
            if ctx:Validate(state) then
                local root, humanoid = ctx:Root(state)
                local floor = Config.Floors[state.Floor]
                local station = root.Position.Y >= Config.WaterTop - 2 or ctx.World:AtStation(root.Position)
                if station then state.Oxygen = math.min(Rules.MaxOxygen(state.Profile), state.Oxygen + step * 35)
                else state.Oxygen = math.max(0, state.Oxygen - floor.OxygenDrain * Rules.PressureMultiplier(state.Profile) * step) end
                if state.Oxygen <= 0 then humanoid:TakeDamage(step * 9) end
                if state.Oxygen / Rules.MaxOxygen(state.Profile) < 0.2 and os.clock() > (state.NextOxygenWarning or 0) then
                    state.NextOxygenWarning = os.clock() + 15; ctx:Notify(state.Player, "⚠ OXYGÈNE FAIBLE\nRejoignez une station O₂ ou un habitat !", "Warning")
                end
                state.Profile.MaxDepth = math.max(state.Profile.MaxDepth, math.max(0, math.floor(Config.WaterTop - root.Position.Y)))
                state.Player:SetAttribute("SwimSpeed", ctx:Speed(state))
                humanoid.WalkSpeed = ctx:Speed(state)
            end
            if not ctx.Data:IsClosing(state.Player) then
                state.Profile.Money = math.min(Config.MaxMoney, state.Profile.Money + Rules.Income(state.Profile, Config) / 60 * step)
            end
        end
        ctx.Eggs:Step()
        ctx.Guardians:Step(step)
        if snapshots >= Config.SnapshotInterval then
            snapshots = 0
            ctx.World:StepAquariums(os.clock())
            for _, state in pairs(ctx.States) do
                ctx.Snapshot:FireClient(state.Player, makeSnapshot(state))
                local stats = state.Player:FindFirstChild("leaderstats")
                if stats then stats.Gold.Value = math.floor(state.Profile.Money); stats.Animaux.Value = Rules.AnimalCount(state.Profile); stats.Profondeur.Value = state.Profile.MaxDepth end
            end
        end
    end)

    -- Populate six independently randomized, individually guarded eggs per active floor.
    workspace:SetAttribute("UnderwaterBootMessage", "Apparition des œufs et des gardiens…")
    for _ = 1, Config.EggsPerFloor do for _, floor in ipairs(Config.Floors) do ctx.Eggs:Spawn(floor) end end
    Players.PlayerAdded:Connect(onPlayer)
    for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, player) end

    local function removePlayer(player)
        local state = ctx.States[player]
        if not state then return end
        ctx.Eggs:Drop(state, "Disconnect")
        ctx.States[player] = nil
        state.Base.OwnerId = 0; state.Base.Model:SetAttribute("OwnerId", 0)
        state.Base.Label.Text = "ÎLE DISPONIBLE\nAQUARIUM GÉANT · ZONE SÉCURISÉE"; state.Base.Display:ClearAllChildren()
        state.Base.EggDisplay:ClearAllChildren(); state.Base.Incubators = {}; state.Base.Swimmers = {}
        local custom = state.Base.Model:FindFirstChild("Personnalisation"); if custom then custom:Destroy() end
        ctx.Data:Save(player, true)
    end
    Players.PlayerRemoving:Connect(removePlayer)
    task.spawn(function()
        while not ctx.ShuttingDown do
            task.wait(Config.AutosaveInterval)
            for player, state in pairs(ctx.States) do
                task.spawn(function()
                    if ctx.Data:IsClosing(player) then return end
                    local ok = ctx.Data:Save(player, false)
                    state.SaveStatus = state.Offline and "STUDIO · NON SAUVEGARDÉ" or (ok and "Sauvegardé" or "Sauvegarde en attente")
                    if not ok then ctx:Notify(player, "Sauvegarde temporairement indisponible. Nouvelle tentative automatique.", "Warning") end
                end)
            end
        end
    end)
    game:BindToClose(function()
        ctx.ShuttingDown = true
        local pending = 0
        for player in pairs(ctx.States) do
            pending += 1
            task.spawn(function() removePlayer(player); pending -= 1 end)
        end
        local deadline = os.clock() + 25
        repeat task.wait(0.1) until pending == 0 or os.clock() >= deadline
    end)
end
local ok, reason = xpcall(start, debug.traceback)
if ok then
    workspace:SetAttribute("UnderwaterBootState", "Ready")
    workspace:SetAttribute("UnderwaterBootMessage", "Océan prêt")
else
    workspace:SetAttribute("UnderwaterBootState", "Failed")
    workspace:SetAttribute("UnderwaterBootMessage", "Le serveur n'a pas pu démarrer. Voir Sortie / Output dans Studio.")
    warn("[Underwater Egg] Démarrage interrompu:\n" .. tostring(reason))
end
