-- =============================================================
-- [[ Chat Channel Bar ]]
-- { Key = "RevTools.ChatChannelBar", Name = "Chat Channel Bar", Desc = "A toolbar for quickly switching chat channels.", Category = 1 },
-- =============================================================

local InfinityMythicPlus = _G.InfinityMythicPlus or _G.InfinityTools
local InfinityTools = InfinityMythicPlus
if not InfinityTools then return end
local L = (InfinityTools and InfinityTools.L) or setmetatable({}, { __index = function(_, key) return key end })

local INFINITY_MODULE_KEY = "RevTools.ChatChannelBar"

local CreateFrame = _G.CreateFrame
local UIParent = _G.UIParent
local C_Timer = _G.C_Timer
local ChatEdit_ChooseBoxForSend = _G.ChatEdit_ChooseBoxForSend
local ChatEdit_SendText = _G.ChatEdit_SendText
local ChatEdit_ActivateChat = _G.ChatEdit_ActivateChat
local GetChannelName = _G.GetChannelName
local SlashCmdList = _G.SlashCmdList
local wipe = _G.wipe

local function REGISTER_LAYOUT()
    local layout = {
        { key = "header", type = "header", x = 2, y = 1, w = 50, h = 2, label = "Chat Channel Bar", labelSize = 25 },
        { key = "desc", type = "description", x = 2, y = 4, w = 50, h = 2, label = "A toolbar for quickly switching chat channels and utility commands." },

        { key = "div1", type = "divider", x = 2, y = 7, w = 50, h = 1 },
        { key = "subheader_basic", type = "subheader", x = 2, y = 6, w = 50, h = 1, label = "General", labelSize = 20 },
        { key = "locked", type = "checkbox", x = 2, y = 8, w = 8, h = 2, label = "Locked" },
        { key = "btn_reset_pos", type = "button", x = 12, y = 8, w = 12, h = 2, label = "Reset Position" },

        { key = "fontSize", type = "slider", x = 2, y = 11, w = 16, h = 2, label = "Font Size", min = 10, max = 30, step = 1 },
        { key = "buttonPadding", type = "slider", x = 20, y = 11, w = 16, h = 2, label = "Button Spacing", min = 0, max = 20, step = 1 },
        { key = "buttonSize", type = "slider", x = 38, y = 11, w = 16, h = 2, label = "Button Size", min = 20, max = 50, step = 1 },
        { key = "fontOutline", type = "dropdown", x = 2, y = 14, w = 16, h = 2, label = "Outline", items = "None,OUTLINE,THICKOUTLINE" },
        { key = "anchorMode", type = "dropdown", x = 20, y = 14, w = 18, h = 2, label = "Attach To", items = "Detached,Blizzard (ChatFrame1),Chattynator,ElvUI" },

        { key = "div2", type = "divider", x = 2, y = 17, w = 50, h = 1 },
        { key = "channels_header", type = "header", x = 2, y = 18, w = 50, h = 2, label = "Channels", labelSize = 20 },

        { key = "show_world", type = "checkbox", x = 2, y = 21, w = 8, h = 2, label = "World" },
        { key = "world", type = "color", x = 11, y = 21, w = 12, h = 2, label = "Color" },
        { key = "world_name", type = "input", x = 24, y = 21, w = 10, h = 2, label = "Label", placeholder = "W" },
        { key = "world_channel", type = "input", x = 35, y = 21, w = 17, h = 2, label = "Command", placeholder = "World Channel" },

        { key = "show_say", type = "checkbox", x = 2, y = 24, w = 8, h = 2, label = "Say" },
        { key = "say", type = "color", x = 11, y = 24, w = 12, h = 2, label = "Color" },
        { key = "say_name", type = "input", x = 24, y = 24, w = 10, h = 2, label = "Label", placeholder = "S" },
        { key = "say_channel", type = "input", x = 35, y = 24, w = 17, h = 2, label = "Command", placeholder = "/s" },

        { key = "show_yell", type = "checkbox", x = 2, y = 27, w = 8, h = 2, label = "Yell" },
        { key = "yell", type = "color", x = 11, y = 27, w = 12, h = 2, label = "Color" },
        { key = "yell_name", type = "input", x = 24, y = 27, w = 10, h = 2, label = "Label", placeholder = "Y" },
        { key = "yell_channel", type = "input", x = 35, y = 27, w = 17, h = 2, label = "Command", placeholder = "/y" },

        { key = "show_party", type = "checkbox", x = 2, y = 30, w = 8, h = 2, label = "Party" },
        { key = "party", type = "color", x = 11, y = 30, w = 12, h = 2, label = "Color" },
        { key = "party_name", type = "input", x = 24, y = 30, w = 10, h = 2, label = "Label", placeholder = "P" },
        { key = "party_channel", type = "input", x = 35, y = 30, w = 17, h = 2, label = "Command", placeholder = "/p" },

        { key = "show_guild", type = "checkbox", x = 2, y = 33, w = 8, h = 2, label = "Guild" },
        { key = "guild", type = "color", x = 11, y = 33, w = 12, h = 2, label = "Color" },
        { key = "guild_name", type = "input", x = 24, y = 33, w = 10, h = 2, label = "Label", placeholder = "G" },
        { key = "guild_channel", type = "input", x = 35, y = 33, w = 17, h = 2, label = "Command", placeholder = "/g" },

        { key = "show_instance", type = "checkbox", x = 2, y = 36, w = 8, h = 2, label = "Instance" },
        { key = "instance", type = "color", x = 11, y = 36, w = 12, h = 2, label = "Color" },
        { key = "instance_name", type = "input", x = 24, y = 36, w = 10, h = 2, label = "Label", placeholder = "I" },
        { key = "instance_channel", type = "input", x = 35, y = 36, w = 17, h = 2, label = "Command", placeholder = "/i" },

        { key = "show_raid", type = "checkbox", x = 2, y = 39, w = 8, h = 2, label = "Raid" },
        { key = "raid", type = "color", x = 11, y = 39, w = 12, h = 2, label = "Color" },
        { key = "raid_name", type = "input", x = 24, y = 39, w = 10, h = 2, label = "Label", placeholder = "R" },
        { key = "raid_channel", type = "input", x = 35, y = 39, w = 17, h = 2, label = "Command", placeholder = "/raid" },

        { key = "show_roll", type = "checkbox", x = 2, y = 42, w = 8, h = 2, label = "Roll" },
        { key = "roll", type = "color", x = 11, y = 42, w = 12, h = 2, label = "Color" },
        { key = "roll_name", type = "input", x = 24, y = 42, w = 10, h = 2, label = "Label", placeholder = "Roll" },
        { key = "roll_channel", type = "input", x = 35, y = 42, w = 17, h = 2, label = "Command", placeholder = "/roll" },

        { key = "show_rc", type = "checkbox", x = 2, y = 45, w = 8, h = 2, label = "Ready Check" },
        { key = "rc", type = "color", x = 11, y = 45, w = 12, h = 2, label = "Color" },
        { key = "rc_name", type = "input", x = 24, y = 45, w = 10, h = 2, label = "Label", placeholder = "RC" },
        { key = "rc_channel", type = "input", x = 35, y = 45, w = 17, h = 2, label = "Command", placeholder = "/rc" },

        { key = "show_pull", type = "checkbox", x = 2, y = 48, w = 8, h = 2, label = "Pull" },
        { key = "pull", type = "color", x = 11, y = 48, w = 12, h = 2, label = "Color" },
        { key = "pull_name", type = "input", x = 24, y = 48, w = 10, h = 2, label = "Label", placeholder = "Pull" },
        { key = "pull_channel", type = "input", x = 35, y = 48, w = 17, h = 2, label = "Command", placeholder = "/cd 10" },

        { key = "show_custom1", type = "checkbox", x = 2, y = 51, w = 8, h = 2, label = "Custom 1" },
        { key = "custom1", type = "color", x = 11, y = 51, w = 12, h = 2, label = "Color" },
        { key = "custom1_name", type = "input", x = 24, y = 51, w = 10, h = 2, label = "Label", placeholder = "C1" },
        { key = "custom1_channel", type = "input", x = 35, y = 51, w = 17, h = 2, label = "Command", placeholder = "/MDT" },

        { key = "show_custom2", type = "checkbox", x = 2, y = 54, w = 8, h = 2, label = "Custom 2" },
        { key = "custom2", type = "color", x = 11, y = 54, w = 12, h = 2, label = "Color" },
        { key = "custom2_name", type = "input", x = 24, y = 54, w = 10, h = 2, label = "Label", placeholder = "C2" },
        { key = "custom2_channel", type = "input", x = 35, y = 54, w = 17, h = 2, label = "Command", placeholder = "/DBM" },

        { key = "show_custom3", type = "checkbox", x = 2, y = 57, w = 8, h = 2, label = "Custom 3" },
        { key = "custom3", type = "color", x = 11, y = 57, w = 12, h = 2, label = "Color" },
        { key = "custom3_name", type = "input", x = 24, y = 57, w = 10, h = 2, label = "Label", placeholder = "C3" },
        { key = "custom3_channel", type = "input", x = 35, y = 57, w = 17, h = 2, label = "Command", placeholder = "/WA" },
    }

    InfinityTools:RegisterModuleLayout(INFINITY_MODULE_KEY, layout)
