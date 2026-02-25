local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local API = NS.API
local L = NS.L
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

Data.spellIds = {
    Echo = 364343,
    Reversion = 366155,
    EchoReversion = 367364,
    DreamBreath = 355941,
    EchoDreamBreath = 376788,
    TimeDilation = 357170,
    Rewind = 363534,
    DreamFlight = 363502,
    Lifebind = 373267,
    VerdantEmbrace = 409895,
    Prescience = 410089,
    ShiftingSands = 413984,
    InfernosBlessing = 410263,
    EbonMight = 395152,
    SymbioticBloom = 410686,
    BlisteringScales = 360827,
    PowerWordShield = 17,
    Atonement = 194384,
    PainSuppression = 33206,
    VoidShield = 1253593,
    Renew = 139,
    EchoOfLight = 77489,
    GuardianSpirit = 47788,
    PrayerOfMending = 41635,
    PowerInfusion = 10060,
    RenewingMist = 119611,
    EnvelopingMist = 124682,
    SoothingMist = 115175,
    LifeCocoon = 116849,
    Rejuvenation = 774,
    Regrowth = 8936,
    Lifebloom = 33763,
    Germination = 155777,
    WildGrowth = 48438,
    IronBark = 102342,
    Riptide = 61295,
    EarthShield = 383648,
    BeaconOfFaith = 156910,
    EternalFlame = 156322,
    BeaconOfLight = 53563,
    BlessingOfProtection = 1022,
    HolyBulwark = 432496,
    SacredWeapon = 432502,
    BlessingOfSacrifice = 6940,
    BeaconOfVirtue = 200025,
    BeaconOfTheSavior = 1244893,
    AspectOfHarmony = 450769,
    StrengthOfTheBlackOx = 443113
}

Data.indicatorTypes = {
    icon = {
        display = L.INDICATOR_TYPE_ICON
    },
    square = {
        display = L.INDICATOR_TYPE_SQUARE
    },
    bar = {
        display = L.INDICATOR_TYPE_BAR
    },
    healthColor = {
        display = L.INDICATOR_TYPE_BORDER
    }
}

