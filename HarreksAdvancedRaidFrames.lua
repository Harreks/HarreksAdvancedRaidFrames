--[[----------------------------------
    Utilities
------------------------------------]]

--Initialize default data
local gameVersion = select(4, GetBuildInfo())
local currentLayout = nil
local unitFrameMap = {}
local playerClass = nil
local supportedBuffTracking = {
    SHAMAN = {
        spell = 'Riptide',
        utility = {
            earthShield = nil
        }
    },
    EVOKER = {
        spell = 'Echo',
        utility = {
            filteredSpellTimestamp = nil,
            filteredSpells = {
                [366155] = true,
                [1256581] = true,
                [374227] = true,
                [369459] = true
            },
            filteredBuffs = {}
        }
    },
    PRIEST = {
        spell = 'Atonement',
        utility = {
            isDisc = false,
            filteredSpellTimestamp = nil,
            filteredSpells = {}
        }
    }
}
local defaultSettings = {
    clickThroughBuffs = true,
    buffIcons = 6,
    debuffIcons = 3,
    frameTransparency = false,
    nameScale = 1,
    colorNames = false,
    buffTracking = false,
    trackingType = 'icon',
    trackingColor = { r = 0, g = 1, b = 0 }
}

--Function to format decimals out for display
local function formatForDisplay(number)
    return math.floor(number * 10 + 0.5) / 10
end

--The addon uses some tables to keep track of unit frames and specific auras, every now and then we empty these tables to remove irrelevant data
--Currently this happens when we remap out frames to new units after a roster update, as the info is tied to a specific player occupying a specific frame
local function CleanUtilityTables()
    unitFrameMap = {}
    supportedBuffTracking.EVOKER.utility.filteredBuffs = {}
end

--Build a list of strings that match the default frame elements
local frameList = { party = {}, raid = {} }
for i = 1, 30 do
    local partyFrame, raidFrame
    if i <= 5 then
        partyFrame = 'CompactPartyFrameMember' .. i
        frameList.party[partyFrame] = {
            buffs = {},
            debuffs = {},
            name = partyFrame .. 'Name',
            centerIcon = partyFrame .. 'CenterStatusIcon',
            defensive = { type = 'defensive', frame = partyFrame }
        }
    end
    raidFrame = 'CompactRaidFrame' .. i
    frameList.raid[raidFrame] = {}
    frameList.raid[raidFrame] = {
        buffs = {},
        debuffs = {},
        name = raidFrame .. 'Name',
        centerIcon = raidFrame .. 'CenterStatusIcon',
        defensive = { type = 'defensive', frame = raidFrame }
    }
    for j = 1, 6 do
        if j <= 3 then
            if partyFrame then
                frameList.party[partyFrame].debuffs[j] = partyFrame .. 'Debuff' .. j
            end
            frameList.raid[raidFrame].debuffs[j] = raidFrame .. 'Debuff' .. j
        end
        if partyFrame then
            frameList.party[partyFrame].buffs[j] = partyFrame .. 'Buff' .. j
        end
        frameList.raid[raidFrame].buffs[j] = raidFrame .. 'Buff' .. j
    end
end

--[[----------------------------------
    Core Functions
------------------------------------]]

--Return the list of raid frames depending on raid or party
local function GetRelevantList()
    return IsInRaid() and frameList.raid or frameList.party
end

--Takes a string, checks global table for frame with that name and changes mouse interaction on it
local function ChangeFrameMouseInteraction(frameString, value)
    local frame
    --Special handling for the center defensive because it doesn't have a direct name to access
    if type(frameString) == 'table' and frameString.type and frameString.type == 'defensive' then
        if _G[frameString.frame] and _G[frameString.frame].CenterDefensiveBuff then
            frame = _G[frameString.frame].CenterDefensiveBuff
        end
    else
        if _G[frameString] then
            frame = _G[frameString]
        end
    end
    if frame and frame:IsMouseEnabled() ~= value then
        frame:EnableMouse(value)
    end
end

--Hides elements by changing opacity
local function ToggleTransparency(frameString, shouldShow)
    if _G[frameString] then
        if shouldShow then
            _G[frameString]:SetAlpha(1)
        else
            _G[frameString]:SetAlpha(0)
        end
    end
end

