local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local API = NS.API
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

local PRES_ECHO_CONSUME_CAST_WINDOW = 0.9
local PRES_DB_PENDING_WINDOW = 0.35
local PRES_VE_PENDING_WINDOW = 0.35

function Core.ParseRestorationDruidBuffs(unit, updateInfo)
    local unitAuras = Data.state.auras[unit]
    local state = Data.state
    local currentTime = GetTime()
    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            if Util.IsAuraFromPlayer(unit, aura.auraInstanceID) and unitAuras[aura.auraInstanceID] == 'Rejuvenation' then
                if Util.AreTimestampsEqual(currentTime, state.casts[33763]) then
                    unitAuras[aura.auraInstanceID] = 'Lifebloom'
                end
            end
        end
    end
end

--PENDING ISSUES FOR PRES TODO:
--Lifebind+VerdantEmbrace and DreamBreath+EchoDreamBreath are handled manually assuming application order and a certain time window
--This means the buffs will be 'wrong' for 0.1 seconds before getting re-checked. The amount of time can be lowered down but that risk miss matches
--Need to investigate if db is always a very short amount regardless of distance and if there is a better way to track the first application for any VE buff
function Core.ParsePreservationEvokerBuffs(unit, updateInfo)
    local unitAuras = Data.state.auras[unit]
    local state = Data.state
    local currentTime = GetTime()
    local dbPendingWindow = PRES_DB_PENDING_WINDOW
    local vePendingWindow = PRES_VE_PENDING_WINDOW
    local consumeCastWindow = PRES_ECHO_CONSUME_CAST_WINDOW

    local function GetRecentEchoConsumerCast()
        local casts = state.casts
        local candidates = {
            { spell = 'DreamBreath', time = casts[355936] },
            { spell = 'DreamBreath', time = casts[382614] },
            { spell = 'Reversion', time = casts[366155] },
            { spell = 'VerdantEmbrace', time = casts[360995] },
        }

        local selectedSpell = nil
        local selectedTime = nil
        for _, candidate in ipairs(candidates) do
            if Util.AreTimestampsEqual(currentTime, candidate.time, consumeCastWindow) then
                if not selectedTime or candidate.time > selectedTime then
                    selectedSpell = candidate.spell
                    selectedTime = candidate.time
                end
            end
        end

        if selectedSpell then
            return { spell = selectedSpell, at = selectedTime }
        end
    end

    local function DidRecentlyCastVerdantEmbrace()
        return Util.AreTimestampsEqual(currentTime, state.casts[360995], consumeCastWindow)
    end

    --Pres handles separate lists to parse buffs
    if not state.extras.echo then state.extras.echo = {} end
    if not state.extras.db then state.extras.db = {} end
    if not state.extras.ve then state.extras.ve = {} end
    if not state.extras.echoConsume then state.extras.echoConsume = {} end

    local unitConsumeData = state.extras.echoConsume[unit]
    if unitConsumeData and not Util.AreTimestampsEqual(currentTime, unitConsumeData.at, consumeCastWindow) then
        state.extras.echoConsume[unit] = nil
    end

    --If we have this unit saved as having echo beforehand we check if it was removed
    if state.extras.echo[unit] and updateInfo.removedAuraInstanceIDs then
        for _, removedAuraId in ipairs(updateInfo.removedAuraInstanceIDs) do
            --If echo was removed, we init this units table in the dbs to parse later
            if state.extras.echo[unit] == removedAuraId then
                local consumeData = GetRecentEchoConsumerCast()
                if consumeData then
                    state.extras.echoConsume[unit] = consumeData
                    if consumeData.spell == 'DreamBreath' then
                        state.extras.db[unit] = { dbs = {}, timer = false, pending = true, startedAt = currentTime }
                    end
                else
                    state.extras.echoConsume[unit] = nil
                end
                state.extras.echo[unit] = nil
                break
            end
        end
    end

    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            if Util.IsAuraFromPlayer(unit, aura.auraInstanceID) then
                if unitAuras[aura.auraInstanceID] == 'DreamBreath' and state.extras.db[unit] and state.extras.db[unit].pending then
                    local consumeData = state.extras.echoConsume[unit]
                    if not consumeData
                        or consumeData.spell ~= 'DreamBreath'
                        or not Util.AreTimestampsEqual(currentTime, consumeData.at, consumeCastWindow)
                    then
                        state.extras.db[unit].pending = false
                        state.extras.db[unit].timer = false
                        wipe(state.extras.db[unit].dbs)
                        state.extras.db[unit].startedAt = nil
                        state.extras.echoConsume[unit] = nil
                    else
                        local dbTable = state.extras.db[unit]
                        local isPendingActive = dbTable and dbTable.pending
                            and dbTable.startedAt
                            and (currentTime - dbTable.startedAt) <= dbPendingWindow

                        if dbTable and dbTable.pending and not isPendingActive then
                            dbTable.pending = false
                            dbTable.timer = false
                            wipe(dbTable.dbs)
                            dbTable.startedAt = nil
                        end

                        --We check if this unit is preparing to parse its dbs
                        if dbTable and dbTable.pending and isPendingActive then
                            --If this unit had its echo consumed, we insert the dbs in the table for later parsing
                            table.insert(dbTable.dbs, aura.auraInstanceID)
                            --If we haven't already, we start a timer to check the dbs after 0.2s
                            if not dbTable.timer then
                                C_Timer.After(0.1, function()
                                    dbTable.timer = false
                                    dbTable.pending = false
                                    if #dbTable.dbs == 2 then
                                        unitAuras[dbTable.dbs[1]] = 'DreamBreath'
                                        unitAuras[dbTable.dbs[2]] = 'EchoDreamBreath'
                                    else
                                        unitAuras[dbTable.dbs[1]] = 'EchoDreamBreath'
                                    end
                                    wipe(dbTable.dbs)
                                    dbTable.startedAt = nil
                                    state.extras.echoConsume[unit] = nil
                                    Util.UpdateIndicatorsForUnit(unit)
                                end)
                                state.extras.db[unit].timer = true
                            end
                        end
                    end
                elseif unitAuras[aura.auraInstanceID] == 'VerdantEmbrace' then
                    if not DidRecentlyCastVerdantEmbrace() then
                        if state.extras.ve[unit] then
                            state.extras.ve[unit].pending = false
                            state.extras.ve[unit].timer = false
                            state.extras.ve[unit].startedAt = nil
                            wipe(state.extras.ve[unit].buffs)
                        end
                    else
                        if not state.extras.ve[unit] then
                            state.extras.ve[unit] = { pending = false, buffs = {}, timer = false, startedAt = nil }
                        end

                        local veTable = state.extras.ve[unit]
                        if not veTable.pending then
                            veTable.pending = true
                            veTable.startedAt = currentTime
                            wipe(veTable.buffs)
                        end

                        local isPendingActive = veTable.startedAt
                            and (currentTime - veTable.startedAt) <= vePendingWindow

                        if not isPendingActive then
                            veTable.pending = true
                            veTable.timer = false
                            veTable.startedAt = currentTime
                            wipe(veTable.buffs)
                        end

                        table.insert(veTable.buffs, aura.auraInstanceID)
                        if not veTable.timer then
                            C_Timer.After(0.1, function()
                                veTable.timer = false
                                veTable.pending = false
                                if #veTable.buffs == 2 then
                                    unitAuras[veTable.buffs[1]] = 'Lifebind'
                                elseif #veTable.buffs == 1 then
                                    if UnitIsUnit(unit, 'player') then
                                        unitAuras[veTable.buffs[1]] = 'Lifebind'
                                    end
                                end
                                wipe(veTable.buffs)
                                veTable.startedAt = nil
                                if state.extras.echoConsume[unit] and state.extras.echoConsume[unit].spell == 'VerdantEmbrace' then
                                    state.extras.echoConsume[unit] = nil
                                end
                                Util.UpdateIndicatorsForUnit(unit)
                            end)
                            veTable.timer = true
                        end
                    end
                end
            end
        end
    end

    --Save the echoes
    for instanceId, aura in pairs(unitAuras) do
        if aura == 'Echo' and not state.extras.echo[unit] then
            state.extras.echo[unit] = instanceId
        end
    end

