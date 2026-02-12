local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core
local Opt = NS.Opt

--Function to format decimals out for display
function Util.FormatForDisplay(number)
    return math.floor(number * 10 + 0.5) / 10
end

--Takes a string, checks global table for frame with that name and changes mouse interaction on it
function Util.ChangeFrameMouseInteraction(frameString, value)
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
function Util.ToggleTransparency(frameString, shouldShow)
    if _G[frameString] then
        if shouldShow then
            _G[frameString]:SetAlpha(1)
        else
            _G[frameString]:SetAlpha(0)
        end
    end
end

--Helper function to check if a specific auraInstanceId on a specific unit is already present on a filter list
function Util.IsAuraOnUnitFilteredByList(auraInstanceId, unit, filteredAurasList)
    if filteredAurasList[unit] and filteredAurasList[unit][auraInstanceId] then
        return true
    else
        return false
    end
end

--The addon uses some tables to keep track of unit frames and specific auras, every now and then we empty these tables to remove irrelevant data
--Currently this happens when we remap out frames to new units after a roster update, as the info is tied to a specific player occupying a specific frame
function Util.CleanUtilityTables()
    for _, spec in pairs(Data.supportedBuffTracking) do
        if spec.utility.filteredBuffs then
            wipe(spec.utility.filteredBuffs)
        end
        if spec.utility.activeAuras then
            wipe(spec.utility.activeAuras)
        end
    end
end

--Return the list of raid frames depending on raid or party
function Util.GetRelevantList()
    return IsInRaid() and Data.unitList.raid or Data.unitList.party
end

--Yes i know what "equal" means
function Util.AreTimestampsEqual(time1, time2)
    local castDelay = Data.supportedBuffTracking[Data.playerClass].allowedCastDelay
    if time1 and time2 then
        return time1 >= time2 and time1 <= time2 + castDelay
    else
        return false
    end
end

function Util.GetSpotlightNames()
    if IsInRaid() then
        local frames = Util.GetRelevantList()
        local raidNameList = {}
        if HARFDB.spotlight.names then
            for name, _ in pairs(HARFDB.spotlight.names) do
                table.insert(raidNameList, { text = name })
            end
        end
        for frameString, _ in pairs(frames) do
            if _G[frameString] then
                local frame = _G[frameString]
                local unitName = UnitName(frame.unit)
                if not UnitIsUnit(frame.unit, 'player') and not HARFDB.spotlight.names[unitName] then
                    table.insert(raidNameList, { text = unitName })
                end
            end
        end
        return raidNameList
    else
        return HARFDB.spotlight.names
    end
end

--Use the spotlight name list to map out where each frame is supposed to go
function Util.MapSpotlightAnchors()
    --Reset the current lists
    wipe(Data.spotlightAnchors.spotlights)
    wipe(Data.spotlightAnchors.defaults)
    local units = HARFDB.spotlight.names
    local frames = Data.frameList.raid --Spotlight only works in raid
    for frameString, _ in pairs(frames) do
        if _G[frameString] and _G[frameString].unit then
            local currentFrame = _G[frameString]
            local unit = currentFrame.unit
            if unit ~= 'player' then --The player can't be spotlight
                local unitName = UnitName(unit)
                local frameIndex = frameString:gsub('CompactRaidFrame', '') --We grab the number of this frame to keep them in order
                --If the unit is in our name list we save it in the spotlights, otherwise we save it on defaults
                if units[unitName] then
                    Data.spotlightAnchors.spotlights[frameIndex] = frameString
                else
                    Data.spotlightAnchors.defaults[frameIndex] = frameString
                end
            end
        end
    end
    --We are gonna sort our frames to know what goes anchored to what
    --The goal here is to have two ordered lists of what order the frames must follow for ReanchorSpotlights() to work with
    for type, list in pairs(Data.spotlightAnchors) do
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
        Data.spotlightAnchors[type] = orderedFrameList
    end
end

