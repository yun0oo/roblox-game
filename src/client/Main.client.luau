--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer
local modules = ReplicatedStorage:WaitForChild("Modules")
local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local Config = require(modules.Config)
local Rules = require(modules.Rules)
local Visuals = require(modules.Visuals)
local UI = require(script.Parent.UI)
local controls
task.spawn(function()
    local module = player.PlayerScripts:WaitForChild("PlayerModule", 15)
    if module then
        -- PlayerModule is supplied at runtime by Roblox, outside the Rojo sourcemap.
        local loadRuntimeModule: (Instance) -> any = require
        local ok, result = pcall(function() return loadRuntimeModule(module):GetControls() end)
        if ok then controls = result end
    end
end)

local context = { Config = Config, Rules = Rules, Visuals = Visuals, Action = remotes.Action }
local ui, character, humanoid, root, velocity, light, lampAttachment
local movement = Vector3.zero
local padUp, padDown = false, false

function context.Equip()
    if not humanoid or humanoid.Health <= 0 then return end
    local backpack = player:FindFirstChild("Backpack")
    local tool = backpack and backpack:FindFirstChild("Harpon")
    if tool then humanoid:EquipTool(tool) end
end

function context.Fire()
    if not root or not humanoid or humanoid.Health <= 0 or (ui and ui.Tab) then return end
    if not character:FindFirstChild("Harpon") then context.Equip(); return end
    local camera = workspace.CurrentCamera
    local input = UserInputService:GetLastInputType()
    local ray
    if input == Enum.UserInputType.Touch or string.find(input.Name, "Gamepad") then
        ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    else
        local mouse = UserInputService:GetMouseLocation()
        ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
    end
    local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { character, workspace:WaitForChild("Eggs"), workspace:WaitForChild("Events") }; params.IgnoreWater = true
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
    local aim = (hit and hit.Position or ray.Origin + ray.Direction * 600) - root.Position
    if aim.Magnitude > 0.1 then context.Action:FireServer("Fire", aim.Unit) end
end

ui = UI.new(context)
remotes.Snapshot.OnClientEvent:Connect(function(state) ui:Update(state) end)
remotes.Notice.OnClientEvent:Connect(function(message, tone) ui:Toast(message, tone) end)

local function attach(newCharacter)
    character = newCharacter
    root = newCharacter:WaitForChild("HumanoidRootPart")
    humanoid = newCharacter:WaitForChild("Humanoid")
    movement = Vector3.zero
    local attachment = Instance.new("Attachment"); attachment.Name = "SwimAttachment"; attachment.Parent = root
    velocity = Instance.new("LinearVelocity")
    velocity.Name = "SwimController"; velocity.Attachment0 = attachment
    velocity.Enabled = false
    velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    velocity.RelativeTo = Enum.ActuatorRelativeTo.World; velocity.ForceLimitsEnabled = false
    velocity.VectorVelocity = Vector3.zero; velocity.Parent = root
    lampAttachment = Instance.new("Attachment"); lampAttachment.Name = "DivingLamp"; lampAttachment.Parent = root
    light = Instance.new("SpotLight"); light.Color = Color3.fromRGB(194, 246, 238)
    light.Angle = 85; light.Brightness = 2.4; light.Range = 24; light.Shadows = true; light.Parent = lampAttachment
end
player.CharacterAdded:Connect(attach)
if player.Character then task.spawn(attach, player.Character) end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonX then context.Action:FireServer("Boost")
    elseif input.KeyCode == Enum.KeyCode.ButtonL1 then padUp = true
    elseif input.KeyCode == Enum.KeyCode.ButtonR1 then padDown = true
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then context.Fire()
    elseif input.KeyCode == Enum.KeyCode.Escape and ui.Tab then ui:Open(nil) end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.ButtonL1 then padUp = false end
    if input.KeyCode == Enum.KeyCode.ButtonR1 then padDown = false end
end)
UserInputService.WindowFocusReleased:Connect(function() ui.Ascend = 0; ui.Descend = 0; padUp = false; padDown = false end)

