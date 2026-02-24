local _, NS = ...
local Util = NS.Util

local debugprofilestop = debugprofilestop
local math_max = math.max

local function GetProfileStore()
    HARFDB = HARFDB or {}
    HARFDB.debugProfile = HARFDB.debugProfile or { enabled = false, stats = {} }
    return HARFDB.debugProfile
end

function Util.IsProfileEnabled()
    local store = GetProfileStore()
    return store.enabled == true
end

function Util.SetProfileEnabled(value)
    local store = GetProfileStore()
    store.enabled = value == true
end

function Util.GetProfileStats()
    local store = GetProfileStore()
    return store.stats
end

function Util.ResetProfileStats()
    local store = GetProfileStore()
    wipe(store.stats)
end

function Util.PrintProfileStats()
    local stats = Util.GetProfileStats()
    for metricName, metric in pairs(stats) do
        local avg = metric.count > 0 and (metric.totalMs / metric.count) or 0
        print('HARF profile - ' .. metricName .. ': count=' .. metric.count .. ', avg=' .. avg .. 'ms, max=' .. metric.maxMs .. 'ms')
    end
end

function Util.ProfileStart()
    if Util.IsProfileEnabled() then
        return debugprofilestop()
    end
    return nil
end

function Util.ProfileStop(metricName, startedAt)
    if not startedAt or not metricName then
        return
    end

    local elapsed = debugprofilestop() - startedAt
    local store = GetProfileStore()
    local stats = store.stats
    local metric = stats[metricName]
    if not metric then
        metric = { count = 0, totalMs = 0, maxMs = 0 }
        stats[metricName] = metric
    end

    metric.count = metric.count + 1
    metric.totalMs = metric.totalMs + elapsed
    metric.maxMs = math_max(metric.maxMs, elapsed)
end

function Util.DebugData(data, name)
    if NS.Debug and DevTool then
        DevTool:AddData(data, name)
    end
end

function Util.PrintData(data)
    if NS.Debug then
        if type(data) == 'table' then
            for k,v in ipairs(data) do print(k, ': ', v) end
            for k,v in pairs(data) do print(k, ': ', v) end
        else
            print(data)
        end
    end
end

function Util.DumpData(data)
    if NS.Debug then
        DevTools_Dump(data)
    end
end