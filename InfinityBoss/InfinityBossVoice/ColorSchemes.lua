---@diagnostic disable: undefined-global

InfinityBoss.Voice = InfinityBoss.Voice or {}
InfinityBoss.Voice.ColorSchemes = InfinityBoss.Voice.ColorSchemes or {}
local CS = InfinityBoss.Voice.ColorSchemes

local FIXED_ORDER = { "tank", "heal", "cooldown", "mechanic" }
local FIXED_DEFAULTS = {
    tank     = { name = "Tank Scheme",     r = 0xC6/255, g = 0x9B/255, b = 0x6C/255 },  -- #C69B6C
    heal     = { name = "Heal Scheme",     r = 0x5F/255, g = 0xFF/255, b = 0x9D/255 },  -- #5FFF9D
    cooldown = { name = "Other Scheme",    r = 0xA5/255, g = 0xAF/255, b = 0xA2/255 },  -- #A5AFA2
    mechanic = { name = "Special Mechanic",r = 0xDA/255, g = 0x5B/255, b = 0xFF/255 },  -- #DA5BFF
}
local CUSTOM_KEY = "__custom"
local EXTRA_CUSTOM_PREFIX = "__extra_custom_"
local EXTRA_CUSTOM_COUNT = 3
local EXTRA_CUSTOM_DEFAULTS = {
    [1] = { name = "Extra Scheme 1", r = 0.35, g = 0.72, b = 1.00 },
    [2] = { name = "Extra Scheme 2", r = 1.00, g = 0.58, b = 0.25 },
    [3] = { name = "Extra Scheme 3", r = 0.78, g = 0.64, b = 1.00 },
}

local function Clamp01(v, fallback)
    local n = tonumber(v)
    if not n then return fallback or 0 end
    if n < 0 then return 0 end
    if n > 1 then return 1 end
    return n
end

local function RGBToHex(r, g, b)
    local rr = math.floor(Clamp01(r, 1) * 255 + 0.5)
    local gg = math.floor(Clamp01(g, 1) * 255 + 0.5)
    local bb = math.floor(Clamp01(b, 1) * 255 + 0.5)
    return string.format("%02x%02x%02x", rr, gg, bb)
end

