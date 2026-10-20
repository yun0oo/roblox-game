--!nonstrict
-- State transitions and pose lifecycle, using motor/physics doubles.
local Engine = require("./support/Engine")
local e = Engine.new()
local Instance, Vector3, CFrame, Enum = e.Instance, e.Vector3, e.CFrame, e.Enum
local factories = {}
--[[ MODULES ]]
local Motion, Pose = factories.SwimController(), factories.SwimAnimation()
local passed = 0
local function check(value, text) assert(value, text); passed += 1 end
local changes = 0
local humanoid = { State = Enum.HumanoidStateType.Running,
    GetState = function(self) return self.State end,
    ChangeState = function(self, value) changes += 1; self.State = value end }
local velocity = {}
local swim = Motion.new(humanoid, velocity, 105)
for _ = 1, 120 do swim:Step(90, Vector3.new(0, 0, -20), true) end
check(changes == 1 and velocity.Enabled, "Continuous swimming changes humanoid state once, not every frame")
check(velocity.VectorVelocity.Z == -20, "The swim controller applies requested water velocity")
for _, y in ipairs({ 105, 105.4, 104.9, 106.1, 105.8 }) do swim:Step(y, Vector3.zero, true) end
check(changes == 1, "Surface waves do not repeatedly restart the swim animation")
swim:Step(108, Vector3.zero, true)
check(changes == 2 and not velocity.Enabled, "Leaving water releases the swimming controller")
swim:Step(90, Vector3.zero, true)
humanoid.State = Enum.HumanoidStateType.Climbing
swim:Step(99, Vector3.new(0, 12, 0), true)
check(not velocity.Enabled and humanoid.State == Enum.HumanoidStateType.Climbing, "Ladders retain native climbing control")
swim:Step(90, Vector3.zero, false)
check(not velocity.Enabled and velocity.VectorVelocity.Magnitude == 0, "A dead avatar never retains a swim force")

local character = Instance.new("Model")
local animate = Instance.new("LocalScript"); animate.Name = "Animate"; animate.Disabled = false; animate.Parent = character
local motor = Instance.new("Motor6D"); motor.Name = "RootJoint"; motor.C0 = CFrame.new(); motor.Transform = CFrame.new(); motor.Parent = character
local original = motor.Transform
local pose = Pose.new(character)
pose:Step(0.016, true, 20)
local firstPhase = pose.Phase
for _ = 1, 120 do pose:Step(0.016, true, 20) end
check(animate.Disabled and pose.Phase > firstPhase and motor.Transform ~= original, "Underwater poses advance continuously while default locomotion is suspended")
for _ = 1, 120 do pose:Step(0.016, false, 0) end
check(not animate.Disabled and motor.Transform == original and not pose.Active, "Leaving water restores the avatar's original joints and Animate script")
animate.Disabled = true
pose:Step(0.016, true, 20); pose:Restore()
check(animate.Disabled, "An Animate script disabled by another system stays disabled")
print(string.format("Swimming: %d assertions passed (engine doubles; native animation remains a Studio check)", passed))
