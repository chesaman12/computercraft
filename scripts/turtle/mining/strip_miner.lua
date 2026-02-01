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

local FUEL_SLOT = 15 -- Reserve slot for fuel so torches can stay in slot 16.
local TORCH_SLOT = 16
local MAX_DIG_ATTEMPTS = 10

local DEFAULT_TORCH_INTERVAL = 8
local DEFAULT_FUEL_RESERVE = 200
local DEFAULT_INV_THRESHOLD = 1
local DEFAULT_POKEHOLE_INTERVAL = 4
local DEFAULT_CORRIDOR_LENGTH = 30
local DEFAULT_CORRIDOR_COUNT = 10
local DEFAULT_GAP = 3
local DEFAULT_MINE_RIGHT = true
local DEFAULT_SHOW_LOGS = true
local DEFAULT_ENABLE_TORCHES = true
local DEFAULT_ENABLE_ORE_MINING = true
local DEFAULT_ENABLE_POKEHOLES = true
local DEFAULT_RETURN_HOME = true
local DEFAULT_FULL_MODE = 1
local SINGLE_CHEST_CAPACITY = 27
local RESTOCK_FUEL_BUFFER = 10

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

local oreList = {
    ["minecraft:coal_ore"] = true,
    ["minecraft:deepslate_coal_ore"] = true,
    ["minecraft:copper_ore"] = true,
    ["minecraft:deepslate_copper_ore"] = true,
    ["minecraft:iron_ore"] = true,
    ["minecraft:deepslate_iron_ore"] = true,
    ["minecraft:gold_ore"] = true,
    ["minecraft:deepslate_gold_ore"] = true,
    ["minecraft:redstone_ore"] = true,
    ["minecraft:deepslate_redstone_ore"] = true,
    ["minecraft:lapis_ore"] = true,
    ["minecraft:deepslate_lapis_ore"] = true,
    ["minecraft:diamond_ore"] = true,
    ["minecraft:deepslate_diamond_ore"] = true,
    ["minecraft:emerald_ore"] = true,
    ["minecraft:deepslate_emerald_ore"] = true,
}

-- Position tracking
local posX = 0
local posZ = 0
local posY = 0
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
local torchInterval = DEFAULT_TORCH_INTERVAL
local fuelReserve = DEFAULT_FUEL_RESERVE
local invThreshold = DEFAULT_INV_THRESHOLD
local pokeholeInterval = DEFAULT_POKEHOLE_INTERVAL
local enableTorches = true
local enableOreMining = true
local enablePokeholes = true
local returnHomeEnabled = true

local function isReservedSlot(slot)
    return slot == FUEL_SLOT or slot == TORCH_SLOT
end

local function countEmptySlots()
    return inventory.countEmptySlots()
end

local function getTorchCount()
    local detail = turtle.getItemDetail(TORCH_SLOT)
    if detail and detail.name:lower():match("torch") then
        return detail.count
    end
    return 0
end

local function renderStatus()
    local pct = totalSteps > 0 and math.floor((currentStep / totalSteps) * 100) or 0
    local elapsedSec = startTime > 0 and math.floor((os.epoch("utc") - startTime) / 1000) or 0
    local fuelLevel = turtle.getFuelLevel()

    term.clear()
    term.setCursorPos(1, 1)
    print("=== Strip Miner Status ===")
    print(string.format("Progress: %d/%d (%d%%)", currentStep, totalSteps, pct))
    print(string.format("Position: x=%d y=%d z=%d dir=%d", posX, posY, posZ, dir))
    if fuelLevel == "unlimited" then
        print("Fuel: Unlimited")
    else
        print(string.format("Fuel: %d", fuelLevel))
    end
    print(string.format("Moves: %d  Turns: %d", moveCount, turnCount))
    print(string.format("Empty slots: %d  Torches: %d", countEmptySlots(), getTorchCount()))
    print(string.format("Elapsed: %ds", elapsedSec))
end

local function applyDefaults()
    return {
        corridorLength = DEFAULT_CORRIDOR_LENGTH,
        corridorCount = DEFAULT_CORRIDOR_COUNT,
        gap = DEFAULT_GAP,
        mineRight = DEFAULT_MINE_RIGHT,
        showLogs = DEFAULT_SHOW_LOGS,
        enableTorches = DEFAULT_ENABLE_TORCHES,
        torchInterval = DEFAULT_TORCH_INTERVAL,
        fuelReserve = DEFAULT_FUEL_RESERVE,
        invThreshold = DEFAULT_INV_THRESHOLD,
        enableOreMining = DEFAULT_ENABLE_ORE_MINING,
        enablePokeholes = DEFAULT_ENABLE_POKEHOLES,
        pokeholeInterval = DEFAULT_POKEHOLE_INTERVAL,
        returnHome = DEFAULT_RETURN_HOME,
        fullMode = DEFAULT_FULL_MODE,
    }
