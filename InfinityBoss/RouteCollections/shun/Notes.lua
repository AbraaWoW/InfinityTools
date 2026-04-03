---@diagnostic disable: undefined-global
-- SHUN route pull notes (to be filled)

local Notes = InfinityBoss.MDT.Notes
if not Notes or type(Notes.Register) ~= "function" then return end

-- Example:
-- Notes.Register("shun_academy", {
--     [1] = "First pull note",
--     [2] = "Second pull note",
-- })
