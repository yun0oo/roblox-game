--!nonstrict
-- The check runner inserts the unchanged server module sources at MODULES below.
-- Engine primitives are small deterministic fakes, not a Roblox multiplayer simulation.
local Config = require("../src/shared/Config")
local Rules = require("../src/shared/Rules")
local clock = 10
local os = { clock = function() return clock end, time = function() return 1700000000 + math.floor(clock) end }
local passed = 0
local function check(condition, message) assert(condition, message); passed += 1 end
local V = {}
local vectorMeta = {}
function V.new(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vectorMeta) end
vectorMeta.__add = function(a, b) return V.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
vectorMeta.__sub = function(a, b) return V.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
vectorMeta.__mul = function(a, b) if type(a) == "number" then a, b = b, a end; return V.new(a.X * b, a.Y * b, a.Z * b) end
vectorMeta.__div = function(a, b) return a * (1 / b) end
vectorMeta.__index = function(a, key)
    if key == "Magnitude" then return math.sqrt(a.X ^ 2 + a.Y ^ 2 + a.Z ^ 2) end
    if key == "Unit" then return a.Magnitude > 0 and a / a.Magnitude or V.new() end
    if key == "Dot" then return function(b, c) return b.X * c.X + b.Y * c.Y + b.Z * c.Z end end
end
local Vector3 = { new = V.new, zero = V.new(), xAxis = V.new(1, 0, 0) }
local frameMeta = {}
local CFrame = {}
function CFrame.new(pos, y, z) return setmetatable({ Position = type(pos) == "table" and pos or V.new(pos, y, z) }, frameMeta) end
CFrame.lookAt = CFrame.new
frameMeta.__mul = function(a, b) return CFrame.new(a.Position + b.Position) end
local Color3 = { fromRGB = function() return {} end }
local ColorSequence = { new = function() return {} end }
local RaycastParams = { new = function() return {} end }
local Enum = { RaycastFilterType = { Exclude = 1 }, Material = { Neon = 1 }, HighlightDepthMode = { Occluded = 1 }, DataStoreRequestType = { UpdateAsync = 1 } }
local Instance = { new = function() return { Triggered = { Connect = function() end }, Destroy = function(self) self.Destroyed = true end } end }
local function typeof(value) return getmetatable(value) == vectorMeta and "Vector3" or type(value) end
local function warn(...) end
local task = { wait = function() return 0 end }
local hitResult, studio, guid, rejectStore, getStoreCalls = nil, false, 0, false, 0
local store = { Value = nil, Fail = false, Calls = 0 }
function store:UpdateAsync(_, callback)
    self.Calls += 1
    if self.Fail then error("DataStore intentionally unavailable") end
    local value = callback(self.Value)
    if value then self.Value = value end
    return value
end
local workspace = { Raycast = function() return hitResult end }
local byCharacter = {}
local services = {
    Workspace = workspace,
    Players = { GetPlayerFromCharacter = function(_, model) return byCharacter[model] end },
    HttpService = { GenerateGUID = function() guid += 1; return "guid-" .. guid end },
    DataStoreService = { GetDataStore = function()
        getStoreCalls += 1
        if rejectStore then error("You must publish this place to access DataStore") end
        return store
    end, GetRequestBudgetForRequestType = function() return 1 end },
    RunService = { IsStudio = function() return studio end },
}
local game = { JobId = "test-job", PlaceId = 123, GetService = function(_, key) return services[key] end }

--[[ MODULES ]]

local function fakePart(position)
    return { Position = position, Size = V.new(3, 4, 3), SetAttribute = function() end, Destroy = function(self) self.Destroyed = true end, FindFirstChild = function() return nil end }
end
local function fakeModel(name, position)
    return { Name = name, Position = position, PrimaryPart = { FindFirstChild = function() return nil end },
        SetAttribute = function() end, Destroy = function(self) self.Destroyed = true end,
        GetPivot = function(self) return { Position = self.Position } end,
        PivotTo = function(self, frame) self.Position = frame.Position end }
end
local function player(id)
    return { UserId = id, DisplayName = "Player" .. id, Character = {}, Parent = true, Kick = function(self) self.Kicked = true end }
