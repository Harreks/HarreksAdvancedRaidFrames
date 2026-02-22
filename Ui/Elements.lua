local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util

local indicatorOverlayRenderers = {
    icon = function(overlay, indicatorData)
        local newIcon = Ui.IconIndicatorPool:Acquire()
        local showText = indicatorData.showText ~= false
        local showTexture = indicatorData.showTexture ~= false
        newIcon.spell = indicatorData.Spell
        newIcon:SetParent(overlay)
        newIcon:SetSize(indicatorData.Size, indicatorData.Size)
        newIcon:SetPoint(indicatorData.Position, overlay, indicatorData.Position, indicatorData.xOffset, indicatorData.yOffset)
        newIcon.cooldown:SetScale(indicatorData.textSize)
        newIcon.cooldown:SetHideCountdownNumbers(not showText)
        newIcon.texture:SetShown(showTexture)
        newIcon.cooldown:SetDrawSwipe(showTexture)
        newIcon.cooldown:SetDrawEdge(showTexture)
        newIcon.cooldown:SetDrawBling(showTexture)
        return newIcon
    end,
    square = function(overlay, indicatorData)
        local newSquare = Ui.SquareIndicatorPool:Acquire()
        newSquare.spell = indicatorData.Spell
        local showText = indicatorData.showText ~= false
        local color = indicatorData.Color
        local backgroundColor = indicatorData.BackgroundColor or { r = 0, g = 0, b = 0, a = 0.8 }
        newSquare:SetParent(overlay)
        newSquare:SetSize(indicatorData.Size, indicatorData.Size)
        newSquare:SetPoint(indicatorData.Position, overlay, indicatorData.Position, indicatorData.xOffset, indicatorData.yOffset)
        if newSquare.background then
            newSquare.background:SetColorTexture(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a)
        end
        newSquare.texture:SetColorTexture(color.r, color.g, color.b, color.a)
        newSquare.cooldownSwipeColor = { r = color.r, g = color.g, b = color.b, a = color.a }
        newSquare.showCooldown = indicatorData.showCooldown
        if indicatorData.showCooldownText == nil then
            newSquare.showCooldownText = showText
        else
            newSquare.showCooldownText = indicatorData.showCooldownText ~= false
        end
        newSquare.cooldownStyle = indicatorData.cooldownStyle or 'Swipe'
        newSquare.depleteDirection = indicatorData.depleteDirection or 'Right to Left'
        newSquare.texture:SetShown(not newSquare.showCooldown)
        if newSquare.background then
            newSquare.background:SetShown(newSquare.showCooldown)
        end
        if newSquare.depleteBar and newSquare.depleteBar.SetStatusBarColor then
            newSquare.depleteBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
        end
        if newSquare.ApplyDepleteDirection then
            newSquare:ApplyDepleteDirection()
        end
        newSquare.cooldown:SetScale(indicatorData.textSize)
        newSquare.cooldown:SetHideCountdownNumbers(not newSquare.showCooldownText)
        newSquare.cooldown:SetReverse(false)
        newSquare.cooldown:SetDrawSwipe(true)
        newSquare.cooldown:SetDrawEdge(false)
        newSquare.cooldown:SetDrawBling(false)
        if newSquare.cooldown.SetSwipeColor then
            newSquare.cooldown:SetSwipeColor(newSquare.cooldownSwipeColor.r, newSquare.cooldownSwipeColor.g, newSquare.cooldownSwipeColor.b, newSquare.cooldownSwipeColor.a)
        end
        newSquare.cooldown:SetShown(indicatorData.showCooldown and newSquare.cooldownStyle ~= 'Deplete')
        if newSquare.depleteBar then
            newSquare.depleteBar:SetShown(indicatorData.showCooldown and newSquare.cooldownStyle == 'Deplete')
        end
        return newSquare
    end,
    bar = function(overlay, indicatorData)
        local newBar = Ui.BarIndicatorPool:Acquire()
        newBar.spell = indicatorData.Spell
        local color = indicatorData.Color
        local backgroundColor = indicatorData.BackgroundColor or { r = 0, g = 0, b = 0, a = 0.8 }
        newBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
        if newBar.background then
            newBar.background:SetColorTexture(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundColor.a)
        end
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
                newBar:SetWidth(indicatorData.Size)
            else
                newBar:SetHeight(indicatorData.Size)
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
        newHealthRecolor:SetAllPoints()
        return newHealthRecolor
    end
}

function Ui.CreateIndicatorOverlay(indicatorDataTable)
    local newIndicatorOverlay = Ui.IndicatorOverlayPool:Acquire()
    if indicatorDataTable and type(indicatorDataTable) == 'table' then
        for _, indicatorData in ipairs(indicatorDataTable) do
            local renderer = indicatorOverlayRenderers[indicatorData.Type]
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
        spotlightFrame.editModeName = 'Advanced Raid Frames Spotlight'
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