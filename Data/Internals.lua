local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local Debug = NS.Debug
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--When we re-order frames for the spotlight we save what they are anchored to
Data.spotlightFrames = {}

--This handles a list of the current auras you have applied on each unit, your casts, and some extras for more complex tracking
Data.state = {
    casts = {},
    auras = {},
    extras = {}
}

--These are the texture ids to show the icons on the designer
Data.textures = {
    --Pres
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
    --Aug
    Prescience = 5199639,
    ShiftingSands = 5199633,
    InfernosBlessing = 5199632,
    EbonMight = 5061347,
    SensePower = 132160,
    SymbioticBloom = 4554354,
    BlisteringScales = 5199621,
    --Priest
    PowerWordShield = 135940,
    Atonement = 458720,
    PainSuppression = 135936,
    VoidShield = 7514191,
    Renew = 135953,
    EchoOfLight = 237537,
    GuardianSpirit = 237542,
    PrayerOfMending = 135944,
    PowerInfusion = 135939,
    --Mw
    RenewingMist = 627487,
    EnvelopingMist = 775461,
    SoothingMist = 606550,
    LifeCocoon = 627485,
    AspectOfHarmony = 5927638,
    StrengthOfTheBlackOx = 615340,
    --rDruid
    Rejuvenation = 136081,
    Regrowth = 136085,
    Lifebloom = 134206,
    Germination = 1033478,
    WildGrowth = 236153,
    IronBark = 572025,
    --rSham
    Riptide = 252995,
    EarthShield = 136089,
    --hPal
    BeaconOfFaith = 1030095,
    EternalFlame = 135433,
    BeaconOfLight = 236247,
    BlessingOfProtection = 135964,
    HolyBulwark = 5927636,
    SacredWeapon = 5927637,
    HolyArmaments = 5927637,
    BlessingOfSacrifice = 135966,
    BeaconOfVirtue = 1030094,
    BeaconOfTheSavior = 7514188
}

--This has all the data for the indicators the addon supports
Data.indicatorTypes = {
    icon = {
        display = 'Icon',
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', row = 1 },
            { controlType = 'Dropdown', dropdownType = 'iconPosition', setting = 'Position', row = 1, default = 'CENTER' },
            { controlType = 'Slider', sliderType = 'iconSize', setting = 'iconSize', row = 1, default = 25 },
            { controlType = 'Slider', sliderType = 'textSize', setting = 'textSize', row = 1, default = 1 },
            { controlType = 'Slider', sliderType = 'xOffset', setting = 'xOffset', row = 2, default = 0 },
            { controlType = 'Slider', sliderType = 'yOffset', setting = 'yOffset', row = 2, default = 0 },
            { controlType = 'Checkbox', setting = 'showText', text = 'Show Text', row = 2, default = true },
            { controlType = 'Checkbox', setting = 'showTexture', text = 'Show Texture', row = 2, default = true }
        }
    },
    square = {
        display = 'Square',
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', row = 1 },
            { controlType = 'Dropdown', dropdownType = 'iconPosition', setting = 'Position', row = 1, default = 'CENTER' },
            { controlType = 'Slider', sliderType = 'iconSize', setting = 'iconSize', row = 1, default = 25 },
            { controlType = 'Slider', sliderType = 'textSize', setting = 'textSize', row = 1, default = 1 },
            { controlType = 'Slider', sliderType = 'xOffset', setting = 'xOffset', row = 2, default = 0 },
            { controlType = 'Slider', sliderType = 'yOffset', setting = 'yOffset', row = 2, default = 0 },
            { controlType = 'ColorPicker', setting = 'Color', row = 2, default = { r = 0, g = 1, b = 0, a = 1 } },
            { controlType = 'Checkbox', setting = 'showText', text = 'Show Text', row = 2, default = false },
            { controlType = 'Checkbox', setting = 'showCooldown', text = 'Show Cooldown', row = 2, default = false }
        }
    },
    bar = {
        display = 'Bar',
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', row = 1 },
            { controlType = 'ColorPicker', setting = 'Color', row = 1, default = { r = 0, g = 1, b = 0, a = 1 } },
            { controlType = 'Dropdown', dropdownType = 'barPosition', setting = 'Position', row = 1, default = 'TOPRIGHT' },
            { controlType = 'Slider', sliderType = 'barSize', setting = 'barSize', row = 1, default = 15 },
            { controlType = 'Dropdown', dropdownType = 'barOrientation', setting = 'Orientation', row = 1, default = 'Horizontal' },
            { controlType = 'Dropdown', dropdownType = 'barScale', setting = 'Scale', row = 2, default = 'Full' },
            { controlType = 'Slider', sliderType = 'offset', setting = 'Offset', row = 2, default = 0 }
        }
    },
    border = {
        display = 'Border',
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', row = 1 },
            { controlType = 'ColorPicker', setting = 'Color', row = 1, default = { r = 0, g = 1, b = 0, a = 1 } },
            { controlType = 'Slider', sliderType = 'borderWidth', setting = 'borderWidth', row = 2, default = 3 }
        }
    },
    healthColor = {
        display = 'Health Bar Color',
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', row = 1 },
            { controlType = 'ColorPicker', setting = 'Color', row = 1, default = { r = 0, g = 1, b = 0, a = 1 } }
        }
    }
}

--Different type of dropdown controls
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
    squareCooldownStyle = {
        text = 'Select Cooldown Style',
        default = 'Swipe',
        options = { 'Swipe', 'Deplete' }
    }
}

--Presets default values for the different types of sliders
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

