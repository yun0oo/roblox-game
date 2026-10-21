--!nonstrict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local UI = {}
UI.__index = UI
local C = { Navy = Color3.fromRGB(22, 31, 75), Panel = Color3.fromRGB(29, 82, 141), White = Color3.fromRGB(249, 253, 255),
    Muted = Color3.fromRGB(190, 218, 247), Teal = Color3.fromRGB(0, 223, 244), Gold = Color3.fromRGB(255, 214, 63), Red = Color3.fromRGB(255, 122, 139) }
local function make(class, parent, props)
    local item = Instance.new(class)
    for key, value in pairs(props or {}) do item[key] = value end
    item.Parent = parent
    return item
end
local function round(item, radius) make("UICorner", item, { CornerRadius = UDim.new(0, radius or 5) }) end
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
    round(item, 5)
    make("UIStroke", item, { Color = C.Navy, Transparency = 0.2, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    if callback then item.Activated:Connect(callback) end
    return item
end
local function panel(parent, props)
    local item = make("Frame", parent, { BackgroundColor3 = C.Panel, BackgroundTransparency = 0, BorderSizePixel = 0 })
    for key, value in pairs(props or {}) do item[key] = value end
    round(item)
    make("UIStroke", item, { Color = Color3.fromRGB(87, 146, 214), Transparency = 0.15, Thickness = 2 })
    return item
end
-- A native GUI hexagon: four gradient-clipped triangles and a central band.
-- It scales cleanly and does not depend on an externally uploaded image.
local function hexagon(parent, size, tint, selected)
    local frame = make("Frame", parent, { Position = UDim2.fromOffset(7, 7), Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = 25 })
    make("Frame", frame, { Position = UDim2.fromScale(0, 0.25), Size = UDim2.fromScale(1, 0.5), BackgroundColor3 = tint, BorderSizePixel = 0, ZIndex = 25 })
    local function triangle(x, y, rotation, inverted)
        local piece = make("Frame", frame, { Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(0.5, 0.25), BackgroundColor3 = tint, BorderSizePixel = 0, ZIndex = 25 })
        make("UIGradient", piece, { Rotation = rotation, Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, inverted and 0 or 1), NumberSequenceKeypoint.new(0.499, inverted and 0 or 1),
            NumberSequenceKeypoint.new(0.501, inverted and 1 or 0), NumberSequenceKeypoint.new(1, inverted and 1 or 0) }) })
    end
    triangle(0, 0, 63.435, false); triangle(0.5, 0, 116.565, false)
    triangle(0, 0.75, 116.565, true); triangle(0.5, 0.75, 63.435, true)
    local points = { { 0.5, 0 }, { 1, 0.25 }, { 1, 0.75 }, { 0.5, 1 }, { 0, 0.75 }, { 0, 0.25 } }
    for i, a in ipairs(points) do
        local b = points[i % 6 + 1]
        local dx, dy = (b[1] - a[1]) * size, (b[2] - a[2]) * size
        make("Frame", frame, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset((a[1] + b[1]) * size / 2, (a[2] + b[2]) * size / 2), Size = UDim2.fromOffset(math.sqrt(dx*dx + dy*dy), selected and 3 or 1), Rotation = math.deg(math.atan2(dy, dx)), BackgroundColor3 = selected and C.White or tint:Lerp(C.White, 0.35), BorderSizePixel = 0, ZIndex = 27 })
    end
    return frame
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
        local scale = math.clamp(math.min(size.Y / 850, size.X / 1200), 0.6, 1.1)
        self.Scale.Scale = scale; root.Size = UDim2.fromScale(1 / scale, 1 / scale)
        self.Compact = size.X / scale < 900
        if self.MenuItems then
            for _, entry in ipairs(self.MenuItems) do
                entry.Button.Size = UDim2.fromOffset(152, 40)
                entry.Button.Text = entry.Text
            end
            self.MenuHeading.Visible = true
        end
        if self.Compass then
            self.Compass.AnchorPoint = Vector2.new(0.5, self.Compact and 1 or 0)
            self.Compass.Position = self.Compact and UDim2.new(0.4, 0, 1, -187) or UDim2.new(0.5, 0, 0, 20)
            self.Compass.Size = self.Compact and UDim2.fromOffset(220, 20) or UDim2.new(1, -480, 0, 30)
        end
        if self.State and (self.Tab == "Collection" or self.Tab == "Bestiaire") then self:RenderPanel() end
    end
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize); resize()
    -- Small independent instruments leave the middle of the screen open.
    local wallet = panel(root, { Name = "Gold", Position = UDim2.fromOffset(20, 16), Size = UDim2.fromOffset(205, 50), BackgroundColor3 = C.Navy, BackgroundTransparency = 0.18 })
    label(wallet, "G", 18, C.Gold, { Position = UDim2.fromOffset(12, 8), Size = UDim2.fromOffset(24, 32), Font = Enum.Font.GothamBlack })
    self.Money = label(wallet, "…", 18, C.White, { Position = UDim2.fromOffset(42, 6), Size = UDim2.fromOffset(150, 23), Font = Enum.Font.GothamBold })
    self.Income = label(wallet, "+0 / min", 10, C.Muted, { Position = UDim2.fromOffset(42, 29), Size = UDim2.fromOffset(150, 15) })
    local depth = panel(root, { Name = "Profondeur", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 16), Size = UDim2.fromOffset(185, 50), BackgroundColor3 = C.Navy, BackgroundTransparency = 0.18 })
    self.Depth = label(depth, "Surface", 17, C.White, { Position = UDim2.fromOffset(12, 6), Size = UDim2.fromOffset(161, 23), Font = Enum.Font.GothamBold })
    self.Floor = label(depth, "NÉRÉIDE", 10, C.Muted, { Position = UDim2.fromOffset(12, 29), Size = UDim2.fromOffset(161, 15) })
    self.OxygenPanel = panel(root, { Name = "Oxygène", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(UserInputService.TouchEnabled and 0.4 or 0.5, 0, 1, -96), Size = UDim2.fromOffset(220, 33), BackgroundColor3 = C.Navy, BackgroundTransparency = 0.25, Visible = false })
    label(self.OxygenPanel, "O₂", 12, C.Muted, { Position = UDim2.fromOffset(10, 3), Size = UDim2.fromOffset(30, 18) })
    self.Oxygen = label(self.OxygenPanel, "100 %", 11, C.Muted, { Position = UDim2.fromOffset(130, 3), Size = UDim2.fromOffset(80, 18), TextXAlignment = Enum.TextXAlignment.Right })
    local track = make("Frame", self.OxygenPanel, { Position = UDim2.fromOffset(10, 24), Size = UDim2.fromOffset(200, 3), BackgroundColor3 = C.Panel, BorderSizePixel = 0 }); round(track, 3)
    self.OxygenBar = make("Frame", track, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Teal, BorderSizePixel = 0 }); round(self.OxygenBar, 3)
    local menu = panel(root, { Name = "Menu d’expédition", Position = UDim2.fromOffset(20, 118), Size = UDim2.fromOffset(172, 484), BackgroundColor3 = C.Navy, BackgroundTransparency = 0.08, Visible = false, ZIndex = 5 })
    self.Menu = menu; self.MenuItems = {}
    self.MenuButton = button(root, "☰", { Position = UDim2.fromOffset(20, 76), Size = UDim2.fromOffset(36, 32), TextSize = 20, BackgroundColor3 = C.Navy, TextColor3 = C.White }, function() menu.Visible = not menu.Visible end)
    self.QuickInventory = button(root, "🥚 0", { Position = UDim2.fromOffset(64, 76), Size = UDim2.fromOffset(76, 32), TextSize = 12, BackgroundColor3 = C.Navy, TextColor3 = C.White }, function() self:Open("Collection") end)
    self.EquipButton = button(root, "HARPON", { Position = UDim2.fromOffset(148, 76), Size = UDim2.fromOffset(77, 32), TextSize = 10, BackgroundColor3 = C.Navy, TextColor3 = C.Teal }, function() context.Equip() end)
    self.MenuHeading = label(menu, "EXPÉDITION", 10, C.Muted, { Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(152, 18), ZIndex = 6 })
    for i, entry in ipairs({ { "Collection", "ŒUFS & ANIMAUX" }, { "Bestiaire", "BESTIAIRE" }, { "Équipement", "ÉQUIPEMENT" }, { "Fusion", "FUSION" }, { "Prestige", "PRESTIGE" }, { "Habitat", "BASE & AQUARIUM" }, { "Classement", "CLASSEMENT" }, { "Guide", "COMMENT JOUER" } }) do
        local item = button(menu, entry[2], { Position = UDim2.fromOffset(10, 36 + (i - 1) * 48), Size = UDim2.fromOffset(152, 40), BackgroundColor3 = C.Panel, TextColor3 = C.White, TextSize = 12, ZIndex = 6 }, function() self:Open(entry[1]) end)
        local icons = { "🥚", "🐋", "🤿", "🧬", "⭐", "🏠", "🏆", "?" }
        table.insert(self.MenuItems, { Button = item, Text = entry[2], Icon = icons[i] })
        if entry[1] == "Collection" then self.InventoryButton = item end
    end
    self.Home = button(menu, "RETOUR À LA BASE", { Position = UDim2.fromOffset(10, 432), Size = UDim2.fromOffset(152, 38), BackgroundColor3 = C.Panel, TextColor3 = C.Muted, TextSize = 11, ZIndex = 6 }, function() menu.Visible = false; context.Action:FireServer("Return") end)
    self.EventPanel = panel(root, { Name = "Événement", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 76), Size = UDim2.fromOffset(185, 32), BackgroundColor3 = C.Navy, BackgroundTransparency = 0.25 })
    self.EventName = label(self.EventPanel, "Prochain événement", 10, C.Muted, { Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(122, 32), TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false })
    self.EventTimer = label(self.EventPanel, "05:00", 11, C.Muted, { Position = UDim2.fromOffset(134, 0), Size = UDim2.fromOffset(42, 32), TextXAlignment = Enum.TextXAlignment.Right })
    self.ToastBox = make("Frame", root, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 120), Size = UDim2.fromOffset(232, 140), BackgroundTransparency = 1 })
    make("UIListLayout", self.ToastBox, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
    self.Objective = label(root, "", 11, C.White, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(UserInputService.TouchEnabled and 0.4 or 0.5, 0, 1, -142), Size = UDim2.fromOffset(310, 32), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamMedium, Visible = false })
    self.Help = label(root, "", 10, C.Muted, { Visible = false })
    self.Compass = label(root, "", 10, C.Muted, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 20), Size = UDim2.new(1, -480, 0, 30), TextTruncate = Enum.TextTruncate.AtEnd, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Center, Visible = false })
    self.Save = label(root, "Connexion…", 9, C.Muted, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -7), Size = UDim2.fromOffset(215, 16) })
    self.Cooldown = label(root, "", 10, C.Teal, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -44), Size = UDim2.fromOffset(175, 18), Visible = false })
    self.Reticle = make("Frame", root, { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(32, 32), BackgroundTransparency = 1, Visible = false, ZIndex = 2 })
    for _, segment in ipairs({ { 15, 0, 2, 9 }, { 15, 23, 2, 9 }, { 0, 15, 9, 2 }, { 23, 15, 9, 2 }, { 14, 14, 4, 4 } }) do
        local line = make("Frame", self.Reticle, { Position = UDim2.fromOffset(segment[1], segment[2]), Size = UDim2.fromOffset(segment[3], segment[4]), BackgroundColor3 = C.White, BorderSizePixel = 0, ZIndex = 2 })
        round(line, 2); make("UIStroke", line, { Color = C.Navy, Thickness = 1.2 })
    end
    self.CameraHint = label(root, "M · CAMÉRA", 10, C.Muted, { Position = UDim2.new(0, 20, 1, -25), Size = UDim2.fromOffset(185, 16), AnchorPoint = Vector2.new(0, 1), Visible = false })
    self.Dimmer = make("TextButton", root, { Size = UDim2.fromScale(1, 1), Text = "", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, Visible = false, ZIndex = 20 })
    self.Dimmer.Activated:Connect(function() self:Open(nil) end)
    self.Modal = panel(root, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.94, 0, 0.90, 0), Visible = false, ZIndex = 21 })
    make("UIStroke", self.Modal, { Thickness = 7, Color = C.Navy })
    self.CollectionTabs = make("Frame", self.Modal, { Position = UDim2.fromOffset(18, 15), Size = UDim2.new(1, -100, 0, 54), BackgroundTransparency = 1, Visible = false, ZIndex = 24 })
    for index, mode in ipairs({ "Animaux", "Œufs", "Bestiaire" }) do
        local tab = button(self.CollectionTabs, string.upper(mode), { Position = UDim2.new((index - 1) / 3, 0, 0, 0), Size = UDim2.new(1 / 3, -12, 1, 0), TextSize = 18, BackgroundColor3 = C.Panel, TextColor3 = C.White, ZIndex = 25 }, function()
            self.CollectionMode = mode; self.SelectedCard = nil; self.CollectionPage = 1
            self:Open(mode == "Bestiaire" and "Bestiaire" or "Collection")
        end)
        tab:SetAttribute("CollectionMode", mode)
    end
    local footer = panel(self.Modal, { Position = UDim2.new(0, 16, 1, -60), Size = UDim2.new(1, -32, 0, 44), BackgroundColor3 = Color3.fromRGB(224, 245, 255), ZIndex = 24 })
    self.Footer = label(footer, "EXPÉDITION NÉRÉIDE · VOTRE COLLECTION MARINE", 12, C.Navy, { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -130, 1, 0), Font = Enum.Font.GothamBold, ZIndex = 25 })
    local function changePage(delta)
        self.CollectionPage = math.clamp((self.CollectionPage or 1) + delta, 1, self.BrowserPages or 1)
        self.SelectedCard = nil; self:RenderPanel()
    end
    self.PreviousPage = button(footer, "‹", { Position = UDim2.new(1, -102, 0, 4), Size = UDim2.fromOffset(42, 36), TextSize = 24, Visible = false, ZIndex = 25 }, function() changePage(-1) end)
    self.NextPage = button(footer, "›", { Position = UDim2.new(1, -52, 0, 4), Size = UDim2.fromOffset(42, 36), TextSize = 24, Visible = false, ZIndex = 25 }, function() changePage(1) end)
    self.Title = label(self.Modal, "", 27, C.White, { Position = UDim2.fromOffset(24, 18), Size = UDim2.new(1, -90, 0, 44), Font = Enum.Font.GothamBold, ZIndex = 22 })
    button(self.Modal, "×", { Position = UDim2.new(1, -68, 0, 14), Size = UDim2.fromOffset(50, 54), BackgroundColor3 = C.Teal, TextColor3 = C.Navy, TextSize = 32, ZIndex = 25 }, function() self:Open(nil) end)
    self.List = make("ScrollingFrame", self.Modal, { Position = UDim2.fromOffset(24, 78), Size = UDim2.new(1, -48, 1, -154), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 4, ScrollBarImageColor3 = C.Teal, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 22 })
    if UserInputService.TouchEnabled then
        self.Help.Text = "JOYSTICK · NAGER    ↑ / ↓ · PROFONDEUR    TIRER · HARPON"
        local function hold(text, x, field)
            local b = button(root, text, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, x, 1, -118), Size = UDim2.fromOffset(72, 66), TextSize = 24 })
            b.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then self[field] = 1 end end)
            b.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then self[field] = 0 end end)
        end
        hold("↑", -104, "Ascend"); hold("↓", -24, "Descend")
        button(root, "TIRER", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -194), Size = UDim2.fromOffset(152, 58) }, context.Fire)
        self.BoostButton = button(root, "BOOST", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -262), Size = UDim2.fromOffset(152, 48), BackgroundColor3 = C.Gold }, function() context.Action:FireServer("Boost") end)
    end
    resize()
    return self
