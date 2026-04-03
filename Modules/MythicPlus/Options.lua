local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local InfinityDB = _G.InfinityDB

-- ─────────────────────────────────────────────────────────────────────────────
-- MythicPlus options — each function returns a DF:BuildMenu options table.
-- Exported via RRT_NS.UI.Options.MP_* so RRTUI.lua can include them
-- in the Mythic+ sidebar exactly like every other tab.
-- ─────────────────────────────────────────────────────────────────────────────

local OUTLINES       = { "NONE", "OUTLINE", "THICKOUTLINE" }
local OUTLINE_LABELS = { "None", "Outline", "Thick" }
local CHANNELS       = { "PARTY", "RAID", "SAY", "YELL" }

-- ─────────────────────────────────────────────────────────────────────────────
-- Popup "Copy Macro" — EditBox préselectionné, Ctrl+A / Ctrl+C pour copier
-- ─────────────────────────────────────────────────────────────────────────────
local FOCUS_INTERRUPT_MACRO =
    "#showtooltip Kick\n" ..
    "/focus [@focus,noexists,@mouseover,harm,nodead][@focus,noexists]\n" ..
    "/cast [@focus,exists] Kick"

local _copyFrame = nil

local function ShowCopyMacroPopup()
    if not _copyFrame then
        local f = CreateFrame("Frame", "RRTMacroCopyPopup", UIParent, "BackdropTemplate")
        f:SetSize(420, 115)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
        f:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        f:SetScript("OnMouseDown", function(self) self:StartMoving() end)
        f:SetScript("OnMouseUp",   function(self) self:StopMovingOrSizing() end)

        local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 10, -10)
        title:SetTextColor(1, 0.82, 0, 1)
        title:SetText("Copy Macro — Select all (Ctrl+A) then copy (Ctrl+C)")

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -2, -2)
        close:SetScript("OnClick", function() f:Hide() end)

        local eb = CreateFrame("EditBox", "RRTMacroCopyEditBox", f, "InputBoxTemplate")
        eb:SetMultiLine(true)
        eb:SetSize(398, 65)
        eb:SetPoint("TOPLEFT", 10, -32)
        eb:SetAutoFocus(false)
        eb:SetFont(STANDARD_TEXT_FONT, 11, "")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        -- Empêcher l'édition
        eb:SetScript("OnChar", function(self) self:SetText(FOCUS_INTERRUPT_MACRO) end)

        f.editBox = eb
        f:Hide()
        _copyFrame = f
    end

    _copyFrame.editBox:SetText(FOCUS_INTERRUPT_MACRO)
    _copyFrame:Show()
    _copyFrame.editBox:SetFocus()
    _copyFrame.editBox:HighlightText()
end

