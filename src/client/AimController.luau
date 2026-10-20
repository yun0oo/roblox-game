--!nonstrict
-- M toggles a shoulder camera lock; menus temporarily release the pointer.
local Aim = {}
Aim.__index = Aim
function Aim.new(input) return setmetatable({ Input = input, Locked = false, Focused = true }, Aim) end
function Aim.InputAction(key)
    if key == Enum.KeyCode.M then return "Camera" end
    if key == Enum.KeyCode.LeftShift or key == Enum.KeyCode.RightShift or key == Enum.KeyCode.ButtonX then return "Boost" end
    return nil
end
function Aim:Toggle() self.Locked = not self.Locked end
function Aim:Centered(kind)
    return self.Locked or kind == Enum.UserInputType.Touch or string.find(kind.Name, "Gamepad") ~= nil
end
function Aim:Step(humanoid, root, camera, blocked, armed)
    local active = self.Locked and not blocked and self.Focused
    if active then self.Input.MouseBehavior = Enum.MouseBehavior.LockCenter
    elseif self.Applied or blocked or not self.Focused then self.Input.MouseBehavior = Enum.MouseBehavior.Default end
    self.Applied = active
    self.Input.MouseIconEnabled = blocked or not self.Focused or not (active or armed)
    if not humanoid then return end
    humanoid.AutoRotate = not active
    humanoid.CameraOffset = active and Vector3.new(1.75, 0.35, 0) or Vector3.zero
    if active and root and camera and humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
        local look = camera.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        if flat.Magnitude > 0.01 then root.CFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit) end
    end
end
return Aim
