local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local API = NS.API
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

local indicatorControlReaders = {
    ColorPicker = function(control)
        local r, g, b, a = control.Color:GetVertexColor()
        return { r = r, g = g, b = b, a = a }
    end,
    Dropdown = function(control)
        return control.selectedOption
    end,
    Slider = function(control)
        return control:GetValue()
    end,
    SpellSelector = function(control)
        return control.selectedOption
    end,
    Checkbox = function(control)
        return control:GetChecked()
    end
}

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
        frame.AnchorElements = function(self)
            local rowAnchors = {}
            for index, element in ipairs(self.elements) do
                element:ClearAllPoints()
                element:SetParent(self)
                local parent, point, rel, xOff, yOff
                local currentRow = element.layoutRow or 1
                if not rowAnchors[currentRow] then
                    parent = self
                    if currentRow == 1 then
                        point = 'LEFT'
                        rel = 'LEFT'
                        xOff = 13
                        yOff = 10
                    else
                        point = 'BOTTOMLEFT'
                        rel = 'BOTTOMLEFT'
                        xOff = 13
                        yOff = 20 - ((currentRow - 2) * 30)
                    end
                    rowAnchors[currentRow] = element
                else
                    parent = rowAnchors[currentRow]
                    point = 'LEFT'
                    rel = 'RIGHT'
                    xOff = 10
                    yOff = 0
                    if self.type == 'icon' and rowAnchors[currentRow].type == 'SpellSelector' and element.type == 'Dropdown' then
                        xOff = 35
                    elseif rowAnchors[currentRow].type == 'Checkbox' then
                        xOff = 60
                        if self.type == 'square' and element.indicatorSetting == 'showText' then
                            xOff = 95
                        end
                    end
                    rowAnchors[currentRow] = element
                end

                element:SetPoint(point, parent, rel, xOff, yOff)
                element:Show()
            end

            self:UpdateDependentControlStates()

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

        frame.UpdateDependentControlStates = function(self)
            if self.type ~= 'square' then
                return
            end

            local showCooldownControl = nil
            local showTextControl = nil
            for _, control in ipairs(self.elements) do
                if control.type == 'Checkbox' then
                    if control.indicatorSetting == 'showCooldown' then
                        showCooldownControl = control
                    elseif control.indicatorSetting == 'showText' then
                        showTextControl = control
                    end
                end
            end

            if showCooldownControl and showTextControl then
                if showCooldownControl:GetChecked() then
                    showTextControl:Enable()
                    showTextControl:SetAlpha(1)
                    if showTextControl.Text then
                        showTextControl.Text:SetTextColor(1, 0.82, 0)
                    end
                else
                    showTextControl:SetChecked(false)
                    showTextControl:Disable()
                    showTextControl:SetAlpha(0.55)
                    if showTextControl.Text then
                        showTextControl.Text:SetTextColor(0.5, 0.5, 0.5)
                    end
                end
            end
        end

        --We update the saved data on the container when the children change
        frame.UpdateOptionsData = function(self)
            self:UpdateDependentControlStates()
            local savedSetting = self.savedSetting
            if savedSetting.spec and savedSetting.index and SavedIndicators[savedSetting.spec][savedSetting.index] then
                local dataTable = SavedIndicators[savedSetting.spec][savedSetting.index]
                wipe(dataTable)
                dataTable.Type = self.type
                local typeData = Data.indicatorTypeSettings[self.type]
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
                        local reader = indicatorControlReaders[control.type]
                        if reader then
                            dataTable[settingKey] = reader(control)
                        end
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

