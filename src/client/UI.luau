--!nonstrict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local UI = {}
UI.__index = UI
local C = { Navy = Color3.fromRGB(8, 24, 39), Panel = Color3.fromRGB(14, 38, 55), White = Color3.fromRGB(232, 249, 250),
    Muted = Color3.fromRGB(137, 175, 188), Teal = Color3.fromRGB(106, 247, 210), Gold = Color3.fromRGB(255, 206, 114), Red = Color3.fromRGB(255, 120, 139) }
local function make(class, parent, props)
    local item = Instance.new(class)
    for key, value in pairs(props or {}) do item[key] = value end
    item.Parent = parent
    return item
end
local function round(item, radius) make("UICorner", item, { CornerRadius = UDim.new(0, radius or 12) }) end
local function label(parent, text, size, color, props)
    local item = make("TextLabel", parent, { BackgroundTransparency = 1, Font = Enum.Font.Gotham,
        Text = text, TextSize = size or 15, TextColor3 = color or C.White, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true })
    for key, value in pairs(props or {}) do item[key] = value end
    return item
end
local function button(parent, text, props, callback)
    local item = make("TextButton", parent, { Text = text, Font = Enum.Font.GothamBold, TextSize = 14,
        TextColor3 = C.Navy, BackgroundColor3 = C.Teal, BorderSizePixel = 0, AutoButtonColor = true })
    for key, value in pairs(props or {}) do item[key] = value end
    round(item, 9)
    if callback then item.Activated:Connect(callback) end
    return item
end
local function panel(parent, props)
    local item = make("Frame", parent, { BackgroundColor3 = C.Panel, BackgroundTransparency = 0.08, BorderSizePixel = 0 })
    for key, value in pairs(props or {}) do item[key] = value end
    round(item)
    make("UIStroke", item, { Color = Color3.fromRGB(46, 94, 108), Transparency = 0.4, Thickness = 1 })
    return item
end
function UI.Format(value)
    if value >= 1e9 then return string.format("%.1f Md", value / 1e9) end
    if value >= 1e6 then return string.format("%.1f M", value / 1e6) end
    if value >= 1000 then return string.format("%.1f k", value / 1000) end
    return tostring(math.floor(value))
end

