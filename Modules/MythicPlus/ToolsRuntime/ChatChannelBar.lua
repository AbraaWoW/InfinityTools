-- =============================================================
-- [[ Chat Channel Bar ]]
-- { Key = "RRTTools.ChatChannelBar", Name = "Chat Channel Bar", Desc = "Quick channel bar with customizable labels, colors, and commands.", Category = 1 },
-- =============================================================

local RRTToolsCore = _G.RRTToolsCore
local EXDB = _G.EXDB
local RRT_NS = _G.RRT_NS or {}
_G.RRT_NS = RRT_NS
if not RRTToolsCore then return end
local L = (RRTToolsCore and RRTToolsCore.L) or setmetatable({}, { __index = function(_, key) return key end })

local RRT_MODULE_KEY = "RRTTools.ChatChannelBar"

-- Global references
local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local C_Timer = _G.C_Timer
local wipe = _G.wipe
local ChatEdit_ChooseBoxForSend = _G.ChatEdit_ChooseBoxForSend
local ChatEdit_SendText = _G.ChatEdit_SendText
local ChatEdit_ActivateChat = _G.ChatEdit_ActivateChat
local GetChannelName = _G.GetChannelName
local SlashCmdList = _G.SlashCmdList

-- =============================================================
-- Grid layout
-- =============================================================
local function RRT_RegisterLayout()
    local layout = {
        { key = "header", type = "header", x = 2, y = 1, w = 50, h = 2, label = L["Chat Channel Bar"], labelSize = 25 },
        { key = "desc", type = "description", x = 2, y = 4, w = 50, h = 2, label = L["Quick channel bar with customizable labels, colors, and commands."] },

        { key = "div1", type = "divider", x = 2, y = 7, w = 50, h = 1 },

        -- Basic settings
        { key = "subheader_basic", type = "subheader", x = 2, y = 6, w = 50, h = 1, label = L["Basic Settings"], labelSize = 20 },
        { key = "locked", type = "checkbox", x = 2, y = 8, w = 8, h = 2, label = L["Lock Position"] },
        { key = "btn_reset_pos", type = "button", x = 12, y = 8, w = 12, h = 2, label = L["Reset Position"] },

        { key = "fontSize", type = "slider", x = 2, y = 11, w = 16, h = 2, label = L["Font Size"], min = 10, max = 30, step = 1 },
        { key = "buttonPadding", type = "slider", x = 20, y = 11, w = 16, h = 2, label = L["Button Spacing"], min = 0, max = 20, step = 1 },
        { key = "buttonSize", type = "slider", x = 38, y = 11, w = 16, h = 2, label = L["Button Size"], min = 20, max = 50, step = 1 },

        { key = "fontOutline", type = "dropdown", x = 2, y = 14, w = 16, h = 2, label = L["Outline"], items = "None,OUTLINE,THICKOUTLINE" },
        { key = "anchorMode", type = "dropdown", x = 20, y = 14, w = 18, h = 2, label = L["Anchor Target"], items = "None,Blizzard (ChatFrame1),Chattynator,ElvUI" },

        { key = "div2", type = "divider", x = 2, y = 17, w = 50, h = 1 },

        -- Channel settings
        { key = "channels_header", type = "header", x = 2, y = 18, w = 50, h = 2, label = L["Channel Settings"], labelSize = 20 },

-- Comment translated to English
        { key = "show_world", type = "checkbox", x = 2, y = 21, w = 8, h = 2, label = L["World"] },
        { key = "world", type = "color", x = 11, y = 21, w = 12, h = 2, label = L["Color"] },
        { key = "world_name", type = "input", x = 24, y = 21, w = 10, h = 2, label = L["Label"], placeholder = L["W"] },
        { key = "world_channel", type = "input", x = 35, y = 21, w = 17, h = 2, label = L["Command"], placeholder = "World" },

-- Comment translated to English
        { key = "show_say", type = "checkbox", x = 2, y = 24, w = 8, h = 2, label = L["Say"] },
        { key = "say", type = "color", x = 11, y = 24, w = 12, h = 2, label = L["Color"] },
        { key = "say_name", type = "input", x = 24, y = 24, w = 10, h = 2, label = L["Label"], placeholder = L["S"] },
        { key = "say_channel", type = "input", x = 35, y = 24, w = 17, h = 2, label = L["Command"], placeholder = "/s" },

-- Comment translated to English
        { key = "show_yell", type = "checkbox", x = 2, y = 27, w = 8, h = 2, label = L["Yell"] },
        { key = "yell", type = "color", x = 11, y = 27, w = 12, h = 2, label = L["Color"] },
        { key = "yell_name", type = "input", x = 24, y = 27, w = 10, h = 2, label = L["Label"], placeholder = L["Y"] },
        { key = "yell_channel", type = "input", x = 35, y = 27, w = 17, h = 2, label = L["Command"], placeholder = "/y" },

-- Comment translated to English
        { key = "show_party", type = "checkbox", x = 2, y = 30, w = 8, h = 2, label = L["Party"] },
        { key = "party", type = "color", x = 11, y = 30, w = 12, h = 2, label = L["Color"] },
        { key = "party_name", type = "input", x = 24, y = 30, w = 10, h = 2, label = L["Label"], placeholder = L["P"] },
        { key = "party_channel", type = "input", x = 35, y = 30, w = 17, h = 2, label = L["Command"], placeholder = "/p" },

-- Comment translated to English
        { key = "show_guild", type = "checkbox", x = 2, y = 33, w = 8, h = 2, label = L["Guild"] },
        { key = "guild", type = "color", x = 11, y = 33, w = 12, h = 2, label = L["Color"] },
        { key = "guild_name", type = "input", x = 24, y = 33, w = 10, h = 2, label = L["Label"], placeholder = L["G"] },
        { key = "guild_channel", type = "input", x = 35, y = 33, w = 17, h = 2, label = L["Command"], placeholder = "/g" },

-- Comment translated to English
        { key = "show_instance", type = "checkbox", x = 2, y = 36, w = 8, h = 2, label = L["Instance"] },
        { key = "instance", type = "color", x = 11, y = 36, w = 12, h = 2, label = L["Color"] },
        { key = "instance_name", type = "input", x = 24, y = 36, w = 10, h = 2, label = L["Label"], placeholder = L["I"] },
        { key = "instance_channel", type = "input", x = 35, y = 36, w = 17, h = 2, label = L["Command"], placeholder = "/i" },

-- Comment translated to English
        { key = "show_raid", type = "checkbox", x = 2, y = 39, w = 8, h = 2, label = L["Raid"] },
        { key = "raid", type = "color", x = 11, y = 39, w = 12, h = 2, label = L["Color"] },
        { key = "raid_name", type = "input", x = 24, y = 39, w = 10, h = 2, label = L["Label"], placeholder = L["R"] },
        { key = "raid_channel", type = "input", x = 35, y = 39, w = 17, h = 2, label = L["Command"], placeholder = "/raid" },

-- Comment translated to English
        { key = "show_roll", type = "checkbox", x = 2, y = 42, w = 8, h = 2, label = L["Roll"] },
        { key = "roll", type = "color", x = 11, y = 42, w = 12, h = 2, label = L["Color"] },
        { key = "roll_name", type = "input", x = 24, y = 42, w = 10, h = 2, label = L["Label"], placeholder = L["Roll"] },
        { key = "roll_channel", type = "input", x = 35, y = 42, w = 17, h = 2, label = L["Command"], placeholder = "/roll" },

-- Comment translated to English
        { key = "show_rc", type = "checkbox", x = 2, y = 45, w = 8, h = 2, label = L["Ready"] },
        { key = "rc", type = "color", x = 11, y = 45, w = 12, h = 2, label = L["Color"] },
        { key = "rc_name", type = "input", x = 24, y = 45, w = 10, h = 2, label = L["Label"], placeholder = L["RC"] },
        { key = "rc_channel", type = "input", x = 35, y = 45, w = 17, h = 2, label = L["Command"], placeholder = "/rc" },

-- Comment translated to English
        { key = "show_pull", type = "checkbox", x = 2, y = 48, w = 8, h = 2, label = L["Pull"] },
        { key = "pull", type = "color", x = 11, y = 48, w = 12, h = 2, label = L["Color"] },
        { key = "pull_name", type = "input", x = 24, y = 48, w = 10, h = 2, label = L["Label"], placeholder = L["Pull"] },
        { key = "pull_channel", type = "input", x = 35, y = 48, w = 17, h = 2, label = L["Command"], placeholder = "/cd 10" },

-- Comment translated to English
        { key = "show_custom1", type = "checkbox", x = 2, y = 51, w = 8, h = 2, label = L["Custom 1"] },
        { key = "custom1", type = "color", x = 11, y = 51, w = 12, h = 2, label = L["Color"] },
        { key = "custom1_name", type = "input", x = 24, y = 51, w = 10, h = 2, label = L["Label"], placeholder = L["C1"] },
        { key = "custom1_channel", type = "input", x = 35, y = 51, w = 17, h = 2, label = L["Command"], placeholder = "/MDT" },

-- Comment translated to English
        { key = "show_custom2", type = "checkbox", x = 2, y = 54, w = 8, h = 2, label = L["Custom 2"] },
        { key = "custom2", type = "color", x = 11, y = 54, w = 12, h = 2, label = L["Color"] },
        { key = "custom2_name", type = "input", x = 24, y = 54, w = 10, h = 2, label = L["Label"], placeholder = L["C2"] },
        { key = "custom2_channel", type = "input", x = 35, y = 54, w = 17, h = 2, label = L["Command"], placeholder = "/DBM" },

-- Comment translated to English
        { key = "show_custom3", type = "checkbox", x = 2, y = 57, w = 8, h = 2, label = L["Custom 3"] },
        { key = "custom3", type = "color", x = 11, y = 57, w = 12, h = 2, label = L["Color"] },
        { key = "custom3_name", type = "input", x = 24, y = 57, w = 10, h = 2, label = L["Label"], placeholder = L["C3"] },
        { key = "custom3_channel", type = "input", x = 35, y = 57, w = 17, h = 2, label = L["Command"], placeholder = "/WA" },
    }

    RRTToolsCore:RegisterModuleLayout(RRT_MODULE_KEY, layout)
