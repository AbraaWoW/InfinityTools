-- =============================================================
-- InfinityExport.lua - configuration import/export core engine
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end

local LibSerialize = LibStub and LibStub("LibSerialize")
local LibDeflate = LibStub and LibStub("LibDeflate")

local Export = {}
InfinityTools.Export = Export

-- Constants
local FORMAT_VERSION = 1
local MAGIC_PREFIX = "!IT1!" -- Export string prefix marker

-- =============================================================
-- Export
-- =============================================================

--- Returns the list of exportable modules.
function Export:GetExportableModules()
    local modules = {}
    local moduleList = InfinityTools.ModuleList or {}

    for _, meta in ipairs(moduleList) do
        local db = InfinityTools.DB and InfinityTools.DB.ModuleDB and InfinityTools.DB.ModuleDB[meta.Key]
        if db and next(db) then
            table.insert(modules, {
                key = meta.Key,
                name = meta.Name or meta.Key,
                desc = meta.Desc or "",
                category = meta.Category or 1,
                hasData = true,
            })
        end
    end
    return modules
end

--- Returns the player identifier.
function Export:GetPlayerIdentifier()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or "UnknownRealm"
    return name .. "-" .. realm
end

--- Exports the selected module settings.
-- @param selectedModules table Set of selected module keys { ["RevTools.MiniTools"] = true }
-- @param profileName string Profile name
-- @param authorName string|nil Custom author name, or nil to use the player name
-- @param note string|nil Optional export note
-- @return string Encoded export string
-- @return string|nil Error message
function Export:ExportModules(selectedModules, profileName, authorName, note)
    if not LibSerialize or not LibDeflate then
        return nil, "Missing required libraries: LibSerialize or LibDeflate"
    end

    -- Resolve the author name.
    local finalAuthor = authorName and authorName ~= "" and authorName or self:GetPlayerIdentifier()

    local exportData = {
        meta = {
            formatVersion = FORMAT_VERSION,
            profileName = profileName or "Unnamed Profile",
            author = finalAuthor,
            note = note or "",
            exportTime = time(),
            exportTimeStr = date("%Y-%m-%d %H:%M"),
            addonVersion = InfinityTools.VERSION or "Unknown",
            moduleCount = 0,
            enabledModules = {},
        },
        modules = {},
    }

    local count = 0
    for moduleKey, isSelected in pairs(selectedModules) do
        if isSelected then
            local db = InfinityTools.DB and InfinityTools.DB.ModuleDB and InfinityTools.DB.ModuleDB[moduleKey]
            if db then
                exportData.modules[moduleKey] = self:DeepCopy(db)
                -- Also store the module enabled state.
                local enabled = InfinityTools.DB.LoadByKey and InfinityTools.DB.LoadByKey[moduleKey]
                exportData.meta.enabledModules[moduleKey] = (enabled == true)
                count = count + 1
            end
        end
    end
    exportData.meta.moduleCount = count

    if count == 0 then
        return nil, "No modules selected or selected modules have no saved data"
    end

    -- Serialize -> compress -> encode
    local ok, serialized = pcall(function()
        return LibSerialize:Serialize(exportData)
    end)
    if not ok then
        return nil, "Serialization failed: " .. tostring(serialized)
    end

    local compressed = LibDeflate:CompressDeflate(serialized)
    if not compressed then
        return nil, "Compression failed"
    end

    local encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then
        return nil, "Encoding failed"
    end

    return MAGIC_PREFIX .. encoded, nil
end

-- =============================================================
-- Import
-- =============================================================

