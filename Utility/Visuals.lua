local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local API = NS.API
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

function Util.GetFirstSpellForSpec(spec)
    if spec and Data.specInfo[spec] and Data.specInfo[spec].auras then
        for _, spellData in pairs(Data.specInfo[spec].auras) do
            return spellData.name
        end
    end
end

function Util.NormalizeSavedIndicators()
    if not SavedIndicators or type(SavedIndicators) ~= 'table' then
        return
    end

    for spec, indicators in pairs(SavedIndicators) do
        if type(indicators) == 'table' then
            for _, indicatorData in ipairs(indicators) do
                if type(indicatorData) == 'table' and indicatorData.Type then

                    local typeData = Data.indicatorTypes[indicatorData.Type]
                    if typeData and typeData.controls then
                        -- Check against controls setting instead of defaults table
                        local defaultKeys = {}
                        for _, control in ipairs(typeData.controls) do
                            if control.setting and control.default ~= nil then
                                defaultKeys[control.setting] = true
                                if indicatorData[control.setting] == nil then
                                    if type(control.default) == 'table' then
                                        indicatorData[control.setting] = CopyTable(control.default)
                                    else
                                        indicatorData[control.setting] = control.default
                                    end
                                end
                            end
                        end

                        for key, _ in pairs(indicatorData) do
                            if key ~= 'Type' and key ~= 'Spell' and not defaultKeys[key] then
                                indicatorData[key] = nil
                            end
                        end
                    end

                    if not indicatorData.Spell then
                        indicatorData.Spell = Util.GetFirstSpellForSpec(spec)
                            or Util.GetFirstSpellForSpec(Options.editingSpec)
                            or Util.GetFirstSpellForSpec(Data.playerSpec)
                    end
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
    local offset = barData.Offset or 0

    if barData.Orientation == 'Vertical' then
        sizing.Orientation = 'VERTICAL'
        sizing.xOffset = offset
        sizing.yOffset = 0
    elseif barData.Orientation == 'Horizontal' then
        sizing.Orientation = 'HORIZONTAL'
        sizing.xOffset = 0
        sizing.yOffset = offset
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

function Util.GetDefaultSettingsForIndicator(indicatorType)
    local data = { Type = indicatorType }
    local typeData = Data.indicatorTypes[indicatorType]
    if typeData and typeData.controls then
        for _, control in ipairs(typeData.controls) do
            if control.setting and control.default ~= nil then
                if type(control.default) == 'table' then
                    data[control.setting] = CopyTable(control.default)
                else
                    data[control.setting] = control.default
                end
            end
        end
    end

    data.Spell = Util.GetFirstSpellForSpec(Options.editingSpec or Data.playerSpec)
        or Util.GetFirstSpellForSpec(Options.editingSpec)
        or Util.GetFirstSpellForSpec(Data.playerSpec)

    return data
end

--This is a small popup window with links to socials
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
            end
        }
    end
    StaticPopup_Show('HARF_COPY_TEXT', title, nil, link)
end

--These are popups for the export and import functions
function Util.DisplayEncodingPopup(type, content)
    if type == 'export' then
        if not StaticPopupDialogs['HARF_EXPORT'] then
            StaticPopupDialogs['HARF_EXPORT'] = {
                text = 'Export Indicators',
                button1 = CLOSE,
                hasEditBox = true,
                editBoxWidth = 250,
                OnShow = function(self, data)
                    self.EditBox:SetText(data)
                    C_Timer.After(0.05, function()
                        self.EditBox:HighlightText()
                        self.EditBox:SetFocus()
                    end)
                end
            }
        end
        StaticPopup_Show('HARF_EXPORT', nil, nil, content)
    elseif type == 'import' then
        if not StaticPopupDialogs['HARF_IMPORT'] then
            StaticPopupDialogs['HARF_IMPORT'] = {
                text = 'Import Indicators',
                button1 = 'Import',
                button2 = CLOSE,
                hasEditBox = true,
                editBoxWidth = 250,
                OnAccept = function(self)
                    local importedText = self.EditBox:GetText()
                    Util.DecodeIndicators(importedText)
                end
            }
        end
        StaticPopup_Show('HARF_IMPORT')
    elseif type == 'confirm' then
        if not StaticPopupDialogs['HARF_CONFIRM'] then
            StaticPopupDialogs['HARF_CONFIRM'] = {
                text = '',
                button1 = ACCEPT,
                button2 = CLOSE,
                OnAccept = function(_, data)
                    SavedIndicators[data.spec] = data.indicators
                    local designer = Ui.GetDesignerFrame()
                    designer.RefreshScrollBox()
                    designer.RefreshPreview()
                end
            }
        end
        if content.spec and content.indicators then
            local specData = Data.specInfo[content.spec]
            local hexColor = select(4, GetClassColor(specData.class))
            local titleText = 'Importing for |c' .. hexColor .. specData.display .. '|r\n'
            titleText = titleText .. 'Importing these indicators will replace the ones currently existing'
            StaticPopup_Show('HARF_CONFIRM', titleText, nil, content)
        end
    end
