local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local API = NS.API
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

local CLASS_ID_BY_TOKEN = {
    WARRIOR = 1,
    PALADIN = 2,
    HUNTER = 3,
    ROGUE = 4,
    PRIEST = 5,
    DEATHKNIGHT = 6,
    SHAMAN = 7,
    MAGE = 8,
    WARLOCK = 9,
    MONK = 10,
    DRUID = 11,
    DEMONHUNTER = 12,
    EVOKER = 13,
}

Data.specInfo = {
    PreservationEvoker = {
        display = 'Preservation Evoker',
        class = 'EVOKER',
        auras = {
            Echo = { points = 2, raid = true, ric = true, ext = false, disp = false }, -- ID: 364343
            Reversion = { points = 3, raid = true, ric = true, ext = false, disp = true }, -- ID: 366155
            EchoReversion = { points = 3, raid = false, ric = true, ext = false, disp = true }, -- ID: 367364
            DreamBreath = { points = 3, raid = false, ric = true, ext = false, disp = false }, -- ID: 355941
            EchoDreamBreath = { points = 3 - 4 , raid = false, ric = true, ext = false, disp = false }, -- ID: 376788
            TimeDilation = { points = 2, raid = true, ric = true, ext = true, disp = false }, -- ID: 357170
            Rewind = { points = 4, raid = true, ric = true, ext = false, disp = false }, -- ID: 363534
            DreamFlight = { points = 2, raid = false, ric = true, ext = false, disp = false }, -- ID: 363502
            --DreamFlightSelf = { points = 9, raid = true, ric = false, ext = false, disp = false }, -- ID: 359816
            Lifebind = { points = 1 - 2, raid = false, ric = true, ext = false, disp = false }, -- ID: 373267
            VerdantEmbrace = { points = 1, raid = false, ric = true, ext = false, disp = false }, -- ID: 409895
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
            Prescience = { points = 3, raid = false, ric = true, ext = false, disp = false }, -- ID: 410089
            ShiftingSands = { points = 2, raid = false, ric = true, ext = false, disp = false }, -- ID: 413984
            BlisteringScales = { points = 2, raid = true, ric = true, ext = false, disp = false }, -- ID: 360827
            InfernosBlessing = { points = 0, raid = false, ric = true, ext = false, disp = false }, -- ID: 410263
            SymbioticBloom = { points = 1, raid = false, ric = true, ext = false, disp = false }, -- ID: 410686
            EbonMight = { points = 3, raid = true, ric = true, ext = false, disp = false }, -- ID: 395152
            SensePower = { points = 0, raid = false, ric = false, ext = false, disp = false }, -- ID: 0
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
            Lifebloom = { points = 1 - 2, raid = true, ric = true, ext = false, disp = true }, -- ID: 33763
            Rejuvenation = { points = 1, raid = true, ric = true, ext = false, disp = true }, -- ID: 774
            Regrowth = { points = 3, raid = true, ric = true, ext = false, disp = true }, -- ID: 8936
            Germination = { points = 1, raid = false, ric = true, ext = false, disp = true }, -- ID: 155777
            WildGrowth = { points = 2, raid = true, ric = true, ext = false, disp = true }, -- ID: 48438
            IronBark = { points = 2, raid = true, ric = true, ext = true, disp = false }, -- ID: 102342
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
            PowerWordShield = { points = 2, raid = true, ric = true, ext = false, disp = true }, -- ID: 17
            Atonement = { points = 0, raid = false, ric = true, ext = false, disp = false }, -- ID: 194384
            PainSuppression = { points = 0, raid = true, ric = true, ext = true, disp = false }, -- ID: 33206
            VoidShield = { points = 3, raid = false, ric = true, ext = false, disp = true }, -- ID: 1253593
            PrayerOfMending = { points = 1, raid = false, ric = true, ext = false, disp = true }, -- ID: 41635
            PowerInfusion = { points = 2, raid = true, ric = false, ext = false, disp = true }, -- ID: 10060
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
            Renew = { points = 2, raid = false, ric = true, ext = false, disp = true }, -- ID: 139
            EchoOfLight = { points = 1, raid = false, ric = true, ext = false, disp = false }, -- ID: 77489
            GuardianSpirit = { points = 3, raid = true, ric = true, ext = true, disp = false }, -- ID: 47788
            PrayerOfMending = { points = 1, raid = false, ric = true, ext = false, disp = true }, -- ID: 41635
            PowerInfusion = { points = 2, raid = true, ric = false, ext = false, disp = true }, -- ID: 10060
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
            RenewingMist = { points = 2, raid = false, ric = true, ext = false, disp = true }, -- ID: 119611
            EnvelopingMist = { points = 3, raid = true, ric = true, ext = false, disp = true }, -- ID: 124682
            SoothingMist = { points = 3, raid = true, ric = true, ext = false, disp = false }, -- ID: 115175
            LifeCocoon = { points = 3, raid = true, ric = true, ext = true, disp = false }, -- ID: 116849
            AspectOfHarmony = { points = 2, raid = false, ric = true, ext = false, disp = false }, -- ID: 450769
            StrengthOfTheBlackOx = { points = 3, raid = false, ric = true, ext = false, disp = true } -- ID: 443113
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
            Riptide = { points = 2, raid = true, ric = true, ext = false, disp = true }, -- ID: 61295
            EarthShield = { points = 3, raid = false, ric = true, ext = false, disp = true }, -- ID: 383648
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
            BeaconOfFaith = { points = 7, raid = true, ric = true, ext = false, disp = false }, -- ID: 156910
            EternalFlame = { points = 3, raid = true, ric = true, ext = false, disp = true }, -- ID: 156322
            BeaconOfLight = { points = 6, raid = true, ric = true, ext = false, disp = false }, -- ID: 53563
            BlessingOfProtection = { points = 0, raid = true, ric = true, ext = true, disp = true }, -- ID: 1022
            HolyBulwark = { points = 5 - 6, raid = false, ric = true, ext = false, disp = false }, -- ID: 432496
            SacredWeapon = { points = 5, raid = false, ric = true, ext = false, disp = false }, -- ID: 432502
            BlessingOfSacrifice = { points = 9, raid = true, ric = true, ext = true, disp = false }, -- ID: 6940
            BeaconOfVirtue = { points = 4, raid = true, ric = false, ext = false, disp = false }, -- ID: 200025
            BeaconOfTheSavior = { points = 7, raid = false, ric = true, ext = false, disp = false }, -- ID: 1244893
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

local function BuildSpecApiMapping()
    for mapKey, specKey in pairs(Data.specMap) do
        local classToken, specIndex = string.match(mapKey, '^(%u+)_(%d+)$')
        local specData = Data.specInfo[specKey]

        if classToken and specIndex and specData then
            specData.specIndex = tonumber(specIndex)
            specData.classID = CLASS_ID_BY_TOKEN[classToken] or CLASS_ID_BY_TOKEN[specData.class]
        end
    end
end

BuildSpecApiMapping()

function Data.GetLocalizedSpecDisplay(specKey)
    local specData = specKey and Data.specInfo and Data.specInfo[specKey]
    if not specData then
        return specKey
    end

    if GetSpecializationInfoForClassID and specData.classID and specData.specIndex then
        local specID, name = GetSpecializationInfoForClassID(specData.classID, specData.specIndex)
        if specID and not specData.specID then
            specData.specID = specID
        end
        if name and name ~= '' then
            return name
        end
    end

    if GetSpecializationNameForSpecID and specData.specID then
        local localizedName = GetSpecializationNameForSpecID(specData.specID)
        if localizedName and localizedName ~= '' then
            return localizedName
        end
    end

    return specData.display or specKey
end