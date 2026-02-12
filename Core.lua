local _, NS = ...
local Data = NS.Data
local Util = NS.Util
local Core = NS.Core
local Opt = NS.Opt

--Toggles mouse interaction on raid frame icons, pass true for enabled and false for disabled, third param is the elements of the edited frame
function Core.ToggleAurasMouseInteraction(value, _, elements)
    for _, buff in ipairs(elements.buffs) do
        Util.ChangeFrameMouseInteraction(buff, value)
    end
    for _, debuff in ipairs(elements.debuffs) do
        Util.ChangeFrameMouseInteraction(debuff, value)
    end
    Util.ChangeFrameMouseInteraction(elements.centerIcon, value)
    Util.ChangeFrameMouseInteraction(elements.defensive, value)
end

--Controls visibility on buff icons, takes how many buffs are to be shown and the element list of the frame to be modified
function Core.ToggleBuffIcons(amount, _, elements)
    for i = 1, 6 do
        if i <= amount then
            Util.ToggleTransparency(elements.buffs[i], true)
            if _G[elements.buffs[i]] and not _G[elements.buffs[i]]:IsMouseEnabled() and not HARFDB.clickThroughBuffs then
                Util.ChangeFrameMouseInteraction(elements.buffs[i], true)
            end
        else
            Util.ToggleTransparency(elements.buffs[i], false)
            if _G[elements.buffs[i]] and _G[elements.buffs[i]]:IsMouseEnabled() then
                Util.ChangeFrameMouseInteraction(elements.buffs[i], false)
            end
        end
    end
end

--Controls visibility on debuff icons, takes how many debuffs are to be shown and the element list of the frame to be modified
function Core.ToggleDebuffIcons(amount, _, elements)
    for i = 1, 3 do
        if i <= amount then
            Util.ToggleTransparency(elements.debuffs[i], true)
            if _G[elements.debuffs[i]] and not _G[elements.debuffs[i]]:IsMouseEnabled() and not HARFDB.clickThroughBuffs then
                Util.ChangeFrameMouseInteraction(elements.buffs[i], true)
            end
        else
            Util.ToggleTransparency(elements.debuffs[i], false)
            if _G[elements.debuffs[i]] and _G[elements.debuffs[i]]:IsMouseEnabled() then
                Util.ChangeFrameMouseInteraction(elements.buffs[i], false)
            end
        end
    end
end

--Toggles frame transparency, true for enabled false for disabled, takes frameString to be modified
function Core.SetGroupFrameTransparency(value, _, elements)
    if _G[elements.frame] then
        _G[elements.frame].background:SetIgnoreParentAlpha(not value)
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
function Core.ColorNames(value, unit, elements)
    if _G[elements.frame] and _G[elements.frame].unit then
        local frame = _G[elements.frame]
        local nameFrame = _G[elements.name]
        local customName
        if not elements.customName then
            customName = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
            local font, size, flags = nameFrame:GetFont()
            customName:SetScale(nameFrame:GetScale())
            customName:SetFont(font, size, flags)
            customName:SetWordWrap(false)
            customName:SetWidth(nameFrame:GetWidth())
            if string.find(elements.frame, 'Raid') then
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
        customName:SetText(GetUnitName(unit, true))
        local _, class = UnitClass(unit)
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

function Core.ParseEvokerBuffs(unit, updateInfo)
    local utilityTable = Data.supportedBuffTracking.EVOKER.utility
    local hasBuff = false
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
                    break
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
        --If we have a saved buff still and it wasn't updated, get the info from it or delete it if its invalid
        if hasBuff and not trackedAura then
            trackedAura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, utilityTable.activeAuras[unit])
            if not trackedAura then
                hasBuff = false
                utilityTable.activeAuras[unit] = nil
            end
        end
    end
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
                    break
                end
            end
        end
    end
    --We return the info we just found
    return hasBuff, trackedAura
end

