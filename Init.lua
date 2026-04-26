--Initialize tables
local addonName, NS = ...
NS.Data = {}
NS.Ui = {}
NS.Util = {}
NS.Core = {}
NS.Debug = {}
NS.Version = C_AddOns.GetAddOnMetadata(addonName, 'Version')
NS.DevEnv = false

HARFDB = HARFDB or {}

if not HARFDB.options then 
    HARFDB.options = {} 
end
if not HARFDB.savedIndicators then 
    HARFDB.savedIndicators = {} 
end

if HARFDB.version ~= NS.Version then
    HARFDB.options.buffIcons = true
    HARFDB.version = NS.Version
end
