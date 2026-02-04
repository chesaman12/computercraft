--- Tree Farmer Turtle Script
-- Automated tree farming with configurable grid layout
--
-- Features:
-- - Grid-based tree farming with configurable dimensions
-- - Automatic harvesting and replanting
-- - Sapling collection and self-sustaining operation
-- - Chest deposits for logs and excess items
-- - Support for multiple tree types (birch recommended)
-- - Full logging with Pastebin upload support
--
-- Usage: tree_farmer <width> <depth> [tree_type] [--upload] [--setup]
--   width:     Number of trees in X direction (default: 5)
--   depth:     Number of trees in Z direction (default: 5)
--   tree_type: birch, oak, spruce, jungle, acacia (default: birch)
--   --upload:  Upload log to Pastebin when complete
--   --setup:   Initial farm setup mode (plants saplings)
--
-- Run from root installation directory: farming/tree_farmer 5 5 birch
--
-- @script tree_farmer

-- ============================================
-- PATH SETUP
-- ============================================

local function setupPaths()
    local scriptPath = shell.getRunningProgram()
    local absPath = "/" .. shell.resolve(scriptPath)
    local scriptDir = absPath:match("(.+/)") or "/"
    local rootDir
    if scriptDir == "/" then
        rootDir = "/"
    else
        local withoutTrailing = scriptDir:sub(1, -2)
        rootDir = withoutTrailing:match("(.*/)" ) or "/"
    end
    package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path
    return rootDir
end

setupPaths()

-- ============================================
-- LOAD MODULES
-- ============================================

-- Common libraries
local movement = require("common.movement")
local inventory = require("common.inventory")
local fuel = require("common.fuel")
local logger = require("common.logger")

-- Farmer modules
local core = require("farmer.core")
local harvest = require("farmer.harvest")
local planting = require("farmer.planting")

-- Capture command line arguments
local tArgs = { ... }

-- ============================================
-- PARSE ARGUMENTS
-- ============================================

local uploadOnComplete = false
local setupMode = false
local treeType = "oak"  -- Default to oak

-- Parse flags
local cleanArgs = {}
for i, arg in ipairs(tArgs) do
    if arg == "--upload" or arg == "-u" then
        uploadOnComplete = true
    elseif arg == "--setup" or arg == "-s" then
        setupMode = true
    else
        table.insert(cleanArgs, arg)
    end
end

-- Parse positional arguments
local width = tonumber(cleanArgs[1]) or 5
local depth = tonumber(cleanArgs[2]) or 5

-- Check if third arg is tree type
if cleanArgs[3] then
    local validTypes = { birch=true, oak=true, spruce=true, jungle=true, acacia=true, dark_oak=true, cherry=true }
    if validTypes[cleanArgs[3]:lower()] then
        treeType = cleanArgs[3]:lower()
    end
end

-- ============================================
-- INITIALIZATION
-- ============================================

-- Set configuration
core.config.width = width
core.config.depth = depth
core.config.treeType = treeType

-- Get tree-specific spacing
local treeInfo = core.TREE_TYPES[treeType]
if treeInfo then
    core.config.spacing = treeInfo.spacing
    core.config.maxTreeHeight = treeInfo.maxHeight
end

-- Initialize modules
core.init({
    movement = movement,
    inventory = inventory,
    fuel = fuel,
})
harvest.init(core)
planting.init(core, harvest)

-- ============================================
-- STARTUP VALIDATION
-- ============================================

local function validateStartup()
    local farmWidth, farmDepth = core.getFarmSize()
    local totalTrees = core.getTotalTrees()
    local fuelNeeded = core.estimateFuelCost()
    
    -- Log startup parameters
    logger.clear()
    logger.logParams("Tree Farmer", {
        width = core.config.width,
        depth = core.config.depth,
        treeType = core.config.treeType,
        spacing = core.config.spacing,
        farmSize = string.format("%dx%d blocks", farmWidth, farmDepth),
        totalTrees = totalTrees,
        setupMode = setupMode,
        uploadOnComplete = uploadOnComplete,
    })
    
    -- Display to terminal
    print("=== Tree Farmer ===")
    print(string.format("Grid: %dx%d trees (%s)", width, depth, treeType))
    print(string.format("Farm size: %dx%d blocks", farmWidth, farmDepth))
    print(string.format("Total positions: %d trees", totalTrees))
    print(string.format("Mode: %s", setupMode and "SETUP" or "HARVEST"))
    
    -- Check fuel
    local currentFuel = turtle.getFuelLevel()
    if currentFuel ~= "unlimited" then
        print(string.format("Fuel: %d / %d needed", currentFuel, fuelNeeded))
        if currentFuel < fuelNeeded then
            logger.warn("Low fuel: %d < %d estimated", currentFuel, fuelNeeded)
            print("WARNING: May not have enough fuel")
            
            -- Try to refuel
            fuel.autoRefuel(fuelNeeded)
            currentFuel = turtle.getFuelLevel()
            
            if currentFuel < core.config.minFuel then
                logger.error("Fuel critically low: %d", currentFuel)
                print("ERROR: Not enough fuel to operate")
                return false
            end
        end
    else
        print("Fuel: Unlimited")
    end
    
    -- Check saplings (for setup mode)
    if setupMode then
        local saplings = core.countSaplings()
        print(string.format("Saplings: %d / %d needed", saplings, totalTrees))
        if saplings < totalTrees then
            logger.warn("Not enough saplings: %d < %d", saplings, totalTrees)
            print("WARNING: Not enough saplings for full setup")
        end
    end
    
    -- Check for deposit chest behind
    local hasChest = false
    movement.turnRight()
    movement.turnRight()
    local success, blockData = turtle.inspect()
    if success and (blockData.name:match("chest") or blockData.name:match("barrel")) then
        hasChest = true
    end
    movement.turnRight()
    movement.turnRight()
    
    if hasChest then
        print("Deposit chest: Found")
        logger.info("Deposit chest detected behind turtle")
    else
        print("Deposit chest: Not found (optional)")
        logger.info("No deposit chest - items will accumulate")
    end
    
    print("")
    return true
