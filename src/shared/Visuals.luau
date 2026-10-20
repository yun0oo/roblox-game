--!nonstrict
-- Original procedural models: no paid assets or external model dependencies.
local Visuals = {}
function Visuals.Color(rgb) return Color3.fromRGB(rgb[1], rgb[2], rgb[3]) end

function Visuals.Part(parent, name, size, frame, color, material, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = frame
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Shape = shape or Enum.PartType.Block
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

function Visuals.Rod(parent, name, a, b, thickness, color, material)
    return Visuals.Part(parent, name, Vector3.new((b - a).Magnitude, thickness, thickness),
        CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0), color, material, Enum.PartType.Cylinder)
end

function Visuals.Label(part, text, color, offset, distance)
    local gui = Instance.new("BillboardGui")
    gui.Name = "Label"
    gui.Size = UDim2.fromOffset(240, 76)
    gui.StudsOffsetWorldSpace = Vector3.new(0, offset or 6, 0)
    gui.MaxDistance = distance or 105
    gui.AlwaysOnTop = false
    gui.Parent = part
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.45
    label.TextWrapped = true
    label.Text = text
    label.Parent = gui
    return label
end

function Visuals.Animal(parent, spec, frame, scale, title)
    scale = scale or 1
    local model = Instance.new("Model")
    model.Name = spec.Name
    local color = Visuals.Color(spec.Color)
    local pale = color:Lerp(Color3.new(1, 1, 1), 0.65)
    local function part(name, size, pos, shade, shape)
        return Visuals.Part(model, name, size * scale, CFrame.new(pos * scale), shade or color, nil, shape)
    end
    local style = spec.Style
    local bodySize = Vector3.new(2.6, 2.2, 5)
    if style == "round" then bodySize = Vector3.new(3.6, 3.8, 3.4) end
    if style == "whale" or style == "orca" or style == "narwhal" then bodySize = Vector3.new(3.6, 3, 6.7) end
    if style == "eel" then bodySize = Vector3.new(1.5, 1.5, 7) end
    if style == "ray" or style == "turtle" or style == "crab" then bodySize = Vector3.new(3.6, 1.3, 3.8) end
    if style == "jelly" or style == "octopus" or style == "squid" then bodySize = Vector3.new(3.4, 3, 3.4) end
    if style == "seahorse" then bodySize = Vector3.new(1.5, 4, 1.7) end
    local body = part("Body", bodySize, Vector3.zero, color, Enum.PartType.Ball)
    model.PrimaryPart = body
    part("Belly", bodySize * Vector3.new(0.8, 0.4, 0.8), Vector3.new(0, -bodySize.Y * 0.3, -0.1), pale, Enum.PartType.Ball)
    for _, side in ipairs({ -1, 1 }) do
        local eye = Vector3.new(side * bodySize.X * 0.43, bodySize.Y * 0.17, -bodySize.Z * 0.27)
        part("Eye", Vector3.new(0.6, 0.6, 0.6), eye, Color3.fromRGB(243, 253, 255), Enum.PartType.Ball)
        part("Pupil", Vector3.new(0.33, 0.36, 0.33), eye + Vector3.new(side * 0.15, 0, -0.17), Color3.fromRGB(8, 25, 43), Enum.PartType.Ball)
    end
    if style == "octopus" or style == "squid" or style == "jelly" then
        for i = 1, 8 do
            local angle = i * math.pi / 4
            local a = Vector3.new(math.cos(angle), -0.6, math.sin(angle)) * scale
            local b = Vector3.new(math.cos(angle) * 2, -3.8, math.sin(angle) * 2) * scale
            Visuals.Rod(model, "Tentacle", a, b, 0.36 * scale, color, style == "jelly" and Enum.Material.Neon or nil)
        end
        if style == "jelly" then body.Material = Enum.Material.Neon; body.Transparency = 0.2 end
    elseif style == "crab" then
        for side = -1, 1, 2 do
            for i = 1, 4 do
                Visuals.Rod(model, "Leg", Vector3.new(side, -0.2, i - 2.5) * scale,
                    Vector3.new(side * 3, -1.4, i - 2.8) * scale, 0.3 * scale, color)
            end
            part("Claw", Vector3.new(1.4, 0.9, 1.6), Vector3.new(side * 2.6, 0, -2.5), pale, Enum.PartType.Ball)
        end
    else
        local finWidth = style == "ray" and 5.6 or (style == "turtle" and 2.4 or 1.6)
        for side = -1, 1, 2 do
            local fin = part("Fin", Vector3.new(finWidth, 0.3, 2.1), Vector3.new(side * (bodySize.X * 0.4 + finWidth * 0.35), -0.2, 0.5), color, Enum.PartType.Ball)
            fin.CFrame *= CFrame.Angles(0, side * 0.35, side * -0.15)
        end
        part("Tail", Vector3.new(2.4, 0.4, 1.4), Vector3.new(0, 0, bodySize.Z * 0.62), pale, Enum.PartType.Ball)
    end
    if style == "shark" or style == "hammerhead" or style == "orca" then
        local fin = Instance.new("WedgePart")
        fin.Name = "DorsalFin"; fin.Size = Vector3.new(0.4, 1.8, 2) * scale
        fin.CFrame = CFrame.new(0, bodySize.Y * scale * 0.65, 0)
        fin.Color = color; fin.Anchored = true; fin.CanCollide = false; fin.CanQuery = false; fin.CanTouch = false
        fin.Parent = model
    end
    if style == "hammerhead" then part("Hammer", Vector3.new(5, 1, 1.3), Vector3.new(0, 0, -2), color, Enum.PartType.Ball) end
    if style == "turtle" then part("Shell", Vector3.new(3.2, 1.8, 3.2), Vector3.new(0, 0.65, 0.3), color:Lerp(Color3.new(0, 0.2, 0.05), 0.45), Enum.PartType.Ball) end
    if style == "narwhal" then Visuals.Rod(model, "Tusk", Vector3.new(0, 0, -3) * scale, Vector3.new(0, 0.1, -6) * scale, 0.25 * scale, pale) end
    if style == "seahorse" then part("Snout", Vector3.new(0.8, 0.8, 2), Vector3.new(0, 1, -1), pale, Enum.PartType.Ball) end
    if title then Visuals.Label(body, title, Color3.new(1, 1, 1), 5 * scale, 85) end
    model.Parent = parent
    model:PivotTo(frame)
    return model
end

function Visuals.Egg(parent, name, rarity, frame)
    local color = Visuals.Color(rarity.Color)
    local egg = Visuals.Part(parent, name, Vector3.new(0.8, 1, 0.8) * rarity.Size, frame, color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    egg.CanQuery = true
    local light = Instance.new("PointLight")
    light.Color = color; light.Brightness = 1.4; light.Range = 16; light.Parent = egg
    local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    particles.Color = ColorSequence.new(color)
    particles.Lifetime = NumberRange.new(0.7, 1.4)
    particles.Speed = NumberRange.new(0.5, 2)
    particles.Rate = 4
    particles.Size = NumberSequence.new(0.25)
    particles.Parent = egg
    return egg
end
return Visuals
