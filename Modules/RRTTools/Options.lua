local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local function GetDB()
    return RRT_NS.Tools and RRT_NS.Tools.GetDB() or {}
end

local function Refresh()
    if RRT_NS.Tools then RRT_NS.Tools.RefreshAll() end
end

-- ═══════════════════════════════════════════════════════════════
-- Spec icon helper
-- ═══════════════════════════════════════════════════════════════
-- specID -> { name, iconID }
local SPEC_INFO = {
    -- Death Knight
    [250] = { name = "Blood",      icon = 135770 },
    [251] = { name = "Frost",      icon = 135773 },
    [252] = { name = "Unholy",     icon = 135775 },
    -- Warrior
    [71]  = { name = "Arms",       icon = 132355 },
    [72]  = { name = "Fury",       icon = 132347 },
    [73]  = { name = "Protection", icon = 132341 },
    -- Paladin
    [65]  = { name = "Holy",       icon = 135920 },
    [66]  = { name = "Protection", icon = 135929 },
    [70]  = { name = "Retribution",icon = 135873 },
    -- Hunter
    [253] = { name = "Beast Mastery", icon = 461112 },
    [254] = { name = "Marksmanship",  icon = 236179 },
    [255] = { name = "Survival",      icon = 982414 },
    -- Shaman
    [262] = { name = "Elemental",  icon = 136048 },
    [263] = { name = "Enhancement",icon = 136051 },
    [264] = { name = "Restoration",icon = 136052 },
    -- Evoker
    [1467]= { name = "Devastation",icon = 4622761 },
    [1468]= { name = "Preservation",icon = 4622764 },
    [1473]= { name = "Augmentation",icon = 5198700 },
    -- Demon Hunter
    [577] = { name = "Havoc",      icon = 1247264 },
    [581] = { name = "Vengeance",  icon = 1247265 },
    [1480]= { name = "Aldrachi Reaver", icon = 5765770 },
    -- Rogue
    [259] = { name = "Assassination", icon = 132302 },
    [260] = { name = "Outlaw",     icon = 132305 },
    [261] = { name = "Subtlety",   icon = 132307 },
    -- Monk
    [268] = { name = "Brewmaster", icon = 608951 },
    [269] = { name = "Windwalker", icon = 606543 },
    [270] = { name = "Mistweaver", icon = 775461 },
    -- Druid
    [102] = { name = "Balance",    icon = 136096 },
    [103] = { name = "Feral",      icon = 132115 },
    [104] = { name = "Guardian",   icon = 132276 },
    [105] = { name = "Restoration",icon = 136041 },
    -- Mage
    [62]  = { name = "Arcane",     icon = 135932 },
    [63]  = { name = "Fire",       icon = 135810 },
    [64]  = { name = "Frost",      icon = 135846 },
    -- Warlock
    [265] = { name = "Affliction", icon = 136145 },
    [266] = { name = "Demonology", icon = 136172 },
    [267] = { name = "Destruction",icon = 136186 },
    -- Priest
    [256] = { name = "Discipline", icon = 135946 },
    [257] = { name = "Holy",       icon = 135945 },
    [258] = { name = "Shadow",     icon = 136207 },
}

local function SpecLabel(specID)
    local info = SPEC_INFO[specID]
    if not info then return "Spec " .. specID end
    return string.format("|T%d:14:14:0:0|t %s", info.icon, info.name)
end

