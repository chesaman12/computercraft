--- Lava Refueler - Refuel turtle using lava bucket from tank below
-- Requires a bucket in inventory and lava tank placed below
-- @script lava_refuel

-- Path setup for require
local scriptPath = shell.getRunningProgram()
local absPath = "/" .. shell.resolve(scriptPath)
local scriptDir = absPath:match("(.+/)") or "/"
local rootDir = scriptDir ~= "/" and scriptDir:sub(1, -2):match("(.*/)" ) or "/"
package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path

local fuel = require("common.fuel")

local initialFuel = turtle.getFuelLevel()
print("Initial fuel level: " .. initialFuel)

local fuelLimit = turtle.getFuelLimit()
print("Fuel limit: " .. fuelLimit)

while turtle.getFuelLevel() < fuelLimit do
    if not fuel.refuelWithLava() then
        print("Refueling stopped")
        break
    end
    print("Current fuel level: " .. turtle.getFuelLevel())
end

local finalFuel = turtle.getFuelLevel()
print("Final fuel level: " .. finalFuel)
print("Fuel added: " .. (finalFuel - initialFuel))
