--- Strip Miner - Mines main corridor with side branches (ladder pattern)
-- Configurable branch spacing, length, and inventory handling
-- Uses junklist.txt for automatic junk disposal
-- @script strip_miner

-- Path setup for require
local scriptPath = shell.getRunningProgram()
local absPath = "/" .. shell.resolve(scriptPath)
local scriptDir = absPath:match("(.+/)") or "/"
local rootDir = scriptDir ~= "/" and scriptDir:sub(1, -2):match("(.*/)" ) or "/"
package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path

local input = require("common.input")
local fuel = require("common.fuel")
local inventory = require("common.inventory")
local logger = require("common.logger")

local FUEL_SLOT = 16
local MAX_DIG_ATTEMPTS = 10

-- Default junk list
local defaultJunkList = table.concat({
    "minecraft:cobblestone",
    "minecraft:stone",
    "minecraft:granite",
    "minecraft:diorite",
    "minecraft:andesite",
    "minecraft:deepslate",
    "minecraft:cobbled_deepslate",
    "minecraft:tuff",
    "minecraft:calcite",
    "minecraft:basalt",
    "minecraft:blackstone",
    "minecraft:netherrack",
    "minecraft:end_stone",
    "minecraft:dirt",
    "minecraft:coarse_dirt",
    "minecraft:gravel",
    "minecraft:sand",
    "minecraft:red_sand",
    "minecraft:clay",
    "minecraft:sandstone",
    "minecraft:red_sandstone",
    "minecraft:dripstone_block",
    "minecraft:pointed_dripstone"
}, "\n")

local junkItems = inventory.loadJunkList("junklist.txt", defaultJunkList)

-- Position tracking
local posX = 0
local posZ = 0
local dir = 0

local totalSteps = 0
local currentStep = 0

-- Statistics tracking
local moveCount = 0
local turnCount = 0
local startTime = 0
local startFuel = 0
local canReturnHome = true
local showLogs = true

local function renderStatus()
    local pct = totalSteps > 0 and math.floor((currentStep / totalSteps) * 100) or 0
    local elapsedSec = startTime > 0 and math.floor((os.epoch("utc") - startTime) / 1000) or 0
    local fuelLevel = turtle.getFuelLevel()

    term.clear()
    term.setCursorPos(1, 1)
    print("=== Strip Miner Status ===")
    print(string.format("Progress: %d/%d (%d%%)", currentStep, totalSteps, pct))
    print(string.format("Position: x=%d z=%d dir=%d", posX, posZ, dir))
    if fuelLevel == "unlimited" then
        print("Fuel: Unlimited")
    else
        print(string.format("Fuel: %d", fuelLevel))
    end
    print(string.format("Moves: %d  Turns: %d", moveCount, turnCount))
    print(string.format("Elapsed: %ds", elapsedSec))
end

local function showProgress()
    if not showLogs then
        renderStatus()
        return
    end
    if totalSteps > 0 then
        local pct = math.floor((currentStep / totalSteps) * 100)
        term.clearLine()
        local x, y = term.getCursorPos()
        term.setCursorPos(1, y)
        write("Progress: " .. currentStep .. "/" .. totalSteps .. " (" .. pct .. "%)")
    end
end

local function turnLeft()
    turtle.turnLeft()
    dir = (dir + 3) % 4
    turnCount = turnCount + 1
    logger.debug("Turned left, now facing %d", dir)
end

local function turnRight()
    turtle.turnRight()
    dir = (dir + 1) % 4
    turnCount = turnCount + 1
    logger.debug("Turned right, now facing %d", dir)
end

local function turnAround()
    turnLeft()
    turnLeft()
end

local function turnTo(targetDir)
    if dir ~= targetDir then
        logger.debug("Turning from %d to %d", dir, targetDir)
    end
    while dir ~= targetDir do
        turnRight()
    end
end

local function updatePosition()
    if dir == 0 then
        posZ = posZ + 1
    elseif dir == 1 then
        posX = posX + 1
    elseif dir == 2 then
        posZ = posZ - 1
    else
        posX = posX - 1
    end
end

local function moveUpSafe()
    local attempts = 0
    while not turtle.up() do
        if turtle.detectUp() then
            turtle.digUp()
            turtle.suckUp()
        else
            sleep(0.2)
        end
        attempts = attempts + 1
        if attempts > MAX_DIG_ATTEMPTS then
            logger.error("Cannot move up at x=%d z=%d", posX, posZ)
            print("\nCannot move up.")
            return false
        end
    end
    moveCount = moveCount + 1
    return true
end