end

local function promptConfig()
    local config = applyDefaults()
    local useDefaults = input.readYesNo("Use defaults? (y/n): ", true)
    if useDefaults then
        return config
    end

    config.corridorLength = input.readNumber("Corridor length: ", config.corridorLength)
    print("Tip: odd corridor counts return home faster; even counts end farther away.")
    config.corridorCount = input.readNumber("Corridor count: ", config.corridorCount)
    config.gap = input.readNumber("Gap between corridors: ", config.gap)
    config.mineRight = input.readYesNo("Mine right? (y/n): ", config.mineRight)
    config.showLogs = input.readYesNo("Show log output? (y/n): ", config.showLogs)
    config.enableTorches = input.readYesNo("Enable torches? (y/n): ", config.enableTorches)
    if config.enableTorches then
        config.torchInterval = input.readNumber("Torch interval: ", config.torchInterval)
    else
        config.torchInterval = 0
    end
    config.fuelReserve = input.readNumber("Fuel reserve: ", config.fuelReserve)
    config.invThreshold = input.readNumber("Return at empty slots: ", config.invThreshold)
    config.enableOreMining = input.readYesNo("Enable ore mining? (y/n): ", config.enableOreMining)
    config.enablePokeholes = input.readYesNo("Enable pokeholes? (y/n): ", config.enablePokeholes)
    if config.enablePokeholes then
        config.pokeholeInterval = input.readNumber("Pokehole interval: ", config.pokeholeInterval)
    else
        config.pokeholeInterval = 0
    end
    config.returnHome = input.readYesNo("Return to start when done? (y/n): ", config.returnHome)
    config.fullMode = input.readChoice(
        "On full inventory: 1) pause, 2) chest + resume, 3) drop junk: ",
        1, 3, config.fullMode
    )
    return config
end

local function applyConfig(config)
    enableTorches = config.enableTorches
    torchInterval = config.torchInterval
    fuelReserve = config.fuelReserve
    invThreshold = config.invThreshold
    enableOreMining = config.enableOreMining
    enablePokeholes = config.enablePokeholes
    pokeholeInterval = config.pokeholeInterval
    showLogs = config.showLogs
    returnHomeEnabled = config.returnHome
end

local function printStartupSummary(config)
    local torchLine = config.enableTorches and ("torches=" .. tostring(config.torchInterval)) or "torches=off"
    local oreLine = config.enableOreMining and "ores=on" or "ores=off"
    local pokeLine = config.enablePokeholes and ("poke=" .. tostring(config.pokeholeInterval)) or "poke=off"
    local modeLine = string.format("return=%s mode=%d", config.returnHome and "on" or "off", config.fullMode)
    print("=== Strip Miner ===")
    print(string.format("Size: %dx%d gap=%d", config.corridorLength, config.corridorCount, config.gap))
    print(string.format("Dir: %s  logs=%s", config.mineRight and "right" or "left", tostring(config.showLogs)))
    print(string.format("Fuel reserve: %d  empty slots: %d", config.fuelReserve, config.invThreshold))
    print(string.format("%s  %s", torchLine, oreLine))
    print(string.format("%s  %s", pokeLine, modeLine))
end

local function logReturnDecision(reason)
    logger.info("Return home: %s", reason)
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
            canReturnHome = false
            return false
        end
    end
    posY = posY + 1
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
            canReturnHome = false
            return false
        end
    end
    posY = posY - 1
    moveCount = moveCount + 1
    return true
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
    moveCount = moveCount + 1
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
    moveCount = moveCount + 1
    logger.debug("Moved forward (safe) to x=%d z=%d", posX, posZ)
    return true
end

-- Navigate to x, y, z (Y handled first).
local function goTo(x, y, z, targetDir)
    logger.debug("goTo: from x=%d y=%d z=%d to x=%d y=%d z=%d", posX, posY, posZ, x, y, z)
    if posY < y then
        for i = 1, (y - posY) do
            if not moveUpSafe() then return false end
        end
    elseif posY > y then
        for i = 1, (posY - y) do
            if not moveDownSafe() then return false end
        end
    end
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
    logger.debug("goTo: arrived at x=%d y=%d z=%d", posX, posY, posZ)
    return true
