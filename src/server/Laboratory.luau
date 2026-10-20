--!nonstrict
local Laboratory = {}
local navy, metal = Color3.fromRGB(21, 48, 76), Color3.fromRGB(202, 218, 226)
local cyan, white = Color3.fromRGB(66, 224, 241), Color3.fromRGB(242, 251, 255)
function Laboratory.Build(parent, center, visuals)
    local lab = Instance.new("Model"); lab.Name = "Laboratoire d’incubation"; lab.Parent = parent
    local function piece(name, size, pos, color, material, shape, frame)
        return visuals.Part(lab, name, size, frame or CFrame.new(pos), color, material, shape)
    end
    local tankCenter = center + Vector3.new(0, 0.4, 21)
    -- A sealed panoramic oval tank, physically separate from the fish aquarium.
    piece("Socle de la cuve", Vector3.new(30, 2, 17), tankCenter - Vector3.new(0, 6.6, 0), navy, Enum.Material.Metal)
    for side = -1, 1, 2 do
        for z = -1, 1, 2 do piece("Pied amortisseur", Vector3.new(2.6, 2.4, 2.6), tankCenter + Vector3.new(side * 11, -8, z * 5), metal, Enum.Material.Metal) end
        visuals.Rod(lab, "Conduite de filtration", tankCenter + Vector3.new(side * 14, -5, -4), tankCenter + Vector3.new(side * 14, 4, -4), 1, metal, Enum.Material.Metal)
    end
    local glass = piece("Cuve vitrée", Vector3.new(11, 27, 14), tankCenter, Color3.fromRGB(174, 237, 255), Enum.Material.Glass, Enum.PartType.Cylinder, CFrame.new(tankCenter) * CFrame.Angles(0, 0, math.pi / 2))
    glass.Transparency = 0.86; glass.Reflectance = 0.05; glass.CanCollide = true; glass.CanQuery = true
    local water = piece("Liquide d’incubation", Vector3.new(9.8, 25.6, 12.6), tankCenter, Color3.fromRGB(45, 171, 206), nil, Enum.PartType.Cylinder, CFrame.new(tankCenter) * CFrame.Angles(0, 0, math.pi / 2))
    water.Transparency = 0.96
    for side = -1, 1, 2 do
        piece("Cerclage de la cuve", Vector3.new(0.7, 28, 15), tankCenter + Vector3.new(0, side * 5.5, 0), white, Enum.Material.Metal, Enum.PartType.Cylinder, CFrame.new(tankCenter + Vector3.new(0, side * 5.5, 0)) * CFrame.Angles(0, 0, math.pi / 2))
        piece("Éclairage de la cuve", Vector3.new(24, 0.18, 0.25), tankCenter + Vector3.new(0, side * 4.8, 5.8), cyan, Enum.Material.Neon)
    end
    for i = 1, 4 do
        piece("Coupelle d’éclosion", Vector3.new(4.8, 0.3, 10), tankCenter + Vector3.new((i - 2.5) * 6, -4.3, 0), metal, Enum.Material.Metal)
    end
    local lamp = Instance.new("PointLight"); lamp.Color = cyan; lamp.Range = 23; lamp.Brightness = 1.3; lamp.Parent = glass
    local display = Instance.new("Folder"); display.Name = "Œufs en incubation"; display.Parent = lab
    local deposit = piece("Dépôt des œufs", Vector3.new(10, 2, 3.5), center + Vector3.new(0, -6, 33), navy, Enum.Material.Metal)
    piece("Lecteur de capsules", Vector3.new(7.5, 0.2, 2), deposit.Position + Vector3.new(0, 1.1, 0), cyan, Enum.Material.Neon)
    visuals.Label(deposit, "CUVE D’ÉCLOSION\nE · DÉPOSER UN ŒUF", white, 3.5, 100)
    local hatch = Instance.new("ProximityPrompt"); hatch.ActionText = "Déposer dans la cuve"; hatch.ObjectText = "Incubateur sécurisé"
    hatch.MaxActivationDistance = 12; hatch.HoldDuration = 0.3; hatch.RequiresLineOfSight = false; hatch.Parent = deposit

    -- Desktop tower, keyboard, tilted monitor, power lights and a real screen.
    local desk = center + Vector3.new(-29, -6, 32)
    piece("Bureau informatique", Vector3.new(16, 0.8, 10), desk - Vector3.new(0, 0.7, 0), white)
    for side = -1, 1, 2 do piece("Pied de bureau", Vector3.new(1, 4, 7), desk + Vector3.new(side * 6.5, -3, 0), navy, Enum.Material.Metal) end
    local terminal = piece("Console marchands", Vector3.new(10, 0.6, 4), desk + Vector3.new(0, 0.1, 2), navy)
    for row = 1, 3 do
        for col = 1, 10 do piece("Touche du clavier", Vector3.new(0.6, 0.15, 0.55), terminal.Position + Vector3.new((col - 5.5) * 0.8, 0.4, row * 0.7 - 1.4), metal) end
    end
    piece("Pied d’écran", Vector3.new(2, 3, 1.5), desk + Vector3.new(0, 1.3, -1.6), metal, Enum.Material.Metal)
    piece("Écran d’ordinateur", Vector3.new(13.5, 7.8, 0.7), desk + Vector3.new(0, 5.2, -1.6), navy, nil, nil, CFrame.new(desk + Vector3.new(0, 5.2, -1.6)) * CFrame.Angles(-0.12, 0, 0))
    local screen = piece("Dalle de téléportation", Vector3.new(12.6, 6.9, 0.12), desk + Vector3.new(0, 5.2, -1.12), Color3.fromRGB(7, 27, 45), Enum.Material.SmoothPlastic)
    local gui = Instance.new("SurfaceGui"); gui.Name = "Interface de l’ordinateur"; gui.Face = Enum.NormalId.Back; gui.CanvasSize = Vector2.new(800, 440); gui.Parent = screen
    local text = Instance.new("TextLabel"); text.BackgroundTransparency = 1; text.Size = UDim2.fromScale(0.9, 0.8); text.Position = UDim2.fromScale(0.05, 0.1)
    text.Font = Enum.Font.GothamBold; text.TextSize = 36; text.TextWrapped = true; text.TextColor3 = cyan; text.Text = "NÉRÉIDE // TRANSFERT\n\n7 MARCHANDS DISPONIBLES\n[E] CHOISIR UNE DESTINATION"; text.Parent = gui
    piece("Unité centrale", Vector3.new(3, 6, 6), desk + Vector3.new(9, -1.7, 0), navy, Enum.Material.Metal)
    for i = 1, 3 do piece("Voyant d’alimentation", Vector3.new(0.8, 0.15, 0.15), desk + Vector3.new(9, i * 0.5 - 0.7, 3.1), cyan, Enum.Material.Neon) end
    local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Téléportation marchands"; prompt.ObjectText = "Ordinateur de la galerie"
    prompt.RequiresLineOfSight = false; prompt.MaxActivationDistance = 12; prompt.Parent = terminal
    visuals.Label(terminal, "ORDINATEUR\nE · REJOINDRE UN MARCHAND", cyan, 9, 100)
    return { Model = lab, Center = tankCenter, Display = display, Deposit = deposit, HatchPrompt = hatch, Terminal = terminal, TerminalPrompt = prompt }
