--!nonstrict
-- Exercise actual shop callbacks with engine doubles, not native rendering.
local Engine = require("./support/Engine")
local OceanLook = require("../src/client/OceanLook")
local e = Engine.new()
local game, workspace, script = e.Game, e.Workspace, e.Script
local Instance, Vector3, CFrame, Color3, Enum = e.Instance, e.Vector3, e.CFrame, e.Color3, e.Enum
local UDim2 = { new = function() return {} end, fromOffset = function() return {} end, fromScale = function() return {} end }
local UDim = { new = function() return {} end }
local Vector2 = { new = function(x, y) return { X = x, Y = y } end }
local NumberSequence = { new = function() return {} end }
local NumberSequenceKeypoint = { new = function() return {} end }
local noticeTimers = {}
local task = { defer = function(fn) fn() end, delay = function(_, fn) table.insert(noticeTimers, fn) end }
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
local daylight = OceanLook.At(Config, Config.WaterTop + 10, 1)
local reefLook = OceanLook.At(Config, Config.WaterTop - 60, 1)
check(daylight.Underwater == 0 and reefLook.Underwater == 1, "The look follows camera immersion and leaves the deck in daylight")
for _, floor in ipairs(Config.Floors) do
    local y = (floor.Top + floor.Bottom) / 2
    local normal = OceanLook.At(Config, y, 1)
    local storm = OceanLook.At(Config, y, 1, "Legendary")
    local lamp = OceanLook.At(Config, y, Config.Upgrades.Lamp.Max)
    check(normal.Brightness >= 2.3 and storm.Brightness > 2.2 and storm.FogEnd > 300, "Every biome and storm keeps playable lighting and visible pursuit distance")
    check(lamp.FogEnd > normal.FogEnd and normal.Density < .14, "A stronger lamp improves visibility without a thick colour veil")
end
for i = 1, #Config.Floors - 1 do
    local boundary = Config.Floors[i].Bottom
    local a, b = OceanLook.At(Config, boundary + .01, 1), OceanLook.At(Config, boundary - .01, 1)
    check(math.abs(a.FogEnd - b.FogEnd) < .1 and math.abs(a.Exposure - b.Exposure) < .001 and math.abs(a.FogColor[1] - b.FogColor[1]) < .1, "Colour, fog and exposure remain continuous at a depth boundary")
end
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
check(not full.Menu.Visible and not full.OxygenPanel.Visible and not full.Objective.Visible, "Exploration starts with the drawer closed and no empty objective or surface oxygen meter")
full.MenuButton.Activated:Fire()
check(full.Menu.Visible, "The compact menu button exposes all expedition pages")
full:ToggleMenu(); check(not full.Menu.Visible, "B menu uses the same reversible drawer state as the mouse button")
full:ToggleMenu()
check(full.Menu.Visible, "Keyboard access can release camera lock without changing its selected mode")
state.Eggs = {}; state.Income = 100; state.Oxygen = 100; state.MaxOxygen = 100
state.Depth = 0; state.Floor = 1; state.SaveStatus = "Sauvegardé"; state.Offline = false
state.Event = { Name = "Prochain événement", Active = false, Remaining = 300 }
state.ServerTime = 1700000000; state.ShotRemaining = 0; state.BoostRemaining = 0
full:Update(state); full:Tick()
check(not full.OxygenPanel.Visible and not full.Save.Visible and not full.Cooldown.Visible, "Full surface oxygen, successful saves and ready harpoon do not create permanent HUD messages")
state.Depth = 30; state.Oxygen = 18; state.Offline = true; state.SaveStatus = "STUDIO · NON SAUVEGARDÉ"
full:Update(state)
check(full.OxygenPanel.Visible and full.Oxygen.Text == "18 %" and full.Save.Visible, "Diving shows the small oxygen meter and temporary Studio saves remain explicit")
state.Carrying = { Rarity = "Rare" }
full:Update(state)
check(full.Objective.Visible and string.find(full.Objective.Text, "RARE"), "A vulnerable inventory egg keeps its return instruction visible")
state.Carrying = nil; state.OwnBase = true
state.Eggs = { { Id = "secured", Rarity = "Rare" } }
full:Update(state)
check(full.Objective.Visible, "A secured unincubated egg keeps the deposit instruction at home")
state.Eggs[1].ReadyAt = state.ServerTime + 40
full:Update(state)
check(not full.Objective.Visible, "Incubating eggs do not leave a stale deposit instruction")
state.Eggs = {}; full:Open("Guide")
check(not full.Menu.Visible, "Opening a page closes the navigation drawer")
full:Open(nil)
full:Toast("Œuf sécurisé", "Rare"); local oldest = full.Notices[1]
full:Toast("Équipement amélioré", "Success"); full:Toast("Oxygène faible", "Warning")
check(#full.Notices == 2 and oldest.Destroyed, "Notifications stay limited to two compact notices")
for _, expire in ipairs(noticeTimers) do expire() end
check(#full.Notices == 0, "Timed notifications disappear completely")
full.State = state; state.Eggs = {}; state.Income = 100; state.Animals = {}; state.Discovered = {}
for id in pairs(Config.Animals) do state.Animals[id] = 1; state.Discovered[id] = true end
full.CollectionMode = "Animaux"; full:Open("Collection")
local function cards()
    local result = {}
    for _, child in ipairs(full.Browser["Grille de collection"]:GetChildren()) do if child:IsA("TextButton") then table.insert(result, child) end end
    return result
end
check(#cards() == 12 and full.BrowserPages > 1, "A large collection is limited to twelve preview cards per page")
local allCount = full.BrowserPages
full.Browser["Filtre ÉVÉNEMENTS"].Activated:Fire()
check(full.EventFilter and #cards() == 12 and full.BrowserPages < allCount, "The event filter isolates the twelve exclusive species without losing pagination")
for _, card in ipairs(cards()) do
    local id = string.sub(card.Name, 7)
    check(Config.Animals[id].EventOnly, "Event collection cards cannot include an ordinary animal")
end
check(UI.RarityLabel(Config, "Tempest") == "TEMPÊTE" and UI.RarityLabel(Config, "Celestial") == "CÉLESTE", "French names are used for the new rarity labels")
local tempest = Config.Animals.tempest_1
local celestial = Config.Animals.celestial_1
check(string.find(UI.EventDescription(Config, tempest), Config.Animals[tempest.IncomeReference].Name, 1, true), "Event animal details name the exact income comparison species")
check(string.find(UI.EventDescription(Config, celestial), "ABYSSAL STORM UNIQUEMENT", 1, true), "Celestial acquisition is explicitly limited to the legendary event")
check(UI.EventDescription(Config, Config.Animals.clownfish) == nil, "Ordinary species do not gain an event-only label")
full.Browser["Filtre TOUT"].Activated:Fire()
check(not full.EventFilter and full.BrowserPages == allCount, "Clearing the event filter restores the entire collection")
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
check(full.Compact and full.MenuItems[1].Button.Text == "ŒUFS & ANIMAUX", "Small screens keep readable menu labels inside the collapsible drawer")
full:OpenShop("Oxygen")
check(not full.Browser.Visible and full.List.Visible and not full.CollectionTabs.Visible, "Shop pages release the collection grid and restore their purchase controls")
print(string.format("UI: %d assertions passed (callbacks with engine fakes; native rendering untested)", passed))