end

local function distanceHome()
    return math.abs(posX) + math.abs(posY) + math.abs(posZ)
end

local function dropJunk()
    for slot = 1, 16 do
        if not isReservedSlot(slot) then
            local detail = turtle.getItemDetail(slot)
            if detail and junkItems[detail.name] then
                turtle.select(slot)
                turtle.drop()
            end
        end
    end
    turtle.select(1)
end

local function dumpToChestBehindStart()
    turnAround()
    if not turtle.detect() then
        print("\nNo chest behind start. Place one and press enter.")
        read()
    end
    for slot = 1, 16 do
        if not isReservedSlot(slot) then
            turtle.select(slot)
            turtle.drop()
        end
    end
    turtle.select(1)
    turnAround()
end

local function tryRefuel(minFuel)
    if turtle.getFuelLevel() == "unlimited" then
        return true
    end
    for slot = 1, 16 do
        if not isReservedSlot(slot) and turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            if turtle.refuel(0) then
                turtle.refuel()
            end
        end
        if turtle.getFuelLevel() >= minFuel then
            turtle.select(1)
            return true
        end
    end
    turtle.select(1)
    return turtle.getFuelLevel() >= minFuel
end

local function refuelFromChest(minFuel)
    if turtle.getFuelLevel() == "unlimited" then
        return true
    end
    local attempts = 0
    while turtle.getFuelLevel() < minFuel and attempts < SINGLE_CHEST_CAPACITY do -- Single chest capacity.
        attempts = attempts + 1
        local emptySlot = nil
        for slot = 1, 16 do
            if not isReservedSlot(slot) and turtle.getItemCount(slot) == 0 then
                emptySlot = slot
                break
            end
        end
        if not emptySlot then
            break
        end
        turtle.select(emptySlot)
        if turtle.suck(64) then
            if turtle.refuel(0) then
                turtle.refuel()
            else
                turtle.drop()
            end
        else
            break
        end
    end
    turtle.select(1)
    return turtle.getFuelLevel() >= minFuel
end

local function restockTorches()
    if not enableTorches then
        return true
    end
    turtle.select(TORCH_SLOT)
    turtle.suck(64)
    turtle.select(1)
    return getTorchCount() > 0
end

local function waitForResource(resource, checkFn, restockFn, reason)
    if reason then
        logger.info("Waiting for %s at chest: %s", resource, reason)
    else
        logger.info("Waiting for %s at chest", resource)
    end
    while not checkFn() do
        print("")
        print("========================================")
        print("  IDLE: Waiting for " .. resource)
        print("========================================")
        print("")
        if reason then
            print(reason)
        end
        print("Add more to the chest and press Enter.")
        read()
        restockFn()
    end
end

local function returnToChestAndBack()
    local targetX = posX
    local targetY = posY
    local targetZ = posZ
    local targetDir = dir
    local homeDistance = distanceHome()

    logger.debug("Returning to chest from x=%d y=%d z=%d (distance=%d)", posX, posY, posZ, homeDistance)
    if not fuel.ensureFuel(homeDistance * 2 + RESTOCK_FUEL_BUFFER) then
        return false
    end

    goTo(0, 0, 0, 0)
    dumpToChestBehindStart()
    logger.debug("Dumped inventory, restocking")

    local minFuel = fuelReserve + math.abs(targetX) + math.abs(targetY) + math.abs(targetZ) + RESTOCK_FUEL_BUFFER
    tryRefuel(minFuel)
    refuelFromChest(minFuel)
    if turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < minFuel then
        waitForResource("fuel", function()
            return turtle.getFuelLevel() == "unlimited" or turtle.getFuelLevel() >= minFuel
        end, function()
            refuelFromChest(minFuel)
        end, "Returned home: fuel low for safe resume.")
    end

    if enableTorches and getTorchCount() == 0 then
        restockTorches()
        if getTorchCount() == 0 then
            waitForResource("torches", function()
                return getTorchCount() > 0
            end, restockTorches, "Returned home: torches needed to continue.")
        end
    end

    logger.info("Restocked: fuel=%s torches=%d", tostring(turtle.getFuelLevel()), getTorchCount())

    logger.debug("Returning to x=%d y=%d z=%d", targetX, targetY, targetZ)
    goTo(targetX, targetY, targetZ, targetDir)
    return true
end

