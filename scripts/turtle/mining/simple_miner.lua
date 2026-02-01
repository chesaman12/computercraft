--- Simple Miner - Mines a 3D area with optional torch placement
-- Torches in slot 15 (optional), Fuel in slot 16 (optional)
-- @script simple_miner

-- Path setup for require
local scriptPath = shell.getRunningProgram()
local absPath = "/" .. shell.resolve(scriptPath)
local scriptDir = absPath:match("(.+/)") or "/"
local rootDir = scriptDir ~= "/" and scriptDir:sub(1, -2):match("(.*/)" ) or "/"
package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path

local input = require("common.input")
local fuel = require("common.fuel")

print("Torches in slot 15 (optional)")
print("Fuel in slot 16 (optional)")

local xSize = input.readNumber("Length (x): ")
local ySize = input.readNumber("Height (y): ")
local zSize = input.readNumber("Width (z, even numbers more efficient): ")

-- Direction tracking: 0 = South, 1 = West, 2 = North, 3 = East
local iDirection = 0
local xMovedFromOrigin = 0
local yMovedFromOrigin = 0
local zMovedFromOrigin = 0

local bHasTorches = turtle.getItemCount(15) > 0
local bHasFuel = turtle.getItemCount(16) > 0

local function checkFuel()
    if not bHasFuel then return true end
    
    if turtle.getFuelLevel() <= 10 then
        turtle.select(16)
        turtle.refuel(1)
    end
    
    if turtle.getFuelLevel() <= 1 then
        print("Out of fuel! Attempting emergency refuel...")
        shell.run("refuel", "all")
        if turtle.getFuelLevel() <= 1 then
            print("Still out of fuel. Waiting 120 seconds...")
            sleep(120)
            return false
        end
    end
    return true
end

local function moveForward()
    checkFuel()
    if turtle.forward() then
        if iDirection == 0 then
            zMovedFromOrigin = zMovedFromOrigin + 1
        elseif iDirection == 1 then
            xMovedFromOrigin = xMovedFromOrigin - 1
        elseif iDirection == 2 then
            zMovedFromOrigin = zMovedFromOrigin - 1
        elseif iDirection == 3 then
            xMovedFromOrigin = xMovedFromOrigin + 1
        end
        return true
    end
    return false
end

local function turnLeft()
    iDirection = (iDirection - 1) % 4
    if iDirection < 0 then iDirection = 3 end
    turtle.turnLeft()
end

local function turnRight()
    iDirection = (iDirection + 1) % 4
    turtle.turnRight()
end

local function moveUp()
    checkFuel()
    if turtle.up() then
        yMovedFromOrigin = yMovedFromOrigin + 1
        return true
    end
    return false
end

local function moveDown()
    checkFuel()
    if turtle.down() then
        yMovedFromOrigin = yMovedFromOrigin - 1
        return true
    end
    return false
end

local function placeTorch()
    if not bHasTorches or turtle.getItemCount(15) < 1 then return end
    
    local iSaveDirection = iDirection
    while iDirection ~= 2 do
        turnRight()
    end
    
    turtle.select(15)
    turtle.place()
    
    while iDirection ~= iSaveDirection do
        turnLeft()
    end
end

local function digUp(iBlocks)
    if iBlocks < 1 then return end
    for y = 1, iBlocks - 1 do
        while not moveUp() do
            turtle.digUp()
            turtle.suckUp()
        end
    end
end

local function digDown(iBlocks)
    if iBlocks < 1 then return end
    for y = 1, iBlocks - 1 do
        while not moveDown() do
            turtle.digDown()
            turtle.suckDown()
        end
    end
end

local function digForward()
    while not moveForward() do
        turtle.dig()
        turtle.suck()
    end
end

local function goHome()
    digDown(yMovedFromOrigin)
    
    if iDirection == 0 then
        turnRight()
        turnRight()
    elseif iDirection == 1 then
        turnRight()
    elseif iDirection == 3 then
        turnLeft()
    end
    
    for i = 1, zMovedFromOrigin do
        digForward()
    end
    turnLeft()
    
    for i = 1, xMovedFromOrigin do
        digForward()
    end
end

local function dumpInventory()
    write("Please collect items & press enter\n")
    read()
end

local function main()
    print("Mining " .. xSize .. "x" .. ySize .. "x" .. zSize)
    
    turnLeft()
    local zMax = math.floor(zSize / 2)
    
    for x = 1, xSize do
        for z = 1, zMax do
            digUp(ySize)
            digForward()
            digDown(ySize)
            
            if z < zMax then
                digForward()
            end
            
            -- Check inventory (slots 2-12)
            if turtle.getItemCount(12) >= 1 then
                print("~" .. math.floor(x / xSize * 100) .. "% complete, " .. turtle.getFuelLevel() .. " fuel")
                dumpInventory()
            end
        end
        
        -- Handle odd width
        if zSize % 2 ~= 0 then
            digForward()
            digUp(ySize)
            digDown(ySize)
        end
        
        -- Alternate direction
        if x % 2 ~= 0 then
            turnRight()
            digForward()
            turnRight()
        else
            turnLeft()
            digForward()
            turnLeft()
        end
        
        if x % 8 == 7 then
            placeTorch()
        end
    end
    
    print("Returning home...")
    goHome()
    dumpInventory()
    print("Mining complete!")
end

main()
