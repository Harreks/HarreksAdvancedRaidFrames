local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core
local Common = Core.EngineCommon

local PRES_ECHO_CONSUME_CAST_WINDOW = 0.9
local PRES_DB_PENDING_WINDOW = 0.35
local PRES_VE_PENDING_WINDOW = 0.35

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

local function HandleDreamBreathAuraForPres(unit, auraId, state, unitAuras, currentTime, consumeCastWindow, dbPendingWindow)
    local dbTable = state.extras.db[unit]
    if not (dbTable and dbTable.pending) then
        return
    end

    local consumeData = state.extras.echoConsume[unit]
    if not consumeData
        or consumeData.spell ~= 'DreamBreath'
        or not Util.AreTimestampsEqual(currentTime, consumeData.at, consumeCastWindow)
    then
        ClearDreamBreathPending(dbTable)
        state.extras.echoConsume[unit] = nil
        return
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
end

--PENDING ISSUES FOR PRES TODO:
--Lifebind+VerdantEmbrace and DreamBreath+EchoDreamBreath are finalized via short pending windows and a delayed resolution pass.
--This is now cast-gated (echo consume context + recency checks), but labels can still settle ~0.1s after apply in ambiguous ordering/travel-time cases.
--Further hardening would require replacing timer-based finalization with a more direct consume/application correlation path from available events.
function Core.ParsePreservationEvokerBuffs(unit, updateInfo)
    local unitAuras = Data.state.auras[unit]
    local state = Data.state
    local currentTime = GetTime()

    EnsurePreservationExtras(state)

    local unitConsumeData = state.extras.echoConsume[unit]
    if unitConsumeData and not Util.AreTimestampsEqual(currentTime, unitConsumeData.at, PRES_ECHO_CONSUME_CAST_WINDOW) then
        state.extras.echoConsume[unit] = nil
    end

    HandleEchoRemovalForPres(unit, updateInfo, state, currentTime, PRES_ECHO_CONSUME_CAST_WINDOW)

    if updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            local auraId = aura.auraInstanceID
            local spell = unitAuras[auraId]
            if (spell == 'DreamBreath' or spell == 'VerdantEmbrace') and Util.IsAuraFromPlayer(unit, auraId) then
                if spell == 'DreamBreath' then
                    HandleDreamBreathAuraForPres(unit, auraId, state, unitAuras, currentTime, PRES_ECHO_CONSUME_CAST_WINDOW, PRES_DB_PENDING_WINDOW)
                else
                    HandleVerdantEmbraceAuraForPres(unit, auraId, state, unitAuras, currentTime, PRES_ECHO_CONSUME_CAST_WINDOW, PRES_VE_PENDING_WINDOW)
                end
            end
        end
    end

    for instanceId, aura in pairs(unitAuras) do
        if aura == 'Echo' and not state.extras.echo[unit] then
            state.extras.echo[unit] = instanceId
        end
    end

    return false
end

function Core.ParseAugmentationEvokerBuffs(unit, updateInfo)
    return Common.NoopParser(unit, updateInfo)
end
