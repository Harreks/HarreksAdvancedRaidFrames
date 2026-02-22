local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local API = NS.API
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--The Advanced Raid Frames API lets you register your frames to use the indicators yourself or query aura information about units
API.Callbacks = LibStub('CallbackHandler-1.0'):New(API)

----[[
-- Every time any valid unit (player, party#1-4, raid#1-40) gets an UNIT_AURA event, Advanced Raid Frames will throw a HARF_UNIT_AURA event sending the current updated aura data
-- It will be a table of the form { auraName = <secret>auraData }, simply use end points that accept secret values to display the data
----]]

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

--Gets a list of all the aura data currently active for a unit (this doesn't cause blizzard api calls, everything is in the addon)
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

function API.SetProfilingEnabled(value)
    Util.SetProfileEnabled(value)
end

function API.ResetProfilingStats()
    Util.ResetProfileStats()
end

function API.GetProfilingStats()
    return Util.GetProfileStats()
end

function API.PrintProfilingStats()
    Util.PrintProfileStats()
end

--Registers a frame to a unit so the indicator overlay is also created on top of that frame
--the units are 'player', 'party#1-4', and 'raid#1-40'
--coloringFunc will be called when the frame is supposed to be recolored, not passing a function will call frame.healthBar:SetStatusBarColor() instead
--returns and index that is then used for UnregisterFrameForUnit
--the idea here is that as your frames change units, you manage a registering/unregistering to keep them attached to the correct unit
function API.RegisterFrameForUnit(unit, frame, coloringFunc)
    local unitList = string.find(unit, 'raid') and Data.unitList.raid or Data.unitList.party
    local unitElements = unitList[unit]
    if unitElements then
        table.insert(unitElements.extraFrames, { frame = frame, indicatorOverlay = nil, index = nil, coloringFunc = coloringFunc })
        local index = #unitElements.extraFrames
        unitElements.extraFrames[index].index = index
        Util.MapOutUnits()
        return index
    else
        return false
    end
end

--You pass the same unit you gave to registering and the index you got back to remove it
function API.UnregisterFrameForUnit(unit, index)
    local unitList = string.find(unit, 'raid') and Data.unitList.raid or Data.unitList.party
    local unitElements = unitList and unitList[unit]
    local extraFrames = unitElements and unitElements.extraFrames
    if extraFrames and #extraFrames > 0 then
        local target = extraFrames[index]
        if not target then
            return false
        end
        if target.indicatorOverlay then
            target.indicatorOverlay:Delete()
        end
        table.remove(extraFrames, index)
        return true
    else
        return false
    end
end

AdvancedRaidFramesAPI = API