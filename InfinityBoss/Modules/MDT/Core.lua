---@diagnostic disable: undefined-global

InfinityBoss = InfinityBoss or {}
InfinityBoss.MDT = InfinityBoss.MDT or {}

local MDT = InfinityBoss.MDT

local DEFAULTS = {
    enabled = false,
    selectedDungeonIdx = nil,
    manualPullIndex = nil,
    followMode = "auto",
    overlay = {
        enabled = false,
        width = 360,
        height = 380,
        scale = 1,
        alpha = 0.96,
        anchorX = 540,
        anchorY = 80,
    },
    simulation = {
        enabled = false,
        progressPercent = 0,
    },
    general = {
        showCasters = true,
    },
    import = {
        selectedBuiltinKey = nil,
        collectionKey = nil,
        importedUIDs = {},
    },
    notes = {},
}

local function DeepCopy(src)
    if type(src) ~= "table" then
        return src
    end
    local out = {}
    for k, v in pairs(src) do
        out[k] = DeepCopy(v)
    end
    return out
end

local function ApplyDefaults(dst, defaults)
    if type(defaults) ~= "table" then
        return dst
    end
    dst = type(dst) == "table" and dst or {}
    for k, v in pairs(defaults) do
        if type(v) == "table" then
            dst[k] = ApplyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

function MDT.IsEnabled()
    local db = MDT.EnsureDB()
    return db.enabled ~= false
end

function MDT.EnsureDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.mdt = ApplyDefaults(InfinityBossDB.mdt, DeepCopy(DEFAULTS))
    return InfinityBossDB.mdt
end

function MDT.Clamp(value, minValue, maxValue)
    local n = tonumber(value) or minValue or 0
    if minValue ~= nil and n < minValue then
        n = minValue
    end
    if maxValue ~= nil and n > maxValue then
        n = maxValue
    end
    return n
end

function MDT.Round(value, digits)
    local n = tonumber(value) or 0
    local mult = 10 ^ (digits or 0)
    return math.floor(n * mult + 0.5) / mult
end

function MDT.NormalizeText(text)
    text = tostring(text or "")
    text = text:gsub("\r\n", "\n")
    text = text:gsub("\r", "\n")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")
    return text
end
