-- [[ InfinityTools Metadata ]]
-- This file is auto-generated or modified by the packaging script to control the version number.
-- Do not manually commit version number changes in this file via Git unless you are testing.

local addonVersion = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("InfinityTools", "Version")) or "DEV-Build"
local displayVersion = addonVersion:match("^v") and addonVersion or ("v" .. addonVersion)

InfinityTools_MetaData = {
    version = displayVersion,
    gridEngineVersion = "2.0",
    changelog = {
        title = displayVersion .. " Changelog",
        publishedAt = "2026-04-03",
        fontSize = 14,
        content = table.concat({
"@H1@ " .. displayVersion,
"",
"@H2@ General",
"- Brewmaster Stagger Monitor: added a configurable stagger bar with percentage-based color thresholds",
"- Focus Cast Alert: added an interrupt-ready marker line and an option to mute sounds while your interrupt is on cooldown",
"- Mythic+ Streamer Tools: added nearby-in-combat enemy count display",
"- Bloodlust Reminder and Sound: added icon border settings, timer font controls, and expandable custom sound entries",
"- Party Keystone Viewer: added keystone caching and a fallback to the latest valid snapshot",
"- Party Sync / State: improved secret-aura handling and restricted sync to valid party contexts",
"- Mythic+ score panel: refreshed Raider.IO cutoff data",
"- Lightblinded Vanguard: adjusted Mythic Heal Absorb tick timings to match 12.0.69",
"- Reminder pipeline: increased reminder display refresh cadence from 20 FPS to 40 FPS",
"- Party CD Tracker (all 4 groups) are now disabled by default for new installs",
"- Fixed duplicate local variable bug in M+ Teleport Announce module",
"- Crown of the Cosmos: disabled TTS on the Phase 2 Immune alert",
"- Lightblinded Vanguard: fixed Heal Absorb bar color parsing for tick alerts",
"- Reminder pipeline: preserved alert Ticks when storing processed reminders",
"",
"@H1@ v2.0.0",
"",
"@H2@ General",
"- Initial public release of InfinityTools v2.0.0",
"- InfinityTools, InfinityBoss and InfinityTools are now unified under a single addon package",
        }, "\n"),
    },
}

_G.InfinityTools_MetaData = InfinityTools_MetaData
_G.InfinityTools_MetaData = InfinityTools_MetaData
