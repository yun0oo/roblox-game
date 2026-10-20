--!nonstrict
-- Runs independently of the gameplay modules and RemoteEvents, so a failed
-- server boot cannot leave the player looking at an unexplained empty scene.
local player = game:GetService("Players").LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "UnderwaterLoading"; gui.ResetOnSpawn = false; gui.DisplayOrder = 100
local text = Instance.new("TextLabel")
text.AnchorPoint = Vector2.new(0.5, 0)
text.Position = UDim2.fromScale(0.5, 0.14); text.Size = UDim2.new(0.85, 0, 0, 110)
text.BackgroundColor3 = Color3.fromRGB(12, 40, 57); text.BackgroundTransparency = 0.1
text.TextColor3 = Color3.fromRGB(188, 255, 237); text.Font = Enum.Font.GothamBold
text.TextSize = 19; text.TextWrapped = true; text.Parent = gui
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = text
gui.Parent = player:WaitForChild("PlayerGui")

local function update()
    local state = workspace:GetAttribute("UnderwaterBootState")
    local character = player.Character
    gui.Enabled = state ~= "Ready" or not character or not character:GetAttribute("UnderwaterReady")
    if state == "Failed" then
        text.Text = "UNDERWATER EGG · ERREUR DE DÉMARRAGE\n" .. (workspace:GetAttribute("UnderwaterBootMessage") or "Consultez Sortie / Output dans Studio.")
        text.TextColor3 = Color3.fromRGB(255, 178, 172)
    elseif state == "Ready" then
        text.Text = "UNDERWATER EGG\nPréparation de votre plongeur et de votre habitat…"
    else
        text.Text = "UNDERWATER EGG\n" .. (workspace:GetAttribute("UnderwaterBootMessage") or "Connexion au serveur…")
    end
end
local function watchCharacter(character)
    character:GetAttributeChangedSignal("UnderwaterReady"):Connect(update)
    update()
end
workspace:GetAttributeChangedSignal("UnderwaterBootState"):Connect(update)
workspace:GetAttributeChangedSignal("UnderwaterBootMessage"):Connect(update)
player.CharacterAdded:Connect(watchCharacter)
player.CharacterRemoving:Connect(function() gui.Enabled = true end)
if player.Character then watchCharacter(player.Character) end
update()
