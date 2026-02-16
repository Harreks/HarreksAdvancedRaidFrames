local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
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
        frame.deleteButton = nil
        frame.savedSetting = { spec = nil, index = nil }
        frame.text = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        frame.text:SetPoint('TOPLEFT', frame, 'TOPLEFT', 10, -10)
        frame.text:SetScale(1.3)
        frame.type = nil
        frame:SetHeight(80)
        frame.SetupText = function(self, index)
            if self.type then
                self.text:SetText(index .. '. ' .. Data.indicatorTypes[self.type].display)
            end
        end
        frame.AnchorElements = function(self)
            for index, element in ipairs(self.elements) do
                element:ClearAllPoints()
                element:SetParent(self)
                local parent, point, rel, xOff, yOff
                if index == 1 then
                    parent = self
                    point = 'BOTTOMLEFT'
                    rel = 'BOTTOMLEFT'
                    xOff = 13
                    yOff = 20
                else
                    parent = self.elements[index - 1]
                    point = 'LEFT'
                    rel = 'RIGHT'
                    xOff = 10
                    yOff = 0
                    --this is a stupid hardcoded fix to make selectors line up when icons don't have a color picker
                    if self.type == 'icon' and index == 2 then
                        xOff = 35
                    end
                end
                element:SetPoint(point, parent, rel, xOff, yOff)
                element:Show()
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
        end
        frame.Release = function(self)
            Ui.ContainerFramePool:Release(self)
        end

        --We update the saved data on the container when the children change
        frame.UpdateOptionsData = function(self)
            local savedSetting = self.savedSetting
            if savedSetting.spec and savedSetting.index and SavedIndicators[savedSetting.spec][savedSetting.index] then
                local dataTable = SavedIndicators[savedSetting.spec][savedSetting.index]
                wipe(dataTable)
                dataTable.Type = self.type
                --Depending on the type of indicator this controls, we expect different options
                if self.type == 'healthColor' then
                    --Health Colors have just the color and the spell selector
                    for _, control in ipairs(self.elements) do
                        if control.type == 'ColorPicker' then
                            local r, g, b, a = control.Color:GetVertexColor()
                            dataTable.Color = { r = r, g = g, b = b, a = a}
                        elseif control.type == 'SpellSelector' then
                            dataTable.Spell = control.selectedOption
                        end
                    end
                elseif self.type == 'icon' then
                    --Icons have position, size and spell
                    for _, control in ipairs(self.elements) do
                        if control.type == 'Dropdown' and control.dropdownType == 'iconPosition' then
                            dataTable.Position = control.selectedOption
                        elseif control.type == 'Slider' and control.sliderType == 'iconSize' then
                            dataTable.Size = control:GetValue()
                        elseif control.type == 'Slider' and control.sliderType == 'xOffset' then
                            dataTable.xOffset = control:GetValue()
                        elseif control.type == 'Slider' and control.sliderType == 'yOffset' then
                            dataTable.yOffset = control:GetValue()
                        elseif control.type == 'SpellSelector' then
                            dataTable.Spell = control.selectedOption
                        end
                    end
                elseif self.type == 'square' then
                    --Squares have everything the icons do, plus color
                    for _, control in ipairs(self.elements) do
                        if control.type == 'ColorPicker' then
                            local r, g, b, a = control.Color:GetVertexColor()
                            dataTable.Color = { r = r, g = g, b = b, a = a}
                        elseif control.type == 'Dropdown' and control.dropdownType == 'iconPosition' then
                            dataTable.Position = control.selectedOption
                        elseif control.type == 'Slider' and control.sliderType == 'iconSize' then
                            dataTable.Size = control:GetValue()
                        elseif control.type == 'Slider' and control.sliderType == 'xOffset' then
                            dataTable.xOffset = control:GetValue()
                        elseif control.type == 'Slider' and control.sliderType == 'yOffset' then
                            dataTable.yOffset = control:GetValue()
                        elseif control.type == 'SpellSelector' then
                            dataTable.Spell = control.selectedOption
                        end
                    end
                elseif self.type == 'bar' then
                    --Bars have color, position, scale, orientation, and spell
                    for _, control in ipairs(self.elements) do
                        if control.type == 'ColorPicker' then
                            local r, g, b, a = control.Color:GetVertexColor()
                            dataTable.Color = { r = r, g = g, b = b, a = a}
                        elseif control.type == 'Dropdown' and control.dropdownType == 'barPosition' then
                            dataTable.Position = control.selectedOption
                        elseif control.type == 'Dropdown' and control.dropdownType == 'barScale' then
                            dataTable.Scale = control.selectedOption
                        elseif control.type == 'Dropdown' and control.dropdownType == 'barOrientation' then
                            dataTable.Orientation = control.selectedOption
                        elseif control.type == 'Slider' and control.sliderType == 'barSize' then
                            dataTable.Size = control:GetValue()
                        elseif control.type == 'SpellSelector' then
                            dataTable.Spell = control.selectedOption
                        end
                    end
                end
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

