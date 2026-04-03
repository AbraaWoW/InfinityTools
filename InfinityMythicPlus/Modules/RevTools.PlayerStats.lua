-- [[ Player Stats Panel ]]
-- { Key = "RevTools.PlayerStats", Name = "Player Stats Panel", Desc = "Displays highly customizable player stats on screen (Haste, Versatility, Dodge, etc.).", Category = 4 },

local InfinityTools = _G.InfinityTools
if not InfinityTools then return end
local InfinityState = InfinityTools.State
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

local INFINITY_MODULE_KEY = "RevTools.PlayerStats"
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local InfinityDB = _G.InfinityDB
local LSM = LibStub("LibSharedMedia-3.0")

-- 3. Data initialization
local function GetDefaultFont()
    return { font = nil, size = 14, outline = "OUTLINE", r = 1, g = 1, b = 1, a = 1, shadow = true, x = 0, y = 0 }
end

local function GetDefaultRows()
    local rows = {}
    local defaultStats = { "Primary Stat", "Crit", "Haste", "Mastery", "Versatility", "Speed" }
    for i = 1, 10 do
        table.insert(rows, {
            enabled = i <= 6,
            label = defaultStats[i] or ("Stat " .. i),
            key = defaultStats[i] or "None",
            isPercent = true,
            format = 1,
            syncFont = true,
            roles = { TANK = true, HEALER = true, DAMAGER = true },
            scenes = { ["In Instance"] = true, ["Out of Instance"] = true },
            fontLabel = GetDefaultFont(),
            fontValue = GetDefaultFont()
        })
    end
    return rows
end

