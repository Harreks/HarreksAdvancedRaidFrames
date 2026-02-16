local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

function Util.UpdateIndicatorsForUnit(unit)
    local unitList = Util.GetRelevantList()
    local auras = Data.state.auras[unit]
    local elements = unitList[unit]
    if not elements.auras then elements.auras = {} end
    wipe(elements.auras)
    for instanceId, buff in pairs(auras) do
        elements.auras[buff] = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, instanceId)
    end

    if elements then
        if elements.indicatorOverlay then
            elements.indicatorOverlay:UpdateIndicators(elements.auras)
        end
        if #elements.extraFrames > 0 then
            for _, extraFrameData in ipairs(elements.extraFrames) do
                if extraFrameData.indicatorOverlay then
                    extraFrameData.indicatorOverlay:UpdateIndicators(elements.auras)
                end
            end
        end
    end
end

--What a stupid fucking function to have to write
function Util.FigureOutBarAnchors(barData)
    local points = {
        { point = barData.Position, relative = barData.Position }
    }
    local sizing = {}

    if barData.Orientation == 'Vertical' then
        sizing.Orientation = 'VERTICAL'
    else
        sizing.Orientation = 'HORIZONTAL'
    end

    if barData.Position == 'TOPRIGHT' then
        if barData.Orientation == 'Vertical' then
            if barData.Scale == 'Full' then
                table.insert(points, { point = 'BOTTOMRIGHT', relative = 'BOTTOMRIGHT' })
            elseif barData.Scale == 'Half' then
                table.insert(points, { point = 'BOTTOMRIGHT', relative = 'RIGHT' })
            end
        elseif barData.Orientation == 'Horizontal' then
            if barData.Scale == 'Full' then
                table.insert(points, { point = 'TOPLEFT', relative = 'TOPLEFT' })
            elseif barData.Scale == 'Half' then
                table.insert(points, { point = 'TOPLEFT', relative = 'TOP' })
            end
        end
    elseif barData.Position == 'TOPLEFT' then
        if barData.Orientation == 'Vertical' then
            if barData.Scale == 'Full' then
                table.insert(points, { point = 'BOTTOMLEFT', relative = 'BOTTOMLEFT' })
            elseif barData.Scale == 'Half' then
                table.insert(points, { point = 'BOTTOMLEFT', relative = 'LEFT' })
            end
        elseif barData.Orientation == 'Horizontal' then
            sizing.Reverse = true
            if barData.Scale == 'Full' then
                table.insert(points, { point = 'TOPRIGHT', relative = 'TOPRIGHT' })
            elseif barData.Scale == 'Half' then
                table.insert(points, { point = 'TOPRIGHT', relative = 'TOP' })
            end
        end
    elseif barData.Position == 'BOTTOMRIGHT' then
        if barData.Orientation == 'Vertical' then
            sizing.Reverse = true
            if barData.Scale == 'Full' then
                table.insert(points, { point = 'TOPRIGHT', relative = 'TOPRIGHT' })
            elseif barData.Scale == 'Half' then
                table.insert(points, { point = 'TOPRIGHT', relative = 'RIGHT' })
            end
        elseif barData.Orientation == 'Horizontal' then
            if barData.Scale == 'Full' then
                table.insert(points, { point = 'BOTTOMLEFT', relative = 'BOTTOMLEFT' })
            elseif barData.Scale == 'Half' then
                table.insert(points, { point = 'BOTTOMLEFT', relative = 'BOTTOM' })
            end
        end
    elseif barData.Position == 'BOTTOMLEFT' then
        sizing.Reverse = true
        if barData.Orientation == 'Vertical' then
            if barData.Scale == 'Full' then
                table.insert(points, { point = 'TOPLEFT', relative = 'TOPLEFT' })
            elseif barData.Scale == 'Half' then
                table.insert(points, { point = 'TOPLEFT', relative = 'LEFT' })
            end
        elseif barData.Orientation == 'Horizontal' then
            if barData.Scale == 'Full' then
                table.insert(points, { point = 'BOTTOMRIGHT', relative = 'BOTTOMRIGHT' })
            elseif barData.Scale == 'Half' then
                table.insert(points, { point = 'BOTTOM', relative = 'BOTTOM' })
            end
        end
    end
    return { points = points, sizing = sizing }
end

--There must be a better way to do this?
--Do i have to rewrite my whole data tables so i can share it between the functions?
function Util.GetDefaultSettingsForIndicator(type)
    local data = { Type = type }
        if type == 'healthColor' then
        data.Color = { r = 0, g = 1, b = 0, a = 1 }
    elseif type == 'icon' then
        data.Position = 'CENTER'
        data.Size = 25
        data.xOffset = 0
        data.yOffset = 0
    elseif type == 'square' then
        data.Color = { r = 0, g = 1, b = 0, a = 1 }
        data.Position = 'CENTER'
        data.Size = 25
        data.xOffset = 0
        data.yOffset = 0
    elseif type == 'bar' then
        data.Color = { r = 0, g = 1, b = 0, a = 1 }
        data.Position = 'TOPRIGHT'
        data.Scale = 'Full'
        data.Orientation = 'Horizontal'
        data.Size = 15
    end
    for spell, _ in pairs(Data.specInfo[Options.editingSpec].auras) do
        data.Spell = spell
        break
    end
    return data
end

function Util.DisplayPopupTextbox(title, link)
    if not StaticPopupDialogs['HARF_COPY_TEXT'] then
        StaticPopupDialogs['HARF_COPY_TEXT'] = {
            text = '',
            button1 = CLOSE,
            hasEditBox = true,
            editBoxWidth = 250,
            OnShow = function(self, data)
                self.EditBox:SetText(data)
                C_Timer.After(0.05, function()
                    self.EditBox:HighlightText()
                    self.EditBox:SetFocus()
                end)
            end,
            EditBoxOnEnterPressed = function(self)
                self:GetParent():Hide()
            end
        }
    end
    StaticPopup_Show('HARF_COPY_TEXT', title, nil, link)
end

--fuck flame recoloring
--[[
hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
    local unitList = Util.GetRelevantList()
    if frame.unit and unitList[frame.unit] and frame == _G[unitList[frame.unit].frame] and unitList[frame.unit].isColored then
        local color = unitList[frame.unit].recolor
        --frame.healthBar.barTexture:SetVertexColor(color.r, color.g, color.b)
    end
end)
]]