local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local L = NS.L
local SavedIndicators = HARFDB.savedIndicators

local IMPORT_EXPORT_PREFIX = 'HARF1:'

local function deepCopyValue(value)
    if type(value) ~= 'table' then
        return value
    end

    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = deepCopyValue(entry)
    end
    return copy
end

local function ensureSpecIndicators(spec)
    if not SavedIndicators[spec] then
        SavedIndicators[spec] = {}
    end
    return SavedIndicators[spec]
end

local function isAllowedDropdownValue(dropdownType, value)
    local dropdownData = Data.dropdownOptions[dropdownType]
    if not (dropdownData and dropdownData.options) then
        return false
    end

    for _, optionValue in ipairs(dropdownData.options) do
        if optionValue == value then
            return true
        end
    end

    return false
end

local function clampNumber(value, minValue, maxValue)
    if type(value) ~= 'number' then
        return nil
    end
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function sanitizeColorTable(value, defaultColor)
    if type(value) ~= 'table' then
        return deepCopyValue(defaultColor)
    end

    local color = deepCopyValue(defaultColor)
    local channels = { 'r', 'g', 'b', 'a' }
    for _, channel in ipairs(channels) do
        local channelValue = value[channel]
        if type(channelValue) == 'number' then
            if channelValue < 0 then
                color[channel] = 0
            elseif channelValue > 1 then
                color[channel] = 1
            else
                color[channel] = channelValue
            end
        end
    end

    return color
end

local function sanitizeImportedIndicator(indicator, spec)
    if type(indicator) ~= 'table' then
        return nil
    end

    local indicatorType = indicator.Type
    if type(indicatorType) ~= 'string' or not Data.indicatorTypeSettings[indicatorType] then
        return nil
    end

    local spell = indicator.Spell
    local specInfo = Data.specInfo[spec]
    if type(spell) ~= 'string' or not (specInfo and specInfo.auras and specInfo.auras[spell]) then
        return nil
    end

    local sanitized = Util.GetDefaultSettingsForIndicator(indicatorType)
    sanitized.Spell = spell

    if indicatorType == 'icon' or indicatorType == 'square' then
        if type(indicator.Position) == 'string' and isAllowedDropdownValue('iconPosition', indicator.Position) then
            sanitized.Position = indicator.Position
        end

        local size = clampNumber(indicator.Size, 5, 50)
        if size then sanitized.Size = size end

        local xOffset = clampNumber(indicator.xOffset, -50, 50)
        if xOffset then sanitized.xOffset = xOffset end

        local yOffset = clampNumber(indicator.yOffset, -50, 50)
        if yOffset then sanitized.yOffset = yOffset end

        local textSize = clampNumber(indicator.textSize, 0.5, 3)
        if textSize then sanitized.textSize = textSize end
    end

    if indicatorType == 'icon' then
        if type(indicator.showText) == 'boolean' then sanitized.showText = indicator.showText end
        if type(indicator.showTexture) == 'boolean' then sanitized.showTexture = indicator.showTexture end
    elseif indicatorType == 'square' then
        sanitized.Color = sanitizeColorTable(indicator.Color, sanitized.Color)
        sanitized.BackgroundColor = sanitizeColorTable(indicator.BackgroundColor, sanitized.BackgroundColor)

        if type(indicator.showCooldown) == 'boolean' then sanitized.showCooldown = indicator.showCooldown end
        if type(indicator.showCooldownText) == 'boolean' then sanitized.showCooldownText = indicator.showCooldownText end
        if type(indicator.showText) == 'boolean' then sanitized.showText = indicator.showText end

        if type(indicator.cooldownStyle) == 'string' and isAllowedDropdownValue('squareCooldownStyle', indicator.cooldownStyle) then
            sanitized.cooldownStyle = indicator.cooldownStyle
        end
        if type(indicator.depleteDirection) == 'string' and isAllowedDropdownValue('squareDepleteDirection', indicator.depleteDirection) then
            sanitized.depleteDirection = indicator.depleteDirection
        end
    elseif indicatorType == 'bar' then
        sanitized.Color = sanitizeColorTable(indicator.Color, sanitized.Color)
        sanitized.BackgroundColor = sanitizeColorTable(indicator.BackgroundColor, sanitized.BackgroundColor)

        if type(indicator.Position) == 'string' and isAllowedDropdownValue('barPosition', indicator.Position) then
            sanitized.Position = indicator.Position
        end
        if type(indicator.Scale) == 'string' and isAllowedDropdownValue('barScale', indicator.Scale) then
            sanitized.Scale = indicator.Scale
        end
        if type(indicator.Orientation) == 'string' and isAllowedDropdownValue('barOrientation', indicator.Orientation) then
            sanitized.Orientation = indicator.Orientation
        end

        local size = clampNumber(indicator.Size, 5, 50)
        if size then sanitized.Size = size end

        local offset = clampNumber(indicator.Offset, -50, 50)
        if offset then sanitized.Offset = offset end
    elseif indicatorType == 'healthColor' then
        sanitized.Color = sanitizeColorTable(indicator.Color, sanitized.Color)
    end

    return sanitized
end

