local addonName, addonTable = ...
local InfinityMythicPlus = addonTable
local InfinityTools = InfinityMythicPlus -- Backward-compatible alias for existing modules.
_G.InfinityMythicPlus = InfinityMythicPlus
_G.InfinityTools = InfinityMythicPlus

-- Attach the Locale proxy to addonTable (InfinityLocale is pre-initialized by Locale/Init.lua)
InfinityTools.L = _G.InfinityLocale and _G.InfinityLocale.GetProxy() or
setmetatable({}, { __index = function(_, k) return k end })

local L = InfinityTools.L

--=======================================================================
--========================== BASIC PROPERTIES ===========================
--=======================================================================
InfinityTools.name = addonName
-- [Core] Version info (read from InfinityTools_Metadata.lua)
local meta = _G.InfinityTools_MetaData or { version = "DEV-Build", gridEngineVersion = "DEV" }
InfinityTools.VERSION = meta.version
InfinityTools.GridEngineVersion = meta.gridEngineVersion
_G.InfinityTools_MetaData = _G.InfinityTools_MetaData or meta

--=======================================================================
--========================== GLOBAL FONT GUIDELINES ====================
--=======================================================================
-- [Core] Establish a highest-priority pointer to the native font
local nativePath, nativeSize, nativeFlags = _G.GameFontHighlight:GetFont()
InfinityTools.MAIN_FONT = nativePath or STANDARD_TEXT_FONT

-- Solution for non-Chinese clients
-- If a CJK font (AR series) is found on a non-Chinese client, force it as MAIN_FONT to support HUD SetFont rendering.
local currentLocale = GetLocale()
if currentLocale ~= "zhCN" and currentLocale ~= "zhTW" then
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local cjkFonts = { "AR ZhongkaiGBK Medium", "AR CrystalzcuheiGBK Demibold" }
        for _, name in ipairs(cjkFonts) do
            local path = LSM:Fetch("font", name)
            if path and path ~= "" then
                InfinityTools.MAIN_FONT = path
                break
            end
        end
    end
end

InfinityTools.MAIN_FONT_SIZE = 16
InfinityTools.MAIN_FONT_OUTLINE = "OUTLINE"

--=======================================================================
--========================== ENVIRONMENT DETECTION =====================
--=======================================================================
local version, build, date, tocversion = GetBuildInfo()
local isPTR = IsPublicTestClient and IsPublicTestClient()
local isBeta = IsBetaBuild and IsBetaBuild()

-- Treat any test-realm environment (PTR or Beta) as a Beta environment
InfinityTools.IsBeta = isBeta or isPTR


--=======================================================================
--========================== CATEGORY DEFINITIONS ======================
--=======================================================================
InfinityTools.Cate = {
    [1] = L["Tools"],
    [2] = L["M+ (Info)"],
    [3] = L["M+ (Combat)"],
    [4] = L["Class (General)"],
    [5] = "PTR/BETA",
}
-- Remove category 5 on non-beta realms
if not InfinityTools.IsBeta then
    InfinityTools.Cate[5] = nil
end