local function SoundValues(setFn)
    local t = {}
    local sounds = RRT_NS.LSM and RRT_NS.LSM:List("sound") or {}
    for _, name in ipairs(sounds) do
        local n = name
        tinsert(t, { label = n, value = n, onclick = function() setFn(n) end })
    end
    return t
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Potion Alert
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildPotionAlertOptions()
    local function d() return RRT and RRT.MP_PotionAlert or {} end
    local function refresh() local m = RRT_NS.MP_PotionAlert; if m then m:UpdateDisplay() end end
    local opts = {}

    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        desc="Show an alert when your combat potion is ready.",
        get=function() return d().enabled end,
        set=function(_,_,v) d().enabled=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="In Mythic Dungeons",
        desc="Show while inside a Mythic dungeon.",
        get=function() return d().enabledInDungeons end,
        set=function(_,_,v) d().enabledInDungeons=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="In Raids",
        desc="Show while in a raid (in combat).",
        get=function() return d().enabledInRaids end,
        set=function(_,_,v) d().enabledInRaids=v; refresh() end }
    opts[#opts+1] = { type="input", name="Display Text",
        desc="Text shown when the potion is ready.",
        get=function() return d().displayText or "Potion ready" end,
        set=function(_,_,v) d().displayText=v; refresh() end }
    opts[#opts+1] = { type="color", name="Text Color",
        get=function() local c=d().color or {}; return c.r or 1,c.g or 1,c.b or 1,c.a or 1 end,
        set=function(_,r,g,b,a) local db=d(); if not db.color then db.color={} end
            db.color.r=r; db.color.g=g; db.color.b=b; db.color.a=a; refresh() end }
    opts[#opts+1] = { type="range", name="Font Size", min=10, max=72, step=1,
        get=function() return d().fontSize or 18 end,
        set=function(_,_,v) d().fontSize=v; refresh() end }
    for i,outline in ipairs(OUTLINES) do
        local o,l = outline, OUTLINE_LABELS[i]
        opts[#opts+1] = { type="button", name=l, desc="Set outline: "..l,
            func=function() d().fontOutline=o; refresh() end }
    end

    opts[#opts+1] = { type="label", get=function() return "Sound / TTS" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Play Sound",
        get=function() return d().playSound end,
        set=function(_,_,v) d().playSound=v; refresh() end }
    opts[#opts+1] = { type="select", name="Sound",
        get=function() return d().sound or "" end,
        values=function() return SoundValues(function(v) d().sound=v; refresh() end) end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Play TTS",
        get=function() return d().playTTS end,
        set=function(_,_,v) d().playTTS=v; refresh() end }
    opts[#opts+1] = { type="input", name="TTS Text",
        get=function() return d().tts or "" end,
        set=function(_,_,v) d().tts=v; refresh() end }
    opts[#opts+1] = { type="range", name="TTS Volume", min=0, max=100, step=1,
        get=function() return d().ttsVolume or 50 end,
        set=function(_,_,v) d().ttsVolume=v; refresh() end }
    opts[#opts+1] = { type="button", name="Reset Position",
        func=function() local m=RRT_NS.MP_PotionAlert; if m then m:ResetPosition() end end }

    return opts
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Focus Interrupt Indicator
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildFocusInterruptOptionsLeft()
    local function d() return RRT and RRT.MP_FocusInterrupt or {} end
    local function refresh() local m=RRT_NS.MP_FocusInterrupt; if m then m:UpdateDisplay() end end
    local opts = {}

    opts[#opts+1] = { type="label", get=function() return "Recommended macro :" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="label", get=function() return "#showtooltip Kick" end }
    opts[#opts+1] = { type="label", get=function() return "/focus [@focus,noexists,@mouseover,harm,nodead][@focus,noexists]" end }
    opts[#opts+1] = { type="label", get=function() return "/cast [@focus,exists] Kick" end }
    opts[#opts+1] = { type="button", name="Copy Macro",
        desc="Open a box with the macro text — select all (Ctrl+A) then copy (Ctrl+C).",
        func=function() ShowCopyMacroPopup() end }
    opts[#opts+1] = { type="label", get=function() return
        "|cFFFFFF00Use this macro for simplicity: 1st click sets your focus target, next click launches your kick.|r"
    end, spacement=true }

    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        desc="Show INTERRUPT when your focus is casting and your interrupt is ready.",
        get=function() return d().enabled end,
        set=function(_,_,v) d().enabled=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Lock Position",
        get=function() return d().locked end,
        set=function(_,_,v) d().locked=v; refresh() end }
    opts[#opts+1] = { type="input", name="Display Text",
        get=function() return d().displayText or "INTERRUPT" end,
        set=function(_,_,v) d().displayText=v; refresh() end }
    opts[#opts+1] = { type="color", name="Text Color",
        get=function() local c=d().color or {}; return c.r or 1,c.g or 0.2,c.b or 0.2,c.a or 1 end,
        set=function(_,r,g,b,a) local db=d(); if not db.color then db.color={} end
            db.color.r=r; db.color.g=g; db.color.b=b; db.color.a=a; refresh() end }
    opts[#opts+1] = { type="range", name="Font Size", min=10, max=72, step=1,
        get=function() return d().fontSize or 22 end,
        set=function(_,_,v) d().fontSize=v; refresh() end }
    for i,outline in ipairs(OUTLINES) do
        local o,l = outline, OUTLINE_LABELS[i]
        opts[#opts+1] = { type="button", name=l, desc="Set outline: "..l,
            func=function() d().fontOutline=o; refresh() end }
    end
    opts[#opts+1] = { type="label", get=function() return "Preview" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="button", name="Preview On",
        func=function() local m=RRT_NS.MP_FocusInterrupt; if m then m:SetPreviewMode(true) end end }
    opts[#opts+1] = { type="button", name="Preview Off",
        func=function() local m=RRT_NS.MP_FocusInterrupt; if m then m:SetPreviewMode(false) end end }
    opts[#opts+1] = { type="button", name="Reset Position",
        func=function() local m=RRT_NS.MP_FocusInterrupt; if m then m:ResetPosition() end end }

    return opts
end

local function BuildFocusInterruptOptionsRight()
    local function d() return RRT and RRT.MP_FocusInterrupt or {} end
    local function refresh() local m=RRT_NS.MP_FocusInterrupt; if m then m:UpdateDisplay() end end
    local opts = {}

    opts[#opts+1] = { type="label", get=function() return "Sound / TTS" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Play Sound",
        get=function() return d().playSound end,
        set=function(_,_,v) d().playSound=v; refresh() end }
    opts[#opts+1] = { type="select", name="Sound",
        get=function() return d().sound or "" end,
        values=function() return SoundValues(function(v) d().sound=v; refresh() end) end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Play TTS",
        get=function() return d().playTTS end,
        set=function(_,_,v) d().playTTS=v; refresh() end }
    opts[#opts+1] = { type="input", name="TTS Text",
        get=function() return d().tts or "" end,
        set=function(_,_,v) d().tts=v; refresh() end }
    opts[#opts+1] = { type="range", name="TTS Volume", min=0, max=100, step=1,
        get=function() return d().ttsVolume or 50 end,
        set=function(_,_,v) d().ttsVolume=v; refresh() end }

    return opts
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Focus Target Marker
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildFocusMarkerOptions()
    local function d() return RRT and RRT.MP_FocusMarker or {} end
    local function refresh() local m=RRT_NS.MP_FocusMarker; if m then m:UpdateDisplay() end end
    local opts = {}

    local MARKER_NAMES = RRT_NS.MP_FocusMarker and RRT_NS.MP_FocusMarker.MARKER_NAMES
        or {[1]="Star",[2]="Circle",[3]="Diamond",[4]="Triangle",
            [5]="Moon",[6]="Square",[7]="Cross",[8]="Skull"}

    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        desc="Show a button to mark your focus target with a raid marker.",
        get=function() return d().enabled end,
        set=function(_,_,v) d().enabled=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Lock Position",
        get=function() return d().locked end,
        set=function(_,_,v) d().locked=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Only in Dungeons",
        desc="Only show the button when inside a dungeon or raid instance.",
        get=function() return d().onlyDungeon end,
        set=function(_,_,v) d().onlyDungeon=v; refresh() end }

    local markerValues = {}
    for i=1,8 do
        local idx=i
        tinsert(markerValues, { label=MARKER_NAMES[i], value=idx,
            onclick=function() d().markerIndex=idx; refresh() end })
    end
    opts[#opts+1] = { type="select", name="Marker",
        desc="Raid marker to apply to the focus target.",
        get=function() return MARKER_NAMES[d().markerIndex or 8] end,
        values=function() return markerValues end }

    opts[#opts+1] = { type="toggle", boxfirst=true, name="Announce on Ready Check",
        desc="Send your kick marker to the group on ready check (e.g. \"My kick marker is {Skull}\").",
        get=function() return d().announce end,
        set=function(_,_,v) d().announce=v; refresh() end }

    opts[#opts+1] = { type="label", get=function() return "Button Size" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="range", name="Width", min=60, max=300, step=1,
        get=function() return d().buttonWidth or 110 end,
        set=function(_,_,v) d().buttonWidth=v; refresh() end }
    opts[#opts+1] = { type="range", name="Height", min=16, max=80, step=1,
        get=function() return d().buttonHeight or 24 end,
        set=function(_,_,v) d().buttonHeight=v; refresh() end }
    opts[#opts+1] = { type="range", name="Font Size", min=6, max=36, step=1,
        get=function() return d().fontSize or 10 end,
        set=function(_,_,v) d().fontSize=v; refresh() end }
    opts[#opts+1] = { type="label", get=function() return "Preview" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="button", name="Preview On",
        desc="Show the marker button on screen.",
        func=function() local m=RRT_NS.MP_FocusMarker; if m then m:SetPreviewMode(true) end end }
    opts[#opts+1] = { type="button", name="Preview Off",
        desc="Hide the preview.",
        func=function() local m=RRT_NS.MP_FocusMarker; if m then m:SetPreviewMode(false) end end }
    opts[#opts+1] = { type="button", name="Reset Position",
        func=function() local m=RRT_NS.MP_FocusMarker; if m then m:ResetPosition() end end }

    return opts
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Death Alert — colonne gauche
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildDeathAlertOptionsLeft()
    local function d() return RRT and RRT.MP_DeathAlert or {} end
    local function refresh() local m=RRT_NS.MP_DeathAlert; if m then m:UpdateDisplay() end end
    local opts = {}

    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        desc="Flash an alert when a group member dies.",
        get=function() return d().enabled end,
        set=function(_,_,v) d().enabled=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Lock Position",
        get=function() return d().locked end,
        set=function(_,_,v) d().locked=v; refresh() end }
    opts[#opts+1] = { type="range", name="Display Duration", min=1, max=15, step=1,
        desc="Seconds the alert stays visible.",
        get=function() return d().displayTime or 4 end,
        set=function(_,_,v) d().displayTime=v; refresh() end }
    opts[#opts+1] = { type="range", name="Font Size", min=10, max=72, step=1,
        get=function() return d().fontSize or 24 end,
        set=function(_,_,v) d().fontSize=v; refresh() end }
    for i,outline in ipairs(OUTLINES) do
        local o,l = outline, OUTLINE_LABELS[i]
        opts[#opts+1] = { type="button", name=l, desc="Set outline: "..l,
            func=function() d().fontOutline=o; refresh() end }
    end

    opts[#opts+1] = { type="label", get=function() return "Per-Role Settings" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    local roles = { {key="tank",label="Tank"}, {key="healer",label="Healer"}, {key="damager",label="DPS"} }
    for _, ri in ipairs(roles) do
        local rk, rl = ri.key, ri.label
        opts[#opts+1] = { type="toggle", boxfirst=true, name="Alert for "..rl,
            get=function() local dr=d().byRole; return dr and dr[rk] and dr[rk].enabled end,
            set=function(_,_,v) local dr=d().byRole; if dr and dr[rk] then dr[rk].enabled=v; refresh() end end }
        opts[#opts+1] = { type="color", name=rl.." Color",
            get=function() local dr=d().byRole; local c=dr and dr[rk] and dr[rk].color or {}
                return c.r or 1,c.g or 1,c.b or 1,c.a or 1 end,
            set=function(_,r,g,b,a) local dr=d().byRole; if dr and dr[rk] then
                if not dr[rk].color then dr[rk].color={} end
                dr[rk].color.r=r; dr[rk].color.g=g; dr[rk].color.b=b; dr[rk].color.a=a; refresh() end end }
    end

    return opts
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Death Alert — colonne droite (Sound / TTS / Preview)
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildDeathAlertOptionsRight()
    local function d() return RRT and RRT.MP_DeathAlert or {} end
    local function refresh() local m=RRT_NS.MP_DeathAlert; if m then m:UpdateDisplay() end end
    local opts = {}

    opts[#opts+1] = { type="label", get=function() return "Sound / TTS" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Play Sound",
        get=function() return d().playSound end,
        set=function(_,_,v) d().playSound=v; refresh() end }
    opts[#opts+1] = { type="select", name="Sound",
        get=function() return d().sound or "" end,
        values=function() return SoundValues(function(v) d().sound=v; refresh() end) end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Play TTS",
        get=function() return d().playTTS end,
        set=function(_,_,v) d().playTTS=v; refresh() end }
    opts[#opts+1] = { type="input", name="TTS Text",
        desc="Use {name} to insert the player's name.",
        get=function() return d().tts or "" end,
        set=function(_,_,v) d().tts=v; refresh() end }
    opts[#opts+1] = { type="range", name="TTS Volume", min=0, max=100, step=1,
        get=function() return d().ttsVolume or 50 end,
        set=function(_,_,v) d().ttsVolume=v; refresh() end }

    opts[#opts+1] = { type="label", get=function() return "Preview" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="button", name="Preview On",
        desc="Show a sample death alert on screen.",
        func=function() local m=RRT_NS.MP_DeathAlert; if m then m:SetPreviewMode(true) end end }
    opts[#opts+1] = { type="button", name="Preview Off",
        desc="Hide the preview.",
        func=function() local m=RRT_NS.MP_DeathAlert; if m then m:SetPreviewMode(false) end end }
    opts[#opts+1] = { type="button", name="Reset Position",
        func=function() local m=RRT_NS.MP_DeathAlert; if m then m:ResetPosition() end end }

    return opts
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Healer Mana Indicator
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildHealerManaOptions()
    local function d() return RRT and RRT.MP_HealerMana or {} end
    local function refresh() local m=RRT_NS.MP_HealerMana; if m then m:UpdateDisplay() end end
    local opts = {}

    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        desc="Show each healer's mana percentage.",
        get=function() return d().enabled end,
        set=function(_,_,v) d().enabled=v; refresh() end }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Lock Position",
        get=function() return d().locked end,
        set=function(_,_,v) d().locked=v; refresh() end }
    opts[#opts+1] = { type="range", name="Font Size", min=8, max=36, step=1,
        get=function() return d().fontSize or 14 end,
        set=function(_,_,v) d().fontSize=v; refresh() end }
    for i,outline in ipairs(OUTLINES) do
        local o,l = outline, OUTLINE_LABELS[i]
        opts[#opts+1] = { type="button", name=l, desc="Set outline: "..l,
            func=function() d().fontOutline=o; refresh() end }
    end
    opts[#opts+1] = { type="range", name="Low Mana %", min=0, max=100, step=1,
        desc="Below this % the indicator turns orange.",
        get=function() return d().lowThreshold or 30 end,
        set=function(_,_,v) d().lowThreshold=v; refresh() end }
    opts[#opts+1] = { type="range", name="Critical Mana %", min=0, max=100, step=1,
        desc="Below this % the indicator turns red.",
        get=function() return d().critThreshold or 15 end,
        set=function(_,_,v) d().critThreshold=v; refresh() end }
    opts[#opts+1] = { type="label", get=function() return "Preview" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="button", name="Preview On",
        desc="Show sample healer mana bars on screen.",
        func=function() local m=RRT_NS.MP_HealerMana; if m then m:SetPreviewMode(true) end end }
    opts[#opts+1] = { type="button", name="Preview Off",
        desc="Hide the preview.",
        func=function() local m=RRT_NS.MP_HealerMana; if m then m:SetPreviewMode(false) end end }
    opts[#opts+1] = { type="button", name="Reset Position",
        func=function() local m=RRT_NS.MP_HealerMana; if m then m:ResetPosition() end end }

    return opts