function UI.new(context)
    local self = setmetatable({ Ctx = context, Notices = {}, Tab = nil, Signature = "", Ascend = 0, Descend = 0, Ingredients = {}, RankBy = "Money" }, UI)
    local gui = make("ScreenGui", Players.LocalPlayer:WaitForChild("PlayerGui"), { Name = "UnderwaterEggUI", ResetOnSpawn = false, DisplayOrder = 10, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
    self.Gui = gui
    local root = make("Frame", gui, { Name = "HUD", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
    self.Root = root
    self.Scale = make("UIScale", root, { Scale = 1 })
    local function resize()
        local size = workspace.CurrentCamera.ViewportSize
        local scale = math.clamp(size.Y / 900, 0.72, 1.1)
        self.Scale.Scale = scale; root.Size = UDim2.fromScale(1 / scale, 1 / scale)
    end
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize); resize()
    local top = panel(root, { Position = UDim2.fromOffset(20, 18), Size = UDim2.new(1, -40, 0, 84) })
    label(top, "UNDERWATER\nEGG", UserInputService.TouchEnabled and 16 or 23, C.Teal, { Position = UDim2.fromOffset(18, 12), Size = UDim2.new(0.23, -18, 1, -24), Font = Enum.Font.GothamBlack })
    local function stat(x, title)
        local frame = make("Frame", top, { BackgroundTransparency = 1, Position = UDim2.fromScale(x, 0), Size = UDim2.fromScale(0.24, 1) })
        label(frame, title, 11, C.Muted, { Position = UDim2.fromOffset(8, 12), Size = UDim2.new(1, -12, 0, 16) })
        return frame, label(frame, "…", 22, C.White, { Position = UDim2.fromOffset(8, 30), Size = UDim2.new(1, -12, 0, 28), Font = Enum.Font.GothamBold })
    end
    local moneyFrame; moneyFrame, self.Money = stat(0.25, "GOLD")
    self.Income = label(moneyFrame, "+0 gold / min", 11, C.Teal, { Position = UDim2.fromOffset(8, 61), Size = UDim2.new(1, -12, 0, 15) })
    local oxygenFrame; oxygenFrame, self.Oxygen = stat(0.50, "RÉSERVE D'OXYGÈNE")
    local track = make("Frame", oxygenFrame, { Position = UDim2.new(0, 8, 0, 65), Size = UDim2.new(1, -20, 0, 5), BackgroundColor3 = C.Navy, BorderSizePixel = 0 }); round(track, 4)
    self.OxygenBar = make("Frame", track, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Teal, BorderSizePixel = 0 }); round(self.OxygenBar, 4)
    local depthFrame; depthFrame, self.Depth = stat(0.75, "PROFONDEUR")
    self.Floor = label(depthFrame, "RÉCIF", 11, C.Muted, { Position = UDim2.fromOffset(8, 61), Size = UDim2.new(1, -12, 0, 15) })
    local menu = make("Frame", root, { Position = UDim2.fromOffset(20, 126), Size = UDim2.fromOffset(152, 460), BackgroundTransparency = 1 })
    label(menu, "VOTRE EXPÉDITION", 10, C.Muted, { Size = UDim2.fromOffset(152, 18) })
    for i, entry in ipairs({ { "Collection", "ŒUFS & ANIMAUX" }, { "Bestiaire", "BESTIAIRE" }, { "Équipement", "ÉQUIPEMENT" }, { "Fusion", "FUSION" }, { "Prestige", "PRESTIGE" }, { "Habitat", "PERSONNALISER" }, { "Classement", "CLASSEMENT" }, { "Guide", "COMMENT JOUER" } }) do
        button(menu, entry[2], { Position = UDim2.fromOffset(0, 26 + (i - 1) * 48), Size = UDim2.fromOffset(152, 40), BackgroundColor3 = C.Panel, TextColor3 = C.White, TextSize = 12 }, function() self:Open(entry[1]) end)
    end
    button(menu, "ÉQUIPER LE HARPON", { Position = UDim2.fromOffset(0, 416), Size = UDim2.fromOffset(152, 42), TextSize = 11 }, function() context.Equip() end)
    self.Home = button(root, "RETOUR À L'HABITAT", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -80), Size = UDim2.fromOffset(180, 38), BackgroundColor3 = C.Panel, TextColor3 = C.Muted, TextSize = 11 }, function() context.Action:FireServer("Return") end)
    self.EventPanel = panel(root, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 126), Size = UDim2.fromOffset(248, 106) })
    label(self.EventPanel, "L'OCÉAN EST VIVANT", 10, C.Muted, { Position = UDim2.fromOffset(14, 10), Size = UDim2.fromOffset(220, 15) })
    self.EventName = label(self.EventPanel, "Prochain phénomène", 15, C.White, { Position = UDim2.fromOffset(14, 31), Size = UDim2.fromOffset(220, 24), Font = Enum.Font.GothamBold })
    self.EventTimer = label(self.EventPanel, "05:00", 21, C.Teal, { Position = UDim2.fromOffset(14, 61), Size = UDim2.fromOffset(220, 28), Font = Enum.Font.GothamBold })
    self.ToastBox = make("Frame", root, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 245), Size = UDim2.fromOffset(248, 390), BackgroundTransparency = 1 })
    make("UIListLayout", self.ToastBox, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    self.Objective = label(root, "TROUVEZ UN ŒUF  →  ÉVITEZ SON GARDIEN  →  REVENEZ À VOTRE HABITAT", 12, C.White,
        { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -46), Size = UDim2.new(1, -50, 0, 28), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold })
    self.Help = label(root, "WASD · NAGER    ESPACE / CTRL · MONTER / DESCENDRE    SHIFT · PROPULSEUR    CLIC · HARPON", 10, C.Muted,
        { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -15), Size = UDim2.new(1, -40, 0, 24), TextXAlignment = Enum.TextXAlignment.Center })
    self.Compass = label(root, "Votre habitat", 12, C.Teal, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 106), Size = UDim2.new(0.5, -24, 0, 18), TextXAlignment = Enum.TextXAlignment.Right })
    self.Save = label(root, "CONNEXION AU SERVEUR…", 10, C.Muted, { Position = UDim2.fromOffset(22, 106), Size = UDim2.new(0.5, -24, 0, 16) })
    self.Cooldown = label(root, "HARPON PRÊT", 11, C.Teal, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -84), Size = UDim2.fromOffset(220, 20), TextXAlignment = Enum.TextXAlignment.Right })
    self.Reticle = label(root, "+", 26, C.Teal, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(28, 28), TextXAlignment = Enum.TextXAlignment.Center, Visible = false, ZIndex = 2 })
    self.Dimmer = make("TextButton", root, { Size = UDim2.fromScale(1, 1), Text = "", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, Visible = false, ZIndex = 20 })
    self.Dimmer.Activated:Connect(function() self:Open(nil) end)
    self.Modal = panel(root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.new(0.88, 0, 0.76, 0), Visible = false, ZIndex = 21 })
    self.Title = label(self.Modal, "", 27, C.White, { Position = UDim2.fromOffset(24, 18), Size = UDim2.new(1, -90, 0, 44), Font = Enum.Font.GothamBold, ZIndex = 22 })
    button(self.Modal, "×", { Position = UDim2.new(1, -54, 0, 20), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = C.Navy, TextColor3 = C.White, TextSize = 24, ZIndex = 22 }, function() self:Open(nil) end)
    self.List = make("ScrollingFrame", self.Modal, { Position = UDim2.fromOffset(24, 78), Size = UDim2.new(1, -48, 1, -100), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 4, ScrollBarImageColor3 = C.Teal, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 22 })
    if UserInputService.TouchEnabled then
        self.Help.Text = "JOYSTICK · NAGER    ↑ / ↓ · PROFONDEUR    TIRER · HARPON"
        self.Home.Position = UDim2.new(0, 20, 1, -152)
        local function hold(text, x, field)
            local b = button(root, text, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, x, 1, -118), Size = UDim2.fromOffset(72, 66), TextSize = 24 })
            b.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then self[field] = 1 end end)
            b.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then self[field] = 0 end end)
        end
        hold("↑", -104, "Ascend"); hold("↓", -24, "Descend")
        button(root, "TIRER", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -194), Size = UDim2.fromOffset(152, 58) }, context.Fire)
        self.BoostButton = button(root, "BOOST", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -262), Size = UDim2.fromOffset(152, 48), BackgroundColor3 = C.Gold }, function() context.Action:FireServer("Boost") end)
    end
    return self
