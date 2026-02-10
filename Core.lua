local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core
local Settings = NS.Settings

--Takes a string, checks global table for frame with that name and changes mouse interaction on it
function Core.ChangeFrameMouseInteraction(frameString, value)
    local frame
    --Special handling for the center defensive because it doesn't have a direct name to access
    if type(frameString) == 'table' and frameString.type and frameString.type == 'defensive' then
        if _G[frameString.frame] and _G[frameString.frame].CenterDefensiveBuff then
            frame = _G[frameString.frame].CenterDefensiveBuff
        end
    else
        if _G[frameString] then
            frame = _G[frameString]
        end
    end
    if frame and frame:IsMouseEnabled() ~= value then
        frame:EnableMouse(value)
    end
end

--Hides elements by changing opacity
function Core.ToggleTransparency(frameString, shouldShow)
    if _G[frameString] then
        if shouldShow then
            _G[frameString]:SetAlpha(1)
        else
            _G[frameString]:SetAlpha(0)
        end
    end
end

--Toggles mouse interaction on raid frame icons, pass true for enabled and false for disabled, third param is the elements of the edited frame
function Core.ToggleAurasMouseInteraction(value, _, elements)
    for _, buff in ipairs(elements.buffs) do
        Core.ChangeFrameMouseInteraction(buff, value)
    end
    for _, debuff in ipairs(elements.debuffs) do
        Core.ChangeFrameMouseInteraction(debuff, value)
    end
    Core.ChangeFrameMouseInteraction(elements.centerIcon, value)
    Core.ChangeFrameMouseInteraction(elements.defensive, value)
end

--Controls visibility on buff icons, takes how many buffs are to be shown and the element list of the frame to be modified
function Core.ToggleBuffIcons(amount, _, elements)
    for i = 1, 6 do
        if i <= amount then
            Core.ToggleTransparency(elements.buffs[i], true)
            if _G[elements.buffs[i]] and not _G[elements.buffs[i]]:IsMouseEnabled() and not HARFDB[Data.currentLayout].clickThroughBuffs then
                Core.ChangeFrameMouseInteraction(elements.buffs[i], true)
            end
        else
            Core.ToggleTransparency(elements.buffs[i], false)
            if _G[elements.buffs[i]] and _G[elements.buffs[i]]:IsMouseEnabled() then
                Core.ChangeFrameMouseInteraction(elements.buffs[i], false)
            end
        end
    end
end

--Controls visibility on debuff icons, takes how many debuffs are to be shown and the element list of the frame to be modified
function Core.ToggleDebuffIcons(amount, _, elements)
    for i = 1, 3 do
        if i <= amount then
            Core.ToggleTransparency(elements.debuffs[i], true)
            if _G[elements.debuffs[i]] and not _G[elements.debuffs[i]]:IsMouseEnabled() and not HARFDB[Data.currentLayout].clickThroughBuffs then
                Core.ChangeFrameMouseInteraction(elements.buffs[i], true)
            end
        else
            Core.ToggleTransparency(elements.debuffs[i], false)
            if _G[elements.debuffs[i]] and _G[elements.debuffs[i]]:IsMouseEnabled() then
                Core.ChangeFrameMouseInteraction(elements.buffs[i], false)
            end
        end
    end
end

--Toggles frame transparency, true for enabled false for disabled, takes frameString to be modified
function Core.SetGroupFrameTransparency(value, frameString, _)
    if _G[frameString] then
        _G[frameString].background:SetIgnoreParentAlpha(not value)
    end
end

--Scale names, value for the new scale and element list to access the name
function Core.ScaleNames(value, _, elements)
    if _G[elements.name] then
        _G[elements.name]:SetScale(value)
    end
    if elements.customName then
        elements.customName:SetScale(value)
        local width = _G[elements.name]:GetWidth()
        if not issecretvalue(width) then
            elements.customName:SetWidth(width)
        end
    end
end

