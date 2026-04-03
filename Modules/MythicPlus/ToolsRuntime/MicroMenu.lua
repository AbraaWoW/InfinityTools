-- =============================================================
-- Comment translated to English
-- Comment translated to English
-- =============================================================
local RRTToolsCore = _G.RRTToolsCore
local InfinityDB = _G.InfinityDB
if not RRTToolsCore then return end

local RRT_MODULE_KEY = "RRTTools.MicroMenu"

-- =============================================================
-- Comment translated to English
-- Comment translated to English
-- Comment translated to English
-- Comment translated to English
-- =============================================================
local ACTION_LIST = {
-- Comment translated to English
-- Comment translated to English
-- Comment translated to English
-- Comment translated to English
    { id = "none", label = "(None)", atlas = nil },
    {
        id = "character",
        label = "Character",
        atlas = "UI-HUD-MicroMenu-GameMenu-Up",
        action = function()
            ToggleCharacter(
                "PaperDollFrame")
        end
    },
    {
        id = "spellbook",
        label = "Spellbook/Talents",
        atlas = "UI-HUD-MicroMenu-SpecTalents-Up",
        action = function()
            TogglePlayerSpellsFrame()
        end
    },
    {
        id = "achievement",
        label = "Achievements",
        atlas = "UI-HUD-MicroMenu-Achievements-Up",
        action = function()
            ToggleAchievementFrame()
        end
    },
    { id = "questlog", label = "Quest Log", atlas = "UI-HUD-MicroMenu-Questlog-Up", action = function() ToggleQuestLog() end },
    { id = "guild", label = "Guild/Communities", atlas = "UI-HUD-MicroMenu-GuildCommunities-Up", action = function() ToggleGuildFrame() end },
    { id = "lfg", label = "Group Finder", atlas = "UI-HUD-MicroMenu-Groupfinder-Up", action = function() ToggleLFDParentFrame() end },
    {
        id = "collections",
        label = "Collections",
        atlas = "UI-HUD-MicroMenu-Collections-Up",
        action = function()
            ToggleCollectionsJournal()
        end
    },
    { id = "ej", label = "Adventure Guide", atlas = "UI-HUD-MicroMenu-AdventureGuide-Up", action = function() ToggleEncounterJournal() end },
    {
        id = "professions",
        label = "Professions",
        atlas = "UI-HUD-MicroMenu-Professions-Up",
        action = function()
            ToggleProfessionsBook()
        end
    },
    {
        id = "housing",
        label = "Housing",
        atlas = "UI-HUD-MicroMenu-Housing-Up",
        action = function()
            HousingFramesUtil
                .ToggleHousingDashboard()
        end
    },
-- Comment translated to English
    { id = "custom", label = "Custom Command", atlas = "UI-HUD-MicroMenu-GameMenu-Up", action = nil },
}

-- Comment translated to English
local ACTION_BY_ID = {}
for _, a in ipairs(ACTION_LIST) do
    ACTION_BY_ID[a.id] = a
end