end
REGISTER_LAYOUT()

if not InfinityTools:IsModuleEnabled(INFINITY_MODULE_KEY) then return end

local MODULE_DEFAULTS = {
    enabled = false,
    locked = true,
    fontSize = 16,
    buttonPadding = 3,
    buttonSize = 30,
    fontOutline = "OUTLINE",
    anchorMode = "Detached",
    posX2 = 46,
    posY2 = 207,
    offsetX = 0,
    offsetY = 30,

    show_world = true,
    worldR = 1, worldG = 0.5, worldB = 0.5, worldA = 1,
    world_name = "",
    world_channel = "World Channel",

    show_say = true,
    sayR = 1, sayG = 1, sayB = 1, sayA = 1,
    say_name = "",
    say_channel = "/s",

    show_yell = true,
    yellR = 1, yellG = 0.25, yellB = 0.25, yellA = 1,
    yell_name = "",
    yell_channel = "/y",

    show_party = true,
    partyR = 0.67, partyG = 0.67, partyB = 1, partyA = 1,
    party_name = "",
    party_channel = "/p",

    show_guild = true,
    guildR = 0.25, guildG = 1, guildB = 0.25, guildA = 1,
    guild_name = "",
    guild_channel = "/g",

    show_instance = true,
    instanceR = 1, instanceG = 0.5, instanceB = 0, instanceA = 1,
    instance_name = "",
    instance_channel = "/i",

    show_raid = true,
    raidR = 1, raidG = 0.5, raidB = 0, raidA = 1,
    raid_name = "",
    raid_channel = "/raid",

    show_roll = true,
    rollR = 1, rollG = 1, rollB = 0, rollA = 1,
    roll_name = "",
    roll_channel = "/roll",

    show_rc = true,
    rcR = 0, rcG = 1, rcB = 1, rcA = 1,
    rc_name = "",
    rc_channel = "/rc",

    show_pull = true,
    pullR = 1, pullG = 0, pullB = 1, pullA = 1,
    pull_name = "",
    pull_channel = "/cd 10",

    show_custom1 = false,
    custom1R = 1, custom1G = 1, custom1B = 1, custom1A = 1,
    custom1_name = "",
    custom1_channel = "/MDT",

    show_custom2 = false,
    custom2R = 1, custom2G = 1, custom2B = 1, custom2A = 1,
    custom2_name = "",
    custom2_channel = "/DBM",

    show_custom3 = false,
    custom3R = 1, custom3G = 1, custom3B = 1, custom3A = 1,
    custom3_name = "",
    custom3_channel = "/WA",
}

