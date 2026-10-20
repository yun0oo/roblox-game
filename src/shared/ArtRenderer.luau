--!nonstrict
-- Portable CC0/derived art. Native editable meshes are an optional enhancement;
-- a bounded triangle renderer also works without enabling any Studio API.
local data = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules").ArtData)
local ArtRenderer = {}
local templates = {}
local nativeAvailable = true

local function color(rgb, tint, kind)
    local base = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
    if kind == "weapon" then
        if rgb[1] > rgb[2] * 1.15 and rgb[2] > rgb[3] * 1.1 then return Color3.fromRGB(36, 165, 207) end
        return base
    end
    if kind == "egg" then return base:Lerp(tint, 0.6) end
    if math.min(rgb[1], rgb[2], rgb[3]) > 235 then return base end
    if rgb[1] > 220 and rgb[2] > 150 and rgb[3] < 80 then return base end
    if math.max(rgb[1], rgb[2], rgb[3]) < 45 then return base end
    return base:Lerp(tint, 0.68)
end

local function nativeMesh(key, asset, tint)
    local cacheKey = key .. tostring(tint)
    if templates[cacheKey] then return templates[cacheKey]:Clone() end
    if not nativeAvailable then return nil end
    local editable
    local ok, result = pcall(function()
        local service = game:GetService("AssetService")
        editable = service:CreateEditableMesh()
        if not editable then error("Mesh memory budget unavailable") end
        local mesh, ids = asset.Full, {}
        for index, v in ipairs(mesh.Vertices) do ids[index] = editable:AddVertex(Vector3.new(v[1], v[2], v[3])) end
        for index, face in ipairs(mesh.Faces) do
            local id = editable:AddTriangle(ids[face[1]], ids[face[2]], ids[face[3]])
            local paint = editable:AddColor(color(mesh.Colors[index], tint, asset.Kind))
            editable:SetFaceColors(id, { paint, paint, paint })
        end
        local part = service:CreateMeshPartAsync(Content.fromObject(editable))
        part.Name = "Sculpture"; part.Anchored = true; part.CanCollide = false; part.CanTouch = false; part.CanQuery = false
        part.Material = Enum.Material.SmoothPlastic
        return part
    end)
    if not ok then
        if editable then editable:Destroy() end
        nativeAvailable = false
        return nil
    end
    -- Keep the EditableMesh alive while cloned parts reference its content.
    templates[cacheKey] = result
    templates[cacheKey .. ":source"] = editable
    return result:Clone()
end

local function wedge(parent, center, right, up, back, height, length, tint)
    if height < 0.002 or length < 0.002 then return end
    local part = Instance.new("WedgePart")
    part.Name = "Surface"; part.Size = Vector3.new(0.012, height, length)
    part.CFrame = CFrame.fromMatrix(center, right, up, back)
    part.Color = tint; part.Material = Enum.Material.SmoothPlastic
    part.Anchored = true; part.CanCollide = false; part.CanTouch = false; part.CanQuery = false
    part.CastShadow = false; part.Parent = parent
end

function ArtRenderer.Build(key, tint, scale, allowNative)
    local asset = data[key] or data.fish
    local model = Instance.new("Model"); model.Name = "ArtSkin"
    local part = allowNative and nativeMesh(key, asset, tint)
    if part then
        local bounds = asset.Full.Bounds
        part.Size = Vector3.new(bounds[1], bounds[2], bounds[3]) * scale
        part.Parent = model
        model.PrimaryPart = part
    else
        local mesh, vertices = asset.Lod, {}
        for index, v in ipairs(mesh.Vertices) do vertices[index] = Vector3.new(v[1], v[2], v[3]) * scale end
        for index, face in ipairs(mesh.Faces) do
            local a, b, c = vertices[face[1]], vertices[face[2]], vertices[face[3]]
            local ab, ac, bc = b - a, c - a, c - b
            if ab:Dot(ab) > ac:Dot(ac) and ab:Dot(ab) > bc:Dot(bc) then a, c = c, a
            elseif ac:Dot(ac) > bc:Dot(bc) then a, b = b, a end
            ab, ac, bc = b - a, c - a, c - b
            local normal = ac:Cross(ab)
            if normal.Magnitude < 0.00001 then continue end
            local right, back = normal.Unit, bc.Unit
            local up = back:Cross(right).Unit
            local height = math.abs(ab:Dot(up))
            local paint = color(mesh.Colors[index], tint, asset.Kind)
            wedge(model, (a + b) / 2, right, up, back, height, math.abs(ab:Dot(back)), paint)
            wedge(model, (a + c) / 2, -right, up, -back, height, math.abs(ac:Dot(back)), paint)
        end
    end
    model:SetAttribute("ArtCost", part and 1 or #model:GetChildren())
    model.WorldPivot = CFrame.new()
    return model
end

function ArtRenderer.Cost(key)
    return #(data[key] or data.fish).Lod.Faces * 2
end

function ArtRenderer.Bounds(key)
    return (data[key] or data.fish).Full.Bounds
end

return ArtRenderer
