local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

function Ui.CreateDropdown(type)
    local newDropdown = Ui.DropdownSelectorPool:Acquire()
    newDropdown:Setup(type)
    return newDropdown
end

function Ui.CreateSlider(type)
    local newSlider = Ui.SliderPool:Acquire()
    newSlider:Setup(type)
    return newSlider
end

--TODO: this generator and the function that pulls the data from the elements of the container are a pain, need to rewrite them so they pull from the same list
--Create the options for a given indicator type. if saved settings is passed that data is used to init the control
function Ui.CreateIndicatorOptions(type, spec, savedSettings)
    local containerFrame = Ui.ContainerFramePool:Acquire()
    containerFrame.type = type
    containerFrame.savedSetting.spec = spec

    local spellSelector = Ui.SpellSelectorFramePool:Acquire()
    spellSelector.spec = spec
    if savedSettings and savedSettings.Spell then
        spellSelector.selectedOption = savedSettings.Spell
    end
    spellSelector:GenerateMenu()
    table.insert(containerFrame.elements, spellSelector)

    if type == 'healthColor' then
        local colorPicker = Ui.ColorPickerFramePool:Acquire()
        if savedSettings and savedSettings.Color then
            local color = savedSettings.Color
            colorPicker.Color:SetVertexColor(color.r, color.g, color.b, color.a)
        end
        table.insert(containerFrame.elements, colorPicker)
    elseif type == 'icon' then
        local iconPositionSelector = Ui.CreateDropdown('iconPosition')
        if savedSettings and savedSettings.Position then
            iconPositionSelector.selectedOption = savedSettings.Position
            iconPositionSelector:GenerateMenu()
        end
        table.insert(containerFrame.elements, iconPositionSelector)
        local iconSizeSlider = Ui.CreateSlider('iconSize')
        if savedSettings and savedSettings.Size then
            iconSizeSlider:SetValue(savedSettings.Size)
        end
        table.insert(containerFrame.elements, iconSizeSlider)
        local iconXOffsetSlider = Ui.CreateSlider('xOffset')
        if savedSettings and savedSettings.xOffset then
            iconXOffsetSlider:SetValue(savedSettings.xOffset)
        end
        table.insert(containerFrame.elements, iconXOffsetSlider)
        local iconYOffsetSlider = Ui.CreateSlider('yOffset')
        if savedSettings and savedSettings.yOffset then
            iconYOffsetSlider:SetValue(savedSettings.yOffset)
        end
        table.insert(containerFrame.elements, iconYOffsetSlider)
    elseif type == 'square' then
        local colorPicker = Ui.ColorPickerFramePool:Acquire()
        if savedSettings and savedSettings.Color then
            local color = savedSettings.Color
            colorPicker.Color:SetVertexColor(color.r, color.g, color.b, color.a)
        end
        table.insert(containerFrame.elements, colorPicker)
        local iconPositionSelector = Ui.CreateDropdown('iconPosition')
        if savedSettings and savedSettings.Position then
            iconPositionSelector.selectedOption = savedSettings.Position
            iconPositionSelector:GenerateMenu()
        end
        table.insert(containerFrame.elements, iconPositionSelector)
        local iconSizeSlider = Ui.CreateSlider('iconSize')
        if savedSettings and savedSettings.Size then
            iconSizeSlider:SetValue(savedSettings.Size)
        end
        table.insert(containerFrame.elements, iconSizeSlider)
        local iconXOffsetSlider = Ui.CreateSlider('xOffset')
        if savedSettings and savedSettings.xOffset then
            iconXOffsetSlider:SetValue(savedSettings.xOffset)
        end
        table.insert(containerFrame.elements, iconXOffsetSlider)
        local iconYOffsetSlider = Ui.CreateSlider('yOffset')
        if savedSettings and savedSettings.yOffset then
            iconYOffsetSlider:SetValue(savedSettings.yOffset)
        end
        table.insert(containerFrame.elements, iconYOffsetSlider)
    elseif type == 'bar' then
        local colorPicker = Ui.ColorPickerFramePool:Acquire()
        if savedSettings and savedSettings.Color then
            local color = savedSettings.Color
            colorPicker.Color:SetVertexColor(color.r, color.g, color.b, color.a)
        end
        table.insert(containerFrame.elements, colorPicker)
        local barPositionSelector = Ui.CreateDropdown('barPosition')
        if savedSettings and savedSettings.Position then
            barPositionSelector.selectedOption = savedSettings.Position
            barPositionSelector:GenerateMenu()
        end
        table.insert(containerFrame.elements, barPositionSelector)
        local barSizeSlider = Ui.CreateSlider('barSize')
        if savedSettings and savedSettings.Size then
            barSizeSlider:SetValue(savedSettings.Size)
        end
        table.insert(containerFrame.elements, barSizeSlider)
        local barOrientationSelector = Ui.CreateDropdown('barOrientation')
        if savedSettings and savedSettings.Orientation then
            barOrientationSelector.selectedOption = savedSettings.Orientation
            barOrientationSelector:GenerateMenu()
        end
        table.insert(containerFrame.elements, barOrientationSelector)
        local barScaleSelector = Ui.CreateDropdown('barScale')
        if savedSettings and savedSettings.Scale then
            barScaleSelector.selectedOption = savedSettings.Scale
            barScaleSelector:GenerateMenu()
        end
        table.insert(containerFrame.elements, barScaleSelector)
    end
    local deleteButton = Ui.DeleteIndicatorOptionsButtonPool:Acquire()
    deleteButton.parent = containerFrame
    containerFrame.deleteButton = deleteButton
    containerFrame:AnchorElements()
    return containerFrame
