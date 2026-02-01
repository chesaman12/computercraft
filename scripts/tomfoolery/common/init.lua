--- Path initialization module for Tomfoolery scripts
-- This module fixes package.path to allow require() to find common modules
-- regardless of which directory the script is run from.
--
-- CC:Tweaked's require() resolves paths relative to the running script,
-- not relative to the current working directory. This module computes
-- the absolute root directory and adds it to package.path.
--
-- Usage: Add this at the top of any script that uses common modules:
--   require("common.init")  -- Only works if already at root
--   dofile("/path/to/common/init.lua")  -- Works from anywhere
--
-- @module init

-- Get the absolute path of the running script
local scriptPath = shell and shell.getRunningProgram() or ""
local absPath = ""
if shell and scriptPath ~= "" then
    absPath = "/" .. shell.resolve(scriptPath)
end

-- Extract the directory containing this script
-- e.g., "/mining/smart_miner.lua" -> "/mining/"
-- e.g., "/tomfoolery/mining/script.lua" -> "/tomfoolery/mining/"
local scriptDir = absPath:match("(.+/)") or "/"

-- Find the root directory (parent of common/, mining/, etc.)
local rootDir = "/"

if scriptDir ~= "/" then
    -- Remove trailing slash to work with the path
    local withoutTrailing = scriptDir:sub(1, -2)  -- "/mining" or "/tomfoolery/mining"
    
    -- Get the parent directory
    local parent = withoutTrailing:match("(.*/)" ) or "/"  -- "/" or "/tomfoolery/"
    
    -- If we're in common/, the parent is the root
    -- If we're in mining/, the parent is the root
    rootDir = parent
end

-- Add root directory to package path with ABSOLUTE paths
package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path

-- Return the root directory in case scripts need it
return {
    rootDir = rootDir,
    scriptDir = scriptDir,
    scriptPath = absPath
}