local function ensureInventorySpace(fullMode)
    if countEmptySlots() > invThreshold then
        return true
    end

    logger.debug("Inventory low (%d empty) at x=%d z=%d", countEmptySlots(), posX, posZ)
    dropJunk()
    if countEmptySlots() > invThreshold then
        return true
    end

    if fullMode == 2 then
        if returnHomeEnabled and canReturnHome then
            logger.info("Inventory low (%d empty), returning to chest", countEmptySlots())
            logReturnDecision("inventory low")
            return returnToChestAndBack()
        end
        logger.warn("Inventory low but return-home disabled or unsafe; pausing for user")
        print("\nInventory low and cannot return home. Remove items and press enter.")
        read()
        return true
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
    local minFuel = distanceHome() + fuelReserve
    if fuelLevel < minFuel then
        if tryRefuel(minFuel) then
            return true
        end
        logger.warn("Fuel low (%d), returning home from x=%d y=%d z=%d", fuelLevel, posX, posY, posZ)
        print("\nFuel low. Returning home.")
        if returnHomeEnabled and canReturnHome then
            logReturnDecision("fuel low")
            return returnToChestAndBack()
        end
        print("Out of fuel. Refuel and restart.")
        return false
    end
    return true
end

local function isOre(name)
    return oreList[name]
end

-- Return (dx, dz) delta for the current facing direction.
local function getForwardDelta()
    if dir == 0 then
        return 0, 1
    elseif dir == 1 then
        return 1, 0
    elseif dir == 2 then
        return 0, -1
    elseif dir == 3 then
        return -1, 0
    end
    return 0, 0
end

-- Move forward without affecting mining progress (used for ore veins).
local function moveForwardRaw()
    local attempts = 0
    while not turtle.forward() do
        if turtle.detect() then
            turtle.dig()
        else
            sleep(0.2)
        end
        attempts = attempts + 1
        if attempts > MAX_DIG_ATTEMPTS then
            return false
        end
    end
    updatePosition()
    moveCount = moveCount + 1
    return true
end

local function moveBackSafe()
    turnAround()
    local ok = moveForwardSafe()
    turnAround()
    return ok
end

local function makeKey(x, y, z)
    return x .. ":" .. y .. ":" .. z
end

local function checkForwardOre(visited, mineFn)
    local dx, dz = getForwardDelta()
    if not visited[makeKey(posX + dx, posY, posZ + dz)] then
        local ok, data = turtle.inspect()
        if ok and isOre(data.name) then
            logger.debug("Ore forward: %s", data.name)
            turtle.dig()
            if moveForwardRaw() then
                mineFn(visited)
                moveBackSafe()
            end
        end
    end
end

--- Recursively mine connected ore blocks.
-- @param visited table Table of "x:y:z" keys to avoid revisiting nodes.
local function mineVein(visited)
    logger.debug("Ore scan at x=%d y=%d z=%d", posX, posY, posZ)
    visited[makeKey(posX, posY, posZ)] = true

    -- Check each direction for ore, step into it, recurse, then return.
    -- Up
    if not visited[makeKey(posX, posY + 1, posZ)] then
        local ok, data = turtle.inspectUp()
        if ok and isOre(data.name) then
            logger.debug("Ore up: %s", data.name)
            turtle.digUp()
            if moveUpSafe() then
                mineVein(visited)
                moveDownSafe()
            end
        end
    end

    -- Down
    if not visited[makeKey(posX, posY - 1, posZ)] then
        local ok, data = turtle.inspectDown()
        if ok and isOre(data.name) then
            logger.debug("Ore down: %s", data.name)
            turtle.digDown()
            if moveDownSafe() then
                mineVein(visited)
                moveUpSafe()
            end
        end
    end

    -- Forward
    checkForwardOre(visited, mineVein)

    -- Left
    turnLeft()
    checkForwardOre(visited, mineVein)
    turnRight()

    -- Right
    turnRight()
    checkForwardOre(visited, mineVein)
    turnLeft()

    -- Back
    turnAround()
    checkForwardOre(visited, mineVein)
    turnAround()
end

local function checkAndMineAdjacent()
    if not enableOreMining then
        return
    end
    mineVein({})
end

local function pokeholeSide(turnIn, turnOut)
    turnIn()
    if turtle.detect() then
        turtle.dig()
    end
    if moveForwardSafe() then
        checkAndMineAdjacent()
        moveBackSafe()
    end
    turnOut()
end

