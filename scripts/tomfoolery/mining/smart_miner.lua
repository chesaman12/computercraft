--- Smart Mining Turtle Script
-- An optimized branch mining turtle that:
-- - Mines efficient branch tunnels exposing maximum ore faces
-- - Tracks position and can return home
-- - Manages inventory and discards junk
-- - Deposits valuables in a chest at start position
-- - Detects and mines ore veins
-- - Handles fuel management automatically
--
-- Usage: smart_miner <length> [branches] [spacing]
--   length:  How far each branch extends (default: 50)
--   branches: Number of branches on each side (default: 5)
--   spacing: Blocks between branches (default: 3, optimal for ore exposure)
--
-- IMPORTANT: Run from the root installation directory (where common/ is):
--   mining/smart_miner 50
--
-- @script smart_miner

-- ============================================
-- PATH SETUP - Required for require() to work
-- ============================================
-- CC:Tweaked's require() resolves relative to the script location.
-- This function finds the absolute root directory and adds it to package.path
-- so that require("common.movement") works correctly from any subdirectory.
local function setupPaths()
    -- Get the absolute path to this script
    local scriptPath = shell.getRunningProgram()
    local absPath = "/" .. shell.resolve(scriptPath)
    
    -- Extract the directory containing this script
    -- e.g., "/mining/smart_miner.lua" -> "/mining/"
    local scriptDir = absPath:match("(.+/)") or "/"
    
    -- Go up one directory from mining/ to find common/
    -- e.g., "/mining/" -> "/"
    -- e.g., "/tomfoolery/mining/" -> "/tomfoolery/"
    local rootDir
    if scriptDir == "/" then
        rootDir = "/"
    else
        -- Remove trailing slash, get parent, add trailing slash
        local withoutTrailing = scriptDir:sub(1, -2)  -- "/mining" or "/tomfoolery/mining"
        rootDir = withoutTrailing:match("(.*/)" ) or "/"  -- "/" or "/tomfoolery/"
    end
    
    -- Add root to package path with ABSOLUTE paths
    package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path
    
    return rootDir
end

local ROOT_DIR = setupPaths()

-- Load modules from common library
local movement = require("common.movement")
local inventory = require("common.inventory")
local miningUtils = require("common.mining")
local fuel = require("common.fuel")

-- Configuration
local CONFIG = {
    -- Mining parameters
    branchLength = 50,      -- Length of each branch
    branchCount = 5,        -- Branches per side
    branchSpacing = 3,      -- Blocks between branches (3 = optimal ore exposure)
    tunnelHeight = 2,       -- Height of tunnel (2 blocks tall)
    
    -- Behavior settings
    placeFloors = false,    -- Place cobblestone floors over gaps
    placeTorches = true,    -- Place torches for lighting (MANDATORY - will idle if out)
    torchInterval = 8,      -- Blocks between torches
    torchSlot = 16,         -- Slot reserved for torches
    checkOreVeins = true,   -- Mine connected ore veins
    
    -- Safety settings
    minFuelToStart = 500,   -- Minimum fuel to begin mining
    fuelReserve = 200,      -- Keep this much fuel for return trip
    fuelCheckInterval = 5,  -- Check fuel every N blocks
    inventoryThreshold = 2, -- Return when only this many slots free
    
    -- Home position (where chest is)
    homeX = 0,
    homeY = 0,
    homeZ = 0,
}

-- Capture command line arguments at file scope
local tArgs = { ... }

-- Statistics tracking
local stats = {
    blocksMined = 0,
    oresMined = 0,
    tripsHome = 0,
    startTime = os.clock(),
}

--- Parse command line arguments
local function parseArgs()
    if tArgs[1] then
        CONFIG.branchLength = tonumber(tArgs[1]) or CONFIG.branchLength
    end
    if tArgs[2] then
        CONFIG.branchCount = tonumber(tArgs[2]) or CONFIG.branchCount
    end
    if tArgs[3] then
        CONFIG.branchSpacing = tonumber(tArgs[3]) or CONFIG.branchSpacing
    end
end

