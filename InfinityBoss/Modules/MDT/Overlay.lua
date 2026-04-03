---@diagnostic disable: undefined-global

local MDTMod = InfinityBoss.MDT
MDTMod.Overlay = MDTMod.Overlay or {}

local Overlay = MDTMod.Overlay
local Provider = MDTMod.Provider
local Runtime = MDTMod.Runtime
local L = InfinityBoss.L or setmetatable({}, { __index = function(_, key) return key end })

local frame
local mobRows = {}
local MIN_OVERLAY_W = 360
local MIN_OVERLAY_H = 380
local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus

local function SavePosition(self)
    local db = MDTMod.EnsureDB()
    local overlay = db.overlay
    local ui = UIParent
    local cx, cy = self:GetCenter()
    local ux, uy = ui:GetCenter()
    if not (cx and cy and ux and uy) then
        return
    end
    overlay.anchorX = MDTMod.Round(cx - ux, 0)
    overlay.anchorY = MDTMod.Round(cy - uy, 0)
end

local function GetMobRow(index)
    local row = mobRows[index]
    if row then
        return row
    end
    row = CreateFrame("Frame", nil, frame)
    row:SetSize(280, 18)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(14, 14)
    row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetTextColor(0.9, 0.93, 1)
    mobRows[index] = row
    return row
end

local function PositionMobRow(row, previousRow)
    row:ClearAllPoints()
    if previousRow then
        row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -4)
    else
        row:SetPoint("TOPLEFT", frame.mobTitle, "BOTTOMLEFT", 0, -8)
    end
end

local function EnsureFrame()
    if frame then
        return
    end

    local db = MDTMod.EnsureDB().overlay

    frame = CreateFrame("Frame", "InfinityBoss_MDTOverlay", UIParent, "BackdropTemplate")
    frame:SetSize(math.max(tonumber(db.width) or 0, MIN_OVERLAY_W), math.max(tonumber(db.height) or 0, MIN_OVERLAY_H))
    frame:SetScale(db.scale or 1)
    frame:SetAlpha(db.alpha or 0.96)
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:SetClampedToScreen(false)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
    end)
    frame:SetPoint("CENTER", UIParent, "CENTER", db.anchorX or 540, db.anchorY or 80)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
    frame:SetBackdropBorderColor(0.28, 0.3, 0.36, 1)

    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)
    frame.closeButton:SetScript("OnClick", function()
        Overlay.SetEnabled(false)
    end)

    frame.imageFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.imageFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -12)
    frame.imageFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -12)
    frame.imageFrame:SetHeight(170)
    frame.imageFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame.imageFrame:SetBackdropColor(0.04, 0.04, 0.05, 0.95)
    frame.imageFrame:SetBackdropBorderColor(0.24, 0.26, 0.3, 1)

    frame.imageTexture = frame.imageFrame:CreateTexture(nil, "ARTWORK")
    frame.imageTexture:SetPoint("TOPLEFT", 6, -6)
    frame.imageTexture:SetPoint("BOTTOMRIGHT", -6, 6)

    frame.prevPullButton = CreateFrame("Button", nil, frame)
    frame.prevPullButton:SetSize(34, 34)
    frame.prevPullButton:SetPoint("TOPLEFT", frame.imageFrame, "BOTTOMLEFT", 0, -8)
    frame.prevPullButton:SetScript("OnClick", function()
        Runtime.StepManualPullIndex(-1)
    end)
    frame.prevPullButton.icon = frame.prevPullButton:CreateTexture(nil, "OVERLAY")
    frame.prevPullButton.icon:SetAllPoints()
    frame.prevPullButton.icon:SetAtlas("wowlabs-spectatecycling-arrowleft_hover", true)

    frame.nextPullButton = CreateFrame("Button", nil, frame)
    frame.nextPullButton:SetSize(34, 34)
    frame.nextPullButton:SetPoint("TOPRIGHT", frame.imageFrame, "BOTTOMRIGHT", 0, -8)
    frame.nextPullButton:SetScript("OnClick", function()
        Runtime.StepManualPullIndex(1)
    end)
    frame.nextPullButton.icon = frame.nextPullButton:CreateTexture(nil, "OVERLAY")
    frame.nextPullButton.icon:SetAllPoints()
    frame.nextPullButton.icon:SetAtlas("wowlabs-spectatecycling-arrowright_hover", true)

    frame.modeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.modeButton:SetSize(68, 24)
    frame.modeButton:SetPoint("CENTER", frame.imageFrame, "BOTTOM", 0, -25)
    frame.modeButton:SetScript("OnClick", function()
        Runtime.ToggleFollowMode()
    end)

    frame.progressText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.progressText:SetPoint("LEFT", frame.modeButton, "RIGHT", 8, 0)
    frame.progressText:SetJustifyH("LEFT")
    frame.progressText:SetTextColor(0.95, 0.9, 0.72)

    frame.noteText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.noteText:SetPoint("TOPLEFT", frame.prevPullButton, "BOTTOMLEFT", 0, -12)
    frame.noteText:SetPoint("RIGHT", frame, "RIGHT", -10, 0)
    frame.noteText:SetJustifyH("LEFT")
    frame.noteText:SetJustifyV("TOP")
    frame.noteText:SetTextColor(0.95, 0.9, 0.72)

    frame.mobTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.mobTitle:SetPoint("TOPLEFT", frame.noteText, "BOTTOMLEFT", 0, -12)
    frame.mobTitle:SetTextColor(1, 0.82, 0.45)
    frame.mobTitle:SetText("Current Pull Casters")
