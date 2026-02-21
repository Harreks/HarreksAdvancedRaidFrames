local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util

-- Legacy pre-EQOL designer pools removed.

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
        frame.UpdateIndicators = function(self, auraData)
            for _, element in ipairs(self.elements) do
                element:UpdateIndicator(self.unit, auraData)
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
        frame.cooldownSwipeColor = nil
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
        frame.cooldownStyle = nil
        frame.cooldownSwipeColor = nil
        if frame.background then
            frame.background:Hide()
            frame.background:SetColorTexture(0, 0, 0, 0)
        end
        if frame.depleteBar then
            frame.depleteBar:Hide()
            frame.depleteBar:SetMinMaxValues(0, 1)
            frame.depleteBar:SetValue(1)
        end
    end, false,
    function(frame)
        frame.background = frame:CreateTexture(nil, 'BACKGROUND')
        frame.background:SetAllPoints()
        frame.background:SetColorTexture(0, 0, 0, 0)
        frame.background:Hide()
        frame.texture = frame:CreateTexture(nil, 'ARTWORK')
        frame.texture:SetAllPoints()

        frame.depleteBar = CreateFrame('StatusBar', nil, frame)
        frame.depleteBar:SetAllPoints()
        frame.depleteBar:SetStatusBarTexture('Interface\\Buttons\\WHITE8x8')
        frame.depleteBar:SetMinMaxValues(0, 1)
        frame.depleteBar:SetValue(1)
        frame.depleteBar:Hide()

        frame.cooldown = CreateFrame('Cooldown', nil, frame, 'CooldownFrameTemplate')
        frame.cooldown:SetAllPoints()
        frame.cooldown:SetReverse(true)
        frame.cooldown:Hide()
        frame.type = 'SquareIndicator'
        frame.spell = nil
        frame.ApplySwipeStyle = function(self)
            if not self.cooldownSwipeColor then
                return
            end

            local c = self.cooldownSwipeColor
            if self.cooldown.SetSwipeTexture then
                self.cooldown:SetSwipeTexture('Interface\\Buttons\\WHITE8x8', c.r, c.g, c.b, c.a)
            end
            if self.cooldown.SetSwipeColor then
                self.cooldown:SetSwipeColor(c.r, c.g, c.b, c.a)
            end
        end
        frame.ApplyDepleteDirection = function(self)
            local direction = self.depleteDirection or 'Right to Left'
            if not self.depleteBar then
                return
            end

            if direction == 'Left to Right' then
                self.depleteBar:SetOrientation('HORIZONTAL')
                self.depleteBar:SetReverseFill(true)
            elseif direction == 'Top to Bottom' then
                self.depleteBar:SetOrientation('VERTICAL')
                self.depleteBar:SetReverseFill(false)
            elseif direction == 'Bottom to Top' then
                self.depleteBar:SetOrientation('VERTICAL')
                self.depleteBar:SetReverseFill(true)
            else
                self.depleteBar:SetOrientation('HORIZONTAL')
                self.depleteBar:SetReverseFill(false)
            end
        end
        frame.UpdateIndicator = function(self, unit, auraData)
            if self.spell and auraData[self.spell] then
                if self.showCooldown then
                    local aura = auraData[self.spell]
                    local duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
                    if self.cooldownStyle == 'Deplete' then
                        self.cooldown:Hide()
                        self:ApplyDepleteDirection()
                        if duration and self.depleteBar and self.depleteBar.SetTimerDuration then
                            self.depleteBar:SetTimerDuration(
                                duration,
                                Enum.StatusBarInterpolation.Immediate,
                                Enum.StatusBarTimerDirection.RemainingTime
                            )
                            self.depleteBar:Show()
                        else
                            self.depleteBar:Hide()
                        end
                    else
                        self.depleteBar:Hide()
                        self:ApplySwipeStyle()
                        if duration then
                            self.cooldown:SetCooldownFromDurationObject(duration)
                            self:ApplySwipeStyle()
                            self.cooldown:Show()
                        end
                    end
                else
                    self.cooldown:Hide()
                    self.depleteBar:Hide()
                end
                self:Show()
            else
                self:Hide()
            end
        end
        frame.ShowPreview = function(self)
            if self.showCooldown then
                if self.cooldownStyle == 'Deplete' then
                    self.cooldown:Hide()
                    self:ApplyDepleteDirection()
                    if self.depleteBar and self.depleteBar.SetTimerDuration then
                        local duration = C_DurationUtil.CreateDuration()
                        duration:SetTimeFromStart(GetTime(), 30)
                        self.depleteBar:SetTimerDuration(
                            duration,
                            Enum.StatusBarInterpolation.Immediate,
                            Enum.StatusBarTimerDirection.RemainingTime
                        )
                        self.depleteBar:Show()
                    else
                        self.depleteBar:Hide()
                    end
                else
                    self.depleteBar:Hide()
                    self:ApplySwipeStyle()
                    self.cooldown:SetCooldown(GetTime(), 30)
                    self:ApplySwipeStyle()
                    self.cooldown:Show()
                end
            else
                self.cooldown:Hide()
                self.depleteBar:Hide()
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