end

--PENDING ISSUES FOR HPAL TODO:
-- Armaments is wonky because of the travel time, i expect to see errors when you cast both charges back to back
function Core.ParseHolyPaladinBuffs(unit, updateInfo)
    local unitAuras = Data.state.auras[unit]

    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            if Util.IsAuraFromPlayer(unit, aura.auraInstanceID) then
                if unitAuras[aura.auraInstanceID] == 'SacredWeapon' then
                    local castedSpell = C_Spell.GetSpellTexture(375576) == 5927637 and 'HolyBulwark' or 'SacredWeapon'
                    if UnitIsUnit(unit, 'player') then
                        unitAuras[aura.auraInstanceID] = castedSpell
                    else
                        --This will fail if the unit is too far away and you press the spell before it lands, leaving it as a stub
                        unitAuras[aura.auraInstanceID] = castedSpell
                    end
                end
            end
        end
    end
    --[[
    --If this is the player, we save the armament buffs of to check if they were recently added down below
    if isPlayer then
        for instanceId, buff in pairs(unitAuras) do
            if buff == 'HolyBulwark' or buff == 'SacredWeapon' then
                table.insert(playerArmamentBuffs, instanceId)
            end
        end
    end

    if updateInfo.addedAuras then
        local lastCastTime = state.casts[state.lastCast]
        for _, aura in ipairs(updateInfo.addedAuras) do
            local pointCount = #aura.points
            --Same as PI, virtue gets lost in the initial filter because its not in raid in combat
            if state.lastCast == specData.virtue and Util.AreTimestampsEqual(currentTime, lastCastTime)
            and Util.DoesAuraPassRaidFilter(unit, aura.auraInstanceID) and Util.DoesAuraDifferBetweenFilters(unit, aura.auraInstanceID) then
                if pointCount == specData.auras.BeaconOfVirtue then
                    unitAuras[aura.auraInstanceID] = 'BeaconOfVirtue'
                end
            end
            if state.lastCast == specData.armaments and not isPlayer and Util.AreTimestampsEqual(currentTime, lastCastTime, 2) then --2 seconds is insanity wtf
                if Util.IsAuraFromPlayer(unit, aura.auraInstanceID) and pointCount == specData.auras.SacredWeapon then --both arms have the same count
                    unitAuras[aura.auraInstanceID] = Core.IdentifyHolyArmaments()
                end
            end
            --If the player has armaments, check if they were added in this run by the gen function, if they were confirm they are correctly marked
            if isPlayer and #playerArmamentBuffs > 0 then
                for _, instanceId in pairs(playerArmamentBuffs) do
                    if aura.auraInstanceID == instanceId then
                        unitAuras[instanceId] = Core.IdentifyHolyArmaments()
                    end
                end
            end
            --Other buffs that got all the way here and have 7 points have to be beacon of the savior
            if pointCount == 7 and not unitAuras[aura.auraInstanceID] then
                unitAuras[aura.auraInstanceID] = 'BeaconOfTheSavior'
            end
        end
    end
    ]]
