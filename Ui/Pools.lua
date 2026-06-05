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

--All indicators are created inside a container, the container is then anchored to the frame to show the indicators on top of it
Ui.IndicatorOverlayPool = CreateFramePool('Frame', UIParent, nil,
    function(_, frame)
        frame:Hide()
        frame:SetParent(UIParent)
        frame:SetFrameStrata('MEDIUM')
        frame:SetFrameLevel(0)
        frame:ReleaseElements()
        frame.unit = nil
        frame:ClearAllPoints()
    end, false,
    function(frame)
        frame.elements = {}
        frame.unit = nil
        frame.ReleaseElements = function(self)
            for _, element in ipairs(frame.elements) do
                element:Release()
            end
            wipe(self.elements)
        end
        frame.UpdateIndicators = function(self, updatedAuras)
            for _, element in ipairs(self.elements) do
                for buffName, auraInfo in pairs(updatedAuras) do
                    if element.spell == buffName then
                        element:UpdateIndicator(auraInfo)
                        break
                    end
                end
            end
        end
        frame.coloringFunc = nil
        frame.extraFrameIndex = nil
        frame.ShowPreview = function(self)
            for _, element in ipairs(self.elements) do
                element:ShowPreview()
            end
            self:Show()
        end
        frame.AttachToFrame = function(self, unitFrame)
            if not unitFrame then return end
            self:SetParent(unitFrame)
            self:SetAllPoints(unitFrame)
            local parentStrata = unitFrame:GetFrameStrata()
            local parentLevel = unitFrame:GetFrameLevel()
            if parentStrata and parentLevel then
                self:SetFrameStrata(parentStrata)
                self:SetFrameLevel(parentLevel + 5)
            end
        end
        frame.Delete = function(self)
            Ui.IndicatorOverlayPool:Release(self)
        end
    end
)

--This is the default icon indicator that shows on frames
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
        frame.ShowPreview = function(self)
            self.texture:SetTexture(Data.textures[self.spell])
            self.stacksText:SetText('5')
            self.cooldown:SetCooldown(GetTime(), 30)
            if not self.previewTimer then
                self.previewTimer = C_Timer.NewTicker(30, function()
                    self:ShowPreview()
                end)
            end
            self:Show()
        end
        frame.UpdateIndicator = function(self, auraInfo)
            if auraInfo.active and auraInfo.data then
                self.stacksText:SetText(auraInfo.data.applications)
                self.texture:SetTexture(auraInfo.data.icon)
                self.cooldown:SetCooldownFromDurationObject(auraInfo.duration)
                self:Show()
            else
                self:Hide()
            end
        end
        frame.Release = function(self)
            if self.previewTimer then
                self.previewTimer:Cancel()
                self.previewTimer = nil
            end
            Ui.IconIndicatorPool:Release(self)
        end
    end
)

--Square type indicators
Ui.SquareIndicatorPool = CreateFramePool('Frame', nil, nil,
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
        frame.cooldown = CreateFrame('Cooldown', nil, frame, 'CooldownFrameTemplate')
        frame.cooldown:SetAllPoints()
        frame.cooldown:SetReverse(true)
        frame.cooldown:Hide()
        frame.stacksText = frame.cooldown:CreateFontString(nil, 'OVERLAY')
        frame.stacksText:SetFont('Fonts\\FRIZQT__.TTF', 16, 'OUTLINE')
        frame.stacksText:SetShadowColor(0, 0, 0, 1)
        frame.stacksText:SetShadowOffset(1, -1)
        frame.stacksText:SetPoint('CENTER', frame.cooldown)
        frame.stacksText:Hide()
        frame.type = 'SquareIndicator'
        frame.spell = nil
        frame.UpdateIndicator = function(self, auraInfo)
            if auraInfo.active and auraInfo.data then
                self.stacksText:SetText(auraInfo.data.applications)
                if self.showCooldown then
                    self.cooldown:SetCooldownFromDurationObject(auraInfo.duration)
                    self.cooldown:Show()
                else
                    self.cooldown:Hide()
                end
                self:Show()
            else
                self:Hide()
            end
        end
        frame.ShowPreview = function(self)
            if self.showCooldown then
                self.cooldown:SetCooldown(GetTime(), 30)
                self.cooldown:Show()
            else
                self.cooldown:Hide()
            end
            self.stacksText:SetText('5')
            if not self.previewTimer then
                self.previewTimer = C_Timer.NewTicker(30, function()
                    self:ShowPreview()
                end)
            end
            self:Show()
        end
        frame.Release = function(self)
            Ui.SquareIndicatorPool:Release(self)
        end
    end
)

