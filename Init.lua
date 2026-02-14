--Initialize tables
local _, NS = ...
NS.Data = {}
NS.Ui = {}
NS.Util = {}
NS.Core = {}
NS.Version = '2.0.0'
NS.Alpha = true

--Initialize saved variables
HARFDB = HARFDB or {}
if not HARFDB.options then HARFDB.options = {} end
if not HARFDB.savedIndicators then HARFDB.savedIndicators = {} end

--Version-specific handling of saved vars
if HARFDB.version ~= NS.Version then
    HARFDB.version = NS.Version
end

print('|cnNORMAL_FONT_COLOR:AdvancedRaidFrames|r v' .. HARFDB.version .. ' by Harrek. use |cnNORMAL_FONT_COLOR:/harf|r to open the settings.')

if NS.Alpha then
    print('|cnPURE_RED_COLOR:This is an alpha version. Bugs are very likely. Please don\'t share it.|r')
end

--[[
TODO:
-- IndicatorOverlays don't refresh when settings change (trigger re-map on every setting change?)
-- shaman earth shield is not showing on player
-- test other specs
-- write api
-- fix grid2 plugin
-- fix danders compat ( write api > just register the danders frames with it)
-- dm Vuhdo dev
-- find who to talk for the cell dev?
-- look into frame recolor
-- recheck all my code to delete old functions
-- dont forget to clear saved vars if version missmatch before releasing
-- rework main.lua (find new way of startup?)
-- write faq
]]