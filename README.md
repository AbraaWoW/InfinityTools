# Infinity Tools
Modular addon suite for WoW combining the InfinityTools core UI, Mythic+ utilities, InfinityBoss fight tracker, and shared helper systems.

## Overview
- **InfinityCore** drives the InfinityTools engine (`InfinityGrid`, module registry, profile handling, ElvUI/NDui skins, shared helpers).  
- **UI/** hosts the central configuration frame (`RRTUI`) with tabs for General, Raid, Notes, PrivateAura, EncounterAlerts, QoL, Tools, Boss, plus a custom status bar linked to Twitch.  
- **InfinityMythicPlus** adds Mythic+ information and combat modules.  
- **InfinityBoss** (with InfinityBossData/InfinityBossVoice) provides the boss UI, encounter database, and voice packs.  
- **Libs**, **InfinityMedia**, **Media**, **Scripts** supply third-party libraries, assets, and macros shared across the addon.

## InfinityMythicPlus modules
### Mythic+ utilities (`RevTools.*`)
- `MiniTools`, `StreamerTools`, `AutoBuy`, `SpellQueue`, `PlayerPosition`, `PlayerStats`, `RaidMarkerPanel`, `SpellAlert` (full panel) plus `MicroMenu`, `ChatChannelBar`, `CastSequence`, `YYSound`, `PlayerPosition`, `StreamerTools`: quick actions, auto-purchase, marker/alert panels, and other helpers.
- `PveInfoPanel`, `PveKeystoneInfo`, `CDTracker`, `SpellAlert` companion, and `YYSound` provide additional Mythic+-centric displays.

### Mythic+ info (`RevMplusInfo.*`)
- `MDTIconHook`, `MythicIcon`, `RunHistory`, `SpellInfo`, `Tooltip`, `TeleMsg`, `MythicFrame`, `SpellData` rebuild MDT UIs, show spell context, history, and enhanced tooltips.
- `MythicDamage`, `MythicCast`, `InterruptTracker`, `FriendlyCD` track damage, casts, interrupts, and friendly cooldowns.

### Class helpers (`RevClass.*`)
- `BrewmasterStagger`, `FocusCast`, `SpellEffectAlpha`, `SpellQueue`, `PlayerStats`, `RangeCheck`, `NoMoveSkillAlert`, `SpellEffectAlpha` assist classes with alerts, proc transparency, queue tuning, and range visuals.

### PTR/Beta (`RevPTR.*`)
- `RevPTR.MiniTools`, `RevPTR.SetKey` remain as PTR-specific utilities.

## InfinityBoss
- Dedicated boss UI with tabs, fixed timelines, import/export, and assignation management.  
- InfinityBossData stores encounter scripts; InfinityBossVoice delivers vocal cues and shares label catalogs.  
- Changelog access is manual (button on the panel) rather than automatic.

## InfinityTools UI
- `RRTUI` central panel hosts tabs for General, Raid, Note, PrivateAura, EncounterAlerts, QoL, Tools, Boss.  
- Status bar links to Twitch/Twitter and syncs theme colors with the rest of the suite.  
- The Tools tab opens InfinityTools/MythicPlus settings; Boss tab exposes InfinityBoss controls.

## Installation & Quick start
1. Copy the entire repository into `World of Warcraft/_retail_/Interface/AddOns`.  
2. Enable `InfinityTools` (and `InfinityBoss`/`InfinityMythicPlus` if needed) via the addon screen or `/iboss`.  
3. Use `/it` or click **Infinity Tools → Tools** from the RRT status bar to open the configuration UI, toggle modules, switch tabs, and change options.  
4. Each module exposes settings through `InfinityTools:RegisterModuleLayout`; module data is persisted in `InfinityToolsDB`.

## Resources
- Twitch: https://www.twitch.tv/abraa_  
- CurseForge: https://www.curseforge.com/wow/addons/infinitytools

## Contributing
- Add new modules under `InfinityMythicPlus/Modules` or `InfinityBoss`.  Respect the `REGISTER_LAYOUT()` pattern so InfinityTools registers the UI automatically.  
- Keep the InfinityTools alias (`_G.InfinityTools`) around as long as legacy modules expect it.
