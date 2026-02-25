local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local L = NS.L
local LibStub = _G.LibStub
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options
local DesignerState = Ui.DesignerState

function Ui.PrintDesignerMessage(message)
    print('|cnNORMAL_FONT_COLOR:AdvancedRaidFrames|r: ' .. message)
end

function Ui.GetSpellIcon(spellKey)
    if spellKey and Data.textures and Data.textures[spellKey] then
        return Data.textures[spellKey]
    end
end

function Ui.BuildIconLabel(iconFileId, text)
    local label = tostring(text or '')
    if not iconFileId then
        return label
    end

    return string.format('|T%d:16:16:0:0:64:64:4:60:4:60|t  %s', iconFileId, label)
end

function Ui.EnsureEditingSpec()
    return DesignerState.EnsureEditingSpec()
end

function Ui.EnsureSpecIndicators(spec)
    return DesignerState.EnsureSpecIndicators(spec)
end

function Ui.ConfirmDesignerDelete(onConfirm)
    if not StaticPopupDialogs['HARF_CONFIRM_DELETE_INDICATOR'] then
        StaticPopupDialogs['HARF_CONFIRM_DELETE_INDICATOR'] = {
            text = L.DESIGNER_DELETE_CONFIRM_TEXT,
            button1 = ACCEPT,
            button2 = CANCEL,
            OnAccept = function(_, data)
                if data and data.onConfirm then
                    data.onConfirm()
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3
        }
    end

    StaticPopup_Show('HARF_CONFIRM_DELETE_INDICATOR', nil, nil, {
        onConfirm = onConfirm
    })
end

function Ui.GetDuplicateIndexForIndicator(indicators, targetIndex, indicator)
    if not (indicators and indicator and targetIndex) then
        return nil
    end

    local duplicateIndex = 0
    local spell = indicator.Spell
    local indicatorType = indicator.Type

    for index, existingIndicator in ipairs(indicators) do
        if existingIndicator and existingIndicator.Spell == spell and existingIndicator.Type == indicatorType then
            duplicateIndex = duplicateIndex + 1
            if index == targetIndex then
                return duplicateIndex
            end
        end
    end

    return nil
end

function Ui.GetLocalizedSpellLabel(spellKey, preferEchoVariantLabel)
    if not spellKey then
        return L.DESIGNER_UNKNOWN
    end

    if preferEchoVariantLabel then
        local echoedLabel = Ui.GetEchoVariantDisplayLabel(spellKey)
        if echoedLabel then
            return echoedLabel
        end
    end

    local spellId = Data.spellIds[spellKey]
    local localizedName = C_Spell.GetSpellName(spellId)
    if localizedName and localizedName ~= '' then
        return localizedName
    end

    return spellKey
end

function Ui.GetEchoVariantDisplayLabel(spellKey)
    if type(spellKey) ~= 'string' or spellKey == 'Echo' or not spellKey:find('^Echo') then
        return nil
    end

    local baseSpellKey = spellKey:gsub('^Echo', '', 1)
    if baseSpellKey == '' then
        return nil
    end

    local baseSpellLabel = Ui.GetLocalizedSpellLabel(baseSpellKey)
    if not baseSpellLabel or baseSpellLabel == '' then
        return nil
    end

    local echoedFormat = L.LABEL_ECHOED_SPELL_FMT
    if type(echoedFormat) == 'string' and echoedFormat:find('%s', 1, true) then
        return string.format(echoedFormat, baseSpellLabel)
    end

    local echoedPrefix = L.LABEL_ECHOED_PREFIX or 'Echoed'
    return echoedPrefix .. ' ' .. baseSpellLabel
end

function Ui.GetSelectedIndicatorIndex()
    return DesignerState.GetSelectedIndicatorIndex()
end

function Ui.GetSelectedIndicator()
    local spec = Ui.EnsureEditingSpec()
    local indicators = Ui.EnsureSpecIndicators(spec)
    local index = Ui.GetSelectedIndicatorIndex()
    if not index then
        return nil, nil, spec, indicators
    end
    return indicators[index], index, spec, indicators
end

function Ui.SelectedIndicatorExists()
    local indicator = Ui.GetSelectedIndicator()
    return indicator ~= nil
end

function Ui.CurrentSpecHasIndicators()
    local spec = Ui.EnsureEditingSpec()
    local indicators = Ui.EnsureSpecIndicators(spec)
    return #indicators > 0
end

function Ui.SelectedIndicatorTypeIs(expectedType)
    local indicator = Ui.GetSelectedIndicator()
    return indicator and indicator.Type == expectedType
end

function Ui.SelectedIndicatorTypeIn(typeList)
    local indicator = Ui.GetSelectedIndicator()
    if not indicator then return false end
    for _, value in ipairs(typeList) do
        if indicator.Type == value then
            return true
        end
    end
    return false
