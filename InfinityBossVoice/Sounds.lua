---@diagnostic disable: undefined-global
-- Auto-generated, do not edit manually
-- Generated: 2026-03-18 08:19:23
-- InfinityBossVoice voice pack sound registration

local PACK_NAME = "Infinity (Default)"
local BASE_PATH  = "Interface\\AddOns\\InfinityBossVoice\Sounds\\"

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
if not LSM then return end

local SOUNDS = {
    { "Prepare AOE",          "prepare-aoe.ogg" },
    { "Prepare Beam",         "prepare-beam.ogg" },
    { "Prepare Interrupt",    "prepare-interrupt.ogg" },
    { "Prepare Pull",         "prepare-pull.ogg" },
    { "Prepare Block Line",   "prepare-block-line.ogg" },
    { "Prepare Soak",         "prepare-soak.ogg" },
    { "Prepare Clear Stack",  "prepare-clear-stack.ogg" },
    { "Prepare Target",       "prepare-target.ogg" },
    { "Prepare Arrow",        "prepare-arrow.ogg" },
    { "Prepare Enter Circle", "prepare-enter-circle.ogg" },
    { "Prepare Link",         "prepare-link.ogg" },
    { "Prepare Ball",         "prepare-ball.ogg" },
    { "Prepare Hook",         "prepare-hook.ogg" },
    { "Prepare Stack",        "prepare-stack.ogg" },
    { "Prepare Dispel",       "prepare-dispel.ogg" },
    { "Hit Clone",            "hit-clone.ogg" },
    { "Tank Buster",          "tank-buster.ogg" },
    { "Fix Camera",           "fix-camera.ogg" },
    { "Clear Water",          "clear-water.ogg" },
    { "Find Beacon",          "find-beacon.ogg" },
    { "Step Trap",            "step-trap.ogg" },
    { "None",                 "none.ogg" },
    { "Watch Knockback",      "watch-knockback.ogg" },
    { "Watch Frontal",        "watch-frontal.ogg" },
    { "Block Ball",           "block-ball.ogg" },
    { "Clear Ball",           "clear-ball.ogg" },
    { "Watch Dodge",          "watch-dodge.ogg" },
    { "Target Frontal",       "target-frontal.ogg" },
    { "Target Drop Water",    "target-drop-water.ogg" },
    { "Target Clear Line",    "target-clear-line.ogg" },
    { "Dodge Frontal",        "dodge-frontal.ogg" },
    { "Switch Add",           "switch-add.ogg" },
    { "Phase Change",         "phase-change.ogg" },
    { "Away Boss",            "away-boss.ogg" },
    { "Spread Close",         "spread-close.ogg" },
    { "Kite Add",             "kite-add.ogg" },
    { "Boss Enrage",          "boss-enrage.ogg" },
    { "Boss Vuln",            "boss-vuln.ogg" },
    { "You White",            "you-white.ogg" },
    { "You Black",            "you-black.ogg" },
    { "Prepare AOE Break",    "prepare-aoe-break.ogg" },
    { "Prepare Absorb Ball",  "prepare-absorb-ball.ogg" },
    { "Drop Water",           "drop-water.ogg" },
    { "Intercept Add",        "intercept-add.ogg" },
    { "Beam On You",          "beam-on-you.ogg" },
    { "Watch Shockwave",      "watch-shockwave.ogg" },
    { "Watch Launch",         "watch-launch.ogg" },
    { "Empower HPal",         "empower-hpal.ogg" },
    { "Empower Ret",          "empower-ret.ogg" },
    { "Empower Prot",         "empower-prot.ogg" },
    { "Spread Now",           "spread-now.ogg" },
    { "Interrupt Now",        "interrupt-now.ogg" },
    { "Rescue Now",           "rescue-now.ogg" },
    { "Break Shield",         "break-shield.ogg" },
    { "Enter Bubble",         "enter-bubble.ogg" },
    { "Break Link",           "break-link.ogg" },
    { "Vuln Burst",           "vuln-burst.ogg" },
    { "Use Defensive",        "use-defensive.ogg" },
    { "Watch Healing",        "watch-healing.ogg" },
    { "Special Mechanic",     "special-mechanic.ogg" },
    { "Switch Boss",          "switch-boss.ogg" },
    { "Away Add",             "away-add.ogg" },
    { "Stack Share",          "stack-share.ogg" },
    { "Countdown 5",          "countdown-5.ogg" },
    { "Countdown 4",          "countdown-4.ogg" },
    { "Countdown 3",          "countdown-3.ogg" },
    { "Countdown 2",          "countdown-2.ogg" },
    { "Countdown 1",          "countdown-1.ogg" },
}

for _, entry in ipairs(SOUNDS) do
    local label, file = entry[1], entry[2]
    LSM:Register("sound", "[" .. PACK_NAME .. "]" .. label, BASE_PATH .. file)
end
