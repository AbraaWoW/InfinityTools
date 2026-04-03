local _, RRT_NS = ...
local Core = _G.RRTMythicTools
if not Core then return end

local MODULE_KEY = "RRTTools.InterruptTracker"
local DEFAULTS = {
    enabled = true,
    locked = true,
    width = 220,
    barHeight = 18,
    maxEntries = 6,
    spacing = 4,
    growDirection = "DOWN", -- "UP" supported
    duration = 18,
    anchor = "CENTER",
    posX = 0,
    posY = -120,
    showIcon = true,
    classColor = true,
}

local DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
local moduleEnabled = Core:IsModuleEnabled(MODULE_KEY)

local frame = CreateFrame("Frame", "RRTInterruptTrackerFrame", UIParent, "BackdropTemplate")
frame:SetSize(DB.width, (DB.barHeight + DB.spacing) * DB.maxEntries - DB.spacing + 4)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("MEDIUM")
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

local bars = {}
local interrupts = {}
local Bit      = _G.bit or _G.bit32
local Colors   = _G.RAID_CLASS_COLORS or _G.CUSTOM_CLASS_COLORS or {}
local GetTime  = _G.GetTime
local CLG      = _G.CombatLogGetCurrentEventInfo
local GetPlayerInfoByGUID = _G.GetPlayerInfoByGUID
local GameTooltip = _G.GameTooltip
local tinsert  = table.insert
local friendlyMask = Bit.bor(
    _G.COMBATLOG_OBJECT_AFFILIATION_PARTY,
    _G.COMBATLOG_OBJECT_AFFILIATION_RAID,
    _G.COMBATLOG_OBJECT_AFFILIATION_MINE,
    _G.COMBATLOG_OBJECT_REACTION_FRIENDLY
)

local function CreateBar(index)
    local bar = bars[index]
    if not bar then
        bar = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetMinMaxValues(0, DB.duration)
        bar:GetStatusBarTexture():SetHorizTile(false)
        bar.bg = bar:CreateTexture(nil, "BACKGROUND")
        bar.bg:SetAllPoints()
        bar.bg:SetColorTexture(0.05, 0.05, 0.05, 0.8)
        bar.border = bar:CreateTexture(nil, "BORDER")
        bar.border:SetColorTexture(0, 0, 0, 0.9)
        bar.border:SetPoint("TOPLEFT", -1, 1)
        bar.border:SetPoint("BOTTOMRIGHT", 1, -1)

        bar.text = bar:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0)
        bar.text:SetJustifyH("LEFT")
        bar.text:SetJustifyV("CENTER")
        bar.text:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")

        bars[index] = bar
    end
    return bar
end

local function UpdatePosition()
    frame:ClearAllPoints()
    frame:SetPoint(DB.anchor or "CENTER", UIParent, DB.anchor or "CENTER", DB.posX or 0, DB.posY or -120)
end

local function ApplySettings()
    frame:SetSize(DB.width, (DB.barHeight + DB.spacing) * DB.maxEntries - DB.spacing + 4)
    UpdatePosition()
end

local function SortEntries(now)
    local list = {}
    for name, info in pairs(interrupts) do
        if info.expires > now then
            tinsert(list, {
                name = name,
                spell = info.spell,
                expires = info.expires,
                class = info.class,
                remaining = info.expires - now,
            })
        else
            interrupts[name] = nil
        end
    end
    table.sort(list, function(a, b) return a.remaining < b.remaining end)
    return list
end

local function RefreshBars()
    local now = GetTime()
    local list = SortEntries(now)
    for i = 1, DB.maxEntries do
        local bar = CreateBar(i)
        if list[i] then
            local info = list[i]
            bar:SetSize(DB.width, DB.barHeight)
            bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0,
                -((i - 1) * (DB.barHeight + DB.spacing)))
            bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0,
                -((i - 1) * (DB.barHeight + DB.spacing)))
            bar:SetMinMaxValues(0, DB.duration)
            bar:SetValue(math.min(info.remaining, DB.duration))
            bar.text:SetText(info.name .. " / " .. info.spell)
            if DB.classColor and info.class and Colors[info.class] then
                local c = Colors[info.class]
                bar:SetStatusBarColor(c.r, c.g, c.b, 1)
            else
                bar:SetStatusBarColor(0.75, 0.15, 0.15, 1)
            end
            bar:Show()
            bar:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(info.spell, 1, 1, 1)
                GameTooltip:AddLine(info.name, 0.7, 0.7, 0.7)
                GameTooltip:AddLine(string.format("Expires in %.1fs", info.remaining), 1, 1, 1)
                GameTooltip:Show()
            end)
            bar:SetScript("OnLeave", function() GameTooltip:Hide() end)
        else
            bar:Hide()
        end
    end