local MODULE_DEFAULTS = {
    bgSettings = {
        bgColorA = 1,
        bgColorB = 1,
        bgColorG = 1,
        bgColorR = 1,
        borderColorA = 1,
        borderColorB = 1,
        borderColorG = 1,
        borderColorR = 1,
        borderTexture = "None",
        edgeSize = 9,
        inset = 8,
        labelAlign = "CENTER:Center",
        labelX = 1,
        rowSpacing = 5,
        texture = "None",
        valueAlign = "LEFT:Left",
        valueX = -16,
    },
    locked = false,
    pos = {
        point = "BOTTOMLEFT",
        x = 380.21630859375,
        y = 179.10350036621,
    },
    rows = {
        {
            enabled = true,
            fontLabel = {
                a = 1,
                b = 0,
                font = nil,
                g = 0.63137257099152,
                outline = "THICKOUTLINE",
                r = 1,
                shadow = false,
                shadowX = 1.2000007629395,
                size = 24,
                x = -1,
                y = 2,
            },
            fontValue = {
                a = 1,
                b = 1,
                font = nil,
                g = 1,
                outline = "OUTLINE",
                r = 1,
                shadow = true,
                shadowX = 1,
                size = 14,
                x = 0,
                y = 0,
            },
            format = 0,
            isPercent = false,
            key = "Primary Stat",
            label = "%Primary Stat",
            roles = {
                DAMAGER = true,
                HEALER = true,
                TANK = true,
            },
            scenes = {
                ["In Instance"] = true,
                ["Out of Instance"] = true,
            },
            syncFont = true,
        },
        {
            enabled = true,
            fontLabel = {
                a = 1,
                b = 0.32549020648003,
                font = nil,
                g = 0.23921570181847,
                outline = "THICKOUTLINE",
                r = 1,
                shadow = false,
                size = 18,
                x = 0,
                y = 0,
            },
            fontValue = {
                a = 1,
                b = 1,
                font = nil,
                g = 1,
                outline = "OUTLINE",
                r = 1,
                shadow = true,
                shadowX = 1,
                size = 14,
                x = 0,
                y = 0,
            },
            format = 1,
            isPercent = true,
            key = "Crit",
            label = "Crit",
            roles = {
                DAMAGER = true,
                HEALER = true,
                TANK = true,
            },
            scenes = {
                ["In Instance"] = true,
                ["Out of Instance"] = true,
            },
            syncFont = true,
        },
        {
            enabled = true,
            fontLabel = {
                a = 1,
                b = 0.0078431377187371,
                font = nil,
                g = 1,
                outline = "THICKOUTLINE",
                r = 0.52156865596771,
                shadow = false,
                size = 18,
                x = 0,
                y = 0,
            },
            fontValue = {
                a = 1,
                b = 1,
                font = nil,
                g = 1,
                outline = "THICKOUTLINE",
                r = 1,
                shadow = false,
                size = 14,
                x = 0,
                y = 0,
            },
            format = 1,
            isPercent = true,
            key = "Haste",
            label = "Haste",
            roles = {
                DAMAGER = true,
                HEALER = true,
                TANK = true,
            },
            scenes = {
                ["In Instance"] = true,
                ["Out of Instance"] = true,
            },
            syncFont = true,
        },
        {
            enabled = true,
            fontLabel = {
                a = 1,
                b = 1,
                font = nil,
                g = 0.57254904508591,
                outline = "THICKOUTLINE",
                r = 0.04313725605607,
                shadow = false,
                size = 18,
                x = 0,
                y = 0,
            },
            fontValue = {
                a = 1,
                b = 1,
                font = nil,
                g = 1,
                outline = "OUTLINE",
                r = 1,
                shadow = true,
                size = 15,
                x = 0,
                y = 0,
            },
            format = 1,
            isPercent = true,
            key = "Mastery",
            label = "Mastery",
            roles = {
                DAMAGER = true,
                HEALER = true,
                TANK = true,
            },
            scenes = {
                ["In Instance"] = true,
                ["Out of Instance"] = true,
            },
            syncFont = true,
        },
        {
            enabled = true,
            fontLabel = {
                a = 1,
                b = 1,
                font = nil,
                g = 0.90980398654938,
                outline = "THICKOUTLINE",
                r = 0.3647058904171,
                shadow = false,
                size = 18,
                x = 0,
                y = 0,
            },
            fontValue = {
                a = 1,
                b = 1,
                font = nil,
                g = 1,
                outline = "OUTLINE",
                r = 1,
                shadow = false,
                size = 14,
                x = 0,
                y = 0,
            },
            format = 1,
            isPercent = true,
            key = "Versatility",
            label = "Versa",
            roles = {
                DAMAGER = true,
                HEALER = true,
                TANK = true,
            },
            scenes = {
                ["In Instance"] = true,
                ["Out of Instance"] = true,
            },
            syncFont = true,
        },
        {
            enabled = true,
            fontLabel = {
                a = 1,
                b = 0.28627452254295,
                font = nil,
                g = 0.91372555494308,
                outline = "THICKOUTLINE",
                r = 1,
                shadow = false,
                size = 18,
                x = 0,
                y = 0,
            },
            fontValue = {
                a = 1,
                b = 1,
                font = nil,
                g = 1,
                outline = "OUTLINE",
                r = 1,
                shadow = true,
                size = 14,
                x = 0,
                y = 0,
            },
            format = 0,
            isPercent = true,
            key = "Speed",
            label = "Speed",
            roles = {
                DAMAGER = true,
                HEALER = true,
                TANK = true,
            },
            scenes = {
                ["In Instance"] = true,
                ["Out of Instance"] = true,
            },
            syncFont = true,
        },
    },
    selectedRow = 1,
    showBg = false,
    showBorder = false,
}

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)
if not MODULE_DB.rows or #MODULE_DB.rows == 0 then
    MODULE_DB.rows = GetDefaultRows()
end

