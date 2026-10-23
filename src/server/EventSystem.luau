--!nonstrict
local EventSystem = {}
EventSystem.__index = EventSystem
function EventSystem.new(ctx)
    local now = os.clock()
    return setmetatable({ Ctx = ctx, Next = { Minor = now + ctx.Config.Events.Minor.Interval, Major = now + ctx.Config.Events.Major.Interval,
        Legendary = now + ctx.Config.Events.Legendary.Interval }, Warned = {} }, EventSystem)
end
function EventSystem:Step()
    local now, ctx = os.clock(), self.Ctx
    if ctx.Event and now >= ctx.Event.Ends then
        ctx.Event = nil
        ctx.Eggs:EndEvent()
        ctx:Broadcast("Les courants se calment. Rareté habituelle rétablie.", "Success")
    end
    local priority = { Minor = 1, Major = 2, Legendary = 3 }
    for _, key in ipairs({ "Legendary", "Major", "Minor" }) do
        local spec = ctx.Config.Events[key]
        if now >= self.Next[key] then
            repeat self.Next[key] += spec.Interval until self.Next[key] > now
            self.Warned[key] = nil
            if not ctx.Event or priority[key] > priority[ctx.Event.Key] then
                local name = spec.Names[ctx.Random:NextInteger(1, #spec.Names)]
                ctx.Event = { Key = key, Name = name, Ends = now + spec.Duration }
                local exclusive = key == "Legendary" and "\n🌟 Œufs TEMPÊTE et CÉLESTES disponibles !" or key == "Major" and "\n⚡ Œufs TEMPÊTE disponibles !" or ""
                ctx:Broadcast("🌊 " .. name .. " EN COURS !\n💎 La rareté des œufs et le danger augmentent !" .. exclusive, "Legendary")
                -- Replenish available nests immediately under the new probability table.
                ctx.Eggs.NextSpawn = 0
                ctx.Eggs:RefreshForEvent()
            end
        elseif self.Next[key] - now <= spec.Warning and not self.Warned[key]
            and (key == "Legendary" or (key == "Major" and self.Next.Major < self.Next.Legendary - 1)
                or (key == "Minor" and self.Next.Minor < math.min(self.Next.Major, self.Next.Legendary) - 1)) then
            self.Warned[key] = true
            ctx:Broadcast("🌊 " .. (key == "Legendary" and "ABYSSAL STORM" or key == "Major" and "ÉVÉNEMENT MAJEUR" or "COURANTS SOUS-MARINS") .. " DANS 30 SECONDES !", "Warning")
        end
    end
end
function EventSystem:Snapshot()
    if self.Ctx.Event then
        return { Active = true, Name = self.Ctx.Event.Name, Key = self.Ctx.Event.Key, Remaining = math.max(0, self.Ctx.Event.Ends - os.clock()) }
    end
    return { Active = false, Name = "Prochain phénomène", Remaining = math.max(0, math.min(self.Next.Minor, self.Next.Major, self.Next.Legendary) - os.clock()) }
end
return EventSystem
