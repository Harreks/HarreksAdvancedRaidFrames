local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

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

--Return the list of frames depending on raid or party
function Util.GetRelevantList()
    return IsInRaid() and Data.unitList.raid or Data.unitList.party
end

--Yes i know what "equal" means. We check if time1 is *close* to time2
function Util.AreTimestampsEqual(time1, time2, delay)
    local castDelay = delay or 0.1
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
        if Options.spotlight.names then
            for name, _ in pairs(Options.spotlight.names) do
                table.insert(raidNameList, { text = name })
            end
        end
        for frameString, _ in pairs(frames) do
            if _G[frameString] then
                local frame = _G[frameString]
                local unitName = UnitName(frame.unit)
                if not UnitIsUnit(frame.unit, 'player') and not Options.spotlight.names[unitName] then
                    table.insert(raidNameList, { text = unitName })
                end
            end
        end
        return raidNameList
    else
        return Options.spotlight.names
    end
end

--Use the spotlight name list to map out where each frame is supposed to go
function Util.MapSpotlightAnchors()
    --Reset the current lists
    wipe(Data.spotlightAnchors.spotlights)
    wipe(Data.spotlightAnchors.defaults)
    local units = Options.spotlight.names
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
            if Options.spotlight.grow == 'right' then
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

--Update unit data of current group members
function Util.MapOutUnits()
    --Refresh some player data too
    Util.UpdatePlayerSpec()
    --Will use this to add handling for pain sup applying atonement in the future
    if Data.playerSpec == 'MistweaverMonk' then
        Data.state.extras.moh = C_SpellBook.IsSpellKnown(450529) and true or false
    end
    --Remove all current data on the unit lists
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
            if elements.indicatorOverlay then
                elements.indicatorOverlay:Delete()
                elements.indicatorOverlay = nil
            end

            if #elements.extraFrames > 0 then
                for _, extraFrameData in ipairs(elements.extraFrames) do
                    if extraFrameData.frame and not extraFrameData.indicatorOverlay then
                        local indicatorOverlay = Ui.CreateIndicatorOverlay(SavedIndicators[Data.playerSpec])
                        if indicatorOverlay then
                            indicatorOverlay.unit = unit
                            indicatorOverlay:AttachToFrame(extraFrameData.frame)
                            indicatorOverlay:Show()
                            indicatorOverlay.extraFrameIndex = extraFrameData.index
                            if extraFrameData.coloringFunc and type(extraFrameData.coloringFunc) == 'function' then
                                indicatorOverlay.coloringFunc = extraFrameData.coloringFunc
                            end
                            extraFrameData.indicatorOverlay = indicatorOverlay
                        end
                    end
                end
            end
        end
    end
    --We check the frames for the party or raid to find where each unit is
    local groupType = IsInRaid() and 'raid' or 'party'
    local unitList = Util.GetRelevantList()
    local frameList = Data.frameList[groupType]
    for _, frameString in ipairs(frameList) do
        local frame = _G[frameString]
        if frame and frame.unit then
            local unitElements = unitList[frame.unit]
            if unitElements then
                unitElements.frame = frameString
                unitElements.centerIcon = frameString .. 'CenterStatusIcon'
                unitElements.defensive.frame = frameString
                unitElements.name = frameString .. 'Name'
                for i = 1, 6 do
                    if i <= 3 then
                        unitElements.debuffs[i] = frameString .. 'Debuff' .. i
                    end
                    unitElements.buffs[i] = frameString .. 'Buff' .. i
                end
                --Don't install overlays if theres no indicators set up
                if SavedIndicators[Data.playerSpec] and #SavedIndicators[Data.playerSpec] > 0 then
                    local indicatorOverlay = Ui.CreateIndicatorOverlay(SavedIndicators[Data.playerSpec])
                    indicatorOverlay.unit = frame.unit
                    indicatorOverlay:AttachToFrame(frame)
                    indicatorOverlay:Show()
                    unitElements.indicatorOverlay = indicatorOverlay
                end
            end
        end
    end
end

function Util.UpdatePlayerSpec()
    local class = UnitClassBase('player')
    local spec = C_SpecializationInfo.GetSpecialization()
    Data.playerSpec = Data.specMap[class .. '_' .. spec]
end

--It says "is from player" but really we are checking that it passes the full raid in combat filter
--The second param is auraInstanceId, not the full aura, same for all the other checks
function Util.IsAuraFromPlayer(unit, auraId)
    local isFromPlayer = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraId, 'PLAYER|HELPFUL|RAID_IN_COMBAT')
    return isFromPlayer
end

--This is an extra function for weirdo buffs, attempting to track things not in raid in combat
function Util.DoesAuraPassRaidFilter(unit, auraId)
    local passesRaidFilter = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraId, 'PLAYER|HELPFUL|RAID')
    return passesRaidFilter
end

--Some spells are in raid in combat but not in raid, this is a quick check to know if this is one of them
function Util.DoesAuraDifferBetweenFilters(unit, auraId)
    local passesRaid = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraId, 'PLAYER|HELPFUL|RAID')
    local passesRaidInCombat = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraId, 'PLAYER|HELPFUL|RAID_IN_COMBAT')
    return passesRaid ~= passesRaidInCombat
end

function Util.IsExternalDefensive(unit, auraId)
    local isExternal = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraId, 'PLAYER|HELPFUL|EXTERNAL_DEFENSIVE')
    return isExternal
end

function Util.MapEngineFunctions()
    local functionMap = Data.engineFunctions
    for spec, _ in pairs(Data.specInfo) do
        functionMap[spec] = Core['Parse' .. spec .. 'Buffs']
    end
end
