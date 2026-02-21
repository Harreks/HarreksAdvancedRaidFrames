local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core

local LIFEBLOOM_CAST_SPELL_ID = 33763

function Core.ParseRestorationDruidBuffs(unit, updateInfo)
    if not updateInfo.addedAuras then
        return false
    end

    local unitAuras = Data.state.auras[unit]
    local state = Data.state
    local currentTime = GetTime()
    local changed = false

    for _, aura in ipairs(updateInfo.addedAuras) do
        local auraId = aura.auraInstanceID
        if unitAuras[auraId] == 'Rejuvenation'
            and Util.IsAuraFromPlayer(unit, auraId)
            and Util.AreTimestampsEqual(currentTime, state.casts[LIFEBLOOM_CAST_SPELL_ID])
        then
            unitAuras[auraId] = 'Lifebloom'
            changed = true
        end
    end

    return changed
end
