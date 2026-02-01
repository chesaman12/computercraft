--- Block Builder - Creates a rectangular block shape
-- Place building materials in slots 1-14
-- @script block

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
local length = input.readNumber("Length: ")
local width = input.readNumber("Width: ")
local height = input.readNumber("Height: ")
write("Direction (l, r): ")
local turn = input.normalizeLeftRight(read())

local slot = 1

local function checkAndFillSlot()
    slot = inventory.selectNextFilled(slot)
end

local function forwardAndDig()
    checkAndFillSlot()
    movement.forwardAndDig()
end

local function adjustOrientation()
    if turn == "left" then
        turtle.turnLeft()
        forwardAndDig()
        turtle.turnLeft()
        turn = "right"
    else
        turtle.turnRight()
        forwardAndDig()
        turtle.turnRight()
        turn = "left"
    end
end

local function digAndPlace()
    if not turtle.compareDown() then
        turtle.digDown()
    end
    checkAndFillSlot()
    turtle.placeDown()
end

local function main()
    for i = 1, height do
        for j = 1, length do
            for k = 1, width - 1 do
                digAndPlace()
                forwardAndDig()
            end
            
            digAndPlace()
            
            if j ~= length then
                adjustOrientation()
            end
        end
        
        turtle.up()
        
        if turn == "left" then
            turtle.turnLeft()
            turtle.turnLeft()
        else
            turtle.turnRight()
            turtle.turnRight()
        end
    end
    
    print("Block building complete!")
end

main()
