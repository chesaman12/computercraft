--- Path initialization module for Tomfoolery scripts
-- This module fixes package.path to allow require() to find common modules
-- regardless of which directory the script is run from.
--
-- Usage: Add this at the top of any script that uses common modules:
--   require("common.init")  -- or dofile the full path
--
-- @module init

-- Get the directory of the running script
local scriptPath = shell and shell.getRunningProgram() or ""
local scriptDir = scriptPath:match("(.*/)" ) or ""

-- Find the root directory (parent of common/, mining/, etc.)
-- If we're in common/, go up one level
-- If we're in mining/, go up one level
-- If we're at root, stay there
local rootDir = ""

if scriptDir:match("common/$") then
    rootDir = scriptDir:match("(.*/)[^/]+/$") or ""
elseif scriptDir:match("[^/]+/$") then
    -- We're in a subdirectory like mining/
    rootDir = scriptDir:match("(.*/)[^/]+/$") or scriptDir
else
    rootDir = scriptDir
end

-- Add root directory to package path so require("common.xxx") works
if rootDir ~= "" then
    package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path
end

-- Also ensure current directory works
package.path = "?.lua;?/init.lua;" .. package.path

-- Return the root directory in case scripts need it
return {
    rootDir = rootDir,
    scriptDir = scriptDir,
    scriptPath = scriptPath
}