--=======================================================================
--========================== MODULE LIST ================================
--=======================================================================
-- ⚠️ WARNING: This ModuleList is shared across multiple addons.
--  NEVER remove any module entry! Only append new modules.
InfinityTools.ModuleList = {
    ----------------------------------------------------------------------------------------------------------
    --------------------------------------------- Tools (1) ---------------------------------------------------
    ----------------------------------------------------------------------------------------------------------
    { Key = "RevTools.MiniTools", Name = L["Common Tools"], Desc = L["Common feature bundle (auto-sell junk, chat log, delete confirm, etc.)"], Category = 1 },
    { Key = "RevTools.StreamerTools", Name = L["M+ Utilities"], Desc = L["Collection of handy Mythic+ keystone utilities."], Category = 1 },
    { Key = "RevTools.PlayerPosition", Name = L["Player Position Marker"], Desc = L["Displays a marker at screen center, changes color when out of range."], Category = 1 },
    { Key = "RevTools.ChatChannelBar", Name = L["Chat Channel Bar"], Desc = L["A quick bar for switching chat channels."], Category = 1 },
    { Key = "RevTools.AutoBuy", Name = L["Auto Purchase"], Desc = L["Automatically purchase specified items."], Category = 1 },
    { Key = "RevTools.MicroMenu", Name = "Micro Menu", Desc = "Top micro menu: shows the time in the center, with configurable panel shortcut icons on each side.", Category = 1 },
    { Key = "RevTools.RaidMarkerPanel", Name = "Raid Marker Panel", Desc = "Quick action panel for target markers and ground flares.", Category = 1 },
    ----------------------------------------------------------------------------------------------------------
    --------------------------------------------- M+ Info (2) ------------------------------------------------
    ----------------------------------------------------------------------------------------------------------
    { Key = "RevMplusInfo.MDTIconHook", Name = L["MDT Spell Icon Replacement"], Desc = L["Replaces mob portraits in MDT maps with spell icons."], Category = 2 },
    { Key = "RevMplusInfo.MDTInfo", Name = "MDT Info Enhancer", Desc = "Adds spell type hints to MDT maps and spell tooltips.", Category = 2 },
    { Key = "RevMplusInfo.MythicIcon", Name = L["M+ Score / Click Teleport"], Desc = L["M+ icon, score, click-to-teleport enhancements."], Category = 2 },
    { Key = "RevMplusInfo.TeleMsg", Name = L["M+ Teleport Announce"], Desc = L["Chat announcements and alerts for M+ teleports."], Category = 2 },
    { Key = "RevMplusInfo.SpellInfo", Name = L["M+ Spell Info Lookup"], Desc = L["Spell info lookup and tooltip enhancements."], Category = 2, HideCfg = true },
    { Key = "RevMplusInfo.Tooltip", Name = L["M+ Best Run (Tooltip)"], Desc = L["M+ tooltip and interaction enhancements."], Category = 2, HideCfg = true },
    { Key = "RevMplusInfo.RunHistory", Name = L["M+ Season History"], Desc = L["Record and display M+ season history."], Category = 2 },
    { Key = "RevMplusInfoMythicFrame", Name = L["M+ Stats Panel"], Desc = L["M+ statistics panel and display."], Category = 2, HideCfg = true },
    { Key = "RevMplusInfoSpellData", Name = L["Spell Data (Internal)"], Desc = L["Internal data / spell database."], Category = 2, HideCfg = true },
    { Key = "RevMplus.MythicDamage", Name = L["M+ Damage Calculator"], Desc = L["Standalone UI to calculate actual spell damage by keystone level."], Category = 2 },
    { Key = "RevTools.PveInfoPanel", Name = L["PvE Info Panel"], Desc = L["Displays an extra info panel alongside the Dungeon Finder (PVEFrame)."], Category = 2 },
    { Key = "RevTools.PveKeystoneInfo", Name = L["Mythic+ Party Keystones"], Desc = L["Displays your and party members' keystones on the PVEFrame."], Category = 2, new = true },
    ----------------------------------------------------------------------------------------------------------
    --------------------------------------------- M+ Combat (3) -----------------------------------------------
    ----------------------------------------------------------------------------------------------------------
    { Key = "RevMplus.InterruptTracker", Name = L["Interrupt Tracker"], Desc = L["Infer and track teammate interrupt cooldowns (supports 12.0)."], Category = 3 },
    { Key = "RevMplus.MythicCast", Name = L["Nearby Cast Monitor"], Desc = L["Shows nearby mob cast bars with separate colors for interruptible and unbreakable casts."], Category = 3 },
    { Key = "RevMplus.FriendlyCD", Name = "Friendly CD Tracker", Desc = "Tracks friendly defensive and offensive cooldowns in M+ and Raid. Bars, icons, and attached-to-frame modes.", Category = 3, new = true },
    { Key = "RevCC.AlertsModule", Name = "Enemy Spell Alerts", Desc = "Floating bar showing active important/defensive enemy spells (nameplates, target, focus).", Category = 3, new = true },
    { Key = "RevCC.Nameplates", Name = "Nameplate Spell Icons", Desc = "Attaches CC and important spell icons directly onto enemy and friendly nameplates.", Category = 3, new = true },
    { Key = "RevCC.FriendlyIndicator", Name = "Friendly Aura Indicators", Desc = "Shows CC, defensive, and important spell icons on Blizzard compact party/raid frames.", Category = 3, new = true },
    ----------------------------------------------------------------------------------------------------------
    --------------------------------------------- Class (General) (4) -----------------------------------------
    ----------------------------------------------------------------------------------------------------------
    { Key = "RevTools.SpellQueue", Name = L["Spell Queue Latency"], Desc = L["Automatically adjusts spell queue latency based on current spec."], Category = 4 },
    { Key = "RevClass.SpellEffectAlpha", Name = L["Proc Transparency"], Desc = L["Automatically adjusts proc transparency based on current spec."], Category = 4 },
    { Key = "RevTools.PlayerStats", Name = L["Player Stats Monitor"], Desc = L["Collect and display player combat stats."], Category = 4 },
    --{ Key = "RevTools.CastBar", Name = "Cast Bar Styler", Desc = "Reskin the native cast bar (texture, size, text position).", Category = 4 },
    { Key = "RevTools.YYSound", Name = L["Bloodlust Sound"], Desc = L["Plays a sound when a teammate triggers Bloodlust. (Beta)"], Category = 4 },
    --{ Key = "RevTools.SpellAlert", Name = "Spell Cast Alert", Desc = "Delayed alert after a successful cast (voice/icon).", Category = 4 },
    { Key = "RevTools.CastSequence", Name = L["Cast Sequence"], Desc = L["Displays your cast sequence in real time with cast/channel/instant/interrupt state visualization."], Category = 4 },
    { Key = "RevClass.RangeCheck", Name = L["Range Monitor"], Desc = L["Displays target distance range in real time."], Category = 4 },
    { Key = "RevClass.NoMoveSkillAlert", Name = L["Movement CD Alert"], Desc = L["Alerts when movement ability is on cooldown."], Category = 4 },
    { Key = "RevClass.FocusCast", Name = L["Focus Cast Alert"], Desc = L["Monitors focus target casting only, with independent cast bar and sound alerts."], Category = 4 },
    { Key = "RevClass.BrewmasterStagger", Name = L["Brewmaster Stagger Monitor"], Desc = L["Shows Brewmaster Monk stagger as a configurable percentage bar."], Category = 4 },
    ----------------------------------------------------------------------------------------------------------
    ---------------------------------------------PTR/BETA (5)-------------------------------------------------
    ----------------------------------------------------------------------------------------------------------
    { Key = "RevPTR.MiniTools", Name = L["PTR Toolbox"], Desc = L["PTR-only convenience features (suppress feedback, one-click talent apply, etc.)"], Category = 5, BlockBeta = true },
    { Key = "RevPTR.SetKey", Name = L["Quick Keystone (PTR)"], Desc = L["PTR: Quickly create or set keystones."], Category = 5, BlockBeta = true, },
}

