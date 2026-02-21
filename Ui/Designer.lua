local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local L = NS.L
local LibStub = _G.LibStub
local LCG = LibStub and LibStub('LibCustomGlow-1.0', true)
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

local PREVIEW_FLOAT_WIDTH = 360
local PREVIEW_FLOAT_HEIGHT = 320

local function getEqolSettingsMode()
    return (LibEQOL and LibEQOL.SettingsMode) or LibStub('LibEQOLSettingsMode-1.0')
end

local function refreshSettingsDisplay()
    if SettingsInbound and SettingsInbound.RepairDisplay then
        SettingsInbound.RepairDisplay()
    elseif SettingsPanel and SettingsPanel.RepairDisplay then
        SettingsPanel:RepairDisplay()
    end
end

local function ensureEditingSpec()
    if Options.editingSpec and Data.specInfo[Options.editingSpec] then
        return Options.editingSpec
    end

    for spec, _ in pairs(Data.specInfo) do
        Options.editingSpec = spec
        break
    end

    return Options.editingSpec
end

local function ensureSpecIndicators(spec)
    if not SavedIndicators[spec] then
        SavedIndicators[spec] = {}
    end
    return SavedIndicators[spec]
end

local function buildIndicatorLabel(index, indicator)
    if not indicator then
        return L.INDICATOR_EMPTY
    end
    local spell = indicator.Spell or L.DESIGNER_UNKNOWN
    local typeName = (indicator.Type and Data.indicatorTypes[indicator.Type] and Data.indicatorTypes[indicator.Type].display) or L.INDICATOR_GENERIC
    return spell .. ' ' .. typeName
end

local function getSelectedIndicatorIndex()
    local spec = ensureEditingSpec()
    local indicators = ensureSpecIndicators(spec)
    if #indicators == 0 then
        return nil
    end

    local index = tonumber(Options.designerSelectedIndicatorIndex) or 1
    if index < 1 then
        index = 1
    elseif index > #indicators then
        index = #indicators
    end

    Options.designerSelectedIndicatorIndex = index
    return index
end

local function getSelectedIndicator()
    local spec = ensureEditingSpec()
    local indicators = ensureSpecIndicators(spec)
    local index = getSelectedIndicatorIndex()
    if not index then
        return nil, nil, spec, indicators
    end
    return indicators[index], index, spec, indicators
end

local function selectedIndicatorExists()
    local indicator = getSelectedIndicator()
    return indicator ~= nil
end

local function selectedIndicatorTypeIs(expectedType)
    local indicator = getSelectedIndicator()
    return indicator and indicator.Type == expectedType
end

local function selectedIndicatorTypeIn(typeList)
    local indicator = getSelectedIndicator()
    if not indicator then return false end
    for _, value in ipairs(typeList) do
        if indicator.Type == value then
            return true
        end
    end
    return false
end

local function updateAfterDesignerChange(refreshList)
    if refreshList then
        refreshSettingsDisplay()
    end

    Util.MapOutUnits()

    if Ui.RefreshDesignerPreview then
        Ui.RefreshDesignerPreview()
    end
end

local function refreshDesignerColorOverrideControls()
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
end

local function stopSelectedPreviewGlow(widget)
    if not (widget and widget.HighlightedPreviewElement and LCG) then
        return
    end

    LCG.PixelGlow_Stop(widget.HighlightedPreviewElement, 'harfDesignerPreviewSelected')
    widget.HighlightedPreviewElement = nil
end

local function applySelectedPreviewGlow(widget)
    if not (widget and widget.Overlay and widget.Overlay.elements and LCG) then
        return
    end

    stopSelectedPreviewGlow(widget)

    local selectedIndex = getSelectedIndicatorIndex()
    if not selectedIndex then
        return
    end

    local selectedElement = widget.Overlay.elements[selectedIndex]
    if not selectedElement then
        return
    end

    LCG.PixelGlow_Start(
        selectedElement,
        { 0.95, 0.82, 0.20, 0.9 },
        4,
        0.25,
        4,
        1,
        0,
        0,
        false,
        'harfDesignerPreviewSelected'
    )
    widget.HighlightedPreviewElement = selectedElement
