local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--The Advanced Raid Frames API lets you register your frames to use the indicators yourself or query aura information about units
local API = {}

--Returns a table with all the internal names for the supported specs
function API.ListSupportedSpecs()
    local specInfo = Data.specInfo
    local specs = {}
    for spec, _ in pairs(specInfo) do
        table.insert(specs, spec)
    end
    return specs
end

--Returns a list of all the tracked auras for a given spec
function API.ListAurasForSpec(specName)
    local specInfo = Data.specInfo[specName]
    if specInfo then
        local auras = {}
        for aura, _ in pairs(specInfo.auras) do
            table.insert(auras, aura)
        end
        return auras
    end
end

--Gets a list of all the aura data currently active for a unit (this doesn't cause api calls, everything is in the addon)
function API.GetUnitAuras(unit)
    local unitList = Util.GetRelevantList()
    local elements = unitList[unit]
    if elements and elements.auras then
        return elements.auras
    else
        return {}
    end
end

--Gets the data for a specific aura on a specific unit
function API.GetUnitAura(unit, aura)
    local unitList = Util.GetRelevantList()
    local elements = unitList[unit]
    if elements and elements.auras and elements.auras[aura] then
        return elements.auras[aura]
    else
        return nil
    end
end

--Registers a frame to a unit so the indicator overlay is also created on top of that frame
--coloringFunc will be called when the frame is supposed to be recolored, not passing a function will call frame.healthBar:SetStatusBarColor() instead
function API.RegisterFrameForUnit(unit, frame, coloringFunc)
end

AdvancedRaidFramesAPI = API