--Use the mapped spotlight anchors to attach the frames where they are supposed to go
function Util.ReanchorSpotlights()
    for index, frameString in ipairs(Data.spotlightAnchors.spotlights) do
        local frame = _G[frameString]
        frame:ClearAllPoints()
        --The first frame goes attached directly to the spotlight anchor
        if index == 1 then
            frame:SetPoint('TOP', 'AdvancedRaidFramesSpotlight', 'TOP')
        --Other frames go attached to the previous one in the list
        else
            local previousFrame = _G[Data.spotlightAnchors.spotlights[index - 1]]
            local childPoint, parentPoint
            if HARFDB.spotlight.grow == 'right' then
                childPoint, parentPoint = 'LEFT', 'RIGHT'
            else
                childPoint, parentPoint = 'TOP', 'BOTTOM'
            end
            frame:SetPoint(childPoint, previousFrame, parentPoint)
        end
    end
    --Similar logic for the frames that remain in the default position
    --This currently has a bug if the user has 'separate tanks' turned on, because the tanks' targets and targetoftarget also use frames but of different size
    for index, frameString in ipairs(Data.spotlightAnchors.defaults) do
        local frame = _G[frameString]
        frame:ClearAllPoints()
        if index == 1 then
            frame:SetPoint('TOPLEFT', 'CompactRaidFrameContainer', 'TOPLEFT')
        else
            --This 5 is a magic number that assumes people have 5 frames before breaking into a new row (needs updating)
            if (index - 1) % 5 == 0 then
                local previousFrame = _G[Data.spotlightAnchors.defaults[index - 5]]
                frame:SetPoint('TOP', previousFrame, 'BOTTOM')
            else
                local previousFrame = _G[Data.spotlightAnchors.defaults[index - 1]]
                frame:SetPoint('LEFT', previousFrame, 'RIGHT')
            end
        end
    end
end

function Util.DisplayTrackedBuff(unit, buff)
    --Get info to update visuals accordingly
    local unitList = Util.GetRelevantList()
    local elements = unitList[unit]
    if elements then
        local trackingType = HARFDB.trackingType
        local trackingColor = CreateColorFromHexString(HARFDB.trackingColor)
        --If the tracking is an icon we update it and show it
        if trackingType == 'icon' and buff then
            local trackingIcon = elements.trackingIcon
            local duration = C_UnitAuras.GetAuraDuration(unit, buff.auraInstanceID)
            trackingIcon.texture:SetTexture(buff.icon)
            trackingIcon.cooldown:SetCooldownFromDurationObject(duration)
            trackingIcon:Show()
        --If the tracking is bar recoloring we recolor the bar and mark it as colored in the elements
        elseif trackingType == 'color' then
            if Util.DandersCompat() then
                DandersFrames_HighlightUnit(unit, trackingColor.r, trackingColor.g, trackingColor.b, trackingColor.a)
            else
                local frame = _G[elements.frame]
                local healthBar = frame.healthBar
                healthBar:SetStatusBarColor(trackingColor.r, trackingColor.g, trackingColor.b)
                elements.isColored = true
            end
        elseif trackingType == 'bar' then
            local bar = elements.displayBar
            local duration = C_UnitAuras.GetAuraDuration(unit, buff.auraInstanceID)
            bar:SetStatusBarColor(trackingColor.r, trackingColor.g, trackingColor.b)
            bar:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
            bar:Show()
        end
    end
end

function Util.HideTrackedBuff(unit)
    local unitList = Util.GetRelevantList()
    local elements = unitList[unit]
    if elements then
        local trackingType = HARFDB.trackingType
        if trackingType == 'icon' then
            local trackingIcon = elements.trackingIcon
            trackingIcon:Hide()
        elseif trackingType == 'color' then
            if Util.DandersCompat() then
                DandersFrames_ClearHighlight(unit)
            else
                local frame = _G[elements.frame]
                elements.isColored = false
                CompactUnitFrame_UpdateHealthColor(frame)
            end
        elseif trackingType == 'bar' then
            local bar = elements.displayBar
            bar:Hide()
        end
    end
end