local correction = Instance.new("ColorCorrectionEffect")
correction.Name = "UnderwaterAtmosphere"; correction.Saturation = -0.08; correction.Parent = Lighting
local function localSound(position, soundId, volume)
    local part = Visuals.Part(workspace.Events, "Audio", Vector3.one, CFrame.new(position), Color3.new())
    part.Transparency = 1
    local sound = Instance.new("Sound"); sound.SoundId = soundId; sound.Volume = volume; sound.RollOffMaxDistance = 90; sound.Parent = part
    sound:Play(); Debris:AddItem(part, 4)
end

remotes.FX.OnClientEvent:Connect(function(kind, data)
    if kind == "OpenUpgrades" then ui:Open("Équipement")
    elseif kind == "OpenBase" then ui:Open("Habitat")
    elseif kind == "Shot" then
        localSound(data.Position, "rbxasset://sounds/swordslash.wav", 0.25)
        local tool = character and character:FindFirstChild("Harpon")
        if data.UserId == player.UserId and tool then
            TweenService:Create(tool, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), { Grip = tool.Grip * CFrame.new(0, 0, 0.35) }):Play()
        end
    elseif kind == "BossWarning" then
        local part = Visuals.Part(workspace.Events, "Onde annoncée", Vector3.one, CFrame.new(data.Position), Color3.fromRGB(255, 92, 147), Enum.Material.Neon, Enum.PartType.Ball)
        part.Transparency = 0.8
        TweenService:Create(part, TweenInfo.new(1.2), { Size = Vector3.one * data.Radius * 2, Transparency = 1 }):Play(); Debris:AddItem(part, 1.3)
    elseif kind == "Impact" then
        local part = Visuals.Part(workspace.Events, "Impact", Vector3.one, CFrame.new(data.Position), Color3.fromRGB(147, 255, 231), Enum.Material.Neon, Enum.PartType.Ball)
        TweenService:Create(part, TweenInfo.new(0.3), { Size = Vector3.one * 6, Transparency = 1 }):Play(); Debris:AddItem(part, 0.35)
        localSound(data.Position, "rbxasset://sounds/impact_water.mp3", 0.3)
    elseif kind == "Damage" then
        local flash = Instance.new("Frame"); flash.Size = UDim2.fromScale(1, 1); flash.BackgroundColor3 = Color3.fromRGB(237, 72, 107)
        flash.BackgroundTransparency = 0.75; flash.BorderSizePixel = 0; flash.ZIndex = 10; flash.Parent = ui.Root
        TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play(); Debris:AddItem(flash, 0.5)
    elseif kind == "Hatch" then
        local spec = Config.Animals[data.AnimalId]
        if not spec then return end
        local egg = Visuals.Egg(workspace.Events, "Éclosion", Config.Rarities[spec.Rarity], CFrame.new(data.Position))
        egg.CanQuery = false
        TweenService:Create(egg, TweenInfo.new(0.85, Enum.EasingStyle.Elastic), { Size = egg.Size * 1.6, CFrame = egg.CFrame * CFrame.Angles(0, 2, 0) }):Play()
        task.delay(0.9, function()
            egg:Destroy()
            local model = Visuals.Animal(workspace.Events, spec, CFrame.new(data.Position), 1.8)
            Debris:AddItem(model, 3)
            localSound(data.Position, "rbxasset://sounds/electronicpingshort.wav", 0.4)
            ui:Hatch(data.AnimalId, data.Grade)
        end)
    end
end)