end

local function bindPreviewSelectionHandlers(widget, onSelect)
    if not (widget and widget.Overlay and widget.Overlay.elements and onSelect) then
        return
    end

    for index, element in ipairs(widget.Overlay.elements) do
        if element and element.EnableMouse and element.SetScript then
            local isHealthColorIndicator = element.type == 'HealthColorIndicator'
            element:EnableMouse(not isHealthColorIndicator)
            if not isHealthColorIndicator then
                element:SetScript('OnMouseDown', function(_, button)
                    if button ~= 'LeftButton' then
                        return
                    end
                    onSelect(index)
                end)
            else
                element:SetScript('OnMouseDown', nil)
            end
        end
    end
end

local function ensureDesignerPreviewWidget()
    if Ui.DesignerPreviewWidget then
        return Ui.DesignerPreviewWidget
    end

    local widget = CreateFrame('Frame', nil, UIParent, 'InsetFrameTemplate3')
    widget:SetSize(PREVIEW_FLOAT_WIDTH, PREVIEW_FLOAT_HEIGHT)
    widget:SetFrameStrata('DIALOG')
    widget:SetFrameLevel(200)
    widget:Hide()
    widget:SetScript('OnHide', function(self)
        stopSelectedPreviewGlow(self)
    end)

    local title = widget:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    title:SetScale(1.2)
    title:SetPoint('TOP', widget, 'TOP', 0, -10)
    title:SetText(L.DESIGNER_PREVIEW_TITLE)
    widget.Title = title

    local specLabel = widget:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    specLabel:SetPoint('TOP', title, 'BOTTOM', 0, -6)
    widget.SpecLabel = specLabel

    local exampleFrame = CreateFrame('Frame', nil, widget)
    exampleFrame:SetSize(165, 65)
    exampleFrame:SetScale(1.5)
    exampleFrame:SetPoint('TOP', widget, 'TOP', 0, -85)
    exampleFrame.bg = exampleFrame:CreateTexture(nil, 'BACKGROUND')
    exampleFrame.bg:SetAllPoints(exampleFrame)
    exampleFrame.bg:SetTexture('Interface\\RaidFrame\\Raid-Bar-Hp-Fill')
    widget.ExampleFrame = exampleFrame

    local disclaimer = exampleFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    disclaimer:SetPoint('TOP', exampleFrame, 'BOTTOM', 0, -3)
    disclaimer:SetWidth(250)
    disclaimer:SetScale(0.7)
    disclaimer:SetText(L.DESIGNER_PREVIEW_DISCLAIMER)
    widget.Disclaimer = disclaimer

    local name = exampleFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    name:SetPoint('TOP', exampleFrame, 'TOP', 0, -5)
    name:SetText('Harrek')

    local health = exampleFrame:CreateFontString(nil, 'OVERLAY', 'GameTooltipText')
    health:SetPoint('CENTER', exampleFrame, 'CENTER')
    health:SetText('100%')

    Ui.DesignerPreviewWidget = widget

    local function getCategoryIdFromObject(categoryObject)
        if type(categoryObject) == 'number' then
            return categoryObject
        end
        if type(categoryObject) == 'table' and categoryObject.GetID then
            local ok, id = pcall(categoryObject.GetID, categoryObject)
            if ok then
                return id
            end
        end
    end

    local function getCurrentSettingsCategoryId()
        if not SettingsPanel then
            return nil
        end

        if SettingsPanel.GetCurrentCategory then
            local ok, categoryObject = pcall(SettingsPanel.GetCurrentCategory, SettingsPanel)
            if ok and categoryObject ~= nil then
                local id = getCategoryIdFromObject(categoryObject)
                if id ~= nil then
                    return id
                end
            end
        end

        if SettingsPanel.GetCurrentCategoryID then
            local ok, id = pcall(SettingsPanel.GetCurrentCategoryID, SettingsPanel)
            if ok then
                return id
            end
        end

        return nil
    end

    Ui.UpdateDesignerPreviewPlacement = function()
        local currentWidget = Ui.DesignerPreviewWidget
        if not currentWidget then
            return
        end

        local wasShown = currentWidget:IsShown()

        local designerCategory = Ui.DesignerEqolCategory
        local designerCategoryId = designerCategory and designerCategory.GetID and designerCategory:GetID() or nil
        local currentCategoryId = getCurrentSettingsCategoryId()

        local categoryMatches = false
        if designerCategoryId and currentCategoryId then
            categoryMatches = designerCategoryId == currentCategoryId
        elseif currentCategoryId == nil then
            categoryMatches = true
        end

        local shouldShow = SettingsPanel and SettingsPanel:IsShown() and categoryMatches
        if not shouldShow then
            stopSelectedPreviewGlow(currentWidget)
            currentWidget:Hide()
            return
        end

        currentWidget:Show()
        currentWidget:ClearAllPoints()
        local uiTop = UIParent:GetTop() or UIParent:GetHeight() or 0
        local uiBottom = UIParent:GetBottom() or 0
        local availableHeight = math.max(180, (uiTop - uiBottom) - 40)
        local clampedHeight = math.min(PREVIEW_FLOAT_HEIGHT, availableHeight)
        currentWidget:SetSize(PREVIEW_FLOAT_WIDTH, clampedHeight)

        local panelRight = SettingsPanel:GetRight() or 0
        local availableRight = (UIParent:GetRight() or UIParent:GetWidth() or 0) - panelRight - 16

        if availableRight >= PREVIEW_FLOAT_WIDTH then
            currentWidget:SetPoint('TOPLEFT', SettingsPanel, 'TOPRIGHT', 10, -12)
        else
            currentWidget:SetPoint('TOPRIGHT', SettingsPanel, 'BOTTOMRIGHT', 0, -8)
        end

        if (not wasShown or not currentWidget.Overlay) and Ui.RefreshDesignerPreview and not Ui._designerPreviewRefreshing then
            Ui.RefreshDesignerPreview()
        end
    end

    if SettingsPanel and not Ui._designerPreviewPanelHooked then
        SettingsPanel:HookScript('OnShow', function()
            if Ui.UpdateDesignerPreviewPlacement then
                Ui.UpdateDesignerPreviewPlacement()
            end
            if Ui.RefreshDesignerPreview then
                Ui.RefreshDesignerPreview()
            end
        end)

        SettingsPanel:HookScript('OnHide', function()
            if Ui.DesignerPreviewWidget then
                stopSelectedPreviewGlow(Ui.DesignerPreviewWidget)
                Ui.DesignerPreviewWidget:Hide()
            end
        end)

        SettingsPanel:HookScript('OnUpdate', function(_, elapsed)
            Ui._designerPreviewElapsed = (Ui._designerPreviewElapsed or 0) + elapsed
            if Ui._designerPreviewElapsed >= 0.25 then
                Ui._designerPreviewElapsed = 0
                if Ui.UpdateDesignerPreviewPlacement then
                    Ui.UpdateDesignerPreviewPlacement()
                end
            end
        end)

        Ui._designerPreviewPanelHooked = true
    end

    return widget
