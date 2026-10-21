-- Executes the actual client streaming script with engine doubles.
local Engine = require('./support/Engine')
local e = Engine.new()
local game, workspace, script = e.Game, e.Workspace, e.Script
local Instance, Vector3, CFrame, Color3, Enum = e.Instance, e.Vector3, e.CFrame, e.Color3, e.Enum
local Content = {}; local task = e.Task
local warn = function(...) table.insert(e.Warnings, table.concat({...}, ' ')) end
local factories, loaded = {}, {}
local function require(ref)
    if not loaded[ref.Name] then loaded[ref.Name] = factories[ref.Name]() end
    return loaded[ref.Name]
end
--[[ MODULES ]]
workspace.CurrentCamera = Instance.new('Camera'); workspace.CurrentCamera.CFrame = CFrame.new()
e.RunService.RenderStepped = Instance.new('Folder').Activated
workspace.DescendantAdded = Instance.new('Folder').Activated
local function root(key, x, environment)
    local model = Instance.new('Model'); model.Parent = workspace
    local part = Instance.new('Part'); part.Size = Vector3.one * 6; part.CFrame = CFrame.new(x, 0, 0)
    part:SetAttribute('ArtAsset', key); part:SetAttribute('ArtScale', Vector3.new(2, 3, 2))
    part:SetAttribute('ArtEnvironment', environment); part.Parent = model
    return part
end
local coral = root('reef_fan', 30, true)
local egg = root('egg', 8, false)
factories['Art.client']()
local passed = 0
local function check(value, message) assert(value, message); passed += 1 end
local function frame() e.RunService.RenderStepped:Fire(.12); e:Drain() end
frame()
local first = coral:FindFirstChild('ArtSkin')
local firstCount = first and #first:GetChildren() or 0
check(first and #first:GetChildren() > 100, 'Imported coral builds its detailed portable mesh when native APIs are unavailable')
check(egg:FindFirstChild('ArtSkin'), 'Scenery streaming also preserves real egg rendering')
workspace.CurrentCamera.CFrame = CFrame.new(-130, 0, 0); frame()
local far = coral:FindFirstChild('ArtSkin')
check(far and far ~= first and first.Destroyed and #far:GetChildren() < firstCount, 'Moving away rebuilds a coral using its distant mesh')
workspace.CurrentCamera.CFrame = CFrame.new(-700, 0, 0); frame()
check(not coral:FindFirstChild('ArtSkin') and far.Destroyed, 'Leaving the display range releases scenery geometry')
workspace.CurrentCamera.CFrame = CFrame.new(); frame()
check(coral:FindFirstChild('ArtSkin'), 'Returning to the reef restores its model')
local later = root('reef_tubes', 15, true); workspace.DescendantAdded:Fire(later); frame()
check(later:FindFirstChild('ArtSkin'), 'Late replicated scenery is discovered and rendered')
local skin = later:FindFirstChild('ArtSkin'); later:Destroy(); frame()
check(skin.Destroyed, 'Removing a root also removes its local mesh')
local tool = root('harpoon', 10, false)
tool:SetAttribute('ArtScale', .7); tool:SetAttribute('ArtOffset', Vector3.new(0, .55, -.45)); tool:SetAttribute('ArtRigid', true)
workspace.DescendantAdded:Fire(tool); frame()
local gun = tool:FindFirstChild('ArtSkin')
check(gun and math.abs(gun.Pivot.Position.Y - .55) < .001 and math.abs(gun.Pivot.Position.Z + .45) < .001, 'Imported receiver is positioned at its grip offset')
tool.CFrame = CFrame.new(12, 3, -5); frame()
check(math.abs(gun.Pivot.Position.X - 12) < .001 and math.abs(gun.Pivot.Position.Y - 3.55) < .001, 'Weapon skin follows its physical handle immediately instead of lagging behind it')
check(#e.Warnings == 0, 'Streaming produces no failed-model warnings')
print('Art streaming: '..passed..' assertions passed (engine doubles; native rendering untested)')