--Class coloring for names, value is true for class colored and false for defaults. takes frameString of the frame to modify and its elements
function Core.ColorNames(value, frameString, elements)
    if _G[frameString] and _G[frameString].unit then
        local frame = _G[frameString]
        local nameFrame = _G[elements.name]
        local customName
        if not elements.customName then
            customName = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
            local font, size, flags = frame.name:GetFont()
            customName:SetScale(nameFrame:GetScale())
            customName:SetFont(font, size, flags)
            customName:SetWordWrap(false)
            customName:SetWidth(nameFrame:GetWidth())
            if string.find(frameString, 'Raid') then
                customName:SetJustifyH('CENTER')
                customName:SetPoint('CENTER', nameFrame, 'CENTER')
            else
                customName:SetJustifyH('LEFT')
                customName:SetPoint('TOPLEFT', nameFrame, 'TOPLEFT')
            end
            elements.customName = customName
        else
            customName = elements.customName
        end
        customName:SetText(GetUnitName(frame.unit, true))
        local _, class = UnitClass(frame.unit)
        if class then
            local color = RAID_CLASS_COLORS[class]
            if color then
                customName:SetTextColor(color.r, color.g, color.b)
            end
        end
        if value then
            nameFrame:SetAlpha(0)
            customName:SetAlpha(1)
        else
            nameFrame:SetAlpha(1)
            customName:SetAlpha(0)
        end
    end
end

--Map out unitsIds to the frameString of their frame for buff tracking, also creates the icon
function Core.MapOutUnits(value, frameString, elements)
    if value and _G[frameString]then
        local unit = _G[frameString].unit
        if unit and HARFDB[Data.currentLayout].buffTracking then
            local frame = _G[frameString]
            Data.unitFrameMap[unit] = frameString
            if not elements.buffTrackingIcon then
                local buffIcon = CreateFrame('Frame', nil, UIParent)
                buffIcon:SetSize(25, 25)
                buffIcon:SetPoint('RIGHT', frame, 'RIGHT', -2, 0)
                buffIcon.texture = buffIcon:CreateTexture(nil, 'ARTWORK')
                buffIcon.texture:SetAllPoints()
                buffIcon.cooldown = CreateFrame('Cooldown', nil, buffIcon, 'CooldownFrameTemplate')
                buffIcon.cooldown:SetAllPoints()
                buffIcon.cooldown:SetReverse(true)
                buffIcon:Hide()
                buffIcon:SetScript('OnEvent', function(_, _, unitId, auraUpdateInfo)
                    Core.CheckAuraStatus(unitId, auraUpdateInfo)
                end)
                elements.buffTrackingIcon = buffIcon
            end
            elements.buffTrackingIcon:RegisterUnitEvent('UNIT_AURA', unit)
        elseif elements.buffTrackingIcon then
            elements.buffTrackingIcon:UnregisterAllEvents()
        end
    end
end

