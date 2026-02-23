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
        frame.cooldownStyle = nil
        frame.cooldownSwipeColor = nil
        frame.shrinkDuration = 0
        frame.shrinkStartTime = 0
        if frame.background then
            frame.background:Hide()
            frame.background:SetColorTexture(0, 0, 0, 0)
        end
        if frame.shrinkTexture then
            frame.shrinkTexture:Hide()
            frame.shrinkTexture:ClearAllPoints()
            frame.shrinkTexture:SetPoint('CENTER', frame, 'CENTER', 0, 0)
            frame.shrinkTexture:SetSize(1, 1)
        end
        if frame.depleteBar then
            frame.depleteBar:Hide()
            frame.depleteBar:SetMinMaxValues(0, 1)
            frame.depleteBar:SetValue(1)
        end
        frame:SetScript('OnUpdate', nil)
    end, false,
    function(frame)
        frame.background = frame:CreateTexture(nil, 'BACKGROUND')
        frame.background:SetAllPoints()
        frame.background:SetColorTexture(0, 0, 0, 0)
        frame.background:Hide()

        frame.texture = frame:CreateTexture(nil, 'ARTWORK')
        frame.texture:SetAllPoints()

        frame.shrinkTexture = frame:CreateTexture(nil, 'ARTWORK')
        frame.shrinkTexture:SetPoint('CENTER', frame, 'CENTER', 0, 0)
        frame.shrinkTexture:SetSize(1, 1)
        frame.shrinkTexture:Hide()

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
        frame.shrinkDuration = 0
        frame.shrinkStartTime = 0
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
        frame.ApplyShrinkDirection = function(self)
            if not self.shrinkTexture then
                return
            end

            local anchor = self.shrinkDirection or 'CENTER'
            self.shrinkTexture:ClearAllPoints()
            self.shrinkTexture:SetPoint(anchor, self, anchor, 0, 0)
        end
        frame.UpdateShrinkFill = function(self)
            if not self.shrinkTexture then
                return
            end

            if self.shrinkDuration <= 0 then
                self.shrinkTexture:SetSize(1, 1)
                return
            end

            local elapsed = GetTime() - self.shrinkStartTime
            local remaining = self.shrinkDuration - elapsed
            if remaining < 0 then
                remaining = 0
            end

            local pct = remaining / self.shrinkDuration
            local width = self:GetWidth() * pct
            local height = self:GetHeight() * pct
            if width < 1 then width = 1 end
            if height < 1 then height = 1 end
            self.shrinkTexture:SetSize(width, height)

            if remaining <= 0 then
                self:SetScript('OnUpdate', nil)
            end
        end
        frame.StartShrinkFromCooldown = function(self)
            local startTimeMs, durationMs = self.cooldown:GetCooldownTimes()
            if not durationMs or durationMs <= 0 then
                self.shrinkDuration = 0
                self.shrinkStartTime = 0
                self.shrinkTexture:SetSize(1, 1)
                self:SetScript('OnUpdate', nil)
                return
            end

            self.shrinkDuration = durationMs / 1000
            self.shrinkStartTime = startTimeMs / 1000
            self:UpdateShrinkFill()
            self:SetScript('OnUpdate', self.UpdateShrinkFill)
        end
        frame.UpdateIndicator = function(self, unit, auraData, auraDurations)
            if self.spell and auraData[self.spell] then
                if self.showCooldown then
                    local aura = auraData[self.spell]
                    local duration = auraDurations and auraDurations[self.spell]
                    if not duration then
                        duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
                    end
                    if self.cooldownStyle == 'Deplete' then
                        self.cooldown:SetDrawSwipe(false)
                        self.cooldown:SetDrawEdge(false)
                        self.cooldown:SetDrawBling(false)
                        self:ApplyDepleteDirection()
                        if duration and self.depleteBar and self.depleteBar.SetTimerDuration then
                            self.depleteBar:SetTimerDuration(
                                duration,
                                Enum.StatusBarInterpolation.Immediate,
                                Enum.StatusBarTimerDirection.RemainingTime
                            )
                            self.depleteBar:Show()
                            if self.showCooldownText then
                                self.cooldown:SetCooldownFromDurationObject(duration)
                                self.cooldown:Show()
                            else
                                self.cooldown:Hide()
                            end
                        else
                            self.depleteBar:Hide()
                            self.cooldown:Hide()
                        end
                        self.shrinkTexture:Hide()
                        self:SetScript('OnUpdate', nil)
                    elseif self.cooldownStyle == 'Shrink' then
                        self.depleteBar:Hide()
                        self.cooldown:SetDrawSwipe(false)
                        self.cooldown:SetDrawEdge(false)
                        self.cooldown:SetDrawBling(false)
                        self:ApplyShrinkDirection()
                        if duration then
                            self.cooldown:SetCooldownFromDurationObject(duration)
                            if self.showCooldownText then
                                self.cooldown:Show()
                            else
                                self.cooldown:Hide()
                            end
                            self.shrinkTexture:Show()
                            self:StartShrinkFromCooldown()
                        else
                            self.cooldown:Hide()
                            self.shrinkTexture:Hide()
                            self:SetScript('OnUpdate', nil)
                        end
                    else
                        self.depleteBar:Hide()
                        self.shrinkTexture:Hide()
                        self:SetScript('OnUpdate', nil)
                        self.cooldown:SetDrawSwipe(true)
                        self.cooldown:SetDrawEdge(false)
                        self.cooldown:SetDrawBling(false)
                        if duration then
                            self.cooldown:SetCooldownFromDurationObject(duration)
                            self:ApplySwipeStyle()
                            self.cooldown:Show()
                        else
                            self.cooldown:Hide()
                        end
                    end
                else
                    self.cooldown:Hide()
                    self.depleteBar:Hide()
                    self.shrinkTexture:Hide()
                    self:SetScript('OnUpdate', nil)
                end
                self:Show()
            else
                self:SetScript('OnUpdate', nil)
                self:Hide()
            end
        end
        frame.ShowPreview = function(self)
            if self.showCooldown then
                if self.cooldownStyle == 'Deplete' then
                    self.cooldown:SetDrawSwipe(false)
                    self.cooldown:SetDrawEdge(false)
                    self.cooldown:SetDrawBling(false)
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
                        if self.showCooldownText then
                            self.cooldown:SetCooldown(GetTime(), 30)
                            self.cooldown:Show()
                        else
                            self.cooldown:Hide()
                        end
                    else
                        self.depleteBar:Hide()
                        self.cooldown:Hide()
                    end
                    self.shrinkTexture:Hide()
                    self:SetScript('OnUpdate', nil)
                elseif self.cooldownStyle == 'Shrink' then
                    self.depleteBar:Hide()
                    self.cooldown:SetDrawSwipe(false)
                    self.cooldown:SetDrawEdge(false)
                    self.cooldown:SetDrawBling(false)
                    self:ApplyShrinkDirection()
                    self.cooldown:SetCooldown(GetTime(), 30)
                    if self.showCooldownText then
                        self.cooldown:Show()
                    else
                        self.cooldown:Hide()
                    end
                    self.shrinkTexture:Show()
                    self:StartShrinkFromCooldown()
                else
                    self.depleteBar:Hide()
                    self.shrinkTexture:Hide()
                    self:SetScript('OnUpdate', nil)
                    self.cooldown:SetDrawSwipe(true)
                    self.cooldown:SetDrawEdge(false)
                    self.cooldown:SetDrawBling(false)
                    self.cooldown:SetCooldown(GetTime(), 30)
                    self:ApplySwipeStyle()
                    self.cooldown:Show()
                end
            else
                self.cooldown:Hide()
                self.depleteBar:Hide()
                self.shrinkTexture:Hide()
                self:SetScript('OnUpdate', nil)
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
        frame:SetReverseFill(false)
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
        frame.borderAnimDuration = 0
        frame.borderAnimStartTime = 0
        frame.borderCooldownDirection = nil
        frame.borderCooldownStartCorner = nil
        if frame.cooldown then
            frame.cooldown:Hide()
            frame.cooldown:Clear()
        end
        if frame.topBorder then frame.topBorder:Hide() end
        if frame.rightBorder then frame.rightBorder:Hide() end
        if frame.bottomBorder then frame.bottomBorder:Hide() end
        if frame.leftBorder then frame.leftBorder:Hide() end
        frame:SetScript('OnUpdate', nil)
    end, false,
    function(frame)
        frame.spell = nil
        frame.color = nil
        frame.type = 'HealthColor'
        frame.showCooldown = false
        frame.borderAnimDuration = 0
        frame.borderAnimStartTime = 0
        frame.borderCooldownDirection = 'Clockwise'
        frame.borderCooldownStartCorner = 'TOPRIGHT'
        frame.borderThickness = 3
        frame:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 3,
            bgFile = "Interface\\Buttons\\WHITE8X8",
            tile = true, tileSize = 16,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        frame:SetBackdropColor(0, 0, 0, 0)
        frame:Hide()

        frame.topBorder = frame:CreateTexture(nil, 'ARTWORK')
        frame.rightBorder = frame:CreateTexture(nil, 'ARTWORK')
        frame.bottomBorder = frame:CreateTexture(nil, 'ARTWORK')
        frame.leftBorder = frame:CreateTexture(nil, 'ARTWORK')

        frame.cooldown = CreateFrame('Cooldown', nil, frame, 'CooldownFrameTemplate')
        frame.cooldown:SetAllPoints()
        frame.cooldown:SetHideCountdownNumbers(true)
        frame.cooldown:Hide()

        frame.ApplyBorderThickness = function(self)
            local thickness = self.borderThickness or 3
            self:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = thickness,
                bgFile = "Interface\\Buttons\\WHITE8X8",
                tile = true, tileSize = 16,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            self:SetBackdropColor(0, 0, 0, 0)
        end

        frame.ApplyBorderColor = function(self)
            if not self.color then
                return
            end

            self.topBorder:SetColorTexture(self.color.r, self.color.g, self.color.b, self.color.a)
            self.rightBorder:SetColorTexture(self.color.r, self.color.g, self.color.b, self.color.a)
            self.bottomBorder:SetColorTexture(self.color.r, self.color.g, self.color.b, self.color.a)
            self.leftBorder:SetColorTexture(self.color.r, self.color.g, self.color.b, self.color.a)
        end

        frame.HideAnimatedBorder = function(self)
            self.topBorder:Hide()
            self.rightBorder:Hide()
            self.bottomBorder:Hide()
            self.leftBorder:Hide()
        end

        frame.GetBorderSegments = function(self)
            local isClockwise = (self.borderCooldownDirection or 'Clockwise') == 'Clockwise'
            local corner = self.borderCooldownStartCorner or 'TOPRIGHT'

            if isClockwise then
                if corner == 'TOPLEFT' then
                    return {
                        { side = 'left', from = 'top' },
                        { side = 'bottom', from = 'left' },
                        { side = 'right', from = 'bottom' },
                        { side = 'top', from = 'right' },
                    }
                elseif corner == 'BOTTOMLEFT' then
                    return {
                        { side = 'bottom', from = 'left' },
                        { side = 'right', from = 'bottom' },
                        { side = 'top', from = 'right' },
                        { side = 'left', from = 'top' },
                    }
                elseif corner == 'BOTTOMRIGHT' then
                    return {
                        { side = 'right', from = 'bottom' },
                        { side = 'top', from = 'right' },
                        { side = 'left', from = 'top' },
                        { side = 'bottom', from = 'left' },
                    }
                end

                return {
                    { side = 'top', from = 'right' },
                    { side = 'left', from = 'top' },
                    { side = 'bottom', from = 'left' },
                    { side = 'right', from = 'bottom' },
                }
            end

            if corner == 'TOPLEFT' then
                return {
                    { side = 'top', from = 'left' },
                    { side = 'right', from = 'top' },
                    { side = 'bottom', from = 'right' },
                    { side = 'left', from = 'bottom' },
                }
            elseif corner == 'BOTTOMLEFT' then
                return {
                    { side = 'left', from = 'bottom' },
                    { side = 'top', from = 'left' },
                    { side = 'right', from = 'top' },
                    { side = 'bottom', from = 'right' },
                }
            elseif corner == 'BOTTOMRIGHT' then
                return {
                    { side = 'bottom', from = 'right' },
                    { side = 'left', from = 'bottom' },
                    { side = 'top', from = 'left' },
                    { side = 'right', from = 'top' },
                }
            end

            return {
                { side = 'right', from = 'top' },
                { side = 'bottom', from = 'right' },
                { side = 'left', from = 'bottom' },
                { side = 'top', from = 'left' },
            }
        end

        frame.SetSegmentFill = function(self, side, from, fillLength)
            local thickness = self.borderThickness or 3
            local width = self:GetWidth()
            local height = self:GetHeight()
            if width <= 0 or height <= 0 then
                return
            end

            local texture
            local maxLength
            if side == 'top' then
                texture = self.topBorder
                maxLength = width
            elseif side == 'bottom' then
                texture = self.bottomBorder
                maxLength = width
            elseif side == 'left' then
                texture = self.leftBorder
                maxLength = height
            else
                texture = self.rightBorder
                maxLength = height
            end

            if fillLength <= 0 then
                texture:Hide()
                return
            end

            if fillLength > maxLength then
                fillLength = maxLength
            end

            texture:ClearAllPoints()
            if side == 'top' then
                texture:SetHeight(thickness)
                texture:SetWidth(fillLength)
                if from == 'left' then
                    texture:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, 0)
                else
                    texture:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, 0)
                end
            elseif side == 'bottom' then
                texture:SetHeight(thickness)
                texture:SetWidth(fillLength)
                if from == 'left' then
                    texture:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 0, 0)
                else
                    texture:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 0, 0)
                end
            elseif side == 'left' then
                texture:SetWidth(thickness)
                texture:SetHeight(fillLength)
                if from == 'top' then
                    texture:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, 0)
                else
                    texture:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', 0, 0)
                end
            else
                texture:SetWidth(thickness)
                texture:SetHeight(fillLength)
                if from == 'top' then
                    texture:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 0, 0)
                else
                    texture:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', 0, 0)
                end
            end
            texture:Show()
        end

        frame.DrawAnimatedBorder = function(self, remainingPct)
            local width = self:GetWidth()
            local height = self:GetHeight()
            if width <= 0 or height <= 0 then
                self:HideAnimatedBorder()
                return
            end

            if remainingPct < 0 then remainingPct = 0 end
            if remainingPct > 1 then remainingPct = 1 end

            local remainingLength = (2 * (width + height)) * remainingPct
            local segments = self:GetBorderSegments()

            for _, segment in ipairs(segments) do
                local sideLength = (segment.side == 'top' or segment.side == 'bottom') and width or height
                local fill = remainingLength
                if fill > sideLength then
                    fill = sideLength
                end

                self:SetSegmentFill(segment.side, segment.from, fill)
                remainingLength = remainingLength - sideLength
            end
        end

        frame.UpdateBorderAnimation = function(self)
            if self.borderAnimDuration <= 0 then
                self:HideAnimatedBorder()
                self:SetScript('OnUpdate', nil)
                return
            end

            local elapsed = GetTime() - self.borderAnimStartTime
            local remaining = self.borderAnimDuration - elapsed
            if remaining < 0 then
                remaining = 0
            end

            self:DrawAnimatedBorder(remaining / self.borderAnimDuration)
            if remaining <= 0 then
                self:SetScript('OnUpdate', nil)
            end
        end

        frame.StartBorderAnimationFromCooldown = function(self)
            local startTimeMs, durationMs = self.cooldown:GetCooldownTimes()
            if not durationMs or durationMs <= 0 then
                self.borderAnimDuration = 0
                self.borderAnimStartTime = 0
                self:HideAnimatedBorder()
                self:SetScript('OnUpdate', nil)
                return
            end

            self.borderAnimDuration = durationMs / 1000
            self.borderAnimStartTime = startTimeMs / 1000
            self:UpdateBorderAnimation()
            self:SetScript('OnUpdate', self.UpdateBorderAnimation)
        end

        frame.DefaultCallback = function(self, shouldBeColored)
            if shouldBeColored then
                self:Show()
                self:SetBackdropBorderColor(self.color.r, self.color.g, self.color.b)
            else
                self:Hide()
            end
        end

        frame.UpdateIndicator = function(self, unit, auraData, auraDurations)
            local unitList = Util.GetRelevantList()
            local elements = unitList[unit]
            if not elements then
                return
            end

            local shouldBeColored = false
            local hasAnimatedBorder = false
            if self.spell and auraData[self.spell] then
                local aura = auraData[self.spell]
                local duration = auraDurations and auraDurations[self.spell]
                if not duration then
                    duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
                end

                elements.isColored = false
                elements.recolor = nil
                shouldBeColored = true

                self:ApplyBorderColor()
                if duration and self.showCooldown then
                    hasAnimatedBorder = true
                    self.cooldown:SetCooldownFromDurationObject(duration)
                    self.cooldown:Hide()
                    self:StartBorderAnimationFromCooldown()
                else
                    self:SetScript('OnUpdate', nil)
                    self:HideAnimatedBorder()
                    self.cooldown:Hide()
                end
            else
                elements.isColored = false
                elements.recolor = nil
                self:SetScript('OnUpdate', nil)
                self:HideAnimatedBorder()
                self.cooldown:Hide()
            end

            self:DefaultCallback(shouldBeColored)
            if shouldBeColored then
                if hasAnimatedBorder then
                    self:SetBackdropBorderColor(self.color.r, self.color.g, self.color.b, 0)
                else
                    self:SetBackdropBorderColor(self.color.r, self.color.g, self.color.b, self.color.a)
                end
            end
        end

        frame.ShowPreview = function(self)
            self:ApplyBorderColor()
            if self.showCooldown then
                self:SetBackdropBorderColor(self.color.r, self.color.g, self.color.b, 0)
                self.cooldown:SetCooldown(GetTime(), 30)
                self.cooldown:Hide()
                self:StartBorderAnimationFromCooldown()
            else
                self:SetScript('OnUpdate', nil)
                self:HideAnimatedBorder()
                self:SetBackdropBorderColor(self.color.r, self.color.g, self.color.b, self.color.a)
                self.cooldown:Hide()
            end
            self:Show()
        end

        frame.Release = function(self)
            Ui.HealthColorIndicatorPool:Release(self)
        end
    end
)