local _, RRT_NS = ... -- Internal namespace

local encID = 3180
local TYRS_WRATH_SPELL_ID = 1248721
local DISPEL_GLOW_TAG = "RRTDispelGlow"
local DISPEL_SCAN_INTERVAL = 0.1
local DISPEL_PRIORITY_HEALER = 1
local DISPEL_PRIORITY_WARLOCK = 2
local DISPEL_PRIORITY_DWARF = 3
local HEAL_ABSORB_SCAN_INTERVAL = 0.1

local function FormatHealAbsorbAmount(amount)
    amount = tonumber(amount) or 0
    if amount >= 1000000 then
        return string.format("%.1fm", amount / 1000000)
    end
    if amount >= 1000 then
        return string.format("%.0fk", amount / 1000)
    end
    return tostring(math.floor(amount + 0.5))
end

local function UnitHasVisiblePrivateAuraAnchor(anchorFrame)
    if not anchorFrame or not anchorFrame:IsShown() then
        return false
    end

    for i = 1, anchorFrame:GetNumChildren() do
        local child = select(i, anchorFrame:GetChildren())
        if child and child:IsShown() and child:GetAlpha() > 0 and child:GetWidth() > 0 and child:GetHeight() > 0 then
            return true
        end
    end

    return false
end

local function StopDispelGlowForUnit(self, unit)
    if not self.DispelGlowActiveUnits or not self.DispelGlowActiveUnits[unit] then
        return
    end

    self.DispelGlowActiveUnits[unit] = nil

    local unitFrame = self.LGF and self.LGF.GetUnitFrame and self.LGF.GetUnitFrame(unit)
    if unitFrame then
        local glowID = unit .. DISPEL_GLOW_TAG
        self.LCG.PixelGlow_Stop(unitFrame, glowID)
        if self.AllGlows then
            self.AllGlows[unitFrame] = nil
        end
    end
end

local function StopDispelGlowTracker(self)
    if self.DispelGlowTicker then
        self.DispelGlowTicker:Cancel()
        self.DispelGlowTicker = nil
    end

    if self.DispelGlowActiveUnits then
        for unit in pairs(self.DispelGlowActiveUnits) do
            StopDispelGlowForUnit(self, unit)
        end
    end

    if self.DispelGlowAnchorIDs then
        if InCombatLockdown() then
            self.DispelGlowCleanupPending = true
            return
        end

        for unit, anchorID in pairs(self.DispelGlowAnchorIDs) do
            if anchorID then
                pcall(C_UnitAuras.RemovePrivateAuraAnchor, anchorID)
            end
            self.DispelGlowAnchorIDs[unit] = nil
        end
    end
end

local function GetUnitSortIndex(unit)
    if unit == "player" then
        return 0
    end

    local raidIndex = unit:match("^raid(%d+)$")
    if raidIndex then
        return tonumber(raidIndex) or 999
    end

    local partyIndex = unit:match("^party(%d+)$")
    if partyIndex then
        return 40 + (tonumber(partyIndex) or 99)
    end

    return 999
end

local function GetDispelPriority(unit)
    if UnitGroupRolesAssigned(unit) == "HEALER" then
        return DISPEL_PRIORITY_HEALER
    end

    local _, classFileName = UnitClass(unit)
    if classFileName == "WARLOCK" then
        return DISPEL_PRIORITY_WARLOCK
    end

    local _, raceFileName = UnitRace(unit)
    if raceFileName and raceFileName:find("Dwarf") then
        return DISPEL_PRIORITY_DWARF
    end
end