function Util.CreateOptionsElement(data, parent)
    local initializer = nil
    if data.type == "header" then
        initializer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", { name = data.text })
        parent.layout:AddInitializer(initializer)
        Data.initializerList[data.key] = initializer
        return
    elseif data.type == "button" then
        local buttonData = {
            name = data.text,
            buttonText = data.content,
            buttonClick = data.func,
            tooltip = data.tooltip,
            newTagID = nil,
            gameDataFunc = nil
        }
        initializer =  Settings.CreateElementInitializer("SettingButtonControlTemplate", buttonData)
        Data.initializerList[data.key] = initializer
        parent.layout:AddInitializer(initializer)
    else
        if not HARFDB[data.key] then HARFDB[data.key] = data.default end
        local input = Settings.RegisterAddOnSetting(parent.category, data.key, data.key, HARFDB, type(data.default), data.text, data.default)
        input:SetValueChangedCallback(function(setting, value)
            local settingKey = setting:GetVariable()
            if data.readOnly and HARFDB[settingKey] ~= data.default then
                HARFDB[settingKey] = data.default
                setting:NotifyUpdate()
            else
                local func
                for _, opt in ipairs(Data.settings) do
                    if opt.key == settingKey then
                        func = opt.func
                        break
                    end
                end
                if func then
                    if func == 'Setup' then
                        Opt.SetupSettings()
                    else
                        Opt.SetupSettings(func, value)
                    end
                end
            end
        end)
        if data.type == "checkbox" then
            initializer = Settings.CreateCheckbox(parent.category, input, data.tooltip)
            Data.initializerList[data.key] = initializer
        elseif data.type == "dropdown" then
            local function GetOptions()
                local container = Settings.CreateControlTextContainer()
                for _, item in ipairs(data.items) do
                    container:Add(item.value, item.text)
                end
                return container:GetData()
            end
            initializer = Settings.CreateDropdown(parent.category, input, GetOptions, data.tooltip)
            Data.initializerList[data.key] = initializer
        elseif data.type == "slider" then
            local options = Settings.CreateSliderOptions(data.min, data.max, data.step)
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, Util.FormatForDisplay);
            initializer = Settings.CreateSlider(parent.category, input, options, data.tooltip)
            Data.initializerList[data.key] = initializer
        elseif data.type == "color" then
            initializer = Settings.CreateColorSwatch(parent.category, input, data.tooltip)
            Data.initializerList[data.key] = initializer
        end
    end
    if initializer and data.parent then
        initializer:SetParentInitializer(Data.initializerList[data.parent], function() return HARFDB[data.parent] end)
    end
end

function Util.CreateOptionsPanel(optionsTable)
    local category, layout = Settings.RegisterVerticalLayoutCategory("Advanced Raid Frames");
    for _, data in ipairs(optionsTable) do
        Util.CreateOptionsElement(data, { category = category, layout = layout })
    end
    Settings.RegisterAddOnCategory(category)

    SLASH_HARREKSADVANCEDRAIDFRAMES1 = "/harf"
    SlashCmdList.HARREKSADVANCEDRAIDFRAMES = function()
        Settings.OpenToCategory(category.ID)
    end
end

function Util.InstallFrames()
    for groupType, units in pairs(Data.unitList) do
        for unit, _ in pairs(units) do
            local elements = Data.unitList[groupType][unit]
            if not elements.trackingIcon then
                local trackingIcon = CreateFrame('Frame', nil, UIParent)
                trackingIcon:SetSize(25, 25)
                trackingIcon.texture = trackingIcon:CreateTexture(nil, 'ARTWORK')
                trackingIcon.texture:SetAllPoints()
                trackingIcon.cooldown = CreateFrame('Cooldown', nil, trackingIcon, 'CooldownFrameTemplate')
                trackingIcon.cooldown:SetAllPoints()
                trackingIcon.cooldown:SetReverse(true)
                trackingIcon:Hide()
                trackingIcon:SetScript('OnEvent', function(_, _, unitId, auraUpdateInfo)
                    Core.CheckAuraStatus(unitId, auraUpdateInfo)
                    if Util.Grid2Plugin and Util.Grid2Plugin.enabled then
                        Util.Grid2Plugin:UpdateIndicators(unitId)
                    end
                end)
                trackingIcon:RegisterUnitEvent('UNIT_AURA', unit)
                elements.trackingIcon = trackingIcon
            end
            if not elements.displayBar then
                local displayBar = CreateFrame('StatusBar', nil, UIParent)
                displayBar:SetStatusBarTexture("Interface/Buttons/WHITE8x8")
                displayBar.background = displayBar:CreateTexture(nil, 'BACKGROUND')
                displayBar.background:SetAllPoints(displayBar)
                displayBar.background:SetColorTexture(0, 0, 0, 1)
                displayBar:Hide()
                elements.displayBar = displayBar
            end
        end
    end
