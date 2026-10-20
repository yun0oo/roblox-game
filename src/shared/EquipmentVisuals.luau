--!nonstrict
-- Cosmetics use welded, massless parts: compatible with both R6 and R15 avatars.
local Gear = {}
local function color(r, g, b) return Color3.fromRGB(r, g, b) end
local navy, white = color(23, 53, 102), color(241, 250, 255)

function Gear.Apply(character, equipment, visuals, anchored)
    local old = character:FindFirstChild("Équipement de plongée")
    if old then old:Destroy() end
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
    if not torso then return end
    local head = character:FindFirstChild("Head") or torso
    local folder = Instance.new("Model"); folder.Name = "Équipement de plongée"; folder.Parent = character
    local suit = equipment.Suit or 1
    local accent = suit >= 50 and color(255, 197, 52) or suit >= 20 and color(173, 113, 255) or suit >= 10 and color(39, 225, 198) or color(52, 172, 255)
    local function part(key, name, limb, size, offset, tint, material, shape)
        local p = visuals.Part(folder, name, size, limb.CFrame * offset, tint, material, shape)
        p.Anchored = anchored == true; p.Massless = true; p.CastShadow = true
        p:SetAttribute("EquipmentType", key); p:SetAttribute("EquipmentLevel", equipment[key] or 1)
        if not anchored then
            local weld = Instance.new("WeldConstraint"); weld.Part0 = limb; weld.Part1 = p; weld.Parent = p
        end
        return p
    end
    part("Suit", "Gilet néoprène", torso, Vector3.new(1.85, 1.45, 0.32), CFrame.new(0, -0.08, -0.58), navy)
    part("Suit", "Plastron de plongée", torso, Vector3.new(1.45, 0.65, 0.18), CFrame.new(0, 0.15, -0.8), accent)
    for side = -1, 1, 2 do
        part("Suit", "Harnais", torso, Vector3.new(0.17, 1.65, 0.15), CFrame.new(side * 0.69, 0, -0.81), white)
        local tankLevel = equipment.Oxygen or 1
        local tank = part("Oxygen", "Bouteille d’oxygène", torso, Vector3.new(1.65 + tankLevel * 0.035, 0.64, 0.64),
            CFrame.new(side * 0.48, 0, 0.91) * CFrame.Angles(0, 0, math.pi / 2), color(255, 211, 49), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
        part("Oxygen", "Collier de bouteille", torso, Vector3.new(0.68, 0.17, 0.68), CFrame.new(side * 0.48, -0.4, 0.91), navy)
        part("Oxygen", "Robinet", torso, Vector3.new(0.25, 0.22, 0.25), CFrame.new(side * 0.48, 0.99, 0.91), white, Enum.Material.Metal)
        tank:SetAttribute("TankCapacityLevel", tankLevel)
        local arm = character:FindFirstChild(side < 0 and "LeftUpperArm" or "RightUpperArm") or character:FindFirstChild(side < 0 and "Left Arm" or "Right Arm") or torso
        local protection = 0.32 + (equipment.Shield or 1) * 0.025
        part("Shield", "Épaulière renforcée", arm, Vector3.new(1.12, protection, 1.12), CFrame.new(0, 0.35, 0), accent)
        local foot = character:FindFirstChild(side < 0 and "LeftFoot" or "RightFoot") or character:FindFirstChild(side < 0 and "Left Leg" or "Right Leg")
        if foot then
            local length = 1.5 + (equipment.Swim or 1) * 0.06
            part("Swim", "Palme", foot, Vector3.new(0.95, 0.18, length), CFrame.new(0, -foot.Size.Y * 0.5, -length * 0.3), accent)
            part("Swim", "Sangle de palme", foot, Vector3.new(1.02, 0.17, 0.35), CFrame.new(0, -foot.Size.Y * 0.25, -0.2), navy)
        end
        local boost = equipment.Thruster or 1
        part("Thruster", "Turbine", torso, Vector3.new(0.9 + boost * 0.035, 0.58, 0.58), CFrame.new(side * 0.96, -0.45, 0.75) * CFrame.Angles(0, 0, math.pi / 2), navy, Enum.Material.Metal, Enum.PartType.Cylinder)
        part("Thruster", "Sortie de propulseur", torso, Vector3.new(0.44, 0.12, 0.44), CFrame.new(side * 0.96, -0.98, 0.75), color(77, 231, 255), Enum.Material.Neon)
    end
    local mask = part("Suit", "Masque panoramique", head, Vector3.new(1.65, 0.69, 0.32), CFrame.new(0, 0.06, -0.59), navy)
    mask.Transparency = 0.12
    local glass = part("Suit", "Verre du masque", head, Vector3.new(1.42, 0.48, 0.12), CFrame.new(0, 0.06, -0.79), color(93, 225, 255), Enum.Material.Glass)
    glass.Transparency = 0.42
    part("Lamp", "Lampe frontale", head, Vector3.new(0.52, 0.45, 0.36), CFrame.new(0, 0.64, -0.55), navy)
    part("Lamp", "Lentille", head, Vector3.new(0.32 + (equipment.Lamp or 1) * 0.025, 0.27 + (equipment.Lamp or 1) * 0.02, 0.06), CFrame.new(0, 0.64, -0.76), color(255, 245, 151), Enum.Material.Neon)
    part("Oxygen", "Détendeur", head, Vector3.new(0.45, 0.3, 0.25), CFrame.new(0, -0.43, -0.66), white)
    return folder
end
return Gear
