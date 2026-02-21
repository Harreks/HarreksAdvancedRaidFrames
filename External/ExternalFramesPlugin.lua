local unitIndexMap = {}
local dandersIndexMap = {}
local LGF = LibStub("LibGetFrame-1.0", true)
local LCG = LibStub('LibCustomGlow-1.0', true)

local dandersRecoloringFunc = function(frame, shouldBeColored, color)
    if frame and DandersFrames_IsReady and DandersFrames_IsReady() then
        if shouldBeColored then
            DandersFrames_HighlightUnit(frame.unit, color.r, color.g, color.b, color.a)
        else
            DandersFrames_ClearHighlight(frame.unit)
        end
    end
end

local recoloringFunc = function(frame, shouldBeColored, color)
    if frame and LCG then
        if shouldBeColored then
            LCG.PixelGlow_Start(frame, {color.r, color.g, color.b, color.a})
        else
            LCG.PixelGlow_Stop(frame)
        end
    end
end

local excludedFrames = {
    '^Grid2Layout.*',
    '^DandersRaidFrame',
    '^DandersFrames_Party',
    '^DandersFrames_Player$',
    '^CompactRaid',
    '^CompactParty'
}

local function GetFrameScanCallback()
    if not AdvancedRaidFramesAPI or not LGF then
        return
    end

    for unit, index in pairs(unitIndexMap) do
        if unit and index then
            local frame = LGF.GetUnitFrame(unit)
            if frame and LCG then
                LCG.PixelGlow_Stop(frame)
            end
            AdvancedRaidFramesAPI.UnregisterFrameForUnit(unit, index)
        end
    end
    wipe(unitIndexMap)
    --Player
    local frame = LGF.GetUnitFrame('player', { ignoreFrames = excludedFrames })
    if frame then
        local index = AdvancedRaidFramesAPI.RegisterFrameForUnit('player', frame, recoloringFunc)
        unitIndexMap['player'] = index
    end
    --Party
    for i = 1, 4 do
        local unit = 'party' .. i
        local unitFrame = LGF.GetUnitFrame(unit, { ignoreFrames = excludedFrames })
        if unitFrame then
            local index = AdvancedRaidFramesAPI.RegisterFrameForUnit(unit, unitFrame, recoloringFunc)
            unitIndexMap[unit] = index
        end
    end
    --Raid
    for i = 1, 40 do
        local unit = 'raid' .. i
        local unitFrame = LGF.GetUnitFrame(unit, { ignoreFrames = excludedFrames })
        if unitFrame then
            local index = AdvancedRaidFramesAPI.RegisterFrameForUnit(unit, unitFrame, recoloringFunc)
            unitIndexMap[unit] = index
        end
    end
end

local groupTracker = CreateFrame('Frame')
groupTracker:RegisterEvent('GROUP_ROSTER_UPDATE')
groupTracker:RegisterEvent('PLAYER_LOGIN')
groupTracker:SetScript('OnEvent', function(_, event)

    if not AdvancedRaidFramesAPI then
        return
    end

    if event == 'PLAYER_LOGIN' and not DandersFrames_IsReady then
        if LGF and LGF.RegisterCallback then
            LGF.RegisterCallback('HarreksAdvancedRaidFrames', 'GETFRAME_REFRESH', GetFrameScanCallback)
        end
    end

    --If we have Danders
    if DandersFrames_IsReady and DandersFrames_IsReady() and DandersFrames_GetFrameForUnit then
            C_Timer.After(1, function()
                for unit, index in pairs(dandersIndexMap) do
                    if unit and index then
                        DandersFrames_ClearHighlight(unit)
                        AdvancedRaidFramesAPI.UnregisterFrameForUnit(unit, index)
                    end
                end
                wipe(dandersIndexMap)
                --Player
                local frame = DandersFrames_GetFrameForUnit('player')
                if frame then
                    local index = AdvancedRaidFramesAPI.RegisterFrameForUnit('player', frame, dandersRecoloringFunc)
                    dandersIndexMap['player'] = index
                end
                --Party
                for i = 1, 4 do
                    local unit = 'party' .. i
                    local unitFrame = DandersFrames_GetFrameForUnit(unit)
                    if unitFrame then
                        local index = AdvancedRaidFramesAPI.RegisterFrameForUnit(unit, unitFrame, dandersRecoloringFunc)
                        dandersIndexMap[unit] = index
                    end
                end
                --Raid
                for i = 1, 40 do
                    local unit = 'raid' .. i
                    local unitFrame = DandersFrames_GetFrameForUnit(unit)
                    if unitFrame then
                        local index = AdvancedRaidFramesAPI.RegisterFrameForUnit(unit, unitFrame, dandersRecoloringFunc)
                        dandersIndexMap[unit] = index
                    end
                end
            end)
    else
        if LGF and LGF.ScanForUnitFrames then
            LGF:ScanForUnitFrames()
        end
    end

end)