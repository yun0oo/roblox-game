--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local config = require(game:GetService("ReplicatedStorage").Modules.Config)
local Motion = require(script.Parent.SwimController)
local Pose = require(script.Parent.SwimAnimation)
local actors = {}
local function register(player)
    player.CharacterAdded:Connect(function(character)
        if actors[player] then actors[player].Pose:Restore() end
        -- Avatar limbs/animations may arrive after CharacterAdded.
        task.spawn(function()
            local humanoid = character:WaitForChild("Humanoid", 12)
            local root = character:WaitForChild("HumanoidRootPart", 12)
            if humanoid and root and player.Character == character then actors[player] = { Root = root, Humanoid = humanoid, Pose = Pose.new(character), Active = false } end
        end)
    end)
    if player.Character then
        local character = player.Character
        task.spawn(function()
            local humanoid = character:WaitForChild("Humanoid", 12)
            local root = character:WaitForChild("HumanoidRootPart", 12)
            if humanoid and root and player.Character == character then actors[player] = { Root = root, Humanoid = humanoid, Pose = Pose.new(character), Active = false } end
        end)
    end
end
for _, player in ipairs(Players:GetPlayers()) do register(player) end
Players.PlayerAdded:Connect(register)
Players.PlayerRemoving:Connect(function(player) if actors[player] then actors[player].Pose:Restore(); actors[player] = nil end end)
RunService.PreSimulation:Connect(function(dt)
    for _, actor in pairs(actors) do
        actor.Active = Motion.ShouldSwim(actor.Root.Position.Y, actor.Active, actor.Humanoid:GetState() == Enum.HumanoidStateType.Climbing, actor.Humanoid.Health > 0 and actor.Root.Parent ~= nil, config.WaterTop)
        local velocity = actor.Root.AssemblyLinearVelocity
        actor.Pose:Step(dt, actor.Active, velocity.Magnitude, velocity.Y / math.max(0.1, velocity.Magnitude))
    end
end)
