-- =============================================================
-- [[ Cast Sequence ]]
-- { Key = "RevTools.CastSequence", Name = "Cast Sequence", Desc = "Displays your recent casts with cast/channel/instant/interrupted states.", Category = 4 },
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
local InfinityDB = _G.InfinityDB
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

local INFINITY_MODULE_KEY = "RevTools.CastSequence"

-- =============================================================
-- Part 1: Grid layout. This must be registered first.
-- =============================================================
local function REGISTER_LAYOUT()
    local layout = {
        -- Header
        { key = "header", type = "header", x = 2, y = 1, w = 53, h = 3, label = L["Cast Sequence"], labelSize = 25 },
        { key = "desc", type = "description", x = 2, y = 4, w = 53, h = 2, label = L["Displays your cast sequence in real time, including cast/channel/instant/interrupt states."] },

        -- General settings
        { key = "sub_general", type = "subheader", x = 2, y = 6, w = 53, h = 2, label = L["General Settings"], labelSize = 20 },  -- TODO: missing key: L["General Settings"]
        { key = "divider_1", type = "divider", x = 2, y = 8, w = 53, h = 1 },
        { key = "enabled", type = "checkbox", x = 2, y = 10, w = 10, h = 2, label = L["Enable"] },  -- TODO: missing key: L["Enable"]
        { key = "locked", type = "checkbox", x = 14, y = 10, w = 10, h = 2, label = L["Lock Position"], desc = L["Use global edit mode to move the frame"] },
        { key = "showTooltip", type = "checkbox", x = 26, y = 10, w = 14, h = 2, label = L["Show tooltip on hover"] },

        -- Spell icon settings
        { key = "sub_square", type = "subheader", x = 2, y = 13, w = 53, h = 2, label = L["Spell Icon Settings"], labelSize = 20 },
        { key = "divider_2", type = "divider", x = 2, y = 15, w = 53, h = 1 },
        { key = "squareSize", type = "slider", x = 2, y = 17, w = 16, h = 2, label = L["Icon Size"], min = 16, max = 64, step = 1, labelPos = "top" },
        { key = "squareAmount", type = "slider", x = 20, y = 17, w = 16, h = 2, label = L["Icon Count"], min = 3, max = 20, step = 1, labelPos = "top" },
        { key = "frameScale", type = "slider", x = 38, y = 17, w = 16, h = 2, label = L["Scale"], min = 0.5, max = 2.0, step = 0.1, labelPos = "top" },
        {
            key = "squareGrowDirection",
            type = "dropdown",
            x = 2,
            y = 21,
            w = 16,
            h = 2,
            label = L["Grow Direction"],
            labelPos = "top",
            items = {
                { L["Right"], "right" },  -- TODO: missing key: L["Right"]
                { L["Left"], "left" },  -- TODO: missing key: L["Left"]
            }
        },
        {
            key = "frameStrata",
            type = "dropdown", --TEST
            x = 20,
            y = 21,
            w = 16,
            h = 2,
            label = L["Frame Strata"],
            labelPos = "top",
            items = {
                { "BACKGROUND", "BACKGROUND" },
                { "LOW",        "LOW" },
                { "MEDIUM",     "MEDIUM" },
                { "HIGH",       "HIGH" },
                { "DIALOG",     "DIALOG" },
            }
        },

        -- Ignored spells
        { key = "sub_ignore", type = "subheader", x = 2, y = 25, w = 53, h = 2, label = L["Ignored Spells"], labelSize = 20 },
        { key = "divider_3", type = "divider", x = 2, y = 27, w = 53, h = 1 },
        { key = "ignoreSpellId", type = "input", x = 2, y = 29, w = 18, h = 2, label = L["Spell ID"], labelPos = "top" },
        { key = "btn_addIgnore", type = "button", x = 22, y = 29, w = 10, h = 3, label = L["Add / Remove"] },
        { key = "btn_showIgnore", type = "button", x = 34, y = 29, w = 10, h = 3, label = L["Show List"] },
        { key = "btn_clearIgnore", type = "button", x = 46, y = 29, w = 10, h = 3, label = L["Clear List"] },
        { key = "desc_ignore", type = "description", x = 2, y = 32, w = 53, h = 1, label = L["Enter a Spell ID, then click Add/Remove. Ignored spells will not appear in the cast sequence."] },
    }

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT() -- Register immediately

-- =============================================================
-- Part 2: Load guard and environment filters
-- =============================================================
if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

-- =============================================================
-- Part 3: Dependencies and data initialization
-- =============================================================

-- Default settings
local INFINITY_DEFAULTS = {
    enabled = false,
    locked = true,   -- Locked by default, unlocked through Edit Mode
    preview = false, -- Edit Mode preview state

    -- Display settings
    frameScale = 1.0,
    frameStrata = "LOW",

    -- Position
    point = "RIGHT",
    relativePoint = "RIGHT",
    xOffset = -6.9,
    yOffset = -201.3,

    -- Icon settings
    squareSize = 36,
    squareAmount = 8,
    squareGrowDirection = "right",
    showTooltip = true,

    -- Ignored spells
    ignoredSpellIds = {},
    ignoreSpellId = "", -- Temporary EditBox value
}

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, INFINITY_DEFAULTS)

