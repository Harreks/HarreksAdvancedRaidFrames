local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

function Util.UpdateIndicatorsForUnit(unit)
    local unitList = Util.GetRelevantList()
    local elements = unitList[unit]
    if elements then
        if elements.indicatorOverlay then
            elements.indicatorOverlay:UpdateIndicators()
        end
        if elements.extraFrames then
            --this will be an api point, so extra frames get their own indicator overlays updated as well
        end
    end
end

function Util.FigureOutBarAnchors(barData)
    local points = {
        { point = barData.Position, relative = barData.Position }
    }
    local sizing = {}

    if barData.Orientation == 'Vertical' then
        sizing.Orientation = 'VERTICAL'
        sizing.Width = 20
    else
        sizing.Orientation = 'HORIZONTAL'
        sizing.Height = 20
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
            if barData.Scale == 'Full' then
            elseif barData.Scale == 'Half' then
            end
        end
    elseif barData.Position == 'BOTTOMRIGHT' then
        if barData.Orientation == 'Vertical' then
            if barData.Scale == 'Full' then
            elseif barData.Scale == 'Half' then
            end
        elseif barData.Orientation == 'Horizontal' then
            if barData.Scale == 'Full' then
                table.insert(points, { point = 'BOTTOMLEFT', relative = 'BOTTOMLEFT' })
            elseif barData.Scale == 'Half' then
                table.insert(points, { point = 'BOTTOMLEFT', relative = 'BOTTOM' })
            end
        end
    elseif barData.Position == 'BOTTOMLEFT' then
        if barData.Orientation == 'Vertical' then
            if barData.Scale == 'Full' then
            elseif barData.Scale == 'Half' then
            end
        elseif barData.Orientation == 'Horizontal' then
            if barData.Scale == 'Full' then
            elseif barData.Scale == 'Half' then
            end
        end
    end
    return { points = points, sizing = sizing }
end

function Util.GetDefaultSettingsForIndicator(type)
    local data = { Type = type }
        if type == 'healthColor' then
        data.Color = { r = 0, g = 1, b = 0, a = 1 }
    elseif type == 'icon' then
        data.Position = 'CENTER'
        data.Size = 25
    elseif type == 'square' then
        data.Color = { r = 0, g = 1, b = 0, a = 1 }
        data.Position = 'CENTER'
        data.Size = 25
    elseif type == 'bar' then
        data.Color = { r = 0, g = 1, b = 0, a = 1 }
        data.Position = 'TOPRIGHT'
        data.Scale = 'Full'
        data.Orientation = 'Horizontal'
    end
    for spell, _ in pairs(Data.specInfo[Options.editingSpec].auras) do
        data.Spell = spell
        break
    end
    return data
end