--- Path initialization module for turtle scripts
-- Fixes package.path to allow require() to find common modules
-- from any subdirectory.
--
-- Usage: Add at top of any script in a subdirectory:
--   require("common.init")
--
-- @module init

local scriptPath = shell and shell.getRunningProgram() or ""
local absPath = ""
if shell and scriptPath ~= "" then
    absPath = "/" .. shell.resolve(scriptPath)
end

local scriptDir = absPath:match("(.+/)") or "/"

local rootDir = "/"
if scriptDir ~= "/" then
    local withoutTrailing = scriptDir:sub(1, -2)
    rootDir = withoutTrailing:match("(.*/)" ) or "/"
end

package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path

return {
    rootDir = rootDir,
    scriptDir = scriptDir,
    scriptPath = absPath
}