local function moveDownSafe()
    local attempts = 0
    while not turtle.down() do
        if turtle.detectDown() then
            turtle.digDown()
            turtle.suckDown()
        else
            sleep(0.2)
        end
        attempts = attempts + 1
        if attempts > MAX_DIG_ATTEMPTS then
            logger.error("Cannot move down at x=%d z=%d", posX, posZ)
            print("\nCannot move down.")
            return false
        end
    end
    moveCount = moveCount + 1
    return true
end

local function clearCeiling2()
    local attempts = 0
    while turtle.detectUp() do
        turtle.digUp()
        turtle.suckUp()
        sleep(0.2)
        attempts = attempts + 1
        if attempts > MAX_DIG_ATTEMPTS then
            logger.error("Stuck on unbreakable block above at x=%d z=%d", posX, posZ)
            print("\nStuck on unbreakable block above.")
            return false
        end
    end

    if not moveUpSafe() then
        return false
    end

    attempts = 0
    while turtle.detectUp() do
        turtle.digUp()
        turtle.suckUp()
        sleep(0.2)
        attempts = attempts + 1
        if attempts > MAX_DIG_ATTEMPTS then
            logger.error("Stuck on unbreakable block above (level 2) at x=%d z=%d", posX, posZ)
            print("\nStuck on unbreakable block above.")
            if not moveDownSafe() then
                logger.error("Cannot return to ground at x=%d z=%d", posX, posZ)
                print("\nCannot return to ground.")
                canReturnHome = false
            end
            return false
        end
    end

    if not moveDownSafe() then
        logger.error("Cannot return to ground at x=%d z=%d", posX, posZ)
        print("\nCannot return to ground.")
        canReturnHome = false
        return false
    end

    return true
end

local function moveForward1x3()
    local attempts = 0
    while turtle.detect() do
        logger.debug("Digging ahead at x=%d z=%d", posX, posZ)
        turtle.dig()
        turtle.suck()
        sleep(0.2)
        attempts = attempts + 1
        if attempts > MAX_DIG_ATTEMPTS then
            logger.error("Stuck on unbreakable block ahead at x=%d z=%d", posX, posZ)
            print("\nStuck on unbreakable block ahead.")
            return false
        end
    end

    attempts = 0
    while not turtle.forward() do
        if turtle.detect() then
            logger.debug("Obstacle appeared, digging at x=%d z=%d", posX, posZ)
            turtle.dig()
            turtle.suck()
        else
            sleep(0.2)
        end
        attempts = attempts + 1
        if attempts > MAX_DIG_ATTEMPTS then
            logger.error("Cannot move forward at x=%d z=%d", posX, posZ)
            print("\nCannot move forward.")
            return false
        end
    end

    updatePosition()
    moveCount = moveCount + 1
    logger.debug("Moved forward to x=%d z=%d", posX, posZ)
    return clearCeiling2()
end

local function moveForwardSafe()
    local attempts = 0
    while not turtle.forward() do
        if turtle.detect() then
            logger.debug("Obstacle while returning, digging at x=%d z=%d", posX, posZ)
            turtle.dig()
            turtle.suck()
        else
            sleep(0.2)
        end
        attempts = attempts + 1
        if attempts > MAX_DIG_ATTEMPTS then
            logger.error("Cannot move forward (safe) at x=%d z=%d", posX, posZ)
            print("\nCannot move forward.")
            return false
        end
    end
    updatePosition()
    moveCount = moveCount + 1
    logger.debug("Moved forward (safe) to x=%d z=%d", posX, posZ)
    return true
end

local function goTo(x, z, targetDir)
    logger.debug("goTo: from x=%d z=%d to x=%d z=%d", posX, posZ, x, z)
    if posZ < z then
        turnTo(0)
        for i = 1, (z - posZ) do
            if not moveForwardSafe() then return false end
        end
    elseif posZ > z then
        turnTo(2)
        for i = 1, (posZ - z) do
            if not moveForwardSafe() then return false end
        end
    end

    if posX < x then
        turnTo(1)
        for i = 1, (x - posX) do
            if not moveForwardSafe() then return false end
        end
    elseif posX > x then
        turnTo(3)
        for i = 1, (posX - x) do
            if not moveForwardSafe() then return false end
        end
    end

    if targetDir ~= nil then
        turnTo(targetDir)
    end
    logger.debug("goTo: arrived at x=%d z=%d", posX, posZ)
    return true
end

local function dropJunk()
    inventory.dropJunk(junkItems, FUEL_SLOT)
end

local function dumpToChestBehindStart()
    turnAround()
    if not turtle.detect() then
        print("\nNo chest behind start. Place one and press enter.")
        read()
    end
    inventory.dumpToChest(FUEL_SLOT)
    turnAround()
end

