--!nonstrict
-- Exercise actual shop callbacks with engine doubles, not native rendering.
local Engine = require("./support/Engine")
local e = Engine.new()
local game, workspace, script = e.Game, e.Workspace, e.Script
local Instance, Vector3, CFrame, Color3, Enum = e.Instance, e.Vector3, e.CFrame, e.Color3, e.Enum
local UDim2 = { new = function() return {} end, fromOffset = function() return {} end, fromScale = function() return {} end }
local UDim = { new = function() return {} end }
local Vector2 = { new = function(x, y) return { X = x, Y = y } end }
local NumberSequence = { new = function() return {} end }
local NumberSequenceKeypoint = { new = function() return {} end }
local task = { defer = function(fn) fn() end }
local factories, loaded = {}, {}
local function require(ref)
    if not loaded[ref.Name] then loaded[ref.Name] = factories[ref.Name]() end
    return loaded[ref.Name]
end
--[[ MODULES ]]
local Config, Rules, UI = factories.Config(), factories.Rules(), factories.UI()
local root = Instance.new("Frame")
local sent, navigation = {}, nil
local ctx = { Config = Config, Rules = Rules, Visuals = factories.Visuals(),
    Action = { FireServer = function(_, ...) table.insert(sent, { ... }) end },
    Navigate = function(position, title) navigation = { Position = position, Title = title } end }
local shop = setmetatable({ Ctx = ctx, List = Instance.new("ScrollingFrame"), Title = Instance.new("TextLabel"),
    Modal = Instance.new("Frame"), Dimmer = Instance.new("TextButton"), Ingredients = {} }, UI)
shop.List.Parent = root; shop.List.CanvasPosition = {}
local state = Rules.NewProfile(Config)
state.NearMerchant = nil; state.Merchants = { Oxygen = Vector3.new(25, 120, 130) }
state.Money = 1000
shop.State = state
local passed = 0
local function check(value, message) assert(value, message); passed += 1 end
local function click(text)
    for _, item in ipairs(shop.List:GetDescendants()) do
        if item.ClassName == "TextButton" and item.Text == text then item.Activated:Fire(); return end
    end
    error("Missing button: " .. text)
