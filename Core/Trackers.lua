local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
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
                    Core.UpdateAuraStatus(unitId, auraUpdateInfo)
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
                        state.lastCast = spellId
                    end
                    if Data.playerSpec == 'RestorationDruid' then
                        --When convoke is casted, we are convoking for the next 3 seconds
                        if spellId == specInfo.convoke then
                            state.extras.isConvoking = true
                            C_Timer.After(3, function() state.extras.isConvoking = false end)
                        end
                    elseif Data.playerSpec == 'PreservationEvoker' then
                        --We set a flag when TTS is casted
                        if spellId == specInfo.tts then
                            state.extras.tts = true
                        --if TTS is already active, check if the cast is an empower
                        elseif state.extras.tts and specInfo.empowers[spellId] then
                            --We remove tts on any empower, but only save the cast on dream breath
                            state.extras.tts = false
                            if specInfo.empowers[spellId] == 'DreamBreath' then
                                state.casts['DreamBreath'] = timestamp
                                state.lastCast = 'DreamBreath'
                            end
                        end
                        --Special handling for dreamflight
                        if spellId == specInfo.df then
                            state.extras.dreamflight = true
                            --This is terrible, i need to find a good event to detect the dreamflight landing
                            C_Timer.After(2, function() state.extras.dreamflight = false end)
                        end
                    elseif Data.playerSpec == 'MistweaverMonk' then
                        if spellId == 116849 then
                            state.lastCast = 'LifeCocoon'
                            state.casts['LifeCocoon'] = timestamp
                        end
                    end
                elseif event == 'UNIT_SPELLCAST_EMPOWER_STOP' then
                    if Data.playerSpec == 'PreservationEvoker' then
                        --instead of cast success, dream breath needs a empower_stop with empSuccess
                        if specInfo.empowers[spellId] == 'DreamBreath' and empSuccess then
                            --kind of a funky workaround, by using the spell name we avoid the normal spellcast_succeed from saving db
                            state.casts['DreamBreath'] = timestamp
                            state.lastCast = 'DreamBreath'
                        end
                    elseif Data.playerSpec == 'AugmentationEvoker' then
                        local empowerCast = specInfo.empowers[spellId]
                        if empowerCast and empSuccess then
                            state.casts[empowerCast] = timestamp
                            state.lastCast = empowerCast
                        end
                    end
                elseif event == 'UNIT_SPELLCAST_CHANNEL_START' then
                    if Data.playerSpec == 'MistweaverMonk' then
                        if spellId == 115175 then
                            --The delay is so the channel stop that triggers basically at the same time doesn't turn it off
                            C_Timer.After(0.05, function() state.extras.sooming = true end)
                        end
                    end
                elseif event == 'UNIT_SPELLCAST_CHANNEL_STOP' then
                    if Data.playerSpec == 'MistweaverMonk' then
                        if spellId == 115175 then
                            state.extras.sooming = false
                        end
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
                Util.UpdatePlayerSpec()
                Util.MapEngineFunctions()
                Data.editingSpec = Data.playerSpec

                Ui.CreateOptionsPanel(Data.settings)

                local spotlightFrame = Ui.GetSpotlightFrame()
                local LEM = NS.LibEditMode
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
