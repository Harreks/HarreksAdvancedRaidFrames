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
local LAMB = NS.LibAdvancedMenuBuilder
Util.FormatForDisplay = LAMB.FormatForDisplay

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
        local classColor = Util.GetClassColorForUnit(name)
        local coloredName
        if classColor then
            coloredName = '|c' .. classColor:GenerateHexColor() .. name .. '|r'
        else
            coloredName = name
        end
        table.insert(spotlightNameList, { text = coloredName, value = name })
    end

    local groupSize = GetNumGroupMembers() or 0
    local groupType = IsInRaid() and 'raid' or 'party'
    for i = 1, groupSize do
        local unit = groupType .. i
        if UnitExists(unit) and not UnitIsUnit(unit, 'player') then
            local unitName = UnitName(unit)
            local classColor = Util.GetClassColorForUnit(unit)
            if unitName and unitName ~= '' and not selectedNames[unitName] then
                local coloredName = unitName
                if classColor then coloredName = '|c' .. classColor:GenerateHexColor() .. unitName .. '|r' end
                table.insert(spotlightNameList, { text = coloredName, value = unitName })
            end
        end
    end

    return spotlightNameList
end

-- Update the spotlight frames by scanning group members and generating custom frames
function Util.UpdateSpotlightFrames()
    local spotlightNameList = Options.spotlight.names
    local spotlightUnitList = {}
    local groupSize = GetNumGroupMembers() or 0
    local groupType = IsInRaid() and 'raid' or 'party'
    for i = 1, groupSize do
        local unit = groupType .. i
        if UnitExists(unit) and not UnitIsUnit(unit, 'player') then
            local unitName = UnitName(unit)
            if unitName and spotlightNameList[unitName] then
                table.insert(spotlightUnitList, unit)
            end
        end
    end
    Ui.CreateSpotlights(spotlightUnitList)
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
        elements.isColored = false
        elements.name = nil
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
                unitElements.roleIcon = frameString .. 'RoleIcon'
                unitElements.name = frameString .. 'Name'
                --Don't install overlays if theres no indicators set up
                if SavedIndicators[Data.playerSpec] and #SavedIndicators[Data.playerSpec] > 0 then
                    local indicatorOverlay = Ui.CreateIndicatorOverlay(SavedIndicators[Data.playerSpec])
                    indicatorOverlay.unit = frame.unit
                    indicatorOverlay:AttachToFrame(frame)
                    indicatorOverlay:Show()
                    unitElements.indicatorOverlay = indicatorOverlay
                    Util.RefreshIndicatorsWithSavedData(frame.unit)
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
        local unitList = Data.unitList
        for unit, elements in pairs(Data.unitList) do
            if unitList[unit] then
                local extFrames = LGF.GetUnitFrame(unit, { ignoreFrames = Data.ignoredFrames, returnAll = true })
                if extFrames then
                    for _, extFrame in pairs(extFrames) do
                        table.insert(elements.extFrames, extFrame)
                        local indicatorOverlay = Ui.CreateIndicatorOverlay(SavedIndicators[Data.playerSpec])
                        indicatorOverlay.unit = unit
                        indicatorOverlay:AttachToFrame(extFrame)
                        indicatorOverlay:Show()
                        table.insert(elements.extIndicatorOverlays, indicatorOverlay)
                        Util.RefreshIndicatorsWithSavedData(unit)
                    end
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
    if IsInRaid() and Options.enableSpotlight then return true end
    return false
end

function Util.GetActiveFrameList()
    if IsInRaid() then
        local displayType = EditModeManagerFrame:GetSettingValue(Enum.EditModeSystem.UnitFrame, Enum.EditModeUnitFrameSystemIndices.Raid, Enum.EditModeUnitFrameSetting.RaidGroupDisplayType)
        if displayType == 2 or displayType == 3 then
            return Data.frameList.raidCombined
        else
            return Data.frameList.raidGroups
        end
    elseif IsInGroup() then
        return Data.frameList.party
    end
    return {}
end

function Util.IsValidUnitForAuraCheck(unit)
    if IsInRaid() then
        if string.match(unit, "^raid%d+$") then
            return true
        else
            return false
        end
    else
        return true
    end
end

function Util.AuraPassesFilter(unit, auraInstanceId, filter)
    return not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraInstanceId, filter)
end

function Util.ToggleEnemyCastTrackingEvents(enabled)
    if Core.EnemyCastTracker and Core.PlayerTargetingTracker then
        if enabled then
            for _, event in ipairs(Data.targetedSpellsEvents.casts) do
                Core.EnemyCastTracker:RegisterEvent(event)
            end
            for _, event in ipairs(Data.targetedSpellsEvents.targeting) do
                Core.PlayerTargetingTracker:RegisterEvent(event)
            end
        else
            Core.EnemyCastTracker:UnregisterAllEvents()
        end
    end
end
