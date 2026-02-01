--- Area Digger - Excavates a rectangular volume
-- @script dig

-- Path setup for require
local scriptPath = shell.getRunningProgram()
local absPath = "/" .. shell.resolve(scriptPath)
local scriptDir = absPath:match("(.+/)") or "/"
local rootDir = scriptDir ~= "/" and scriptDir:sub(1, -2):match("(.*/)" ) or "/"
package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path

local input = require("common.input")
local movement = require("common.movement")
local fuel = require("common.fuel")
local logger = require("common.logger")

-- Get parameters from user
write("Dig up or down (u, d): ")
local direction = input.normalizeUpDown(read())
write("Dig to the left or right (l, r): ")
local turn = input.normalizeLeftRight(read())
local length = input.readNumber("Length: ")
local width = input.readNumber("Width: ")
local depth = input.readNumber("Depth/Height: ")

logger.logParams("dig", { direction = direction, turn = turn, length = length, width = width, depth = depth })

local function digUpOrDown()
    fuel.verifyFuelLevel()
    if direction == "up" then
        turtle.digUp()
    else
        turtle.digDown()
    end
end

local function adjustOrientation()
    fuel.verifyFuelLevel()
    if turn == "left" then
        turtle.turnLeft()
        movement.forwardAndDig()
        turtle.turnLeft()
        turn = "right"
    else
        turtle.turnRight()
        movement.forwardAndDig()
        turtle.turnRight()
        turn = "left"
    end
end

local function digLoop()
    for i = 1, depth do
        for j = 1, length do
            for k = 1, width - 1 do
                digUpOrDown()
                movement.forwardAndDig()
            end
            
            digUpOrDown()
            
            if j ~= length then
                adjustOrientation()
            end
        end
        
        fuel.verifyFuelLevel()
        
        if direction == "up" then
            turtle.up()
        else
            turtle.down()
        end
        
        if turn == "left" then
            turtle.turnLeft()
            turtle.turnLeft()
        else
            turtle.turnRight()
            turtle.turnRight()
        end
    end
end

local function positionBackToStart()
    for i = 1, depth do
        if direction == "up" then
            turtle.down()
        else
            turtle.up()
        end
    end
end

local function main()
    print("Digging " .. length .. "x" .. width .. "x" .. depth .. "...")
    digLoop()
    positionBackToStart()
    print("Digging complete!")
end

main()
