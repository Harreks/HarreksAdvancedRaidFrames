local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core
local Opt = NS.Opt

function Opt.SetupSettings(modifiedSettingFunction, newValue)
    if not InCombatLockdown() then
        local unitList = Util.GetRelevantList()
        local functionsToRun = {}
        if modifiedSettingFunction and type(Core[modifiedSettingFunction]) == 'function' then
            table.insert(functionsToRun, { func = Core[modifiedSettingFunction], val = newValue } )
        else
            table.insert(functionsToRun, { func = Core.ToggleBuffIcons, val = HARFDB.buffIcons } )
            table.insert(functionsToRun, { func = Core.ToggleDebuffIcons, val = HARFDB.debuffIcons } )
            table.insert(functionsToRun, { func = Core.ToggleAurasMouseInteraction, val = not HARFDB.clickThroughBuffs } )
            table.insert(functionsToRun, { func = Core.SetGroupFrameTransparency, val = HARFDB.frameTransparency } )
            table.insert(functionsToRun, { func = Core.ScaleNames, val = HARFDB.nameScale } )
            table.insert(functionsToRun, { func = Core.ColorNames, val = HARFDB.colorNames } )

            if Data.playerClass == 'PRIEST' and HARFDB.buffTracking then
                Data.supportedBuffTracking.PRIEST.utility.isDisc = C_SpecializationInfo.GetSpecialization() == 1
            end

            Util.CleanUtilityTables()
            Util.MapOutUnits()
        end

        for unit, elements in pairs(unitList) do
            for _, functionData in ipairs(functionsToRun) do
                functionData.func(functionData.val, unit, elements)
            end
        end

        if IsInRaid() and HARFDB.spotlight.names then
            Util.MapSpotlightAnchors()
            Util.ReanchorSpotlights()
        end
    end
end

Opt.spotlightOptionsFrame = CreateFrame('Frame', 'AdvancedRaidFramesSpotlight', UIParent, 'InsetFrameTemplate')
Opt.spotlightOptionsFrame:SetSize(200, 50)
Opt.spotlightOptionsFrame:SetPoint('CENTER', UIParent, 'CENTER')
Opt.spotlightOptionsFrame.text = Opt.spotlightOptionsFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
Opt.spotlightOptionsFrame.text:SetPoint("CENTER", Opt.spotlightOptionsFrame, 'CENTER')
Opt.spotlightOptionsFrame.text:SetText('Advanced Raid Frames\nSpotlight')
Opt.spotlightOptionsFrame:SetAlpha(0)

Opt.eventTracker = CreateFrame('Frame')
Opt.eventTracker.trackingCasts = false
Opt.eventTracker:SetScript('OnEvent', function(_, event, ...)
    if event == 'PLAYER_LOGIN' then
        Data.playerClass = UnitClassBase('player')

        Util.CreateOptionsPanel(Data.settings)
        Util.InstallFrames()

        local LEM = NS.LibEditMode

        LEM:RegisterCallback('enter', function()
            Opt.spotlightOptionsFrame:SetAlpha(1)
        end)

        LEM:RegisterCallback('exit', function()
            Opt.spotlightOptionsFrame:SetAlpha(0)
            if IsInRaid() and not InCombatLockdown() and HARFDB.spotlight.names then
                Util.ReanchorSpotlights()
            end
        end)

        LEM:RegisterCallback('layout', function()
            if not HARFDB.spotlight then
                HARFDB.spotlight = {
                    pos = { p = 'CENTER', x = 0, y = 0 },
                    names = {},
                    grow = 'right'
                }
            end
            Opt.SetupSettings()
            Opt.spotlightOptionsFrame:SetPoint(HARFDB.spotlight.pos.p, HARFDB.spotlight.pos.x, HARFDB.spotlight.pos.y)
        end)

        LEM:AddFrame(Opt.spotlightOptionsFrame, function(_, _, point, x, y)
            HARFDB.spotlight.pos = { p = point, x = x, y = y }
        end)

        LEM:AddFrameSettings(Opt.spotlightOptionsFrame, {
            {
                name = 'Player List',
                kind = LEM.SettingType.Dropdown,
                default = {},
                desc = 'Select the players to be shown in the spotlight',
                multiple = true,
                get = function()
                    local nameList = {}
                    for name, _ in pairs(HARFDB.spotlight.names) do
                        table.insert(nameList, name)
                    end
                    return nameList
                end,
                set = function(_, value)
                    if HARFDB.spotlight.names[value] then
                        HARFDB.spotlight.names[value] = nil
                    else
                        HARFDB.spotlight.names[value] = true
                    end
                    Util.MapSpotlightAnchors()
                end,
                values = Util.GetSpotlightNames
            },
            {
                name = 'Grow Direction',
                kind = LEM.SettingType.Dropdown,
                default = 'right',
                desc = 'Grow direction for the spotlight frames',
                get = function(_)
                    return HARFDB.spotlight.grow
                end,
                set = function(_, value)
                    HARFDB.spotlight.grow = value
                end,
                values = {
                    { text = 'Right', value = 'right' },
                    { text = 'Bottom', value = 'bottom' }
                }
            }
        })
    elseif event == 'GROUP_ROSTER_UPDATE' then
        Opt.SetupSettings()
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