--This is the data table for the default frames options of the addons
Data.settings = {
    {
        key = 'iconsHeader',
        type = 'header',
        text = 'Icons'
    },
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
        text = 'Show Buff Icons',
        min = 0,
        max = 6,
        step = 1,
        default = 0,
        tooltip = 'Changes the maximum amount of buff icons on the default frames.',
        func = 'ToggleBuffIcons'
    },
    {
        key = 'debuffIcons',
        type = 'slider',
        text = 'Show Debuff Icons',
        min = 0,
        max = 3,
        step = 1,
        default = 3,
        tooltip = 'Changes the maximum amount of debuff icons on the default frames.',
        func = 'ToggleDebuffIcons'
    },
    {
        key = 'showDefensiveIcon',
        ddKey = 'defensivePosition',
        type = 'checkbox-dropdown',
        text = 'Center Defensive Icon',
        default = true,
        ddDefault = 'CENTER',
        items = {
            { value = 'CENTER', text = 'Center' },
            { value = 'TOPLEFT', text = 'Top Left' },
            { value = 'TOP', text = 'Top' },
            { value = 'TOPRIGHT', text = 'Top Right' },
            { value = 'RIGHT', text = 'Right' },
            { value = 'BOTTOMRIGHT', text = 'Bottom Right' },
            { value = 'BOTTOM', text = 'Bottom' },
            { value = 'BOTTOMLEFT', text = 'Bottom Left' },
            { value = 'LEFT', text = 'Left' },
        },
        tooltip = 'Control the icon that shows defensive usage on the default frames.',
        func = 'ToggleCenterDefensive',
        ddFunc = 'ReanchorCenterDefensive'
    },
    {
        key = 'defensiveIconScale',
        type = 'slider',
        text = 'Center Defensive Scale',
        min = 0.5,
        max = 1.5,
        step = 0.1,
        default = 1,
        tooltip = 'Size of the center defensive icon.',
        func = 'ResizeCenterDefensive'
    },
    {
        key = 'roleIcon',
        type = 'checkbox',
        text = 'Show Role Icon',
        default = true,
        tooltip = 'Show the role icon next to the name on the default frames.',
        func = 'ToggleRoleIcon'
    },
    {
        key = 'barHeader',
        type = 'header',
        text = 'Health Bar'
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
        key = 'barTextureEnabled',
        ddKey = 'barTexture',
        type = 'checkbox-texture',
        text = 'Bar Texture',
        default = false,
        ddDefault = 'Default',
        tooltip = 'Changes the texture of the health bars on the default raid frames',
        func = 'EnableBarTexture',
        ddFunc = 'SetBarTexture'
    },
    {
        key = 'showOvershields',
        ddKey = 'overshieldsTexture',
        type = 'checkbox-texture',
        text = 'Overshields',
        default = true,
        ddDefault = 'Shields',
        tooltip = 'Shows shields that go above the players max hp.',
        func = 'ShowOvershields',
        ddFunc = 'OvershieldsTexture'
    },
    {
        key = 'namesHeader',
        type = 'header',
        text = 'Names'
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
        key = 'miscHeader',
        type = 'header',
        text = 'Misc.'
    },
    {
        key = 'extFrames',
        type = 'checkbox',
        text = 'Use Frame Addons',
        default = true,
        tooltip = 'Add Advanced Raid Frames indicators on top of other active frame addons.',
        func = 'Setup'
    },
    {
        key = 'enableSpotlight',
        type = 'dropdown',
        text = 'Enable Spotlight',
        default = 0,
        tooltip = 'Enable the Spotlight feature to separate specific players into their own groups.',
        items = {
            { value = 0, text = 'Disabled' },
            { value = 1, text = 'In Raid' },
            { value = 2, text = 'In Party' },
            { value = 3, text = 'Always' }
        }
    }
}

--This is a list of external frames we ignore for libGetFrame
Data.ignoredFrames = {
    '^CompactRaid',
    '^CompactParty',
    '^InvenUnitFrames_Player$',
    '^SUFUnitplayer$',
    '^LUFUnitplayer$',
    '^PitBull4_Frames_Player$',
    '^ElvUF_Player$',
    '^oUF_.-Player$',
    '^XPerl_Player$',
    '^UUF_Player$',
    '^PlayerFrame$'
}

Data.barTextures = {
    ["Default"] = { type = 'T', path = 7539072 },
    ["Blizzard Raid"] = { type = 'T', path = 'Interface/RaidFrame/Raid-Bar-Hp-Fill' },
    ["Blizzard Flat"] = { type = 'T', path = 'Interface/Buttons/WHITE8X8' },
    ["Smooth"] = { type = 'T', path = 137012 },
    ["Shields"] = { type = 'T', path = 'interface/raidframe/raidframeshieldoverlay' },
    ["Lunar"] = { type = 'A', path = '_Druid-LunarBar' },
    ["Torghast"] = { type = 'A', path = 'jailerstower-scorebar-fill-normal' },
    ["Insanity"] = { type = 'A', path = '_Priest-InsanityBar' },
    ["Empower"] = { type = 'A', path = 'ui-castingbar-disabled-tier4-empower' }
}

Data.textureChanged = false

--Initializer list is used when we generate the menu, so we can parent some options to others
Data.initializerList = {}
--Player spec is checked constantly through the run to make sure we're using appropriate data
Data.playerSpec = nil
Data.auraSignatures = {}

--When using external frames we securehook a recoloring on them to maintain our colors, this list lets us keep track of the ones already hooked
Data.hookedFrames = {}