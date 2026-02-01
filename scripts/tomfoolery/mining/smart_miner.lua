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
    placeTorches = true,    -- Place torches for lighting
    torchInterval = 8,      -- Blocks between torches
    checkOreVeins = true,   -- Mine connected ore veins
    
    -- Safety settings
    minFuelToStart = 500,   -- Minimum fuel to begin mining
    fuelReserve = 200,      -- Keep this much fuel for return trip
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
    
    print("=== Smart Miner Status ===")
    print(string.format("Position: %d, %d, %d", pos.x, pos.y, pos.z))
    print(string.format("Fuel: %d / %d", fuel.getLevel(), fuel.getLimit()))
    print(string.format("Empty slots: %d / 16", inventory.emptySlots()))
    print(string.format("Blocks mined: %d", stats.blocksMined))
    print(string.format("Ores found: %d", stats.oresMined))
    print(string.format("Return trips: %d", stats.tripsHome))
    print(string.format("Elapsed: %.0fs", elapsed))
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
    
    return false
end

--- Deposit items in chest and refuel
local function depositAndRefuel()
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
    
    -- Compact and try to auto-refuel
    inventory.compact()
    fuel.autoRefuel(CONFIG.minFuelToStart)
    
    stats.tripsHome = stats.tripsHome + 1
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
    
    -- Deposit items
    depositAndRefuel()
    
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
    for step = 1, length do
        -- Check if we should return home
        local needReturn, reason = shouldReturnHome()
        if needReturn then
            print("Returning: " .. reason)
            returnHomeAndDeposit()
        end
        
        -- Determine if we should place a torch
        local placeTorch = CONFIG.placeTorches and (step % CONFIG.torchInterval == 0)
        
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
        -- Move to next branch position
        for step = 1, CONFIG.branchSpacing + 1 do
            mineTunnelStep(true, step == CONFIG.branchSpacing + 1)
        end
        
        -- Mine right branch
        branchNum = branchNum + 1
        print(string.format("Mining branch %d (right)...", branchNum))
        movement.turnRight()
        mineBranch(CONFIG.branchLength)
        
        -- Return to main tunnel
        movement.turnAround()
        for step = 1, CONFIG.branchLength do
            movement.forward(true)
        end
        
        -- Mine left branch
        branchNum = branchNum + 1
        print(string.format("Mining branch %d (left)...", branchNum))
        -- Already facing back, so turn right to face left branch
        movement.turnRight()
        mineBranch(CONFIG.branchLength)
        
        -- Return to main tunnel
        movement.turnAround()
        for step = 1, CONFIG.branchLength do
            movement.forward(true)
        end
        movement.turnRight()  -- Face forward again
    end
    
    -- Return home
    print("Mining complete! Returning home...")
    movement.goHome(true)
    
    -- Deposit final load
    movement.turnAround()
    depositAndRefuel()
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
    
    -- Confirm start
    print("")
    print("Place a chest behind the turtle for deposits.")
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