local function maybePokeholes()
    if not enablePokeholes or pokeholeInterval <= 0 then
        return
    end
    if currentStep > 0 and currentStep % pokeholeInterval == 0 then
        logger.debug("Pokeholes at step %d", currentStep)
        pokeholeSide(turnLeft, turnRight)
        pokeholeSide(turnRight, turnLeft)
    end
end

local function placeTorchIfNeeded()
    if not enableTorches or torchInterval <= 0 then
        return true
    end
    if currentStep == 0 or currentStep % torchInterval ~= 0 then
        return true
    end
    if getTorchCount() == 0 then
        logger.warn("Out of torches at x=%d y=%d z=%d", posX, posY, posZ)
        if returnHomeEnabled and canReturnHome then
            logReturnDecision("out of torches")
            return returnToChestAndBack()
        end
        logger.warn("Torches empty and return-home disabled or unsafe; pausing for user")
        print("\nOut of torches. Return-home disabled. Add torches and press enter.")
        read()
        return true
    end

    local prev = turtle.getSelectedSlot()
    turtle.select(TORCH_SLOT)
    if not turtle.placeDown() then
        logger.debug("Failed to place torch at x=%d y=%d z=%d", posX, posY, posZ)
    else
        logger.debug("Placed torch at x=%d y=%d z=%d", posX, posY, posZ)
    end
    turtle.select(prev)
    return true
end

local function mineForward(fullMode)
    if not moveForward1x2() then return false end
    currentStep = currentStep + 1
    showProgress()
    checkAndMineAdjacent()
    maybePokeholes()
    if not placeTorchIfNeeded() then return false end
    ensureInventorySpace(fullMode)
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

    local config = promptConfig()

    -- Efficiency tip based on corridor count
    if config.corridorCount >= 2 then
        local interiorCount = config.corridorCount - 2
        local walkBackMoves = math.max(0, interiorCount - 1) * config.corridorLength
        if config.corridorCount % 2 == 1 then
            print("  (Odd count = shorter return home)")
        else
            print("  (Even count = ends farther from start)")
        end
        if walkBackMoves > 0 then
            print(string.format("  (~%d repositioning moves)", walkBackMoves))
        end
    end

    applyConfig(config)
    printStartupSummary(config)

    logger.setEcho(config.showLogs)

    logger.logParams("strip_miner", {
        corridorLength = config.corridorLength,
        corridorCount = config.corridorCount,
        gap = config.gap,
        mineRight = config.mineRight,
        showLogs = config.showLogs,
        enableTorches = config.enableTorches,
        torchInterval = config.torchInterval,
        fuelReserve = config.fuelReserve,
        invThreshold = config.invThreshold,
        enableOreMining = config.enableOreMining,
        enablePokeholes = config.enablePokeholes,
        pokeholeInterval = config.pokeholeInterval,
        returnHome = config.returnHome,
        fullMode = config.fullMode,
    })

    local shift = config.gap + 1
    local maxX = (config.corridorCount - 1) * shift
    -- Perimeter: 2 bars (maxX each) + 2 outer corridors (corridorLength each)
    -- Interior: (corridorCount - 2) corridors of corridorLength each
    local perimeterMoves = (maxX * 2) + (config.corridorLength * 2)
    local interiorMoves = (config.corridorCount - 2) * config.corridorLength
    local totalMiningMoves = perimeterMoves + interiorMoves
    -- Return path: walk back through existing tunnels
    local estimatedReturn = config.returnHome and (maxX + config.corridorLength) or 0
    local estimatedMoves = totalMiningMoves + estimatedReturn + config.fuelReserve

    totalSteps = totalMiningMoves
    currentStep = 0

    startTime = os.epoch("utc")
    startFuel = turtle.getFuelLevel()

    if not fuel.ensureFuel(estimatedMoves) then
        return
    end

    logger.info("Starting strip mine: length=%d corridors=%d gap=%d right=%s", config.corridorLength, config.corridorCount, config.gap, tostring(config.mineRight))
    if config.showLogs then
        print("Mining " .. totalSteps .. " blocks...")
    else
        renderStatus()
    end

    local aborted = false
    if not mineSymmetricGrid(config.corridorLength, config.corridorCount, config.gap, config.fullMode, config.mineRight) then
        aborted = true
    end

    print("")
    if config.returnHome and canReturnHome then
        logger.info("Returning home from x=%d y=%d z=%d", posX, posY, posZ)
        print("Returning home...")
        logReturnDecision("end of run")
        goTo(0, 0, 0, 0)
        -- Final dump after returning home to clear any remaining ore (fuel/torch slots preserved).
        dumpToChestBehindStart()
    elseif config.returnHome then
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
