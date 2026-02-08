--[[----------------------------------
    Utilities
------------------------------------]]

--Initialize default data
local gameVersion = select(4, GetBuildInfo())
local currentLayout = nil
local unitFrameMap = {}
local playerClass = nil
local supportedBuffTracking = {
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
    Reversion (non-echo)
    Source of Magic
    Zephyr
    Rewind
    Time Dilation
    ]]
    EVOKER = {
        spell = 'Echo',
        utility = {
            filteredSpellTimestamp = nil,
            filteredSpells = {
                [366155] = true,
                [1256581] = true,
                [374227] = true,
                [369459] = true,
                [357170] = true,
                [390386] = true,
                [363916] = true,
                [363564] = true
            },
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
local spotlightAnchors = {
    spotlights = {},
    defaults = {}
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
    trackingColor = { r = 0, g = 1, b = 0 },
    spotlight = {
        point = 'CENTER',
        x = 0,
        y = 0,
        grow = 'Right',
        names = {}
    }
}

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
            isColored = false,
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
        isColored = false,
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

--Return the list of raid frames depending on raid or party
local function GetRelevantList()
    return IsInRaid() and frameList.raid or frameList.party
end

local function AreTimestampsEqual(time1, time2)
    if time1 and time2 then
        return time1 > time2 and time1 < time2 + 0.2
        --return time1 == time2
    else
        return false
    end
end

local function GetSpotlightNames()
    if IsInRaid() then
        local frames = GetRelevantList()
        local raidNameList = {}
        if currentLayout and HARFDB[currentLayout] and HARFDB[currentLayout].spotlight.names then
            for name, _ in pairs(HARFDB[currentLayout].spotlight.names) do
                table.insert(raidNameList, { text = name })
            end
        end
        for frameString, _ in pairs(frames) do
            if _G[frameString] then
                local frame = _G[frameString]
                local unitName = UnitName(frame.unit)
                if not UnitIsUnit(frame.unit, 'player') and not HARFDB[currentLayout].spotlight.names[unitName] then
                    table.insert(raidNameList, { text = unitName })
                end
            end
        end
        return raidNameList
    else
        return HARFDB[currentLayout].spotlight.names
    end
end

--Use the spotlight name list to map out where each frame is supposed to go
local function MapSpotlightAnchors()
    spotlightAnchors = { spotlights = {}, defaults = {} } --Reset the current lists
    local units = HARFDB[currentLayout].spotlight.names
    local frames = frameList.raid --Spotlight only works in raid
    for frameString, _ in pairs(frames) do
        if _G[frameString] and _G[frameString].unit then
            local currentFrame = _G[frameString]
            local unit = currentFrame.unit
            if unit ~= 'player' then --The player can't be spotlight
                local unitName = UnitName(unit)
                local frameIndex = frameString:gsub('CompactRaidFrame', '') --We grab the number of this frame to keep them in order
                --If the unit is in our name list we save it in the spotlights, otherwise we save it on defaults
                if units[unitName] then
                    spotlightAnchors.spotlights[frameIndex] = frameString
                else
                    spotlightAnchors.defaults[frameIndex] = frameString
                end
            end
        end
    end
    --We are gonna sort our frames to know what goes anchored to what
    --The goal here is to have two ordered lists of what order the frames must follow for ReanchorSpotlights() to work with
    for type, list in pairs(spotlightAnchors) do
        local framesIndexes = {}
        for index in pairs(list) do
            table.insert(framesIndexes, tonumber(index)) --Insert the frame number into a new list
        end
        table.sort(framesIndexes) --Sort the numbers
        local orderedFrameList = {}
        local order = 1
        --Now we use the ordered indices to list the frames in the order they're supposed to go
        for _, index in ipairs(framesIndexes) do
            orderedFrameList[order] = list[tostring(index)]
            order = order + 1
        end
        --Save the sorted data in our spotlight anchors list
        spotlightAnchors[type] = orderedFrameList
    end
end

--Use the mapped spotlight anchors to attach the frames where they are supposed to go
function ReanchorSpotlights()
    for index, frameString in ipairs(spotlightAnchors.spotlights) do
        local frame = _G[frameString]
        frame:ClearAllPoints()
        --The first frame goes attached directly to the spotlight anchor
        if index == 1 then
            frame:SetPoint('TOP', 'AdvancedRaidFramesSpotlight', 'TOP')
        --Other frames go attached to the previous one in the list
        else
            local previousFrame = _G[spotlightAnchors.spotlights[index - 1]]
            local childPoint, parentPoint
            if HARFDB[currentLayout].spotlight.grow == 'right' then
                childPoint, parentPoint = 'LEFT', 'RIGHT'
            else
                childPoint, parentPoint = 'TOP', 'BOTTOM'
            end
            frame:SetPoint(childPoint, previousFrame, parentPoint)
        end
    end
    --Similar logic for the frames that remain in the default position
    --This currently has a bug if the user has 'separate tanks' turned on, because the tanks' targets and targetoftarget also use frames but of different size
    for index, frameString in ipairs(spotlightAnchors.defaults) do
        local frame = _G[frameString]
        frame:ClearAllPoints()
        if index == 1 then
            frame:SetPoint('TOPLEFT', 'CompactRaidFrameContainer', 'TOPLEFT')
        else
            --This 5 is a magic number that assumes people have 5 frames before breaking into a new row (needs updating)
            if (index - 1) % 5 == 0 then
                local previousFrame = _G[spotlightAnchors.defaults[index - 5]]
                frame:SetPoint('TOP', previousFrame, 'BOTTOM')
            else
                local previousFrame = _G[spotlightAnchors.defaults[index - 1]]
                frame:SetPoint('LEFT', previousFrame, 'RIGHT')
            end
        end
    end
end

--We hook into the function that recolors the health bars
hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
    --check if this unit frame is one of the ones we have mapped
    if frame.unit and unitFrameMap[frame.unit] and
    --Confirm the addon is setup and we care about recoloring bars
    currentLayout and HARFDB[currentLayout].buffTracking and HARFDB[currentLayout].trackingType == 'color'
    then
        --See if this frame is supposed to be colored, if so recolor it
        local elements = GetRelevantList()[unitFrameMap[frame.unit]]
        if elements.isColored then
            local healthBar = frame.healthBar
            local trackingColor = HARFDB[currentLayout].trackingColor
            healthBar:SetStatusBarColor(trackingColor.r, trackingColor.g, trackingColor.b)
        end
    end
end)

--[[----------------------------------
    Core Functions
------------------------------------]]

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
        local width = _G[elements.name]:GetWidth()
        if not issecretvalue(width) then
            elements.customName:SetWidth(width)
        end
    end
end

--Class coloring for names, value is true for class colored and false for defaults. takes frameString of the frame to modify and its elements
function ColorNames(value, frameString, elements)
    if _G[frameString] and _G[frameString].unit then
        local frame = _G[frameString]
        local nameFrame = _G[elements.name]
        local customName
        if not elements.customName then
            customName = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
            local font, size, flags = frame.name:GetFont()
            customName:SetScale(nameFrame:GetScale())
            customName:SetFont(font, size, flags)
            customName:SetWordWrap(false)
            customName:SetWidth(nameFrame:GetWidth())
            if string.find(frameString, 'Raid') then
                customName:SetJustifyH('CENTER')
                customName:SetPoint('CENTER', nameFrame, 'CENTER')
            else
                customName:SetJustifyH('LEFT')
                customName:SetPoint('TOPLEFT', nameFrame, 'TOPLEFT')
            end
            elements.customName = customName
        else
            customName = elements.customName
        end
        customName:SetText(GetUnitName(frame.unit, true))
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
    if value and _G[frameString]then
        local unit = _G[frameString].unit
        if unit then
            local frame = _G[frameString]
            unitFrameMap[unit] = frameString
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
                buffIcon:SetScript('OnEvent', function(_, _, unitId, auraUpdateInfo)
                    CheckAuraStatus(unitId, auraUpdateInfo)
                end)
                elements.buffTrackingIcon = buffIcon
            end
            elements.buffTrackingIcon:RegisterUnitEvent('UNIT_AURA', unit)
        elseif elements.buffTrackingIcon then
            elements.buffTrackingIcon:UnregisterAllEvents()
        end
    end
end

--Check aura status to see if the unit has the relevant buff
function CheckAuraStatus(unit, updateInfo)
    local util = supportedBuffTracking[playerClass].utility
    local hasBuff = false
    local isPlayer = UnitIsUnit(unit, 'player')
    local auras
    local currentTime = GetTime()
    --Check if the aura update time matches the timestamp of casting a filtered spell
    if AreTimestampsEqual(currentTime, util.filteredSpellTimestamp) and updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            --Check the auras added to see if any was applied by the player, if so we assume this aura was applied by a spell we don't want to track
            if C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, aura.auraInstanceID, 'PLAYER') then
                util.filteredBuffs[aura.auraInstanceID] = unit
            end
        end
    end
    --If we already have a valid saved buff for this unit
    if util.activeAuras[unit] then
        hasBuff = true
        --Check the removed auras to make sure our auraInstanceID still exists
        if updateInfo.removedAuraInstanceIDs then
            for _, auraId in ipairs(updateInfo.removedAuraInstanceIDs) do
                --If our saved auraInstanceID was removed, clear the saved aura for this unit
                if util.activeAuras[unit] == auraId then
                    util.activeAuras[unit] = nil
                    hasBuff = false
                end
            end
        end
    end
    --Shaman aura handling
    if playerClass == 'SHAMAN' then
        --If this is the unit that we have saved as our earth shield, check if its still there
        if util.earthShield and unit == util.earthShield.unit then
            if updateInfo.removedAuraInstanceIDs then
                for _, auraId in ipairs(updateInfo.removedAuraInstanceIDs) do
                    --If our saved auraInstanceID was removed, clear the saved aura for this unit
                    if util.earthShield.aura == auraId then
                        util.earthShield = nil
                    end
                end
            end
        end
        if not util.activeAuras[unit] or not util.earthShield then
            auras = C_UnitAuras.GetUnitAuras(unit, 'PLAYER|HELPFUL|RAID_IN_COMBAT', 2, Enum.UnitAuraSortRule.ExpirationOnly)
            if #auras == 2 then --If the unit has two auras these have to be Earth Shield and Riptide
                hasBuff = true
                util.activeAuras[unit] = auras[1].auraInstanceID --We know the first aura is Riptide because of the sorting
                if not isPlayer then
                    util.earthShield = { unit = unit, aura = auras[2].auraInstanceID } --If the unit has two auras and is not the player, this is our second earth shield
                end
            --If the unit has one aura, is not the player nor the earth shield target, then this unit has Riptide
            elseif #auras == 1 and not isPlayer and (util.earthShield == nil or util.earthShield.unit ~= unit) then
                hasBuff = true
                util.activeAuras[unit] = auras[1].auraInstanceID --Save the auraInstanceID for future checks on this unit
            end
        end
    --Evoker aura handling
    elseif playerClass == 'EVOKER' then
        --If we don't have a valid saved aura for this unit, we check their buffs
        if not util.activeAuras[unit] then
            auras = C_UnitAuras.GetUnitAuras(unit, 'PLAYER|HELPFUL|RAID', 1, Enum.UnitAuraSortRule.NameOnly)
            if #auras > 0 then
                --The sorting means Echo will always be first, so we check the first aura to see if its filtered out by our casts
                if not util.filteredBuffs[auras[1].auraInstanceID] or not util.filteredBuffs[auras[1].auraInstanceID] == unit then
                    hasBuff = true --If it isn't filtered, this is echo
                    util.activeAuras[unit] = auras[1].auraInstanceID
                end
            end
        end
    --Priest aura handling
    elseif playerClass == 'PRIEST' and util.isDisc then
        --If we don't have a valid saved aura for this unit, we check their buffs
        if not util.activeAuras[unit] then
            auras = C_UnitAuras.GetUnitAuras(unit, 'PLAYER|HELPFUL|RAID_IN_COMBAT', 1, Enum.UnitAuraSortRule.NameOnly)
            --Sorting means Atonement will be first, if the auraInstanceID isn't from one of our filtered casts then the unit has atonement
            if #auras == 1 and not util.filteredBuffs[auras[1].auraInstanceID]  then
                hasBuff = true
                util.activeAuras[unit] = auras[1].auraInstanceID
            end
        end
    end
    --Get info to update visuals accordingly
    local elements = GetRelevantList()[unitFrameMap[unit]]
    local buffIcon = elements.buffTrackingIcon
    local frame = _G[unitFrameMap[unit]]
    if hasBuff then
        local trackingType = HARFDB[currentLayout].trackingType
        --If the tracking is an icon we update it and show it
        if trackingType == 'icon' then
            buffIcon.texture:SetTexture(auras[1].icon)
            local duration = C_UnitAuras.GetAuraDuration(unit, auras[1].auraInstanceID)
            buffIcon.cooldown:SetCooldownFromDurationObject(duration)
            buffIcon:Show()
        --If the tracking is bar recoloring ew recolor the bar and mark it as colored in the elements
        elseif trackingType == 'color' then
            local healthBar = frame.healthBar
            local trackingColor = HARFDB[currentLayout].trackingColor
            healthBar:SetStatusBarColor(trackingColor.r, trackingColor.g, trackingColor.b)
            elements.isColored = true
        end
    --If the unit does not have a valid buff we hide the icon, mark is as not colored and call Blizz' coloring function on the frame
    else
        buffIcon:Hide()
        elements.isColored = false
        CompactUnitFrame_UpdateHealthColor(frame)
    end
