local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core
local Settings = NS.Settings

--Initialize default data
Data.gameVersion = select(4, GetBuildInfo())
Data.currentLayout = nil
Data.unitFrameMap = {}
Data.playerClass = nil
Data.allowedCastDelay = 0.25
Data.buffFilter = 'PLAYER|HELPFUL|RAID_IN_COMBAT'
Data.supportedBuffTracking = {
    --[[
    Riptide
    Earth Shield
    ]]
    SHAMAN = {
        spell = 'Riptide',
        utility = {
            earthShield = nil,
            activeAuras = {}
        }
    },
    --[[
    Echo
    Reversion (both)
    Dream Breath (both)
    Time Dilation
    ]]
    EVOKER = {
        spell = 'Echo',
        utility = {
            filteredSpellTimestamp = nil,
            filteredSpells = {
                [366155] = true,
                [357170] = true,
                [1256581] = true,
                [360995] = true
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
    --[[
    Atonement
    Pain Suppression
    Power Word: Shield
    Void Shield
    ]]
    PRIEST = {
        spell = 'Atonement',
        utility = {
            isDisc = false,
            filteredSpellTimestamp = nil,
            filteredSpells = {
                [33206] = true
            },
            filteredBuffs = {},
            activeAuras = {}
        }
    }
}

Data.dandersColors = {}

Data.spotlightAnchors = {
    spotlights = {},
    defaults = {}
}

Data.defaultSettings = {
    clickThroughBuffs = true,
    buffIcons = 6,
    debuffIcons = 3,
    frameTransparency = false,
    nameScale = 1,
    colorNames = false,
    buffTracking = false,
    trackingType = 'icon',
    trackingColor = { r = 0, g = 1, b = 0 },
    dandersCompat = false,
    spotlight = {
        point = 'CENTER',
        x = 0,
        y = 0,
        grow = 'right',
        names = {}
    }
}

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

--Build a list of strings that match the default frame elements
Data.frameList = { party = {}, raid = {} }
for i = 1, 30 do
    local partyFrame, raidFrame
    if i <= 5 then
        partyFrame = 'CompactPartyFrameMember' .. i
        Data.frameList.party[partyFrame] = {
            buffs = {},
            debuffs = {},
            name = partyFrame .. 'Name',
            centerIcon = partyFrame .. 'CenterStatusIcon',
            isColored = false,
            defensive = { type = 'defensive', frame = partyFrame }
        }
    end
    raidFrame = 'CompactRaidFrame' .. i
    Data.frameList.raid[raidFrame] = {
        buffs = {},
        debuffs = {},
        name = raidFrame .. 'Name',
        centerIcon = raidFrame .. 'CenterStatusIcon',
        isColored = false,
        defensive = { type = 'defensive', frame = raidFrame }
    }
    for j = 1, 6 do
        if j <= 3 then
            if partyFrame then
                Data.frameList.party[partyFrame].debuffs[j] = partyFrame .. 'Debuff' .. j
            end
            Data.frameList.raid[raidFrame].debuffs[j] = raidFrame .. 'Debuff' .. j
        end
        if partyFrame then
            Data.frameList.party[partyFrame].buffs[j] = partyFrame .. 'Buff' .. j
        end
        Data.frameList.raid[raidFrame].buffs[j] = raidFrame .. 'Buff' .. j
    end
end