--Toggles mouse interaction on raid frame icons, pass true for enabled and false for disabled, third param is the elements of the edited frame
local function ToggleAurasMouseInteraction(value, _, elements)
    for _, buff in ipairs(elements.buffs) do
        ChangeFrameMouseInteraction(buff, value)
    end
    for _, debuff in ipairs(elements.debuffs) do
        ChangeFrameMouseInteraction(debuff, value)
    end
    ChangeFrameMouseInteraction(elements.centerIcon, value)
    ChangeFrameMouseInteraction(elements.defensive, value)
end

--Controls visibility on buff icons, takes how many buffs are to be shown and the element list of the frame to be modified
local function ToggleBuffIcons(amount, _, elements)
    for i = 1, 6 do
        if i <= amount then
            ToggleTransparency(elements.buffs[i], true)
            if _G[elements.buffs[i]] and not _G[elements.buffs[i]]:IsMouseEnabled() and not HARFDB[currentLayout].clickThroughBuffs then
                ChangeFrameMouseInteraction(elements.buffs[i], true)
            end
        else
            ToggleTransparency(elements.buffs[i], false)
            if _G[elements.buffs[i]] and _G[elements.buffs[i]]:IsMouseEnabled() then
                ChangeFrameMouseInteraction(elements.buffs[i], false)
            end
        end
    end
end

--Controls visibility on debuff icons, takes how many debuffs are to be shown and the element list of the frame to be modified
local function ToggleDebuffIcons(amount, _, elements)
    for i = 1, 3 do
        if i <= amount then
            ToggleTransparency(elements.debuffs[i], true)
            if _G[elements.debuffs[i]] and not _G[elements.debuffs[i]]:IsMouseEnabled() and not HARFDB[currentLayout].clickThroughBuffs then
                ChangeFrameMouseInteraction(elements.buffs[i], true)
            end
        else
            ToggleTransparency(elements.debuffs[i], false)
            if _G[elements.debuffs[i]] and _G[elements.debuffs[i]]:IsMouseEnabled() then
                ChangeFrameMouseInteraction(elements.buffs[i], false)
            end
        end
    end
end

--Toggles frame transparency, true for enabled false for disabled, takes frameString to be modified
function SetGroupFrameTransparency(value, frameString, _)
    if _G[frameString] then
        _G[frameString].background:SetIgnoreParentAlpha(not value)
    end
end

--Scale names, value for the new scale and element list to access the name
function ScaleNames(value, _, elements)
    if _G[elements.name] then
        _G[elements.name]:SetScale(value)
    end
    if elements.customName then
        elements.customName:SetScale(value)
        elements.customName:SetWidth(_G[elements.name]:GetWidth())
    end
end

--Class coloring for names, value is true for class colored and false for defaults. takes frameString of the frame to modify and its elements
function ColorNames(value, frameString, elements)
    if _G[frameString] then
        local frame = _G[frameString]
        local nameFrame = _G[elements.name]
        local customName
        if not elements.customName then
            customName = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
            customName:SetPoint('TOPLEFT', nameFrame, 'TOPLEFT')
            local font, size, flags = frame.name:GetFont()
            customName:SetScale(nameFrame:GetScale())
            customName:SetFont(font, size, flags)
            customName:SetWidth(nameFrame:GetWidth())
            customName:SetWordWrap(false)
            customName:SetJustifyH('LEFT')
            elements.customName = customName
        else
            customName = elements.customName
        end
        customName:SetText(GetUnitName(frame.unit, true) or GetUnitName('player', true))
        local _, class = UnitClass(frame.unit)
        if class then
            local color = RAID_CLASS_COLORS[class]
            if color then
                customName:SetTextColor(color.r, color.g, color.b)
            end
        end
        if value then
            nameFrame:SetAlpha(0)
            customName:SetAlpha(1)
        else
            nameFrame:SetAlpha(1)
            customName:SetAlpha(0)
        end
    end
end

--Map out unitsIds to the frameString of their frame for buff tracking, also creates the icon
function MapOutUnits(value, frameString, elements)
    if value and _G[frameString] and _G[frameString].unit then
        local unit = _G[frameString].unit
        local frame = _G[frameString]
        unitFrameMap[unit] = frameString
        local r, g, b = frame.healthBar:GetStatusBarColor()
        elements.originalColor = { r = r, g = g, b = b }
        if not elements.buffTrackingIcon then
            local buffIcon = CreateFrame('Frame', nil, UIParent)
            buffIcon:SetSize(25, 25)
            buffIcon:SetPoint('RIGHT', frame, 'RIGHT', -2, 0)
            buffIcon.texture = buffIcon:CreateTexture(nil, 'ARTWORK')
            buffIcon.texture:SetAllPoints()
            buffIcon.cooldown = CreateFrame('Cooldown', nil, buffIcon, 'CooldownFrameTemplate')
            buffIcon.cooldown:SetAllPoints()
            buffIcon.cooldown:SetReverse(true)
            buffIcon:Hide()
            elements.buffTrackingIcon = buffIcon
        end
    end
