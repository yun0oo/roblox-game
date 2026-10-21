--!nonstrict
-- Licensed marine scenery is local, bounded and independent of gameplay models.
local RunService = game:GetService("RunService")
local modules = game:GetService("ReplicatedStorage"):WaitForChild("Modules")
local Renderer = require(modules:WaitForChild("ArtRenderer"))
local Budget = require(modules:WaitForChild("ArtBudget"))
local roots, active = {}, {}
local function watch(instance)
    if instance:IsA("BasePart") and instance:GetAttribute("ArtAsset") then roots[instance] = {} end
end
for _, instance in ipairs(workspace:GetDescendants()) do watch(instance) end
workspace.DescendantAdded:Connect(watch)
local tick = 0
local function unload(root, record)
    if record.Model then record.Model:Destroy(); record.Model = nil end
    active[root] = nil
end
RunService.RenderStepped:Connect(function(dt)
    local camera = workspace.CurrentCamera
    if not camera then return end
    tick += dt
    -- Sorting and streaming run ten times per second, not once per render frame.
    if tick >= 0.1 then
        tick = 0
        local candidates = {}
        for root, record in pairs(roots) do
            if not root.Parent then unload(root, record); roots[root] = nil; continue end
            local environment = root:GetAttribute("ArtEnvironment") == true
            local distance = (root.Position - camera.CFrame.Position).Magnitude
            local range = root:GetAttribute("ArtDistance") or (root.Parent:GetAttribute("Guardian") and 420 or 270)
            if distance > range then continue end
            local key = root:GetAttribute("ArtAsset")
            table.insert(candidates, { Root = root, Environment = environment, Distance = distance, Range = range,
                NearCost = Renderer.Cost(key), FarCost = environment and Renderer.Cost(key, "Far") or 0,
                PreviousQuality = record.Quality, Native = record.Native })
        end
        local wanted, ordered = Budget.Select(candidates)
        for root, record in pairs(roots) do
            record.Wanted = wanted[root] ~= nil
            record.RequestedQuality = wanted[root]
            if not record.Wanted or (record.Model and not record.Native and record.Quality ~= wanted[root]) then unload(root, record) end
        end
        local builds = { Core = 1, Scenery = 2 }
        for _, c in ipairs(ordered) do
            local root, record = c.Root, roots[c.Root]
            local group = c.Environment and "Scenery" or "Core"
            if not record.Wanted or record.Model or record.Loading or record.Failed or builds[group] <= 0 then continue end
            builds[group] -= 1; record.Loading = true
            local quality = record.RequestedQuality
            task.spawn(function()
                local key = root:GetAttribute("ArtAsset")
                local scale = root:GetAttribute("ArtScale") or 1
                if key == "egg" then scale = root.Size.Y / Renderer.Bounds(key)[2] end
                local ok, model = pcall(Renderer.Build, key, root.Color, scale, true, quality)
                record.Loading = false
                if not ok then record.Failed = true; warn("[Underwater Egg] Modèle indisponible:", key, model); return end
                local native = model:GetAttribute("ArtCost") == 1
                if not root.Parent or not record.Wanted or (not native and record.RequestedQuality ~= quality) then model:Destroy(); return end
                model.Parent = root; model:PivotTo(root.CFrame)
                root.LocalTransparencyModifier = 1
                local aura = root:FindFirstChild("Aura de rareté")
                if aura then aura.Adornee = model end
                record.Model = model; record.Frame = root.CFrame; record.InitialHeight = root.Size.Y
                record.Native = native; record.Quality = native and "Lod" or quality
                active[root] = record
            end)
        end
    end
    for root, record in pairs(active) do
        if not root.Parent then unload(root, record); continue end
        if root:GetAttribute("ArtAsset") == "egg" then
            local scale = root.Size.Y / record.InitialHeight
            if math.abs(scale - (record.Scale or 1)) > 0.002 then record.Model:ScaleTo(scale); record.Scale = scale end
        end
        if record.Frame ~= root.CFrame then
            if root:GetAttribute("ArtEnvironment") or ((record.Frame.Position - root.Position).Magnitude < 0.005 and (record.Frame.LookVector - root.CFrame.LookVector).Magnitude < 0.002) then record.Frame = root.CFrame
            else record.Frame = record.Frame:Lerp(root.CFrame, math.min(1, dt * 18)) end
            record.Model:PivotTo(record.Frame)
        end
    end
end)
