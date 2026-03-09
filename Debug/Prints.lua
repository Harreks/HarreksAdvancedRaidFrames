local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local Debug = NS.Debug
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--TODO: Expand the debug options, let users export error data to share

function Debug.DebugData(data, name)
    if NS.DevEnv and DevTool then
        DevTool:AddData(data, name)
    end
end

function Debug.PrintData(data)
    if NS.DevEnv then
        if type(data) == 'table' then
            for k,v in ipairs(data) do print(k, ': ', v) end
            for k,v in pairs(data) do print(k, ': ', v) end
        else
            print(data)
        end
    end
end

function Debug.DumpData(data)
    if NS.DevEnv then
        DevTools_Dump(data)
    end
end

function Debug.GetTableSize(t)
    if NS.DevEnv then
        local count = 0
        local function countRecursive(tbl)
            if type(tbl) ~= "table" then return end
            for k, v in pairs(tbl) do
                count = count + 1 -- Count the entry itself
                -- Estimate primitive sizes (very rough approximation)
                if type(k) == "string" then count = count + (#k / 1024) end
                if type(v) == "string" then count = count + (#v / 1024) end
                if type(v) == "table" then
                    countRecursive(v)
                end
            end
        end
        countRecursive(t)
        print(string.format("Table weight: ~%.2f KB", count))
    end
end