local function GetAssignedDispelTarget(self)
    local dispellers = {}
    local targets = {}

    for unit, anchorID in pairs(self.DispelGlowAnchorIDs or {}) do
        local priority = GetDispelPriority(unit)
        if priority then
            dispellers[#dispellers + 1] = {
                unit = unit,
                priority = priority,
                order = GetUnitSortIndex(unit),
                isPlayer = UnitIsUnit(unit, "player"),
            }
        end

        if anchorID and UnitHasVisiblePrivateAuraAnchor(self.DispelGlowAnchors and self.DispelGlowAnchors[unit]) then
            targets[#targets + 1] = {
                unit = unit,
                order = GetUnitSortIndex(unit),
            }
        end
    end

    table.sort(dispellers, function(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end
        return a.order < b.order
    end)

    table.sort(targets, function(a, b)
        return a.order < b.order
    end)

    for index, dispeller in ipairs(dispellers) do
        if dispeller.isPlayer then
            return targets[index] and targets[index].unit or nil
        end
    end
end

local function StopHealAbsorbDisplayTracker(self)
    if self.HealAbsorbDisplayTicker then
        self.HealAbsorbDisplayTicker:Cancel()
        self.HealAbsorbDisplayTicker = nil
    end

    if self.HealAbsorbDisplayFrames then
        for _, frame in pairs(self.HealAbsorbDisplayFrames) do
            if frame then
                frame:Hide()
            end
        end
    end
end

local function StartHealAbsorbDisplayTracker(self)
    StopHealAbsorbDisplayTracker(self)

    if UnitGroupRolesAssigned("player") ~= "HEALER" then
        return
    end

    self.HealAbsorbDisplayFrames = self.HealAbsorbDisplayFrames or {}

    self.HealAbsorbDisplayTicker = C_Timer.NewTicker(HEAL_ABSORB_SCAN_INTERVAL, function()
        local activeUnits = {}

        for unit in self:IterateGroupMembers() do
            activeUnits[unit] = true

            local amount = 0
            if UnitGetTotalHealAbsorbs then
                local ok, value = pcall(UnitGetTotalHealAbsorbs, unit)
                if ok and value then
                    amount = value
                end
            end

            local textFrame = self.HealAbsorbDisplayFrames[unit]
            if amount > 0 then
                local unitFrame = self.LGF and self.LGF.GetUnitFrame and self.LGF.GetUnitFrame(unit)
                if unitFrame then
                    if not textFrame then
                        textFrame = CreateFrame("Frame", nil, unitFrame)
                        textFrame:SetFrameStrata("HIGH")
                        textFrame:SetAllPoints(unitFrame)
                        textFrame.Text = textFrame:CreateFontString(nil, "OVERLAY")
                        textFrame.Text:SetPoint("CENTER", unitFrame, "CENTER", 0, 0)
                        self.HealAbsorbDisplayFrames[unit] = textFrame
                    else
                        textFrame:ClearAllPoints()
                        textFrame:SetParent(unitFrame)
                        textFrame:SetAllPoints(unitFrame)
                        textFrame.Text:ClearAllPoints()
                        textFrame.Text:SetPoint("CENTER", unitFrame, "CENTER", 0, 0)
                    end

                    textFrame.Text:SetFont(self.LSM:Fetch("font", RRT.Settings.GlobalFont), 12, "OUTLINE")
                    textFrame.Text:SetTextColor(0.2, 1, 0.9, 1)
                    textFrame.Text:SetText(FormatHealAbsorbAmount(amount))
                    textFrame:Show()
                elseif textFrame then
                    textFrame:Hide()
                end
            elseif textFrame then
                textFrame:Hide()
            end
        end

        for unit, textFrame in pairs(self.HealAbsorbDisplayFrames) do
            if not activeUnits[unit] and textFrame then
                textFrame:Hide()
            end
        end
    end)
end

local function StartDispelGlowTracker(self)
    StopDispelGlowTracker(self)

    if not GetDispelPriority("player") then
        return
    end
    if self.Restricted and self:Restricted() then
        return
    end

    self.DispelGlowAnchors = self.DispelGlowAnchors or {}
    self.DispelGlowAnchorIDs = self.DispelGlowAnchorIDs or {}
    self.DispelGlowActiveUnits = {}
    self.DispelGlowLastAlert = {}
    self.AllGlows = self.AllGlows or {}

    for unit in self:IterateGroupMembers() do
        local unitFrame = self.LGF and self.LGF.GetUnitFrame and self.LGF.GetUnitFrame(unit)
        if unitFrame then
            local anchorFrame = self.DispelGlowAnchors[unit]
            if not anchorFrame then
                anchorFrame = CreateFrame("Frame", nil, unitFrame)
                self.DispelGlowAnchors[unit] = anchorFrame
            end

            anchorFrame:ClearAllPoints()
            anchorFrame:SetParent(unitFrame)
            anchorFrame:SetPoint("CENTER", unitFrame, "CENTER", 0, 0)
            anchorFrame:SetSize(1, 1)
            anchorFrame:SetAlpha(0.01)
            anchorFrame:Show()

            local ok, anchorID = pcall(C_UnitAuras.AddPrivateAuraAnchor, {
                unitToken = unit,
                spellID = TYRS_WRATH_SPELL_ID,
                parent = anchorFrame,
                showCountdownFrame = false,
                showCountdownNumbers = false,
                iconInfo = {
                    iconAnchor = {
                        point = "CENTER",
                        relativeTo = anchorFrame,
                        relativePoint = "CENTER",
                        offsetX = 0,
                        offsetY = 0,
                    },
                    borderScale = -100,
                    iconWidth = 1,
                    iconHeight = 1,
                },
            })
            if ok and anchorID then
                self.DispelGlowAnchorIDs[unit] = anchorID
            end
        end
    end

    if not next(self.DispelGlowAnchorIDs) then
        return
    end

    self.DispelGlowTicker = C_Timer.NewTicker(DISPEL_SCAN_INTERVAL, function()
        local assignedTarget = GetAssignedDispelTarget(self)

        for unit in pairs(self.DispelGlowActiveUnits or {}) do
            if unit ~= assignedTarget then
                StopDispelGlowForUnit(self, unit)
            end
        end

        if not assignedTarget or self.DispelGlowActiveUnits[assignedTarget] then
            return
        end

        local unitFrame = self.LGF and self.LGF.GetUnitFrame and self.LGF.GetUnitFrame(assignedTarget)
        if not unitFrame then
            return
        end

        local glowID = assignedTarget .. DISPEL_GLOW_TAG
        local glowSettings = RRT.ReminderSettings and RRT.ReminderSettings.GlowSettings or {}
        self.LCG.PixelGlow_Stop(unitFrame, glowID)
        self.LCG.PixelGlow_Start(
            unitFrame,
            glowSettings.colors or {0, 1, 0, 1},
            glowSettings.Lines or 10,
            glowSettings.Frequency or 0.2,
            glowSettings.Length or 10,
            glowSettings.Thickness or 4,
            glowSettings.xOffset or 0,
            glowSettings.yOffset or 0,
            true,
            glowID
        )
        self.AllGlows[unitFrame] = glowID
        self.DispelGlowActiveUnits[assignedTarget] = true

        local now = GetTime()
        if not self.DispelGlowLastAlert[assignedTarget] or (now - self.DispelGlowLastAlert[assignedTarget]) > 1.5 then
            self.DispelGlowLastAlert[assignedTarget] = now
            local name = RRTAPI:GetName(assignedTarget, "short") or UnitName(assignedTarget) or assignedTarget
            self:DisplayText("Dispel " .. name, 2)
            RRTAPI:TTS("Dispel " .. name)
        end
    end)
end

-- /run RRTAPI:DebugEncounter(3180)
RRT_NS.EncounterAlertStart[encID] = function(self, id) -- on ENCOUNTER_START
    if not RRT.EncounterAlerts[encID] then
        RRT.EncounterAlerts[encID] = {enabled = false}
    end
    id = id or self:DifficultyCheck(14) or 0
    if RRT.EncounterAlerts[encID].enabled then -- text, Type, spellID, dur, phase, encID
        local Alert = self:CreateDefaultAlert("Divine Toll", "Text", nil, 5, 1, encID)

        local timers = {
            [0] = {},
            [16] = {22, 40, 58, 76, 112, 130, 166, 184, 202, 220, 274, 292, 310, 328, 346, 364, 382},
        }
        for _, time in ipairs(timers[id] or {}) do
            Alert.time = time
            self:AddToReminder(Alert)
        end

        if UnitGroupRolesAssigned("player") == "TANK" then
            -- same timer on all difficulties for now
            Alert.TTS = false
            Alert.dur = 8
            Alert.text = "Peace Aura"
            local timers = {
                [0] = {},
                [16] = {132, 291, 450},
            }
            for _, time in ipairs(timers[id] or {}) do
                Alert.time = time
                self:AddToReminder(Alert)
            end

            Alert.text = "Devotion Aura"
            local timers = {
                [0] = {},
                [16] = {26, 184.7, 343.5},
            }
            for _, time in ipairs(timers[id] or {}) do
                Alert.time = time
                self:AddToReminder(Alert)
            end

            Alert.text = "Aura of Wrath"
            local timers = {
                [0] = {},
                [16] = {78.5, 237.5, 396.5},
            }
            for _, time in ipairs(timers[id] or {}) do
                Alert.time = time
                self:AddToReminder(Alert)
            end
        end
    end
    if RRT.EncounterAlerts[encID].HealAbsorbTicks then
        local timers = {
            [0] = {},
            [15] = {147.3, 324.4},
            [16] = {54.4, 162.6, 212.5, 322, 372, 481.5},
        }
        self.AlertTimers = self.AlertTimers or {}
        local dur = id == 16 and 20 or 15
        local Alert = self:CreateDefaultAlert("", "Bar", 1248721, dur, 1, encID) -- text, Type, spellID, dur, phase, encID, isAssignment
        Alert.TTS = false
        Alert.colors = "0 1 0 1"
        Alert.Ticks = id == 16 and {5, 10, 15} or {5, 10}
        if self:IsUsingTLAlerts() then
            for _, time in ipairs(timers[id] or {}) do
                Alert.time = time+dur
                self:AddToReminder(Alert)
            end
        else
            for i, v in ipairs(timers[id] or {}) do
                self.AlertTimers[i] = C_Timer.NewTimer(v, function()
                    local F = self:DisplayReminder(Alert)
                    if F then
                        if id == 16 then
                            self:AddTickToBar(F, 0.25)
                            self:AddTickToBar(F, 0.5)
                            self:AddTickToBar(F, 0.75)
                        else
                            self:AddTickToBar(F, 0.333)
                            self:AddTickToBar(F, 0.666)
                        end
                    end
                end)
            end
        end
    end

    if RRT.EncounterAlerts[encID].HealAbsorbDisplay then
        StartHealAbsorbDisplayTracker(self)
    else
        StopHealAbsorbDisplayTracker(self)
    end

    if RRT.EncounterAlerts[encID].TauntAlerts and UnitGroupRolesAssigned("player") == "TANK" then
        self.TauntFrame = self.TauntFrame or CreateFrame("Frame", nil, RRT_NS.RRTFrame, "BackdropTemplate")
        self.TauntFrame:SetSize(100, 30)
        self.TauntFrame.Text = self.TauntFrame.Text or self.TauntFrame:CreateFontString(nil, "OVERLAY")
        self.TauntFrame.Text:SetFont(self.LSM:Fetch("font", RRT.Settings.GlobalFont), RRT.Settings["GlobalEncounterFontSize"] or 50, "OUTLINE")
        self.TauntFrame.Text:SetText("Taunt")
        self.TauntFrame.Text:SetPoint("CENTER")
        self.TauntFrame.Text:Hide()
        local Taunts = {
            [115546] = true,
            [56222] = true,
            [185245] = true,
            [2649] = true,
            [6795] = true,
            [355] = true,
            [62124] = true,
            [49576] = true,
        }
        local timers = {
            [0] = {},
            [15] = {29, 71, 113, 127, 151, 191, 243, 303, 323, 346, 33, 75, 115, 131, 155, 175, 195, 247, 307, 327, 350}, -- cast success timers from wcl
            [16] = {25, 29, 61, 65, 115, 119, 151, 155, 169, 173, 223, 227, 277, 281, 313, 317, 331, 335, 385, 389, 439, 443}, -- cast success timers from wcl}
        }
        local blacklist = {}
        self.TauntFrame:SetScript("OnEvent", function(_, e, u, _, spellID)
            if e == "UNIT_SPELLCAST_START" then
                if not u:find("^nameplate%d") then return end
                local plate = C_NamePlate.GetNamePlateForUnit(u)
                if not plate then return end
                if blacklist[u] then return end -- meaning this unit has already casted in this timespan
                blacklist[u] = true
                -- threat check
                local threatLevel = UnitThreatSituation("player", u)
                local isTanking = threatLevel and threatLevel >= 2
                if isTanking then return end -- only alert if the mob is not
                self.TauntFrame:ClearAllPoints()
                self.TauntFrame:SetPoint("TOP", plate, "BOTTOM", 0, 0)
                self.TauntFrame.Text:Show()
                RRTAPI:TTS("Taunt")
                self.TauntTimersCancel = C_Timer.NewTimer(3, function()
                    self.TauntFrame.Text:Hide()
                    self.TauntTimersCancel = nil
                end)
                self.TauntFrame:UnregisterEvent("UNIT_SPELLCAST_START") -- unregister on first detection to help reduce false positives
            elseif e == "UNIT_SPELLCAST_SUCCEEDED" and Taunts[spellID] then
                if self.TauntTimersCancel then
                    self.TauntTimersCancel:Cancel()
                    self.TauntTimersCancel = nil
                end
                self.TauntFrame.Text:Hide()
            end
        end)
        self.TauntFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        for i, time in ipairs(timers[id] or {}) do
            time = time-3.5
            self.TauntTimers = self.TauntTimers or {}
            self.TauntTimers[i] = C_Timer.NewTimer(time, function()
                self.TauntFrame:RegisterEvent("UNIT_SPELLCAST_START")
                C_Timer.After(1, function()
                    self.TauntFrame:UnregisterEvent("UNIT_SPELLCAST_START")
                end)
                C_Timer.After(7, function()
                    blacklist = {}
                end)
            end)
        end
    end

    if RRT.EncounterAlerts[encID].DispelGlow then
        StartDispelGlowTracker(self)
    else
        StopDispelGlowTracker(self)
    end
