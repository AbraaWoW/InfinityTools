---@diagnostic disable: undefined-global

local L = InfinityLocale and InfinityLocale.NewLocale("enUS")
if not L then return end

-- InfinityTools.lua — categories
L["Tools"] = true
L["M+ (Info)"] = true
L["M+ (Combat)"] = true
L["Class (General)"] = true

-- InfinityTools.lua — module names
L["Common Tools"] = true
L["M+ Utilities"] = true
L["Player Position Marker"] = true
L["Chat Channel Bar"] = true
L["Auto Purchase"] = true
L["MDT Spell Icon Replacement"] = true
L["M+ Score / Click Teleport"] = true
L["M+ Teleport Announce"] = true
L["M+ Spell Info Lookup"] = true
L["M+ Best Run (Tooltip)"] = true
L["M+ Season History"] = true
L["M+ Stats Panel"] = true
L["Spell Data (Internal)"] = true
L["M+ Damage Calculator"] = true
L["PvE Info Panel"] = true
L["Interrupt Tracker"] = true
L["Nearby Cast Monitor"] = true
L["Spell Queue Latency"] = true
L["Proc Transparency"] = true
L["Player Stats Monitor"] = true
L["Bloodlust Sound"] = true
L["Cast Sequence"] = true
L["Range Monitor"] = true
L["Movement CD Alert"] = true
L["Focus Cast Alert"] = true
L["PTR Toolbox"] = true
L["Quick Keystone (PTR)"] = true

-- InfinityTools.lua — module descriptions
L["Common feature bundle (auto-sell junk, chat log, delete confirm, etc.)"] = true
L["Collection of handy Mythic+ keystone utilities."] = true
L["Displays a marker at screen center, changes color when out of range."] = true
L["Toolbar for quickly switching chat channels."] = true
L["Automatically purchase specified items."] = true
L["Replaces mob portraits in MDT maps with spell icons."] = true
L["M+ icon, score, click-to-teleport enhancements."] = true
L["Chat announcements and alerts for M+ teleports."] = true
L["Spell info lookup and tooltip enhancements."] = true
L["M+ tooltip and interaction enhancements."] = true
L["Record and display M+ season history."] = true
L["M+ statistics panel and display."] = true
L["Internal data / spell database."] = true
L["Standalone UI to calculate actual spell damage by keystone level."] = true
L["Displays an extra info panel alongside the Dungeon Finder (PVEFrame)."] = true
L["Infer and track teammate interrupt cooldowns (supports 12.0)."] = true
L["Shows nearby mob cast bars with separate colors for interruptible and unbreakable casts."] = true
L["Automatically adjusts spell queue latency based on current spec."] = true
L["Automatically adjusts proc transparency based on current spec."] = true
L["Collect and display player combat stats."] = true
L["Plays a sound when a teammate triggers Bloodlust. (Beta)"] = true
L["Displays your cast sequence in real time with cast/channel/instant/interrupt state visualization."] = true
L["Displays target distance range in real time."] = true
L["Alerts when movement ability is on cooldown."] = true
L["Monitors focus target casting only, with independent cast bar and sound alerts."] = true
L["PTR-only convenience features (suppress feedback, one-click talent apply, etc.)"] = true
L["PTR: Quickly create or set keystones."] = true

-- InfinityToolsUI.lua — main panel
L["Dangerous: cannot be undone. Export a backup in Profile Manager first."] = true
L["Settings"] = true
L["Version: %s | Engine: GRID %s"] = true
L["Reload UI"] = true
L["Enable Edit Mode"] = true
L["Disable Edit Mode"] = true
L["Changelog"] = true

-- InfinityToolsUI.lua — sidebar
L["Home"] = true
L["Modules"] = true
L["Diagnostics"] = true
L["Profiles"] = true
L["disabled"] = true

-- InfinityToolsUI.lua — module manager
L["Module Manager"] = true
L["Click a card to enable/disable. Click Settings to configure. Changes require /reload."] = true
L["Enable All"] = true
L["Disable All"] = true
L["Disable"] = true
L["Enable"] = true

-- InfinityToolsUI.lua — modals
L["Reset all InfinityTools settings and reload?\n|cffff4444This cannot be undone!|r"] = true
L["Confirm Reset"] = true
L["Cancel"] = true