end
RRT_RegisterLayout()

-- =============================================================
-- Comment translated to English
-- =============================================================
if not RRTToolsCore:IsModuleEnabled(RRT_MODULE_KEY) then return end

-- =============================================================
-- Comment translated to English
-- =============================================================
local RRT_DEFAULTS = {
    enabled = false,
    locked = true,
    fontSize = 16,
    buttonPadding = 3,
    buttonSize = 30,
    fontOutline = "OUTLINE",
    anchorMode = "None",
    posX2 = 46,
    posY2 = 207,
    offsetX = 0,
    offsetY = 30,

-- Comment translated to English
    show_world = true,
    worldR = 1,
    worldG = 0.5,
    worldB = 0.5,
    worldA = 1,
    world_name = "",
    world_channel = "World",

    show_say = true,
    sayR = 1,
    sayG = 1,
    sayB = 1,
    sayA = 1,
    say_name = "",
    say_channel = "/s",

    show_yell = true,
    yellR = 1,
    yellG = 0.25,
    yellB = 0.25,
    yellA = 1,
    yell_name = "",
    yell_channel = "/y",

    show_party = true,
    partyR = 0.67,
    partyG = 0.67,
    partyB = 1,
    partyA = 1,
    party_name = "",
    party_channel = "/p",

    show_guild = true,
    guildR = 0.25,
    guildG = 1,
    guildB = 0.25,
    guildA = 1,
    guild_name = "",
    guild_channel = "/g",

    show_instance = true,
    instanceR = 1,
    instanceG = 0.5,
    instanceB = 0,
    instanceA = 1,
    instance_name = "",
    instance_channel = "/i",

    show_raid = true,
    raidR = 1,
    raidG = 0.5,
    raidB = 0,
    raidA = 1,
    raid_name = "",
    raid_channel = "/raid",

    show_roll = true,
    rollR = 1,
    rollG = 1,
    rollB = 0,
    rollA = 1,
    roll_name = "",
    roll_channel = "/roll",

    show_rc = true,
    rcR = 0,
    rcG = 1,
    rcB = 1,
    rcA = 1,
    rc_name = "",
    rc_channel = "/rc",

    show_pull = true,
    pullR = 1,
    pullG = 0,
    pullB = 1,
    pullA = 1,
    pull_name = "",
    pull_channel = "/cd 10",

    show_custom1 = false,
    custom1R = 1,
    custom1G = 1,
    custom1B = 1,
    custom1A = 1,
    custom1_name = "",
    custom1_channel = "/MDT",

    show_custom2 = false,
    custom2R = 1,
    custom2G = 1,
    custom2B = 1,
    custom2A = 1,
    custom2_name = "",
    custom2_channel = "/DBM",

    show_custom3 = false,
    custom3R = 1,
    custom3G = 1,
    custom3B = 1,
    custom3A = 1,
    custom3_name = "",
    custom3_channel = "/WA",
}

