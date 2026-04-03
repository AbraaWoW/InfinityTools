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
        publishedAt = "2026-04-04",
        fontSize = 14,
        content = "",
    },
}

_G.InfinityTools_MetaData = InfinityTools_MetaData
_G.InfinityTools_MetaData = InfinityTools_MetaData
