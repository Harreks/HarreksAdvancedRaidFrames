local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core

local HOLY_ARMAMENTS_SPELL_ID = 375576
local HOLY_BULWARK_TEXTURE_ID = 5927637

local function ResolveHolyArmamentAuraName()
    return C_Spell.GetSpellTexture(HOLY_ARMAMENTS_SPELL_ID) == HOLY_BULWARK_TEXTURE_ID and 'HolyBulwark' or 'SacredWeapon'
end

--PENDING ISSUES FOR HPAL TODO:
--Armament identity still depends on cast/apply timing (texture check at application), so back-to-back charges can remain edge-casey.
function Core.ParseHolyPaladinBuffs(unit, updateInfo)
    if not updateInfo.addedAuras then
        return false
    end

    local unitAuras = Data.state.auras[unit]
    local changed = false

    for _, aura in ipairs(updateInfo.addedAuras) do
        local auraId = aura.auraInstanceID
        if unitAuras[auraId] == 'SacredWeapon' and Util.IsAuraFromPlayer(unit, auraId) then
            local resolvedSpell = ResolveHolyArmamentAuraName()
            if unitAuras[auraId] ~= resolvedSpell then
                unitAuras[auraId] = resolvedSpell
                changed = true
            end
        end
    end

    return changed
end