end

function Util.AttachElements(elements, parent)
    local icon = elements.trackingIcon
    icon:SetParent(UIParent)
    icon:ClearAllPoints()
    icon:SetPoint(HARFDB.iconPosition, parent, HARFDB.iconPosition)
    icon:SetSize(HARFDB.iconSize, HARFDB.iconSize)
    icon:Hide()
    local bar = elements.displayBar
    local barPos = HARFDB.barPosition
    local barWidth = HARFDB.barWidth
    bar:SetParent(UIParent)
    bar:ClearAllPoints()
    bar:SetPoint(barPos, parent, barPos)
    if barPos == 'topRight' then
        if barWidth == 'full' then
            bar:SetPoint('TOPLEFT', parent, 'TOPLEFT')
        else
            bar:SetPoint('TOPLEFT', parent, 'TOP')
        end
    elseif barPos == 'topLeft' then
        if barWidth == 'full' then
            bar:SetPoint('TOPRIGHT', parent, 'TOPRIGHT')
        else
            bar:SetPoint('TOPRIGHT', parent, 'TOP')
        end
    elseif barPos == 'bottomRight' then
        if barWidth == 'full' then
            bar:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT')
        else
            bar:SetPoint('BOTTOMLEFT', parent, 'BOTTOM')
        end
    elseif barPos == 'bottomLeft' then
        if barWidth == 'full' then
            bar:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT')
        else
            bar:SetPoint('BOTTOMRIGHT', parent, 'BOTTOM')
        end
    end
    bar:SetHeight(HARFDB.barHeight)
    bar:Hide()
end

function Util.DandersCompat()
    return HARFDB.dandersCompat and DandersFrames_IsReady and DandersFrames_IsReady()
end

--Connects units to the default frames
function Util.MapOutUnits()
    for groupType, units in pairs(Data.unitList) do
        for unit, _ in pairs(units) do
            local elements = Data.unitList[groupType][unit]
            elements.frame = nil
            elements.centerIcon = nil
            elements.isColored = false
            elements.defensive.frame = nil
            elements.name = nil
            wipe(elements.buffs)
            wipe(elements.debuffs)
        end
    end
    local groupType = IsInRaid() and 'raid' or 'party'
    local unitList = Util.GetRelevantList()
    local frameList = Data.frameList[groupType]
    for _, frameString in ipairs(frameList) do
        local frame = _G[frameString]
        if frame and frame.unit then
            local unitElements = unitList[frame.unit]
            unitElements.frame = frameString
            unitElements.centerIcon = frameString .. 'CenterStatusIcon'
            unitElements.defensive.frame = frameString
            unitElements.name = frameString .. 'Name'
            Util.AttachElements(unitElements, frame)
            for i = 1, 6 do
                if i <= 3 then
                    unitElements.debuffs[i] = frameString .. 'Debuff' .. i
                end
                unitElements.buffs[i] = frameString .. 'Buff' .. i
            end
        end
    end

    if Util.DandersCompat() then
        for unit, unitElements in pairs(unitList) do
            local frame = DandersFrames_GetFrameForUnit(unit)
            if frame then
                Util.AttachElements(unitElements, frame)
                local icon = unitElements.trackingIcon
                icon:SetParent(frame)
                icon:SetFrameLevel(frame:GetFrameLevel() + 10)
                local bar = unitElements.displayBar
                bar:SetParent(frame)
                bar:SetFrameLevel(frame:GetFrameLevel() + 10)
            end
        end
    end
end

--We hook into the function that recolors the health bars
hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
    --check if this unit frame is one of the ones we have mapped
    local unitList = Util.GetRelevantList()
    if frame.unit and unitList[frame.unit] and
    --Confirm the addon is setup and we care about recoloring bars
    HARFDB.buffTracking and HARFDB.trackingType == 'color'
    then
        --See if this frame is supposed to be colored, if so recolor it
        local elements = unitList[frame.unit]
        if elements and elements.isColored then
            local healthBar = frame.healthBar
            local trackingColor = CreateColorFromHexString(HARFDB.trackingColor)
            healthBar:SetStatusBarColor(trackingColor.r, trackingColor.g, trackingColor.b)
        end
    end
end)
