---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossGUI/SettingsPage/FixedTimelinePage.lua
-- =============================================================

InfinityBoss.UI.Panel.FixedTimelinePage = InfinityBoss.UI.Panel.FixedTimelinePage or {}
local Page = InfinityBoss.UI.Panel.FixedTimelinePage

local RANGE_SECONDS = 180
local TRACK_LABEL_WIDTH = 240
local TRACK_ROW_HEIGHT = 34
local TICK_STEP_SECONDS = 30
local MAX_TICKS = math.floor(RANGE_SECONDS / TICK_STEP_SECONDS) + 1

local root
local headerFrame
local bossPane
local detailPane
local bossStatsText
local bossEmptyText
local detailTitleText
local detailMetaText
local rulerFrame
local timelineScroll
local timelineChild
local timelineEmptyText

local bossListScroll
local bossListChild
local selectedEncounterID

local bossRows = {}
local activeBossButtons = {}
local bossButtonPool = {}

local activeTimelineRows = {}
local timelineRowPool = {}

local rulerTickLines = {}
local rulerTickLabels = {}
local rulerTrackBorder
local rulerSkillLabel

local function ToNumber(v, fallback)
    local n = tonumber(v)
    if n == nil then
        return fallback
    end
    return n
end

local function Clamp(v, minV, maxV)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

local function FormatTime(sec)
    local n = math.max(0, math.floor(ToNumber(sec, 0) + 0.5))
    local m = math.floor(n / 60)
    local s = n % 60
    return string.format("%d:%02d", m, s)
end

local function ResolveSkillSpellID(skill)
    if type(skill) ~= "table" then
        return nil
    end
    return ToNumber(skill.evenSpellID) or ToNumber(skill.spellIdentifier) or ToNumber(skill.spellID)
end

local function ResolveSpellNameAndIcon(spellID)
    if not spellID then
        return nil, nil
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
        if ok and type(info) == "table" then
            return info.name, info.iconID
        end
    end
    if GetSpellInfo then
        local name, _, icon = GetSpellInfo(spellID)
        return name, icon
    end
    return nil, nil
end

local function ResolveSkillDisplay(skill)
    local sid = ResolveSkillSpellID(skill)
    local name = tostring((type(skill) == "table" and (skill.displayName or skill.name)) or "")
    local icon
    if sid then
        local spellName, spellIcon = ResolveSpellNameAndIcon(sid)
        if name == "" and type(spellName) == "string" and spellName ~= "" then
            name = spellName
        end
        icon = spellIcon
    end
    if name == "" then
        name = sid and ("Spell " .. tostring(sid)) or "Unnamed Spell"
    end
    return name, icon, sid
end

