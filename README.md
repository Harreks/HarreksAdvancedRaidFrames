[![Patreon](https://i.imgur.com/VHOsqDj.png)](https://www.patreon.com/harrek) [![Discord](https://i.imgur.com/iUrRmiw.png)](https://discord.gg/MMjNrUTxQe) [![Ko-Fi](https://i.imgur.com/9UxoYqf.png)](https://ko-fi.com/harrek)

## Introduction
Advanced Raid Frames works with default and addon frames to improve functionality, offering features like buff tracking customization. This is intended to work with your favorite frame addons, integrating and leaving as small of a footprint as possible so you can enjoy the look of your preferred frames with the advanced options Advanced Raid Frames offers. If you have feature requests, bug reports, or any questions, please use come to the [SpiritbloomPro discord](https://discord.gg/MMjNrUTxQe) and leave a message.

## Functionality

- Advanced Buff Tracking: Selectively track buffs in several ways and reposition those buff icons on your party/raid frames. Buff tracking is very good but not perfect and is actively being worked on as bugs are found.
- Click-through Aura Icons: Removes mouse interaction from most elements on the default frames, letting targeting work through them and removing the tooltips.
- Frame Transparency: Disables transparency effects on the default frames so they remain 100% solid when units are out of range.
- Name Size and Color: Scale player names and color them according to class colors.
- Spotlight: Move the raid frames of selected units into a separate group with any position of your choice.

## Planned Upgrades

- Overshields: Show shields that go above the unit's max health on the default frames.
- Spotlight Groupings: Separate the spotlight in several rows or columns.
- Integrate the tracking into more frame addons
- Aura Spotlight: Track specific auras on specific units in a more clear way (think mini-weakauras for your own buffs)

## Buff Tracking Aura List and Known Issues

### PreservationEvoker
- Echo
- Reversion
- EchoReversion
- DreamBreath
- EchoDreamBreath
- TimeDilation
- Rewind
- DreamFlight


### AugmentationEvoker
- Prescience
- ShiftingSands
- BlisteringScales
- InfernosBlessing
- SymbioticBloom
- EbonMight
- SensePower

- Spellqueueing Blistering Scales off of Ebon Might or an empower might cause issues

### RestorationDruid
- Rejuvenation
- Regrowth
- Lifebloom
- Germination
- WildGrowth
- IronBark

- Spellqueueing BarkSkin off of WildGrowth can cause issues

### DisciplinePriest
- PowerWordShield
- Atonement
- PainSuppression
- VoidShield
- PrayerOfMending
- PowerInfusion

- Power Infusion tracking is work-in-progress, i require more real world data to confirm its accuracy
- Spellqueueing Pain Suppression off of radiance might cause issues

### HolyPriest
- Renew
- EchoOfLight
- GuardianSpirit
- PrayerOfMending
- PowerInfusion

- **Holy Priest is currently not implemented**, some tracking might work by mistake but it will be very broken. It will be worked on in the future

### MistweaverMonk
- RenewingMist
- EnvelopingMist
- SoothingMist
- LifeCocoon
- AspectOfHarmony

- Casting EnvM, Vivify, or Sheiluns during the Soothing Mist channel will cause buffs to get mixed up. This is being actively worked on

### RestorationShaman
- Riptide
- EarthShield

### HolyPaladin
- BeaconOfFaith
- EternalFlame
- BeaconOfLight
- BlessingOfProtection
- HolyBulwark
- SacredWeapon
- BlessingOfSacrifice
- BeaconOfVirtue
- BeaconOfTheSavior

- Holy Bulwark and Sacred Weapon can get mixed up when the spells are casted several times back to back.

## Debug Profiling and Validation

- Enable lightweight profiling in-game with `/run AdvancedRaidFramesAPI.SetProfilingEnabled(true)`
- Reset collected metrics with `/run AdvancedRaidFramesAPI.ResetProfilingStats()`
- Print current metrics with `/run AdvancedRaidFramesAPI.PrintProfilingStats()`
- Disable profiling with `/run AdvancedRaidFramesAPI.SetProfilingEnabled(false)`

### Suggested validation flow for inference changes

- Validate direct success path first (single cast -> expected tracked aura on target frame)
- Validate ambiguity path (spell queueing / travel-time overlap / repeated casts)
- Validate both party and raid unit-frame contexts
- Validate with and without external frame integrations enabled