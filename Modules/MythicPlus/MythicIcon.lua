local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
local SpellData = RRT_NS.MythicSpellData
if not Core or not SpellData then
    return
end

local MODULE_KEY = "RRTTools.MythicIcon"
local DEFAULTS = {
    enabled = false,
    locked = true,
    posX = 0,
    posY = 200,
    width = 420,
}

local DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
local frame
local buttons = {}

local function GetDungeonList()
    local data = RRT_NS.MythicSpellData or SpellData
    if not data then
        return {}
    end
    if type(data.GetDungeonList) == "function" then
        return data:GetDungeonList() or {}
    end
    return data.Dungeons or {}
end

local function GetBestLevels()
    local best = {}
    local history = C_MythicPlus and C_MythicPlus.GetRunHistory and C_MythicPlus.GetRunHistory(false, true, true) or {}
    for _, run in ipairs(history) do
        local current = best[run.mapChallengeModeID]
        if not current or (run.level or 0) > current then
            best[run.mapChallengeModeID] = run.level or 0
        end
    end
    return best
end

local function EnsureFrame()
    if frame then
        return frame
    end

    frame = CreateFrame("Frame", "RRTMythicIconFrame", UIParent, "BackdropTemplate")
    frame:SetSize(DB.width or DEFAULTS.width, 90)
    frame:SetPoint("CENTER", UIParent, "CENTER", DB.posX or 0, DB.posY or DEFAULTS.posY)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0.03, 0.03, 0.03, 0.7)
    frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
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

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", 8, -8)
    title:SetText("Mythic Icons")

    for i = 1, 8 do
        local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
        button:SetSize(44, 44)
        button:SetPoint("TOPLEFT", 10 + ((i - 1) * 50), -24)
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        button:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
        button:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetAllPoints()

        button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.text:SetPoint("CENTER")

        button.sub = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        button.sub:SetPoint("BOTTOM", 0, 2)

        buttons[i] = button
    end

    frame:Hide()
    return frame
end

RRT_NS.MythicIcon = {
    RefreshDisplay = function()
        DB = Core:GetModuleDB(MODULE_KEY, DEFAULTS)
        EnsureFrame()
        frame:SetWidth(DB.width or DEFAULTS.width)
        local bestLevels = GetBestLevels()
        local dungeons = GetDungeonList()
        for i = 1, #buttons do
            local button = buttons[i]
            local entry = dungeons[i]
            if entry then
                button.icon:SetTexture(entry.icon or 134400)
                button.text:SetText(entry.abbreviation or "?")
                button.sub:SetText(bestLevels[entry.mapID] and ("+" .. bestLevels[entry.mapID]) or "-")
                button:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(entry.name, 1, 1, 1)
                    GameTooltip:AddLine("Best level: " .. (bestLevels[entry.mapID] and ("+" .. bestLevels[entry.mapID]) or "none"), 0.8, 0.8, 0.8)
                    GameTooltip:Show()
                end)
                button:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
                button:Show()
            else
                button:Hide()
            end
        end
        if DB.enabled then
            frame:Show()
        else
            frame:Hide()
        end
    end,
    ToggleWindow = function()
        EnsureFrame()
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
            RRT_NS.MythicIcon:RefreshDisplay()
        end
    end,
}

Core:RegisterHUD(MODULE_KEY, EnsureFrame())
RRT_NS.MythicIcon:RefreshDisplay()