local MODULE_DB = InfinityTools:GetModuleDB(INFINITY_MODULE_KEY, MODULE_DEFAULTS)

local CHANNELS = {
    { id = "world", name = "W", command = "/1", isWorld = true },
    { id = "say", name = "S", command = "/s", chatType = "SAY" },
    { id = "yell", name = "Y", command = "/y", chatType = "YELL" },
    { id = "party", name = "P", command = "/p", chatType = "PARTY" },
    { id = "guild", name = "G", command = "/g", chatType = "GUILD" },
    { id = "instance", name = "I", command = "/i", chatType = "INSTANCE_CHAT" },
    { id = "raid", name = "R", command = "/raid", chatType = "RAID" },
    { id = "roll", name = "Roll", command = "/roll", isCommand = true },
    { id = "rc", name = "RC", command = "/rc", isCommand = true },
    { id = "pull", name = "Pull", command = "/cd 10", isCommand = true },
    { id = "custom1", name = "C1", isCustom = true },
    { id = "custom2", name = "C2", isCustom = true },
    { id = "custom3", name = "C3", isCustom = true },
}

local barFrame
local buttons = {}

local function TrimCommand(raw)
    local cmd = tostring(raw or "")
    return string.gsub(cmd, "^%s*(.-)%s*$", "%1")
end