-- Remove BlockBeta modules on non-beta realms

if not InfinityTools.IsBeta then
    local i = 1
    while i <= #InfinityTools.ModuleList do
        if InfinityTools.ModuleList[i].BlockBeta then
            table.remove(InfinityTools.ModuleList, i)
        else
            i = i + 1
        end
    end
end

-- Key -> Index mapping
InfinityTools.ModuleIndexByKey = {}
for i, meta in ipairs(InfinityTools.ModuleList) do
    InfinityTools.ModuleIndexByKey[meta.Key] = i
end

--=======================================================================
--========================== DATABASE INITIALIZATION ===================
--=======================================================================
_G.InfinityToolsDB = _G.InfinityToolsDB or {}
local db = _G.InfinityToolsDB

db.DBVersion = db.DBVersion or 1
db.ModuleDB = db.ModuleDB or {}
db.LoadByKey = db.LoadByKey or {}
db.Load = {}
db.LoadKeys = {}
db.Minimap = db.Minimap or { hide = false }

-- Sync module configuration
local validKeys = {}
for i, meta in ipairs(InfinityTools.ModuleList) do
    local key = meta.Key
    validKeys[key] = true
    db.LoadKeys[i] = key
    if db.LoadByKey[key] == nil then db.LoadByKey[key] = (meta.DefaultEnabled ~= false) end
    db.Load[i] = db.LoadByKey[key]
end
for k in pairs(db.LoadByKey) do
    if not validKeys[k] then db.LoadByKey[k] = nil end
end

InfinityTools.DB = db

local function SyncModuleRegistry()
    wipe(InfinityTools.ModuleIndexByKey)
    wipe(db.Load)
    wipe(db.LoadKeys)

    local validKeys = {}
    for i, meta in ipairs(InfinityTools.ModuleList) do
        local key = meta.Key
        validKeys[key] = true
        InfinityTools.ModuleIndexByKey[key] = i
        db.LoadKeys[i] = key
        if db.LoadByKey[key] == nil then
            db.LoadByKey[key] = (meta.DefaultEnabled ~= false)
        end
        db.Load[i] = db.LoadByKey[key]
    end

    for k in pairs(db.LoadByKey) do
        if not validKeys[k] then
            db.LoadByKey[k] = nil
        end
    end
end

function InfinityTools:RegisterExternalModule(meta)
    if type(meta) ~= "table" or type(meta.Key) ~= "string" or meta.Key == "" then
        return false
    end

    if meta.BlockBeta and not self.IsBeta then
        return false
    end

    local idx = self.ModuleIndexByKey[meta.Key]
    if idx then
        local cur = self.ModuleList[idx]
        for k, v in pairs(meta) do
            cur[k] = v
        end
    else
        self.ModuleList[#self.ModuleList + 1] = meta
    end

    SyncModuleRegistry()

    if self.UI and self.UI.MainFrame and self.UI.MainFrame:IsShown() then
        if self.UI.SidebarFrame and self.UI.BuildNavigationTree then
            self.UI:BuildNavigationTree(self.UI.SidebarFrame)
        end
        if self.UI.RefreshContent then
            self.UI:RefreshContent()
        end
    end

    return true
end

--=======================================================================
--========================== DEBUG MODE =================================
--=======================================================================
InfinityTools.DebugMode = false

function InfinityDebug(fmt, ...)
    if not InfinityTools.DebugMode then return end
    local msg = select("#", ...) > 0 and string.format(fmt, ...) or fmt
    print(string.format("|cffff9900[INFINITY-DEBUG]|r %s", msg))
end

_G.InfinityDebug = InfinityDebug

--=======================================================================
--========================== MODULE STATUS REPORTING ===================
--=======================================================================
InfinityTools.ModuleStatus = {}
InfinityTools.RegisteredLayouts = {}

function InfinityTools:ReportReady(moduleKey)
    self.ModuleStatus[moduleKey] = "ready"
end

--=======================================================================
--========================== ERROR LOG COLLECTION ======================
--=======================================================================
InfinityTools.ErrorLog = {}
local MAX_ERROR_LOG = 20

function InfinityTools:LogError(source, message)
    local entry = { time = _G.date("%H:%M:%S"), source = source, message = tostring(message) }
    table.insert(self.ErrorLog, 1, entry)
    while #self.ErrorLog > MAX_ERROR_LOG do table.remove(self.ErrorLog) end
end

--=======================================================================
--========================== DEPENDENCY LIBRARY CHECK ==================
--=======================================================================
InfinityTools.LibStatus = {}

local function CheckLibs()
    local libs = {
        { name = "LibStub",  check = function() return _G.LibStub ~= nil end },
        {
            name = "CallbackHandler-1.0",
            check = function()
                return LibStub and LibStub:GetLibrary("CallbackHandler-1.0", true) ~= nil
            end
        },
        {
            name = "LibSharedMedia-3.0",
            check = function()
                return LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true) ~= nil
            end
        },
        { name = "LibAsync", check = function() return LibStub and LibStub:GetLibrary("LibAsync", true) ~= nil end },
        {
            name = "LibCustomGlow-1.0",
            check = function()
                return LibStub and
                    LibStub:GetLibrary("LibCustomGlow-1.0", true) ~= nil
            end
        },
        {
            name = "LibDBIcon-1.0",
            check = function()
                return LibStub and
                    LibStub:GetLibrary("LibDBIcon-1.0", true) ~= nil
            end
        },
        {
            name = "LibDataBroker-1.1",
            check = function()
                return LibStub and
                    LibStub:GetLibrary("LibDataBroker-1.1", true) ~= nil
            end
        },
        { name = "LibDeflate", check = function() return LibStub and LibStub:GetLibrary("LibDeflate", true) ~= nil end },
        {
            name = "LibSerialize",
            check = function()
                return LibStub and
                    LibStub:GetLibrary("LibSerialize", true) ~= nil
            end
        },
    }
    for _, lib in ipairs(libs) do
        local ok, result = pcall(lib.check)
        InfinityTools.LibStatus[lib.name] = (ok and result) and true or false
    end