end

function UI:Toast(message, tone)
    local rarity = self.Ctx.Config.Rarities[tone]
    local color = rarity and self.Ctx.Visuals.Color(rarity.Color) or (tone == "Warning" and C.Gold or C.Teal)
    local frame = panel(self.ToastBox, { Size = UDim2.fromOffset(248, 82) })
    make("Frame", frame, { Size = UDim2.new(0, 3, 1, -20), Position = UDim2.fromOffset(0, 10), BackgroundColor3 = color, BorderSizePixel = 0 })
    label(frame, message, 12, color, { Position = UDim2.fromOffset(13, 8), Size = UDim2.new(1, -24, 1, -16), Font = Enum.Font.GothamMedium })
    table.insert(self.Notices, frame)
    while #self.Notices > 4 do local old = table.remove(self.Notices, 1); old:Destroy() end
    task.delay(7, function()
        local index = table.find(self.Notices, frame)
        if index then table.remove(self.Notices, index); frame:Destroy() end
    end)
end

function UI:Open(tab)
    if tab ~= "Prestige" then self.PrestigeArmedAt = nil end
    self.Tab = tab; self.Signature = ""
    self.Modal.Visible = tab ~= nil; self.Dimmer.Visible = tab ~= nil
    if tab then self:RenderPanel() end
end

function UI:Viewport(parent, spec)
    local viewport = make("ViewportFrame", parent, { BackgroundTransparency = 1, Position = UDim2.fromOffset(2, 3), Size = UDim2.fromOffset(104, 92), Ambient = Color3.fromRGB(185, 211, 226), LightColor = Color3.new(1, 1, 1), ZIndex = 24 })
    local world = make("WorldModel", viewport)
    self.Ctx.Visuals.Animal(world, spec, CFrame.new(), 1)
    local camera = make("Camera", viewport, { CFrame = CFrame.lookAt(Vector3.new(7, 3, -10), Vector3.new(0, -0.5, 0)), FieldOfView = 42 })
    viewport.CurrentCamera = camera
end

function UI:Row(height)
    return panel(self.List, { Size = UDim2.new(1, -8, 0, height or 100), BackgroundColor3 = C.Navy, ZIndex = 23 })
end