local function NormalizeChatChannelBarConfig(db)
    if not db then return end
    local outlineMap = { [string.char(230,151,160)] = "None" }
    local anchorModeMap = {
        [string.char(228,184,141,229,144,184,233,153,132)] = "Detached",
        [string.char(230,154,180,233,155,170) .. "(ChatFrame1)"] = "Blizzard (ChatFrame1)",
    }
    local worldChannelMap = { [string.char(229,164,167,232,132,154,228,184,150,231,149,140,233,162,145,233,129,147)] = "World Channel" }

    db.fontOutline = outlineMap[db.fontOutline] or db.fontOutline
    db.anchorMode = anchorModeMap[db.anchorMode] or db.anchorMode
    db.world_channel = worldChannelMap[db.world_channel] or db.world_channel
end

local function NormalizeSlashCommand(raw)
    local cmd = TrimCommand(raw)
    if cmd == "" then return "" end
    if not string.find(cmd, "^/") then
        cmd = "/" .. cmd
    end
    return cmd
end

local function ExecuteSlashCommand(rawCmd)
    local cmd = NormalizeSlashCommand(rawCmd)
    if cmd == "" then return false end

    local slash, args = string.match(cmd, "^(/[^%s]+)%s*(.*)")
    if slash and SlashCmdList then
        slash = string.upper(slash)
        for key, func in pairs(SlashCmdList) do
            local i = 1
            while true do
                local registered = _G["SLASH_" .. key .. i]
                if not registered then break end
                if string.upper(registered) == slash then
                    local ok = pcall(func, args or "")
                    return ok
                end
                i = i + 1
            end
        end
    end

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

local function TryActivateNumericChannel(rawCmd)
    local cmd = NormalizeSlashCommand(rawCmd)
    if cmd == "" then return false end

    local slash, args = string.match(cmd, "^(/[^%s]+)%s*(.*)")
    if not slash or (args and args ~= "") then return false end
    if not string.match(slash, "^/%d+$") then return false end
    if not ChatEdit_ChooseBoxForSend or not ChatEdit_ActivateChat then return false end

    local editBox = ChatEdit_ChooseBoxForSend()
    if not editBox then return false end

    ChatEdit_ActivateChat(editBox)
    editBox:SetText(slash .. " ")
    return true
end

local function TryActivateNamedChannel(channelName)
    local name = TrimCommand(channelName)
    if name == "" then return false end
    if not GetChannelName or not ChatEdit_ChooseBoxForSend or not ChatEdit_ActivateChat then return false end

    local id = GetChannelName(name)
    if not id or id <= 0 then return false end

    local editBox = ChatEdit_ChooseBoxForSend()
    if not editBox then return false end

    ChatEdit_ActivateChat(editBox)
    editBox:SetText("/" .. id .. " ")
    return true
end

local function GetChannelConfiguredCommand(channel)
    if not channel or not channel.id then return "", false end

    local raw = TrimCommand(MODULE_DB[channel.id .. "_channel"])
    if channel.isWorld then
        local worldName = raw ~= "" and raw or "World Channel"
        if not string.find(worldName, "^/") then
            return worldName, true
        end
    end

    local cmd = NormalizeSlashCommand(raw)
    if cmd ~= "" then return cmd, false end
    return NormalizeSlashCommand(channel.command), false
end

local function GetAnchorTarget()
    if MODULE_DB.anchorMode == "Blizzard (ChatFrame1)" and _G.ChatFrame1 then
        return _G.ChatFrame1
    elseif MODULE_DB.anchorMode == "Chattynator" and _G.ChattynatorHyperlinkHandler then
        for _, child in ipairs({ _G.ChattynatorHyperlinkHandler:GetChildren() }) do
            if type(child.GetID) == "function" and child:GetID() == 1 then
                return child
            end
        end
    elseif MODULE_DB.anchorMode == "ElvUI" and _G.LeftChatPanel then
        return _G.LeftChatPanel
    end
end

