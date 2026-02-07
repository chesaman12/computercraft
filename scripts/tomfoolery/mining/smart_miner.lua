--- Smart Mining Turtle Script
-- Square perimeter mining with internal branches
--
-- Features:
-- - Square perimeter mining with parallel branch fill
-- - Auto-adjusts size for proper spacing (3 blocks between edges/branches)
-- - Standard 1x2 tunnels with pokehole mining (wiki-recommended)
-- - Ore vein detection and mining
-- - Auto return home for deposits and restocking
-- - Torch placement at regular intervals
-- - Full logging with Pastebin upload support
--
-- Usage: smart_miner <size> [spacing] [--upload]
--   size:    Target square size (default: 25)
--   spacing: Blocks between branches (default: 3)
--   --upload: Upload log to Pastebin when complete
--
-- Run from root installation directory: mining/smart_miner 25
--
-- @script smart_miner

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
local miningUtils = require("common.mining")
local fuel = require("common.fuel")
local logger = require("common.logger")

-- Miner modules
local core = require("miner.core")
local home = require("miner.home")
local tunnel = require("miner.tunnel")
local patterns = require("miner.patterns")

-- Capture command line arguments at file scope
local tArgs = { ... }

-- Parse --upload flag
local uploadOnComplete = false
for i, arg in ipairs(tArgs) do
    if arg == "--upload" or arg == "-u" then
        uploadOnComplete = true
        table.remove(tArgs, i)
        break
    end
end

-- Initialize modules
core.init({
    movement = movement,
    inventory = inventory,
    mining = miningUtils,
    fuel = fuel,
})
home.init(core)
tunnel.init(core)
patterns.init(core, home, tunnel)

-- Apply mining dimension mode if configured
if core.config.miningDimensionMode then
    miningUtils.enableMiningDimensionMode()
end

-- ============================================
-- STARTUP VALIDATION
-- ============================================

local function validateStartup()
    local adjustedSize, numBranches = core.calculateAdjustedSize(core.config.squareSize)
    local startOffset = core.config.branchSpacing + 1
    local branchLength = adjustedSize - 2 * startOffset
    
    -- Log startup parameters
    logger.clear()  -- Start fresh log for this run
    logger.logParams("Smart Miner", {
        targetSize = core.config.squareSize,
        adjustedSize = adjustedSize,
        numBranches = numBranches,
        branchLength = branchLength,
        branchSpacing = core.config.branchSpacing,
        usePokeholes = core.config.usePokeholes,
        pokeholeInterval = core.config.pokeholeInterval,
        placeTorches = core.config.placeTorches,
        torchInterval = core.config.torchInterval,
        miningDimensionMode = core.config.miningDimensionMode,
        uploadOnComplete = uploadOnComplete,
    })
    
    print("=== Smart Mining Turtle ===")
    print(string.format("Size: %d (adjusted: %d x %d)", core.config.squareSize, adjustedSize, adjustedSize))
    print(string.format("Branches: %d x %d blocks", numBranches, branchLength))
    
    if core.config.usePokeholes then
        print(string.format("Mode: Pokehole (every %d blocks)", core.config.pokeholeInterval))
    elseif core.config.useSnakeMining then
        print("Mode: Snake (1x3 tunnel)")
    else
        print("Mode: Simple (1x2 tunnel)")
    end
    
    if core.config.miningDimensionMode then
        print("Ore detection: Mining dimension (mine all non-junk)")
    else
        print("Ore detection: Whitelist (ores.cfg)")
    end
    print("")
    
    -- Check fuel
    if not fuel.isUnlimited() then
        local pokeholeExtra = core.config.usePokeholes and 
            ((4 * adjustedSize + numBranches * branchLength) / core.config.pokeholeInterval * 2) or 0
        local totalDistance = (4 * adjustedSize) + (numBranches * branchLength) + 
            (numBranches * startOffset * 2) + pokeholeExtra
        
        print(string.format("Fuel needed: ~%d (current: %d)", math.ceil(totalDistance), fuel.getLevel()))
        logger.info("Fuel estimate: needed=%d, current=%d", math.ceil(totalDistance), fuel.getLevel())
        
        if fuel.getLevel() < core.config.minFuelToStart then
            print("Refueling...")
            logger.info("Auto-refueling to %d", core.config.minFuelToStart)
            if not fuel.autoRefuel(core.config.minFuelToStart) then
                fuel.waitForFuel(core.config.minFuelToStart)
            end
            logger.info("Fuel after refuel: %d", fuel.getLevel())
        end
    end
    
    -- Check torches
    if core.config.placeTorches then
        local torchCount = core.getTorchCount()
        print(string.format("Torches: %d (slot %d)", torchCount, core.config.torchSlot))
        logger.info("Torches available: %d in slot %d", torchCount, core.config.torchSlot)
        
        if torchCount == 0 then
            printError("ERROR: Torches required!")
            logger.warn("No torches found, waiting for user")
            print(string.format("Place torches in slot %d and press Enter.", core.config.torchSlot))
            
            while core.getTorchCount() == 0 do
                read()
            end
            print(string.format("Found %d torches.", core.getTorchCount()))
            logger.info("Torches loaded: %d", core.getTorchCount())
        end
    end
    
    -- Check chest
    print("\nChecking for chest...")
    logger.info("Verifying chest placement")
    home.verifyChest()
    logger.info("Chest verified")
    
    -- Confirm
    print("\nPress Enter to start mining (Ctrl+T to cancel).")
    read()
    logger.section("Mining Started")
