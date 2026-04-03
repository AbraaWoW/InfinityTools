local _, RRT_NS = ...

-- ═══════════════════════════════════════════════════════════════════════════
-- DB helpers
-- ═══════════════════════════════════════════════════════════════════════════

local function GetDB()
    RRT.CustomEncounterAlerts = RRT.CustomEncounterAlerts or {}
    return RRT.CustomEncounterAlerts
end

local function NextID()
    local db, max = GetDB(), 0
    for _, a in ipairs(db) do if (a.id or 0) > max then max = a.id end end
    return max + 1
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Runtime — hooked from EventHandler after EncounterAlertStart
-- ═══════════════════════════════════════════════════════════════════════════

function RRT_NS:ProcessCustomEncounterAlerts(encID)
    local db = GetDB()
    if #db == 0 then return end
    local diff = self:DifficultyCheck(14) or 0
    for _, alert in ipairs(db) do
        if alert.enabled and alert.encID == encID then
            if alert.diff == 0 or alert.diff == diff then
                local a = self:CreateDefaultAlert(
                    alert.label   or "",
                    alert.type    or "Bar",
                    (alert.spellID and alert.spellID ~= 0) and alert.spellID or nil,
                    alert.dur     or 5,
                    alert.phase   or 1,
                    encID
                )
                if alert.tts      ~= nil  then a.TTS      = alert.tts      end
                if alert.ttsTimer ~= nil  then a.TTSTimer = alert.ttsTimer end
                if alert.countdown        then a.countdown= alert.countdown end
                if alert.sound    ~= ""   and alert.sound then a.sound = alert.sound end
                if alert.colors   ~= ""   and alert.colors then a.colors = alert.colors end
                for _, t in ipairs(alert.times or {}) do
                    a.time = t
                    self:AddToReminder(a)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Constants
-- ═══════════════════════════════════════════════════════════════════════════

local C_RED     = { 1.000, 0.300, 0.300 }
local C_GREEN   = { 0.300, 1.000, 0.500 }
local C_BG_ROW1 = { 0.09,  0.09,  0.09,  0.70 }
local C_BG_ROW2 = { 0.06,  0.06,  0.06,  0.70 }

local DIFF_VALUES = { 0, 14, 15, 16 }
local DIFF_LABELS = { "All", "Normal", "Heroic", "Mythic" }
local DIFF_MAP    = { [0]="All", [14]="Normal", [15]="Heroic", [16]="Mythic" }
local TYPE_VALUES = { "Bar", "Text", "Icon" }

local LIST_ROW_H = 44
local FORM_PAD   = 8

local BTN_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local function GetThemeRGB()
    local c = (RRT and RRT.Settings and RRT.Settings.TabSelectionColor) or {0.639, 0.188, 0.788, 1}
    return c[1], c[2], c[3]
end

local function FontSet(fs, size)
    local f, _, fl = GameFontNormalSmall:GetFont()
    if f then fs:SetFont(f, size or 9, fl or "") end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Widget helpers  (style = rest of the addon)
-- ═══════════════════════════════════════════════════════════════════════════

local function MakeLabel(parent, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    FontSet(fs, 9)
    fs:SetText(text or "")
    fs:SetTextColor(0.75, 0.75, 0.75, 1)
    return fs
end

local function MakeEditBox(parent, w, numeric, hint)
    local tR, tG, tB = GetThemeRGB()
    local f = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    f:SetSize(w, 22)
    f:SetBackdrop(BTN_BACKDROP)
    f:SetBackdropColor(0.07, 0.07, 0.07, 0.9)
    f:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    f:SetAutoFocus(false)
    f:SetFontObject("GameFontHighlightSmall")
    FontSet(f, 9)
    f:SetTextInsets(5, 5, 2, 2)
    if numeric then f:SetNumeric(true) end
    f:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(tR, tG, tB, 1)
    end)
    f:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)
    if hint then
        local ht = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        FontSet(ht, 9)
        ht:SetPoint("TOPLEFT",     f, "TOPLEFT",     5, -5)
        ht:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -5, 5)
        ht:SetTextColor(0.35, 0.35, 0.35, 1)
        ht:SetText(hint)
        ht:SetJustifyH("LEFT")
        f:SetScript("OnTextChanged", function(self)
            ht:SetShown(self:GetText() == "")
        end)
        f:SetScript("OnEditFocusGained", function(self)
            self:SetBackdropBorderColor(tR, tG, tB, 1)
            ht:Hide()
        end)
        f:SetScript("OnEditFocusLost", function(self)
            self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            ht:SetShown(self:GetText() == "")
        end)
    end
    return f
