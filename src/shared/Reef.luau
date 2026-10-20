--!nonstrict
local Reef = {}
function Reef.Coral(parent, origin, scale, style, visuals)
    local model = Instance.new("Model"); model.Name = "Corail vivant · " .. style; model.Parent = parent
    local palette = { { 255, 114, 153 }, { 178, 115, 255 }, { 255, 175, 83 }, { 71, 218, 205 } }
    local tint = visuals.Color(palette[(style - 1) % #palette + 1])
    local tip = tint:Lerp(Color3.new(1, 1, 1), 0.35)
    local function pos(x, y, z) return origin + Vector3.new(x, y, z) * scale end
    local function stem(a, b, size)
        visuals.Rod(model, "Branche de corail", a, b, size * scale, tint)
        visuals.Part(model, "Pointe arrondie", Vector3.one * size * scale, CFrame.new(b), tip, nil, Enum.PartType.Ball)
    end
    if style % 3 == 1 then
        for i = 1, 5 do
            local angle = i * 2.4
            local base = pos(math.cos(angle) * 0.7, 0, math.sin(angle) * 0.7)
            local fork = pos(math.cos(angle) * 2.2, 3.3 + i * 0.3, math.sin(angle) * 2.2)
            stem(base, fork, 0.65)
            for side = -1, 1, 2 do stem(fork, fork + Vector3.new(side * 1.4, 1.8, math.sin(i) * 1.2) * scale, 0.4) end
        end
    elseif style % 3 == 2 then
        stem(pos(0, 0, 0), pos(0, 3, 0), 0.8)
        for i = -3, 3 do
            local a, b = pos(0, 2, 0), pos(i * 1.5, 6.5 - math.abs(i) * 0.6, math.sin(i) * 0.4)
            stem(a, b, 0.28)
            for level = 1, 2 do
                local t = level / 3
                stem(a:Lerp(b, t), a:Lerp(b, t) + Vector3.new(i * 0.3, 1.3, 0.2) * scale, 0.18)
            end
        end
    else
        for i = 1, 4 do
            local center = pos(math.sin(i * 2) * 1.8, 0.8 + i * 0.9, math.cos(i * 2) * 1.3)
            visuals.Part(model, "Plateau de corail", Vector3.new(5.8 - i * 0.55, 0.65, 4.8 - i * 0.4) * scale, CFrame.new(center), tint, nil, Enum.PartType.Ball)
            visuals.Part(model, "Bord nacré", Vector3.new(4.9 - i * 0.5, 0.2, 4 - i * 0.35) * scale, CFrame.new(center + Vector3.new(0, 0.28, 0) * scale), tip, nil, Enum.PartType.Ball)
        end
    end
    return model
end
function Reef.Grass(parent, origin, scale, visuals)
    for i = 1, 4 do
        local base = origin + Vector3.new(i * 0.4, 0, math.sin(i)) * scale
        local top = base + Vector3.new(math.sin(i) * 1.5, 3 + i * 0.6, 0.5) * scale
        visuals.Rod(parent, "Tige d’algue", base, top, 0.2 * scale, Color3.fromRGB(42, 153, 124))
        visuals.Part(parent, "Feuille marine", Vector3.new(0.5, 3, 1.7) * scale, CFrame.new(top) * CFrame.Angles(0, i, math.sin(i) * 0.3), Color3.fromRGB(60, 199, 138), nil, Enum.PartType.Ball)
    end
end
return Reef
