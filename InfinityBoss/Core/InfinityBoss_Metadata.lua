-- [[ InfinityBoss Metadata ]]
-- This file is auto-generated or modified by the build script to control the version number.
-- Do not manually commit changes to the version number via Git unless you are testing.

local addonVersion = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("InfinityTools", "Version")) or "DEV-Build"
local displayVersion = addonVersion:match("^v") and addonVersion or ("v" .. addonVersion)

InfinityBoss_MetaData = {
    version = displayVersion,
    changelog = {
        title = displayVersion .. " Changelog",
        publishedAt = "2026-03-31",
        fontSize = 14,
        content = table.concat({
"@H1@ " .. displayVersion,
"",
"@H2@ General",
"- Version bump to match InfinityTools " .. displayVersion,
"",
"@H1@ v2.0.0",
"",
"@H2@ General",
"- Initial public release of InfinityBoss v2.0.0",
"- InfinityTools, InfinityBoss and InfinityTools are now unified under a single addon package",
        }, "\n"),
    },
}

_G.InfinityBoss_MetaData = InfinityBoss_MetaData
_G.InfinityBoss_MetaData = InfinityBoss_MetaData