-- InfinityToolsUI.lua — home page
L["Zero deps - Event-driven - State bus - Grid layout"] = true
L["Version: "] = true
L["Open InfinityBoss"] = true
L["Use Modules to enable/disable features. Configure each module via its Grid panel."] = true
L["Info & Feedback"] = true
L["Author"] = true
L["Website"] = true
L["Discord"] = true
L["Click the box to select all and copy"] = true
L["Feedback"] = true
L["DM"] = true
L["NGA Link"] = true
L["Click to select all, Ctrl+C to copy"] = true
L["Quick Actions"] = true
L["These actions affect addon settings directly. Reset will wipe InfinityTools data and reload."] = true
L["Reset Settings"] = true
L["Hide Minimap Button"] = true
L["Tips"] = true
L["Use the Modules page to enable/disable modules. Changes take effect after /reload."] = true
L["Inside a module settings page, use the Grid panel to adjust styles, position, and toggles."] = true
L["Global edit mode: /ex edmode (drag HUD elements to reposition)."] = true
L["Author: Abraa"] = true
L["Twitch"] = true

-- InfinityToolsUI.lua — profiles page
L["Export Profile"] = true
L["Profile Name:"] = true
L["My Profile"] = true
L["Author:"] = true
L["Leave blank to use current name"] = true
L["Notes:"] = true
L["Select modules to export:"] = true
L["All"] = true
L["None"] = true
L["Generate Export String"] = true
L["Import Profile"] = true
L["Paste import string:"] = true
L["Parse & Preview"] = true
L["Select modules to import:"] = true
L["Apply Import"] = true

-- InfinityToolsUI.lua — diagnostics
L["[ Environment ]"] = true
L["Addon: |cff00ff00%s|r  |  WTF: |cff00ff00%d|r"] = true
L["Game: |cffffd100%s|r (Build: %s)"] = true
L["OS: |cffffd100%s (%s)|r  |  Region: |cffffd100%s|r  |  Locale: |cffffd100%s|r"] = true
L["PTR: %s  |  BETA: %s  |  ElvUI: %s"] = true
L["Time: |cffffd100%s|r"] = true
L["Yes"] = true
L["No"] = true
L["[ Current State ]"] = true
L["Class: |cff00ff00%s|r  |  Spec: |cff00ff00%s|r  |  Level: |cffffd100%d|r"] = true
L["Instance: %s  |  Type: |cffffd100%s|r  |  Combat: %s"] = true
L["MapID: |cffffd100%d|r  |  MapGroup: |cffffd100%d|r  |  InstanceID: |cffffd100%d|r"] = true
L["Boss: %s  |  BossID: |cffffd100%d|r"] = true
L["Party: %s  |  Raid: %s"] = true
L["[ Player Stats ]"] = true
L["Primary: STR: |cffffd100%d|r AGI: |cffffd100%d|r INT: |cffffd100%d|r STA: |cffffd100%d|r"] = true
L["Secondary: Crit: |cffffd100%.2f%%|r Haste: |cffffd100%.2f%%|r Mastery: |cffffd100%.2f%%|r Vers: |cffffd100%.2f%%|r"] = true
L["Tertiary: Leech: |cffffd100%.2f%%|r Avoid: |cffffd100%.2f%%|r Speed: |cffffd100%.2f%%|r Move: |cffffd100%d%%|r"] = true
L["Defense: Armor: |cffffd100%d|r Dodge: |cffffd100%.2f%%|r Parry: |cffffd100%.2f%%|r Block: |cffffd100%.2f%%|r"] = true
L["Other: iLvl: |cffffd100%.1f|r HP: |cffffd100%d|r"] = true
L["[ Libraries ]"] = true
L["[ Event Registry ]"] = true
L["No events registered"] = true
L["|cff00ff00%d|r events: %s"] = true
L["[ Module Status ]"] = true
L["OFF"] = true

-- InfinityToolsUI.lua — profiles (dynamic)
L["Untitled"] = true
L["Unknown"] = true
L["No notes"] = true
L["Export failed: "] = true
L["Unknown error"] = true
L["Parsed successfully! Found %d module(s)"] = true
L["Parse failed: "] = true
L["Please parse the import string first"] = true
L["No modules imported (none selected or data empty)"] = true
L["Export Successful"] = true
L["|cffffd100Ctrl+C|r to copy and close, or click |cffffd100Select All|r"] = true
L["Copied to clipboard"] = true
L["Select All"] = true
L["Close"] = true
L["Waiting for parse..."] = true
L["Preview:"] = true
L["Version: %s"] = true
L["not installed"] = true

-- InfinityToolsUI.lua — RESET_HINT (technical key, keep as-is)
L["RESET_HINT"] = "Dangerous: cannot be undone. Export a backup in Profile Manager first."

