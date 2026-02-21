local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core

local ipairs = ipairs
local wipe = wipe


local function RebuildTrackedUnitAuras(unit, currentUnitAuras)
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
    local profileStart = Util.ProfileStart()
    local playerSpec = Data.playerSpec
    if not Util.IsSupportedSpec(playerSpec) then
        Util.ProfileStop('UpdateAuraStatus', profileStart)
        return
    end

    local state = Data.state
    if not updateInfo then updateInfo = {} end

    local currentUnitAuras = state.auras[unit]
    local needsIndicatorRefresh = false

    --Init this unit state
    if not currentUnitAuras then
        currentUnitAuras = {}
        state.auras[unit] = currentUnitAuras
        needsIndicatorRefresh = RebuildTrackedUnitAuras(unit, currentUnitAuras)
    end

    --Process full updates as a fresh snapshot from the API
    if updateInfo.isFullUpdate then
        wipe(currentUnitAuras)
        needsIndicatorRefresh = RebuildTrackedUnitAuras(unit, currentUnitAuras) or needsIndicatorRefresh
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

        --If the unit got new auras added, classify only player-owned ones
        if updateInfo.addedAuras then
            for _, aura in ipairs(updateInfo.addedAuras) do
                local auraId = aura.auraInstanceID
                local previousAura = currentUnitAuras[auraId]
                local matchedAura = Util.MatchAuraInfo(unit, aura)
                if matchedAura ~= previousAura then
                    if matchedAura then
                        currentUnitAuras[auraId] = matchedAura
                    else
                        currentUnitAuras[auraId] = nil
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

    --We pass the data to specialized functions
    local parserChanged = Data.engineFunctions[playerSpec](unit, updateInfo)
    if parserChanged then
        needsIndicatorRefresh = true
    end

    --Hit a refresh only when tracked aura state or tracked durations may have changed
    if needsIndicatorRefresh then
        Util.UpdateIndicatorsForUnit(unit, updateInfo)
    end

    Util.ProfileStop('UpdateAuraStatus', profileStart)
end