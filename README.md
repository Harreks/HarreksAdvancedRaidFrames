# Introduction

Implement improvements and extra functionality to Blizzard's party and raid frames. The goal is to integrate with as little footprint as possible, reusing existing elements when available and doing most set up work outside of combat.

# Functionality

- Click-through Aura Icons: Removes mouse interaction from most elements on the frames, letting targeting work through them and removing the tooltips.
- Buff and Debuff icon amounts: While still limited to a maximum of 6 buffs and 3 debuffs, you can reduce them even more if desired.
- Frame Transparency: disables transparency effects on the frames to they remain fully solid when units are out of range.
- Name Size: Controls the scale of the player names on the frames.
- Class Colored Names: Colors the player names according to their class.
- Spotlight: Move the raid frames of selected units into a separate group with positioning.
- Buff Tracking (Experimental): Track one specific buff relevant to your spec, either by showing an icon in a separate spot for only that buff or by recoloring the frame when the buff is present. Currently supports Atonement, Riptide and Echo.

# Planned Upgrades

- Buff Tracking Icon Customization: Implement more options to position and size the buff track icon.
- Overshields: Show shields that go above the unit's max health on the frame
- Spotlight Customization: More options to customize the spotlight

# Known Bugs

- Buff tracking is experimental and relies on assumptions and logic, as such it might sometimes trigger false positives or false negatives. It's accuracy is being actively worked on and more specs might be added when the environment allows it. For details on the implementation check [here](https://spiritbloom.pro/blog/tracking-buffs-in-midnight).
- The spotlight doesn't work correctly with the "Display Main Tank and Assist" option. It breaks the flow of the default raid frame. This will be fixed in a future release.
- The list of players in the raid to select your spotlights doesn't refresh in real time and can cause some bugs. This will be fixed in a future release.

# Known Limitations

- Riptide tracking for Restoration Shaman can produce false positives on your external Earth Shield when freshly applied. Once the unit with your Earth Shield also has Riptide applied to them at the same time the tracking will be accurate from that point forwards until the Earth Shield is moved to another target.
- Echo tracking for Preservation is fairly delicate. Spellqueueing certain spells (Reversion, Merithra's Blessing, Zephyr, Time Dilation) off Temporal Anomaly might cause false negatives as the addon believes the echoes applied by TA are instead buffs applied by the other spells that should not be shown.
- Atonement tracking can produce false positives on units that get a Power Word: Shield applied to them from Unfolding Vision
- The player can't be part of the spotlight group