end

function Ui.CreateIndicatorOverlay(indicatorDataTable)
    local newIndicatorOverlay = Ui.IndicatorOverlayPool:Acquire()
    if indicatorDataTable and type(indicatorDataTable) == 'table' then
        for _, indicatorData in ipairs(indicatorDataTable) do
            if indicatorData.Type == 'icon' then
                local newIcon = Ui.IconIndicatorPool:Acquire()
                newIcon.spell = indicatorData.Spell
                newIcon:SetParent(newIndicatorOverlay)
                newIcon:SetSize(indicatorData.Size, indicatorData.Size)
                newIcon:SetPoint(indicatorData.Position, newIndicatorOverlay, indicatorData.Position, indicatorData.xOffset, indicatorData.yOffset)
                table.insert(newIndicatorOverlay.elements, newIcon)
            elseif indicatorData.Type == 'square' then
                local newSquare = Ui.SquareIndicatorPool:Acquire()
                newSquare.spell = indicatorData.Spell
                local color = indicatorData.Color
                newSquare:SetParent(newIndicatorOverlay)
                newSquare:SetSize(indicatorData.Size, indicatorData.Size)
                newSquare:SetPoint(indicatorData.Position, newIndicatorOverlay, indicatorData.Position, indicatorData.xOffset, indicatorData.yOffset)
                newSquare.texture:SetColorTexture(color.r, color.g, color.b, color.a)
                table.insert(newIndicatorOverlay.elements, newSquare)
            elseif indicatorData.Type == 'bar' then
                local newBar = Ui.BarIndicatorPool:Acquire()
                newBar.spell = indicatorData.Spell
                local color = indicatorData.Color
                newBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
                newBar:SetParent(newIndicatorOverlay)
                local anchorData = Util.FigureOutBarAnchors(indicatorData)
                if anchorData.points then
                    for _, anchor in ipairs(anchorData.points) do
                        newBar:SetPoint(anchor.point, newIndicatorOverlay, anchor.relative)
                    end
                end
                if anchorData.sizing.Orientation then
                    newBar:SetOrientation(anchorData.sizing.Orientation)
                    if anchorData.sizing.Orientation == 'VERTICAL' then
                        newBar:SetWidth(indicatorData.Size)
                    else
                        newBar:SetHeight(indicatorData.Size)
                    end
                end
                if anchorData.sizing.Reverse then
                    newBar:SetReverseFill(true)
                end
                newBar.spell = indicatorData.Spell
                table.insert(newIndicatorOverlay.elements, newBar)
            elseif indicatorData.Type == 'healthColor' then
                local newHealthRecolor = Ui.HealthColorIndicatorPool:Acquire()
                newHealthRecolor.spell = indicatorData.Spell
                newHealthRecolor.color = indicatorData.Color
                table.insert(newIndicatorOverlay.elements, newHealthRecolor)
            end
        end
        return newIndicatorOverlay
    end
end

function Ui.GetSpotlightFrame()
    if not Ui.SpotlightFrame then
        local spotlightFrame = CreateFrame('Frame', 'AdvancedRaidFramesSpotlight', UIParent, 'InsetFrameTemplate')
        spotlightFrame:SetSize(200, 50)
        spotlightFrame:SetPoint('CENTER', UIParent, 'CENTER')
        spotlightFrame.text = spotlightFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
        spotlightFrame.text:SetPoint("CENTER", spotlightFrame, 'CENTER')
        spotlightFrame.text:SetText('Advanced Raid Frames\nSpotlight')
        spotlightFrame:SetAlpha(0)
        Ui.SpotlightFrame = spotlightFrame
    end
    return Ui.SpotlightFrame
end