end

--Check aura status to see if the unit has the relevant buff
function CheckAuraStatus(unit, updateInfo)
    local util = supportedBuffTracking[playerClass].utility
    local hasBuff = false
    local isPlayer = UnitIsUnit(unit, 'player')
    local auras
    if playerClass == 'SHAMAN' then
        auras = C_UnitAuras.GetUnitAuras(unit, 'PLAYER|HELPFUL|RAID_IN_COMBAT', 2, Enum.UnitAuraSortRule.ExpirationOnly)
        if #auras == 2 then
            hasBuff = true
            if not isPlayer then
                util.earthShield = unit
            end
        elseif #auras == 1 and not isPlayer and (util.earthShield == nil or util.earthShield ~= unit) then
            hasBuff = true
        end
    elseif playerClass == 'EVOKER' then
        local currentTime = GetTime()
        auras = C_UnitAuras.GetUnitAuras(unit, 'PLAYER|HELPFUL|RAID', 2, Enum.UnitAuraSortRule.NameOnly)
        if currentTime == util.filteredSpellTimestamp and updateInfo.addedAuras then
            --This unit just got an invalid aura applied
            for _, aura in ipairs(updateInfo.addedAuras) do
                if C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, aura.auraInstanceID, 'PLAYER') then
                    util.filteredSpells[aura.auraInstanceID] = unit
                end
            end
        end
        if #auras > 0 then
            for _, aura in ipairs(auras) do
                if not util.filteredBuffs[aura.auraInstanceID] or not util.filteredBuffs[aura.auraInstanceID] == unit then
                    hasBuff = true
                end
            end
        end
    elseif playerClass == 'PRIEST' and util.isDisc then
        local currentTime = GetTime()
        if currentTime == util.filteredSpellTimestamp and updateInfo.addedAuras then
            --This update is at the same time as Pain Sup cast and applied an aura
            for _, aura in ipairs(updateInfo.addedAuras) do
                if C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, aura.auraInstanceID, 'PLAYER') then
                    util.filteredSpells[aura.auraInstanceID] = unit
                end
            end
        end
        auras = C_UnitAuras.GetUnitAuras(unit, 'PLAYER|HELPFUL|RAID_IN_COMBAT', 1, Enum.UnitAuraSortRule.NameOnly)
        if #auras == 1 and not util.filteredSpells[auras[1].auraInstanceID]  then
            hasBuff = true
        end
    end
    local elements = GetRelevantList()[unitFrameMap[unit]]
    local buffIcon = elements.buffTrackingIcon
    local healthBar = _G[unitFrameMap[unit]].healthBar
    local trackingColor = HARFDB[currentLayout].trackingColor
    local originalColor = elements.originalColor
    if hasBuff then
        local trackingType = HARFDB[currentLayout].trackingType
        if trackingType == 'icon' then
            buffIcon.texture:SetTexture(auras[1].icon)
            local duration = C_UnitAuras.GetAuraDuration(unit, auras[1].auraInstanceID)
            buffIcon.cooldown:SetCooldownFromDurationObject(duration)
            buffIcon:Show()
        elseif trackingType == 'color' then
            healthBar:SetStatusBarColor(trackingColor.r, trackingColor.g, trackingColor.b)
        end
    else
        buffIcon:Hide()
        healthBar:SetStatusBarColor(originalColor.r, originalColor.g, originalColor.b)
    end
end