end

function Ui.UpdateAfterDesignerChange(refreshList)
    if refreshList then
        if SettingsInbound and SettingsInbound.RepairDisplay then
            SettingsInbound.RepairDisplay()
        elseif SettingsPanel and SettingsPanel.RepairDisplay then
            SettingsPanel:RepairDisplay()
        end
    end

    Util.MapOutUnits()

    if Ui.RefreshDesignerPreview then
        Ui.RefreshDesignerPreview()
    end
end

function Ui.CompareLocalizedText(leftText, rightText)
    local left = tostring(leftText or '')
    local right = tostring(rightText or '')

    local utf8Compare = _G.strcmputf8i
    if type(utf8Compare) == 'function' then
        local cmp = utf8Compare(left, right)
        if type(cmp) == 'number' then
            if cmp == 0 then
                return left < right
            end
            return cmp < 0
        end
    end

    local lowerLeft = left:lower()
    local lowerRight = right:lower()
    if lowerLeft == lowerRight then
        return left < right
    end
    return lowerLeft < lowerRight
end

function Ui.GetDropdownValues(dropdownType)
    local function formatAnchorValue(value)
        if type(value) ~= 'string' then
            return value
        end

        local anchorLabels = {
            TOPLEFT = L.ANCHOR_TOPLEFT,
            TOP = L.ANCHOR_TOP,
            TOPRIGHT = L.ANCHOR_TOPRIGHT,
            LEFT = L.ANCHOR_LEFT,
            CENTER = L.ANCHOR_CENTER,
            RIGHT = L.ANCHOR_RIGHT,
            BOTTOMLEFT = L.ANCHOR_BOTTOMLEFT,
            BOTTOM = L.ANCHOR_BOTTOM,
            BOTTOMRIGHT = L.ANCHOR_BOTTOMRIGHT
        }

        return anchorLabels[value] or value
    end

    local function formatDropdownOption(dropdownKey, value)
        local anchorValue = formatAnchorValue(value)
        if anchorValue ~= value then
            return anchorValue
        end

        if value == 'Swipe' then
            return L.OPTION_SWIPE or value
        elseif value == 'Deplete' then
            return L.OPTION_DEPLETE or value
        elseif value == 'Right to Left' then
            return L.OPTION_RIGHT_TO_LEFT or value
        elseif value == 'Left to Right' then
            return L.OPTION_LEFT_TO_RIGHT or value
        elseif value == 'Top to Bottom' then
            return L.OPTION_TOP_TO_BOTTOM or value
        elseif value == 'Bottom to Top' then
            return L.OPTION_BOTTOM_TO_TOP or value
        elseif value == 'Horizontal' then
            return L.OPTION_HORIZONTAL or value
        elseif value == 'Vertical' then
            return L.OPTION_VERTICAL or value
        elseif value == 'Full' then
            return L.OPTION_FULL or value
        elseif value == 'Half' then
            return L.OPTION_HALF or value
        elseif value == 'Inset' then
            return L.OPTION_INSET or value
        elseif value == 'Outset' then
            return L.OPTION_OUTSET or value
        elseif value == 'Low' then
            return L.OPTION_LAYER_LOW or value
        elseif value == 'Normal' then
            return L.OPTION_LAYER_NORMAL or value
        elseif value == 'High' then
            return L.OPTION_LAYER_HIGH or value
        elseif value == 'Top' then
            return L.OPTION_LAYER_TOP or value
        end

        if dropdownKey == 'borderCooldownDirection' then
            if value == 'Clockwise' then
                return L.OPTION_CLOCKWISE or value
            elseif value == 'Anti-Clockwise' then
                return L.OPTION_ANTI_CLOCKWISE or value
            end
        end

        return value
    end

    local data = Data.dropdownOptions[dropdownType]
    local options = {}
    if data and data.options then
        for _, value in ipairs(data.options) do
            table.insert(options, { value = value, text = formatDropdownOption(dropdownType, value) })
        end
    end
    return options
end

