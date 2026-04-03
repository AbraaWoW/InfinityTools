---@diagnostic disable: undefined-global, undefined-field, need-check-nil
-- =============================================================
-- InfinityBossGUI/SettingsPage/VoicePackPage.lua
-- =============================================================

InfinityBoss.UI.Panel.VoicePackPage = InfinityBoss.UI.Panel.VoicePackPage or {}
local Page = InfinityBoss.UI.Panel.VoicePackPage

local root        = nil
local packDropdown = nil
local ui          = {}

local THEME = {
    accent  = { 0.733, 0.4, 1.0 },
    cyan    = { 0.24, 0.78, 1.00 },
    ok      = { 0.20, 0.95, 0.50 },
    muted   = { 0.55, 0.60, 0.68 },
    border  = { 0.18, 0.22, 0.28 },
    cardBg  = { 0.03, 0.04, 0.07 },
}


local function Bg(parent, r, g, b, a)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    f:SetBackdropColor(r or 0.03, g or 0.04, b or 0.07, a or 0.92)
    f:SetBackdropBorderColor(
        THEME.border[1], THEME.border[2], THEME.border[3], 0.95)
    return f
end

local function TopBar(parent, r, g, b)
    local t = parent:CreateTexture(nil, "BORDER")
    t:SetColorTexture(r, g, b, 0.95)
    t:SetHeight(2)
    t:SetPoint("TOPLEFT",  parent, "TOPLEFT",  6, -6)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6)
    return t
end

local function Divider(parent, anchor, offY)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetHeight(1)
    t:SetColorTexture(0.22, 0.26, 0.32, 0.85)
    t:SetPoint("TOPLEFT",  anchor, "BOTTOMLEFT",   0, offY or -10)
    t:SetPoint("TOPRIGHT", parent, "RIGHT",        -16, 0)
    return t
end

local function Chip(parent, r, g, b)
    local chip = Bg(parent, r * 0.18, g * 0.18, b * 0.18, 0.88)
    chip:SetBackdropBorderColor(r * 0.6, g * 0.6, b * 0.6, 0.90)
    local fs = chip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER")
    fs:SetTextColor(r, g, b)
    chip.label = fs
    return chip
end


local function EnsureDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.voice = InfinityBossDB.voice or {}
    InfinityBossDB.voice.global = InfinityBossDB.voice.global or {}
    local g = InfinityBossDB.voice.global
    g.selectedVoicePack = g.selectedVoicePack or "Infinity (Default)"
    return g
end

