---@diagnostic disable: undefined-global

local MDTMod = InfinityBoss.MDT
MDTMod.Presets = MDTMod.Presets or {}

local Presets = MDTMod.Presets


local COLLECTIONS = {}      -- collectionKey -> { label, routes = { {key, label, mapID, importString}, ... } }
local FLAT_INDEX  = {}      -- key -> { collectionKey, route }

function Presets.RegisterCollection(collectionKey, def)
    if type(collectionKey) ~= "string" or collectionKey == "" then return end
    if type(def) ~= "table" or type(def.routes) ~= "table" then return end
    COLLECTIONS[collectionKey] = def
    for _, route in ipairs(def.routes) do
        if type(route.key) == "string" and route.key ~= "" then
            FLAT_INDEX[route.key] = { collectionKey = collectionKey, route = route }
        end
    end
end

function Presets.GetAll()
    local out = {}
    for _, def in pairs(COLLECTIONS) do
        for _, route in ipairs(def.routes) do
            out[#out + 1] = {
                key          = route.key,
                label        = route.label,
                collectionKey = route.collectionKey or def.collectionKey,
                importString = route.importString,
            }
        end
    end
    return out
end

function Presets.GetAllCollections()
    local out = {}
    for key, def in pairs(COLLECTIONS) do
        out[#out + 1] = { key = key, label = def.label, routes = def.routes }
    end
    table.sort(out, function(a, b) return tostring(a.label) < tostring(b.label) end)
    return out
end

function Presets.GetByKey(key)
    local entry = FLAT_INDEX[tostring(key or "")]
    if not entry then return nil end
    local route = entry.route
    return {
        key          = route.key,
        label        = route.label,
        collectionKey = entry.collectionKey,
        importString = route.importString,
    }
end

function Presets.GetRouteKeyByCollectionAndMapID(collectionKey, mapID)
    local def = COLLECTIONS[tostring(collectionKey or "")]
    local targetMapID = tonumber(mapID)
    if type(def) ~= "table" or type(def.routes) ~= "table" or not targetMapID then
        return nil
    end
    for _, route in ipairs(def.routes) do
        if tonumber(route.mapID) == targetMapID and type(route.key) == "string" and route.key ~= "" then
            return route.key
        end
    end
    return nil
end

function Presets.GetDefaultKey()
    for _, def in pairs(COLLECTIONS) do
        if type(def.routes) == "table" and def.routes[1] then
            return def.routes[1].key
        end
    end
    return nil
end