-- =============================================================
-- Part 4: Helper functions
-- =============================================================

-- Spell info helper for the 12.0 C_Spell API
local function GetSpellInfo(spellId)
    local spellInfo = C_Spell.GetSpellInfo(spellId)
    if spellInfo then
        return spellInfo.name, nil, spellInfo.iconID
    end
end

-- In 12.0 the UNIT_SPELLCAST_SENT target argument became a secret string.


local function CS_Print(msg)
    print("|cffff7700[" .. L["Cast Sequence"] .. "]|r " .. tostring(msg))
end

-- =============================================================
-- Part 5: Cast tracking
-- =============================================================

-- Cast tracking table
local CastsTable = {}

-- Debug mode
local debugMode = false
local debugSpellId = nil

local function DebugPrint(spellId, event, msg)
    if not debugMode then return end
    if debugSpellId and debugSpellId ~= spellId then return end
    local spellName = GetSpellInfo(spellId) or "Unknown"
    print(string.format("|cff00ff00[CS Debug]|r [%s] %s - %s", event, spellName, msg))
end

-- Built-in ignored spells
local ignoredSpells = {
    [49821] = true,  -- Mind Sear ticks
    [121557] = true, -- Angelic Feather walk-on
}

-- Spell color definitions
local COLOR_HARMFUL = { 0.9, 0.5, 0.5, 0.4 }
local COLOR_HELPFUL = { 0.1, 0.9, 0.1, 0.4 }
local COLOR_DEFAULT = { 0.5, 0.5, 0.5, 0.4 }

-- Previous spell tracking state
local lastSpell, lastCastId, lastChannelId, isChanneling, lastSpellId
local channelSpells = {}
local lastChannelSpell = ""

-- Duplicate cast debounce
local recentCasts = {}
local DUPLICATE_THRESHOLD = 0.5

-- Periodic cleanup of stale cast data (60s)
C_Timer.NewTicker(60, function()
    local now = GetTime()
    for castGUID, info in pairs(CastsTable) do
        if info.CastStart and (now - info.CastStart) > 120 then
            CastsTable[castGUID] = nil
        end
    end
    for spellId, timestamp in pairs(recentCasts) do
        if (now - timestamp) > 10 then
            recentCasts[spellId] = nil
        end
    end
    local channelCount = 0
    for _ in pairs(channelSpells) do channelCount = channelCount + 1 end
    if channelCount > 20 then
        channelSpells = {}
    end
end)

-- =============================================================
-- Part 6: Display system
-- =============================================================

-- Display data
local castContent = {}
local squares = {}
local totalSquares = 0

-- Main UI objects
local mainFrame, titleBar

-- Resolve spell display info (color/icon)
local function GetSpellDisplayInfo(spellId)
    local _, _, icon = GetSpellInfo(spellId)
    local backgroundcolor = COLOR_DEFAULT

    local isHarmful = C_Spell.IsSpellHarmful(spellId)
    local isHelpful = C_Spell.IsSpellHelpful(spellId)

    if isHarmful then
        backgroundcolor = COLOR_HARMFUL
    elseif isHelpful then
        backgroundcolor = COLOR_HELPFUL
    end

    local bordercolor = { 0, 0, 0, 0 }
    return icon, backgroundcolor, bordercolor
end

-- [12.0] ParseTargetName was removed because of secret-string taint.

-- ===================== Forward declarations =====================
local UpdateSquares, UpdateSquare, Refresh, RefreshAllSquareStyle, ReorderSquares
local CreateMainFrame, SavePosition, RestorePosition, UpdateLockState
local CreateSquareBox, SetSquareStyle, AutoSizeFrame
local UpdateCooldownFrame

-- ===================== Cooldown frame updates =====================
UpdateCooldownFrame = function(square, inCooldown, startTime, endTime, castInfo)
    if castInfo and (castInfo.Interrupted or castInfo.ChannelStopped) and castInfo.InterruptedPct then
        local completedPct = castInfo.InterruptedPct
        if completedPct < 0 then completedPct = 0 end
        if completedPct > 1 then completedPct = 1 end
        CooldownFrame_SetDisplayAsPercentage(square.cooldown, completedPct)
        square.cooldown:Show()
        return
    end

    if endTime and endTime < GetTime() then
        CooldownFrame_Clear(square.cooldown)
        square.cooldown:Hide()
        return
    end

    if inCooldown then
        local duration = endTime - startTime
        CooldownFrame_Set(square.cooldown, startTime, duration, duration > 0, true)
        square.cooldown:Show()
    else
        CooldownFrame_Clear(square.cooldown)
        square.cooldown:Hide()
    end
end

