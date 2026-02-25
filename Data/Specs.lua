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
            [364343] = { name = 'Echo', raid = true, ric = true, ext = false, disp = false },
            [366155] = { name = 'Reversion', raid = true, ric = true, ext = false, disp = true },
            [367364] = { name = 'EchoReversion', raid = false, ric = true, ext = false, disp = true },
            [355941] = { name = 'DreamBreath', raid = false, ric = true, ext = false, disp = false },
            [376788] = { name = 'EchoDreamBreath', raid = false, ric = true, ext = false, disp = false },
            [357170] = { name = 'TimeDilation', raid = true, ric = true, ext = true, disp = false, secret = true },
            [363534] = { name = 'Rewind', raid = true, ric = true, ext = false, disp = false, secret = true },
            [363502] = { name = 'DreamFlight', raid = false, ric = true, ext = false, disp = false },
            [373267] = { name = 'Lifebind', raid = false, ric = true, ext = false, disp = false },
            [409895] = { name = 'VerdantEmbrace', raid = false, ric = true, ext = false, disp = false, secret = true },
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
            [410089] = { name = 'Prescience', points = 3, raid = false, ric = true, ext = false, disp = false },
            [413984] = { name = 'ShiftingSands', points = 2, raid = false, ric = true, ext = false, disp = false },
            [360827] = { name = 'BlisteringScales', points = 2, raid = true, ric = true, ext = false, disp = false },
            [410263] = { name = 'InfernosBlessing', points = 0, raid = false, ric = true, ext = false, disp = false },
            [410686] = { name = 'SymbioticBloom', points = 1, raid = false, ric = true, ext = false, disp = false },
            [395152] = { name = 'EbonMight', points = 3, raid = true, ric = true, ext = false, disp = false },
            [0] = { name = 'SensePower', points = 0, raid = false, ric = false, ext = false, disp = false },
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
            [33763] = { name = 'Lifebloom', raid = true, ric = true, ext = false, disp = true },
            [774] = { name = 'Rejuvenation', raid = true, ric = true, ext = false, disp = true },
            [8936] = { name = 'Regrowth', raid = true, ric = true, ext = false, disp = true },
            [155777] = { name = 'Germination', raid = false, ric = true, ext = false, disp = true },
            [48438] = { name = 'WildGrowth', raid = true, ric = true, ext = false, disp = true },
            [102342] = { name = 'IronBark', raid = true, ric = true, ext = true, disp = false },
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
            [17] = { name = 'PowerWordShield', points = 2, raid = true, ric = true, ext = false, disp = true },
            [194384] = { name = 'Atonement', points = 0, raid = false, ric = true, ext = false, disp = false },
            [33206] = { name = 'PainSuppression', points = 0, raid = true, ric = true, ext = true, disp = false },
            [1253593] = { name = 'VoidShield', points = 3, raid = false, ric = true, ext = false, disp = true },
            [41635] = { name = 'PrayerOfMending', points = 1, raid = false, ric = true, ext = false, disp = true },
            [10060] = { name = 'PowerInfusion', points = 2, raid = true, ric = false, ext = false, disp = true },
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
            [139] = { name = 'Renew', points = 2, raid = false, ric = true, ext = false, disp = true },
            [77489] = { name = 'EchoOfLight', points = 1, raid = false, ric = true, ext = false, disp = false },
            [47788] = { name = 'GuardianSpirit', points = 3, raid = true, ric = true, ext = true, disp = false },
            [41635] = { name = 'PrayerOfMending', points = 1, raid = false, ric = true, ext = false, disp = true },
            [10060] = { name = 'PowerInfusion', points = 2, raid = true, ric = false, ext = false, disp = true },
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
            [119611] = { name = 'RenewingMist', raid = false, ric = true, ext = false, disp = true },
            [124682] = { name = 'EnvelopingMist', raid = true, ric = true, ext = false, disp = true },
            [115175] = { name = 'SoothingMist', raid = true, ric = true, ext = false, disp = false },
            [116849] = { name = 'LifeCocoon', raid = true, ric = true, ext = true, disp = false },
            [450769] = { name = 'AspectOfHarmony', raid = false, ric = true, ext = false, disp = false },
            [443113] = { name = 'StrengthOfTheBlackOx', raid = false, ric = true, ext = false, disp = true },
            [406139] = { name = 'ChiCocoon', raid = false, ric = true, ext = false, disp = true }
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
            [61295] = { name = 'Riptide', points = 2, raid = true, ric = true, ext = false, disp = true },
            [383648] = { name = 'EarthShield', points = 3, raid = false, ric = true, ext = false, disp = true },
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
            [156910] = { name = 'BeaconOfFaith', points = 7, raid = true, ric = true, ext = false, disp = false },
            [156322] = { name = 'EternalFlame', points = 3, raid = true, ric = true, ext = false, disp = true },
            [53563] = { name = 'BeaconOfLight', points = 6, raid = true, ric = true, ext = false, disp = false },
            [1022] = { name = 'BlessingOfProtection', points = 0, raid = true, ric = true, ext = true, disp = true },
            [432496] = { name = 'HolyBulwark', points = 5 - 6, raid = false, ric = true, ext = false, disp = false },
            [432502] = { name = 'SacredWeapon', points = 5, raid = false, ric = true, ext = false, disp = false },
            [6940] = { name = 'BlessingOfSacrifice', points = 9, raid = true, ric = true, ext = true, disp = false },
            [200025] = { name = 'BeaconOfVirtue', points = 4, raid = true, ric = false, ext = false, disp = false },
            [1244893] = { name = 'BeaconOfTheSavior', points = 7, raid = false, ric = true, ext = false, disp = false },
            [431381] = { name = 'Dawnlight', raid = false, ric = true, ext = false, disp = false }
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
        local classInfo = C_CreatureInfo.GetClassInfo(specData.classID)
        if specID and not specData.specID then
            specData.specID = specID
        end
        if name and name ~= '' and classInfo and classInfo.className then
            return name .. ' ' .. classInfo.className
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