end

function UI:Toast(message, tone)
    local rarity = self.Ctx.Config.Rarities[tone]
    local color = rarity and self.Ctx.Visuals.Color(rarity.Color) or (tone == "Warning" and C.Gold or C.Teal)
    local frame = panel(self.ToastBox, { Size = UDim2.fromOffset(232, 60), BackgroundColor3 = C.Navy, BackgroundTransparency = 0.15 })
    make("Frame", frame, { Size = UDim2.new(0, 3, 1, -20), Position = UDim2.fromOffset(0, 10), BackgroundColor3 = color, BorderSizePixel = 0 })
    label(frame, message, 12, color, { Position = UDim2.fromOffset(13, 8), Size = UDim2.new(1, -24, 1, -16), Font = Enum.Font.GothamMedium })
    table.insert(self.Notices, frame)
    while #self.Notices > 2 do local old = table.remove(self.Notices, 1); old:Destroy() end
    task.delay(5, function()
        local index = table.find(self.Notices, frame)
        if index then table.remove(self.Notices, index); frame:Destroy() end
    end)
end

function UI:Open(tab)
    if tab ~= "Prestige" then self.PrestigeArmedAt = nil end
    self.Tab = tab; self.Signature = ""
    if self.Menu then self.Menu.Visible = false end
    self.Modal.Visible = tab ~= nil; self.Dimmer.Visible = tab ~= nil
    if tab == "Collection" and self.State and self.State.Carrying then self.CollectionMode = "Œufs" end
    if tab then self:RenderPanel() end
