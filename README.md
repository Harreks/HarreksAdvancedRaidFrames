# Introduction

Implement improvements and extra functionality to Blizzard's party and raid frames. The goal is to integrate with as little footprint as possible, reusing existing elements when available and doing most set up work outside of combat.

**The buff tracking currently only works on beta due to certain filters not being implemented on live yet, it is still an experimental feature**

# Functionality

- Click-through Aura Icons: Removes mouse interaction from most elements on the frames, letting targeting work through them and removing the tooltips.
- Buff and Debuff icon amounts: While still limited to a maximum of 6 buffs and 3 debuffs, you can reduce them even more if desired.
- Frame Transparency: disables transparency effects on the frames to they remain fully solid when units are out of range.
- Name Size: Controls the scale of the player names on the frames.
- Class Colored Names: Colors the player names according to their class.
- Buff Tracking (Experimental): Track one specific buff relevant to your spec, either by showing an icon in a separate spot for only that buff or by recoloring the frame when the buff is present. Currently supports Atonement, Riptide and Echo.

# Planned Upgrades

- Spotlight: Move the raid frames of selected units into a separate group with custom scaling an positioning.
- Buff Tracking Icon Customization: Implement more options to position and size the buff track icon.
- Overshields: Show shields that go above the unit's max health on the frame

# Known Bugs

- Buff tracking is experimental and relies on assumptions and logic, as such it might sometimes trigger false positives or false negatives. It's accuracy is being actively worked on and more specs might be added when the environment allows it. For details on the implementation check BLOGPOSTLINK.
- Changing the "Display Class Colors" option from the default Blizzard settings without triggering a GROUP_ROSTER_UPDATE event might cause some frames to recolor unintendedly. Reloading the UI or changing the group will fix this.