end
local function context()
    local ctx = { Config = Config, Rules = Rules, States = {}, Notices = 0, Effects = 0,
        Random = { NextNumber = function() return 0.3 end, NextInteger = function() return 1 end },
        Visuals = { Part = function(_, _, _, frame) return fakePart(frame.Position) end,
            HarpoonProjectile = function(_, frame) return fakePart(frame.Position) end,
            Egg = function(_, _, _, frame) return fakePart(frame.Position) end, Color = function(rgb) return rgb end, Label = function() end,
            Animal = function(_, spec, frame) return fakeModel(spec.Name, frame.Position) end },
        FX = { FireAllClients = function() end, FireClient = function() end } }
    ctx.World = setmetatable({ Config = Config, Bases = { { Center = V.new(200, 0, 0), TankCenter = V.new(200, 0, 0), Core = { Position = V.new(200, 0, 0) }, OwnerId = 1 } }, Spawns = {}, Eggs = {}, Events = {}, Guardians = {}, RefreshAnimals = function() end, RefreshIncubators = function() end }, World)
    for _, floor in ipairs(Config.Floors) do ctx.World.Spawns[floor.Id] = {} end
    function ctx:Notify() self.Notices += 1 end
    function ctx:Broadcast() self.Notices += 1 end
    function ctx:Root(state) return state.Root, state.Humanoid end
    function ctx:Validate(state) return state.Valid ~= false end
    ctx.Guardians = GuardianSystem.new(ctx)
    ctx.Eggs = EggSystem.new(ctx)
    ctx.Harpoons = HarpoonSystem.new(ctx)
    return ctx
end
local function state(ctx, id, position)
    local p = player(id)
    local s = { Player = p, Profile = Rules.NewProfile(Config), Base = ctx.World.Bases[1], LastPosition = position, Root = { Position = position, CFrame = CFrame.new(position) },
        Humanoid = { Health = 100, TakeDamage = function(self, amount) self.Health -= amount end },
        Tool = { Parent = p.Character, Handle = { FindFirstChild = function() return {} end } } }
    ctx.States[p] = s; byCharacter[p.Character] = p
    return s
end
local function egg(ctx, id, position, carrier)
    local value = { Id = id, PointId = id, Name = "Œuf test", Floor = 1, Rarity = "Common", State = carrier and "Carried" or "World",
        Part = fakePart(position), Prompt = { Enabled = not carrier }, Carrier = carrier and carrier.Player, Home = position, Expires = clock + 1000 }
    ctx.Eggs.Eggs[id] = value
    if carrier then carrier.Carrying = id end
    return value
end

