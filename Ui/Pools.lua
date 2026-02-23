local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util

local function clearOnUpdate(frame)
    if frame and frame.SetScript then
        frame:SetScript('OnUpdate', nil)
    end
end

local function cancelFrameTicker(frame, tickerKey)
    if not frame then
        return
    end

    local ticker = frame[tickerKey]
    if ticker then
        ticker:Cancel()
        frame[tickerKey] = nil
    end
end

local function hideFrameRegions(frame, regionKeys)
    if not frame then
        return
    end

    for _, key in ipairs(regionKeys) do
        local region = frame[key]
        if region and region.Hide then
            region:Hide()
        end
    end
end

local function hideBarSpark(frame)
    hideFrameRegions(frame, { 'spark', 'sparkGlow' })
end

-- Legacy pre-EQOL designer pools removed.

-- All indicators are created inside a container, then anchored to the frame to show indicators on top of it.
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

            local overlayLevel = self:GetFrameLevel() or 0
            for _, element in ipairs(self.elements) do
                if element and element.SetFrameLevel then
                    local offset = element.layerPriorityOffset or 0
                    element:SetFrameLevel(overlayLevel + offset)
                end
            end
        end
        frame.Delete = function(self)
            Ui.IndicatorOverlayPool:Release(self)
        end
    end
)

