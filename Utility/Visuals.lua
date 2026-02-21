local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local API = NS.API
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

local pairs = pairs
local ipairs = ipairs
local wipe = wipe
local next = next
local type = type

local GetAuraDataByAuraInstanceID = C_UnitAuras.GetAuraDataByAuraInstanceID
local GetAuraDuration = C_UnitAuras.GetAuraDuration

local function GetFirstSpellForSpec(spec)
    if spec and Data.specInfo[spec] and Data.specInfo[spec].auras then
        for spell, _ in pairs(Data.specInfo[spec].auras) do
            return spell
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
                    if indicatorData.Type == 'bar' and indicatorData.Offset == nil and indicatorData.offset ~= nil then
                        indicatorData.Offset = indicatorData.offset
                        indicatorData.offset = nil
                    end

                    local typeData = Data.indicatorTypeSettings[indicatorData.Type]
                    if typeData and typeData.defaults then
                        for key, defaultValue in pairs(typeData.defaults) do
                            if indicatorData[key] == nil then
                                if type(defaultValue) == 'table' then
                                    indicatorData[key] = CopyTable(defaultValue)
                                else
                                    indicatorData[key] = defaultValue
                                end
                            end
                        end
                    end

                    if indicatorData.Type == 'square' then
                        if indicatorData.showCooldown then
                            if indicatorData.showText == nil then
                                indicatorData.showText = true
                            end
                        else
                            indicatorData.showText = false
                        end
                    end

                    if not indicatorData.Spell then
                        indicatorData.Spell = GetFirstSpellForSpec(spec)
                            or GetFirstSpellForSpec(Options.editingSpec)
                            or GetFirstSpellForSpec(Data.playerSpec)
                    end
                end
            end
        end
    end
end