end

local function OnEvent(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, _, _, _, destName, _, _, spellId, spellName = CLG()
        if subevent == "SPELL_INTERRUPT" and sourceName and sourceName ~= "" then
            if Bit.band(sourceFlags, friendlyMask) == 0 then return end
            local class = select(2, GetPlayerInfoByGUID(sourceGUID)) or "PRIEST"
            interrupts[sourceName] = {
                spell = spellName or "Interrupt",
                class = class,
                expires = GetTime() + (DB.duration or DEFAULTS.duration),
            }
            RefreshBars()
        end
    elseif event == "PLAYER_REGEN_ENABLED" or event == "GROUP_ROSTER_UPDATE" then
        RefreshBars()
    end
end

local isVisible = false
local function UpdateVisibility()
    if DB.enabled then
        frame:Show()
        isVisible = true
    else
        frame:Hide()
        isVisible = false
    end
end

    local layout = {
        { key = "header", type = "header", x = 1, y = 1, w = 52, h = 2, label = "Interrupt Tracker", labelSize = 24 },
        { key = "desc", type = "description", x = 1, y = 4, w = 52, h = 2, label = "Track party interrupts in real time with countdown bars." },
        { key = "enabled", type = "checkbox", x = 1, y = 7, w = 10, h = 2, label = "Enable" },
        { key = "locked", type = "checkbox", x = 12, y = 7, w = 10, h = 2, label = "Lock Position" },
        { key = "maxEntries", type = "slider", x = 1, y = 10, w = 18, h = 2, label = "Max Bars", min = 1, max = 12, step = 1 },
        { key = "barHeight", type = "slider", x = 21, y = 10, w = 18, h = 2, label = "Bar Height", min = 14, max = 32, step = 1 },
        { key = "width", type = "slider", x = 1, y = 13, w = 38, h = 2, label = "Bar Width", min = 120, max = 360, step = 5 },
        { key = "spacing", type = "slider", x = 1, y = 16, w = 20, h = 2, label = "Spacing", min = 2, max = 16, step = 1 },
        { key = "growDirection", type = "dropdown", x = 22, y = 16, w = 16, h = 2, label = "Grow Direction", items = "DOWN,UP" },
        { key = "duration", type = "slider", x = 1, y = 19, w = 20, h = 2, label = "Duration (seconds)", min = 8, max = 30, step = 1 },
        { key = "classColor", type = "checkbox", x = 22, y = 19, w = 16, h = 2, label = "Use Class Colors" },
        { key = "posGroup", type = "header", x = 1, y = 23, w = 52, h = 2, label = "Position" },
        { key = "anchor", type = "dropdown", x = 1, y = 26, w = 18, h = 2, label = "Anchor", items = "CENTER,TOP,TOPLEFT,TOPRIGHT,BOTTOM,BOTTOMLEFT,BOTTOMRIGHT" },
        { key = "posX", type = "slider", x = 20, y = 26, w = 16, h = 2, label = "X Offset", min = -800, max = 800, step = 1 },
        { key = "posY", type = "slider", x = 37, y = 26, w = 16, h = 2, label = "Y Offset", min = -600, max = 600, step = 1 },
    }
    Core:RegisterModuleLayout(MODULE_KEY, layout)
end
RegisterLayout()

local Module = {
    frame = frame,
    db = DB,
}

function Module:RefreshDisplay()
    DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
    ApplySettings()
    UpdateVisibility()
    RefreshBars()
end

function Module:ResetPosition()
    DB.anchor = DEFAULTS.anchor
    DB.posX = DEFAULTS.posX
    DB.posY = DEFAULTS.posY
    UpdatePosition()
end

if moduleEnabled then
    frame:SetScript("OnDragStart", function(self)
        if not DB.locked then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        DB.anchor = point or DB.anchor
        DB.posX = x or DB.posX
        DB.posY = y or DB.posY
    end)
    frame:SetScript("OnEvent", OnEvent)
    frame:SetScript("OnUpdate", function()
        if not isVisible then return end
        RefreshBars()
    end)
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

Module:RefreshDisplay()

Core:RegisterHUD(MODULE_KEY, frame)
RRT_NS.TestInterrupt = Module
