-- =============================================================
-- [[ Micro Menu ]]
-- { Key = "RevTools.MicroMenu", Name = "Micro Menu", Desc = "Top micro menu with time in the center and configurable side shortcut icons.", Category = 1 },
-- =============================================================
local ondev = false
if ondev then
    return
end

local InfinityTools = _G.InfinityTools
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end

local INFINITY_MODULE_KEY = "RevTools.MicroMenu"

-- =============================================================
-- Action definitions
-- Each slot has an independent icon and action, and those two choices are fully decoupled.
-- Note: game menu functions (ShowUIPanel/ToggleGameMenu) are protected and can trigger ForceTaint_Strong.
--       They are intentionally excluded from this action list.
-- =============================================================
local ACTION_LIST = {
    -- id = stable key stored in DB
    -- label = display name
    -- atlas = Blizzard atlas icon used by the default Blizzard icon theme
    -- action = callback function, nil means no action or a custom slash command
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
    -- Custom command: action=nil, then execution reads the _cmd field
    { id = "custom", label = "Custom Command", atlas = "UI-HUD-MicroMenu-GameMenu-Up", action = nil },
}

-- id -> action definition map
local ACTION_BY_ID = {}
for _, a in ipairs(ACTION_LIST) do
    ACTION_BY_ID[a.id] = a
end

-- Dropdown item string with atlas previews
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

-- label with markup -> id map, used to restore action IDs from DB values
local ACTION_LABEL_TO_ID = {}
for _, a in ipairs(ACTION_LIST) do
    if a.atlas then
        ACTION_LABEL_TO_ID[CreateAtlasMarkup(a.atlas, 16, 16) .. " " .. a.label] = a.id
    end
    ACTION_LABEL_TO_ID[a.label] = a.id
    ACTION_LABEL_TO_ID[a.id]    = a.id
end

-- =============================================================
-- Icon theme system
-- =============================================================

-- Icon semantic order, aligned with ACTION_LIST ids and picker columns
local ICON_SEMANTIC_IDS = {
    "character", "spellbook", "achievement", "questlog",
    "guild", "lfg", "collections", "ej",
    "professions", "housing", "custom",
}

local ADDON_PATH        = "Interface\\AddOns\\InfinityTools\\InfinityMythicPlus\\Textures\\Icons\\"