end

RRT_NS.EncounterAlertStop[encID] = function(self) -- on ENCOUNTER_END
    if self.TauntTimers then
        for i, timer in pairs(self.TauntTimers) do
            timer:Cancel()
            self.TauntTimers[i] = nil
        end
    end
    if self.TauntFrame then
        self.TauntFrame:UnregisterEvent("UNIT_SPELLCAST_START")
        self.TauntFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        self.TauntFrame.Text:Hide()
    end
    if self.AlertTimers then
        for i, v in ipairs(self.AlertTimers) do
            if v and v.Cancel then
                v:Cancel()
            end
        end
        self.AlertTimers = nil
    end
    StopHealAbsorbDisplayTracker(self)
    StopDispelGlowTracker(self)
end

local dispelGlowCleanupFrame = CreateFrame("Frame")
dispelGlowCleanupFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
dispelGlowCleanupFrame:SetScript("OnEvent", function()
    if not RRT_NS.DispelGlowCleanupPending or not RRT_NS.DispelGlowAnchorIDs then
        return
    end

    RRT_NS.DispelGlowCleanupPending = nil
    for unit, anchorID in pairs(RRT_NS.DispelGlowAnchorIDs) do
        if anchorID then
            pcall(C_UnitAuras.RemovePrivateAuraAnchor, anchorID)
        end
        RRT_NS.DispelGlowAnchorIDs[unit] = nil
    end
end)