local RRT_DB = RRTToolsCore:GetModuleDB(RRT_MODULE_KEY, RRT_DEFAULTS)

-- =============================================================
-- Comment translated to English
-- =============================================================
local CHANNELS = {
    { id = "world", name = L["W"], command = "/1", isWorld = true, chatType = nil },
    { id = "say", name = L["S"], command = "/s", chatType = "SAY" },
    { id = "yell", name = L["Y"], command = "/y", chatType = "YELL" },
    { id = "party", name = L["P"], command = "/p", chatType = "PARTY" },
    { id = "guild", name = L["G"], command = "/g", chatType = "GUILD" },
    { id = "instance", name = L["I"], command = "/i", chatType = "INSTANCE_CHAT" },
    { id = "raid", name = L["R"], command = "/raid", chatType = "RAID" },
    { id = "roll", name = L["Roll"], command = "/roll", isCommand = true },
    { id = "rc", name = L["RC"], command = "/rc", isCommand = true },
    { id = "pull", name = L["Pull"], command = "/cd 10", isCommand = true },
    { id = "custom1", name = L["C1"], isCustom = true },
    { id = "custom2", name = L["C2"], isCustom = true },
    { id = "custom3", name = L["C3"], isCustom = true },
}

-- =============================================================
-- Comment translated to English
-- =============================================================
local barFrame = nil
local buttons = {}