local function ParseExtraCustomIndex(scheme)
    local s = tostring(scheme or "")
    if s:sub(1, #EXTRA_CUSTOM_PREFIX) ~= EXTRA_CUSTOM_PREFIX then
        return nil
    end
    local idx = tonumber(s:sub(#EXTRA_CUSTOM_PREFIX + 1))
    if not idx or idx < 1 or idx > EXTRA_CUSTOM_COUNT then
        return nil
    end
    return idx
end

function CS.EnsureDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.voice = InfinityBossDB.voice or {}
    local db = InfinityBossDB.voice

    db.colorSchemes = type(db.colorSchemes) == "table" and db.colorSchemes or {}
    db.customColors = type(db.customColors) == "table" and db.customColors or {}
    db.extraCustomColors = type(db.extraCustomColors) == "table" and db.extraCustomColors or {}

    for _, key in ipairs(FIXED_ORDER) do
        local def = FIXED_DEFAULTS[key]
        local row = db.colorSchemes[key]
        if type(row) ~= "table" then
            row = {}
            db.colorSchemes[key] = row
        end
        row.name = (type(row.name) == "string" and row.name ~= "") and row.name or def.name
        row.r = Clamp01(row.r, def.r)
        row.g = Clamp01(row.g, def.g)
        row.b = Clamp01(row.b, def.b)
    end

    local c1 = db.customColors[1]
    if type(c1) ~= "table" then
        c1 = {}
        db.customColors[1] = c1
    end
    c1.name = (type(c1.name) == "string" and c1.name ~= "") and c1.name or "Custom Scheme"
    c1.r = Clamp01(c1.r, 1)
    c1.g = Clamp01(c1.g, 0.82)
    c1.b = Clamp01(c1.b, 0.25)

    for i = 1, EXTRA_CUSTOM_COUNT do
        local def = EXTRA_CUSTOM_DEFAULTS[i]
        local row = db.extraCustomColors[i]
        if type(row) ~= "table" then
            row = {}
            db.extraCustomColors[i] = row
        end
        row.enabled = (row.enabled == true)
        row.name = (type(row.name) == "string" and row.name ~= "") and row.name or def.name
        row.r = Clamp01(row.r, def.r)
        row.g = Clamp01(row.g, def.g)
        row.b = Clamp01(row.b, def.b)
    end

    return db
end

function CS.GetFixedOrder()
    return FIXED_ORDER
end

function CS.GetFixedDefaults()
    return FIXED_DEFAULTS
end

function CS.GetCustomKey()
    return CUSTOM_KEY
end

function CS.GetExtraCustomCount()
    return EXTRA_CUSTOM_COUNT
end

function CS.GetExtraCustomKey(index)
    local idx = tonumber(index)
    if not idx or idx < 1 or idx > EXTRA_CUSTOM_COUNT then
        return nil
    end
    return EXTRA_CUSTOM_PREFIX .. tostring(idx)
end

function CS.GetExtraCustomSlot(index)
    local idx = tonumber(index)
    if not idx or idx < 1 or idx > EXTRA_CUSTOM_COUNT then
        return nil
    end
    local db = CS.EnsureDB()
    return db.extraCustomColors and db.extraCustomColors[idx] or nil
end

function CS.GetSchemeDisplayName(scheme)
    if scheme == CUSTOM_KEY then
        return CS.GetCustomName()
    end
    local extraIdx = ParseExtraCustomIndex(scheme)
    if extraIdx then
        local row = CS.GetExtraCustomSlot(extraIdx)
        local def = EXTRA_CUSTOM_DEFAULTS[extraIdx]
        if type(row) == "table" and type(row.name) == "string" and row.name ~= "" then
            return row.name
        end
        return def and def.name or ("Extra Scheme " .. tostring(extraIdx))
    end

    local db = CS.EnsureDB()
    local row = db.colorSchemes and db.colorSchemes[scheme]
    local def = FIXED_DEFAULTS[scheme]
    if type(row) == "table" and type(row.name) == "string" and row.name ~= "" then
        return row.name
    end
    return (def and def.name) or tostring(scheme or "")
end

function CS.GetSchemeColor(scheme)
    if scheme == CUSTOM_KEY then
        return CS.GetCustomColor()
    end
    local extraIdx = ParseExtraCustomIndex(scheme)
    if extraIdx then
        local row = CS.GetExtraCustomSlot(extraIdx)
        local def = EXTRA_CUSTOM_DEFAULTS[extraIdx]
        if type(row) == "table" then
            return Clamp01(row.r, def and def.r or 1), Clamp01(row.g, def and def.g or 1), Clamp01(row.b, def and def.b or 1)
        end
        if def then
            return def.r, def.g, def.b
        end
        return 1, 1, 1
    end

    local db = CS.EnsureDB()
    local row = db.colorSchemes and db.colorSchemes[scheme]
    local def = FIXED_DEFAULTS[scheme]
    if type(row) == "table" then
        return Clamp01(row.r, def and def.r or 1), Clamp01(row.g, def and def.g or 1), Clamp01(row.b, def and def.b or 1)
    end
    if def then
        return def.r, def.g, def.b
    end
    return 1, 1, 1
end

function CS.GetCustomColor()
    local db = CS.EnsureDB()
    local row = db.customColors and db.customColors[1]
    if type(row) ~= "table" then
        return 1, 0.82, 0.25
    end
    return Clamp01(row.r, 1), Clamp01(row.g, 0.82), Clamp01(row.b, 0.25)
end

function CS.GetCustomName()
    local db = CS.EnsureDB()
    local row = db.customColors and db.customColors[1]
    if type(row) == "table" and type(row.name) == "string" and row.name ~= "" then
        return row.name
    end
    return "Custom Scheme"
end

function CS.BuildDropdownItems()
    local items = {}
    for _, key in ipairs(FIXED_ORDER) do
        local r, g, b = CS.GetSchemeColor(key)
        local hex = RGBToHex(r, g, b)
        items[#items + 1] = { "|cff" .. hex .. CS.GetSchemeDisplayName(key) .. "|r", key }
    end
    local cr, cg, cb = CS.GetCustomColor()
    local ch = RGBToHex(cr, cg, cb)
    items[#items + 1] = { "|cff" .. ch .. CS.GetCustomName() .. "|r", CUSTOM_KEY }

    local db = CS.EnsureDB()
    for i = 1, EXTRA_CUSTOM_COUNT do
        local row = db.extraCustomColors and db.extraCustomColors[i]
        if type(row) == "table" and row.enabled == true then
            local key = CS.GetExtraCustomKey(i)
            local r, g, b = CS.GetSchemeColor(key)
            local hex = RGBToHex(r, g, b)
            items[#items + 1] = { "|cff" .. hex .. CS.GetSchemeDisplayName(key) .. "|r", key }
        end
    end
    return items
end

function CS.NormalizeSchemeKey(scheme)
    local s = tostring(scheme or "")
    for _, key in ipairs(FIXED_ORDER) do
        if s == key then
            return s
        end
    end
    if s == CUSTOM_KEY then
        return CUSTOM_KEY
    end
    local extraIdx = ParseExtraCustomIndex(s)
    if extraIdx then
        return CS.GetExtraCustomKey(extraIdx)
    end
    return nil
end

function CS.NormalizeEventColorConfig(colorCfg)
    if type(colorCfg) ~= "table" then
        return nil
    end
    if colorCfg.enabled == nil then
        colorCfg.enabled = true
    end

    local scheme = CS.NormalizeSchemeKey(colorCfg.scheme)
    local hasRGB = (colorCfg.r ~= nil and colorCfg.g ~= nil and colorCfg.b ~= nil)
    local useCustom = (colorCfg.useCustom == true)
    if colorCfg.useCustom == nil then
        useCustom = (scheme == CUSTOM_KEY) or (scheme == nil and hasRGB)
    end

    if useCustom then
        local cr, cg, cb = CS.GetCustomColor()
        colorCfg.useCustom = true
        colorCfg.scheme = CUSTOM_KEY
        colorCfg.r = Clamp01(colorCfg.r, cr)
        colorCfg.g = Clamp01(colorCfg.g, cg)
        colorCfg.b = Clamp01(colorCfg.b, cb)
    else
        colorCfg.useCustom = false
        colorCfg.scheme = scheme or "cooldown"
    end
    return colorCfg
end

function CS.ResolveEventColor(colorCfg)
    if type(colorCfg) ~= "table" or colorCfg.enabled == false then
        return nil
    end

    local cfg = CS.NormalizeEventColorConfig(colorCfg)
    if not cfg then
        return nil
    end

    if cfg.useCustom == true or cfg.scheme == CUSTOM_KEY then
        return Clamp01(cfg.r, 1), Clamp01(cfg.g, 0.82), Clamp01(cfg.b, 0.25)
    end
    return CS.GetSchemeColor(cfg.scheme)
end
