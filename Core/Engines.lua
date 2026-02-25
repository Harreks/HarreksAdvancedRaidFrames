local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core

function Core.RebuildTrackedUnitAuras(unit, currentUnitAuras)
    local needsIndicatorRefresh = false
    local auras = C_UnitAuras.GetUnitAuras(unit, 'PLAYER|HELPFUL')
    for _, aura in ipairs(auras) do
        local auraId = aura.auraInstanceID
        local matchedAura = Util.MatchAuraInfo(unit, aura)
        if matchedAura then
            currentUnitAuras[auraId] = matchedAura
            needsIndicatorRefresh = true
        end
    end

    return needsIndicatorRefresh
end

--Check data of UNIT_AURA to update its status
function Core.UpdateAuraStatus(unit, updateInfo)
    local playerSpec = Data.playerSpec
    if Util.IsSupportedSpec(playerSpec) then
        local state = Data.state
        if not updateInfo then updateInfo = {} end

        local currentUnitAuras = state.auras[unit]
        local needsIndicatorRefresh = false

        --Init this unit state
        if not currentUnitAuras then
            currentUnitAuras = {}
            state.auras[unit] = currentUnitAuras
            needsIndicatorRefresh = Core.RebuildTrackedUnitAuras(unit, currentUnitAuras)
        end

        --Process full updates as a fresh snapshot from the API
        if updateInfo.isFullUpdate then
            wipe(currentUnitAuras)
            needsIndicatorRefresh = Core.RebuildTrackedUnitAuras(unit, currentUnitAuras) or needsIndicatorRefresh
        else
            --If a tracked auraInstanceID has been removed, remove it from state
            if updateInfo.removedAuraInstanceIDs then
                for _, auraId in ipairs(updateInfo.removedAuraInstanceIDs) do
                    if currentUnitAuras[auraId] then
                        currentUnitAuras[auraId] = nil
                        needsIndicatorRefresh = true
                    end
                end
            end

            if updateInfo.addedAuras then
                for _, aura in ipairs(updateInfo.addedAuras) do
                    if Util.IsAuraFromPlayer(unit, aura.auraInstanceID) then
                        local matchedAura = Util.MatchAuraInfo(unit, aura)
                        if matchedAura then
                            currentUnitAuras[aura.auraInstanceID] = matchedAura
                            needsIndicatorRefresh = true
                        end
                        needsIndicatorRefresh = true
                    end
                end
            end

            --If tracked auras were updated, refresh duration displays and avoid rematch/API fetch work
            if updateInfo.updatedAuraInstanceIDs then
                for _, auraId in ipairs(updateInfo.updatedAuraInstanceIDs) do
                    if currentUnitAuras[auraId] then
                        needsIndicatorRefresh = true
                    end
                end
            end
        end

        --Hit a refresh only when tracked aura state or tracked durations may have changed
        if needsIndicatorRefresh then
            Util.UpdateIndicatorsForUnit(unit, updateInfo)
        end
    end
end