-- Comment translated to English
local function ExecuteSlashCommand(rawCmd)
    local cmd = tostring(rawCmd or "")
    cmd = string.gsub(cmd, "^%s*(.-)%s*$", "%1")
    if cmd == "" then
        return false
    end

    if not string.find(cmd, "^/") then
        cmd = "/" .. cmd
    end

-- Comment translated to English
    local slash, args = string.match(cmd, "^(/[^%s]+)%s*(.*)")
    if slash and SlashCmdList then
        slash = string.upper(slash)
        for key, func in pairs(SlashCmdList) do
            local i = 1
            while true do
                local registered = _G["SLASH_" .. key .. i]
                if not registered then
                    break
                end
                if string.upper(registered) == slash then
                    local ok = pcall(func, args or "")
                    return ok
                end
                i = i + 1
            end
        end
    end

-- Comment translated to English
    if ChatEdit_ChooseBoxForSend and ChatEdit_SendText then
        local editBox = ChatEdit_ChooseBoxForSend()
        if editBox then
            editBox:SetText(cmd)
            ChatEdit_SendText(editBox, 0)
            return true
        end
    end

    return false
end

-- Comment translated to English
local function TryActivateNumericChannel(rawCmd)
    local cmd = tostring(rawCmd or "")
    cmd = string.gsub(cmd, "^%s*(.-)%s*$", "%1")
    if cmd == "" then
        return false
    end

    if not string.find(cmd, "^/") then
        cmd = "/" .. cmd
    end

    local slash, args = string.match(cmd, "^(/[^%s]+)%s*(.*)")
    if not slash then
        return false
    end

    if args and args ~= "" then
        return false
    end

    if not string.match(slash, "^/%d+$") then
        return false
    end

    if not ChatEdit_ChooseBoxForSend or not ChatEdit_ActivateChat then
        return false
    end

    local editBox = ChatEdit_ChooseBoxForSend()
    if not editBox then
        return false
    end

    ChatEdit_ActivateChat(editBox)
    editBox:SetText(slash .. " ")
    return true
