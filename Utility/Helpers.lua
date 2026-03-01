local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

function Util.MakeAuraSignature(passesRaid, passesRic, passesExt, passesDisp)
    return (passesRaid and '1' or '0') .. ':' .. (passesRic and '1' or '0') .. ':' .. (passesExt and '1' or '0') .. ':' .. (passesDisp and '1' or '0')
end

function Util.GetAuraSignatures(spec)
    if not Data.auraSignatures[spec] then
        local signatures = {}
        local specData = Data.specInfo[spec]
        if specData and specData.auras then
            for _, auraData in pairs(specData.auras) do
                if auraData.secret then
                    signatures[auraData.signature] = auraData.name
                end
            end
        end
        Data.auraSignatures[spec] = signatures
    end
    return Data.auraSignatures[spec]
end

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
    local spotlight = Options.spotlight or {}
    local selectedNames = spotlight.names or {}
    local spotlightNameList = {}
    for name, _ in pairs(selectedNames) do
        table.insert(spotlightNameList, { text = name })
    end

    if IsInRaid() then
        local groupSize = GetNumGroupMembers() or 0
        for i = 1, groupSize do
            local unit = 'raid' .. i
            if UnitExists(unit) and not UnitIsUnit(unit, 'player') then
                local unitName = UnitName(unit)
                if unitName and unitName ~= '' and not selectedNames[unitName] then
                    table.insert(spotlightNameList, { text = unitName })
                end
            end
        end
    end

    return spotlightNameList
end

--Use the spotlight name list to map out where each frame is supposed to go
function Util.MapSpotlightAnchors()
    --Reset the current lists
    wipe(Data.spotlightAnchors.spotlights)
    wipe(Data.spotlightAnchors.defaults)
    local units = Options.spotlight.names
    local frames = Data.frameList.raid --Spotlight only works in raid
    local seenUnits = {}
    for _, frameString in ipairs(frames) do
        local currentFrame = _G[frameString]
        if currentFrame and currentFrame.unit then
            local unit = currentFrame.unit
            if unit ~= 'player' and not seenUnits[unit] then --The player can't be spotlight
                seenUnits[unit] = true
                local unitName = UnitName(unit)
                if unitName and units[unitName] then
                    table.insert(Data.spotlightAnchors.spotlights, frameString)
                else
                    table.insert(Data.spotlightAnchors.defaults, frameString)
                end
            end
        end
    end
end

--Use the mapped spotlight anchors to attach the frames where they are supposed to go
function Util.ReanchorSpotlights()
    local spotlightFrame = Ui.GetSpotlightFrame()
    if not spotlightFrame then
        return
    end

    for index, frameString in ipairs(Data.spotlightAnchors.spotlights) do
        local frame = _G[frameString]
        if frame then
            frame:ClearAllPoints()
            --The first frame goes attached directly to the spotlight anchor
            if index == 1 then
                frame:SetPoint('TOP', spotlightFrame, 'TOP')
            --Other frames go attached to the previous one in the list
            else
                local previousFrame = _G[Data.spotlightAnchors.spotlights[index - 1]]
                if previousFrame then
                    local childPoint, parentPoint
                    if Options.spotlight.grow == 'right' then
                        childPoint, parentPoint = 'LEFT', 'RIGHT'
                    else
                        childPoint, parentPoint = 'TOP', 'BOTTOM'
                    end
                    frame:SetPoint(childPoint, previousFrame, parentPoint)
                else
                    frame:SetPoint('TOP', spotlightFrame, 'TOP')
                end
            end
        end
    end
    --Similar logic for the frames that remain in the default position
    --This currently has a bug if the user has 'separate tanks' turned on, because the tanks' targets and targetoftarget also use frames but of different size
    for index, frameString in ipairs(Data.spotlightAnchors.defaults) do
        local frame = _G[frameString]
        if frame then
            frame:ClearAllPoints()
            if index == 1 then
                frame:SetPoint('TOPLEFT', 'CompactRaidFrameContainer', 'TOPLEFT')
            else
                --This 5 is a magic number that assumes people have 5 frames before breaking into a new row (needs updating)
                if (index - 1) % 5 == 0 then
                    local previousFrame = _G[Data.spotlightAnchors.defaults[index - 5]]
                    if previousFrame then
                        frame:SetPoint('TOP', previousFrame, 'BOTTOM')
                    end
                else
                    local previousFrame = _G[Data.spotlightAnchors.defaults[index - 1]]
                    if previousFrame then
                        frame:SetPoint('LEFT', previousFrame, 'RIGHT')
                    end
                end
            end
        end
    end