--- Print status to terminal
local function printStatus()
    term.clear()
    term.setCursorPos(1, 1)
    
    local pos = movement.getPosition()
    local elapsed = os.clock() - stats.startTime
    local fuelLevel = fuel.getLevel()
    local fuelLimit = fuel.getLimit()
    
    -- Get torch count (need to check before using getTorchCount which may not exist yet)
    local torchCount = 0
    local torchDetail = turtle.getItemDetail(CONFIG.torchSlot)
    if torchDetail and torchDetail.name:match("torch") then
        torchCount = torchDetail.count
    end
    
    print("=== Smart Miner Status ===")
    print(string.format("Position: %d, %d, %d", pos.x, pos.y, pos.z))
    if fuelLevel == "unlimited" then
        print("Fuel: Unlimited")
    else
        print(string.format("Fuel: %d / %d", fuelLevel, fuelLimit))
    end
    print(string.format("Torches: %d (slot %d)", torchCount, CONFIG.torchSlot))
    print(string.format("Empty slots: %d / 16", inventory.emptySlots()))
    print(string.format("Blocks mined: %d", stats.blocksMined))
    print(string.format("Ores found: %d", stats.oresMined))
    print(string.format("Return trips: %d", stats.tripsHome))
    print(string.format("Elapsed: %.0fs", elapsed))
end

--- Get the number of torches in the torch slot
local function getTorchCount()
    local detail = turtle.getItemDetail(CONFIG.torchSlot)
    if detail and detail.name:match("torch") then
        return detail.count
    end
    return 0
end

--- Check if block in front is a chest
local function isChestInFront()
    local success, block = turtle.inspect()
    if success then
        return block.name:match("chest") ~= nil
    end
    return false
end

--- Calculate fuel needed to return home from current position
local function fuelNeededToReturnHome()
    local pos = movement.getPosition()
    local distanceHome = math.abs(pos.x) + math.abs(pos.y) + math.abs(pos.z)
    return distanceHome + CONFIG.fuelReserve
end

--- Check if we have enough fuel to continue safely
local function hasSafeFuel()
    if fuel.isUnlimited() then
        return true
    end
    return fuel.getLevel() >= fuelNeededToReturnHome()
end

--- Idle and wait for resources (fuel or torches)
-- @param resource string "fuel" or "torches"
local function idleForResource(resource)
    print("")
    print("========================================")
    print("  IDLE: Waiting for " .. resource)
    print("========================================")
    print("")
    print("The turtle is out of " .. resource .. ".")
    print("Add more to the chest and press Enter.")
    print("")
    
    while true do
        read()
        
        if resource == "fuel" then
            -- Try to pick up fuel from chest
            if isChestInFront() then
                for slot = 1, 15 do
                    turtle.select(slot)
                    turtle.suck(64)
                end
                fuel.autoRefuel(CONFIG.minFuelToStart)
            end
            
            if fuel.getLevel() >= CONFIG.minFuelToStart then
                print("Fuel replenished! Resuming...")
                return true
            else
                print(string.format("Still need %d fuel. Add more and press Enter.", 
                    CONFIG.minFuelToStart - fuel.getLevel()))
            end
            
        elseif resource == "torches" then
            -- Try to pick up torches from chest
            if isChestInFront() then
                turtle.select(CONFIG.torchSlot)
                turtle.suck(64)
            end
            
            if getTorchCount() > 0 then
                print("Torches replenished! Resuming...")
                return true
            else
                print("No torches found. Add torches to the chest and press Enter.")
            end
        end
    end
end

--- Check if we should return home
local function shouldReturnHome()
    local pos = movement.getPosition()
    local distanceHome = math.abs(pos.x) + math.abs(pos.y) + math.abs(pos.z)
    local fuelNeeded = distanceHome + CONFIG.fuelReserve
    
    -- Return if inventory is nearly full
    if inventory.emptySlots() <= CONFIG.inventoryThreshold then
        return true, "inventory full"
    end
    
    -- Return if fuel is getting low
    if not fuel.isUnlimited() and fuel.getLevel() < fuelNeeded then
        return true, "low fuel"
    end
    
    -- Return if out of torches (torches are mandatory)
    if CONFIG.placeTorches and getTorchCount() == 0 then
        return true, "out of torches"
    end
    
    return false