local function returnToChestAndBack()
    local targetX = posX
    local targetZ = posZ
    local targetDir = dir
    local distanceHome = math.abs(posX) + math.abs(posZ)

    logger.debug("Returning to chest from x=%d z=%d (distance=%d)", posX, posZ, distanceHome)
    if not fuel.ensureFuel(distanceHome * 2 + 10) then
        return false
    end

    goTo(0, 0, 0)
    dumpToChestBehindStart()
    logger.debug("Dumped inventory, returning to x=%d z=%d", targetX, targetZ)
    goTo(targetX, targetZ, targetDir)
    return true
end

local function ensureInventorySpace(fullMode)
    if not inventory.isFull() then
        return true
    end

    logger.debug("Inventory full at x=%d z=%d, dropping junk", posX, posZ)
    dropJunk()
    if not inventory.isFull() then
        return true
    end

    if fullMode == 2 then
        logger.info("Inventory full, returning to chest")
        return returnToChestAndBack()
    elseif fullMode == 3 then
        return true
    end

    logger.info("Inventory full, waiting for user")
    print("\nInventory full. Remove items and press enter.")
    read()
    return true
end

local function checkFuelPeriodic()
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" then
        return true
    end
    local distanceHome = math.abs(posX) + math.abs(posZ)
    if fuelLevel < distanceHome + 20 then
        logger.warn("Fuel low (%d), returning home from x=%d z=%d", fuelLevel, posX, posZ)
        print("\nFuel low. Returning home.")
        goTo(0, 0, 0)
        print("Out of fuel. Refuel and restart.")
        return false
    end
    return true
end

local function mineForward(fullMode)
    if not moveForward1x3() then return false end
    ensureInventorySpace(fullMode)
    currentStep = currentStep + 1
    showProgress()
    if not checkFuelPeriodic() then return false end
    return true
end

--- Symmetric grid: perimeter rectangle + interior corridors
-- Creates a clean rectangular shape with all corridors connected at both ends
-- @param mineRight boolean: true = mine to the right (+X), false = mine to the left (-X)
local function mineSymmetricGrid(corridorLength, corridorCount, gap, fullMode, mineRight)
    local shift = gap + 1
    local maxX = (corridorCount - 1) * shift
    
    -- Direction constants based on mineRight
    local sideDir = mineRight and 1 or 3    -- +X or -X
    local backDir = mineRight and 3 or 1    -- -X or +X
    
    logger.debug("Mining symmetric grid: length=%d, corridors=%d, maxX=%d, right=%s", corridorLength, corridorCount, maxX, tostring(mineRight))
    
    -- Phase 1: Mine the perimeter rectangle
    -- Bottom bar: mine from x=0 to x=maxX (or -maxX) at z=0
    logger.debug("Phase 1a: Mining bottom bar at z=0")
    turnTo(sideDir)
    for i = 1, maxX do
        if not mineForward(fullMode) then return false end
    end
    -- Now at (maxX, 0) or (-maxX, 0)
    
    -- Far corridor: mine from z=0 to z=corridorLength at x=maxX (or -maxX)
    logger.debug("Phase 1b: Mining far corridor")
    turnTo(0) -- face +Z
    for i = 1, corridorLength do
        if not mineForward(fullMode) then return false end
    end
    -- Now at (maxX, corridorLength) or (-maxX, corridorLength)
    
    -- Top bar: mine back to x=0 at z=corridorLength
    logger.debug("Phase 1c: Mining top bar at z=%d", corridorLength)
    turnTo(backDir)
    for i = 1, maxX do
        if not mineForward(fullMode) then return false end
    end
    -- Now at (0, corridorLength)
    
    -- Near corridor: mine from z=corridorLength to z=0 at x=0
    logger.debug("Phase 1d: Mining near corridor at x=0")
    turnTo(2) -- face -Z
    for i = 1, corridorLength do
        if not mineForward(fullMode) then return false end
    end
    -- Now back at (0, 0), facing -Z
    
    -- Phase 2: Fill in interior corridors
    if corridorCount > 2 then
        logger.debug("Phase 2: Mining %d interior corridors", corridorCount - 2)
        for corridor = 2, corridorCount - 1 do
            -- Navigate to corridor start via bottom bar (already mined)
            turnTo(sideDir)
            for i = 1, shift do
                if not moveForwardSafe() then return false end
            end
            
            -- Mine this corridor upward
            logger.debug("Mining interior corridor %d", corridor)
            turnTo(0) -- face +Z
            for i = 1, corridorLength do
                if not mineForward(fullMode) then return false end
            end
            -- Now at top of this corridor
            
            -- Walk back down via the corridor we just mined (if more corridors to do)
            if corridor < corridorCount - 1 then
                turnTo(2) -- face -Z
                for i = 1, corridorLength do
                    if not moveForwardSafe() then return false end
                end
            end
        end
    end
    
    return true