local function CreateBarFrame()
    if barFrame then return end

    barFrame = CreateFrame("Frame", "RevChatChannelBar", UIParent)
    barFrame:SetMovable(true)
    barFrame:EnableMouse(true)
    barFrame:RegisterForDrag("LeftButton")

    barFrame.bg = barFrame:CreateTexture(nil, "BACKGROUND")
    barFrame.bg:SetAllPoints()
    barFrame.bg:SetColorTexture(0, 0.5, 0, 0.5)
    barFrame.bg:Hide()

    barFrame.label = barFrame:CreateFontString(nil, "OVERLAY")
    barFrame.label:SetFont("Fonts\\ARHei.ttf", 14, "OUTLINE")
    barFrame.label:SetPoint("CENTER")
    barFrame.label:SetText("Chat Shortcut Bar - Drag this frame to move")
    barFrame.label:SetTextColor(1, 1, 1)
    barFrame.label:Hide()

    InfinityTools:RegisterHUD(INFINITY_MODULE_KEY, barFrame)

    barFrame:SetScript("OnDragStart", function(self)
        if not MODULE_DB.locked then
            self:StartMoving()
        end
    end)

    barFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if MODULE_DB.anchorMode and MODULE_DB.anchorMode ~= "Detached" then
            local target = GetAnchorTarget()
            if target then
                local sLeft, sBottom = self:GetLeft(), self:GetBottom()
                local tLeft, tTop = target:GetLeft(), target:GetTop()
                if sLeft and sBottom and tLeft and tTop then
                    local scale = self:GetEffectiveScale()
                    local tScale = target:GetEffectiveScale()
                    MODULE_DB.offsetX = math.floor((sLeft * scale - tLeft * tScale) / scale)
                    MODULE_DB.offsetY = math.floor((sBottom * scale - tTop * tScale) / scale)
                end
            end
        else
            local x, y = self:GetLeft(), self:GetBottom()
            if x and y then
                MODULE_DB.posX2 = math.floor(x)
                MODULE_DB.posY2 = math.floor(y)
            end
        end

        if InfinityTools.UI and InfinityTools.UI.RefreshContent then
            InfinityTools.UI:RefreshContent()
        end
    end)
end

