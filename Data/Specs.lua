local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--[[
spells that are in raid but not in raidincombat:
TODO: check every single one of these, rework gen function to check for them (massive gains)
- beacon of virtue

spells in raidincombat but not in raid
- germination
- Power infusion
]]

Data.specInfo = {
    PreservationEvoker = {
        display = 'Preservation Evoker',
        class = 'EVOKER',
        auras = {
            Echo = 2,
            Reversion = 3,
            EchoReversion = 3,
            DreamBreath = 3,
            EchoDreamBreath = 3,
            TimeDilation = 2,
            Rewind = 4,
            DreamFlight = 2,
        },
        casts = {
            [364343] = { 'Echo' },
            [366155] = { 'Reversion' },
            [357170] = { 'TimeDilation' },
            [363534] = { 'Rewind' }
        },
        empowers = {
            [355936] = 'DreamBreath',
            [382614] = 'DreamBreath',
            [357208] = 'FireBreath',
            [382266] = 'FireBreath'
        },
        tts = 370553,
        df = 359816
    },
    AugmentationEvoker = {
        display = 'Augmentation Evoker',
        class = 'EVOKER',
        auras = {
            Prescience = 3,
            ShiftingSands = 2,
            BlisteringScales = 2,
            InfernosBlessing = 0,
            SymbioticBloom = 1,
            EbonMight = 3,
            SensePower = 0
        },
        casts = {
            [409311] = { 'Prescience' },
            Upheaval = { 'ShiftingSands' },
            Firebreath = { 'ShiftingSands', 'InfernosBlessing' },
            [395152] = { 'EbonMight' }
        },
        empowers = {
            [396286] = 'Upheaval',
            [408092] = 'Upheaval',
            [357208] = 'Firebreath',
            [382266] = 'Firebreath'
        },
        spec = 0,
    },
    RestorationDruid = {
        display = 'Restoration Druid',
        class = 'DRUID',
        auras = {
            Rejuvenation = 1,
            Regrowth = 3,
            Lifebloom = 1,
            Germination = 1,
            WildGrowth = 2,
            IronBark = 2
        },
        casts = {
            [774] = { 'Rejuvenation', 'Germination' },
            [8936] = { 'Regrowth' },
            [33763] = { 'Lifebloom' },
            [48438] = { 'WildGrowth' },
            [102342] = { 'IronBark' },
        },
        convoke = 391528
    },
    DisciplinePriest = {
        display = 'Discipline Priest',
        class = 'PRIEST',
        auras = {
            PowerWordShield = 2,
            Atonement = 0,
            PainSuppression = 0,
            VoidShield = 3,
            PrayerOfMending = 1,
            PowerInfusion = 2
        },
        casts = {
            [17] = { 'Atonement', 'PowerWordShield', 'PrayerOfMending' }, --PW: Shield
            [47540] = { 'Atonement' }, --Penance
            [200829] = { 'Atonement' }, --Plea
            [194509] = { 'Atonement' }, --Radiance
            [33206] = { 'PainSuppression' },
            [1253593] = { 'Atonement', 'VoidShield' },
            [10060] = { 'PowerInfusion' }
        },
        pi = 10060
    },
    HolyPriest = {
        display = 'Holy Priest',
        class = 'PRIEST',
        auras = {
            Renew = 2,
            EchoOfLight = 1,
            GuardianSpirit = 3,
            PrayerOfMending = 1,
            PowerInfusion = 2
        },
        casts = {
            --Holy Priest is pending (they dont care (noobs))
            --[[
            [0] = { 'Renew' },
            [1] = { 'EchoOfLight' },
            ]]
            [47788] = { 'GuardianSpirit' },
            [33076] = { 'PrayerOfMending' },
            [10060] = { 'PowerInfusion' }
        },
    },
    MistweaverMonk = {
        display = 'Mistweaver Monk',
        class = 'MONK',
        auras = {
            RenewingMist = 2,
            EnvelopingMist = 3,
            SoothingMist = 3,
            LifeCocoon = 3,
            AspectOfHarmony = 2
        },
        casts = {
            [124682] = { 'EnvelopingMist', 'RenewingMist' },
            [115151] = { 'RenewingMist' },
            [107428] = { 'RenewingMist' },
            [115175] = { 'SoothingMist' },
            [116670] = { 'AspectOfHarmony' },
            [399491] = { 'AspectOfHarmony' }
        },
        spec = 0,
    },
    RestorationShaman = {
        display = 'Restoration Shaman',
        class = 'SHAMAN',
        auras = {
            Riptide = 2,
            EarthShield = 3
        },
        casts = {
            [61295] = { 'Riptide' },
            [974] = { 'EarthShield' }
        },
        spec = 0,
    },
    HolyPaladin = {
        display = 'Holy Paladin',
        class = 'PALADIN',
        auras = {
            BeaconOfFaith = 7,
            EternalFlame = 3,
            BeaconOfLight = 6,
            BlessingOfProtection = 0,
            HolyBulwark = 5,
            SacredWeapon = 5,
            BlessingOfSacrifice = 9,
            BeaconOfVirtue = 4,
            BeaconOfTheSavior = 7
        },
        casts = {
            [156910] = { 'BeaconOfFaith' },
            [156322] = { 'EternalFlame' },
            [53563] = { 'BeaconOfLight' },
            [1022] = { 'BlessingOfProtection' },
            [432472] = { 'HolyBulwark', 'SacredWeapon' },
            [6940] = { 'BlessingOfSacrifice' },
            [200025] = { 'BeaconOfVirtue' }
        },
        virtue = 200025,
        armaments = 432472,
        icons = { bulwark = 5927636, weapon = 5927637 }
    },
}

Data.specMap = {
    DRUID_4 = 'RestorationDruid',
    SHAMAN_3 = 'RestorationShaman',
    PRIEST_1 = 'DisciplinePriest',
    PRIEST_2 = 'HolyPriest',
    PALADIN_1 = 'HolyPaladin',
    EVOKER_2 = 'PreservationEvoker',
    EVOKER_3 = 'AugmentationEvoker',
    MONK_2 = 'MistweaverMonk'
}