--Color picker pool
Ui.ColorPickerFramePool = CreateFramePool('Button', nil, 'ColorSwatchTemplate',
    function(_, frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent()
        frame.indicatorSetting = nil
        frame.layoutRow = nil
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
        frame.indicatorSetting = nil
        frame.layoutRow = nil
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
        frame.indicatorSetting = nil
        frame.layoutRow = nil
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
        frame.indicatorSetting = nil
        frame.layoutRow = nil
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
            self.Current:SetText(Util.FormatForDisplay(value))
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

Ui.CheckboxPool = CreateFramePool('CheckButton', nil, 'InterfaceOptionsCheckButtonTemplate',
    function(_, frame)
        frame:Hide()
        frame:ClearAllPoints()
        frame:SetParent()
        frame.setting = nil
        frame.indicatorSetting = nil
        frame.layoutRow = nil
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
        frame.UpdateIndicators = function(self, auraData, auraDurations)
            for _, element in ipairs(self.elements) do
                element:UpdateIndicator(self.unit, auraData, auraDurations)
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
            if unitFrame.GetFrameStrata and unitFrame.GetFrameLevel then
                local parentStrata = unitFrame:GetFrameStrata()
                local parentLevel = unitFrame:GetFrameLevel()
                if parentStrata then self:SetFrameStrata(parentStrata) end
                if parentLevel then self:SetFrameLevel(parentLevel + 5) end
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
        frame.UpdateIndicator = function(self, unit, auraData, auraDurations)
            if self.spell and auraData[self.spell] then
                local aura = auraData[self.spell]
                local duration = auraDurations and auraDurations[self.spell]
                if not duration then
                    duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
                end
                self.texture:SetTexture(aura.icon)
                if duration then
                    self.cooldown:SetCooldownFromDurationObject(duration)
                end
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
        frame.cooldown = CreateFrame('Cooldown', nil, frame, 'CooldownFrameTemplate')
        frame.cooldown:SetAllPoints()
        frame.cooldown:SetReverse(true)
        frame.cooldown:Hide()
        frame.type = 'SquareIndicator'
        frame.spell = nil
        frame.UpdateIndicator = function(self, unit, auraData, auraDurations)
            if self.spell and auraData[self.spell] then
                if self.showCooldown then
                    local aura = auraData[self.spell]
                    local duration = auraDurations and auraDurations[self.spell]
                    if not duration then
                        duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
                    end
                    if duration then
                        self.cooldown:SetCooldownFromDurationObject(duration)
                        self.cooldown:Show()
                    else
                        self.cooldown:Hide()
                    end
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
        frame.UpdateIndicator = function(self, unit, auraData, auraDurations)
            if self.spell and auraData[self.spell] then
                local aura = auraData[self.spell]
                local duration = auraDurations and auraDurations[self.spell]
                if not duration then
                    duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
                end
                if duration then
                    self:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
                end
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

Ui.HealthColorIndicatorPool = CreateFramePool('Frame', nil, 'BackdropTemplate',
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
        frame.type = 'HealthColor'
        frame:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 3,
            bgFile = "Interface\\Buttons\\WHITE8X8",
            tile = true, tileSize = 16,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        frame:SetBackdropColor(0, 0, 0, 0)
        frame:Hide()
        frame.DefaultCallback = function(self, frameToRecolor, shouldBeColored)
            if frameToRecolor and frameToRecolor.healthBar then
                if shouldBeColored then
                    --frameToRecolor.healthBar.barTexture:SetVertexColor(self.color.r, self.color.g, self.color.b)
                    self:Show()
                    self:SetBackdropBorderColor(self.color.r, self.color.g, self.color.b)
                else
                    self:Hide()
                    --CompactUnitFrame_UpdateHealthColor(frameToRecolor)
                end
            end
        end
        frame.UpdateIndicator = function(self, unit, auraData)
            local overlay = self:GetParent()
            local unitList = Util.GetRelevantList()
            local elements = unitList[unit]
            if elements then
                --Util.DumpData(elements)
                local shouldBeColored = false
                if self.spell and auraData[self.spell] then
                    elements.isColored = true
                    elements.recolor = self.color
                    shouldBeColored = true
                else
                    elements.isColored = false
                    elements.recolor = nil
                end
                local coloringFunc = overlay.coloringFunc
                if coloringFunc and type(coloringFunc) == 'function' and elements.extraFrames and elements.extraFrames[overlay.extraFrameIndex] then
                    local unitFrame = elements.extraFrames[overlay.extraFrameIndex].frame
                    coloringFunc(unitFrame, shouldBeColored, self.color)
                else
                    local unitFrame = _G[elements.frame]
                    self:DefaultCallback(unitFrame, shouldBeColored)
                end
            end
        end
        frame.ShowPreview = function(self)
            self:SetBackdropBorderColor(self.color.r, self.color.g, self.color.b)
            self:Show()
        end
        frame.Release = function(self)
            Ui.HealthColorIndicatorPool:Release(self)
        end
    end
)