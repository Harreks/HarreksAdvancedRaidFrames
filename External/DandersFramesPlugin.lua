local unitIndexMap = {}

local recoloringFunc = function(frame, shouldBeColored, color)
    if frame and DandersFrames_IsReady and DandersFrames_IsReady() then
        if shouldBeColored then
            DandersFrames_HighlightUnit(frame.unit, color.r, color.g, color.b, color.a)
        else
            DandersFrames_ClearHighlight(frame.unit)
        end
    end
end

local groupTracker = CreateFrame('Frame')
groupTracker:RegisterEvent('GROUP_ROSTER_UPDATE')
groupTracker:RegisterEvent('PLAYER_LOGIN')
groupTracker:SetScript('OnEvent', function()
    --just in case
    C_Timer.After(1, function()

        if AdvancedRaidFramesAPI and DandersFrames_IsReady and DandersFrames_IsReady() and DandersFrames_GetFrameForUnit then
            for unit, index in pairs(unitIndexMap) do
                if unit and index then
                    AdvancedRaidFramesAPI.UnregisterFrameForUnit(unit, index)
                end
            end
            --Player
            local frame = DandersFrames_GetFrameForUnit('player')
            if frame then
                local index = AdvancedRaidFramesAPI.RegisterFrameForUnit('player', frame, recoloringFunc)
                unitIndexMap['player'] = index
            end
            --Party
            for i = 1, 4 do
                local unit = 'party' .. i
                local unitFrame = DandersFrames_GetFrameForUnit(unit)
                if unitFrame then
                    local index = AdvancedRaidFramesAPI.RegisterFrameForUnit(unit, unitFrame, recoloringFunc)
                    unitIndexMap[unit] = index
                end
            end
            --Raid
            for i = 1, 40 do
                local unit = 'raid' .. i
                local unitFrame = DandersFrames_GetFrameForUnit(unit)
                if unitFrame then
                    local index = AdvancedRaidFramesAPI.RegisterFrameForUnit(unit, unitFrame, recoloringFunc)
                    unitIndexMap[unit] = index
                end
            end
        end

    end)
end)