function UI:RenderPanel()
    local state = self.State
    if not self.Tab or not state then return end
    local config, rules = self.Ctx.Config, self.Ctx.Rules
    local position = self.List.CanvasPosition
    self.List:ClearAllChildren()
    make("UIListLayout", self.List, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    self.Title.Text = self.Tab
    local function paragraph(text, height, color)
        local row = self:Row(height or 72)
        label(row, text, 14, color or C.Muted, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 1, -20), ZIndex = 24 })
    end
    self.HatchTimers = {}
    if self.Tab == "Collection" then
        paragraph(string.format("%d œuf(s) sécurisé(s)  ·  %d animaux  ·  +%s gold / min\nDéposez les œufs dans l'aquarium : les animaux produisent des gold pendant votre connexion.", #state.Eggs, rules.AnimalCount(state), UI.Format(state.Income)), 70, C.Teal)
        for _, egg in ipairs(state.Eggs) do
            local row = self:Row(112)
            local color = self.Ctx.Visuals.Color(config.Rarities[egg.Rarity].Color)
            label(row, "ŒUF SÉCURISÉ  /  " .. string.upper(egg.Rarity), 11, color, { Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -180, 0, 20), ZIndex = 24 })
            label(row, egg.Name, 18, C.White, { Position = UDim2.fromOffset(16, 38), Size = UDim2.new(1, -180, 0, 32), Font = Enum.Font.GothamBold, ZIndex = 24 })
            local timer = label(row, "", 12, color, { Position = UDim2.fromOffset(16, 76), Size = UDim2.new(1, -32, 0, 24), ZIndex = 24 })
            if egg.ReadyAt then table.insert(self.HatchTimers, { Egg = egg, Label = timer })
            else timer.Text = "Durée : " .. config.HatchTimes[egg.Rarity] .. " s après dépôt" end
            local enabled = state.OwnBase and not egg.ReadyAt
            button(row, egg.ReadyAt and "EN INCUBATION" or state.OwnBase and "DÉPOSER" or "SUR VOTRE ÎLE", { Position = UDim2.new(1, -160, 0, 26), Size = UDim2.fromOffset(144, 38), TextSize = 12, BackgroundColor3 = enabled and C.Teal or C.Panel, TextColor3 = enabled and C.Navy or C.Muted, ZIndex = 24 }, function() if enabled then self.Ctx.Action:FireServer("Hatch", egg.Id) end end)
        end
        local ids = {}; for id in pairs(config.Animals) do if rules.SpeciesCount(state, id) > 0 then table.insert(ids, id) end end
        table.sort(ids, function(a, b) return config.Animals[a].Income > config.Animals[b].Income end)
        for _, id in ipairs(ids) do
            local spec = config.Animals[id]; local row = self:Row(118)
            self:Viewport(row, spec)
            label(row, spec.Name .. "  ×" .. rules.SpeciesCount(state, id), 18, C.White, { Position = UDim2.fromOffset(114, 18), Size = UDim2.new(1, -130, 0, 28), Font = Enum.Font.GothamBold, ZIndex = 24 })
            label(row, string.upper(spec.Rarity) .. "  ·  PALIER " .. spec.Floor .. "  ·  " .. UI.Format(spec.Income) .. " gold / min chacun", 12, self.Ctx.Visuals.Color(config.Rarities[spec.Rarity].Color), { Position = UDim2.fromOffset(114, 52), Size = UDim2.new(1, -130, 0, 32), ZIndex = 24 })
            local variants = state.Variants[id] or {}
            label(row, "NORMAL " .. (state.Animals[id] or 0) .. " · GOLD " .. (variants.Gold or 0) .. " · DIAMOND " .. (variants.Diamond or 0) .. " · MYTHIC " .. (variants.Mythic or 0), 10, C.Gold, { Position = UDim2.fromOffset(114, 86), Size = UDim2.new(1, -130, 0, 24), ZIndex = 24 })
        end
        if #ids == 0 and #state.Eggs == 0 then paragraph("Votre collection commence avec votre première plongée.\nCherchez un œuf lumineux au récif, puis rapportez-le dans votre île de surface.", 100) end
    elseif self.Tab == "Bestiaire" then
        local ids, discovered = {}, 0
        for id in pairs(config.Animals) do table.insert(ids, id); if state.Discovered[id] then discovered += 1 end end
        table.sort(ids, function(a, b) local x, y = config.Animals[a], config.Animals[b]; return x.Floor == y.Floor and x.Income < y.Income or x.Floor < y.Floor end)
        paragraph(discovered .. " / " .. #ids .. " espèces découvertes · Les espèces inconnues restent mystérieuses.", 60, C.Teal)
        for _, id in ipairs(ids) do
            local spec = config.Animals[id]; local known = state.Discovered[id]; local row = self:Row(138)
            if known then self:Viewport(row, spec) else label(row, "?", 48, C.Muted, { Position = UDim2.fromOffset(26, 18), Size = UDim2.fromOffset(60, 64), Font = Enum.Font.GothamBlack, ZIndex = 24 }) end
            label(row, known and spec.Name or "???", 18, C.White, { Position = UDim2.fromOffset(114, 18), Size = UDim2.new(1, -130, 0, 28), Font = Enum.Font.GothamBold, ZIndex = 24 })
            label(row, "PALIER " .. spec.Floor .. "  ·  " .. (known and (string.upper(spec.Rarity) .. " · " .. UI.Format(spec.Income) .. " gold/min · VALEUR " .. UI.Format(spec.Income * 60) .. " gold · POSSÉDÉS : " .. rules.SpeciesCount(state, id)) or "À DÉCOUVRIR"), 12, C.Muted, { Position = UDim2.fromOffset(114, 50), Size = UDim2.new(1, -130, 0, 42), ZIndex = 24 })
            if known then
                local description = "GOLD ×3,5 · DIAMOND ×12 · MYTHIC ×45"
                for _, recipe in ipairs(state.Recipes) do
                    if recipe.Output == id then
                        local names = {}; for _, ingredient in ipairs(recipe.Ingredients) do table.insert(names, config.Animals[ingredient].Name) end
                        description = "RECETTE : " .. table.concat(names, " + ")
                    end
                end
                label(row, description, 10, C.Teal, { Position = UDim2.fromOffset(114, 98), Size = UDim2.new(1, -130, 0, 32), ZIndex = 24 })
            end
        end
    elseif self.Tab == "Équipement" then
        paragraph(state.OwnBase and "ATELIER OUVERT · Chaque achat est validé par le serveur." or "Rejoignez votre île pour acheter des améliorations.\nProfondeurs ouvertes : équipez-vous pour survivre aux gardiens.", 72, state.OwnBase and C.Teal or C.Gold)
        for _, key in ipairs(config.UpgradeOrder) do
            local spec, level = config.Upgrades[key], state.Equipment[key]
            local price = rules.UpgradeCost(config, key, level); local row = self:Row(104)
            label(row, spec.Name .. "  ·  NIVEAU " .. level .. " / " .. spec.Max, 17, C.White, { Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -185, 0, 28), Font = Enum.Font.GothamBold, ZIndex = 24 })
            label(row, spec.Description, 12, C.Muted, { Position = UDim2.fromOffset(16, 48), Size = UDim2.new(1, -185, 0, 40), ZIndex = 24 })
            local enabled = price and state.OwnBase and state.Money >= price
            button(row, price and (UI.Format(price) .. " gold") or "MAXIMUM", { Position = UDim2.new(1, -160, 0, 33), Size = UDim2.fromOffset(144, 40), BackgroundColor3 = enabled and C.Teal or C.Panel, TextColor3 = enabled and C.Navy or C.Muted, ZIndex = 24 }, function() if enabled then self.Ctx.Action:FireServer("Upgrade", key) end end)
        end
    elseif self.Tab == "Fusion" then
        paragraph("3 IDENTIQUES → GOLD ×3,5 → DIAMOND ×12 → MYTHIC ×45\nCombinez aussi des espèces normales. Les essais inconnus ne consomment rien. Les achats et fusions nécessitent votre habitat.", 98, C.Teal)
        for id, spec in pairs(config.Animals) do
            for index = 1, 3 do
                local grade = config.GradeOrder[index]
                local amount = grade == "Normal" and (state.Animals[id] or 0) or ((state.Variants[id] or {})[grade] or 0)
                if amount >= 3 then
                    local cost = math.floor(spec.Income * config.Grades[grade] * 0.5 / (1 + state.Prestige * 0.03))
                    local row = self:Row(94)
                    label(row, spec.Name .. " · 3 " .. grade .. " → " .. config.GradeOrder[index + 1], 14, C.White, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -170, 1, -20), ZIndex = 24 })
                    button(row, UI.Format(cost) .. " gold", { Position = UDim2.new(1, -150, 0, 28), Size = UDim2.fromOffset(134, 38), ZIndex = 24 }, function() if state.OwnBase then self.Ctx.Action:FireServer("Fuse", { Kind = "Classic", Species = id, Grade = grade }) end end)
                end
            end
        end
        paragraph("RECETTES CONNUES · Les recettes secrètes apparaissent ici après leur découverte.", 66, C.Gold)
        for _, recipe in ipairs(state.Recipes) do
            local names = {}; for _, id in ipairs(recipe.Ingredients) do table.insert(names, config.Animals[id].Name) end
            local spec = config.Animals[recipe.Output]; local row = self:Row(112)
            label(row, spec.Name .. (recipe.Secret and " · SECRET" or "") .. "\n" .. table.concat(names, " + "), 13, C.White, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -175, 1, -20), ZIndex = 24 })
            local cost = math.floor(spec.Income * 0.4 / (1 + state.Prestige * 0.03))
            button(row, UI.Format(cost) .. " gold", { Position = UDim2.new(1, -150, 0, 36), Size = UDim2.fromOffset(134, 38), ZIndex = 24 }, function() if state.OwnBase then self.Ctx.Action:FireServer("Fuse", { Kind = "Recipe", Ingredients = recipe.Ingredients }) end end)
        end
        local names = {}; for _, id in ipairs(self.Ingredients) do table.insert(names, config.Animals[id].Name) end
        local experiment = self:Row(108)
        label(experiment, "LABORATOIRE SECRET\n" .. (#names > 0 and table.concat(names, " + ") or "Sélectionnez 2 ou 3 espèces ci-dessous."), 13, C.Gold, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -175, 1, -20), ZIndex = 24 })
        button(experiment, "EXPÉRIMENTER", { Position = UDim2.new(1, -150, 0, 34), Size = UDim2.fromOffset(134, 40), ZIndex = 24 }, function()
            if state.OwnBase then self.Ctx.Action:FireServer("Fuse", { Kind = "Recipe", Ingredients = table.clone(self.Ingredients) }); self.Ingredients = {}; self:RenderPanel() end
        end)
        local ids = {}; for id, count in pairs(state.Animals) do if count > 0 then table.insert(ids, id) end end; table.sort(ids)
        for _, id in ipairs(ids) do
            local row = self:Row(52)
            local selected = table.find(self.Ingredients, id)
            button(row, (selected and "✓  " or "+  ") .. config.Animals[id].Name, { Size = UDim2.new(1, -16, 1, -10), Position = UDim2.fromOffset(8, 5), BackgroundColor3 = selected and C.Teal or C.Panel, TextColor3 = selected and C.Navy or C.White, ZIndex = 24 }, function()
                local index = table.find(self.Ingredients, id)
                if index then table.remove(self.Ingredients, index) elseif #self.Ingredients < 3 then table.insert(self.Ingredients, id) end
                self:RenderPanel()
            end)
        end
    elseif self.Tab == "Prestige" then
        paragraph("PRESTIGE " .. state.Prestige .. "\nBonus actuels : gold ×" .. (1 + state.Prestige * 0.25) .. " · +" .. state.Prestige * 5 .. " oxygène · nage améliorée · harpon renforcé · fusions moins chères.", 112, C.Teal)
        paragraph("Le prestige réinitialise gold, animaux, variantes, œufs, équipement et niveau de plongée. Le bestiaire découvert, les recettes, les statistiques, la profondeur record et les décorations restent acquis.\nPrérequis : combinaison 20 et " .. UI.Format(state.PrestigeCost) .. " gold.", 158, C.Gold)
        local row = self:Row(86)
        button(row, self.PrestigeArmedAt and "CONFIRMER LA RÉINITIALISATION" or "PASSER AU PRESTIGE SUIVANT", { Size = UDim2.new(1, -32, 0, 46), Position = UDim2.fromOffset(16, 20), BackgroundColor3 = C.Gold, ZIndex = 24 }, function()
            if not state.OwnBase then self:Toast("Le prestige s'effectue dans votre habitat.", "Warning"); return end
            if state.Money < state.PrestigeCost or state.Equipment.Suit < 20 then self:Toast("Conditions de prestige insuffisantes.", "Warning"); return end
            if self.PrestigeArmedAt and os.clock() - self.PrestigeArmedAt < 5 then self.PrestigeArmedAt = nil; self.Ctx.Action:FireServer("Prestige")
            else
                self.PrestigeArmedAt = os.clock()
                task.delay(5, function() self.PrestigeArmedAt = nil; if self.Tab == "Prestige" then self:RenderPanel() end end)
            end
            self:RenderPanel()
        end)
    elseif self.Tab == "Habitat" then
        paragraph((state.OwnBase and "ATELIER OUVERT" or "REJOIGNEZ VOTRE HABITAT POUR PERSONNALISER") .. "\nLes décorations restent acquises après un prestige. Palettes, aquarium, statue et bulles.", 84, C.Teal)
        for _, id in ipairs({ "lagoon", "coral", "abyss", "bubbles", "aquarium", "statue" }) do
            local spec = config.Decorations[id]; local row = self:Row(88)
            label(row, spec.Name .. "\n" .. (state.OwnedDecor[id] and "ACQUIS" or UI.Format(spec.Cost) .. " gold"), 16, C.White, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -175, 1, -20), ZIndex = 24 })
            button(row, state.Palette == id and "ACTIF" or state.OwnedDecor[id] and "APPLIQUER" or "ACHETER", { Position = UDim2.new(1, -150, 0, 26), Size = UDim2.fromOffset(134, 38), ZIndex = 24 }, function() if state.OwnBase then self.Ctx.Action:FireServer("Decorate", id) end end)
        end
    elseif self.Tab == "Classement" then
        paragraph("CLASSEMENTS DU SERVEUR · Richesse / collection / revenus / vols / profondeur\nLes revenus correspondent à la valeur productive de la collection.", 76, C.Teal)
        local rankings = table.clone(state.Rankings)
        local sort = self:Row(106)
        for index, field in ipairs({ { "Money", "GOLD" }, { "Value", "COLLECTION" }, { "Steals", "VOLS" }, { "Depth", "PROFONDEUR" }, { "Rare", "ANIMAUX RARES" }, { "Fusions", "FUSIONS" } }) do
            button(sort, field[2], { Position = UDim2.new(((index - 1) % 3) / 3, 4, 0, 7 + math.floor((index - 1) / 3) * 48), Size = UDim2.new(1 / 3, -8, 0, 40), TextSize = 10, BackgroundColor3 = self.RankBy == field[1] and C.Teal or C.Panel, TextColor3 = self.RankBy == field[1] and C.Navy or C.White, ZIndex = 24 }, function() self.RankBy = field[1]; self:RenderPanel() end)
        end
        table.sort(rankings, function(a, b) return a[self.RankBy] > b[self.RankBy] end)
        for i, entry in ipairs(rankings) do
            local row = self:Row(108)
            label(row, "#" .. i .. "  " .. entry.Name, 19, i == 1 and C.Gold or C.White, { Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 28), Font = Enum.Font.GothamBold, ZIndex = 24 })
            label(row, UI.Format(entry.Money) .. " gold  ·  " .. entry.Animals .. " animaux  ·  " .. UI.Format(entry.Income) .. " gold/min\n" .. entry.Steals .. " vols  ·  " .. entry.Depth .. " m  ·  " .. entry.Rare .. " rares  ·  " .. entry.Fusions .. " fusions découvertes", 12, C.Muted, { Position = UDim2.fromOffset(16, 44), Size = UDim2.new(1, -32, 0, 52), ZIndex = 24 })
        end
    elseif self.Tab == "Guide" then
        for _, text in ipairs({
            "01  EXPLOREZ\nNagez jusqu'aux nids lumineux. Chaque œuf possède un gardien : utilisez le harpon pour le combattre ou esquivez-le.",
            "02  TRANSPORTEZ\nMaintenez E près d'un œuf. Il apparaît sur votre personnage et vous ralentit. Un simple contact avec un joueur ne vole rien.",
            "03  INTERCEPTEZ\nÉquipez le harpon, visez avec la souris et cliquez. Sur mobile, visez au centre et utilisez TIRER. Un tir doit réellement toucher le transporteur pour faire tomber l'œuf.",
            "04  SÉCURISEZ\nRemontez vers VOTRE île de surface indiquée par la boussole. L'œuf est automatiquement sécurisé et ne peut plus être volé. Tous les habitats sont des zones sans combat.",
            "05  REMPLISSEZ L'AQUARIUM\nDéposez les œufs sur votre île avec E ou Collection. Éclosion : Common 15 s · Rare 40 s · Epic 90 s · Legendary 3 min · Mythic 6 min · Secret 12 min. Les animaux produisent des gold pour acheter l'équipement.",
            "06  DESCENDEZ À VOS RISQUES\nToutes les profondeurs sont ouvertes. Combinaisons conseillées : 10 / 20 / 35 / 50 / 75. Les gardiens géants deviennent plus rapides et plus meurtriers si vous êtes mal équipé.",
            "07  RESPIREZ\nLes stations vertes O₂, la surface et les îles rechargent votre réserve. L'oxygène se consomme plus vite en profondeur. À zéro, votre santé diminue.",
            "08  PRENEZ DES RISQUES\nLes événements de 5, 15 et 40 minutes augmentent la rareté et le danger. Esquivez les ondes rouges annonçant les attaques des boss. Aucun retour rapide avec un œuf.",
            "09  ÉVOLUEZ\nFusionnez vos animaux dans votre habitat, découvrez les recettes secrètes, personnalisez la base et recommencez avec le prestige pour obtenir des bonus permanents.",
            "COMMANDES\nWASD / joystick : nager · Espace / LB : monter · Ctrl / RB : descendre · Shift / X manette : propulseur · clic / RT : tirer · E : interagir.",
        }) do paragraph(text, 112) end
    end
    task.defer(function() if self.List.Parent then self.List.CanvasPosition = position end end)