end

function UI:OpenShop(key)
    self.SelectedEquipment = self.Ctx.Config.Merchants[key] and key or nil
    self:Open("Équipement")
end

function UI:EquipmentPreview(parent, equipment)
    local view = make("ViewportFrame", parent, { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(150, 175), BackgroundTransparency = 1, Ambient = Color3.fromRGB(210, 229, 255), LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-1, -1, -2), ZIndex = 24 })
    local scene = make("WorldModel", view)
    local dummy = make("Model", scene)
    local v = self.Ctx.Visuals
    for _, item in ipairs({
        { "Torso", Vector3.new(2, 2, 1), Vector3.new(0, 0, 0) },
        { "Head", Vector3.new(1.5, 1.5, 1.5), Vector3.new(0, 1.75, 0) },
        { "Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 0, 0) },
        { "Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 0, 0) },
        { "Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -2, 0) },
        { "Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, -2, 0) },
    }) do v.Part(dummy, item[1], item[2], CFrame.new(item[3]), item[1] == "Head" and Color3.fromRGB(255, 215, 161) or C.Navy) end
    require(game:GetService("ReplicatedStorage").Modules.EquipmentVisuals).Apply(dummy, equipment, v, true)
    local camera = make("Camera", view, { CFrame = CFrame.lookAt(Vector3.new(6, 3, -10), Vector3.new(0, -0.3, 0)), FieldOfView = 37 })
    view.CurrentCamera = camera
end

function UI:Viewport(parent, spec)
    local viewport = make("ViewportFrame", parent, { BackgroundTransparency = 1, Position = UDim2.fromOffset(2, 3), Size = UDim2.fromOffset(104, 92), Ambient = Color3.fromRGB(185, 211, 226), LightColor = Color3.new(1, 1, 1), ZIndex = 24 })
    local world = make("WorldModel", viewport)
    self.Ctx.Visuals.Animal(world, spec, CFrame.new(), 1)
    local camera = make("Camera", viewport, { CFrame = CFrame.lookAt(Vector3.new(7, 3, -10), Vector3.new(0, -0.5, 0)), FieldOfView = 42 })
    viewport.CurrentCamera = camera
    return viewport
end

function UI:Row(height)
    return panel(self.List, { Size = UDim2.new(1, -8, 0, height or 100), BackgroundColor3 = C.Navy, ZIndex = 23 })
end

-- Responsive collection view: paged rarity cards and a separate detail panel.
function UI.BrowserLayout(width, height)
    local stacked = width < 700
    local details = stacked and width or math.clamp(width * 0.31, 250, 340)
    local gridWidth = stacked and width or width - details - 18
    local columns = math.clamp(math.floor(gridWidth / 145), 2, 4)
    return { Stacked = stacked, GridWidth = gridWidth, DetailsWidth = details, Columns = columns,
        CellWidth = math.floor((gridWidth - 20 - (columns - 1) * 10) / columns), GridHeight = stacked and math.min(350, height * 0.56) or height }
end
function UI:BrowserPreview(parent, entry, known)
    if not known then
        label(parent, "?", 56, C.Muted, { Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 26 })
        return
    end
    if entry.Kind == "Egg" then
        local view = make("ViewportFrame", parent, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Ambient = Color3.fromRGB(210, 236, 255), LightColor = Color3.new(1, 1, 1), ZIndex = 26 })
        local world = make("WorldModel", view)
        local skin = require(game:GetService("ReplicatedStorage").Modules.ArtRenderer).Build("egg", self.Ctx.Visuals.Color(self.Ctx.Config.Rarities[entry.Spec.Rarity].Color), 1, true)
        skin.Parent = world
        local camera = make("Camera", view, { CFrame = CFrame.lookAt(Vector3.new(1.8, 0.6, -2.6), Vector3.zero), FieldOfView = 40 }); view.CurrentCamera = camera
    else
        local view = self:Viewport(parent, entry.Spec)
        view.Position = UDim2.fromScale(0, 0); view.Size = UDim2.fromScale(1, 1); view.ZIndex = 26
    end
end
function UI:RenderBrowser()
    local config, state, rules = self.Ctx.Config, self.State, self.Ctx.Rules
    local mode = self.Tab == "Bestiaire" and "Bestiaire" or self.CollectionMode or "Œufs"
    self.List.Visible = false; self.Title.Visible = false
    if not self.Browser then
        self.Browser = make("ScrollingFrame", self.Modal, { Position = UDim2.fromOffset(20, 86), Size = UDim2.new(1, -40, 1, -155), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, ScrollBarImageColor3 = C.Teal, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 22 })
    end
    self.Browser.Visible = true; self.Browser:ClearAllChildren()
    local entries, discovered = {}, 0
    if mode == "Œufs" then
        for _, egg in ipairs(state.Eggs) do table.insert(entries, { Id = egg.Id, Kind = "Egg", Spec = egg, Known = true }) end
    else
        for id, spec in pairs(config.Animals) do
            local count = rules.SpeciesCount(state, id)
            if state.Discovered[id] then discovered += 1 end
            if mode == "Bestiaire" or count > 0 then table.insert(entries, { Id = id, Spec = spec, Count = count, Known = mode ~= "Bestiaire" or state.Discovered[id] == true }) end
        end
        table.sort(entries, function(a, b) return a.Spec.Floor == b.Spec.Floor and a.Spec.Income > b.Spec.Income or a.Spec.Floor < b.Spec.Floor end)
    end
    local pages = math.max(1, math.ceil(#entries / 12))
    self.CollectionPage = math.clamp(self.CollectionPage or 1, 1, pages)
    if self.CollectionTabs then
        self.CollectionTabs.Visible = true
        for _, tab in ipairs(self.CollectionTabs:GetChildren()) do
            if tab:IsA("TextButton") then
                local selected = tab:GetAttribute("CollectionMode") == mode
                tab.BackgroundColor3 = selected and C.Teal or C.Panel
                tab.TextColor3 = selected and C.Navy or C.Muted
            end
        end
    end
    local width = self.Modal.AbsoluteSize and self.Modal.AbsoluteSize.X or 1000
    local height = self.Modal.AbsoluteSize and self.Modal.AbsoluteSize.Y or 650
    local scale = self.Scale and self.Scale.Scale or 1
    local layout = UI.BrowserLayout(width / scale - 40, height / scale - 155)
    local grid = make("ScrollingFrame", self.Browser, { Name = "Grille de collection", Size = UDim2.fromOffset(layout.GridWidth, layout.GridHeight), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5, ScrollBarImageColor3 = C.Teal, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 23 })
    local cellHeight = layout.CellWidth + 72
    make("UIGridLayout", grid, { CellSize = UDim2.fromOffset(layout.CellWidth, cellHeight), CellPadding = UDim2.fromOffset(10, 12), SortOrder = Enum.SortOrder.LayoutOrder })
    local chosen
    for _, entry in ipairs(entries) do if entry.Id == self.SelectedCard then chosen = entry end end
    chosen = chosen or entries[(self.CollectionPage - 1) * 12 + 1]
    for index = (self.CollectionPage - 1) * 12 + 1, math.min(#entries, self.CollectionPage * 12) do
        local entry = entries[index]
        local tint = self.Ctx.Visuals.Color(config.Rarities[entry.Spec.Rarity].Color)
        local card = button(grid, "", { Name = "Carte " .. entry.Id, BackgroundColor3 = C.Panel, BackgroundTransparency = 1, ZIndex = 24, LayoutOrder = index }, function() self.SelectedCard = entry.Id; self:RenderPanel() end)
        card:FindFirstChildOfClass("UIStroke").Transparency = 1
        local medallion = hexagon(card, layout.CellWidth - 14, entry.Known and tint:Lerp(C.Panel, 0.28) or C.Navy, chosen == entry)
        self:BrowserPreview(medallion, entry, entry.Known)
        label(card, entry.Known and entry.Spec.Name or "???", 12, C.White, { Position = UDim2.fromOffset(5, layout.CellWidth), Size = UDim2.new(1, -10, 0, 30), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, ZIndex = 26 })
        local caption = entry.Kind == "Egg" and (entry.Spec.Unsecured and "⚠ VOLABLE" or entry.Spec.ReadyAt and "INCUBATION" or "SÉCURISÉ") or entry.Known and ("+" .. UI.Format(entry.Spec.Income) .. " / min  ·  ×" .. entry.Count) or "À DÉCOUVRIR"
        label(card, caption, 11, entry.Known and tint or C.Muted, { Position = UDim2.fromOffset(4, layout.CellWidth + 33), Size = UDim2.new(1, -8, 0, 25), TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, ZIndex = 26 })
    end
    local detail = panel(self.Browser, { Name = "Détail sélection", Position = layout.Stacked and UDim2.fromOffset(0, layout.GridHeight + 16) or UDim2.fromOffset(layout.GridWidth + 18, 0), Size = UDim2.fromOffset(layout.DetailsWidth, math.max(480, layout.Stacked and 510 or layout.GridHeight)), BackgroundColor3 = Color3.fromRGB(32, 99, 169), ZIndex = 23 })
    if chosen then
        local spec, known = chosen.Spec, chosen.Known
        local tint = self.Ctx.Visuals.Color(config.Rarities[spec.Rarity].Color)
        label(detail, known and spec.Name or "ESPÈCE INCONNUE", 20, C.White, { Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 52), Font = Enum.Font.GothamBlack, ZIndex = 24 })
        local preview = make("Frame", detail, { Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 0, 170), BackgroundTransparency = 1, ZIndex = 24 })
        self:BrowserPreview(preview, chosen, known)
        label(detail, known and string.upper(spec.Rarity) or "???", 17, known and tint or C.Muted, { Position = UDim2.fromOffset(18, 236), Size = UDim2.new(1, -36, 0, 26), Font = Enum.Font.GothamBold, ZIndex = 26 })
        if chosen.Kind == "Egg" then
            local timer = label(detail, "", 13, C.White, { Position = UDim2.fromOffset(18, 274), Size = UDim2.new(1, -36, 0, 88), ZIndex = 26 })
            if spec.ReadyAt then table.insert(self.HatchTimers, { Egg = spec, Label = timer })
            elseif spec.Unsecured then timer.Text = "NON SÉCURISÉ\nLe harpon peut vous le faire perdre. Rejoignez votre galerie."
            else timer.Text = "DÉFINITIVEMENT SÉCURISÉ\nÉclosion : " .. config.HatchTimes[spec.Rarity] .. " s après dépôt dans la cuve." end
            local enabled = state.OwnBase and not spec.Unsecured and not spec.ReadyAt
            button(detail, spec.Unsecured and "À SÉCURISER" or spec.ReadyAt and "EN INCUBATION" or state.OwnBase and "DÉPOSER DANS LA CUVE" or "REJOINDRE MA CUVE", { Position = UDim2.fromOffset(16, 382), Size = UDim2.new(1, -32, 0, 54), BackgroundColor3 = enabled and C.Teal or C.Panel, TextColor3 = enabled and C.Navy or C.Muted, ZIndex = 26 }, function()
                if enabled then self.Ctx.Action:FireServer("Hatch", spec.Id)
                elseif not state.OwnBase and not spec.Unsecured and not spec.ReadyAt then self.Ctx.Navigate(state.BasePosition, "VOTRE CUVE À ŒUFS"); self:Open(nil) end
            end)
        else
            local variants = state.Variants[chosen.Id] or {}
            local text = known and ("PALIER " .. spec.Floor .. "  ·  ×" .. chosen.Count .. " POSSÉDÉS\n+" .. UI.Format(spec.Income) .. " GOLD / MIN\nValeur : " .. UI.Format(spec.Income * 60) .. " gold\n\nNormal " .. (state.Animals[chosen.Id] or 0) .. " · Gold " .. (variants.Gold or 0) .. "\nDiamond " .. (variants.Diamond or 0) .. " · Mythic " .. (variants.Mythic or 0)) or ("PALIER " .. spec.Floor .. "\n\nRapportez et faites éclore des œufs de cette profondeur pour découvrir cet animal.")
            label(detail, text, 13, C.White, { Position = UDim2.fromOffset(18, 275), Size = UDim2.new(1, -36, 0, 142), ZIndex = 26 })
            local recipe = "Fusion : Gold ×3,5 · Diamond ×12 · Mythic ×45"
            for _, item in ipairs(state.Recipes or {}) do
                if item.Output == chosen.Id then local names = {}; for _, id in ipairs(item.Ingredients) do table.insert(names, config.Animals[id].Name) end; recipe = "RECETTE : " .. table.concat(names, " + ") end
            end
            label(detail, known and recipe or "???", 11, C.Teal, { Position = UDim2.fromOffset(18, 428), Size = UDim2.new(1, -36, 0, 52), ZIndex = 26 })
        end
    else
        label(detail, mode == "Œufs" and "VOTRE PREMIER ŒUF\n\nPlongez par le bassin central. Évitez le boss, ramassez un œuf avec E puis rapportez-le dans votre galerie." or "VOTRE COLLECTION\n\nFaites éclore vos œufs dans la cuve pour remplir votre aquarium.", 18, C.White, { Position = UDim2.fromOffset(22, 40), Size = UDim2.new(1, -44, 0, 300), ZIndex = 24 })
    end
    if self.Footer then
        self.Footer.Text = mode == "Bestiaire" and (discovered .. " ESPÈCES DÉCOUVERTES  ·  PAGE " .. self.CollectionPage .. " / " .. pages) or (#entries .. (mode == "Œufs" and " ŒUFS" or " ESPÈCES") .. "  ·  +" .. UI.Format(state.Income) .. " GOLD / MIN  ·  " .. self.CollectionPage .. " / " .. pages)
        self.PreviousPage.Visible = true; self.NextPage.Visible = true
        self.BrowserPages = pages
    end
end

function UI:RenderPanel()
    local state = self.State
    if not self.Tab or not state then return end
    local config, rules = self.Ctx.Config, self.Ctx.Rules
    local position = self.List.CanvasPosition
    self.List:ClearAllChildren()
    make("UIListLayout", self.List, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
    self.Title.Text = self.Tab
    self.Title.Visible = true; self.List.Visible = true
    if self.Browser then self.Browser.Visible = false end
    if self.CollectionTabs then self.CollectionTabs.Visible = false end
    if self.Footer then
        self.Footer.Text = "NÉRÉIDE · " .. self.Tab:upper() .. "  ·  " .. UI.Format(state.Money) .. " GOLD"
        self.PreviousPage.Visible = false; self.NextPage.Visible = false
    end
    local function paragraph(text, height, color)
        local row = self:Row(height or 72)
        label(row, text, 14, color or C.Muted, { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 1, -20), ZIndex = 24 })
    end
    self.HatchTimers = {}
    if self.Tab == "Collection" or self.Tab == "Bestiaire" then
        self:RenderBrowser()
    elseif self.Tab == "Téléportation" then
        self.Title.Text = "ORDINATEUR · TÉLÉPORTATION"
        paragraph("Choisissez votre marchand. Le transfert depuis votre ordinateur est gratuit et vous dépose devant son stand.", 74, C.Teal)
        for _, key in ipairs(config.UpgradeOrder) do
            local merchant = config.Merchants[key]
            local row = self:Row(96)
            label(row, merchant.Icon .. " " .. merchant.Name .. "\n" .. config.Upgrades[key].Name, 17, C.White, { Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -220, 1, -20), ZIndex = 24 })
            local enabled = state.OwnBase and state.NearConsole
            button(row, enabled and "SE TÉLÉPORTER" or "REJOINDRE LE PC", { Position = UDim2.new(1, -192, 0, 25), Size = UDim2.fromOffset(172, 44), BackgroundColor3 = self.Ctx.Visuals.Color(merchant.Color), ZIndex = 24 }, function()
                if enabled then self.Ctx.Action:FireServer("TeleportMerchant", key)
                else self.Ctx.Navigate(state.ConsolePosition, "ORDINATEUR DE VOTRE GALERIE"); self:Open(nil) end
            end)
        end
    elseif self.Tab == "Équipement" then
        self.Title.Text = "LE MARCHÉ DES PLONGEURS"
        paragraph("7 marchands sur le pont · Choisissez un équipement.\nL’achat se fait auprès du spécialiste. Votre équipement apparaît sur votre personnage dès l’amélioration.", 76, C.White)
        local tabs = self:Row(88)
        local selected = self.SelectedEquipment or state.NearMerchant or "Suit"
        for index, key in ipairs(config.UpgradeOrder) do
            local merchant = config.Merchants[key]
            button(tabs, merchant.Icon .. "\n" .. config.Upgrades[key].Name, { Position = UDim2.new((index - 1) / 7, 4, 0, 8), Size = UDim2.new(1 / 7, -8, 0, 70), TextSize = 12,
                BackgroundColor3 = selected == key and self.Ctx.Visuals.Color(merchant.Color) or C.Panel, TextColor3 = selected == key and C.Navy or C.White, ZIndex = 24 }, function() self.SelectedEquipment = key; self:RenderPanel() end)
        end
        local key = selected
        local spec, merchant, level = config.Upgrades[key], config.Merchants[key], state.Equipment[key]
        local tint = self.Ctx.Visuals.Color(merchant.Color)
        local price = rules.UpgradeCost(config, key, level)
        local vendor = self:Row(194)
        self:EquipmentPreview(vendor, state.Equipment)
        label(vendor, merchant.Icon .. " " .. merchant.Name, 23, tint, { Position = UDim2.fromOffset(172, 24), Size = UDim2.new(1, -190, 0, 36), Font = Enum.Font.GothamBlack, ZIndex = 24 })
        label(vendor, merchant.Motto .. "\n\n" .. spec.Name:upper() .. " · NIVEAU " .. level .. " / " .. spec.Max, 15, C.White, { Position = UDim2.fromOffset(172, 68), Size = UDim2.new(1, -190, 0, 100), ZIndex = 24 })
        local function benefit(n)
            if key == "Oxygen" then return (100 + (n - 1) * 18 + state.Prestige * 5) .. " unités d’oxygène" end
            if key == "Swim" then return string.format("%.1f studs/s", 20 + (n - 1) * 2 + math.sqrt(state.Prestige) * 0.3) end
            if key == "Suit" then return "Pression ×" .. string.format("%.2f", 1 / (1 + (n - 1) * 0.018)) .. " · préparation " .. n end
            if key == "Shield" then return "−" .. math.floor(math.min(0.54, (n - 1) * 0.06) * 100 + 0.5) .. " % de dégâts" end
            if key == "Lamp" then return (24 + (n - 1) * 8) .. " studs de lumière" end
            if key == "Thruster" then return "+" .. (12 + n * 2) .. " studs/s pendant le boost" end
            local h = config.Harpoons[n]
            return h.Range .. " studs · " .. h.Cooldown .. " s · " .. h.Damage .. " dégâts de base"
        end
        local detail = self:Row(226)
        label(detail, "ACTUEL     " .. benefit(level) .. (price and ("\nSUIVANT   " .. benefit(level + 1)) or "\nNIVEAU MAXIMUM ATTEINT"), 17, C.White, { Position = UDim2.fromOffset(20, 18), Size = UDim2.new(1, -40, 0, 70), ZIndex = 24 })
        label(detail, price and ("Prix : " .. UI.Format(price) .. " gold   ·   Votre solde : " .. UI.Format(state.Money) .. " gold") or "Vous possédez le meilleur modèle.", 15, C.Gold, { Position = UDim2.fromOffset(20, 96), Size = UDim2.new(1, -40, 0, 28), ZIndex = 24 })
        local near = state.NearMerchant == key
        local affordable = price and state.Money >= price
        local text = not near and "LOCALISER CE MARCHAND" or not price and "ÉQUIPEMENT AU MAXIMUM" or affordable and "ACHETER L’AMÉLIORATION" or ("IL MANQUE " .. UI.Format(price - state.Money) .. " GOLD")
        button(detail, text, { Position = UDim2.fromOffset(20, 143), Size = UDim2.new(1, -40, 0, 52), BackgroundColor3 = not near and tint or affordable and C.Teal or C.Panel, TextColor3 = (not near or affordable) and C.Navy or C.Muted, ZIndex = 24 }, function()
            if not near then self.Ctx.Navigate(state.Merchants[key], merchant.Name); self:Open(nil)
            elseif affordable then self.Ctx.Action:FireServer("Upgrade", key) end
        end)
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
        local tier = config.BaseUpgrades[state.BaseLevel]
        paragraph("VOTRE GALERIE · NIVEAU " .. state.BaseLevel .. " / " .. #config.BaseUpgrades .. "\n" .. tier.Name .. " · " .. tier.Display .. " espèces exposées · +" .. math.floor(tier.IncomeBonus * 100) .. " % de gold. Les améliorations restent acquises après un prestige.", 100, C.Gold)
        local nextTier = config.BaseUpgrades[state.BaseLevel + 1]
        if nextTier then paragraph("PROCHAIN NIVEAU · " .. nextTier.Name .. "\n" .. nextTier.Display .. " espèces exposées · +" .. math.floor(nextTier.IncomeBonus * 100) .. " % de gold · aquarium agrandi", 76, C.Teal) end
        local upgrade = self:Row(76)
        local enabled = state.OwnBase and state.NearBaseSign and state.BaseUpgradeCost and state.Money >= state.BaseUpgradeCost
        button(upgrade, not state.NearBaseSign and "LOCALISER LA PANCARTE D’AMÉLIORATION" or state.BaseUpgradeCost and ("AMÉLIORER LA BASE · " .. UI.Format(state.BaseUpgradeCost) .. " GOLD") or "BASE AU NIVEAU MAXIMUM", { Position = UDim2.fromOffset(14, 16), Size = UDim2.new(1, -28, 0, 44), BackgroundColor3 = enabled and C.Gold or C.Panel, TextColor3 = enabled and C.Navy or C.Muted, ZIndex = 24 }, function() if enabled then self.Ctx.Action:FireServer("UpgradeBase") elseif not state.NearBaseSign then self.Ctx.Navigate(state.BaseSignPosition, "PANCARTE · AMÉLIORER LA BASE"); self:Open(nil) end end)
        paragraph((state.OwnBase and "ATELIER OUVERT" or "REJOIGNEZ VOTRE HABITAT POUR PERSONNALISER") .. "\nVotre galerie est sur le Néréide, près du bassin commun. Les décorations restent acquises après un prestige.", 84, C.Teal)
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
            "01  EXPLOREZ\nRejoignez le bassin central du navire et sautez : tous les plongeurs partent du même endroit. Nagez jusqu'aux nids lumineux. Un boss géant surveille tous les œufs du palier : combattez-le ou esquivez-le.",
            "02  REMPLISSEZ L’INVENTAIRE\nMaintenez E près d’un œuf. Il rejoint votre inventaire NON SÉCURISÉ, sans modèle dans le dos. Votre personnage brille de la couleur de sa rareté. Un seul œuf non sécurisé à la fois.",
            "03  COMBATTEZ\nÉquipez le harpon, visez avec la souris et cliquez. Sur mobile, visez au centre et utilisez TIRER. Un tir valide fait tomber l’œuf non sécurisé du joueur touché. Récupérez-le avec E pour le voler. Les tirs blessent aussi les boss.",
            "04  SÉCURISEZ\nRemontez par le bassin central et rejoignez VOTRE galerie sur le navire. Votre œuf est automatiquement sécurisé à l’arrivée dans votre propre galerie : il ne peut plus être volé et la surbrillance disparaît. Tous les habitats sont des zones sans combat.",
            "05  REMPLISSEZ L'AQUARIUM\nDéposez les œufs dans votre galerie avec E ou Collection. Éclosion : Common 15 s · Rare 40 s · Epic 90 s · Legendary 3 min · Mythic 6 min · Secret 12 min. Les animaux produisent des gold pour acheter l’équipement chez les sept marchands du pont.",
            "06  DESCENDEZ À VOS RISQUES\nToutes les profondeurs sont ouvertes. Combinaisons conseillées : 10 / 20 / 35 / 50 / 75. Les gardiens géants deviennent plus rapides et plus meurtriers si vous êtes mal équipé.",
            "07  RESPIREZ\nLes stations vertes O₂, la surface et le navire rechargent votre réserve. L'oxygène se consomme plus vite en profondeur. À zéro, votre santé diminue.",
            "08  PRENEZ DES RISQUES\nLes événements de 5, 15 et 40 minutes augmentent la rareté et le danger. Esquivez les ondes rouges annonçant les attaques des boss. Après sa défaite, un boss réapparaît après un court répit.",
            "09  ÉVOLUEZ\nFusionnez vos animaux dans votre habitat, découvrez les recettes secrètes, personnalisez la base et recommencez avec le prestige pour obtenir des bonus permanents.",
            "CRÉDITS DES DÉCORS\nPoly by Google, God Appeasers, Device Lab, Laney XR Labs — modèles via Poly Pizza, CC-BY 3.0 (creativecommons.org/licenses/by/3.0). Rochers, ruines et épave : WebGL Aquarium / Human Engines, Copyright Google Inc., BSD 3-Clause. Modèles adaptés et recolorés.",
            "COMMANDES\nWASD / joystick : nager · Espace / LB : monter · Ctrl / RB : descendre · Maj / X manette : propulseur · M : verrouiller / libérer la caméra · clic / RT : tirer · E : interagir.",
        }) do paragraph(text, 112) end
    end
    task.defer(function() if self.List.Parent then self.List.CanvasPosition = position end end)
end

function UI:Update(state)
    self.State = state; self.ReceivedAt = os.clock()
    self.InventoryButton.Text = self.Compact and ("🥚 " .. #state.Eggs) or ("🥚 INVENTAIRE · " .. #state.Eggs)
    self.QuickInventory.Text = "🥚 " .. #state.Eggs
    self.Money.Text = UI.Format(state.Money); self.Income.Text = "+" .. UI.Format(state.Income) .. " / min"
    local ratio = math.clamp(state.Oxygen / math.max(1, state.MaxOxygen), 0, 1)
    self.Oxygen.Text = math.ceil(ratio * 100) .. " %"
    self.OxygenPanel.Visible = state.Depth > 0 or ratio < 0.99
    self.Oxygen.TextColor3 = ratio < 0.2 and C.Red or C.Muted
    self.OxygenBar.Size = UDim2.fromScale(ratio, 1)
    self.OxygenBar.BackgroundColor3 = ratio < 0.2 and C.Red or C.Teal
    self.Depth.Text = state.Depth == 0 and "Surface" or state.Depth .. " m"; self.Floor.Text = state.Depth == 0 and "NÉRÉIDE" or self.Ctx.Config.Floors[state.Floor].ShortName
    self.Save.Text = state.SaveStatus; self.Save.TextColor3 = state.Offline and C.Gold or C.Muted
    self.Save.Visible = state.Offline or (state.SaveStatus ~= "Sauvegardé" and state.SaveStatus ~= "Sauvegarde active")
    self.EventName.Text = state.Event.Name; self.EventName.TextColor3 = state.Event.Active and C.Gold or C.White
    local waiting = 0
    for _, egg in ipairs(state.Eggs) do if not egg.ReadyAt then waiting += 1 end end
    self.Objective.Visible = state.Carrying ~= nil or (state.OwnBase and waiting > 0)
    self.Objective.Text = state.Carrying and ("ŒUF " .. string.upper(state.Carrying.Rarity) .. " · Retournez à votre base") or "E · Déposer vos œufs dans la cuve"
    self.Objective.TextColor3 = state.Carrying and self.Ctx.Visuals.Color(self.Ctx.Config.Rarities[state.Carrying.Rarity].Color) or #state.Eggs > 0 and C.Gold or C.White
    local signature = self.Tab or ""
    if self.Tab == "Collection" or self.Tab == "Bestiaire" or self.Tab == "Fusion" then
        for id in pairs(self.Ctx.Config.Animals) do
            signature ..= id .. (state.Animals[id] or 0) .. tostring(state.Discovered[id])
            for _, grade in ipairs({ "Gold", "Diamond", "Mythic" }) do signature ..= ((state.Variants[id] or {})[grade] or 0) end
        end
        for _, egg in ipairs(state.Eggs) do signature ..= egg.Id .. tostring(egg.ReadyAt) .. tostring(egg.Unsecured) end
        signature ..= tostring(state.OwnBase) .. state.Prestige
    elseif self.Tab == "Équipement" then
        for _, key in ipairs(self.Ctx.Config.UpgradeOrder) do local price = self.Ctx.Rules.UpgradeCost(self.Ctx.Config, key, state.Equipment[key]); signature ..= state.Equipment[key] .. tostring(price and state.Money >= price) end
        signature ..= tostring(state.NearMerchant)
    elseif self.Tab == "Téléportation" then signature ..= tostring(state.NearConsole) .. tostring(state.OwnBase)
    elseif self.Tab == "Prestige" then signature ..= state.Prestige .. tostring(state.Money >= state.PrestigeCost) .. state.Equipment.Suit .. tostring(state.OwnBase)
    elseif self.Tab == "Habitat" then for id in pairs(self.Ctx.Config.Decorations) do signature ..= id .. tostring(state.OwnedDecor[id]) end; signature ..= state.Palette .. tostring(state.OwnBase) .. tostring(state.NearBaseSign) .. state.BaseLevel .. tostring(state.BaseUpgradeCost and state.Money >= state.BaseUpgradeCost)
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
    self.EventTimer.Text = string.format("%02d:%02d", math.floor(remaining / 60), math.floor(remaining % 60))
    local cooldown = math.max(0, self.State.ShotRemaining - elapsed)
    self.Cooldown.Text = cooldown > 0 and string.format("Harpon · %.1f s", cooldown) or ""
    self.Cooldown.Visible = cooldown > 0 and not self.Tab
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
