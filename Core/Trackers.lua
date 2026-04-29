local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local Debug = NS.Debug
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

function Core.InstallTrackers()
    --The aura trackers are per-unit, this is the most efficient way because the events only ever fire for valid units
    --So even if we install trackers for raid40, they would simply never activate on a 5man party
    --We also completely avoid all events that are not from group members this way
    for unit, elements in pairs(Data.unitList) do
        if not elements.tracker then
            local tracker = CreateFrame('Frame')
            tracker.unit = unit
            tracker.lastUpdate = 0
            tracker.active = false
            --The visible check is a function that runs on active trackers if there has not been any events in the last second
            --If there hasn't it confirms that the unit is still valid and if it isn't it sends an update to hide all indicators
            tracker.VisibleCheck = function(self)
                if self.active and (GetTime() - self.lastUpdate) > 1 then
                    if not UnitIsVisible(self.unit) or not UnitIsConnected(self.unit) then
                        self.active = false
                        self:SetScript('OnUpdate', nil)
                        Util.ResetUnitAuraData(self.unit)
                    end
                end
            end
            tracker:SetScript('OnEvent', function(self, event, unitId, auraUpdateInfo)
                if event == 'UNIT_AURA' and Data.playerSpec and Util.IsValidUnitForAuraCheck(unitId) then
                    if not self.active then
                        self.active = true
                        self:SetScript('OnUpdate', self.VisibleCheck)
                    end
                    self.lastUpdate = GetTime()
                    Core.UpdateAuraStatus(unitId, auraUpdateInfo)
                elseif event == 'UNIT_ABSORB_AMOUNT_CHANGED' then
                    Util.UpdateOvershields(unitId)
                end
            end)
            tracker:RegisterUnitEvent('UNIT_AURA', unit)
            if Options.showOvershields then
                tracker:RegisterUnitEvent('UNIT_ABSORB_AMOUNT_CHANGED', unit)
            end
            elements.tracker = tracker
        end
    end

    --Cast tracker is to assist in identifying some auras that are still secret
    if not Core.CastTracker then
        local castTracker = CreateFrame('Frame')
        castTracker:RegisterUnitEvent('UNIT_SPELLCAST_SUCCEEDED', 'player')
        castTracker:SetScript('OnEvent', function(_, event, _, _, spellId)
            local state = Data.state
            if Data.playerSpec then
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

    --Enemy cast tracking for targeted spells
    if not Core.EnemyCastTracker then
        local enemyCastTracker = CreateFrame('Frame')
        Util.ToggleEnemyCastTrackingEvents(Options.enableTargetedSpells)
        enemyCastTracker:SetScript('OnEvent', function(_, event, castingUnit)
            if string.match(castingUnit, "^nameplate%d+$") and not issecretvalue(castingUnit) and UnitIsEnemy(castingUnit, 'player')  then
                if event == 'UNIT_SPELLCAST_START' or event == 'UNIT_SPELLCAST_CHANNEL_START' then
                    local castIcon, castDuration
                    if select(9, UnitCastingInfo(castingUnit)) then
                        castIcon = select(3, UnitCastingInfo(castingUnit))
                        castDuration = UnitCastingDuration(castingUnit)
                    else
                        castIcon = select(3, UnitChannelInfo(castingUnit))
                        castDuration = UnitChannelDuration(castingUnit)
                    end
                    local castData = { caster = castingUnit, icon = castIcon, duration = castDuration }
                    Util.CreateTargetedSpellIcon(castData)
                elseif
                    event == 'UNIT_SPELLCAST_STOP' or
                    event == 'UNIT_SPELLCAST_INTERRUPTED' or
                    event == 'UNIT_SPELLCAST_CHANNEL_STOP' or
                    event == 'UNIT_SPELLCAST_FAILED_QUIET'
                then
                    Util.DeleteTargetedSpellIcon(castingUnit)
                end
            end
        end)
        Core.EnemyCastTracker = enemyCastTracker
    end

    if not Core.PlayerTargetingTracker then
        local playerTargetingTracker = CreateFrame('Frame')
        playerTargetingTracker:SetScript('OnEvent', function()
            for castingUnit, _ in pairs(Data.state.enemyCasts) do
                Util.RunAlphaCalculationForCast(castingUnit)
            end
        end)
        Core.PlayerTargetingTracker = playerTargetingTracker
    end

    --State tracker to initialize settings and keep them updated
    if not Core.StateTracker then
        local stateTracker = CreateFrame('Frame')
        stateTracker:RegisterEvent('ADDON_LOADED')
        stateTracker:RegisterEvent('PLAYER_LOGIN')
        stateTracker:RegisterEvent('PLAYER_ENTERING_WORLD')
        stateTracker:RegisterEvent('GROUP_ROSTER_UPDATE')
        stateTracker:RegisterEvent('ACTIVE_PLAYER_SPECIALIZATION_CHANGED')
        stateTracker:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')

        stateTracker:SetScript('OnEvent', function(self, event, addonName)
            if event == 'ADDON_LOADED' and addonName == 'HarreksAdvancedRaidFrames' then
                Debug.DebugData(Data.state, 'State')
                Debug.DebugData(Data.unitList, 'Units')
                Util.UpdatePlayerSpec()
                if not Options.editingSpec or not Data.specInfo[Options.editingSpec] then
                    Options.editingSpec = Data.playerSpec
                end

                Ui.CreateOptions()
                Core.ModifySettings()

                local spotlightFrame = Ui.GetSpotlightFrame()

                local LEM = NS.LibEditMode
                LEM:RegisterCallback('enter', function()
                    spotlightFrame:SetAlpha(1)
                end)

                LEM:RegisterCallback('exit', function()
                    spotlightFrame:SetAlpha(0)
                    Core.ModifySettings()
                end)

                --TODO: The whole spotlight settings should be moved to a different file
                LEM:RegisterCallback('layout', function()
                    if not Options.spotlight then
                        Options.spotlight = {
                            pos = { p = 'CENTER', x = 0, y = 0 },
                            groupSize = 5,
                            names = {},
                            grow = 'right'
                        }
                    end
                    --TODO: in the future run option validations on init
                    if not Options.spotlight.groupSize then Options.spotlight.groupSize = 5 end
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
                            Util.UpdateSpotlightFrames()
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
                    },
                    {
                        name = 'Max Group Size',
                        kind = LEM.SettingType.Slider,
                        default = 5,
                        desc = 'Select the maximum amount of units before the spotlight breaks into a new line',
                        get = function(_)
                            return Options.spotlight.groupSize
                        end,
                        set = function(_, value)
                            Options.spotlight.groupSize = value
                        end,
                        minValue = 2,
                        maxValue = 10,
                        valueStep = 1
                    }
                })

                local LGF = LibStub('LibGetFrame-1.0')
                LGF.RegisterCallback('HarreksAdvancedRaidFrames', 'GETFRAME_REFRESH', function()
                    if Options.extFrames and Data.updatingExternalFrames then
                        Data.updatingExternalFrames = false
                        Util.GetExternalFrames()
                    end
                end)
            elseif event == 'PLAYER_LOGIN' or event == 'GROUP_ROSTER_UPDATE' then
                C_Timer.After(0.2, Core.ModifySettings)
            elseif event == 'PLAYER_ENTERING_WORLD' then
                local activeAuraData = Data.state.auras
                for unit, _ in pairs(activeAuraData) do
                    Util.ResetUnitAuraData(unit)
                end
            elseif event == 'ACTIVE_PLAYER_SPECIALIZATION_CHANGED' or event == 'ACTIVE_TALENT_GROUP_CHANGED' then
                Util.HandlePlayerSpecializationChanged()
            end
        end)
    end
end
