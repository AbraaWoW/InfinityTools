local _, RRT_NS = ...

local Core = RRT_NS.Mythic or _G.RRTMythicTools
if not Core then
    return
end

local Factory = {}
_G.RRTMythicFactory = Factory
Core.Factory = Factory

Factory.Pools = {}
Factory.ActiveTracker = {}

local function standardReset(_, frame)
    frame:Hide()
    frame:ClearAllPoints()
    frame:SetParent(UIParent)
    frame:SetAlpha(1)
    frame:SetScale(1)
    frame:SetScript("OnUpdate", nil)
    frame:SetScript("OnEnter", nil)
    frame:SetScript("OnLeave", nil)

    if frame.IsObjectType and frame:IsObjectType("Button") then
        frame:SetScript("OnClick", nil)
    end

    if frame.SetText then
        frame:SetText("")
    end

    if frame.icon then
        frame.icon:SetTexture(nil)
    end
    if frame.text and frame.text.SetText then
        frame.text:SetText("")
    end
    if frame.name and frame.name.SetText then
        frame.name:SetText("")
    end
    if frame.title and frame.title.SetText then
        frame.title:SetText("")
    end
    if frame.value and frame.value.SetText then
        frame.value:SetText("")
    end
    if frame.cells then
        for _, cell in ipairs(frame.cells) do
            cell:SetText("")
            cell:ClearAllPoints()
        end
    end
end

function Factory:InitPool(poolType, frameType, template, customInit)
    if self.Pools[poolType] then
        return
    end
    local pool = CreateFramePool(frameType or "Frame", UIParent, template, standardReset)
    pool.customInit = customInit
    self.Pools[poolType] = pool
end

function Factory:Acquire(poolType, parent)
    local pool = self.Pools[poolType]
    if not pool then
        self:InitPool(poolType, "Frame")
        pool = self.Pools[poolType]
    end

    local frame, isNew = pool:Acquire()
    frame._fromPool = poolType

    if isNew and pool.customInit then
        local ok, err = pcall(pool.customInit, frame)
        if not ok then
            Core:LogError("FramePool:" .. poolType, err)
        end
    end

    if parent then
        frame:SetParent(parent)
    end

    self.ActiveTracker[poolType] = self.ActiveTracker[poolType] or {}
    self.ActiveTracker[poolType][frame] = true
    frame:Show()
    return frame, isNew
end

function Factory:Release(poolType, frame)
    if not frame or not frame._fromPool then
        return
    end

    local actualType = frame._fromPool
    local pool = self.Pools[actualType]
    if not pool then
        frame:Hide()
        return
    end

    frame._fromPool = nil
    if self.ActiveTracker[actualType] then
        self.ActiveTracker[actualType][frame] = nil
    end
    pool:Release(frame)
end

Factory:InitPool("SimpleFrame", "Frame", "BackdropTemplate", function()
end)

Factory:InitPool("StandardRow", "Frame", nil, function(frame)
    frame:SetSize(720, 25)
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.cells = {}
    for _ = 1, 5 do
        local fontString = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        table.insert(frame.cells, fontString)
    end
end)

Factory:InitPool("IconTextCard", "Frame", "BackdropTemplate", function(frame)
    frame:SetSize(130, 65)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetSize(45, 45)
    frame.icon:SetPoint("LEFT", 0, -5)
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetPoint("TOP", 3, -6)
    frame.value = frame:CreateFontString(nil, "OVERLAY")
    frame.value:SetPoint("TOP", 2, -27)
end)

Factory:InitPool("StatRow", "Frame", "BackdropTemplate", function(frame)
    frame:SetSize(800, 45)
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetSize(40, 40)
    frame.icon:SetPoint("LEFT", 10, 0)
    frame.name = frame:CreateFontString(nil, "OVERLAY")
    frame.name:SetPoint("LEFT", 57, 0)
    frame.cells = {}
    for _ = 1, 10 do
        local fontString = frame:CreateFontString(nil, "OVERLAY")
        table.insert(frame.cells, fontString)
    end
end)

Factory:InitPool("RunRow", "Frame", "BackdropTemplate", function(frame)
    frame:SetSize(300, 40)
    frame.icon = frame:CreateTexture(nil, "OVERLAY")
    frame.icon:SetSize(30, 30)
    frame.icon:SetPoint("LEFT", 6, 0)
    frame.text = frame:CreateFontString(nil, "OVERLAY")
    frame.text:SetPoint("LEFT", 40, 0)
    frame.ilvl = frame:CreateFontString(nil, "OVERLAY")
    frame.ilvl:SetPoint("RIGHT", -8, 0)
end)

Factory:InitPool("DungeonIconOverlay", "Frame", nil, function(frame)
    frame.name = frame:CreateFontString(nil, "OVERLAY")
    frame.level = frame:CreateFontString(nil, "OVERLAY")
    frame.score = frame:CreateFontString(nil, "OVERLAY")
end)