local STAT_MAP = {
    ["None"] = "None",
    ["Primary Stat"] = "PStat_Major",
    ["Strength"] = "PStat_Str",
    ["Agility"] = "PStat_Agi",
    ["Intellect"] = "PStat_Int", ["Intel"] = "PStat_Int",
    ["Crit"] = "PStat_Crit",
    ["Haste"] = "PStat_Haste",
    ["Mastery"] = "PStat_Mastery",
    ["Versatility"] = "PStat_Versa", ["Versa"] = "PStat_Versa",
    ["Leech"] = "PStat_Leech",
    ["Avoidance"] = "PStat_Avoidance",
    ["Speed"] = "PStat_Movement",
    ["Armor"] = "PStat_Armor",
    ["Dodge"] = "PStat_Dodge",
    ["Parry"] = "PStat_Parry",
    ["Block"] = "PStat_Block",
    ["Item Level"] = "PStat_EquippedItemLevel",
    ["Health"] = "PStat_MaxHealth",
    ["Durability"] = "PStat_Durability"
}

local function NormalizePlayerStatsConfig()
    local keyMap = {
        -- (CN label migration removed)
    }
    local sceneMap = { ["In Instance"] = "In Instance", ["Out of Instance"] = "Out of Instance" }
    for _, row in ipairs(MODULE_DB.rows or {}) do
        if keyMap[row.key] then row.key = keyMap[row.key] end


        if row.scenes then
            for oldKey, newKey in pairs(sceneMap) do
                if row.scenes[oldKey] ~= nil and row.scenes[newKey] == nil then row.scenes[newKey] = row.scenes[oldKey] end
                row.scenes[oldKey] = nil
            end
        end
    end
    if MODULE_DB.bgSettings then
        
        
        
        
        
        
    end
end

NormalizePlayerStatsConfig()

InfinityTools.GetRowItems_PlayerStats = function()
    local items = {}
    for i, row in ipairs(MODULE_DB.rows) do
        local name = (row.label and row.label ~= "") and (L[row.label] or row.label) or ("Row " .. i)
        if #name > 14 then name = name:sub(1, 14) end
        table.insert(items, { i .. ": " .. name, i })
    end
    return items
end
InfinityTools.GetPlayerStatTree = function()
    return {
        { "None", "None" },
        {
            text = "Primary",
            isMenu = true,
            menu = {
                { "Primary (Auto)", "Primary Stat" }, { "Strength", "Strength" }, { "Agility", "Agility" }, { "Intel", "Intellect" }
            }
        },
        {
            text = "Secondary",
            isMenu = true,
            menu = {
                { "|cffFF3D53Crit|r", "Crit" }, { "|cff85FF02Haste|r", "Haste" }, { "|cff0B92FFMastery|r", "Mastery" }, { "|cff5DE8FFVersa|r", "Versatility" }
            }
        },
        {
            text = "Tertiary",
            isMenu = true,
            menu = {
                { "Leech", "Leech" }, { "Avoid", "Avoidance" }, { "Speed", "Speed" }
            }
        },
        {
            text = "Defense",
            isMenu = true,
            menu = {
                { "Armor", "Armor" }, { "Dodge", "Dodge" }, { "Parry", "Parry" }, { "Block", "Block" }
            }
        },
        {
            text = "Other",
            isMenu = true,
            menu = {
                { "iLvl", "Item Level" }, { "Health", "Health" }, { "Durab.", "Durability" }
            }
        }
    }
end

