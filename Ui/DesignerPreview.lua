local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local L = NS.L
local LibStub = _G.LibStub
local LCG = LibStub and LibStub('LibCustomGlow-1.0', true)
local SavedIndicators = HARFDB.savedIndicators

local PREVIEW_FLOAT_WIDTH = 360
local PREVIEW_FLOAT_HEIGHT = 320

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
            currentWidget.SpecLabel:SetText(string.format(L.DESIGNER_CURRENT_SPEC_FMT, specData.display))
        elseif currentWidget.SpecLabel then
            currentWidget.SpecLabel:SetText(string.format(L.DESIGNER_CURRENT_SPEC_FMT, L.DESIGNER_UNKNOWN))
        end

        if currentWidget.Overlay then
            stopSelectedPreviewGlow(currentWidget)
            currentWidget.Overlay:Delete()
            currentWidget.Overlay = nil
        end

        local indicatorData = SavedIndicators[spec]
        local overlay = Ui.CreateIndicatorOverlay(indicatorData)
        if overlay then
            overlay:SetParent(currentWidget)
            overlay:AttachToFrame(currentWidget.ExampleFrame)
            overlay:ShowPreview()
            currentWidget.Overlay = overlay
            bindPreviewSelectionHandlers(currentWidget, setSelectedIndicatorIndex)
            applySelectedPreviewGlow(currentWidget, getSelectedIndicatorIndex)
        end

        Ui._designerPreviewRefreshing = nil
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

    Ui._designerPreviewInitialized = true
    return Ui.DesignerPreviewWidget
end
