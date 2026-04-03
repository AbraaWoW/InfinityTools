local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local function GetDB()
    return RRT_NS.ExTools and RRT_NS.ExTools.GetDB() or {}
end

local function Refresh()
    if RRT_NS.ExTools then RRT_NS.ExTools.RefreshAll() end
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
            if v and RRT_NS.ExTools then RRT_NS.ExTools.InitBulkBuy() end
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
    opts[#opts+1] = {
        type     = "toggle",
        boxfirst = true,
        name     = "Reset Damage Meter on Instance Enter",
        desc     = "Prompts you to reset the damage meter (C_DamageMeter) when you enter an instance.",
        get      = function() return GetDB().ResetDMG end,
        set      = function(s, _, v) GetDB().ResetDMG = v end,
        nocombat = true,
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
            if RRT_NS.ExTools then RRT_NS.ExTools.InitMapInfo() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshRangeCheck() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshRangeCheck() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshRangeCheck() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshRangeCheck() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshPlayerPosition() end
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
                if RRT_NS.ExTools then RRT_NS.ExTools.RefreshPlayerPosition() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshPlayerPosition() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshPlayerPosition() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshPlayerPosition() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshAll() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshAll() end
        end,
        nocombat = true,
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
            if RRT_NS.ExTools then RRT_NS.ExTools.ApplySpellQueue() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.ApplySpellQueue() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.ApplySpellQueue() end
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
                    if RRT_NS.ExTools then RRT_NS.ExTools.ApplySpellQueue() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshAll() end
        end,
        nocombat = true,
    }

    -- Sound dropdown
    local soundList = LSM and LSM:List("sound") or {}
    local soundValues = {}
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshYYSound() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshYYSound() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshYYSound() end
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
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshYYSound() end
        end,
    }
    opts[#opts+1] = { type = "breakline" }

    return opts
end

-- ═══════════════════════════════════════════════════════════════
-- Export
-- ═══════════════════════════════════════════════════════════════
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.ExTools = {
    BuildAutoToolsOptions  = BuildAutoToolsOptions,
    BuildMapDisplayOptions = BuildMapDisplayOptions,
    BuildMPlusOptions      = BuildMPlusOptions,
    BuildClassOptions      = BuildClassOptions,
    BuildCallback = function()
        return function()
            if RRT_NS.ExTools then RRT_NS.ExTools.RefreshAll() end
        end
    end,
}