end

function UI:Update(state)
    self.State = state; self.ReceivedAt = os.clock()
    self.Money.Text = UI.Format(state.Money) .. " gold"; self.Income.Text = "+" .. UI.Format(state.Income) .. " gold / min"
    self.Oxygen.Text = math.ceil(state.Oxygen) .. " / " .. state.MaxOxygen
    self.OxygenBar.Size = UDim2.fromScale(math.clamp(state.Oxygen / state.MaxOxygen, 0, 1), 1)
    self.OxygenBar.BackgroundColor3 = state.Oxygen / state.MaxOxygen < 0.2 and C.Red or C.Teal
    self.Depth.Text = state.Depth .. " m"; self.Floor.Text = (state.Depth == 0 and "SURFACE" or self.Ctx.Config.Floors[state.Floor].ShortName) .. " · COMBI " .. state.Equipment.Suit
    self.Save.Text = state.SaveStatus; self.Save.TextColor3 = state.Offline and C.Gold or C.Muted
    self.EventName.Text = state.Event.Name; self.EventName.TextColor3 = state.Event.Active and C.Gold or C.White
    self.Objective.Text = state.Carrying and ("ŒUF " .. string.upper(state.Carrying.Rarity) .. " À BORD  →  REJOIGNEZ VOTRE HABITAT")
        or (state.OwnBase and "HABITAT SÉCURISÉ  ·  DÉPOSEZ VOS ŒUFS DANS L'AQUARIUM · ACHETEZ L'ÉQUIPEMENT EN GOLD" or "EXPLOREZ  →  TROUVEZ UN ŒUF  →  REJOIGNEZ VOTRE HABITAT")
    self.Objective.TextColor3 = state.Carrying and C.Gold or C.White
    local signature = self.Tab or ""
    if self.Tab == "Collection" or self.Tab == "Bestiaire" or self.Tab == "Fusion" then
        for id in pairs(self.Ctx.Config.Animals) do
            signature ..= id .. (state.Animals[id] or 0) .. tostring(state.Discovered[id])
            for _, grade in ipairs({ "Gold", "Diamond", "Mythic" }) do signature ..= ((state.Variants[id] or {})[grade] or 0) end
        end
        for _, egg in ipairs(state.Eggs) do signature ..= egg.Id .. tostring(egg.ReadyAt) end
        signature ..= tostring(state.OwnBase) .. state.Prestige
    elseif self.Tab == "Équipement" then
        for _, key in ipairs(self.Ctx.Config.UpgradeOrder) do local price = self.Ctx.Rules.UpgradeCost(self.Ctx.Config, key, state.Equipment[key]); signature ..= state.Equipment[key] .. tostring(price and state.Money >= price) end
        signature ..= tostring(state.OwnBase)
    elseif self.Tab == "Prestige" then signature ..= state.Prestige .. tostring(state.Money >= state.PrestigeCost) .. state.Equipment.Suit .. tostring(state.OwnBase)
    elseif self.Tab == "Habitat" then for id in pairs(self.Ctx.Config.Decorations) do signature ..= id .. tostring(state.OwnedDecor[id]) end; signature ..= state.Palette .. tostring(state.OwnBase)
    elseif self.Tab == "Classement" then signature ..= tostring(os.clock()) end
    if self.Tab and signature ~= self.Signature then self.Signature = signature; self:RenderPanel() end
