---@diagnostic disable: undefined-global
-- =============================================================
-- =============================================================

InfinityBoss = InfinityBoss or {}
_G.InfinityBoss = InfinityBoss

_G.InfinityBossDB = _G.InfinityBossDB or {}

local meta = _G.InfinityBoss_MetaData or { version = "DEV-Build" }
InfinityBoss.MetaData = meta
InfinityBoss.VERSION  = tostring(meta.version or "DEV-Build")
_G.InfinityBoss_MetaData = _G.InfinityBoss_MetaData or meta

InfinityBoss.Voice    = InfinityBoss.Voice    or {}
InfinityBoss.Voice.Engine = InfinityBoss.Voice.Engine or {}
InfinityBoss.Voice.OtherSounds = InfinityBoss.Voice.OtherSounds or {}
InfinityBoss.Voice.Profiles = InfinityBoss.Voice.Profiles or {}
InfinityBoss.Voice.ImportExport = InfinityBoss.Voice.ImportExport or {}
InfinityBoss.Timeline = InfinityBoss.Timeline or {}
InfinityBoss.MDT      = InfinityBoss.MDT      or {}
InfinityBoss.UI       = InfinityBoss.UI       or {}
InfinityBoss.UI.TimerBar   = InfinityBoss.UI.TimerBar   or {}
InfinityBoss.UI.BunBar     = InfinityBoss.UI.BunBar     or {}
InfinityBoss.UI.RingProgress = InfinityBoss.UI.RingProgress or {}
InfinityBoss.UI.Countdown  = InfinityBoss.UI.Countdown  or {}
InfinityBoss.UI.FlashText  = InfinityBoss.UI.FlashText  or {}
InfinityBoss.UI.HeadAlert  = InfinityBoss.UI.HeadAlert  or {}
InfinityBoss.UI.Panel      = InfinityBoss.UI.Panel      or {}
InfinityBoss.UI.Panel.MDTPage = InfinityBoss.UI.Panel.MDTPage or {}
InfinityBoss.UI.Panel.OtherVoicePage = InfinityBoss.UI.Panel.OtherVoicePage or {}
InfinityBoss.UI.Panel.ImportExportPage = InfinityBoss.UI.Panel.ImportExportPage or {}
InfinityBoss.Data     = InfinityBoss.Data     or {}
InfinityBoss.DB       = InfinityBoss.DB       or {}
InfinityBoss.Export   = InfinityBoss.Export   or {}
InfinityBoss.Modules  = InfinityBoss.Modules  or {}
InfinityBoss.Modules.Boss = InfinityBoss.Modules.Boss or {}
InfinityBoss.PrivateAura = InfinityBoss.PrivateAura or {}
InfinityBoss.BossConfig = InfinityBoss.BossConfig or {}
InfinityBoss._initLoaded = InfinityBoss._initLoaded or false

InfinityBoss.Timeline._bosses = InfinityBoss.Timeline._bosses or {}
if type(InfinityBoss.Timeline.RegisterBoss) ~= "function" then
    function InfinityBoss.Timeline:RegisterBoss(encounterID, def)
        if type(encounterID) ~= "number" or type(def) ~= "table" then
            return
        end
        self._bosses[encounterID] = def
    end
end


do
    local ET = _G.InfinityTools
    if ET and ET.RegisterEvent then
        ET:RegisterEvent("ENCOUNTER_START", "InfinityBoss_Bootstrap_EncStart", function(_, encounterID)
            if InfinityBoss._initLoaded then return end
            if InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler and InfinityBoss.Timeline.Scheduler.StartBoss then
                InfinityBoss.Timeline.Scheduler:StartBoss(encounterID)
            end
        end)
        ET:RegisterEvent("ENCOUNTER_END", "InfinityBoss_Bootstrap_EncEnd", function()
            if InfinityBoss._initLoaded then return end
            if InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler and InfinityBoss.Timeline.Scheduler.EndBoss then
                InfinityBoss.Timeline.Scheduler:EndBoss()
            end
        end)
    end
end

-- =============================================================
-- =============================================================
SLASH_InfinityBoss1 = "/infinityboss"
SLASH_InfinityBoss2 = "/iboss"
SLASH_InfinityBoss3 = "/rboss"
SlashCmdList["InfinityBoss"] = function(input)
    local arg = (input or ""):match("^%s*(.-)%s*$"):lower()

    if arg == "edit" or arg == "edmode" then
        local ET = _G.InfinityTools
        if ET and ET.ToggleGlobalEditMode then
            ET:ToggleGlobalEditMode()
        else
        end
        return
    end

    if arg == "version" then
--         print("|cffff4400Ex|r|cff00ccffBoss|r v" .. InfinityBoss.VERSION)
        return
    end

    if arg == "debug" then
        local bossCount = 0
        if InfinityBoss.Timeline and InfinityBoss.Timeline._bosses then
            for _ in pairs(InfinityBoss.Timeline._bosses) do
                bossCount = bossCount + 1
            end
        end
        local sched = InfinityBoss.Timeline and InfinityBoss.Timeline.Scheduler
        local timelineAPI = (C_EncounterTimeline and true) or false
--         print("--- InfinityBoss Debug ---")
--         print("InfinityBoss.UI.Panel = " .. tostring(InfinityBoss.UI.Panel))
--         print("Panel.Toggle = " .. tostring(InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.Toggle))
--         print("Timeline.Bosses = " .. tostring(bossCount))
--         print("Timeline.API = " .. tostring(timelineAPI))
--         print("Scheduler.HandlesEncounterEvents = " .. tostring(sched and sched._handlesEncounterEvents))
--         print("Scheduler = running:" .. tostring(sched and sched._running)
--             .. " mode:" .. tostring(sched and sched._mode)
--             .. " encounter:" .. tostring(sched and sched._encounterID))
--         print("InfinityTools = " .. tostring(_G.InfinityTools))
--         print("InfinityFactory = " .. tostring(_G.InfinityFactory))
        return
    end

    local P = InfinityBoss.UI.Panel
    if P and P.Toggle then
        P:Toggle()
    else
    end
end
