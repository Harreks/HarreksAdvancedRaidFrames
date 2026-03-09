local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local Debug = NS.Debug
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--List of the names of all the default raid frames
Data.frameList = { party = {}, raidCombined = {}, raidGroups = {} }
for i = 1, 30 do
    if i <= 5 then
        table.insert(Data.frameList.party, 'CompactPartyFrameMember' .. i)
    end
    table.insert(Data.frameList.raidCombined, 'CompactRaidFrame' .. i)
    local group = math.floor((i / 5) - 0.1 + 1)
    local member = ((i - 1) % 5) + 1
    table.insert(Data.frameList.raidGroups, 'CompactRaidGroup' .. group .. 'Member' .. member)
end

--Default data that each unit carries
Data.defaultUnitData = {
    frame = nil,
    buffs = {},
    debuffs = {},
    centerIcon = nil,
    roleIcon = nil,
    name = nil,
    isColored = false,
    defensive = { type = 'defensive', frame = nil },
    extFrames = {},
    extIndicatorOverlays = {}
}

--Build a list of units to store data for each group member
Data.unitList = {
    player = CopyTable(Data.defaultUnitData)
}
for i = 1, 30 do
    if i < 5 then
        Data.unitList['party' .. i] = CopyTable(Data.defaultUnitData)
    end
    Data.unitList['raid' .. i] = CopyTable(Data.defaultUnitData)
end
