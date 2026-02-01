--- House Builder - Builds a complete house with floor, walls, roof, and door
-- Place blocks in slots 1-14, fuel in slot 15 (optional), door in slot 16
-- Created by Kolacats (C) 2013 - GPL License
-- @script house

-- Path setup for require
local scriptPath = shell.getRunningProgram()
local absPath = "/" .. shell.resolve(scriptPath)
local scriptDir = absPath:match("(.+/)") or "/"
local rootDir = scriptDir ~= "/" and scriptDir:sub(1, -2):match("(.*/)" ) or "/"
package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path

local fuel = require("common.fuel")
local input = require("common.input")

print("House Builder by Kolacats")
print("Place blocks (1-14), fuel (15), door (16)")

-- Refuel option
if input.readYesNo("Refuel first? (y/n): ", false) then
    print("Refueling...")
    fuel.refuelFromInventory()
    print("Fuel level: " .. turtle.getFuelLevel())
end

local lw = input.readNumber("Length and width: ")
local h = input.readNumber("Height: ")

local oe = lw
lw = lw - 1

local n = 1
local r = 0

local function selectNextSlot()
    if turtle.getItemCount(n) < 1 then
        n = n + 1
        if n > 14 then n = 1 end
        turtle.select(n)
    end
end

local function floorWall()
    for i = 1, lw do
        turtle.digDown()
        turtle.placeDown()
        turtle.forward()
        selectNextSlot()
    end
end

local function wall()
    for i = 1, lw do
        turtle.forward()
        turtle.placeDown()
        selectNextSlot()
    end
end

local function floor()
    selectNextSlot()
    for i = 1, lw do
        floorWall()
        if r < 1 then
            turtle.turnLeft()
            turtle.forward()
            turtle.turnLeft()
            r = r + 1
        else
            turtle.turnRight()
            turtle.forward()
            turtle.turnRight()
            r = 0
        end
    end
end

local function walls()
    if (oe % 2) == 0 then
        turtle.up()
        wall()
        turtle.turnLeft()
        wall()
        turtle.turnLeft()
        wall()
        turtle.turnLeft()
        wall()
        turtle.turnLeft()
    else
        turtle.up()
        wall()
        turtle.turnRight()
        wall()
        turtle.turnRight()
        wall()
        turtle.turnRight()
        wall()
        turtle.turnRight()
    end
end

local function roof()
    selectNextSlot()
    for i = 1, lw do
        wall()
        if r < 1 then
            turtle.turnRight()
            turtle.forward()
            turtle.turnRight()
            r = r + 1
        else
            turtle.turnLeft()
            turtle.forward()
            turtle.turnLeft()
            r = 0
        end
    end
end

local function door()
    local halfLw = math.floor(lw / 2)
    turtle.turnLeft()
    for i = 1, halfLw do
        turtle.forward()
    end
    turtle.turnRight()
    turtle.dig()
    turtle.up()
    turtle.dig()
    turtle.down()
    turtle.select(16)
    turtle.place()
end

local function main()
    turtle.select(1)
    floor()
    
    for i = 1, h do
        walls()
    end
    
    roof()
    turtle.back()
    
    for i = 1, h do
        turtle.down()
    end
    
    door()
    
    -- Return to starting position
    turtle.turnRight()
    local halfLw = math.floor(lw / 2)
    for i = 1, halfLw do
        turtle.forward()
    end
    turtle.turnLeft()
    
    print("House complete!")
end

main()