-- Theme registry
local ICON_THEMES       = {
    {
        id   = "blizzard",
        name = "Blizzard Default",
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
-- Constants
-- =============================================================
local MAX_SLOTS = 10

-- =============================================================
-- Helper: run custom slash commands
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
-- Defaults
-- Each slot stores three fields:
--   _action = action id to run on click
--   _icon = icon id override, empty means follow the selected theme
--   _cmd = custom command, only used when action=custom
-- =============================================================
local MODULE_DEFAULTS = {
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

    -- Left slot defaults, empty _tip means no tooltip
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

    -- Right slot defaults
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
-- Grid layout
-- Each slot uses three rows:
--   Row 1: [icon picker button 8 cols] [action dropdown 30 cols] [empty]
--   Row 2: [command input full width], meaningful only for action=custom, but always visible
-- =============================================================
local function REGISTER_LAYOUT()
    local function SlotRows(side, startY)
        local rows = {}
        local y = startY
        for i = 1, MAX_SLOTS do
            local actionKey = side .. i .. "_action"
            local iconKey   = side .. i .. "_iconbtn"
            local cmdKey    = side .. i .. "_cmd"
            local tipKey    = side .. i .. "_tip"

            -- One row: [icon button 5 cols] [action dropdown 19 cols] [command input 12 cols] [tooltip input 12 cols]
            local label     = (side == "left" and "L" or "R") .. i
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
            label = "Top micro menu: center clock, configurable icons on each side. Icon and action are set independently."
        },

        { key = "div_basic", type = "divider", x = 1, y = 6, w = 50, h = 1 },
        { key = "sh_basic", type = "subheader", x = 1, y = 7, w = 50, h = 1, label = "Basic Settings" },

        { key = "enabled", type = "checkbox", x = 1, y = 9, w = 8, h = 2, label = "Enable" },
        { key = "locked", type = "checkbox", x = 10, y = 9, w = 8, h = 2, label = "Lock Position" },
        { key = "showBackground", type = "checkbox", x = 19, y = 9, w = 8, h = 2, label = "Show Background" },

        { key = "iconSize", type = "slider", x = 1, y = 12, w = 16, h = 2, label = "Icon Size", min = 16, max = 64, step = 1 },
        { key = "barScale", type = "slider", x = 19, y = 12, w = 16, h = 2, label = "Overall Scale", min = 0.5, max = 2.0, step = 0.05 },
        { key = "bgAlpha", type = "slider", x = 36, y = 12, w = 14, h = 2, label = "Background Opacity", min = 0, max = 1, step = 0.05 },

        { key = "div_theme", type = "divider", x = 1, y = 15, w = 50, h = 1 },
        { key = "sh_theme", type = "subheader", x = 1, y = 16, w = 50, h = 1, label = "Icon Style" },
        { key = "iconTheme", type = "dropdown", x = 1, y = 18, w = 25, h = 2, label = "Overall Theme", items = THEME_ITEMS_STR },

        { key = "div_time", type = "divider", x = 1, y = 21, w = 50, h = 1 },
        { key = "sh_time", type = "subheader", x = 1, y = 22, w = 50, h = 1, label = "Time Text" },
        { key = "timeFormat", type = "dropdown", x = 1, y = 24, w = 16, h = 2, label = "Time Format", items = "24h,12h" },
        { key = "showSeconds", type = "checkbox", x = 19, y = 24, w = 8, h = 2, label = "Show Seconds" },
        { key = "timeFontSize", type = "slider", x = 28, y = 24, w = 12, h = 2, label = "Font Size (0=auto)", min = 0, max = 36, step = 1 },
        { key = "timeOffsetX", type = "slider", x = 1, y = 27, w = 16, h = 2, label = "Time X Offset", min = -200, max = 200, step = 1 },
        { key = "timeOffsetY", type = "slider", x = 19, y = 27, w = 16, h = 2, label = "Time Y Offset", min = -50, max = 50, step = 1 },

        { key = "div_pos", type = "divider", x = 1, y = 30, w = 50, h = 1 },
        { key = "sh_pos", type = "subheader", x = 1, y = 31, w = 50, h = 1, label = "Position" },
        { key = "posAnchor", type = "dropdown", x = 1, y = 33, w = 20, h = 2, label = "Anchor", items = "TOP,TOPLEFT,TOPRIGHT,CENTER,BOTTOM" },
        { key = "posX", type = "slider", x = 22, y = 33, w = 14, h = 2, label = "X Offset", min = -1000, max = 1000, step = 1 },
        { key = "posY", type = "slider", x = 37, y = 33, w = 13, h = 2, label = "Y Offset", min = -600, max = 600, step = 1 },
        { key = "btn_reset_pos", type = "button", x = 1, y = 36, w = 12, h = 2, label = "Reset Position" },
    }

    -- Left slots
    layout[#layout + 1] = { key = "div_left", type = "divider", x = 1, y = 39, w = 50, h = 1 }
    layout[#layout + 1] = { key = "sh_left", type = "subheader", x = 1, y = 40, w = 50, h = 1, label = "Left Icon Slots" }
    layout[#layout + 1] = {
        key = "leftCount",
        type = "slider",
        x = 1,
        y = 42,
        w = 16,
        h = 2,
        label = "Left Icon Count",
        min = 0,
        max =
            MAX_SLOTS,
        step = 1
    }

    local leftRows, leftEndY = SlotRows("left", 45)
    for _, row in ipairs(leftRows) do layout[#layout + 1] = row end

    -- Right slots
    layout[#layout + 1] = { key = "div_right", type = "divider", x = 1, y = leftEndY, w = 50, h = 1 }
    layout[#layout + 1] = {
        key = "sh_right",
        type = "subheader",
        x = 1,
        y = leftEndY + 1,
        w = 50,
        h = 1,
        label =
        "Right Icon Slots"
    }
    layout[#layout + 1] = {
        key = "rightCount",
        type = "slider",
        x = 1,
        y = leftEndY + 3,
        w = 16,
        h = 2,
        label = "Right Icon Count",
        min = 0,
        max =
            MAX_SLOTS,
        step = 1
    }

    local rightRows, _ = SlotRows("right", leftEndY + 6)
    for _, row in ipairs(rightRows) do layout[#layout + 1] = row end

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

-- =============================================================
-- Load guard
-- =============================================================
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local MICRO_MENU_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

-- =============================================================
-- Helper functions
-- =============================================================

-- Restore action id from a DB value (markup label / plain label / id)
local function GetActionIdFromDB(key)
    local val = MICRO_MENU_DB[key]
    if not val or val == "" then return "none" end
    return ACTION_LABEL_TO_ID[val] or "none"
end

-- Get current theme
local function GetCurrentTheme()
    local themeVal = MICRO_MENU_DB.iconTheme or "blizzard"
    return THEME_BY_ID[THEME_NAME_TO_ID[themeVal] or themeVal] or THEME_BY_ID["blizzard"]
end

-- Parse per-slot icon override and return (themeId, iconId)
-- _icon format: empty = follow theme, "themeId:iconId" = per-slot override
local function GetSlotIconInfo(side, i, actionId)
    local override = MICRO_MENU_DB[side .. i .. "_icon"]
    if override and override ~= "" then
        -- Format: "cyberpunk:achievement"
        local themeId, iconId = override:match("^(.+):(.+)$")
        if themeId and iconId then
            return themeId, iconId
        end
    end
    -- Follow the global theme, semantic icon id = action id
    local theme = GetCurrentTheme()
    return theme.id, actionId
end

-- Apply an icon definition to a texture
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

-- Build current time string
local function GetTimeString()
    local d                 = date("*t")
    local hour, minute, sec = d.hour, d.min, d.sec
    local format24          = MICRO_MENU_DB.timeFormat ~= "12h"
    if format24 then
        if MICRO_MENU_DB.showSeconds then
            return string.format("%02d:%02d:%02d", hour, minute, sec)
        else
            return string.format("%02d:%02d", hour, minute)
        end
    else
        local ampm = hour >= 12 and "PM" or "AM"
        local h12  = hour % 12
        if h12 == 0 then h12 = 12 end
        if MICRO_MENU_DB.showSeconds then
            return string.format("%d:%02d:%02d %s", h12, minute, sec, ampm)
        else
            return string.format("%d:%02d %s", h12, minute, ampm)
        end
    end
end

-- =============================================================
-- Icon picker popup
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

    -- Title
    if not f.titleText then
        f.titleText = f:CreateFontString(nil, "OVERLAY")
        f.titleText:SetFont(InfinityTools.MAIN_FONT, 13, "OUTLINE")
        f.titleText:SetTextColor(1, 1, 1, 1)
        f.titleText:SetPoint("TOPLEFT", f, "TOPLEFT", PICKER_PADDING, -PICKER_PADDING)
    end
    local sideLabel = IconPicker.targetSide == "left" and "L" or "R"
    f.titleText:SetText("Select Icon  [" .. sideLabel .. IconPicker.targetIndex .. "]")

    -- Column headers
    local colHeaderY = -PICKER_PADDING - 18
    for ci, iconId in ipairs(ICON_SEMANTIC_IDS) do
        local hdrKey = "colHdr" .. ci
        if not f[hdrKey] then
            local lbl = f:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(InfinityTools.MAIN_FONT, 8, "OUTLINE")
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

    -- Grid cells: one row per theme, one column per icon
    local currentKey  = IconPicker.targetSide .. IconPicker.targetIndex .. "_icon"
    local currentIcon = MICRO_MENU_DB[currentKey] or ""

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

            -- Highlight the currently selected icon
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

            -- Stored format: "themeId:iconId", e.g. "cyberpunk:achievement"
            local capturedThemeId = theme.id
            local capturedIconId  = iconId
            cell:SetScript("OnClick", function()
                local key = IconPicker.targetSide .. IconPicker.targetIndex .. "_icon"
                MICRO_MENU_DB[key] = capturedThemeId .. ":" .. capturedIconId
                -- Use a timestamp so UpdateState always fires, even if the value did not change.
                InfinityTools:UpdateState(INFINITY_MODULE_KEY .. ".IconPickerApplied", GetTime())
                IconPicker_Close()
            end)

            f.cells[#f.cells + 1] = cell
        end
    end

    -- "Follow Action" button, clears icon override
    if not f.resetBtn then
        f.resetBtn = CreateFrame("Button", nil, f)
        f.resetBtn:SetSize(110, 22)
        local btnTex = f.resetBtn:CreateTexture(nil, "BACKGROUND")
        btnTex:SetAllPoints()
        btnTex:SetColorTexture(0.2, 0.2, 0.2, 0.9)
        local btnLbl = f.resetBtn:CreateFontString(nil, "OVERLAY")
        btnLbl:SetFont(InfinityTools.MAIN_FONT, 11, "OUTLINE")
        btnLbl:SetTextColor(0.8, 0.8, 0.8, 1)
        btnLbl:SetText("↺ Follow Overall Theme")
        btnLbl:SetAllPoints()
        f.resetBtn:SetScript("OnClick", function()
            local key = IconPicker.targetSide .. IconPicker.targetIndex .. "_icon"
            MICRO_MENU_DB[key] = ""
            InfinityTools:UpdateState(INFINITY_MODULE_KEY .. ".IconPickerApplied", GetTime())
            IconPicker_Close()
        end)
        f.resetBtn:SetScript("OnEnter", function(_) btnTex:SetColorTexture(0.3, 0.3, 0.3, 0.9) end)
        f.resetBtn:SetScript("OnLeave", function(_) btnTex:SetColorTexture(0.2, 0.2, 0.2, 0.9) end)
    end
    local resetY = -(PICKER_PADDING + 24 + #ICON_THEMES * (PICKER_CELL_SIZE + 2) + 8)
    f.resetBtn:ClearAllPoints()
    f.resetBtn:SetPoint("BOTTOMLEFT", f, "TOPLEFT", PICKER_PADDING, resetY)

    -- Close button
    if not f.closeBtn then
        f.closeBtn = CreateFrame("Button", nil, f)
        f.closeBtn:SetSize(22, 22)
        local closeTex = f.closeBtn:CreateTexture(nil, "BACKGROUND")
        closeTex:SetAllPoints()
        closeTex:SetColorTexture(0.6, 0.1, 0.1, 0.9)
        local closeLbl = f.closeBtn:CreateFontString(nil, "OVERLAY")
        closeLbl:SetFont(InfinityTools.MAIN_FONT, 13, "OUTLINE")
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
        local f = CreateFrame("Frame", "RevMicroMenuIconPicker", UIParent, "BackdropTemplate")
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
-- HUD frame
-- =============================================================
local mainFrame    = nil
local leftBtns     = {}
local rightBtns    = {}
local timeText     = nil
local ticker       = nil
local editBgFrames = {}

-- Apply current theme + slot override to a button texture
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

-- Create one icon button
local function CreateIconButton(parent, actionId, side, slotIndex)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(MICRO_MENU_DB.iconSize, MICRO_MENU_DB.iconSize)
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

    -- Mouseover scale + tooltip
    btn:SetScript("OnEnter", function(self)
        SetButtonTextureBounds(self, true)
        -- Custom tooltip text takes priority, empty text means no tooltip.
        local tip = MICRO_MENU_DB[self._side .. self._slotIndex .. "_tip"] or ""
        if tip ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tip, 1, 1, 1)
            GameTooltip:Show()
            return
        end
        -- No custom text and no action means no tooltip.
        local def = ACTION_BY_ID[self._actionId]
        if not def or def.id == "none" then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        -- Line 1: action name
        GameTooltip:SetText(def.label, 1, 1, 1)
        -- Line 2: icon info (theme / icon)
        local iconThemeId, iconId = GetSlotIconInfo(self._side, self._slotIndex, self._actionId)
        local iconTheme           = THEME_BY_ID[iconThemeId]
        local iconAction          = ACTION_BY_ID[iconId]
        local iconDesc            = (iconTheme and iconTheme.name or iconThemeId)
            .. " / " .. (iconAction and iconAction.label or iconId)
        GameTooltip:AddLine("|cffaaaaaa Icon: " .. iconDesc .. "|r", 1, 1, 1)
        -- Line 3: custom command
        if def.id == "custom" then
            local cmd = MICRO_MENU_DB[self._side .. self._slotIndex .. "_cmd"] or ""
            if cmd ~= "" then GameTooltip:AddLine("|cffffd700" .. cmd .. "|r", 1, 1, 1) end
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        SetButtonTextureBounds(self, false)
        GameTooltip:Hide()
    end)

    -- Click: run action
    btn:SetScript("OnClick", function(self)
        local def = ACTION_BY_ID[self._actionId]
        if not def then return end
        if def.id == "custom" then
            local cmd = MICRO_MENU_DB[self._side .. self._slotIndex .. "_cmd"] or ""
            RunCustomCmd(cmd)
        elseif def.action then
            local ok, err = pcall(def.action)
            if not ok then InfinityDebug("MicroMenu button execution failed: %s", tostring(err)) end
        end
    end)

    return btn
end

-- Update button action without rebuilding frames
local function UpdateButtonAction(btn, actionId, side, slotIndex)
    btn._actionId  = actionId
    btn._side      = side
    btn._slotIndex = slotIndex
    ApplyButtonIcon(btn, side, slotIndex, actionId)
    SetButtonTextureBounds(btn, false)
end

-- Create/rebuild the full HUD
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
    if not MICRO_MENU_DB.enabled then return end

    local iconSize   = MICRO_MENU_DB.iconSize
    local iconGap    = 4
    local padding    = 8
    local leftCount  = math.min(MICRO_MENU_DB.leftCount or 5, MAX_SLOTS)
    local rightCount = math.min(MICRO_MENU_DB.rightCount or 5, MAX_SLOTS)
    local barHeight  = iconSize + padding * 2

    mainFrame        = CreateFrame("Frame", "RevMicroMenuFrame", UIParent)
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetFrameLevel(10)
    mainFrame:SetScale(MICRO_MENU_DB.barScale)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(not MICRO_MENU_DB.locked)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetSize(100, barHeight)

    local timeBg = mainFrame:CreateTexture(nil, "BACKGROUND")
    timeBg:SetAllPoints()
    timeBg:SetColorTexture(0, 0, 0, MICRO_MENU_DB.showBackground and MICRO_MENU_DB.bgAlpha or 0)

    local mainEditBg = mainFrame:CreateTexture(nil, "OVERLAY", nil, 7)
    mainEditBg:SetAllPoints()
    mainEditBg:SetColorTexture(0, 1, 0, 0.45)
    mainEditBg:Hide()
    table.insert(editBgFrames, mainEditBg)

    mainFrame._editDragLabel = mainFrame:CreateFontString(nil, "OVERLAY", nil, 8)
    mainFrame._editDragLabel:SetFont(InfinityTools.MAIN_FONT, 11, "OUTLINE")
    mainFrame._editDragLabel:SetTextColor(0, 1, 0, 1)
    mainFrame._editDragLabel:SetText("Drag here")
    mainFrame._editDragLabel:SetPoint("CENTER", mainFrame, "CENTER", 0, 0)
    mainFrame._editDragLabel:Hide()

    timeText = mainFrame:CreateFontString(nil, "OVERLAY")
    local tfs = (MICRO_MENU_DB.timeFontSize and MICRO_MENU_DB.timeFontSize > 0) and MICRO_MENU_DB.timeFontSize or math.floor(iconSize * 0.75)
    timeText:SetFont(InfinityTools.MAIN_FONT, tfs, "OUTLINE")
    timeText:SetTextColor(1, 1, 1, 1)
    timeText:SetPoint("CENTER", mainFrame, "CENTER", MICRO_MENU_DB.timeOffsetX or 0, MICRO_MENU_DB.timeOffsetY or 0)
    timeText:SetText(GetTimeString())

    mainFrame:SetScript("OnDragStart", function(self)
        if not MICRO_MENU_DB.locked then self:StartMoving() end
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        MICRO_MENU_DB.posX      = math.floor(x or 0)
        MICRO_MENU_DB.posY      = math.floor(y or 0)
        MICRO_MENU_DB.posAnchor = point or "TOP"
    end)

    InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, mainFrame)

    -- Left frame
    if leftCount > 0 then
        local leftWidth = padding + leftCount * iconSize + (leftCount - 1) * iconGap + padding
        local leftFrame = CreateFrame("Frame", nil, mainFrame)
        leftFrame:SetFrameStrata("MEDIUM"); leftFrame:SetFrameLevel(10)
        leftFrame:SetSize(leftWidth, barHeight)
        leftFrame:SetPoint("RIGHT", mainFrame, "LEFT", 0, 0)

        local leftBg = leftFrame:CreateTexture(nil, "BACKGROUND")
        leftBg:SetAllPoints()
        leftBg:SetColorTexture(0, 0, 0, MICRO_MENU_DB.showBackground and MICRO_MENU_DB.bgAlpha or 0)

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

    -- Right frame
    if rightCount > 0 then
        local rightWidth = padding + rightCount * iconSize + (rightCount - 1) * iconGap + padding
        local rightFrame = CreateFrame("Frame", nil, mainFrame)
        rightFrame:SetFrameStrata("MEDIUM"); rightFrame:SetFrameLevel(10)
        rightFrame:SetSize(rightWidth, barHeight)
        rightFrame:SetPoint("LEFT", mainFrame, "RIGHT", 0, 0)

        local rightBg = rightFrame:CreateTexture(nil, "BACKGROUND")
        rightBg:SetAllPoints()
        rightBg:SetColorTexture(0, 0, 0, MICRO_MENU_DB.showBackground and MICRO_MENU_DB.bgAlpha or 0)

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
    local anchor = MICRO_MENU_DB.posAnchor or "TOP"
    mainFrame:SetPoint(anchor, UIParent, anchor, MICRO_MENU_DB.posX or 0, MICRO_MENU_DB.posY or 0)
    mainFrame:Show()
end

-- Hide/restore Blizzard's built-in micro menu
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
        InfinityDebug("MicroMenu BuildHUD error: %s", tostring(err))
    end
    if InfinityTools.GlobalEditMode then
        for _, bg in ipairs(editBgFrames) do bg:Show() end
        if mainFrame and mainFrame._editDragLabel then mainFrame._editDragLabel:Show() end
    end
    if MICRO_MENU_DB.enabled then
        StartTicker()
        SetBlizzardMicroMenuVisible(false)
    else
        if ticker then
            ticker:Cancel(); ticker = nil
        end
        SetBlizzardMicroMenuVisible(true)
    end
end

local function RefreshPanels()
    local leftCount  = math.min(MICRO_MENU_DB.leftCount or 5, MAX_SLOTS)
    local rightCount = math.min(MICRO_MENU_DB.rightCount or 5, MAX_SLOTS)
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

-- Refresh icon picker buttons in the settings panel
-- Read buttons from InfinityTools.Grid.Widgets, overlay icon textures, and hide button text.
local function RefreshIconBtnTextures()
    local widgets = InfinityTools.Grid and InfinityTools.Grid.Widgets
    if not widgets then return end

    local function ApplyToWidget(side, i)
        local key = side .. i .. "_iconbtn"
        local btn = widgets[key]
        if not btn then return end

        local actionId        = GetActionIdFromDB(side .. i .. "_action")
        local themeId, iconId = GetSlotIconInfo(side, i, actionId)

        -- First-time setup: clear template textures, create a clean canvas, then add our icon texture.
        if not btn._iconPreviewTex then
            -- Hide all native texture layers from SharedButtonLargeTemplate
            btn:SetNormalTexture("")
            btn:SetPushedTexture("")
            btn:SetHighlightTexture("")
            btn:SetDisabledTexture("")
            -- Hide text
            local fs = btn:GetFontString()
            if fs then fs:SetAlpha(0) end
            -- Create the icon texture in ARTWORK so template layers do not interfere
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
-- Event and state subscriptions
-- =============================================================
InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY, function()
    C_Timer.After(0.5, RefreshAll)
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
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

    -- Global theme or slot icon/action changes -> refresh icons
    if info.key == "iconTheme"
        or string.find(info.key, "_action$")
        or string.find(info.key, "_icon$") then
        RefreshPanels()
        RefreshIconBtnTextures()
        return
    end

    if info.key == "locked" then
        if mainFrame then mainFrame:EnableMouse(not MICRO_MENU_DB.locked) end
    end
end)

-- Refresh after picker apply
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".IconPickerApplied", INFINITY_MODULE_KEY, function()
    RefreshPanels()
    RefreshIconBtnTextures()
end)

-- After panel render, sync picker button previews
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".PanelRendered", INFINITY_MODULE_KEY, function()
    RefreshIconBtnTextures()
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end

    if info.key == "btn_reset_pos" then
        MICRO_MENU_DB.posX = 0; MICRO_MENU_DB.posY = 0; MICRO_MENU_DB.posAnchor = "TOP"
        if mainFrame then
            mainFrame:ClearAllPoints()
            mainFrame:SetPoint("TOP", UIParent, "TOP", 0, 0)
        end
        return
    end

    -- Icon buttons open the picker popup
    local btnSide, btnIdx = info.key:match("^(left)(%d+)_iconbtn$")
    if not btnSide then btnSide, btnIdx = info.key:match("^(right)(%d+)_iconbtn$") end
    if btnSide and btnIdx then
        IconPicker_Open(btnSide, tonumber(btnIdx))
    end
end)

InfinityTools:RegisterEditModeCallback(INFINITY_MODULE_KEY, function(enabled)
    if not mainFrame then return end
    if enabled then
        MICRO_MENU_DB.locked = false
        mainFrame:EnableMouse(true)
        for _, bg in ipairs(editBgFrames) do bg:Show() end
        if mainFrame._editDragLabel then mainFrame._editDragLabel:Show() end
    else
        MICRO_MENU_DB.locked = true
        mainFrame:EnableMouse(false)
        for _, bg in ipairs(editBgFrames) do bg:Hide() end
        if mainFrame._editDragLabel then mainFrame._editDragLabel:Hide() end
    end
end)

-- =============================================================
-- Report module ready
-- =============================================================
InfinityTools:ReportReady(INFINITY_MODULE_KEY)
