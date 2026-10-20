--!nonstrict
-- Local poses are rendered on EVERY client for all divers. No uploaded animation
-- or asset ownership permission is needed; R6/R15 joint bases are respected.
local SwimAnimation = {}
SwimAnimation.__index = SwimAnimation
local kinds = {
    Root = "Body", RootJoint = "Body", Neck = "Neck", Waist = "Waist",
    LeftShoulder = "LeftArm", ["Left Shoulder"] = "LeftArm",
    RightShoulder = "RightArm", ["Right Shoulder"] = "RightArm",
    LeftHip = "LeftLeg", ["Left Hip"] = "LeftLeg",
    RightHip = "RightLeg", ["Right Hip"] = "RightLeg",
    LeftElbow = "Elbow", RightElbow = "Elbow", LeftKnee = "Knee", RightKnee = "Knee",
}
function SwimAnimation.new(character)
    local self = setmetatable({ Character = character, Joints = {}, Weight = 0, Phase = 0, Active = false }, SwimAnimation)
    for _, item in ipairs(character:GetDescendants()) do
        if item:IsA("Motor6D") and kinds[item.Name] then
            table.insert(self.Joints, { Motor = item, Kind = kinds[item.Name], Original = item.Transform, Basis = item.C0.Rotation })
        end
    end
    return self
end
function SwimAnimation:Restore()
    for _, joint in ipairs(self.Joints) do if joint.Motor.Parent then joint.Motor.Transform = joint.Original end end
    if self.Animate and self.Animate.Parent then self.Animate.Disabled = self.WasDisabled end
    self.Animate = nil; self.Active = false; self.Weight = 0
end
function SwimAnimation:Step(dt, swimming, speed, vertical)
    dt = math.min(dt, 0.1)
    if swimming and not self.Active then
        self.Active = true
        self.Animate = self.Character:FindFirstChild("Animate")
        if self.Animate then self.WasDisabled = self.Animate.Disabled; self.Animate.Disabled = true end
        local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                if track.Priority == Enum.AnimationPriority.Core or track.Priority == Enum.AnimationPriority.Idle or track.Priority == Enum.AnimationPriority.Movement then track:Stop(0.15) end
            end
        end
    end
    if not self.Active then return end
    self.Weight += ((swimming and 1 or 0) - self.Weight) * math.min(1, dt * 10)
    if not swimming and self.Weight < 0.01 then self:Restore(); return end
    local moving = math.clamp(speed / 7, 0, 1)
    self.Phase += dt * (1.4 + moving * 5)
    local tilt = -(math.pi / 2 - math.asin(math.clamp(vertical or 0, -1, 1))) * 0.85 * moving
    local wave = math.sin(self.Phase)
    local armed = self.Character:FindFirstChild("Harpon") ~= nil
    for _, joint in ipairs(self.Joints) do
        local x, z = 0, 0
        if joint.Kind == "Body" then x = tilt; z = wave * 0.035 * moving
        elseif joint.Kind == "Neck" then x = 0.72 * moving
        elseif joint.Kind == "Waist" then z = wave * 0.04 * moving
        elseif joint.Kind == "LeftArm" then x = 0.3 + moving * (2.1 + wave * 0.45); z = -0.16
        elseif joint.Kind == "RightArm" then x = armed and (1.4 - tilt) or (0.3 + moving * (2.1 - wave * 0.45)); z = 0.16
        elseif joint.Kind == "LeftLeg" then x = wave * 0.32 * moving
        elseif joint.Kind == "RightLeg" then x = -wave * 0.32 * moving
        elseif joint.Kind == "Elbow" then x = -0.25 * moving
        elseif joint.Kind == "Knee" then x = 0.15 * moving end
        local rotation = CFrame.Angles(x, 0, z)
        if joint.Motor.Parent then joint.Motor.Transform = joint.Original:Lerp(joint.Basis:Inverse() * rotation * joint.Basis, self.Weight) end
    end
end
return SwimAnimation