-- RevClass.RangeCheck.lua
L["Range Check"] = true
L["Displays the target distance range in real time and changes color based on the minimum distance."] = true
L["General Settings"] = true
L["Appearance"] = true
L["Show Distance Text"] = true
L["Font Size"] = true
L["Scale"] = true
L["Hide Distance Threshold"] = true
L["Hide when the target is beyond this range (100 = never hide)"] = true
L["Enable Shadow"] = true
L["Shadow X Offset"] = true
L["Shadow Y Offset"] = true
L["Range Format"] = true
L["Min-Only Format"] = true
L["Range format requires two %d values (min/max, e.g. %d - %d). Min-only format requires one %d+. Leave blank to use the default."] = true
L["Position"] = true
L["X Offset"] = true
L["Y Offset"] = true
L["Distance Colors"] = true
L["Automatically switches text color based on target distance. Each color maps to a distance bracket."] = true
L["< 5 yd"] = true
L[">= 5 yd"] = true
L[">= 10 yd"] = true
L[">= 15 yd"] = true
L[">= 20 yd"] = true
L[">= 30 yd"] = true
L[">= 40 yd"] = true
L["LibRangeCheck-3.0 not found. Module cannot function."] = true
L["Position reset."] = true

-- RevClass.NoMoveSkillAlert.lua
L["Shows an on-screen alert when movement abilities are on cooldown.|cffff0518Currently supports Mage/Rogue. More classes later.|r"] = true
L["Display Format (%t = time)"] = true
L["Decimal Threshold (sec)"] = true
L["|cff97a393Example: No Blink (%t) -> No Blink (12) or No Blink (3.2)|r"] = true
L["Alert Text|cffff140d (position set above)|r"] = true
L["Position X|cff0aff2a (edit here)|r"] = true
L["Position Y|cff0aff2a (edit here)|r"] = true
L["Rogue Settings"] = true
L["Shadowstep Format (%t = time)"] = true
L["Grappling Hook Format (%t = time)"] = true
L["Mage Settings"] = true

-- Shared drag/edit strings
L["Drag to reposition"] = true
L["Right-click to open settings"] = true
L["New Component"] = true

-- RevClass.FocusCast.lua
L["Show Cast Bar"] = true
L["Play alert sound|cffff2007 (plays on all casts; cannot filter by interruptability)|r"] = true
L["Sound Settings"] = true
L["Select Sound"] = true
L["Output Channel"] = true
L["Master"] = true
L["SFX"] = true
L["Ambience"] = true
L["Music"] = true
L["Dialog"] = true
L["Test Sound"] = true
L["Cast Bar Settings"] = true
L["Hide interruptible bars while interrupt is on cooldown"] = true
L["Show when interrupt cooldown is below this many seconds (left color)"] = true
L["Uninterruptible Color"] = true
L["Interrupt CD Color"] = true
L["Spell Alignment"] = true
L["Show Target"] = true
L["Target Alignment"] = true
L["Show Time"] = true
L["Time Alignment"] = true
L["|cffff080aHide non-interruptible bars|r"] = true
L["Bar Appearance"] = true
L["Spell Text"] = true
L["Spell Name"] = true
L["Target Text"] = true
L["Cast Target"] = true
L["Time Text"] = true
L["Remaining Time"] = true
L["Use custom file path (leave blank to use the selected sound above)"] = true
L["|cffafafafPath example: Interface\\AddOns\\Infinity\\sound\\Interrupt.mp3|r"] = true
L["Example: when interrupt cooldown reaches 2s, the bar uses the left color and changes when interrupt becomes ready."] = true
L["Focus Test Cast"] = true
L["Player"] = true

-- RevTools.YYSound.lua
L["Bloodlust Sound (YY Sound)"] = true
L["Plays a sound and countdown when Bloodlust/Heroism is gained. Beta feature."] = true
L["Icon Settings"] = true
L["Hide Icon"] = true
L["Unlock Drag"] = true
L["Use Blizzard Native Cooldown (lower CPU)"] = true
L["Spell ID (Preferred)"] = true
L["Icon Path/ID |cffff2628Spell ID takes priority if set|r"] = true
L["Size"] = true
L["|cff97a393Example: Interface\\AddOns\\InfinityMythicPlus\\Textures\\EJ-UI\\RV1.PNG|r"] = true
L["Reverse Cooldown"] = true
L["Built-in Sound"] = true
L["Use Custom Paths (1-6 below)"] = true
L["Play Random Entry"] = true
L["Sound (1)"] = true
L["Sound (2)"] = true
L["Sound (3)"] = true
L["Sound (4)"] = true
L["Sound (5)"] = true
L["Sound (6)"] = true
L["Test Actions"] = true
L["Test Effect"] = true
L["Stop Test"] = true