end
CheckLibs()
C_Timer.After(3, CheckLibs)

--=======================================================================
--========================== ENVIRONMENT INFO COLLECTION ===============
--=======================================================================
function InfinityTools:GetEnvironmentInfo()
    local version, build, buildDate = GetBuildInfo()
    local isPTR = (IsPublicTestClient and IsPublicTestClient()) and "Yes" or "No"
    local isBeta = (IsBetaBuild and IsBetaBuild()) and "Yes" or "No"
    local platform = IsWindowsClient() and "Windows" or (IsMacClient() and "Mac" or "Unknown")
    local arch = Is64BitClient() and "64-bit" or "32-bit"
    local gameLocale = GetLocale()
    local regionID = GetCurrentRegion()
    local regionMap = { [1] = "US", [2] = "KR", [3] = "EU", [4] = "TW", [5] = "CN", [90] = "BETA" }

    return {
        addonVersion = self.VERSION,
        dbVersion = db.DBVersion,
        gameVersion = version,
        gameBuild = build,
        buildDate = buildDate,
        isPTR = isPTR,
        isBeta = isBeta,
        isElvUI = C_AddOns.IsAddOnLoaded("ElvUI") and "Yes" or "No",
        platform = platform,
        arch = arch,
        locale = gameLocale,
        region = regionMap[regionID] or tostring(regionID),
        serverTime = (function()
            if C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime then
                local t = C_DateAndTime.GetCurrentCalendarTime()
                if t then
                    return string.format("%04d-%02d-%02d %02d:%02d", t.year, t.month, t.monthDay, t.hour, t.minute)
                end
            end
            return "N/A"
        end)(),
    }
end

function InfinityTools:GenerateDiagnosticText()
    local env = self:GetEnvironmentInfo()
    local lines = {
        "=== InfinityTools Diagnostics ===",
        string.format("Addon Version: %s | WTF Version: %d", env.addonVersion, env.dbVersion),
        string.format("Game Version: %s (Build: %s)", env.gameVersion, env.gameBuild),
        string.format("System: %s (%s) | Region: %s | Locale: %s | ElvUI: %s", env.platform, env.arch, env.region, env.locale,
            env.isElvUI),
        "",
        "=== Current State ===",
        string.format("Class: %s | Spec: %s", self.State and self.State.ClassName or "N/A",
            self.State and self.State.SpecName or "N/A"),
        string.format("Instance: %s | Combat: %s", self.State and self.State.InInstance and "Yes" or "No",
            self.State and self.State.InCombat and "Yes" or "No"),
        "",
        "=== Libraries ===",
    }
    for name, loaded in pairs(self.LibStatus) do
        table.insert(lines, string.format("%s: %s", name, loaded and "OK" or "MISSING"))
    end
    return table.concat(lines, "\n")
end

--=======================================================================
--========================== EVENT DISPATCH SYSTEM =====================
--=======================================================================
InfinityTools.EventHandlers = {}
InfinityTools.CoreEventFrame = CreateFrame("Frame")

--- Register a game event (supports both native and virtual events)
function InfinityTools:RegisterEvent(event, owner, func)
    if type(event) ~= "string" then error("RegisterEvent: event must be string", 2) end
    if owner == nil then error("RegisterEvent: owner cannot be nil", 2) end
    if type(func) ~= "function" then error("RegisterEvent: func must be function", 2) end

    if not self.EventHandlers[event] then
        self.EventHandlers[event] = {}
        -- Try to register a native event; virtual events will silently fail
        pcall(self.CoreEventFrame.RegisterEvent, self.CoreEventFrame, event)
    end
    self.EventHandlers[event][owner] = func
end

--- Unregister a game event (supports both native and virtual events)
function InfinityTools:UnregisterEvent(event, owner)
    if self.EventHandlers[event] then
        self.EventHandlers[event][owner] = nil
        local count = 0
        for _ in pairs(self.EventHandlers[event]) do count = count + 1 end
        if count == 0 then
            pcall(self.CoreEventFrame.UnregisterEvent, self.CoreEventFrame, event)
            self.EventHandlers[event] = nil
        end
    end
end

--- Fire a virtual event
--- @param event string Event name
--- @param ... any Event arguments
function InfinityTools:SendEvent(event, ...)
    local handlers = self.EventHandlers[event]
    if not handlers then return end

    for owner, func in pairs(handlers) do
        local ok, err = pcall(func, event, ...)
        if not ok then
            self:LogError(string.format("SendEvent[%s][%s]", event, owner), err)
            print(string.format("|cffff0000[InfinityTools] SendEvent error [%s][%s]: %s|r", event, owner, tostring(err)))
        end
    end