function Util.UpdateIndicatorsForUnit(unit, updateInfo)
    local profileStart = Util.ProfileStart()
    local unitList = Util.GetRelevantList()
    local auras = Data.state.auras[unit]
    local elements = unitList[unit]
    if elements then
        if not elements.auras then elements.auras = {} end
        if not elements.auraInstanceMap then elements.auraInstanceMap = {} end
        if not elements.auraDurations then elements.auraDurations = {} end
        if not elements.spellInstanceCounts then elements.spellInstanceCounts = {} end
        if not elements.spellInstanceAny then elements.spellInstanceAny = {} end
        if not elements.snapshotAuras then elements.snapshotAuras = {} end
        if not elements.snapshotInstanceMap then elements.snapshotInstanceMap = {} end
        if not elements.snapshotDurations then elements.snapshotDurations = {} end
        if not elements.trackedSpellCounts then elements.trackedSpellCounts = {} end

        local instanceMap = elements.auraInstanceMap
        local durationMap = elements.auraDurations
        local spellInstanceCounts = elements.spellInstanceCounts
        local spellInstanceAny = elements.spellInstanceAny

        wipe(spellInstanceCounts)
        wipe(spellInstanceAny)
        for trackedInstanceId, trackedSpell in pairs(instanceMap) do
            spellInstanceCounts[trackedSpell] = (spellInstanceCounts[trackedSpell] or 0) + 1
            spellInstanceAny[trackedSpell] = trackedInstanceId
        end

        local trackedSpellCounts = elements.trackedSpellCounts
        wipe(trackedSpellCounts)
        for _, trackedSpell in pairs(auras or {}) do
            trackedSpellCounts[trackedSpell] = (trackedSpellCounts[trackedSpell] or 0) + 1
        end

        local function HasTrackedStateForSpell(targetSpell)
            return (trackedSpellCounts[targetSpell] or 0) > 0
        end

        local function SetSpellDisplayData(targetAuras, targetDurations, spell, auraData, duration)
            targetAuras[spell] = auraData
            targetDurations[spell] = duration
        end

        local function ClearCurrentSpellDisplayData(spell)
            elements.auras[spell] = nil
            elements.auraDurations[spell] = nil
        end

        local function RemoveTrackedInstance(instanceId)
            local spell = instanceMap[instanceId]
            if not spell then
                return nil
            end

            instanceMap[instanceId] = nil
            local nextCount = (spellInstanceCounts[spell] or 1) - 1
            if nextCount <= 0 then
                spellInstanceCounts[spell] = nil
                spellInstanceAny[spell] = nil
            else
                spellInstanceCounts[spell] = nextCount
                if spellInstanceAny[spell] == instanceId then
                    spellInstanceAny[spell] = nil
                    for trackedInstanceId, trackedSpell in pairs(instanceMap) do
                        if trackedSpell == spell then
                            spellInstanceAny[spell] = trackedInstanceId
                            break
                        end
                    end
                end
            end

            return spell
        end

        local function SetTrackedInstance(instanceId, spell)
            local previousSpell = instanceMap[instanceId]
            if previousSpell == spell then
                return
            end

            if previousSpell then
                RemoveTrackedInstance(instanceId)
            end

            if spell then
                instanceMap[instanceId] = spell
                spellInstanceCounts[spell] = (spellInstanceCounts[spell] or 0) + 1
                if not spellInstanceAny[spell] then
                    spellInstanceAny[spell] = instanceId
                end
            end
        end

        local shouldFullRefresh = not updateInfo
            or updateInfo.isFullUpdate
            or next(instanceMap) == nil

        if shouldFullRefresh then
            local previousAuras = elements.snapshotAuras
            local previousInstanceMap = elements.snapshotInstanceMap
            local previousDurations = elements.snapshotDurations

            wipe(previousAuras)
            for spell, auraData in pairs(elements.auras) do
                previousAuras[spell] = auraData
            end

            wipe(previousInstanceMap)
            for trackedInstanceId, trackedSpell in pairs(instanceMap) do
                previousInstanceMap[trackedInstanceId] = trackedSpell
            end

            wipe(previousDurations)
            for spell, duration in pairs(durationMap) do
                previousDurations[spell] = duration
            end

            wipe(elements.auras)
            wipe(instanceMap)
            wipe(durationMap)
            wipe(spellInstanceCounts)
            wipe(spellInstanceAny)

            for instanceId, buff in pairs(auras or {}) do
                SetTrackedInstance(instanceId, buff)
                local auraData = GetAuraDataByAuraInstanceID(unit, instanceId)
                if auraData then
                    SetSpellDisplayData(elements.auras, durationMap, buff, auraData, GetAuraDuration(unit, instanceId))
                else
                    local previousSpell = previousInstanceMap and previousInstanceMap[instanceId]
                    if previousSpell == buff and previousAuras and previousAuras[buff] then
                        SetSpellDisplayData(elements.auras, durationMap, buff, previousAuras[buff], previousDurations and previousDurations[buff] or nil)
                    end
                end
            end
        else
            if updateInfo.removedAuraInstanceIDs then
                for _, instanceId in ipairs(updateInfo.removedAuraInstanceIDs) do
                    local spell = RemoveTrackedInstance(instanceId)
                    if spell then
                        local fallbackInstanceId = spellInstanceAny[spell]
                        if fallbackInstanceId then
                            local fallbackAuraData = GetAuraDataByAuraInstanceID(unit, fallbackInstanceId)
                            if fallbackAuraData then
                                SetSpellDisplayData(elements.auras, durationMap, spell, fallbackAuraData, GetAuraDuration(unit, fallbackInstanceId))
                            else
                                ClearCurrentSpellDisplayData(spell)
                            end
                        elseif not HasTrackedStateForSpell(spell) then
                            ClearCurrentSpellDisplayData(spell)
                        end
                    end
                end
            end

            local function RefreshAuraByInstanceId(instanceId)
                local spell = (auras and auras[instanceId]) or instanceMap[instanceId]
                if spell then
                    local hasTrackedState = auras and auras[instanceId] ~= nil
                    local auraData = GetAuraDataByAuraInstanceID(unit, instanceId)
                    if auraData then
                        SetTrackedInstance(instanceId, spell)
                        SetSpellDisplayData(elements.auras, durationMap, spell, auraData, GetAuraDuration(unit, instanceId))
                    else
                        if not hasTrackedState then
                            RemoveTrackedInstance(instanceId)
                            local fallbackInstanceId = spellInstanceAny[spell]
                            if fallbackInstanceId then
                                local fallbackAuraData = GetAuraDataByAuraInstanceID(unit, fallbackInstanceId)
                                if fallbackAuraData then
                                    SetSpellDisplayData(elements.auras, durationMap, spell, fallbackAuraData, GetAuraDuration(unit, fallbackInstanceId))
                                else
                                    if not HasTrackedStateForSpell(spell) then
                                        ClearCurrentSpellDisplayData(spell)
                                    end
                                end
                            else
                                if not HasTrackedStateForSpell(spell) then
                                    ClearCurrentSpellDisplayData(spell)
                                end
                            end
                        end
                    end
                end
            end

            if updateInfo.addedAuras then
                for _, aura in ipairs(updateInfo.addedAuras) do
                    RefreshAuraByInstanceId(aura.auraInstanceID)
                end
            end

            if updateInfo.updatedAuraInstanceIDs then
                for _, instanceId in ipairs(updateInfo.updatedAuraInstanceIDs) do
                    RefreshAuraByInstanceId(instanceId)
                end
            end
        end

        if elements.indicatorOverlay then
            elements.indicatorOverlay:UpdateIndicators(elements.auras, elements.auraDurations)
        end
        if #elements.extraFrames > 0 then
            for _, extraFrameData in ipairs(elements.extraFrames) do
                if extraFrameData.indicatorOverlay then
                    extraFrameData.indicatorOverlay:UpdateIndicators(elements.auras, elements.auraDurations)
                end
            end
        end
        API.Callbacks:Fire('HARF_UNIT_AURA', unit, elements.auras)
    end

    Util.ProfileStop('UpdateIndicatorsForUnit', profileStart)
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
    local typeData = Data.indicatorTypeSettings[indicatorType]
    if typeData and typeData.defaults then
        for key, value in pairs(typeData.defaults) do
            if type(value) == 'table' then
                data[key] = CopyTable(value)
            else
                data[key] = value
            end
        end
    end

    data.Spell = GetFirstSpellForSpec(Options.editingSpec or Data.playerSpec)
        or GetFirstSpellForSpec(Options.editingSpec)
        or GetFirstSpellForSpec(Data.playerSpec)

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