local function GetVoicePacks()
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    local seen, list = {}, {}
    if LSM then
        for key in pairs(LSM:HashTable("sound") or {}) do
            local pack = key:match("^%[([^%]]+)%]")
            if pack and not seen[pack] then
                seen[pack] = true
                list[#list + 1] = pack
            end
        end
    end
    if #list == 0 then list[1] = "Infinity (Default)" end
    table.sort(list)
    return list
end

local function SetPack(packName)
    local g = EnsureDB()
    local prev = g.selectedVoicePack
    g.selectedVoicePack = packName
    if packName ~= prev then
        local Eng = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine
        if Eng and Eng.InvalidateLabelCache then Eng:InvalidateLabelCache() end
        if Eng and Eng.ApplyEventOverridesToAPI then
            local _, t = GetInstanceInfo()
            if t == "raid" or t == "party" then
                C_Timer.After(0, function() Eng:ApplyEventOverridesToAPI() end)
            end
        end
    end
end

local PACK_META = {
    ["Infinity (Default)"] = {
        displayName = "Infinity (Default)",
        subtitle    = "InfinityBoss official default voice pack",
        description = "Covers common boss and M+ voice labels, standard reference implementation.",
        addonName   = "InfinityBossVoice",
    },
    ["Wangyou-Jingjiu"] = {
        displayName = "Wangyou Jingjiu",
        subtitle    = "Chinese Voice Pack",
        description = "Wangyou Jingjiu voice pack. Label-compatible with the default pack; can directly replace global voices.",
        addonName   = "InfinityBoss-WYJJ",
    },
    ["Guyijin-Girl"] = {
        displayName = "Guyijin / Girl Voice",
        subtitle    = "Chinese Voice Pack",
        description = "Guyijin (girl voice) version. Maintains the same label structure for easy switching.",
        addonName   = "InfinityBoss-GUYIJIN-GIRL",
    },
    ["Guyijin-Lady"] = {
        displayName = "Guyijin / Lady Voice",
        subtitle    = "Chinese Voice Pack",
        description = "Guyijin (mature voice) version. Label-compatible; fits existing preset configurations.",
        addonName   = "InfinityBoss-GUYIJIN-LADY",
    },
    ["Kele"] = {
        displayName = "Kele",
        subtitle    = "Chinese Voice Pack",
        description = "Kele voice pack. Label-compatible with the default preset; ready for dungeon configs.",
        addonName   = "InfinityBoss-KELE",
    },
    ["Xiayike"] = {
        displayName = "Xiayike",
        subtitle    = "Chinese Voice Pack",
        description = "Xiayike voice pack. Standard label-compatible; easy to switch.",
        addonName   = "InfinityBoss-XIAYIKE",
    },
    ["Ranran"] = {
        displayName = "Ranran",
        subtitle    = "Chinese Voice Pack",
        description = "Ranran voice pack. Includes standard labels and countdown voices.",
        addonName   = "InfinityBoss-RANRAN",
    },
    ["Tangtangjiang"] = {
        displayName = "Tangtangjiang",
        subtitle    = "Chinese Voice Pack",
        description = "Tangtangjiang voice pack. Label structure compatible with the default pack.",
        addonName   = "InfinityBoss-TANGTANGJIANG",
    },
    ["Yagi"] = {
        displayName = "Yagi",
        subtitle    = "Chinese Voice Pack",
        description = "Yagi voice pack. Includes standard labels and countdown voices.",
        addonName   = "InfinityBoss-YAGI",
    },
    ["Niuniu"] = {
        displayName = "Niuniu",
        subtitle    = "Chinese Voice Pack",
        description = "Niuniu voice pack (source: Niushifu). Includes standard labels and countdown voices.",
        addonName   = "InfinityBoss-NIUNIU",
    },
    ["Ayarei"] = {
        displayName = "Ayarei",
        subtitle    = "Chinese Voice Pack",
        description = "Ayarei voice pack. Uses standard label structure; compatible with default configs.",
        addonName   = "InfinityBoss-AYAREI",
    },
    ["Rurutia"] = {
        displayName = "Rurutia",
        subtitle    = "Chinese Voice Pack",
        description = "Rurutia voice pack. Label structure compatible with the default pack.",
        addonName   = "InfinityBoss-RURU",
    },
}

local function NormalizePackKey(name)
    name = tostring(name or "")
    if PACK_META[name] then return name end
    local u = name:upper()
    if u:find("WYJJ", 1, true) then return "Wangyou-Jingjiu" end
    if u:find("GUYIJIN%-GIRL", 1, true) then return "Guyijin-Girl" end
    if u:find("GUYIJIN%-LADY", 1, true) then return "Guyijin-Lady" end
    if u:find("KELE",  1, true) then return "Kele" end
    if u:find("XIAYIKE", 1, true) then return "Xiayike" end
    if u:find("RANRAN", 1, true) then return "Ranran" end
    if u:find("TANGTANGJIANG", 1, true) then return "Tangtangjiang" end
    if u:find("YAGI", 1, true) then return "Yagi" end
    if u:find("NIUNIU", 1, true) then return "Niuniu" end
    if u:find("AYAREI", 1, true) then return "Ayarei" end
    if u:find("RURU", 1, true) or u:find("RURUTIA", 1, true) then return "Rurutia" end
    if u:find("Infinity",1, true) then return "Infinity(Default)" end
    return name
end

local function GetPackInfo(packName)
    local key  = NormalizePackKey(packName)
    local base = PACK_META[key] or {}
    local addon = base.addonName
    local title, notes, author, version
    if addon and GetAddOnMetadata then
        title   = GetAddOnMetadata(addon, "Title")
        notes   = GetAddOnMetadata(addon, "Notes")
        author  = GetAddOnMetadata(addon, "Author")
        version = GetAddOnMetadata(addon, "Version")
    end
    local labelCount = 0
    local Catalog = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.LabelCatalog
    if Catalog and Catalog.GetPackLabels then
        local t = Catalog.GetPackLabels(packName)
        if type(t) == "table" then labelCount = #t end
    end
    return {
        displayName = (title ~= "" and title) or base.displayName or key,
        subtitle    = base.subtitle or "Voice Pack",
        description = (notes ~= "" and notes) or base.description or "No description",
        author      = (author ~= "" and author) or "—",
        version     = version or "—",
        labelCount  = labelCount,
    }
end

local function BuildLabelSet(labels)
    local set = {}
    for i = 1, #(labels or {}) do
        local label = tostring(labels[i] or "")
        if label ~= "" then
            set[label] = true
        end
    end
    return set
end

local function GetMissingLabelsForPack(packName)
    local Catalog = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.LabelCatalog
    if not (Catalog and Catalog.GetPackLabels) then
        return nil, "Label catalog not loaded"
    end

    local baseline = Catalog.GetPackLabels("Infinity(Default)") or {}
    local current = Catalog.GetPackLabels(packName) or {}
    local currentSet = BuildLabelSet(current)

    local missing, seen = {}, {}
    for i = 1, #baseline do
        local label = tostring(baseline[i] or "")
        if label ~= "" and not currentSet[label] and not seen[label] then
            seen[label] = true
            missing[#missing + 1] = label
        end
    end
    return missing, nil
end

local function GetProfiles()
    return InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Profiles
end

local function GetBossConfig()
    local cfg = InfinityBoss and InfinityBoss.BossConfig
    if type(cfg) == "table" and type(cfg.Ensure) == "function" then
        cfg:Ensure()
        return cfg
    end
    return nil
end

local FindItemText

local function BuildAuthorItems(slotKey)
    local bossCfg = GetBossConfig()
    if bossCfg and bossCfg.GetAuthorItems then
        return bossCfg:GetAuthorItems(slotKey)
    end
    return {}
end

local function SetDropdownValue(dropdown, items, value)
    if not dropdown then
        return
    end
    dropdown._items = items or {}
    dropdown._currentValue = value
    dropdown:SetText(FindItemText(items, value))
end

local function SetStatus(text, ok)
    if ui.cfgStatus then
        if ok == nil then
            ui.cfgStatus:SetText(text or "")
        elseif ok then
            ui.cfgStatus:SetText("|cff33ee77" .. tostring(text or "") .. "|r")
        else
            ui.cfgStatus:SetText("|cffff6666" .. tostring(text or "") .. "|r")
        end
    end
end

local SLOT_ROWS = {
    { slot = "raid_tank",  label = "Raid Tank" },
    { slot = "raid_dps",   label = "Raid DPS"  },
    { slot = "raid_heal",  label = "Raid Healer" },
    { slot = "mplus_tank", label = "M+ Tank" },
    { slot = "mplus_dps",  label = "M+ DPS"  },
    { slot = "mplus_heal", label = "M+ Healer" },
}

local function RefreshConfigInfo()
    local bossCfg = GetBossConfig()
    if not bossCfg then
        SetStatus("Boss config module not loaded", false)
        return
    end

    ui.slotDropdowns = ui.slotDropdowns or {}
    for _, row in ipairs(SLOT_ROWS) do
        local dd = ui.slotDropdowns[row.slot]
        SetDropdownValue(dd, BuildAuthorItems(row.slot), bossCfg:GetSelectedAuthor(row.slot))
    end

    local summary = bossCfg.GetSelectionSummary and bossCfg:GetSelectionSummary() or nil
    if type(summary) == "table" and ui.summaryText then
        local lines = {}
        for i = 1, #summary do
            local item = summary[i]
            lines[#lines + 1] = string.format("%s: %s", tostring(item.label or item.slotKey), tostring(item.author or "Infinity"))
        end
        local role = InfinityTools and InfinityTools.State and tostring(InfinityTools.State.RoleKey or "") or "dps"
        lines[#lines + 1] = ""
        lines[#lines + 1] = string.format("Current role: %s", role)
        ui.summaryText:SetText(table.concat(lines, "\n"))
    end
    SetStatus("6-slot author presets loaded; boss page will auto-apply the matching preset for your current role.")
end

local function ApplySlotSelection(slotKey, value)
    local bossCfg = GetBossConfig()
    if not bossCfg then
        SetStatus("Boss config module not loaded", false)
        return
    end
    local ok, err = bossCfg:SetSelectedAuthor(slotKey, value)
    SetStatus(ok and ("Switched to " .. tostring(bossCfg:GetSlotLabel(slotKey))) or ("Apply failed: " .. tostring(err)), ok)
    local BossPage = InfinityBoss and InfinityBoss.UI and InfinityBoss.UI.Panel and InfinityBoss.UI.Panel.BossPage
    if BossPage and BossPage.RefreshSpellUI then
        BossPage:RefreshSpellUI()
    end
    RefreshConfigInfo()
end

FindItemText = function(items, value)
    local target = tostring(value or "")
    for i = 1, #(items or {}) do
        local row = items[i]
        if type(row) == "table" and tostring(row[2] or "") == target then
            return tostring(row[1] or "")
        end
    end
    return "Select Config"
end

-- ─── Refresh ──────────────────────────────────────────────────

local function RefreshInfo()
    local g    = EnsureDB()
    local info = GetPackInfo(g.selectedVoicePack or "Infinity(Default)")

    ui.infoName:SetText(info.displayName)
    ui.infoSub:SetText(info.subtitle)
    ui.infoDesc:SetText(info.description)
    ui.infoAuthor:SetText(info.author)
    ui.infoVer:SetText(info.version)
    ui.chipCount.label:SetText(info.labelCount .. " labels")

    ui.activeBadge:SetText("● Active")

    local missing, err = GetMissingLabelsForPack(g.selectedVoicePack or "Infinity(Default)")
    if ui.missingCount and ui.missingList then
        if err then
            ui.missingCount:SetText("|cffff6666Missing: ?|r")
            ui.missingList:SetText(tostring(err))
            ui.missingList:SetTextColor(1.0, 0.50, 0.50)
        elseif type(missing) == "table" and #missing > 0 then
            ui.missingCount:SetText(string.format("|cffffaa55Missing: %d|r", #missing))
            ui.missingList:SetText(table.concat(missing, ", "))
            ui.missingList:SetTextColor(0.92, 0.84, 0.66)
        else
            ui.missingCount:SetText("|cff33dd88Missing: 0|r")
            ui.missingList:SetText("All default voice labels covered")
            ui.missingList:SetTextColor(0.55, 0.75, 0.60)
        end
    end
end

-- ─── BuildUI ──────────────────────────────────────────────────

local function BuildUI(contentFrame)
    local InfinityUI = _G.InfinityTools and _G.InfinityTools.UI

    for k in pairs(ui) do
        ui[k] = nil
    end

    root = CreateFrame("Frame", nil, contentFrame)
    root:SetAllPoints(contentFrame)

    do
        local bg = root:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(root)
        bg:SetColorTexture(0.012, 0.016, 0.032, 0.96)
    end

    do
        local glow = root:CreateTexture(nil, "BACKGROUND", nil, 1)
        glow:SetPoint("TOPLEFT",  root, "TOPLEFT", 0, 0)
        glow:SetPoint("TOPRIGHT", root, "TOPRIGHT", 0, 0)
        glow:SetHeight(120)
        glow:SetColorTexture(0.06, 0.10, 0.22, 0.35)
    end

    if not (InfinityUI and InfinityUI.CreateDropdown) then
        local missing = root:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        missing:SetPoint("TOPLEFT", 24, -24)
        missing:SetPoint("RIGHT", root, "RIGHT", -24, 0)
        missing:SetJustifyH("LEFT")
        missing:SetTextColor(1, 0.4, 0.4)
        missing:SetText("Voice/Config page requires InfinityTools.UI, which is not ready. Ensure InfinityCore is loaded, then reopen the panel.")
        root._missingDeps = true
        return
    end

    local hTitle = root:CreateFontString(nil, "OVERLAY")
    hTitle:SetPoint("TOPLEFT", 24, -22)
    hTitle:SetTextColor(THEME.accent[1], THEME.accent[2], THEME.accent[3])
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(hTitle, "text") end
    if _G.InfinityTools and _G.InfinityTools.MAIN_FONT then
        hTitle:SetFont(_G.InfinityTools.MAIN_FONT, 24, "OUTLINE")
    else
        hTitle:SetFontObject("GameFontNormalLarge")
    end
    hTitle:SetText("Voice / Config")

    local hEng = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hEng:SetPoint("TOPLEFT", hTitle, "TOPRIGHT", 10, -4)
    hEng:SetText("VOICE / PROFILE")
    hEng:SetTextColor(THEME.cyan[1], THEME.cyan[2], THEME.cyan[3])

    local hDesc = root:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hDesc:SetPoint("TOPLEFT", hTitle, "BOTTOMLEFT", 0, -5)
    hDesc:SetText("Select a voice pack on the left; configure author presets by role on the right.")
    hDesc:SetTextColor(0.60, 0.64, 0.72)

    local hLine = root:CreateTexture(nil, "ARTWORK")
    hLine:SetPoint("TOPLEFT",  hDesc, "BOTTOMLEFT", 0, -10)
    hLine:SetPoint("TOPRIGHT", root,  "TOPRIGHT",  -24, 0)
    hLine:SetHeight(1)
    hLine:SetColorTexture(0.22, 0.26, 0.32, 0.80)

    local leftPane = Bg(root, 0.03, 0.04, 0.07, 0.92)
    leftPane:SetPoint("TOPLEFT", root, "TOPLEFT", 24, -98)
    leftPane:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 24, 24)
    leftPane:SetWidth(560)
    local _tb1 = TopBar(leftPane, THEME.accent[1], THEME.accent[2], THEME.accent[3])
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(_tb1, "texture", 0.95) end
    ui.leftPane = leftPane

    local rightPane = Bg(root, 0.03, 0.04, 0.07, 0.92)
    rightPane:SetPoint("TOPLEFT", leftPane, "TOPRIGHT", 16, 0)
    rightPane:SetPoint("TOPRIGHT", root, "TOPRIGHT", -24, -98)
    rightPane:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -24, 24)
    TopBar(rightPane, THEME.cyan[1], THEME.cyan[2], THEME.cyan[3])
    ui.rightPane = rightPane

    local leftTitle = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftTitle:SetPoint("TOPLEFT", 14, -12)
    leftTitle:SetText("|cffffd16dVoice Pack|r")

    local dropY = -34
    local g = EnsureDB()
    local packs = GetVoicePacks()

    local dropLabel = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dropLabel:SetPoint("TOPLEFT", 16, dropY)
    dropLabel:SetText("Select Voice Pack")
    dropLabel:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3])

    packDropdown = InfinityUI:CreateDropdown(leftPane, 420, "Current Voice Pack", packs, g.selectedVoicePack, function(value)
        SetPack(value)
        RefreshInfo()
        if ui.activeBadge then
            ui.activeBadge:SetText("● Active")
        end
    end)
    packDropdown:SetPoint("TOPLEFT", leftPane, "TOPLEFT", 16, dropY - 18)
    root._packDropdown = packDropdown

    local card = Bg(leftPane, 0.03, 0.04, 0.07, 0.92)
    card:SetPoint("TOPLEFT",  leftPane, "TOPLEFT",  12, -94)
    card:SetPoint("BOTTOMRIGHT", leftPane, "BOTTOMRIGHT", -12, 12)
    local _tb2 = TopBar(card, THEME.accent[1], THEME.accent[2], THEME.accent[3])
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(_tb2, "texture", 0.95) end
    ui.card = card

    local vline = card:CreateTexture(nil, "BORDER")
    vline:SetWidth(1)
    vline:SetColorTexture(THEME.accent[1], THEME.accent[2], THEME.accent[3], 0.30)
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(vline, "texture", 0.30) end
    vline:SetPoint("TOPLEFT",    card, "TOPLEFT",    14, -14)
    vline:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 14, 14)

    ui.infoName = card:CreateFontString(nil, "OVERLAY")
    ui.infoName:SetPoint("TOPLEFT", 24, -16)
    ui.infoName:SetTextColor(THEME.accent[1], THEME.accent[2], THEME.accent[3])
    if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(ui.infoName, "text") end
    if _G.InfinityTools and _G.InfinityTools.MAIN_FONT then
        ui.infoName:SetFont(_G.InfinityTools.MAIN_FONT, 20, "OUTLINE")
    else
        ui.infoName:SetFontObject("GameFontNormalLarge")
    end
    ui.infoName:SetJustifyH("LEFT")

    ui.activeBadge = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.activeBadge:SetPoint("TOPRIGHT", -16, -16)
    ui.activeBadge:SetTextColor(THEME.ok[1], THEME.ok[2], THEME.ok[3])

    ui.infoSub = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.infoSub:SetPoint("TOPLEFT", ui.infoName, "BOTTOMLEFT", 0, -4)
    ui.infoSub:SetJustifyH("LEFT")
    ui.infoSub:SetTextColor(THEME.cyan[1], THEME.cyan[2], THEME.cyan[3])

    ui.chipCount = Chip(card, THEME.accent[1], THEME.accent[2], THEME.accent[3])
    ui.chipCount:SetSize(100, 22)
    ui.chipCount:SetPoint("TOPLEFT", ui.infoSub, "BOTTOMLEFT", 0, -10)

    local div1 = Divider(card, ui.chipCount, -10)

    local descLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descLabel:SetPoint("TOPLEFT", div1, "BOTTOMLEFT", 0, -10)
    descLabel:SetText("Description")
    descLabel:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3])

    ui.infoDesc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.infoDesc:SetPoint("TOPLEFT",  descLabel, "BOTTOMLEFT", 0, -5)
    ui.infoDesc:SetPoint("TOPRIGHT", card,      "TOPRIGHT",  -24, 0)
    ui.infoDesc:SetJustifyH("LEFT")
    ui.infoDesc:SetJustifyV("TOP")
    ui.infoDesc:SetTextColor(0.78, 0.80, 0.86)

    local div2 = Divider(card, ui.infoDesc, -10)

    local metaRow = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    metaRow:SetPoint("TOPLEFT", div2, "BOTTOMLEFT", 0, -10)
    metaRow:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3])
    metaRow:SetText("Author")

    ui.infoAuthor = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.infoAuthor:SetPoint("TOPLEFT", metaRow, "BOTTOMLEFT", 0, -4)
    ui.infoAuthor:SetJustifyH("LEFT")
    ui.infoAuthor:SetTextColor(0.85, 0.87, 0.92)

    local verLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    verLabel:SetPoint("TOPLEFT", metaRow, "TOPRIGHT", 80, 0)
    verLabel:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3])
    verLabel:SetText("Version")

    ui.infoVer = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.infoVer:SetPoint("TOPLEFT", verLabel, "BOTTOMLEFT", 0, -4)
    ui.infoVer:SetJustifyH("LEFT")
    ui.infoVer:SetTextColor(0.85, 0.87, 0.92)

    local div3 = Divider(card, ui.infoAuthor, -10)

    local missingLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    missingLabel:SetPoint("TOPLEFT", div3, "BOTTOMLEFT", 0, -10)
    missingLabel:SetText("Missing Voices")
    missingLabel:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3])

    ui.missingCount = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.missingCount:SetPoint("TOPLEFT", missingLabel, "TOPRIGHT", 12, 0)
    ui.missingCount:SetJustifyH("LEFT")
    ui.missingCount:SetTextColor(0.92, 0.84, 0.66)

    ui.missingList = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.missingList:SetPoint("TOPLEFT", missingLabel, "BOTTOMLEFT", 0, -5)
    ui.missingList:SetPoint("TOPRIGHT", card, "TOPRIGHT", -24, 0)
    ui.missingList:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 0, 16)
    ui.missingList:SetJustifyH("LEFT")
    ui.missingList:SetJustifyV("TOP")
    ui.missingList:SetTextColor(0.92, 0.84, 0.66)

    local cfgTitle = rightPane:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cfgTitle:SetPoint("TOPLEFT", 14, -12)
    cfgTitle:SetText("|cff66d0ffConfig Preset|r")

    local cfgDesc = rightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cfgDesc:SetPoint("TOPLEFT", cfgTitle, "BOTTOMLEFT", 0, -6)
    cfgDesc:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", -14, 0)
    cfgDesc:SetJustifyH("LEFT")
    cfgDesc:SetTextColor(0.70, 0.78, 0.88)
    cfgDesc:SetText("Select an author preset for each of the 6 role slots; the boss page auto-applies the matching preset for your current role.")

    ui.slotDropdowns = {}
    ui.slotGroups = {}

    local function BuildSlotGroup(groupKey, titleText, topAnchor, rows)
        local box = Bg(rightPane, 0.035, 0.04, 0.07, 0.96)
        if topAnchor == cfgDesc then
            box:SetPoint("TOPLEFT", topAnchor, "BOTTOMLEFT", -2, -16)
        else
            box:SetPoint("TOPLEFT", topAnchor, "BOTTOMLEFT", 0, -14)
        end
        box:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", -12, 0)
        box:SetHeight(148)
        TopBar(box, THEME.cyan[1], THEME.cyan[2], THEME.cyan[3])

        local title = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 14, -10)
        title:SetText(titleText)
        title:SetTextColor(THEME.accent[1], THEME.accent[2], THEME.accent[3])
        if InfinityBoss.UI.RegisterAccent then InfinityBoss.UI.RegisterAccent(title, "text") end

        local sub = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        sub:SetText(groupKey == "raid" and "Auto-applied when entering a Raid with the current role." or "Auto-applied when entering M+ with the current role.")
        sub:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3])

        local anchor = sub
        local dropdowns = {}
        for i, row in ipairs(rows) do
            local label = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, (i == 1) and -14 or -10)
            label:SetText(row.label .. " Preset")
            label:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3])
            label:SetWidth(104)
            label:SetJustifyH("LEFT")

            local dd = InfinityUI:CreateDropdown(box, 420, "", BuildAuthorItems(row.slot), "", function(value)
                ApplySlotSelection(row.slot, value)
            end)
            dd:SetPoint("LEFT", label, "RIGHT", 10, 0)
            ui.slotDropdowns[row.slot] = dd
            dropdowns[#dropdowns + 1] = dd
            anchor = label
        end

        ui.slotGroups[groupKey] = { frame = box, dropdowns = dropdowns }
        return box
    end

    local raidBox = BuildSlotGroup("raid", "|cffffd16dRaid Preset|r", cfgDesc, {
        SLOT_ROWS[1], SLOT_ROWS[2], SLOT_ROWS[3],
    })
    local mplusBox = BuildSlotGroup("mplus", "|cff66d0ffM+ Preset|r", raidBox, {
        SLOT_ROWS[4], SLOT_ROWS[5], SLOT_ROWS[6],
    })

    ui.cfgStatus = rightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.cfgStatus:SetPoint("TOPLEFT", mplusBox, "BOTTOMLEFT", 0, -12)
    ui.cfgStatus:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", -14, 0)
    ui.cfgStatus:SetJustifyH("LEFT")
    ui.cfgStatus:SetTextColor(0.65, 0.70, 0.78)
    ui.cfgStatus:SetText("")

    ui.summaryText = rightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.summaryText:SetPoint("TOPLEFT", ui.cfgStatus, "BOTTOMLEFT", 0, -10)
    ui.summaryText:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", -14, 0)
    ui.summaryText:SetJustifyH("LEFT")
    ui.summaryText:SetJustifyV("TOP")
    ui.summaryText:SetTextColor(0.85, 0.87, 0.92)

    local hint = rightPane:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", ui.summaryText, "BOTTOMLEFT", 0, -10)
    hint:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", -14, 0)
    hint:SetText("Tip: The preset for your current role is automatically used and edited.")
    hint:SetTextColor(0.45, 0.50, 0.58)
    hint:SetJustifyH("LEFT")
end


local function RefreshDropdown()
    if not packDropdown then return end
    local g     = EnsureDB()
    local packs = GetVoicePacks()
    packDropdown._items        = packs
    packDropdown._currentValue = g.selectedVoicePack
    local txt = g.selectedVoicePack or "Select..."
    packDropdown:SetText(txt)
    RefreshInfo()
    RefreshConfigInfo()
end


function Page:Render(contentFrame)
    local InfinityUI = _G.InfinityTools and _G.InfinityTools.UI
    local uiReady = InfinityUI and InfinityUI.CreateDropdown
    if root and root._missingDeps and uiReady then
        root:Hide()
        root = nil
    end
    if not root then BuildUI(contentFrame) end
    if not root then return end
    root:SetParent(contentFrame)
    root:ClearAllPoints()
    root:SetAllPoints(contentFrame)
    root:Show()
    if ui.leftPane then
        local totalW = contentFrame:GetWidth() or 1100
        local leftW = math.max(420, math.floor((totalW - 64) * 0.5))
        ui.leftPane:SetWidth(leftW)
    end
    if packDropdown then
        local leftW = (ui.leftPane and ui.leftPane:GetWidth()) or 560
        packDropdown:SetWidth(math.max(320, leftW - 32))
    end
    if ui.rightPane then
        local rightW = ui.rightPane:GetWidth() or 520
        for _, group in pairs(ui.slotGroups or {}) do
            local frame = group.frame
            if frame then
                local ddW = math.max(220, (frame:GetWidth() or rightW) - 160)
                for _, dd in ipairs(group.dropdowns or {}) do
                    if dd and dd.SetWidth then
                        dd:SetWidth(ddW)
                    end
                end
            end
        end
    end
    RefreshDropdown()
end

function Page:Hide()
    if root then root:Hide() end
end