end

local function getSpellOptionsForCurrentSpec()
    local spec = ensureEditingSpec()
    local options = {}
    if spec and Data.specInfo[spec] and Data.specInfo[spec].auras then
        for spell, _ in pairs(Data.specInfo[spec].auras) do
            table.insert(options, { value = spell, text = spell })
        end
        table.sort(options, function(a, b)
            return tostring(a.text) < tostring(b.text)
        end)
    end
    return options
end

local function getDropdownValues(dropdownType)
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
        if dropdownKey == 'iconPosition' or dropdownKey == 'barPosition' then
            return formatAnchorValue(value)
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

local function getSelectedIndicatorOptions()
    local spec = ensureEditingSpec()
    local indicators = ensureSpecIndicators(spec)
    local options = {}
    for index, indicator in ipairs(indicators) do
        table.insert(options, { value = index, text = buildIndicatorLabel(index, indicator) })
    end
    return options
end

local function getSortedIndicatorTypeEntries()
    local entries = {}
    for key, data in pairs(Data.indicatorTypes or {}) do
        table.insert(entries, {
            key = key,
            label = (data and data.display) or tostring(key)
        })
    end
    table.sort(entries, function(a, b)
        return tostring(a.label) < tostring(b.label)
    end)
    return entries
end

local function ensureCreateIndicatorTypePopup()
    if Ui.DesignerCreateIndicatorTypePopup then
        return Ui.DesignerCreateIndicatorTypePopup
    end

    local popup = CreateFrame('Frame', nil, UIParent, 'InsetFrameTemplate3')
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

    if SettingsPanel and not Ui._designerCreateIndicatorPopupHooked then
        SettingsPanel:HookScript('OnHide', function()
            if Ui.DesignerCreateIndicatorTypePopup then
                Ui.DesignerCreateIndicatorTypePopup:Hide()
            end
        end)
        Ui._designerCreateIndicatorPopupHooked = true
    end

    return popup
