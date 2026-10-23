--!nonstrict
-- Exercise the real guardian service against deterministic engine doubles.
-- Native mesh orientation, collision and swimming are still Studio checks.
local Engine = require("./support/Engine")
local e = Engine.new()
local game, workspace, script = e.Game, e.Workspace, e.Script
local Instance, Vector3, CFrame, Color3, Enum = e.Instance, e.Vector3, e.CFrame, e.Color3, e.Enum
local UDim2 = { fromOffset = function() return {} end, fromScale = function() return {} end }
local RaycastParams = { new = function() return {} end }
local os = { clock = function() return e.Clock end }
local factories, loaded = {}, {}
local function require(ref)
    if not loaded[ref.Name] then loaded[ref.Name] = factories[ref.Name]() end
    return loaded[ref.Name]
end
--[[ MODULES ]]
local config, rules, visuals = factories.Config(), factories.Rules(), factories.Visuals()
local player = e:Player(10); local avatar = e:Character(player)
avatar.Humanoid.Health = 1000000
local state = { Player = player, Profile = rules.NewProfile(config), Oxygen = 100 }
state.Profile.Equipment.Suit = 75; state.Profile.Equipment.Shield = 10
local ctx = { Config = config, Rules = rules, Visuals = visuals, States = { [player] = state },
    Random = { NextNumber = function(_, low) return low or 0 end },
    World = { Spawns = {}, Guardians = Instance.new("Folder"), Eggs = Instance.new("Folder"), SafeBase = function() return nil end },
    FX = Instance.new("RemoteEvent"), Notify = function() end }
function ctx:Root(target)
    local character = target.Player.Character
    if character and character.Humanoid.Health > 0 then return character.HumanoidRootPart, character.Humanoid end
end
local guardians = factories.GuardianSystem().new(ctx)
local passed = 0
local function check(value, message) assert(value, message); passed += 1 end
for _, floor in ipairs(config.Floors) do
    ctx.World.Spawns[floor.Id] = { { Position = Vector3.new(0, floor.Bottom + 1, 0) } }
    local record = guardians:Spawn(nil, floor)
    check(record.Home.Y - record.Model.PrimaryPart.Size.Y / 2 >= floor.Bottom + 3 - 0.001,
        "A newly spawned giant guardian fits fully above its seabed")
    check(record.Home.Y + record.Model.PrimaryPart.Size.Y / 2 <= floor.Top - 3 + 0.001,
        "A newly spawned guardian also respects its biome ceiling")
    check(guardians:Spawn(nil, floor) == record, "Multiple nests share exactly one guardian")
end
local floor = config.Floors[6]
local record = guardians.ByFloor[6]
avatar.HumanoidRootPart.CFrame = CFrame.new(record.Home + Vector3.new(8, 0, 0))
guardians:Step(0.2)
local prepared = floor.GuardianSpeed * (1 + (record.Power - 1) * 0.08) * 0.65
check(math.abs(record.Model:GetAttribute("ChaseSpeed") - prepared) < 0.001,
    "Sufficient equipment reduces chase speed while preserving depth scaling")
state.Profile.Equipment.Suit = 1
guardians:Step(0.2)
local rage = rules.GuardianThreat(state.Profile, floor, config)
check(math.abs(record.Model:GetAttribute("ChaseSpeed") - floor.GuardianSpeed * (1 + (record.Power - 1) * 0.08) * rage) < 0.001,
    "Undergeared players retain the full depth and rage speed penalty")
state.Profile.Equipment.Suit = 75
local hp = record.Health
for _, damage in ipairs({ -1, 0, math.huge, -math.huge, 0 / 0 }) do guardians:Damage(record.Model, damage, player) end
check(record.Health == hp, "Invalid damage cannot heal a boss or corrupt its health")
record.Telegraph = e.Clock - 0.1; record.NextAbility = e.Clock - 0.1
check(guardians:Damage(record.Model, 10, player), "A valid harpoon hit damages the guardian")
local untilTime = record.StaggerUntil
check(record.Health == hp - 10 and untilTime == e.Clock + 1.25 and record.Model:GetAttribute("Staggered"),
    "A surviving guardian exposes a bounded recovery window")
check(not record.Telegraph and record.NextAbility > untilTime,
    "The hit cancels an imminent ability and delays its next warning")
local position, playerHealth, slow = record.Model:GetPivot().Position, avatar.Humanoid.Health, state.SlowUntil
e.Clock += 0.5; guardians:Step(0.5)
check((record.Model:GetPivot().Position - position).Magnitude == 0 and record.Model:GetAttribute("ChaseSpeed") == 0,
    "Staggered guardians cannot move")
check(avatar.Humanoid.Health == playerHealth and state.SlowUntil == slow,
    "Staggered guardians cannot perform contact attacks or pending abilities")
e.Clock = untilTime + 0.01; guardians:Step(0.1)
check(not record.Model:GetAttribute("Staggered") and record.Model:GetAttribute("ChaseSpeed") > 0,
    "The guardian resumes its pursuit when recovery ends")
check(avatar.Humanoid.Health == playerHealth, "Recovery does not finish with an immediate extra attack")
e.Clock = untilTime + floor.AttackCooldown + 0.1; guardians:Step(0.1)
check(avatar.Humanoid.Health < playerHealth, "Contact attacks resume after the normal attack cooldown")
record.Model:PivotTo(CFrame.new(0, floor.Bottom + 2, 0))
avatar.HumanoidRootPart.CFrame = CFrame.new(0, floor.Bottom + 1, 0)
guardians:Step(0.1)
check(record.Model:GetPivot().Position.Y - record.Model.PrimaryPart.Size.Y / 2 >= floor.Bottom + 3 - 0.001,
    "Chasing low nests cannot push the guardian through the seabed")
local old = record.Model
guardians:Damage(old, record.Health, player)
check(old.Destroyed and not guardians.ByFloor[6], "A defeated guardian is removed once")
check(not guardians:Damage(old, 10, player), "Late hits cannot damage or stagger a removed guardian")
guardians:Step(0.1)
check(not guardians.ByFloor[6], "A defeated guardian respects its respawn timer")
e.Clock += floor.BossRespawn + 0.1; guardians:Step(0.1)
check(guardians.ByFloor[6] and guardians.ByFloor[6].Model ~= old,
    "Exactly one replacement guardian returns after its cooldown")
print(string.format("Guardians: %d assertions passed (engine doubles; native collision remains a Studio check)", passed))
