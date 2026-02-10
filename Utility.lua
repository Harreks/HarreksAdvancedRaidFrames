local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core
local Settings = NS.Settings

--Function to format decimals out for display
function Util.FormatForDisplay(number)
    return math.floor(number * 10 + 0.5) / 10
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
    wipe(Data.unitFrameMap)
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
    return IsInRaid() and Data.frameList.raid or Data.frameList.party
end

--Yes i know what "equal" means
function Util.AreTimestampsEqual(time1, time2)
    if time1 and time2 then
        return time1 >= time2 and time1 <= time2 + Data.allowedCastDelay
    else
        return false
    end
end

function Util.GetSpotlightNames()
    if IsInRaid() then
        local frames = Util.GetRelevantList()
        local raidNameList = {}
        if Data.currentLayout and HARFDB[Data.currentLayout] and HARFDB[Data.currentLayout].spotlight.names then
            for name, _ in pairs(HARFDB[Data.currentLayout].spotlight.names) do
                table.insert(raidNameList, { text = name })
            end
        end
        for frameString, _ in pairs(frames) do
            if _G[frameString] then
                local frame = _G[frameString]
                local unitName = UnitName(frame.unit)
                if not UnitIsUnit(frame.unit, 'player') and not HARFDB[Data.currentLayout].spotlight.names[unitName] then
                    table.insert(raidNameList, { text = unitName })
                end
            end
        end
        return raidNameList
    else
        return HARFDB[Data.currentLayout].spotlight.names
    end
end

--Use the spotlight name list to map out where each frame is supposed to go
function Util.MapSpotlightAnchors()
    --Reset the current lists
    wipe(Data.spotlightAnchors.spotlights)
    wipe(Data.spotlightAnchors.defaults)
    local units = HARFDB[Data.currentLayout].spotlight.names
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
            if HARFDB[Data.currentLayout].spotlight.grow == 'right' then
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
    local elements = Util.GetRelevantList()[Data.unitFrameMap[unit]]
    local buffIcon = elements.buffTrackingIcon
    local frame = _G[Data.unitFrameMap[unit]]
    local trackingType = HARFDB[Data.currentLayout].trackingType
    local trackingColor = HARFDB[Data.currentLayout].trackingColor
    --If the tracking is an icon we update it and show it
    if trackingType == 'icon' and buff then
        buffIcon.texture:SetTexture(buff.icon)
        local duration = C_UnitAuras.GetAuraDuration(unit, buff.auraInstanceID)
        buffIcon.cooldown:SetCooldownFromDurationObject(duration)
        buffIcon:Show()
    --If the tracking is bar recoloring we recolor the bar and mark it as colored in the elements
    elseif trackingType == 'color' then
        local healthBar = frame.healthBar
        healthBar:SetStatusBarColor(trackingColor.r, trackingColor.g, trackingColor.b)
        elements.isColored = true
    end

    if HARFDB[Data.currentLayout].dandersCompat and DandersFrames_IsReady and DandersFrames_IsReady() then
        local danderFrame = DandersFrames_GetFrameForUnit(unit)
        local r,g,b = danderFrame.healthBar:GetStatusBarColor()
        if not Data.dandersColors[unit] then
            Data.dandersColors[unit] = { r = r, g = g, b = b}
        end
        danderFrame.healthBar:SetStatusBarColor(trackingColor.r, trackingColor.g, trackingColor.b)
    end
end

function Util.HideTrackedBuff(unit)
    local elements = Util.GetRelevantList()[Data.unitFrameMap[unit]]
    if elements then
        local buffIcon = elements.buffTrackingIcon
        local frame = _G[Data.unitFrameMap[unit]]
        buffIcon:Hide()
        elements.isColored = false
        CompactUnitFrame_UpdateHealthColor(frame)

        if HARFDB[Data.currentLayout].dandersCompat and Data.dandersColors[unit] and DandersFrames_IsReady and DandersFrames_IsReady() then
            local danderFrame = DandersFrames_GetFrameForUnit(unit)
            local originalColor = Data.dandersColors[unit]
            danderFrame.healthBar:SetStatusBarColor(originalColor.r, originalColor.g, originalColor.b)
            Data.dandersColors[unit] = nil
        end
    end
end

--We hook into the function that recolors the health bars
hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
    --check if this unit frame is one of the ones we have mapped
    if frame.unit and Data.unitFrameMap[frame.unit] and
    --Confirm the addon is setup and we care about recoloring bars
    Data.currentLayout and HARFDB[Data.currentLayout].buffTracking and HARFDB[Data.currentLayout].trackingType == 'color'
    then
        --See if this frame is supposed to be colored, if so recolor it
        local elements = Util.GetRelevantList()[Data.unitFrameMap[frame.unit]]
        if elements.isColored then
            local healthBar = frame.healthBar
            local trackingColor = HARFDB[Data.currentLayout].trackingColor
            healthBar:SetStatusBarColor(trackingColor.r, trackingColor.g, trackingColor.b)
        end
    end
end)