-- RevTools.PveInfoPanel.lua
L["Automatically attaches an info panel to the side of the PVE frame."] = true
L["Enable Module"] = true
L["Attach Side"] = true
L["Left"] = true
L["Right"] = true
L["Horizontal Offset (X)"] = true
L["Vertical Offset (Y)"] = true
L["Spells"] = true
L["Mythic+"] = true
L["History"] = true
L["Great Vault Summary"] = true
L["This Week's M+ Details"] = true
L["Operation"] = true
L["Saron"] = true
L["Pinnacle"] = true
L["Academy"] = true
L["Gale"] = true
L["Maw"] = true
L["Cavern"] = true
L["Nexus"] = true
L["Floodgate"] = true
L["Priory"] = true
L["Dawnbreaker"] = true
L["Echo"] = true
L["Eco-Dome"] = true
L["Atonement"] = true
L["Grand Design"] = true
L["Celestial Street"] = true

-- RevTools.StreamerTools.lua
L["Mythic+ Keystone"] = true
L["Auto Insert Keystone When Panel Opens"] = true

-- RevMplus.MythicCast.lua
L["Mythic Mob Casts (MythicCast)"] = true
L["Tracks cast progress on nameplate units in real time."] = true
L["Preview Mode"] = true
L["Overall Horizontal Position"] = true
L["Overall Vertical Position"] = true
L["Free Attach (Beta)"] = true
L["Attach the cast bar group to any UI element. Falls back to screen center if the target frame is missing."] = true
L["Enable Free Attach"] = true
L["Current Target Path"] = true
L["Pick With Mouse"] = true
L["Raid Markers"] = true
L["Show Raid Markers"] = true
L["Marker Size"] = true
L["Horizontal Offset"] = true
L["Vertical Offset"] = true
L["Grow Direction"] = true
L["Max Visible Bars"] = true
L["Font: Spell Name"] = true
L["Alignment"] = true
L["Spell Text Width"] = true
L["Font: Cast Target"] = true
L["Show Target Name"] = true
L["Merge Into Spell Name"] = true
L["Merge Format"] = true
L["Separator"] = true
L["Font: Cooldown Time"] = true
L["Show Time Text"] = true
L["M+ Cast Monitor"] = true
L["Test Cast "] = true
L["2.5s"] = true
L["Entered a 5-player instance. Cast monitor enabled."] = true

-- RevMplus.InterruptTracker.lua
L["Interrupt Tracker (Bars)"] = true
L["Tracks teammate interrupt cooldowns in real time (bar style)."] = true
L["Bars"] = true
L["Use Class Colors"] = true
L["Player Name"] = true
L["Show Player Name"] = true
L["Name Alignment"] = true
L["Player Name Text"] = true
L["Cooldown Time Settings"] = true
L["Show Remaining Time"] = true
L["Show Ready When Cooldown Ends"] = true
L["Ready Text"] = true
L["Time Text Settings"] = true
L["Sort Priority"] = true
L["When cooldown is ready, sort by role priority. While cooling down, sort by remaining time (shorter first)."] = true
L["Tank Priority"] = true
L["Healer Priority"] = true
L["DPS Priority"] = true
L["Melee DPS before Ranged DPS"] = true
L["Attach to Party Frames"] = true
L["Attach the interrupt bars above or below the party frame group."] = true
L["Enable Party Frame Attach"] = true
L["Target Frame"] = true
L["Attach to Target Frame"] = true
L["Auto Width"] = true
L["Interrupt Tracker Anchor"] = true

-- RevTools.CastSequence.lua
L["Displays your cast sequence in real time, including cast/channel/instant/interrupt states."] = true
L["Use global edit mode to move the frame"] = true
L["Show tooltip on hover"] = true
L["Spell Icon Settings"] = true
L["Icon Size"] = true
L["Icon Count"] = true
L["Frame Strata"] = true
L["Ignored Spells"] = true
L["Spell ID"] = true
L["Add / Remove"] = true
L["Show List"] = true
L["Clear List"] = true
L["Enter a Spell ID, then click Add/Remove. Ignored spells will not appear in the cast sequence."] = true

-- RevClass.SpellQueue.lua
L["Spell Queue Latency (SpellQueueWindow)"] = true
L["AI mode: queue window = latency + offset. Fixed mode: queue window = configured value."] = true
L["Current: %s|cff%s%s - %s|r | System: |cffffd100%sms|r"] = true
L["Core Controls"] = true
L["Enable Feature"] = true
L["Enable AI Smart Mode"] = true
L["Global Default Latency (Fixed)"] = true
L["Plate Classes"] = true
L["Mail Classes"] = true
L["Leather Classes"] = true
L["Cloth Classes"] = true
L["Global Latency Offset |cff00ffff(AI)|r"] = true
L["Switched to AI mode (queue window = latency + offset)"] = true
L["Switched to fixed manual mode (queue window = fixed value)"] = true