--Progress Bars
Ui.BarIndicatorPool = CreateFramePool('StatusBar', nil, nil,
    function(_, frame)
        frame:Hide()
        frame:SetScale(1)
        frame:ClearAllPoints()
        frame:SetParent()
        frame.spell = nil
    end, false,
    function(frame)
        frame:SetStatusBarTexture("Interface/Buttons/WHITE8x8")
        frame.background = frame:CreateTexture(nil, 'BACKGROUND')
        frame.background:SetAllPoints(frame)
        frame.background:SetColorTexture(0, 0, 0, 1)
        frame.type = 'BarIndicator'
        frame.previewTimer = nil
        frame.spell = nil
        frame.UpdateIndicator = function(self, auraInfo)
            if auraInfo.active and auraInfo.data then
                self:SetTimerDuration(auraInfo.duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
                self:Show()
            else
                self:Hide()
            end
        end
        frame.ShowPreview = function(self)
            local duration = C_DurationUtil.CreateDuration()
            duration:SetTimeFromStart(GetTime(), 30)
            self:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
            if not self.previewTimer then
                self.previewTimer = C_Timer.NewTicker(30, function()
                    local duration = C_DurationUtil.CreateDuration()
                    duration:SetTimeFromStart(GetTime(), 30)
                    self:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
                end)
            end
            self:Show()
        end
        frame.Release = function(self)
            if self.previewTimer then
                self.previewTimer:Cancel()
                self.previewTimer = nil
            end
            Ui.BarIndicatorPool:Release(self)
        end
    end
)

--Colored border around the frame
Ui.BorderIndicatorPool = CreateFramePool('Frame', nil, 'BackdropTemplate',
    function(_, frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent()
        frame.coloringFunc = nil
        frame.spell = nil
    end, false,
    function(frame)
        frame.spell = nil
        frame.color = nil
        frame.type = 'Border'
        frame.defaultBackdrop = {
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 3,
            tile = true, tileSize = 16,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        }
        frame:SetBackdropColor(0, 0, 0, 0)
        frame:Hide()
        frame.UpdateIndicator = function(self, auraInfo)
            if auraInfo.active and auraInfo.data then
                self:SetBackdropBorderColor(self.color.r, self.color.g, self.color.b)
                self:Show()
            else
                self:Hide()
            end
        end
        frame.SetWidth = function(self, width)
            self:ClearBackdrop()
            self.backdropInfo = CopyTable(self.defaultBackdrop)
            self.backdropInfo.edgeSize = width
            self:ApplyBackdrop()
        end
        frame.ShowPreview = function(self)
            self:SetBackdropBorderColor(self.color.r, self.color.g, self.color.b)
            self:Show()
        end
        frame.Release = function(self)
            Ui.BorderIndicatorPool:Release(self)
        end
    end
)

--This indicator recolors the frame of the unit, doesn't show anything by itself
Ui.HealthColorIndicatorPool = CreateFramePool('Frame', nil, nil,
    function(_, frame)
        frame:SetParent()
        frame.spell = nil
        frame.oldColor = nil
        frame.color = nil
    end, false,
    function(frame)
        frame.spell = nil
        frame.color = nil
        frame.type = 'HealthColor'
        frame.UpdateIndicator = function(self, auraInfo)
            local overlay = self:GetParent()
            local unitList = Data.unitList
            local unit = overlay.unit
            local elements = unitList[unit]
            if elements then
                local unitFrame = overlay:GetParent()
                if unitFrame then
                    local texture = Util.GetFrameHealthTexture(unitFrame)
                    if texture then
                        local isDefault = unitFrame == _G[elements.frame]
                        if not isDefault and not texture._HARF_Hooked then
                            texture._HARF_SetVertexColor = texture.SetVertexColor
                            texture.SetVertexColor = Util.CustomSetVertexColor
                            texture._HARF_Hooked = true
                        end
                        if auraInfo.active and auraInfo.data then
                            elements.isColored = true
                            elements.recolor = self.color
                            if not self.oldColor then
                                local oldR, oldG, oldB = texture:GetVertexColor()
                                self.oldColor = { r = oldR, g = oldG, b = oldB }
                            end
                            if isDefault then
                                texture:SetVertexColor(self.color.r, self.color.g, self.color.b)
                            else
                                texture:_HARF_SetVertexColor(self.color.r, self.color.g, self.color.b)
                            end
                        else
                            elements.isColored = false
                            elements.recolor = nil
                            if self.oldColor then
                                if isDefault then
                                    texture:SetVertexColor(self.oldColor.r, self.oldColor.g, self.oldColor.b)
                                else
                                    texture:_HARF_SetVertexColor(self.oldColor.r, self.oldColor.g, self.oldColor.b)
                                end
                                self.oldColor = nil
                            end
                        end
                    end
                end
            end
        end
        frame.ShowPreview = function() end
        frame.Release = function(self)
            Ui.HealthColorIndicatorPool:Release(self)
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