-- ===================== Square styling =====================
SetSquareStyle = function(square, index)
    square:SetSize(MODULE_DB.squareSize, MODULE_DB.squareSize)
end

-- ===================== Square ordering =====================
ReorderSquares = function()
    local direction = MODULE_DB.squareGrowDirection
    local spacing = 2

    -- [v4.7.6 Fix] Padding must stay constant so square anchors do not jump.
    local padding = 2

    for index = 1, #squares do
        local thisSquare = squares[index]
        thisSquare:ClearAllPoints()
        if direction == "right" then
            if index == 1 then
                thisSquare:SetPoint("topleft", mainFrame, "topleft", padding, -padding)
            else
                thisSquare:SetPoint("topleft", squares[index - 1], "topright", spacing, 0)
            end
        else
            if index == 1 then
                thisSquare:SetPoint("topright", mainFrame, "topright", -padding, -padding)
            else
                thisSquare:SetPoint("topright", squares[index - 1], "topleft", -spacing, 0)
            end
        end
    end
end

-- ===================== Create squares =====================
CreateSquareBox = function()
    local index = #squares + 1

    local square = CreateFrame("Frame", "CastSequenceSquare" .. index, mainFrame, "BackdropTemplate")
    square:SetBackdrop({
        bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        edgeFile = [[Interface\Buttons\WHITE8X8]],
        edgeSize = 1,
        tile = true,
        tileSize = 16,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    square:SetBackdropBorderColor(0, 0, 0, 0)
    square.squareIndex = index

    square.texture = square:CreateTexture(nil, "ARTWORK")
    square.texture:SetAllPoints()

    square.interruptedTexture = square:CreateTexture(nil, "OVERLAY")
    square.interruptedTexture:SetColorTexture(1, 0, 0, 0.4)
    square.interruptedTexture:SetAllPoints()
    square.interruptedTexture:Hide()

    local cooldown = CreateFrame("Cooldown", "$parentCooldown", square, "CooldownFrameTemplate, BackdropTemplate")
    cooldown:SetAllPoints()
    cooldown:EnableMouse(false)
    cooldown:SetHideCountdownNumbers(true)
    square.cooldown = cooldown

    -- Mouseover tooltip
    square:EnableMouse(true)
    -- [v4.7.6 Fix] Forward clicks to mainFrame in Edit Mode.
    square:SetScript("OnMouseDown", function(_, button)
        if not MODULE_DB.locked then
            mainFrame:GetScript("OnMouseDown")(mainFrame, button)
        end
    end)
    square:SetScript("OnMouseUp", function()
        if not MODULE_DB.locked then
            mainFrame:GetScript("OnMouseUp")(mainFrame)
        end
    end)
    square:SetScript("OnEnter", function(self)
        if not MODULE_DB.showTooltip then return end
        local data = castContent[self.squareIndex]
        if data then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            if data.spellId then
                local success = pcall(function()
                    GameTooltip:SetSpellByID(data.spellId)
                end)
                if success then
                    GameTooltip:AddLine("Spell ID: " .. data.spellId, 0.5, 0.5, 0.5)
                else
                    GameTooltip:AddLine(data.spellName or "Unknown Spell", 1, 1, 1)
                    GameTooltip:AddLine("Spell ID: " .. data.spellId, 0.5, 0.5, 0.5)
                end
            else
                GameTooltip:AddLine(data.spellName or "Unknown Spell", 1, 1, 1)
            end
            GameTooltip:Show()
        end
    end)
    square:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    squares[#squares + 1] = square
    square.in_use = 1
    square:Hide()

    SetSquareStyle(square, index)
    ReorderSquares()
end

-- ===================== Update one square =====================
UpdateSquare = function(index)
    local square = squares[index]
    if not square then return end

    local data = castContent[index]
    if data then
        square:Show()
        square.texture:SetTexture(data.icon)
        square.texture:SetTexCoord(5 / 64, 59 / 64, 5 / 64, 59 / 64)

        local castinfo = CastsTable[data.castID]
        local percent = castinfo and castinfo.Percent or 0
        if percent > 100 then percent = 100 end

        local startTime = data.startTime
        local endTime = data.endTime
        UpdateCooldownFrame(square, true, startTime, endTime, castinfo)

        -- Show the red interruption overlay only for non-channeled casts.
        if castinfo and castinfo.Interrupted and not castinfo.IsChanneled then
            square.interruptedTexture:Show()
        else
            square.interruptedTexture:Hide()
        end

        square.in_use = data.castStart
    else
        square:Hide()
        square.in_use = 1
    end
end

UpdateSquares = function()
    for index = 1, totalSquares do
        UpdateSquare(index)
    end
end

-- ===================== Refresh display =====================
Refresh = function()
    if not mainFrame then return end

    local amount = MODULE_DB.squareAmount or 8
    totalSquares = amount

    -- Auto-resize the frame
    AutoSizeFrame()

    while #squares < amount do
        CreateSquareBox()
    end

    for i = 1, #squares do
        if i <= amount then
            squares[i]:Show()
        else
            squares[i]:Hide()
        end
    end

    UpdateSquares()
end

RefreshAllSquareStyle = function()
    for i, square in ipairs(squares) do
        SetSquareStyle(square, i)
    end
    ReorderSquares()
    AutoSizeFrame()
end

-- ===================== Auto-size frame =====================
AutoSizeFrame = function()
    if not mainFrame then return end
    local squareSize = MODULE_DB.squareSize or 36
    local amount = MODULE_DB.squareAmount or 8
    local spacing = 2
    local width = squareSize * amount + spacing * (amount + 1)
    local height = squareSize + spacing * 2

    -- [v4.7.7 Fix] Never change the frame's physical size from AutoSizeFrame.
    -- Edit Mode uses editBG as the enlarged hit region so the CENTER anchor stays stable.
    mainFrame:SetSize(width, height)
end

-- ===================== Preview mode for Edit Mode =====================
local function TogglePreview(enabled)
    MODULE_DB.preview = enabled
    if enabled then
        -- Backup live data
        mainFrame._realCastContent = castContent

        -- Inject preview data with 5 sample spells
        local previewIcons = {
            { spellId = 116, name = "Frostbolt", icon = 134851 },
            { spellId = 44425, name = "Arcane Barrage", icon = 135732 },
            { spellId = 190356, name = "Glacial Spike", icon = 135838 },
            { spellId = 2139, name = "Counterspell", icon = 135856 },
            { spellId = 31661, name = "Dragon's Breath", icon = 135812 },
        }

        castContent = {}
        for i = 1, totalSquares do
            local p = previewIcons[(i % #previewIcons) + 1]
            table.insert(castContent, {
                spellId = p.spellId,
                spellName = p.name,
                icon = p.icon,
                castStart = GetTime() - i,
                startTime = GetTime() - i,
                endTime = GetTime() + 10,

            })
        end
    else
        -- Restore live data
        if mainFrame._realCastContent then
            castContent = mainFrame._realCastContent
            mainFrame._realCastContent = nil
        end
    end
    UpdateSquares()
end

-- ===================== Save/restore position =====================
SavePosition = function()
    if not mainFrame then return end

    local point, _, relativePoint, xOfs, yOfs = mainFrame:GetPoint()
    if point and relativePoint then
        MODULE_DB.point = point
        MODULE_DB.relativePoint = relativePoint
        MODULE_DB.xOffset = xOfs or 0
        MODULE_DB.yOffset = yOfs or 0
    end
end

RestorePosition = function()
    if not mainFrame then return end

    mainFrame:SetFrameStrata(MODULE_DB.frameStrata)
    mainFrame:SetScale(MODULE_DB.frameScale)
    AutoSizeFrame()

    mainFrame:ClearAllPoints()
    mainFrame:SetPoint(
        MODULE_DB.point or "CENTER",
        UIParent,
        MODULE_DB.relativePoint or "CENTER",
        MODULE_DB.xOffset or 0,
        MODULE_DB.yOffset or -100
    )
end

-- ===================== Lock state =====================
UpdateLockState = function()
    if not mainFrame then return end

    if MODULE_DB.locked then
        -- Locked mode: disable drag hit area and hide helper layer
        mainFrame:EnableMouse(false)
        if mainFrame.editBG then mainFrame.editBG:Hide() end
        if mainFrame.editLabel then mainFrame.editLabel:Hide() end
    else
        -- Edit Mode: enable drag hit area and show helper layer
        mainFrame:EnableMouse(true)
        if mainFrame.editBG then mainFrame.editBG:Show() end
        if mainFrame.editLabel then mainFrame.editLabel:Show() end
    end

    -- [v4.7.7 Fix] Squares must stop intercepting the mouse while unlocked.
    -- That lets mainFrame/editBG receive drags even when clicking directly on an icon.
    for _, square in ipairs(squares) do
        square:EnableMouse(MODULE_DB.locked) -- Locked=tooltips on, unlocked=no interception
    end

    AutoSizeFrame()
    ReorderSquares()
end

-- ===================== Reset position =====================
local function ResetPosition()
    MODULE_DB.point = INFINITY_DEFAULTS.point
    MODULE_DB.relativePoint = INFINITY_DEFAULTS.relativePoint
    MODULE_DB.xOffset = INFINITY_DEFAULTS.xOffset
    MODULE_DB.yOffset = INFINITY_DEFAULTS.yOffset
    RestorePosition()
    CS_Print("Cleared the entire ignore list")
end

-- [v4.0] Removed the old CreateTitleBar and switched to the core Edit Mode.
local function RegisterEditMode()
    InfinityTools:RegisterEditModeCallback(INFINITY_MODULE_KEY, function(enabled)
        MODULE_DB.locked = not enabled
        UpdateLockState()
        TogglePreview(enabled)
    end)
end

-- ===================== Create main frame =====================
CreateMainFrame = function()
    local frame = CreateFrame("Frame", "CastSequenceFrame", UIParent, "BackdropTemplate")
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    mainFrame = frame

    -- [v4.7.7] editBG is an expanded hit layer that does not alter the frame center.
    local editBG = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    editBG:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    editBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    editBG:SetBackdrop({
        bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    editBG:SetBackdropColor(0, 0.7, 0.2, 0.4)
    editBG:SetFrameLevel(frame:GetFrameLevel() - 1) -- Keep it behind text/icons
    editBG:Hide()
    frame.editBG = editBG

    -- Attach the helper label to the hit layer/main frame
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(InfinityTools.MAIN_FONT, 12, "OUTLINE")
    label:SetPoint("CENTER")
    label:SetText(L["Cast Sequence"])
    label:SetTextColor(0, 1, 0, 0.8)
    label:Hide()
    frame.editLabel = label

    -- Handle interaction on mainFrame/editBG. editBG is a child frame with its own mouse region.
    frame:SetScript("OnMouseDown", function(f, button)
        if MODULE_DB.locked then return end
        if button == "LeftButton" then
            f.moving = true
            f:StartMoving()
        elseif button == "RightButton" and InfinityTools.GlobalEditMode then
            InfinityTools:OpenConfig(INFINITY_MODULE_KEY)
        end
    end)

    frame:SetScript("OnMouseUp", function(f)
        if f.moving then
            f.moving = false
            f:StopMovingOrSizing()
            SavePosition()
        end
    end)

    -- [Critical Fix] Register the HUD and Edit Mode callback.
    RegisterEditMode()
    InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, frame)

    Refresh()
    UpdateLockState()
end

-- ===================== New cast record =====================
local lastDisplayedSpell = {}
local DISPLAY_DUPLICATE_THRESHOLD = 0.4

local function NewCast(icon, spellName, spellId, backgroundcolor, bordercolor, castID, castStart, startTime,
                       endTime)
    local now = GetTime()
    if lastDisplayedSpell.spellName == spellName and
        lastDisplayedSpell.time and
        (now - lastDisplayedSpell.time) < DISPLAY_DUPLICATE_THRESHOLD then
        if debugMode then
            print(string.format("|cff00ff00[CS Debug]|r NewCast BLOCKED: %s duplicate within %.3fs",
                tostring(spellName), now - lastDisplayedSpell.time))
        end
        return
    end

    lastDisplayedSpell.spellName = spellName
    lastDisplayedSpell.time = now

    if debugMode then
        local castIDShort = castID and tostring(castID):sub(-8) or "nil"
        print(string.format("|cff00ff00[CS Debug]|r NewCast: %s, spellId: %s, castID: ...%s, before: %d",
            tostring(spellName), tostring(spellId), castIDShort, #castContent))
    end

    table.insert(castContent, 1, {
        icon = icon,
        spellName = spellName,
        spellId = spellId,
        backgroundcolor = backgroundcolor,
        bordercolor = bordercolor,
        castID = castID,
        castStart = castStart,
        startTime = startTime,
        endTime = endTime
    })
    table.remove(castContent, totalSquares + 1)

    if debugMode then
        print(string.format("|cff00ff00[CS Debug]|r NewCast: castContent count after: %d, totalSquares: %d", #
            castContent, totalSquares))
    end

    UpdateSquares()
end

-- ===================== Cast started (cast bar) =====================
local function CastStart(castGUID)
    local castInfo = CastsTable[castGUID]
    if not castInfo then return end

    if castInfo.Displayed then return end

    local spellId = castInfo.SpellId
    local castStart = castInfo.CastStart
    local startTime = castInfo.CastTimeStart
    local endTime = castInfo.CastTimeEnd

    if ignoredSpells[spellId] then return end
    if MODULE_DB.ignoredSpellIds and MODULE_DB.ignoredSpellIds[spellId] then return end

    local icon, backgroundcolor, bordercolor = GetSpellDisplayInfo(spellId)
    local spellName = GetSpellInfo(spellId)

    castInfo.Displayed = true
    DebugPrint(spellId, "CastStart",
        string.format("Displaying via CastStart, castGUID=...%s", tostring(castGUID):sub(-8)))
    NewCast(icon, spellName, spellId, backgroundcolor, bordercolor, castGUID, castStart, startTime, endTime)
end

-- ===================== Cast finished (instant) =====================
local function CastFinished(castId)
    local castInfo = CastsTable[castId]
    if not castInfo then
        DebugPrint(nil, "CastFinished", "No castInfo for " .. tostring(castId))
        return
    end

    local spellId = castInfo.SpellId

    if castInfo.Displayed then
        DebugPrint(spellId, "CastFinished", "Skipped: already displayed (flag)")
        return
    end

    local castStart = castInfo.CastStart

    if spellId and ignoredSpells[spellId] then return end
    if spellId and MODULE_DB.ignoredSpellIds and MODULE_DB.ignoredSpellIds[spellId] then return end

    local icon, backgroundcolor, bordercolor = GetSpellDisplayInfo(spellId)
    local spellName = GetSpellInfo(spellId)

    castInfo.Displayed = true
    DebugPrint(spellId, "CastFinished",
        string.format("Displaying via CastFinished, castGUID=...%s", tostring(castId):sub(-8)))
    NewCast(icon, spellName, spellId, backgroundcolor, bordercolor, castId, castStart, GetTime(), GetTime() + 1.2)
end

-- ===================== OnUpdate: live cast progress =====================
local function TrackSpellCast()
    if not castContent or not squares then return end

    for i = 1, #castContent do
        local content = castContent[i]
        local square = squares[i]
        if not content or not square then break end

        local castInfo = CastsTable[content.castID]
        if castInfo and not castInfo.Done then
            if castInfo.PendingInterrupt then
                square.in_use = GetTime()
            elseif castInfo.HasCastTime then
                if castInfo.Success then
                    castInfo.Done = true
                    castInfo.Percent = 100
                    UpdateCooldownFrame(square, false)
                elseif castInfo.IsChanneled then
                    local name, _, _, startTime, endTime = UnitChannelInfo("player")
                    if name then
                        startTime = startTime / 1000
                        endTime = endTime / 1000
                        local diff = endTime - startTime
                        local current = GetTime() - startTime
                        local percent = current / diff * 100
                        castInfo.Percent = percent
                        UpdateCooldownFrame(square, true, startTime, endTime, castInfo)
                    end
                else
                    local _, _, _, startTime, endTime = UnitCastingInfo("player")
                    if startTime and endTime then
                        startTime = startTime / 1000
                        endTime = endTime / 1000
                        local diff = endTime - startTime
                        local current = GetTime() - startTime
                        local percent = current / diff * 100
                        castInfo.Percent = percent
                        UpdateCooldownFrame(square, true, startTime, endTime, castInfo)
                    else
                        UpdateCooldownFrame(square, false)
                    end
                end
            else
                -- Instant cast
                if castInfo.CastStart + 1.2 < GetTime() then
                    castInfo.Done = true
                    castInfo.Percent = 100
                    UpdateCooldownFrame(square, false)
                else
                    local startTime = castInfo.CastStart
                    local endTime = castInfo.CastStart + 1.2
                    local diff = endTime - startTime
                    local current = GetTime() - startTime
                    local percent = current / diff * 100
                    castInfo.Percent = percent
                    UpdateCooldownFrame(square, true, startTime, endTime, castInfo)
                end
            end

            square.in_use = GetTime()
        end
    end
end

-- ===================== Event frame =====================
local eventFrame = CreateFrame("Frame")

local function StartTracking()
    eventFrame:RegisterEvent("UNIT_SPELLCAST_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SENT")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    eventFrame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    eventFrame:SetScript("OnUpdate", TrackSpellCast)
end

local function StopTracking()
    eventFrame:UnregisterAllEvents()
    eventFrame:SetScript("OnUpdate", nil)
end

-- ===================== Event handler =====================
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "UNIT_SPELLCAST_SENT" then
        local unitID, _, castGUID, spellId = ...
        -- [12.0] Ignore the secret-string target argument.
        local spell = GetSpellInfo(spellId)

        if unitID == "player" then
            local existed = CastsTable[castGUID] ~= nil
            DebugPrint(spellId, "SENT",
                string.format("castGUID=%s existed=%s", tostring(castGUID), tostring(existed)))

            if not existed then
                CastsTable[castGUID] = {
                    Id = castGUID,
                    CastStart = GetTime(),
                    SpellId = spellId
                }
            else
                CastsTable[castGUID].SpellId = CastsTable[castGUID].SpellId or spellId
            end
            lastChannelSpell = castGUID
            lastSpell = spell
            lastSpellId = spellId
            lastCastId = castGUID
        end
    elseif event == "UNIT_SPELLCAST_START" then
        local unitID, castGUID, spellId = ...
        if unitID ~= "player" then return end

        DebugPrint(spellId, "START",
            string.format("unitID=%s castGUID=%s hasCastEntry=%s", tostring(unitID), tostring(castGUID),
                tostring(CastsTable[castGUID] ~= nil)))

        if CastsTable[castGUID] then
            CastsTable[castGUID].SpellId = spellId
            CastsTable[castGUID].HasCastTime = true

            local _, _, _, startTime, endTime = UnitCastingInfo("player")
            if startTime and endTime then
                CastsTable[castGUID].CastTimeStart = startTime / 1000
                CastsTable[castGUID].CastTimeEnd = endTime / 1000
            end

            CastStart(castGUID)
            DebugPrint(spellId, "START", "Called CastStart")
        end
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unitID, castGUID, spellId = ...
        if unitID ~= "player" then return end

        DebugPrint(spellId, "INTERRUPTED", string.format("castGUID=%s, hasEntry=%s",
            tostring(castGUID), tostring(CastsTable[castGUID] ~= nil)))

        if CastsTable[castGUID] then
            local castInfo = CastsTable[castGUID]

            if castInfo.Success then
                DebugPrint(spellId, "INTERRUPTED", "Ignored: spell already succeeded (latency)")
                return
            end

            castInfo.PendingInterrupt = true
            castInfo.InterruptTime = GetTime()
            castInfo.InterruptPct = (castInfo.Percent or 0) / 100

            local _, _, _, startTime, endTime = UnitCastingInfo("player")
            if startTime and endTime then
                startTime = startTime / 1000
                endTime = endTime / 1000
                local totalTime = endTime - startTime
                local elapsed = GetTime() - startTime
                castInfo.InterruptPct = elapsed / totalTime
            end

            if castInfo.InterruptPct < 0 then castInfo.InterruptPct = 0 end
            if castInfo.InterruptPct > 1 then castInfo.InterruptPct = 1 end

            DebugPrint(spellId, "INTERRUPTED",
                string.format("Pending, pct=%s, waiting for SUCCEEDED...", tostring(castInfo.InterruptPct * 100)))

            C_Timer.After(0.25, function()
                if castInfo.Success then
                    DebugPrint(spellId, "INTERRUPTED", "Cancelled: spell succeeded during delay")
                    castInfo.PendingInterrupt = false
                    return
                end

                if castInfo.PendingInterrupt then
                    castInfo.Interrupted = true
                    castInfo.InterruptedTime = castInfo.InterruptTime
                    castInfo.Done = true
                    castInfo.Percent = castInfo.InterruptPct * 100
                    castInfo.InterruptedPct = castInfo.InterruptPct
                    castInfo.PendingInterrupt = false

                    for i, content in ipairs(castContent) do
                        if content.castID == castGUID then
                            content.endTime = castInfo.InterruptTime
                            break
                        end
                    end

                    DebugPrint(spellId, "INTERRUPTED",
                        string.format("Finalized: pct=%s", tostring(castInfo.InterruptPct * 100)))
                    UpdateSquares()
                end
            end)
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        local unitID, castGUID, spellId = ...

        if unitID == "player" then
            castGUID = lastChannelId

            if not CastsTable[castGUID] then
                castGUID = lastChannelSpell
                if not castGUID or not CastsTable[castGUID] then
                    isChanneling = false
                    lastChannelId = nil
                    return
                end
            end

            local castInfo = CastsTable[castGUID]

            local wasCompleted = castInfo.CastTimeEnd and GetTime() >= (castInfo.CastTimeEnd - 0.1)

            if wasCompleted then
                castInfo.Success = true
                castInfo.Done = true
                castInfo.Percent = 100
            else
                local completedPct = (castInfo.Percent or 0) / 100

                if castInfo.CastTimeStart and castInfo.CastTimeEnd then
                    local totalTime = castInfo.CastTimeEnd - castInfo.CastTimeStart
                    local elapsed = GetTime() - castInfo.CastTimeStart
                    completedPct = elapsed / totalTime
                end

                if completedPct < 0 then completedPct = 0 end
                if completedPct > 1 then completedPct = 1 end

                castInfo.ChannelStopped = true
                castInfo.Done = true
                castInfo.Percent = completedPct * 100
                castInfo.InterruptedPct = completedPct

                for i, content in ipairs(castContent) do
                    if content.castID == castGUID then
                        content.endTime = GetTime()
                        break
                    end
                end
            end

            isChanneling = false
            lastChannelId = nil
            UpdateSquares()
        end
    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local unitID, castGUID, spellId = ...

        if unitID == "player" then
            if not castGUID or castGUID == "" then
                castGUID = lastCastId
            end

            if not CastsTable[castGUID] then
                castGUID = lastChannelSpell
            end

            if not CastsTable[castGUID] then
                castGUID = lastCastId or ("channel_" .. GetTime())
                CastsTable[castGUID] = { Id = castGUID, CastStart = GetTime() }
            end

            if isChanneling and lastChannelId and CastsTable[lastChannelId] then
                CastsTable[lastChannelId].Interrupted = true
                CastsTable[lastChannelId].InterruptedTime = GetTime()
            end

            CastsTable[castGUID].HasCastTime = true
            CastsTable[castGUID].IsChanneled = true
            CastsTable[castGUID].SpellId = lastSpellId
            lastChannelId = castGUID
            isChanneling = true

            local _, _, _, startTime, endTime = UnitChannelInfo("player")
            if startTime and endTime then
                CastsTable[castGUID].CastTimeStart = startTime / 1000
                CastsTable[castGUID].CastTimeEnd = endTime / 1000
            end

            if lastSpell then
                channelSpells[lastSpell] = true
            end

            CastStart(castGUID)
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitID, castGUID, spellId = ...

        if unitID ~= "player" then return end

        local spell = GetSpellInfo(spellId)

        DebugPrint(spellId, "SUCCEEDED", string.format("castGUID=%s hasCastEntry=%s isChannel=%s",
            tostring(castGUID), tostring(CastsTable[castGUID] ~= nil), tostring(channelSpells[spell])))

        if not channelSpells[spell] then
            local castInfo = CastsTable[castGUID]

            if castInfo and castInfo.Displayed then
                DebugPrint(spellId, "SUCCEEDED", "Skipped: already displayed by CastStart")
                castInfo.Success = true
                return
            end

            -- [12.0] No SENT record means a side effect/multi-hit proc, so ignore it.
            -- Player casts always fire UNIT_SPELLCAST_SENT first and already exist in CastsTable.
            if not castInfo then
                DebugPrint(spellId, "SUCCEEDED", "Skipped: no SENT record (secondary effect)")
                return
            end

            local now = GetTime()
            if recentCasts[spellId] and (now - recentCasts[spellId]) < DUPLICATE_THRESHOLD then
                DebugPrint(spellId, "SUCCEEDED",
                    string.format("Skipped: duplicate within %.3fs", now - recentCasts[spellId]))
                return
            end

            recentCasts[spellId] = now

            castInfo.Success = true
            castInfo.SpellId = spellId

            CastFinished(castGUID)
            DebugPrint(spellId, "SUCCEEDED", "Called CastFinished")
        end
    end
end)

-- ===================== Expiry cleanup (10s) =====================
C_Timer.NewTicker(10, function()
    if not mainFrame then return end
    local now = GetTime()
    local EXPIRE_TIME = 60

    local i = 1
    while i <= #castContent do
        local content = castContent[i]
        if content and content.castStart and (content.castStart + EXPIRE_TIME < now) then
            table.remove(castContent, i)
        else
            i = i + 1
        end
    end
    UpdateSquares()
end)

-- =============================================================
-- Part 7: Event and state subscriptions
-- =============================================================

-- Listen for database changes from the Grid panel.
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end

    local key = info.key

    -- Display setting changes
    if key == "frameScale" then
        if mainFrame then mainFrame:SetScale(MODULE_DB.frameScale) end
    elseif key == "frameStrata" then
        if mainFrame then mainFrame:SetFrameStrata(MODULE_DB.frameStrata) end
    elseif key == "locked" then
        UpdateLockState()
    elseif key == "enabled" then
        if MODULE_DB.enabled then
            if mainFrame then mainFrame:Show() end
            StartTracking()
        else
            if mainFrame then mainFrame:Hide() end
            StopTracking()
        end
    elseif key == "squareSize" then
        RefreshAllSquareStyle()
    elseif key == "squareAmount" then
        Refresh()
    elseif key == "squareGrowDirection" then
        ReorderSquares()
    end
end)

-- Handle button clicks
InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end

    if info.key == "btn_reset" then
        ResetPosition()
        CS_Print("Position reset")
    elseif info.key == "btn_addIgnore" then
        local idStr = MODULE_DB.ignoreSpellId
        local id = tonumber(idStr)
        if id then
            if not MODULE_DB.ignoredSpellIds then
                MODULE_DB.ignoredSpellIds = {}
            end
            if MODULE_DB.ignoredSpellIds[id] then
                MODULE_DB.ignoredSpellIds[id] = nil
                local spellName = GetSpellInfo(id) or "Unknown"
                CS_Print(string.format("Removed from ignore list: %s (ID: %d)", spellName, id))
            else
                MODULE_DB.ignoredSpellIds[id] = true
                local spellName = GetSpellInfo(id) or "Unknown"
                CS_Print(string.format("Added to ignore list: %s (ID: %d)", spellName, id))
            end
            MODULE_DB.ignoreSpellId = ""
        else
            CS_Print("Enter a valid numeric spell ID")
        end
    elseif info.key == "btn_showIgnore" then
        local count = 0
        CS_Print("Ignored spells:")
        if MODULE_DB.ignoredSpellIds then
            for id, _ in pairs(MODULE_DB.ignoredSpellIds) do
                local spellName = GetSpellInfo(id) or "Unknown"
                print(string.format("  - %s (ID: %d)", spellName, id))
                count = count + 1
            end
        end
        if count == 0 then
            print("  (None)")
        else
            CS_Print(string.format("Total spells: %d", count))
        end
    elseif info.key == "btn_clearIgnore" then
        MODULE_DB.ignoredSpellIds = {}
        CS_Print("Cleared the entire ignore list")
    end
end)

-- =============================================================
-- Part 8: Initialization
-- =============================================================

InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY, function(event, isLogin, isReload)
    -- Clear stale data
    castContent = {}
    for k in pairs(CastsTable) do CastsTable[k] = nil end

    -- Create the main frame
    if not mainFrame then
        CreateMainFrame()
    end

    -- Restore position
    RestorePosition()

    -- Show and start tracking
    if MODULE_DB.enabled then
        mainFrame:Show()
        StartTracking()
    else
        mainFrame:Hide()
    end
end)

-- Report module ready
InfinityTools:ReportReady(INFINITY_MODULE_KEY)

