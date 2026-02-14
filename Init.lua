--Initialize tables
local _, NS = ...
NS.Data = {}
NS.Ui = {}
NS.Util = {}
NS.Core = {}
NS.Version = '2.0.0'

--Initialize saved variables
HARFDB = {} --HARFDB or {}
if HARFDB.version ~= NS.Version then
    HARFDB = {}
    HARFDB.version = NS.Version
end
if not HARFDB.options then HARFDB.options = {} end
if not HARFDB.savedIndicators then HARFDB.savedIndicators = {} end

print('|cnNORMAL_FONT_COLOR:AdvancedRaidFrames|r v' .. HARFDB.version .. ' by Harrek. use |cnNORMAL_FONT_COLOR:/harf|r to open the settings.')

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
-- remake the options, half of them do nothing now
-- add bar width/height depending
-- fix bar inverting and add extra anchor info
]]