local function REGISTER_LAYOUT()
    local sel = tonumber(MODULE_DB.selectedRow) or 1
    if sel < 1 then sel = 1 end
    if sel > #MODULE_DB.rows then sel = #MODULE_DB.rows end
    MODULE_DB.selectedRow = sel

    local currentRowPath = "rows." .. sel
    local layout = {
        { key = "header", type = "header", x = 2, y = 1, w = 53, h = 2, label = L["Player Stats Panel"], labelSize = 25 },
        { key = "desc", type = "description", x = 2, y = 4, w = 53, h = 2, label = L["Shows your character stats in real time. Right-click the widget to enter edit mode."] },
        { key = "sub_gen", type = "subheader", x = 2, y = 7, w = 53, h = 2, label = L["General Settings"], labelSize = 20 },  -- TODO: missing key: L["General Settings"]
        { key = "locked", type = "checkbox", x = 2, y = 11, w = 8, h = 2, label = L["Lock Position"] },
        { key = "showBg", type = "checkbox", x = 2, y = 14, w = 8, h = 2, label = L["Show Background"] },
        { key = "showBorder", type = "checkbox", x = 2, y = 18, w = 8, h = 1, label = L["Show Border"] },
        {
            key = "bgGroup",
            type = "TableGroup",
            x = 1,
            y = 1,
            w = 1,
            h = 1,
            label = "--[[ Function ]]",
            parentKey = "bgSettings",
            children = {
                { key = "texture", type = "lsm_background", x = 11, y = 13, w = 12, h = 2, label = L["Background Texture"] },
                { key = "bgColor", type = "color", x = 24, y = 13, w = 10, h = 2, label = L["Background Color"] },
                { key = "borderTexture", type = "lsm_border", x = 11, y = 17, w = 12, h = 2, label = L["Border Texture"] },
                { key = "borderColor", type = "color", x = 24, y = 17, w = 10, h = 2, label = L["Border Color"] },
                { key = "edgeSize", type = "slider", x = 35, y = 17, w = 10, h = 2, label = L["Border Size"], min = 1, max = 32 },
                { key = "inset", type = "slider", x = 46, y = 17, w = 10, h = 2, label = L["Border Inset"], min = 0, max = 16 },
                { key = "labelAlign", type = "dropdown", x = 2, y = 22, w = 10, h = 2, label = "Label Align", items = "LEFT:Left,CENTER:Center,RIGHT:Right" },
                { key = "valueAlign", type = "dropdown", x = 13, y = 22, w = 10, h = 2, label = "Value Align", items = "LEFT:Left,CENTER:Center,RIGHT:Right" },
                { key = "rowSpacing", type = "slider", x = 46, y = 22, w = 10, h = 2, label = L["Row Spacing"], min = -10, max = 30 },
                { key = "labelX", type = "slider", x = 24, y = 22, w = 10, h = 2, label = L["Global Label X"], min = -50, max = 50 },
                { key = "valueX", type = "slider", x = 35, y = 22, w = 10, h = 2, label = L["Global Value X"], min = -50, max = 50 },
            }
        },
        { key = "sub_row", type = "subheader", x = 2, y = 27, w = 53, h = 2, label = L["Stat Row Management"], labelSize = 20 },
        { key = "selectedRow", type = "dropdown", x = 2, y = 31, w = 16, h = 2, label = L["Select Row to Edit"], items = "func:InfinityTools.GetRowItems_PlayerStats" },
        { key = "btn_up", type = "button", x = 19, y = 31, w = 4, h = 2, label = "Up" },
        { key = "btn_down", type = "button", x = 24, y = 31, w = 4, h = 2, label = "Dn" },
        { key = "btn_add", type = "button", x = 29, y = 31, w = 7, h = 2, label = "Add" },
        { key = "btn_delete", type = "button", x = 37, y = 31, w = 7, h = 2, label = "Delete" },
        { key = "btn_reset", type = "button", x = 45, y = 31, w = 8, h = 2, label = L["Reset Position"] },
        {
            key = "RowEditor",
            type = "TableGroup",
            x = 1,
            y = 1,
            w = 1,
            h = 1,
            label = "--[[ Function ]]",
            children = {
                { key = "enabled", type = "checkbox", x = 2, y = 35, w = 7, h = 2, label = "Enable" },
                { key = "label", type = "input", x = 10, y = 35, w = 11, h = 2, label = "Name" },
                { key = "key", type = "dropdown", x = 23, y = 35, w = 11, h = 2, label = "Stat", items = "func:InfinityTools.GetPlayerStatTree" },
                { key = "isPercent", type = "checkbox", x = 36, y = 35, w = 6, h = 2, label = "%" },
                { key = "format", type = "slider", x = 45, y = 35, w = 8, h = 2, label = "Dec.", min = 0, max = 3 },
                { key = "roles", type = "multiselect", x = 22, y = 40, w = 14, h = 2, label = L["Show Roles"], items = "TANK,HEALER,DAMAGER" },
                { key = "scenes", type = "multiselect", x = 40, y = 40, w = 13, h = 2, label = "Context", items = "In Instance,Out of Instance" },
                { key = "syncFont", type = "checkbox", x = 2, y = 63, w = 16, h = 2, label = "|cffff0501" .. L["Sync Styles"] .. "|r", labelSize = 20 },
                { key = "fontLabel", type = "fontgroup", x = 2, y = 43, w = 54, h = 18, label = L["Label Style"], labelSize = 20 },
                { key = "fontValue", type = "fontgroup", x = 2, y = 67, w = 54, h = 18, label = L["Value Style"], labelSize = 20 },
            }
        },
        { key = "divider_2", type = "divider", x = 2, y = 29, w = 53, h = 1, label = "" },
        { key = "divider_5137", type = "divider", x = 2, y = 9, w = 53, h = 1, label = L["Components"] },
    }



    if InfinityGrid then
        InfinityGrid.ExportReplacements = { [currentRowPath] = '"rows." .. sel' }
    end
    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

