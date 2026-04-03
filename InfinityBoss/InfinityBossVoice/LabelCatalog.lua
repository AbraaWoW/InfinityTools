---@diagnostic disable: undefined-global

InfinityBoss = InfinityBoss or {}
InfinityBoss.Voice = InfinityBoss.Voice or {}
InfinityBoss.Voice.LabelCatalog = InfinityBoss.Voice.LabelCatalog or {}
local Catalog = InfinityBoss.Voice.LabelCatalog

local function NormalizeStandardLabel(label, triggerIndex)
    label = tostring(label or "")
    label = label:gsub("^%s+", ""):gsub("%s+$", "")
    if label == "" then
        if tonumber(triggerIndex) == 2 then
            return "54321"
        end
        return nil
    end

    local lowered = label:lower()
    if lowered == "none" then
        if tonumber(triggerIndex) == 2 then
            return "54321"
        end
        return nil
    end
    return label
end

local function BuildFactoryDefaultLabels()
    local seen = {}
    local out = {}

    local function Add(label)
        label = tostring(label or "")
        label = label:gsub("^%s+", ""):gsub("%s+$", "")
        if label == "" or seen[label] then
            return
        end
        seen[label] = true
        out[#out + 1] = label
    end

    local encounterRoot = _G.InfinityBossData and _G.InfinityBossData.GetEncounterDataRoot and _G.InfinityBossData.GetEncounterDataRoot()
    if type(encounterRoot) == "table" then
        for _, mapRow in pairs(encounterRoot) do
            if type(mapRow) == "table" and type(mapRow.bosses) == "table" then
                for _, bossRow in pairs(mapRow.bosses) do
                    if type(bossRow) == "table" and type(bossRow.events) == "table" then
                        for _, eventRow in pairs(bossRow.events) do
                            if type(eventRow) == "table" and type(eventRow.voiceLabel) == "string" then
                                Add(NormalizeStandardLabel(eventRow.voiceLabel, 1))
                            end
                        end
                    end
                end
            end
        end
    end

    Add("54321")

    if #out == 0 then
        return nil
    end

    table.sort(out, function(a, b) return a < b end)
    return out
end

local function GetGeneratedDefaultLabels()
    local built = BuildFactoryDefaultLabels()
    if type(built) == "table" and #built > 0 then
        _G.InfinityBossVoiceLabels = built
        _G.EXBV_LABELS = built
        return built
    end
    if type(_G.InfinityBossVoiceLabels) == "table" and #_G.InfinityBossVoiceLabels > 0 then
        return _G.InfinityBossVoiceLabels
    end
    if type(_G.EXBV_LABELS) == "table" and #_G.EXBV_LABELS > 0 then
        return _G.EXBV_LABELS
    end
    return nil
end

do
    local generated = BuildFactoryDefaultLabels()
    if type(generated) == "table" and #generated > 0 then
        _G.InfinityBossVoiceLabels = generated
        _G.EXBV_LABELS = generated
    end
end

local function GetLabelsFromLSM(packName)
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if not LSM then return nil end
    local tbl = LSM:HashTable("sound")
    if type(tbl) ~= "table" then return nil end
    local prefix = "[" .. tostring(packName) .. "]"
    local out = {}
    for key in pairs(tbl) do
        if key:sub(1, #prefix) == prefix then
            local label = key:sub(#prefix + 1)
            if label and label ~= "" then
                out[#out + 1] = label
            end
        end
    end
    if #out == 0 then return nil end
    table.sort(out, function(a, b) return a < b end)
    return out
end

function Catalog.GetPackLabels(packName)
    packName = tostring(packName or "")

    if packName == "Infinity(Default)" or packName == "" then
        local generatedLabels = GetGeneratedDefaultLabels()
        if generatedLabels then
            return generatedLabels
        end
    end

    local lsmLabels = GetLabelsFromLSM(packName)
    if lsmLabels then return lsmLabels end

    return {}
end

function Catalog.GetStandardLabels()
    local labels = GetGeneratedDefaultLabels()
    if labels then
        return labels
    end
    return {}
end

function Catalog.GetDropdownItems()
    local labels = Catalog.GetStandardLabels()

    local out = {}
    for _, label in ipairs(labels) do
        out[#out + 1] = { label, label }
    end
    if #out == 0 then
        out[1] = { "(No Labels)", "" }
    end
    return out
end
