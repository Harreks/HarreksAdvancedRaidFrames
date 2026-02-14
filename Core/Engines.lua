local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--PENDING ISSUES FOR DRUID TODO:
-- Spellqueueing Barkskin off of WildGrowth will mark the WildGrowths as Barkskins
function Core.ParseRestorationDruidBuffs(unit, updateInfo)
    local unitAuras = Data.state.auras[unit]
    local state = Data.state
    --Convoke will apply WildGrowth, Regrowth and Rejuv with no cast events, but we can diff those using points
    if updateInfo.addedAuras and state.extras.isConvoking then
        for _, aura in ipairs(updateInfo.addedAuras) do
            local pointCount = #aura.points
            if Util.IsAuraFromPlayer(unit, aura.auraInstanceID) then
                if pointCount == 1 then
                    unitAuras[aura.auraInstanceID] = 'Rejuvenation'
                elseif pointCount == 2 then
                    unitAuras[aura.auraInstanceID] = 'WildGrowth'
                elseif pointCount == 3 then
                    unitAuras[aura.auraInstanceID] = 'Regrowth'
                end
            end
        end
    end

    --One of the resto druid issues is separating rejuv from germ. We do that here
    local rejuvenationBuffs = {}
    for instanceId, aura in pairs(unitAuras) do
        if aura == 'Rejuvenation' then
            table.insert(rejuvenationBuffs, instanceId)
        end
    end
    if #rejuvenationBuffs > 0 then
        for _, instanceId in ipairs(rejuvenationBuffs) do
            if Util.DoesAuraDifferBetweenFilters(unit, instanceId) then
                unitAuras[instanceId] = 'Germination'
            end
        end
    end
end

--Check data of UNIT_AURA to update its status
function Core.UpdateAuraStatus(unit, updateInfo)
    local specInfo = Data.specInfo[Data.playerSpec]
    local currentTime = GetTime()
    local state = Data.state
    if not state.auras[unit] then state.auras[unit] = {} end
    if not updateInfo then updateInfo = {} end

    --If an auraInstanceID that we have saved has been removed, get it away
    if updateInfo.removedAuraInstanceIDs then
        local currentUnitAuras = state.auras[unit]
        if currentUnitAuras then
            for _, auraId in ipairs(updateInfo.removedAuraInstanceIDs) do
                if currentUnitAuras[auraId] then
                    currentUnitAuras[auraId] = nil
                end
            end
        end
    end

    --If the unit got new auras added, check if they came from a cast
    if updateInfo.addedAuras then
        local lastCastTime = state.casts[state.lastCast]
        --If these auras match a spell cast
        if lastCastTime and Util.AreTimestampsEqual(currentTime, lastCastTime) then
            --Get the buffs this cast can apply
            local castBuffs = specInfo.casts[state.lastCast]
            for _, aura in ipairs(updateInfo.addedAuras) do
                local pointCount = #aura.points
                for _, buff in ipairs(castBuffs) do
                    if Util.IsAuraFromPlayer(unit, aura.auraInstanceID) and pointCount == specInfo.auras[buff] then
                        state.auras[unit][aura.auraInstanceID] = buff
                        break
                    end
                end
            end
        end
    end

    --For the auras applied with no cast, we pass them to specialized functions
    if Data.playerSpec == 'RestorationDruid' then
        Core.ParseRestorationDruidBuffs(unit, updateInfo)
    end

    --Hit a refresh of the indicators at the end
    Util.UpdateIndicatorsForUnit(unit)
end