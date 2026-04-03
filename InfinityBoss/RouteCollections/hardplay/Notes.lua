---@diagnostic disable: undefined-global
-- Hardplay Vengeance route pull notes
-- Automatically loaded after the route is registered in Collection.lua
-- Format: InfinityBoss.MDT.Notes.Register(routeKey, { [pullIndex] = "note text", ... })

local Notes = InfinityBoss.MDT.Notes
if not Notes or type(Notes.Register) ~= "function" then return end

-- Algeth'ar Academy (hardplay_academy)
Notes.Register("hardplay_academy", {
    [1]  = "Use Bloodlust. Watch the bleed debuff and use Stoneform after mitigation ends.",
    [2]  = "Watch bleed stacks.",
    [3]  = "Watch bleed stacks.",
    [4]  = "Move along the left side. If you get an add, skip the 3 center mobs and recover count later.",
    [5]  = "After the big mob dies, start chain pulling.",
    [6]  = "After caster mobs die, start chain pulling.",
    [7]  = "Interrupt the devourer first. The textbook mob can be CC'd or dispelled.",
    [8]  = "Focus caster mobs. When the boss activates, remember to pull 2 Arcane Looters.",
    [9]  = "Remember to pull the 2 Arcane Looters.",
    [10] = "Focus caster mobs.",
    [11] = "Focus Echo Knights. AOE at 15s and 25s.",
})

-- Council Seat (hardplay_council)
Notes.Register("hardplay_council", {
    [1]  = "Use Bloodlust. Pull both left and right Conqueror packs.",
    [2]  = "During the boss, remember to pull one Shatterer pack, ideally at the start.",
    [3]  = "Watch the Guardian beam. Thick beam means damage amp, thin beam is normal.",
    [4]  = "Watch the Guardian beam. Thick beam means damage amp, thin beam is normal.",
    [5]  = "Pull Conquerors first, then stack on the caster mob at the end.",
    [6]  = "Watch the Guardian beam. Thick beam means damage amp, thin beam is normal.",
    [7]  = "Elite and Hunter left from pull 9.",
    [8]  = "Keep the Starver away from the center to avoid activating the boss.",
    [9]  = "Keep the Starver away from the center to avoid activating the boss.",
    [10] = "Use Bloodlust on boss.",
    [11] = "After the priority target dies, start chain pulling.",
    [12] = "After the priority target dies, start chain pulling.",
    [13] = "After the priority target dies, start chain pulling.",
    [14] = "If combining pulls, start 15 first, then start 16 after 5 seconds.",
    [15] = "If combining pulls, start 15 first, then start 16 after 5 seconds.",
    [16] = "",
})

-- Caves Route (hardplay_cave)
Notes.Register("hardplay_cave", {
    [1]  = "Rescue NPCs 1 and 2. Use Bloodlust. Avoid adding the lynx below.",
    [2]  = "Rescue NPCs 3 and 4. Consider having a teammate help pull the elephant.",
    [3]  = "Rescue NPC 5 and take the buff.",
    [4]  = "Rescue NPCs 6, 7, and 8.",
    [5]  = "Rescue NPCs 6, 7, and 8.",
    [6]  = "Avoid adding the lynx and elephant.",
    [7]  = "Pull 2 bears + mask with the boss. Use Stoneform on tank hits.",
    [8]  = "Pull 2 bears + mask with the boss. Use Stoneform on tank hits.",
    [9]  = "Use Bloodlust. Pull from the side to stack mobs and hold threat more easily.",
    [10] = "",
    [11] = "Tank solo interrupt on Soul Rend.",
    [12] = "Start chain pulling. Once the big mob/casters die, move into pull 13.",
    [13] = "When only the Defender remains, pull the shades, kill them, then start boss.",
    [14] = "When only the Defender remains, pull the shades, kill them, then start boss.",
    [15] = "",
    [16] = "",
    [17] = "",
})

-- Saronite Mine (hardplay_mine)
Notes.Register("hardplay_mine", {
    [1]  = "Use Bloodlust. Start by going bottom-left to pull the Ambusher, then rescue NPC 1.",
    [2]  = "Rescue NPC 2.",
    [3]  = "Rescue NPC 3. Watch ground effects and avoid extra pulls.",
    [4]  = "After the caster mob dies, you can start chain pulling.",
    [5]  = "Rescue NPC 4.",
    [6]  = "Move on the right side, watch bat patrols, and avoid extra pulls.",
    [7]  = "Rescue NPC 7.",
    [8]  = "Rescue NPC 8, then leave from the upper side.",
    [9]  = "Watch bat patrols while pulling small mobs.",
    [10] = "Chain pull and kill caster mobs.",
    [11] = "Chain pull and kill the Ambusher.",
    [12] = "Chain pull and kill the witch.",
    [13] = "You can consider killing the caster mob together with the elite.",
})

