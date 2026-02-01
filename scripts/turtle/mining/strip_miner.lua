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

local function showProgress()
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
    logger.debug("Turned left, now facing %d", dir)
end

local function turnRight()
    turtle.turnRight()
    dir = (dir + 1) % 4
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

local function moveForward1x2()
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
    while turtle.detectUp() do
        logger.debug("Digging up at x=%d z=%d", posX, posZ)
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
    logger.debug("Moved forward to x=%d z=%d", posX, posZ)
    return true
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

local function mineBranch(length, fullMode)
    logger.debug("Starting branch (length=%d) at x=%d z=%d", length, posX, posZ)
    for i = 1, length do
        if not moveForward1x2() then return false end
        ensureInventorySpace(fullMode)
        currentStep = currentStep + 1
        showProgress()
        if not checkFuelPeriodic() then return false end
    end
    logger.debug("Branch dig complete, returning from x=%d z=%d", posX, posZ)
    turnAround()
    for i = 1, length do
        if not moveForwardSafe() then return false end
        ensureInventorySpace(fullMode)
        currentStep = currentStep + 1
        showProgress()
    end
    turnAround()
    logger.debug("Branch complete, back at x=%d z=%d", posX, posZ)
    return true
end

local function main()
    print("Strip Miner (ladder pattern)")
    
    local spineLength = input.readNumber("Main corridor length: ")
    local branchLength = input.readNumber("Branch length: ")
    local spacing = input.readNumber("Spacing between branches (default 3): ", 3)
    local bothSides = input.readYesNo("Branches on both sides? (y/n, default y): ", true)
    local returnHome = input.readYesNo("Return to start when done? (y/n, default y): ", true)
    local fullMode = input.readChoice(
        "On full inventory: 1) pause, 2) chest + resume, 3) drop junk only: ",
        1, 3, 1
    )

    logger.logParams("strip_miner", {
        spineLength = spineLength,
        branchLength = branchLength,
        spacing = spacing,
        bothSides = bothSides,
        returnHome = returnHome,
        fullMode = fullMode,
    })

    local branchCount = math.floor((spineLength - 1) / spacing)
    local movesPerBranch = bothSides and (branchLength * 4) or (branchLength * 2)
    local estimatedMoves = spineLength + (returnHome and spineLength or 0) + (branchCount * movesPerBranch)

    totalSteps = spineLength + (branchCount * (bothSides and (branchLength * 2) or branchLength))
    currentStep = 0

    if not fuel.ensureFuel(estimatedMoves) then
        return
    end

    logger.info("Starting strip mine: spine=%d branches=%d spacing=%d", spineLength, branchCount, spacing)
    print("Mining " .. totalSteps .. " blocks...")

    local aborted = false
    for step = 1, spineLength do
        if not moveForward1x2() then
            aborted = true
            break
        end
        ensureInventorySpace(fullMode)
        currentStep = currentStep + 1
        showProgress()
        if not checkFuelPeriodic() then
            aborted = true
            break
        end
        
        if step % spacing == 0 and step < spineLength then
            if bothSides then
                turnLeft()
                if not mineBranch(branchLength, fullMode) then
                    aborted = true
                    break
                end
                turnRight()

                turnRight()
                if not mineBranch(branchLength, fullMode) then
                    aborted = true
                    break
                end
                turnLeft()
            else
                turnLeft()
                if not mineBranch(branchLength, fullMode) then
                    aborted = true
                    break
                end
                turnRight()
            end
        end
    end

    print("")
    if returnHome then
        logger.info("Returning home from x=%d z=%d", posX, posZ)
        print("Returning home...")
        goTo(0, 0, 0)
    end

    if aborted then
        logger.warn("Strip mining aborted at step %d/%d", currentStep, totalSteps)
        print("Strip mining aborted.")
    else
        logger.info("Strip mining complete (%d steps)", totalSteps)
        print("Strip mining complete!")
    end
end

main()