function Core.ParseShamanBuffs(unit, updateInfo)
    local utilityTable = Data.supportedBuffTracking.SHAMAN.utility
    local hasBuff = false
    local isPlayer = UnitIsUnit(unit, 'player')
    local isEarthShield = false
    local trackedAura
    if utilityTable.earthShield and unit == utilityTable.earthShield.unit then
        isEarthShield = true
    end
    --If we already have a valid saved buff for this unit or this unit is our earth shield
    if utilityTable.activeAuras[unit] or isEarthShield then
        hasBuff = utilityTable.activeAuras[unit] ~= nil --True if the buff exists
        --Check the removed auras to make sure our auras still exist
        if updateInfo.removedAuraInstanceIDs then
            for _, auraId in ipairs(updateInfo.removedAuraInstanceIDs) do
                --If our saved auraInstanceID was removed, clear the saved aura for this unit
                if utilityTable.activeAuras[unit] == auraId then
                    utilityTable.activeAuras[unit] = nil
                    hasBuff = false
                end
                --If our saved earth shield was removed, clear the info
                if isEarthShield and utilityTable.earthShield.aura == auraId then
                    utilityTable.earthShield = nil
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
        --If we have a saved buff still and it wasn't updated, get the info from it or delete it if its invalid
        if hasBuff and not trackedAura then
            trackedAura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, utilityTable.activeAuras[unit])
            if not trackedAura then
                hasBuff = false
                utilityTable.activeAuras[unit] = nil
            end
        end
    end
    if not utilityTable.activeAuras[unit] or not utilityTable.earthShield then
        local auras = C_UnitAuras.GetUnitAuras(unit, Data.buffFilter, 2, Enum.UnitAuraSortRule.ExpirationOnly)
        if #auras == 2 then --If the unit has two auras these have to be Earth Shield and Riptide
            hasBuff = true
            trackedAura = auras[1]
            utilityTable.activeAuras[unit] = auras[1].auraInstanceID --We know the first aura is Riptide because of the sorting
            if not isPlayer then
                utilityTable.earthShield = { unit = unit, aura = auras[2].auraInstanceID } --If the unit has two auras and is not the player, this is our second earth shield
            end
        --If the unit has one aura, is not the player nor the earth shield target, then this unit has Riptide
        elseif #auras == 1 and not isPlayer and not isEarthShield then
            hasBuff = true
            trackedAura = auras[1]
            utilityTable.activeAuras[unit] = auras[1].auraInstanceID --Save the auraInstanceID for future checks on this unit
        end
    end
    --We return the info we just found
    return hasBuff, trackedAura
end

function Core.ParsePriestBuffs(unit, updateInfo)
    local utilityTable = Data.supportedBuffTracking.PRIEST.utility
    local hasBuff = false
    local trackedAura
    local currentTime = GetTime()
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
                    break
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
        --If we have a saved buff still and it wasn't updated, get the info from it or delete it if its invalid
        if hasBuff and not trackedAura then
            trackedAura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, utilityTable.activeAuras[unit])
            if not trackedAura then
                hasBuff = false
                utilityTable.activeAuras[unit] = nil
            end
        end
    end
    --For priest we check if a spell was casted recently to detect atonements, even if we already currently have a buff
    if updateInfo.addedAuras and Util.AreTimestampsEqual(currentTime, utilityTable.filteredSpellTimestamp) then
        local auras = C_UnitAuras.GetUnitAuras(unit, Data.buffFilter, 1, Enum.UnitAuraSortRule.NameOnly)
        --Sorting means Atonement will be first
        if #auras == 1 then
            for _, aura in ipairs(updateInfo.addedAuras) do
                --If one of the added auras matches, this is the atonement
                if aura.auraInstanceID == auras[1].auraInstanceID then
                    hasBuff = true
                    trackedAura = aura
                    utilityTable.activeAuras[unit] = aura.auraInstanceID
                end
            end
        end
    end
    --We return the info we just found
    return hasBuff, trackedAura
end

--Check aura status to see if the unit has the relevant buff
function Core.CheckAuraStatus(unit, updateInfo)
    if not updateInfo then updateInfo = {} end
    local hasBuff, trackedAura = false, nil
    if Data.playerClass == 'EVOKER' then
        hasBuff, trackedAura = Core.ParseEvokerBuffs(unit, updateInfo)
    elseif Data.playerClass == 'SHAMAN' then
        hasBuff, trackedAura = Core.ParseShamanBuffs(unit, updateInfo)
    elseif Data.playerClass == 'PRIEST' then
        hasBuff, trackedAura = Core.ParsePriestBuffs(unit, updateInfo)
    end
    if hasBuff then
        Util.DisplayTrackedBuff(unit, trackedAura)
    else
        Util.HideTrackedBuff(unit)
    end
    return hasBuff, trackedAura
end