-- This is the default icon indicator that shows on frames.
Ui.IconIndicatorPool = CreateFramePool('Frame', nil, nil,
    function(_, frame)
        frame:Hide()
        frame:SetScale(1)
        frame:ClearAllPoints()
        frame:SetParent()
        frame.spell = nil
        frame.cooldownSwipeColor = nil
        cancelFrameTicker(frame, 'previewTimer')
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
            cancelFrameTicker(self, 'previewTimer')
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
        cancelFrameTicker(frame, 'previewTimer')
        clearOnUpdate(frame)
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
                        self:SetScript('OnUpdate', nil)
                    else
                        self.depleteBar:Hide()
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
                    self:SetScript('OnUpdate', nil)
                else
                    self.depleteBar:Hide()
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
            cancelFrameTicker(self, 'previewTimer')
            clearOnUpdate(self)
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
        frame.showSpark = false
        hideBarSpark(frame)
        clearOnUpdate(frame)
        cancelFrameTicker(frame, 'previewTimer')
    end, false,
    function(frame)
        frame:SetStatusBarTexture("Interface/Buttons/WHITE8x8")
        frame.background = frame:CreateTexture(nil, 'BACKGROUND')
        frame.background:SetAllPoints(frame)
        frame.background:SetColorTexture(0, 0, 0, 1)
        frame.spark = frame:CreateTexture(nil, 'OVERLAY')
        frame.spark:SetTexture('Interface\\CastingBar\\UI-CastingBar-Spark')
        frame.spark:SetBlendMode('ADD')
        frame.spark:Hide()
        frame.sparkGlow = frame:CreateTexture(nil, 'OVERLAY')
        frame.sparkGlow:SetTexture('Interface\\CastingBar\\UI-CastingBar-Spark')
        frame.sparkGlow:SetBlendMode('ADD')
        frame.sparkGlow:SetVertexColor(1, 1, 1, 0.35)
        frame.sparkGlow:Hide()
        frame.type = 'BarIndicator'
        frame.previewTimer = nil
        frame.spell = nil
        frame.showSpark = false
        frame.UpdateSpark = function(self)
            if not self.showSpark then
                if self.spark then self.spark:Hide() end
                if self.sparkGlow then self.sparkGlow:Hide() end
                return
            end

            local barTexture = self:GetStatusBarTexture()
            if not barTexture or not barTexture:IsShown() then
                self.spark:Hide()
                self.sparkGlow:Hide()
                return
            end

            local orientation = self:GetOrientation()
            local reverseFill = self:GetReverseFill()
            local width = self:GetWidth()
            local height = self:GetHeight()
            local sparkLength = 18
            self.spark:ClearAllPoints()
            self.sparkGlow:ClearAllPoints()

            if orientation == 'VERTICAL' then
                self.spark:SetSize(width, sparkLength)
                self.sparkGlow:SetSize(width, sparkLength)
                if reverseFill then
                    self.spark:SetPoint('CENTER', barTexture, 'BOTTOM', 0, 0)
                    self.sparkGlow:SetPoint('CENTER', barTexture, 'BOTTOM', 0, 0)
                else
                    self.spark:SetPoint('CENTER', barTexture, 'TOP', 0, 0)
                    self.sparkGlow:SetPoint('CENTER', barTexture, 'TOP', 0, 0)
                end
            else
                self.spark:SetSize(sparkLength, height)
                self.sparkGlow:SetSize(sparkLength, height)
                if reverseFill then
                    self.spark:SetPoint('CENTER', barTexture, 'LEFT', 0, 0)
                    self.sparkGlow:SetPoint('CENTER', barTexture, 'LEFT', 0, 0)
                else
                    self.spark:SetPoint('CENTER', barTexture, 'RIGHT', 0, 0)
                    self.sparkGlow:SetPoint('CENTER', barTexture, 'RIGHT', 0, 0)
                end
            end

            self.spark:SetVertexColor(1, 1, 1, 1)
            self.spark:Show()
            self.sparkGlow:Show()
        end
        frame.UpdateIndicator = function(self, unit, auraData, auraDurations)
            if self.spell and auraData[self.spell] then
                local aura = auraData[self.spell]
                local duration = auraDurations and auraDurations[self.spell]
                if not duration then
                    duration = C_UnitAuras.GetAuraDuration(unit, aura.auraInstanceID)
                end
                if duration then
                    self:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
                    if self.showSpark then
                        self:SetScript('OnUpdate', self.UpdateSpark)
                        self:UpdateSpark()
                    else
                        self:SetScript('OnUpdate', nil)
                        self.spark:Hide()
                        self.sparkGlow:Hide()
                    end
                else
                    self:SetScript('OnUpdate', nil)
                    self.spark:Hide()
                    self.sparkGlow:Hide()
                end
                self:Show()
            else
                self:SetScript('OnUpdate', nil)
                self.spark:Hide()
                self.sparkGlow:Hide()
                self:Hide()
            end
        end
        frame.ShowPreview = function(self)
            local duration = C_DurationUtil.CreateDuration()
            duration:SetTimeFromStart(GetTime(), 30)
            self:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
            if self.showSpark then
                self:SetScript('OnUpdate', self.UpdateSpark)
                self:UpdateSpark()
            else
                self:SetScript('OnUpdate', nil)
                self.spark:Hide()
                self.sparkGlow:Hide()
            end
            if not self.previewTimer then
                self.previewTimer = C_Timer.NewTicker(30, function()
                    local duration = C_DurationUtil.CreateDuration()
                    duration:SetTimeFromStart(GetTime(), 30)
                    self:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
                    if self.showSpark then
                        self:UpdateSpark()
                    end
                end)
            end
            self:Show()
        end
        frame.Release = function(self)
            cancelFrameTicker(self, 'previewTimer')
            clearOnUpdate(self)
            hideBarSpark(self)
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
        cancelFrameTicker(frame, 'previewTimer')
        hideFrameRegions(frame, {
            'topEdge',
            'rightEdge',
            'bottomEdge',
            'leftEdge',
            'topClip',
            'rightClip',
            'bottomClip',
            'leftClip',
        })
        clearOnUpdate(frame)
    end, false,
    function(frame)
        frame.spell = nil
        frame.color = nil
        frame.type = 'HealthColor'
        frame.showCooldown = false
        frame.borderCooldownDirection = 'Clockwise'
        frame.borderCooldownStartCorner = 'TOPRIGHT'
        frame.borderPlacement = 'Inset'
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

        frame.topClip = CreateFrame('Frame', nil, frame)
        frame.topClip:SetClipsChildren(true)
        frame.rightClip = CreateFrame('Frame', nil, frame)
        frame.rightClip:SetClipsChildren(true)
        frame.bottomClip = CreateFrame('Frame', nil, frame)
        frame.bottomClip:SetClipsChildren(true)
        frame.leftClip = CreateFrame('Frame', nil, frame)
        frame.leftClip:SetClipsChildren(true)

        frame.topEdge = CreateFrame('StatusBar', nil, frame.topClip)
        frame.rightEdge = CreateFrame('StatusBar', nil, frame.rightClip)
        frame.bottomEdge = CreateFrame('StatusBar', nil, frame.bottomClip)
        frame.leftEdge = CreateFrame('StatusBar', nil, frame.leftClip)

        local function SetupEdgeBar(bar)
            bar:SetStatusBarTexture('Interface/Buttons/WHITE8x8')
            bar:SetMinMaxValues(0, 1)
            bar:SetValue(1)
            bar:Hide()
        end

        SetupEdgeBar(frame.topEdge)
        SetupEdgeBar(frame.rightEdge)
        SetupEdgeBar(frame.bottomEdge)
        SetupEdgeBar(frame.leftEdge)

        frame.GetSequentialSpec = function(self)
            local direction = self.borderCooldownDirection or 'Clockwise'
            local corner = self.borderCooldownStartCorner or 'TOPRIGHT'

            if direction == 'Anti-Clockwise' then
                if corner == 'TOPLEFT' then
                    return {
                        { side = 'left', reverse = false },
                        { side = 'bottom', reverse = true },
                        { side = 'right', reverse = true },
                        { side = 'top', reverse = false },
                    }
                elseif corner == 'BOTTOMLEFT' then
                    return {
                        { side = 'bottom', reverse = true },
                        { side = 'right', reverse = true },
                        { side = 'top', reverse = false },
                        { side = 'left', reverse = false },
                    }
                elseif corner == 'BOTTOMRIGHT' then
                    return {
                        { side = 'right', reverse = true },
                        { side = 'top', reverse = false },
                        { side = 'left', reverse = false },
                        { side = 'bottom', reverse = true },
                    }
                end

                return {
                    { side = 'top', reverse = false },
                    { side = 'left', reverse = false },
                    { side = 'bottom', reverse = true },
                    { side = 'right', reverse = true },
                }
            end

            if corner == 'TOPLEFT' then
                return {
                    { side = 'top', reverse = true },
                    { side = 'right', reverse = false },
                    { side = 'bottom', reverse = false },
                    { side = 'left', reverse = true },
                }
            elseif corner == 'BOTTOMLEFT' then
                return {
                    { side = 'left', reverse = true },
                    { side = 'top', reverse = true },
                    { side = 'right', reverse = false },
                    { side = 'bottom', reverse = false },
                }
            elseif corner == 'BOTTOMRIGHT' then
                return {
                    { side = 'bottom', reverse = false },
                    { side = 'left', reverse = true },
                    { side = 'top', reverse = true },
                    { side = 'right', reverse = false },
                }
            end

            return {
                { side = 'right', reverse = false },
                { side = 'bottom', reverse = false },
                { side = 'left', reverse = true },
                { side = 'top', reverse = true },
            }
        end

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

            local isOutset = (self.borderPlacement or 'Inset') == 'Outset'
            local insetOffset = isOutset and math.floor(thickness / 2) or 0
            local edgeOffset = isOutset and math.floor((thickness + 1) / 2) or 0

            self.topClip:ClearAllPoints()
            self.topClip:SetPoint('TOPLEFT', self, 'TOPLEFT', -insetOffset, edgeOffset)
            self.topClip:SetPoint('TOPRIGHT', self, 'TOPRIGHT', insetOffset, edgeOffset)
            self.topClip:SetHeight(thickness)
            self.topClip:Show()

            self.rightClip:ClearAllPoints()
            self.rightClip:SetPoint('TOPRIGHT', self, 'TOPRIGHT', edgeOffset, insetOffset)
            self.rightClip:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', edgeOffset, -insetOffset)
            self.rightClip:SetWidth(thickness)
            self.rightClip:Show()

            self.bottomClip:ClearAllPoints()
            self.bottomClip:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', -insetOffset, -edgeOffset)
            self.bottomClip:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', insetOffset, -edgeOffset)
            self.bottomClip:SetHeight(thickness)
            self.bottomClip:Show()

            self.leftClip:ClearAllPoints()
            self.leftClip:SetPoint('TOPLEFT', self, 'TOPLEFT', -edgeOffset, insetOffset)
            self.leftClip:SetPoint('BOTTOMLEFT', self, 'BOTTOMLEFT', -edgeOffset, -insetOffset)
            self.leftClip:SetWidth(thickness)
            self.leftClip:Show()

            local horizontalLength = self.topClip:GetWidth()
            local verticalLength = self.leftClip:GetHeight()
            if horizontalLength <= 0 then
                horizontalLength = self:GetWidth()
            end
            if verticalLength <= 0 then
                verticalLength = self:GetHeight()
            end
            if horizontalLength <= 0 then
                horizontalLength = 1
            end
            if verticalLength <= 0 then
                verticalLength = 1
            end

            local perimeterLength = (2 * horizontalLength) + (2 * verticalLength)
            if perimeterLength <= 0 then
                perimeterLength = 1
            end

            local sideLength = {
                top = horizontalLength,
                right = verticalLength,
                bottom = horizontalLength,
                left = verticalLength,
            }

            local sequence = self:GetSequentialSpec()
            local consumedLength = 0
            local layoutBySide = {}
            for _, segment in ipairs(sequence) do
                local length = sideLength[segment.side]
                local low = (perimeterLength - consumedLength - length) / perimeterLength
                local high = (perimeterLength - consumedLength) / perimeterLength
                consumedLength = consumedLength + length

                local startOffset
                if segment.reverse then
                    startOffset = (1 - high) * perimeterLength
                else
                    startOffset = low * perimeterLength
                end

                layoutBySide[segment.side] = {
                    offset = startOffset,
                    reverse = segment.reverse,
                }
            end

            local topLayout = layoutBySide.top or { offset = 0, reverse = false }
            self.topEdge:ClearAllPoints()
            self.topEdge:SetPoint('LEFT', self.topClip, 'LEFT', -topLayout.offset, 0)
            self.topEdge:SetSize(perimeterLength, thickness)
            self.topEdge:SetOrientation('HORIZONTAL')
            self.topEdge:SetReverseFill(topLayout.reverse)

            local rightLayout = layoutBySide.right or { offset = 0, reverse = false }
            self.rightEdge:ClearAllPoints()
            self.rightEdge:SetPoint('BOTTOM', self.rightClip, 'BOTTOM', 0, -rightLayout.offset)
            self.rightEdge:SetSize(thickness, perimeterLength)
            self.rightEdge:SetOrientation('VERTICAL')
            self.rightEdge:SetReverseFill(rightLayout.reverse)

            local bottomLayout = layoutBySide.bottom or { offset = 0, reverse = false }
            self.bottomEdge:ClearAllPoints()
            self.bottomEdge:SetPoint('LEFT', self.bottomClip, 'LEFT', -bottomLayout.offset, 0)
            self.bottomEdge:SetSize(perimeterLength, thickness)
            self.bottomEdge:SetOrientation('HORIZONTAL')
            self.bottomEdge:SetReverseFill(bottomLayout.reverse)

            local leftLayout = layoutBySide.left or { offset = 0, reverse = false }
            self.leftEdge:ClearAllPoints()
            self.leftEdge:SetPoint('BOTTOM', self.leftClip, 'BOTTOM', 0, -leftLayout.offset)
            self.leftEdge:SetSize(thickness, perimeterLength)
            self.leftEdge:SetOrientation('VERTICAL')
            self.leftEdge:SetReverseFill(leftLayout.reverse)
        end

        frame.ApplyBorderColor = function(self)
            if not self.color then
                return
            end

            self.topEdge:SetStatusBarColor(self.color.r, self.color.g, self.color.b, self.color.a)
            self.rightEdge:SetStatusBarColor(self.color.r, self.color.g, self.color.b, self.color.a)
            self.bottomEdge:SetStatusBarColor(self.color.r, self.color.g, self.color.b, self.color.a)
            self.leftEdge:SetStatusBarColor(self.color.r, self.color.g, self.color.b, self.color.a)
        end

        frame.HideAnimatedBorder = function(self)
            self.topEdge:Hide()
            self.rightEdge:Hide()
            self.bottomEdge:Hide()
            self.leftEdge:Hide()
            if self.topClip then self.topClip:Hide() end
            if self.rightClip then self.rightClip:Hide() end
            if self.bottomClip then self.bottomClip:Hide() end
            if self.leftClip then self.leftClip:Hide() end
            self.topEdge:SetValue(1)
            self.rightEdge:SetValue(1)
            self.bottomEdge:SetValue(1)
            self.leftEdge:SetValue(1)
            self.activeDuration = nil
            self:SetScript('OnUpdate', nil)
        end

        frame.StartSimultaneousBorder = function(self, duration)
            if not duration then
                return false
            end

            self:SetScript('OnUpdate', nil)
            if self.topClip then self.topClip:Show() end
            if self.rightClip then self.rightClip:Show() end
            if self.bottomClip then self.bottomClip:Show() end
            if self.leftClip then self.leftClip:Show() end
            self.topEdge:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
            self.rightEdge:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
            self.bottomEdge:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
            self.leftEdge:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
            self.topEdge:Show()
            self.rightEdge:Show()
            self.bottomEdge:Show()
            self.leftEdge:Show()
            return true
        end

        frame.ShowAnimatedBorder = function(self, duration)
            if not duration then
                self:HideAnimatedBorder()
                return false
            end

            self:ApplyBorderThickness()
            self.activeDuration = duration
            return self:StartSimultaneousBorder(duration)
        end

        frame.DefaultCallback = function(self, shouldBeColored)
            if shouldBeColored then
                self:Show()
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
            if self.spell and auraData[self.spell] then
                elements.isColored = false
                elements.recolor = nil
                shouldBeColored = true
                self:ApplyBorderColor()
                self:SetScript('OnUpdate', nil)
                local duration = auraDurations and auraDurations[self.spell]
                if not duration then
                    duration = C_UnitAuras.GetAuraDuration(unit, auraData[self.spell].auraInstanceID)
                end
                local hasAnimatedBorder = self.showCooldown and duration and self:ShowAnimatedBorder(duration)
                if hasAnimatedBorder then
                    self:SetBackdropBorderColor(self.color.r, self.color.g, self.color.b, 0)
                else
                    self:HideAnimatedBorder()
                    self:SetBackdropBorderColor(self.color.r, self.color.g, self.color.b, self.color.a)
                end
            else
                elements.isColored = false
                elements.recolor = nil
                self:SetScript('OnUpdate', nil)
                self:HideAnimatedBorder()
            end

            self:DefaultCallback(shouldBeColored)
        end

        frame.ShowPreview = function(self)
            self:ApplyBorderColor()
            self:SetScript('OnUpdate', nil)
            if self.showCooldown then
                local duration = C_DurationUtil.CreateDuration()
                duration:SetTimeFromStart(GetTime(), 30)
                self:ShowAnimatedBorder(duration)
                self:SetBackdropBorderColor(self.color.r, self.color.g, self.color.b, 0)
                if not self.previewTimer then
                    self.previewTimer = C_Timer.NewTicker(30, function()
                        local tickerDuration = C_DurationUtil.CreateDuration()
                        tickerDuration:SetTimeFromStart(GetTime(), 30)
                        self:ShowAnimatedBorder(tickerDuration)
                    end)
                end
            else
                if self.previewTimer then
                    self.previewTimer:Cancel()
                    self.previewTimer = nil
                end
                self:HideAnimatedBorder()
                self:SetBackdropBorderColor(self.color.r, self.color.g, self.color.b, self.color.a)
            end
            self:Show()
        end

        frame.Release = function(self)
            Ui.HealthColorIndicatorPool:Release(self)
        end
    end
)