--- Stair Miner - Mines in a staircase pattern
-- @script stair_miner

-- Path setup for require
local scriptPath = shell.getRunningProgram()
local absPath = "/" .. shell.resolve(scriptPath)
local scriptDir = absPath:match("(.+/)") or "/"
local rootDir = scriptDir ~= "/" and scriptDir:sub(1, -2):match("(.*/)" ) or "/"
package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path

local input = require("common.input")
local movement = require("common.movement")
local logger = require("common.logger")

local function beginUp()
    movement.digUntilEmpty()
    turtle.forward()
    turtle.digDown()
    turtle.digUp()
    turtle.up()
    turtle.digUp()
end

local function beginDown()
    movement.digUntilEmpty()
    turtle.forward()
    turtle.digDown()
    turtle.down()
    turtle.digDown()
    turtle.down()
    turtle.digDown()
    turtle.down()
end

local function main()
    local distance = input.readNumber("Distance (digs forward and alternates up/down): ")
    
    logger.logParams("stair_miner", { distance = distance })
    print("Mining staircase for " .. distance .. " steps...")
    
    for i = 1, distance do
        if i % 2 == 0 then
            beginDown()
        else
            beginUp()
        end
    end
    
    print("Stair mining complete!")
end

main()