end

local function MakeCycleBtn(parent, values, labels, w)
    local idx = 1
    local tR, tG, tB = GetThemeRGB()
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w or 70, 22)
    btn:SetBackdrop(BTN_BACKDROP)
    btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    btn:SetBackdropBorderColor(tR, tG, tB, 1)

    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    FontSet(txt, 9)
    txt:SetPoint("CENTER")
    txt:SetText((labels or values)[idx])
    txt:SetTextColor(0.9, 0.9, 0.9, 1)

    btn:SetScript("OnClick", function(self)
        idx = (idx % #values) + 1
        txt:SetText((labels or values)[idx])
    end)
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 1, 1, 1)
        txt:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(tR, tG, tB, 1)
        txt:SetTextColor(0.9, 0.9, 0.9, 1)
    end)

    function btn:GetValue()  return values[idx] end
    function btn:GetLabel()  return (labels or values)[idx] end
    function btn:Reset()
        idx = 1
        txt:SetText((labels or values)[idx])
    end
    function btn:SetByValue(v)
        for i, val in ipairs(values) do
            if val == v then
                idx = i
                txt:SetText((labels or values)[idx])
                return
            end
        end
    end
    function btn:SetThemeColor(r, g, b)
        tR, tG, tB = r, g, b
        self:SetBackdropBorderColor(r, g, b, 1)
    end
    return btn
end

local function MakeActionBtn(parent, text, w, h, cr, cg, cb)
    local tR, tG, tB
    if cr then
        tR, tG, tB = cr, cg, cb
    else
        tR, tG, tB = GetThemeRGB()
    end
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w or 90, h or 24)
    btn:SetBackdrop(BTN_BACKDROP)
    btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    btn:SetBackdropBorderColor(tR, tG, tB, 1)

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    FontSet(lbl, 9)
    lbl:SetPoint("CENTER")
    lbl:SetText(text)
    lbl:SetTextColor(0.9, 0.9, 0.9, 1)

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 1, 1, 1)
        lbl:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(tR, tG, tB, 1)
        lbl:SetTextColor(0.9, 0.9, 0.9, 1)
    end)
    function btn:SetThemeColor(nr, ng, nb)
        tR, tG, tB = nr, ng, nb
        self:SetBackdropBorderColor(nr, ng, nb, 1)
    end
    return btn
end

local function MakeSeparator(parent, y)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetTexture("Interface\\Buttons\\WHITE8X8")
    sep:SetVertexColor(0.3, 0.3, 0.3, 0.5)
    sep:SetHeight(1)
    return sep
end

local function MakeSectionHeader(parent, text)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    FontSet(lbl, 9)
    lbl:SetText(text or "")
    lbl:SetTextColor(0.75, 0.75, 0.75, 1)
    lbl._sectionText = text or ""

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetVertexColor(0.3, 0.3, 0.3, 0.5)
    line:SetHeight(1)
    lbl._line = line

    return lbl, line
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Info helpers
-- ═══════════════════════════════════════════════════════════════════════════

local function GetSpellName(spellID)
    if not spellID or spellID == 0 then return nil end
    local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
    return (ok and info and info.name) or nil
end

local function GetEncounterName(encID)
    if not encID or encID == 0 then return nil end
    local ok, name = pcall(EJ_GetEncounterInfo, encID)
    return (ok and name and name ~= "") and name or nil
end