end

local TrimCommand

local function TryActivateNamedChannel(channelName)
    local name = TrimCommand(channelName)
    if name == "" then
        return false
    end

    if not GetChannelName or not ChatEdit_ChooseBoxForSend or not ChatEdit_ActivateChat then
        return false
    end

    local id = GetChannelName(name)
    if not id or id <= 0 then
        return false
    end

    local editBox = ChatEdit_ChooseBoxForSend()
    if not editBox then
        return false
    end

    ChatEdit_ActivateChat(editBox)
    editBox:SetText("/" .. id .. " ")
    return true
end

TrimCommand = function(raw)
    local cmd = tostring(raw or "")
    return string.gsub(cmd, "^%s*(.-)%s*$", "%1")
end

local function NormalizeSlashCommand(raw)
    local cmd = TrimCommand(raw)
    if cmd == "" then
        return ""
    end
    if not string.find(cmd, "^/") then
        cmd = "/" .. cmd
    end
    return cmd
end

local function GetChannelConfiguredCommand(channel)
    if not channel or not channel.id then
        return "", false
    end

    local key = channel.id .. "_channel"
    local raw = TrimCommand(RRT_DB[key])

    if channel.isWorld then
        local worldName = raw ~= "" and raw or "World"
        if not string.find(worldName, "^/") then
            return worldName, true
        end
    end

    local cmd = NormalizeSlashCommand(raw)
    if cmd ~= "" then
        return cmd, false
    end

    return NormalizeSlashCommand(channel.command), false
end

-- Comment translated to English
local function CreateBarFrame()
    if barFrame then return end

    barFrame = CreateFrame("Frame", "ExChatChannelBar", UIParent)
    barFrame:SetMovable(true)
    barFrame:EnableMouse(true)
    barFrame:RegisterForDrag("LeftButton")

-- Comment translated to English
    barFrame.bg = barFrame:CreateTexture(nil, "BACKGROUND")
    barFrame.bg:SetAllPoints()
    barFrame.bg:SetColorTexture(0, 0.5, 0, 0.5)
    barFrame.bg:Hide()

-- Comment translated to English
    barFrame.label = barFrame:CreateFontString(nil, "OVERLAY")
    barFrame.label:SetFont("Fonts\\ARHei.ttf", 14, "OUTLINE")
    barFrame.label:SetPoint("CENTER")
    barFrame.label:SetText(L["Chat Bar - Drag this frame to move"])
    barFrame.label:SetTextColor(1, 1, 1)
    barFrame.label:Hide()

-- Comment translated to English
    RRTToolsCore:RegisterHUD(RRT_MODULE_KEY, barFrame)

-- Comment translated to English
    barFrame:SetScript("OnDragStart", function(self)
        if not RRT_DB.locked then
            self:StartMoving()
        end
    end)

    barFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
