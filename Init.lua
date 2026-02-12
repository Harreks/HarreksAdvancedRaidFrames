local _, NS = ...
HARFDB = HARFDB or {}
NS.Data = {}
NS.Util = {}
NS.Core = {}
NS.Opt = {}

--Version-specific handling of saved vars
if HARFDB.version ~= '1.1.1' then
    HARFDB.version = "1.1.1"
end

print('AdvancedRaidFrames v.' .. HARFDB.version .. ' by Harrek.')