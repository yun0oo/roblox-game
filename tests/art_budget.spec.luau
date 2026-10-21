local Budget = require('../src/shared/ArtBudget')
local passed = 0
local function check(value, message) assert(value, message); passed += 1 end
local function candidate(root, env, distance, near, far)
    return { Root = root, Environment = env, Distance = distance, Range = 300, NearCost = near, FarCost = far }
end
local candidates = {}
for i = 1, 150 do table.insert(candidates, candidate('reef'..i, true, i, 800, 180)) end
table.insert(candidates, candidate('boss', false, 160, 12000, 0))
table.insert(candidates, candidate('egg', false, 2, 1800, 0))
local wanted = Budget.Select(candidates)
check(wanted.boss and wanted.egg, 'Dense scenery cannot consume the gameplay model budget')
local total = 0
for _, c in ipairs(candidates) do if c.Environment and wanted[c.Root] then total += wanted[c.Root] == 'Far' and c.FarCost or c.NearCost end end
check(total <= Budget.Scenery, 'Portable scenery stays within its own live geometry budget')
local a = candidate('test', true, 140, 800, 180)
check(Budget.Select({a}).test == 'Far', 'Distant scenery uses its baked reduced mesh')
a.Distance = 100; a.PreviousQuality = 'Far'
check(Budget.Select({a}).test == 'Far', 'LOD hysteresis prevents rebuilds along the threshold')
a.Distance = 90
check(Budget.Select({a}).test == 'Lod', 'Approaching reveals the more detailed authored mesh')
a.Distance = 301
check(Budget.Select({a}).test == nil, 'Distant scenery is unloaded')
a.Distance = 140; a.Native = true
check(Budget.Select({a}).test == 'Lod', 'Available native meshes retain full sculpted detail')
print('Art budget: '..passed..' assertions passed')