end

--[[----------------------------------
    Setup and Options
------------------------------------]]
local function SetupSettings(modifiedSettingFunction, newValue)
    if not InCombatLockdown() then
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

        if IsInRaid() and HARFDB[currentLayout].spotlight.names then
            MapSpotlightAnchors()
            ReanchorSpotlights()
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

local spotlightOptionsFrame = CreateFrame('Frame', 'AdvancedRaidFramesSpotlight', UIParent, 'InsetFrameTemplate')
spotlightOptionsFrame:SetSize(200, 50)
spotlightOptionsFrame:SetPoint('CENTER', UIParent, 'CENTER')
spotlightOptionsFrame.text = spotlightOptionsFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
spotlightOptionsFrame.text:SetPoint("CENTER", spotlightOptionsFrame, 'CENTER')
spotlightOptionsFrame.text:SetText('Advanced Raid Frames\nSpotlight')
spotlightOptionsFrame:SetAlpha(0)

local trackedEvents = {
    'PLAYER_LOGIN',
    'GROUP_ROSTER_UPDATE',
    'UNIT_SPELLCAST_SUCCEEDED'
}
local eventTracker = CreateFrame('Frame')
for _, event in ipairs(trackedEvents) do
    eventTracker:RegisterEvent(event)
end
eventTracker:SetScript('OnEvent', function(self, event, ...)
    if event == 'PLAYER_LOGIN' then

        playerClass = UnitClassBase('player')

        local LEM = LibStub('LibEditMode')

        LEM:RegisterCallback('enter', function()
            clickableOptionsFrame:Show()
            spotlightOptionsFrame:SetAlpha(1)
        end)

        LEM:RegisterCallback('exit', function()
            clickableOptionsFrame:Hide()
            spotlightOptionsFrame:SetAlpha(0)
            if IsInRaid() and not InCombatLockdown() and HARFDB[currentLayout].spotlight.names then
                ReanchorSpotlights()
            end
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

            spotlightOptionsFrame:SetPoint(HARFDB[layout].spotlight.point, HARFDB[layout].spotlight.x, HARFDB[layout].spotlight.y)
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
                    desc = 'Choose how to track the buffs.',
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

        LEM:AddFrame(spotlightOptionsFrame, function(frame, layout, point, x, y)
            HARFDB[layout].spotlight.point = point
            HARFDB[layout].spotlight.x = x
            HARFDB[layout].spotlight.y = y
        end)
        LEM:AddFrameSettings(spotlightOptionsFrame, {
            {
                name = 'Player List',
                kind = LEM.SettingType.Dropdown,
                default = defaultSettings.spotlight.names,
                desc = 'Select the players to be shown in the spotlight',
                multiple = true,
                get = function(layout)
                    local nameList = {}
                    for name, _ in pairs(HARFDB[layout].spotlight.names) do
                        table.insert(nameList, name)
                    end
                    return nameList
                end,
                set = function(layout, value)
                    if HARFDB[layout].spotlight.names[value] then
                        HARFDB[layout].spotlight.names[value] = nil
                    else
                        HARFDB[layout].spotlight.names[value] = true
                    end
                    MapSpotlightAnchors()
                end,
                values = GetSpotlightNames()
            },
            {
                name = 'Grow Direction',
                kind = LEM.SettingType.Dropdown,
                default = defaultSettings.spotlight.grow,
                desc = 'Grow direction for the spotlight frames',
                get = function(layout)
                    return HARFDB[layout].spotlight.grow
                end,
                set = function(layout, value)
                    HARFDB[layout].spotlight.grow = value
                end,
                values = {
                    { text = 'Right', value = 'right' },
                    { text = 'Bottom', value = 'bottom' }
                }
            }
        })

    elseif event == 'GROUP_ROSTER_UPDATE' then

        SetupSettings()

    elseif event == 'UNIT_SPELLCAST_SUCCEEDED' and supportedBuffTracking[playerClass] and HARFDB[currentLayout].buffTracking then

        local unit, _, spellId = ...
        if not issecretvalue(spellId) and not issecretvalue(unit) and unit == 'player' and supportedBuffTracking[playerClass].utility.filteredSpells[spellId] then
            supportedBuffTracking[playerClass].utility.filteredSpellTimestamp = GetTime()
        end

    end
end)