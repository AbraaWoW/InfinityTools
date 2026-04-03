local _, RRT_NS = ...

local Core = _G.RRTMythicTools
if not Core then
    return
end

Core.L = Core.L or setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})

Core.State = Core.State or {}
Core.PartySync = Core.PartySync or {}
Core.PartySpec = Core.PartySpec or {}
Core.UI = Core.UI or {}

function Core.UI:RefreshContent()
end

function Core:RegisterChatCommand(command, callback)
    if type(command) ~= "string" or command == "" or type(callback) ~= "function" then
        return
    end

    local slashName = "RRTMYTHIC_" .. command:gsub("%W", "_"):upper()
    _G["SLASH_" .. slashName .. "1"] = "/" .. command
    SlashCmdList[slashName] = callback
end

function Core:OpenSettingsPanel(moduleKey)
    self:OpenConfig(moduleKey)
end

Core.IsBeta = Core.IsBeta or false
Core.MAIN_FONT = Core.MAIN_FONT or STANDARD_TEXT_FONT

_G.RRTToolsCore = Core