end

-- Event dispatch core
InfinityTools.CoreEventFrame:SetScript("OnEvent", function(_, event, ...)
    local handlers = InfinityTools.EventHandlers[event]
    if handlers then
        for owner, func in pairs(handlers) do
            local ok, err = pcall(func, event, ...)
            if not ok then
                InfinityTools:LogError(string.format("Event[%s][%s]", event, owner), err)
                print(string.format("|cffff0000[InfinityTools] Event error [%s][%s]: %s|r", event, owner, tostring(err)))
            end
        end
    end
end)

--=======================================================================
--========================== EVENT FREQUENCY WATCHER (WatchEven) =======
--=======================================================================
InfinityTools.WatchEvenRegistry = {}
InfinityTools.WatchEvenOwner = "__InfinityTools_WatchEven_Dispatcher"

local function NormalizeWatchEvenArgs(a, b, c, d, e, f, g)
    -- Compatible with two calling styles:
    -- 1) InfinityTools.WatchEven("EVENT", "module", 3, 4, 1.0, callback)
    -- 2) InfinityTools:WatchEven("EVENT", "module", 3, 4, 1.0, callback)
    if a == InfinityTools then
        return b, c, d, e, f, g
    end
    return a, b, c, d, e, f
end

local function NormalizeUnwatchEvenArgs(a, b, c)
    if a == InfinityTools then
        return b, c
    end
    return a, b
end

local function IsTableEmpty(t)
    for _ in pairs(t) do
        return false
    end
    return true
end