-- Comment translated to English
        if RRT_DB.anchorMode and RRT_DB.anchorMode ~= "None" then
            local target = nil
            if RRT_DB.anchorMode == "Blizzard (ChatFrame1)" and _G.ChatFrame1 then
                target = _G.ChatFrame1
            elseif RRT_DB.anchorMode == "Chattynator" and _G.ChattynatorHyperlinkHandler then
                for _, child in ipairs({ _G.ChattynatorHyperlinkHandler:GetChildren() }) do
                    if type(child.GetID) == "function" and child:GetID() == 1 then
                        target = child
                        break
                    end
                end
            elseif RRT_DB.anchorMode == "ElvUI" and _G.LeftChatPanel then
                target = _G.LeftChatPanel
            end

            if target then
                local sLeft, sBottom = self:GetLeft(), self:GetBottom()
                local tLeft, tTop = target:GetLeft(), target:GetTop()
                if sLeft and sBottom and tLeft and tTop then
                    local scale = self:GetEffectiveScale()
                    local tScale = target:GetEffectiveScale()
                    RRT_DB.offsetX = math.floor((sLeft * scale - tLeft * tScale) / scale)
                    RRT_DB.offsetY = math.floor((sBottom * scale - tTop * tScale) / scale)
                end
            end
        else
-- Comment translated to English
            local x, y = self:GetLeft(), self:GetBottom()
            if x and y then
                RRT_DB.posX2 = math.floor(x)
                RRT_DB.posY2 = math.floor(y)
            end
        end

        if RRTToolsCore.UI and RRTToolsCore.UI.RefreshContent then
            RRTToolsCore.UI:RefreshContent()
        end
    end)

-- Comment translated to English
end

-- Comment translated to English
local function CreateButtons()
-- Comment translated to English
    for _, btn in ipairs(buttons) do
        if btn then
            btn:Hide()
            btn:SetParent(nil)
        end
    end
    wipe(buttons)

    if not barFrame then return end

-- Comment translated to English
    local index = 0
    for _, channel in ipairs(CHANNELS) do
        local showKey = "show_" .. channel.id
        if RRT_DB[showKey] then
            index = index + 1
            local btn = CreateFrame("Frame", "ExChatChannelBtn_" .. channel.id, barFrame)
            btn:SetSize(RRT_DB.buttonSize, RRT_DB.buttonSize)
            btn:EnableMouse(true)

-- Comment translated to English
            local nameKey = channel.id .. "_name"
            local displayName = RRT_DB[nameKey] or ""
            if displayName == "" then
                if channel.isCustom then
                    displayName = ""
                else
                    displayName = channel.name
                end
            else
-- Comment translated to English
                displayName = string.sub(displayName, 1, 3) -- Comment translated to English
            end

-- Comment translated to English
            local text = btn:CreateFontString(nil, "OVERLAY")
            text:SetPoint("CENTER")
-- Comment translated to English
            text:SetFont("Fonts\\ARHei.ttf", 14, "OUTLINE")
            text:SetText(displayName)
            btn.text = text
            btn.channelData = channel

-- Comment translated to English
            btn:SetScript("OnEnter", function(self)
                if self.text then
                    self.text:SetScale(1.2)
                end
            end)

            btn:SetScript("OnLeave", function(self)
                if self.text then
                    self.text:SetScale(1.0)
                end
            end)

            btn:SetScript("OnMouseDown", function(self)
                if self.text then
                    self.text:SetAlpha(0.7)
                end
            end)

            btn:SetScript("OnMouseUp", function(self)
                if self.text then
                    self.text:SetAlpha(1.0)
                end

                local ch = self.channelData
                if not ch then return end

                local cmd, isNamedChannel = GetChannelConfiguredCommand(ch)
                if cmd == "" then
                    return
                end

                if isNamedChannel then
                    if not TryActivateNamedChannel(cmd) then
                        print("|cffff0000[" .. L["Chat Bar"] .. "]|r " .. L["Channel not found: "] .. tostring(cmd))
                    end
                    return
                end

-- Comment translated to English
                if TryActivateNumericChannel(cmd) then
                    return
                end

                if ch.isCommand then
-- Comment translated to English
                    if not ExecuteSlashCommand(cmd) then
                        print("|cffff0000[" .. L["Chat Bar"] .. "]|r " .. L["Command failed: "] .. tostring(cmd))
                    end
                elseif ch.isCustom then
-- Comment translated to English
                    if not ExecuteSlashCommand(cmd) then
                        print("|cffff0000[" .. L["Chat Bar"] .. "]|r " .. L["Command failed: "] .. cmd)
                    end
                else
-- Comment translated to English
                    if not ChatEdit_ChooseBoxForSend or not ChatEdit_ActivateChat then return end
                    local editBox = ChatEdit_ChooseBoxForSend()
                    if editBox then
                        ChatEdit_ActivateChat(editBox)
                        editBox:SetText(cmd .. " ")
                        if ch.chatType and string.upper(cmd) == string.upper(NormalizeSlashCommand(ch.command)) then
                            editBox:SetAttribute("chatType", ch.chatType)
                        end
                    end
                end
            end)

            buttons[index] = btn
        end
    end