--[[----------------------------------
    Setup and Options
------------------------------------]]
local function SetupSettings(modifiedSettingFunction, newValue)
    local relevantFrameList = GetRelevantList()
    local layoutInfo = HARFDB[currentLayout]
    local functionsToRun = {}
    if not modifiedSettingFunction or modifiedSettingFunction == MapOutUnits then
        if playerClass == 'PRIEST' and layoutInfo.buffTracking then
            supportedBuffTracking.PRIEST.utility.isDisc = C_SpecializationInfo.GetSpecialization() == 1
        end
        CleanUtilityTables()
    end
    if modifiedSettingFunction and type(modifiedSettingFunction) == 'function' then
        table.insert(functionsToRun, { func = modifiedSettingFunction, val = newValue } )
    else
        table.insert(functionsToRun, { func = ToggleBuffIcons, val = layoutInfo.buffIcons } )
        table.insert(functionsToRun, { func = ToggleDebuffIcons, val = layoutInfo.debuffIcons } )
        table.insert(functionsToRun, { func = ToggleAurasMouseInteraction, val = not layoutInfo.clickThroughBuffs } )
        table.insert(functionsToRun, { func = SetGroupFrameTransparency, val = layoutInfo.frameTransparency } )
        table.insert(functionsToRun, { func = ScaleNames, val = layoutInfo.nameScale } )
        table.insert(functionsToRun, { func = ColorNames, val = layoutInfo.colorNames } )
        table.insert(functionsToRun, { func = MapOutUnits, val = layoutInfo.buffTracking } )
    end

    for frameString, elements in pairs(relevantFrameList) do
        for _, functionData in ipairs(functionsToRun) do
            functionData.func(functionData.val, frameString, elements)
        end
    end
end

local clickableOptionsFrame = CreateFrame('Frame', 'HarreksAdvancedRaidFrames', UIParent, 'InsetFrameTemplate')
clickableOptionsFrame:SetSize(150, 45)
clickableOptionsFrame:SetPoint('TOPRIGHT', CompactPartyFrame, 'TOPLEFT', -5, 0)
clickableOptionsFrame.text = clickableOptionsFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
clickableOptionsFrame.text:SetPoint("CENTER", clickableOptionsFrame, 'CENTER')
clickableOptionsFrame.text:SetText('Advanced Raid Frames')
clickableOptionsFrame:Hide()

local trackedEvents = {
    'PLAYER_LOGIN',
    'GROUP_ROSTER_UPDATE',
    'UNIT_SPELLCAST_SUCCEEDED',
    'UNIT_AURA'
}
local eventTracker = CreateFrame('Frame')
for _, event in ipairs(trackedEvents) do
    eventTracker:RegisterEvent(event)