-- RevMplus.MythicDamage.lua
L["%.2fB"] = true
L["%dW"] = true
L["Current Level: |cffffd100%d|r\nSeason Coefficient (ID:%d): |cffffd100%.2f|r\nFinal Multiplier: |cff00ff00%.2f|r\n\nWhen enabled, spell description numbers are adjusted in real time by this multiplier."] = true
L["Mythic Damage Calc"] = true
L["Spell description values scale with keystone level."] = true
L["Core Settings"] = true
L["Color Numbers"] = true
L["Simulated Level (0-30)"] = true
L["Damage Number Color"] = true
L["M+ Mob Spells"] = true
L["Shorten Numbers (W/B)"] = true
L["Note: levels above 10 already include the 1.2x base modifier outside Tyrannical/Fortified.\nThis setting directly affects MDT enhancements and spell detail displays."] = true

-- RevMplusInfo.MDTIconHook.lua
L["None"] = true
L["Star (1)"] = true
L["Circle (2)"] = true
L["Diamond (3)"] = true
L["Triangle (4)"] = true
L["Moon (5)"] = true
L["Square (6)"] = true
L["Cross (7)"] = true
L["Skull (8)"] = true
L["MDT refreshed."] = true
L["MDT Spell Icon Hook"] = true
L["Supports spell icon replacement plus one-shot real raid markers written into the current MDT route."] = true
L["Custom Icons (NPCID = SpellID), one per line"] = true
L["Blacklisted NPCs (comma-separated IDs)"] = true
L["Save and Refresh (text config only applies after this)"] = true
L["Real Raid Markers (one-time write)"] = true
L["Writes into the current route when clicking the left/MDT buttons. It will not auto-overwrite or auto-clear."] = true
L["Interrupt Marker"] = true
L["Apply real markers to all interrupt mobs"] = true
L["Elite Marker"] = true
L["Apply real markers to all elite mobs"] = true
L["MDT not detected. Cannot write real markers."] = true
L["No current MDT route detected. Cannot write real markers."] = true
L["No MDT enemy data found for the current dungeon."] = true
L["Interrupt Mobs"] = true
L["Elite Mobs"] = true
L["Please select a valid raid marker first."] = true
L["Wrote MDT real markers for %s: added %d, skipped %d existing markers"] = true
L["Cleared all markers from the current MDT route."] = true
L["MDT Quick Actions"] = true

-- RevMplusInfo.RunHistory.lua
L["M+ Run History"] = true
L["View a table of your Mythic+ runs for the current season."] = true
L["Provides an on-demand detailed run history table. Use /emr to open it."] = true
L["Open Run History"] = true
L["Filters"] = true
L["This Week Only"] = true
L["Timed Runs Only"] = true
L["#"] = true
L["Dungeon (Level)"] = true
L["Date & Time"] = true
L["Result (Time)"] = true
L["Unknown Dungeon"] = true
L["No Time Data"] = true
L["Timed (%s left)"] = true
L["Overtime (%s over)"] = true

-- RevTools.ChatChannelBar.lua
L["A quick chat channel bar with customizable label, color, and command for each channel."] = true
L["A quick bar for switching chat channels."] = true
L["Lock Position"] = true
L["Reset Position"] = true
L["Button Spacing"] = true
L["Button Size"] = true
L["Attach To"] = true
L["Channel Settings"] = true
L["World"] = true
L["Say"] = true
L["Yell"] = true
L["Party"] = true
L["Guild"] = true
L["Raid"] = true
L["Roll"] = true
L["Ready Check"] = true
L["Pull"] = true
L["Label"] = true
L["Command"] = true
L["W"] = true
L["S"] = true
L["Y"] = true
L["P"] = true
L["G"] = true
L["I"] = true
L["R"] = true
L["D"] = true
L["RC"] = true
L["CD"] = true
L["C1"] = true
L["C2"] = true
L["C3"] = true
L["Custom 1"] = true
L["Custom 2"] = true
L["Custom 3"] = true
L["Chat Bar - Drag this box to move"] = true
L["Channel not found: "] = true
L["Command failed: "] = true

-- RevMplusInfo.Tooltip.lua
L["M+ Info Tooltips"] = true
L["Shows detailed run history, party specs, and dungeon teleport cooldown when hovering dungeon icons in the PVE challenge panel."] = true
L["Enable Tooltip Enhancements"] = true
L["Error: shared database not loaded!"] = true
L["%dh %dm"] = true
L["%dm %ds"] = true
L["%ds"] = true
L["Score: "] = true
L["Best Run"] = true
L["Level "] = true
L["%02d:%02d left"] = true
L["%02d:%02d over"] = true
L["Time "] = true
L["Party Members"] = true
L["Dungeon Timer: "] = true
L["Completed: %02d/%02d/%02d %02d:%02d"] = true
L["No run recorded this season"] = true
L["Teleport cooldown: "] = true
L["Teleport Ready"] = true

