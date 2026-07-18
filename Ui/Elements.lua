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
    containerFrame.savedSetting.index = savedSettings.index

    local typeSettings = Data.indicatorTypes[type]
    if typeSettings and typeSettings.controls then
        for _, controlData in ipairs(typeSettings.controls) do
            local factory = Ui.IndicatorControlFactories[controlData.controlType]
            local control = factory(spec, controlData, savedSettings)

            if control then
                control.indicatorSetting = controlData.setting
                control.section = controlData.section
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

-- Removed Ui.IndicatorOverlayRenderers and Ui.CreateIndicatorOverlay

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

function Ui.RegisterFrameStyle()
    local oUF = NS.oUF
    oUF:RegisterStyle('AdvancedSpotlightStyle', function(self)
        self:RegisterForClicks('AnyUp')
        self:SetScript('OnEnter', UnitFrame_OnEnter)
        self:SetScript('OnLeave', UnitFrame_OnLeave)

        self.bg = self:CreateTexture(nil, 'BACKGROUND')
        self.bg:SetAllPoints(self)
        self.bg:SetColorTexture(0, 0, 0, 0.5)

        local health = CreateFrame('StatusBar', nil, self)
        health:SetPoint('TOPLEFT')
        health:SetPoint('BOTTOMRIGHT')
        health.colorDisconnected = true
        health.colorReaction = true
        health.colorClass = C_CVar.GetCVarBool('raidFramesDisplayClassColor')
        health.bg = health:CreateTexture(nil, 'BORDER')
        health.bg:SetAllPoints(health)
        health.bg:SetColorTexture(0.1, 0.1, 0.1)
        health._SetStatusBarColor = health.SetStatusBarColor
        health.SetStatusBarColor = function(barSelf, r, g, b, a)
            local parent = barSelf:GetParent()
            if parent then
                local unit = parent:GetAttribute('unit')
                if unit then
                    local unitList = Data.unitList
                    local elements = unitList[unit]
                    if not elements.isColored then
                        health._SetStatusBarColor(barSelf, r, g, b, a)
                    end
                end
            end
        end
        self.Health = health

        local name = health:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        self:Tag(name, '[name]')
        self.name = name

        local healthText = health:CreateFontString(nil, 'ARTWORK', 'GameFontDisable')
        local healthDisplayOption = C_CVar.GetCVar('raidFramesHealthText')
        healthText:SetPoint('CENTER', self, 'CENTER')
        healthText:SetFontHeight(19.3)
        self:Tag(healthText, Data.hpStatusOptions[healthDisplayOption])
        self.healthText = healthText

        Util.ApplyFrameStyle(self)
    end)
    oUF:SetActiveStyle('AdvancedSpotlightStyle')
    oUF.DisableBlizzard = function() end
end

function Ui.CreateSpotlights(unitList)
    local oUF = NS.oUF
    if not Data.registeredFrameStyle then
        Ui.RegisterFrameStyle()
        Data.registeredFrameStyle = true
    end
    local spotlightFrame = Ui.GetSpotlightFrame()
    local spotlightFrames = Data.spotlightFrames
    local frameStyle = Util.GetDefaultFrameVisuals()
    for i, unitId in ipairs(unitList) do
        local frame = spotlightFrames[i]
        if not frame then
            frame = oUF:Spawn(unitId)
            spotlightFrames[i] = frame
        end

        frame:ClearAllPoints()
        Util.ApplyFrameStyle(frame, frameStyle, unitId)
        frame:SetAttribute('unit', unitId)

        if i == 1 then
            frame:SetPoint('TOP', spotlightFrame, 'TOP')
        else
            local childPoint, parentPoint, anchorTo = nil, nil, nil
            if Options.spotlight.grow == 'right' then
                if i + 1 == Options.spotlight.groupSize then
                    childPoint, parentPoint, anchorTo = 'TOP', 'BOTTOM', spotlightFrames[1]
                else
                    childPoint, parentPoint, anchorTo = 'LEFT', 'RIGHT', spotlightFrames[i-1]
                end
            else
                if i + 1 == Options.spotlight.groupSize then
                    childPoint, parentPoint, anchorTo = 'LEFT', 'RIGHT', spotlightFrames[1]
                else
                    childPoint, parentPoint, anchorTo = 'TOP', 'BOTTOM', spotlightFrames[i-1]
                end
            end
            frame:SetPoint(childPoint, anchorTo, parentPoint)
        end
        frame:Show()
        frame:UpdateAllElements("ForceUpdate")
    end

    for i = #unitList + 1, #spotlightFrames do
        local frame = spotlightFrames[i]
        if frame then
            frame:ClearAllPoints()
            frame:SetAttribute('unit', nil)
            frame:Hide()
        end
    end
end