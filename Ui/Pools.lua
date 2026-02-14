local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--Container frame is a holder for indicator option elements
Ui.ContainerFramePool = CreateFramePool('Frame', nil, nil,
    function(_, frame)
        frame:ReleaseElements()
        frame:ClearAllPoints()
        frame:Hide()
        frame.type = nil
    end, false,
    function(frame)
        frame.elements = {}
        frame.savedSetting = { spec = nil, index = nil }
        frame.text = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        frame.text:SetPoint('TOPLEFT', frame, 'TOPLEFT')
        frame.type = nil
        frame:SetSize(1, 40)
        frame.SetupText = function(self, index)
            self.optionsContainerIndex = index
            if self.type then
                self.text:SetText(index .. '. ' .. Data.indicatorTypes[self.type].display)
            end
        end
        frame.AnchorElements = function(self)
            for index, element in ipairs(self.elements) do
                element:SetParent(self)
                element:ClearAllPoints()
                local parent
                if index == 1 then
                    parent = self.text
                else
                    parent = self.elements[index - 1]
                end
                element:SetPoint('LEFT', parent, 'RIGHT', 10, 0)
            end
        end
        frame.ReleaseElements = function(self)
            for _, element in ipairs(frame.elements) do
                element:SetParent()
                element:Release()
            end
            wipe(self.elements)
            wipe(self.savedSetting)
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
            local parent = self:GetParent()
            if parent then
                if self.optionsContainerIndex then
                    table.remove(parent.Elements, self.optionsContainerIndex)
                end
                parent:DisplayElements()
            end
            Ui.ContainerFramePool:Release(self)
            local designer = Ui.GetDesignerFrame()
            designer:RefreshPreview()
        end
    end
)

--Color picker pool
Ui.ColorPickerFramePool = CreateFramePool('Button', nil, 'ColorSwatchTemplate',
    function(_, frame)
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
    end, false,
    function(frame)
        frame.type = 'SpellSelector'
        frame:SetWidth(150)
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
        frame:GenerateMenu()
    end, false,
    function(frame)
        frame.type = 'Dropdown'
        frame.dropdownType = nil
        frame:SetWidth(100)
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
            local parent = self:GetParent()
            if parent then
                parent:DeleteOption()
            end
        end)
        frame.Release = function(self)
            Ui.DeleteIndicatorOptionsButtonPool:Release(self)
        end
    end
)

Ui.SliderPool = CreateFramePool('Slider', nil, 'UISliderTemplateWithLabels',
    function(_, frame)
        frame:SetValue(0)
        frame.Text:SetText("")
    end, false,
    function(frame)
        frame.type = 'Slider'
        frame.sliderType = nil
        frame:SetSize(100, 15)
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
        frame.UpdateIndicators = function(self)
            --Handling for UNIT_AURA events
            local aurasData = Data.state.auras[self.unit]
            for _, element in ipairs(self.elements) do
                element:UpdateIndicator(self.unit, aurasData)
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
        frame:ClearAllPoints()
        frame.spell = nil
        frame:Hide()
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
            frame.texture:SetTexture('Interface/Addons/HarreksAdvancedRaidFrames/HarreksAdvancedRaidFrames.tga')
            frame.cooldown:SetCooldown(GetTime(), 30)
            if not frame.previewTimer then
                frame.previewTimer = C_Timer.NewTicker(30, function()
                    frame:ShowPreview()
                end)
            end
            frame:Show()
        end
        frame.UpdateIndicator = function(self, unit, aurasData)
            self:Hide()
            for instanceId, auraName in pairs(aurasData) do
                if auraName == self.spell then
                    --TODO: improve performance, im querying the aura on every single UNIT_AURA
                    local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, instanceId)
                    local duration = C_UnitAuras.GetAuraDuration(unit, instanceId)
                    if auraData and duration then
                        self.texture:SetTexture(auraData.icon)
                        self.cooldown:SetCooldownFromDurationObject(duration)
                        self:Show()
                    end
                end
            end
        end
        frame.Release = function(self)
            if self.previewTimer then self.previewTimer:Cancel() end
            Ui.IconIndicatorPool:Release(self)
        end
    end
)

--Square type indicators
Ui.SquareIndicatorPool = CreateFramePool('Frame', nil, nil,
    function(_, frame)
        frame:ClearAllPoints()
        frame.spell = nil
        frame:Hide()
    end, false,
    function(frame)
        frame.texture = frame:CreateTexture(nil, 'ARTWORK')
        frame.texture:SetAllPoints()
        frame.type = 'SquareIndicator'
        frame.spell = nil
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
        frame:ClearAllPoints()
        frame.spell = nil
        frame:Hide()
    end, false,
    function(frame)
        frame:SetStatusBarTexture("Interface/Buttons/WHITE8x8")
        frame.background = frame:CreateTexture(nil, 'BACKGROUND')
        frame.background:SetAllPoints(frame)
        frame.background:SetColorTexture(0, 0, 0, 1)
        frame.type = 'BarIndicator'
        frame.previewTimer = nil
        frame.spell = nil
        frame.ShowPreview = function(self)
            local duration = C_DurationUtil.CreateDuration()
            duration:SetTimeFromStart(GetTime(), 30)
            self:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
            if not frame.previewTimer then
                frame.previewTimer = C_Timer.NewTicker(30, function()
                    frame:ShowPreview()
                end)
            end
            self:Show()
        end
        frame.Release = function(self)
            if self.previewTimer then self.previewTimer:Cancel() end
            Ui.BarIndicatorPool:Release(self)
        end
    end
)