local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local API = NS.API
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

function Core.InstallTrackers()
    for groupType, units in pairs(Data.unitList) do
        for unit, _ in pairs(units) do
            local elements = Data.unitList[groupType][unit]
            if not elements.tracker then
                local tracker = CreateFrame('Frame')
                tracker:SetSize(25, 25)
                tracker:SetScript('OnEvent', function(_, _, unitId, auraUpdateInfo)
                    if Data.playerSpec then
                        Core.UpdateAuraStatus(unitId, auraUpdateInfo)
                    end
                end)
                tracker:RegisterUnitEvent('UNIT_AURA', unit)
                elements.tracker = tracker
            end
        end
    end

    if not Core.CastTracker then
        local castTracker = CreateFrame('Frame')
        castTracker:RegisterUnitEvent('UNIT_SPELLCAST_SUCCEEDED', 'player')
        castTracker:RegisterUnitEvent('UNIT_SPELLCAST_EMPOWER_STOP', 'player')
        castTracker:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_STOP', 'player')
        castTracker:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_START', 'player')
        castTracker:SetScript('OnEvent', function(_, event, _, _, spellId, empSuccess)
            local state = Data.state
            if Data.playerSpec then --Getting some weird triggers on casts before the player logs in
                local specInfo = Data.specInfo[Data.playerSpec]
                local timestamp = GetTime()
                if event == 'UNIT_SPELLCAST_SUCCEEDED' then
                    if specInfo.casts[spellId] then
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
        stateTracker:SetScript('OnEvent', function(self, event)
            if event == 'PLAYER_LOGIN' then
                Util.DebugData(Data.state, 'State')
                Util.DebugData(Data.unitList, 'Units')
                Util.DebugData(SavedIndicators, 'Indicators')
                Util.UpdatePlayerSpec()
                Util.MapEngineFunctions()

                Ui.CreateOptionsPanel(Data.settings)

                local spotlightFrame = Ui.GetSpotlightFrame()
                local LEM = (LibEQOL and LibEQOL.EditMode) or LibStub('LibEQOLEditMode-1.0')
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
                            for name, _ in pairs(Options.spotlight.names) do
                                table.insert(nameList, name)
                            end
                            return nameList
                        end,
                        set = function(_, value)
                            if Options.spotlight.names[value] then
                                Options.spotlight.names[value] = nil
                            else
                                Options.spotlight.names[value] = true
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
            end
        end)
    end
end
