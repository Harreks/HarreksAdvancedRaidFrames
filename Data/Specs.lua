local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local API = NS.API
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--All the data about spec buffs we could possibly need
--Most of this isn't needed as of the great Midnight de-secreting but i still keep it just in case
--Added extra parameters to parse only some of the auras so i can keep tracking some secret stuff
Data.specInfo = {
    PreservationEvoker = {
        display = 'Preservation Evoker',
        class = 'EVOKER',
        auras = {
            [364343] = { name = 'Echo', signature = '1:1:0:0' },
            [366155] = { name = 'Reversion', signature = '1:1:0:1' },
            [367364] = { name = 'EchoReversion', signature = '0:1:0:1' },
            [355941] = { name = 'DreamBreath', signature = '0:1:0:0' },
            [376788] = { name = 'EchoDreamBreath', signature = '0:1:0:0' },
            [357170] = { name = 'TimeDilation', signature = '1:1:1:0', secret = true },
            [363534] = { name = 'Rewind', signature = '1:1:0:0', secret = true },
            [363502] = { name = 'DreamFlight', signature = '0:1:0:0' },
            [373267] = { name = 'Lifebind', signature = '0:1:0:0' },
            [409895] = { name = 'VerdantEmbrace', signature = '0:1:0:0', secret = true },
        },
        casts = {
            [364343] = { 'Echo' },
            [366155] = { 'Reversion' },
            [357170] = { 'TimeDilation' },
            [363534] = { 'Rewind' },
            [360995] = { 'Lifebind', 'VerdantEmbrace' }
        },
        empowers = {
            [355936] = 'DreamBreath',
            [382614] = 'DreamBreath',
            [357208] = 'FireBreath',
            [382266] = 'FireBreath'
        },
        tts = 370553
    },
    AugmentationEvoker = {
        display = 'Augmentation Evoker',
        class = 'EVOKER',
        auras = {
            [410089] = { name = 'Prescience', signature = '0:1:0:0' },
            [413984] = { name = 'ShiftingSands', signature = '0:1:0:0' },
            [360827] = { name = 'BlisteringScales', signature = '1:1:0:0' },
            [410263] = { name = 'InfernosBlessing', signature = '0:1:0:0' },
            [410686] = { name = 'SymbioticBloom', signature = '0:1:0:0' },
            [395152] = { name = 'EbonMight', signature = '' },
            [0] = { name = 'SensePower', signature = '' },
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
            [33763] = { name = 'Lifebloom', signature = '1:1:0:1' },
            [774] = { name = 'Rejuvenation', signature = '1:1:0:1' },
            [8936] = { name = 'Regrowth', signature = '1:1:0:1' },
            [155777] = { name = 'Germination', signature = '0:1:0:1' },
            [48438] = { name = 'WildGrowth', signature = '1:1:0:1' },
            [102342] = { name = 'IronBark', signature = '1:1:1:0', secret = true },
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
            [17] = { name = 'PowerWordShield', signature = '1:1:0:1' },
            [194384] = { name = 'Atonement', signature = '0:1:0:0' },
            [33206] = { name = 'PainSuppression', signature = '1:1:1:0', secret = true },
            [1253593] = { name = 'VoidShield', signature = '' },
            [41635] = { name = 'PrayerOfMending', signature = '0:1:0:1' },
            [10060] = { name = 'PowerInfusion', signature = '1:0:0:1', secret = true },
        },
        casts = {
            [17] = { 'Atonement', 'PowerWordShield', 'PrayerOfMending' }, --PW: Shield
            [47540] = { 'Atonement' }, --Penance
            [200829] = { 'Atonement' }, --Plea
            [194509] = { 'Atonement' }, --Radiance
            [2061] = { 'Atonement' }, --Flash Heal
            [1252215] = { 'Atonement' }, --Shadow Mend
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
            [139] = { name = 'Renew', signature = '0:1:0:1' },
            [77489] = { name = 'EchoOfLight', signature = '0:1:0:0' },
            [47788] = { name = 'GuardianSpirit', signature = '1:1:1:0', secret = true },
            [41635] = { name = 'PrayerOfMending', signature = '0:1:0:1' },
            [10060] = { name = 'PowerInfusion', signature = '1:0:0:1', secret = true },
        },
        casts = {
            [2061] = { 'Renew' }, --Flash Heal
            [34861] = { 'Renew', 'EchoOfLight' }, --Sanctify
            [2050] = { 'Renew', 'EchoOfLight' }, --Serenity
            [120517] = { 'EchoOfLight' }, --Halo
            [132157] = { 'EchoOfLight' }, --Holy Nova
            [596] = { 'EchoOfLight' }, --Prayer of Healing
            [47788] = { 'GuardianSpirit' },
            [33076] = { 'PrayerOfMending', 'EchoOfLight' }, --PoM cast
            [64843] = { 'PrayerOfMending', 'EchoOfLight' }, --Hymn
            [10060] = { 'PowerInfusion' }
        },
    },
    MistweaverMonk = {
        display = 'Mistweaver Monk',
        class = 'MONK',
        auras = {
            [119611] = { name = 'RenewingMist', signature = '0:1:0:1' },
            [124682] = { name = 'EnvelopingMist', signature = '1:1:0:1' },
            [115175] = { name = 'SoothingMist', signature = '1:1:0:0' },
            [116849] = { name = 'LifeCocoon', signature = '1:1:1:0', secret = true },
            [450769] = { name = 'AspectOfHarmony', signature = '0:1:0:0' },
            [443113] = { name = 'StrengthOfTheBlackOx', signature = '0:1:0:1', secret = true }, --TODO fix this match
            [406139] = { name = 'ChiCocoon', signature = '0:1:0:1', secret = true }
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
            [61295] = { name = 'Riptide', signature = '1:1:0:1' },
            [974] = { name = 'EarthShield', signature = '1:1:0:1' },
            [383648] = { name = 'EarthShield', signature = '1:1:0:1', hide = true }
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
            [156910] = { name = 'BeaconOfFaith', signature = '1:1:0:0' },
            [156322] = { name = 'EternalFlame', signature = '1:1:0:1' },
            [53563] = { name = 'BeaconOfLight', signature = '1:1:0:0' },
            [1022] = { name = 'BlessingOfProtection', signature = '1:1:1:1', secret = true },
            --[432496] = { name = 'HolyBulwark', signature = '0:1:0:0', secret = true },
            --[432502] = { name = 'SacredWeapon', signature = '0:1:0:0', secret = true },
            [432502] = { name = 'HolyArmaments', signature = '0:1:0:0', secret = true }, --Both armaments look the same, we combine them to make my life easier
            [6940] = { name = 'BlessingOfSacrifice', signature = '1:1:1:0', secret = true },
            [1044] = { name = 'BlessingOfFreedom', signature = '1:0:0:1', secret = true },
            [200025] = { name = 'BeaconOfVirtue', signature = '1:0:0:0', secret = true },
            [1244893] = { name = 'BeaconOfTheSavior', signature = '' },
            [431381] = { name = 'Dawnlight', signature = '0:1:0:0', secret = true }
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

--Each spec has a specific id, combined with the class token we can know what spec we're using without worrying about language
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