--- Parses an import string and returns metadata without applying it.
-- @param importString string Import string
-- @return table|nil Parsed result
-- @return string|nil Error message
function Export:ParseImportString(importString)
    if not importString or importString == "" then
        return nil, "Import string is empty"
    end

    if not LibSerialize or not LibDeflate then
        return nil, "Missing required libraries: LibSerialize or LibDeflate"
    end

    -- Trim leading/trailing whitespace.
    importString = importString:match("^%s*(.-)%s*$")

    -- Validate prefix.
    if not importString:find("^" .. MAGIC_PREFIX:gsub("!", "%%!")) then
        return nil, "Invalid import string format (missing !IT1! prefix)"
    end

    local encoded = importString:sub(#MAGIC_PREFIX + 1)
    if encoded == "" then
        return nil, "Import string content is empty"
    end

    -- Decode -> decompress -> deserialize
    local decoded = LibDeflate:DecodeForPrint(encoded)
    if not decoded then
        return nil, "String decoding failed (possibly corrupted)"
    end

    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return nil, "Data decompression failed (possibly corrupted)"
    end

    local success, data = LibSerialize:Deserialize(decompressed)
    if not success then
        return nil, "Data deserialization failed: " .. tostring(data)
    end

    -- Validate data shape.
    if type(data) ~= "table" then
        return nil, "Invalid data structure (not a table)"
    end
    if not data.meta then
        return nil, "Invalid data structure (missing metadata)"
    end
    if not data.modules then
        return nil, "Invalid data structure (missing module data)"
    end

    return data, nil
end

--- Builds an import summary for preview.
function Export:GetImportSummary(data)
    local summary = {
        profileName = data.meta.profileName or "Unnamed",
        author = data.meta.author or "Unknown",
        note = data.meta.note or "",
        exportTime = data.meta.exportTimeStr or "Unknown",
        addonVersion = data.meta.addonVersion or "Unknown",
        formatVersion = data.meta.formatVersion or 1,
        moduleCount = data.meta.moduleCount or 0,
        modules = {},
    }

    for moduleKey, _ in pairs(data.modules) do
        local meta = self:GetModuleMeta(moduleKey)
        table.insert(summary.modules, {
            key = moduleKey,
            name = meta and meta.Name or moduleKey,
            exists = meta ~= nil,
        })
    end

    -- Sort by name.
    table.sort(summary.modules, function(a, b)
        return a.name < b.name
    end)

    return summary
end

--- Applies imported module settings.
-- @param data table Parsed import data
-- @param selectedModules table Selected module keys to import { ["RevTools.MiniTools"] = true }
-- @param mergeMode string "replace" or "merge"
-- @return number Number of successfully imported modules
function Export:ApplyImport(data, selectedModules, mergeMode)
    mergeMode = mergeMode or "replace"

    if not InfinityTools.DB or not InfinityTools.DB.ModuleDB then
        return 0, "Database not initialized"
    end

    local applied = 0
    local targetDB = InfinityTools.DB.ModuleDB

    for moduleKey, isSelected in pairs(selectedModules) do
        if isSelected and data.modules[moduleKey] then
            if mergeMode == "replace" then
                targetDB[moduleKey] = self:DeepCopy(data.modules[moduleKey])
            else
                targetDB[moduleKey] = targetDB[moduleKey] or {}
                self:DeepMerge(targetDB[moduleKey], data.modules[moduleKey])
            end
            -- Sync module enabled state when present in the export payload.
            if data.meta and data.meta.enabledModules and data.meta.enabledModules[moduleKey] ~= nil then
                InfinityTools.DB.LoadByKey[moduleKey] = data.meta.enabledModules[moduleKey]
            end
            applied = applied + 1
        end
    end

    return applied
end

-- =============================================================
-- Utility helpers
-- =============================================================

function Export:DeepCopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for k, v in pairs(orig) do
            copy[self:DeepCopy(k)] = self:DeepCopy(v)
        end
        -- Do not copy the metatable to avoid carrying function references.
    else
        copy = orig
    end
    return copy
end

function Export:DeepMerge(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            self:DeepMerge(target[k], v)
        else
            target[k] = self:DeepCopy(v)
        end
    end
end

function Export:GetModuleMeta(moduleKey)
    local moduleList = InfinityTools.ModuleList or {}
    for _, meta in ipairs(moduleList) do
        if meta.Key == moduleKey then
            return meta
        end
    end
    return nil
end

-- =============================================================
-- Import success dialog
-- =============================================================
StaticPopupDialogs["INFINITY_IMPORT_SUCCESS"] = {
    text = "Import successful! Imported settings for %d module(s).\n\nA UI reload is required for all changes to take effect.",
    button1 = "Reload Now",
    button2 = "Later",
    OnAccept = function()
        C_UI.Reload()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

InfinityDebug("InfinityExport core loaded")

