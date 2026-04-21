local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local Debug = NS.Debug
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

--Controls visibility on buff icons, takes how many buffs are to be shown and the element list of the frame to be modified
function Core.ToggleBuffIcons(amount, unit, elements)
end

--Controls visibility on debuff icons, takes how many debuffs are to be shown and the element list of the frame to be modified
function Core.ToggleDebuffIcons(amount, _, elements)

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
end

--Class coloring for names, value is true for class colored and false for defaults. takes frameString of the frame to modify and its elements
function Core.ColorNames(value, unit, elements)
    if _G[elements.name] then
        local nameFrame = _G[elements.name]
        if nameFrame and value then
            local _, class = UnitClass(unit)
            if class then
                local color = RAID_CLASS_COLORS[class]
                if color then
                    nameFrame:SetTextColor(color.r, color.g, color.b)
                end
            end
        end
    end
end

--This setting is a bit wonky because enabling or disabling doesn't alter the textures immediately
--Enabling the check enables the dropdown which changes the texture when an option is picked
--And disabling the check means the texture replacement is never ran so it doesn't interfere with other addons
--But this setting could be expanded to make it work in real time. Tho i don't expect it to be a huge problem
function Core.EnableBarTexture(value, _, elements)
end

--Sets the texture on the default frames' health bars
function Core.SetBarTexture(value, _, elements)
    if Options.barTextureEnabled then
        if _G[elements.frame] and _G[elements.frame].healthBar then
            local healthBar = _G[elements.frame].healthBar
            local texture = Data.barTextures[value]
            if texture.type == 'T' then
                healthBar:GetStatusBarTexture():SetTexture(texture.path)
            else
                healthBar:GetStatusBarTexture():SetAtlas(texture.path)
            end
        end
    end
end

function Core.ShowOvershields(value, unit, elements)
    if value then
        if not elements.overshield then
            local frame = _G[elements.frame]
            if frame and frame.healthBar then
                local overshield = CreateFrame('StatusBar', nil, frame)
                overshield:SetAlpha(0.8)
                overshield:SetAllPoints(frame.healthBar)
                overshield:SetFrameLevel(frame.healthBar:GetFrameLevel())
                overshield:SetReverseFill(true)
                Util.SetStatusbarTextureOrAtlas(overshield, Data.barTextures[Options.overshieldsTexture])

                local overshieldTexture = overshield:GetStatusBarTexture()
                overshieldTexture:SetDrawLayer("BORDER")

                local mask = overshield:CreateMaskTexture()
                mask:SetTexture("Interface/TargetingFrame/UI-StatusBar", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                mask:SetAllPoints(frame.healthBar:GetStatusBarTexture())
                overshieldTexture:AddMaskTexture(mask)

                elements.overshield = overshield
            end
        end
        if elements.overshield then
            elements.overshield:Show()
            elements.tracker:RegisterUnitEvent('UNIT_ABSORB_AMOUNT_CHANGED', unit)
            Util.UpdateOvershields(unit)
        end
    else
        if elements.overshield then
            elements.overshield:Hide()
        end
        elements.tracker:UnregisterEvent('UNIT_ABSORB_AMOUNT_CHANGED')
    end
end

function Core.OvershieldsTexture(value, _, elements)
    if elements.overshield and Data.barTextures[value] then
        Util.SetStatusbarTextureOrAtlas(elements.overshield, Data.barTextures[value])
    end
end

function Core.ToggleRoleIcon(value, _, elements)
    if _G[elements.roleIcon] then
        _G[elements.roleIcon]:SetAlpha(value and 1 or 0)
    end
end

function Core.ToggleGroupTitles(value)
    for i = 1, 8 do
        local titleText = _G['CompactRaidGroup' .. i .. 'Title']
        if titleText then
            titleText:SetAlpha(value and 1 or 0)
        end
    end
end

function Core.ScaleRaidFrameContainer(value)
    local container = _G['CompactRaidFrameContainer']
    if container and value then
        container:SetScale(value)
    end
end

function Core.TargetedSpells(value)
    Util.ToggleEnemyCastTrackingEvents(value)
    if value then
        if not Core.TargetedSpellsCleaner then
            Core.TargetedSpellsCleaner = C_Timer.NewTicker(1, Util.CleanupTargetedSpellsIcons)
        end
        C_CVar.SetCVar('softTargetFriend', 3) --Enable friendly action targeting
    else
        if Core.TargetedSpellsCleaner then
            Core.TargetedSpellsCleaner:Cancel()
            Core.TargetedSpellsCleaner = nil
        end
    end
end

function Core.ModifySettings(newValue, functionArgs)
    local timeSinceLastModify = GetTime() - Data.lastModify
    if timeSinceLastModify > 0.1 and not InCombatLockdown() then
        Data.lastModify = GetTime()
        local unitList = Data.unitList
        local functionsToRun = {}
        local modifiedSettingFunction = functionArgs and functionArgs.functionToRun
        if modifiedSettingFunction and type(Core[modifiedSettingFunction]) == 'function' then
            table.insert(functionsToRun, { func = Core[modifiedSettingFunction], val = newValue } )
        else
            for _, option in ipairs(Data.settings) do
                if option.key and option.func and Core[option.func] then
                    table.insert(functionsToRun, { func = Core[option.func], val = Options[option.key] })
                end
                if option.ddKey and option.ddFunc and Core[option.ddFunc] then
                    table.insert(functionsToRun, { func = Core[option.ddFunc], val = Options[option.ddKey] })
                end
            end
        end

        Util.MapOutUnits()

        for unit, elements in pairs(unitList) do
            for _, functionData in ipairs(functionsToRun) do
                functionData.func(functionData.val, unit, elements)
            end
        end

        if Util.IsSpotlightActive() and Options.spotlight.names then
            Util.UpdateSpotlightFrames()
        end
    end
end