end

local function main()
    print("Strip Miner (symmetric grid)")
    
    local corridorLength = input.readNumber("Corridor length: ")
    print("Tip: odd corridor counts return home faster; even counts end farther away.")
    local corridorCount = input.readNumber("Number of corridors: ")
    
    -- Efficiency tip based on corridor count
    if corridorCount >= 2 then
        local interiorCount = corridorCount - 2
        local walkBackMoves = math.max(0, interiorCount - 1) * corridorLength
        if corridorCount % 2 == 1 then
            print("  (Odd count = shorter return home)")
        else
            print("  (Even count = ends farther from start)")
        end
        if walkBackMoves > 0 then
            print(string.format("  (~%d repositioning moves)", walkBackMoves))
        end
    end
    
    local gap = input.readNumber("Rock gap between corridors (default 3): ", 3)
    local mineRight = input.readYesNo("Mine to the right? (y/n, default y): ", true)
    showLogs = input.readYesNo("Show log output? (y/n, default y): ", true)
    local returnHome = input.readYesNo("Return to start when done? (y/n, default y): ", true)
    local fullMode = input.readChoice(
        "On full inventory: 1) pause, 2) chest + resume, 3) drop junk only: ",
        1, 3, 1
    )

    logger.setEcho(showLogs)

    logger.logParams("strip_miner", {
        corridorLength = corridorLength,
        corridorCount = corridorCount,
        gap = gap,
        mineRight = mineRight,
        showLogs = showLogs,
        returnHome = returnHome,
        fullMode = fullMode,
    })

    local shift = gap + 1
    local maxX = (corridorCount - 1) * shift
    -- Perimeter: 2 bars (maxX each) + 2 outer corridors (corridorLength each)
    -- Interior: (corridorCount - 2) corridors of corridorLength each
    local perimeterMoves = (maxX * 2) + (corridorLength * 2)
    local interiorMoves = (corridorCount - 2) * corridorLength
    local totalMiningMoves = perimeterMoves + interiorMoves
    -- Return path: walk back through existing tunnels
    local estimatedReturn = returnHome and (maxX + corridorLength) or 0
    local estimatedMoves = totalMiningMoves + estimatedReturn

    totalSteps = totalMiningMoves
    currentStep = 0

    startTime = os.epoch("utc")
    startFuel = turtle.getFuelLevel()

    if not fuel.ensureFuel(estimatedMoves) then
        return
    end

    logger.info("Starting strip mine: length=%d corridors=%d gap=%d right=%s", corridorLength, corridorCount, gap, tostring(mineRight))
    if showLogs then
        print("Mining " .. totalSteps .. " blocks...")
    else
        renderStatus()
    end

    local aborted = false
    if not mineSymmetricGrid(corridorLength, corridorCount, gap, fullMode, mineRight) then
        aborted = true
    end

    print("")
    if returnHome and canReturnHome then
        logger.info("Returning home from x=%d z=%d", posX, posZ)
        print("Returning home...")
        goTo(0, 0, 0)
    elseif returnHome then
        logger.warn("Skipping return home because turtle is not at ground level")
        print("Skipping return home (turtle not at ground level).")
    end

    -- Calculate statistics
    local endTime = os.epoch("utc")
    local endFuel = turtle.getFuelLevel()
    local elapsedMs = endTime - startTime
    local elapsedSec = math.floor(elapsedMs / 1000)
    local elapsedMin = math.floor(elapsedSec / 60)
    local remainingSec = elapsedSec % 60
    local fuelUsed = (startFuel ~= "unlimited" and endFuel ~= "unlimited") and (startFuel - endFuel) or 0
    local efficiency = elapsedSec > 0 and ((currentStep / elapsedSec) * 60) or 0
    
    print("")
    print("=== Mining Statistics ===")
    print(string.format("Time: %dm %ds", elapsedMin, remainingSec))
    print(string.format("Movements: %d", moveCount))
    print(string.format("Turns: %d", turnCount))
    if fuelUsed > 0 then
        print(string.format("Fuel used: %d", fuelUsed))
    end
    if elapsedSec > 0 then
        print(string.format("Efficiency: %.1f blocks/min", efficiency))
    else
        print("Efficiency: n/a")
    end
    
    logger.info("Stats: time=%ds moves=%d turns=%d fuel=%d", elapsedSec, moveCount, turnCount, fuelUsed)
    
    if aborted then
        logger.warn("Strip mining aborted at step %d/%d", currentStep, totalSteps)
        print("Strip mining aborted.")
    else
        logger.info("Strip mining complete (%d steps)", totalSteps)
        print("Strip mining complete!")
    end
end

main()
