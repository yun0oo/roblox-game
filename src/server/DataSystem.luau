--!nonstrict
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local DataSystem = {}
DataSystem.__index = DataSystem

function DataSystem.new(config, rules)
    local studio = RunService:IsStudio()
    local storeName = config.DataStoreName .. (studio and "_Studio" or "")
    local store, storeError
    -- An unpublished Studio place cannot use DataStore. GetDataStore itself can
    -- throw, before Load's UpdateAsync protection has a chance to run.
    if studio and game.PlaceId == 0 then
        storeError = "Fichier Studio non publié"
    else
        local ok, result = pcall(function() return DataStoreService:GetDataStore(storeName) end)
        if ok then store = result else storeError = tostring(result) end
    end
    return setmetatable({ Config = config, Rules = rules, Store = store, StoreError = storeError,
        Sessions = {}, Token = game.JobId .. ":" .. HttpService:GenerateGUID(false) }, DataSystem)
end

local function waitForBudget()
    local deadline = os.clock() + 8
    repeat
        if DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync) > 0 then return true end
        task.wait(0.25)
    until os.clock() > deadline
    return false
end

function DataSystem:Load(player)
    local result, lastError, locked, incompatible = nil, self.StoreError, false, false
    local attempts = self.Store and (RunService:IsStudio() and 1 or 3) or 0
    for attempt = 1, attempts do
        if not waitForBudget() then lastError = "Budget DataStore indisponible"; break end
        local ok, value = pcall(function()
            return self.Store:UpdateAsync("u_" .. player.UserId, function(old)
                if old ~= nil and (type(old) ~= "table" or old.Version ~= self.Config.Version or type(old.Data) ~= "table") then
                    incompatible = true
                    return nil
                end
                if type(old) == "table" and type(old.Session) == "table" and old.Session.Id ~= self.Token
                    and type(old.Session.Expires) == "number" and old.Session.Expires > os.time() then
                    locked = true
                    return nil
                end
                local raw = type(old) == "table" and old.Data or nil
                return { Version = 1, Data = self.Rules.Sanitize(raw, self.Config),
                    Session = { Id = self.Token, Expires = os.time() + self.Config.SessionLease } }
            end)
        end)
        if ok and value then result = value; break end
        if incompatible then return nil, "Format de sauvegarde incompatible. Votre progression a été préservée." end
        if locked then return nil, "Votre progression est encore ouverte sur un autre serveur. Réessayez dans quelques instants." end
        lastError = tostring(value)
        if attempt < attempts then task.wait(attempt) end
    end
    if result then
        local profile = self.Rules.Sanitize(result.Data, self.Config)
        self.Sessions[player] = { Profile = profile, Saving = false, Offline = false, Closing = false, LastSave = os.clock() }
        return profile, nil, false
    end
    warn("[Underwater Egg] Profile load failed for user", player.UserId, lastError)
    if RunService:IsStudio() and self.Config.AllowStudioOffline then
        local profile = self.Rules.NewProfile(self.Config)
        self.Sessions[player] = { Profile = profile, Saving = false, Offline = true, Closing = false }
        return profile, nil, true
    end
    return nil, "La sauvegarde est indisponible. Reconnectez-vous pour protéger votre progression."
end

function DataSystem:Save(player, release)
    local session = self.Sessions[player]
    if not session then return false end
    if release then session.Closing = true end
    if session.Saving then
        if not release then return false end
        local deadline = os.clock() + 15
        repeat task.wait(0.1) until not session.Saving or os.clock() > deadline
        if session.Saving then return false end
    end
    if session.Offline then
        if release then self.Sessions[player] = nil end
        return true
    end
    session.Saving = true
    local snapshot = self.Rules.Sanitize(session.Profile, self.Config)
    local saved, lostLock = false, false
    for attempt = 1, 3 do
        if not waitForBudget() then break end
        local ok, value = pcall(function()
            return self.Store:UpdateAsync("u_" .. player.UserId, function(old)
                if type(old) ~= "table" or type(old.Session) ~= "table" or old.Session.Id ~= self.Token then
                    lostLock = true
                    return nil
                end
                return { Version = 1, Data = snapshot,
                    Session = not release and { Id = self.Token, Expires = os.time() + self.Config.SessionLease } or nil }
            end)
        end)
        if ok and value then saved = true; break end
        if lostLock then break end
        task.wait(attempt)
    end
    session.Saving = false
    if saved then
        session.LastSave = os.clock()
        if release then self.Sessions[player] = nil end
    else
        warn("[Underwater Egg] Save failed for user", player.UserId, "lock lost:", lostLock)
        -- Freeze transactions after a lost lock; never overwrite another session.
        if lostLock and player.Parent then player:Kick("La session de sauvegarde a changé. Reconnectez-vous.") end
    end
    return saved
end

function DataSystem:IsClosing(player)
    local session = self.Sessions[player]
    if session and not session.Offline and not session.Closing and os.clock() - session.LastSave > self.Config.SessionLease - 15 then
        session.Closing = true
        if player.Parent then player:Kick("La sauvegarde ne répond plus. Reconnectez-vous pour protéger votre session.") end
    end
    return not session or session.Closing
end
return DataSystem