end
function Laboratory.UpgradeBoard(parent, board, center, visuals)
    local gold = Color3.fromRGB(255, 196, 65)
    local pad = visuals.Part(parent, "Plateforme d’amélioration", Vector3.new(0.65, 18, 18), CFrame.new(center + Vector3.new(29, -9, 31)) * CFrame.Angles(0, 0, math.pi / 2), navy, Enum.Material.Metal, Enum.PartType.Cylinder)
    pad.CanCollide = true
    for side = -1, 1, 2 do
        visuals.Part(parent, "Montant d’amélioration", Vector3.new(1, 8, 1), CFrame.new(board.Position + Vector3.new(side * 7.7, -0.4, 0)), metal, Enum.Material.Metal)
        visuals.Part(parent, "Liseré d’amélioration", Vector3.new(0.25, 6, 0.25), CFrame.new(board.Position + Vector3.new(side * 7.1, -0.4, 0.6)), gold, Enum.Material.Neon)
    end
    local screen = visuals.Part(parent, "Écran des améliorations", Vector3.new(13.2, 4.7, 0.1), CFrame.new(board.Position + Vector3.new(0, 0, 0.42)), navy)
    local gui = Instance.new("SurfaceGui"); gui.Face = Enum.NormalId.Back; gui.CanvasSize = Vector2.new(740, 300); gui.Parent = screen
    local text = Instance.new("TextLabel"); text.BackgroundTransparency = 1; text.Size = UDim2.fromScale(1, 1)
    text.Font = Enum.Font.GothamBold; text.TextSize = 38; text.TextWrapped = true; text.TextColor3 = gold; text.Text = "GALERIE · NIVEAU 1\n[F] AMÉLIORER"; text.Parent = gui
    return text
end
return Laboratory