--Check aura status to see if the unit has the relevant buff
function Core.CheckAuraStatus(unit, updateInfo)
    local utilityTable = Data.supportedBuffTracking[Data.playerClass].utility
    local hasBuff = false
    local isPlayer = UnitIsUnit(unit, 'player')
    local trackedAura
    local currentTime = GetTime()
    --Check if the aura update time matches the timestamp of casting a filtered spell
    if Util.AreTimestampsEqual(currentTime, utilityTable.filteredSpellTimestamp) and updateInfo.addedAuras then
        for _, aura in ipairs(updateInfo.addedAuras) do
            --Check the auras added to see if any was applied by the player, if so we assume this aura was applied by a spell we don't want to track
            if C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, aura.auraInstanceID, 'PLAYER') then
                if not utilityTable.filteredBuffs[unit] then utilityTable.filteredBuffs[unit] = {} end
                utilityTable.filteredBuffs[unit][aura.auraInstanceID] = true
            end
        end
    end
    --If we already have a valid saved buff for this unit
    if utilityTable.activeAuras[unit] then
        hasBuff = true
        --Check the removed auras to make sure our auraInstanceID still exists
        if updateInfo.removedAuraInstanceIDs then
            for _, auraId in ipairs(updateInfo.removedAuraInstanceIDs) do
                --If our saved auraInstanceID was removed, clear the saved aura for this unit
                if utilityTable.activeAuras[unit] == auraId then
                    utilityTable.activeAuras[unit] = nil
                    hasBuff = false
                end
            end
        end
        --Check the updated auras to see if we need new info for our aura
        if updateInfo.updatedAuraInstanceIDs then
            for _, auraId in ipairs(updateInfo.updatedAuraInstanceIDs) do
                if auraId == utilityTable.activeAuras[unit] then
                    trackedAura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraId)
                    break
                end
            end
        end
    end
    --Shaman aura handling
    if Data.playerClass == 'SHAMAN' then
        --If this is the unit that we have saved as our earth shield, check if its still there
        if utilityTable.earthShield and unit == utilityTable.earthShield.unit then
            if updateInfo.removedAuraInstanceIDs then
                for _, auraId in ipairs(updateInfo.removedAuraInstanceIDs) do
                    --If our saved auraInstanceID was removed, clear the saved aura for this unit
                    if utilityTable.earthShield.aura == auraId then
                        utilityTable.earthShield = nil
                    end
                end
            end
        end
        if not utilityTable.activeAuras[unit] or not utilityTable.earthShield then
            local auras = C_UnitAuras.GetUnitAuras(unit, Data.buffFilter, 2, Enum.UnitAuraSortRule.ExpirationOnly)
            if #auras == 2 then --If the unit has two auras these have to be Earth Shield and Riptide
                hasBuff = true
                utilityTable.activeAuras[unit] = auras[1].auraInstanceID --We know the first aura is Riptide because of the sorting
                if not isPlayer then
                    utilityTable.earthShield = { unit = unit, aura = auras[2].auraInstanceID } --If the unit has two auras and is not the player, this is our second earth shield
                end
            --If the unit has one aura, is not the player nor the earth shield target, then this unit has Riptide
            elseif #auras == 1 and not isPlayer and (utilityTable.earthShield == nil or utilityTable.earthShield.unit ~= unit) then
                hasBuff = true
                trackedAura = auras[1]
                utilityTable.activeAuras[unit] = auras[1].auraInstanceID --Save the auraInstanceID for future checks on this unit
            end
        end
    --Evoker aura handling
    elseif Data.playerClass == 'EVOKER' then
        --If we don't have a valid saved aura for this unit, we check their buffs
        if not utilityTable.activeAuras[unit] then
            --Echo can be in any of the first three spots due to Dream Breath
            local auras = C_UnitAuras.GetUnitAuras(unit, Data.buffFilter, 3, Enum.UnitAuraSortRule.NameOnly)
            if #auras > 0 then
                for _, aura in ipairs(auras) do
                    if not Util.IsAuraOnUnitFilteredByList(aura.auraInstanceID, unit, utilityTable.filteredBuffs) then
                        hasBuff = true --If it isn't filtered, this is echo
                        trackedAura = aura
                        utilityTable.activeAuras[unit] = aura.auraInstanceID
                    end
                end
            end
        end
    --Priest aura handling
    elseif Data.playerClass == 'PRIEST' and utilityTable.isDisc then
        --If we don't have a valid saved aura for this unit, we check their buffs
        if not utilityTable.activeAuras[unit] then
            local auras = C_UnitAuras.GetUnitAuras(unit, Data.buffFilter, 1, Enum.UnitAuraSortRule.NameOnly)
            --Sorting means Atonement will be first, if the auraInstanceID isn't from one of our filtered casts then the unit has atonement
            if #auras == 1 and not Util.IsAuraOnUnitFilteredByList(auras[1].auraInstanceID, unit, utilityTable.filteredBuffs)  then
                hasBuff = true
                trackedAura = auras[1]
                utilityTable.activeAuras[unit] = auras[1].auraInstanceID
            end
        end
    end
    --We send the info we just found to the respective functions to display or hide
    if hasBuff then
        Util.DisplayTrackedBuff(unit, trackedAura)
    else
        Util.HideTrackedBuff(unit)
    end
end
