---@diagnostic disable: undefined-global

InfinityBoss = InfinityBoss or {}
InfinityBoss.Locale = InfinityBoss.Locale or {}

local Locale = InfinityBoss.Locale

Locale._appName = "InfinityBoss"
Locale._defaultLocale = Locale._defaultLocale or "zhCN"
Locale._stores = Locale._stores or {}

local function NormalizeLocaleTag(tag)
    local locale = tostring(tag or ""):gsub("%s+", "")
    if locale == "enGB" then
        return "enUS"
    end
    return locale ~= "" and locale or "zhCN"
end

Locale._currentLocale = NormalizeLocaleTag(GetLocale and GetLocale() or "zhCN")

local function EnsureStore(locale)
    locale = NormalizeLocaleTag(locale)
    local store = Locale._stores[locale]
    if not store then
        store = {}
        Locale._stores[locale] = store
    end
    return store
end

function Locale:NewLocale(appName, locale, isDefault)
    if tostring(appName or self._appName) ~= self._appName then
        return nil
    end

    locale = NormalizeLocaleTag(locale)
    local store = EnsureStore(locale)
    if isDefault == true then
        self._defaultLocale = locale
    end

    return setmetatable({}, {
        __newindex = function(_, key, value)
            if type(key) ~= "string" or key == "" then
                return
            end
            if value == true or value == nil then
                store[key] = key
            else
                store[key] = tostring(value)
            end
        end,
        __index = function(_, key)
            return store[key]
        end,
    })
end

function Locale:GetLocale(appName)
    if tostring(appName or self._appName) ~= self._appName then
        return self._proxy
    end
    return self._proxy
end

function Locale:GetCurrentLocale()
    return self._currentLocale
end

function Locale:GetDefaultLocale()
    return self._defaultLocale
end

Locale._proxy = Locale._proxy or setmetatable({}, {
    __index = function(_, key)
        if type(key) ~= "string" or key == "" then
            return key
        end
        local current = Locale._stores[Locale._currentLocale]
        if type(current) == "table" and current[key] ~= nil then
            return current[key]
        end
        local defaultStore = Locale._stores[Locale._defaultLocale]
        if type(defaultStore) == "table" and defaultStore[key] ~= nil then
            return defaultStore[key]
        end
        return key
    end,
})

function InfinityBoss:NewLocale(locale, isDefault)
    return Locale:NewLocale(self.Locale._appName, locale, isDefault)
end

function InfinityBoss:GetLocale()
    return Locale:GetLocale(self.Locale._appName)
end

InfinityBoss.L = Locale:GetLocale(Locale._appName)
