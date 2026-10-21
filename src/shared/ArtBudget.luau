--!nonstrict
-- Keep gameplay models visible independently of the amount of scenery nearby.
local Budget = { Core = 16000, Scenery = 22000 }
function Budget.Select(candidates)
    local ordered = table.clone(candidates)
    table.sort(ordered, function(a, b)
        if a.Environment ~= b.Environment then return not a.Environment end
        return a.Distance < b.Distance
    end)
    local remaining = { Core = Budget.Core, Scenery = Budget.Scenery }
    local wanted = {}
    for _, c in ipairs(ordered) do
        if c.Distance < 0 or c.Distance > c.Range then continue end
        local quality = c.Environment and c.Distance > (c.PreviousQuality == "Far" and 95 or 125) and "Far" or "Lod"
        if c.Native then quality = "Lod" end
        local cost = c.Native and 1 or quality == "Far" and c.FarCost or c.NearCost
        local group = c.Environment and "Scenery" or "Core"
        if cost >= 1 and cost <= remaining[group] then
            wanted[c.Root] = quality; remaining[group] -= cost
        end
    end
    return wanted, ordered
end
return Budget
