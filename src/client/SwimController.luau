--!nonstrict
local Swim = {}
Swim.__index = Swim
function Swim.ShouldSwim(y, active, climbing, alive, waterTop)
    return alive and not climbing and y < waterTop + (active and 2 or 0.2)
end
function Swim.new(humanoid, velocity, waterTop)
    return setmetatable({ Humanoid = humanoid, Velocity = velocity, WaterTop = waterTop, Active = false }, Swim)
end
function Swim:Step(y, movement, alive)
    local state = self.Humanoid:GetState()
    local active = Swim.ShouldSwim(y, self.Active, state == Enum.HumanoidStateType.Climbing, alive, self.WaterTop)
    if active ~= self.Active then
        self.Active = active
        if active then
            -- One transition on entry. Re-entering Swimming every render frame
            -- restarts the default animation and fights climbing/surface states.
            self.Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
        elseif alive and state == Enum.HumanoidStateType.Swimming then
            self.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        end
    end
    self.Velocity.Enabled = active
    self.Velocity.VectorVelocity = active and movement or Vector3.zero
    return active
end
return Swim