end

function UI:Tick()
    if not self.State then return end
    local elapsed = os.clock() - self.ReceivedAt
    local serverNow = self.State.ServerTime + elapsed
    for _, timer in ipairs(self.HatchTimers or {}) do
        if timer.Label.Parent then
            local seconds = math.max(0, math.ceil(timer.Egg.ReadyAt - serverNow))
            timer.Label.Text = seconds > 0 and string.format("AQUARIUM · ÉCLOSION DANS %02d:%02d", math.floor(seconds / 60), seconds % 60) or "ÉCLOSION PRÊTE · Libérez une place si la collection est pleine."
        end
    end
    local remaining = math.max(0, self.State.Event.Remaining - elapsed)
    self.EventTimer.Text = string.format("%02d:%02d", math.floor(remaining / 60), math.floor(remaining % 60)) .. (self.State.Event.Active and "  ·  RARETÉ ↑" or "")
    local cooldown = math.max(0, self.State.ShotRemaining - elapsed)
    self.Cooldown.Text = cooldown > 0 and string.format("HARPON  ·  %.1f s", cooldown) or "HARPON PRÊT  ·  VISEZ ET TIREZ"
    if self.BoostButton then
        local boost = math.max(0, self.State.BoostRemaining - elapsed)
        self.BoostButton.Text = boost > 0 and ("BOOST · " .. math.ceil(boost) .. " s") or "BOOST"
    end
