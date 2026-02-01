--- Simple Refuel - Refuel from all inventory slots
-- @script refuel

-- Path setup for require
local scriptPath = shell.getRunningProgram()
local absPath = "/" .. shell.resolve(scriptPath)
local scriptDir = absPath:match("(.+/)") or "/"
local rootDir = scriptDir ~= "/" and scriptDir:sub(1, -2):match("(.*/)" ) or "/"
package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path

local fuel = require("common.fuel")

local initialFuel = turtle.getFuelLevel()
print("Initial fuel level: " .. initialFuel)

if fuel.refuelFromInventory() then
    local finalFuel = turtle.getFuelLevel()
    print("Final fuel level: " .. finalFuel)
    print("Fuel added: " .. (finalFuel - initialFuel))
else
    print("No fuel items found in inventory")
end