end

-- Comment translated to English
local function UpdateLayout()
    if not barFrame then return end

    local padding = RRT_DB.buttonPadding
    local size = RRT_DB.buttonSize
    local count = #buttons

    if count == 0 then
-- Comment translated to English
        barFrame:SetSize(200, 40)
        return
    end

    local barWidth = (count * (size + padding)) + padding
    local barHeight = size + (padding * 2)

-- Comment translated to English
    if not RRT_DB.locked then
        barHeight = math.max(barHeight, 40) -- Comment translated to English
        barWidth = math.max(barWidth, 200) -- Comment translated to English
    end

    barFrame:SetSize(barWidth, barHeight)

    for i, btn in ipairs(buttons) do
        btn:SetSize(size, size)
        btn:ClearAllPoints()
        btn:SetPoint("LEFT", barFrame, "LEFT", padding + ((i - 1) * (size + padding)), 0)
    end
end

-- Comment translated to English
local function UpdateButtonStyles()
-- Comment translated to English
    local fontPath = "Fonts\\ARHei.ttf"

-- Comment translated to English
    local outline = RRT_DB.fontOutline
    if outline == "None" then
        outline = ""
    end

    for _, btn in ipairs(buttons) do
        local channel = btn.channelData
        if not channel then return end

-- Comment translated to English
        if btn.text then
            btn.text:SetFont(fontPath, RRT_DB.fontSize, outline)

-- Comment translated to English
            local rKey = channel.id .. "R"
            local gKey = channel.id .. "G"
            local bKey = channel.id .. "B"

            local r = RRT_DB[rKey] or 1
            local g = RRT_DB[gKey] or 1
            local b = RRT_DB[bKey] or 1

            btn.text:SetTextColor(r, g, b)

-- Comment translated to English
            local nameKey = channel.id .. "_name"
            local displayName = RRT_DB[nameKey] or ""
            if displayName == "" then
                if channel.isCustom then
                    displayName = ""
                else
                    displayName = channel.name
                end
            else
-- Comment translated to English
                displayName = string.sub(displayName, 1, 3)
            end
            btn.text:SetText(displayName)
        end
    end
end

-- Comment translated to English
local function RefreshAll()
    if not RRT_DB.enabled then
        if barFrame then
            barFrame:Hide()
        end
        return
    end

    if not barFrame then
        CreateBarFrame()
    end

    CreateButtons()
    UpdateLayout()
    UpdateButtonStyles()

    barFrame:Show()

-- Comment translated to English
    if RRT_DB.locked then
        barFrame:EnableMouse(false)
        barFrame.bg:Hide()
        barFrame.label:Hide()
    else
        barFrame:EnableMouse(true)
        barFrame.bg:Show()
        barFrame.label:Show()
    end

-- Comment translated to English
-- Comment translated to English
    barFrame:ClearAllPoints()
    local attached = false
    local anchorTarget = nil

    if RRT_DB.anchorMode == "Blizzard (ChatFrame1)" and _G.ChatFrame1 then
        anchorTarget = _G.ChatFrame1
    elseif RRT_DB.anchorMode == "Chattynator" and _G.ChattynatorHyperlinkHandler then
        for _, child in ipairs({ _G.ChattynatorHyperlinkHandler:GetChildren() }) do
            if type(child.GetID) == "function" and child:GetID() == 1 then
                anchorTarget = child
                break
            end
        end
    elseif RRT_DB.anchorMode == "ElvUI" and _G.LeftChatPanel then
        anchorTarget = _G.LeftChatPanel
    end

    if anchorTarget then
        barFrame:SetPoint("BOTTOMLEFT", anchorTarget, "TOPLEFT", RRT_DB.offsetX or 0, RRT_DB.offsetY or 30)
        attached = true
    end

    if not attached then
