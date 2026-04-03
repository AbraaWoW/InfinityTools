local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
if not Core then
    return
end

local MODULE_KEY = "RRTTools.MythicCast"
local DEFAULTS = {
    enabled = false,
    locked = true,
    width = 260,
    barHeight = 20,
    maxBars = 5,
    spacing = 3,
    posX = -420,
    posY = 0,
}

local DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
local frame = CreateFrame("Frame", "RRTMythicCastFrame", UIParent, "BackdropTemplate")
local bars = {}
local elapsedSinceScan = 0

local TRACKED_UNITS = { "target", "focus", "mouseover" }
for i = 1, 40 do
    TRACKED_UNITS[#TRACKED_UNITS + 1] = "nameplate" .. i
end
for i = 1, 5 do
    TRACKED_UNITS[#TRACKED_UNITS + 1] = "boss" .. i
end

frame:SetPoint("CENTER", UIParent, "CENTER", DB.posX or DEFAULTS.posX, DB.posY or 0)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
frame:SetBackdropColor(0.02, 0.02, 0.02, 0.3)
frame:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.8)
frame:SetScript("OnDragStart", function(self)
    if not DB.locked then
        self:StartMoving()
    end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local _, _, _, x, y = self:GetPoint()
    DB.posX = x
    DB.posY = y
end)

local function CreateBar(index)
    local bar = bars[index]
    if bar then
        return bar
    end

    bar = CreateFrame("StatusBar", nil, frame, "BackdropTemplate")
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    bar:SetBackdropColor(0.06, 0.06, 0.06, 0.95)
    bar:SetBackdropBorderColor(0.15, 0.15, 0.15, 1)

    bar.icon = bar:CreateTexture(nil, "ARTWORK")
    bar.icon:SetPoint("LEFT", 2, 0)

    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.text:SetPoint("LEFT", 26, 0)
    bar.text:SetPoint("RIGHT", -40, 0)
    bar.text:SetJustifyH("LEFT")

    bar.timer = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bar.timer:SetPoint("RIGHT", -6, 0)
    bars[index] = bar
    return bar
end

local function GetHostileCasts()
    local now = GetTime()
    local list = {}
    local seen = {}

    for _, unit in ipairs(TRACKED_UNITS) do
        if UnitExists(unit) and UnitCanAttack("player", unit) then
            local name, _, texture, startTimeMS, endTimeMS, _, _, notInterruptible = UnitCastingInfo(unit)
            local isChannel = false
            if not name then
                name, _, texture, startTimeMS, endTimeMS, _, notInterruptible = UnitChannelInfo(unit)
                isChannel = name ~= nil
            end

            if name and endTimeMS and startTimeMS then
                local unitName = UnitName(unit) or unit
                local castKey = string.format("%s:%s:%d:%d", unitName, name, startTimeMS or 0, endTimeMS or 0)
                if not seen[castKey] then
                    seen[castKey] = true
                    list[#list + 1] = {
                        unit = unit,
                        name = unitName,
                        spellName = name,
                        texture = texture or 136243,
                        startTime = startTimeMS / 1000,
                        endTime = endTimeMS / 1000,
                        remaining = math.max((endTimeMS / 1000) - now, 0),
                        interruptible = not notInterruptible,
                        isChannel = isChannel,
                    }
                end
            end
        end
    end

    table.sort(list, function(a, b)
        return a.remaining < b.remaining
    end)
    return list
end

local function RefreshBars()
    local casts = GetHostileCasts()
    local count = math.min(#casts, DB.maxBars or DEFAULTS.maxBars)
    frame:SetSize(DB.width or DEFAULTS.width, math.max(count, 1) * ((DB.barHeight or DEFAULTS.barHeight) + DB.spacing) + 2)

    for i = 1, DB.maxBars do
        local bar = CreateBar(i)
        local cast = casts[i]
        if cast then
            local duration = math.max(cast.endTime - cast.startTime, 0.1)
            local progress = cast.isChannel and cast.remaining or (duration - cast.remaining)

            bar:SetSize(DB.width or DEFAULTS.width, DB.barHeight or DEFAULTS.barHeight)
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -((i - 1) * ((DB.barHeight or DEFAULTS.barHeight) + DB.spacing)))
            bar:SetMinMaxValues(0, duration)
            bar:SetValue(progress)
            bar.icon:SetTexture(cast.texture)
            bar.icon:SetSize((DB.barHeight or DEFAULTS.barHeight) - 4, (DB.barHeight or DEFAULTS.barHeight) - 4)
            bar.text:SetText(string.format("%s - %s", cast.name, cast.spellName))
            bar.timer:SetText(string.format("%.1f", cast.remaining))
            if cast.interruptible then
                bar:SetStatusBarColor(0.22, 0.78, 0.3, 1)
            else
                bar:SetStatusBarColor(0.82, 0.22, 0.22, 1)
            end
            bar:Show()
        else
            bar:Hide()
        end
    end

    if DB.enabled and (count > 0 or not DB.locked) then
        frame:Show()
    else
        frame:Hide()
    end
end

frame:SetScript("OnUpdate", function(_, elapsed)
    elapsedSinceScan = elapsedSinceScan + elapsed
    if elapsedSinceScan < 0.1 then
        return
    end
    elapsedSinceScan = 0

    if DB.enabled then
        RefreshBars()
    end
end)

Core:RegisterHUD(MODULE_KEY, frame)
RRT_NS.MythicCast = {
    RefreshDisplay = function()
        DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", DB.posX or DEFAULTS.posX, DB.posY or 0)
        RefreshBars()
    end,
}

RRT_NS.MythicCast:RefreshDisplay()
