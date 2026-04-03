---@diagnostic disable: undefined-global

InfinityBoss.Voice = InfinityBoss.Voice or {}
InfinityBoss.Voice.OtherSounds = InfinityBoss.Voice.OtherSounds or {}
local OtherSounds = InfinityBoss.Voice.OtherSounds

local TARGET_REMAINING = 5

local driverFrame = nil
local currentCountdown = nil

local function NormalizeSourceType(value)
    local sourceType = tostring(value or "pack"):lower()
    if sourceType ~= "lsm" and sourceType ~= "file" then
        sourceType = "pack"
    end
    return sourceType
end

local function EnsureConfigShape(cfg)
    if type(cfg) ~= "table" then
        cfg = {}
    end
    if cfg.enabled == nil then
        cfg.enabled = false
    end
    cfg.sourceType = NormalizeSourceType(cfg.sourceType)
    if type(cfg.label) ~= "string" then
        cfg.label = ""
    end
    if type(cfg.customLSM) ~= "string" then
        cfg.customLSM = ""
    end
    if type(cfg.customPath) ~= "string" then
        cfg.customPath = ""
    end
    return cfg
end

local function EnsureDB()
    InfinityBossDB = InfinityBossDB or {}
    InfinityBossDB.voice = InfinityBossDB.voice or {}
    InfinityBossDB.voice.global = InfinityBossDB.voice.global or {}
    local globalCfg = InfinityBossDB.voice.global
    globalCfg.otherSounds = type(globalCfg.otherSounds) == "table" and globalCfg.otherSounds or {}
    globalCfg.otherSounds.playerCountdown5 = EnsureConfigShape(globalCfg.otherSounds.playerCountdown5)
    return globalCfg.otherSounds
end

local function GetPlayerCountdown5Config()
    return EnsureDB().playerCountdown5
end

local function CancelCurrentCountdown()
    currentCountdown = nil
    if driverFrame then
        driverFrame:Hide()
    end
end

local function BuildSignature(initiatedBy, totalTime)
    return tostring(initiatedBy or "") .. "|" .. tostring(tonumber(totalTime) or 0)
end

local function EnsureDriverFrame()
    if driverFrame then
        return driverFrame
    end

    driverFrame = CreateFrame("Frame")
    driverFrame:Hide()
    driverFrame:SetScript("OnUpdate", function(self)
        local state = currentCountdown
        if not state then
            self:Hide()
            return
        end

        local now = GetTime and GetTime() or 0
        if now < (state.fireAt or 0) then
            return
        end

        if state.played == true then
            if now >= (state.endAt or 0) + 0.2 then
                CancelCurrentCountdown()
            end
            return
        end

        state.played = true
        state.fireAt = (state.endAt or now) + 0.2
        local ok, err = OtherSounds:TryPlayPlayerCountdown5(state.throttleKey or "misc:playerCountdown5:runtime")
        if not ok and err == "sound not found" then
        end
    end)
    return driverFrame
end

function OtherSounds:GetPlayerCountdown5Config()
    return GetPlayerCountdown5Config()
end

function OtherSounds:TryPlayPlayerCountdown5(throttleKey)
    local Engine = InfinityBoss and InfinityBoss.Voice and InfinityBoss.Voice.Engine
    local cfg = GetPlayerCountdown5Config()
    if not (Engine and Engine.TryPlayStandaloneSound and cfg) then
        return false, "voice engine unavailable"
    end
    if cfg.enabled ~= true then
        return false, "disabled"
    end
    return Engine:TryPlayStandaloneSound(cfg, tostring(throttleKey or "misc:playerCountdown5:runtime"), {
        triggerIndex = 2,
    })
end

function OtherSounds:CancelPlayerCountdown5()
    CancelCurrentCountdown()
end

function OtherSounds:HandleStartPlayerCountdown(_, initiatedBy, timeRemaining, totalTime)
    CancelCurrentCountdown()

    local cfg = GetPlayerCountdown5Config()
    if not cfg or cfg.enabled ~= true then
        return
    end

    local remaining = tonumber(timeRemaining) or 0
    if remaining <= 0 then
        return
    end

    local total = tonumber(totalTime) or remaining
    if total <= 0 then
        total = remaining
    end

    local now = GetTime and GetTime() or 0
    local signature = BuildSignature(initiatedBy, total)
    local throttleKey = "misc:playerCountdown5:" .. signature

    if remaining < (TARGET_REMAINING - 0.05) then
        return
    end

    if remaining <= (TARGET_REMAINING + 0.05) then
        self:TryPlayPlayerCountdown5(throttleKey)
        return
    end

    currentCountdown = {
        signature = signature,
        throttleKey = throttleKey,
        startedAt = now,
        endAt = now + remaining,
        fireAt = now + (remaining - TARGET_REMAINING),
        played = false,
    }
    EnsureDriverFrame():Show()
end

function OtherSounds:HandleStopPlayerCountdown()
    CancelCurrentCountdown()
end

if InfinityTools and not OtherSounds._eventsRegistered then
    InfinityTools:RegisterEvent("START_PLAYER_COUNTDOWN", "InfinityBossVoice.OtherSounds.StartPlayerCountdown", function(...)
        OtherSounds:HandleStartPlayerCountdown(...)
    end)
    InfinityTools:RegisterEvent("STOP_PLAYER_COUNTDOWN", "InfinityBossVoice.OtherSounds.StopPlayerCountdown", function()
        OtherSounds:HandleStopPlayerCountdown()
    end)
    InfinityTools:RegisterEvent("PLAYER_ENTERING_WORLD", "InfinityBossVoice.OtherSounds.PlayerEnteringWorld", function()
        OtherSounds:HandleStopPlayerCountdown()
    end)
    OtherSounds._eventsRegistered = true
end