local function ExpandSkillTimes(skill, limitSec)
    local out = {}
    if type(skill) ~= "table" then
        return out
    end

    local first = ToNumber(skill.first)
    if not first or first < 0 then
        return out
    end

    local t = first
    local interval = skill.interval
    local tickCount = 0
    while t <= limitSec and tickCount < 300 do
        out[#out + 1] = t
        tickCount = tickCount + 1

        if interval == nil then
            break
        end

        local inc = nil
        if type(interval) == "table" then
            if #interval <= 0 then
                break
            end
            local idx = ((tickCount - 1) % #interval) + 1
            inc = ToNumber(interval[idx])
        else
            inc = ToNumber(interval)
        end

        if not inc or inc <= 0 then
            break
        end
        t = t + inc
    end

    return out
end

local function BuildEncounterLookup()
    local out = {}

    local encounterData = _G.InfinityBoss_ENCOUNTER_DATA
    if type(encounterData) == "table" then
        local maps = encounterData.maps
        if type(maps) ~= "table" then
            maps = encounterData
        end
        for mapID, mapRow in pairs(maps) do
            if type(mapRow) == "table" then
                local mapName = tostring(mapRow.mapName or mapRow.name or ("Unknown Dungeon " .. tostring(mapID)))
                local bosses = mapRow.bosses
                if type(bosses) == "table" then
                    for bossID, bossRow in pairs(bosses) do
                        if type(bossRow) == "table" then
                            local encounterID = ToNumber(bossRow.encounterID) or ToNumber(bossID)
                            if encounterID and not out[encounterID] then
                                out[encounterID] = {
                                    mapID = ToNumber(mapID) or mapID,
                                    mapName = mapName,
                                    bossName = tostring(bossRow.bossName or bossRow.name or ("Boss " .. tostring(encounterID))),
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    return out
end

local function BuildSkillRows(skills)
    local out = {}
    for idx, skill in ipairs(skills or {}) do
        if type(skill) == "table" then
            local name, icon, spellID = ResolveSkillDisplay(skill)
            local times = ExpandSkillTimes(skill, RANGE_SECONDS)
            out[#out + 1] = {
                index = idx,
                name = name,
                icon = icon,
                spellID = spellID,
                first = ToNumber(skill.first, 0) or 0,
                times = times,
            }
        end
    end
    table.sort(out, function(a, b)
        if a.first ~= b.first then
            return a.first < b.first
        end
        return tostring(a.name) < tostring(b.name)
    end)
    return out
end

local function BuildBossRows()
    local rows = {}
    local bosses = InfinityBoss and InfinityBoss.Timeline and InfinityBoss.Timeline._bosses
    if type(bosses) ~= "table" then
        return rows
    end

    local fixedSet = _G.InfinityBoss_FIXED_TIMELINE_ENCOUNTERS
    local hasFixedSet = type(fixedSet) == "table"
    local lookup = BuildEncounterLookup()

    for encounterKey, bossDef in pairs(bosses) do
        local encounterID = ToNumber(encounterKey)
        if encounterID and type(bossDef) == "table" and type(bossDef.skills) == "table" and #bossDef.skills > 0 then
            if (not hasFixedSet) or fixedSet[encounterID] == true then
                local info = lookup[encounterID] or {}
                local mapName = tostring(info.mapName or "Unknown Dungeon")
                local bossName = tostring(info.bossName or bossDef.name or ("Boss " .. tostring(encounterID)))
                local skillRows = BuildSkillRows(bossDef.skills)
                local markerCount = 0
                for i = 1, #skillRows do
                    markerCount = markerCount + #skillRows[i].times
                end
                rows[#rows + 1] = {
                    encounterID = encounterID,
                    mapName = mapName,
                    bossName = bossName,
                    bossDef = bossDef,
                    skillRows = skillRows,
                    skillCount = #skillRows,
                    markerCount = markerCount,
                }
            end
        end
    end

    table.sort(rows, function(a, b)
        if tostring(a.mapName) ~= tostring(b.mapName) then
            return tostring(a.mapName) < tostring(b.mapName)
        end
        if tostring(a.bossName) ~= tostring(b.bossName) then
            return tostring(a.bossName) < tostring(b.bossName)
        end
        return (a.encounterID or 0) < (b.encounterID or 0)
    end)

    return rows
end

local function AcquireBossButton()
    local btn = table.remove(bossButtonPool)
    if btn then
        return btn
    end

    btn = CreateFrame("Button", nil, bossListChild, "BackdropTemplate")
    btn:SetHeight(56)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })

    btn.leftStripe = btn:CreateTexture(nil, "BORDER")
    btn.leftStripe:SetPoint("TOPLEFT", 0, 0)
    btn.leftStripe:SetPoint("BOTTOMLEFT", 0, 0)
    btn.leftStripe:SetWidth(3)
    btn.leftStripe:SetColorTexture(1, 0.78, 0.25, 1)

    btn.nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.nameText:SetPoint("TOPLEFT", 10, -8)
    btn.nameText:SetPoint("RIGHT", -8, 0)
    btn.nameText:SetJustifyH("LEFT")
    btn.nameText:SetWordWrap(false)

    btn.metaText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.metaText:SetPoint("TOPLEFT", btn.nameText, "BOTTOMLEFT", 0, -3)
    btn.metaText:SetPoint("RIGHT", -8, 0)
    btn.metaText:SetJustifyH("LEFT")
    btn.metaText:SetTextColor(0.72, 0.78, 0.86, 1)
    btn.metaText:SetWordWrap(false)

    btn:SetScript("OnEnter", function(self)
        if self._selected then return end
        self:SetBackdropColor(0.08, 0.1, 0.14, 0.92)
        self:SetBackdropBorderColor(0.35, 0.45, 0.6, 0.9)
    end)
    btn:SetScript("OnLeave", function(self)
        if self._selected then return end
        self:SetBackdropColor(0.04, 0.05, 0.07, 0.88)
        self:SetBackdropBorderColor(0.2, 0.22, 0.28, 0.85)
    end)

    return btn
end

local function AcquireTimelineRow()
    local row = table.remove(timelineRowPool)
    if row then
        return row
    end

    row = CreateFrame("Frame", nil, timelineChild, "BackdropTemplate")
    row:SetHeight(TRACK_ROW_HEIGHT)
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(20, 20)
    row.icon:SetPoint("LEFT", 8, 0)

    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.nameText:SetPoint("LEFT", 34, 0)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(false)

    row.countText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.countText:SetPoint("RIGHT", -6, 0)
    row.countText:SetJustifyH("RIGHT")
    row.countText:SetTextColor(0.77, 0.86, 0.96, 1)

    row.track = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.track:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    row.track:SetBackdropColor(0.03, 0.05, 0.08, 0.92)

    row.ticks = {}
    for i = 1, MAX_TICKS do
        local tick = row.track:CreateTexture(nil, "BORDER")
        tick:SetWidth(1)
        tick:SetColorTexture(0.22, 0.28, 0.38, 0.65)
        row.ticks[i] = tick
    end

    row.activeMarkers = {}
    row.markerPool = {}
    return row
end

local function ReleaseTimelineRows()
    for i = 1, #activeTimelineRows do
        local row = activeTimelineRows[i]
        for j = 1, #row.activeMarkers do
            local m = row.activeMarkers[j]
            m:Hide()
            row.markerPool[#row.markerPool + 1] = m
        end
        wipe(row.activeMarkers)
        row:Hide()
        row:ClearAllPoints()
        timelineRowPool[#timelineRowPool + 1] = row
    end
    wipe(activeTimelineRows)
end

local function AcquireMarker(row)
    local m = table.remove(row.markerPool)
    if m then
        return m
    end
    m = row.track:CreateTexture(nil, "ARTWORK")
    m:SetTexture("Interface\\Buttons\\WHITE8X8")
    m:SetSize(7, 7)
    m:SetColorTexture(1.0, 0.82, 0.32, 0.95)
    return m
end

local function UpdateBossButtonStates()
    for i = 1, #activeBossButtons do
        local btn = activeBossButtons[i]
        local selected = ToNumber(btn._encounterID) == ToNumber(selectedEncounterID)
        btn._selected = selected
        if selected then
            btn:SetBackdropColor(0.12, 0.2, 0.32, 0.94)
            btn:SetBackdropBorderColor(0.32, 0.62, 0.92, 0.95)
            btn.leftStripe:Show()
            btn.nameText:SetTextColor(1, 0.87, 0.42, 1)
        else
            btn:SetBackdropColor(0.04, 0.05, 0.07, 0.88)
            btn:SetBackdropBorderColor(0.2, 0.22, 0.28, 0.85)
            btn.leftStripe:Hide()
            btn.nameText:SetTextColor(0.9, 0.9, 0.92, 1)
        end
    end
end

local function RenderRuler(labelWidth, trackWidth, totalWidth)
    if not rulerFrame then return end
    local frameW = math.max(300, totalWidth)
    rulerFrame:SetWidth(frameW)

    local leftX = labelWidth
    local rightX = labelWidth + trackWidth

    rulerTrackBorder:SetPoint("TOPLEFT", leftX, -2)
    rulerTrackBorder:SetPoint("BOTTOMRIGHT", -6, 0)

    rulerSkillLabel:SetPoint("LEFT", 10, 0)
    rulerSkillLabel:SetText("Spell")

    for i = 1, MAX_TICKS do
        local sec = (i - 1) * TICK_STEP_SECONDS
        local p = sec / RANGE_SECONDS
        local x = leftX + math.floor(p * trackWidth + 0.5)
        local line = rulerTickLines[i]
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", rulerFrame, "TOPLEFT", x, -2)
        line:SetPoint("BOTTOMLEFT", rulerFrame, "BOTTOMLEFT", x, 2)
        line:SetWidth(1)
        line:Show()

        local label = rulerTickLabels[i]
        label:ClearAllPoints()
        label:SetPoint("TOP", line, "BOTTOM", 0, -1)
        label:SetText(FormatTime(sec))
        label:Show()
    end

    rulerTickLines[MAX_TICKS]:SetPoint("TOPLEFT", rulerFrame, "TOPLEFT", rightX, -2)
    rulerTickLines[MAX_TICKS]:SetPoint("BOTTOMLEFT", rulerFrame, "BOTTOMLEFT", rightX, 2)
end

local function FindSelectedBossRow()
    for i = 1, #bossRows do
        if ToNumber(bossRows[i].encounterID) == ToNumber(selectedEncounterID) then
            return bossRows[i]
        end
    end
    return nil
end

local function RenderTimeline()
    ReleaseTimelineRows()

    local row = FindSelectedBossRow()
    if not row then
        detailTitleText:SetText("Fixed Timeline Preview")
        detailMetaText:SetText("Select a boss on the left to view the 3-minute timeline.")
        timelineEmptyText:Show()
        timelineChild:SetHeight(40)
        return
    end

    detailTitleText:SetText(string.format("%s  |  encounterID:%d", tostring(row.bossName), tonumber(row.encounterID) or 0))
    detailMetaText:SetText(string.format("%s  |  spells:%d  |  3-min markers:%d", tostring(row.mapName), tonumber(row.skillCount) or 0, tonumber(row.markerCount) or 0))

    local skillRows = row.skillRows or {}
    if #skillRows <= 0 then
        timelineEmptyText:Show()
        timelineChild:SetHeight(40)
        return
    end

    local childW = math.max(560, (timelineScroll:GetWidth() or 560) - 4)
    local trackW = math.max(220, childW - TRACK_LABEL_WIDTH - 42)
    local labelW = TRACK_LABEL_WIDTH
    local y = 0

    timelineChild:SetWidth(childW)
    RenderRuler(labelW, trackW, childW)
    timelineEmptyText:Hide()

    for i = 1, #skillRows do
        local skill = skillRows[i]
        local frame = AcquireTimelineRow()
        frame:SetParent(timelineChild)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", timelineChild, "TOPLEFT", 0, -y)
        frame:SetSize(childW, TRACK_ROW_HEIGHT - 2)
        frame:SetBackdropColor((i % 2 == 0) and 0.04 or 0.03, 0.04, 0.06, 0.86)
        frame:Show()

        frame.nameText:SetPoint("LEFT", 34, 0)
        frame.nameText:SetWidth(labelW - 44)
        frame.nameText:SetText(skill.name or ("Spell " .. tostring(i)))

        if skill.icon then
            frame.icon:SetTexture(skill.icon)
            frame.icon:Show()
        else
            frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            frame.icon:Show()
        end

        frame.track:ClearAllPoints()
        frame.track:SetPoint("LEFT", frame, "LEFT", labelW, 0)
        frame.track:SetSize(trackW, TRACK_ROW_HEIGHT - 10)

        for t = 1, MAX_TICKS do
            local tickTex = frame.ticks[t]
            local sec = (t - 1) * TICK_STEP_SECONDS
            local x = math.floor((sec / RANGE_SECONDS) * trackW + 0.5)
            tickTex:ClearAllPoints()
            tickTex:SetPoint("TOPLEFT", frame.track, "TOPLEFT", x, 0)
            tickTex:SetPoint("BOTTOMLEFT", frame.track, "BOTTOMLEFT", x, 0)
            tickTex:Show()
        end

        for j = 1, #frame.activeMarkers do
            local marker = frame.activeMarkers[j]
            marker:Hide()
            frame.markerPool[#frame.markerPool + 1] = marker
        end
        wipe(frame.activeMarkers)

        for j = 1, #(skill.times or {}) do
            local t = skill.times[j]
            local x = Clamp((t / RANGE_SECONDS) * trackW, 0, trackW)
            local marker = AcquireMarker(frame)
            marker:ClearAllPoints()
            marker:SetPoint("CENTER", frame.track, "LEFT", x, 0)
            marker:Show()
            frame.activeMarkers[#frame.activeMarkers + 1] = marker
        end

        local count = #(skill.times or {})
        if count > 0 then
            frame.countText:SetText(string.format("%d times", count))
        else
            frame.countText:SetText("1st>3:00")
        end

        activeTimelineRows[#activeTimelineRows + 1] = frame
        y = y + TRACK_ROW_HEIGHT
    end

    timelineChild:SetHeight(math.max(32, y + 8))
end

local function RefreshBossList()
    for i = 1, #activeBossButtons do
        local btn = activeBossButtons[i]
        btn:Hide()
        btn:ClearAllPoints()
        bossButtonPool[#bossButtonPool + 1] = btn
    end
    wipe(activeBossButtons)

    bossRows = BuildBossRows()
    local totalBoss = #bossRows
    local totalSkills = 0
    for i = 1, totalBoss do
        totalSkills = totalSkills + (ToNumber(bossRows[i].skillCount, 0) or 0)
    end
    bossStatsText:SetText(string.format("Fixed bosses: %d  |  Total spells: %d  |  Window: %s", totalBoss, totalSkills, FormatTime(RANGE_SECONDS)))

    local found = false
    for i = 1, totalBoss do
        if ToNumber(bossRows[i].encounterID) == ToNumber(selectedEncounterID) then
            found = true
            break
        end
    end
    if (not found) and totalBoss > 0 then
        selectedEncounterID = bossRows[1].encounterID
    end

    if totalBoss <= 0 then
        bossEmptyText:Show()
        bossListChild:SetHeight(40)
        UpdateBossButtonStates()
        return
    end

    bossEmptyText:Hide()
    local y = 0
    for i = 1, totalBoss do
        local row = bossRows[i]
        local btn = AcquireBossButton()
        btn:SetParent(bossListChild)
        btn:SetPoint("TOPLEFT", bossListChild, "TOPLEFT", 0, -y)
        btn:SetPoint("RIGHT", bossListChild, "RIGHT", -2, 0)
        btn._encounterID = row.encounterID
        btn.nameText:SetText(string.format("%s > %s", tostring(row.mapName), tostring(row.bossName)))
        btn.metaText:SetText(string.format("encounter:%d  |  spells:%d  |  markers:%d", tonumber(row.encounterID) or 0, tonumber(row.skillCount) or 0, tonumber(row.markerCount) or 0))
        btn:SetScript("OnClick", function(self)
            selectedEncounterID = self._encounterID
            UpdateBossButtonStates()
            RenderTimeline()
        end)
        btn:Show()
        activeBossButtons[#activeBossButtons + 1] = btn
        y = y + 60
    end
    bossListChild:SetHeight(math.max(40, y))
    UpdateBossButtonStates()
end

local function RefreshAll()
    if not root then return end
    RefreshBossList()
    RenderTimeline()
end

local function BuildUI(contentFrame)
    root = CreateFrame("Frame", nil, contentFrame)
    root:SetAllPoints(contentFrame)

    headerFrame = CreateFrame("Frame", nil, root, "BackdropTemplate")
    headerFrame:SetPoint("TOPLEFT", 10, -10)
    headerFrame:SetPoint("TOPRIGHT", -10, -10)
    headerFrame:SetHeight(64)
    headerFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    headerFrame:SetBackdropColor(0.08, 0.11, 0.16, 0.92)
    headerFrame:SetBackdropBorderColor(0.28, 0.45, 0.68, 0.9)

    local title = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -10)
    title:SetText("Fixed Timeline Overview")
    title:SetTextColor(1, 0.84, 0.42, 1)
    if InfinityTools and InfinityTools.MAIN_FONT then
        title:SetFont(InfinityTools.MAIN_FONT, 20, "OUTLINE")
    end

    local sub = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetText("View when each fixed-timeline spell appears in the first 3 minutes per boss, for quick pacing verification.")
    sub:SetTextColor(0.78, 0.86, 0.95, 1)

    local refreshBtn = CreateFrame("Button", nil, headerFrame, "UIPanelButtonTemplate")
    refreshBtn:SetSize(90, 24)
    refreshBtn:SetPoint("TOPRIGHT", -12, -16)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        RefreshAll()
    end)

    bossPane = CreateFrame("Frame", nil, root, "BackdropTemplate")
    bossPane:SetPoint("TOPLEFT", headerFrame, "BOTTOMLEFT", 0, -10)
    bossPane:SetPoint("BOTTOMLEFT", 10, 10)
    bossPane:SetWidth(360)
    bossPane:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    bossPane:SetBackdropColor(0.04, 0.05, 0.08, 0.92)
    bossPane:SetBackdropBorderColor(0.2, 0.25, 0.34, 0.9)

    local bossTitle = bossPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bossTitle:SetPoint("TOPLEFT", 12, -10)
    bossTitle:SetText("Boss List")
    bossTitle:SetTextColor(0.9, 0.94, 1, 1)

    bossStatsText = bossPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bossStatsText:SetPoint("TOPLEFT", bossTitle, "BOTTOMLEFT", 0, -4)
    bossStatsText:SetTextColor(0.7, 0.8, 0.92, 1)
    bossStatsText:SetText("Fixed bosses: 0")

    bossListScroll = CreateFrame("ScrollFrame", nil, bossPane, "ScrollFrameTemplate")
    if InfinityBoss.UI and InfinityBoss.UI.ApplyModernScrollBarSkin then
        InfinityBoss.UI.ApplyModernScrollBarSkin(bossListScroll)
    end
    bossListScroll:SetPoint("TOPLEFT", 10, -56)
    bossListScroll:SetPoint("BOTTOMRIGHT", -28, 10)

    bossListChild = CreateFrame("Frame", nil, bossListScroll)
    bossListChild:SetSize(320, 40)
    bossListScroll:SetScrollChild(bossListChild)

    bossEmptyText = bossListChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bossEmptyText:SetPoint("TOPLEFT", 4, -6)
    bossEmptyText:SetTextColor(0.6, 0.65, 0.72, 1)
    bossEmptyText:SetText("No fixed timeline data")
    bossEmptyText:Hide()

    detailPane = CreateFrame("Frame", nil, root, "BackdropTemplate")
    detailPane:SetPoint("TOPLEFT", bossPane, "TOPRIGHT", 10, 0)
    detailPane:SetPoint("BOTTOMRIGHT", -10, 10)
    detailPane:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    detailPane:SetBackdropColor(0.035, 0.045, 0.07, 0.93)
    detailPane:SetBackdropBorderColor(0.22, 0.28, 0.38, 0.9)

    detailTitleText = detailPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    detailTitleText:SetPoint("TOPLEFT", 12, -10)
    detailTitleText:SetTextColor(1, 0.85, 0.46, 1)
    detailTitleText:SetText("Fixed Timeline Preview")

    detailMetaText = detailPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detailMetaText:SetPoint("TOPLEFT", detailTitleText, "BOTTOMLEFT", 0, -4)
    detailMetaText:SetTextColor(0.74, 0.84, 0.96, 1)
    detailMetaText:SetText("Select a boss on the left to view the 3-minute timeline.")

    rulerFrame = CreateFrame("Frame", nil, detailPane, "BackdropTemplate")
    rulerFrame:SetPoint("TOPLEFT", 12, -52)
    rulerFrame:SetPoint("TOPRIGHT", -12, -52)
    rulerFrame:SetHeight(26)
    rulerFrame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    rulerFrame:SetBackdropColor(0.05, 0.08, 0.12, 0.88)

    rulerTrackBorder = CreateFrame("Frame", nil, rulerFrame, "BackdropTemplate")
    rulerTrackBorder:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    rulerTrackBorder:SetBackdropColor(0.08, 0.12, 0.18, 0.95)

    rulerSkillLabel = rulerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    rulerSkillLabel:SetTextColor(0.7, 0.82, 0.96, 1)

    for i = 1, MAX_TICKS do
        local line = rulerFrame:CreateTexture(nil, "ARTWORK")
        line:SetColorTexture(0.28, 0.36, 0.48, 0.85)
        rulerTickLines[i] = line

        local label = rulerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetTextColor(0.64, 0.75, 0.9, 1)
        rulerTickLabels[i] = label
    end

    timelineScroll = CreateFrame("ScrollFrame", nil, detailPane, "ScrollFrameTemplate")
    if InfinityBoss.UI and InfinityBoss.UI.ApplyModernScrollBarSkin then
        InfinityBoss.UI.ApplyModernScrollBarSkin(timelineScroll)
    end
    timelineScroll:SetPoint("TOPLEFT", rulerFrame, "BOTTOMLEFT", 0, -20)
    timelineScroll:SetPoint("BOTTOMRIGHT", detailPane, "BOTTOMRIGHT", -28, 10)

    timelineChild = CreateFrame("Frame", nil, timelineScroll)
    timelineChild:SetSize(860, 40)
    timelineScroll:SetScrollChild(timelineChild)

    timelineEmptyText = timelineChild:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timelineEmptyText:SetPoint("TOPLEFT", 6, -8)
    timelineEmptyText:SetTextColor(0.6, 0.65, 0.72, 1)
    timelineEmptyText:SetText("No timeline markers")
    timelineEmptyText:Hide()
end

function Page:Render(contentFrame)
    if not root then
        BuildUI(contentFrame)
    end
    if not root then return end

    root:SetParent(contentFrame)
    root:ClearAllPoints()
    root:SetAllPoints(contentFrame)
    root:Show()

    RefreshAll()
end

function Page:Hide()
    if root then
        root:Hide()
    end
end