RRT_NS.AddAssignments[encID] = function(self, id) -- on ENCOUNTER_START
    if not (self.Assignments and self.Assignments[encID]) then return end
    if (not (id and id == 16)) and not self:DifficultyCheck(16) then return end -- Mythic only
    local subgroup = self:GetSubGroup("player")
    local Alert = self:CreateDefaultAlert("", nil, nil, nil, 1, encID, true) -- text, Type, spellID, dur, phase, encID
    local group = {}
    local healer = {}
    for unit in self:IterateGroupMembers() do
        local specID = RRTAPI:GetSpecs(unit) or 0
        local prio = self.spectable[specID]
        local G = self.GUIDS and self.GUIDS[unit] or ""
        if UnitGroupRolesAssigned(unit) == "HEALER" then
            table.insert(healer, {unit = unit, prio = prio, GUID = G})
        else
            table.insert(group, {unit = unit, prio = prio, GUID = G})
        end
    end
    self:SortTable(group)
    self:SortTable(healer)
    local mygroup
    local IsHealer = UnitGroupRolesAssigned("player") == "HEALER"
    if IsHealer then
        for i, v in ipairs(healer) do
            if UnitIsUnit("player", v.unit) then
                mygroup = i
            end
        end
    else
        for i, v in ipairs(group) do
            if UnitIsUnit("player", v.unit) then
                mygroup = math.ceil(i/4)
                mygroup = math.min(4, mygroup) -- if there are less than 4healers dps would overflow so put any extra in 4th
                break
            end
        end
    end
    if not mygroup then return end
    local pos = (mygroup == 1 and "Star") or (mygroup == 2 and "Orange") or (mygroup == 3 and "Purple") or (mygroup == 4 and "Green") or "Flex Spot"
    local text = (IsHealer and "Go to {rt"..mygroup.."}") or "Soak {rt"..mygroup.."}"
    local TTS = (IsHealer and "Go to "..pos) or "Soak "..pos
    Alert.TTS, Alert.TTSTimer, Alert.text = TTS, 10, text
    local phaselength = 162.7 -- guess based on Zealous Spirit in logs

    for phase = 0, 2 do
        Alert.time = 92 + (phase * phaselength)
        self:AddToReminder(Alert)
        if self:DifficultyCheck(16) then -- second cast is mythic only in case I want to support Heroic as well
            Alert.time = 149.2 + (phase * phaselength)
            self:AddToReminder(Alert)
        end
    end

    if RRT.AssignmentSettings.OnPull then
        local text = mygroup == 1 and "|cFFFFFF00Star|r" or mygroup == 2 and "|cFFFFA500Orange|r" or mygroup == 3 and "|cFF9400D3Purple|r" or mygroup == 4 and "|cFF00FF00Green|r" or ""
        self:DisplayText("You are assigned to soak |cFF00FF00Execution Sentence|r in the "..text.." Group", 5)
    end
end
