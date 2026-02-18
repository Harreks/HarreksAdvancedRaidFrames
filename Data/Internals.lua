local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local API = NS.API
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

Data.spotlightAnchors = {
    spotlights = {},
    defaults = {},
}

Data.state = {
    casts = {},
    auras = {},
    extras = {}
}


Data.textures = {
    Echo = 4622456,
    Reversion = 4630467,
    EchoReversion = 4630469,
    DreamBreath = 4622454,
    EchoDreamBreath = 7439198,
    TimeDilation = 4622478,
    Rewind = 4622474,
    DreamFlight = 4622455,
    Lifebind = 4630453,
    VerdantEmbrace = 4622471,
    Prescience = 5199639,
    ShiftingSands = 5199633,
    InfernosBlessing = 5199632,
    EbonMight = 5061347,
    SensePower = 132160,
    SymbioticBloom = 4554354,
    BlisteringScales = 5199621,
    PowerWordShield = 135940,
    Atonement = 458720,
    PainSuppression = 135936,
    VoidShield = 7514191,
    Renew = 135953,
    EchoOfLight = 237537,
    GuardianSpirit = 237542,
    PrayerOfMending = 135944,
    PowerInfusion = 135939,
    RenewingMist = 627487,
    EnvelopingMist = 775461,
    SoothingMist = 606550,
    LifeCocoon = 627485,
    Rejuvenation = 136081,
    Regrowth = 136085,
    Lifebloom = 134206,
    Germination = 1033478,
    WildGrowth = 236153,
    IronBark = 572025,
    Riptide = 252995,
    EarthShield = 136089,
    BeaconOfFaith = 1030095,
    EternalFlame = 135433,
    BeaconOfLight = 236247,
    BlessingOfProtection = 135964,
    HolyBulwark = 5927636,
    SacredWeapon = 5927637,
    BlessingOfSacrifice = 135966,
    BeaconOfVirtue = 1030094,
    BeaconOfTheSavior = 7514188,
    AspectOfHarmony = 5927638,
    StrengthOfTheBlackOx = 615340
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
        display = 'Border'
    }
}

Data.indicatorTypeSettings = {
    healthColor = {
        defaults = {
            Color = { r = 0, g = 1, b = 0, a = 1 }
        },
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', row = 1 },
            { controlType = 'ColorPicker', setting = 'Color', row = 1 }
        }
    },
    icon = {
        defaults = {
            Position = 'CENTER',
            Size = 25,
            xOffset = 0,
            yOffset = 0,
            textSize = 1,
            showText = true,
            showTexture = true
        },
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', row = 1 },
            { controlType = 'Dropdown', dropdownType = 'iconPosition', setting = 'Position', row = 1 },
            { controlType = 'Slider', sliderType = 'iconSize', setting = 'Size', row = 1 },
            { controlType = 'Slider', sliderType = 'xOffset', setting = 'xOffset', row = 1 },
            { controlType = 'Slider', sliderType = 'yOffset', setting = 'yOffset', row = 1 },
            { controlType = 'Slider', sliderType = 'textSize', setting = 'textSize', row = 2 },
            { controlType = 'Checkbox', setting = 'showText', text = 'Show Text', row = 2 },
            { controlType = 'Checkbox', setting = 'showTexture', text = 'Show Texture', row = 2 }
        }
    },
    square = {
        defaults = {
            Color = { r = 0, g = 1, b = 0, a = 1 },
            Position = 'CENTER',
            Size = 25,
            xOffset = 0,
            yOffset = 0,
            textSize = 1,
            showCooldown = false
        },
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', row = 1 },
            { controlType = 'ColorPicker', setting = 'Color', row = 1 },
            { controlType = 'Dropdown', dropdownType = 'iconPosition', setting = 'Position', row = 1 },
            { controlType = 'Slider', sliderType = 'iconSize', setting = 'Size', row = 1 },
            { controlType = 'Slider', sliderType = 'xOffset', setting = 'xOffset', row = 1 },
            { controlType = 'Slider', sliderType = 'yOffset', setting = 'yOffset', row = 1 },
            { controlType = 'Slider', sliderType = 'textSize', setting = 'textSize', row = 2 },
            { controlType = 'Checkbox', setting = 'showCooldown', text = 'Show Cooldown', row = 2 }
        }
    },
    bar = {
        defaults = {
            Color = { r = 0, g = 1, b = 0, a = 1 },
            Position = 'TOPRIGHT',
            Scale = 'Full',
            Orientation = 'Horizontal',
            Size = 15,
            Offset = 0
        },
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', row = 1 },
            { controlType = 'ColorPicker', setting = 'Color', row = 1 },
            { controlType = 'Dropdown', dropdownType = 'barPosition', setting = 'Position', row = 1 },
            { controlType = 'Slider', sliderType = 'barSize', setting = 'Size', row = 1 },
            { controlType = 'Dropdown', dropdownType = 'barOrientation', setting = 'Orientation', row = 1 },
            { controlType = 'Dropdown', dropdownType = 'barScale', setting = 'Scale', row = 2 },
            { controlType = 'Slider', sliderType = 'offset', setting = 'Offset', row = 2 }
        }
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
        default = 15,
        min = 5,
        max = 30,
        step = 1
    },
    xOffset = {
        text = 'X Offset',
        decimals = 0,
        default = 0,
        min = -50,
        max = 50,
        step = 1
    },
    yOffset = {
        text = 'Y Offset',
        decimals = 0,
        default = 0,
        min = -50,
        max = 50,
        step = 1
    },
    offset = {
        text = 'Offset',
        decimals = 0,
        default = 0,
        min = -50,
        max = 50,
        step = 1
    },
    textSize = {
        text = 'Text Scale',
        decimals = 1,
        default = 1,
        min = 0.5,
        max = 3,
        step = 0.1
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
        key = 'miscOptionsHeader',
        type = 'header',
        text = 'Misc.'
    },
    {
        key = 'showMinimapIcon',
        type = 'checkbox',
        text = 'Show Minimap Icon',
        default = true,
        tooltip = 'Shows or hides the minimap icon for the addon',
        func = 'ToggleMinimapIcon'
    }
}

Data.otherAddonsInfo = {
    {
        title = 'Compatibility With Other Frame Addons',
        text = 'One of my goals is trying to integrate as much as possible with existing addons so you can very easily improve your gameplay without having to start over ' ..
        'with a whole new set of frames. With that purpose i have designed advanced raid frames to seamlessly integrate into other frames with very little work. I have done ' ..
        'this integration myself for a couple of them but others might require me to talk to their developers or for them to use my api. If you use different frames that i don\'t ' ..
        'currently support please let me know about it and also let the author know, so we can work together to get you sorted.'
    },
    {
        title = 'Grid2',
        text = 'Grid2 lets other addons register plugins for it to add new statuses. Advanced Raid Frames registers all the buffs it tracks as custom statuses so you can assign them to ' ..
        'any indicators like you normally would and did before Midnight. Simply having both addons installed is enough to get them to work.'
    },
    {
        title = 'DandersFrames',
        text = 'Integration with DandersFrames works via installing the Advanced Raid Frames indicators on top of the frames from the addon. If DandersFrames is installed when you form ' ..
        'a group the addon will try to also add any indicator you have created in the designer onto those frames and show the tracking for the spells.'
    }
}

Data.engineFunctions = {}
Data.registeredExtraFrames = {}
Data.initializerList = {}
Data.playerSpec = nil