local EXStatsUI = { RowFrames = {} }
_G.EXStatsUI = EXStatsUI

function EXStatsUI:RefreshStyle()
    if not self.frame then return end
    local conf = MODULE_DB.bgSettings
    self.frame:SetBackdrop({
        bgFile = MODULE_DB.showBg and LSM:Fetch("background", conf.texture) or nil,
        edgeFile = MODULE_DB.showBorder and LSM:Fetch("border", conf.borderTexture) or nil,
        edgeSize = conf.edgeSize or 12,
        insets = { left = conf.inset or 4, right = conf.inset or 4, top = conf.inset or 4, bottom = conf.inset or 4 }
    })

    local r, g, b, a = conf.bgColorR or 0, conf.bgColorG or 0, conf.bgColorB or 0, conf.bgColorA or 0.5
    local br, bg, bb, ba = conf.borderColorR or 1, conf.borderColorG or 1, conf.borderColorB or 1, conf.borderColorA or 1

    self.frame:SetBackdropColor(r, g, b, MODULE_DB.showBg and a or 0)
    self.frame:SetBackdropBorderColor(br, bg, bb, MODULE_DB.showBorder and ba or 0)
    -- Mouse click-through is controlled by the global edit mode; no intervention here
end

function EXStatsUI:RefreshRows()
    if not self.frame then return end
    local specID = InfinityTools.State.SpecID
    local role = "DAMAGER"
    if specID and specID > 0 and InfinityDB.SpecByID[specID] then
        role = InfinityDB.SpecByID[specID].role
    end
    local inInstance = IsInInstance()

    -- 1. Cleanup
    for i, r in pairs(self.RowFrames) do
        r:Hide()
        if r._lastWatchKey then InfinityTools:UnwatchState(r._lastWatchKey, "StatsUI_R" .. i) end
    end

    local yOffset = -12
    local rowHeight = 20
    local spacing = MODULE_DB.bgSettings.rowSpacing or 2
    local lAlign = MODULE_DB.bgSettings.labelAlign or "LEFT"
    local vAlign = MODULE_DB.bgSettings.valueAlign or "RIGHT"
    lAlign = lAlign:match("^([^:]+):") or lAlign
    vAlign = vAlign:match("^([^:]+):") or vAlign

    -- 2. Render
    for i, conf in ipairs(MODULE_DB.rows) do
        if conf.enabled then
            local visible = true
            if conf.roles and not conf.roles[role] then visible = false end
            local sceneKey = inInstance and "In Instance" or "Out of Instance"
            if conf.scenes and not conf.scenes[sceneKey] then visible = false end

            if visible then
                local row = self.RowFrames[i]
                if not row then
                    row = CreateFrame("Frame", nil, self.frame)
                    row:SetSize(self.frame:GetWidth() - 16, rowHeight)
                    row:EnableMouse(false) -- Child rows always click-through; mouse events are handled by the parent frame
                    row.label = row:CreateFontString(nil, "OVERLAY")
                    row.value = row:CreateFontString(nil, "OVERLAY")
                    self.RowFrames[i] = row
                end

                row:Show(); row:SetPoint("TOPLEFT", 8, yOffset)

                local lf = conf.fontLabel or GetDefaultFont()
                local vf = conf.syncFont and lf or (conf.fontValue or GetDefaultFont())
                InfinityDB:ApplyFont(row.label, lf)
                InfinityDB:ApplyFont(row.value, vf)

                row.label:ClearAllPoints(); row.value:ClearAllPoints()
                local halfW = self.frame:GetWidth() / 2
                local gap = 4
                local glX = MODULE_DB.bgSettings.labelX or 0
                local gvX = MODULE_DB.bgSettings.valueX or 0

                -- Label layout (overlay local X/Y and global X)
                if lAlign == "LEFT" then
                    row.label:SetPoint("LEFT", row, "LEFT", 8 + (lf.x or 0) + glX, (lf.y or 0))
                elseif lAlign == "CENTER" then
                    row.label:SetPoint("CENTER", row, "LEFT", halfW / 2 + (lf.x or 0) + glX, (lf.y or 0))
                else -- RIGHT
                    row.label:SetPoint("RIGHT", row, "CENTER", -gap + (lf.x or 0) + glX, (lf.y or 0))
                end
                row.label:SetJustifyH(lAlign)

                -- Value layout (overlay local X/Y and global X)
                if vAlign == "RIGHT" then
                    row.value:SetPoint("RIGHT", row, "RIGHT", -8 + (vf.x or 0) + gvX, (vf.y or 0))
                elseif vAlign == "CENTER" then
                    row.value:SetPoint("CENTER", row, "RIGHT", -halfW / 2 + (vf.x or 0) + gvX, (vf.y or 0))
                else -- LEFT
                    row.value:SetPoint("LEFT", row, "CENTER", gap + (vf.x or 0) + gvX, (vf.y or 0))
                end
                row.value:SetJustifyH(vAlign)

                local primaryStat = InfinityDB:GetPlayerPrimaryStat() or "Stat"
                local legacyPrimaryToken = "%" .. string.char(228,184,187,229,177,158,230,128,167)
                local labelText = (conf.label or ""):gsub(legacyPrimaryToken, primaryStat):gsub("%%Primary Stat", primaryStat)
                row.label:SetText(L[labelText] or labelText)
                local internalKey = STAT_MAP[conf.key] or conf.key
                row._lastWatchKey = internalKey
                local function UpdateVal()
                    local val = (internalKey ~= "None") and InfinityState[internalKey] or 0
                    local fmt = "%." .. (conf.format or 1) .. "f" .. (conf.isPercent and "%%" or "")
                    row.value:SetText(string.format(fmt, val or 0))
                end

                if internalKey ~= "None" then
                    InfinityTools:WatchState(internalKey, "StatsUI_R" .. i, UpdateVal)
                    UpdateVal()
                else
                    row.value:SetText(L["N/A"])
                end

                yOffset = yOffset - rowHeight - spacing
            end
        end
    end
    self.frame:SetHeight(math.abs(yOffset) + 12)
