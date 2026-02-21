local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

function Core.InstallTrackers()
    if not Core.AuraTracker then
        local auraTracker = CreateFrame('Frame')
        auraTracker:SetSize(25, 25)
        auraTracker:SetScript('OnEvent', function(_, _, unitId, auraUpdateInfo)
            if Util.IsSupportedSpec(Data.playerSpec) and unitId and Util.GetRelevantList()[unitId] then
                Core.UpdateAuraStatus(unitId, auraUpdateInfo)
            end
        end)

        auraTracker:RegisterEvent('UNIT_AURA')

        Core.AuraTracker = auraTracker
    end

    if not Core.CastTracker then
        local castTracker = CreateFrame('Frame')
        castTracker:RegisterUnitEvent('UNIT_SPELLCAST_SUCCEEDED', 'player')
        castTracker:RegisterUnitEvent('UNIT_SPELLCAST_EMPOWER_STOP', 'player')
        castTracker:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_STOP', 'player')
        castTracker:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_START', 'player')
        castTracker:SetScript('OnEvent', function(_, event, _, _, spellId)
            local state = Data.state
            if Util.IsSupportedSpec(Data.playerSpec) then --Getting some weird triggers on casts before the player logs in
                local specInfo = Data.specInfo[Data.playerSpec]
                local timestamp = GetTime()
                if event == 'UNIT_SPELLCAST_SUCCEEDED' then
                    if specInfo.casts[spellId] then
                        state.casts[spellId] = timestamp
                    end
                elseif event == 'UNIT_SPELLCAST_EMPOWER_STOP' then
                    if specInfo.empowers and specInfo.empowers[spellId] then
                        state.casts[spellId] = timestamp
                    end
                end
            end
        end)
        Core.CastTracker = castTracker
    end

    if not Core.StateTracker then
        local stateTracker = CreateFrame('Frame')
        stateTracker:RegisterEvent('PLAYER_LOGIN')
        stateTracker:RegisterEvent('GROUP_ROSTER_UPDATE')
        stateTracker:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
        stateTracker:RegisterEvent('ACTIVE_PLAYER_SPECIALIZATION_CHANGED')
        stateTracker:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')

        local function HandlePlayerSpecializationChanged()
            local previousSpec = Data.playerSpec
            Util.UpdatePlayerSpec()
            if previousSpec == Data.playerSpec then
                return
            end

            Util.MapOutUnits()

            if Ui.DesignerFrame then
                Ui.DesignerFrame:RefreshScrollBox()
                Ui.DesignerFrame:RefreshPreview()
            end
        end

        stateTracker:SetScript('OnEvent', function(self, event, unitTarget)
            if event == 'PLAYER_LOGIN' then
                Util.DebugData(Data.state, 'State')
                Util.DebugData(Data.unitList, 'Units')
                Util.DebugData(SavedIndicators, 'Indicators')
                Util.UpdatePlayerSpec()
                if not Options.editingSpec or not Data.specInfo[Options.editingSpec] then
                    Options.editingSpec = Data.playerSpec
                end
                Util.MapEngineFunctions()

                Ui.CreateOptionsPanel(Data.settings)

                local spotlightFrame = Ui.GetSpotlightFrame()
                local LEM = (LibEQOL and LibEQOL.EditMode) or LibStub('LibEQOLEditMode-1.0')

                if not Options.spotlight then
                    Options.spotlight = {
                        pos = { p = 'CENTER', x = 0, y = 0 },
                        names = {},
                        grow = 'right'
                    }
                end

                if type(Options.spotlight.names) ~= 'table' then
                    Options.spotlight.names = {}
                end

                local spotlightNameValues = Util.GetSpotlightNames()
                if type(spotlightNameValues) ~= 'table' then
                    spotlightNameValues = {}
                end

                LEM:RegisterCallback('enter', function()
                    spotlightFrame:SetAlpha(1)
                end)

                LEM:RegisterCallback('exit', function()
                    spotlightFrame:SetAlpha(0)
                    if IsInRaid() and not InCombatLockdown() and Options.spotlight.names then
                        Util.ReanchorSpotlights()
                    end
                end)

                LEM:RegisterCallback('layout', function()
                    if not Options.spotlight then
                        Options.spotlight = {
                            pos = { p = 'CENTER', x = 0, y = 0 },
                            names = {},
                            grow = 'right'
                        }
                    end
                    Core.ModifySettings()
                    spotlightFrame:SetPoint(Options.spotlight.pos.p, Options.spotlight.pos.x, Options.spotlight.pos.y)
                end)

                LEM:AddFrame(spotlightFrame, function(_, _, point, x, y)
                    Options.spotlight.pos = { p = point, x = x, y = y }
                end)

                LEM:AddFrameSettings(spotlightFrame, {
                    {
                        name = 'Player List',
                        kind = LEM.SettingType.Dropdown,
                        default = {},
                        desc = 'Select the players to be shown in the spotlight',
                        multiple = true,
                        get = function()
                            local nameList = {}
                            local selectedNames = (Options.spotlight and Options.spotlight.names) or {}
                            for name, _ in pairs(selectedNames) do
                                table.insert(nameList, name)
                            end
                            return nameList
                        end,
                        set = function(_, value)
                            if not Options.spotlight then
                                Options.spotlight = { pos = { p = 'CENTER', x = 0, y = 0 }, names = {}, grow = 'right' }
                            end
                            if type(Options.spotlight.names) ~= 'table' then
                                Options.spotlight.names = {}
                            end
                            if Options.spotlight.names[value] then
                                Options.spotlight.names[value] = nil
                            else
                                Options.spotlight.names[value] = true
                            end
                            Util.MapSpotlightAnchors()
                        end,
                        values = spotlightNameValues
                    },
                    {
                        name = 'Grow Direction',
                        kind = LEM.SettingType.Dropdown,
                        default = 'right',
                        desc = 'Grow direction for the spotlight frames',
                        get = function(_)
                            return Options.spotlight.grow
                        end,
                        set = function(_, value)
                            Options.spotlight.grow = value
                        end,
                        values = {
                            { text = 'Right', value = 'right' },
                            { text = 'Bottom', value = 'bottom' }
                        }
                    }
                })
            elseif event == 'GROUP_ROSTER_UPDATE' then
                Core.ModifySettings()
            elseif event == 'ACTIVE_PLAYER_SPECIALIZATION_CHANGED' or event == 'ACTIVE_TALENT_GROUP_CHANGED' then
                HandlePlayerSpecializationChanged()
            elseif event == 'PLAYER_SPECIALIZATION_CHANGED' and unitTarget and UnitIsUnit(unitTarget, 'player') then
                HandlePlayerSpecializationChanged()
            end
        end)
    end
end
