local _, NS = ...

local activeLocale = GetLocale and GetLocale() or 'enUS'
local L = NS.L or {}
NS.L = L

setmetatable(L, {
    __index = function(_, key)
        return key
    end
})

function NS.GetLocaleTable(locale, isDefault)
    if isDefault or locale == activeLocale then
        return L
    end
    return nil
end

NS.ActiveLocale = activeLocale

L.MENU_CATEGORY_ADDON = 'Advanced Raid Frames'
L.MENU_CATEGORY_DEFAULT_FRAMES = 'Default Frames'
L.MENU_CATEGORY_DESIGNER = 'Designer'
L.MENU_CATEGORY_OTHER_FRAMES = 'Other Frames'

L.MENU_INTRO_TITLE_FMT = 'Advanced Raid Frames v%s'
L.MENU_INTRO_BODY = 'Advanced Raid Frames is my attempt at giving healers the tools they need to properly play the game, while this is not a perfect solution i am working very hard trying to make it the best it can possibly be so we can all enjoy the game like we are used to.\n\nThe method used can be a bit finnicky in some situations but improvements are constantly being made. If you find any bug or have any questions please contact me so we can talk about it, i am excited to hear what you think.\n\n-Harrek'

L.MENU_BUTTON_PATREON = 'Patreon'
L.MENU_BUTTON_DISCORD = 'Discord'
L.MENU_BUTTON_KOFI = 'Ko-fi'

L.MENU_POPUP_PATREON_TITLE = 'Harrek\'s Patreon'
L.MENU_POPUP_DISCORD_TITLE = 'Spiritbloom.Pro Discord'
L.MENU_POPUP_KOFI_TITLE = 'Buy me a Coffee'

L.MENU_UTILITIES_HEADER = 'Utilities'
L.MENU_UTILITIES_DESC = 'Use these tools to profile aura processing, inspect runtime metrics in chat, and reset addon data when testing. Data reset requires confirmation and reloads the UI.'
L.MENU_BUTTON_TOGGLE_PROFILING = 'Toggle Profiling'
L.MENU_BUTTON_PRINT_PROFILING = 'Print Profile Stats'
L.MENU_BUTTON_RESET_PROFILING = 'Reset Profile Stats'
L.MENU_BUTTON_RESET_DATA = 'Reset Addon Data'