-- Comment translated to English
        if RRT_DB.posX2 and RRT_DB.posY2 then
            barFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", RRT_DB.posX2, RRT_DB.posY2)
        else
            barFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
    end
end

local Module = RRT_NS.ChatChannelBar or {}
RRT_NS.ChatChannelBar = Module

function Module:RefreshDisplay()
    RefreshAll()
end

function Module:SetLocked(locked)
    RRT_DB.locked = not not locked
    RefreshAll()
end

function Module:SetEnabled(enabled)
    RRT_DB.enabled = not not enabled
    RefreshAll()
end

-- =============================================================
-- Comment translated to English
-- =============================================================
RRTToolsCore:RegisterEvent("PLAYER_ENTERING_WORLD", RRT_MODULE_KEY, function()
    RRT_DB.locked = true
    C_Timer.After(0.5, function()
        RefreshAll()
    end)
end)

-- Comment translated to English
RRTToolsCore:WatchState(RRT_MODULE_KEY .. ".DatabaseChanged", RRT_MODULE_KEY, function(info)
    if not info or not info.key then return end

-- Comment translated to English
    if string.find(info.key, "^show_") then
        RefreshAll()
    else
-- Comment translated to English
        UpdateLayout()
        UpdateButtonStyles()

-- Comment translated to English
        if info.key == "locked" then
            if RRT_DB.locked then
                barFrame:EnableMouse(false)
                barFrame.bg:Hide()
                barFrame.label:Hide()
            else
                barFrame:EnableMouse(true)
                barFrame.bg:Show()
                barFrame.label:Show()
            end
        end

-- Comment translated to English
        if info.key == "enabled" or info.key == "anchorMode" then
            RefreshAll()
        end
    end
end)

-- Comment translated to English
RRTToolsCore:WatchState(RRT_MODULE_KEY .. ".ButtonClicked", RRT_MODULE_KEY, function(info)
    if not info or not info.key then return end

    if info.key == "btn_reset_pos" then
        RRT_DB.posX2 = nil
        RRT_DB.posY2 = nil
        RRT_DB.offsetX = 0
        RRT_DB.offsetY = 30
        if barFrame then
            barFrame:ClearAllPoints()
            barFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        RefreshAll()
    end
end)

-- Comment translated to English
RRTToolsCore:RegisterEditModeCallback(RRT_MODULE_KEY, function(enabled)
-- Comment translated to English
    if enabled then
-- Comment translated to English
        RRT_DB.locked = false
    else
-- Comment translated to English
        RRT_DB.locked = true
    end

-- Comment translated to English
    C_Timer.After(0.05, function()
        RefreshAll()
    end)
end)

-- =============================================================
-- Comment translated to English
-- =============================================================
_G.SLASH_EXCHATCHANNEL1 = "/cc"
_G.SlashCmdList["EXCHATCHANNEL"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "show" then
        RRT_DB.enabled = true
        RefreshAll()
    elseif msg == "hide" then
        RRT_DB.enabled = false
        RefreshAll()
    elseif msg == "toggle" then
        RRT_DB.enabled = not RRT_DB.enabled
        RefreshAll()
    elseif msg == "reset" then
        RRT_DB.posX = 0
        RRT_DB.posY = 0
        RefreshAll()
    else
-- Comment translated to English
        RRTToolsCore:OpenSettingsPanel(RRT_MODULE_KEY)
    end
end

-- =============================================================
-- Comment translated to English
-- =============================================================
RRTToolsCore:ReportReady(RRT_MODULE_KEY)



