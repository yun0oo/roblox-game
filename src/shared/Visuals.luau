--!nonstrict
-- Built-in environment pieces and bundled CC0/derived marine art.
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
    local modules = game:GetService("ReplicatedStorage"):WaitForChild("Modules")
    local art = require(modules.ArtData)
    local key = spec.Art or ({ hammerhead = "shark", orca = "whale", narwhal = "whale", squid = "octopus", round = "fish" })[spec.Style] or spec.Style
    if not art[key] then key = "fish" end
    local color = Visuals.Color(spec.Color)
    local bounds = art[key].Full.Bounds
    local model = Instance.new("Model"); model.Name = spec.Name
    local body = Visuals.Part(model, "Body", Vector3.new(bounds[1], bounds[2], bounds[3]) * scale, CFrame.new(), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    body.Transparency = 0.85
    body:SetAttribute("ArtAsset", key); body:SetAttribute("ArtScale", scale)
    if spec.EventOnly then
        model:SetAttribute("EventRarity", spec.Rarity)
        local aura = Instance.new("Highlight"); aura.Name = "Aura événementielle"
        aura.Adornee = model; aura.FillColor = color; aura.OutlineColor = color
        aura.FillTransparency = 0.86; aura.OutlineTransparency = 0.3
        aura.DepthMode = Enum.HighlightDepthMode.Occluded; aura.Parent = model
        -- A small original crystal crest distinguishes event sculpts even when
        -- their imported base mesh keeps its authored colours.
        for i = -1, 1 do
            local gem = Visuals.Part(model, "Cristal événementiel", Vector3.new(0.3, 0.65 + (i == 0 and 0.3 or 0), 0.3) * scale,
                CFrame.new(i * 0.4 * scale, (bounds[2] / 2 + 0.35) * scale, 0) * CFrame.Angles(0, math.pi / 4, i * -0.2), color, Enum.Material.Neon)
            local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Pyramid; mesh.Parent = gem
        end
    end
    model.PrimaryPart = body
    if game:GetService("RunService"):IsClient() then
        local renderer = require(modules.ArtRenderer)
        local sculpture = renderer.Build(key, color, scale, false)
        sculpture.Parent = body; body.Transparency = 1
    end
    if title then Visuals.Label(body, title, Color3.new(1, 1, 1), bounds[2] * scale * 0.55 + 2, 110) end
    model.Parent = parent; model:PivotTo(frame)
    return model
end

function Visuals.Egg(parent, name, rarity, frame)
    local color = Visuals.Color(rarity.Color)
    local egg = Visuals.Part(nil, name, Vector3.new(0.96, 1.25, 0.96) * rarity.Size, frame, color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    egg.CanQuery = true; egg.Transparency = 0.92
    egg:SetAttribute("ArtAsset", "egg")
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
    if rarity.EventOnly then
        egg:SetAttribute("EventExclusive", true)
        particles.Rate = math.min(particles.Rate, 24)
        particles.LightEmission = 1
        light.Brightness = 1.6
        aura.FillTransparency = 0.86; aura.OutlineTransparency = 0.02
        image.ImageTransparency = 0.52
    end
    egg.Parent = parent
    return egg
end

function Visuals.Harpoon(tool, level)
    local steel = Color3.fromRGB(177, 199, 207)
    local dark = Color3.fromRGB(27, 39, 47)
    local accent = level >= 3 and Color3.fromRGB(255, 196, 78) or Color3.fromRGB(44, 180, 185)
    local handle = Visuals.Part(tool, "Handle", Vector3.new(0.5, 1.2, 0.65), CFrame.new(), dark, Enum.Material.SmoothPlastic)
    handle.Anchored = false; handle.Massless = true
    handle:SetAttribute("ArtAsset", "harpoon"); handle:SetAttribute("ArtScale", 0.7)
    handle:SetAttribute("ArtOffset", Vector3.new(0, 0.55, -0.45)); handle:SetAttribute("ArtRigid", true)
    local function piece(name, size, frame, color, shape)
        local p = Visuals.Part(tool, name, size, frame, color, Enum.Material.Metal, shape)
        p.Anchored = false; p.Massless = true
        local weld = Instance.new("WeldConstraint"); weld.Part0 = handle; weld.Part1 = p; weld.Parent = p
        return p
    end
    -- Slender imported Kenney receiver, polished spear rail and twin rubber bands.
    handle.Color = accent
    piece("Canon", Vector3.new(4.2, 0.35, 0.35), CFrame.new(0, 0.85, -1.7) * CFrame.Angles(0, math.pi / 2, 0), dark, Enum.PartType.Cylinder)
    for _, z in ipairs({ -0.1, -1.25, -2.4, -3.65 }) do
        piece("Bague de canon inox", Vector3.new(0.18, 0.52, 0.52), CFrame.new(0, 0.85, z) * CFrame.Angles(0, math.pi / 2, 0), steel, Enum.PartType.Cylinder)
    end
    piece("Flèche", Vector3.new(0.12, 0.12, 5), CFrame.new(0, 1.1, -2), steel)
    local tip = piece("Pointe du harpon", Vector3.new(0.7, 0.7, 1.1), CFrame.new(0, 1.1, -4.6) * CFrame.Angles(-math.pi / 2, 0, 0), steel)
    local tipMesh = Instance.new("SpecialMesh"); tipMesh.MeshType = Enum.MeshType.Pyramid; tipMesh.Parent = tip
    for side = -1, 1, 2 do
        piece("Ardillon", Vector3.new(0.12, 0.12, 0.85), CFrame.new(side * 0.2, 1.1, -4.15) * CFrame.Angles(0, side * -0.55, 0), steel)
        piece("Sandow", Vector3.new(0.18, 0.18, 3), CFrame.new(side * 0.45, 0.7, -1.5), dark)
        piece("Fourche de tête", Vector3.new(0.18, 0.4, 0.85), CFrame.new(side * 0.4, 0.85, -3.6), accent)
        for i = 1, 5 do
            piece("Rainure de préhension", Vector3.new(0.05, 0.6, 0.05), CFrame.new(side * 0.35, 0.4, 0.25 + i * 0.15) * CFrame.Angles(-0.2, 0, 0), dark)
        end
    end
    piece("Moulinet", Vector3.new(0.7, 0.75, 0.75), CFrame.new(0, -0.1, -1.1), dark, Enum.PartType.Cylinder)
    for side = -1, 1, 2 do
        piece("Flasque du moulinet", Vector3.new(0.1, 0.95, 0.95), CFrame.new(side * 0.4, -0.1, -1.1), accent, Enum.PartType.Cylinder)
        piece("Axe du moulinet", Vector3.new(0.16, 0.24, 0.24), CFrame.new(side * 0.49, -0.1, -1.1), steel, Enum.PartType.Cylinder)
    end
    for x = -0.25, 0.25, 0.1 do
        piece("Ligne enroulée", Vector3.new(0.04, 0.8, 0.8), CFrame.new(x, -0.1, -1.1), Color3.fromRGB(228, 215, 174), Enum.PartType.Cylinder)
    end
    piece("Guide de visée", Vector3.new(0.1, 0.23, 0.1), CFrame.new(0, 1.25, -3.5), accent)
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