local uiTick = 0
RunService.RenderStepped:Connect(function(dt)
    uiTick += dt
    if uiTick > 0.1 then ui:Tick(); uiTick = 0 end
    if not root or not root.Parent or not humanoid or humanoid.Health <= 0 or not character:GetAttribute("UnderwaterReady") then
        if velocity then velocity.Enabled = false end
        return
    end
    local camera = workspace.CurrentCamera
    local lastInput = UserInputService:GetLastInputType()
    ui.Reticle.Visible = not ui.Tab and (lastInput == Enum.UserInputType.Touch or string.find(lastInput.Name, "Gamepad") ~= nil)
    local inset = GuiService:GetGuiInset()
    ui.Reticle.Position = UDim2.fromOffset((camera.ViewportSize.X / 2 - inset.X) / ui.Scale.Scale, (camera.ViewportSize.Y / 2 - inset.Y) / ui.Scale.Scale)
    local move = Vector3.zero
    if not UserInputService:GetFocusedTextBox() and not ui.Tab then
        if controls then move = controls:GetMoveVector() else
            move = Vector3.new((UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0), 0,
                (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0))
        end
        move = camera.CFrame:VectorToWorldSpace(move)
        local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) or padUp or ui.Ascend > 0
        local down = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) or padDown or ui.Descend > 0
        move += Vector3.new(0, (up and 1 or 0) - (down and 1 or 0), 0)
    end
    if move.Magnitude > 1 then move = move.Unit end
    local speed = player:GetAttribute("SwimSpeed") or 20
    local current = Vector3.new(player:GetAttribute("CurrentX") or 0, 0, player:GetAttribute("CurrentZ") or 0)
    movement = movement:Lerp(move * speed + current, 1 - math.exp(-dt * 9))
    local underwater = root.Position.Y < Config.WaterTop + 1 and humanoid:GetState() ~= Enum.HumanoidStateType.Climbing
    velocity.Enabled = underwater
    if underwater then
        velocity.VectorVelocity = movement
        humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
    else
        movement = Vector3.zero
    end
    light.Enabled = underwater
    lampAttachment.CFrame = root.CFrame:ToObjectSpace(CFrame.lookAt(root.Position, root.Position + camera.CFrame.LookVector))
    local lampLevel = player:GetAttribute("LampLevel") or 1
    light.Range = 24 + (lampLevel - 1) * 8; light.Brightness = 2.4 + lampLevel * 0.3
    local floor = Rules.FloorAt(Config, root.Position.Y)
    local event = ui.State and ui.State.Event.Active
    local darkness = (floor.Id - 1) / math.max(1, #Config.Floors - 1) * 0.78 + (event and 0.12 or 0)
    Lighting.Brightness = 1.8 - darkness * 1.5
    Lighting.Ambient = Color3.fromRGB(45, 107, 131):Lerp(Color3.fromRGB(9, 18, 43), darkness)
    Lighting.FogColor = Color3.fromRGB(35, 120, 145):Lerp(Color3.fromRGB(12, 24, 52), darkness)
    Lighting.FogStart = 25; Lighting.FogEnd = 210 - darkness * 170 + lampLevel * 4
    correction.TintColor = Color3.fromRGB(207, 246, 255):Lerp(Color3.fromRGB(139, 172, 225), darkness * 0.5)
    if not underwater then
        Lighting.Brightness = 2.5; Lighting.Ambient = Color3.fromRGB(135, 151, 158)
        Lighting.FogStart = 700; Lighting.FogEnd = 1800
        Lighting.FogColor = Color3.fromRGB(170, 221, 241)
        correction.TintColor = Color3.new(1, 1, 1)
    end
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        atmosphere.Density = underwater and (0.22 + darkness * 0.4) or 0.24
        atmosphere.Haze = underwater and (1.3 + darkness * 2) or 1
        atmosphere.Color = underwater and Lighting.FogColor or Color3.fromRGB(176, 209, 227)
    end
    camera.FieldOfView += ((70 + math.max(0, speed - 25) * 0.35) - camera.FieldOfView) * math.min(1, dt * 5)
    if ui.State then
        local toDive = root.Position.Y > Config.WaterTop and not ui.State.Carrying and not ui.State.OwnBase
        local delta = (toDive and ui.State.DivePosition or ui.State.BasePosition) - root.Position
        local localDirection = camera.CFrame:VectorToObjectSpace(delta)
        local arrow = math.abs(localDirection.X) > math.abs(localDirection.Z) and (localDirection.X > 0 and "→" or "←") or (localDirection.Z < 0 and "↑" or "↓")
        ui.Compass.Text = ui.State.OwnBase and "◇ VOTRE GALERIE · AQUARIUM SÉCURISÉ" or (arrow .. (toDive and "  Bassin commun · " or "  Votre galerie · ") .. math.floor(delta.Magnitude) .. " studs")
    end
end)
context.Action:FireServer("Sync")
