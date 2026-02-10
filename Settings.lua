local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core
local Settings = NS.Settings

function Settings.SetupSettings(modifiedSettingFunction, newValue)
    if not InCombatLockdown() then
        local relevantFrameList = Util.GetRelevantList()
        local layoutInfo = HARFDB[Data.currentLayout]
        local functionsToRun = {}
        if not modifiedSettingFunction or modifiedSettingFunction == Core.MapOutUnits then
            if Data.playerClass == 'PRIEST' and layoutInfo.buffTracking then
                Data.supportedBuffTracking.PRIEST.utility.isDisc = C_SpecializationInfo.GetSpecialization() == 1
            end
            Util.CleanUtilityTables()
        end

        if modifiedSettingFunction and type(modifiedSettingFunction) == 'function' then
            table.insert(functionsToRun, { func = modifiedSettingFunction, val = newValue } )
        else
            table.insert(functionsToRun, { func = Core.ToggleBuffIcons, val = layoutInfo.buffIcons } )
            table.insert(functionsToRun, { func = Core.ToggleDebuffIcons, val = layoutInfo.debuffIcons } )
            table.insert(functionsToRun, { func = Core.ToggleAurasMouseInteraction, val = not layoutInfo.clickThroughBuffs } )
            table.insert(functionsToRun, { func = Core.SetGroupFrameTransparency, val = layoutInfo.frameTransparency } )
            table.insert(functionsToRun, { func = Core.ScaleNames, val = layoutInfo.nameScale } )
            table.insert(functionsToRun, { func = Core.ColorNames, val = layoutInfo.colorNames } )
            table.insert(functionsToRun, { func = Core.MapOutUnits, val = layoutInfo.buffTracking } )
        end

        for frameString, elements in pairs(relevantFrameList) do
            for _, functionData in ipairs(functionsToRun) do
                functionData.func(functionData.val, frameString, elements)
            end
        end

        if IsInRaid() and HARFDB[Data.currentLayout].spotlight.names then
            Util.MapSpotlightAnchors()
            Util.ReanchorSpotlights()
        end
    end
end

Settings.clickableOptionsFrame = CreateFrame('Frame', 'HarreksAdvancedRaidFrames', UIParent, 'InsetFrameTemplate')
Settings.clickableOptionsFrame:SetSize(150, 45)
Settings.clickableOptionsFrame:SetPoint('TOPRIGHT', CompactPartyFrame, 'TOPLEFT', -5, 0)
Settings.clickableOptionsFrame.text = Settings.clickableOptionsFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
Settings.clickableOptionsFrame.text:SetPoint("CENTER", Settings.clickableOptionsFrame, 'CENTER')
Settings.clickableOptionsFrame.text:SetText('Advanced Raid Frames')
Settings.clickableOptionsFrame:Hide()

Settings.spotlightOptionsFrame = CreateFrame('Frame', 'AdvancedRaidFramesSpotlight', UIParent, 'InsetFrameTemplate')
Settings.spotlightOptionsFrame:SetSize(200, 50)
Settings.spotlightOptionsFrame:SetPoint('CENTER', UIParent, 'CENTER')
Settings.spotlightOptionsFrame.text = Settings.spotlightOptionsFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
Settings.spotlightOptionsFrame.text:SetPoint("CENTER", Settings.spotlightOptionsFrame, 'CENTER')
Settings.spotlightOptionsFrame.text:SetText('Advanced Raid Frames\nSpotlight')
Settings.spotlightOptionsFrame:SetAlpha(0)

