--Utility
local currentLayout = nil

local function ChangeFrameMouseInteraction(frameString, value)
    if _G[frameString] and _G[frameString]:IsMouseEnabled() ~= value then
        _G[frameString]:EnableMouse(value)
    end
end

local function ToggleTransparency(frameString, shouldShow)
    if _G[frameString] then
        if shouldShow then
            _G[frameString]:SetAlpha(1)
        else
            _G[frameString]:SetAlpha(0)
        end
    end
end

--Toggles mouse interaction on raid frame icons, pass true for enabled and false for disabled
local function ToggleIndicatorsMouse(value)
    for i = 1, GetNumGroupMembers() do
        local partyUnit, raidUnit, frame
        if i <= 5 then
            partyUnit = 'CompactPartyFrameMember' .. i
        end
        raidUnit = 'CompactRaidFrame' .. i
        for j = 1, 6 do
            if j <= 3 then
                frame = partyUnit .. 'Debuff' .. j
                ChangeFrameMouseInteraction(frame, value)
                frame = raidUnit .. 'Debuff' .. j
                ChangeFrameMouseInteraction(frame, value)
            end
            frame = partyUnit .. 'Buff' .. j
            ChangeFrameMouseInteraction(frame, value)
            frame = raidUnit .. 'Buff' .. j
            ChangeFrameMouseInteraction(frame, value)
        end
        frame = partyUnit .. 'CenterStatusIcon'
        ChangeFrameMouseInteraction(frame, value)
        frame = raidUnit .. 'CenterStatusIcon'
        ChangeFrameMouseInteraction(frame, value)
    end
end

--Controls visibility on buff icons
local function ToggleBuffIcons(amount)
    for i = 1, GetNumGroupMembers() do
        for j = 2, 6 do
            if j > amount then
                if i <= 5 then
                    local buffIconName = 'CompactPartyFrameMember' .. i .. 'Buff' .. j
                    ChangeFrameMouseInteraction(buffIconName, false)
                    ToggleTransparency(buffIconName, false)
                end
                local buffIconName = 'CompactRaidFrame' .. i .. 'Buff' .. j
                ChangeFrameMouseInteraction(buffIconName, false)
                ToggleTransparency(buffIconName, false)
            else
                if i <= 5 then
                    local buffIconName = 'CompactPartyFrameMember' .. i .. 'Buff' .. j
                    ChangeFrameMouseInteraction(buffIconName, true)
                    ToggleTransparency(buffIconName, true)
                end
                local buffIconName = 'CompactRaidFrame' .. i .. 'Buff' .. j
                ChangeFrameMouseInteraction(buffIconName, true)
                ToggleTransparency(buffIconName, true)
            end
        end
    end
end

--Controls visibility on debuff icons
local function ToggleDebuffIcons(amount)
    for i = 1, GetNumGroupMembers() do
        for j = 2, 3 do
            if j > amount then
                if i <= 5 then
                    local buffIconName = 'CompactPartyFrameMember' .. i .. 'Debuff' .. j
                    ChangeFrameMouseInteraction(buffIconName, false)
                    ToggleTransparency(buffIconName, false)
                end
                local buffIconName = 'CompactRaidFrame' .. i .. 'Debuff' .. j
                ChangeFrameMouseInteraction(buffIconName, false)
                ToggleTransparency(buffIconName, false)
            else
                if i <= 5 then
                    local buffIconName = 'CompactPartyFrameMember' .. i .. 'Debuff' .. j
                    ChangeFrameMouseInteraction(buffIconName, true)
                    ToggleTransparency(buffIconName, true)
                end
                local buffIconName = 'CompactRaidFrame' .. i .. 'Debuff' .. j
                ChangeFrameMouseInteraction(buffIconName, true)
                ToggleTransparency(buffIconName, true)
            end
        end
    end
end

local function SetupSettings()
    ToggleIndicatorsMouse(not RaidFrameTweaksDB[currentLayout].clickThroughBuffs)
    ToggleBuffIcons(RaidFrameTweaksDB[currentLayout].buffIcons)
    ToggleDebuffIcons(RaidFrameTweaksDB[currentLayout].debuffIcons)
end

local eventTracker = CreateFrame('Frame')
eventTracker:RegisterEvent('PLAYER_LOGIN')
eventTracker:RegisterEvent('GROUP_ROSTER_UPDATE')
eventTracker:SetScript('OnEvent', function(self, event)
    if event == 'PLAYER_LOGIN' then
        RaidFrameTweaksDB = RaidFrameTweaksDB or {}

        local LEM = LibStub('LibEditMode')

        LEM:RegisterCallback('layout', function(layout)
            currentLayout = layout
            if not RaidFrameTweaksDB[layout] then
                RaidFrameTweaksDB[layout] = {
                    clickThroughBuffs = true,
                    buffIcons = 6,
                    debuffIcons = 3,
                    classColorNames = false
                }
            end
            SetupSettings()
        end)

        LEM:AddSystemSettings(Enum.EditModeSystem.UnitFrame, {
            {
                name = 'Click Through Buff Icons',
                kind = LEM.SettingType.Checkbox,
                default = true,
                get = function(layout)
                    return RaidFrameTweaksDB[layout].clickThroughBuffs
                end,
                set = function(layout, value)
                    RaidFrameTweaksDB[layout].clickThroughBuffs = value
                    ToggleIndicatorsMouse(not value)
                end
            },
            {
                name = 'Buff Icons',
                kind = LEM.SettingType.Slider,
                default = 6,
                get = function(layout)
                    return RaidFrameTweaksDB[layout].buffIcons
                end,
                set = function(layout, value)
                    RaidFrameTweaksDB[layout].buffIcons = value
                    ToggleBuffIcons(value)
                end,
                minValue = 1,
                maxValue = 6,
                valueStep = 1
            },
            {
                name = 'Debuff Icons',
                kind = LEM.SettingType.Slider,
                default = 3,
                get = function(layout)
                    return RaidFrameTweaksDB[layout].debuffIcons
                end,
                set = function(layout, value)
                    RaidFrameTweaksDB[layout].debuffIcons = value
                    ToggleDebuffIcons(value)
                end,
                minValue = 1,
                maxValue = 3,
                valueStep = 1
            }
        })
    elseif event == 'GROUP_ROSTER_UPDATE' then
        SetupSettings()
    end
end)