local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

Data.spotlightAnchors = {
    spotlights = {},
    defaults = {},
}

Data.state = {
    casts = {},
    lastCast = nil,
    auras = {},
    extras = {}
}

Data.indicatorTypes = {
    icon = {
        display = 'Icon'
    },
    square = {
        display = 'Square'
    },
    bar = {
        display = 'Bar'
    },
    healthColor = {
        display = 'Health Color'
    }
}

Data.dropdownOptions = {
    iconPosition = {
        text = 'Select Icon Position',
        default = 'CENTER',
        options = { 'TOPLEFT', 'TOP', 'TOPRIGHT', 'LEFT', 'CENTER', 'RIGHT', 'BOTTOMLEFT', 'BOTTOM', 'BOTTOMRIGHT' }
    },
    barPosition = {
        text = 'Select Bar Position',
        default = 'TOPRIGHT',
        options = { 'TOPLEFT', 'TOPRIGHT', 'BOTTOMLEFT', 'BOTTOMRIGHT' }
    },
    barScale = {
        text = 'Select Bar Scale',
        default = 'Full',
        options = { 'Full', 'Half' }
    },
    barOrientation = {
        text = 'Select Bar Orientation',
        default = 'Horizontal',
        options = { 'Horizontal', 'Vertical' }
    },
}

Data.sliderPresets = {
    iconSize = {
        text = 'Size',
        decimals = 0,
        default = 25,
        min = 10,
        max = 50,
        step = 1
    },
    barSize = {
        text = 'Size',
        decimals = 0,
        default = 10,
        min = 5,
        max = 20,
        step = 1
    }
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

Data.initializerList = {}
Data.playerSpec = nil