local function ParseTimers(str)
    local t = {}
    for v in (str or ""):gmatch("[^,%s]+") do
        local n = tonumber(v)
        if n then t[#t+1] = n end
    end
    return t
end

local function FormatTimerList(times)
    if #times == 0 then return "none" end
    local parts = {}
    for _, t in ipairs(times) do parts[#parts+1] = tostring(t).."s" end
    local str = table.concat(parts, ", ")
    if #str > 60 then str = str:sub(1,58) .. "..." end
    return str
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Row pool (list rows)
-- ═══════════════════════════════════════════════════════════════════════════

local rowPool = {}

local function GetOrCreateRow(content, i)
    if rowPool[i] then return rowPool[i] end
    local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
    row:SetHeight(LIST_ROW_H)
    row:SetBackdrop(BTN_BACKDROP)
    row:SetBackdropColor(0.08, 0.08, 0.08, 0.7)
    row:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.9)

    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.check:SetSize(20, 20)
    row.check:SetPoint("LEFT", row, "LEFT", 6, 0)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(32, 32)
    row.icon:SetPoint("LEFT", row.check, "RIGHT", 6, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.info = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    FontSet(row.info, 9)
    row.info:SetPoint("LEFT", row.icon, "RIGHT", 6, 2)
    row.info:SetJustifyH("LEFT")
    row.info:SetWordWrap(false)

    row.sub = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    FontSet(row.sub, 9)
    row.sub:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 6, 2)
    row.sub:SetJustifyH("LEFT")
    row.sub:SetTextColor(0.55, 0.55, 0.55, 1)

    row.del = MakeActionBtn(row, "X", 26, 20, C_RED[1], C_RED[2], C_RED[3])
    row.del:SetPoint("RIGHT", row, "RIGHT", -6, 0)

    rowPool[i] = row
    return row
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Panel builder
-- ═══════════════════════════════════════════════════════════════════════════

local function BuildCustomAlertsPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)

    local y = -FORM_PAD

    -- ── Section header: Add Custom Alert ────────────────────────────────────
    local hdrLbl, hdrLine = MakeSectionHeader(panel, " Add Custom Alert ")
    hdrLbl:SetPoint("TOPLEFT", panel, "TOPLEFT", FORM_PAD, y)
    hdrLine:SetPoint("LEFT",  hdrLbl, "RIGHT",  4, 0)
    hdrLine:SetPoint("RIGHT", panel,  "RIGHT", -FORM_PAD, 0)
    hdrLine:SetPoint("TOP",   hdrLbl, "CENTER", 0, 0)
    y = y - 20

    -- Form container
    local form = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    form:SetPoint("TOPLEFT",  panel, "TOPLEFT",  FORM_PAD, y)
    form:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -FORM_PAD, y)
    form:SetHeight(210)
    form:SetBackdrop(BTN_BACKDROP)
    form:SetBackdropColor(0.05, 0.05, 0.05, 0.6)
    form:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
    y = y - 214

    local fy = -8

    -- Row 1: EncID / SpellID / Label
    local lEnc = MakeLabel(form, "Encounter ID")
    lEnc:SetPoint("TOPLEFT", form, "TOPLEFT", 8, fy)
    local ebEnc = MakeEditBox(form, 72, true, "3181")
    ebEnc:SetPoint("TOPLEFT", lEnc, "BOTTOMLEFT", 0, -3)
    ebEnc:SetMaxLetters(10)

    local lSpell = MakeLabel(form, "Spell ID")
    lSpell:SetPoint("TOPLEFT", form, "TOPLEFT", 96, fy)
    local ebSpell = MakeEditBox(form, 90, true, "0")
    ebSpell:SetPoint("TOPLEFT", lSpell, "BOTTOMLEFT", 0, -3)

    local lLbl = MakeLabel(form, "Label")
    lLbl:SetPoint("TOPLEFT", form, "TOPLEFT", 202, fy)
    local ebLabel = MakeEditBox(form, 160, false, "Explosion")
    ebLabel:SetPoint("TOPLEFT", lLbl, "BOTTOMLEFT", 0, -3)
    ebLabel:SetMaxLetters(48)
    fy = fy - 42

    -- Row 2: Type / Dur / Phase / Difficulty
    local lType = MakeLabel(form, "Type")
    lType:SetPoint("TOPLEFT", form, "TOPLEFT", 8, fy)
    local btnType = MakeCycleBtn(form, TYPE_VALUES, nil, 58)
    btnType:SetPoint("TOPLEFT", lType, "BOTTOMLEFT", 0, -3)

    local lDur = MakeLabel(form, "Dur (s)")
    lDur:SetPoint("TOPLEFT", form, "TOPLEFT", 80, fy)
    local ebDur = MakeEditBox(form, 44, true, "5")
    ebDur:SetPoint("TOPLEFT", lDur, "BOTTOMLEFT", 0, -3)
    ebDur:SetText("5")

    local lPhase = MakeLabel(form, "Phase")
    lPhase:SetPoint("TOPLEFT", form, "TOPLEFT", 152, fy)
    local ebPhase = MakeEditBox(form, 38, true, "1")
    ebPhase:SetPoint("TOPLEFT", lPhase, "BOTTOMLEFT", 0, -3)
    ebPhase:SetText("1")

    local lDiff = MakeLabel(form, "Difficulty")
    lDiff:SetPoint("TOPLEFT", form, "TOPLEFT", 206, fy)
    local btnDiff = MakeCycleBtn(form, DIFF_VALUES, DIFF_LABELS, 74)
    btnDiff:SetPoint("TOPLEFT", lDiff, "BOTTOMLEFT", 0, -3)
    fy = fy - 42

    -- Row 3: Timers
    local lTimes = MakeLabel(form, "Timers — seconds from phase start, comma-separated  (e.g. 33, 53, 75, 95)")
    lTimes:SetPoint("TOPLEFT", form, "TOPLEFT", 8, fy)
    local ebTimes = MakeEditBox(form, 360, false, "33,53,75,95,117")
    ebTimes:SetPoint("TOPLEFT", lTimes, "BOTTOMLEFT", 0, -3)
    ebTimes:SetMaxLetters(300)
    fy = fy - 38

    -- Row 4: TTS / TTSTimer / Countdown
    local lTTS = MakeLabel(form, "TTS  (blank = off)")
    lTTS:SetPoint("TOPLEFT", form, "TOPLEFT", 8, fy)
    local ebTTS = MakeEditBox(form, 158, false, "Explosion!")
    ebTTS:SetPoint("TOPLEFT", lTTS, "BOTTOMLEFT", 0, -3)

    local lTTST = MakeLabel(form, "TTS timer (s)")
    lTTST:SetPoint("TOPLEFT", form, "TOPLEFT", 178, fy)
    local ebTTSTimer = MakeEditBox(form, 52, true, "")
    ebTTSTimer:SetPoint("TOPLEFT", lTTST, "BOTTOMLEFT", 0, -3)

    local lCD = MakeLabel(form, "Countdown (s)")
    lCD:SetPoint("TOPLEFT", form, "TOPLEFT", 244, fy)
    local ebCD = MakeEditBox(form, 52, true, "")
    ebCD:SetPoint("TOPLEFT", lCD, "BOTTOMLEFT", 0, -3)
    fy = fy - 38

    -- Row 5: Sound / Colors
    local lSound = MakeLabel(form, "Sound  (LSM name)")
    lSound:SetPoint("TOPLEFT", form, "TOPLEFT", 8, fy)
    local ebSound = MakeEditBox(form, 168, false, "")
    ebSound:SetPoint("TOPLEFT", lSound, "BOTTOMLEFT", 0, -3)

    local lColors = MakeLabel(form, "Bar color  (R G B A)")
    lColors:SetPoint("TOPLEFT", form, "TOPLEFT", 192, fy)
    local ebColors = MakeEditBox(form, 168, false, "")
    ebColors:SetPoint("TOPLEFT", lColors, "BOTTOMLEFT", 0, -3)

    -- Info / preview row
    local infoBox = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    infoBox:SetPoint("TOPLEFT",  panel, "TOPLEFT",  FORM_PAD, y)
    infoBox:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -FORM_PAD, y)
    infoBox:SetHeight(38)
    infoBox:SetBackdrop(BTN_BACKDROP)
    infoBox:SetBackdropColor(0.04, 0.06, 0.04, 0.85)
    infoBox:SetBackdropBorderColor(0.2, 0.5, 0.2, 0.7)
    y = y - 42

    local infoIcon = infoBox:CreateTexture(nil, "ARTWORK")
    infoIcon:SetSize(28, 28)
    infoIcon:SetPoint("LEFT", infoBox, "LEFT", 6, 0)
    infoIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    infoIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    local infoText = infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    FontSet(infoText, 9)
    infoText:SetPoint("LEFT",  infoIcon, "RIGHT", 6, 2)
    infoText:SetPoint("RIGHT", infoBox,  "RIGHT", -8, 0)
    infoText:SetJustifyH("LEFT")
    infoText:SetWordWrap(true)
    infoText:SetText("|cFF888888Enter an Encounter ID and Spell ID to see a preview.|r")

    local function UpdateInfoPreview()
        local encID_   = tonumber(ebEnc:GetText())
        local spellID_ = tonumber(ebSpell:GetText())
        local times_   = ParseTimers(ebTimes:GetText())
        local type_    = btnType:GetValue()
        local phase_   = tonumber(ebPhase:GetText()) or 1
        local diff_    = btnDiff:GetLabel()
        local spellName = GetSpellName(spellID_)
        local encName   = GetEncounterName(encID_)
        if spellID_ and spellID_ ~= 0 then
            local ok, si = pcall(C_Spell.GetSpellInfo, spellID_)
            if ok and si and si.iconID then
                infoIcon:SetTexture(si.iconID)
            else
                infoIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
        else
            infoIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        local line1 = ""
        if spellID_ and spellID_ ~= 0 then
            line1 = "|cFFFFD700Spell:|r " .. (spellName and ("|cFFFFFFFF"..spellName.."|r") or "|cFFFF4444Unknown spell "..spellID_.."|r")
        else
            line1 = "|cFF888888No spell ID - will display as text only|r"
        end
        local line2 = ""
        if encID_ and encID_ ~= 0 then
            local eName = encName and ("|cFFFFFFFF"..encName.."|r") or ("|cFFFF8844enc "..encID_.." (unknown)|r")
            line2 = "-> |cFFBB66FF" .. type_ .. "|r in " .. eName .. "  Phase |cFF88FF88" .. phase_ .. "|r  |cFFAAAAAA" .. diff_ .. "|r  |cFFFFD700" .. #times_ .. " timer(s):|r " .. FormatTimerList(times_)
        else
            line2 = "|cFF888888Fill Encounter ID to see full preview.|r"
        end
        infoText:SetText(line1 .. "\n" .. line2)
    end

    local function Throttle(eb)
        local orig = eb:GetScript("OnTextChanged")
        eb:SetScript("OnTextChanged", function(self, ...)
            if orig then orig(self, ...) end
            UpdateInfoPreview()
        end)
    end
    Throttle(ebEnc); Throttle(ebSpell); Throttle(ebTimes)
    local origTypeClick = btnType:GetScript("OnClick")
    btnType:SetScript("OnClick", function(self, ...)
        if origTypeClick then origTypeClick(self, ...) end
        UpdateInfoPreview()
    end)
    local origDiffClick = btnDiff:GetScript("OnClick")
    btnDiff:SetScript("OnClick", function(self, ...)
        if origDiffClick then origDiffClick(self, ...) end
        UpdateInfoPreview()
    end)

    -- Action buttons + status
    local btnTest = MakeActionBtn(panel, "> Test Preview", 110, 26, C_GREEN[1], C_GREEN[2], C_GREEN[3])
    btnTest:SetPoint("TOPLEFT", panel, "TOPLEFT", FORM_PAD, y)

    local btnAdd = MakeActionBtn(panel, "+ Add Alert", 100, 26)
    btnAdd:SetPoint("LEFT", btnTest, "RIGHT", 8, 0)

    local statusFS = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    FontSet(statusFS, 9)
    statusFS:SetPoint("LEFT", btnAdd, "RIGHT", 12, 0)
    statusFS:SetText("")

    local function SetStatus(msg, r, g, b)
        statusFS:SetText(msg)
        statusFS:SetTextColor(r or 1, g or 1, b or 1, 1)
        C_Timer.After(4, function() statusFS:SetText("") end)
    end

    y = y - 34

    -- ── Section header: Saved Custom Alerts ─────────────────────────────────
    local hdr2Lbl, hdr2Line = MakeSectionHeader(panel, " Saved Custom Alerts ")
    hdr2Lbl:SetPoint("TOPLEFT", panel, "TOPLEFT", FORM_PAD, y)
    hdr2Line:SetPoint("LEFT",  hdr2Lbl, "RIGHT",  4, 0)
    hdr2Line:SetPoint("RIGHT", panel,   "RIGHT", -FORM_PAD, 0)
    hdr2Line:SetPoint("TOP",   hdr2Lbl, "CENTER", 0, 0)
    y = y - 18

    local emptyLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    FontSet(emptyLabel, 9)
    emptyLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", FORM_PAD + 4, y)
    emptyLabel:SetText("No custom alerts yet - add one above.")
    emptyLabel:SetTextColor(0.45, 0.45, 0.45, 1)

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     panel, "TOPLEFT",     FORM_PAD, y)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 6)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)

    scrollFrame:SetScript("OnSizeChanged", function(self, w)
        content:SetWidth(w)
        for _, row in ipairs(rowPool) do row:SetWidth(w) end
    end)

    local function RefreshList()
        local db = GetDB()
        emptyLabel:SetShown(#db == 0)
        scrollFrame:SetShown(#db > 0)
        for i, alert in ipairs(db) do
            local row = GetOrCreateRow(content, i)
            row:SetWidth(content:GetWidth())
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i-1)*(LIST_ROW_H+2))
            row:Show()
            local r2 = (i % 2 == 0)
            row:SetBackdropColor(r2 and 0.09 or 0.06, r2 and 0.09 or 0.06, r2 and 0.09 or 0.06, 0.7)
            local sName = GetSpellName(alert.spellID)
            if alert.spellID and alert.spellID ~= 0 then
                local ok, si = pcall(C_Spell.GetSpellInfo, alert.spellID)
                if ok and si and si.iconID then
                    row.icon:SetTexture(si.iconID)
                    row.icon:Show()
                else
                    row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    row.icon:Show()
                end
            else
                row.icon:SetTexture("Interface\\Icons\\Ability_Warrior_VictoryRush")
                row.icon:Show()
            end
            row.check:SetChecked(alert.enabled)
            row.check:SetScript("OnClick", function(self)
                alert.enabled = self:GetChecked()
            end)
            local encName_ = GetEncounterName(alert.encID)
            local nameStr  = encName_ and ("|cFFFFFFFF"..encName_.."|r") or ("enc:|cFFFFD700"..tostring(alert.encID).."|r")
            local spellStr = sName and ("|cFFFFFFFF"..sName.."|r") or
                ((alert.spellID and alert.spellID ~= 0) and tostring(alert.spellID) or "|cFF888888text|r")
            local w = content:GetWidth() - 100
            row.info:SetWidth(w)
            row.info:SetText("|cFFBB66FF" .. (alert.label or "?") .. "|r  " .. nameStr .. "  " .. spellStr .. "  |cFF88FF88" .. (alert.type or "Bar") .. "|r")
            local timesStr = FormatTimerList(alert.times or {})
            local extras = {}
            if alert.tts   and alert.tts   ~= "" then extras[#extras+1] = "TTS"   end
            if alert.sound and alert.sound ~= "" then extras[#extras+1] = "Sound" end
            if alert.colors and alert.colors ~= "" then extras[#extras+1] = "Color" end
            local extraStr = (#extras > 0) and ("  |cFFFFD700[" .. table.concat(extras, ",") .. "]|r") or ""
            row.sub:SetWidth(w)
            row.sub:SetText("Phase |cFF88FF88" .. tostring(alert.phase or 1) .. "|r  " .. (DIFF_MAP[alert.diff] or "?") .. "  |cFFFFD700" .. #(alert.times or {}) .. " timer(s):|r " .. timesStr .. extraStr)
            local idx = i
            row.del:SetScript("OnClick", function()
                table.remove(db, idx)
                RefreshList()
                SetStatus("Alert removed.", C_RED[1], C_RED[2], C_RED[3])
            end)
        end
        for i = #db+1, #rowPool do rowPool[i]:Hide() end
        content:SetHeight(math.max(1, #db * (LIST_ROW_H+2)))
    end

    panel:SetScript("OnShow", function()
        RefreshList()
        UpdateInfoPreview()
    end)

    -- Test button
    btnTest:SetScript("OnClick", function()
        local spellID_ = tonumber(ebSpell:GetText())
        local label_   = ebLabel:GetText()
        if label_ == "" then label_ = spellID_ and GetSpellName(spellID_) or "Test Alert" end
        local dur_   = tonumber(ebDur:GetText()) or 5
        local phase_ = tonumber(ebPhase:GetText()) or 1
        local type_  = btnType:GetValue()
        local prevDebug = RRT.Settings["Debug"]
        RRT.Settings["Debug"] = true
        RRT_NS.PlayedSound      = RRT_NS.PlayedSound      or {}
        RRT_NS.StartedCountdown = RRT_NS.StartedCountdown or {}
        RRT_NS.GlowStarted      = RRT_NS.GlowStarted      or {}
        RRT_NS.DefaultAlertID   = (RRT_NS.DefaultAlertID  or 10000) + 1
        local info = {
            notsticky    = true,
            BarOverwrite = (type_ == "Bar"),
            IconOverwrite= (type_ == "Icon"),
            TTSTimer     = tonumber(ebTTSTimer:GetText()) or dur_,
            phase        = phase_,
            id           = RRT_NS.DefaultAlertID,
            time         = dur_,
            text         = label_,
            spellID      = (spellID_ and spellID_ ~= 0) and spellID_ or nil,
            dur          = dur_,
            IsAlert      = true,
        }
        local tts = ebTTS:GetText()
        if tts ~= "" then info.TTS = tts end
        local cd = tonumber(ebCD:GetText())
        if cd then info.countdown = cd end
        local snd = ebSound:GetText()
        if snd ~= "" then info.sound = snd end
        local col = ebColors:GetText()
        if col ~= "" then info.colors = col end
        RRT_NS:DisplayReminder(info)
        RRT.Settings["Debug"] = prevDebug
        SetStatus("Showing preview...", C_GREEN[1], C_GREEN[2], C_GREEN[3])
    end)

    -- Add button
    btnAdd:SetScript("OnClick", function()
        local encID_   = tonumber(ebEnc:GetText())
        local spellID_ = tonumber(ebSpell:GetText()) or 0
        local label_   = ebLabel:GetText()
        local dur_     = tonumber(ebDur:GetText()) or 5
        local phase_   = tonumber(ebPhase:GetText()) or 1
        local diff_    = btnDiff:GetValue()
        local times_   = ParseTimers(ebTimes:GetText())
        local tts_     = ebTTS:GetText()
        local ttsT_    = tonumber(ebTTSTimer:GetText())
        local cd_      = tonumber(ebCD:GetText())
        local snd_     = ebSound:GetText()
        local col_     = ebColors:GetText()
        if not encID_ or encID_ == 0 then
            SetStatus("! Encounter ID is required.", C_RED[1], C_RED[2], C_RED[3]); return
        end
        if #times_ == 0 then
            SetStatus("! At least one timer is required.", C_RED[1], C_RED[2], C_RED[3]); return
        end
        if label_ == "" then
            label_ = GetSpellName(spellID_) or (spellID_ ~= 0 and tostring(spellID_) or "Alert")
        end
        local entry = {
            id      = NextID(),
            encID   = encID_,
            spellID = spellID_,
            label   = label_,
            type    = btnType:GetValue(),
            dur     = dur_,
            phase   = phase_,
            diff    = diff_,
            times   = times_,
            enabled = true,
        }
        if tts_  ~= "" then entry.tts       = tts_  end
        if ttsT_        then entry.ttsTimer  = ttsT_ end
        if cd_          then entry.countdown = cd_   end
        if snd_  ~= "" then entry.sound     = snd_  end
        if col_  ~= "" then entry.colors    = col_  end
        GetDB()[#GetDB()+1] = entry
        ebEnc:SetText(""); ebSpell:SetText(""); ebLabel:SetText("")
        ebTimes:SetText(""); ebDur:SetText("5"); ebPhase:SetText("1")
        ebTTS:SetText(""); ebTTSTimer:SetText(""); ebCD:SetText("")
        ebSound:SetText(""); ebColors:SetText("")
        btnType:Reset(); btnDiff:Reset()
        RefreshList()
        UpdateInfoPreview()
        local encName_ = GetEncounterName(encID_)
        SetStatus("Added to " .. (encName_ or ("enc "..encID_)) .. " - Phase " .. phase_ .. " (" .. #times_ .. " timers)", C_GREEN[1], C_GREEN[2], C_GREEN[3])
    end)

    -- Theme color support
    local function ApplyTheme(r, g, b)
        local hex = string.format("%02X%02X%02X", math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5))
        hdrLbl:SetText("|cFF" .. hex .. " Add Custom Alert |r")
        hdrLbl._line:SetVertexColor(r, g, b, 0.4)
        hdr2Lbl:SetText("|cFF" .. hex .. " Saved Custom Alerts |r")
        hdr2Lbl._line:SetVertexColor(r, g, b, 0.4)
        btnType:SetThemeColor(r, g, b)
        btnDiff:SetThemeColor(r, g, b)
        btnAdd:SetThemeColor(r, g, b)
    end

    ApplyTheme(GetThemeRGB())

    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b, a)
        ApplyTheme(r, g, b)
    end)

    return panel
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Export
-- ═══════════════════════════════════════════════════════════════════════════
RRT_NS.BuildCustomEncounterAlertsPanel = BuildCustomAlertsPanel
