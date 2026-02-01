--- Wall Builder - Creates a rectangular perimeter wall
-- Place building materials in slots 1-14
-- @script wall

-- Path setup for require
local scriptPath = shell.getRunningProgram()
local absPath = "/" .. shell.resolve(scriptPath)
local scriptDir = absPath:match("(.+/)") or "/"
local rootDir = scriptDir ~= "/" and scriptDir:sub(1, -2):match("(.*/)" ) or "/"
package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path

local input = require("common.input")
local movement = require("common.movement")
local inventory = require("common.inventory")

-- Get dimensions from user
local width = input.readNumber("Width: ")
local length = input.readNumber("Length: ")
local height = input.readNumber("Height: ")

local slot = 1

local function checkAndFillSlot()
    slot = inventory.selectNextFilled(slot)
end

local function forwardAndDig()
    checkAndFillSlot()
    movement.forwardAndDig()
end

local function checkAndPlace()
    if not turtle.compareDown() then
        turtle.digDown()
    end
    checkAndFillSlot()
    turtle.placeDown()
end

local function makeWall(distance)
    for j = 1, distance do
        checkAndFillSlot()
        checkAndPlace()
        forwardAndDig()
    end
end

local function main()
    -- Place the first block where we start
    checkAndPlace()

    for i = 1, height do
        makeWall(width - 1)
        turtle.turnRight()
        makeWall(length - 1)
        turtle.turnRight()
        makeWall(width - 1)
        turtle.turnRight()
        makeWall(length - 1)
        turtle.turnRight()

        turtle.up()
    end

    print("Wall building complete!")
end

main()