-- RevTools.AutoBuy.lua
L["Auto Buy"] = true
L["Automatically buys missing items from vendors up to your configured amount."] = true
L["Add Manually (Item ID)"] = true
L["Item ID"] = true
L["Add"] = true
L["Custom Buy List (drag supported)"] = true
L["Preset Items (enable/disable only)"] = true
L["Consumables"] = true
L["Keystone Tools"] = true
L["Dungeon Maps"] = true

-- RevMplusInfo.TeleMsg.lua
L["Teleport Announce"] = true
L["Teleport: Pit of Saron"] = true
L["Pit of Saron"] = true
L["|cffffd100Variables:|r\n  |cff00ff00%link|r = spell link\n  |cff00ff00%name|r = dungeon name"] = true
L["Announce Timing"] = true
L["Custom Message"] = true
L["Reset Message"] = true

-- RevMplusInfo.MythicIcon.lua
L["Mythic Icon Overlays"] = true
L["Overlays extra information on dungeon icons in the Mythic+ challenge panel."] = true
L["Display Options"] = true
L["Show Best Level (Center)"] = true
L["Show Dungeon Score (Bottom)"] = true
L["Text Style"] = true
L["Dungeon Name Style"] = true
L["Best Level Style"] = true
L["Dungeon Score Style"] = true
L["Custom Short Names (leave blank for default)"] = true
L["SR (161)"] = true
L["SEAT (239)"] = true
L["HoA (378)"] = true
L["Streets (391)"] = true
L["Gambit (392)"] = true
L["AA (402)"] = true
L["Priory (499)"] = true
L["Echoes (503)"] = true
L["Dawn (505)"] = true
L["Floodgate (525)"] = true
L["Eco (542)"] = true
L["POS (556)"] = true
L["WS (557)"] = true
L["MT (558)"] = true
L["NPX (559)"] = true
L["MC (560)"] = true
-- Short abbreviations (without IDs), used separately from long names
L["SEAT"] = true
L["POS"] = true
L["SR"] = true
L["AA"] = true
L["WS"] = true
L["MT"] = true
L["MC"] = true
L["NPX"] = true
L["Flood"] = true
L["Dawn"] = true
L["Echoes"] = true
L["Eco"] = true
L["HoA"] = true
L["Gambit"] = true
L["Streets"] = true

-- RevPTR.MiniTools.lua
L["Disable PTR feedback popups (Tooltip Issue Reporter)"] = true
L["Enable one-click profession spec learning"] = true
L["|cff808080* These features only work on Beta/PTR. The one-click learn button appears on the profession specialization page.|r"] = true
L["Profession specialization points maxed out (PTR mode)."] = true
L["No available specialization points to spend."] = true
L["Learn All"] = true

-- RevPTR.SetKey.lua
L["BETA Keystone Panel"] = true
L["A quick keystone setup panel attached to the left side of the PVE frame."] = true
L["Global X Offset"] = true
L["Global Y Offset"] = true
L["Icon Group Offset (adjust this instead of moving the frame)"] = true
L["Icon Group X"] = true
L["Icon Group Y"] = true
L["Current Keystone"] = true
L["Module X"] = true
L["Module Y"] = true
L["Current Text Style"] = true
L["Level Buttons"] = true
L["Horizontal Spacing"] = true
L["Number Font Style"] = true
L["Map Buttons"] = true
L["Vertical Spacing"] = true
L["Dungeon Font Style"] = true
L["Create Keystone"] = true

-- RevMplusInfoMythicFrame.lua
L["Mythic Dashboard"] = true
L["A full-screen immersive panel for Mythic+ analysis with live score, title-line gap, regional rank, Great Vault progress, and more."] = true
L["Open Dashboard"] = true
L["No Reward"] = true
L["Unknown Track"] = true
L["Hero 1/6"] = true
L["Hero 2/6"] = true
L["Hero 3/6"] = true
L["Hero 4/6"] = true
L["Myth 1/6"] = true
L["Season Run History"] = true
L["Advanced Analytics (Soon)"] = true
L["INFINITY Mythic Dashboard %s  |  Title data updated: %s  |  %s player count: %s"] = true
L["SEASON SCORE"] = true
L["Highest Key"] = true
L["Season Total"] = true
L["Dungeon"] = true
L["Best"] = true
L["Score"] = true
L["(Season) Total/Timed/Over"] = true
L["(Week) Total/Timed/Over"] = true
L["This Week's M+ Runs (Top 8)"] = true
L["Unknown Race"] = true
L["Loading..."] = true
L["Unequipped"] = true
L["Summary"] = true
L["Top %s%%"] = true
L["Rank %s"] = true
L["|cFFFFFFFF%s|r needs |cFF00FF00%.1f|r more score"] = true
L["Congratulations, you are already a title player!"] = true
L["Current title line (0.1%): "] = true
L["Not Reached"] = true