Data.indicatorTypeSettings = {
    healthColor = {
        defaults = {
            Color = { r = 0, g = 1, b = 0, a = 1 },
            LayerPriority = 'Normal',
            showCooldown = false,
            borderCooldownDirection = 'Clockwise',
            borderCooldownStartCorner = 'TOPRIGHT',
            borderWidth = 3,
            borderPlacement = 'Inset'
        },
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', row = 1 },
            { controlType = 'ColorPicker', setting = 'Color', row = 1 },
            { controlType = 'Checkbox', setting = 'showCooldown', text = 'Show Cooldown', row = 2 },
            { controlType = 'Slider', sliderType = 'borderWidth', setting = 'borderWidth', row = 2 },
            { controlType = 'Dropdown', dropdownType = 'borderPlacement', setting = 'borderPlacement', row = 3 }
        }
    },
    icon = {
        defaults = {
            LayerPriority = 'Normal',
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
            BackgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
            LayerPriority = 'Normal',
            Position = 'CENTER',
            Size = 25,
            xOffset = 0,
            yOffset = 0,
            textSize = 1,
            showText = false,
                showCooldown = false,
                showCooldownText = true,
                cooldownStyle = 'Swipe',
                depleteDirection = 'Right to Left'
        },
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', row = 1 },
            { controlType = 'ColorPicker', setting = 'Color', row = 1 },
            { controlType = 'Dropdown', dropdownType = 'iconPosition', setting = 'Position', row = 1 },
            { controlType = 'Slider', sliderType = 'iconSize', setting = 'Size', row = 1 },
            { controlType = 'Slider', sliderType = 'xOffset', setting = 'xOffset', row = 1 },
            { controlType = 'Slider', sliderType = 'yOffset', setting = 'yOffset', row = 1 },
            { controlType = 'Slider', sliderType = 'textSize', setting = 'textSize', row = 2 },
            { controlType = 'Checkbox', setting = 'showCooldown', text = 'Show Cooldown', row = 2 },
            { controlType = 'Checkbox', setting = 'showText', text = 'Show Text', row = 2 }
        }
    },
    bar = {
        defaults = {
            Color = { r = 0, g = 1, b = 0, a = 1 },
            BackgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
            LayerPriority = 'Normal',
            showSpark = false,
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
    indicatorLayer = {
        text = 'Select Layer Priority',
        default = 'Normal',
        options = { 'Low', 'Normal', 'High', 'Top' }
    },
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
    squareCooldownStyle = {
        text = 'Select Cooldown Style',
        default = 'Swipe',
        options = { 'Swipe', 'Deplete' }
    },
    squareDepleteDirection = {
        text = 'Select Deplete Direction',
        default = 'Right to Left',
        options = { 'Right to Left', 'Left to Right', 'Top to Bottom', 'Bottom to Top' }
    },
    borderCooldownDirection = {
        text = 'Select Cooldown Direction',
        default = 'Clockwise',
        options = { 'Clockwise', 'Anti-Clockwise' }
    },
    borderCooldownStartCorner = {
        text = 'Select Cooldown Start Corner',
        default = 'TOPRIGHT',
        options = { 'TOPLEFT', 'TOPRIGHT', 'BOTTOMLEFT', 'BOTTOMRIGHT' }
    },
    borderPlacement = {
        text = 'Select Border Placement',
        default = 'Inset',
        options = { 'Inset', 'Outset' }
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
    },
    borderWidth = {
        text = 'Border Width',
        decimals = 0,
        default = 3,
        min = 1,
        max = 10,
        step = 1
    }
}

Data.settings = {
    {
        key = 'clickThroughBuffs',
        type = 'checkbox',
        text = L.OPTION_CLICK_THROUGH_AURAS,
        default = true,
        tooltip = L.OPTION_CLICK_THROUGH_AURAS_TOOLTIP,
        func = 'ToggleAurasMouseInteraction'
    },
    {
        key = 'buffIcons',
        type = 'slider',
        text = L.OPTION_BUFF_ICONS,
        min = 0,
        max = 6,
        step = 1,
        default = 6,
        tooltip = L.OPTION_BUFF_ICONS_TOOLTIP,
        func = 'ToggleBuffIcons'
    },
    {
        key = 'debuffIcons',
        type = 'slider',
        text = L.OPTION_DEBUFF_ICONS,
        min = 0,
        max = 3,
        step = 1,
        default = 3,
        tooltip = L.OPTION_DEBUFF_ICONS_TOOLTIP,
        func = 'ToggleDebuffIcons'
    },
    {
        key = 'frameTransparency',
        type = 'checkbox',
        text = L.OPTION_FRAME_TRANSPARENCY,
        default = false,
        tooltip = L.OPTION_FRAME_TRANSPARENCY_TOOLTIP,
        func = 'SetGroupFrameTransparency'
    },
    {
        key = 'nameScale',
        type = 'slider',
        text = L.OPTION_NAME_SIZE,
        min = 0.5,
        max = 3,
        step = 0.1,
        default = 1,
        tooltip = L.OPTION_NAME_SIZE_TOOLTIP,
        func = 'ScaleNames'
    },
    {
        key = 'colorNames',
        type = 'checkbox',
        text = L.OPTION_CLASS_COLORED_NAMES,
        default = false,
        tooltip = L.OPTION_CLASS_COLORED_NAMES_TOOLTIP,
        func = 'ColorNames'
    },
    {
        key = 'spotlightHeader',
        type = 'header',
        text = L.SPOTLIGHT_SETTINGS_HEADER
    },
    {
        key = 'spotlightOpenEditMode',
        type = 'button',
        text = L.SPOTLIGHT_SETTINGS_BUTTON_TITLE,
        content = L.SPOTLIGHT_SETTINGS_BUTTON,
        tooltip = L.SPOTLIGHT_SETTINGS_BUTTON_TOOLTIP,
        func = 'OpenSpotlightEditMode'
    },
    {
        key = 'miscOptionsHeader',
        type = 'header',
        text = L.OPTION_MISC_HEADER
    },
    {
        key = 'showMinimapIcon',
        type = 'checkbox',
        text = L.OPTION_SHOW_MINIMAP_ICON,
        default = true,
        tooltip = L.OPTION_SHOW_MINIMAP_ICON_TOOLTIP,
        func = 'ToggleMinimapIcon'
    }
}

Data.initializerList = {}
Data.playerSpec = nil