function Ui.ShowCreateIndicatorTypePopup(onSelect)
    local popup
    if not Ui.DesignerCreateIndicatorTypePopup then
        popup = CreateFrame('Frame', nil, UIParent, 'InsetFrameTemplate3')
        popup:SetWidth(260)
        popup:SetFrameStrata('DIALOG')
        popup:SetFrameLevel(250)
        popup:SetPoint('CENTER')
        popup:Hide()

        local title = popup:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        title:SetPoint('TOP', popup, 'TOP', 0, -10)
        title:SetText(L.DESIGNER_CREATE_INDICATOR_TITLE)
        popup.Title = title

        local subtitle = popup:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        subtitle:SetPoint('TOP', title, 'BOTTOM', 0, -6)
        subtitle:SetText(L.DESIGNER_CHOOSE_INDICATOR_TYPE)
        popup.Subtitle = subtitle

        local closeButton = CreateFrame('Button', nil, popup, 'UIPanelCloseButton')
        closeButton:SetPoint('TOPRIGHT', popup, 'TOPRIGHT', -1, 0)
        popup.CloseButton = closeButton

        local emptyText = popup:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        emptyText:SetPoint('TOP', subtitle, 'BOTTOM', 0, -24)
        emptyText:SetText(L.DESIGNER_NO_INDICATOR_TYPES)
        emptyText:Hide()
        popup.EmptyText = emptyText

        popup.TypeButtons = {}
        Ui.DesignerCreateIndicatorTypePopup = popup

        if not popup._hideHookRegistered then
            Ui.RegisterDesignerPanelHook('hide', function()
                if Ui.DesignerCreateIndicatorTypePopup then
                    Ui.DesignerCreateIndicatorTypePopup:Hide()
                end
            end)
            popup._hideHookRegistered = true
        end
    else
        popup = Ui.DesignerCreateIndicatorTypePopup
    end

    local entries = {}
    for key, data in pairs(Data.indicatorTypes or {}) do
        table.insert(entries, {
            key = key,
            label = (data and data.display) or tostring(key)
        })
    end
    table.sort(entries, function(a, b)
        return Ui.CompareLocalizedText(a.label, b.label)
    end)

    for _, button in ipairs(popup.TypeButtons) do
        button:Hide()
    end

    popup._onTypeSelected = onSelect

    local previous
    for index, entry in ipairs(entries) do
        local button = popup.TypeButtons[index]
        if not button then
            button = CreateFrame('Button', nil, popup, 'UIPanelButtonTemplate')
            button:SetSize(220, 22)
            popup.TypeButtons[index] = button
        end

        if index == 1 then
            button:SetPoint('TOP', popup.Subtitle, 'BOTTOM', 0, -14)
        else
            button:SetPoint('TOP', previous, 'BOTTOM', 0, -8)
        end

        button:SetText(entry.label)
        button:SetScript('OnClick', function()
            popup:Hide()
            if popup._onTypeSelected then
                popup._onTypeSelected(entry.key)
            end
        end)
        button:Show()
        previous = button
    end

    if #entries == 0 then
        popup.EmptyText:Show()
        popup:SetHeight(120)
    else
        popup.EmptyText:Hide()
        popup:SetHeight(90 + (#entries * 30))
    end

    popup:Show()
end

function Ui.SyncDesignerSpecToCurrent()
    local currentSpec = Data.playerSpec
    if not (currentSpec and Data.specInfo[currentSpec]) then
        currentSpec = Ui.EnsureEditingSpec()
    end

    if not currentSpec then
        return
    end

    Options.editingSpec = currentSpec
    local indicators = Ui.EnsureSpecIndicators(currentSpec)
    if #indicators > 0 then
        Ui.SetSelectedIndicatorIndex(1)
    else
        Ui.SetSelectedIndicatorIndex(nil)
    end
end

function Ui.CreateDesignerCategory(parentCategory)
    if Ui.DesignerEqolCategory then
        return Ui.DesignerEqolCategory
    end

    local EQOL = (LibEQOL and LibEQOL.SettingsMode) or LibStub('LibEQOLSettingsMode-1.0')
    EQOL:SetVariablePrefix('harfDesigner_')

    hooksecurefunc(LibEQOL_ScrollDropdownMixin, 'Init', function(dropdownControl)
        if not dropdownControl then
            return
        end

        local setting = dropdownControl.GetSetting and dropdownControl:GetSetting()
        local variable = setting and setting.GetVariable and setting:GetVariable()
        if type(variable) ~= 'string' or not variable:find('^harfDesigner_') then
            return
        end

        local control = dropdownControl.Control
        if control and control.SetSteppersShown then
            control:SetSteppersShown(false)
        end

        local function hideButtons(frame)
            if not frame then
                return
            end

            if frame.DecrementButton then
                frame.DecrementButton:Hide()
            end

            if frame.IncrementButton then
                frame.IncrementButton:Hide()
            end
        end

        hideButtons(dropdownControl)
        hideButtons(control)
    end)

    local category = EQOL:CreateCategory(parentCategory, L.MENU_CATEGORY_DESIGNER, false)
    Ui.DesignerEqolCategory = category

    Ui.DesignerTrackedSettings = {}
    local function trackSetting(setting)
        if setting and setting.NotifyUpdate then
            table.insert(Ui.DesignerTrackedSettings, setting)
        end
    end

    local function notifyTrackedSettings()
        for _, setting in ipairs(Ui.DesignerTrackedSettings) do
            setting:NotifyUpdate()
        end
    end

    function Ui.SetSelectedIndicatorIndex(index)
        local normalizedIndex = tonumber(index)
        if normalizedIndex and normalizedIndex >= 1 then
            Options.designerSelectedIndicatorIndex = normalizedIndex
        else
            Options.designerSelectedIndicatorIndex = nil
        end

        if not SettingsPanel or not SettingsPanel:IsShown() then
            return
        end

        local queue = { SettingsPanel }
        while #queue > 0 do
            local frame = table.remove(queue)
            if frame and frame.RefreshAll then
                pcall(frame.RefreshAll, frame)
            end

            if frame and frame.GetChildren then
                local children = { frame:GetChildren() }
                for _, child in ipairs(children) do
                    table.insert(queue, child)
                end
            end
        end
        notifyTrackedSettings()
        Ui.UpdateAfterDesignerChange(true)
    end

    Ui.InitializeDesignerPreview()

    Ui.SyncDesignerSpecToCurrent()

    if not Ui._designerSpecSyncHooked then
        Ui.RegisterDesignerPanelHook('show', function()
            Ui.SyncDesignerSpecToCurrent()
        end)
        Ui._designerSpecSyncHooked = true
    end

    EQOL:CreateScrollDropdown(category, {
        key = 'editingSpec',
        name = L.DESIGNER_CURRENTLY_EDITING_SPEC,
        default = Ui.EnsureEditingSpec(),
        optionfunc = function()
            local options = {}
            for spec, _ in pairs(Data.specInfo) do
                table.insert(options, { value = spec, text = Data.GetLocalizedSpecDisplay(spec) })
            end
            table.sort(options, function(a, b)
                return Ui.CompareLocalizedText(a.text, b.text)
            end)
            return options
        end,
        get = function()
            return Ui.EnsureEditingSpec()
        end,
        set = function(value)
            Options.editingSpec = value
            local indicators = Ui.EnsureSpecIndicators(value)
            if #indicators > 0 then
                Ui.SetSelectedIndicatorIndex(1)
            else
                Ui.SetSelectedIndicatorIndex(nil)
            end
        end,
        height = 260
    })

    local _, selectedIndicatorSetting = EQOL:CreateScrollDropdown(category, {
        key = 'selectedIndicator',
        name = L.DESIGNER_INDICATORS,
        default = 1,
        optionfunc = function()
            local spec = Ui.EnsureEditingSpec()
            local indicators = Ui.EnsureSpecIndicators(spec)
            local options = {}
            for index, indicator in ipairs(indicators) do

                local plainLabel
                if indicator then
                    local spell = Ui.GetLocalizedSpellLabel(indicator.Spell, true)
                    local typeName = (indicator.Type and Data.indicatorTypes[indicator.Type] and Data.indicatorTypes[indicator.Type].display) or L.INDICATOR_GENERIC
                    local label = spell .. ' ' .. typeName
                    local duplicateIndex = Ui.GetDuplicateIndexForIndicator(indicators, index, indicator)
                    if duplicateIndex and duplicateIndex > 1 then
                        plainLabel = label .. ' #' .. duplicateIndex
                    else
                        plainLabel = label
                    end
                else
                    plainLabel = L.INDICATOR_EMPTY
                end

                table.insert(options, {
                    value = index,
                    text = Ui.BuildIconLabel(Ui.GetSpellIcon(indicator and indicator.Spell), plainLabel),
                    sortText = plainLabel
                })
            end

            table.sort(options, function(a, b)
                if tostring(a.sortText or a.text or '') == tostring(b.sortText or b.text or '') then
                    return (a.value or 0) < (b.value or 0)
                end
                return Ui.CompareLocalizedText(a.sortText or a.text, b.sortText or b.text)
            end)

            return options
        end,
        get = function()
            return Ui.GetSelectedIndicatorIndex() or 0
        end,
        set = function(value)
            Ui.SetSelectedIndicatorIndex(value)
        end,
        height = 320,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = Ui.CurrentSpecHasIndicators
    })
    trackSetting(selectedIndicatorSetting)

    EQOL:CreateButton(category, {
        key = 'createIndicator',
        text = L.DESIGNER_CREATE_INDICATOR,
        click = function()
            Ui.ShowCreateIndicatorTypePopup(function(indicatorType)
                local spec = Ui.EnsureEditingSpec()
                local indicators = Ui.EnsureSpecIndicators(spec)
                table.insert(indicators, Util.GetDefaultSettingsForIndicator(indicatorType or 'icon'))
                Ui.SetSelectedIndicatorIndex(#indicators)
            end)
        end
    })

    EQOL:CreateButton(category, {
        key = 'duplicateSelectedIndicator',
        text = L.DESIGNER_DUPLICATE_INDICATOR,
        click = function()
            local indicator, index, _, indicators = Ui.GetSelectedIndicator()
            if not indicator then return end

            local duplicatedIndicator = DesignerState.DeepCopyValue(indicator)
            table.insert(indicators, index + 1, duplicatedIndicator)
            Ui.SetSelectedIndicatorIndex(index + 1)
        end,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = Ui.CurrentSpecHasIndicators
    })

    EQOL:CreateButton(category, {
        key = 'deleteSelectedIndicator',
        text = L.DESIGNER_DELETE_INDICATOR,
        click = function()
            local indicator, index, _, indicators = Ui.GetSelectedIndicator()
            if not indicator then return end

            Ui.ConfirmDesignerDelete(function()
                table.remove(indicators, index)
                local nextIndex = 1
                if #indicators > 0 then
                    if index > #indicators then
                        nextIndex = #indicators
                    else
                        nextIndex = index
                    end
                end
                Ui.SetSelectedIndicatorIndex(nextIndex)
            end)
        end,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = Ui.CurrentSpecHasIndicators
    })

    EQOL:CreateHeader(category, {
        name = L.DESIGNER_EDIT_INDICATOR,
        expandWith = Ui.CurrentSpecHasIndicators
    })

    local appearanceSection = EQOL:CreateExpandableSection(category, {
        key = 'indicatorAppearanceSection',
        name = L.DESIGNER_APPEARANCE_SECTION,
        expanded = true,
        expandWith = Ui.SelectedIndicatorExists
    })

    local function isAppearanceSectionExpanded()
        if appearanceSection and type(appearanceSection.IsExpanded) == 'function' then
            return appearanceSection:IsExpanded() ~= false
        end

        if appearanceSection and appearanceSection.data and appearanceSection.data.expanded ~= nil then
            return appearanceSection.data.expanded ~= false
        end

        return true
    end

    local _, indicatorSpellSetting = EQOL:CreateScrollDropdown(category, {
        key = 'indicatorSpell',
        name = L.LABEL_SPELL,
        default = '',
        optionfunc = function()
            local spec = Ui.EnsureEditingSpec()
            local options = {}
            if spec and Data.specInfo[spec] and Data.specInfo[spec].auras then
                for _, spellData in pairs(Data.specInfo[spec].auras) do
                    local localizedSpell = Ui.GetLocalizedSpellLabel(spellData.name, true)
                    table.insert(options, {
                        value = spellData.name,
                        text = Ui.BuildIconLabel(Ui.GetSpellIcon(spellData.name), localizedSpell),
                        sortText = localizedSpell
                    })
                end
                table.sort(options, function(a, b)
                    return Ui.CompareLocalizedText(a.sortText or a.text, b.sortText or b.text)
                end)
            end
            return options
        end,
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.Spell or ''
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.Spell = value
            notifyTrackedSettings()
            Ui.UpdateAfterDesignerChange(false)
        end,
        height = 260,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isAppearanceSectionExpanded() and Ui.SelectedIndicatorExists()
        end
    })
    trackSetting(indicatorSpellSetting)

    local _, indicatorPositionSetting = EQOL:CreateScrollDropdown(category, {
        key = 'indicatorPosition',
        name = L.LABEL_POSITION,
        default = 'CENTER',
        optionfunc = function()
            local indicator = Ui.GetSelectedIndicator()
            if indicator and indicator.Type == 'bar' then
                return Ui.GetDropdownValues('barPosition')
            end
            return Ui.GetDropdownValues('iconPosition')
        end,
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            if indicator then
                if indicator.Position then
                    return indicator.Position
                end
                if indicator.Type == 'bar' then
                    return 'TOPRIGHT'
                end
                return 'CENTER'
            end
            return 'CENTER'
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.Position = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        height = 220,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isAppearanceSectionExpanded() and Ui.SelectedIndicatorTypeIn({ 'icon', 'square', 'bar' })
        end
    })
    trackSetting(indicatorPositionSetting)

    local _, indicatorSizeSetting = EQOL:CreateSlider(category, {
        key = 'indicatorSize',
        name = L.LABEL_SIZE,
        default = 25,
        min = 5,
        max = 50,
        step = 1,
        formatter = Util.FormatForDisplay,
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.Size or 25
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.Size = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isAppearanceSectionExpanded() and Ui.SelectedIndicatorTypeIn({ 'icon', 'square', 'bar' })
        end
    })
    trackSetting(indicatorSizeSetting)

    local _, indicatorXOffsetSetting = EQOL:CreateSlider(category, {
        key = 'indicatorXOffset',
        name = L.LABEL_X_OFFSET,
        default = 0,
        min = -50,
        max = 50,
        step = 1,
        formatter = Util.FormatForDisplay,
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.xOffset or 0
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.xOffset = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isAppearanceSectionExpanded() and Ui.SelectedIndicatorTypeIn({ 'icon', 'square' })
        end
    })
    trackSetting(indicatorXOffsetSetting)

    local _, indicatorYOffsetSetting = EQOL:CreateSlider(category, {
        key = 'indicatorYOffset',
        name = L.LABEL_Y_OFFSET,
        default = 0,
        min = -50,
        max = 50,
        step = 1,
        formatter = Util.FormatForDisplay,
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.yOffset or 0
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.yOffset = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isAppearanceSectionExpanded() and Ui.SelectedIndicatorTypeIn({ 'icon', 'square' })
        end
    })
    trackSetting(indicatorYOffsetSetting)

    local _, indicatorOffsetSetting = EQOL:CreateSlider(category, {
        key = 'indicatorOffset',
        name = L.LABEL_OFFSET,
        default = 0,
        min = -50,
        max = 50,
        step = 1,
        formatter = Util.FormatForDisplay,
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.Offset or 0
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.Offset = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isAppearanceSectionExpanded() and Ui.SelectedIndicatorTypeIs('bar')
        end
    })
    trackSetting(indicatorOffsetSetting)

    local _, indicatorShowSparkSetting = EQOL:CreateCheckbox(category, {
        key = 'indicatorShowSpark',
        name = L.LABEL_SHOW_SPARK,
        default = false,
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.showSpark or false
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.showSpark = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isAppearanceSectionExpanded() and Ui.SelectedIndicatorTypeIs('bar')
        end
    })
    trackSetting(indicatorShowSparkSetting)

    local _, indicatorLayerPrioritySetting = EQOL:CreateScrollDropdown(category, {
        key = 'indicatorLayerPriority',
        name = L.LABEL_LAYER_PRIORITY,
        default = 'Normal',
        values = Ui.GetDropdownValues('indicatorLayer'),
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.LayerPriority or 'Normal'
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.LayerPriority = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        height = 120,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isAppearanceSectionExpanded() and Ui.SelectedIndicatorExists()
        end
    })
    trackSetting(indicatorLayerPrioritySetting)

    local _, indicatorBorderWidthSetting = EQOL:CreateSlider(category, {
        key = 'indicatorBorderWidth',
        name = L.LABEL_BORDER_WIDTH,
        default = 3,
        min = 1,
        max = 10,
        step = 1,
        formatter = Util.FormatForDisplay,
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.borderWidth or 3
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.borderWidth = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isAppearanceSectionExpanded() and Ui.SelectedIndicatorTypeIs('healthColor')
        end
    })
    trackSetting(indicatorBorderWidthSetting)

    local _, indicatorBorderPlacementSetting = EQOL:CreateScrollDropdown(category, {
        key = 'indicatorBorderPlacement',
        name = L.LABEL_BORDER_PLACEMENT,
        desc = L.DESC_BORDER_PLACEMENT_HINT,
        default = 'Inset',
        values = Ui.GetDropdownValues('borderPlacement'),
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.borderPlacement or 'Inset'
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.borderPlacement = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        height = 120,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isAppearanceSectionExpanded() and Ui.SelectedIndicatorTypeIs('healthColor')
        end
    })
    trackSetting(indicatorBorderPlacementSetting)

    local _, barScaleSetting = EQOL:CreateScrollDropdown(category, {
        key = 'barScale',
        name = L.LABEL_BAR_SCALE,
        default = 'Full',
        values = Ui.GetDropdownValues('barScale'),
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.Scale or 'Full'
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.Scale = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        height = 140,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isAppearanceSectionExpanded() and Ui.SelectedIndicatorTypeIs('bar')
        end
    })
    trackSetting(barScaleSetting)

    local _, barOrientationSetting = EQOL:CreateScrollDropdown(category, {
        key = 'barOrientation',
        name = L.LABEL_BAR_ORIENTATION,
        default = 'Horizontal',
        values = Ui.GetDropdownValues('barOrientation'),
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.Orientation or 'Horizontal'
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.Orientation = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        height = 140,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isAppearanceSectionExpanded() and Ui.SelectedIndicatorTypeIs('bar')
        end
    })
    trackSetting(barOrientationSetting)

    EQOL:CreateColorOverrides(category, {
        key = 'indicatorColor',
        entries = {
            { key = 'main', label = L.LABEL_COLOR }
        },
        getColor = function()
            local indicator = Ui.GetSelectedIndicator()
            if indicator and indicator.Color then
                local c = indicator.Color
                return c.r or 1, c.g or 1, c.b or 1, c.a or 1
            end
            return 1, 1, 1, 1
        end,
        setColor = function(_, r, g, b, a)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.Color = { r = r, g = g, b = b, a = a }
            Ui.UpdateAfterDesignerChange(false)
        end,
        hasOpacity = true,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isAppearanceSectionExpanded() and Ui.SelectedIndicatorTypeIn({ 'square', 'bar', 'healthColor' })
        end
    })

    EQOL:CreateColorOverrides(category, {
        key = 'indicatorBackgroundColor',
        entries = {
            { key = 'background', label = L.LABEL_BACKGROUND_COLOR }
        },
        getColor = function()
            local indicator = Ui.GetSelectedIndicator()
            if indicator and indicator.BackgroundColor then
                local c = indicator.BackgroundColor
                return c.r or 0, c.g or 0, c.b or 0, c.a or 0.8
            end
            return 0, 0, 0, 0.8
        end,
        setColor = function(_, r, g, b, a)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.BackgroundColor = { r = r, g = g, b = b, a = a }
            Ui.UpdateAfterDesignerChange(false)
        end,
        hasOpacity = true,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then
                return false
            end

            if not isAppearanceSectionExpanded() then
                return false
            end

            if indicator.Type == 'bar' then
                return true
            end

            return indicator.Type == 'square' and indicator.showCooldown
        end
    })

    local cooldownSection = EQOL:CreateExpandableSection(category, {
        key = 'indicatorCooldownSection',
        name = L.DESIGNER_COOLDOWN_SECTION,
        expanded = true,
        expandWith = function()
            return Ui.SelectedIndicatorTypeIn({ 'square', 'healthColor', 'icon' })
        end
    })

    local function isCooldownSectionExpanded()
        if cooldownSection and type(cooldownSection.IsExpanded) == 'function' then
            return cooldownSection:IsExpanded() ~= false
        end

        if cooldownSection and cooldownSection.data and cooldownSection.data.expanded ~= nil then
            return cooldownSection.data.expanded ~= false
        end

        return true
    end

    local _, indicatorShowCooldownSetting = EQOL:CreateCheckbox(category, {
        key = 'indicatorShowCooldown',
        name = L.LABEL_SHOW_COOLDOWN,
        default = false,
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.showCooldown or false
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.showCooldown = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isCooldownSectionExpanded() and Ui.SelectedIndicatorTypeIn({ 'square', 'healthColor' })
        end
    })
    trackSetting(indicatorShowCooldownSetting)

    local _, indicatorBorderCooldownDirectionSetting = EQOL:CreateScrollDropdown(category, {
        key = 'indicatorBorderCooldownDirection',
        name = L.LABEL_COOLDOWN_DIRECTION,
        default = 'Clockwise',
        values = Ui.GetDropdownValues('borderCooldownDirection'),
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.borderCooldownDirection or 'Clockwise'
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.borderCooldownDirection = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        height = 120,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            local indicator = Ui.GetSelectedIndicator()
            return isCooldownSectionExpanded() and indicator and indicator.Type == 'healthColor' and indicator.showCooldown
        end
    })
    trackSetting(indicatorBorderCooldownDirectionSetting)

    local _, indicatorBorderCooldownStartCornerSetting = EQOL:CreateScrollDropdown(category, {
        key = 'indicatorBorderCooldownStartCorner',
        name = L.LABEL_COOLDOWN_START_CORNER,
        default = 'TOPRIGHT',
        values = Ui.GetDropdownValues('borderCooldownStartCorner'),
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.borderCooldownStartCorner or 'TOPRIGHT'
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.borderCooldownStartCorner = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        height = 140,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            local indicator = Ui.GetSelectedIndicator()
            return isCooldownSectionExpanded() and indicator and indicator.Type == 'healthColor' and indicator.showCooldown
        end
    })
    trackSetting(indicatorBorderCooldownStartCornerSetting)

    local _, indicatorCooldownStyleSetting = EQOL:CreateScrollDropdown(category, {
        key = 'indicatorCooldownStyle',
        name = L.LABEL_COOLDOWN_STYLE,
        default = 'Swipe',
        values = Ui.GetDropdownValues('squareCooldownStyle'),
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.cooldownStyle or 'Swipe'
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.cooldownStyle = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        height = 120,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            local indicator = Ui.GetSelectedIndicator()
            return isCooldownSectionExpanded() and indicator and indicator.Type == 'square' and indicator.showCooldown
        end
    })
    trackSetting(indicatorCooldownStyleSetting)

    local _, indicatorDepleteDirectionSetting = EQOL:CreateScrollDropdown(category, {
        key = 'indicatorDepleteDirection',
        name = L.LABEL_DEPLETE_DIRECTION,
        default = 'Right to Left',
        values = Ui.GetDropdownValues('squareDepleteDirection'),
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.depleteDirection or 'Right to Left'
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.depleteDirection = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        height = 160,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            local indicator = Ui.GetSelectedIndicator()
            return isCooldownSectionExpanded() and indicator
                and indicator.Type == 'square'
                and indicator.showCooldown
                and (indicator.cooldownStyle or 'Swipe') == 'Deplete'
        end
    })
    trackSetting(indicatorDepleteDirectionSetting)

    local _, indicatorShowCooldownTextSetting = EQOL:CreateCheckbox(category, {
        key = 'indicatorShowCooldownText',
        name = L.LABEL_SHOW_COOLDOWN_TEXT,
        default = true,
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then
                return true
            end
            return indicator.showCooldownText ~= false
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.showCooldownText = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            local indicator = Ui.GetSelectedIndicator()
            return isCooldownSectionExpanded() and indicator and indicator.Type == 'square' and indicator.showCooldown
        end
    })
    trackSetting(indicatorShowCooldownTextSetting)

    local _, indicatorShowTextSetting = EQOL:CreateCheckbox(category, {
        key = 'indicatorShowText',
        name = L.LABEL_SHOW_COOLDOWN_TEXT,
        default = true,
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then
                return true
            end

            if indicator.showCooldownText == nil then
                return indicator.showText ~= false
            end

            return indicator.showCooldownText ~= false
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.showCooldownText = value
            indicator.showText = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            return isCooldownSectionExpanded() and Ui.SelectedIndicatorTypeIs('icon')
        end
    })
    trackSetting(indicatorShowTextSetting)

    local _, indicatorShowTextureSetting = EQOL:CreateCheckbox(category, {
        key = 'indicatorShowTexture',
        name = L.LABEL_SHOW_TEXTURE,
        default = true,
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then
                return true
            end
            return indicator.showTexture ~= false
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.showTexture = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            local indicator = Ui.GetSelectedIndicator()
            if not (isCooldownSectionExpanded() and indicator and indicator.Type == 'icon') then
                return false
            end

            if indicator.showCooldownText == nil then
                return indicator.showText ~= false
            end

            return indicator.showCooldownText ~= false
        end
    })
    trackSetting(indicatorShowTextureSetting)

    local _, indicatorTextSizeSetting = EQOL:CreateSlider(category, {
        key = 'indicatorTextSize',
        name = L.LABEL_TEXT_SCALE,
        default = 1,
        min = 0.5,
        max = 3,
        step = 0.1,
        formatter = Util.FormatForDisplay,
        get = function()
            local indicator = Ui.GetSelectedIndicator()
            return indicator and indicator.textSize or 1
        end,
        set = function(value)
            local indicator = Ui.GetSelectedIndicator()
            if not indicator then return end
            indicator.textSize = value
            Ui.UpdateAfterDesignerChange(false)
        end,
        isEnabled = Ui.SelectedIndicatorExists,
        expandWith = function()
            local indicator = Ui.GetSelectedIndicator()

            if indicator and indicator.Type == 'icon' then
                return isAppearanceSectionExpanded()
                    and (indicator.showCooldownText ~= false)
            end

            return isCooldownSectionExpanded()
                and indicator
                and indicator.Type == 'square'
                and indicator.showCooldown
                and (indicator.showCooldownText ~= false)
        end
    })
    trackSetting(indicatorTextSizeSetting)

    EQOL:CreateHeader(category, {
        name = L.DESIGNER_IMPORT_EXPORT_HEADER
    })

    EQOL:CreateButton(category, {
        key = 'exportCurrentSpecIndicators',
        text = L.DESIGNER_EXPORT_SPEC_INDICATORS,
        click = function()
            local spec = Ui.EnsureEditingSpec()
            local exportString, errorText = Ui.DesignerExportSpecIndicators(spec)
            if not exportString then
                Ui.PrintDesignerMessage(errorText or L.DESIGNER_EXPORT_FAILED)
                return
            end

            Util.DisplayPopupTextbox(string.format(L.DESIGNER_EXPORT_POPUP_TITLE_FMT, spec), exportString)
        end
    })

    EQOL:CreateButton(category, {
        key = 'importCurrentSpecIndicators',
        text = L.DESIGNER_IMPORT_SPEC_INDICATORS,
        click = function()
            local spec = Ui.EnsureEditingSpec()
            Ui.ShowDesignerImportPopup(spec, function(importText)

                local result, errorText = Ui.DesignerImportSpecIndicators(spec, importText)
                if result then
                    SavedIndicators[spec] = result.indicators

                    if #result.indicators > 0 then
                        Ui.SetSelectedIndicatorIndex(1)
                    else
                        Options.designerSelectedIndicatorIndex = nil
                        Ui.UpdateAfterDesignerChange(true)
                    end

                    if result.invalidCount and result.invalidCount > 0 then
                        Ui.PrintDesignerMessage(string.format(L.DESIGNER_IMPORT_PARTIAL_FMT, #result.indicators, result.totalCount, result.invalidCount))
                    else
                        Ui.PrintDesignerMessage(string.format(L.DESIGNER_IMPORT_SUCCESS_FMT, #result.indicators))
                    end
                else
                    Ui.PrintDesignerMessage(errorText or L.DESIGNER_IMPORT_INVALID)
                end

            end)
        end
    })

    Ui.UpdateAfterDesignerChange(false)
    return category
end