end

-- ============================================
-- MAIN
-- ============================================

local function main()
    -- Parse arguments
    core.parseArgs(tArgs)
    
    -- Validate and prepare
    validateStartup()
    
    -- Initialize position
    movement.setPosition(0, 0, 0)
    movement.setFacing(0)
    core.stats.startTime = os.clock()
    
    -- Execute mining pattern
    patterns.squareMine()
    
    -- Final stats
    local elapsed = os.clock() - core.stats.startTime
    
    print("")
    print("=== Mining Complete ===")
    print(string.format("Blocks mined: %d", core.stats.blocksMined))
    print(string.format("Ores found: %d", core.stats.oresMined))
    print(string.format("Return trips: %d", core.stats.tripsHome))
    print(string.format("Total time: %.0f seconds", elapsed))
    
    -- Log final statistics
    local finalStats = {
        blocksMined = core.stats.blocksMined,
        oresMined = core.stats.oresMined,
        tripsHome = core.stats.tripsHome,
        elapsedSeconds = math.floor(elapsed),
        finalFuel = fuel.getLevel(),
    }
    
    -- Upload log if requested
    if uploadOnComplete then
        local title = string.format("Smart Miner - %dx%d - %d ores", 
            core.config.adjustedSquareSize or core.config.squareSize,
            core.config.adjustedSquareSize or core.config.squareSize,
            core.stats.oresMined)
        logger.finalize(finalStats, title)
    else
        logger.logStats(finalStats)
        logger.section("Run Complete")
        print("")
        print("Log saved to: " .. logger.getLogPath())
        print("To upload: Run 'upload_log' or add --upload flag")
    end
end

-- Run with error handling
local success, err = pcall(main)
if not success then
    printError("Error: " .. tostring(err))
    logger.error("Fatal error: %s", tostring(err))
    
    -- Log position for debugging
    local pos = movement.getPosition()
    logger.error("Position at error: x=%d, y=%d, z=%d, facing=%d", 
        pos.x, pos.y, pos.z, movement.getFacing())
    
    print("Attempting to return home...")
    logger.info("Attempting emergency return home")
    
    local homeSuccess = movement.goHome(true)
    if homeSuccess then
        logger.info("Successfully returned home after error")
    else
        logger.error("Failed to return home!")
    end
    
    -- Upload on error if flag was set
    if uploadOnComplete then
        logger.finalize(core.stats, "Smart Miner - ERROR - " .. tostring(err):sub(1, 30))
    end
end