-- Shared missing keys
L["Position X"] = true
L["Position Y"] = true
L["Color"] = true
L["Outline"] = true
L["Instance"] = true
L["Chat Bar"] = true
L["Weekly Mythic+ Info"] = true
L["Only monitors your focus target's casts, with separate toggles for cast bar and alert sound."] = true
L["Components"] = true
L["The Vortex Pinnacle"] = true

-- RevClass.SpellEffectAlpha.lua
L["Spell Overlay Picker"] = true
L["Click any tile to write the config and trigger a test immediately."] = true
L["Filter ID"] = true
L["OverlayFileDataID: "] = true
L["Candidates: %d / %d"] = true
L["Choose Left/Right Overlay"] = true
L["Choose Top/Bottom Overlay"] = true
L["Spell Activation Overlay Opacity"] = true
L["Automatically adjusts spell activation overlay opacity based on your current spec."] = true
L["Current: %s|cff%s%s - %s|r | System: |cffffd100%d%%|r"] = true
L["Spell Overlay Adjustments"] = true
L["Global Default Opacity (%)"] = true
L["Enable |cffff173b(requires reload for safety)|r"] = true
L["Start Test"] = true
L["Global Scale"] = true
L["Global Horizontal (Y) Offset"] = true
L["Global Vertical (X) Offset"] = true
L["Overlay Scale"] = true
L["Left/Right Spacing"] = true
L["Top/Bottom Spacing"] = true
L["Pulse Magnitude (0 disables)"] = true
L["Pulse Speed"] = true
L["Fade-in Speed"] = true
L["Fade-out Speed"] = true
L["Choose Left/Right Texture (preview only)"] = true
L["Choose Top Test Texture (preview only)"] = true
L["Note: selected textures are only for preview tuning. All settings are global."] = true

-- InfinityGUI.lua — common controls
L["Select..."] = true
L["Select "] = true
L["Font"] = true
L["Select Texture"] = true
L["INFINITY Sounds"] = true
L["None selected"] = true
L["%d selected"] = true
L["Clear All"] = true
-- FontGroup
L["Text Color"] = true
L["Text Outline"] = true
L["Shadow X"] = true
L["Shadow Y"] = true
L["Thin"] = true
L["Thick"] = true
L["Monochrome"] = true
-- SoundGroup
L["Select Sound (LSM)"] = true
L["Channel"] = true
L["Use Custom Path"] = true
L["Example: Interface\\AddOns\\MySound\\test.ogg"] = true
-- VoiceGroup
L["Text Alert"] = true
L["Cast Start"] = true
L["5s Early"] = true
L["Voice Pack"] = true
L["LSM Sound"] = true
L["Custom Path"] = true
L["Alert"] = true
L["Source"] = true
L["Volume"] = true
L["Voice Settings"] = true
L["Path..."] = true
-- ItemConfig
L["Drag a consumable here to add"] = true
L["Qty"] = true
-- GlowSettings
L["Glow Style"] = true
L["Enable Glow"] = true
L["Classic"] = true
L["Pixel"] = true
L["AutoCast"] = true
L["Proc"] = true
L["Style"] = true
L["Glow Color"] = true
L["Frequency"] = true
L["Lines"] = true
L["Offset"] = true
L["Blink Speed"] = true
L["Flow Speed"] = true
L["Line Count"] = true
L["Line Width"] = true
L["Particles"] = true
L["Particle Size"] = true
-- IconGroup
L["Show Icon"] = true
L["Icon ID (optional)"] = true
L["Reverse CD"] = true
L["Width"] = true
L["Height"] = true
L["Icon Side"] = true
L["Icon X"] = true
L["Icon Y"] = true
-- TimerBarGroup
L["Timer Bar Settings"] = true
L["Texture"] = true
L["Foreground"] = true
L["Background"] = true
L["Border"] = true
L["Enable Border"] = true
L["Border Texture"] = true
L["Border Color"] = true
L["Border Size"] = true
L["Padding"] = true

