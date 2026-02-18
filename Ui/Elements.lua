local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local API = NS.API
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

local indicatorControlFactories = {
    SpellSelector = function(spec, controlData, savedSettings)
        local control = Ui.SpellSelectorFramePool:Acquire()
        control.spec = spec
        if savedSettings and savedSettings[controlData.setting] then
            control.selectedOption = savedSettings[controlData.setting]
        end
        control:GenerateMenu()
        return control
    end,
    ColorPicker = function(_, controlData, savedSettings)
        local control = Ui.ColorPickerFramePool:Acquire()
        if savedSettings and savedSettings[controlData.setting] then
            local color = savedSettings[controlData.setting]
            control.Color:SetVertexColor(color.r, color.g, color.b, color.a)
        end
        return control
    end,
    Dropdown = function(_, controlData, savedSettings)
        local control = Ui.CreateDropdown(controlData.dropdownType)
        if savedSettings and savedSettings[controlData.setting] then
            control.selectedOption = savedSettings[controlData.setting]
            control:GenerateMenu()
        end
        return control
    end,
    Slider = function(_, controlData, savedSettings)
        local control = Ui.CreateSlider(controlData.sliderType)
        if savedSettings and savedSettings[controlData.setting] ~= nil then
            control:SetValue(savedSettings[controlData.setting])
        end
        return control
    end,
    Checkbox = function(_, controlData, savedSettings)
        local control = Ui.CheckboxPool:Acquire()
        control.setting = controlData.setting
        control.Text:SetText(controlData.text)
        if savedSettings and savedSettings[controlData.setting] ~= nil then
            control:SetChecked(savedSettings[controlData.setting])
        end
        return control
    end
}

--Create the options for a given indicator type. if saved settings is passed that data is used to init the control
function Ui.CreateIndicatorOptions(type, spec, savedSettings)
    local containerFrame = Ui.ContainerFramePool:Acquire()
    containerFrame.type = type
    containerFrame.savedSetting.spec = spec

    local typeSettings = Data.indicatorTypeSettings[type]
    if typeSettings and typeSettings.controls then
        for _, controlData in ipairs(typeSettings.controls) do
            local factory = indicatorControlFactories[controlData.controlType]
            local control = factory and factory(spec, controlData, savedSettings)

            if control then
                control.indicatorSetting = controlData.setting
                control.layoutRow = controlData.row or 1
                table.insert(containerFrame.elements, control)
            end
        end
    end

    local deleteButton = Ui.DeleteIndicatorOptionsButtonPool:Acquire()
    deleteButton.parent = containerFrame
    containerFrame.deleteButton = deleteButton
    containerFrame:AnchorElements()

    -- This is a bit stupid *shrug* should rework it along with the whole indicators
    -- At least is a fix to that bug i guess?
    containerFrame.LoadSavedSettings = function(self, saved)
        local data = saved or (self.savedSetting and self.savedSetting.spec and self.savedSetting.index and SavedIndicators[self.savedSetting.spec] and SavedIndicators[self.savedSetting.spec][self.savedSetting.index])
        if not data then return end
        for _, control in ipairs(self.elements) do
            if control.type == 'SpellSelector' then
                control.selectedOption = data.Spell
                control:GenerateMenu()
            elseif control.type == 'ColorPicker' then
                if data.Color then
                    local c = data.Color
                    control.Color:SetVertexColor(c.r, c.g, c.b, c.a)
                end
            elseif control.type == 'Dropdown' then
                if control.dropdownType == 'iconPosition' and data.Position then
                    control.selectedOption = data.Position
                    control:GenerateMenu()
                elseif control.dropdownType == 'barPosition' and data.Position then
                    control.selectedOption = data.Position
                    control:GenerateMenu()
                elseif control.dropdownType == 'barScale' and data.Scale then
                    control.selectedOption = data.Scale
                    control:GenerateMenu()
                elseif control.dropdownType == 'barOrientation' and data.Orientation then
                    control.selectedOption = data.Orientation
                    control:GenerateMenu()
                end
            elseif control.type == 'Slider' then
                if data[control.sliderType] ~= nil then
                    control:SetValue(data[control.sliderType])
                end
            elseif control.type == 'Checkbox' then
                if data[control.setting] ~= nil then
                    control:SetChecked(data[control.setting])
                end
            end
        end
        self:AnchorElements()
    end

    return containerFrame
end

local indicatorOverlayRenderers = {
    icon = function(overlay, indicatorData)
        local newIcon = Ui.IconIndicatorPool:Acquire()
        newIcon.spell = indicatorData.Spell
        newIcon:SetParent(overlay)
        newIcon:SetSize(indicatorData.Size, indicatorData.Size)
        newIcon:SetPoint(indicatorData.Position, overlay, indicatorData.Position, indicatorData.xOffset, indicatorData.yOffset)
        newIcon.cooldown:SetScale(indicatorData.textSize)
        newIcon.cooldown:SetHideCountdownNumbers(not indicatorData.showText)
        newIcon.texture:SetShown(indicatorData.showTexture)
        newIcon.cooldown:SetDrawSwipe(indicatorData.showTexture)
        newIcon.cooldown:SetDrawEdge(indicatorData.showTexture)
        newIcon.cooldown:SetDrawBling(indicatorData.showTexture)
        return newIcon
    end,
    square = function(overlay, indicatorData)
        local newSquare = Ui.SquareIndicatorPool:Acquire()
        newSquare.spell = indicatorData.Spell
        local color = indicatorData.Color
        newSquare:SetParent(overlay)
        newSquare:SetSize(indicatorData.Size, indicatorData.Size)
        newSquare:SetPoint(indicatorData.Position, overlay, indicatorData.Position, indicatorData.xOffset, indicatorData.yOffset)
        newSquare.texture:SetColorTexture(color.r, color.g, color.b, color.a)
        newSquare.showCooldown = indicatorData.showCooldown
        newSquare.cooldown:SetScale(indicatorData.textSize)
        newSquare.cooldown:SetShown(indicatorData.showCooldown)
        return newSquare
    end,
    bar = function(overlay, indicatorData)
        local newBar = Ui.BarIndicatorPool:Acquire()
        newBar.spell = indicatorData.Spell
        local color = indicatorData.Color
        newBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
        newBar:SetParent(overlay)
        local anchorData = Util.FigureOutBarAnchors(indicatorData)
        if anchorData.points then
            for _, anchor in ipairs(anchorData.points) do
                newBar:SetPoint(anchor.point, overlay, anchor.relative, anchorData.sizing.xOffset, anchorData.sizing.yOffset)
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
        return newBar
    end,
    healthColor = function(overlay, indicatorData)
        local newHealthRecolor = Ui.HealthColorIndicatorPool:Acquire()
        newHealthRecolor.spell = indicatorData.Spell
        newHealthRecolor.color = indicatorData.Color
        newHealthRecolor:SetParent(overlay)
        newHealthRecolor:SetAllPoints()
        return newHealthRecolor
    end
}

function Ui.CreateIndicatorOverlay(indicatorDataTable)
    local newIndicatorOverlay = Ui.IndicatorOverlayPool:Acquire()
    if indicatorDataTable and type(indicatorDataTable) == 'table' then
        for _, indicatorData in ipairs(indicatorDataTable) do
            local renderer = indicatorOverlayRenderers[indicatorData.Type]
            if renderer then
                local element = renderer(newIndicatorOverlay, indicatorData)
                if element then
                    table.insert(newIndicatorOverlay.elements, element)
                end
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