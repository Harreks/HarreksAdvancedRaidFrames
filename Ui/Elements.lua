local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local Debug = NS.Debug
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

Ui.IndicatorControlFactories = {
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

    local typeSettings = Data.indicatorTypes[type]
    if typeSettings and typeSettings.controls then
        for _, controlData in ipairs(typeSettings.controls) do
            local factory = Ui.IndicatorControlFactories[controlData.controlType]
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

    containerFrame.LoadSavedSettings = function(self, saved)
        local data = saved or (self.savedSetting and self.savedSetting.spec and self.savedSetting.index and SavedIndicators[self.savedSetting.spec] and SavedIndicators[self.savedSetting.spec][self.savedSetting.index])
        if not data then return end
        self.isLoading = true
        for _, control in ipairs(self.elements) do
            local settingKey = control.indicatorSetting
            if control.type == 'SpellSelector' then
                control.selectedOption = data.Spell
                control:GenerateMenu()
            elseif control.type == 'ColorPicker' and data[settingKey] then
                local c = data[settingKey]
                control.Color:SetVertexColor(c.r, c.g, c.b, c.a)
            elseif control.type == 'Dropdown' and data[settingKey] then
                control.selectedOption = data[settingKey]
                control:GenerateMenu()
            elseif control.type == 'Slider' and data[settingKey] ~= nil then
                control:SetValue(data[settingKey])
            elseif control.type == 'Checkbox' and data[settingKey] ~= nil then
                control:SetChecked(data[settingKey])
            end
        end
        self.isLoading = false
        self:AnchorElements()
    end

    return containerFrame
end

--Generalist functions to get init all the data every indicator needs
--TODO: maybe this could be hooked up to the default data to simplify?
Ui.IndicatorOverlayRenderers = {
    icon = function(overlay, indicatorData)
        local newIcon = Ui.IconIndicatorPool:Acquire()
        newIcon.spell = indicatorData.Spell
        newIcon:SetParent(overlay)
        newIcon:SetSize(indicatorData.iconSize, indicatorData.iconSize)
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
        newSquare:SetSize(indicatorData.iconSize, indicatorData.iconSize)
        newSquare:SetPoint(indicatorData.Position, overlay, indicatorData.Position, indicatorData.xOffset, indicatorData.yOffset)
        newSquare.texture:SetColorTexture(color.r, color.g, color.b, color.a)
        newSquare.cooldown:SetScale(indicatorData.textSize)
        newSquare.showCooldown = indicatorData.showCooldown
        newSquare.cooldown:SetHideCountdownNumbers(not indicatorData.showText)
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
                newBar:SetWidth(indicatorData.barSize)
            else
                newBar:SetHeight(indicatorData.barSize)
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
        return newHealthRecolor
    end,
    border = function(overlay, indicatorData)
        local newBorder = Ui.BorderIndicatorPool:Acquire()
        newBorder.spell = indicatorData.Spell
        newBorder.color = indicatorData.Color
        newBorder:SetWidth(indicatorData.borderWidth)
        newBorder:SetParent(overlay)
        newBorder:SetAllPoints()
        return newBorder
    end
}

--Uses the functions defined above to create a new overlay from the savedvars data table
function Ui.CreateIndicatorOverlay(indicatorDataTable)
    local newIndicatorOverlay = Ui.IndicatorOverlayPool:Acquire()
    if indicatorDataTable and type(indicatorDataTable) == 'table' then
        for _, indicatorData in ipairs(indicatorDataTable) do
            local renderer = Ui.IndicatorOverlayRenderers[indicatorData.Type]
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