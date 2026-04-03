---@diagnostic disable: undefined-global

local MDTMod = InfinityBoss.MDT
MDTMod.Progress = MDTMod.Progress or {}

local Progress = MDTMod.Progress

local KEYWORDS = {
    "enemy forces",
    "forces",
}

local function ParseQuantityString(text)
    text = tostring(text or "")
    local a, b = text:match("(%d+)%s*/%s*(%d+)")
    if a and b then
        return tonumber(a), tonumber(b)
    end
    local pct = text:match("(%d+%.?%d*)%%")
    if pct then
        return tonumber(pct), 100
    end
end

local function NormalizeCriteriaRecord(description, quantityString, currentQuantity, totalQuantity, isWeightedProgress)
    local quantityText = tostring(quantityString or "")
    local cur = tonumber((quantityText:gsub("%%", "")))
    local total = tonumber(totalQuantity)

    if not cur or not total or total <= 0 then
        return nil
    end
    return {
        description = tostring(description or ""),
        quantityString = tostring(quantityString or ""),
        current = cur,
        total = total,
    }
end

local function TryGetCriteriaInfo(index)
    if C_ScenarioInfo and type(C_ScenarioInfo.GetCriteriaInfo) == "function" then
        local ok, info = pcall(C_ScenarioInfo.GetCriteriaInfo, index)
        if ok and type(info) == "table" then
            local record = NormalizeCriteriaRecord(
                info.description or info.criteriaString or info.name,
                info.quantityString,
                info.curQuantity or info.quantity or info.currentQuantity,
                info.totalQuantity or info.maxQuantity,
                info.isWeightedProgress
            )
            if record then
                return record
            end
        end
    end

    if C_Scenario and type(C_Scenario.GetCriteriaInfo) == "function" then
        local ok, info = pcall(C_Scenario.GetCriteriaInfo, index)
        if ok and type(info) == "table" then
            local record = NormalizeCriteriaRecord(
                info.description or info.criteriaString or info.name,
                info.quantityString,
                info.curQuantity or info.quantity or info.currentQuantity,
                info.totalQuantity or info.maxQuantity,
                info.isWeightedProgress
            )
            if record then
                return record
            end
        end
    end

    if type(GetCriteriaInfo) == "function" then
        local ok, description, _, _, quantityString, currentQuantity, totalQuantity = pcall(GetCriteriaInfo, index)
        if ok then
            local record = NormalizeCriteriaRecord(description, quantityString, currentQuantity, totalQuantity, nil)
            if record then
                return record
            end
        end
    end
end

local function MatchesForcesCriteria(info)
    local haystack = string.lower(tostring(info.description or "") .. " " .. tostring(info.quantityString or ""))
    for _, keyword in ipairs(KEYWORDS) do
        if haystack:find(keyword, 1, true) then
            return true
        end
    end
    return false
end

function Progress.GetLiveEnemyForcesInfo()
    if C_ChallengeMode and type(C_ChallengeMode.IsChallengeModeActive) == "function" then
        local ok, active = pcall(C_ChallengeMode.IsChallengeModeActive)
        if ok and active ~= true then
            return nil
        end
    end

    local fallback = nil
    local nilCount = 0
    for idx = 1, 12 do
        local info = TryGetCriteriaInfo(idx)
        if not info then
            nilCount = nilCount + 1
            if nilCount >= 3 then
                break
            end
        else
            nilCount = 0
            if MatchesForcesCriteria(info) then
                info.percent = (info.total > 0) and (info.current / info.total * 100) or 0
                return info
            end
            if not fallback and info.total >= 100 then
                fallback = info
            end
        end
    end

    if fallback then
        fallback.percent = (fallback.total > 0) and (fallback.current / fallback.total * 100) or 0
        return fallback
    end
end

function Progress.ResolvePullIndex(snapshot, currentForces, previousIndex)
    if type(snapshot) ~= "table" or type(snapshot.pulls) ~= "table" or #snapshot.pulls == 0 then
        return nil
    end

    local value = tonumber(currentForces) or 0
    if value < 0 then
        value = 0
    end

    local resolved = #snapshot.pulls
    for idx, pull in ipairs(snapshot.pulls) do
        local cumulativeFrom = tonumber(pull.cumulativeFrom) or 0
        local cumulativeTo = tonumber(pull.cumulativeTo) or cumulativeFrom
        local pullForces = math.max(0, cumulativeTo - cumulativeFrom)
        local switchPoint = cumulativeTo
        if idx < #snapshot.pulls and pullForces > 0 then
            switchPoint = cumulativeFrom + pullForces * 0.9
        end
        if value < switchPoint then
            resolved = idx
            break
        end
    end

    local prev = tonumber(previousIndex)
    if prev and prev >= 1 and prev <= #snapshot.pulls then
        local prevPull = snapshot.pulls[prev]
        if prevPull and value >= (tonumber(prevPull.cumulativeFrom) or 0) then
            if resolved < prev then
                resolved = prev
            end
        end
    end

    return MDTMod.Clamp(resolved, 1, #snapshot.pulls)
end
