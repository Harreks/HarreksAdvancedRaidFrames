[![Patreon](https://i.imgur.com/VHOsqDj.png)](https://www.patreon.com/harrek) [![Discord](https://i.imgur.com/iUrRmiw.png)](https://discord.gg/MMjNrUTxQe)

# Introduction

Implementing improvements to the default frames and advanced functionality to all frames. The goal is to integrate with as little footprint as possible, reusing existing elements when available and doing most set up work outside of combat. Working alongside popular frame addons to improve them when possible.

# Functionality

- Click-through Aura Icons: Removes mouse interaction from most elements on the default frames, letting targeting work through them and removing the tooltips.
- Buff and Debuff icon amounts: While still limited to a maximum of 6 buffs and 3 debuffs, you can reduce them even more if desired.
- Frame Transparency: disables transparency effects on the default frames to they remain fully solid when units are out of range.
- Name Size: Controls the scale of the player names on the default frames.
- Class Colored Names: Colors the player names according to their class.
- Spotlight: Move the raid frames of selected units into a separate group with custom positioning.
- Buff Tracking: Track one specific buff relevant to your spec with different display methods. Currently supports Atonement, Riptide and Echo.
- DandersFrames Compatibility: Display the tracking on the addon frames.
- Grid2 Compatibility: The addon implements its own "HealerBuff" custom status as a plugin.

# Planned Upgrades

- Overshields: Show shields that go above the unit's max health on the default frames.
- Spotlight Groupings: Separate the spotlight in several rows or columns.
- Restoration Druid and Augmentation Evoker tracking in the works. Holy Paladin and Holy Priest tracking will be explored in the future.
- ElvUI frames tracking is being looked into.

# Known Bugs

- Buff tracking relies on assumptions and logic, as such it might sometimes trigger false positives or false negatives. It's accuracy is being actively worked on and more specs might be added when the environment allows it. For details on the implementation check [here](https://spiritbloom.pro/blog/tracking-buffs-in-midnight).
- The spotlight doesn't work correctly with the "Display Main Tank and Assist" option. It breaks the flow of the default raid frame. This will be fixed in a future release.
- Some times unit that are in a different instance or very far away might get stuck on a false positive state for buff tracking. This is being actively worked on.

# Known Limitations

- Riptide tracking for Restoration Shaman can produce false positives on your external Earth Shield when freshly applied. Once the unit with your Earth Shield also has Riptide applied to them at the same time the tracking will be accurate from that point forwards until the Earth Shield is moved to another target.
- Echo tracking for Preservation can be fairly delicate. Spellqueueing Reversion or Time Dilation off Temporal Anomaly might cause false negatives as the addon believes the echoes applied by TA are instead buffs applied by the other spells that should not be shown.
- The player can't be part of the spotlight group