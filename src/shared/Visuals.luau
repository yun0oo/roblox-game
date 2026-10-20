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
    local myth = spec.Style
    local style = ({ kraken = "octopus", leviathan = "eel", dragon = "shark", scylla = "octopus", charybdis = "round" })[myth] or myth
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
    if myth == "kraken" or myth == "leviathan" or myth == "dragon" or myth == "scylla" or myth == "charybdis" then
        local glow = Color3.fromRGB(255, 96, 143)
        for _, side in ipairs({ -1, 1 }) do
            Visuals.Rod(model, "Corne mythologique", Vector3.new(side * 0.9, 0.8, -1.7) * scale,
                Vector3.new(side * 1.8, 3, -2.6) * scale, 0.38 * scale, pale)
            local eye = part("Œil incandescent", Vector3.new(0.65, 0.5, 0.5), Vector3.new(side * 1.1, 0.6, -2), glow, Enum.PartType.Ball)
            eye.Material = Enum.Material.Neon
            for i = 1, 3 do
                Visuals.Rod(model, "Croc", Vector3.new(side * 0.7, 0, -1.8 - i * 0.25) * scale,
                    Vector3.new(side * 0.5, -1, -1.8 - i * 0.25) * scale, 0.18 * scale, pale)
            end
            if myth == "dragon" then
                local wing = part("Nageoire draconique", Vector3.new(5, 0.35, 3.5), Vector3.new(side * 3.3, 0.5, 0.6), pale, Enum.PartType.Ball)
                wing.CFrame *= CFrame.Angles(0, side * 0.35, side * 0.4)
            end
        end
        for i = 1, 5 do
            local rune = part("Épine runique", Vector3.new(0.45, 1.2 + i * 0.12, 0.65), Vector3.new(0, bodySize.Y * 0.55, -2.5 + i), glow)
            rune.Material = Enum.Material.Neon
        end
        if myth == "scylla" then
            for i = -1, 1 do
                Visuals.Rod(model, "Cou de Scylla", Vector3.new(i, 0, 0) * scale, Vector3.new(i * 2, 3.5, -2) * scale, 0.7 * scale, color)
                part("Tête de Scylla", Vector3.new(1.5, 1.2, 2), Vector3.new(i * 2, 3.5, -2), pale, Enum.PartType.Ball)
            end
        elseif myth == "charybdis" then
            local maw = part("Gueule du vortex", Vector3.new(3.2, 3.2, 0.8), Vector3.new(0, 0, -1.8), Color3.fromRGB(9, 6, 25), Enum.PartType.Ball)
            maw.Material = Enum.Material.Neon
            for i = 1, 10 do
                local a = i * math.pi / 5
                part("Dent du vortex", Vector3.new(0.4, 0.65, 0.5), Vector3.new(math.cos(a) * 1.25, math.sin(a) * 1.25, -2.2), pale)
            end
        end
    end
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
    local power = rarity.Power
    particles.Rate = math.floor(5 + power * 6)
    particles.SpreadAngle = Vector2.new(180, 180)
    particles.LightEmission = 0.8
    particles.Size = NumberSequence.new(0.2 + power * 0.15)
    light.Range = 14 + power * 9
    local aura = Instance.new("Highlight")
    aura.Name = "Aura de rareté"; aura.Adornee = egg
    aura.FillColor = color; aura.OutlineColor = color
    aura.FillTransparency = 0.75; aura.OutlineTransparency = 0.1
    aura.DepthMode = Enum.HighlightDepthMode.Occluded; aura.Parent = egg
    local halo = Instance.new("BillboardGui")
    halo.Name = "Halo"; halo.Size = UDim2.fromScale(rarity.Size * 2.6, rarity.Size * 2.6)
    halo.AlwaysOnTop = false; halo.MaxDistance = 180; halo.Parent = egg
    local image = Instance.new("ImageLabel")
    image.Size = UDim2.fromScale(1, 1); image.BackgroundTransparency = 1
    image.Image = "rbxasset://textures/particles/flare_main.dds"
    image.ImageColor3 = color; image.ImageTransparency = 0.4; image.Parent = halo
    egg:SetAttribute("AuraPower", power)
    return egg
end

