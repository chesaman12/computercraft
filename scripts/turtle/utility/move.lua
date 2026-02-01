--- Move Utility - Simple turtle movement script
-- @script move

-- Path setup for require
local scriptPath = shell.getRunningProgram()
local absPath = "/" .. shell.resolve(scriptPath)
local scriptDir = absPath:match("(.+/)") or "/"
local rootDir = scriptDir ~= "/" and scriptDir:sub(1, -2):match("(.*/)" ) or "/"
package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path

local movement = require("common.movement")
local input = require("common.input")
local logger = require("common.logger")

write("Direction (f,b,l,r,u,d): ")
local direction = read():lower()
local distance = input.readNumber("Distance: ")

logger.logParams("move", { direction = direction, distance = distance })
print("Moving " .. direction .. " x" .. distance .. "...")

if movement.move(direction, distance) then
    print("Movement complete!")
else
    print("Movement interrupted!")
end