end

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Group Joined — popup éditeur de message
-- ─────────────────────────────────────────────────────────────────────────────
local _editPopup = nil

local function ShowEditMessagePopup(title, getText, setText)
    if not _editPopup then
        local f = CreateFrame("Frame", "RRTGroupJoinedEditPopup", UIParent, "BackdropTemplate")
        f:SetSize(460, 110)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:SetClampedToScreen(true)
        f:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
        f:SetBackdropBorderColor(0.5, 0.3, 0.8, 1)
        f:SetScript("OnMouseDown", function(self) self:StartMoving() end)
        f:SetScript("OnMouseUp",   function(self) self:StopMovingOrSizing() end)

        local titleLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleLabel:SetPoint("TOPLEFT", 10, -10)
        titleLabel:SetTextColor(1, 0.82, 0, 1)
        f.titleLabel = titleLabel

        local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -2, -2)
        close:SetScript("OnClick", function() f:Hide() end)

        local eb = CreateFrame("EditBox", "RRTGroupJoinedEditBox", f, "InputBoxTemplate")
        eb:SetSize(430, 22)
        eb:SetPoint("TOPLEFT", 12, -34)
        eb:SetAutoFocus(true)
        eb:SetFont(STANDARD_TEXT_FONT, 12, "")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        eb:SetScript("OnEnterPressed", function()
            if f.onApply then f.onApply(f.editBox:GetText()) end
            f:Hide()
        end)
        f.editBox = eb

        local hint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOPLEFT", 12, -60)
        hint:SetTextColor(0.6, 0.6, 0.6, 1)
        hint:SetText("Variables : {name}  {dungeon}  {level}")
        f.hint = hint

        local applyBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
        applyBtn:SetSize(100, 22)
        applyBtn:SetPoint("BOTTOMRIGHT", -10, 10)
        applyBtn:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        applyBtn:SetBackdropColor(0.18, 0.35, 0.18, 0.9)
        applyBtn:SetBackdropBorderColor(0.3, 0.7, 0.3, 1)
        local applyLbl = applyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        applyLbl:SetPoint("CENTER")
        applyLbl:SetText("Apply")
        applyBtn:SetScript("OnClick", function()
            if f.onApply then f.onApply(f.editBox:GetText()) end
            f:Hide()
        end)
        f.applyBtn = applyBtn

        _editPopup = f
    end

    _editPopup.titleLabel:SetText(title)
    _editPopup.editBox:SetText(getText())
    _editPopup.editBox:SetFocus()
    _editPopup.editBox:HighlightText()
    _editPopup.onApply = setText
    _editPopup:Show()