end

--Check data of UNIT_AURA to update its status
function Core.UpdateAuraStatus(unit, updateInfo)
    local state = Data.state
    if not updateInfo then updateInfo = {} end

    local currentUnitAuras = state.auras[unit]
    local needsIndicatorRefresh = false

    --Init this unit state
    if not currentUnitAuras then
        currentUnitAuras = {}
        state.auras[unit] = currentUnitAuras

        local auras = C_UnitAuras.GetUnitAuras(unit, 'PLAYER|HELPFUL')
        for _, aura in ipairs(auras) do
            local auraId = aura.auraInstanceID
            local matchedAura = Util.MatchAuraInfo(unit, aura)
            if matchedAura then
                currentUnitAuras[auraId] = matchedAura
                needsIndicatorRefresh = true
            end
        end
    end

    --Process full updates as a fresh snapshot from the API
    if updateInfo.isFullUpdate then
        wipe(currentUnitAuras)
        local auras = C_UnitAuras.GetUnitAuras(unit, 'PLAYER|HELPFUL')
        for _, aura in ipairs(auras) do
            local auraId = aura.auraInstanceID
            local matchedAura = Util.MatchAuraInfo(unit, aura)
            if matchedAura then
                currentUnitAuras[auraId] = matchedAura
                needsIndicatorRefresh = true
            end
        end
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
    local engineFunction = Data.engineFunctions[Data.playerSpec]
    if engineFunction then
        engineFunction(unit, updateInfo)
        if updateInfo.isFullUpdate or updateInfo.addedAuras or updateInfo.removedAuraInstanceIDs or updateInfo.updatedAuraInstanceIDs then
            if next(currentUnitAuras) then
                needsIndicatorRefresh = true
            end
        end
    end

    --Hit a refresh only when tracked aura state or tracked durations may have changed
    if needsIndicatorRefresh then
        Util.UpdateIndicatorsForUnit(unit, updateInfo)
    end
end