end

local function ApplyVisibility()
    EnsureFrame()
    local db = MDTMod.EnsureDB().overlay
    frame:SetScale(db.scale or 1)
    frame:SetAlpha(db.alpha or 0.96)
    frame:SetSize(math.max(tonumber(db.width) or 0, MIN_OVERLAY_W), math.max(tonumber(db.height) or 0, MIN_OVERLAY_H))
    if db.enabled == false or MDTMod.IsEnabled() ~= true then
        frame:Hide()
    else
        frame:Show()
    end
end

function Overlay.SetEnabled(enabled)
    local db = MDTMod.EnsureDB()
    db.overlay.enabled = enabled == true
    ApplyVisibility()
end

local function RenderRows(state)
    local currentPull = state and state.currentPull or nil
    local enemies = {}
    if currentPull and type(currentPull.enemies) == "table" then
        for _, enemy in ipairs(currentPull.enemies) do
            if Runtime.ShouldShowEnemy(enemy) then
                enemies[#enemies + 1] = enemy
            end
        end
    end

    local previousRow
    for i = 1, math.max(#mobRows, #enemies, 1) do
        local row = GetMobRow(i)
        local data = enemies[i]
        if data then
            PositionMobRow(row, previousRow)
            Provider.SetCreaturePortrait(row.icon, data.displayID, data.icon or 134400)
            local label = string.format("x%d %s", tonumber(data.count) or 0, tostring(data.name))
            local spellID = type(data.interruptibleSpells) == "table" and data.interruptibleSpells[1] or nil
            if spellID then
                local spellName = Provider.GetSpellName(spellID) or tostring(spellID)
                local spellIcon = Provider.GetSpellTexture(spellID)
                if spellIcon then
                    label = string.format("%s (|T%d:12:12:0:0|t %s)", label, spellIcon, spellName)
                else
                    label = string.format("%s (%s)", label, spellName)
                end
            end
            row.text:SetText(label)
            row:Show()
            previousRow = row
        elseif i == 1 and #enemies == 0 then
            PositionMobRow(row, nil)
            row.icon:SetTexture(134400)
            row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            row.text:SetText("No interruptible mobs")
            row:Show()
            previousRow = row
        else
            row:Hide()
        end
    end
end

local function RenderPullImage(state)
    if not (frame and frame.imageTexture) then
        return
    end
    frame.imageTexture:SetTexture(nil)
    local snapshot = state and state.snapshot
    local pullIndex = state and state.currentPullIndex or nil
    local collectionKey = state and state.collectionKey or nil
    local path = snapshot and Provider.GetPullImagePath(snapshot.mapID, pullIndex, collectionKey) or nil
    if path then
        frame.imageTexture:SetTexture(path)
    end
end

function Overlay.Refresh(state)
    EnsureFrame()
    ApplyVisibility()
    if not frame:IsShown() then
        return
    end

    if not (state and state.ok) then
        frame:Hide()
        return
    end

    local snapshot = state.snapshot
    if state.currentNote and state.currentNote ~= "" then
        frame.noteText:SetText(string.format("Note: %s", state.currentNote))
    else
        frame.noteText:SetText("Note: none")
    end

    if frame.modeButton then
        frame.modeButton:SetText((state.mode == "manual") and "Manual" or "Auto")
    end
    if frame.progressText then
        local progress = state.progress
        if progress and tonumber(progress.total) and tonumber(progress.total) > 0 then
            frame.progressText:SetText(string.format("%.1f%%", tonumber(progress.percent) or 0))
        else
            frame.progressText:SetText("0.0%%")
        end
    end

    if frame.prevPullButton then
        local manual = state.mode == "manual"
        local canPrev = (tonumber(state.currentPullIndex) or 1) > 1
        frame.prevPullButton:SetEnabled(manual and canPrev)
        frame.prevPullButton:SetAlpha((manual and canPrev) and 1 or 0.35)
    end
    if frame.nextPullButton then
        local manual = state.mode == "manual"
        local canNext = (tonumber(state.currentPullIndex) or 1) < #snapshot.pulls
        frame.nextPullButton:SetEnabled(manual and canNext)
        frame.nextPullButton:SetAlpha((manual and canNext) and 1 or 0.35)
    end

    RenderPullImage(state)
    RenderRows(state)
end

EnsureFrame()
Runtime.RegisterListener("MDTOverlay", function(state)
    Overlay.Refresh(state)
end)
Overlay.Refresh(Runtime.GetState())

