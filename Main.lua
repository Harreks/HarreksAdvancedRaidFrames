------------------------------------------------------------------------------------------------[[
--- Advanced Raid Frames adds improved functionality to the default frames.
--- The goal is to improve what already exists while adding as little as possible.
--- Settings create their frames and set up their tracking only when needed to make sure
--- a disabled settings doesn't affect performance.
------------------------------------------------------------------------------------------------]]
local _, NS = ...
------------------------------------------------------------------------------------------------[[
--- Data contains default information and utility tables.
--- Here we define the options for a newly installed addon, handle some addon-wide
--- constants and also hold extra tables that we write to and read from during execution.
------------------------------------------------------------------------------------------------]]
local Data = NS.Data
------------------------------------------------------------------------------------------------[[
--- Util defines several utility functions that update and compare information across
--- the addon. Some are formatting functions called by LEM for display, some are special
--- comparisons to match timestamps, and some are called to wipe tables to help performance.
------------------------------------------------------------------------------------------------]]
local Util = NS.Util
------------------------------------------------------------------------------------------------[[
--- Core has the business logic. The main functionality of each setting is defined here.
--- These functions are called directly when their related setting is changed, or in the
--- case of `CheckAuraStatus` when a relevant unit fires a UNIT_AURA event if buff tracking
--- is enabled.
------------------------------------------------------------------------------------------------]]
local Core = NS.Core
------------------------------------------------------------------------------------------------[[
--- Settings has the data about the settings and binds them to LibEditMode.
--- It creates the three main frames the addon uses: ClickableOptionsFrame, SpotlightFrame,
--- and EventTracker. ClickableOptionsFrame carries the option controls, SpotlightFrame has
--- the settings for the spotlight and controls its anchor, the EventTracker sets up all
--- the options on PLAYER_LOGIN, refreshes the settings on GROUP_ROSTER_UPDATE to make sure
--- data matches the current group, and checks UNIT_SPELLCAST_SUCCEEDED to assist with
--- buff tracking if the setting is enabled.
------------------------------------------------------------------------------------------------]]
local Settings = NS.Settings
------------------------------------------------------------------------------------------------[[
--- Main is the last file to be loaded, by this point all the data is ready
--- (including the saved variables due to `LoadSavedVariablesFirst: 1`)
--- and the only thing left is to bind PLAYER_LOGIN and GROUP_ROSTER_UPDATE to
--- the EventTracker so it can initialize the addon on login and keep the settings
--- properly applied when the group changes.
------------------------------------------------------------------------------------------------]]
for _, event in ipairs(Data.trackedEvents.general) do
    Settings.eventTracker:RegisterEvent(event)
end
for _, event in ipairs(Data.trackedEvents.player) do
    Settings.eventTracker:RegisterUnitEvent(event, 'player')
end