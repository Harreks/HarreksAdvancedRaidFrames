local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local Debug = NS.Debug
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--Try to match an aura with a buff name, some are non-secret others we need to check deeper
function Core.MatchAuraInfo(unit, aura)
    --If aura is not secret, return the internal name
    local specInfo = Data.specInfo[Data.playerSpec]
    if canaccesstable(aura) and not issecretvalue(aura.spellId) then
        if specInfo.auras[aura.spellId] and Util.AuraPassesFilter(unit, aura.auraInstanceID, 'PLAYER|HELPFUL') then
            return specInfo.auras[aura.spellId].name
        end
    end

    --If its secret we check if its a player aura and compose the signature
    local passesRaid = Util.AuraPassesFilter(unit, aura.auraInstanceID, 'PLAYER|HELPFUL|RAID')
    local passesRic = Util.AuraPassesFilter(unit, aura.auraInstanceID, 'PLAYER|HELPFUL|RAID_IN_COMBAT')

    if not (passesRaid or passesRic) then
        return nil
    end

    local passesExt = Util.AuraPassesFilter(unit, aura.auraInstanceID, 'PLAYER|HELPFUL|EXTERNAL_DEFENSIVE')
    local passesDisp = Util.AuraPassesFilter(unit, aura.auraInstanceID, 'PLAYER|HELPFUL|RAID_PLAYER_DISPELLABLE')

    local auraSignatures = Util.GetAuraSignatures(Data.playerSpec)
    local signature = Util.MakeAuraSignature(passesRaid, passesRic, passesExt, passesDisp)
    return auraSignatures[signature]
end

--Check data of UNIT_AURA to update its status
function Core.UpdateAuraStatus(unit, updateInfo)
    if Data.playerSpec then
        local updatedAuras = {}
        local hideBuffs = Options.buffIcons
        local state = Data.state
        if not updateInfo then updateInfo = {} end
        local currentUnitAuras = state.auras[unit]

        --Init this unit state
        if not currentUnitAuras or updateInfo.isFullUpdate then
            currentUnitAuras = {}
            state.auras[unit] = currentUnitAuras
            local auras = C_UnitAuras.GetUnitAuras(unit, 'HELPFUL')
            for _, aura in ipairs(auras) do
                local auraId = aura.auraInstanceID
                local matchedAura = Core.MatchAuraInfo(unit, aura)
                if hideBuffs then
                    if pcall(C_UnitAuras.AddBlockedAura, unit, aura.auraInstanceID) then
                        state.blockedAuras[unit] = state.blockedAuras[unit] or {}
                        table.insert(state.blockedAuras[unit], aura.auraInstanceID)
                    end
                end
                if matchedAura then
                    currentUnitAuras[auraId] = matchedAura
                    updatedAuras[matchedAura] = auraId
                end
            end
        end

        --If a tracked auraInstanceID has been removed, remove it from state
        if updateInfo.removedAuraInstanceIDs then
            for _, auraId in ipairs(updateInfo.removedAuraInstanceIDs) do
                if currentUnitAuras[auraId] then
                    updatedAuras[currentUnitAuras[auraId]] = auraId
                    currentUnitAuras[auraId] = nil
                end
            end
        end

        if updateInfo.addedAuras then
            for _, aura in ipairs(updateInfo.addedAuras) do
                if Util.AuraPassesFilter(unit, aura.auraInstanceID, 'PLAYER|HELPFUL') then
                    local matchedAura = Core.MatchAuraInfo(unit, aura)
                    if matchedAura then
                        currentUnitAuras[aura.auraInstanceID] = matchedAura
                        updatedAuras[matchedAura] = aura.auraInstanceID
                    end
                end
            end
        end

        --If tracked auras were updated, refresh duration displays and avoid rematch/API fetch work
        if updateInfo.updatedAuraInstanceIDs then
            for _, auraId in ipairs(updateInfo.updatedAuraInstanceIDs) do
                if currentUnitAuras[auraId] then
                    updatedAuras[currentUnitAuras[auraId]] = auraId
                end
            end
        end

        --Hit a refresh of the indicators if at least one aura has changed
        if next(updatedAuras) then
            local updatedAuraData = {}
            for buffName, instanceId in pairs(updatedAuras) do
                local aura = {}
                if currentUnitAuras[instanceId] then
                    aura.active = true
                    aura.duration = C_UnitAuras.GetAuraDuration(unit, instanceId)
                    aura.data = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, instanceId)
                else
                    aura.active = false
                end
                updatedAuraData[buffName] = aura
            end
            Util.UpdateIndicatorsForUnit(unit, updatedAuraData)
        end

        if hideBuffs then
            if updateInfo.addedAuras then
                for _, aura in ipairs(updateInfo.addedAuras) do
                    if Util.AuraPassesFilter(unit, aura.auraInstanceID, 'HELPFUL') then
                        if pcall(C_UnitAuras.AddBlockedAura, unit, aura.auraInstanceID) then
                            state.blockedAuras[unit] = state.blockedAuras[unit] or {}
                            table.insert(state.blockedAuras[unit], aura.auraInstanceID)
                        end
                    end
                end
            end
        end
    end
end