local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local Debug = NS.Debug
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--Container frame is a holder for indicator option elements
Ui.ContainerFramePool = CreateFramePool('Frame', nil, 'InsetFrameTemplate3',
    function(_, frame)
        frame:ReleaseElements()
        frame:ClearAllPoints()
        frame:Hide()
        frame.type = nil
        frame.savedSetting.spec = nil
        frame.savedSetting.index = nil
    end, false,
    function(frame)
        frame.elements = {}
        frame.sections = {
            buttons = {},
            elements = {}
        }
        frame.deleteButton = nil
        frame.savedSetting = { spec = nil, index = nil }
        frame.index = nil
        frame.text = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        frame.text:SetPoint('TOPLEFT', frame, 'TOPLEFT', 10, -10)
        frame.text:SetScale(1.3)
        frame.type = nil
        frame.SetupText = function(self, index)
            self.index = index
            local spell
            local dataTable = SavedIndicators[self.savedSetting.spec][self.savedSetting.index]
            if dataTable and dataTable.Spell then
                spell = dataTable.Spell
            end
            if self.type then
                local text = index .. '. ' .. Data.indicatorTypes[self.type].display
                if spell then
                    text = text .. ' - '
                    local texture = Data.textures[spell]
                    if texture then
                        text = text .. '|T' .. texture .. ':16|t '
                    end
                    text = text .. spell
                end
                self.text:SetText(text)
            end
        end
        frame.ClearSections = function(self)
            for _, button in ipairs(self.sections.buttons) do
                button:Release()
            end
            for _, section in pairs(self.sections.elements) do
                if section.container then
                    section.container:Release()
                end
            end
            wipe(self.sections.buttons)
            wipe(self.sections.elements)
        end
        frame.DisplaySection = function(self, section)
            Data.optionSections[self.savedSetting.spec][self.savedSetting.index] = section
            for _, element in ipairs(self.elements) do
                if section == element.section then
                    element:Show()
                else
                    element:Hide()
                end
            end
        end
        frame.AnchorElements = function(self)
            self:ClearSections()
            local sectionElements = self.sections.elements
            local activeSection
            if Data.optionSections[self.savedSetting.spec] and Data.optionSections[self.savedSetting.spec][self.savedSetting.index] then
                activeSection = Data.optionSections[self.savedSetting.spec][self.savedSetting.index]
            else
                if not Data.optionSections[self.savedSetting.spec] then Data.optionSections[self.savedSetting.spec] = {} end
                activeSection = self.elements[1].section
                Data.optionSections[self.savedSetting.spec][self.savedSetting.index] = activeSection
            end

            for _, element in ipairs(self.elements) do
                element:ClearAllPoints()
                element:SetParent(self)
                local parent, point, rel, xOff, yOff
                local currentSection = element.section
                --If the section of the current control doesn't exist, initialize it
                if not sectionElements[currentSection] then
                    local sectionContainer = Ui.ControlSectionContainerPool:Acquire()
                    sectionContainer:AttachToParent(self)
                    sectionElements[currentSection] = {
                        container = sectionContainer,
                        elements = {}
                    }
                    local sectionButton = Ui.ControlSectionButtonPool:Acquire()
                    sectionButton:Initialize(self, currentSection)
                    table.insert(self.sections.buttons, sectionButton)

                    parent = sectionContainer
                    point = 'LEFT'
                    rel = 'LEFT'
                    xOff = 13
                    yOff = 5
                    table.insert(sectionElements[currentSection].elements, element)
                else
                    local currentSectionElements = sectionElements[currentSection].elements
                    parent = currentSectionElements[#currentSectionElements]
                    point = 'LEFT'
                    rel = 'RIGHT'
                    xOff = 10
                    yOff = 0
                    if currentSectionElements[#currentSectionElements].type == 'Checkbox' then
                        local offset = currentSectionElements[#currentSectionElements].Text:GetStringWidth()
                        xOff = offset
                    end
                    table.insert(sectionElements[currentSection].elements, element)
                end

                element:SetPoint(point, parent, rel, xOff, yOff)
                element:SetShown(activeSection == currentSection and true or false)
            end
            for index, button in ipairs(self.sections.buttons) do
                if index == 1 then
                    button:SetPoint('LEFT', self, 'LEFT', 10, 10)
                else
                    button:SetPoint('LEFT', self.sections.buttons[index - 1], 'RIGHT')
                end
                button:Show()
            end
            self.deleteButton:ClearAllPoints()
            self.deleteButton:SetParent(self)
            self.deleteButton:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -2, -2)
        end
        frame.ReleaseElements = function(self)
            for i = #self.elements, 1, -1 do
                local element = self.elements[i]
                element:Release()
                self.elements[i] = nil
            end
            if self.deleteButton then
                self.deleteButton:Release()
                self.deleteButton = nil
            end
            wipe(self.elements)
            self:ClearSections()
        end
        frame.Release = function(self)
            Ui.ContainerFramePool:Release(self)
        end

        --We update the saved data on the container when the children change
        frame.UpdateOptionsData = function(self)
            if self.isLoading then return end
            local savedSetting = self.savedSetting
            if savedSetting.spec and savedSetting.index and SavedIndicators[savedSetting.spec][savedSetting.index] then
                local dataTable = SavedIndicators[savedSetting.spec][savedSetting.index]
                wipe(dataTable)
                dataTable.Type = self.type
                local typeData = Data.indicatorTypes[self.type]
                if typeData and typeData.defaults then
                    for key, value in pairs(typeData.defaults) do
                        if type(value) == 'table' then
                            dataTable[key] = CopyTable(value)
                        else
                            dataTable[key] = value
                        end
                    end
                end

                for _, control in ipairs(self.elements) do
                    local settingKey = control.indicatorSetting
                    if settingKey then
                        dataTable[settingKey] = control:GetValue()
                    end
                end
                if self.index then
                    self:SetupText(self.index)
                end
                Util.MapOutUnits()
                local designer = Ui.GetDesignerFrame()
                designer.RefreshPreview()
            end
        end
        frame.DeleteOption = function(self)
            local spec = self.savedSetting.spec
            local index = self.savedSetting.index
            self.savedSetting.spec, self.savedSetting.index = nil, nil
            if spec and index then
                table.remove(SavedIndicators[spec], index)
            end
            local designer = Ui.GetDesignerFrame()
            designer:RefreshScrollBox()
            designer:RefreshPreview()
        end
    end
)

--Empty container for the indicator controls of one section
Ui.ControlSectionContainerPool = CreateFramePool('Frame', nil, nil,
    function(_, frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent()
        frame.section = nil
    end, false,
    function(frame)
        frame.AttachToParent = function(self, parent)
            self:SetParent(parent)
            self:SetPoint('TOPLEFT', parent, 'LEFT')
            self:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT')
        end
        frame.Release = function(self)
            Ui.ControlSectionContainerPool:Release(self)
        end
    end
)

--Buttons to swap between the control sections
Ui.ControlSectionButtonPool = CreateFramePool('Button', nil, 'UIPanelButtonTemplate',
    function(_, frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame.section = ''
        frame:SetText('')
        frame:SetParent()
    end, false,
    function(frame)
        frame:SetSize(100, 25)
        frame.section = ''
        frame.Initialize = function(self, parent, text)
            self:SetParent(parent)
            self:SetText(text)
            frame.section = text
        end
        frame:SetScript('OnClick', function(self)
            local parent = self:GetParent()
            if parent then
                parent:DisplaySection(self.section)
            end
        end)
        frame.Release = function(self)
            Ui.ControlSectionButtonPool:Release(self)
        end
    end
)

--Color picker pool
Ui.ColorPickerFramePool = CreateFramePool('Button', nil, 'ColorSwatchTemplate',
    function(_, frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent()
        frame.indicatorSetting = nil
        frame.section = nil
        frame.Color:SetVertexColor(0, 1, 0, 1)
    end, false,
    function(frame)
        frame.type = 'ColorPicker'
        frame.Color:SetVertexColor(0, 1, 0, 1)
        frame.OnColorChanged = function()
            local newR, newG, newB = ColorPickerFrame:GetColorRGB()
            local newA = ColorPickerFrame:GetColorAlpha();
            frame.Color:SetVertexColor(newR, newG, newB, newA)
            local parent = frame:GetParent()
            if parent then
                parent:UpdateOptionsData()
            end
        end
        frame.GetValue = function(self)
            local r, g, b, a = self.Color:GetVertexColor()
            return { r = r, g = g, b = b, a = a }
        end
        frame.OnCancel = function()
            local newR, newG, newB, newA = ColorPickerFrame:GetPreviousValues();
            frame.Color:SetVertexColor(newR, newG, newB, newA)
        end
        frame:SetScript('OnClick', function(self)
            local r, g, b, a = self.Color:GetVertexColor()
            ColorPickerFrame:SetupColorPickerAndShow({
                swatchFunc = self.OnColorChanged,
                opacityFunc = self.OnColorChanged,
                cancelFunc = self.OnCancel,
                hasOpacity = true,
                opacity = a,
                r = r,
                g = g,
                b = b,
            })
        end)
        frame.Release = function(self)
            Ui.ColorPickerFramePool:Release(self)
        end
    end
)

--Spell selector pool
Ui.SpellSelectorFramePool = CreateFramePool('DropdownButton', nil, "WowStyle1DropdownTemplate",
    function(_, frame)
        frame.spec = nil
        frame.selectedOption = nil
        frame.indicatorSetting = nil
        frame.section = nil
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent()
        frame:CloseMenu()
    end, false,
    function(frame)
        frame.type = 'SpellSelector'
        frame:SetWidth(150)
        frame.spec = nil
        frame.selectedOption = nil
        frame:SetupMenu(function(owner, root)
            root:CreateTitle('Pick Aura To Track')
            if frame.spec then
                for _, spellData in pairs(Data.specInfo[frame.spec].auras) do
                    if not frame.selectedOption then frame.selectedOption = spellData.name end
                    if not spellData.hide then
                        root:CreateRadio(
                            spellData.name,
                            function() return frame.selectedOption and frame.selectedOption == spellData.name end,
                            function()
                                frame.selectedOption = spellData.name
                                local parent = frame:GetParent()
                                if parent then
                                    parent:UpdateOptionsData()
                                end
                            end
                        )
                    end
                end
            end
        end)
        frame.GetValue = function(self)
            return self.selectedOption
        end
        frame.Release = function(self)
            Ui.SpellSelectorFramePool:Release(self)
        end
    end
)

Ui.DropdownSelectorPool = CreateFramePool('DropdownButton', nil, "WowStyle1DropdownTemplate",
    function(_, frame)
        frame.selectedOption = nil
        frame.allOptions = {}
        frame.dropdownType = nil
        frame.indicatorSetting = nil
        frame.section = nil
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent()
        frame:CloseMenu()
        frame:GenerateMenu()
    end, false,
    function(frame)
        frame.type = 'Dropdown'
        frame.dropdownType = nil
        frame:SetWidth(150)
        frame.selectedOption = nil
        frame:SetupMenu(function(owner, root)
            if frame.dropdownType then
                local frameTypeData = Data.dropdownOptions[frame.dropdownType]
                root:CreateTitle(frameTypeData.text)
                local options = frameTypeData.options
                if not frame.selectedOption then frame.selectedOption = frameTypeData.default end
                for _, option in ipairs(options) do
                    root:CreateRadio(
                        option,
                        function() return frame.selectedOption and frame.selectedOption == option end,
                        function()
                            frame.selectedOption = option
                            local parent = frame:GetParent()
                            if parent then
                                parent:UpdateOptionsData()
                            end
                        end
                    )
                end
            end
        end)
        frame.GetValue = function(self)
            return self.selectedOption
        end
        frame.Setup = function(self, type)
            self.dropdownType = type
            self:GenerateMenu()
        end
        frame.Release = function(self)
            Ui.DropdownSelectorPool:Release(self)
        end
    end
)

Ui.DeleteIndicatorOptionsButtonPool = CreateFramePool('Button', nil, 'UIPanelButtonTemplate',
    function(_, frame)
        frame.parent = nil
    end, false,
    function(frame)
        frame:SetSize(30, 30)
        frame:SetText(' X ')
        frame:SetScript('OnClick', function(self)
            if self.parent then
                self.parent:DeleteOption()
            end
        end)
        frame.Release = function(self)
            Ui.DeleteIndicatorOptionsButtonPool:Release(self)
        end
    end
)

Ui.SliderPool = CreateFramePool('Slider', nil, 'MinimalSliderWithSteppersTemplate',
    function(_, frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent()
        frame.Slider:SetValue(0)
        frame.indicatorSetting = nil
        frame.section = nil
        frame.Text:SetText()
    end, false,
    function(frame)
        frame.type = 'Slider'
        frame.sliderType = nil
        frame:SetSize(150, 30)
        frame.formatters = {}
        frame.formatters[MinimalSliderWithSteppersMixin.Label.Top] = CreateMinimalSliderFormatter(
            MinimalSliderWithSteppersMixin.Label.Top,
            function(value) return Util.FormatForDisplay(value) end
        )
        frame.MaxText:Show()
        frame.MinText:Show()
        frame.Text = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
        frame.Text:SetPoint('CENTER', frame, 'BOTTOM', 0, -3)
        frame.Text:SetJustifyH('CENTER')
        frame:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
            local parent = frame:GetParent()
            if parent and parent.UpdateOptionsData then
                parent:UpdateOptionsData()
            end
        end, frame)
        frame.Setup = function(self, type)
            self.sliderType = type
            local typeData = Data.sliderPresets[type]
            local steps = (typeData.max - typeData.min) / typeData.step
            self:Init(typeData.default, typeData.min, typeData.max, steps, self.formatters)
            self.MaxText:SetText(typeData.max)
            self.MinText:SetText(typeData.min)
            self.Text:SetText(typeData.text)
        end
        frame.GetValue = function(self)
            return self.Slider:GetValue()
        end
        frame.Release = function(self)
            Ui.SliderPool:Release(self)
        end
    end
)

Ui.CheckboxPool = CreateFramePool('CheckButton', nil, 'InterfaceOptionsCheckButtonTemplate',
    function(_, frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent()
        frame.setting = nil
        frame.indicatorSetting = nil
        frame.section = nil
        frame.Text:SetText("")
    end, false,
    function(frame)
        frame.type = 'Checkbox'
        frame.setting = nil
        frame:SetScale(1.2)
        frame:SetScript('OnClick', function(self)
            local parent = self:GetParent()
            if parent then
                parent:UpdateOptionsData()
            end
        end)
        frame.GetValue = function(self)
            return self:GetChecked()
        end
        frame.Release = function(self)
            Ui.CheckboxPool:Release(self)
        end
    end
)

function Ui.SetupIndicatorFrame(btn, indicatorData)
    local size = indicatorData.iconSize or 25
    local pos = indicatorData.Position or 'CENTER'
    local xOff = indicatorData.xOffset or 0
    local yOff = indicatorData.yOffset or 0

    if indicatorData.Type == 'icon' then
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(btn)

        local spellTexture = indicatorData.Spell and Data.textures[indicatorData.Spell]
        if spellTexture then
            icon:SetTexture(spellTexture)
        end
        btn:SetIcon(icon)
        
        local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
        cd:SetAllPoints(btn)
        cd:SetReverse(true)
        cd:SetHideCountdownNumbers(not indicatorData.showText or indicatorData.showStacks)
        btn:SetDurationCooldown(cd)
        
        local text = cd:CreateFontString(nil, "OVERLAY")
        text:SetFont('Fonts\\FRIZQT__.TTF', indicatorData.textSize or 16, 'OUTLINE')
        text:SetShadowColor(0, 0, 0, 1)
        text:SetShadowOffset(1, -1)
        text:SetPoint("CENTER")
        if indicatorData.showStacks then
            btn:SetApplicationCount(text)
        end
        
        if indicatorData.textColor then
            local cooldownText = cd:GetCountdownFontString()
            if cooldownText then
                cooldownText:SetTextColor(indicatorData.textColor.r, indicatorData.textColor.g, indicatorData.textColor.b, indicatorData.textColor.a)
            end
        end

        btn:SetSize(size, size)
        btn:SetPoint(pos, btn:GetParent(), pos, xOff, yOff)
    elseif indicatorData.Type == 'square' then
        local square = btn:CreateTexture(nil, "OVERLAY")
        square:SetAllPoints(btn)
        square:SetDrawLayer("OVERLAY")
        square:SetColorTexture(indicatorData.Color.r, indicatorData.Color.g, indicatorData.Color.b, indicatorData.Color.a)
        square:SetBlendMode('BLEND')
        square:Show()
        
        if indicatorData.showCooldown then
            local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
            cd:SetAllPoints(btn)
            cd:SetReverse(true)
            cd:SetHideCountdownNumbers(not indicatorData.showText or indicatorData.showStacks)
            btn:SetDurationCooldown(cd)
            
            if indicatorData.textColor then
                local cooldownText = cd:GetCountdownFontString()
                if cooldownText then
                    cooldownText:SetTextColor(indicatorData.textColor.r, indicatorData.textColor.g, indicatorData.textColor.b, indicatorData.textColor.a)
                end
            end
        end
        
        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont('Fonts\\FRIZQT__.TTF', indicatorData.textSize or 16, 'OUTLINE')
        text:SetShadowColor(0, 0, 0, 1)
        text:SetShadowOffset(1, -1)
        text:SetPoint("CENTER")
        if indicatorData.showStacks then
            btn:SetApplicationCount(text)
        end

        btn:SetSize(size, size)
        btn:SetPoint(pos, btn:GetParent(), pos, xOff, yOff)
    elseif indicatorData.Type == 'bar' then
        local bar = CreateFrame("StatusBar", nil, btn)
        bar:SetStatusBarTexture("Interface/Buttons/WHITE8x8")
        bar:SetStatusBarColor(indicatorData.Color.r, indicatorData.Color.g, indicatorData.Color.b, indicatorData.Color.a)
        
        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(bar)
        bg:SetColorTexture(indicatorData.BackgroundColor.r, indicatorData.BackgroundColor.g, indicatorData.BackgroundColor.b, indicatorData.BackgroundColor.a)
        
        btn:SetDurationBar(bar)
        
        local anchorData = Util.FigureOutBarAnchors(indicatorData)
        if anchorData.points then
            for _, anchor in ipairs(anchorData.points) do
                bar:SetPoint(anchor.point, btn:GetParent(), anchor.relative, anchorData.sizing.xOffset, anchorData.sizing.yOffset)
            end
        end
        if anchorData.sizing.Orientation then
            bar:SetOrientation(anchorData.sizing.Orientation)
            if anchorData.sizing.Orientation == 'VERTICAL' then
                bar:SetWidth(indicatorData.barSize)
            else
                bar:SetHeight(indicatorData.barSize)
            end
        end
        if anchorData.sizing.Reverse then
            bar:SetReverseFill(true)
        else
            bar:SetReverseFill(false)
        end
    elseif indicatorData.Type == 'healthColor' then
        --stub
    elseif indicatorData.Type == 'border' then
        local borderWidth = indicatorData.borderWidth or 3
        local borderColor = indicatorData.Color or { r = 1, g = 1, b = 1, a = 1 }
        local host = btn:GetParent() or UIParent

        local borderFrame = CreateFrame('Frame', nil, btn)
        borderFrame:SetAllPoints(btn)
        borderFrame:SetFrameLevel(btn:GetFrameLevel() + 10)

        local topBorder = borderFrame:CreateTexture(nil, 'OVERLAY')
        topBorder:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
        topBorder:SetPoint('TOPLEFT', btn, 'TOPLEFT')
        topBorder:SetPoint('TOPRIGHT', btn, 'TOPRIGHT')
        topBorder:SetHeight(borderWidth)

        local rightBorder = borderFrame:CreateTexture(nil, 'OVERLAY')
        rightBorder:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
        rightBorder:SetPoint('TOPRIGHT', btn, 'TOPRIGHT')
        rightBorder:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT')
        rightBorder:SetWidth(borderWidth)

        local bottomBorder = borderFrame:CreateTexture(nil, 'OVERLAY')
        bottomBorder:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
        bottomBorder:SetPoint('BOTTOMLEFT', btn, 'BOTTOMLEFT')
        bottomBorder:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT')
        bottomBorder:SetHeight(borderWidth)

        local leftBorder = borderFrame:CreateTexture(nil, 'OVERLAY')
        leftBorder:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
        leftBorder:SetPoint('TOPLEFT', btn, 'TOPLEFT')
        leftBorder:SetPoint('BOTTOMLEFT', btn, 'BOTTOMLEFT')
        leftBorder:SetWidth(borderWidth)

        btn:SetPoint('TOPLEFT', host, 'TOPLEFT', 0, 0)
        btn:SetPoint('BOTTOMRIGHT', host, 'BOTTOMRIGHT', 0, 0)
    end
end

Ui.IconIndicatorPool = CreateFramePool('Frame', nil, nil,
    function(_, frame)
        frame:Hide()
        frame:SetScale(1)
        frame:ClearAllPoints()
        frame:SetParent()
        frame.spell = nil
        frame.stacksText:Hide()
    end, false,
    function(frame)
        frame.texture = frame:CreateTexture(nil, 'ARTWORK')
        frame.texture:SetAllPoints()
        frame.type = 'IconIndicator'
        frame.spell = nil
        frame.previewTimer = nil
        frame.cooldown = CreateFrame('Cooldown', nil, frame, 'CooldownFrameTemplate')
        frame.cooldown:SetAllPoints()
        frame.cooldown:SetReverse(true)
        frame.stacksText = frame.cooldown:CreateFontString(nil, 'OVERLAY')
        frame.stacksText:SetFont('Fonts\\FRIZQT__.TTF', 16, 'OUTLINE')
        frame.stacksText:SetShadowColor(0, 0, 0, 1)
        frame.stacksText:SetShadowOffset(1, -1)
        frame.stacksText:SetPoint('CENTER', frame.cooldown)
        frame.stacksText:Hide()
        frame.Release = function(self)
            if self.previewTimer then
                self.previewTimer:Cancel()
                self.previewTimer = nil
            end
            Ui.IconIndicatorPool:Release(self)
        end
    end
)

--Statusbar display for the overshields
Ui.OvershieldsBarPool = CreateFramePool('StatusBar', nil, nil,
    function(_, frame)
        frame:Hide()
        frame:SetParent()
        frame:ClearAllPoints()
        frame.mask:ClearAllPoints()
    end, false,
    function(frame)
        frame:SetAlpha(0.8)
        frame:SetReverseFill(true)
        frame:SetStatusBarTexture("")
        frame.texture = frame:GetStatusBarTexture()
        frame.texture:SetDrawLayer("BORDER")
        frame.mask = frame:CreateMaskTexture()
        frame.mask:SetTexture("Interface/TargetingFrame/UI-StatusBar", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        frame.texture:AddMaskTexture(frame.mask)
        frame.AttachToFrame = function(self, parentFrame)
            self:SetParent(parentFrame)
            self:SetAllPoints(parentFrame.healthBar)
            self:SetFrameLevel(parentFrame.healthBar:GetFrameLevel())
            self.mask:SetAllPoints(parentFrame.healthBar:GetStatusBarTexture())
            Util.SetStatusbarTextureOrAtlas(self, Data.barTextures[Options.overshieldsTexture])
            self:Show()
        end
        frame.Release = function(self)
            Ui.OvershieldsBarPool:Release(self)
        end
    end
)