-- RevTools.PlayerStats.lua
L["Player Stats Panel"] = true
L["Displays highly customizable player stats on screen (Haste, Versatility, Dodge, etc.)."] = true
L["Shows your character stats in real time. Right-click the widget to enter edit mode."] = true
L["Row "] = true
L["Main Stat"] = true
L["Auto"] = true
L["Str"] = true
L["Agi"] = true
L["Int"] = true
L["Secondary"] = true
L["Crit"] = true
L["Haste"] = true
L["Mast"] = true
L["Vers"] = true
L["Tertiary"] = true
L["Leech"] = true
L["Avoid"] = true
L["Move"] = true
L["Defense"] = true
L["Armor"] = true
L["Dodge"] = true
L["Parry"] = true
L["Block"] = true
L["Other"] = true
L["iLvl"] = true
L["HP"] = true
L["Dur"] = true
L["Player Stats"] = true
L["Show Background"] = true
L["Show Border"] = true
L["Background Texture"] = true
L["Background Color"] = true
L["Border Inset"] = true
L["Label Alignment"] = true
L["Value Alignment"] = true
L["Row Spacing"] = true
L["Global Label X"] = true
L["Global Value X"] = true
L["Stat Row Management"] = true
L["Select Row to Edit"] = true
L["Enable This Row"] = true
L["Stat"] = true
L["Decimals"] = true
L["Show Roles"] = true
L["Show Scenes"] = true
L["Sync Styles"] = true
L["Label Style"] = true
L["Value Style"] = true
L["N/A"] = true
L["New Stat"] = true
L["Name"] = true
L["Font Settings"] = true
L["Delete"] = true

-- RevTools.MiniTools.lua
L["Mini Tools"] = true
L["A toolbox of small and practical utility tweaks."] = true
L["A collection of small utility features. |cffff0000Note: changes usually require /reload to fully apply.|r"] = true
L["1. Map Info (optional ID + mouse/player coordinates)"] = true
L["Enable: show coordinates on the world map"] = true
L["Hide MapID"] = true
L["Anchor Position"] = true
L["2. Auto Delete Confirm"] = true
L["Enable: auto-fill 'DELETE' when deleting items"] = true
L["3. Auto Sell Junk"] = true
L["Enable: auto-sell gray items when opening a merchant"] = true
L["4. Auto Combat Log"] = true
L["5-player dungeon settings"] = true
L["Normal"] = true
L["Heroic"] = true
L["Mythic"] = true
L["Follower"] = true
L["Raid settings"] = true
L["LFR"] = true
L["5. Bulk Buy Assistant"] = true
L["Enable: Shift+Click to override merchant purchase"] = true
L["Require a confirmation popup when total cost exceeds this many gold"] = true
L["6. Reset Damage on Instance Entry"] = true
L["Enable: show a reset damage meter prompt when entering an instance"] = true
L["7. Override BattleTag"] = true
L["Enable: override BattleTag |cffff0c08(/rl required)|r"] = true
L["Enter name (leave blank to hide)"] = true
L["8. Auto Repair"] = true
L["Enable: automatically repair all gear when opening a merchant"] = true
L["Prefer guild bank repairs (pay yourself if guild funds are insufficient)"] = true
L["Show repair cost in chat after repairing"] = true
L["9. Adventure Guide Enhancements"] = true
L["Enable: show SpellID and full spell tooltip when hovering ability titles"] = true
L["10. Merchant UI Enhancements"] = true
L["Enable: widen the merchant frame (keep original height)"] = true
L["Columns"] = true
L["11. Macro UI Enhancements"] = true
L["Enable: macro UI enhancements |cffff1f13(beta, still under testing!)|r"] = true
L["MapID: %s"] = true
L["Mouse: %.2f, %.2f"] = true
L["Player: %.2f, %.2f"] = true
L["Mouse: %.2f, %.2f  Player: %.2f, %.2f"] = true
L["Entered instance, combat logging enabled automatically"] = true
L["Left instance, combat logging disabled automatically"] = true
L["Bulk Buy"] = true
L["Max Stack: "] = true
L["This purchase will cost %s\nBuy %s?"] = true
L["Buying..."] = true
L["Buy"] = true
L["item"] = true
L["%d x %s"] = true
L["Total: "] = true
L["Instance detected. Reset damage meter data?"] = true
L["Damage meter data has been reset"] = true
L["Error: C_DamageMeter.ResetAllCombatSessions API is unavailable"] = true
L["Repaired all gear using guild bank funds for %s"] = true
L["Automatically repaired all gear for %s"] = true
L["Search spell / icon ID"] = true
L["Mythic+ Party Keystones"] = true
L["Player Text Settings"] = true
L["Party Name Settings"] = true
L["Party Keystone Settings"] = true
L["No Cache"] = true
L["Waiting for Sync"] = true
L["Hidden"] = true
L["No Keystone"] = true
L["Show your and your party's keystone info on the PVEFrame."] = true
L["Displays your and party members' keystones on the PVEFrame."] = true
L["Party Member"] = true

-- Additional keys (variant forms from modules)
L["Preview"] = true
L["Time: |cffffd100%s|r"] = true

-- Placeholder strings
L["????"] = true
L["??: ????"] = true