end

-- ============================================
-- CHEST OPERATIONS
-- ============================================

--- Target number of saplings to keep (one stack)
local TARGET_SAPLINGS = 64

--- Deposit items to chest and restock saplings
-- Handles double chests by depositing/withdrawing in a loop
local function depositAndRestock()
    local movement = core.libs.movement
    local treeInfo = core.getTreeInfo()
    
    logger.section("Deposit & Restock")
    
    -- Turn to face chest
    movement.turnRight()
    movement.turnRight()
    
    -- Check if chest is there
    local success, blockData = turtle.inspect()
    if not success or not (blockData.name:match("chest") or blockData.name:match("barrel")) then
        logger.warn("No chest found for deposit")
        movement.turnRight()
        movement.turnRight()
        return false
    end
    
    -- STEP 1: Consolidate all saplings to slot 1 first
    core.consolidateSaplings()
    local currentSaplings = core.countSaplings()
    logger.info("Current saplings before deposit: %d", currentSaplings)
    
    -- STEP 2: Deposit everything EXCEPT slot 1 (saplings) and slot 16 (torches)
    local deposited = 0
    for slot = 2, 15 do
        local item = turtle.getItemDetail(slot)
        if item then
            turtle.select(slot)
            if turtle.drop() then
                deposited = deposited + 1
                logger.debug("Deposited %s x%d from slot %d", item.name, item.count, slot)
            end
        end
    end
    
    -- STEP 3: If we have excess saplings (more than target), deposit some
    turtle.select(1)
    local slot1 = turtle.getItemDetail(1)
    if slot1 and slot1.name == treeInfo.sapling and slot1.count > TARGET_SAPLINGS then
        local excess = slot1.count - TARGET_SAPLINGS
        turtle.drop(excess)
        logger.info("Deposited %d excess saplings", excess)
    end
    
    -- STEP 4: If we need more saplings, try to withdraw from chest
    currentSaplings = core.countSaplings()
    if currentSaplings < TARGET_SAPLINGS then
        local needed = TARGET_SAPLINGS - currentSaplings
        logger.info("Need %d more saplings, searching chest...", needed)
        
        -- Suck items and check if they're saplings
        -- This works with double chests - just keep sucking
        local attempts = 0
        local maxAttempts = 54 * 2  -- Double chest has 54 slots, may need multiple passes
        
        while currentSaplings < TARGET_SAPLINGS and attempts < maxAttempts do
            -- Try to suck into an empty slot
            local emptySlot = nil
            for slot = 2, 15 do
                if turtle.getItemCount(slot) == 0 then
                    emptySlot = slot
                    break
                end
            end
            
            if not emptySlot then
                -- Inventory full, can't check more
                break
            end
            
            turtle.select(emptySlot)
            if not turtle.suck(64) then
                -- Chest is empty or we can't suck more
                break
            end
            
            local item = turtle.getItemDetail(emptySlot)
            if item then
                if item.name == treeInfo.sapling then
                    -- Found saplings! Transfer to slot 1
                    turtle.transferTo(1)
                    currentSaplings = core.countSaplings()
                    logger.debug("Found saplings, now have %d", currentSaplings)
                else
                    -- Not saplings, put back
                    turtle.drop()
                end
            end
            
            attempts = attempts + 1
        end
        
        logger.info("Restocked to %d saplings", currentSaplings)
    end
    
    turtle.select(1)
    
    -- Turn back to original facing (north)
    movement.turnRight()
    movement.turnRight()
    
    logger.info("Deposited items from %d slots, saplings: %d", deposited, core.countSaplings())
    return true
end

-- Alias for backward compatibility
local function depositItems()
    return depositAndRestock()
end

-- ============================================
-- MAIN HARVEST LOOP
-- ============================================