end

--This is a small popup window with links to socials
function Util.DisplayResetPopup()
    if not StaticPopupDialogs['HARF_RESET'] then
        StaticPopupDialogs['HARF_RESET'] = {
            text = '|cnNORMAL_FONT_COLOR:AdvancedRaidFrames|r\nAre you sure you want to reset your data? this will delete your indicators.',
            button1 = ACCEPT,
            button2 = CLOSE,
            OnAccept = function()
                HARFDB = nil
                C_UI.Reload()
            end
        }
    end
    StaticPopup_Show('HARF_RESET')
end

function Util.CustomSetVertexColor(self, r, g, b, a)
    local healthBar = self:GetParent()
    if healthBar then
        local unitFrame = healthBar:GetParent()
        if unitFrame and unitFrame.unit then
            local unitList = Data.unitList
            local elements = unitList[unitFrame.unit]
            if not elements.isColored then
                self:_HARF_SetVertexColor(r, g, b, a)
            end
        end
    end
end

function Util.ResetUnitAuraData(unit)
    local emptyAuraData = {}
    for _, auraData in pairs(Data.specInfo[Data.playerSpec].auras) do
        emptyAuraData[auraData.name] = { active = false }
    end
    Util.UpdateIndicatorsForUnit(unit, emptyAuraData)
end

function Util.UpdateIndicatorsForUnit(unit, auraData)
    local elements = Data.unitList[unit]
    if elements.indicatorOverlay then
        elements.indicatorOverlay:UpdateIndicators(auraData)
    end
    if next(elements.extIndicatorOverlays) then
        for _, overlay in ipairs(elements.extIndicatorOverlays) do
            overlay:UpdateIndicators(auraData)
        end
    end
end

--Different frames contain their texture in different ways
function Util.GetFrameHealthTexture(frame)
    if frame then
        --This works on default and Danders
        if frame.healthBar and frame.healthBar.GetStatusBarTexture then
            return frame.healthBar:GetStatusBarTexture()
        end
        --Grid2 has its health bars inside an array, this isn't super well tested
        if frame['health-bar'] then
            return frame['health-bar'].myTextures[1]:GetStatusBarTexture()
        end
    end
end

function Util.GetTextureDropdown()
    local container = Settings.CreateControlTextContainer()
    local sortedNames = {}
    for name in pairs(Data.barTextures) do table.insert(sortedNames, name) end
    table.sort(sortedNames)
    for _, name in ipairs(sortedNames) do
        local texturePath = Data.barTextures[name]
        local displayLabel = "|T" .. texturePath .. ":14:100|t " .. name
        container:Add(name, displayLabel)
    end
    return container:GetData()
end

--This recolors the default frames if blizzard tries to color them back beforehand
hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
    local unitList = Data.unitList
    if frame.unit and unitList[frame.unit] and frame == _G[unitList[frame.unit].frame] and unitList[frame.unit].isColored then
        local color = unitList[frame.unit].recolor
        local texture = frame.healthBar:GetStatusBarTexture()
        texture:SetVertexColor(color.r, color.g, color.b)
    end
end)