end

local function BuildGroupJoinedOptions()
    local function d() return RRT and RRT.MP_GroupJoined or {} end
    local function refresh() local m=RRT_NS.MP_GroupJoined; if m then m:UpdateDisplay() end end
    local opts = {}

    -- ── Greeting ──────────────────────────────────────────────────────────────
    opts[#opts+1] = { type="label", get=function() return "Greeting" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        get=function() return d().enabled end,
        set=function(_,_,v) d().enabled=v; refresh() end }
    opts[#opts+1] = { type="label", get=function() return
        "Message : \"" .. (d().message or "") .. "\"" end }
    opts[#opts+1] = { type="button", name="Change Greeting Message",
        func=function()
            ShowEditMessagePopup(
                "Greeting Message  —  {name}  {dungeon}",
                function() return d().message or "" end,
                function(v) d().message = v; refresh() end
            )
        end }
    opts[#opts+1] = { type="label", get=function() return "" end }
    opts[#opts+1] = { type="range", name="Delay (sec)", min=0, max=30, step=1,
        get=function() return d().delay or 2 end,
        set=function(_,_,v) d().delay=v; refresh() end }

    -- ── Farewell ──────────────────────────────────────────────────────────────
    opts[#opts+1] = { type="label", get=function() return "Farewell — Mythic+ Completed" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="toggle", boxfirst=true, name="Enable",
        get=function() return d().farewellEnabled end,
        set=function(_,_,v) d().farewellEnabled=v; refresh() end }
    opts[#opts+1] = { type="label", get=function() return
        "Message : \"" .. (d().farewellMessage or "") .. "\"" end }
    opts[#opts+1] = { type="button", name="Change Farewell Message",
        func=function()
            ShowEditMessagePopup(
                "Farewell Message  —  {name}  {dungeon}  {level}",
                function() return d().farewellMessage or "" end,
                function(v) d().farewellMessage = v; refresh() end
            )
        end }
    opts[#opts+1] = { type="label", get=function() return "" end }
    opts[#opts+1] = { type="range", name="Delay (sec)", min=0, max=30, step=1,
        get=function() return d().farewellDelay or 3 end,
        set=function(_,_,v) d().farewellDelay=v; refresh() end }

    return opts
end

local function BuildToolsOptions()
    local opts = {}

    opts[#opts+1] = { type="label", get=function() return "Mythic+ Tools" end,
        text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }
    opts[#opts+1] = { type="label", get=function() return
        "Cette section servira a accueillir les outils Mythic+ importes dans InfinityRaidTools."
    end }
    opts[#opts+1] = { type="label", get=function() return
        "Modules prevus : Party Keys, Interrupt Tracker, Mythic Cast, Run History, Spell Guide."
    end }
    opts[#opts+1] = { type="label", get=function() return "" end }
    opts[#opts+1] = { type="label", get=function() return
        "Etat actuel : le core est pret, aucun module outil n'est encore branche ici."
    end, text_template=DF:GetTemplate("font","ORANGE_FONT_TEMPLATE"), spacement=true }

    return opts
end

local function GetToolsCore()
    return _G.RRTMythicTools or (RRT_NS and RRT_NS.Mythic)
end

local function GetToolsDB(moduleKey, defaults)
    local core = GetToolsCore()
    if core and core.GetModuleDB then
        return core:GetModuleDB(moduleKey, defaults)
    end

    RRT = RRT or {}
    RRT.MythicCore = RRT.MythicCore or {}
    RRT.MythicCore.ModuleDB = RRT.MythicCore.ModuleDB or {}
    RRT.MythicCore.ModuleDB[moduleKey] = RRT.MythicCore.ModuleDB[moduleKey] or {}

    local db = RRT.MythicCore.ModuleDB[moduleKey]
    if defaults then
        for key, value in pairs(defaults) do
            if db[key] == nil then
                if type(value) == "table" then
                    local copy = {}
                    for subKey, subValue in pairs(value) do
                        copy[subKey] = subValue
                    end
                    db[key] = copy
                else
                    db[key] = value
                end
            end
        end
    end
    return db
end

local function OutlineValues(setFn)
    local values = {}
    for _, outline in ipairs(OUTLINES) do
        values[#values + 1] = {
            label = outline == "NONE" and "None" or outline,
            value = outline,
            onclick = function()
                setFn(outline)
            end,
        }
    end
    return values
end

local function SimpleDropdownValues(items, setFn)
    local values = {}
    for _, item in ipairs(items) do
        values[#values + 1] = {
            label = item.label,
            value = item.value,
            onclick = function()
                setFn(item.value)
            end,
        }
    end
    return values
end

local function BuildMicroMenuOptions()
    local function d()
        return GetToolsDB("RRTTools.MicroMenu", {
            enabled = false,
            locked = true,
            showBackground = true,
            iconSize = 28,
            barScale = 1,
            bgAlpha = 0.5,
            iconTheme = "blizzard",
            timeFormat = "24h",
            showSeconds = false,
            timeFontSize = 0,
            timeOffsetX = 0,
            timeOffsetY = 0,
            posAnchor = "TOP",
            posX = 0,
            posY = -4,
        })
    end

    local function refresh()
        local module = RRT_NS.MP_MicroMenu
        if module and module.RefreshDisplay then
            module:RefreshDisplay()
        end
    end

    local themes = {
        { label = "Blizzard", value = "blizzard" },
        { label = "Cyberpunk", value = "cyberpunk" },
    }
    local timeFormats = {
        { label = "24h", value = "24h" },
        { label = "12h", value = "12h" },
    }
    local anchors = {
        { label = "TOP", value = "TOP" },
        { label = "TOPLEFT", value = "TOPLEFT" },
        { label = "TOPRIGHT", value = "TOPRIGHT" },
        { label = "CENTER", value = "CENTER" },
        { label = "BOTTOM", value = "BOTTOM" },
    }

    local opts = {}
    opts[#opts + 1] = { type = "label", get = function() return "Micro Menu" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"), spacement = true }
    opts[#opts + 1] = { type = "label", get = function() return "Le module source est désactivé en amont dans RRT, mais ses réglages principaux sont déjà préparés ici." end }
    opts[#opts + 1] = { type = "toggle", boxfirst = true, name = "Enable", get = function() return d().enabled end, set = function(_, _, v) d().enabled = v; refresh() end }
    opts[#opts + 1] = { type = "toggle", boxfirst = true, name = "Lock Position", get = function() return d().locked end, set = function(_, _, v) d().locked = v; refresh() end }
    opts[#opts + 1] = { type = "toggle", boxfirst = true, name = "Show Background", get = function() return d().showBackground end, set = function(_, _, v) d().showBackground = v; refresh() end }
    opts[#opts + 1] = { type = "range", name = "Icon Size", min = 16, max = 64, step = 1, get = function() return d().iconSize or 28 end, set = function(_, _, v) d().iconSize = v; refresh() end }
    opts[#opts + 1] = { type = "range", name = "Bar Scale", min = 0.5, max = 2, step = 0.05, get = function() return d().barScale or 1 end, set = function(_, _, v) d().barScale = v; refresh() end }
    opts[#opts + 1] = { type = "range", name = "Background Alpha", min = 0, max = 1, step = 0.05, get = function() return d().bgAlpha or 0.5 end, set = function(_, _, v) d().bgAlpha = v; refresh() end }
    opts[#opts + 1] = { type = "select", name = "Icon Theme", get = function() return d().iconTheme or "blizzard" end, values = function() return SimpleDropdownValues(themes, function(v) d().iconTheme = v; refresh() end) end }
    opts[#opts + 1] = { type = "select", name = "Time Format", get = function() return d().timeFormat or "24h" end, values = function() return SimpleDropdownValues(timeFormats, function(v) d().timeFormat = v; refresh() end) end }
    opts[#opts + 1] = { type = "toggle", boxfirst = true, name = "Show Seconds", get = function() return d().showSeconds end, set = function(_, _, v) d().showSeconds = v; refresh() end }
    opts[#opts + 1] = { type = "range", name = "Time Font Size", min = 0, max = 36, step = 1, get = function() return d().timeFontSize or 0 end, set = function(_, _, v) d().timeFontSize = v; refresh() end }
    opts[#opts + 1] = { type = "range", name = "Time Offset X", min = -200, max = 200, step = 1, get = function() return d().timeOffsetX or 0 end, set = function(_, _, v) d().timeOffsetX = v; refresh() end }
    opts[#opts + 1] = { type = "range", name = "Time Offset Y", min = -50, max = 50, step = 1, get = function() return d().timeOffsetY or 0 end, set = function(_, _, v) d().timeOffsetY = v; refresh() end }
    opts[#opts + 1] = { type = "select", name = "Anchor", get = function() return d().posAnchor or "TOP" end, values = function() return SimpleDropdownValues(anchors, function(v) d().posAnchor = v; refresh() end) end }
    opts[#opts + 1] = { type = "range", name = "Position X", min = -1000, max = 1000, step = 1, get = function() return d().posX or 0 end, set = function(_, _, v) d().posX = v; refresh() end }
    opts[#opts + 1] = { type = "range", name = "Position Y", min = -600, max = 600, step = 1, get = function() return d().posY or 0 end, set = function(_, _, v) d().posY = v; refresh() end }
    return opts
end

local function BuildPvePanelOptions()
    local function d()
        return GetToolsDB("RRTTools.PveInfoPanel", {
            enabled = false,
            side = "RIGHT",
            offsetX = 2,
            offsetY = 0,
        })
    end

    local function refresh()
        local module = RRT_NS.PveInfoPanel
        if module and module.RefreshDisplay then
            module:RefreshDisplay()
        end
    end

    local sides = {
        { label = "Left", value = "LEFT" },
        { label = "Right", value = "RIGHT" },
    }

    local opts = {}
    opts[#opts + 1] = { type = "label", get = function() return "PVE Info Panel" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"), spacement = true }
    opts[#opts + 1] = { type = "toggle", boxfirst = true, name = "Enable", get = function() return d().enabled end, set = function(_, _, v) d().enabled = v; refresh() end }
    opts[#opts + 1] = { type = "select", name = "Side", get = function() return d().side or "RIGHT" end, values = function() return SimpleDropdownValues(sides, function(v) d().side = v; refresh() end) end }
    opts[#opts + 1] = { type = "range", name = "Offset X", min = -100, max = 100, step = 1, get = function() return d().offsetX or 0 end, set = function(_, _, v) d().offsetX = v; refresh() end }
    opts[#opts + 1] = { type = "range", name = "Offset Y", min = -500, max = 500, step = 5, get = function() return d().offsetY or 0 end, set = function(_, _, v) d().offsetY = v; refresh() end }
    return opts
end

local function BuildPartyKeysOptions()
    local function d()
        return GetToolsDB("RRTTools.PveKeystoneInfo", {
            enabled = false,
            side = "RIGHT",
            offsetX = 156,
            offsetY = -107,
            previewMode = false,
            playerFont    = { size = 20 },
            partyNameFont = { size = 15 },
            partyKeyFont  = { size = 15 },
        })
    end

    local function refresh()
        local module = RRT_NS.PveKeystoneInfo
        if module and module.RefreshDisplay then
            module:RefreshDisplay()
        end
    end

    local sides = {
        { label = "Left", value = "LEFT" },
        { label = "Right", value = "RIGHT" },
    }

    local opts = {}
    opts[#opts + 1] = { type = "label", get = function() return "Party Keys" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"), spacement = true }
    opts[#opts + 1] = { type = "toggle", boxfirst = true, name = "Enable",
        get = function() return d().enabled end,
        set = function(_, _, v) d().enabled = v; refresh() end }
    opts[#opts + 1] = { type = "toggle", boxfirst = true, name = "Preview Mode",
        get = function() return d().previewMode end,
        set = function(_, _, v) d().previewMode = v; refresh() end }
    opts[#opts + 1] = { type = "select", name = "Side",
        get = function() return d().side or "RIGHT" end,
        values = function() return SimpleDropdownValues(sides, function(v) d().side = v; refresh() end) end }
    opts[#opts + 1] = { type = "range", name = "Offset X", min = -300, max = 300, step = 1,
        get = function() return d().offsetX or 0 end,
        set = function(_, _, v) d().offsetX = v; refresh() end }
    opts[#opts + 1] = { type = "range", name = "Offset Y", min = -500, max = 500, step = 1,
        get = function() return d().offsetY or 0 end,
        set = function(_, _, v) d().offsetY = v; refresh() end }
    opts[#opts + 1] = { type = "range", name = "Player Font Size", min = 8, max = 40, step = 1,
        get = function() local db = d(); return db.playerFont and db.playerFont.size or 20 end,
        set = function(_, _, v) local db = d(); if not db.playerFont then db.playerFont = {} end; db.playerFont.size = v; refresh() end }
    opts[#opts + 1] = { type = "range", name = "Party Name Font Size", min = 8, max = 40, step = 1,
        get = function() local db = d(); return db.partyNameFont and db.partyNameFont.size or 15 end,
        set = function(_, _, v) local db = d(); if not db.partyNameFont then db.partyNameFont = {} end; db.partyNameFont.size = v; refresh() end }
    opts[#opts + 1] = { type = "range", name = "Party Key Font Size", min = 8, max = 40, step = 1,
        get = function() local db = d(); return db.partyKeyFont and db.partyKeyFont.size or 15 end,
        set = function(_, _, v) local db = d(); if not db.partyKeyFont then db.partyKeyFont = {} end; db.partyKeyFont.size = v; refresh() end }
    return opts
end

local function BuildSimpleMythicModuleOptions(title, moduleKey, runtimeName, defaults, extra)
    local function d()
        local core = _G.RRTMythicTools
        if not core then
            return defaults
        end
        return core:GetModuleDB(moduleKey, defaults)
    end

    local function refresh()
        local module = RRT_NS[runtimeName]
        if module and module.RefreshDisplay then
            module:RefreshDisplay()
        end
    end

    local opts = {
        { type = "label", get = function() return title end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"), spacement = true },
        { type = "toggle", boxfirst = true, name = "Enable", get = function() return d().enabled end, set = function(_, _, v) d().enabled = v; refresh() end },
    }

    if defaults.locked ~= nil then
        opts[#opts + 1] = { type = "toggle", boxfirst = true, name = "Lock Position", get = function() return d().locked end, set = function(_, _, v) d().locked = v; refresh() end }
    end

    if extra then
        for _, option in ipairs(extra) do
            opts[#opts + 1] = option
        end
    end

    return opts
end

local function BuildMythicTooltipOptions()
    return BuildSimpleMythicModuleOptions("Tooltip", "RRTTools.Tooltip", "MythicTooltip", {
        enabled = false,
        showTeleportInfo = true,
        showInterruptInfo = true,
    }, {
        { type = "toggle", boxfirst = true, name = "Show Teleport Info", get = function() return _G.RRTMythicTools:GetModuleDB("RRTTools.Tooltip", { enabled = false, showTeleportInfo = true, showInterruptInfo = true }).showTeleportInfo end, set = function(_, _, v) _G.RRTMythicTools:GetModuleDB("RRTTools.Tooltip", { enabled = false, showTeleportInfo = true, showInterruptInfo = true }).showTeleportInfo = v; if RRT_NS.MythicTooltip then RRT_NS.MythicTooltip:RefreshDisplay() end end },
        { type = "toggle", boxfirst = true, name = "Show Interrupt Info", get = function() return _G.RRTMythicTools:GetModuleDB("RRTTools.Tooltip", { enabled = false, showTeleportInfo = true, showInterruptInfo = true }).showInterruptInfo end, set = function(_, _, v) _G.RRTMythicTools:GetModuleDB("RRTTools.Tooltip", { enabled = false, showTeleportInfo = true, showInterruptInfo = true }).showInterruptInfo = v; if RRT_NS.MythicTooltip then RRT_NS.MythicTooltip:RefreshDisplay() end end },
    })
end

local function BuildDashboardOptions()
    return BuildSimpleMythicModuleOptions("Dashboard", "RRTTools.MythicDashboard", "MythicDashboard", {
        enabled = false,
    }, {
        { type = "button", name = "Open Dashboard", func = function() if RRT_NS.MythicDashboard then RRT_NS.MythicDashboard:ToggleWindow() end end },
    })
end

local function BuildTeleMsgOptions()
    local channels = {
        { label = "Party", value = "PARTY" },
        { label = "Raid", value = "RAID" },
        { label = "Say", value = "SAY" },
        { label = "Yell", value = "YELL" },
    }
    return BuildSimpleMythicModuleOptions("Teleport Messages", "RRTTools.TeleMsg", "MythicTeleMsg", {
        enabled = false,
        channel = "PARTY",
        message = "Teleporting to %s.",
    }, {
        { type = "select", name = "Channel", get = function() return _G.RRTMythicTools:GetModuleDB("RRTTools.TeleMsg", { enabled = false, channel = "PARTY", message = "Teleporting to %s." }).channel end, values = function() return SimpleDropdownValues(channels, function(v) _G.RRTMythicTools:GetModuleDB("RRTTools.TeleMsg", { enabled = false, channel = "PARTY", message = "Teleporting to %s." }).channel = v end) end },
        { type = "input", name = "Message", get = function() return _G.RRTMythicTools:GetModuleDB("RRTTools.TeleMsg", { enabled = false, channel = "PARTY", message = "Teleporting to %s." }).message end, set = function(_, _, v) _G.RRTMythicTools:GetModuleDB("RRTTools.TeleMsg", { enabled = false, channel = "PARTY", message = "Teleporting to %s." }).message = v end },
    })
end


-- ─────────────────────────────────────────────────────────────────────────────
-- Export — same pattern as every other module in this addon
-- ─────────────────────────────────────────────────────────────────────────────
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}

RRT_NS.UI.Options.MP_PotionAlert    = { BuildOptions = BuildPotionAlertOptions,    BuildCallback = function() return function() end end }
RRT_NS.UI.Options.MP_FocusInterrupt = { BuildOptions = BuildFocusInterruptOptionsLeft, BuildOptionsRight = BuildFocusInterruptOptionsRight, BuildCallback = function() return function() end end }
RRT_NS.UI.Options.MP_FocusMarker    = { BuildOptions = BuildFocusMarkerOptions,     BuildCallback = function() return function() end end }
RRT_NS.UI.Options.MP_DeathAlert     = { BuildOptions = BuildDeathAlertOptionsLeft, BuildOptionsRight = BuildDeathAlertOptionsRight, BuildCallback = function() return function() end end }
RRT_NS.UI.Options.MP_HealerMana     = { BuildOptions = BuildHealerManaOptions,      BuildCallback = function() return function() end end }
RRT_NS.UI.Options.MP_GroupJoined    = { BuildOptions = BuildGroupJoinedOptions, singleColumn = true, BuildCallback = function() return function() end end }
RRT_NS.UI.Options.MP_Tools          = { BuildOptions = BuildToolsOptions, singleColumn = true, BuildCallback = function() return function() end end }
RRT_NS.UI.Options.MythicTooltip = { BuildOptions = BuildMythicTooltipOptions, singleColumn = true, BuildCallback = function() return function() end end }
RRT_NS.UI.Options.MythicDashboard = { BuildOptions = BuildDashboardOptions, singleColumn = true, BuildCallback = function() return function() end end }
RRT_NS.UI.Options.TeleMsg = { BuildOptions = BuildTeleMsgOptions, singleColumn = true, BuildCallback = function() return function() end end }

