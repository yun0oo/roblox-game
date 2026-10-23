--!nonstrict
-- Deterministic startup test doubles. No rendering, physics, network, or native
-- character creation. Workspace's Studio-only property deliberately rejects writes.
local Engine = {}
function Engine.new()
    local e = { Clock = 10, Queue = {}, Timers = {}, Warnings = {}, StoreCalls = 0, TerrainEdits = 0 }
    local vectorMeta = {}
    local V = {}
    function V.new(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vectorMeta) end
    vectorMeta.__add = function(a, b) return V.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
    vectorMeta.__sub = function(a, b) return V.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
    vectorMeta.__unm = function(a) return V.new(-a.X, -a.Y, -a.Z) end
    vectorMeta.__mul = function(a, b)
        if type(a) == "number" then a, b = b, a end
        if type(b) == "number" then return V.new(a.X * b, a.Y * b, a.Z * b) end
        return V.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
    end
    vectorMeta.__div = function(a, b) return a * (1 / b) end
    vectorMeta.__index = function(a, key)
        if key == "Magnitude" then return math.sqrt(a.X ^ 2 + a.Y ^ 2 + a.Z ^ 2) end
        if key == "Unit" then return a.Magnitude > 0 and a / a.Magnitude or V.new() end
        if key == "Lerp" then return function(b, c, t) return b + (c - b) * t end end
        if key == "Dot" then return function(b, c) return b.X * c.X + b.Y * c.Y + b.Z * c.Z end end
        if key == "Cross" then return function(b, c) return V.new(b.Y*c.Z-b.Z*c.Y, b.Z*c.X-b.X*c.Z, b.X*c.Y-b.Y*c.X) end end
    end
    V.zero = V.new(); V.one = V.new(1, 1, 1); V.xAxis = V.new(1, 0, 0)
    e.Vector3 = V
    local frameMeta, CF = {}, {}
    function CF.new(x, y, z) return setmetatable({ Position = type(x) == "table" and x or V.new(x, y, z) }, frameMeta) end
    CF.Angles = function() return CF.new() end
    CF.lookAt = function(pos) return CF.new(pos) end
    CF.fromMatrix = function(pos) return CF.new(pos) end
    frameMeta.__mul = function(a, b) return CF.new(a.Position + b.Position) end
    frameMeta.__index = function(value, key)
        if key == "Rotation" then return CF.new() end
        if key == "Lerp" then return function(_, other, t) return CF.new(value.Position:Lerp(other.Position, t)) end end
        if key == "Inverse" then return function() return CF.new(-value.Position) end end
    end
    e.CFrame = CF
    local colors = {}
    function colors:Lerp() return self end
    e.Color3 = { new = function() return colors end, fromRGB = function() return colors end }
    e.Enum = setmetatable({}, { __index = function(t, k)
        local group = setmetatable({}, { __index = function(_, name) return name end })
        rawset(t, k, group); return group
    end })
    local function signal()
        local s = { Listeners = {} }
        function s:Connect(fn) table.insert(self.Listeners, fn); return { Disconnect = function() end } end
        function s:Fire(...)
            for _, fn in ipairs(self.Listeners) do fn(...) end
        end
        return s
    end
    local instance
    local methods = {}
    function methods:GetPropertyChangedSignal(key)
        self._signals = self._signals or {}
        if not self._signals[key] then self._signals[key] = signal() end
        return self._signals[key]
    end
    function methods:Clone()
        local copy = instance(self.ClassName)
        for key, value in pairs(self._props) do if key ~= "Parent" then copy._props[key] = value end end
        return copy
    end
    function methods:IsA(class) return self.ClassName == class or (class == "BasePart" and (self.ClassName == "Part" or self.ClassName == "WedgePart")) end
    function methods:IsDescendantOf(ancestor)
        local parent = self.Parent
        while parent do
            if parent == ancestor then return true end
            parent = parent.Parent
        end
        return false
    end
    function methods:GetChildren() return table.clone(self._children) end
    function methods:GetDescendants()
        local result = {}
        for _, child in ipairs(self:GetChildren()) do
            table.insert(result, child)
            for _, descendant in ipairs(child:GetDescendants()) do table.insert(result, descendant) end
        end
        return result
    end
    function methods:FindFirstChild(name)
        for _, child in ipairs(self._children) do if child.Name == name then return child end end
    end
    function methods:WaitForChild(name) return assert(self:FindFirstChild(name), self.Name .. "." .. name .. " missing") end
    function methods:FindFirstChildOfClass(class)
        for _, child in ipairs(self._children) do if child.ClassName == class then return child end end
    end
    function methods:Destroy()
        self.Parent = nil; self.Destroyed = true
        for _, child in ipairs(self:GetChildren()) do child:Destroy() end
    end
    function methods:ClearAllChildren() for _, child in ipairs(self:GetChildren()) do child:Destroy() end end
    function methods:SetAttribute(key, value) self._attributes[key] = value end
    function methods:GetAttribute(key) return self._attributes[key] end
    function methods:GetPivot() return self._props.Pivot or CF.new() end
    function methods:PivotTo(frame) self.Pivot = frame end
    function methods:SetStateEnabled() end
    function methods:EquipTool(tool) tool.Parent = self.Parent end
    function methods:TakeDamage(amount) self.Health -= amount; if self.Health <= 0 then self.Died:Fire() end end
    function methods:FireClient(player, ...)
        self.Messages[player] = self.Messages[player] or {}
        table.insert(self.Messages[player], { ... })
    end
    function methods:FireAllClients(...) table.insert(self.Broadcasts, { ... }) end
    function methods:GetPlayers() return self:GetChildren() end
    function methods:Kick(message) self.Kicked = message end
    function methods:Raycast() return nil end
    function methods:FillBlock()
        if e.FailTerrain then error("Terrain edit intentionally rejected") end
        e.TerrainEdits += 1
    end
    local instanceMeta = {}
    instanceMeta.__index = function(obj, key)
        if methods[key] then return methods[key] end
        if key == "Position" then return obj._props.CFrame.Position end
        local value = obj._props[key]
        if value ~= nil then return value end
        return obj:FindFirstChild(key)
    end
    instanceMeta.__newindex = function(obj, key, value)
        if obj.ClassName == "Workspace" and key == "FallenPartsDestroyHeight" then
            error("FallenPartsDestroyHeight can only be set by Studio/plugins")
        end
        if key == "Parent" then
            local old = obj._props.Parent
            if old then
                local index = table.find(old._children, obj)
                if index then table.remove(old._children, index) end
            end
            if value then table.insert(value._children, obj) end
        end
        obj._props[key] = value
    end
    instance = function(class)
        return setmetatable({ _props = { Name = class, ClassName = class, CFrame = CF.new(), Health = 100,
            Activated = signal(), Triggered = signal(), Died = signal(), CharacterAdded = signal(), PlayerAdded = signal(), PlayerRemoving = signal(),
            Heartbeat = signal(), OnServerEvent = signal(), Messages = {}, Broadcasts = {} }, _children = {}, _attributes = {} }, instanceMeta)
    end
    e.Instance = { new = instance }
    e.Workspace = instance("Workspace")
    instance("Terrain").Parent = e.Workspace
    e.Players = instance("Players"); e.Players.CharacterAutoLoads = true
    e.ReplicatedStorage = instance("ReplicatedStorage")
    local modules = instance("Folder"); modules.Name = "Modules"; modules.Parent = e.ReplicatedStorage
    local server = instance("Folder")
    for _, name in ipairs({ "Config", "Rules", "Visuals", "ArtData", "ArtRenderer", "EquipmentVisuals", "Reef", "MerchantVisuals", "ArtBudget" }) do
        local ref = instance("ModuleScript"); ref.Name = name; ref.Parent = modules
    end
    for _, name in ipairs({ "DataSystem", "World", "Ship", "Merchants", "Laboratory", "EggSystem", "GuardianSystem", "HarpoonSystem", "EventSystem", "FusionData" }) do
        local ref = instance("ModuleScript"); ref.Name = name; ref.Parent = server
    end
    e.Script = instance("Script"); e.Script.Parent = server
    local guid = 0
    e.RunService = { IsStudio = function() return true end, IsClient = function() return false end, Heartbeat = signal() }
    local services = { Workspace = e.Workspace, Players = e.Players, ReplicatedStorage = e.ReplicatedStorage,
        UserInputService = { TouchEnabled = false }, RunService = e.RunService, HttpService = { GenerateGUID = function() guid += 1; return "id-" .. guid end },
        DataStoreService = { GetDataStore = function() e.StoreCalls += 1; error("Unpublished Studio place") end } }
    e.Game = { JobId = "", PlaceId = 0, GetService = function(_, name) return assert(services[name], name) end,
        BindToClose = function(_, fn) e.Close = fn end }
    e.Task = {
        wait = function(seconds) return coroutine.yield(seconds or 0.02) end,
        spawn = function(fn, ...) table.insert(e.Queue, { coroutine.create(fn), table.pack(...) }) end,
        delay = function() error("No startup action should depend on task.delay") end,
    }
    function e:Drain()
        local rounds = 0
        while #self.Queue > 0 do
            rounds += 1; assert(rounds < 200, "Startup did not settle")
            local job = table.remove(self.Queue, 1)
            local ok, delay = coroutine.resume(job[1], table.unpack(job[2], 1, job[2].n))
            assert(ok, delay)
            if coroutine.status(job[1]) ~= "dead" then
                if delay >= 5 then table.insert(self.Timers, { Coroutine = job[1], Due = self.Clock + delay })
                else
                    self.Clock += delay
                    table.insert(self.Queue, { job[1], table.pack(delay) })
                end
            end
        end
    end
    function e:Character(player)
        local character = instance("Model"); character.Parent = e.Workspace
        local root = instance("Part"); root.Name = "HumanoidRootPart"; root.Parent = character
        for _, name in ipairs({ "Torso", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }) do
            local limb = instance("Part"); limb.Name = name; limb.Size = V.new(1, 2, 1); limb.Parent = character
        end
        instance("Humanoid").Parent = character
        player.Character = character
        return character
    end
    function e:Player(id)
        local player = instance("Player"); player.UserId = id; player.DisplayName = "Diver" .. id; player.Parent = e.Players
        instance("Backpack").Parent = player
        return player
    end
    return e
end
return Engine
