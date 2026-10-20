--!nonstrict
-- Executes the unchanged entry point, World, Visuals, and all game services.
-- The engine API is simulated; native Roblox rendering/physics are not tested.
local Engine = require("./support/Engine")
local passed = 0
local function check(value, message) assert(value, message); passed += 1 end
local function run(failTerrain)
    local e = Engine.new(); e.FailTerrain = failTerrain
    local game, workspace, script = e.Game, e.Workspace, e.Script
    local Instance, Vector3, CFrame, Color3, Enum = e.Instance, e.Vector3, e.CFrame, e.Color3, e.Enum
    local task = e.Task
    local os = { clock = function() return e.Clock end, time = function() return 1700000000 + math.floor(e.Clock) end }
    local warn = function(...) table.insert(e.Warnings, table.concat({ ... }, " ")) end
    local UDim2 = { fromOffset = function() return {} end, fromScale = function() return {} end }
    local ColorSequence = { new = function() return {} end }
    local NumberSequence = { new = function() return {} end }
    local NumberRange = { new = function() return {} end }
    local Vector2 = { new = function() return {} end }
    local RaycastParams = { new = function() return {} end }
    local Random = { new = function()
        local n = 17
        return { NextNumber = function(_, low, high)
            n = (n * 16807) % 2147483647
            return (low or 0) + n / 2147483647 * ((high or 1) - (low or 0))
        end, NextInteger = function(_, low, high) n = (n * 16807) % 2147483647; return low + n % (high - low + 1) end }
    end }
    local factories, loaded = {}, {}
    local function require(ref)
        local name = ref.Name
        if not loaded[name] then loaded[name] = assert(factories[name], name)() end
        return loaded[name]
    end
    --[[ MODULES ]]
    local function boot()
        --[[ MAIN ]]
    end
    -- Cover a player/avatar already present while the ocean is still building.
    local player = e:Player(1); e:Character(player)
    e.Task.spawn(boot)
    e:Drain()
    return e, player, loaded