end

--- Deposit items in chest and restock supplies
local function depositAndRestock()
    -- First check if there's actually a chest in front
    if not isChestInFront() then
        print("WARNING: No chest found! Dropping junk instead.")
        inventory.dropJunk()
        return false
    end
    
    -- Drop junk first to make room
    inventory.dropJunk()
    
    -- Dump inventory into chest (keep slot 16 for torches)
    for slot = 1, 15 do
        local detail = turtle.getItemDetail(slot)
        if detail then
            turtle.select(slot)
            turtle.drop()
        end
    end
    
    -- Try to pick up fuel from chest
    local needFuel = not fuel.isUnlimited() and fuel.getLevel() < CONFIG.minFuelToStart
    if needFuel then
        -- Suck items to find fuel
        for slot = 1, 15 do
            turtle.select(slot)
            if turtle.suck(64) then
                -- Check if it's fuel
                if not turtle.refuel(0) then
                    -- Not fuel, put it back
                    turtle.drop()
                end
            end
        end
        fuel.autoRefuel(CONFIG.minFuelToStart)
        
        -- Put unused items back
        for slot = 1, 15 do
            local detail = turtle.getItemDetail(slot)
            if detail then
                turtle.select(slot)
                turtle.drop()
            end
        end
    end
    
    -- Restock torches if needed
    if CONFIG.placeTorches and getTorchCount() < 32 then
        turtle.select(CONFIG.torchSlot)
        turtle.suck(64)  -- Try to grab a stack of torches
    end
    
    stats.tripsHome = stats.tripsHome + 1
    
    -- Check if we got what we needed
    local fuelOk = fuel.isUnlimited() or fuel.getLevel() >= CONFIG.minFuelToStart
    local torchesOk = not CONFIG.placeTorches or getTorchCount() > 0
    
    if not fuelOk then
        idleForResource("fuel")
    end
    
    if not torchesOk then
        idleForResource("torches")
    end
    
    return true
end

--- Go home, deposit items, then return to mining position
local function returnHomeAndDeposit()
    local pos = movement.getPosition()
    local savedPos = { x = pos.x, y = pos.y, z = pos.z }
    local savedFacing = movement.getFacing()
    
    print("Returning home to deposit...")
    
    -- Navigate home
    movement.goHome(true)
    
    -- Turn to face chest (assumed to be behind start position)
    movement.turnAround()
    
    -- Deposit items and restock supplies
    depositAndRestock()
    
    -- Return to mining position
    print("Returning to mining position...")
    movement.turnAround()
    movement.goTo(savedPos.x, savedPos.y, savedPos.z, true)
    movement.turnTo(savedFacing)
    
    print("Resuming mining...")
end

--- Dig forward, handling gravel and updating stats
local function digForwardAndMove()
    if turtle.detect() then
        miningUtils.digForward()
        stats.blocksMined = stats.blocksMined + 1
    end
    return movement.forward(true)
end

--- Dig up, updating stats
local function digUpBlock()
    if turtle.detectUp() then
        miningUtils.digUp()
        stats.blocksMined = stats.blocksMined + 1
        return true
    end
    return false
end

--- Dig down, updating stats
local function digDownBlock()
    if turtle.detectDown() then
        miningUtils.digDown()
        stats.blocksMined = stats.blocksMined + 1
        return true
    end
    return false
end