end

function UI:Hatch(animalId, grade)
    local spec = self.Ctx.Config.Animals[animalId]
    if not spec then return end
    local frame = panel(self.Root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(370, 300), ZIndex = 40 })
    label(frame, grade and ("FUSION " .. string.upper(grade) .. " RÉUSSIE") or "NOUVEL ANIMAL DÉCOUVERT", 13, C.Teal, { Position = UDim2.fromOffset(20, 20), Size = UDim2.fromOffset(330, 24), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 41 })
    self:Viewport(frame, spec)
    local viewport = frame:FindFirstChildOfClass("ViewportFrame"); viewport.Position = UDim2.fromOffset(65, 52); viewport.Size = UDim2.fromOffset(240, 150); viewport.ZIndex = 41
    label(frame, spec.Name, 24, C.White, { Position = UDim2.fromOffset(20, 205), Size = UDim2.fromOffset(330, 36), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, ZIndex = 41 })
    label(frame, string.upper(spec.Rarity) .. "  ·  +" .. UI.Format(spec.Income * (self.Ctx.Config.Grades[grade] or 1)) .. " gold / min de base", 14, self.Ctx.Visuals.Color(self.Ctx.Config.Rarities[spec.Rarity].Color), { Position = UDim2.fromOffset(20, 251), Size = UDim2.fromOffset(330, 24), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 41 })
    task.delay(4, function() frame:Destroy() end)
end
return UI
