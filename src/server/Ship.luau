--!nonstrict
-- NÉRÉIDE: one continuous research vessel, eight personal galleries, one moonpool.
local Ship = {}
local navy = Color3.fromRGB(26, 75, 156)
local brass = Color3.fromRGB(255, 195, 56)
local ivory = Color3.fromRGB(247, 251, 255)
local teak = Color3.fromRGB(205, 141, 75)
local teal = Color3.fromRGB(36, 230, 212)
local steel = Color3.fromRGB(157, 181, 193)

local function solid(visuals, parent, name, size, frame, color, material, shape)
    local part = visuals.Part(parent, name, size, frame, color, material or Enum.Material.SmoothPlastic, shape)
    part.CanCollide = true; part.CanQuery = true; part.CastShadow = true
    return part
end

-- Rope mesh backed by native climbable trusses, not an ornamental flat panel.
local function rescueNet(vessel, config, visuals, side)
    local net = Instance.new("Model"); net.Name = "Filet de remontée"; net.Parent = vessel
    local bottom, top = config.WaterTop - 22, config.BaseHeight - 2
    local z = side * (config.DiveHalfLength - 2)
    local rope = Color3.fromRGB(224, 205, 160)
    for x = -12, 12, 4 do
        local climb = Instance.new("TrussPart"); climb.Name = "Prise de filet"
        climb.Size = Vector3.new(4, top - bottom, 2)
        climb.CFrame = CFrame.new(x, (bottom + top) / 2, z)
        climb.Anchored = true; climb.CanCollide = true; climb.Transparency = 1; climb.Parent = net
        visuals.Rod(net, "Corde verticale", Vector3.new(x, bottom, z - side * 1.1), Vector3.new(x, top, z - side * 1.1), 0.2, rope, Enum.Material.Fabric)
    end
    for y = bottom, top, 3 do
        visuals.Rod(net, "Maille du filet", Vector3.new(-14, y, z - side * 1.1), Vector3.new(14, y, z - side * 1.1), 0.2, rope, Enum.Material.Fabric)
    end
    for edge = -1, 1, 2 do
        visuals.Rod(net, "Ralingue renforcée", Vector3.new(edge * 14, bottom, z - side * 1.1), Vector3.new(edge * 14, top, z - side * 1.1), 0.45, rope, Enum.Material.Fabric)
        solid(visuals, net, "Fixation inox", Vector3.new(1.2, 1.2, 2.5), CFrame.new(edge * 14, top, z), steel, Enum.Material.Metal)
    end
    net:SetAttribute("ClimbBottom", bottom); net:SetAttribute("ClimbTop", top)
end

local function lifeRing(parent, position, visuals)
    for i = 1, 16 do
        local a, b = (i - 1) * math.pi / 8, i * math.pi / 8
        visuals.Rod(parent, "Bouée de sauvetage", position + Vector3.new(math.cos(a) * 2.1, math.sin(a) * 2.1, 0), position + Vector3.new(math.cos(b) * 2.1, math.sin(b) * 2.1, 0), 0.85, i % 4 == 0 and ivory or Color3.fromRGB(246, 112, 54))
    end
end

