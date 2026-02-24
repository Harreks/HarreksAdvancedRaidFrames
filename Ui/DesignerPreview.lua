local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local L = NS.L
local Options = HARFDB.options
local LibStub = _G.LibStub
local LCG = LibStub and LibStub('LibCustomGlow-1.0', true)
local LGF = LibStub and LibStub('LibGetFrame-1.0', true)
local DesignerState = Ui.DesignerState
local IsSecretValue = issecretvalue

local PREVIEW_FLOAT_WIDTH = 360
local PREVIEW_FLOAT_HEIGHT = 320
local PREVIEW_DEFAULT_HEALTH_COLOR = { r = 0.10, g = 0.95, b = 0.10, a = 1 }
local PREVIEW_EXTERNAL_DEFAULT_COLOR = { r = 1, g = 1, b = 1, a = 1 }
local EXTERNAL_FRAME_IGNORE_PATTERNS = {
    '^CompactRaid',
    '^CompactParty'
}
local updatePreviewHealthColor

local function getCustomPreviewBarColor()
    if type(Options.designerPreviewCustomBarColor) ~= 'table' then
        Options.designerPreviewCustomBarColor = {
            r = PREVIEW_EXTERNAL_DEFAULT_COLOR.r,
            g = PREVIEW_EXTERNAL_DEFAULT_COLOR.g,
            b = PREVIEW_EXTERNAL_DEFAULT_COLOR.b,
            a = PREVIEW_EXTERNAL_DEFAULT_COLOR.a
        }
    end

    local color = Options.designerPreviewCustomBarColor
    if type(color.r) ~= 'number' then color.r = PREVIEW_EXTERNAL_DEFAULT_COLOR.r end
    if type(color.g) ~= 'number' then color.g = PREVIEW_EXTERNAL_DEFAULT_COLOR.g end
    if type(color.b) ~= 'number' then color.b = PREVIEW_EXTERNAL_DEFAULT_COLOR.b end
    if type(color.a) ~= 'number' then color.a = PREVIEW_EXTERNAL_DEFAULT_COLOR.a end
    return color
end

local function setCustomPreviewBarColor(r, g, b, a)
    local color = getCustomPreviewBarColor()
    color.r = r
    color.g = g
    color.b = b
    color.a = a or PREVIEW_EXTERNAL_DEFAULT_COLOR.a
end

local function refreshCustomColorSwatch(widget)
    if not (widget and widget.CustomPreviewColorSwatch) then
        return
    end

    local color = getCustomPreviewBarColor()
    widget.CustomPreviewColorSwatch:SetColorTexture(color.r, color.g, color.b, color.a)
end

local function openCustomPreviewColorPicker(widget)
    if not (ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow) then
        return
    end

    local color = getCustomPreviewBarColor()

    local function apply(r, g, b, a)
        setCustomPreviewBarColor(r, g, b, a)
        refreshCustomColorSwatch(widget)
        updatePreviewHealthColor(widget, false)
    end

    ColorPickerFrame:SetupColorPickerAndShow({
        r = color.r,
        g = color.g,
        b = color.b,
        opacity = color.a,
        hasOpacity = true,
        swatchFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or color.a
            apply(r, g, b, a)
        end,
        opacityFunc = function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a = ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or color.a
            apply(r, g, b, a)
        end,
        cancelFunc = function()
            local r, g, b, a = ColorPickerFrame:GetPreviousValues()
            apply(r or color.r, g or color.g, b or color.b, a or color.a)
        end,
    })
end

local function isFrameShown(frame)
    if not (frame and frame.IsShown and frame:IsShown()) then
        return false
    end

    if frame.GetAlpha then
        local alpha = frame:GetAlpha()
        if alpha ~= nil and (not IsSecretValue or not IsSecretValue(alpha)) then
            return alpha > 0
        end
    end

    return true
end

