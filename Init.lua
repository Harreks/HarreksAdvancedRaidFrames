--Initialize tables
local addonName, NS = ...
NS.Data = {}
NS.Ui = {}
NS.Util = {}
NS.Core = {}
NS.Debug = {}
NS.Version = C_AddOns.GetAddOnMetadata(addonName, 'Version')
NS.DevEnv = true

--Initialize saved variables
HARFDB = HARFDB or {}
if HARFDB.version ~= NS.Version then
    HARFDB.options.buffIcons = 'none'
    HARFDB.version = NS.Version
end
if not HARFDB.options then HARFDB.options = {} end
if not HARFDB.savedIndicators then HARFDB.savedIndicators = {} end
