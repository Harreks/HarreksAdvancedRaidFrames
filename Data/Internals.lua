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
    blockedAuras = {},
    enemyCasts = {}
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
    EarthlivingWeapon = 237578,
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
        sections = {
            'Icon',
            'Position',
            'Text'
        },
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', section = 'Icon' },
            { controlType = 'Dropdown', dropdownType = 'iconPosition', setting = 'Position', section = 'Position', default = 'CENTER' },
            { controlType = 'Slider', sliderType = 'iconSize', setting = 'iconSize', section = 'Icon', default = 25 },
            { controlType = 'Slider', sliderType = 'textSize', setting = 'textSize', section = 'Text', default = 1 },
            { controlType = 'Slider', sliderType = 'xOffset', setting = 'xOffset', section = 'Position', default = 0 },
            { controlType = 'Slider', sliderType = 'yOffset', setting = 'yOffset', section = 'Position', default = 0 },
            { controlType = 'ColorPicker', setting = 'textColor', section = 'Text', default = { r = 1, g = 1, b = 1, a = 1 } },
            { controlType = 'Checkbox', setting = 'showText', text = 'Show Text', section = 'Text', default = true },
            { controlType = 'Checkbox', setting = 'showTexture', text = 'Show Texture', section = 'Icon', default = true }
        }
    },
    square = {
        display = 'Square',
        sections = {
            'Icon',
            'Position',
            'Text'
        },
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', section = 'Icon' },
            { controlType = 'Dropdown', dropdownType = 'iconPosition', setting = 'Position', section = 'Position', default = 'CENTER' },
            { controlType = 'Slider', sliderType = 'iconSize', setting = 'iconSize', section = 'Icon', default = 25 },
            { controlType = 'Slider', sliderType = 'textSize', setting = 'textSize', section = 'Text', default = 1 },
            { controlType = 'Slider', sliderType = 'xOffset', setting = 'xOffset', section = 'Position', default = 0 },
            { controlType = 'Slider', sliderType = 'yOffset', setting = 'yOffset', section = 'Position', default = 0 },
            { controlType = 'ColorPicker', setting = 'Color', section = 'Icon', default = { r = 0, g = 1, b = 0, a = 1 } },
            { controlType = 'ColorPicker', setting = 'textColor', section = 'Text', default = { r = 1, g = 1, b = 1, a = 1 } },
            { controlType = 'Checkbox', setting = 'showText', text = 'Show Text', section = 'Text', default = false },
            { controlType = 'Checkbox', setting = 'showCooldown', text = 'Show Cooldown', section = 'Text', default = false }
        }
    },
    bar = {
        display = 'Bar',
        sections = {
            'Display',
            'Size',
            'Position'
        },
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', section = 'Display' },
            { controlType = 'ColorPicker', setting = 'Color', section = 'Display', default = { r = 0, g = 1, b = 0, a = 1 } },
            { controlType = 'ColorPicker', setting = 'BackgroundColor', section = 'Display', default = { r = 0, g = 0, b = 0, a = 1 } },
            { controlType = 'Dropdown', dropdownType = 'barPosition', setting = 'Position', section = 'Position', default = 'TOPRIGHT' },
            { controlType = 'Slider', sliderType = 'barSize', setting = 'barSize', section = 'Size', default = 15 },
            { controlType = 'Dropdown', dropdownType = 'barOrientation', setting = 'Orientation', section = 'Position', default = 'Horizontal' },
            { controlType = 'Dropdown', dropdownType = 'barScale', setting = 'Scale', section = 'Size', default = 'Full' },
            { controlType = 'Slider', sliderType = 'offset', setting = 'Offset', section = 'Position', default = 0 }
        }
    },
    border = {
        display = 'Border',
        sections = {
            'Display'
        },
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', section = 'Display' },
            { controlType = 'ColorPicker', setting = 'Color', section = 'Display', default = { r = 0, g = 1, b = 0, a = 1 } },
            { controlType = 'Slider', sliderType = 'borderWidth', setting = 'borderWidth', section = 'Display', default = 3 }
        }
    },
    healthColor = {
        display = 'Health Bar Color',
        sections = {
            'Display'
        },
        controls = {
            { controlType = 'SpellSelector', setting = 'Spell', section = 'Display' },
            { controlType = 'ColorPicker', setting = 'Color', section = 'Display', default = { r = 0, g = 1, b = 0, a = 1 } }
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
        key = 'buffIcons',
        type = 'checkbox',
        text = 'Hide Buff Icons',
        default = true,
        tooltip = 'Enable to remove the default buff icons on the raid frames.',
        func = 'ToggleBuffIcons'
    },
    --[[
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
    ]]
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
        text = 'Frame & Health Bar'
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
        key = 'extFrames',
        type = 'checkbox',
        text = 'Use Frame Addons',
        default = true,
        tooltip = 'Add Advanced Raid Frames indicators on top of other active frame addons.',
        func = 'Setup'
    },
    {
        key = 'toggleGroupTitles',
        type = 'checkbox',
        text = 'Show Group Titles',
        default = true,
        tooltip = 'Toggle the display of the group title when using separate groups in raids.',
        func = 'ToggleGroupTitles'
    },
    {
        key = 'raidFrameContainerScale',
        type = 'slider',
        text = 'Raid Container Scale',
        min = 0.4,
        max = 2,
        step = 0.1,
        default = 1,
        tooltip = 'Changes the size of the raid frames container.',
        func = 'ScaleRaidFrameContainer'
    },
    {
        key = 'partyFrameContainerScale',
        type = 'slider',
        text = 'Party Container Scale',
        min = 0.4,
        max = 2,
        step = 0.1,
        default = 1,
        tooltip = 'Changes the size of the party frames container.',
        func = 'ScalePartyFrameContainer'
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
        key = 'targetedSpellsHeader',
        type = 'header',
        text = 'Targeted Spells'
    },
    {
        key = 'enableTargetedSpells',
        type = 'checkbox',
        text = 'Enable Targeted Spells',
        default = false,
        tooltip = 'Targeted spells lets you see incoming enemy casts on friendly player frames.',
        func = 'TargetedSpells'
    },
    {
        key = 'targetedSpellsIconSize',
        text = 'Icon Size',
        type = 'slider',
        min = 10,
        max = 60,
        step = 1,
        default = 32,
        tooltip = 'Changes the size of the targeted spells icon.'
    },
    {
        key = 'targetedSpellsAnchor',
        type = 'dropdown',
        text = 'Icon Position',
        default = 'BOTTOM',
        items = {
            { text = 'Top Left', value = 'TOPLEFT' },
            { text = 'Top', value = 'TOP' },
            { text = 'Top Right', value = 'TOPRIGHT' },
            { text = 'Left', value = 'LEFT' },
            { text = 'Center', value = 'CENTER' },
            { text = 'Right', value = 'RIGHT' },
            { text = 'Bottom Left', value = 'BOTTOMLEFT' },
            { text = 'Bottom', value = 'BOTTOM' },
            { text = 'Bottom Right', value = 'BOTTOMRIGHT' }
        },
        tooltip = 'Pick the position in which the targeted spells icons will be anchored.'
    },
    {
        key = 'targetedSpellsXOffset',
        text = 'Horizontal Offset',
        type = 'slider',
        min = -100,
        max = 100,
        step = 1,
        default = 0,
        tooltip = 'Horizontal offset for the targeted spells icon.'
    },
    {
        key = 'targetedSpellsYOffset',
        text = 'Vertical Offset',
        type = 'slider',
        min = -100,
        max = 100,
        step = 1,
        default = 0,
        tooltip = 'Vertical offset for the targeted spells icon.'
    },
    {
        key = 'useSoftTarget',
        text = 'Use Soft Friendly Targeting',
        type = 'checkbox',
        default = true,
        tooltip = 'Soft Friend is an extra type of targeting that can be used to compare units, targeted spells uses this to make the comparisons more precise. Turning this off might make some casts harder to see but would resolve issues related to automatic targeting.'
    },
    {
        key = 'showTargetedSpellsPreview',
        text = 'Preview Targeted Spells',
        content = 'Show Example',
        tooltip = 'Show a quick example of how the targeted spells will be displayed on the party frames.',
        type = 'button',
        func = 'ShowTargetedSpellsPreview'
    },
    {
        key = 'extraFramesHeader',
        type = 'header',
        text = 'Extra Frames',
        tooltip = 'Options for external frames controlled by HARF'
    },
    {
        key = 'enableSpotlight',
        type = 'checkbox',
        text = 'Enable Spotlight',
        default = false,
        tooltip = 'Enable the Spotlight feature to separate specific players into their own groups.',
    },
    {
        key = 'spotlightFrameScale',
        type = 'slider',
        text = 'Spotlight Frame Scale',
        min = 0.4,
        max = 2,
        step = 0.1,
        default = 1,
        tooltip = 'Changes the size of the unit frames in the spotlight.',
        func = 'Setup'
    },
    --[[
    {
        key = 'enableFriendlyBossFrames',
        type = 'checkbox',
        text = 'Enable Friendly Boss Frames',
        default = false,
        tooltip = 'Enable the Friendly Boss Frames feature to have custom unit frames for healable npcs.'
    },
    ]]
    {
        key = 'miscHeader',
        type = 'header',
        text = 'Misc.'
    },
    {
        key = 'debugMode',
        type = 'checkbox',
        text = 'Debug Mode',
        default = false,
        tooltip = 'Enable debug mode.'
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

Data.targetedSpellsUnits = {
    players = {'player', 'party1', 'party2', 'party3', 'party4'},
    tokens = {'focus', 'mouseover', 'softfriend', 'player'}
}

Data.targetedSpellsEvents = {
    casts = {
        'UNIT_SPELLCAST_START',
        'UNIT_SPELLCAST_CHANNEL_START',
        'UNIT_SPELLCAST_INTERRUPTED',
        'UNIT_SPELLCAST_STOP',
        'UNIT_SPELLCAST_CHANNEL_STOP',
        'UNIT_SPELLCAST_FAILED_QUIET'
    },
    targeting = {
        'PLAYER_SOFT_FRIEND_CHANGED',
        'UPDATE_MOUSEOVER_UNIT'
    }
}

Data.auraContainerSettings = {
    container = {
        unitToken = nil,
        auraIndex = 1,
        parent = nil,
        showCountdownFrame = true,
        showCountdownNumbers = false,
        isContainer = true,
        iconInfo = {
            iconAnchor = {
                point = "BOTTOMLEFT",
                relativeTo = nil,
                relativePoint = "BOTTOMLEFT",
                offsetX = 0,
                offsetY = 0,
            },
            iconWidth = nil,
            iconHeight = nil,
            borderScale = nil,
        },
        durationAnchor = nil,
    },
    attributes = {
        'max-debuffs',
        'max-dispel-debuffs',
        'ignore-debuffs',
        'always-hide-duration',
        'show-dispel-indicator-overlay',
        'suppress-dispel-border-icons',
        'aura-organization-type',
        'set-aura-size-to-icon-size',
        'show-big-defensive',
        'big-defensive-size',
        'power-bar-used-height',
        'group-type',
        'display-larger-role-specific-debuffs',
        'dispel-indicator-option',
        'display-only-dispellable-debuffs',
    },
}

local LAMB = NS.LibAdvancedMenuBuilder
Data.barTextures = LAMB.barTextures
Data.registeredFrameStyle = false
Data.lastModify = 0
Data.optionSections = {}
--Player spec is checked constantly through the run to make sure we're using appropriate data
Data.playerSpec = nil
Data.auraSignatures = {}
Data.allowedAuraClear = false
Data.hpStatusOptions = {
    losthealth = '[missinghp]',
    health = '[curhp]',
    perc = '[perhp]%',
    none = ''
}