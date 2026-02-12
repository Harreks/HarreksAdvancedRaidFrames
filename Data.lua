local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core
local Opt = NS.Opt

--Initialize default data
Data.initializerList = {}
Data.playerClass = nil
Data.buffFilter = 'PLAYER|HELPFUL|RAID_IN_COMBAT'
Data.supportedBuffTracking = {
    SHAMAN = {
        spell = 'Riptide',
        utility = {
            earthShield = nil,
            activeAuras = {}
        }
    },
    EVOKER = {
        spell = 'Echo',
        allowedCastDelay = 0.1,
        utility = {
            filteredSpellTimestamp = nil,
            filteredSpells = {
                [366155] = true,
                [357170] = true,
                [1256581] = true,
                [360995] = true,
                [363564] = true
            },
            filteredEmpowers = {
                [355936] = true,
                [382614] = true
            },
            allEmpowers = {
                [355936] = true,
                [382614] = true,
                [357208] = true,
                [382266] = true
            },
            ttsActive = false,
            filteredBuffs = {},
            activeAuras = {}
        }
    },
    PRIEST = {
        spell = 'Atonement',
        allowedCastDelay = 0.1,
        utility = {
            isDisc = false,
            filteredSpellTimestamp = nil,
            --Disc works the other way around, tracks the casts that apply atonement
            filteredSpells = {
                [200829] = true,
                [2061] = true,
                [17] = true,
                [47540] = true,
                [194509] = true
            },
            filteredBuffs = {},
            activeAuras = {}
        }
    }
}

Data.spotlightAnchors = {
    spotlights = {},
    defaults = {},
}

Data.settings = {
    {
        key = 'clickThroughBuffs',
        type = 'checkbox',
        text = 'Click Through Aura Icons',
        default = true,
        tooltip = 'Disables mouse interaction on the aura icons on the frame, letting you mouseover and click through them.',
        func = 'ToggleAurasMouseInteraction'
    },
    {
        key = 'buffIcons',
        type = 'slider',
        text = 'Buff Icons',
        min = 0,
        max = 6,
        step = 1,
        default = 6,
        tooltip = 'Changes the maximum amount of buff icons on the default frames.',
        func = 'ToggleBuffIcons'
    },
    {
        key = 'debuffIcons',
        type = 'slider',
        text = 'Debuff Icons',
        min = 0,
        max = 3,
        step = 1,
        default = 3,
        tooltip = 'Changes the maximum amount of debuff icons on the default frames.',
        func = 'ToggleDebuffIcons'
    },
    {
        key = 'frameTransparency',
        type = 'checkbox',
        text = 'Frame Transparency',
        default = false,
        tooltip = 'Disabling frame transparency keeps the frame fully solid even when out of range.',
        func = 'SetGroupFrameTransparency'
    },
    {
        key = 'nameScale',
        type = 'slider',
        text = 'Name Size',
        min = 0.5,
        max = 3,
        step = 0.1,
        default = 1,
        tooltip = 'Changes the size of the unit names.',
        func = 'ScaleNames'
    },
    {
        key = 'colorNames',
        type = 'checkbox',
        text = 'Class Colored Names',
        default = false,
        tooltip = 'Replaces the unit name for class-colored ones.',
        func = 'ColorNames'
    },
    {
        key = 'buffTrackingHeader',
        type = 'header',
        text = 'Advanced Buff Tracking'
    },
    {
        key = 'buffTracking',
        type = 'checkbox',
        text = 'Buff Tracking',
        default = true,
        tooltip = 'Some specializations can track a specific buff better on their frames, this enables that tracking.',
        func = 'Setup'
    },
    {
        key = 'trackingType',
        type = 'dropdown',
        text = 'Tracking Type',
        items = {
            { text = 'Icon', value = 'icon' },
            { text = 'Bar Recolor', value = 'color' },
            { text = 'Progress Bar', value = 'bar' }
        },
        default = 'color',
        tooltip = 'Choose how to track the buffs.',
        parent = 'buffTracking',
        func = 'Setup'
    },
    {
        key = 'trackingColor',
        type = 'color',
        text = 'Tracking Color',
        default = 'ff00ff00',
        tooltip = 'Color to change the bars into when the buff is present.',
        parent = 'buffTracking'
    },
    {
        key = 'iconSize',
        type = 'slider',
        text = 'Icon Size',
        min = 10,
        max = 50,
        step = 1,
        default = 25,
        tooltip = 'Choose the size of the tracking icon.',
        parent = 'buffTracking',
        func = 'Setup'
    },
    {
        key = 'iconPosition',
        type = 'dropdown',
        text = 'Icon Position',
        items = {
            { text = 'Top Left', value = 'TOPLEFT' },
            { text = 'Top', value = 'TOP' },
            { text = 'Top Right', value = 'TOPRIGHT' },
            { text = 'Left', value = 'LEFT' },
            { text = 'Right', value = 'RIGHT' },
            { text = 'Bottom Left', value = 'BOTTOMLEFT' },
            { text = 'Bottom', value = 'BOTTOM' },
            { text = 'Bottom Right', value = 'BOTTOMRIGHT' }
        },
        default = 'RIGHT',
        tooltip = 'Choose where to place the tracking icon.',
        parent = 'buffTracking',
        func = 'Setup'
    },
    {
        key = 'barPosition',
        type = 'dropdown',
        text = 'Bar Position',
        items = {
            { text = 'Top Right', value = 'topRight' },
            { text = 'Bottom Right', value = 'bottomRight' },
            { text = 'Bottom Left', value = 'bottomLeft' },
            { text = 'Top Left', value = 'topLeft' }
        },
        default = 'topRight',
        tooltip = 'Choose where to place the progress bar.',
        parent = 'buffTracking',
        func = 'Setup'
    },
    {
        key = 'barHeight',
        type = 'slider',
        text = 'Bar Height',
        min = 5,
        max = 20,
        step = 1,
        default = 10,
        tooltip = 'Choose the height of the progress bar.',
        parent = 'buffTracking',
        func = 'Setup'
    },
    {
        key = 'barWidth',
        type = 'dropdown',
        text = 'Bar Width',
        items = {
            { text = 'Full', value = 'full' },
            { text = 'Half', value = 'half' }
        },
        default = 'full',
        tooltip = 'Choose the width of the progress bar.',
        parent = 'buffTracking',
        func = 'Setup'
    },
    {
        key = 'addonsHeader',
        type = 'header',
        text = 'Frame AddOn Compatibility'
    },
    {
        key = 'dandersCompat',
        type = 'checkbox',
        text = 'DandersFrames Compatibility',
        default = false,
        tooltip = 'Shows the selected tracking method on DandersFrames instead of the default ones.',
        func = 'Setup'
    },
    {
        key = 'grid2Compat',
        type = 'checkbox',
        text = 'Grid2 Compatibility',
        default = true,
        readOnly = true,
        tooltip = 'Having the AddOn installed enables the \'HealerBuff\' status in Grid2. Use it to configure how to display the tracking.'
    }
}

--Events the frames need to check for
Data.trackedEvents = {
    general = {
        'PLAYER_LOGIN',
        'GROUP_ROSTER_UPDATE'
    },
    player = {
        'UNIT_SPELLCAST_SUCCEEDED',
        'UNIT_SPELLCAST_EMPOWER_STOP'
    }
}

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