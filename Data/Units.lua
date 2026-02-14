local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--List of the names of all the default raid frames
Data.frameList = { party = {}, raid = {} }
for i = 1, 30 do
    if i <= 5 then
        table.insert(Data.frameList.party, 'CompactPartyFrameMember' .. i)
    end
    table.insert(Data.frameList.raid, 'CompactRaidFrame' .. i)
    local group = math.floor((i / 5) - 0.1 + 1)
    local member = ((i - 1) % 5) + 1
    table.insert(Data.frameList.raid, 'CompactRaidGroup' .. group .. 'Member' .. member)
end

--Default data that each unit carries
Data.defaultUnitData = {
    frame = nil,
    buffs = {},
    debuffs = {},
    centerIcon = nil,
    name = nil,
    isColored = false,
    defensive = { type = 'defensive', frame = nil }
}

--Build a list of units to store data for each group member
Data.unitList = {
    party = {
        player = CopyTable(Data.defaultUnitData)
    },
    raid = {}
}
for i = 1, 30 do
    local partyMember, raidMember
    if i <= 4 then
        partyMember = 'party' .. i
        Data.unitList.party[partyMember] = CopyTable(Data.defaultUnitData)
    end
    raidMember = 'raid' .. i
    Data.unitList.raid[raidMember] = CopyTable(Data.defaultUnitData)
end