local ctx = context()
local a, b = state(ctx, 1, V.new()), state(ctx, 2, V.new(3, 0, 0))
local item = egg(ctx, "steal", V.new(5, 0, 0))
ctx.Eggs:Pickup(a.Player, item.Id)
check(a.Carrying == item.Id and item.State == "Carried" and item.Part == nil, "Pickup creates an unsecured inventory slot without a world model")
check(a.Aura and a.Aura.FillColor == Config.Rarities.Common.Color, "Carrier is highlighted with the egg rarity color")
check(#a.Profile.Eggs == 0, "Pending inventory egg is not persisted as secured loot")
ctx.Eggs:Pickup(b.Player, item.Id)
check(b.Carrying == nil and item.Carrier == a.Player, "Second pickup cannot steal a carried egg")
check(ctx.Eggs:Drop(a, "Harpoon") and item.Part ~= nil and a.Aura == nil, "Harpoon removes the carrier aura and recreates the dropped world egg")
ctx.Eggs:Pickup(b.Player, item.Id)
check(b.Carrying == item.Id and b.Profile.Stats.Steals == 1, "Another player can recover a harpooned egg")
ctx.Eggs:Drop(b, "Harpoon"); ctx.Eggs:Pickup(b.Player, item.Id)
check(b.Profile.Stats.Steals == 1, "Recovering your own egg does not farm steals")

ctx = context(); a = state(ctx, 1, V.new(200, 0, 0)); b = state(ctx, 2, V.new(200, 0, 0))
item = egg(ctx, "safe", V.new(200, 0, 0), a)
check(not ctx.Eggs:Drop(a, "Harpoon"), "Harpoon cannot drop an egg arriving at its owner's base")
check(a.Carrying == nil and #a.Profile.Eggs == 1 and item.State == "Secured", "Arrival permanently secures ownership")
check(ctx.Eggs.Eggs.safe == nil and item.Part.Destroyed, "Secured egg leaves the shared world")
ctx.Eggs:Pickup(b.Player, "safe")
check(b.Carrying == nil, "A secured egg cannot be picked up by another player")
item = egg(ctx, "visitor", V.new(200, 0, 0), b)
check(not ctx.Eggs:Drop(b, "Harpoon") and b.Carrying == "visitor", "Visitors also have PvP immunity in every base")
check(#b.Profile.Eggs == 0, "Somebody else's base does not secure your egg")
ctx.Eggs:Hatch(b, "safe")
check(Rules.AnimalCount(b.Profile) == 0, "Hatching cannot access another player's inventory")
ctx.Eggs:Hatch(a, "safe")
check(Rules.AnimalCount(a.Profile) == 0 and a.Profile.Eggs[1].ReadyAt, "Owner deposits into own aquarium without an instant animal")
local deadline = a.Profile.Eggs[1].ReadyAt
ctx.Eggs:Hatch(a, "safe")
check(a.Profile.Eggs[1].ReadyAt == deadline, "Repeated remote hatch cannot skip or restart incubation")
ctx.Eggs:Step()
check(Rules.AnimalCount(a.Profile) == 0, "Server heartbeat cannot hatch before deadline")
clock += Config.HatchTimes.Common
ctx.Eggs:Step()
check(Rules.AnimalCount(a.Profile) == 1 and #a.Profile.Eggs == 0, "Server automatically hatches the deposited egg at deadline")
ctx.Eggs:Hatch(a, "safe")
check(Rules.AnimalCount(a.Profile) == 1, "Replayed hatch never duplicates an animal")

ctx = context(); a = state(ctx, 1, V.new()); item = egg(ctx, "distant", V.new(40, 0, 0))
ctx.Eggs:Pickup(a.Player, item.Id); check(a.Carrying == nil, "Remote prompt distance checked")
item.Part.Position = V.new(2, 0, 0); item.Floor = 2
ctx.Eggs:Pickup(a.Player, item.Id); check(a.Carrying == item.Id, "A poorly equipped diver can still pick up a deeper egg")
ctx.Eggs:Drop(a, "Manual")
item.Floor = 1; hitResult = { Instance = {} }
ctx.Eggs:Pickup(a.Player, item.Id); check(a.Carrying == nil, "Pickup through a wall rejected")
hitResult = nil; a.Valid = false
ctx.Eggs:Pickup(a.Player, item.Id); check(a.Carrying == nil, "Invalid movement prevents pickup")

ctx = context(); a = state(ctx, 1, V.new())
item = egg(ctx, "mythic-inventory", V.new(2, 0, 0)); item.Rarity = "Mythic"
ctx.Eggs:Pickup(a.Player, item.Id)
check(a.Aura.FillColor == Config.Rarities.Mythic.Color, "Highlight uses the actual collected egg rarity")
ctx.Eggs:Hatch(a, item.Id)
check(#a.Profile.Eggs == 0 and a.Carrying == item.Id, "An unsecured inventory egg cannot be hatched remotely")
ctx.Eggs.Spawn = function() end
ctx.Eggs:RefreshForEvent()
check(ctx.Eggs.Eggs[item.Id] == item and a.Carrying == item.Id, "Events cannot discard an unsecured inventory egg")
ctx.Eggs:Drop(a, "Death")
check(a.Carrying == nil and a.Aura == nil and item.State == "Dropped" and item.Part, "Death restores the unsecured egg in the shared world")

local function projectileCase(targetPosition, hasEgg, collision)
    local c = context()
    local shooter, target = state(c, 1, V.new()), state(c, 2, targetPosition)
    local e = hasEgg and egg(c, "projectile", targetPosition, target)
    if hasEgg then table.insert(target.Profile.Eggs, { Id = "permanent", Name = "Œuf sécurisé", Floor = 1, Rarity = "Common" }) end
    hitResult = collision and { Position = targetPosition, Instance = { FindFirstAncestorOfClass = function() return target.Player.Character end } } or nil
    c.Harpoons.Projectiles = { { Spec = Config.Harpoons[1], Position = V.new(), Direction = V.new(1, 0, 0), Traveled = 0, Part = fakePart(V.new()), Shooter = shooter } }
    c.Harpoons:Step(0.4)
    return c, shooter, target, e
end
local c, shooter, target = projectileCase(V.new(10, 0, 0), true, true)
check(target.Carrying == nil and shooter.Profile.Stats.Hits == 1, "Swept projectile collision drops carried egg")
check(target.Aura == nil and target.Humanoid.Health == 100, "Interception removes only the pending egg, without player damage")
check(#target.Profile.Eggs == 1 and target.Profile.Eggs[1].Id == "permanent", "A harpoon hit never removes a permanently secured inventory egg")
c, shooter, target = projectileCase(V.new(10, 0, 0), true, false)
check(target.Carrying == "projectile" and shooter.Profile.Stats.Hits == 0, "Miss has no gameplay effect")
c, shooter, target = projectileCase(V.new(10, 0, 0), false, true)
check(shooter.Profile.Stats.Hits == 0, "Hitting an empty player has no gameplay effect")
c, shooter, target = projectileCase(V.new(200, 0, 0), true, true)
check(target.Carrying == "projectile" and shooter.Profile.Stats.Hits == 0, "Safe sphere blocks projectile interception")
c, shooter, target = projectileCase(V.new(30, 0, 0), true, true)
check(target.Carrying == "projectile", "Out-of-range collision cannot steal")
hitResult = nil; ctx = context(); a = state(ctx, 1, V.new())
ctx.Harpoons:Fire(a, V.new(1, 0, 0)); ctx.Harpoons:Fire(a, V.new(1, 0, 0))
check(#ctx.Harpoons.Projectiles == 1, "Server cooldown rejects an immediate second shot")
ctx.Harpoons:Fire(a, V.new(0 / 0, 0, 0))
check(#ctx.Harpoons.Projectiles == 1, "Non-finite aim rejected")
a.NextShot = 0; a.Tool.Parent = {}
ctx.Harpoons:Fire(a, V.new(1, 0, 0)); check(#ctx.Harpoons.Projectiles == 1, "Unequipped harpoon rejected")

local p = player(99)
local first, second = DataSystem.new(Config, Rules), DataSystem.new(Config, Rules)
local data = first:Load(p)
check(data ~= nil and store.Value.Session.Id == first.Token, "Load acquires a lease")
local blocked = second:Load(p)
check(blocked == nil, "Concurrent session cannot load or overwrite a locked profile")
data.Money = 1234
data.BaseLevel = 3
data.Eggs = { { Id = "incubating", Name = "Œuf", Floor = 1, Rarity = "Common", StartedAt = os.time(), ReadyAt = os.time() + 15 } }
check(first:Save(p, false) and store.Value.Data.Money == 1234, "Autosave persists actual profile state")
check(first:Save(p, true) and store.Value.Session == nil, "Leaving releases the lease")
local restored = second:Load(p)
check(restored and restored.Money == 1234, "Reconnect restores saved progression")
check(restored.BaseLevel == 3, "Reconnect restores the upgraded aquarium gallery")
check(restored.Eggs[1].ReadyAt == data.Eggs[1].ReadyAt, "Reconnect preserves incubation deadline without restarting it")
local existing = store.Value
store.Fail = true
local failed = DataSystem.new(Config, Rules)
check(failed:Load(player(100)) == nil, "Production rejects failed loads")
check(store.Value == existing and failed.Sessions[p] == nil, "Failed load cannot replace a profile with defaults")
studio = true
local offline = DataSystem.new(Config, Rules)
local guest = player(101)
local temporary, _, isOffline = offline:Load(guest)
check(temporary and isOffline, "Studio-only fallback is explicit")
local calls = store.Calls
temporary.Money = 999999
check(offline:Save(guest, true) and store.Calls == calls, "Offline fallback never writes temporary defaults")
check(store.Value == existing, "Original saved progression remains intact")
game.PlaceId = 0
calls = getStoreCalls
local unpublished, visitor = DataSystem.new(Config, Rules), player(104)
local fresh, _, localOnly = unpublished:Load(visitor)
check(fresh and localOnly and getStoreCalls == calls, "Unpublished Studio starts without requesting DataStore")
calls = store.Calls
check(unpublished:Save(visitor, true) and store.Calls == calls, "Unpublished play cannot save temporary data")
game.PlaceId = 123; rejectStore = true
local unavailable, visitor2 = DataSystem.new(Config, Rules), player(105)
check(select(3, unavailable:Load(visitor2)), "GetDataStore throwing does not abort Studio startup")
studio = false
local unavailableLive = DataSystem.new(Config, Rules)
check(unavailableLive:Load(player(106)) == nil, "GetDataStore failure never creates a live default profile")
check(store.Value == existing, "Constructor failures preserve the stored profile")
rejectStore = false
store.Fail = false; studio = false
store.Value.Session = { Id = "other-session", Expires = os.time() + 300 }
check(not second:Save(p, false) and p.Kicked, "Lost lease blocks a write and disconnects stale session")
check(store.Value.Data.Money == 1234, "Lost lease cannot overwrite the newer session")
store.Value = { Version = 999, Data = { Money = 555 } }
local unsupported = DataSystem.new(Config, Rules)
check(unsupported:Load(player(102)) == nil and store.Value.Data.Money == 555, "Unknown schema cannot be overwritten by defaults")
store.Value = nil
local stale, stalePlayer = DataSystem.new(Config, Rules), player(103)
check(stale:Load(stalePlayer) ~= nil, "New save session starts")
clock += Config.SessionLease
check(stale:IsClosing(stalePlayer) and stalePlayer.Kicked, "Expired save lease freezes the session")

ctx = context(); a = state(ctx, 1, V.new(17, 3, 0))
item = egg(ctx, "guarded", V.new())
local guardian = ctx.Guardians:Spawn(item, Config.Floors[1])
check(guardian.Health == Config.Floors[1].BossHealth, "Reef boss uses configured zone health")
local another = egg(ctx, "second-egg", V.new(200, 0, 0))
check(ctx.Guardians:Spawn(another, Config.Floors[1]) == guardian, "All nests in a floor share exactly the same boss")
ctx.Eggs:Remove(item)
check(ctx.Guardians.ByFloor[1] == guardian and not guardian.Model.Destroyed, "Removing an egg never destroys its shared boss")
ctx.Guardians:Step(0.1)
check(a.Humanoid.Health < 100, "Nearby exploration target takes boss damage")
local deep = ctx.Guardians.ByFloor[3]
check(deep.Health > guardian.Health and deep.Floor.GuardianSpeed > guardian.Floor.GuardianSpeed, "Deeper bosses have more health and speed")
a.Root.Position = V.new(200, 0, 0); a.LastPosition = a.Root.Position; a.Humanoid.Health = 100
guardian.Model.Position = V.new(199, 0, 0)
clock += 3; ctx.Guardians:Step(0.1)
check(a.Humanoid.Health == 100, "Bosses never attack a player in a safe base")
a.Root.Position = V.new(-300, 0, 0); a.LastPosition = a.Root.Position
clock += 3; ctx.Guardians:Step(0.1)
check(guardian.Target == a, "Zone boss detects a diver across distant nests in its floor")
ctx.Guardians:Damage(guardian.Model, guardian.Health + 1, a.Player)
check(guardian.Model.Destroyed and ctx.Guardians.ByFloor[1] == nil, "Defeated boss is removed once")
ctx.Guardians:Step(0.1)
check(ctx.Guardians.ByFloor[1] == nil, "Defeated boss grants a real cooldown before respawn")
clock += Config.Floors[1].BossRespawn; ctx.Guardians:Step(0.1)
check(ctx.Guardians.ByFloor[1] and ctx.Guardians.ByFloor[1] ~= guardian, "Boss respawns after configured delay even without a new egg")

ctx = context(); a = state(ctx, 1, V.new(17, -300, 0))
item = egg(ctx, "rage", V.new(0, -303, 0))
local angry = ctx.Guardians:Spawn(item, Config.Floors[2])
local origin = angry.Model.Position
ctx.Guardians:Step(0.1)
local badSpeed = (angry.Model.Position - origin).Magnitude / 0.1
local badDamage = 100 - a.Humanoid.Health
angry.Model.Position = origin; a.Profile.Equipment.Suit = 10; a.Humanoid.Health = 100
clock += 2; ctx.Guardians:Step(0.1)
check(badSpeed > (angry.Model.Position - origin).Magnitude / 0.1, "Actual boss movement is faster against inadequate equipment")
check(badDamage > 100 - a.Humanoid.Health, "Adequate equipment reduces actual boss attack damage")
ctx = context(); a = state(ctx, 1, V.new(17, -1600, 0))
item = egg(ctx, "deadly", V.new(0, -1603, 0))
ctx.Guardians:Spawn(item, Config.Floors[6]); ctx.Guardians:Step(0.1)
check(a.Humanoid.Health <= 0, "A deep boss can kill a starting diver")

clock = 0; ctx = context()
ctx.Eggs.RefreshForEvent = function(self) self.Refreshed = true end
local eventSystem = EventSystem.new(ctx)
clock = 270; eventSystem:Step()
check(ctx.Notices == 1 and not ctx.Event, "Minor event warns thirty seconds before starting")
clock = 271; eventSystem:Step()
check(ctx.Notices == 1, "Event warning is not spammed")
clock = 300; eventSystem:Step()
check(ctx.Event and ctx.Event.Key == "Minor" and ctx.Eggs.NextSpawn == 0, "Five-minute event starts and refreshes spawn scheduler")
clock = 390; eventSystem:Step()
check(ctx.Event == nil, "Temporary event expires")
clock = 900; eventSystem:Step()
check(ctx.Event and ctx.Event.Key == "Major", "Fifteen-minute major event takes priority over coincident minor event")
clock = 1050; eventSystem:Step()
check(not eventSystem:Snapshot().Active, "Major event also expires and restores normal state")
clock = 2370; eventSystem:Step()
check(eventSystem.Warned.Legendary, "Forty-minute storm has an advance warning")
clock = 2400; eventSystem:Step()
check(ctx.Event and ctx.Event.Key == "Legendary", "Forty-minute storm supersedes smaller events")
clock = 2610; eventSystem:Step()
check(not ctx.Event or ctx.Event.Key ~= "Legendary", "Legendary storm is temporary")

ctx = context(); ctx.World.Spawns = { [1] = {} }
for i = 1, 16 do table.insert(ctx.World.Spawns[1], { Id = "point-" .. i, Position = V.new(i * 15, 0, 0) }) end
for _ = 1, Config.EggsPerFloor + 2 do ctx.Eggs:Spawn(Config.Floors[1]) end
local spawned, points = 0, {}
for _, spawnedEgg in pairs(ctx.Eggs.Eggs) do
    spawned += 1
    check(spawnedEgg.Guardian and ctx.Guardians.Active[spawnedEgg.Guardian.Model], "Every spawned egg has an active guardian")
    check(not points[spawnedEgg.PointId], "Occupied nests cannot spawn a second egg")
    points[spawnedEgg.PointId] = true
end
check(spawned == Config.EggsPerFloor, "Egg count respects floor capacity")
local sharedBoss = ctx.Guardians.ByFloor[1]
local replacements = 0
ctx.Eggs.Spawn = function() replacements += 1 end
ctx.Eggs:RefreshForEvent()
check(ctx.Guardians.ByFloor[1] == sharedBoss and not sharedBoss.Model.Destroyed, "Event egg replacement preserves the zone boss")
check(replacements == Config.ActiveFloors, "Event rarity applies immediately to every active floor")
for _, ability in ipairs({ "Siphon", "Shock", "Vortex" }) do
    ctx = context(); a = state(ctx, 1, V.new(60, -1000, 0)); a.Oxygen = 100
    item = egg(ctx, "boss-" .. ability, V.new(0, -1003, 0))
    local floor = table.clone(Config.Floors[4]); floor.Ability = ability
    local boss = ctx.Guardians:Spawn(item, floor); boss.NextAbility = clock
    ctx.Guardians:Step(0.01)
    check(boss.Telegraph ~= nil, "Boss attack telegraphed before impact")
    check(a.Oxygen == 100 and a.Humanoid.Health == 100 and not a.SlowUntil, "Telegraph itself has no combat effect")
    clock += 1.3; ctx.Guardians:Step(0.01)
    check((ability == "Siphon" and a.Oxygen < 100) or (ability == "Shock" and a.Humanoid.Health < 100)
        or (ability == "Vortex" and a.SlowUntil > clock), "Boss ability produces its configured gameplay effect")
    a.Oxygen = 100; a.Humanoid.Health = 100; a.SlowUntil = nil
    boss.NextAbility = clock; ctx.Guardians:Step(0.01)
    ctx.World.Bases[1].Center = a.Root.Position
    clock += 1.3; ctx.Guardians:Step(0.01)
    check(a.Oxygen == 100 and a.Humanoid.Health == 100 and not a.SlowUntil, "Base immunity also blocks boss abilities")
end
print(string.format("Services: %d assertions passed (deterministic engine fakes)", passed))