-- Nexus Route (hardplay_node)
Notes.Register("hardplay_node", {
    [1]  = "Sx pull. Do not get hit by Defenders on the path. Use a health pot if you drop low.",
    [2]  = "Transition cooldowns.",
    [3]  = "Pull the left Defender first. This is a pressure pull.",
    [4]  = "Start chain pulling and kill the Node Specialist first.",
    [5]  = "Start chain pulling and kill the Node Specialist first.",
    [6]  = "Sentinel hits the tank. Focus the Sentinel.",
    [7]  = "Transition pull.",
    [8]  = "Pull the right Commander first, wait for one cast, then stack mobs on that Commander.",
    [9]  = "Kill the large Disabler first to activate the event.",
    [10] = "Remember to pull the Ripper. If missed, you can consider bringing it into boss.",
    [11] = "Remember to pull the Ripper. If missed, you can consider bringing it into boss.",
    [12] = "Two tank busters, use mitigation.",
    [13] = "",
    [14] = "Focus Radiance. Chain pull and keep one big mob + one Radiance in each pull.",
    [15] = "Focus Radiance. Chain pull and keep one big mob + one Radiance in each pull.",
    [16] = "Focus Radiance. Chain pull and keep one big mob + one Radiance in each pull.",
})

-- The Vortex Pinnacle (hardplay_pinnacle)
Notes.Register("hardplay_pinnacle", {
    [1]  = "Use Bloodlust. Focus Dragonclaw Warriors.",
    [2]  = "Watch Wind Elemental AOE enrage at 30% HP.",
    [3]  = "Watch interrupts, 3 interrupts needed.",
    [4]  = "Two interrupts. Watch DoT stacks.",
    [5]  = "Do not activate both robots at the same time. Offset their timelines slightly.",
    [6]  = "Do not activate both robots at the same time. Offset their timelines slightly.",
    [7]  = "Control the unstoppable cast.",
    [8]  = "Focus Solar Elemental.",
    [9]  = "Focus Solar Elemental.",
    [10] = "Focus Dragonclaw Warrior.",
    [11] = "Focus Solar Elemental.",
})

-- Windrunner Tower (hardplay_wanderer)
Notes.Register("hardplay_wanderer", {
    [1]  = "Use Bloodlust. Make sure to drag mobs out of shields.",
    [2]  = "Start chain pulling. Kill caster mobs while moving down.",
    [3]  = "Control the dragonhawk.",
    [4]  = "",
    [5]  = "",
    [6]  = "When the big mob casts its unstoppable, it empowers nearby small mobs. Use mitigation.",
    [7]  = "Control the dragonhawk. You can activate the boss early.",
    [8]  = "Start chain pulling and kill caster mobs.",
    [9]  = "",
    [10] = "",
    [11] = "Be careful when opening Throat-Slasher + big mob together, second AOE lines up with Slasher combo.",
    [12] = "",
    [13] = "Start chain pulling, control shooter ground casts, focus the shooter.",
    [14] = "Start chain pulling and control shooter ground casts.",
    [15] = "Move on the right side and control Axe Throwers during caster AOE.",
    [16] = "",
})

-- Magister's Terrace (hardplay_mage)
Notes.Register("hardplay_mage", {
    [1]  = "Bloodlust recommended.",
    [2]  = "Start chain pulling once all caster mobs are dead.",
    [3]  = "Start chain pulling once all caster mobs are dead.",
    [4]  = "Mind the stack point and click the book for the haste buff.",
    [5]  = "Wait for the 110 patrol, do not add the center small mobs, and stack at the robot.",
    [6]  = "Floating dragon near boss, pull it on the second vulnerability window.",
    [7]  = "Floating dragon near boss, pull it on the second vulnerability window.",
    [8]  = "Start chain pulling and kill floating dragons + caster mobs.",
    [9]  = "Pull mobs inside and fight there.",
    [10] = "If Bloodlust is back up, you can consider chain pulling.",
    [11] = "If Bloodlust is back up, you can consider chain pulling.",
    [12] = "Focus caster mobs and chain pull.",
    [13] = "Chain CC during AOE and control Rippers.",
    [14] = "",
    [15] = "",
    [16] = "Brewmaster can use Bonedust Brew on Void Terror to reduce interrupt pressure. Terror can be brought into boss.",
    [17] = "",
    [18] = "Focus the Summoner.",
})