end

function Util.HandlePlayerSpecializationChanged()
    local previousSpec = Data.playerSpec
    Util.UpdatePlayerSpec()
    if previousSpec ~= Data.playerSpec then
        Util.MapOutUnits()
        local designer = Ui.GetDesignerFrame()
        designer.RefreshPreview()
    end
end

--Update unit data of current group members
function Util.MapOutUnits()
    --Refresh some player data too
    Util.UpdatePlayerSpec()

    --Remove all current data on the unit lists
    for _, elements in pairs(Data.unitList) do
        elements.frame = nil
        elements.centerIcon = nil
        elements.isColored = false
        elements.defensive.frame = nil
        elements.name = nil
        wipe(elements.buffs)
        wipe(elements.debuffs)
        wipe(elements.extFrames)
        if elements.indicatorOverlay then
            elements.indicatorOverlay:Delete()
            elements.indicatorOverlay = nil
        end
        if next(elements.extIndicatorOverlays) then
            for index, overlay in ipairs(elements.extIndicatorOverlays) do
                overlay:Delete()
                elements.extIndicatorOverlays[index] = nil
            end
        end
    end

    --If we are using external frames, call a cache refresh
    if Options.extFrames then
        local LGF = LibStub('LibGetFrame-1.0')
        Data.updatingExternalFrames = true
        LGF:ScanForUnitFrames()
    end

    --We check the frames for the party or raid to find where each unit is
    local currentGroupType = IsInRaid() and 'raid' or 'party'
    local unitList = Data.unitList
    local frameList = Data.frameList[currentGroupType]
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

    if Data.playerSpec then
        for _, units in pairs(Data.unitList) do
            for unit, _ in pairs(units) do
                if UnitIsVisible(unit) then Core.UpdateAuraStatus(unit) end
            end
        end
    end
end

function Util.GetExternalFrames()
    if SavedIndicators[Data.playerSpec] and #SavedIndicators[Data.playerSpec] > 0 then
        local LGF = LibStub('LibGetFrame-1.0')
        for unit, elements in pairs(Data.unitList) do
            local extFrames = LGF.GetUnitFrame(unit, { ignoreFrames = Data.ignoredFrames, returnAll = true })
            if extFrames then
                for _, extFrame in pairs(extFrames) do
                    table.insert(elements.extFrames, extFrame)
                    local indicatorOverlay = Ui.CreateIndicatorOverlay(SavedIndicators[Data.playerSpec])
                    indicatorOverlay.unit = unit
                    indicatorOverlay:AttachToFrame(extFrame)
                    indicatorOverlay:Show()
                    table.insert(elements.extIndicatorOverlays, indicatorOverlay)
                end
            end
        end
    end
end

function Util.UpdatePlayerSpec()
    local class = UnitClassBase('player')
    local spec = C_SpecializationInfo.GetSpecialization()
    if Data.specMap[class .. '_' .. spec] then
        Data.playerSpec = Data.specMap[class .. '_' .. spec]
    else
        Data.playerSpec = nil
    end
end

--it says "is from player" but really we are checking it is not a trash buff
function Util.IsAuraFromPlayer(unit, auraId)
    local passesRic = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraId, 'PLAYER|HELPFUL|RAID_IN_COMBAT')
    local passesRaid = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraId, 'PLAYER|HELPFUL|RAID')
    return passesRic or passesRaid
end

--Here we handle encoding and decoding for export and import
function Util.EncodeIndicators(spec)
    local indicators = SavedIndicators[spec]
    if indicators then
        local dataToExport = {
            spec = spec,
            indicators = indicators
        }
        local jsonData = C_EncodingUtil.SerializeJSON(dataToExport)
        local compressedJson = C_EncodingUtil.CompressString(jsonData, Enum.CompressionMethod.Gzip)
        local baseText = C_EncodingUtil.EncodeBase64(compressedJson)
        return baseText
    end
end

function Util.DecodeIndicators(string)
    local compressedJson = C_EncodingUtil.DecodeBase64(string)
    if compressedJson then
        local success, jsonData = pcall(C_EncodingUtil.DecompressString, compressedJson, Enum.CompressionMethod.Gzip)
        if success then
            local importedData = C_EncodingUtil.DeserializeJSON(jsonData)
            if importedData and importedData.spec and importedData.indicators then
                Util.DisplayEncodingPopup('confirm', importedData)
            end
        else
            print('|cnNORMAL_FONT_COLOR:AdvancedRaidFrames:|r Error importing indicators.')
        end
    end
end