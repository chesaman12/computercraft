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
--
-- Usage: smart_miner <size> [spacing]
--   size:    Target square size (default: 25)
--   spacing: Blocks between branch tunnels (default: 3)
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

-- Miner modules
local core = require("miner.core")
local home = require("miner.home")
local tunnel = require("miner.tunnel")
local patterns = require("miner.patterns")

-- Capture command line arguments at file scope
local tArgs = { ... }

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

-- ============================================
-- STARTUP VALIDATION
-- ============================================

local function validateStartup()
    local adjustedSize, numBranches = core.calculateAdjustedSize(core.config.squareSize)
    local startOffset = core.config.branchSpacing + 1
    local branchLength = adjustedSize - 2 * startOffset
    
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
    print("")
    
    -- Check fuel
    if not fuel.isUnlimited() then
        local pokeholeExtra = core.config.usePokeholes and 
            ((4 * adjustedSize + numBranches * branchLength) / core.config.pokeholeInterval * 2) or 0
        local totalDistance = (4 * adjustedSize) + (numBranches * branchLength) + 
            (numBranches * startOffset * 2) + pokeholeExtra
        
        print(string.format("Fuel needed: ~%d (current: %d)", math.ceil(totalDistance), fuel.getLevel()))
        
        if fuel.getLevel() < core.config.minFuelToStart then
            print("Refueling...")
            if not fuel.autoRefuel(core.config.minFuelToStart) then
                fuel.waitForFuel(core.config.minFuelToStart)
            end
        end
    end
    
    -- Check torches
    if core.config.placeTorches then
        local torchCount = core.getTorchCount()
        print(string.format("Torches: %d (slot %d)", torchCount, core.config.torchSlot))
        
        if torchCount == 0 then
            printError("ERROR: Torches required!")
            print(string.format("Place torches in slot %d and press Enter.", core.config.torchSlot))
            
            while core.getTorchCount() == 0 do
                read()
            end
            print(string.format("Found %d torches.", core.getTorchCount()))
        end
    end
    
    -- Check chest
    print("\nChecking for chest...")
    home.verifyChest()
    
    -- Confirm
    print("\nPress Enter to start mining (Ctrl+T to cancel).")
    read()
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
    print("")
    print("=== Mining Complete ===")
    print(string.format("Blocks mined: %d", core.stats.blocksMined))
    print(string.format("Ores found: %d", core.stats.oresMined))
    print(string.format("Return trips: %d", core.stats.tripsHome))
    print(string.format("Total time: %.0f seconds", os.clock() - core.stats.startTime))
end

-- Run with error handling
local success, err = pcall(main)
if not success then
    printError("Error: " .. tostring(err))
    print("Attempting to return home...")
    movement.goHome(true)
end