end

function EXStatsUI:Init()
    if self.frame then return end
    local f = CreateFrame("Frame", "InfinityPlayerStatsFrame", UIParent, "BackdropTemplate")
    local pos = MODULE_DB.pos or { point = "CENTER", x = 0, y = 0 }
    f:SetSize(220, 100); f:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    f:SetMovable(true); f:RegisterForDrag("LeftButton")
    -- Dragging is only allowed in edit mode
    f:SetScript("OnDragStart", function(s) if InfinityTools.GlobalEditMode then s:StartMoving() end end)
    f:SetScript("OnDragStop",
        function(s)
            s:StopMovingOrSizing(); local p, _, _, x, y = s:GetPoint(); if not MODULE_DB.pos then MODULE_DB.pos = {} end; MODULE_DB.pos.x, MODULE_DB.pos.y, MODULE_DB.pos.point =
                x, y, p
        end)
    -- Edit mode green background (hidden by default)
    local editBg = f:CreateTexture(nil, "BACKGROUND")
    editBg:SetAllPoints(f)
    editBg:SetColorTexture(0, 1, 0, 0.35)
    editBg:Hide()
    self.editBg = editBg

    self.frame = f

    -- RegisterHUD internally forces EnableMouse(true); restore click-through immediately after registration
    InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, f)
    f:EnableMouse(false)

    -- Respond to global edit mode: show green background and allow mouse interaction when enabled; restore click-through when disabled
    InfinityTools:RegisterEditModeCallback(INFINITY_MODULE_KEY, function(enabled)
        f:EnableMouse(enabled)
        editBg:SetShown(enabled)
    end)

    self:RefreshStyle(); self:RefreshRows()

    -- Watch for spec changes and auto-refresh stat rows (fixes primary stat label not updating)
    InfinityTools:WatchState("SpecID", INFINITY_MODULE_KEY, function()
        if self.frame then self:RefreshRows() end
    end)