local function runHarvestLoop()
    logger.section("Harvest Loop")
    
    print("Starting harvest loop...")
    print("Press Ctrl+T to stop")
    print("")
    
    while core.state.running do
        -- Check fuel before each pass
        local currentFuel = turtle.getFuelLevel()
        if currentFuel ~= "unlimited" and currentFuel < core.config.minFuel then
            logger.warn("Low fuel, attempting refuel")
            fuel.autoRefuel(core.config.minFuel)
            
            if turtle.getFuelLevel() < core.config.minFuel then
                logger.error("Cannot continue - out of fuel")
                print("Out of fuel! Add fuel and restart.")
                break
            end
        end
        
        -- Harvest all trees AND replant empty positions in one pass
        local logs, planted = harvest.harvestAllTrees(true)  -- true = replant
        
        -- Return home after the pass
        harvest.returnHome()
        
        -- Always deposit logs and restock saplings after each pass
        depositAndRestock()
        
        -- Print status
        print(string.format("Pass #%d: %d logs, %d planted", 
            core.stats.harvestPasses, logs, planted))
        print(string.format("Fuel: %s, Saplings: %d",
            tostring(turtle.getFuelLevel()), core.countSaplings()))

        -- Upload log after each pass (before waiting)
        if uploadOnComplete then
            local passStats = {
                harvestPasses = core.stats.harvestPasses,
                treesHarvested = core.stats.treesHarvested,
                logsCollected = core.stats.logsCollected,
                saplingsPlanted = core.stats.saplingsPlanted,
                fuel = turtle.getFuelLevel(),
                lastPassLogs = logs,
                lastPassPlanted = planted,
            }
            local title = string.format("Tree Farmer - Pass #%d", core.stats.harvestPasses)
            logger.uploadAndPrint(title, passStats)
        end
        
        -- Wait before next pass
        if core.state.running then
            logger.debug("Waiting %d seconds before next pass", core.config.harvestInterval)
            print(string.format("Next pass in %d seconds...", core.config.harvestInterval))
            
            -- Interruptible sleep
            local waitTime = core.config.harvestInterval
            while waitTime > 0 and core.state.running do
                sleep(math.min(waitTime, 10))
                waitTime = waitTime - 10
            end
        end
    end
end

-- ============================================
-- MAIN EXECUTION
-- ============================================

local function main()
    -- Validate startup
    if not validateStartup() then
        logger.error("Startup validation failed")
        return false
    end
    
    print("Starting in 3 seconds...")
    sleep(3)
    
    local success, err = pcall(function()
        if setupMode then
            -- Initial farm setup
            logger.section("Farm Setup")
            local planted = planting.setupFarm()
            print(string.format("Setup complete: %d saplings planted", planted))
            
            -- Wait for trees to grow before starting harvest loop
            if planted > 0 then
                print("Waiting 60 seconds for trees to grow...")
                sleep(60)
            end
            
            -- Continue to harvest loop
            runHarvestLoop()
        else
            -- Normal harvest mode
            runHarvestLoop()
        end
    end)
    
    if not success then
        logger.error("Runtime error: %s", tostring(err))
        printError("Error: " .. tostring(err))
    end
    
    -- Final stats
    logger.section("Final Statistics")
    core.printStats()
    
    -- Finalize logging
    local stats = {
        harvestPasses = core.stats.harvestPasses,
        treesHarvested = core.stats.treesHarvested,
        logsCollected = core.stats.logsCollected,
        saplingsPlanted = core.stats.saplingsPlanted,
        fuel = turtle.getFuelLevel(),
    }
    
    if uploadOnComplete then
        logger.finalize(stats, "Tree Farmer Run")
    else
        logger.info("Run complete (no upload requested)")
    end
    
    return success
end

-- ============================================
-- RUN
-- ============================================

local ok, err = pcall(main)
if not ok then
    logger.error("Fatal error: %s", tostring(err))
    printError("Fatal error: " .. tostring(err))
    
    -- Log position at crash for debugging
    local pos = movement.getPosition()
    local facing = movement.getFacing()
    logger.error("Position at crash: (%d, %d, %d) facing=%d", pos.x, pos.y, pos.z, facing)
    logger.error("Fuel at crash: %s", tostring(turtle.getFuelLevel()))
    
    -- Log inventory at crash
    logger.error("=== INVENTORY AT CRASH ===")
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            logger.error("  Slot %02d: %s x%d", slot, item.name, item.count)
        end
    end
    
    -- Try to return home
    print("Attempting to return home...")
    logger.info("Attempting emergency return home")
    local homeOk = pcall(function()
        harvest.returnHome()
    end)
    if homeOk then
        logger.info("Emergency return home succeeded")
    else
        logger.error("Emergency return home FAILED")
    end
    
    if uploadOnComplete then
        logger.finalize({ 
            error = tostring(err),
            posX = pos.x,
            posY = pos.y,
            posZ = pos.z,
            facing = facing,
        }, "Tree Farmer CRASH")
    end
end