--Color picker pool
Ui.ColorPickerFramePool = CreateFramePool('Button', nil, 'ColorSwatchTemplate',
    function(_, frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent()
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
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent()
        frame:CloseMenu()
    end, false,
    function(frame)
        frame.type = 'SpellSelector'
        frame:SetWidth(110)
        frame.spec = nil
        frame.selectedOption = nil
        frame:SetupMenu(function(owner, root)
            root:CreateTitle('Pick Aura To Track')
            if frame.spec then
                for spell, _ in pairs(Data.specInfo[frame.spec].auras) do
                    if not frame.selectedOption then frame.selectedOption = spell end
                    root:CreateRadio(
                        spell,
                        function() return frame.selectedOption and frame.selectedOption == spell end,
                        function()
                            frame.selectedOption = spell
                            local parent = frame:GetParent()
                            if parent then
                                parent:UpdateOptionsData()
                            end
                        end
                    )
                end
            end
        end)
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
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent()
        frame:CloseMenu()
        frame:GenerateMenu()
    end, false,
    function(frame)
        frame.type = 'Dropdown'
        frame.dropdownType = nil
        frame:SetWidth(110)
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

Ui.SliderPool = CreateFramePool('Slider', nil, 'UISliderTemplateWithLabels',
    function(_, frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent()
        frame:SetValue(0)
        frame:SetMinMaxValues(0, 0)
        frame.Text:SetText("")
    end, false,
    function(frame)
        frame.type = 'Slider'
        frame.sliderType = nil
        frame:SetSize(110, 15)
        frame.Current = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
        local font, size, flags = frame.High:GetFont()
        frame.Current:SetScale(frame.High:GetScale())
        frame.Current:SetFont(font, size, flags)
        frame.Current:SetWidth(frame.High:GetWidth())
        frame.Current:SetPoint('TOP', frame, 'BOTTOM')
        frame:SetScript('OnValueChanged', function(self, value)
            self.Current:SetText(value)
            local parent = self:GetParent()
            if parent then
                parent:UpdateOptionsData()
            end
        end)
        frame.Setup = function(self, type)
            self.sliderType = type
            local typeData = Data.sliderPresets[type]
            self:SetMinMaxValues(typeData.min, typeData.max)
            self:SetValueStep(typeData.step)
            self:SetValue(typeData.default)
            self:SetObeyStepOnDrag(true)
            self.Text:SetText(typeData.text)
            self.Current:SetText(typeData.default)
            self.High:SetText(typeData.max)
            self.Low:SetText(typeData.min)
        end
        frame.Release = function(self)
            Ui.SliderPool:Release(self)
        end
    end
)

--All indicators are created inside a container, the container is then anchored to the frame to show the indicators on top of it
Ui.IndicatorOverlayPool = CreateFramePool('Frame', UIParent, nil,
    function(_, frame)
        frame:ReleaseElements()
        frame.unit = nil
        frame:ClearAllPoints()
        frame:Hide()
    end, false,
    function(frame)
        frame.elements = {}
        frame.unit = nil
        frame:SetFrameStrata('DIALOG')
        frame.ReleaseElements = function(self)
            for _, element in ipairs(frame.elements) do
                element:Release()
            end
            wipe(self.elements)
        end
        frame.UpdateIndicators = function(self, auraData)
            for _, element in ipairs(self.elements) do
                element:UpdateIndicator(self.unit, auraData)
            end
        end
        frame.ShowPreview = function(self)
            for _, element in ipairs(self.elements) do
                element:SetScale(1.3)
                element:ShowPreview()
            end
            self:Show()
        end
        frame.AttachToFrame = function(self, unitFrame)
            self:SetAllPoints(unitFrame)
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
        frame.ShowPreview = function(self)
            self.texture:SetTexture(Data.textures[self.spell])
            self.cooldown:SetCooldown(GetTime(), 30)
            if not self.previewTimer then
                self.previewTimer = C_Timer.NewTicker(30, function()
                    self:ShowPreview()
                end)
            end
            self:Show()
        end
        frame.UpdateIndicator = function(self, unit, auraData)
            if self.spell and auraData[self.spell] then
                local aura = auraData[self.spell]
                local duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
                self.texture:SetTexture(aura.icon)
                self.cooldown:SetCooldownFromDurationObject(duration)
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
    end, false,
    function(frame)
        frame.texture = frame:CreateTexture(nil, 'ARTWORK')
        frame.texture:SetAllPoints()
        frame.type = 'SquareIndicator'
        frame.spell = nil
        frame.UpdateIndicator = function(self, unit, auraData)
            if self.spell and auraData[self.spell] then
                self:Show()
            else
                self:Hide()
            end
        end
        frame.ShowPreview = function(self)
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
        frame.UpdateIndicator = function(self, unit, auraData)
            if self.spell and auraData[self.spell] then
                local aura = auraData[self.spell]
                local duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
                self:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
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

Ui.HealthColorIndicatorPool = CreateFramePool('Frame', nil, nil,
    function(_, frame)
        frame.spell = nil
    end, false,
    function(frame)
        frame.spell = nil
        frame.color = nil
        frame.type = 'HealthColor'
        frame.DefaultCallback = function(self, unit, auraData)
            local unitList = Util.GetRelevantList()
            local elements = unitList[unit]
            if self.spell and auraData[self.spell] and elements then
                elements.isColored = true
                elements.recolor = self.color
                local unitFrame = _G[elements.frame]
                if unitFrame and unitFrame.healthBar then
                    --unitFrame.healthBar.barTexture:SetVertexColor(self.color.r, self.color.g, self.color.b)
                end
            else
                elements.isColored = false
                elements.recolor = nil
                local unitFrame = _G[elements.frame]
                --CompactUnitFrame_UpdateHealthColor(unitFrame)
            end
        end
        frame.UpdateIndicator = function(self, unit, auraData)
            self:DefaultCallback(unit, auraData)
        end
        frame.ShowPreview = function(self) end
        frame.Release = function(self)
            Ui.HealthColorIndicatorPool:Release(self)
        end
    end
)