end
local e, player, loaded = run(false)
check(e.Workspace:GetAttribute("UnderwaterBootState") == "Ready", "Server boot reaches Ready: " .. table.concat(e.Warnings, "\n"))
check(e.StoreCalls == 0, "Unpublished Studio startup does not request DataStore")
check(e.TerrainEdits > 1, "Actual World.Build fills the ocean in chunks")
check(e.Players.CharacterAutoLoads, "Automatic Roblox avatar spawning remains enabled")
check(player.Character:GetAttribute("UnderwaterReady"), "Existing avatar initialized after the world loads")
check(player.Character:FindFirstChild("Harpon") ~= nil, "Existing avatar receives and equips the harpoon")
check(player.Character.HumanoidRootPart.Position.Y > loaded.Config.WaterTop, "Existing avatar spawns on an island above the sea")
check(#e.Workspace.Bases:GetChildren() == 8, "Actual World.Build creates eight habitats")
check(#e.Workspace.Floors:GetChildren() == 6, "Actual World.Build creates all six floors")
check(#e.Workspace.Eggs:GetChildren() == 36, "Startup spawns six eggs per floor")
check(#e.Workspace.Guardians:GetChildren() == 36, "Every initial egg receives a guardian")
for _, base in ipairs(e.Workspace.Bases:GetChildren()) do
    check(base:FindFirstChild("Aquarium géant") ~= nil, "Every surface island includes a giant aquarium")
end
check(#player.Character.Harpon:GetChildren() >= 12, "Harpoon is a detailed welded weapon rather than a single block")
for _, guardian in ipairs(e.Workspace.Guardians:GetChildren()) do
    check(guardian.PrimaryPart and guardian:GetAttribute("Guardian") and guardian:GetAttribute("Health") > 0,
        "Guardian model has a body and combat state")
end
local remote = e.ReplicatedStorage.RemoteEvents
check(remote.Snapshot.Messages[player][1][1].Offline, "Offline session is visible in the first UI snapshot")
local second = e:Player(2)
e.Players.PlayerAdded:Fire(second)
local secondCharacter = e:Character(second); second.CharacterAdded:Fire(secondCharacter)
check(secondCharacter:GetAttribute("UnderwaterReady"), "Late automatically spawned avatar is initialized")
check((secondCharacter.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude > 100, "Each player gets a separate habitat")
local replacement = e:Character(player); player.CharacterAdded:Fire(replacement)
check(replacement:GetAttribute("UnderwaterReady") and replacement:FindFirstChild("Harpon"), "Automatic respawn reinitializes the diver")
e.RunService.Heartbeat:Fire(0.8)
check(remote.Snapshot.Messages[second] ~= nil, "Gameplay heartbeat sends state to a late joiner")

local function latest(p)
    local messages = remote.Snapshot.Messages[p]
    return messages[#messages][1]
end
local function travel(p, destination)
    local root = p.Character.HumanoidRootPart
    local from = root.Position
    local steps = math.ceil((destination - from).Magnitude / 7)
    for index = 1, steps do
        e.Clock += 0.4
        root.CFrame = e.CFrame.new(from + (destination - from) * (index / steps))
        e.RunService.Heartbeat:Fire(0.4)
    end
end
-- Traverse the actual server movement validator with starter equipment.
-- Collision and swimming physics remain native Studio checks.
replacement.Humanoid.Health = 1000000
local spawn = replacement.HumanoidRootPart.Position
travel(player, e.Vector3.new(0, -550, 0))
check(replacement.HumanoidRootPart.Position.Y == -550 and latest(player).Floor == 3 and latest(player).Equipment.Suit == 1,
    "Starting diver crosses two depth recommendations without a level teleport")
local reefEgg
for _, egg in ipairs(e.Workspace.Eggs:GetChildren()) do
    check(egg:FindFirstChild("Aura de rareté") and egg:GetAttribute("AuraPower"), "Every wild egg has its rarity aura")
    if egg.Position.Y > loaded.Config.Floors[1].Bottom then reefEgg = egg end
end
local eggId = reefEgg:GetAttribute("EggId")
travel(player, reefEgg.Position)
reefEgg.ProximityPrompt.Triggered:Fire(player)
travel(player, spawn)
check(#latest(player).Eggs == 1 and not latest(player).Eggs[1].ReadyAt, "Returning to the surface secures the egg without an instant hatch")
remote.Action.OnServerEvent:Fire(player, "Hatch", eggId)
local readyAt = latest(player).Eggs[1].ReadyAt
check(readyAt ~= nil, "Deposit remote creates a server incubation deadline")
local tank = e.Workspace.Bases.Base_1["Aquarium géant"]
check(#tank["Œufs en incubation"]:GetChildren() == 1 and #tank.Animaux:GetChildren() == 0, "Deposited egg is physically displayed inside the aquarium")
remote.Action.OnServerEvent:Fire(player, "Hatch", { Id = eggId, ReadyAt = 0 })
check(#latest(player).Eggs == 1 and latest(player).Eggs[1].ReadyAt == readyAt, "Client cannot submit a shorter incubation deadline")
travel(player, spawn + e.Vector3.new(80, 0, 0))
e.Clock += loaded.Config.HatchTimes[latest(player).Eggs[1].Rarity]
e.RunService.Heartbeat:Fire(0.8)
check(#latest(player).Eggs == 0 and #tank.Animaux:GetChildren() == 1, "Incubation completes automatically in the aquarium while the owner is away")
check(latest(player).Income > 0, "New aquarium animal generates gold income")
for _ = 1, 30 do e.Clock += 0.5; e.RunService.Heartbeat:Fire(0.5) end
check(latest(player).Money > 150, "Server actually credits the animal's gold production")
travel(player, spawn)
local goldBefore = latest(player).Money
remote.Action.OnServerEvent:Fire(player, "Upgrade", "Oxygen")
e.Clock += 1; e.RunService.Heartbeat:Fire(0.8)
check(latest(player).Equipment.Oxygen == 2 and latest(player).Money < goldBefore, "Gold buys equipment in the surface workshop")

local failed = run(true)
check(failed.Workspace:GetAttribute("UnderwaterBootState") == "Failed", "Boot exceptions become a visible failure state")
check(failed.Players.CharacterAutoLoads, "A map-generation error never disables Roblox avatars")
check(string.find(failed.Warnings[1], "Terrain edit intentionally rejected", 1, true), "Original boot error is preserved in Output")
print(string.format("Startup: %d assertions passed (engine fakes; native Studio still required)", passed))
