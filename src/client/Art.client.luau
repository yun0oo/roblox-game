--!nonstrict
-- Cosmetic geometry stays on the client, with a distance limit and a build
-- budget. Server hitboxes, pickups, damage and ownership remain authoritative.
local RunService = game:GetService("RunService")
local modules = game:GetService("ReplicatedStorage"):WaitForChild("Modules")
local Renderer = require(modules:WaitForChild("ArtRenderer"))
local roots = {}
local function watch(instance)
    if instance:IsA("BasePart") and instance:GetAttribute("ArtAsset") then roots[instance] = {} end
end
for _, instance in ipairs(workspace:GetDescendants()) do watch(instance) end
workspace.DescendantAdded:Connect(watch)
local tick = 0
RunService.RenderStepped:Connect(function(dt)
    local camera = workspace.CurrentCamera
    if not camera then return end
    tick += dt
    local buildBudget = tick >= 0.12 and 1 or 0
    if buildBudget > 0 then tick = 0 end
    for root, record in pairs(roots) do
        if not root.Parent then
            if record.Model then record.Model:Destroy() end
            roots[root] = nil
            continue
        end
        local distance = (root.Position - camera.CFrame.Position).Magnitude
        if distance > 270 then
            if record.Model then record.Model:Destroy(); record.Model = nil end
            continue
        end
        if not record.Model and buildBudget > 0 and not record.Loading and not record.Failed then
            record.Loading = true; buildBudget -= 1
            task.spawn(function()
                local key = root:GetAttribute("ArtAsset")
                local scale = root:GetAttribute("ArtScale") or 1
                if key == "egg" then scale = root.Size.Y / Renderer.Bounds(key)[2] end
                local ok, model = pcall(Renderer.Build, key, root.Color, scale, true)
                record.Loading = false
                if not ok then
                    record.Failed = true
                    warn("[Underwater Egg] Modèle visuel indisponible:", key, model)
                    return
                end
                if not root.Parent then model:Destroy(); return end
                model.Parent = root
                model:PivotTo(root.CFrame)
                root.LocalTransparencyModifier = 1
                local aura = root:FindFirstChild("Aura de rareté")
                if aura then aura.Adornee = model end
                record.Model = model; record.Frame = root.CFrame; record.InitialHeight = root.Size.Y
            end)
        end
        if record.Model then
            if root:GetAttribute("ArtAsset") == "egg" then
                local scale = root.Size.Y / record.InitialHeight
                if math.abs(scale - (record.Scale or 1)) > 0.002 then record.Model:ScaleTo(scale); record.Scale = scale end
            end
            -- Smooth server updates instead of moving every triangle over the network.
            if record.Frame ~= root.CFrame then
                if (record.Frame.Position - root.Position).Magnitude < 0.005 and (record.Frame.LookVector - root.CFrame.LookVector).Magnitude < 0.002 then
                    record.Frame = root.CFrame
                else record.Frame = record.Frame:Lerp(root.CFrame, math.min(1, dt * 18)) end
                record.Model:PivotTo(record.Frame)
            end
        end
    end
end)