--- Check for ores in all directions and mine veins
local function checkForOres()
    if not CONFIG.checkOreVeins then return 0 end
    
    local oresFound = 0
    
    -- Check all 6 directions
    local function checkDirection(inspectFunc, digFunc, moveFunc, returnFunc)
        local block = inspectFunc()
        if miningUtils.isOre(block) then
            digFunc()
            oresFound = oresFound + 1
            stats.oresMined = stats.oresMined + 1
        end
    end
    
    -- Check front
    local front = miningUtils.inspectForward()
    if miningUtils.isOre(front) then
        oresFound = oresFound + miningUtils.checkAndMineOres(movement)
        stats.oresMined = stats.oresMined + oresFound
    end
    
    -- Check up
    local up = miningUtils.inspectUp()
    if miningUtils.isOre(up) then
        oresFound = oresFound + 1
        stats.oresMined = stats.oresMined + 1
        miningUtils.digUp()
    end
    
    -- Check down  
    local down = miningUtils.inspectDown()
    if miningUtils.isOre(down) then
        oresFound = oresFound + 1
        stats.oresMined = stats.oresMined + 1
        miningUtils.digDown()
    end
    
    return oresFound
end

--- Mine a 2-tall tunnel forward
local function mineTunnelStep(checkOres, placeTorch)
    -- Dig forward
    digForwardAndMove()
    
    -- Dig block above
    digUpBlock()
    
    -- Check for ores if enabled
    if checkOres then
        checkForOres()
    end
    
    -- Place torch if needed
    if placeTorch then
        miningUtils.placeTorch("up")
    end
    
    -- Periodic cleanup
    if inventory.emptySlots() < 4 then
        inventory.dropJunk()
    end
end

--- Mine a single branch
local function mineBranch(length)
    local stepsSinceCheck = 0
    
    for step = 1, length do
        stepsSinceCheck = stepsSinceCheck + 1
        
        -- Check safety conditions more frequently
        if stepsSinceCheck >= CONFIG.fuelCheckInterval then
            stepsSinceCheck = 0
            
            -- Check fuel level
            if not hasSafeFuel() then
                print("WARNING: Fuel getting low, returning home...")
                returnHomeAndDeposit()
            end
            
            -- Check inventory space
            if inventory.emptySlots() <= CONFIG.inventoryThreshold then
                print("Inventory full, returning home...")
                returnHomeAndDeposit()
            end
            
            -- Check torches (mandatory)
            if CONFIG.placeTorches and getTorchCount() == 0 then
                print("Out of torches, returning home...")
                returnHomeAndDeposit()
            end
        end
        
        -- Determine if we should place a torch
        local placeTorch = CONFIG.placeTorches and (step % CONFIG.torchInterval == 0)
        
        -- Verify we have a torch before attempting to place
        if placeTorch and getTorchCount() == 0 then
            print("Out of torches! Returning home...")
            returnHomeAndDeposit()
        end
        
        -- Mine one step forward
        mineTunnelStep(CONFIG.checkOreVeins, placeTorch)
        
        -- Update display periodically
        if step % 10 == 0 then
            printStatus()
        end
    end
end

--- Mine the main tunnel
local function mineMainTunnel(length)
    print("Mining main tunnel...")
    mineBranch(length)
end

--- Mine all branches in a branch mining pattern
local function branchMine()
    local mainTunnelLength = (CONFIG.branchCount * 2) * (CONFIG.branchSpacing + 1) + 1
    
    print(string.format("Branch mining pattern:"))
    print(string.format("  Main tunnel: %d blocks", mainTunnelLength))
    print(string.format("  Branches: %d per side, %d blocks each", CONFIG.branchCount, CONFIG.branchLength))
    print(string.format("  Spacing: %d blocks between branches", CONFIG.branchSpacing))
    print("")
    sleep(2)
    
    local branchNum = 0
    
    -- Mine main tunnel and branches
    for i = 1, CONFIG.branchCount do
        -- Check safety before starting new branch section
        if not hasSafeFuel() then
            print("Low fuel before branch section, returning home...")
            returnHomeAndDeposit()
        end
        
        -- Move to next branch position (mine main tunnel section)
        for step = 1, CONFIG.branchSpacing + 1 do
            -- Quick safety check each step in main tunnel
            if not hasSafeFuel() then
                returnHomeAndDeposit()
            end
            mineTunnelStep(true, step == CONFIG.branchSpacing + 1)
        end
        
        -- Mine right branch
        branchNum = branchNum + 1
        print(string.format("Mining branch %d (right)...", branchNum))
        movement.turnRight()
        mineBranch(CONFIG.branchLength)
        
        -- Return to main tunnel (check fuel during return)
        movement.turnAround()
        for step = 1, CONFIG.branchLength do
            if not hasSafeFuel() then
                -- We're in the branch, need to return home then come back
                print("Low fuel during return, going home first...")
                returnHomeAndDeposit()
            end
            movement.forward(true)
        end
        
        -- Mine left branch
        branchNum = branchNum + 1
        print(string.format("Mining branch %d (left)...", branchNum))
        -- Already facing back, so turn right to face left branch
        movement.turnRight()
        mineBranch(CONFIG.branchLength)
        
        -- Return to main tunnel (check fuel during return)
        movement.turnAround()
        for step = 1, CONFIG.branchLength do
            if not hasSafeFuel() then
                print("Low fuel during return, going home first...")
                returnHomeAndDeposit()
            end
            movement.forward(true)
        end
        movement.turnRight()  -- Face forward again
    end
    
    -- Return home
    print("Mining complete! Returning home...")
    movement.goHome(true)
    
    -- Deposit final load
    movement.turnAround()
    depositAndRestock()
