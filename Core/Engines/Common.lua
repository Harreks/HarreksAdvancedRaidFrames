local _, NS = ...
local Core = NS.Core

Core.EngineCommon = Core.EngineCommon or {}
local Common = Core.EngineCommon

function Common.NoopParser()
    return false
end

function Common.IsWithinPendingWindow(startedAt, currentTime, window)
    return startedAt and (currentTime - startedAt) <= window
end

function Common.ClearPendingState(stateTable, listKey)
    if not stateTable then
        return
    end

    stateTable.pending = false
    stateTable.timer = false
    stateTable.startedAt = nil

    if listKey and stateTable[listKey] then
        wipe(stateTable[listKey])
    end
end
