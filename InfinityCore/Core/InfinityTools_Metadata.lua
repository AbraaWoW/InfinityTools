-- [[ InfinityTools Metadata ]]
-- This file is auto-generated or modified by the packaging script to control the version number.
-- Do not manually commit version number changes in this file via Git unless you are testing.

local addonVersion = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("InfinityTools", "Version")) or "1.0.0"
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
"@H2@ Party CD Tracker",
"- Raid support: spec detection now works in raid via a local inspect queue (PartySync is intentionally disabled in raids)",
"- Raid support: addon peers broadcast their spec via COMM on join — bars appear instantly without waiting for inspect",
"- Raid support: reactive UNIT_AURA fallback creates bars on the fly when a known cooldown aura is detected (no spec required)",
"- Fixed: removed CanInspect() gate that was silently dropping out-of-range raid members from the inspect queue",
"",
"@H1@ v1.0.0",
"",
"@H2@ General",
"- Initial public release of InfinityTools v2.0.0",
"- InfinityTools, InfinityBoss and InfinityTools are now unified under a single addon package",
        }, "\n"),
    },
}

_G.InfinityTools_MetaData = InfinityTools_MetaData
_G.InfinityTools_MetaData = InfinityTools_MetaData
