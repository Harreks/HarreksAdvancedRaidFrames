local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local API = NS.API
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--TODO: Expand the debug options, let users export error data to share

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