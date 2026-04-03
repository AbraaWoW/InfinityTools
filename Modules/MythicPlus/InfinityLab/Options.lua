local _, RRT_NS = ...

local function GetTools()
    return _G.RRTMythicTools
end

local function ClickState(moduleKey, buttonKey)
    local tools = GetTools()
    if tools and tools.UpdateState then
        tools:UpdateState(moduleKey .. ".ButtonClicked", { key = buttonKey })
    end
end

local function SetState(moduleKey, stateKey, value)
    local tools = GetTools()
    if not tools then
        return
    end

    local db = tools:GetModuleDB(moduleKey, {})
    db[stateKey] = value
    tools:UpdateState(moduleKey .. ".DatabaseChanged", { key = stateKey, value = value })
end

local function ToggleState(moduleKey, stateKey)
    local tools = GetTools()
    if not tools then
        return
    end

    local db = tools:GetModuleDB(moduleKey, {})
    SetState(moduleKey, stateKey, not db[stateKey])
end

local function SetCombatPreview(moduleKey, enabled)
    SetState(moduleKey, "enabled", true)
    SetState(moduleKey, "locked", not enabled)
    SetState(moduleKey, "preview", enabled)
end

local function SetPartyKeystonePreview(enabled)
    SetState("ExTools.PveKeystoneInfo", "enabled", true)
    SetState("ExTools.PveKeystoneInfo", "previewMode", enabled)
end

local function OpenRunHistory()
    if _G.InfinityRunHistory and _G.InfinityRunHistory.ToggleWindow then
        _G.InfinityRunHistory:ToggleWindow()
        return
    end
    ClickState("ExM+Info.RunHistory", "open")
end

local function OpenDashboard()
    if _G.InfinitySpellInfo and _G.InfinitySpellInfo.ToggleFrame then
        _G.InfinitySpellInfo:ToggleFrame()
        return
    end
    ClickState("ExM+InfoMythicFrame", "open")
end

local function OpenSpellGuide()
    if _G.InfinitySpellInfo and not _G.InfinitySpellInfo.MainFrame and _G.InfinitySpellInfo.CreateMainFrame then
        _G.InfinitySpellInfo.CreateMainFrame()
    end
    if SlashCmdList and SlashCmdList["InfinitySpellInfo"] then
        SlashCmdList["InfinitySpellInfo"]()
    end
end

local function BuildInfinityLabOptions()
    local DF = _G["DetailsFramework"]
    local orange = DF and DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
    local opts = {}

    local function addHeader(text)
        opts[#opts + 1] = {
            type = "label",
            get = function()
                return text
            end,
            text_template = orange,
            spacement = true,
        }
    end

    local function addButton(name, callback, desc)
        opts[#opts + 1] = {
            type = "button",
            name = name,
            desc = desc,
            func = callback,
        }
    end

    addHeader("Infinity Lab")
    opts[#opts + 1] = {
        type = "label",
        get = function()
            return "|cFFAAAAAABoutons de preview directs et textes nettoyes pour les tests. Tes modules Mythic+ actuels restent dans l'onglet General.|r"
        end,
    }

    addHeader("Combat Previews")
    addButton("Interrupt Preview On", function() SetCombatPreview("ExM+.InterruptTracker", true) end, "Affiche le preview du tracker d'interrupt.")
    addButton("Interrupt Preview Off", function() SetCombatPreview("ExM+.InterruptTracker", false) end, "Masque le preview du tracker d'interrupt.")
    addButton("Cast Preview On", function() SetCombatPreview("ExM+.MythicCast", true) end, "Affiche le preview des casts Mythic+.")
    addButton("Cast Preview Off", function() SetCombatPreview("ExM+.MythicCast", false) end, "Masque le preview des casts Mythic+.")
    addButton("Party Keys Preview On", function() SetPartyKeystonePreview(true) end, "Affiche un preview des cles de groupe sur le panneau PVE.")
    addButton("Party Keys Preview Off", function() SetPartyKeystonePreview(false) end, "Masque le preview des cles de groupe.")

    addHeader("Windows")
    addButton("Open Run History", OpenRunHistory, "Ouvre l'historique de saison.")
    addButton("Open Mythic Dashboard", OpenDashboard, "Ouvre le tableau de bord Mythic+.")
    addButton("Open Spell Guide", OpenSpellGuide, "Ouvre le guide de sorts Mythic+.")

    addHeader("PVE Panel")
    addButton("Toggle Party Keys", function() ToggleState("ExTools.PveKeystoneInfo", "enabled") end, "Active ou desactive les cles de groupe sur le panneau PVE.")
    addButton("Toggle Icon Overlays", function() ToggleState("ExM+Info.MythicIcon", "enabled") end, "Active ou desactive les overlays sur les icones de donjon.")
    addButton("Toggle Tooltip Enhancer", function() ToggleState("ExM+Info.Tooltip", "enabled") end, "Active ou desactive les tooltips enrichis.")
    addButton("Toggle Teleport Message", function() ToggleState("ExM+Info.TeleMsg", "enabled") end, "Active ou desactive les messages de teleport.")
    addButton("Toggle MDT Hook", function() ToggleState("ExM+Info.MDTIconHook", "enabled") end, "Active ou desactive l'integration MDT.")

    addHeader("Notes")
    opts[#opts + 1] = {
        type = "label",
        get = function()
            return "|cFFAAAAAACertains textes internes des modules importes restent a nettoyer. Les previews et l'ouverture des fenetres sont maintenant accessibles ici.|r"
        end,
    }

    return opts
end

RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.MP_InfinityLab = {
    BuildOptions = BuildInfinityLabOptions,
    singleColumn = true,
    BuildCallback = function()
        return function()
        end
    end,
}