Settings.eventTracker = CreateFrame('Frame')
Settings.eventTracker.trackingCasts = false
Settings.eventTracker:SetScript('OnEvent', function(_, event, ...)
    if event == 'PLAYER_LOGIN' then
        Data.playerClass = UnitClassBase('player')

        local LEM = LibStub('LibEditMode')

        LEM:RegisterCallback('enter', function()
            Settings.clickableOptionsFrame:Show()
            Settings.spotlightOptionsFrame:SetAlpha(1)
        end)

        LEM:RegisterCallback('exit', function()
            Settings.clickableOptionsFrame:Hide()
            Settings.spotlightOptionsFrame:SetAlpha(0)
            if IsInRaid() and not InCombatLockdown() and HARFDB[Data.currentLayout].spotlight.names then
                Util.ReanchorSpotlights()
            end
        end)

        LEM:RegisterCallback('layout', function(layout)
            Data.currentLayout = layout
            if not HARFDB[layout] then
                HARFDB[layout] = CopyTable(Data.defaultSettings)
            else
                for option, value in pairs(Data.defaultSettings) do
                    if not HARFDB[layout][option] then
                        HARFDB[layout][option] = value
                    end
                end
            end
            Settings.SetupSettings()
            Settings.spotlightOptionsFrame:SetPoint(HARFDB[layout].spotlight.point, HARFDB[layout].spotlight.x, HARFDB[layout].spotlight.y)
        end)

        local options = {
            {
                name = 'Click Through Aura Icons',
                kind = LEM.SettingType.Checkbox,
                default = Data.defaultSettings.clickThroughBuffs,
                desc = 'Disables mouse interaction on the aura icons on the frame, letting you mouseover and click through them.',
                get = function(layout)
                    return HARFDB[layout].clickThroughBuffs
                end,
                set = function(layout, value)
                    HARFDB[layout].clickThroughBuffs = value
                    Settings.SetupSettings(Core.ToggleAurasMouseInteraction, not value)
                end
            },
            {
                name = 'Buff Icons',
                kind = LEM.SettingType.Slider,
                default = Data.defaultSettings.buffIcons,
                desc = 'Changes the maximum amount of buff icons on the frame.',
                get = function(layout)
                    return HARFDB[layout].buffIcons
                end,
                set = function(layout, value)
                    HARFDB[layout].buffIcons = value
                    Settings.SetupSettings(Core.ToggleBuffIcons, value)
                end,
                minValue = 0,
                maxValue = 6,
                valueStep = 1
            },
            {
                name = 'Debuff Icons',
                kind = LEM.SettingType.Slider,
                default = Data.defaultSettings.debuffIcons,
                desc = 'Changes the maximum amount of debuff icons on the frame.',
                get = function(layout)
                    return HARFDB[layout].debuffIcons
                end,
                set = function(layout, value)
                    HARFDB[layout].debuffIcons = value
                    Settings.SetupSettings(Core.ToggleDebuffIcons, value)
                end,
                minValue = 0,
                maxValue = 3,
                valueStep = 1
            },
            {
                name = 'Frame Transparency',
                kind = LEM.SettingType.Checkbox,
                default = Data.defaultSettings.frameTransparency,
                desc = 'Disabling frame transparency keeps the frame fully solid even when out of range.',
                get = function(layout)
                    return HARFDB[layout].frameTransparency
                end,
                set = function(layout, value)
                    HARFDB[layout].frameTransparency = value
                    Settings.SetupSettings(Core.SetGroupFrameTransparency, value)
                end
            },
            {
                name = 'Name Size',
                kind = LEM.SettingType.Slider,
                default = Data.defaultSettings.nameScale,
                desc = 'Changes the size of the unit name.',
                get = function(layout)
                    return HARFDB[layout].nameScale
                end,
                set = function(layout, value)
                    HARFDB[layout].nameScale = value
                    Settings.SetupSettings(Core.ScaleNames, value)
                end,
                formatter = Util.FormatForDisplay,
                minValue = 0.5,
                maxValue = 3,
                valueStep = 0.1
            },
            {
                name = 'Class Colored Names',
                kind = LEM.SettingType.Checkbox,
                default = Data.defaultSettings.colorNames,
                desc = 'Replaces the unit name for class-colored ones.',
                get = function(layout)
                    return HARFDB[layout].colorNames
                end,
                set = function(layout, value)
                    HARFDB[layout].colorNames = value
                    Settings.SetupSettings(Core.ColorNames, value)
                end
            }
        }
        if Data.supportedBuffTracking[Data.playerClass] and Data.gameVersion >= 120001 then
            local conditionalOptions = {
                {
                    name = 'Buff Tracking: ' .. Data.supportedBuffTracking[Data.playerClass].spell,
                    kind = LEM.SettingType.Checkbox,
                    default = Data.defaultSettings.buffTracking,
                    desc = 'Some specializations can track a specific buff better on their frames, this enables that tracking.',
                    get = function(layout)
                        return HARFDB[layout].buffTracking
                    end,
                    set = function(layout, value)
                        HARFDB[layout].buffTracking = value
                        Settings.SetupSettings(Core.MapOutUnits, value)
                    end
                },
                {
                    name = 'Tracking Type',
                    kind = LEM.SettingType.Dropdown,
                    default = Data.defaultSettings.trackingType,
                    desc = 'Choose how to track the buffs.',
                    get = function(layout)
                        return HARFDB[layout].trackingType
                    end,
                    set = function(layout, value)
                        HARFDB[layout].trackingType = value
                    end,
                    values = {
                        icon = { text = 'Icon', value = 'icon'},
                        color = { text = 'Bar Recolor', value = 'color' }
                    }
                },
                {
                    name = 'Tracking Bar Color',
                    kind = LEM.SettingType.ColorPicker,
                    default = CreateColor(Data.defaultSettings.trackingColor.r, Data.defaultSettings.trackingColor.g, Data.defaultSettings.trackingColor.b),
                    desc = 'Color to change the bars into when the buff is present.',
                    get = function(layout)
                        local currentColor = HARFDB[layout].trackingColor
                        return CreateColor(currentColor.r, currentColor.g, currentColor.b)
                    end,
                    set = function(layout, value)
                        local r, g, b = value:GetRGB()
                        HARFDB[layout].trackingColor = { r = r, g = g, b = b }
                    end
                }
            }
            if DandersFrames_IsReady and DandersFrames_IsReady() then
                table.insert(conditionalOptions, {
                    name = 'DandersFrames Compatibility',
                    kind = LEM.SettingType.Checkbox,
                    default = Data.defaultSettings.dandersCompat,
                    desc = 'Enables bar-recoloring on buffs for the addon frame.',
                    get = function(layout)
                        return HARFDB[layout].dandersCompat
                    end,
                    set = function(layout, value)
                        HARFDB[layout].dandersCompat = value
                    end
                })
            end
            for _, option in ipairs(conditionalOptions) do
                table.insert(options, option)
            end
        end

        LEM:AddFrame(Settings.clickableOptionsFrame, function(frame)
            frame:ClearAllPoints()
            frame:SetPoint("TOPRIGHT", CompactPartyFrame, "TOPLEFT", -5, 0)
        end, { point = 'CENTER', x = 0, y = 0})
        LEM:AddFrameSettings(Settings.clickableOptionsFrame, options)

        LEM:AddFrame(Settings.spotlightOptionsFrame, function(_, layout, point, x, y)
            HARFDB[layout].spotlight.point = point
            HARFDB[layout].spotlight.x = x
            HARFDB[layout].spotlight.y = y
        end)

        LEM:AddFrameSettings(Settings.spotlightOptionsFrame, {
            {
                name = 'Player List',
                kind = LEM.SettingType.Dropdown,
                default = Data.defaultSettings.spotlight.names,
                desc = 'Select the players to be shown in the spotlight',
                multiple = true,
                get = function(layout)
                    local nameList = {}
                    for name, _ in pairs(HARFDB[layout].spotlight.names) do
                        table.insert(nameList, name)
                    end
                    return nameList
                end,
                set = function(layout, value)
                    if HARFDB[layout].spotlight.names[value] then
                        HARFDB[layout].spotlight.names[value] = nil
                    else
                        HARFDB[layout].spotlight.names[value] = true
                    end
                    Util.MapSpotlightAnchors()
                end,
                values = Util.GetSpotlightNames()
            },
            {
                name = 'Grow Direction',
                kind = LEM.SettingType.Dropdown,
                default = Data.defaultSettings.spotlight.grow,
                desc = 'Grow direction for the spotlight frames',
                get = function(layout)
                    return HARFDB[layout].spotlight.grow
                end,
                set = function(layout, value)
                    HARFDB[layout].spotlight.grow = value
                end,
                values = {
                    { text = 'Right', value = 'right' },
                    { text = 'Bottom', value = 'bottom' }
                }
            }
        })
    elseif event == 'GROUP_ROSTER_UPDATE' then
        Settings.SetupSettings()
    elseif event == 'UNIT_SPELLCAST_SUCCEEDED' and Data.supportedBuffTracking[Data.playerClass] then
        local utilityTable = Data.supportedBuffTracking[Data.playerClass].utility
        local spellId = select(3, ...)
        if utilityTable.filteredSpells and utilityTable.filteredSpells[spellId] then
            utilityTable.filteredSpellTimestamp = GetTime()
        end
        --Special handling for TTS
        if Data.playerClass == 'EVOKER' then
            if spellId == 370553 then
                utilityTable.ttsActive = true
            elseif utilityTable.ttsActive and utilityTable.allEmpowers[spellId] then
                utilityTable.ttsActive = false
                if utilityTable.filteredEmpowers[spellId] then
                    utilityTable.filteredSpellTimestamp = GetTime()
                end
            end
        end
    elseif Data.playerClass == 'EVOKER' and event == 'UNIT_SPELLCAST_EMPOWER_STOP' then
        local _, _, spellId, empSuccess = ...
        local utilityTable = Data.supportedBuffTracking[Data.playerClass].utility
        if empSuccess and utilityTable.filteredEmpowers[spellId] then
            utilityTable.filteredSpellTimestamp = GetTime()
        end
    end
end)
