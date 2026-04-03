---@diagnostic disable: undefined-global

-- The localization engine is attached to the standalone global table InfinityLocale.
-- It does not depend on _G.InfinityTools (that value is only overridden by addonTable inside InfinityTools.lua).
-- After InfinityTools.lua starts, it runs: InfinityTools.L = InfinityLocale.GetProxy().

InfinityLocale = InfinityLocale or {}
_G.InfinityLocale = InfinityLocale

local Locale = InfinityLocale

Locale._appName    = "InfinityTools"
Locale._defaultLocale = "enUS"
Locale._stores        = Locale._stores or {}

local function NormalizeLocaleTag(tag)
    local locale = tostring(tag or ""):gsub("%s+", "")
    if locale == "enGB" then return "enUS" end
    return locale ~= "" and locale or "enUS"
end

Locale._currentLocale = Locale._defaultLocale

local function EnsureStore(locale)
    locale = NormalizeLocaleTag(locale)
    if not Locale._stores[locale] then
        Locale._stores[locale] = {}
    end
    return Locale._stores[locale]
end

-- Create a write proxy for a locale, used by zhCN.lua / enUS.lua.
function Locale.NewLocale(locale, isDefault)
    locale = NormalizeLocaleTag(locale)
    local store = EnsureStore(locale)
    if isDefault == true then
        Locale._defaultLocale = locale
    end
    return setmetatable({}, {
        __newindex = function(_, key, value)
            if type(key) ~= "string" or key == "" then return end
            store[key] = (value == true or value == nil) and key or tostring(value)
        end,
        __index = function(_, key)
            return store[key]
        end,
    })
end

-- L[] lookup proxy (always reads Locale._stores and does not depend on InfinityTools).
Locale._proxy = Locale._proxy or setmetatable({}, {
    __index = function(_, key)
        if type(key) ~= "string" or key == "" then return key end
        local cur = Locale._stores[Locale._currentLocale]
        if type(cur) == "table" and cur[key] ~= nil then return cur[key] end
        local def = Locale._stores[Locale._defaultLocale]
        if type(def) == "table" and def[key] ~= nil then return def[key] end
        return key -- fallback: return the key itself
    end,
})

-- Called by InfinityTools.lua to attach the proxy to addonTable.
function Locale.GetProxy()
    return Locale._proxy
end