function Ui.DesignerExportSpecIndicators(spec)
    local encoder = C_EncodingUtil
    if not (encoder and encoder.SerializeJSON and encoder.CompressString and encoder.EncodeBase64) then
        return nil, L.DESIGNER_IMPORT_EXPORT_UNSUPPORTED
    end

    local indicators = ensureSpecIndicators(spec)
    local payload = {
        version = 1,
        spec = spec,
        indicators = deepCopyValue(indicators)
    }

    local okSerialize, jsonPayload = pcall(encoder.SerializeJSON, payload)
    if not okSerialize or type(jsonPayload) ~= 'string' or jsonPayload == '' then
        return nil, L.DESIGNER_EXPORT_FAILED
    end

    local okCompress, compressedPayload = pcall(encoder.CompressString, jsonPayload)
    if not okCompress or type(compressedPayload) ~= 'string' or compressedPayload == '' then
        return nil, L.DESIGNER_EXPORT_FAILED
    end

    local okEncode, encodedPayload = pcall(encoder.EncodeBase64, compressedPayload)
    if not okEncode or type(encodedPayload) ~= 'string' or encodedPayload == '' then
        return nil, L.DESIGNER_EXPORT_FAILED
    end

    return IMPORT_EXPORT_PREFIX .. encodedPayload
end

function Ui.DesignerImportSpecIndicators(spec, rawText)
    local encoder = C_EncodingUtil
    if not (encoder and encoder.DeserializeJSON and encoder.DecompressString and encoder.DecodeBase64) then
        return nil, L.DESIGNER_IMPORT_EXPORT_UNSUPPORTED
    end

    if type(rawText) ~= 'string' or rawText == '' then
        return nil, L.DESIGNER_IMPORT_EMPTY
    end

    local compactInput = rawText:gsub('%s+', '')
    if compactInput == '' then
        return nil, L.DESIGNER_IMPORT_EMPTY
    end

    if compactInput:sub(1, #IMPORT_EXPORT_PREFIX) == IMPORT_EXPORT_PREFIX then
        compactInput = compactInput:sub(#IMPORT_EXPORT_PREFIX + 1)
    end

    local okDecode, compressedPayload = pcall(encoder.DecodeBase64, compactInput)
    if not okDecode or type(compressedPayload) ~= 'string' or compressedPayload == '' then
        return nil, L.DESIGNER_IMPORT_INVALID
    end

    local okDecompress, jsonPayload = pcall(encoder.DecompressString, compressedPayload)
    if not okDecompress or type(jsonPayload) ~= 'string' or jsonPayload == '' then
        return nil, L.DESIGNER_IMPORT_INVALID
    end

    local okDeserialize, payload = pcall(encoder.DeserializeJSON, jsonPayload)
    if not okDeserialize or type(payload) ~= 'table' then
        return nil, L.DESIGNER_IMPORT_INVALID
    end

    if payload.version ~= 1 or type(payload.indicators) ~= 'table' then
        return nil, L.DESIGNER_IMPORT_INVALID
    end

    if payload.spec and payload.spec ~= spec then
        return nil, string.format(L.DESIGNER_IMPORT_SPEC_MISMATCH_FMT, spec)
    end

    local sanitizedIndicators = {}
    local invalidCount = 0
    local totalCount = 0

    for _, indicator in ipairs(payload.indicators) do
        totalCount = totalCount + 1
        local sanitized = sanitizeImportedIndicator(indicator, spec)
        if sanitized then
            table.insert(sanitizedIndicators, sanitized)
        else
            invalidCount = invalidCount + 1
        end
    end

    if #sanitizedIndicators == 0 then
        return nil, L.DESIGNER_IMPORT_NO_VALID
    end

    return {
        indicators = sanitizedIndicators,
        invalidCount = invalidCount,
        totalCount = totalCount
    }
end

function Ui.ShowDesignerImportPopup(spec, onConfirm)
    if not StaticPopupDialogs.HARF_IMPORT_SPEC_INDICATORS then
        StaticPopupDialogs.HARF_IMPORT_SPEC_INDICATORS = {
            text = L.DESIGNER_IMPORT_POPUP_TEXT,
            button1 = L.DESIGNER_IMPORT_CONFIRM,
            button2 = CANCEL,
            hasEditBox = true,
            editBoxWidth = 360,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = STATICPOPUP_NUMDIALOGS,
            OnShow = function(self)
                local editBox = self.EditBox
                if editBox then
                    editBox:SetText('')
                    C_Timer.After(0.05, function()
                        if editBox and editBox:IsShown() then
                            editBox:SetFocus()
                            editBox:HighlightText()
                        end
                    end)
                end
            end,
            OnAccept = function(self, data)
                local editBox = self.EditBox
                local importText = editBox and editBox:GetText() or ''
                if data and data.onConfirm then
                    data.onConfirm(importText)
                end
            end,
            EditBoxOnEnterPressed = function(self)
                local parent = self:GetParent()
                if parent and parent.button1 then
                    parent.button1:Click()
                end
            end,
            EditBoxOnEscapePressed = function(self)
                local parent = self:GetParent()
                if parent then
                    parent:Hide()
                end
            end,
        }
    end

    local popup = StaticPopup_Show('HARF_IMPORT_SPEC_INDICATORS', string.format(L.DESIGNER_IMPORT_POPUP_TITLE_FMT, spec), nil, {
        onConfirm = onConfirm
    })

    if popup and popup.EditBox then
        popup.EditBox:SetMaxLetters(50000)
    end
end
