local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local Debug = NS.Debug
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

    local groupSize = GetNumGroupMembers() or 0
    local groupType = IsInRaid() and 'raid' or 'party'
    for i = 1, groupSize do
        local unit = groupType .. i
        if UnitExists(unit) and not UnitIsUnit(unit, 'player') then
            local unitName = UnitName(unit)
            if unitName and unitName ~= '' and not selectedNames[unitName] then
                table.insert(spotlightNameList, { text = unitName })
            end
        end
    end

    return spotlightNameList
end

--Use the spotlight name list to map out where each frame is supposed to go
function Util.MapSpotlightGroups()
    --Reset the current lists
    wipe(Data.spotlightFrames)
    local units = Options.spotlight.names
    local frames = Util.GetActiveFrameList()
    local seenUnits = {}
    for _, frameString in ipairs(frames) do
        local currentFrame = _G[frameString]
        if currentFrame and currentFrame.unit then
            local unit = currentFrame.unit
            if not UnitIsUnit(unit, 'player') and not seenUnits[unit] then --The player can't be spotlight
                seenUnits[unit] = true
                local unitName = UnitName(unit)
                if unitName and units[unitName] then
                    Data.spotlightFrames[frameString] = true
                end
            end
        end
    end
end

--Use the mapped spotlight anchors to attach the frames where they are supposed to go
function Util.ReanchorSpotlights()
    local spotlightFrame = Ui.GetSpotlightFrame()
    if spotlightFrame then
        local frameList = Util.GetActiveFrameList()
        local firstSpotlight, previousSpotlight, spotlightCount = false, nil, 0
        for index, frameString in ipairs(frameList) do
            local frame = _G[frameString]
            if frame then
                if Data.spotlightFrames[frameString] then
                    for i = #frameList, index, -1 do
                        local currentFrame = _G[frameList[i]]
                        local nextFrame = _G[frameList[i-1]]
                        if currentFrame and nextFrame then
                            local _, _, _, xOff, yOff = nextFrame:GetPoint()
                            currentFrame:ClearAllPoints()
                            currentFrame:SetPoint('TOPLEFT', xOff, yOff)
                        end
                    end
                    frame:ClearAllPoints()
                    if not firstSpotlight then
                        firstSpotlight = frame
                        frame:SetPoint('TOP', spotlightFrame, 'TOP')
                    else
                        local childPoint, parentFrame, parentPoint
                        if Options.spotlight.grow == 'right' then
                            if spotlightCount == Options.spotlight.groupSize then
                                childPoint, parentFrame, parentPoint = 'TOP', firstSpotlight, 'BOTTOM'
                            else
                                childPoint, parentFrame, parentPoint = 'LEFT', previousSpotlight, 'RIGHT'
                            end
                        else
                            if spotlightCount == Options.spotlight.groupSize then
                                childPoint, parentFrame, parentPoint = 'LEFT', firstSpotlight, 'RIGHT'
                            else
                                childPoint, parentFrame, parentPoint = 'TOP', previousSpotlight, 'BOTTOM'
                            end
                        end
                        frame:SetPoint(childPoint, parentFrame, parentPoint)
                    end
                    previousSpotlight = frame
                    spotlightCount = spotlightCount + 1
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
    local unitList = Data.unitList
    local frameList = Util.GetActiveFrameList()
    for _, frameString in ipairs(frameList) do
        local frame = _G[frameString]
        if frame and frame.unit then
            local unitElements = unitList[frame.unit]
            if unitElements then
                unitElements.frame = frameString
                unitElements.centerIcon = frameString .. 'CenterStatusIcon'
                unitElements.roleIcon = frameString .. 'RoleIcon'
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
                --Reset overshields just in case
                if unitElements.overshield then
                    Util.UpdateOvershields(frame.unit)
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

function Util.IsSpotlightActive()
    local enabledOption = Options.enableSpotlight
    if enabledOption == 3 then return true end
    if IsInRaid() and enabledOption == 1 then return true end
    if IsInGroup() and enabledOption == 2 then return true end
    return false
end

function Util.GetActiveFrameList()
    if IsInRaid() then
        if CompactRaidFrame1 and CompactRaidFrame1.unit then
            return Data.frameList.raidCombined
        else
            return Data.frameList.raidGroups
        end
    elseif IsInGroup() then
        return Data.frameList.party
    end
    return {}
end