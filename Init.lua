--Initialize tables
local addonName, NS = ...
NS.Data = {}
NS.Ui = {}
NS.Util = {}
NS.Core = {}
NS.Debug = {}
NS.Version = C_AddOns.GetAddOnMetadata(addonName, 'Version')

--Initialize saved variables
HARFDB = HARFDB or {}
if HARFDB.version ~= NS.Version then
    HARFDB.version = NS.Version
    if HARFDB.savedIndicators then
        HARFDB.savedIndicators = {}
        print('|cnNORMAL_FONT_COLOR:AdvancedRaidFrames:|r Due to sweeping API changes in 12.1, all your indicators have been deleted. Sorry.')
    end
end
if not HARFDB.options then HARFDB.options = {} end
if not HARFDB.savedIndicators then HARFDB.savedIndicators = {} end