end
eventTracker:SetScript('OnEvent', function(self, event, ...)
    if event == 'PLAYER_LOGIN' then

        HARFDB = HARFDB or {}
        playerClass = UnitClassBase('player')

        local LEM = LibStub('LibEditMode')

        LEM:RegisterCallback('enter', function()
            clickableOptionsFrame:Show()
        end)

        LEM:RegisterCallback('exit', function()
            clickableOptionsFrame:Hide()
        end)

        LEM:RegisterCallback('layout', function(layout)
            currentLayout = layout
            if not HARFDB[layout] then
                HARFDB[layout] = CopyTable(defaultSettings)
            else
                for option, value in pairs(defaultSettings) do
                    if not HARFDB[layout][option] then
                        HARFDB[layout][option] = value
                    end
                end
            end
            SetupSettings()
        end)

        local options = {
            {
                name = 'Click Through Aura Icons',
                kind = LEM.SettingType.Checkbox,
                default = defaultSettings.clickThroughBuffs,
                desc = 'Disables mouse interaction on the aura icons on the frame, letting you mouseover and click through them.',
                get = function(layout)
                    return HARFDB[layout].clickThroughBuffs
                end,
                set = function(layout, value)
                    HARFDB[layout].clickThroughBuffs = value
                    SetupSettings(ToggleAurasMouseInteraction, not value)
                end
            },
            {
                name = 'Buff Icons',
                kind = LEM.SettingType.Slider,
                default = defaultSettings.buffIcons,
                desc = 'Changes the maximum amount of buff icons on the frame.',
                get = function(layout)
                    return HARFDB[layout].buffIcons
                end,
                set = function(layout, value)
                    HARFDB[layout].buffIcons = value
                    SetupSettings(ToggleBuffIcons, value)
                end,
                minValue = 0,
                maxValue = 6,
                valueStep = 1
            },
            {
                name = 'Debuff Icons',
                kind = LEM.SettingType.Slider,
                default = defaultSettings.debuffIcons,
                desc = 'Changes the maximum amount of debuff icons on the frame.',
                get = function(layout)
                    return HARFDB[layout].debuffIcons
                end,
                set = function(layout, value)
                    HARFDB[layout].debuffIcons = value
                    SetupSettings(ToggleDebuffIcons, value)
                end,
                minValue = 0,
                maxValue = 3,
                valueStep = 1
            },
            {
                name = 'Frame Transparency',
                kind = LEM.SettingType.Checkbox,
                default = defaultSettings.frameTransparency,
                desc = 'Disabling frame transparency keeps the frame fully solid even when out of range.',
                get = function(layout)
                    return HARFDB[layout].frameTransparency
                end,
                set = function(layout, value)
                    HARFDB[layout].frameTransparency = value
                    SetupSettings(SetGroupFrameTransparency, value)
                end
            },
            {
                name = 'Name Size',
                kind = LEM.SettingType.Slider,
                default = defaultSettings.nameScale,
                desc = 'Changes the size of the unit name.',
                get = function(layout)
                    return HARFDB[layout].nameScale
                end,
                set = function(layout, value)
                    HARFDB[layout].nameScale = value
                    SetupSettings(ScaleNames, value)
                end,
                formatter = formatForDisplay,
                minValue = 0.5,
                maxValue = 3,
                valueStep = 0.1
            },
            {
                name = 'Class Colored Names',
                kind = LEM.SettingType.Checkbox,
                default = defaultSettings.colorNames,
                desc = 'Replaces the unit name for class-colored ones.',
                get = function(layout)
                    return HARFDB[layout].colorNames
                end,
                set = function(layout, value)
                    HARFDB[layout].colorNames = value
                    SetupSettings(ColorNames, value)
                end
            }
        }
        if supportedBuffTracking[playerClass] and gameVersion >= 120001 then
            local conditionalOptions = {
                {
                    name = 'Buff Tracking: ' .. supportedBuffTracking[playerClass].spell,
                    kind = LEM.SettingType.Checkbox,
                    default = defaultSettings.buffTracking,
                    desc = 'Some specializations can track a specific buff better on their frames, this enables that tracking.',
                    get = function(layout)
                        return HARFDB[layout].buffTracking
                    end,
                    set = function(layout, value)
                        HARFDB[layout].buffTracking = value
                        SetupSettings(MapOutUnits, value)
                    end
                },
                {
                    name = 'Tracking Type',
                    kind = LEM.SettingType.Dropdown,
                    default = defaultSettings.trackingType,
                    desc = 'asd dada',
                    get = function(layout)
                        return HARFDB[layout].trackingType
                    end,
                    set = function(layout, value)
                        HARFDB[layout].trackingType = value
                    end,
                    values = {
                        icon = { text = 'Icon', value = 'icon'},
                        color = { text = 'Bar Recolor', value = 'color' }
                    }
                },
                {
                    name = 'Tracking Bar Color',
                    kind = LEM.SettingType.ColorPicker,
                    default = CreateColor(defaultSettings.trackingColor.r, defaultSettings.trackingColor.g, defaultSettings.trackingColor.b),
                    desc = 'Color to change the bars into when the buff is present.',
                    get = function(layout)
                        local currentColor = HARFDB[layout].trackingColor
                        return CreateColor(currentColor.r, currentColor.g, currentColor.b)
                    end,
                    set = function(layout, value)
                        local r, g, b = value:GetRGB()
                        HARFDB[layout].trackingColor = { r = r, g = g, b = b }
                    end
                }
            }
            for _, option in ipairs(conditionalOptions) do
                table.insert(options, option)
            end
        end

        LEM:AddFrame(clickableOptionsFrame, function(frame)
            frame:ClearAllPoints()
            frame:SetPoint("TOPRIGHT", CompactPartyFrame, "TOPLEFT", -5, 0)
        end, { point = 'CENTER', x = 0, y = 0})
        LEM:AddFrameSettings(clickableOptionsFrame, options)

    elseif event == 'GROUP_ROSTER_UPDATE' then

        SetupSettings()

    elseif event == 'UNIT_AURA' and HARFDB[currentLayout].buffTracking then

        local unit, updateInfo = ...
        if supportedBuffTracking[playerClass] and unitFrameMap[unit] then
            CheckAuraStatus(unit, updateInfo)
        end

    elseif event == 'UNIT_SPELLCAST_SUCCEEDED' and supportedBuffTracking[playerClass] and HARFDB[currentLayout].buffTracking then

        local unit, _, spellId = ...
        if not issecretvalue(spellId) and not issecretvalue(unit) and unit == 'player' then
            if playerClass == 'EVOKER' and supportedBuffTracking.EVOKER.utility.filteredSpells[spellId] then
                supportedBuffTracking.EVOKER.utility.filteredSpellTimestamp = GetTime()
            elseif playerClass == 'PRIEST' and supportedBuffTracking.PRIEST.utility.isDisc and spellId == 33206 then
                supportedBuffTracking.PRIEST.utility.filteredSpellTimestamp = GetTime()
            end
        end

    end
end)