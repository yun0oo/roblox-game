--!nonstrict
local Merchants = {}

function Merchants.Build(world, config, visuals)
    world.Merchants = {}
    local spots = { { -24, -250 }, { 24, -250 }, { -24, -170 }, { 24, -170 }, { -24, 130 }, { 24, 130 }, { -24, 225 } }
    local deck = config.BaseHeight - 10
    for index, key in ipairs(config.UpgradeOrder) do
        local spec = config.Merchants[key]
        local tint = visuals.Color(spec.Color)
        local pos = Vector3.new(spots[index][1], deck, spots[index][2])
        local facing = spots[index][1] < 0 and -math.pi / 2 or math.pi / 2
        local frame = CFrame.new(pos) * CFrame.Angles(0, facing, 0)
        local stall = Instance.new("Model"); stall.Name = "Marchand_" .. key; stall.Parent = world.NPCs
        local function piece(name, size, offset, color, shape)
            local p = visuals.Part(stall, name, size, frame * CFrame.new(offset), color, Enum.Material.SmoothPlastic, shape)
            p.CastShadow = true
            return p
        end
        local platform = piece("Estrade", Vector3.new(15, 0.5, 13), Vector3.new(0, 0.25, 0), tint)
        platform.TopSurface = Enum.SurfaceType.Studs
        piece("Comptoir", Vector3.new(12, 3, 3), Vector3.new(0, 1.5, -3.3), Color3.fromRGB(26, 63, 114))
        piece("Façade colorée", Vector3.new(11.3, 2.3, 0.15), Vector3.new(0, 1.6, -4.85), tint)
        for side = -1, 1, 2 do
            piece("Poteau", Vector3.new(0.55, 12, 0.55), Vector3.new(side * 6.5, 6, 2.8), Color3.fromRGB(236, 187, 84))
        end
        piece("Auvent", Vector3.new(15, 0.8, 13), Vector3.new(0, 11.5, 0), tint)
        for x = -6, 6, 4 do piece("Rayure de l’auvent", Vector3.new(1.7, 0.12, 13), Vector3.new(x, 11.96, 0), Color3.fromRGB(240, 192, 88)) end
        local sign = piece("Enseigne", Vector3.new(13, 2.8, 0.4), Vector3.new(0, 10, -6), tint)
        visuals.Label(sign, spec.Icon .. " " .. config.Upgrades[key].Name:upper() .. "\n" .. spec.Name, Color3.new(1, 1, 1), 2, 160)
        require(game:GetService("ReplicatedStorage").Modules.MerchantVisuals).Build(stall, key, spec, frame * CFrame.new(0, 0.5, 1.8), visuals)
        piece("Socle du comptoir", Vector3.new(12.3, 0.22, 3.3), Vector3.new(0, 3.15, -3.3), Color3.fromRGB(240, 192, 88))
        for side = -1, 1, 2 do
            local plinth = piece("Présentoir de cristal", Vector3.new(1.9, 0.5, 1.9), Vector3.new(side * 4.4, 3.5, -3.3), Color3.fromRGB(27, 57, 101))
            piece("Cristal de la boutique", Vector3.new(0.65, 1.1, 0.65), Vector3.new(side * 4.4, 4.3, -3.3), tint).Material = Enum.Material.Neon
            plinth.CastShadow = false
        end
        local badge = piece("Emblème", Vector3.one, Vector3.new(0, 5, -3.3), tint)
        badge.Transparency = 1
        visuals.Label(badge, spec.Icon .. "\nACHETER / AMÉLIORER", Color3.new(1, 1, 1), 0.6, 65)
        local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Voir la boutique"; prompt.ObjectText = spec.Name .. " · " .. config.Upgrades[key].Name
        prompt.MaxActivationDistance = config.MerchantDistance; prompt.RequiresLineOfSight = false; prompt.HoldDuration = 0; prompt.Parent = sign
        world.Merchants[key] = { Model = stall, Arrival = (frame * CFrame.new(0, 3.5, -10)).Position, Position = sign.Position, Prompt = prompt, Key = key }
    end
end

function Merchants.Near(world, config, key, position)
    if type(key) ~= "string" then return false end
    local merchant = world.Merchants and world.Merchants[key]
    return merchant ~= nil and (position - merchant.Position).Magnitude <= config.MerchantDistance
end
return Merchants
