local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core
local Common = Core.EngineCommon

local pairs = pairs
local ipairs = ipairs
local wipe = wipe
local UnitExists = UnitExists
local C_Timer_After = C_Timer.After

local PRES_ECHO_CONSUME_CAST_WINDOW = 0.9
local PRES_DB_PENDING_WINDOW = 0.35
local PRES_VE_PENDING_WINDOW = 0.35
local PRES_STALE_PRUNE_INTERVAL = 2
local PRES_CAST_APPLY_WINDOW = 0.35

local function EnsurePreservationExtras(state)
    if not state.extras.echo then state.extras.echo = {} end
    if not state.extras.db then state.extras.db = {} end
    if not state.extras.ve then state.extras.ve = {} end
    if not state.extras.echoConsume then state.extras.echoConsume = {} end
end

local function GetRecentEchoConsumerCast(state, currentTime, consumeCastWindow)
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

local function ClearDreamBreathPending(dbTable)
    Common.ClearPendingState(dbTable, 'dbs')
    if dbTable then
        dbTable.mode = nil
    end
end

local function IsRecentDreamBreathCast(state, currentTime, castWindow)
    return Util.AreTimestampsEqual(currentTime, state.casts[355936], castWindow)
        or Util.AreTimestampsEqual(currentTime, state.casts[382614], castWindow)
end

local function OpenDreamBreathPending(state, unit, currentTime, mode)
    local dbTable = state.extras.db[unit]
    if not dbTable then
        dbTable = { dbs = {}, timer = false, pending = true, startedAt = currentTime, mode = mode }
        state.extras.db[unit] = dbTable
        return dbTable
    end

    dbTable.pending = true
    dbTable.timer = false
    dbTable.startedAt = currentTime
    dbTable.mode = mode
    wipe(dbTable.dbs)
    return dbTable
end

local function InferPreservationSpellFromCastContext(state, currentTime, castWindow)
    if IsRecentDreamBreathCast(state, currentTime, castWindow) then
        return 'DreamBreath'
    end

    if Util.AreTimestampsEqual(currentTime, state.casts[360995], castWindow) then
        return 'VerdantEmbrace'
    end

    if Util.AreTimestampsEqual(currentTime, state.casts[364343], castWindow) then
        return 'Echo'
    end
end

local function PrunePreservationExtras(state, currentTime)
    local extras = state.extras
    if not extras then
        return
    end

    local lastPruneAt = extras.lastPresPruneAt or 0
    if (currentTime - lastPruneAt) < PRES_STALE_PRUNE_INTERVAL then
        return
    end
    extras.lastPresPruneAt = currentTime

    for unit, consumeData in pairs(extras.echoConsume) do
        if not UnitExists(unit) or not consumeData or not Util.AreTimestampsEqual(currentTime, consumeData.at, PRES_ECHO_CONSUME_CAST_WINDOW) then
            extras.echoConsume[unit] = nil
        end
    end

    for unit, dbTable in pairs(extras.db) do
        if not UnitExists(unit) then
            extras.db[unit] = nil
        elseif dbTable and dbTable.pending and not Common.IsWithinPendingWindow(dbTable.startedAt, currentTime, PRES_DB_PENDING_WINDOW) then
            ClearDreamBreathPending(dbTable)
        end
    end

    for unit, veTable in pairs(extras.ve) do
        if not UnitExists(unit) then
            extras.ve[unit] = nil
        elseif veTable and veTable.pending and not Common.IsWithinPendingWindow(veTable.startedAt, currentTime, PRES_VE_PENDING_WINDOW) then
            Common.ClearPendingState(veTable, 'buffs')
        end
    end

    for unit, echoAuraId in pairs(extras.echo) do
        if not UnitExists(unit) then
            extras.echo[unit] = nil
        elseif not state.auras[unit] or not state.auras[unit][echoAuraId] then
            extras.echo[unit] = nil
        end
    end
end

local function HandleEchoRemovalForPres(unit, updateInfo, state, currentTime, consumeCastWindow)
    local trackedEcho = state.extras.echo[unit]
    if not trackedEcho or not updateInfo.removedAuraInstanceIDs then
        return
    end

    for _, removedAuraId in ipairs(updateInfo.removedAuraInstanceIDs) do
        if trackedEcho == removedAuraId then
            local consumeData = GetRecentEchoConsumerCast(state, currentTime, consumeCastWindow)
            if consumeData then
                state.extras.echoConsume[unit] = consumeData
                if consumeData.spell == 'DreamBreath' then
                    OpenDreamBreathPending(state, unit, currentTime, 'echoConsume')
                end
            else
                state.extras.echoConsume[unit] = nil
            end
            state.extras.echo[unit] = nil
            break
        end
    end
end

local function HandleImplicitEchoRemovalForPres(unit, state, currentTime, consumeCastWindow)
    local trackedEcho = state.extras.echo[unit]
    if not trackedEcho then
        return
    end

    local unitAuras = state.auras[unit]
    if unitAuras and unitAuras[trackedEcho] then
        return
    end

    local consumeData = GetRecentEchoConsumerCast(state, currentTime, consumeCastWindow)
    if consumeData then
        state.extras.echoConsume[unit] = consumeData
        if consumeData.spell == 'DreamBreath' then
            OpenDreamBreathPending(state, unit, currentTime, 'echoConsume')
        end
    else
        state.extras.echoConsume[unit] = nil
    end

    state.extras.echo[unit] = nil
end