function Ship.Build(world, config, visuals)
    local vessel = Instance.new("Model"); vessel.Name = "NÉRÉIDE · Navire d'exploration"; vessel.Parent = world.Map
    world.Vessel = vessel
    local deckY = config.BaseHeight - 12
    local function block(name, size, pos, color, material)
        return solid(visuals, vessel, name, size, CFrame.new(pos), color, material)
    end
    -- Segmented hull/deck keeps the entire central diving shaft physically open.
    for side = -1, 1, 2 do
        block("Coque tribord/bâbord", Vector3.new(137, 24, 640), Vector3.new(side * 103.5, deckY - 14, 0), navy)
        block("Pont en teck", Vector3.new(137, 4, 640), Vector3.new(side * 103.5, deckY, 0), teak, Enum.Material.WoodPlanks)
        for edge = -1, 1, 2 do
            block("Ligne de flottaison", Vector3.new(2, 3, 640), Vector3.new(side * 173, config.WaterTop - 4 + edge * 2, 0), edge > 0 and ivory or brass)
        end
        for z = -312, 312, 16 do
            block("Joints du pont", Vector3.new(136, 0.04, 0.1), Vector3.new(side * 103.5, deckY + 2.02, z), Color3.fromRGB(66, 49, 38), Enum.Material.Wood)
        end
        for z = -310, 310, 26 do
            block("Chandelier de garde-corps", Vector3.new(1, 7, 1), Vector3.new(side * 170, deckY + 5.5, z), brass)
            local port = visuals.Part(vessel, "Hublot", Vector3.new(0.7, 6, 6), CFrame.new(side * 172.2, config.WaterTop, z), Color3.fromRGB(74, 148, 168), Enum.Material.Glass, Enum.PartType.Cylinder)
            port.Reflectance = 0.15
        end
        for height = 0, 1 do
            block("Lisse de sécurité", Vector3.new(1, 0.7, 638), Vector3.new(side * 170, deckY + 5 + height * 3, 0), ivory)
        end
    end
    for side = -1, 1, 2 do
        local length = 320 - config.DiveHalfLength
        local z = side * (config.DiveHalfLength + length / 2)
        block("Coque centrale", Vector3.new(70, 24, length), Vector3.new(0, deckY - 14, z), navy)
        local promenade = block("Promenade centrale", Vector3.new(70, 4, length), Vector3.new(0, deckY, z), ivory)
        promenade.TopSurface = Enum.SurfaceType.Smooth
        for x = -22, 22, 44 do
            block("Incrustation de promenade", Vector3.new(0.3, 0.08, length), Vector3.new(x, deckY + 2.05, z), steel, Enum.Material.Metal)
        end
        block("Cadre du bassin", Vector3.new(72, 3, 2), Vector3.new(0, deckY + 2, side * config.DiveHalfLength), brass)
        block("Marche du bassin", Vector3.new(28, 1, 9), Vector3.new(0, deckY + 3, side * (config.DiveHalfLength + 6)), navy)
    end
    -- Bow and stern create an unmistakable ocean liner silhouette.
    for i = 1, 6 do
        local width = 344 - i * 44
        block("Étrave profilée", Vector3.new(width, 22 - i, 12), Vector3.new(0, deckY - 14 + i * 0.35, -320 - i * 10), navy)
        block("Pont de proue", Vector3.new(width, 3, 12), Vector3.new(0, deckY - 0.5, -320 - i * 10), teak, Enum.Material.WoodPlanks)
    end
    block("Poupe", Vector3.new(330, 26, 9), Vector3.new(0, deckY - 12, 322), navy)
    block("Bandeau de poupe", Vector3.new(332, 4, 3), Vector3.new(0, deckY + 2, 328), ivory)
    -- Bridge, windows, stacks, antennas and cable stays.
    block("Passerelle de commandement", Vector3.new(100, 22, 40), Vector3.new(0, deckY + 14, 282), ivory)
    block("Verrière de la passerelle", Vector3.new(96, 10, 2), Vector3.new(0, deckY + 17, 260), Color3.fromRGB(49, 116, 140), Enum.Material.Glass)
    block("Toit de la passerelle", Vector3.new(108, 3, 48), Vector3.new(0, deckY + 27, 282), navy)
    for x = -40, 40, 16 do block("Meneau", Vector3.new(0.8, 12, 3), Vector3.new(x, deckY + 17, 259), brass) end
    for side = -1, 1, 2 do
        local stack = block("Cheminée", Vector3.new(14, 25, 14), Vector3.new(side * 36, deckY + 39, 288), navy)
        stack.Shape = Enum.PartType.Cylinder; stack.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
        stack.Size = Vector3.new(25, 14, 14)
        block("Marque de cheminée", Vector3.new(15, 4, 15), Vector3.new(side * 36, deckY + 46, 288), brass)
    end
    for z = -275, 210, 485 do
        local foot, top = Vector3.new(0, deckY + 4, z), Vector3.new(0, deckY + 65, z)
        visuals.Rod(vessel, "Mât", foot, top, 2, ivory, Enum.Material.Metal)
        for side = -1, 1, 2 do visuals.Rod(vessel, "Hauban", foot + Vector3.new(side * 65, 0, 20), top, 0.3, brass) end
        visuals.Part(vessel, "Radar", Vector3.new(22, 2, 5), CFrame.new(top + Vector3.new(0, 1, 0)), navy, Enum.Material.Metal)
    end
    local nameplate = visuals.Part(vessel, "Nom du navire", Vector3.one, CFrame.new(0, deckY + 36, 258), brass)
    nameplate.Transparency = 1
    visuals.Label(nameplate, "N É R É I D E\nEXPÉDITION OCÉANIQUE", ivory, 6, 650).TextSize = 30
    -- Both ends of the shared moonpool can be climbed without a teleport.
    for side = -1, 1, 2 do
        block("Margelle du bassin", Vector3.new(5, 3, 96), Vector3.new(side * 32.5, deckY + 1, 0), brass)
        rescueNet(vessel, config, visuals, side)
        lifeRing(vessel, Vector3.new(21, deckY + 7, side * (config.DiveHalfLength + 1)), visuals)
        local light = visuals.Part(vessel, "Balisage du bassin", Vector3.new(2, 1, 92), CFrame.new(side * 33, deckY + 2.8, 0), teal, Enum.Material.Neon)
        local point = Instance.new("PointLight"); point.Range = 32; point.Brightness = 1; point.Color = teal; point.Parent = light
    end
    local sign = visuals.Part(vessel, "Plongeoir commun", Vector3.one, CFrame.new(0, deckY + 6, 65), teal)
    sign.Transparency = 1
    visuals.Label(sign, "↓ PLONGER · FILETS POUR REMONTER", teal, 6, 180).TextSize = 18
    for z = 90, 220, 30 do
        visuals.Part(vessel, "Guide vers le bassin", Vector3.new(1.5, 0.12, 12), CFrame.new(0, deckY + 2.1, z), brass, Enum.Material.Neon)
    end
    world.DiveStart = Vector3.new(0, deckY + 7, 65)
    world.DiveWater = Vector3.new(0, config.WaterTop - 12, 0)
    world.SharedDeck = { OwnerId = 0, Center = Vector3.new(0, config.BaseHeight, 0),
        Min = Vector3.new(-174, config.WaterTop + 2, -388), Max = Vector3.new(174, config.SurfaceCeiling, 330) }
    world.SafeRegions = { world.SharedDeck }
    world.BasesFolder = world.Bases; world.Bases = {}
    for i = 1, config.MaxPlayers do
        local column = (i - 1) % 2 == 0 and -1 or 1
        local row = math.floor((i - 1) / 2)
        local center = Vector3.new(column * 104, config.BaseHeight, -195 + row * 130)
        local model = Instance.new("Model"); model.Name = "Base_" .. i; model.Parent = world.BasesFolder
        local plot = solid(visuals, model, "Galerie personnelle", Vector3.new(88, 0.4, 100), CFrame.new(center - Vector3.new(0, 9.8, 0)), navy, Enum.Material.Metal)
        plot.TopSurface = Enum.SurfaceType.Smooth
        solid(visuals, model, "Terrasse en teck", Vector3.new(82, 0.15, 94), CFrame.new(center + Vector3.new(0, -9.5, 0)), teak, Enum.Material.WoodPlanks)
        for z = -44, 44, 5.5 do
            visuals.Part(model, "Calfatage de la terrasse", Vector3.new(81, 0.03, 0.12), CFrame.new(center + Vector3.new(0, -9.4, z)), Color3.fromRGB(80, 59, 47), Enum.Material.Wood)
        end
        local rear = center + Vector3.new(0, 6, -47)
        solid(visuals, model, "Cloison de galerie", Vector3.new(84, 30, 1.2), CFrame.new(rear), navy, Enum.Material.Metal)
        solid(visuals, model, "Corniche de galerie", Vector3.new(86, 1, 3), CFrame.new(rear + Vector3.new(0, 15, 0)), ivory, Enum.Material.Metal)
        for x = -36, 36, 12 do
            visuals.Part(model, "Nervure de cloison", Vector3.new(0.2, 25, 0.2), CFrame.new(rear + Vector3.new(x, 0, 0.7)), steel, Enum.Material.Metal)
        end
        for side = -1, 1, 2 do
            require(game:GetService("ReplicatedStorage").Modules.Reef).Prop(model, "ship_cargo", center + Vector3.new(side * 35, -9.4, -35), 0.95, visuals, side * 0.3)
            visuals.Part(model, "Lumière de coursive", Vector3.new(0.25, 0.15, 86), CFrame.new(center + Vector3.new(side * 40, -9.2, 0)), teal, Enum.Material.Neon)
            solid(visuals, model, "Pilastre de galerie", Vector3.new(2.5, 33, 3), CFrame.new(center + Vector3.new(side * 41, 7, -45)), ivory, Enum.Material.Metal)
        end
        for side = -1, 1, 2 do
            visuals.Part(model, "Filet de laiton", Vector3.new(88, 0.15, 0.3), CFrame.new(center + Vector3.new(0, -9.5, side * 49)), brass, Enum.Material.Metal)
        end
        local lab = require(script.Parent.Laboratory).Build(model, center, visuals)
        local core, bench, prompt, upgrade = lab.Deposit, lab.Terminal, lab.HatchPrompt, lab.TerminalPrompt
        -- A separate, unmistakable upgrade board, away from the egg deposit.
        local signPos = center + Vector3.new(29, -3, 31)
        solid(visuals, model, "Pied de pancarte", Vector3.new(2, 7, 1.4), CFrame.new(signPos - Vector3.new(0, 3, 0)), navy, Enum.Material.Metal)
        local baseSign = visuals.Part(model, "Pancarte amélioration", Vector3.new(14, 6, 0.65), CFrame.new(signPos), brass)
        visuals.Label(baseSign, "⬆ AMÉLIORER LA BASE\nAQUARIUM · REVENUS · DÉCORS", ivory, 2, 110)
        local upgradeStatus = require(script.Parent.Laboratory).UpgradeBoard(model, baseSign, center, visuals)
        local upgradeBase = Instance.new("ProximityPrompt"); upgradeBase.ActionText = "Améliorer ma base"; upgradeBase.ObjectText = "Pancarte d’amélioration"
        upgradeBase.KeyboardKeyCode = Enum.KeyCode.F; upgradeBase.MaxActivationDistance = 12; upgradeBase.RequiresLineOfSight = false; upgradeBase.Parent = baseSign
        for side = -1, 1, 2 do
            for z = -45, 15, 15 do
                solid(visuals, model, "Chandelier de galerie", Vector3.new(0.6, 6, 0.6), CFrame.new(center + Vector3.new(side * 42, -6.5, z)), steel, Enum.Material.Metal)
            end
            local glass = solid(visuals, model, "Garde-corps vitré", Vector3.new(0.25, 4.4, 60), CFrame.new(center + Vector3.new(side * 42, -6.7, -15)), Color3.fromRGB(194, 232, 242), Enum.Material.Glass)
            glass.Transparency = 0.72; glass.Reflectance = 0.06
            solid(visuals, model, "Main courante inox", Vector3.new(0.8, 0.5, 62), CFrame.new(center + Vector3.new(side * 42, -3.5, -15)), steel, Enum.Material.Metal)
        end
        local marker = visuals.Part(model, "Identité du propriétaire", Vector3.one, CFrame.new(center + Vector3.new(0, 38, -8)), brass)
        marker.Transparency = 1
        local gui = Instance.new("BillboardGui"); gui.Name = "Identité"; gui.Size = UDim2.fromScale(30, 18)
        gui.MaxDistance = 750; gui.AlwaysOnTop = false; gui.Parent = marker
        local portrait = Instance.new("ImageLabel"); portrait.Name = "Portrait"; portrait.Size = UDim2.fromScale(0.28, 0.48)
        portrait.Position = UDim2.fromScale(0.36, 0); portrait.BackgroundColor3 = navy; portrait.BackgroundTransparency = 0.1; portrait.Parent = gui
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1, 0); corner.Parent = portrait
        local label = Instance.new("TextLabel"); label.Name = "Pseudo"; label.Size = UDim2.fromScale(1, 0.32)
        label.Position = UDim2.fromScale(0, 0.53); label.BackgroundTransparency = 1; label.TextColor3 = ivory
        label.Font = Enum.Font.GothamBlack; label.TextSize = 34; label.TextScaled = true; label.TextWrapped = true; label.TextStrokeTransparency = 0.35
        label.Text = "GALERIE DISPONIBLE"; label.Parent = gui
        local tier = label:Clone(); tier.Name = "Niveau"; tier.Position = UDim2.fromScale(0, 0.86); tier.Size = UDim2.fromScale(1, 0.14)
        tier.TextSize = 19; tier.TextColor3 = brass; tier.Text = "AQUARIUM · NIVEAU 1"; tier.Parent = gui
        local base = { Model = model, Center = center, Spawn = center + Vector3.new(0, -6, 37), TankCenter = center + Vector3.new(0, 8, -10),
            UpgradeStatus = upgradeStatus, Lab = lab, IncubationCenter = lab.Center, Core = core, Bench = bench, BaseSign = baseSign, HatchPrompt = prompt, UpgradePrompt = upgrade, BasePrompt = upgradeBase, Label = label, Avatar = portrait, TierLabel = tier, Marker = marker,
            Min = center + Vector3.new(-44, -16, -50), Max = center + Vector3.new(44, 80, 50),
            OwnerId = 0, Swimmers = {}, Incubators = {}, Level = 0 }
        table.insert(world.Bases, base)
        Ship.Aquarium(base, 1, config, visuals)
    end
    require(script.Parent.Merchants).Build(world, config, visuals)