-- Comment translated to English
local ACTION_ITEMS_STR = (function()
    local t = {}
    for _, a in ipairs(ACTION_LIST) do
        if a.atlas then
            t[#t + 1] = CreateAtlasMarkup(a.atlas, 16, 16) .. " " .. a.label
        else
            t[#t + 1] = a.label
        end
    end
    return table.concat(t, ",")
end)()

-- Comment translated to English
local ACTION_LABEL_TO_ID = {}
for _, a in ipairs(ACTION_LIST) do
    if a.atlas then
        ACTION_LABEL_TO_ID[CreateAtlasMarkup(a.atlas, 16, 16) .. " " .. a.label] = a.id
    end
    ACTION_LABEL_TO_ID[a.label] = a.id
    ACTION_LABEL_TO_ID[a.id]    = a.id
end

-- =============================================================
-- Comment translated to English
-- =============================================================

-- Comment translated to English
local ICON_SEMANTIC_IDS = {
    "character", "spellbook", "achievement", "questlog",
    "guild", "lfg", "collections", "ej",
    "professions", "housing", "custom",
}

local ADDON_PATH        = "Interface\\AddOns\\InfinityTools\\Media\\RRTToolsAssets\\ToolTextures\\Icons\\"

-- Comment translated to English
local ICON_THEMES       = {
    {
        id   = "blizzard",
        name = "Blizzard",
        type = "blizzard",
    },
    {
        id   = "cyberpunk",
        name = "Cyberpunk",
        type = "custom",
        path = ADDON_PATH .. "cyberpunk\\",
    },
}
local ELVUI_MICROBAR_TEXTURE = "Interface\\AddOns\\InfinityTools\\InfinityMythicPlus\\Textures\\Icons\\MicroBar_ElvUI.tga"

local THEME_BY_ID       = {}
local THEME_NAME_LIST   = {}
for _, t in ipairs(ICON_THEMES) do
    THEME_BY_ID[t.id]                     = t
    THEME_NAME_LIST[#THEME_NAME_LIST + 1] = t.name
end
local THEME_ITEMS_STR = table.concat(THEME_NAME_LIST, ",")

local THEME_NAME_TO_ID = {}
for _, t in ipairs(ICON_THEMES) do
    THEME_NAME_TO_ID[t.name] = t.id
    THEME_NAME_TO_ID[t.id]   = t.id
end

-- =============================================================
-- Comment translated to English
-- =============================================================
local MAX_SLOTS = 10

-- =============================================================
-- Comment translated to English
-- =============================================================
local function RunCustomCmd(cmd)
    if not cmd or cmd == "" then return end
    cmd = cmd:match("^%s*(.-)%s*$")
    if cmd == "" then return end
    local slash, args = cmd:match("^(/[^%s]+)%s*(.*)")
    if slash then
        slash = slash:upper()
        for k, v in pairs(_G.SlashCmdList) do
            local i = 1
            while true do
                local registered = _G["SLASH_" .. k .. i]
                if not registered then break end
                if registered:upper() == slash then
                    v(args or "")
                    return
                end
                i = i + 1
            end
        end
    end
    local editBox = ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend()
    if editBox then
        editBox:SetText(cmd)
        ChatEdit_SendText(editBox, 0)
    end
end

-- =============================================================
-- Comment translated to English
-- Comment translated to English
-- Comment translated to English
-- Comment translated to English
-- Comment translated to English
-- =============================================================
local RRT_DEFAULTS = {
    enabled = false,
    locked = true,
    iconSize = 28,
    barScale = 1.0,
    showBackground = true,
    bgAlpha = 0.6,
    timeFormat = "24h",
    showSeconds = false,
    posX = 0,
    posY = 0,
    posAnchor = "TOP",

    timeFontSize = 0,
    timeOffsetX = 0,
    timeOffsetY = 0,

    iconTheme = "blizzard",

    leftCount = 5,
    rightCount = 5,

-- Comment translated to English
    left1_action = "character",
    left1_icon = "",
    left1_cmd = "",
    left1_tip = "",
    left2_action = "questlog",
    left2_icon = "",
    left2_cmd = "",
    left2_tip = "",
    left3_action = "achievement",
    left3_icon = "",
    left3_cmd = "",
    left3_tip = "",
    left4_action = "lfg",
    left4_icon = "",
    left4_cmd = "",
    left4_tip = "",
    left5_action = "guild",
    left5_icon = "",
    left5_cmd = "",
    left5_tip = "",
    left6_action = "none",
    left6_icon = "",
    left6_cmd = "",
    left6_tip = "",
    left7_action = "none",
    left7_icon = "",
    left7_cmd = "",
    left7_tip = "",
    left8_action = "none",
    left8_icon = "",
    left8_cmd = "",
    left8_tip = "",
    left9_action = "none",
    left9_icon = "",
    left9_cmd = "",
    left9_tip = "",
    left10_action = "none",
    left10_icon = "",
    left10_cmd = "",
    left10_tip = "",

-- Comment translated to English
    right1_action = "spellbook",
    right1_icon = "",
    right1_cmd = "",
    right1_tip = "",
    right2_action = "professions",
    right2_icon = "",
    right2_cmd = "",
    right2_tip = "",
    right3_action = "collections",
    right3_icon = "",
    right3_cmd = "",
    right3_tip = "",
    right4_action = "ej",
    right4_icon = "",
    right4_cmd = "",
    right4_tip = "",
    right5_action = "housing",
    right5_icon = "",
    right5_cmd = "",
    right5_tip = "",
    right6_action = "none",
    right6_icon = "",
    right6_cmd = "",
    right6_tip = "",
    right7_action = "none",
    right7_icon = "",
    right7_cmd = "",
    right7_tip = "",
    right8_action = "none",
    right8_icon = "",
    right8_cmd = "",
    right8_tip = "",
    right9_action = "none",
    right9_icon = "",
    right9_cmd = "",
    right9_tip = "",
    right10_action = "none",
    right10_icon = "",
    right10_cmd = "",
    right10_tip = "",
}

-- =============================================================
-- Comment translated to English
-- Comment translated to English
-- Comment translated to English
-- Comment translated to English
-- =============================================================
local function RRT_RegisterLayout()
    local function SlotRows(side, startY)
        local rows = {}
        local y = startY
        for i = 1, MAX_SLOTS do
            local actionKey = side .. i .. "_action"
            local iconKey   = side .. i .. "_iconbtn"
            local cmdKey    = side .. i .. "_cmd"
            local tipKey    = side .. i .. "_tip"

-- Comment translated to English
            local label     = (side == "left" and "Left " or "Right ") .. i
            rows[#rows + 1] = {
                key = iconKey,
                type = "button",
                x = 1,
                y = y,
                w = 5,
                h = 2,
                label = label,
            }
            rows[#rows + 1] = {
                key = actionKey,
                type = "dropdown",
                x = 7,
                y = y,
                w = 19,
                h = 2,
                label = "Action",
                items = ACTION_ITEMS_STR,
            }
            rows[#rows + 1] = {
                key = cmdKey,
                type = "input",
                x = 27,
                y = y,
                w = 12,
                h = 2,
                label = "Custom Command",
                placeholder = "/target boss1",
            }
            rows[#rows + 1] = {
                key = tipKey,
                type = "input",
                x = 40,
                y = y,
                w = 11,
                h = 2,
                label = "Tooltip Text",
                placeholder = "Leave empty to hide",
            }
            y               = y + 3
        end
        return rows, y
    end

    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 50, h = 2, label = "Micro Menu" },
        {
            key = "desc",
            type = "description",
            x = 1,
            y = 3,
            w = 50,
            h = 2,
            label = "Top micro menu with a centered clock and configurable icons on both sides. Icons and actions are configured separately."
        },

        { key = "div_basic", type = "divider", x = 1, y = 6, w = 50, h = 1 },
        { key = "sh_basic", type = "subheader", x = 1, y = 7, w = 50, h = 1, label = "Basic Settings" },

        { key = "enabled", type = "checkbox", x = 1, y = 9, w = 8, h = 2, label = "Enable" },
        { key = "locked", type = "checkbox", x = 10, y = 9, w = 8, h = 2, label = "Lock Position" },
        { key = "showBackground", type = "checkbox", x = 19, y = 9, w = 8, h = 2, label = "Show Background" },

        { key = "iconSize", type = "slider", x = 1, y = 12, w = 16, h = 2, label = "Icon Size", min = 16, max = 64, step = 1 },
        { key = "barScale", type = "slider", x = 19, y = 12, w = 16, h = 2, label = "Global Scale", min = 0.5, max = 2.0, step = 0.05 },
        { key = "bgAlpha", type = "slider", x = 36, y = 12, w = 14, h = 2, label = "Background Alpha", min = 0, max = 1, step = 0.05 },

        { key = "div_theme", type = "divider", x = 1, y = 15, w = 50, h = 1 },
        { key = "sh_theme", type = "subheader", x = 1, y = 16, w = 50, h = 1, label = "Icon Theme" },
        { key = "iconTheme", type = "dropdown", x = 1, y = 18, w = 25, h = 2, label = "Theme", items = THEME_ITEMS_STR },

        { key = "div_time", type = "divider", x = 1, y = 21, w = 50, h = 1 },
        { key = "sh_time", type = "subheader", x = 1, y = 22, w = 50, h = 1, label = "Clock Text" },
        { key = "timeFormat", type = "dropdown", x = 1, y = 24, w = 16, h = 2, label = "Time Format", items = "24h,12h" },
        { key = "showSeconds", type = "checkbox", x = 19, y = 24, w = 8, h = 2, label = "Show Seconds" },
        { key = "timeFontSize", type = "slider", x = 28, y = 24, w = 12, h = 2, label = "Font Size (0 = Auto)", min = 0, max = 36, step = 1 },
        { key = "timeOffsetX", type = "slider", x = 1, y = 27, w = 16, h = 2, label = "Time X Offset", min = -200, max = 200, step = 1 },
        { key = "timeOffsetY", type = "slider", x = 19, y = 27, w = 16, h = 2, label = "Time Y Offset", min = -50, max = 50, step = 1 },

        { key = "div_pos", type = "divider", x = 1, y = 30, w = 50, h = 1 },
        { key = "sh_pos", type = "subheader", x = 1, y = 31, w = 50, h = 1, label = "Position" },
        { key = "posAnchor", type = "dropdown", x = 1, y = 33, w = 20, h = 2, label = "Anchor", items = "TOP,TOPLEFT,TOPRIGHT,CENTER,BOTTOM" },
        { key = "posX", type = "slider", x = 22, y = 33, w = 14, h = 2, label = "X Offset", min = -1000, max = 1000, step = 1 },
        { key = "posY", type = "slider", x = 37, y = 33, w = 13, h = 2, label = "Y Offset", min = -600, max = 600, step = 1 },
        { key = "btn_reset_pos", type = "button", x = 1, y = 36, w = 12, h = 2, label = "Reset Position" },
    }

-- Comment translated to English
    layout[#layout + 1] = { key = "div_left", type = "divider", x = 1, y = 39, w = 50, h = 1 }
    layout[#layout + 1] = { key = "sh_left", type = "subheader", x = 1, y = 40, w = 50, h = 1, label = "Left Slots" }
    layout[#layout + 1] = {
        key = "leftCount",
        type = "slider",
        x = 1,
        y = 42,
        w = 16,
        h = 2,
        label = "Left Slot Count",
        min = 0,
        max =
            MAX_SLOTS,
        step = 1
    }

    local leftRows, leftEndY = SlotRows("left", 45)
    for _, row in ipairs(leftRows) do layout[#layout + 1] = row end

-- Comment translated to English
    layout[#layout + 1] = { key = "div_right", type = "divider", x = 1, y = leftEndY, w = 50, h = 1 }
    layout[#layout + 1] = {
        key = "sh_right",
        type = "subheader",
        x = 1,
        y = leftEndY + 1,
        w = 50,
        h = 1,
        label =
        "Right Slots"
    }
    layout[#layout + 1] = {
        key = "rightCount",
        type = "slider",
        x = 1,
        y = leftEndY + 3,
        w = 16,
        h = 2,
        label = "Right Slot Count",
        min = 0,
        max =
            MAX_SLOTS,
        step = 1
    }

    local rightRows, _ = SlotRows("right", leftEndY + 6)
    for _, row in ipairs(rightRows) do layout[#layout + 1] = row end

    RRTToolsCore:RegisterModuleLayout(RRT_MODULE_KEY, layout)
end
RRT_RegisterLayout()

-- =============================================================
-- Comment translated to English
-- =============================================================
if not RRTToolsCore:IsModuleEnabled(RRT_MODULE_KEY) then return end

local RRT_DB = RRTToolsCore:GetModuleDB(RRT_MODULE_KEY, RRT_DEFAULTS)

-- =============================================================
-- Comment translated to English
-- =============================================================

-- Comment translated to English
local function GetActionIdFromDB(key)
    local val = RRT_DB[key]
    if not val or val == "" then return "none" end
    return ACTION_LABEL_TO_ID[val] or "none"
end

-- Comment translated to English
local function GetCurrentTheme()
    local themeVal = RRT_DB.iconTheme or "blizzard"
    return THEME_BY_ID[THEME_NAME_TO_ID[themeVal] or themeVal] or THEME_BY_ID["blizzard"]
end

-- Comment translated to English
-- Comment translated to English
local function GetSlotIconInfo(side, i, actionId)
    local override = RRT_DB[side .. i .. "_icon"]
    if override and override ~= "" then
-- Comment translated to English
        local themeId, iconId = override:match("^(.+):(.+)$")
        if themeId and iconId then
            return themeId, iconId
        end
    end
-- Comment translated to English
    local theme = GetCurrentTheme()
    return theme.id, actionId
end

-- Comment translated to English
local function ApplyIconToTex(tex, themeId, iconId)
    local theme = THEME_BY_ID[themeId] or THEME_BY_ID["blizzard"]
    if theme.type == "blizzard" then
        local actionDef = ACTION_BY_ID[iconId]
        if iconId == "character" then
            tex:SetTexture(ELVUI_MICROBAR_TEXTURE)
            tex:SetTexCoord(0.0058, 0.0708, 0.038, 0.35)
            tex:SetVertexColor(1, 1, 1, 0.92)
        elseif actionDef and actionDef.atlas then
            local applied = tex:SetAtlas(actionDef.atlas, false)
            if not applied then
                tex:SetColorTexture(0.3, 0.3, 0.3, 0.5)
                tex:SetTexCoord(0, 1, 0, 1)
                tex:SetVertexColor(1, 1, 1, 1)
            else
                tex:SetTexCoord(0, 1, 0, 1)
                tex:SetVertexColor(1, 1, 1, 1)
            end
        else
            tex:SetColorTexture(0.3, 0.3, 0.3, 0.5)
            tex:SetTexCoord(0, 1, 0, 1)
            tex:SetVertexColor(1, 1, 1, 1)
        end
    else
        tex:SetTexture(theme.path .. iconId .. ".tga")
        tex:SetTexCoord(0, 1, 0, 1)
    end
    tex:SetAlpha(1.0)
end

local function SetButtonTextureBounds(btn, expanded)
    local inset = 0
    if btn._actionId == "character" then
        inset = expanded and -1 or 5
    elseif expanded then
        inset = -math.floor((btn:GetWidth() or 0) * 0.15)
    end

    btn.normalTex:ClearAllPoints()
    btn.normalTex:SetPoint("TOPLEFT", btn, "TOPLEFT", inset, -inset)
    btn.normalTex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -inset, inset)
end

-- Comment translated to English
local function GetTimeString()
    local d                 = date("*t")
    local hour, minute, sec = d.hour, d.min, d.sec
    local format24          = RRT_DB.timeFormat ~= "12h"
    if format24 then
        if RRT_DB.showSeconds then
            return string.format("%02d:%02d:%02d", hour, minute, sec)
        else
            return string.format("%02d:%02d", hour, minute)
        end
    else
        local ampm = hour >= 12 and "PM" or "AM"
        local h12  = hour % 12
        if h12 == 0 then h12 = 12 end
        if RRT_DB.showSeconds then
            return string.format("%d:%02d:%02d %s", h12, minute, sec, ampm)
        else
            return string.format("%d:%02d %s", h12, minute, ampm)
        end
    end
end

-- =============================================================
-- Comment translated to English
-- =============================================================
local IconPicker       = {}
IconPicker.frame       = nil
IconPicker.targetSide  = nil
IconPicker.targetIndex = nil

local PICKER_CELL_SIZE = 40
local PICKER_PADDING   = 12

local function IconPicker_Close()
    if IconPicker.frame then IconPicker.frame:Hide() end
end

local function IconPicker_Refresh()
    local f = IconPicker.frame
    if not f then return end

    if f.cells then
        for _, cell in ipairs(f.cells) do
            cell:Hide(); cell:SetParent(nil)
        end
    end
    f.cells          = {}

    local themeCount = #ICON_THEMES
    local iconCount  = #ICON_SEMANTIC_IDS
    local totalW     = PICKER_PADDING * 2 + iconCount * PICKER_CELL_SIZE + (iconCount - 1) * 2
    local totalH     = PICKER_PADDING * 2 + 24 + themeCount * (PICKER_CELL_SIZE + 2) + 16 + 28
    f:SetSize(totalW, totalH)

-- Comment translated to English
    if not f.titleText then
        f.titleText = f:CreateFontString(nil, "OVERLAY")
        f.titleText:SetFont(RRTToolsCore.MAIN_FONT, 13, "OUTLINE")
        f.titleText:SetTextColor(1, 1, 1, 1)
        f.titleText:SetPoint("TOPLEFT", f, "TOPLEFT", PICKER_PADDING, -PICKER_PADDING)
    end
    local sideLabel = IconPicker.targetSide == "left" and "Left " or "Right "
    f.titleText:SetText("Choose Icon [" .. sideLabel .. IconPicker.targetIndex .. "]")

-- Comment translated to English
    local colHeaderY = -PICKER_PADDING - 18
    for ci, iconId in ipairs(ICON_SEMANTIC_IDS) do
        local hdrKey = "colHdr" .. ci
        if not f[hdrKey] then
            local lbl = f:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(RRTToolsCore.MAIN_FONT, 8, "OUTLINE")
            lbl:SetTextColor(0.7, 0.7, 0.7, 1)
            f[hdrKey] = lbl
        end
        local lbl = f[hdrKey]
        lbl:ClearAllPoints()
        lbl:SetPoint("TOPLEFT", f, "TOPLEFT",
            PICKER_PADDING + (ci - 1) * (PICKER_CELL_SIZE + 2), colHeaderY)
        lbl:SetWidth(PICKER_CELL_SIZE)
        lbl:SetJustifyH("CENTER")
        local actionDef = ACTION_BY_ID[iconId]
        lbl:SetText(actionDef and actionDef.label or iconId)
        lbl:Show()
    end

-- Comment translated to English
    local currentKey  = IconPicker.targetSide .. IconPicker.targetIndex .. "_icon"
    local currentIcon = RRT_DB[currentKey] or ""

    for ri, theme in ipairs(ICON_THEMES) do
        for ci, iconId in ipairs(ICON_SEMANTIC_IDS) do
            local cellX = PICKER_PADDING + (ci - 1) * (PICKER_CELL_SIZE + 2)
            local cellY = -(PICKER_PADDING + 24 + (ri - 1) * (PICKER_CELL_SIZE + 2))

            local cell = CreateFrame("Button", nil, f)
            cell:SetSize(PICKER_CELL_SIZE, PICKER_CELL_SIZE)
            cell:SetPoint("TOPLEFT", f, "TOPLEFT", cellX, cellY)
            cell:EnableMouse(true)
            cell:RegisterForClicks("AnyUp")

            local bg = cell:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)
            cell.bg = bg

-- Comment translated to English
            if currentIcon == iconId then
                local border = cell:CreateTexture(nil, "OVERLAY")
                border:SetAllPoints()
                border:SetColorTexture(1, 0.8, 0, 0.4)
            end

            local iconTex = cell:CreateTexture(nil, "ARTWORK")
            iconTex:SetAllPoints()
            ApplyIconToTex(iconTex, theme.id, iconId)

            cell:SetScript("OnEnter", function(self)
                self.bg:SetColorTexture(0.3, 0.6, 1.0, 0.4)
                local actionDef = ACTION_BY_ID[iconId]
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(theme.name .. " / " .. (actionDef and actionDef.label or iconId), 1, 1, 1)
                GameTooltip:Show()
            end)
            cell:SetScript("OnLeave", function(self)
                self.bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)
                GameTooltip:Hide()
            end)

-- Comment translated to English
            local capturedThemeId = theme.id
            local capturedIconId  = iconId
            cell:SetScript("OnClick", function()
                local key = IconPicker.targetSide .. IconPicker.targetIndex .. "_icon"
                RRT_DB[key] = capturedThemeId .. ":" .. capturedIconId
-- Comment translated to English
                RRTToolsCore:UpdateState(RRT_MODULE_KEY .. ".IconPickerApplied", GetTime())
                IconPicker_Close()
            end)

            f.cells[#f.cells + 1] = cell
        end
    end

-- Comment translated to English
    if not f.resetBtn then
        f.resetBtn = CreateFrame("Button", nil, f)
        f.resetBtn:SetSize(110, 22)
        local btnTex = f.resetBtn:CreateTexture(nil, "BACKGROUND")
        btnTex:SetAllPoints()
        btnTex:SetColorTexture(0.2, 0.2, 0.2, 0.9)
        local btnLbl = f.resetBtn:CreateFontString(nil, "OVERLAY")
        btnLbl:SetFont(RRTToolsCore.MAIN_FONT, 11, "OUTLINE")
        btnLbl:SetTextColor(0.8, 0.8, 0.8, 1)
        btnLbl:SetText("↺ Use Theme Default")
        btnLbl:SetAllPoints()
        f.resetBtn:SetScript("OnClick", function()
            local key = IconPicker.targetSide .. IconPicker.targetIndex .. "_icon"
            RRT_DB[key] = ""
            RRTToolsCore:UpdateState(RRT_MODULE_KEY .. ".IconPickerApplied", GetTime())
            IconPicker_Close()
        end)
        f.resetBtn:SetScript("OnEnter", function(_) btnTex:SetColorTexture(0.3, 0.3, 0.3, 0.9) end)
        f.resetBtn:SetScript("OnLeave", function(_) btnTex:SetColorTexture(0.2, 0.2, 0.2, 0.9) end)
    end
    local resetY = -(PICKER_PADDING + 24 + #ICON_THEMES * (PICKER_CELL_SIZE + 2) + 8)
    f.resetBtn:ClearAllPoints()
    f.resetBtn:SetPoint("BOTTOMLEFT", f, "TOPLEFT", PICKER_PADDING, resetY)

-- Comment translated to English
    if not f.closeBtn then
        f.closeBtn = CreateFrame("Button", nil, f)
        f.closeBtn:SetSize(22, 22)
        local closeTex = f.closeBtn:CreateTexture(nil, "BACKGROUND")
        closeTex:SetAllPoints()
        closeTex:SetColorTexture(0.6, 0.1, 0.1, 0.9)
        local closeLbl = f.closeBtn:CreateFontString(nil, "OVERLAY")
        closeLbl:SetFont(RRTToolsCore.MAIN_FONT, 13, "OUTLINE")
        closeLbl:SetTextColor(1, 1, 1, 1)
        closeLbl:SetText("✕")
        closeLbl:SetAllPoints()
        f.closeBtn:SetScript("OnClick", IconPicker_Close)
        f.closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    end

    f:Show()
end

local function IconPicker_Open(side, index)
    if not IconPicker.frame then
        local f = CreateFrame("Frame", "ExMicroMenuIconPicker", UIParent, "BackdropTemplate")
        f:SetFrameStrata("TOOLTIP")
        f:SetFrameLevel(100)
        f:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetBackdropColor(0.05, 0.05, 0.08, 0.97)
        f:SetBackdropBorderColor(0.4, 0.4, 0.5, 1)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        f:SetScript("OnKeyDown", function(_, key)
            if key == "ESCAPE" then IconPicker_Close() end
        end)
        f:SetPropagateKeyboardInput(true)
        f:Hide()
        IconPicker.frame = f
    end

    IconPicker.targetSide  = side
    IconPicker.targetIndex = index
    IconPicker.frame:ClearAllPoints()
    IconPicker.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    IconPicker_Refresh()
end

-- =============================================================
-- Comment translated to English
-- =============================================================
local mainFrame    = nil
local leftBtns     = {}
local rightBtns    = {}
local timeText     = nil
local ticker       = nil
local editBgFrames = {}

-- Comment translated to English
local function ApplyButtonIcon(btn, side, slotIndex, actionId)
    local themeId, iconId = GetSlotIconInfo(side, slotIndex, actionId)
    if iconId == "none" or not iconId or iconId == "" then
        btn.normalTex:SetColorTexture(0.3, 0.3, 0.3, 0.5)
        btn.normalTex:SetTexCoord(0, 1, 0, 1)
        btn.normalTex:SetAlpha(0.4)
        return
    end
    ApplyIconToTex(btn.normalTex, themeId, iconId)
end

-- Comment translated to English
local function CreateIconButton(parent, actionId, side, slotIndex)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(RRT_DB.iconSize, RRT_DB.iconSize)
    btn:EnableMouse(true)
    btn:RegisterForClicks("AnyUp")

    local normalTex = btn:CreateTexture(nil, "ARTWORK")
    normalTex:SetAllPoints()
    btn.normalTex = normalTex
    btn._actionId  = actionId
    btn._side      = side
    btn._slotIndex = slotIndex
    ApplyButtonIcon(btn, side, slotIndex, actionId)
    SetButtonTextureBounds(btn, false)

-- Comment translated to English
    btn:SetScript("OnEnter", function(self)
        SetButtonTextureBounds(self, true)
-- Comment translated to English
        local tip = RRT_DB[self._side .. self._slotIndex .. "_tip"] or ""
        if tip ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tip, 1, 1, 1)
            GameTooltip:Show()
            return
        end
-- Comment translated to English
        local def = ACTION_BY_ID[self._actionId]
        if not def or def.id == "none" then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
-- Comment translated to English
        GameTooltip:SetText(def.label, 1, 1, 1)
-- Comment translated to English
        local iconThemeId, iconId = GetSlotIconInfo(self._side, self._slotIndex, self._actionId)
        local iconTheme           = THEME_BY_ID[iconThemeId]
        local iconAction          = ACTION_BY_ID[iconId]
        local iconDesc            = (iconTheme and iconTheme.name or iconThemeId)
            .. " / " .. (iconAction and iconAction.label or iconId)
        GameTooltip:AddLine("|cffaaaaaaIcon: " .. iconDesc .. "|r", 1, 1, 1)
-- Comment translated to English
        if def.id == "custom" then
            local cmd = RRT_DB[self._side .. self._slotIndex .. "_cmd"] or ""
            if cmd ~= "" then GameTooltip:AddLine("|cffffd700" .. cmd .. "|r", 1, 1, 1) end
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        SetButtonTextureBounds(self, false)
        GameTooltip:Hide()
    end)

-- Comment translated to English
    btn:SetScript("OnClick", function(self)
        local def = ACTION_BY_ID[self._actionId]
        if not def then return end
        if def.id == "custom" then
            local cmd = RRT_DB[self._side .. self._slotIndex .. "_cmd"] or ""
            RunCustomCmd(cmd)
        elseif def.action then
            local ok, err = pcall(def.action)
            if not ok then RRTDebug("MicroMenu button action failed: %s", tostring(err)) end
        end
    end)

    return btn
end

-- Comment translated to English
local function UpdateButtonAction(btn, actionId, side, slotIndex)
    btn._actionId  = actionId
    btn._side      = side
    btn._slotIndex = slotIndex
    ApplyButtonIcon(btn, side, slotIndex, actionId)
    SetButtonTextureBounds(btn, false)
end

-- Comment translated to English
local function BuildHUD()
    if mainFrame then
        mainFrame:Hide()
        mainFrame:SetParent(nil)
        mainFrame    = nil
        leftBtns     = {}
        rightBtns    = {}
        timeText     = nil
        editBgFrames = {}
    end
    if not RRT_DB.enabled then return end

    local iconSize   = RRT_DB.iconSize
    local iconGap    = 4
    local padding    = 8
    local leftCount  = math.min(RRT_DB.leftCount or 5, MAX_SLOTS)
    local rightCount = math.min(RRT_DB.rightCount or 5, MAX_SLOTS)
    local barHeight  = iconSize + padding * 2

    mainFrame        = CreateFrame("Frame", "ExMicroMenuFrame", UIParent)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetFrameLevel(10)
    mainFrame:SetScale(RRT_DB.barScale)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(not RRT_DB.locked)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetSize(100, barHeight)

    local timeBg = mainFrame:CreateTexture(nil, "BACKGROUND")
    timeBg:SetAllPoints()
    timeBg:SetColorTexture(0, 0, 0, RRT_DB.showBackground and RRT_DB.bgAlpha or 0)

    local mainEditBg = mainFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    mainEditBg:SetAllPoints()
    mainEditBg:SetColorTexture(0, 1, 0, 0.45)
    mainEditBg:Hide()
    table.insert(editBgFrames, mainEditBg)

    mainFrame._editDragLabel = mainFrame:CreateFontString(nil, "OVERLAY", nil, 8)
    mainFrame._editDragLabel:SetFont(RRTToolsCore.MAIN_FONT, 11, "OUTLINE")
    mainFrame._editDragLabel:SetTextColor(0, 1, 0, 1)
    mainFrame._editDragLabel:SetText("Drag Here")
    mainFrame._editDragLabel:SetPoint("CENTER", mainFrame, "CENTER", 0, 0)
    mainFrame._editDragLabel:Hide()

    timeText = mainFrame:CreateFontString(nil, "OVERLAY")
    local tfs = (RRT_DB.timeFontSize and RRT_DB.timeFontSize > 0) and RRT_DB.timeFontSize or math.floor(iconSize * 0.75)
    timeText:SetFont(RRTToolsCore.MAIN_FONT, tfs, "OUTLINE")
    timeText:SetTextColor(1, 1, 1, 1)
    timeText:SetPoint("CENTER", mainFrame, "CENTER", RRT_DB.timeOffsetX or 0, RRT_DB.timeOffsetY or 0)
    timeText:SetText(GetTimeString())

    mainFrame:SetScript("OnDragStart", function(self)
        if not RRT_DB.locked then self:StartMoving() end
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        RRT_DB.posX              = math.floor(x or 0)
        RRT_DB.posY              = math.floor(y or 0)
        RRT_DB.posAnchor         = point or "TOP"
    end)

    RRTToolsCore:RegisterHUD(RRT_MODULE_KEY, mainFrame)

-- Comment translated to English
    if leftCount > 0 then
        local leftWidth = padding + leftCount * iconSize + (leftCount - 1) * iconGap + padding
        local leftFrame = CreateFrame("Frame", nil, mainFrame)
        leftFrame:SetFrameStrata("MEDIUM"); leftFrame:SetFrameLevel(10)
        leftFrame:SetSize(leftWidth, barHeight)
        leftFrame:SetPoint("RIGHT", mainFrame, "LEFT", 0, 0)

        local leftBg = leftFrame:CreateTexture(nil, "BACKGROUND")
        leftBg:SetAllPoints()
        leftBg:SetColorTexture(0, 0, 0, RRT_DB.showBackground and RRT_DB.bgAlpha or 0)

        local leftEditBg = leftFrame:CreateTexture(nil, "OVERLAY", nil, 7)
        leftEditBg:SetAllPoints()
        leftEditBg:SetColorTexture(0, 1, 0, 0.45)
        leftEditBg:Hide()
        table.insert(editBgFrames, leftEditBg)

        local curX = leftWidth - padding
        for i = 1, leftCount do
            local actionId = GetActionIdFromDB("left" .. i .. "_action")
            local btn      = CreateIconButton(leftFrame, actionId, "left", i)
            btn:SetPoint("RIGHT", leftFrame, "LEFT", curX, 0)
            curX        = curX - iconSize - iconGap
            leftBtns[i] = btn
        end
    end

-- Comment translated to English
    if rightCount > 0 then
        local rightWidth = padding + rightCount * iconSize + (rightCount - 1) * iconGap + padding
        local rightFrame = CreateFrame("Frame", nil, mainFrame)
        rightFrame:SetFrameStrata("MEDIUM"); rightFrame:SetFrameLevel(10)
        rightFrame:SetSize(rightWidth, barHeight)
        rightFrame:SetPoint("LEFT", mainFrame, "RIGHT", 0, 0)

        local rightBg = rightFrame:CreateTexture(nil, "BACKGROUND")
        rightBg:SetAllPoints()
        rightBg:SetColorTexture(0, 0, 0, RRT_DB.showBackground and RRT_DB.bgAlpha or 0)

        local rightEditBg = rightFrame:CreateTexture(nil, "OVERLAY", nil, 7)
        rightEditBg:SetAllPoints()
        rightEditBg:SetColorTexture(0, 1, 0, 0.45)
        rightEditBg:Hide()
        table.insert(editBgFrames, rightEditBg)

        local curX = padding
        for i = 1, rightCount do
            local actionId = GetActionIdFromDB("right" .. i .. "_action")
            local btn      = CreateIconButton(rightFrame, actionId, "right", i)
            btn:SetPoint("LEFT", rightFrame, "LEFT", curX, 0)
            curX         = curX + iconSize + iconGap
            rightBtns[i] = btn
        end
    end

    mainFrame:ClearAllPoints()
    local anchor = RRT_DB.posAnchor or "TOP"
    mainFrame:SetPoint(anchor, UIParent, anchor, RRT_DB.posX or 0, RRT_DB.posY or 0)
    mainFrame:Show()
end

-- Comment translated to English
local blizzMicroMenuOrigPoint = nil
local function SetBlizzardMicroMenuVisible(visible)
    local container = _G["MicroMenuContainer"]
    if not container then return end
    if visible then
        if blizzMicroMenuOrigPoint then
            container:ClearAllPoints()
            container:SetPoint(unpack(blizzMicroMenuOrigPoint))
        end
        container:Show()
        if UpdateMicroButtons then
            pcall(UpdateMicroButtons)
        end
    else
        if not blizzMicroMenuOrigPoint then
            local point, relativeTo, relativePoint, x, y = container:GetPoint()
            if point then
                blizzMicroMenuOrigPoint = { point, relativeTo, relativePoint, x, y }
            end
        end
        container:ClearAllPoints()
        container:SetPoint("TOP", UIParent, "BOTTOM", 0, -9999)
    end
end

local function TickTime()
    if timeText and timeText:IsShown() then
        timeText:SetText(GetTimeString())
    end
end

local function StartTicker()
    if ticker then
        ticker:Cancel(); ticker = nil
    end
    ticker = C_Timer.NewTicker(1, TickTime)
end

local function RefreshAll()
    local ok, err = pcall(BuildHUD)
    if not ok then
        RRTDebug("MicroMenu BuildHUD failed: %s", tostring(err))
    end
    if RRTToolsCore.GlobalEditMode then
        for _, bg in ipairs(editBgFrames) do bg:Show() end
        if mainFrame and mainFrame._editDragLabel then mainFrame._editDragLabel:Show() end
    end
    if RRT_DB.enabled then
        StartTicker()
        SetBlizzardMicroMenuVisible(false)
    else
        if ticker then
            ticker:Cancel(); ticker = nil
        end
        SetBlizzardMicroMenuVisible(true)
    end
end

RRT_NS.MP_MicroMenu = RRT_NS.MP_MicroMenu or {}
function RRT_NS.MP_MicroMenu:RefreshDisplay()
    RefreshAll()
end

local function RefreshPanels()
    local leftCount  = math.min(RRT_DB.leftCount or 5, MAX_SLOTS)
    local rightCount = math.min(RRT_DB.rightCount or 5, MAX_SLOTS)
    for i = 1, leftCount do
        if leftBtns[i] then
            UpdateButtonAction(leftBtns[i], GetActionIdFromDB("left" .. i .. "_action"), "left", i)
        end
    end
    for i = 1, rightCount do
        if rightBtns[i] then
            UpdateButtonAction(rightBtns[i], GetActionIdFromDB("right" .. i .. "_action"), "right", i)
        end
    end
end

-- Comment translated to English
-- Comment translated to English
local function RefreshIconBtnTextures()
    local widgets = RRTToolsCore.Grid and RRTToolsCore.Grid.Widgets
    if not widgets then return end

    local function ApplyToWidget(side, i)
        local key = side .. i .. "_iconbtn"
        local btn = widgets[key]
        if not btn then return end

        local actionId        = GetActionIdFromDB(side .. i .. "_action")
        local themeId, iconId = GetSlotIconInfo(side, i, actionId)

-- Comment translated to English
        if not btn._iconPreviewTex then
-- Comment translated to English
            btn:SetNormalTexture("")
            btn:SetPushedTexture("")
            btn:SetHighlightTexture("")
            btn:SetDisabledTexture("")
-- Comment translated to English
            local fs = btn:GetFontString()
            if fs then fs:SetAlpha(0) end
-- Comment translated to English
            btn._iconPreviewTex = btn:CreateTexture(nil, "ARTWORK")
            btn._iconPreviewTex:SetAllPoints(btn)
        end

        local tex = btn._iconPreviewTex
        if iconId == "none" or not iconId or iconId == "" then
            tex:SetColorTexture(0.3, 0.3, 0.3, 0.5)
            tex:SetTexCoord(0, 1, 0, 1)
            tex:SetAlpha(0.5)
        else
            ApplyIconToTex(tex, themeId, iconId)
        end
        tex:Show()
    end

    for i = 1, MAX_SLOTS do
        ApplyToWidget("left", i)
        ApplyToWidget("right", i)
    end
end

-- =============================================================
-- Comment translated to English
-- =============================================================
RRTToolsCore:RegisterEvent("PLAYER_ENTERING_WORLD", RRT_MODULE_KEY, function()
    C_Timer.After(0.5, RefreshAll)
end)

RRTToolsCore:WatchState(RRT_MODULE_KEY .. ".DatabaseChanged", RRT_MODULE_KEY, function(info)
    if not info or not info.key then return end

    local rebuildKeys = {
        enabled = true,
        iconSize = true,
        barScale = true,
        leftCount = true,
        rightCount = true,
        showBackground = true,
        bgAlpha = true,
        posAnchor = true,
        posX = true,
        posY = true,
        showSeconds = true,
        timeFormat = true,
        timeFontSize = true,
        timeOffsetX = true,
        timeOffsetY = true,
    }
    if rebuildKeys[info.key] then
        RefreshAll(); return
    end

-- Comment translated to English
    if info.key == "iconTheme"
        or string.find(info.key, "_action$")
        or string.find(info.key, "_icon$") then
        RefreshPanels()
        RefreshIconBtnTextures()
        return
    end

    if info.key == "locked" then
        if mainFrame then mainFrame:EnableMouse(not RRT_DB.locked) end
    end
end)

-- Comment translated to English
RRTToolsCore:WatchState(RRT_MODULE_KEY .. ".IconPickerApplied", RRT_MODULE_KEY, function()
    RefreshPanels()
    RefreshIconBtnTextures()
end)

-- Comment translated to English
RRTToolsCore:WatchState(RRT_MODULE_KEY .. ".PanelRendered", RRT_MODULE_KEY, function()
    RefreshIconBtnTextures()
end)

RRTToolsCore:WatchState(RRT_MODULE_KEY .. ".ButtonClicked", RRT_MODULE_KEY, function(info)
    if not info or not info.key then return end

    if info.key == "btn_reset_pos" then
        RRT_DB.posX = 0; RRT_DB.posY = 0; RRT_DB.posAnchor = "TOP"
        if mainFrame then
            mainFrame:ClearAllPoints()
            mainFrame:SetPoint("TOP", UIParent, "TOP", 0, 0)
        end
        return
    end

-- Comment translated to English
    local btnSide, btnIdx = info.key:match("^(left)(%d+)_iconbtn$")
    if not btnSide then btnSide, btnIdx = info.key:match("^(right)(%d+)_iconbtn$") end
    if btnSide and btnIdx then
        IconPicker_Open(btnSide, tonumber(btnIdx))
    end
end)

RRTToolsCore:RegisterEditModeCallback(RRT_MODULE_KEY, function(enabled)
    if not mainFrame then return end
    if enabled then
        RRT_DB.locked = false
        mainFrame:EnableMouse(true)
        for _, bg in ipairs(editBgFrames) do bg:Show() end
        if mainFrame._editDragLabel then mainFrame._editDragLabel:Show() end
    else
        RRT_DB.locked = true
        mainFrame:EnableMouse(false)
        for _, bg in ipairs(editBgFrames) do bg:Hide() end
        if mainFrame._editDragLabel then mainFrame._editDragLabel:Hide() end
    end
end)

-- =============================================================
-- Comment translated to English
-- =============================================================
RRTToolsCore:ReportReady(RRT_MODULE_KEY)