local function HandleDreamBreathAuraForPres(unit, auraId, state, unitAuras, currentTime, consumeCastWindow, dbPendingWindow)
    local dbTable = state.extras.db[unit]
    if not (dbTable and dbTable.pending) then
        if IsRecentDreamBreathCast(state, currentTime, consumeCastWindow) then
            dbTable = OpenDreamBreathPending(state, unit, currentTime, 'fallback')
        else
            return
        end
    end

    if dbTable.mode ~= 'fallback' then
        local consumeData = state.extras.echoConsume[unit]
        if not consumeData
            or consumeData.spell ~= 'DreamBreath'
            or not Util.AreTimestampsEqual(currentTime, consumeData.at, consumeCastWindow)
        then
            ClearDreamBreathPending(dbTable)
            state.extras.echoConsume[unit] = nil
            return
        end
    end

    local isPendingActive = Common.IsWithinPendingWindow(dbTable.startedAt, currentTime, dbPendingWindow)

    if not isPendingActive then
        ClearDreamBreathPending(dbTable)
        return
    end

    table.insert(dbTable.dbs, auraId)
    if dbTable.timer then
        return
    end

    dbTable.timer = true
    C_Timer_After(0.1, function()
        dbTable.timer = false
        dbTable.pending = false
        if dbTable.mode == 'fallback' then
            if #dbTable.dbs == 2 then
                unitAuras[dbTable.dbs[1]] = 'DreamBreath'
                unitAuras[dbTable.dbs[2]] = 'EchoDreamBreath'
            elseif #dbTable.dbs == 1 then
                unitAuras[dbTable.dbs[1]] = 'DreamBreath'
            end
        elseif #dbTable.dbs == 2 then
            unitAuras[dbTable.dbs[1]] = 'DreamBreath'
            unitAuras[dbTable.dbs[2]] = 'EchoDreamBreath'
        else
            unitAuras[dbTable.dbs[1]] = 'EchoDreamBreath'
        end
        wipe(dbTable.dbs)
        dbTable.startedAt = nil
        dbTable.mode = nil
        state.extras.echoConsume[unit] = nil
        Util.UpdateIndicatorsForUnit(unit)
    end)
end

local function HandleVerdantEmbraceAuraForPres(unit, auraId, state, unitAuras, currentTime, consumeCastWindow, vePendingWindow)
    if not Util.AreTimestampsEqual(currentTime, state.casts[360995], consumeCastWindow) then
        local veTable = state.extras.ve[unit]
        if veTable then
            Common.ClearPendingState(veTable, 'buffs')
        end
        return
    end

    local veTable = state.extras.ve[unit]
    if not veTable then
        veTable = { pending = false, buffs = {}, timer = false, startedAt = nil }
        state.extras.ve[unit] = veTable
    end

    if not veTable.pending then
        veTable.pending = true
        veTable.startedAt = currentTime
        wipe(veTable.buffs)
    end

    local isPendingActive = Common.IsWithinPendingWindow(veTable.startedAt, currentTime, vePendingWindow)

    if not isPendingActive then
        veTable.pending = true
        veTable.timer = false
        veTable.startedAt = currentTime
        wipe(veTable.buffs)
    end

    table.insert(veTable.buffs, auraId)
    if veTable.timer then
        return
    end

    veTable.timer = true
    C_Timer_After(0.1, function()
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
end

function Core.ParsePreservationEvokerBuffs(unit, updateInfo)
    local unitAuras = Data.state.auras[unit]
    local state = Data.state
    local currentTime = GetTime()
    local parserChanged = false

    EnsurePreservationExtras(state)
    PrunePreservationExtras(state, currentTime)

    local unitConsumeData = state.extras.echoConsume[unit]
    if unitConsumeData and not Util.AreTimestampsEqual(currentTime, unitConsumeData.at, PRES_ECHO_CONSUME_CAST_WINDOW) then
        state.extras.echoConsume[unit] = nil
    end

    HandleEchoRemovalForPres(unit, updateInfo, state, currentTime, PRES_ECHO_CONSUME_CAST_WINDOW)
    HandleImplicitEchoRemovalForPres(unit, state, currentTime, PRES_ECHO_CONSUME_CAST_WINDOW)

    if updateInfo.isFullUpdate then
        state.extras.echo[unit] = nil
        for instanceId, auraName in pairs(unitAuras) do
            if auraName == 'Echo' then
                state.extras.echo[unit] = instanceId
                break
            end
        end
    end

    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            local auraId = aura.auraInstanceID
            local spell = unitAuras[auraId]
            local isPlayerOwned = Util.IsAuraFromPlayer(unit, auraId)

            if not spell and isPlayerOwned then
                spell = InferPreservationSpellFromCastContext(state, currentTime, PRES_CAST_APPLY_WINDOW)
                if spell then
                    unitAuras[auraId] = spell
                    parserChanged = true
                end
            end

            if spell == 'Echo' then
                state.extras.echo[unit] = auraId
            end
            if (spell == 'DreamBreath' or spell == 'VerdantEmbrace') and isPlayerOwned then
                if spell == 'DreamBreath' then
                    HandleDreamBreathAuraForPres(unit, auraId, state, unitAuras, currentTime, PRES_ECHO_CONSUME_CAST_WINDOW, PRES_DB_PENDING_WINDOW)
                else
                    HandleVerdantEmbraceAuraForPres(unit, auraId, state, unitAuras, currentTime, PRES_ECHO_CONSUME_CAST_WINDOW, PRES_VE_PENDING_WINDOW)
                end
            end
        end
    end

    return parserChanged
end

function Core.ParseAugmentationEvokerBuffs(unit, updateInfo)
    return Common.NoopParser(unit, updateInfo)
end