-- ═══════════════════════════════════════════════════════════════
-- 1. Auto Tools
-- ═══════════════════════════════════════════════════════════════
local function BuildAutoToolsOptions()
    local opts = {}

    opts[#opts+1] = {
        type = "label",
        get  = function() return "Auto Tools" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Auto Delete",
        desc     = "Automatically fills in the delete confirmation dialog so you don't have to type DELETE.",
        get      = function() return GetDB().AutoDelete end,
        set      = function(s, _, v) GetDB().AutoDelete = v end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Auto Sell Junk",
        desc     = "Automatically sells all gray (junk) items when you open a merchant.",
        get      = function() return GetDB().AutoSellJunk end,
        set      = function(s, _, v) GetDB().AutoSellJunk = v end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Auto Repair",
        desc     = "Automatically repairs your equipment when you open a merchant.",
        get      = function() return GetDB().AutoRepair end,
        set      = function(s, _, v) GetDB().AutoRepair = v end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Use Guild Bank for Repair",
        desc     = "Use guild bank funds for repairs instead of your own gold (if available).",
        get      = function() return GetDB().AutoRepairGuild end,
        set      = function(s, _, v) GetDB().AutoRepairGuild = v end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Bulk Buy (Right-Click Merchant)",
        desc     = "Right-click any merchant item to open a bulk buy panel with quantity input.",
        get      = function() return GetDB().BulkBuy end,
        set      = function(s, _, v)
            GetDB().BulkBuy = v
            if v and RRT_NS.Tools then RRT_NS.Tools.InitBulkBuy() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Bulk Buy - Warn if total cost exceeds (Gold)",
        desc = "Show a confirmation dialog if the bulk purchase total exceeds this amount in gold.",
        min  = 0,
        max  = 100000,
        step = 100,
        get  = function() return GetDB().BulkBuyWarnGold end,
        set  = function(s, _, v) GetDB().BulkBuyWarnGold = v end,
    }
    opts[#opts+1] = { type = "breakline" }

    return opts
end

-- ═══════════════════════════════════════════════════════════════
-- 2. Map & Display
-- ═══════════════════════════════════════════════════════════════
local function BuildMapDisplayOptions()
    local opts = {}

    -- Map Info
    opts[#opts+1] = {
        type = "label",
        get  = function() return "Map Info" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Show Map Info Overlay",
        desc     = "Display MapID, cursor coordinates and player coordinates on the World Map.",
        get      = function() return GetDB().MapInfo end,
        set      = function(s, _, v)
            GetDB().MapInfo = v
            if RRT_NS.Tools then RRT_NS.Tools.InitMapInfo() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Show Map ID",
        desc     = "Include the current MapID in the overlay.",
        get      = function() return GetDB().MapInfoShowMapID end,
        set      = function(s, _, v) GetDB().MapInfoShowMapID = v end,
        nocombat = true,
    }
    opts[#opts+1] = { type = "breakline" }

    -- Range Check
    opts[#opts+1] = {
        type = "label",
        get  = function() return "Range Check" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Enable Range Check",
        desc     = "Show an on-screen display of your approximate distance to your target.",
        get      = function() return GetDB().RangeCheck end,
        set      = function(s, _, v)
            GetDB().RangeCheck = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshRangeCheck() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Font Size",
        desc = "Size of the range check text.",
        min  = 8,
        max  = 48,
        step = 1,
        get  = function() return GetDB().RangeCheckFontSize end,
        set  = function(s, _, v)
            GetDB().RangeCheckFontSize = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshRangeCheck() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Position X",
        desc = "Horizontal offset from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().RangeCheckPosX end,
        set  = function(s, _, v)
            GetDB().RangeCheckPosX = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshRangeCheck() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Position Y",
        desc = "Vertical offset from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().RangeCheckPosY end,
        set  = function(s, _, v)
            GetDB().RangeCheckPosY = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshRangeCheck() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Hide Threshold (yards)",
        desc = "Distance beyond which the indicator turns red.",
        min  = 5,
        max  = 100,
        step = 1,
        get  = function() return GetDB().RangeCheckHideThreshold end,
        set  = function(s, _, v) GetDB().RangeCheckHideThreshold = v end,
    }
    opts[#opts+1] = {
        type = "input",
        name = "Range Spell ID",
        desc = "Spell ID used for range detection via C_Spell.IsSpellInRange. Leave blank for approximate mode.",
        get  = function() return GetDB().RangeCheckRangeSpell or "" end,
        set  = function(s, _, v) GetDB().RangeCheckRangeSpell = v end,
    }
    opts[#opts+1] = { type = "breakline" }

    -- Player Position
    opts[#opts+1] = {
        type = "label",
        get  = function() return "Player Position Marker" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Enable Player Position Marker",
        desc     = "Draw a shape at your character's screen position.",
        get      = function() return GetDB().PlayerPosition end,
        set      = function(s, _, v)
            GetDB().PlayerPosition = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshPlayerPosition() end
        end,
        nocombat = true,
    }

    -- Shape dropdown
    local shapeValues = {}
    for _, shape in ipairs({"CROSS", "SQUARE", "CIRCLE", "DIAMOND"}) do
        local sh = shape
        tinsert(shapeValues, {
            label   = sh,
            value   = sh,
            onclick = function()
                GetDB().PlayerPositionShape = sh
                if RRT_NS.Tools then RRT_NS.Tools.RefreshPlayerPosition() end
            end,
        })
    end
    opts[#opts+1] = {
        type   = "select",
        name   = "Shape",
        desc   = "Shape to draw at the player's position.",
        get    = function() return GetDB().PlayerPositionShape or "CROSS" end,
        values = function() return shapeValues end,
    }

    opts[#opts+1] = {
        type = "range",
        name = "Scale",
        desc = "Size scale of the marker.",
        min  = 0.1,
        max  = 2.0,
        step = 0.05,
        get  = function() return GetDB().PlayerPositionScale end,
        set  = function(s, _, v)
            GetDB().PlayerPositionScale = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshPlayerPosition() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Position X",
        desc = "Horizontal offset from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().PlayerPositionPosX end,
        set  = function(s, _, v)
            GetDB().PlayerPositionPosX = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshPlayerPosition() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Position Y",
        desc = "Vertical offset from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().PlayerPositionPosY end,
        set  = function(s, _, v)
            GetDB().PlayerPositionPosY = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshPlayerPosition() end
        end,
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Show In Combat",
        desc     = "Show the marker while you are in combat.",
        get      = function() return GetDB().PlayerPositionInCombat end,
        set      = function(s, _, v) GetDB().PlayerPositionInCombat = v end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Show Out of Combat",
        desc     = "Show the marker while you are out of combat.",
        get      = function() return GetDB().PlayerPositionOutCombat end,
        set      = function(s, _, v) GetDB().PlayerPositionOutCombat = v end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Instances Only",
        desc     = "Only show the marker when inside a dungeon or raid instance.",
        get      = function() return GetDB().PlayerPositionInstanceOnly end,
        set      = function(s, _, v) GetDB().PlayerPositionInstanceOnly = v end,
        nocombat = true,
    }
    opts[#opts+1] = { type = "breakline" }

    return opts
end

-- ═══════════════════════════════════════════════════════════════
-- 3. M+ Tools
-- ═══════════════════════════════════════════════════════════════
local function BuildMPlusOptions()
    local opts = {}

    opts[#opts+1] = {
        type = "label",
        get  = function() return "Teleport Message" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Enable Tele Message",
        desc     = "Send a party message when you cast a M+ dungeon teleport spell.",
        get      = function() return GetDB().TeleMsg end,
        set      = function(s, _, v)
            GetDB().TeleMsg = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshAll() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type = "input",
        name = "Message Template",
        desc = "Message sent to party. Use %link for the spell link, %name for the dungeon name.",
        get  = function() return GetDB().TelemsgText or '[RRT] Casting %link, teleporting to "%name"' end,
        set  = function(s, _, v) GetDB().TelemsgText = v end,
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Send on Cast Success (not on cast start)",
        desc     = "If enabled, the message is sent when the spell succeeds. If disabled, it sends on cast start.",
        get      = function() return GetDB().TelemsgOnSuccess end,
        set      = function(s, _, v)
            GetDB().TelemsgOnSuccess = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshAll() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = { type = "breakline" }

    opts[#opts+1] = {
        type = "label",
        get  = function() return "Beta Keystone Helper" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Enable Set Key Panel",
        desc     = "Attach a beta-only keystone helper panel to the PVE frame.",
        get      = function() return GetDB().SetKey end,
        set      = function(s, _, v)
            GetDB().SetKey = v
            if RRT_NS.Tools and RRT_NS.Tools.UpdateSetKeyVisibility then RRT_NS.Tools.UpdateSetKeyVisibility() end
        end,
        nocombat = true,
    }
    local setKeySides = {
        {
            label = "Left",
            value = "LEFT",
            onclick = function()
                GetDB().SetKeySide = "LEFT"
                if RRT_NS.Tools and RRT_NS.Tools.UpdateSetKeyVisibility then RRT_NS.Tools.UpdateSetKeyVisibility() end
            end,
        },
        {
            label = "Right",
            value = "RIGHT",
            onclick = function()
                GetDB().SetKeySide = "RIGHT"
                if RRT_NS.Tools and RRT_NS.Tools.UpdateSetKeyVisibility then RRT_NS.Tools.UpdateSetKeyVisibility() end
            end,
        },
    }
    opts[#opts+1] = {
        type   = "select",
        name   = "Attach Side",
        desc   = "Which side of the PVE frame the helper should use.",
        get    = function() return GetDB().SetKeySide or "LEFT" end,
        values = function() return setKeySides end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Offset X",
        desc = "Horizontal offset from the PVE frame.",
        min  = -150,
        max  = 150,
        step = 1,
        get  = function() return GetDB().SetKeyOffsetX end,
        set  = function(s, _, v)
            GetDB().SetKeyOffsetX = v
            if RRT_NS.Tools and RRT_NS.Tools.UpdateSetKeyVisibility then RRT_NS.Tools.UpdateSetKeyVisibility() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Offset Y",
        desc = "Vertical offset from the PVE frame.",
        min  = -200,
        max  = 200,
        step = 1,
        get  = function() return GetDB().SetKeyOffsetY end,
        set  = function(s, _, v)
            GetDB().SetKeyOffsetY = v
            if RRT_NS.Tools and RRT_NS.Tools.UpdateSetKeyVisibility then RRT_NS.Tools.UpdateSetKeyVisibility() end
        end,
    }
    opts[#opts+1] = { type = "breakline" }

    return opts
end

-- ═══════════════════════════════════════════════════════════════
-- 4. Class Tools
-- ═══════════════════════════════════════════════════════════════
local function BuildClassOptions()
    local opts = {}

    -- Spell Queue
    opts[#opts+1] = {
        type = "label",
        get  = function() return "Spell Queue Window" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Enable Spell Queue Auto-Set",
        desc     = "Automatically sets SpellQueueWindow CVar based on your latency and per-spec settings.",
        get      = function() return GetDB().SpellQueue end,
        set      = function(s, _, v)
            GetDB().SpellQueue = v
            if RRT_NS.Tools then RRT_NS.Tools.ApplySpellQueue() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "AI Mode (add world latency)",
        desc     = "Add your current world latency to the spell queue window value.",
        get      = function() return GetDB().SpellQueueAI end,
        set      = function(s, _, v)
            GetDB().SpellQueueAI = v
            if RRT_NS.Tools then RRT_NS.Tools.ApplySpellQueue() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Global Spell Queue Window (ms)",
        desc = "Default spell queue window in milliseconds (0-400). Per-spec values below override this.",
        min  = 0,
        max  = 400,
        step = 10,
        get  = function() return GetDB().SpellQueueGlobal end,
        set  = function(s, _, v)
            GetDB().SpellQueueGlobal = v
            if RRT_NS.Tools then RRT_NS.Tools.ApplySpellQueue() end
        end,
    }
    opts[#opts+1] = {
        type = "label",
        get  = function()
            return "|cFFAAAAAAPer-spec values below override the global. Set to 0 to use global for that spec.|r"
        end,
    }

    -- Per-spec groups
    local specGroups = {
        { label = "|cFFa0a0a0Plate — DK / Warrior / Paladin|r",
          specs = {250, 251, 252, 71, 72, 73, 65, 66, 70} },
        { label = "|cFFa0a0a0Mail — Hunter / Shaman / Evoker|r",
          specs = {253, 254, 255, 262, 263, 264, 1467, 1468, 1473} },
        { label = "|cFFa0a0a0Leather — DH / Rogue / Monk / Druid|r",
          specs = {577, 581, 1480, 259, 260, 261, 268, 269, 270, 102, 103, 104, 105} },
        { label = "|cFFa0a0a0Cloth — Mage / Warlock / Priest|r",
          specs = {62, 63, 64, 265, 266, 267, 256, 257, 258} },
    }

    for _, grp in ipairs(specGroups) do
        opts[#opts+1] = {
            type = "label",
            get  = function() return grp.label end,
        }
        for _, specID in ipairs(grp.specs) do
            local sid = specID
            opts[#opts+1] = {
                type = "range",
                name = SpecLabel(sid),
                desc = string.format("Spell queue window for spec %d. Set to 0 to use global.", sid),
                min  = 0,
                max  = 400,
                step = 10,
                get  = function()
                    local db = GetDB()
                    db.SpellQueueSpecs = db.SpellQueueSpecs or {}
                    return db.SpellQueueSpecs[sid] or 0
                end,
                set  = function(s, _, v)
                    local db = GetDB()
                    db.SpellQueueSpecs = db.SpellQueueSpecs or {}
                    db.SpellQueueSpecs[sid] = v
                    if RRT_NS.Tools then RRT_NS.Tools.ApplySpellQueue() end
                end,
            }
        end
    end

    opts[#opts+1] = { type = "breakline" }

    -- YY Sound
    opts[#opts+1] = {
        type = "label",
        get  = function() return "Bloodlust / Heroism Alert" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Enable Bloodlust Alert",
        desc     = "Play a sound and show an icon when Bloodlust, Heroism, Time Warp or similar is applied.",
        get      = function() return GetDB().YYSound end,
        set      = function(s, _, v)
            GetDB().YYSound = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshAll() end
        end,
        nocombat = true,
    }

    -- Sound dropdown
    local soundList = LSM and LSM:List("sound") or {}
    local soundValues = {}
    local focusSoundValues = {}
    local spellAlertSoundValues = {}
    for _, sname in ipairs(soundList) do
        local n = sname
        tinsert(soundValues, {
            label   = n,
            value   = n,
            onclick = function()
                GetDB().YYSoundFile = n
                if LSM then
                    local path = LSM:Fetch("sound", n)
                    if path then PlaySoundFile(path, "Master") end
                end
            end,
        })
        tinsert(focusSoundValues, {
            label   = n,
            value   = n,
            onclick = function()
                GetDB().FocusCastSound = n
                if LSM then
                    local path = LSM:Fetch("sound", n)
                    if path then PlaySoundFile(path, "Master") end
                end
            end,
        })
        tinsert(spellAlertSoundValues, {
            label   = n,
            value   = n,
            onclick = function()
                GetDB().SpellAlertSound = n
                if LSM then
                    local path = LSM:Fetch("sound", n)
                    if path then PlaySoundFile(path, "Master") end
                end
            end,
        })
    end
    if #soundValues > 0 then
        opts[#opts+1] = {
            type   = "select",
            name   = "Alert Sound",
            desc   = "Sound to play when Bloodlust is detected.",
            get    = function() return GetDB().YYSoundFile or "None" end,
            values = function() return soundValues end,
        }
    end

    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Show Bloodlust Icon",
        desc     = "Display a cooldown icon when Bloodlust is active.",
        get      = function() return GetDB().YYShowIcon end,
        set      = function(s, _, v)
            GetDB().YYShowIcon = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshYYSound() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Icon Size",
        desc = "Size of the Bloodlust icon in pixels.",
        min  = 30,
        max  = 120,
        step = 1,
        get  = function() return GetDB().YYIconSize end,
        set  = function(s, _, v)
            GetDB().YYIconSize = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshYYSound() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Icon Position X",
        desc = "Horizontal offset of the Bloodlust icon from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().YYPosX end,
        set  = function(s, _, v)
            GetDB().YYPosX = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshYYSound() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Icon Position Y",
        desc = "Vertical offset of the Bloodlust icon from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().YYPosY end,
        set  = function(s, _, v)
            GetDB().YYPosY = v
            if RRT_NS.Tools then RRT_NS.Tools.RefreshYYSound() end
        end,
    }
    opts[#opts+1] = { type = "breakline" }

    opts[#opts+1] = {
        type = "label",
        get  = function() return "Movement Cooldown Alert" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Enable No Move Skill Alert",
        desc     = "Show a text warning while Blink, Shimmer, Shadowstep or Grappling Hook is on cooldown.",
        get      = function() return GetDB().NoMoveSkillAlert end,
        set      = function(s, _, v)
            GetDB().NoMoveSkillAlert = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshNoMoveAlert then RRT_NS.Tools.RefreshNoMoveAlert() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Alert Font Size",
        desc = "Font size for the movement cooldown text.",
        min  = 12,
        max  = 48,
        step = 1,
        get  = function() return GetDB().NoMoveSkillAlertFontSize end,
        set  = function(s, _, v)
            GetDB().NoMoveSkillAlertFontSize = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshNoMoveAlert then RRT_NS.Tools.RefreshNoMoveAlert() end
        end,
    }
    opts[#opts+1] = {
        type = "input",
        name = "Mage Format",
        desc = "Use %t as the remaining cooldown placeholder for Blink/Shimmer.",
        get  = function() return GetDB().NoMoveSkillAlertMageFormat or "" end,
        set  = function(s, _, v) GetDB().NoMoveSkillAlertMageFormat = v end,
    }
    opts[#opts+1] = {
        type = "input",
        name = "Rogue Format",
        desc = "Use %t as the remaining cooldown placeholder for Step/Hook.",
        get  = function() return GetDB().NoMoveSkillAlertRogueFormat or "" end,
        set  = function(s, _, v) GetDB().NoMoveSkillAlertRogueFormat = v end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Alert Position X",
        desc = "Horizontal offset from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().NoMoveSkillAlertPosX end,
        set  = function(s, _, v)
            GetDB().NoMoveSkillAlertPosX = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshNoMoveAlert then RRT_NS.Tools.RefreshNoMoveAlert() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Alert Position Y",
        desc = "Vertical offset from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().NoMoveSkillAlertPosY end,
        set  = function(s, _, v)
            GetDB().NoMoveSkillAlertPosY = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshNoMoveAlert then RRT_NS.Tools.RefreshNoMoveAlert() end
        end,
    }
    opts[#opts+1] = { type = "breakline" }

    opts[#opts+1] = {
        type = "label",
        get  = function() return "Focus Cast" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Enable Focus Cast Bar",
        desc     = "Show a cast bar for your current focus target.",
        get      = function() return GetDB().FocusCast end,
        set      = function(s, _, v)
            GetDB().FocusCast = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshFocusCast then RRT_NS.Tools.RefreshFocusCast() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Show Focus Target Name",
        desc     = "Display the target of your focus cast if available.",
        get      = function() return GetDB().FocusCastShowTarget end,
        set      = function(s, _, v)
            GetDB().FocusCastShowTarget = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshFocusCast then RRT_NS.Tools.RefreshFocusCast() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Bar Width",
        desc = "Width of the focus cast bar.",
        min  = 140,
        max  = 420,
        step = 1,
        get  = function() return GetDB().FocusCastWidth end,
        set  = function(s, _, v)
            GetDB().FocusCastWidth = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshFocusCast then RRT_NS.Tools.RefreshFocusCast() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Bar Height",
        desc = "Height of the focus cast bar.",
        min  = 14,
        max  = 48,
        step = 1,
        get  = function() return GetDB().FocusCastHeight end,
        set  = function(s, _, v)
            GetDB().FocusCastHeight = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshFocusCast then RRT_NS.Tools.RefreshFocusCast() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Bar Position X",
        desc = "Horizontal offset from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().FocusCastPosX end,
        set  = function(s, _, v)
            GetDB().FocusCastPosX = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshFocusCast then RRT_NS.Tools.RefreshFocusCast() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Bar Position Y",
        desc = "Vertical offset from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().FocusCastPosY end,
        set  = function(s, _, v)
            GetDB().FocusCastPosY = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshFocusCast then RRT_NS.Tools.RefreshFocusCast() end
        end,
    }
    if #soundValues > 0 then
        opts[#opts+1] = {
            type   = "select",
            name   = "Focus Start Sound",
            desc   = "Sound played when your focus starts a cast.",
            get    = function() return GetDB().FocusCastSound or "None" end,
            values = function() return focusSoundValues end,
        }
    end
    opts[#opts+1] = { type = "breakline" }

    opts[#opts+1] = {
        type = "label",
        get  = function() return "Spell Overlay Alpha" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Enable Spell Effect Alpha",
        desc     = "Control SpellActivationOverlay opacity per spec.",
        get      = function() return GetDB().SpellEffectAlpha end,
        set      = function(s, _, v)
            GetDB().SpellEffectAlpha = v
            if RRT_NS.Tools and RRT_NS.Tools.UpdateSpellOverlayAlpha then RRT_NS.Tools.UpdateSpellOverlayAlpha() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Default Overlay Opacity",
        desc = "Default opacity percentage used when no per-spec override is set.",
        min  = 0,
        max  = 100,
        step = 1,
        get  = function() return GetDB().SpellEffectAlphaDefault end,
        set  = function(s, _, v)
            GetDB().SpellEffectAlphaDefault = v
            if RRT_NS.Tools and RRT_NS.Tools.UpdateSpellOverlayAlpha then RRT_NS.Tools.UpdateSpellOverlayAlpha() end
        end,
    }
    local overlaySpecIDs = {62, 63, 64, 259, 260, 261, 577, 581, 1467, 1468, 1473}
    for _, specID in ipairs(overlaySpecIDs) do
        local sid = specID
        opts[#opts+1] = {
            type = "range",
            name = "Overlay " .. SpecLabel(sid),
            desc = "Per-spec overlay opacity. Set to the same value as default if you do not need a custom override.",
            min  = 0,
            max  = 100,
            step = 1,
            get  = function() return (GetDB().SpellEffectAlphaSpecs or {})[sid] or GetDB().SpellEffectAlphaDefault end,
            set  = function(s, _, v)
                local db = GetDB()
                db.SpellEffectAlphaSpecs = db.SpellEffectAlphaSpecs or {}
                db.SpellEffectAlphaSpecs[sid] = v
                if RRT_NS.Tools and RRT_NS.Tools.UpdateSpellOverlayAlpha then RRT_NS.Tools.UpdateSpellOverlayAlpha() end
            end,
        }
    end
    opts[#opts+1] = { type = "breakline" }

    opts[#opts+1] = {
        type = "label",
        get  = function() return "Cast Sequence" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Enable Cast Sequence",
        desc     = "Show a rolling icon history of your recent successful spell casts.",
        get      = function() return GetDB().CastSequence end,
        set      = function(s, _, v)
            GetDB().CastSequence = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshCastSequence then RRT_NS.Tools.RefreshCastSequence() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Sequence Icon Size",
        desc = "Size of each icon in the cast sequence row.",
        min  = 18,
        max  = 64,
        step = 1,
        get  = function() return GetDB().CastSequenceSize end,
        set  = function(s, _, v)
            GetDB().CastSequenceSize = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshCastSequence then RRT_NS.Tools.RefreshCastSequence() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Sequence Icon Count",
        desc = "Number of recent spells kept on screen.",
        min  = 3,
        max  = 20,
        step = 1,
        get  = function() return GetDB().CastSequenceAmount end,
        set  = function(s, _, v)
            GetDB().CastSequenceAmount = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshCastSequence then RRT_NS.Tools.RefreshCastSequence() end
        end,
    }
    local sequenceDirections = {
        {
            label = "Right",
            value = "RIGHT",
            onclick = function()
                GetDB().CastSequenceGrow = "RIGHT"
                if RRT_NS.Tools and RRT_NS.Tools.RefreshCastSequence then RRT_NS.Tools.RefreshCastSequence() end
            end,
        },
        {
            label = "Left",
            value = "LEFT",
            onclick = function()
                GetDB().CastSequenceGrow = "LEFT"
                if RRT_NS.Tools and RRT_NS.Tools.RefreshCastSequence then RRT_NS.Tools.RefreshCastSequence() end
            end,
        },
    }
    opts[#opts+1] = {
        type   = "select",
        name   = "Sequence Direction",
        desc   = "Which direction new icons should grow.",
        get    = function() return GetDB().CastSequenceGrow or "RIGHT" end,
        values = function() return sequenceDirections end,
    }
    opts[#opts+1] = {
        type = "input",
        name = "Ignored Spell IDs",
        desc = "Comma-separated spell IDs to hide from the sequence.",
        get  = function() return GetDB().CastSequenceIgnored or "" end,
        set  = function(s, _, v)
            GetDB().CastSequenceIgnored = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshCastSequence then RRT_NS.Tools.RefreshCastSequence() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Sequence Position X",
        desc = "Horizontal offset from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().CastSequencePosX end,
        set  = function(s, _, v)
            GetDB().CastSequencePosX = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshCastSequence then RRT_NS.Tools.RefreshCastSequence() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Sequence Position Y",
        desc = "Vertical offset from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().CastSequencePosY end,
        set  = function(s, _, v)
            GetDB().CastSequencePosY = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshCastSequence then RRT_NS.Tools.RefreshCastSequence() end
        end,
    }
    opts[#opts+1] = { type = "breakline" }

    opts[#opts+1] = {
        type = "label",
        get  = function() return "Spell Alert" end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Enable Spell Alert",
        desc     = "Show a native icon/text alert when configured spells succeed.",
        get      = function() return GetDB().SpellAlert end,
        set      = function(s, _, v)
            GetDB().SpellAlert = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshSpellAlert then RRT_NS.Tools.RefreshSpellAlert() end
        end,
        nocombat = true,
    }
    opts[#opts+1] = {
        type = "input",
        name = "Watched Spell IDs",
        desc = "Comma-separated spell IDs that should trigger the alert.",
        get  = function() return GetDB().SpellAlertSpellIDs or "" end,
        set  = function(s, _, v)
            GetDB().SpellAlertSpellIDs = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshSpellAlert then RRT_NS.Tools.RefreshSpellAlert() end
        end,
    }
    opts[#opts+1] = {
        type = "input",
        name = "Alert Text",
        desc = "Use %spell to insert the spell name.",
        get  = function() return GetDB().SpellAlertText or "" end,
        set  = function(s, _, v) GetDB().SpellAlertText = v end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Alert Duration",
        desc = "How long the spell alert should remain visible.",
        min  = 0.2,
        max  = 8,
        step = 0.1,
        get  = function() return GetDB().SpellAlertDuration end,
        set  = function(s, _, v) GetDB().SpellAlertDuration = v end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Alert Icon Size",
        desc = "Size of the alert icon.",
        min  = 24,
        max  = 96,
        step = 1,
        get  = function() return GetDB().SpellAlertIconSize end,
        set  = function(s, _, v)
            GetDB().SpellAlertIconSize = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshSpellAlert then RRT_NS.Tools.RefreshSpellAlert() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Alert Position X",
        desc = "Horizontal offset from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().SpellAlertPosX end,
        set  = function(s, _, v)
            GetDB().SpellAlertPosX = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshSpellAlert then RRT_NS.Tools.RefreshSpellAlert() end
        end,
    }
    opts[#opts+1] = {
        type = "range",
        name = "Alert Position Y",
        desc = "Vertical offset from screen center.",
        min  = -1000,
        max  = 1000,
        step = 1,
        get  = function() return GetDB().SpellAlertPosY end,
        set  = function(s, _, v)
            GetDB().SpellAlertPosY = v
            if RRT_NS.Tools and RRT_NS.Tools.RefreshSpellAlert then RRT_NS.Tools.RefreshSpellAlert() end
        end,
    }
    if #soundValues > 0 then
        opts[#opts+1] = {
            type   = "select",
            name   = "Spell Alert Sound",
            desc   = "Sound played when one of the watched spells succeeds.",
            get    = function() return GetDB().SpellAlertSound or "None" end,
            values = function() return spellAlertSoundValues end,
        }
    end
    opts[#opts+1] = { type = "breakline" }

    return opts
end

-- ═══════════════════════════════════════════════════════════════
-- Export
-- ═══════════════════════════════════════════════════════════════
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.Tools = {
    BuildAutoToolsOptions  = BuildAutoToolsOptions,
    BuildMapDisplayOptions = BuildMapDisplayOptions,
    BuildMPlusOptions      = BuildMPlusOptions,
    BuildClassOptions      = BuildClassOptions,
    BuildCallback = function()
        return function()
            if RRT_NS.Tools then RRT_NS.Tools.RefreshAll() end
        end
    end,
}