end

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    if not info then return end
    if info.key == "selectedRow" or info.key == "label" or info.key == "syncFont" then
        REGISTER_LAYOUT(); InfinityTools.UI:RefreshContent()
    end
    if EXStatsUI.frame then
        EXStatsUI:RefreshStyle(); EXStatsUI:RefreshRows()
    end
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end
    local sel = tonumber(MODULE_DB.selectedRow) or 1
    if info.key == "btn_up" and sel > 1 then
        local t = sel - 1; MODULE_DB.rows[sel], MODULE_DB.rows[t] = MODULE_DB.rows[t], MODULE_DB.rows[sel]; MODULE_DB.selectedRow = t; REGISTER_LAYOUT(); InfinityTools
            .UI:RefreshContent()
    elseif info.key == "btn_down" and sel < #MODULE_DB.rows then
        local t = sel + 1; MODULE_DB.rows[sel], MODULE_DB.rows[t] = MODULE_DB.rows[t], MODULE_DB.rows[sel]; MODULE_DB.selectedRow = t; REGISTER_LAYOUT(); InfinityTools
            .UI:RefreshContent()
    elseif info.key == "btn_add" then
        table.insert(MODULE_DB.rows,
            {
                enabled = true,
                label = "New Stat",
                key = "None",
                isPercent = true,
                format = 1,
                syncFont = true,
                roles = { TANK = true, HEALER = true, DAMAGER = true },
                scenes = { ["In Instance"] = true, ["Out of Instance"] = true },
                fontLabel =
                    GetDefaultFont(),
                fontValue = GetDefaultFont()
            })
        MODULE_DB.selectedRow = #MODULE_DB.rows; REGISTER_LAYOUT(); InfinityTools.UI:RefreshContent()
    elseif info.key == "btn_delete" and #MODULE_DB.rows > 1 then
        table.remove(MODULE_DB.rows, sel); MODULE_DB.selectedRow = math.max(1, sel - 1); REGISTER_LAYOUT(); InfinityTools.UI
            :RefreshContent()
    elseif info.key == "btn_reset" and InfinityPlayerStatsFrame then
        MODULE_DB.pos = { point = "CENTER", x = 0, y = 0 }; InfinityPlayerStatsFrame:SetPoint("CENTER", 0, 0)
    end
end)

C_Timer.After(1.5, function() EXStatsUI:Init() end)
InfinityTools:ReportReady(INFINITY_MODULE_KEY)
