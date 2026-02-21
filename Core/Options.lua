local _, NS = ...
local Data = NS.Data
local Ui = NS.Ui
local Util = NS.Util
local Core = NS.Core
local API = NS.API
local SavedIndicators = HARFDB.savedIndicators
local Options = HARFDB.options

local function Print(message)
    print('|cnNORMAL_FONT_COLOR:AdvancedRaidFrames|r: ' .. message)
end

local function ResetAddonDataAndReload()
    if not HARFDB then
        return
    end

    HARFDB.options = HARFDB.options or {}
    HARFDB.savedIndicators = HARFDB.savedIndicators or {}

    wipe(HARFDB.options)
    wipe(HARFDB.savedIndicators)
    HARFDB.debugProfile = { enabled = false, stats = {} }
    HARFDB.version = NS.Version

    Print('Addon data reset. Reloading UI...')
    ReloadUI()
end

StaticPopupDialogs['HARF_CONFIRM_RESET_DB'] = {
    text = 'Reset Advanced Raid Frames data? This will clear options and saved indicators.',
    button1 = ACCEPT,
    button2 = CANCEL,
    OnAccept = function()
        ResetAddonDataAndReload()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function Core.ToggleMinimapIcon(value, _, _)
    local LibDBIcon = LibStub('LibDBIcon-1.0')
    if value then
        LibDBIcon:Show('HARF')
    else
        LibDBIcon:Hide('HARF')
    end
end

function Core.ToggleProfiling()
    local currentlyEnabled = Util.IsProfileEnabled()
    Util.SetProfileEnabled(not currentlyEnabled)
    if currentlyEnabled then
        Print('Profiling disabled.')
    else
        Print('Profiling enabled.')
    end
end

function Core.PrintProfilingStats()
    if not Util.IsProfileEnabled() then
        Print('Profiling is disabled. Enable it first to collect fresh metrics.')
    end
    Util.PrintProfileStats()
end

function Core.ResetProfilingStats()
    Util.ResetProfileStats()
    Print('Profiling stats reset.')
end

function Core.ConfirmResetDatabase()
    if InCombatLockdown() then
        Print('Cannot reset data in combat.')
        return
    end
    StaticPopup_Show('HARF_CONFIRM_RESET_DB')
end

--Controls visibility on buff icons, takes how many buffs are to be shown and the element list of the frame to be modified
function Core.ToggleBuffIcons(amount, _, elements)
    for i = 1, 6 do
        if i <= amount then
            Util.ToggleTransparency(elements.buffs[i], true)
            if _G[elements.buffs[i]] and not _G[elements.buffs[i]]:IsMouseEnabled() and not Options.clickThroughBuffs then
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

--Controls visibility on debuff icons, takes how many debuffs are to be shown and the element list of the frame to be modified
function Core.ToggleDebuffIcons(amount, _, elements)
    for i = 1, 3 do
        if i <= amount then
            Util.ToggleTransparency(elements.debuffs[i], true)
            if _G[elements.debuffs[i]] and not _G[elements.debuffs[i]]:IsMouseEnabled() and not Options.clickThroughBuffs then
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
            if _G[elements.name] then
            local width = _G[elements.name]:GetWidth()
            if not issecretvalue(width) then
                elements.customName:SetWidth(width)
            end
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

function Core.ModifySettings(modifiedSettingFunction, newValue)
    if not InCombatLockdown() then
        local unitList = Util.GetRelevantList()
        local functionsToRun = {}
        if modifiedSettingFunction and type(Core[modifiedSettingFunction]) == 'function' then
            table.insert(functionsToRun, { func = Core[modifiedSettingFunction], val = newValue } )
        else
            table.insert(functionsToRun, { func = Core.ToggleBuffIcons, val = Options.buffIcons } )
            table.insert(functionsToRun, { func = Core.ToggleDebuffIcons, val = Options.debuffIcons } )
            table.insert(functionsToRun, { func = Core.ToggleAurasMouseInteraction, val = not Options.clickThroughBuffs } )
            table.insert(functionsToRun, { func = Core.SetGroupFrameTransparency, val = Options.frameTransparency } )
            table.insert(functionsToRun, { func = Core.ScaleNames, val = Options.nameScale } )
            table.insert(functionsToRun, { func = Core.ColorNames, val = Options.colorNames } )

            Util.MapOutUnits()
        end

        for unit, elements in pairs(unitList) do
            for _, functionData in ipairs(functionsToRun) do
                functionData.func(functionData.val, unit, elements)
            end
        end

        if IsInRaid() and Options.spotlight.names then
            Util.MapSpotlightAnchors()
            Util.ReanchorSpotlights()
        end
    end
end