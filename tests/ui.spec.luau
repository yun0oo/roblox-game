--!nonstrict
-- Exercise actual shop callbacks with engine doubles, not native rendering.
local Engine = require("./support/Engine")
local e = Engine.new()
local game, workspace, script = e.Game, e.Workspace, e.Script
local Instance, Vector3, CFrame, Color3, Enum = e.Instance, e.Vector3, e.CFrame, e.Color3, e.Enum
local UDim2 = { new = function() return {} end, fromOffset = function() return {} end, fromScale = function() return {} end }
local UDim = { new = function() return {} end }
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
local input = { MouseBehavior = "camera-right-click", MouseIconEnabled = true }
local aim = factories.AimController().new(input)
local humanoid = { GetState = function() return "Swimming" end }
local avatarRoot = Instance.new("Part"); avatarRoot.CFrame = CFrame.new(12, 4, 8)
local camera = { CFrame = { LookVector = Vector3.new(1, 0, 0) } }
aim:Step(humanoid, avatarRoot, camera, false, true)
check(input.MouseBehavior == "camera-right-click", "Free aim preserves Roblox right-click camera controls")
aim:Toggle(); aim:Step(humanoid, avatarRoot, camera, false, true)
check(aim:Centered({ Name = "MouseMovement" }), "Locked mouse aim uses the centered reticle ray")
check(input.MouseBehavior == Enum.MouseBehavior.LockCenter and humanoid.AutoRotate == false and humanoid.CameraOffset.X > 0, "Shift enables centered aim and shoulder camera lock")
check(avatarRoot.Position.X == 12 and avatarRoot.Position.Y == 4, "Camera lock never teleports the player")
aim:Step(humanoid, avatarRoot, camera, true, true)
check(input.MouseBehavior == Enum.MouseBehavior.Default and input.MouseIconEnabled and humanoid.AutoRotate, "Opening a shop releases the pointer for its buttons")
aim:Step(humanoid, avatarRoot, camera, false, true)
check(input.MouseBehavior == Enum.MouseBehavior.LockCenter, "Closing a shop restores the selected camera lock")
aim.Focused = false; aim:Step(humanoid, avatarRoot, camera, false, true)
check(input.MouseBehavior == Enum.MouseBehavior.Default, "Losing window focus releases the cursor")
aim.Focused = true; aim:Toggle(); aim:Step(humanoid, avatarRoot, camera, false, false)
check(input.MouseBehavior == Enum.MouseBehavior.Default and input.MouseIconEnabled and humanoid.CameraOffset.Magnitude == 0, "Second Shift restores normal camera and cursor")
check(not aim:Centered({ Name = "MouseMovement" }) and aim:Centered({ Name = "Gamepad1" }) and aim:Centered(Enum.UserInputType.Touch), "Mouse free aim follows the pointer while touch and gamepad stay centered")
print(string.format("UI: %d assertions passed (callbacks with engine fakes; native rendering untested)", passed))
