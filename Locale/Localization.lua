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

L.OPTION_CLICK_THROUGH_AURAS = 'Click Through Aura Icons'
L.OPTION_CLICK_THROUGH_AURAS_TOOLTIP = 'Disables mouse interaction on the aura icons on the frame, letting you mouseover and click through them.'
L.OPTION_BUFF_ICONS = 'Buff Icons'
L.OPTION_BUFF_ICONS_TOOLTIP = 'Changes the maximum amount of buff icons on the default frames.'
L.OPTION_DEBUFF_ICONS = 'Debuff Icons'
L.OPTION_DEBUFF_ICONS_TOOLTIP = 'Changes the maximum amount of debuff icons on the default frames.'
L.OPTION_FRAME_TRANSPARENCY = 'Frame Transparency'
L.OPTION_FRAME_TRANSPARENCY_TOOLTIP = 'Disabling frame transparency keeps the frame fully solid even when out of range.'
L.OPTION_NAME_SIZE = 'Name Size'
L.OPTION_NAME_SIZE_TOOLTIP = 'Changes the size of the unit names.'
L.OPTION_CLASS_COLORED_NAMES = 'Class Colored Names'
L.OPTION_CLASS_COLORED_NAMES_TOOLTIP = 'Replaces the unit name for class-colored ones.'
L.OPTION_MISC_HEADER = 'Misc.'
L.OPTION_SHOW_MINIMAP_ICON = 'Show Minimap Icon'
L.OPTION_SHOW_MINIMAP_ICON_TOOLTIP = 'Shows or hides the minimap icon for the addon.'

L.INDICATOR_TYPE_ICON = 'Icon'
L.INDICATOR_TYPE_SQUARE = 'Square'
L.INDICATOR_TYPE_BAR = 'Bar'
L.INDICATOR_TYPE_BORDER = 'Border'

L.SPOTLIGHT_SETTINGS_HEADER = 'Spotlight'
L.SPOTLIGHT_SETTINGS_DESC = 'Spotlight helps you pick exact raid members to prioritize, mainly for Augmentation Evoker support buffs like Prescience. Player List fills in raid only, and selected names stay saved.'
L.SPOTLIGHT_SETTINGS_BUTTON_TITLE = 'Edit Spotlight Anchor'
L.SPOTLIGHT_SETTINGS_BUTTON = 'Open Spotlight in Edit Mode'
L.SPOTLIGHT_SETTINGS_BUTTON_TOOLTIP = 'Open Edit Mode and jump to the Spotlight anchor to move it. Use Player List to choose specific raid members (useful for Aug Evoker buffs like Prescience). Spotlight works with Blizzard default raid frames only.'

L.DESIGNER_DUPLICATE_INDICATOR = 'Clone Indicator'
L.DESIGNER_IMPORT_EXPORT_HEADER = 'Import / Export'
L.DESIGNER_EXPORT_SPEC_INDICATORS = 'Export Spec Indicators'
L.DESIGNER_IMPORT_SPEC_INDICATORS = 'Import Spec Indicators'
L.DESIGNER_EXPORT_POPUP_TITLE_FMT = 'Export (%s)'
L.DESIGNER_IMPORT_POPUP_TITLE_FMT = 'Import (%s)'
L.DESIGNER_IMPORT_POPUP_TEXT = 'Paste the import string for this spec.'
L.DESIGNER_IMPORT_CONFIRM = 'Import'
L.DESIGNER_IMPORT_EXPORT_UNSUPPORTED = 'Import/export is not supported on this client version.'
L.DESIGNER_EXPORT_FAILED = 'Failed to export indicators.'
L.DESIGNER_IMPORT_EMPTY = 'Paste an import string first.'
L.DESIGNER_IMPORT_INVALID = 'Invalid import string.'
L.DESIGNER_IMPORT_NO_VALID = 'Import contained no valid indicators for this spec.'
L.DESIGNER_IMPORT_SPEC_MISMATCH_FMT = 'Import is for a different spec. Switch to %s before importing.'
L.DESIGNER_IMPORT_SUCCESS_FMT = 'Imported %d indicators.'
L.DESIGNER_IMPORT_PARTIAL_FMT = 'Imported %d of %d indicators (%d skipped as invalid).'
L.DESIGNER_PREVIEW_FADE_OTHER_INDICATORS = 'Fade unselected indicators'
L.DESIGNER_APPEARANCE_SECTION = 'Appearance'
L.DESIGNER_COOLDOWN_SECTION = 'Cooldown'
L.DESIGNER_DELETE_CONFIRM_TEXT = 'Delete this indicator?'
L.LABEL_ECHOED_PREFIX = 'Echoed'
L.LABEL_ECHOED_SPELL_FMT = 'Echoed %s'