local function getTrackedUnitsForGroupContext()
    local units = {}
    if IsInRaid() then
        for i = 1, 40 do
            units[#units + 1] = 'raid' .. i
        end
    else
        units[#units + 1] = 'player'
        for i = 1, 4 do
            units[#units + 1] = 'party' .. i
        end
    end
    return units
end

local function sampleDefaultFrameHealthColor()
    local frameLists = {
        Data.frameList and Data.frameList.party,
        Data.frameList and Data.frameList.raid
    }

    for _, frameList in ipairs(frameLists) do
        if frameList then
            for _, frameName in ipairs(frameList) do
                local frame = _G[frameName]
                if isFrameShown(frame) and frame.healthBar and frame.healthBar.GetStatusBarColor then
                    local r, g, b, a = frame.healthBar:GetStatusBarColor()
                    if r and g and b then
                        return r, g, b, a or 1
                    end
                end
            end
        end
    end

    return nil
end

local function isUsingBlizzardDefaultFrames()
    local trackedUnits = getTrackedUnitsForGroupContext()

    if DandersFrames_IsReady and DandersFrames_IsReady() and DandersFrames_GetFrameForUnit then
        for _, unit in ipairs(trackedUnits) do
            if UnitExists(unit) then
                local dandersFrame = DandersFrames_GetFrameForUnit(unit)
                if dandersFrame and (isFrameShown(dandersFrame) or dandersFrame.unit) then
                    return false
                end
            end
        end
    end

    if LGF and LGF.GetUnitFrame then
        for _, unit in ipairs(trackedUnits) do
            if UnitExists(unit) then
                local externalFrame = LGF.GetUnitFrame(unit, { ignoreFrames = EXTERNAL_FRAME_IGNORE_PATTERNS })
                if isFrameShown(externalFrame) then
                    return false
                end
            end
        end
    end

    local hasVisibleDefaultFrame = false
    local frameList = IsInRaid() and Data.frameList and Data.frameList.raid or Data.frameList and Data.frameList.party

    if frameList then
        for _, frameName in ipairs(frameList) do
            local frame = _G[frameName]
            if isFrameShown(frame) and frame.unit and UnitExists(frame.unit) then
                hasVisibleDefaultFrame = true
                break
            end
        end
    end

    if not hasVisibleDefaultFrame then
        return false
    end

    return true
end

updatePreviewHealthColor = function(widget, usingDefaultFrames)
    if not (widget and widget.ExampleHealthTexture) then
        return
    end

    local r, g, b, a
    if usingDefaultFrames then
        r, g, b, a = sampleDefaultFrameHealthColor()
    else
        local customColor = getCustomPreviewBarColor()
        r, g, b, a = customColor.r, customColor.g, customColor.b, customColor.a
    end

    if not (r and g and b) then
        r = PREVIEW_DEFAULT_HEALTH_COLOR.r
        g = PREVIEW_DEFAULT_HEALTH_COLOR.g
        b = PREVIEW_DEFAULT_HEALTH_COLOR.b
        a = PREVIEW_DEFAULT_HEALTH_COLOR.a
    end

    widget.ExampleHealthTexture:SetVertexColor(r, g, b, a or 1)
end

local function updateDefaultFramesNotice(widget, usingDefaultFrames)
    if not (widget and widget.DefaultFramesNotice and widget.DefaultFramesButton and widget.CustomPreviewColorLabel and widget.CustomPreviewColorButton) then
        return
    end

    if usingDefaultFrames and Ui.DefaultFramesCategoryID then
        widget.DefaultFramesNotice:SetText(L.DESIGNER_PREVIEW_DEFAULT_FRAMES_NOTICE)
        widget.DefaultFramesNotice:Show()
        widget.DefaultFramesButton:SetText(L.DESIGNER_PREVIEW_DEFAULT_FRAMES_BUTTON)
        widget.DefaultFramesButton:Show()
        widget.CustomPreviewColorLabel:Hide()
        widget.CustomPreviewColorButton:Hide()
    else
        widget.DefaultFramesNotice:Hide()
        widget.DefaultFramesButton:Hide()
        widget.CustomPreviewColorLabel:SetText(L.DESIGNER_PREVIEW_CUSTOM_BAR_COLOR)
        widget.CustomPreviewColorLabel:Show()
        widget.CustomPreviewColorButton:Show()
        refreshCustomColorSwatch(widget)
    end
end

local function getDesiredPreviewHeight(widget)
    if not (widget and widget.IsShown and widget:IsShown() and widget.GetTop and widget.GetBottom) then
        return PREVIEW_FLOAT_HEIGHT
    end

    local lowestBottom = nil
    local candidates = {
        widget.DefaultFramesButton,
        widget.CustomPreviewColorButton,
        widget.DefaultFramesNotice,
        widget.FadeOthersCheckbox,
        widget.Disclaimer,
    }

    for _, frame in ipairs(candidates) do
        if frame and frame.IsShown and frame:IsShown() and frame.GetBottom then
            local bottom = frame:GetBottom()
            if bottom and (not lowestBottom or bottom < lowestBottom) then
                lowestBottom = bottom
            end
        end
    end

    local top = widget:GetTop()
    if not (top and lowestBottom) then
        return PREVIEW_FLOAT_HEIGHT
    end

    local desiredHeight = math.ceil((top - lowestBottom) + 22)
    if desiredHeight < PREVIEW_FLOAT_HEIGHT then
        desiredHeight = PREVIEW_FLOAT_HEIGHT
    end

    return desiredHeight
end

local function stopSelectedPreviewGlow(widget)
    if not (widget and widget.HighlightedPreviewElement and LCG) then
        return
    end

    LCG.PixelGlow_Stop(widget.HighlightedPreviewElement, 'harfDesignerPreviewSelected')
    widget.HighlightedPreviewElement = nil
end

local function applySelectedPreviewGlow(widget, getSelectedIndicatorIndex)
    if not (widget and widget.Overlay and widget.Overlay.elements and LCG and getSelectedIndicatorIndex) then
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

local function applyPreviewIndicatorFade(widget, getSelectedIndicatorIndex)
    if not (widget and widget.Overlay and widget.Overlay.elements) then
        return
    end

    local selectedIndex = getSelectedIndicatorIndex and getSelectedIndicatorIndex()
    local shouldFadeOthers = Ui.designerPreviewFadeOtherIndicators ~= false

    for index, element in ipairs(widget.Overlay.elements) do
        if element and element.SetAlpha then
            local alpha = 1
            if shouldFadeOthers and selectedIndex and index ~= selectedIndex then
                alpha = 0.3
            end
            element:SetAlpha(alpha)
        end
    end
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

function Ui.InitializeDesignerPreview(config)
    if Ui._designerPreviewInitialized then
        return Ui.DesignerPreviewWidget
    end

    local ensureEditingSpec = config and config.ensureEditingSpec
    local getSelectedIndicatorIndex = config and config.getSelectedIndicatorIndex
    local setSelectedIndicatorIndex = config and config.setSelectedIndicatorIndex

    if Ui.designerPreviewFadeOtherIndicators == nil then
        Ui.designerPreviewFadeOtherIndicators = true
    end

    local widget = Ui.DesignerPreviewWidget
    if not widget then
        widget = CreateFrame('Frame', nil, UIParent, 'InsetFrameTemplate3')
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

        local healthTexture = exampleFrame:CreateTexture(nil, 'BACKGROUND')
        healthTexture:SetAllPoints(exampleFrame)
        healthTexture:SetTexture('Interface\\RaidFrame\\Raid-Bar-Hp-Fill')
        healthTexture:SetVertexColor(
            PREVIEW_DEFAULT_HEALTH_COLOR.r,
            PREVIEW_DEFAULT_HEALTH_COLOR.g,
            PREVIEW_DEFAULT_HEALTH_COLOR.b,
            PREVIEW_DEFAULT_HEALTH_COLOR.a
        )
        widget.ExampleHealthTexture = healthTexture

        widget.ExampleFrame = exampleFrame

        local disclaimer = exampleFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        disclaimer:SetPoint('TOP', exampleFrame, 'BOTTOM', 0, -3)
        disclaimer:SetWidth(250)
        disclaimer:SetScale(0.7)
        disclaimer:SetText(L.DESIGNER_PREVIEW_DISCLAIMER)
        widget.Disclaimer = disclaimer

        local fadeOthersCheckbox = CreateFrame('CheckButton', nil, widget, 'UICheckButtonTemplate')
        fadeOthersCheckbox:SetPoint('TOPLEFT', disclaimer, 'BOTTOMLEFT', -8, -8)
        fadeOthersCheckbox:SetChecked(Ui.designerPreviewFadeOtherIndicators ~= false)

        local fadeOthersLabel = widget:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        fadeOthersLabel:SetPoint('LEFT', fadeOthersCheckbox, 'RIGHT', 1, 1)
        fadeOthersLabel:SetText(L.DESIGNER_PREVIEW_FADE_OTHER_INDICATORS)

        fadeOthersCheckbox:SetScript('OnClick', function(self)
            Ui.designerPreviewFadeOtherIndicators = self:GetChecked() and true or false
            applyPreviewIndicatorFade(widget, getSelectedIndicatorIndex)
        end)

        widget.FadeOthersCheckbox = fadeOthersCheckbox
        widget.FadeOthersLabel = fadeOthersLabel

        local defaultFramesNotice = widget:CreateFontString(nil, 'OVERLAY', 'GameTooltipTextSmall')
        defaultFramesNotice:SetPoint('TOPLEFT', fadeOthersCheckbox, 'BOTTOMLEFT', 8, -6)
        defaultFramesNotice:SetPoint('RIGHT', widget, 'RIGHT', -14, 0)
        defaultFramesNotice:SetJustifyH('LEFT')
        defaultFramesNotice:SetWordWrap(true)
        defaultFramesNotice:Hide()
        widget.DefaultFramesNotice = defaultFramesNotice

        local defaultFramesButton = CreateFrame('Button', nil, widget, 'UIPanelButtonTemplate')
        defaultFramesButton:SetSize(205, 22)
        defaultFramesButton:SetPoint('TOPLEFT', defaultFramesNotice, 'BOTTOMLEFT', -2, -6)
        defaultFramesButton:SetScript('OnClick', function()
            if Settings and Settings.OpenToCategory and Ui.DefaultFramesCategoryID then
                Settings.OpenToCategory(Ui.DefaultFramesCategoryID)
            end
        end)
        defaultFramesButton:SetScript('OnEnter', function(self)
            if not L.DESIGNER_PREVIEW_DEFAULT_FRAMES_BUTTON_TOOLTIP then
                return
            end
            GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            GameTooltip:SetText(L.DESIGNER_PREVIEW_DEFAULT_FRAMES_BUTTON_TOOLTIP, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        defaultFramesButton:SetScript('OnLeave', function()
            GameTooltip:Hide()
        end)
        defaultFramesButton:Hide()
        widget.DefaultFramesButton = defaultFramesButton

        local customPreviewColorLabel = widget:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        customPreviewColorLabel:SetPoint('TOPLEFT', fadeOthersCheckbox, 'BOTTOMLEFT', 8, -10)
        customPreviewColorLabel:SetText(L.DESIGNER_PREVIEW_CUSTOM_BAR_COLOR)
        customPreviewColorLabel:Hide()
        widget.CustomPreviewColorLabel = customPreviewColorLabel

        local customPreviewColorButton = CreateFrame('Button', nil, widget, 'UIPanelButtonTemplate')
        customPreviewColorButton:SetSize(92, 22)
        customPreviewColorButton:SetPoint('LEFT', customPreviewColorLabel, 'RIGHT', 8, 0)
        customPreviewColorButton:SetText(L.LABEL_COLOR)
        customPreviewColorButton:SetScript('OnClick', function()
            openCustomPreviewColorPicker(widget)
        end)
        customPreviewColorButton:SetScript('OnEnter', function(self)
            if not L.DESIGNER_PREVIEW_CUSTOM_BAR_COLOR_TOOLTIP then
                return
            end
            GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            GameTooltip:SetText(L.DESIGNER_PREVIEW_CUSTOM_BAR_COLOR_TOOLTIP, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        customPreviewColorButton:SetScript('OnLeave', function()
            GameTooltip:Hide()
        end)

        local swatchBorder = customPreviewColorButton:CreateTexture(nil, 'ARTWORK')
        swatchBorder:SetSize(12, 12)
        swatchBorder:SetPoint('RIGHT', customPreviewColorButton, 'RIGHT', -8, 0)
        swatchBorder:SetColorTexture(0.15, 0.15, 0.15, 1)

        local swatch = customPreviewColorButton:CreateTexture(nil, 'OVERLAY')
        swatch:SetSize(10, 10)
        swatch:SetPoint('CENTER', swatchBorder, 'CENTER')
        customPreviewColorButton.Swatch = swatch
        widget.CustomPreviewColorSwatch = swatch

        customPreviewColorButton:Hide()
        widget.CustomPreviewColorButton = customPreviewColorButton

        local name = exampleFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        name:SetPoint('TOP', exampleFrame, 'TOP', 0, -5)
        name:SetText('Harrek')

        local health = exampleFrame:CreateFontString(nil, 'OVERLAY', 'GameTooltipText')
        health:SetPoint('CENTER', exampleFrame, 'CENTER')
        health:SetText('100%')

        Ui.DesignerPreviewWidget = widget
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
        local targetHeight = currentWidget.DesiredHeight or PREVIEW_FLOAT_HEIGHT
        local clampedHeight = math.min(targetHeight, availableHeight)
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

    Ui.RefreshDesignerPreview = function()
        local currentWidget = Ui.DesignerPreviewWidget
        if not currentWidget then
            return
        end

        if Ui._designerPreviewRefreshing then
            return
        end
        Ui._designerPreviewRefreshing = true

        if Ui.UpdateDesignerPreviewPlacement then
            Ui.UpdateDesignerPreviewPlacement()
        end

        if not currentWidget:IsShown() then
            Ui._designerPreviewRefreshing = nil
            return
        end

        local spec = ensureEditingSpec and ensureEditingSpec()
        local specData = spec and Data.specInfo[spec]
        if specData and currentWidget.SpecLabel then
            currentWidget.SpecLabel:SetText(string.format(L.DESIGNER_CURRENT_SPEC_FMT, Data.GetLocalizedSpecDisplay(spec)))
        elseif currentWidget.SpecLabel then
            currentWidget.SpecLabel:SetText(string.format(L.DESIGNER_CURRENT_SPEC_FMT, L.DESIGNER_UNKNOWN))
        end

        if currentWidget.FadeOthersCheckbox then
            currentWidget.FadeOthersCheckbox:SetChecked(Ui.designerPreviewFadeOtherIndicators ~= false)
        end

        local usingDefaultFrames = isUsingBlizzardDefaultFrames()
        updatePreviewHealthColor(currentWidget, usingDefaultFrames)
        updateDefaultFramesNotice(currentWidget, usingDefaultFrames)

        local desiredHeight = getDesiredPreviewHeight(currentWidget)
        if currentWidget.DesiredHeight ~= desiredHeight then
            currentWidget.DesiredHeight = desiredHeight
            if Ui.UpdateDesignerPreviewPlacement then
                Ui.UpdateDesignerPreviewPlacement()
            end
        end

        if currentWidget.Overlay then
            stopSelectedPreviewGlow(currentWidget)
            currentWidget.Overlay:Delete()
            currentWidget.Overlay = nil
        end

        local indicatorData = spec and DesignerState.EnsureSpecIndicators(spec)
        local overlay = Ui.CreateIndicatorOverlay(indicatorData)
        if overlay then
            overlay:SetParent(currentWidget)
            overlay:AttachToFrame(currentWidget.ExampleFrame)
            overlay:ShowPreview()
            currentWidget.Overlay = overlay
            bindPreviewSelectionHandlers(currentWidget, setSelectedIndicatorIndex)
            applySelectedPreviewGlow(currentWidget, getSelectedIndicatorIndex)
            applyPreviewIndicatorFade(currentWidget, getSelectedIndicatorIndex)
        end

        Ui._designerPreviewRefreshing = nil
    end

    if not Ui._designerPreviewPanelHooked then
        Ui.RegisterDesignerPanelHook('show', function()
            if Ui.UpdateDesignerPreviewPlacement then
                Ui.UpdateDesignerPreviewPlacement()
            end
            if Ui.RefreshDesignerPreview then
                Ui.RefreshDesignerPreview()
            end
        end)

        Ui.RegisterDesignerPanelHook('hide', function()
            if Ui.DesignerPreviewWidget then
                stopSelectedPreviewGlow(Ui.DesignerPreviewWidget)
                Ui.DesignerPreviewWidget:Hide()
            end
        end)

        Ui.RegisterDesignerPanelHook('tick', function()
            if Ui.UpdateDesignerPreviewPlacement then
                Ui.UpdateDesignerPreviewPlacement()
            end
        end)

        Ui._designerPreviewPanelHooked = true
    end

    Ui._designerPreviewInitialized = true
    return Ui.DesignerPreviewWidget
end
