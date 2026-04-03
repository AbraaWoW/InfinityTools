---@diagnostic disable: undefined-global

InfinityBoss.Voice = InfinityBoss.Voice or {}
InfinityBoss.Voice.ImportExport = InfinityBoss.Voice.ImportExport or {}
local IE = InfinityBoss.Voice.ImportExport

local PREFIX          = "INFBXC:" -- renamed from EXBXC for Infinity branding
local RAW_SENTINEL    = "RAW:"
local PAYLOAD_TYPE    = "rboss_bundle"
local PAYLOAD_VERSION = 5

local STYLE_MODULE_KEYS = {
    "InfinityBoss.TimerBar",
    "InfinityBoss.BunBar",
    "InfinityBoss.Countdown",
    "InfinityBoss.FlashText",
    "InfinityBoss.RingProgress",
}


local function DeepCopy(v)
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in pairs(v) do t[k] = DeepCopy(x) end
    return t
end

local function Trim(s)
    return tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function CountEntries(t)
    if type(t) ~= "table" then return 0 end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end


local function Serialize(v)
    local tv = type(v)
    if tv == "nil"     then return "nil" end
    if tv == "boolean" then return v and "true" or "false" end
    if tv == "number"  then return tostring(v) end
    if tv == "string"  then return string.format("%q", v) end
    if tv == "table" then
        local parts = {}
        local i = 1
        while rawget(v, i) ~= nil do
            parts[#parts + 1] = Serialize(v[i])
            i = i + 1
        end
        for k, x in pairs(v) do
            if not (type(k) == "number" and k >= 1 and k < i and math.floor(k) == k) then
                local key = (type(k) == "string" and k:match("^[%a_][%w_]*$")) and k
                            or ("[" .. Serialize(k) .. "]")
                parts[#parts + 1] = key .. "=" .. Serialize(x)
            end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "nil"
end

local function Deserialize(s)
    if type(s) ~= "string" or s == "" then return nil, "empty" end
    local loader = loadstring("return " .. s)
    if not loader then return nil, "invalid lua" end
    local ok, data = pcall(loader)
    if not ok then return nil, tostring(data) end
    if type(data) ~= "table" then return nil, "not a table" end
    return data
end


local function GetLibs()
    local ls = LibStub and LibStub("LibSerialize", true)
    local ld = LibStub and LibStub("LibDeflate", true)
    return ls, ld
end

local function EncodePayload(payload)
    local ls, ld = GetLibs()
    if ls and ld then
        local ok, serialized = pcall(function() return ls:Serialize(payload) end)
        if ok and serialized then
            local compressed = ld:CompressDeflate(serialized)
            local encoded = compressed and ld:EncodeForPrint(compressed)
            if encoded then return PREFIX .. encoded, nil end
        end
    end
    return PREFIX .. RAW_SENTINEL .. Serialize(payload), nil
end

local function DecodePayload(rawText)
    local str = Trim(rawText)
    if str == "" then return nil, "empty string" end
    if str:sub(1, #PREFIX) ~= PREFIX then
        return nil, "unsupported prefix (expected INFBXC:)"
    end
    local body = str:sub(#PREFIX + 1)
    if body:sub(1, #RAW_SENTINEL) == RAW_SENTINEL then
        return Deserialize(body:sub(#RAW_SENTINEL + 1))
    end
    local ls, ld = GetLibs()
    if not ls or not ld then return nil, "missing LibSerialize/LibDeflate" end
    local decoded = ld:DecodeForPrint(body)
    if not decoded then return nil, "decode failed" end
    local decompressed = ld:DecompressDeflate(decoded)
    if not decompressed then return nil, "decompress failed" end
    local ok, payload = ls:Deserialize(decompressed)
    if not ok or type(payload) ~= "table" then return nil, "deserialize failed" end
    return payload
end


local function CaptureAppearance()
    local out = { timer = {}, moduleDB = {}, voiceGlobal = nil }
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.timer = InfinityBossDB.timer or {}
    local timer = InfinityBossDB.timer
    if timer.timerBar    ~= nil then out.timer.timerBar    = DeepCopy(timer.timerBar)    end
    if timer.bunBar      ~= nil then out.timer.bunBar      = DeepCopy(timer.bunBar)      end
    if timer.countdown   ~= nil then out.timer.countdown   = DeepCopy(timer.countdown)   end
    if timer.flashText   ~= nil then out.timer.flashText   = DeepCopy(timer.flashText)   end
    if timer.ringProgress ~= nil then out.timer.ringProgress = DeepCopy(timer.ringProgress) end
    if type(InfinityToolsDB) == "table" and type(InfinityToolsDB.ModuleDB) == "table" then
        for _, key in ipairs(STYLE_MODULE_KEYS) do
            if InfinityToolsDB.ModuleDB[key] ~= nil then
                out.moduleDB[key] = DeepCopy(InfinityToolsDB.ModuleDB[key])
            end
        end
    end
    if type(InfinityBossDB.voice) == "table" and type(InfinityBossDB.voice.global) == "table" then
        out.voiceGlobal = DeepCopy(InfinityBossDB.voice.global)
    end
    return out
end

local SLOT_SCENE = {
    raid_tank = "raid",
    raid_dps = "raid",
    raid_heal = "raid",
    mplus_tank = "mplus",
    mplus_dps = "mplus",
    mplus_heal = "mplus",
}

local function GetBossConfig()
    local cfg = InfinityBoss and InfinityBoss.BossConfig
    if type(cfg) == "table" and type(cfg.Ensure) == "function" then
        cfg:Ensure()
        return cfg
    end
    return nil
end

local function ApplyAppearance(appearance)
    if type(appearance) ~= "table" then return false, "invalid appearance" end
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.timer = InfinityBossDB.timer or {}
    InfinityBossDB.voice = InfinityBossDB.voice or {}
    local timer = type(appearance.timer) == "table" and appearance.timer or {}
    InfinityBossDB.timer.timerBar     = DeepCopy(timer.timerBar)
    InfinityBossDB.timer.bunBar       = DeepCopy(timer.bunBar)
    InfinityBossDB.timer.countdown    = DeepCopy(timer.countdown)
    InfinityBossDB.timer.flashText    = DeepCopy(timer.flashText)
    InfinityBossDB.timer.ringProgress = DeepCopy(timer.ringProgress)
    InfinityBossDB.voice.global       = DeepCopy(appearance.voiceGlobal) or InfinityBossDB.voice.global or {}
    InfinityToolsDB = InfinityToolsDB or {}
    InfinityToolsDB.ModuleDB = InfinityToolsDB.ModuleDB or {}
    for _, key in ipairs(STYLE_MODULE_KEYS) do
        InfinityToolsDB.ModuleDB[key] = nil
    end
    if type(appearance.moduleDB) == "table" then
        for key, value in pairs(appearance.moduleDB) do
            InfinityToolsDB.ModuleDB[key] = DeepCopy(value)
        end
    end
    if InfinityBoss and InfinityBoss.UI then
        for _, name in ipairs({ "TimerBar", "BunBar", "Countdown", "FlashText", "RingProgress" }) do
            local m = InfinityBoss.UI[name]
            if m and m.RefreshVisuals then m:RefreshVisuals() end
        end
    end
    local Engine = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine
    if Engine and Engine.ApplyEventOverridesToAPI then
        Engine:ApplyEventOverridesToAPI()
    end
    return true
end


function IE:GetPlayerIdentifier()
    local name  = UnitName   and UnitName("player") or "Unknown"
    local realm = GetRealmName and GetRealmName()    or "Realm"
    return tostring(name) .. "-" .. tostring(realm)
end

function IE:DecodePayload(rawText)
    local payload, err = DecodePayload(rawText)
    if not payload then return nil, err end
    if type(payload.meta) ~= "table"
        or payload.meta.payloadType ~= PAYLOAD_TYPE
        or tonumber(payload.version) ~= PAYLOAD_VERSION then
        return nil, "unsupported payload (version=" .. tostring(payload.version)
                    .. ", expected=" .. PAYLOAD_VERSION .. ")"
    end
    return payload
end

-- options = {
--   includeAppearance = bool,
--   includeSlots      = { [slotKey] = true, ... },
--   configName        = string,
--   note              = string,
--   exporterName      = string,
-- }
function IE:Export(options)
    options = type(options) == "table" and options or {}
    local inclAppearance = (options.includeAppearance == true)
    local includeSlots = type(options.includeSlots) == "table" and options.includeSlots or {}
    local hasBossSlots = false
    for slotKey, enabled in pairs(includeSlots) do
        if enabled == true and SLOT_SCENE[slotKey] then
            hasBossSlots = true
            break
        end
    end
    if not inclAppearance and not hasBossSlots then
        return nil, "nothing selected"
    end

    local payload = {
        version = PAYLOAD_VERSION,
        meta = {
            payloadType  = PAYLOAD_TYPE,
            configName   = options.configName  or "Unnamed Config",
            exporter     = options.exporterName or self:GetPlayerIdentifier(),
            note         = options.note        or "",
            exportedAt   = date and date("%Y-%m-%d %H:%M:%S") or "",
            addonVersion = InfinityBoss and InfinityBoss.VERSION or "unknown",
        },
    }

    if inclAppearance then
        payload.appearance = CaptureAppearance()
    end

    if hasBossSlots then
        local bossCfg = GetBossConfig()
        if not bossCfg then return nil, "boss config unavailable" end
        payload.bossConfig = {}
        local mplusSlots, raidSlots = {}, {}
        for slotKey, enabled in pairs(includeSlots) do
            if enabled == true then
                local scene = SLOT_SCENE[slotKey]
                if scene == "mplus" then
                    mplusSlots[slotKey] = true
                elseif scene == "raid" then
                    raidSlots[slotKey] = true
                end
            end
        end
        if next(mplusSlots) then
            payload.bossConfig.mplus = bossCfg:ExportScene("mplus", mplusSlots)
        end
        if next(raidSlots) then
            payload.bossConfig.raid = bossCfg:ExportScene("raid", raidSlots)
        end
    end

    return EncodePayload(payload)
end

function IE:GetImportSummary(payload)
    if type(payload) ~= "table" then return nil, "invalid payload" end
    local meta = type(payload.meta) == "table" and payload.meta or {}
    if meta.payloadType ~= PAYLOAD_TYPE then return nil, "unsupported payload" end

    local summary = {
        version         = payload.version,
        configName      = meta.configName  or "Unnamed Config",
        exporter        = meta.exporter    or "Unknown",
        note            = meta.note        or "",
        exportedAt      = meta.exportedAt  or "",
        hasAppearance   = (type(payload.appearance) == "table"),
        hasMplus        = false,
        hasRaid         = false,
        mplusEventCount = 0,
        raidEventCount  = 0,
        slotAvailability = {},
        slotEventCount   = {},
    }

    local scenes = payload.bossConfig
    if type(scenes) == "table" then
        if type(scenes.mplus) == "table" then
            summary.hasMplus        = true
            local slotCount = 0
            for slotKey, slotRow in pairs((scenes.mplus.slots or {})) do
                local count = CountEntries(type(slotRow) == "table" and slotRow.events or nil)
                slotCount = slotCount + count
                summary.slotAvailability[slotKey] = true
                summary.slotEventCount[slotKey] = count
            end
            summary.mplusEventCount = slotCount
        end
        if type(scenes.raid) == "table" then
            summary.hasRaid        = true
            local slotCount = 0
            for slotKey, slotRow in pairs((scenes.raid.slots or {})) do
                local count = CountEntries(type(slotRow) == "table" and slotRow.events or nil)
                slotCount = slotCount + count
                summary.slotAvailability[slotKey] = true
                summary.slotEventCount[slotKey] = count
            end
            summary.raidEventCount = slotCount
        end
    end
    return summary
end

-- options = {
--   importAppearance = bool,
--   importSlots      = { [slotKey] = true, ... },
--   namePrefix       = string,
-- }
function IE:Import(payload, options)
    if type(payload) ~= "table" then return false, "invalid payload" end
    local summary, err = self:GetImportSummary(payload)
    if not summary then return false, err or "unsupported payload" end

    options = type(options) == "table" and options or {}
    local doAppearance = (options.importAppearance == true)
    local importSlots = type(options.importSlots) == "table" and options.importSlots or {}
    local importAuthorName = Trim(options.authorName or options.namePrefix or "")
    local wantMplus, wantRaid = false, false
    for slotKey, enabled in pairs(importSlots) do
        if enabled == true then
            local scene = SLOT_SCENE[slotKey]
            if scene == "mplus" then
                wantMplus = true
            elseif scene == "raid" then
                wantRaid = true
            end
        end
    end
    if not doAppearance and not wantMplus and not wantRaid then
        return false, "nothing selected"
    end

    local parts = {}

    if doAppearance then
        if type(payload.appearance) ~= "table" then
            return false, "payload has no appearance section"
        end
        local ok2, applyErr = ApplyAppearance(payload.appearance)
        if not ok2 then return false, applyErr end
        parts[#parts + 1] = "Appearance applied"
    end

    if wantMplus or wantRaid then
        local bossCfg = GetBossConfig()
        if not bossCfg then return false, "boss config unavailable" end
        local scenes = payload.bossConfig
        if type(scenes) ~= "table" then
            return false, "payload has no bossConfig section"
        end

        if wantMplus then
            local src = scenes.mplus
            if type(src) ~= "table" then
                return false, "payload has no mplus config"
            end
            local slotData = { selections = {}, slots = {} }
            for slotKey, enabled in pairs(importSlots) do
                if enabled == true and SLOT_SCENE[slotKey] == "mplus" then
                    if type(src.selections) == "table" and src.selections[slotKey] ~= nil then
                        slotData.selections[slotKey] = src.selections[slotKey]
                    end
                    if type(src.slots) == "table" and src.slots[slotKey] ~= nil then
                        slotData.slots[slotKey] = src.slots[slotKey]
                    end
                end
            end
            local ok2, err2 = bossCfg:ImportScene("mplus", slotData, {
                authorName = importAuthorName ~= "" and importAuthorName or (payload.meta and payload.meta.configName) or nil,
            })
            if not ok2 then return false, err2 end
            parts[#parts + 1] = "M+ slots imported"
        end
        if wantRaid then
            local src = scenes.raid
            if type(src) ~= "table" then
                return false, "payload has no raid config"
            end
            local slotData = { selections = {}, slots = {} }
            for slotKey, enabled in pairs(importSlots) do
                if enabled == true and SLOT_SCENE[slotKey] == "raid" then
                    if type(src.selections) == "table" and src.selections[slotKey] ~= nil then
                        slotData.selections[slotKey] = src.selections[slotKey]
                    end
                    if type(src.slots) == "table" and src.slots[slotKey] ~= nil then
                        slotData.slots[slotKey] = src.slots[slotKey]
                    end
                end
            end
            local ok2, err2 = bossCfg:ImportScene("raid", slotData, {
                authorName = importAuthorName ~= "" and importAuthorName or (payload.meta and payload.meta.configName) or nil,
            })
            if not ok2 then return false, err2 end
            parts[#parts + 1] = "Raid slots imported"
        end
    end

    return true, table.concat(parts, ", ")
end

function IE:ImportString(rawText, options)
    local payload, decErr = DecodePayload(rawText)
    if not payload then return false, "decode failed: " .. tostring(decErr) end
    if type(payload.meta) ~= "table"
        or payload.meta.payloadType ~= PAYLOAD_TYPE
        or tonumber(payload.version) ~= PAYLOAD_VERSION then
        return false, "unsupported payload version " .. tostring(payload.version)
    end
    if type(options) ~= "table" then
        local scenes = payload.bossConfig
        local autoSlots = {}
        local function Collect(sceneName)
            local sceneRow = type(scenes) == "table" and scenes[sceneName] or nil
            if type(sceneRow) == "table" and type(sceneRow.slots) == "table" then
                for slotKey in pairs(sceneRow.slots) do
                    autoSlots[slotKey] = true
                end
            end
        end
        Collect("mplus")
        Collect("raid")
        options = {
            importAppearance = (type(payload.appearance) == "table"),
            importSlots      = autoSlots,
        }
    end
    return self:Import(payload, options)
end