end

function Ship.Aquarium(base, level, config, visuals)
    local old = base.Model:FindFirstChild("Aquarium géant"); if old then old:Destroy() end
    local tank = Instance.new("Model"); tank.Name = "Aquarium géant"; tank.Parent = base.Model
    local width, height, depth = 52 + level * 2, 24 + level * 2.4, 29 + level
    -- Upgrade upward: the pedestal stays on the deck instead of sinking into it.
    base.TankAnchor = base.TankAnchor or base.TankCenter
    local lift = (height - 26.4) / 2
    local center = base.TankAnchor + Vector3.new(0, lift, 0)
    base.TankCenter = center
    if base.Marker then base.Marker.CFrame = CFrame.new(base.Center + Vector3.new(0, 38 + lift, -8)) end
    local accent = level >= 3 and brass or teal
    local function piece(name, size, pos, color, material)
        return solid(visuals, tank, name, size, CFrame.new(pos), color, material)
    end
    piece("Socle sculpté", Vector3.new(width + 5, 5, depth + 5), center - Vector3.new(0, height / 2 + 2, 0), navy, Enum.Material.Metal)
    piece("Plinthe ivoire", Vector3.new(width + 6, 0.8, depth + 6), center - Vector3.new(0, height / 2 + 4, 0), ivory, Enum.Material.Metal)
    piece("Bandeau en laiton", Vector3.new(width + 6, 0.6, depth + 6), center - Vector3.new(0, height / 2 - 0.3, 0), brass)
    piece("Couronne technique", Vector3.new(width + 5, 2, depth + 5), center + Vector3.new(0, height / 2, 0), ivory, Enum.Material.Metal)
    piece("Capot de filtration", Vector3.new(width + 2, 0.6, depth + 2), center + Vector3.new(0, height / 2 + 1.3, 0), navy, Enum.Material.Metal)
    for x = -width / 2 + 4, width / 2 - 4, 4 do
        visuals.Part(tank, "Grille de ventilation", Vector3.new(0.6, 0.08, depth - 5), CFrame.new(center + Vector3.new(x, height / 2 + 1.65, 0)), steel, Enum.Material.Metal)
    end
    local water = visuals.Part(tank, "Eau claire", Vector3.new(width - 1, height - 2, depth - 1), CFrame.new(center), Color3.fromRGB(64, 166, 184))
    water.Transparency = 0.95
    for side = -1, 1, 2 do
        local pane = piece("Vitre latérale", Vector3.new(0.35, height, depth), center + Vector3.new(side * width / 2, 0, 0), Color3.fromRGB(188, 237, 240), Enum.Material.Glass)
        pane.Transparency = 0.86; pane.Reflectance = 0.08
        pane = piece("Vitre panoramique", Vector3.new(width, height, 0.35), center + Vector3.new(0, 0, side * depth / 2), Color3.fromRGB(188, 237, 240), Enum.Material.Glass)
        pane.Transparency = side > 0 and 0.9 or 0.55
        for edge = -1, 1, 2 do
            piece("Montant brossé", Vector3.new(0.9, height + 2, 0.9), center + Vector3.new(side * width / 2, 0, edge * depth / 2), brass)
        end
    end
    piece("Sable nacré", Vector3.new(width - 1, 1, depth - 1), center - Vector3.new(0, height / 2 - 1, 0), Color3.fromRGB(255, 230, 151), Enum.Material.Sand)
    local lightBar = visuals.Part(tank, "Rampe lumineuse", Vector3.new(width - 4, 0.2, 0.8), CFrame.new(center + Vector3.new(0, height / 2 - 1.5, depth / 2 - 2)), accent, Enum.Material.Neon)
    local lamp = Instance.new("PointLight"); lamp.Color = Color3.fromRGB(164, 235, 239); lamp.Range = 38; lamp.Brightness = 1.5 + level * 0.2; lamp.Parent = lightBar
    -- Clear display: no coral or rock sculptures, including after an upgrade.
    for i = -2, 2 do
        local x = i * (width - 10) / 5
        piece("Trappe de maintenance", Vector3.new((width - 12) / 5, 2.8, 0.12), center + Vector3.new(x, -height / 2 - 2, depth / 2 + 2.56), steel, Enum.Material.Metal)
        visuals.Part(tank, "Témoin de filtration", Vector3.new(0.6, 0.16, 0.15), CFrame.new(center + Vector3.new(x, -height / 2 - 1.4, depth / 2 + 2.65)), accent, Enum.Material.Neon)
    end
    for side = -1, 1, 2 do
        local air = visuals.Part(tank, "Diffuseur de bulles", Vector3.new(1, 0.3, depth - 4), CFrame.new(center + Vector3.new(side * (width / 2 - 3), -height / 2 + 1.6, 0)), ivory)
        local bubbles = Instance.new("ParticleEmitter"); bubbles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        bubbles.Color = ColorSequence.new(Color3.fromRGB(194, 246, 255)); bubbles.Rate = 4
        bubbles.Lifetime = NumberRange.new(2, 4); bubbles.Speed = NumberRange.new(3, 5); bubbles.Size = NumberSequence.new(0.18)
        bubbles.LightEmission = 0.7; bubbles.Parent = air
    end
    if level >= 2 then
        for side = -1, 1, 2 do
            piece("Filtre pressurisé", Vector3.new(4, height * 0.8, 4), center + Vector3.new(side * (width / 2 + 4), 0, -depth / 2 + 2), navy)
        end
    end
    if level >= 4 then
        for side = -1, 1, 2 do
            visuals.Part(tank, "Balisage premium", Vector3.new(0.3, 0.3, depth - 2), CFrame.new(center + Vector3.new(side * (width / 2 + 1), height / 2 + 1.65, 0)), accent, Enum.Material.Neon)
        end
    end
    base.Display = Instance.new("Folder"); base.Display.Name = "Animaux"; base.Display.Parent = tank
    base.EggDisplay = base.Lab.Display
    base.Level = level; base.Swimmers = {}; base.Incubators = {}
    base.TierLabel.Text = config.BaseUpgrades[level].Name:upper() .. " · NIVEAU " .. level
    tank:SetAttribute("BaseLevel", level)
end

return Ship