end

--- Main entry point
local function main()
    parseArgs()
    
    print("=== Smart Mining Turtle ===")
    print(string.format("Branch length: %d", CONFIG.branchLength))
    print(string.format("Branches per side: %d", CONFIG.branchCount))
    print(string.format("Branch spacing: %d", CONFIG.branchSpacing))
    print("")
    
    -- Check fuel
    if not fuel.isUnlimited() then
        local totalDistance = CONFIG.branchLength * CONFIG.branchCount * 4 + 
                              CONFIG.branchCount * CONFIG.branchSpacing * 2
        print(string.format("Estimated fuel needed: %d", totalDistance))
        print(string.format("Current fuel: %d", fuel.getLevel()))
        
        if fuel.getLevel() < CONFIG.minFuelToStart then
            print("Insufficient fuel! Attempting to refuel...")
            if not fuel.autoRefuel(CONFIG.minFuelToStart) then
                fuel.waitForFuel(CONFIG.minFuelToStart)
            end
        end
    end
    
    -- Check torches (mandatory)
    if CONFIG.placeTorches then
        local torchCount = getTorchCount()
        print(string.format("Torches in slot %d: %d", CONFIG.torchSlot, torchCount))
        
        if torchCount == 0 then
            print("")
            printError("ERROR: Torches are required!")
            print(string.format("Place torches in slot %d and press Enter.", CONFIG.torchSlot))
            
            while getTorchCount() == 0 do
                read()
                if getTorchCount() == 0 then
                    print("Still no torches detected. Please add torches.")
                end
            end
            print(string.format("Found %d torches. Continuing...", getTorchCount()))
        end
    end
    
    -- Verify chest is behind turtle
    print("")
    print("Checking for chest behind turtle...")
    movement.turnAround()
    if isChestInFront() then
        print("Chest detected!")
    else
        printError("WARNING: No chest detected behind turtle!")
        print("Place a chest behind the turtle for deposits.")
        print("Press Enter to continue anyway, or add chest first.")
    end
    movement.turnAround()
    
    -- Confirm start
    print("")
    print("Press Enter to start mining, or Ctrl+T to cancel.")
    read()
    
    -- Initialize start position
    movement.setPosition(0, 0, 0)
    movement.setFacing(0)  -- Assume facing north
    stats.startTime = os.clock()
    
    -- Start branch mining
    branchMine()
    
    -- Print final stats
    print("")
    print("=== Mining Complete ===")
    print(string.format("Blocks mined: %d", stats.blocksMined))
    print(string.format("Ores found: %d", stats.oresMined))
    print(string.format("Return trips: %d", stats.tripsHome))
    print(string.format("Total time: %.0f seconds", os.clock() - stats.startTime))
end

-- Run main with error handling
local success, err = pcall(main)
if not success then
    printError("Error: " .. tostring(err))
    
    -- Try to return home on error
    print("Attempting to return home...")
    movement.goHome(true)
end