local function CreateButtons()
    for _, btn in ipairs(buttons) do
        if btn then
            btn:Hide()
            btn:SetParent(nil)
        end
    end
    wipe(buttons)
    if not barFrame then return end

    local index = 0
    for _, channel in ipairs(CHANNELS) do
        if MODULE_DB["show_" .. channel.id] then
            index = index + 1
            local btn = CreateFrame("Frame", "RevChatChannelBtn_" .. channel.id, barFrame)
            btn:SetSize(MODULE_DB.buttonSize, MODULE_DB.buttonSize)
            btn:EnableMouse(true)

            local displayName = MODULE_DB[channel.id .. "_name"] or ""
            if displayName == "" then
                displayName = channel.isCustom and "" or channel.name
            else
                displayName = string.sub(displayName, 1, 3)
            end

            local text = btn:CreateFontString(nil, "OVERLAY")
            text:SetPoint("CENTER")
            text:SetFont("Fonts\\ARHei.ttf", 14, "OUTLINE")
            text:SetText(displayName)
            btn.text = text
            btn.channelData = channel

            btn:SetScript("OnEnter", function(self)
                if self.text then self.text:SetScale(1.2) end
            end)
            btn:SetScript("OnLeave", function(self)
                if self.text then self.text:SetScale(1.0) end
            end)
            btn:SetScript("OnMouseDown", function(self)
                if self.text then self.text:SetAlpha(0.7) end
            end)
            btn:SetScript("OnMouseUp", function(self)
                if self.text then self.text:SetAlpha(1.0) end
                local ch = self.channelData
                if not ch then return end

                local cmd, isNamedChannel = GetChannelConfiguredCommand(ch)
                if cmd == "" then return end

                if isNamedChannel then
                    if not TryActivateNamedChannel(cmd) then
                        print("|cffff0000[Chat Channel Bar]|r Channel not found: " .. tostring(cmd))
                    end
                    return
                end

                if TryActivateNumericChannel(cmd) then return end

                if ch.isCommand or ch.isCustom then
                    if not ExecuteSlashCommand(cmd) then
                        print("|cffff0000[Chat Channel Bar]|r Command failed: " .. tostring(cmd))
                    end
                else
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

local function UpdateLayout()
    if not barFrame then return end
    local padding = MODULE_DB.buttonPadding
    local size = MODULE_DB.buttonSize
    local count = #buttons

    if count == 0 then
        barFrame:SetSize(200, 40)
        return
    end

    local barWidth = (count * (size + padding)) + padding
    local barHeight = size + (padding * 2)
    if not MODULE_DB.locked then
        barHeight = math.max(barHeight, 40)
        barWidth = math.max(barWidth, 200)
    end

    barFrame:SetSize(barWidth, barHeight)
    for i, btn in ipairs(buttons) do
        btn:SetSize(size, size)
        btn:ClearAllPoints()
        btn:SetPoint("LEFT", barFrame, "LEFT", padding + ((i - 1) * (size + padding)), 0)
    end
end

local function UpdateButtonStyles()
    local outline = MODULE_DB.fontOutline
    if outline == "None" then
        outline = ""
    end

    for _, btn in ipairs(buttons) do
        local channel = btn.channelData
        if channel and btn.text then
            btn.text:SetFont("Fonts\\ARHei.ttf", MODULE_DB.fontSize, outline)
            btn.text:SetTextColor(MODULE_DB[channel.id .. "R"] or 1, MODULE_DB[channel.id .. "G"] or 1, MODULE_DB[channel.id .. "B"] or 1)

            local displayName = MODULE_DB[channel.id .. "_name"] or ""
            if displayName == "" then
                displayName = channel.isCustom and "" or channel.name
            else
                displayName = string.sub(displayName, 1, 3)
            end
            btn.text:SetText(displayName)
        end
    end
end

local function RefreshAll()
    if not MODULE_DB.enabled then
        if barFrame then barFrame:Hide() end
        return
    end

    if not barFrame then
        CreateBarFrame()
    end

    CreateButtons()
    UpdateLayout()
    UpdateButtonStyles()
    barFrame:Show()

    if MODULE_DB.locked then
        barFrame:EnableMouse(false)
        barFrame.bg:Hide()
        barFrame.label:Hide()
    else
        barFrame:EnableMouse(true)
        barFrame.bg:Show()
        barFrame.label:Show()
    end

    barFrame:ClearAllPoints()
    local anchorTarget = GetAnchorTarget()
    if anchorTarget then
        barFrame:SetPoint("BOTTOMLEFT", anchorTarget, "TOPLEFT", MODULE_DB.offsetX or 0, MODULE_DB.offsetY or 30)
    elseif MODULE_DB.posX2 and MODULE_DB.posY2 then
        barFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", MODULE_DB.posX2, MODULE_DB.posY2)
    else
        barFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", INFINITY_MODULE_KEY, function()
    NormalizeChatChannelBarConfig(MODULE_DB)
    MODULE_DB.locked = true
    C_Timer.After(0.5, function()
        RefreshAll()
    end)
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".DatabaseChanged", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end

    if string.find(info.key, "^show_") or info.key == "enabled" or info.key == "anchorMode" then
        RefreshAll()
        return
    end

    UpdateLayout()
    UpdateButtonStyles()

    if info.key == "locked" and barFrame then
        if MODULE_DB.locked then
            barFrame:EnableMouse(false)
            barFrame.bg:Hide()
            barFrame.label:Hide()
        else
            barFrame:EnableMouse(true)
            barFrame.bg:Show()
            barFrame.label:Show()
        end
    end
end)

InfinityTools:WatchState(INFINITY_MODULE_KEY .. ".ButtonClicked", INFINITY_MODULE_KEY, function(info)
    if not info or not info.key then return end
    if info.key == "btn_reset_pos" then
        MODULE_DB.posX2 = nil
        MODULE_DB.posY2 = nil
        MODULE_DB.offsetX = 0
        MODULE_DB.offsetY = 30
        if barFrame then
            barFrame:ClearAllPoints()
            barFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        end
        RefreshAll()
    end
end)

InfinityTools:RegisterEditModeCallback(INFINITY_MODULE_KEY, function(enabled)
    MODULE_DB.locked = not enabled
    C_Timer.After(0.05, function()
        RefreshAll()
    end)
end)

_G.SLASH_EXCHATCHANNEL1 = "/cc"
_G.SlashCmdList["EXCHATCHANNEL"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "show" then
        MODULE_DB.enabled = true
        RefreshAll()
    elseif msg == "hide" then
        MODULE_DB.enabled = false
        RefreshAll()
    elseif msg == "toggle" then
        MODULE_DB.enabled = not MODULE_DB.enabled
        RefreshAll()
    elseif msg == "reset" then
        MODULE_DB.posX2 = nil
        MODULE_DB.posY2 = nil
        MODULE_DB.offsetX = 0
        MODULE_DB.offsetY = 30
        RefreshAll()
    else
        InfinityTools:OpenSettingsPanel(INFINITY_MODULE_KEY)
    end
end

InfinityTools:ReportReady(INFINITY_MODULE_KEY)