end

local function showCreateIndicatorTypePopup(onSelect)
    local popup = ensureCreateIndicatorTypePopup()
    local entries = getSortedIndicatorTypeEntries()

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

local function buildDesignerEqol(parentCategory)
    if Ui.DesignerEqolCategory then
        return Ui.DesignerEqolCategory
    end

    local EQOL = getEqolSettingsMode()
    EQOL:SetVariablePrefix('harfDesigner_')

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

    local function setSelectedIndicatorIndex(index)
        Options.designerSelectedIndicatorIndex = tonumber(index) or 1
        notifyTrackedSettings()
        refreshDesignerColorOverrideControls()
        updateAfterDesignerChange(true)
    end

    ensureDesignerPreviewWidget()

    Ui.RefreshDesignerPreview = function()
        local widget = Ui.DesignerPreviewWidget
        if not widget then
            return
        end

        if Ui._designerPreviewRefreshing then
            return
        end
        Ui._designerPreviewRefreshing = true

        if Ui.UpdateDesignerPreviewPlacement then
            Ui.UpdateDesignerPreviewPlacement()
        end

        if not widget:IsShown() then
            Ui._designerPreviewRefreshing = nil
            return
        end

        local spec = ensureEditingSpec()
        local specData = spec and Data.specInfo[spec]
        if specData and widget.SpecLabel then
            widget.SpecLabel:SetText(string.format(L.DESIGNER_CURRENT_SPEC_FMT, specData.display))
        elseif widget.SpecLabel then
            widget.SpecLabel:SetText(string.format(L.DESIGNER_CURRENT_SPEC_FMT, L.DESIGNER_UNKNOWN))
        end

        if widget.Overlay then
            stopSelectedPreviewGlow(widget)
            widget.Overlay:Delete()
            widget.Overlay = nil
        end

        local indicatorData = SavedIndicators[spec]
        local overlay = Ui.CreateIndicatorOverlay(indicatorData)
        if overlay then
            overlay:SetParent(widget)
            overlay:AttachToFrame(widget.ExampleFrame)
            overlay:ShowPreview()
            widget.Overlay = overlay
            bindPreviewSelectionHandlers(widget, setSelectedIndicatorIndex)
            applySelectedPreviewGlow(widget)
        end

        Ui._designerPreviewRefreshing = nil
    end

    ensureEditingSpec()

    EQOL:CreateScrollDropdown(category, {
        key = 'editingSpec',
        name = L.DESIGNER_CURRENTLY_EDITING_SPEC,
        default = ensureEditingSpec(),
        optionfunc = function()
            local options = {}
            for spec, data in pairs(Data.specInfo) do
                table.insert(options, { value = spec, text = data.display })
            end
            table.sort(options, function(a, b)
                return tostring(a.text) < tostring(b.text)
            end)
            return options
        end,
        get = function()
            return ensureEditingSpec()
        end,
        set = function(value)
            Options.editingSpec = value
            Options.designerSelectedIndicatorIndex = 1
            refreshSettingsDisplay()
            updateAfterDesignerChange(false)
        end,
        height = 260
    })

    local _, selectedIndicatorSetting = EQOL:CreateScrollDropdown(category, {
        key = 'selectedIndicator',
        name = L.DESIGNER_INDICATORS,
        default = 1,
        optionfunc = getSelectedIndicatorOptions,
        get = function()
            return getSelectedIndicatorIndex() or 0
        end,
        set = function(value)
            setSelectedIndicatorIndex(value)
        end,
        height = 320,
        isEnabled = selectedIndicatorExists
    })
    trackSetting(selectedIndicatorSetting)

    EQOL:CreateButton(category, {
        key = 'createIndicator',
        text = L.DESIGNER_CREATE_INDICATOR,
        click = function()
            showCreateIndicatorTypePopup(function(indicatorType)
                local spec = ensureEditingSpec()
                local indicators = ensureSpecIndicators(spec)
                table.insert(indicators, Util.GetDefaultSettingsForIndicator(indicatorType or 'icon'))
                setSelectedIndicatorIndex(#indicators)
            end)
        end
    })

    EQOL:CreateHeader(category, L.DESIGNER_EDIT_INDICATOR)

    local _, indicatorSpellSetting = EQOL:CreateScrollDropdown(category, {
        key = 'indicatorSpell',
        name = L.LABEL_SPELL,
        default = '',
        optionfunc = getSpellOptionsForCurrentSpec,
        get = function()
            local indicator = getSelectedIndicator()
            return indicator and indicator.Spell or ''
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.Spell = value
            refreshSettingsDisplay()
            updateAfterDesignerChange(false)
        end,
        height = 260,
        isEnabled = selectedIndicatorExists,
        expandWith = selectedIndicatorExists
    })
    trackSetting(indicatorSpellSetting)

    local _, indicatorPositionSetting = EQOL:CreateScrollDropdown(category, {
        key = 'indicatorPosition',
        name = L.LABEL_POSITION,
        default = 'CENTER',
        optionfunc = function()
            local indicator = getSelectedIndicator()
            if indicator and indicator.Type == 'bar' then
                return getDropdownValues('barPosition')
            end
            return getDropdownValues('iconPosition')
        end,
        get = function()
            local indicator = getSelectedIndicator()
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
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.Position = value
            updateAfterDesignerChange(false)
        end,
        height = 220,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            return selectedIndicatorTypeIn({ 'icon', 'square', 'bar' })
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
            local indicator = getSelectedIndicator()
            return indicator and indicator.Size or 25
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.Size = value
            updateAfterDesignerChange(false)
        end,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            return selectedIndicatorTypeIn({ 'icon', 'square', 'bar' })
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
            local indicator = getSelectedIndicator()
            return indicator and indicator.xOffset or 0
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.xOffset = value
            updateAfterDesignerChange(false)
        end,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            return selectedIndicatorTypeIn({ 'icon', 'square' })
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
            local indicator = getSelectedIndicator()
            return indicator and indicator.yOffset or 0
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.yOffset = value
            updateAfterDesignerChange(false)
        end,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            return selectedIndicatorTypeIn({ 'icon', 'square' })
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
            local indicator = getSelectedIndicator()
            return indicator and indicator.Offset or 0
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.Offset = value
            updateAfterDesignerChange(false)
        end,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            return selectedIndicatorTypeIs('bar')
        end
    })
    trackSetting(indicatorOffsetSetting)

    local _, indicatorShowTextSetting = EQOL:CreateCheckbox(category, {
        key = 'indicatorShowText',
        name = L.LABEL_SHOW_TEXT,
        default = true,
        get = function()
            local indicator = getSelectedIndicator()
            if not indicator then
                return true
            end
            return indicator.showText ~= false
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.showText = value
            updateAfterDesignerChange(false)
        end,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            return selectedIndicatorTypeIs('icon')
        end
    })
    trackSetting(indicatorShowTextSetting)

    local _, indicatorShowTextureSetting = EQOL:CreateCheckbox(category, {
        key = 'indicatorShowTexture',
        name = L.LABEL_SHOW_TEXTURE,
        default = true,
        get = function()
            local indicator = getSelectedIndicator()
            if not indicator then
                return true
            end
            return indicator.showTexture ~= false
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.showTexture = value
            updateAfterDesignerChange(false)
        end,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            return selectedIndicatorTypeIs('icon')
        end
    })
    trackSetting(indicatorShowTextureSetting)

    local _, indicatorShowCooldownSetting = EQOL:CreateCheckbox(category, {
        key = 'indicatorShowCooldown',
        name = L.LABEL_SHOW_COOLDOWN,
        default = false,
        get = function()
            local indicator = getSelectedIndicator()
            return indicator and indicator.showCooldown or false
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.showCooldown = value
            updateAfterDesignerChange(false)
        end,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            return selectedIndicatorTypeIs('square')
        end
    })
    trackSetting(indicatorShowCooldownSetting)

    local _, indicatorCooldownStyleSetting = EQOL:CreateScrollDropdown(category, {
        key = 'indicatorCooldownStyle',
        name = L.LABEL_COOLDOWN_STYLE,
        default = 'Swipe',
        values = getDropdownValues('squareCooldownStyle'),
        get = function()
            local indicator = getSelectedIndicator()
            return indicator and indicator.cooldownStyle or 'Swipe'
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.cooldownStyle = value
            updateAfterDesignerChange(false)
        end,
        height = 120,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            local indicator = getSelectedIndicator()
            return indicator and indicator.Type == 'square' and indicator.showCooldown
        end
    })
    trackSetting(indicatorCooldownStyleSetting)

    local _, indicatorDepleteDirectionSetting = EQOL:CreateScrollDropdown(category, {
        key = 'indicatorDepleteDirection',
        name = L.LABEL_DEPLETE_DIRECTION,
        default = 'Right to Left',
        values = getDropdownValues('squareDepleteDirection'),
        get = function()
            local indicator = getSelectedIndicator()
            return indicator and indicator.depleteDirection or 'Right to Left'
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.depleteDirection = value
            updateAfterDesignerChange(false)
        end,
        height = 160,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            local indicator = getSelectedIndicator()
            return indicator
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
            local indicator = getSelectedIndicator()
            if not indicator then
                return true
            end
            return indicator.showCooldownText ~= false
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.showCooldownText = value
            updateAfterDesignerChange(false)
        end,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            local indicator = getSelectedIndicator()
            return indicator and indicator.Type == 'square' and indicator.showCooldown
        end
    })
    trackSetting(indicatorShowCooldownTextSetting)

    local _, indicatorTextSizeSetting = EQOL:CreateSlider(category, {
        key = 'indicatorTextSize',
        name = L.LABEL_TEXT_SCALE,
        default = 1,
        min = 0.5,
        max = 3,
        step = 0.1,
        formatter = Util.FormatForDisplay,
        get = function()
            local indicator = getSelectedIndicator()
            return indicator and indicator.textSize or 1
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.textSize = value
            updateAfterDesignerChange(false)
        end,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            local indicator = getSelectedIndicator()
            if not indicator then
                return false
            end

            if indicator.Type == 'icon' then
                return indicator.showText ~= false
            end

            if indicator.Type == 'square' then
                return indicator.showCooldown and (indicator.showCooldownText ~= false)
            end

            return false
        end
    })
    trackSetting(indicatorTextSizeSetting)

    local _, barScaleSetting = EQOL:CreateScrollDropdown(category, {
        key = 'barScale',
        name = L.LABEL_BAR_SCALE,
        default = 'Full',
        values = getDropdownValues('barScale'),
        get = function()
            local indicator = getSelectedIndicator()
            return indicator and indicator.Scale or 'Full'
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.Scale = value
            updateAfterDesignerChange(false)
        end,
        height = 140,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            return selectedIndicatorTypeIs('bar')
        end
    })
    trackSetting(barScaleSetting)

    local _, barOrientationSetting = EQOL:CreateScrollDropdown(category, {
        key = 'barOrientation',
        name = L.LABEL_BAR_ORIENTATION,
        default = 'Horizontal',
        values = getDropdownValues('barOrientation'),
        get = function()
            local indicator = getSelectedIndicator()
            return indicator and indicator.Orientation or 'Horizontal'
        end,
        set = function(value)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.Orientation = value
            updateAfterDesignerChange(false)
        end,
        height = 140,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            return selectedIndicatorTypeIs('bar')
        end
    })
    trackSetting(barOrientationSetting)

    EQOL:CreateColorOverrides(category, {
        key = 'indicatorColor',
        entries = {
            { key = 'main', label = L.LABEL_COLOR }
        },
        getColor = function()
            local indicator = getSelectedIndicator()
            if indicator and indicator.Color then
                local c = indicator.Color
                return c.r or 1, c.g or 1, c.b or 1, c.a or 1
            end
            return 1, 1, 1, 1
        end,
        setColor = function(_, r, g, b, a)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.Color = { r = r, g = g, b = b, a = a }
            updateAfterDesignerChange(false)
        end,
        hasOpacity = true,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            return selectedIndicatorTypeIn({ 'square', 'bar', 'healthColor' })
        end
    })

    EQOL:CreateColorOverrides(category, {
        key = 'indicatorBackgroundColor',
        entries = {
            { key = 'background', label = L.LABEL_BACKGROUND_COLOR }
        },
        getColor = function()
            local indicator = getSelectedIndicator()
            if indicator and indicator.BackgroundColor then
                local c = indicator.BackgroundColor
                return c.r or 0, c.g or 0, c.b or 0, c.a or 0.8
            end
            return 0, 0, 0, 0.8
        end,
        setColor = function(_, r, g, b, a)
            local indicator = getSelectedIndicator()
            if not indicator then return end
            indicator.BackgroundColor = { r = r, g = g, b = b, a = a }
            updateAfterDesignerChange(false)
        end,
        hasOpacity = true,
        isEnabled = selectedIndicatorExists,
        expandWith = function()
            local indicator = getSelectedIndicator()
            if not indicator then
                return false
            end

            if indicator.Type == 'bar' then
                return true
            end

            return indicator.Type == 'square' and indicator.showCooldown
        end
    })

    EQOL:CreateButton(category, {
        key = 'deleteSelectedIndicator',
        text = L.DESIGNER_DELETE_INDICATOR,
        click = function()
            local indicator, index, spec, indicators = getSelectedIndicator()
            if not indicator then return end

            table.remove(indicators, index)
            local nextIndex = 1
            if #indicators > 0 then
                if index > #indicators then
                    nextIndex = #indicators
                else
                    nextIndex = index
                end
            end
            setSelectedIndicatorIndex(nextIndex)
        end,
        isEnabled = selectedIndicatorExists
    })

    updateAfterDesignerChange(false)
    return category
end

function Ui.CreateDesignerCategory(parentCategory)
    return buildDesignerEqol(parentCategory)
end