function Visuals.Harpoon(tool, level)
    local steel = Color3.fromRGB(177, 199, 207)
    local dark = Color3.fromRGB(27, 39, 47)
    local accent = level >= 3 and Color3.fromRGB(255, 196, 78) or Color3.fromRGB(44, 180, 185)
    local handle = Visuals.Part(tool, "Handle", Vector3.new(0.5, 1.2, 0.65), CFrame.new(), dark, Enum.Material.SmoothPlastic)
    handle.Anchored = false; handle.Massless = true
    local function piece(name, size, frame, color, shape)
        local p = Visuals.Part(tool, name, size, frame, color, Enum.Material.Metal, shape)
        p.Anchored = false; p.Massless = true
        local weld = Instance.new("WeldConstraint"); weld.Part0 = handle; weld.Part1 = p; weld.Parent = p
        return p
    end
    piece("Corps du fusil", Vector3.new(0.65, 0.7, 3.5), CFrame.new(0, 0.6, -0.95), accent)
    piece("Crosse", Vector3.new(0.8, 0.9, 1.1), CFrame.new(0, 0.65, 1.1), dark)
    piece("Canon", Vector3.new(4.2, 0.35, 0.35), CFrame.new(0, 0.85, -1.7) * CFrame.Angles(0, math.pi / 2, 0), steel, Enum.PartType.Cylinder)
    piece("Flèche", Vector3.new(0.12, 0.12, 5), CFrame.new(0, 1.1, -2), steel)
    local tip = piece("Pointe du harpon", Vector3.new(0.7, 0.7, 1.1), CFrame.new(0, 1.1, -4.6) * CFrame.Angles(-math.pi / 2, 0, 0), steel)
    local tipMesh = Instance.new("SpecialMesh"); tipMesh.MeshType = Enum.MeshType.Pyramid; tipMesh.Parent = tip
    for side = -1, 1, 2 do
        piece("Ardillon", Vector3.new(0.12, 0.12, 0.85), CFrame.new(side * 0.2, 1.1, -4.15) * CFrame.Angles(0, side * -0.55, 0), steel)
        piece("Sandow", Vector3.new(0.18, 0.18, 3), CFrame.new(side * 0.45, 0.7, -1.5), dark)
    end
    piece("Moulinet", Vector3.new(0.55, 0.8, 0.8), CFrame.new(0, -0.1, -1.1) * CFrame.Angles(0, 0, math.pi / 2), dark, Enum.PartType.Cylinder)
    piece("Pontet", Vector3.new(0.13, 0.65, 0.13), CFrame.new(0, -0.25, -0.6), steel)
    piece("Détente", Vector3.new(0.12, 0.4, 0.12), CFrame.new(0, 0, -0.35) * CFrame.Angles(-0.35, 0, 0), dark)
    local origin = Instance.new("Attachment"); origin.Name = "RopeOrigin"; origin.Position = Vector3.new(0, 1.1, -4.7); origin.Parent = handle
    return handle
end

function Visuals.HarpoonProjectile(parent, frame)
    local shaft = Visuals.Part(parent, "Flèche du harpon", Vector3.new(0.15, 0.15, 3.2), frame, Color3.fromRGB(201, 223, 229), Enum.Material.Metal)
    local tip = Visuals.Part(shaft, "Pointe", Vector3.new(0.5, 0.5, 0.85), frame * CFrame.new(0, 0, -1.7) * CFrame.Angles(-math.pi / 2, 0, 0), shaft.Color, Enum.Material.Metal)
    local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Pyramid; mesh.Parent = tip
    tip.Anchored = false; tip.Massless = true
    local tipWeld = Instance.new("WeldConstraint"); tipWeld.Part0 = shaft; tipWeld.Part1 = tip; tipWeld.Parent = tip
    for side = -1, 1, 2 do
        local barb = Visuals.Part(shaft, "Ardillon", Vector3.new(0.12, 0.12, 0.9), frame * CFrame.new(side * 0.2, 0, -1.2) * CFrame.Angles(0, side * -0.55, 0), shaft.Color, Enum.Material.Metal)
        barb.Anchored = false; barb.Massless = true
        local weld = Instance.new("WeldConstraint"); weld.Part0 = shaft; weld.Part1 = barb; weld.Parent = barb
    end
    return shaft
end
return Visuals