local function WatchEvenOnEvent(event, ...)
    local moduleWatchers = InfinityTools.WatchEvenRegistry[event]
    if not moduleWatchers then return end

    local now = (GetTimePreciseSec and GetTimePreciseSec()) or GetTime()

    for moduleName, watcher in pairs(moduleWatchers) do
        local hitTimes = watcher.hitTimes
        hitTimes[#hitTimes + 1] = now

        -- Clean up records outside the window; keep only triggers within the last interval seconds
        while hitTimes[1] and (now - hitTimes[1]) > watcher.interval do
            table.remove(hitTimes, 1)
        end

        local count = #hitTimes
        if count >= watcher.minCount and count <= watcher.maxCount then
            local ok, err = pcall(
                watcher.callback,
                event,
                moduleName,
                count,
                watcher.minCount,
                watcher.maxCount,
                watcher.interval,
                ...
            )
            if not ok then
                InfinityTools:LogError(string.format("WatchEven[%s][%s]", event, moduleName), err)
                print(string.format("|cffff0000[InfinityTools] WatchEven callback error [%s][%s]: %s|r", event, moduleName,
                    tostring(err)))
            end
        end
    end
end

--- Register an event frequency watcher
--- @param eventName string Event name
--- @param moduleName string Module name (used to isolate different callers)
--- @param minCount number Minimum trigger count (inclusive)
--- @param maxCount number Maximum trigger count (inclusive)
--- @param interval number|function Statistics window (seconds); if omitted, callback can be passed directly; default 1 second
--- @param callback function Callback function
function InfinityTools.WatchEven(a, b, c, d, e, f, g)
    local eventName, moduleName, minCount, maxCount, interval, callback = NormalizeWatchEvenArgs(a, b, c, d, e, f, g)

    -- Shorthand compatibility: WatchEven(event, module, min, max, callback)
    if type(interval) == "function" and callback == nil then
        callback = interval
        interval = 1
    end

    if type(eventName) ~= "string" or eventName == "" then
        error("WatchEven: eventName must be non-empty string", 2)
    end
    if type(moduleName) ~= "string" or moduleName == "" then
        error("WatchEven: moduleName must be non-empty string", 2)
    end
    if type(minCount) ~= "number" or minCount < 1 then
        error("WatchEven: minCount must be number >= 1", 2)
    end
    if type(maxCount) ~= "number" or maxCount < minCount then
        error("WatchEven: maxCount must be number and >= minCount", 2)
    end
    if type(interval) ~= "number" or interval <= 0 then
        error("WatchEven: interval must be number > 0", 2)
    end
    if type(callback) ~= "function" then
        error("WatchEven: callback must be function", 2)
    end

    local isNewEvent = (InfinityTools.WatchEvenRegistry[eventName] == nil)
    if isNewEvent then
        InfinityTools.WatchEvenRegistry[eventName] = {}
    end

    InfinityTools.WatchEvenRegistry[eventName][moduleName] = {
        minCount = math.floor(minCount),
        maxCount = math.floor(maxCount),
        interval = interval,
        callback = callback,
        hitTimes = {},
    }

    if isNewEvent then
        InfinityTools:RegisterEvent(eventName, InfinityTools.WatchEvenOwner, WatchEvenOnEvent)
    end
end

--- Unregister an event frequency watcher
--- @param eventName string Event name
--- @param moduleName string|nil Module name; when nil, removes all watchers for this event
function InfinityTools.UnwatchEven(a, b, c)
    local eventName, moduleName = NormalizeUnwatchEvenArgs(a, b, c)

    if type(eventName) ~= "string" or eventName == "" then
        error("UnwatchEven: eventName must be non-empty string", 2)
    end

    local moduleWatchers = InfinityTools.WatchEvenRegistry[eventName]
    if not moduleWatchers then return end

    if moduleName ~= nil then
        if type(moduleName) ~= "string" or moduleName == "" then
            error("UnwatchEven: moduleName must be non-empty string when provided", 2)
        end
        moduleWatchers[moduleName] = nil
    else
        wipe(moduleWatchers)
    end

    if IsTableEmpty(moduleWatchers) then
        InfinityTools.WatchEvenRegistry[eventName] = nil
        InfinityTools:UnregisterEvent(eventName, InfinityTools.WatchEvenOwner)
    end
end

--- Unregister all event frequency watchers for a specific module
--- @param moduleName string Module name
function InfinityTools.UnwatchEvenByModule(a, b)
    local moduleName = (a == InfinityTools) and b or a

    if type(moduleName) ~= "string" or moduleName == "" then
        error("UnwatchEvenByModule: moduleName must be non-empty string", 2)
    end

    for eventName, moduleWatchers in pairs(InfinityTools.WatchEvenRegistry) do
        if moduleWatchers[moduleName] then
            moduleWatchers[moduleName] = nil
            if IsTableEmpty(moduleWatchers) then
                InfinityTools.WatchEvenRegistry[eventName] = nil
                InfinityTools:UnregisterEvent(eventName, InfinityTools.WatchEvenOwner)
            end
        end
    end
end

--=======================================================================
--========================== MODULE MANAGEMENT =========================
--=======================================================================
local function MergeDefaults(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then return end
    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = dst[k] or {}
            MergeDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

function InfinityTools:IsModuleEnabled(moduleKey)
    -- 1. Check whether configuration is enabled
    if db.LoadByKey[moduleKey] ~= true then
        return false
    end

    -- 2. Check static block rules (BlockBeta)
    local idx = self.ModuleIndexByKey[moduleKey]
    if idx then
        local meta = self.ModuleList[idx]
        if meta and meta.BlockBeta and not self.IsBeta then
            return false -- If BlockBeta is set and this is not a Beta realm, treat as disabled
        end
    end

    return true
end

function InfinityTools:GetModuleDB(moduleKey, defaults)
    if type(moduleKey) ~= "string" or moduleKey == "" then
        error("GetModuleDB: moduleKey must be non-empty string", 2)
    end
    db.ModuleDB[moduleKey] = db.ModuleDB[moduleKey] or {}
    if type(defaults) == "table" then
        MergeDefaults(db.ModuleDB[moduleKey], defaults)
    end
    return db.ModuleDB[moduleKey]
end

function InfinityTools:RegisterModuleOptions() end -- compatibility shim

--- Register a callback for a button widget inside a module's InfinityGrid layout.
--- The callback fires whenever that button is clicked in the settings panel.
--- @param moduleKey string  The module key (same as used in RegisterModuleLayout)
--- @param fieldKey  string  The button's `key` field from the layout table
--- @param func      function Callback function: func()
function InfinityTools:RegisterModuleCallback(moduleKey, fieldKey, func)
    local stateKey = moduleKey .. ".ButtonClicked"
    local owner    = moduleKey .. "." .. fieldKey
    self:WatchState(stateKey, owner, function(newValue)
        if newValue and newValue.key == fieldKey then
            func()
        end
    end)
end

function InfinityTools:RegisterModuleLayout(moduleKey, layoutData)
    if type(moduleKey) == "string" and type(layoutData) == "table" then
        self.RegisteredLayouts[moduleKey] = layoutData
    end
end

-- =========================================================
-- ========================== HUD FRAME REGISTRATION & EDIT MODE ================
-- =========================================================
InfinityTools.HUDs = {}

--- Register a module's HUD frame
--- After registration it gains: right-click jump to settings, unified control, etc.
--- @param moduleKey string Module Key
--- @param frame table The corresponding Frame object
function InfinityTools:RegisterHUD(moduleKey, frame)
    if not frame then return end

    -- 1. Basic config to ensure mouse clicks work
    frame:EnableMouse(true)

    -- 2. Inject right-click jump logic (use Hook to avoid overriding existing module scripts)
    frame:HookScript("OnMouseDown", function(_, button)
        if button == "RightButton" and self.GlobalEditMode then
            self:OpenConfig(moduleKey)
        end
    end)

    -- 3. Record in the registry
    table.insert(self.HUDs, { key = moduleKey, frame = frame })

    -- 4. Automatically associate with global edit mode changes
    self:RegisterEditModeCallback(moduleKey .. "_HUD_" .. (frame:GetName() or tostring(frame)), function(enabled)
        if enabled then
            frame:EnableMouse(true)
        end
    end)
end

local function ShowMissingInfinityToolsWarning()
    local exists = C_AddOns and C_AddOns.DoesAddOnExist and C_AddOns.DoesAddOnExist("InfinityTools")
    local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("InfinityTools")
    local loadable, reason
    if C_AddOns and C_AddOns.GetAddOnInfo then
        local _, _, _, addonLoadable, addonReason = C_AddOns.GetAddOnInfo("InfinityTools")
        loadable = addonLoadable
        reason = addonReason
    end
    local message

    if not exists then
        message = "InfinityTools is not installed, so the settings panel cannot be opened."
    elseif not loaded then
        if loadable == false and reason and reason ~= "" then
            message = string.format("InfinityTools is not currently loaded, so the settings panel cannot be opened.\nReason: %s", tostring(reason))
        else
            message = "InfinityTools is not currently loaded, so the settings panel cannot be opened."
        end
    else
        return false
    end

    if not StaticPopupDialogs["INFINITYTOOLS_MISSING_WARNING"] then
        StaticPopupDialogs["INFINITYTOOLS_MISSING_WARNING"] = {
            text = "%s",
            button1 = "OK",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
    end

    StaticPopup_Show("INFINITYTOOLS_MISSING_WARNING", message)
    InfinityTools:Print(message)
    return true
end

function InfinityTools:OpenConfig(moduleKey)
    if type(moduleKey) == "string" and string.sub(moduleKey, 1, 13) == "InfinityBoss." then
        local panel = _G.InfinityBoss and _G.InfinityBoss.UI and _G.InfinityBoss.UI.Panel
        if panel and panel.Show and panel.SetTab then
            if self.UI.MainFrame and self.UI.MainFrame:IsShown() then
                self.UI.MainFrame:Hide()
            end

            local targetTab = "boss"
            local targetGlobalKey = nil

            if moduleKey == "InfinityBoss.TimerBar" then
                targetTab = "globalsettings"
                targetGlobalKey = "timerbar"
            elseif moduleKey == "InfinityBoss.BunBar" then
                targetTab = "globalsettings"
                targetGlobalKey = "bunbar"
            elseif moduleKey == "InfinityBoss.Countdown" then
                targetTab = "globalsettings"
                targetGlobalKey = "countdown"
            elseif moduleKey == "InfinityBoss.FlashText" then
                targetTab = "globalsettings"
                targetGlobalKey = "flashtext"
            elseif moduleKey == "InfinityBoss.RingProgress" then
                targetTab = "globalsettings"
                targetGlobalKey = "ringprogress"
            elseif moduleKey == "InfinityBoss.PrivateAuraOptions" or moduleKey == "InfinityBoss.BossSpellOptions" then
                targetTab = "boss"
            end

            panel:SetTab(targetTab)
            panel:Show()
            if targetGlobalKey then
                local globalPage = panel.GlobalSettingsPage
                if globalPage and globalPage.SetSelectedKey then
                    globalPage:SetSelectedKey(targetGlobalKey)
                end
            end
            return
        end
    end

    if not self.UI or not self.UI.Toggle then return end

    if moduleKey then
        self.UI.CurrentPage = "ModuleSettings"
        self.UI.CurrentModule = moduleKey
    end

    if not self.UI.MainFrame or not self.UI.MainFrame:IsShown() then
        self.UI:Toggle()
    else
        self.UI:RefreshContent()
        -- [v4.7] Ensure the window is brought to front
        self.UI.MainFrame:Raise()
    end
end

--=======================================================================
--========================== Global Edit Mode System ============================
--=======================================================================
-- Global edit mode toggle
-- Allows /it edmode to toggle drag mode for every supported module
InfinityTools.GlobalEditMode = false
InfinityTools.EditModeCallbacks = {}

--- Register an edit mode callback.
--- @param moduleKey string Module key
--- @param callback function Callback receiving enabled (boolean)
function InfinityTools:RegisterEditModeCallback(moduleKey, callback)
    if type(callback) ~= "function" then
        error("RegisterEditModeCallback: callback must be function", 2)
    end
    self.EditModeCallbacks[moduleKey] = callback
end

--- Unregister an edit mode callback.
function InfinityTools:UnregisterEditModeCallback(moduleKey)
    self.EditModeCallbacks[moduleKey] = nil
end

--- Toggle global edit mode.
function InfinityTools:ToggleGlobalEditMode(forceState)
    if forceState ~= nil then
        self.GlobalEditMode = forceState
    else
        self.GlobalEditMode = not self.GlobalEditMode
    end

    local status = self.GlobalEditMode and "|cff00ff00[Enabled]|r" or "|cffff0000[Disabled]|r"
    self:Print("Global Edit Mode: " .. status)

    -- 1. Trigger all registered callbacks
    for moduleKey, callback in pairs(self.EditModeCallbacks) do
        pcall(callback, self.GlobalEditMode)
    end

    -- 2. Sync UI button text
    if self.UI and self.UI.EditModeToggleButton then
        self.UI.EditModeToggleButton:SetText(self.GlobalEditMode and "Exit Edit Mode" or "Enable Edit Mode")
    end

    -- 3. Popup logic
    if self.GlobalEditMode then
        if not StaticPopupDialogs["INFINITY_EDIT_MODE_EXIT"] then
            StaticPopupDialogs["INFINITY_EDIT_MODE_EXIT"] = {
                text = "Exit edit mode?",
                button1 = "Confirm",
                OnAccept = function()
                    InfinityTools:ToggleGlobalEditMode(false) -- Click OK to leave edit mode
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = false, -- Confirmation required
                preferredIndex = 3,
            }
        end
        StaticPopup_Show("INFINITY_EDIT_MODE_EXIT")
    else
        StaticPopup_Hide("INFINITY_EDIT_MODE_EXIT")
    end
end

--=======================================================================
--========================== Slash Command System ================================
--=======================================================================
function InfinityTools:Print(msg, ...)
    print("|cffA330C9InfinityTools|r " .. (select("#", ...) > 0 and string.format(msg, ...) or msg))
end

function InfinityTools:RegisterChatCommand(slash, func)
    local cmd = slash:upper()
    _G["SLASH_" .. cmd .. "1"] = "/" .. slash
    SlashCmdList[cmd] = func
end

local function PrintSlashHelp()
    InfinityTools:Print("Available commands:")
    print("  |cffA330C9/it|r - Open InfinityTools settings")
    print("  |cffA330C9/it help|r - Show this command list")
    print("  |cffA330C9/it edmode|r - Toggle global HUD edit mode")
    print("  |cffA330C9/it debug|r - Toggle debug mode")
    print("  |cffA330C9/it dev|r or |cffA330C9/it edit|r - Toggle developer mode")
    print("  |cffA330C9/it re|r or |cffA330C9/rl|r - Reload UI")
    print("  |cffA330C9/itstate|r - Print InfinityTools runtime state")
    print("  |cffA330C9/itreset|r - Reset InfinityTools saved variables and reload")
    InfinityTools:Print("Use the Modules page inside InfinityTools settings to reach InfinityMythicPlus tools.")
end

-- Main commands
local function HandleConfigCommand(input)
    local arg = (input or ""):trim():lower()

    if arg == "dev" or arg == "edit" then
        InfinityTools.State.DevMode = not InfinityTools.State.DevMode
        print("|cffA330C9[InfinityTools]|r Developer Mode: " ..
            (InfinityTools.State.DevMode and "|cff00ff00[Enabled]|r" or "|cffff0000[Disabled]|r"))
        if InfinityTools.UI and InfinityTools.UI.RefreshContent then InfinityTools.UI:RefreshContent() end
        return
    end

    if arg == "debug" then
        InfinityTools.DebugMode = not InfinityTools.DebugMode
        print("|cffA330C9[InfinityTools]|r DEBUG: " .. (InfinityTools.DebugMode and "|cff00ff00[Enabled]|r" or "|cffff0000[Disabled]|r"))
        return
    end

    if arg == "edmode" then
        InfinityTools:ToggleGlobalEditMode()
        return
    end

    if arg == "re" then
        C_UI.Reload(); return
    end

    if arg == "help" or arg == "?" then
        PrintSlashHelp()
        return
    end

    InfinityTools:OpenConfig()
end

InfinityTools:RegisterChatCommand("it", HandleConfigCommand)
InfinityTools:RegisterChatCommand("infinitytools", HandleConfigCommand)
InfinityTools:RegisterChatCommand("itconfig", HandleConfigCommand)

InfinityTools:RegisterChatCommand("itreset", function()
    _G.InfinityToolsDB = nil
    C_UI.Reload()
end)

-- /rl quick reload shortcut (compatible fallback if ACP is not installed)
InfinityTools:RegisterChatCommand("rl", function()
    C_UI.Reload()
end)

InfinityTools:RegisterChatCommand("itstate", function()
    print("|cffA330C9[InfinityTools] Current States:|r")
    if not InfinityTools.State then
        print("  State not initialized"); return
    end

    local keys = {}
    for k in pairs(InfinityTools.State) do table.insert(keys, k) end
    table.sort(keys)

    for _, k in ipairs(keys) do
        local v = InfinityTools.State[k]
        local vStr = type(v) == "number" and string.format("%.2f", v) or tostring(v)
        print(string.format("  |cffcccccc[%s]|r = |cff00ff00%s|r", k, vStr))
    end
end)



--=======================================================================
--========================== Minimap Button ======================================
--=======================================================================
function InfinityTools:IsMinimapButtonHidden()
    db.Minimap = db.Minimap or { hide = false }
    return db.Minimap.hide == true
end

function InfinityTools:SetMinimapButtonHidden(hidden)
    db.Minimap = db.Minimap or { hide = false }
    db.Minimap.hide = hidden and true or false

    local LDBIcon = LibStub("LibDBIcon-1.0", true)
    if not LDBIcon then return end
    if LDBIcon:IsRegistered("InfinityTools") then
        LDBIcon:Refresh("InfinityTools", db.Minimap)
    end
end

local function InitMinimapButton()
    local LDB = LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub("LibDBIcon-1.0", true)
    if not LDB or not LDBIcon then return end

    local INFINITY_LDB = LDB:NewDataObject("InfinityTools", {
        type = "launcher",
        text = "InfinityTools",
        icon = [[Interface\AddOns\InfinityCore\Textures\LOGO\rv.png]],
        OnClick = function(self, button)
            if button == "LeftButton" then
                InfinityTools:OpenConfig()
            elseif button == "RightButton" then
                -- Right-click toggles global edit mode
                InfinityTools:ToggleGlobalEditMode()
            end
        end,
        OnTooltipShow = function(tt)
            tt:AddLine("|cffA330C9InfinityTools|r " .. InfinityTools.VERSION)
            tt:AddLine(" ")
            tt:AddLine("|cff00ff00Left-click:|r Open Settings")
            tt:AddLine("|cff00ff00Right-click:|r Toggle Edit Mode")
        end,
    })

    -- Store position in InfinityToolsDB
    db.Minimap = db.Minimap or { hide = false }
    LDBIcon:Register("InfinityTools", INFINITY_LDB, db.Minimap)
    LDBIcon:Refresh("InfinityTools", db.Minimap)
end

-- Minimap button is handled by InfinityRaidTools ("RRT" LDB entry)
-- C_Timer.After(0.5, InitMinimapButton)

InfinityDebug("InfinityTools core loaded")