end
shop:OpenShop("Oxygen")
click("LOCALISER CE MARCHAND")
check(navigation.Position == state.Merchants.Oxygen and navigation.Title == "BULLE", "Remote shop browsing gives directions to the selected merchant")
check(#sent == 0 and shop.Tab == nil, "Directions close the modal without charging gold")
state.NearMerchant = "Oxygen"
shop:OpenShop("Oxygen")
click("ACHETER L’AMÉLIORATION")
check(#sent == 1 and sent[1][1] == "Upgrade" and sent[1][2] == "Oxygen", "Specialist purchase sends only the chosen equipment key")
state.Money = 0
shop:RenderPanel()
click("IL MANQUE 75 GOLD")
check(#sent == 1, "Insufficient gold cannot trigger a purchase callback")
state.Money = 1000; state.Equipment.Oxygen = Config.Upgrades.Oxygen.Max
shop:RenderPanel(); click("ÉQUIPEMENT AU MAXIMUM")
check(#sent == 1, "Maximum equipment cannot be purchased again")
state.NearBaseSign = false; state.OwnBase = true; state.BaseUpgradeCost = 600
state.BaseSignPosition = Vector3.new(100, 120, 30)
shop:Open("Habitat"); click("LOCALISER LA PANCARTE D’AMÉLIORATION")
check(navigation.Position == state.BaseSignPosition and shop.Tab == nil, "Base upgrades have their own sign directions")
state.NearBaseSign = true
shop:Open("Habitat"); click("AMÉLIORER LA BASE · 600 GOLD")
check(#sent == 2 and sent[2][1] == "UpgradeBase", "Base upgrade button submits its separate action")
state.OwnBase = false
shop:RenderPanel(); click("AMÉLIORER LA BASE · 600 GOLD")
check(#sent == 2, "Visiting another base does not enable base purchases")
state.OwnBase = true; state.NearConsole = true; state.ConsolePosition = Vector3.new(1, 117, 32)
shop:Open("Téléportation"); click("SE TÉLÉPORTER")
check(sent[#sent][1] == "TeleportMerchant" and type(sent[#sent][2]) == "string", "The computer sends a merchant key rather than client-selected coordinates")
local before = #sent
state.NearConsole = false; shop:RenderPanel(); click("REJOINDRE LE PC")
check(#sent == before and navigation.Position == state.ConsolePosition, "Remote computer browsing gives directions without teleporting")
local input = { MouseBehavior = "camera-right-click", MouseIconEnabled = true }
local aim = factories.AimController().new(input)
local humanoid = { GetState = function() return "Swimming" end }
local avatarRoot = Instance.new("Part"); avatarRoot.CFrame = CFrame.new(12, 4, 8)
local camera = { CFrame = { LookVector = Vector3.new(1, 0, 0) } }
aim:Step(humanoid, avatarRoot, camera, false, true)
check(input.MouseBehavior == "camera-right-click", "Free aim preserves Roblox right-click camera controls")
aim:Toggle(); aim:Step(humanoid, avatarRoot, camera, false, true)
check(aim:Centered({ Name = "MouseMovement" }), "Locked mouse aim uses the centered reticle ray")
check(input.MouseBehavior == Enum.MouseBehavior.LockCenter and humanoid.AutoRotate == false and humanoid.CameraOffset.X > 0, "M enables centered aim and shoulder camera lock")
check(avatarRoot.Position.X == 12 and avatarRoot.Position.Y == 4, "Camera lock never teleports the player")
aim:Step(humanoid, avatarRoot, camera, true, true)
check(input.MouseBehavior == Enum.MouseBehavior.Default and input.MouseIconEnabled and humanoid.AutoRotate, "Opening a shop releases the pointer for its buttons")
aim:Step(humanoid, avatarRoot, camera, false, true)
check(input.MouseBehavior == Enum.MouseBehavior.LockCenter, "Closing a shop restores the selected camera lock")
aim.Focused = false; aim:Step(humanoid, avatarRoot, camera, false, true)
check(input.MouseBehavior == Enum.MouseBehavior.Default, "Losing window focus releases the cursor")
aim.Focused = true; aim:Toggle(); aim:Step(humanoid, avatarRoot, camera, false, false)
check(input.MouseBehavior == Enum.MouseBehavior.Default and input.MouseIconEnabled and humanoid.CameraOffset.Magnitude == 0, "Second M restores normal camera and cursor")
check(not aim:Centered({ Name = "MouseMovement" }) and aim:Centered({ Name = "Gamepad1" }) and aim:Centered(Enum.UserInputType.Touch), "Mouse free aim follows the pointer while touch and gamepad stay centered")
local AimController = factories.AimController()
check(AimController.InputAction(Enum.KeyCode.M) == "Camera", "M toggles the camera")
check(AimController.InputAction(Enum.KeyCode.LeftShift) == "Boost" and AimController.InputAction(Enum.KeyCode.RightShift) == "Boost", "Both Shift keys boost without locking the camera")
check(AimController.InputAction(Enum.KeyCode.R) == nil and AimController.InputAction(Enum.KeyCode.ButtonX) == "Boost", "R is free and controller boost is preserved")
for _, width in ipairs({ 350, 480, 680, 720, 1000, 1600 }) do
    local layout = UI.BrowserLayout(width, 650)
    check(layout.Columns * layout.CellWidth + (layout.Columns - 1) * 10 <= layout.GridWidth, "Collection cards fit narrow and wide screens")
    check(layout.Stacked or layout.GridWidth + layout.DetailsWidth + 18 == width, "Detail panel cannot overlap the card grid")
end
local player = e:Player(99); e.Players.LocalPlayer = player
local playerGui = Instance.new("PlayerGui"); playerGui.Parent = player
workspace.CurrentCamera = Instance.new("Camera"); workspace.CurrentCamera.ViewportSize = { X = 1440, Y = 900 }
ctx.Equip = function() end; ctx.Fire = function() end
local full = UI.new(ctx)
check(full.Gui.Parent == playerGui and full.CollectionTabs, "The real HUD and collection window construct successfully")
full.State = state; state.Eggs = {}; state.Income = 100; state.Animals = {}; state.Discovered = {}
for id in pairs(Config.Animals) do state.Animals[id] = 1; state.Discovered[id] = true end
full.CollectionMode = "Animaux"; full:Open("Collection")
local function cards()
    local result = {}
    for _, child in ipairs(full.Browser["Grille de collection"]:GetChildren()) do if child:IsA("TextButton") then table.insert(result, child) end end
    return result
end
check(#cards() == 12 and full.BrowserPages > 1, "A large collection is limited to twelve preview cards per page")
local firstPage = cards()[1].Name
full.NextPage.Activated:Fire()
check(full.CollectionPage == 2 and cards()[1].Name ~= firstPage, "Next page displays a different set of animals")
full.PreviousPage.Activated:Fire()
check(full.CollectionPage == 1 and cards()[1].Name == firstPage, "Previous page restores the first animals")
local browserSent = #sent
state.Eggs = { { Id = "test-egg", Name = "Œuf de récif", Rarity = "Rare", Unsecured = true } }
full.CollectionMode = "Œufs"; full:Open("Collection")
for _, child in ipairs(full.Browser:GetDescendants()) do if child:IsA("TextButton") and child.Text == "À SÉCURISER" then child.Activated:Fire() end end
check(#sent == browserSent, "An unsecured egg card cannot hatch or deposit it")
state.Eggs[1].Unsecured = false; state.Eggs[1].ReadyAt = nil; state.OwnBase = true
full:RenderPanel()
for _, child in ipairs(full.Browser:GetDescendants()) do if child:IsA("TextButton") and child.Text == "DÉPOSER DANS LA CUVE" then child.Activated:Fire() end end
check(#sent == browserSent + 1 and sent[#sent][1] == "Hatch" and sent[#sent][2] == "test-egg", "The egg detail action deposits the selected secured egg")
state.Eggs[1].ReadyAt = 1700000015
full:RenderPanel()
check(#full.HatchTimers == 1, "Selected incubating egg retains its live countdown")
state.Discovered = {}; full:Open("Bestiaire")
for _, card in ipairs(cards()) do
    local hasUnknown = false
    for _, label in ipairs(card:GetChildren()) do if label.ClassName == "TextLabel" and label.Text == "???" then hasUnknown = true end end
    check(hasUnknown, "Undiscovered species hide their names in the grid")
end
workspace.CurrentCamera.ViewportSize = { X = 390, Y = 844 }; workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Fire()
check(full.Compact and full.MenuItems[1].Button.Text == "🥚", "Small screens switch the HUD navigation to compact icons")
full:OpenShop("Oxygen")
check(not full.Browser.Visible and full.List.Visible and not full.CollectionTabs.Visible, "Shop pages release the collection grid and restore their purchase controls")
print(string.format("UI: %d assertions passed (callbacks with engine fakes; native rendering untested)", passed))
