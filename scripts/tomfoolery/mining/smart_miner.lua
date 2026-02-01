--- Smart Mining Turtle Script
-- An optimized branch mining turtle using wiki-recommended techniques for maximum efficiency
--
-- Features:
-- - Standard 1x2 tunnels (1 wide, 2 tall) as recommended by Minecraft Wiki
-- - Pokehole mining: Every 4 blocks, digs 1-block holes left and right to expose more ore
--   (This gives better blocks-revealed to blocks-mined ratio than wider tunnels)
-- - Branch spacing of 6 blocks for maximum efficiency (or 3 for balance)
-- - Checks all 6 directions for valuable ores and follows veins recursively
-- - Tracks position and can return home safely
-- - Manages inventory, discards junk, deposits valuables in chest
-- - Auto-refuels from inventory and chest
-- - Places torches at regular intervals
--
-- Mining Pattern (top-down view):
--   Main tunnel goes forward, branches go left/right
--   With pokeholes enabled, each branch looks like:
--     ═══╤═══╤═══╤═══  (main branch tunnel, 2 tall)
--        │   │   │     (pokeholes every 4 blocks, 1 tall, expose extra ore faces)
--
-- Efficiency (from wiki MATLAB analysis):
-- - Spacing 6: Maximum efficiency, ~1.7% of blocks are diamond
-- - Spacing 3: Good balance of efficiency and thoroughness
-- - Pokeholes: Reveal more blocks without mining full tunnels
--
-- Usage: smart_miner <length> [branches] [spacing]
--   length:  How far each branch extends (default: 50)
--   branches: Number of branches on each side (default: 5)
--   spacing: Blocks between branches (default: 6 for max efficiency)
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
    branchSpacing = 6,      -- Blocks between branches (6 = maximum efficiency per wiki)
                            -- Use 3 for balance of efficiency and thoroughness
    tunnelHeight = 2,       -- Height of tunnel (standard 1x2 as per wiki)
    
    -- Pokehole mining settings (from wiki "Layout 6")
    -- Every N blocks, dig 1-block holes to left and right to expose more ore
    -- This gives better blocks-revealed to blocks-mined ratio
    usePokeholes = true,    -- Enable pokehole mining for extra ore exposure
    pokeholeInterval = 4,   -- Dig pokeholes every N blocks (wiki recommends 4)
    
    -- Legacy snake mining (NOT recommended by wiki - uses more fuel, less efficient)
    useSnakeMining = false, -- Disabled - wiki recommends standard 1x2 tunnels
    
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
    
    -- First, try to refuel from inventory before deciding fuel is low
    local currentFuel = fuel.getLevel()
    local needed = fuelNeededToReturnHome()
    
    if currentFuel < needed then
        -- Try to refuel from inventory first
        fuel.autoRefuel(needed)
    end
    
    return fuel.getLevel() >= needed
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
                -- Look for fuel items in chest
                local attempts = 0
                while fuel.getLevel() < CONFIG.minFuelToStart and attempts < 27 do
                    attempts = attempts + 1
                    
                    -- Find empty slot
                    local emptySlot = nil
                    for slot = 1, 15 do
                        if turtle.getItemCount(slot) == 0 then
                            emptySlot = slot
                            break
                        end
                    end
                    
                    if not emptySlot then break end
                    
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
                
                -- Drop any non-fuel items back
                for slot = 1, 15 do
                    if turtle.getItemCount(slot) > 0 then
                        turtle.select(slot)
                        if not turtle.refuel(0) then
                            turtle.drop()
                        end
                    end
                end
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
        print("")
        print("========================================")
        printError("  ERROR: No chest found!")
        print("========================================")
        print("")
        print("The turtle expected a chest behind the")
        print("starting position but didn't find one.")
        print("")
        print("Please place a chest and press Enter.")
        
        -- Wait for chest to be placed
        while not isChestInFront() do
            read()
            if not isChestInFront() then
                print("Still no chest detected. Please place a chest.")
            end
        end
        print("Chest detected! Continuing...")
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
    
    -- Try to pick up fuel from chest if needed
    local needFuel = not fuel.isUnlimited() and fuel.getLevel() < CONFIG.minFuelToStart
    if needFuel then
        print("Looking for fuel in chest...")
        
        -- Strategy: Pull items from chest, keep fuel items, hold non-fuel temporarily
        -- Only put non-fuel back AFTER we've searched the whole chest
        -- This prevents the "pull same item repeatedly" bug
        
        local nonFuelSlots = {}  -- Track which slots have non-fuel items to return
        local chestEmpty = false
        
        -- Pull items until chest is empty or we have enough fuel
        while not chestEmpty and fuel.getLevel() < CONFIG.minFuelToStart do
            -- Find an empty slot to pull into
            local emptySlot = nil
            for slot = 1, 15 do
                if turtle.getItemCount(slot) == 0 then
                    emptySlot = slot
                    break
                end
            end
            
            if not emptySlot then
                -- Inventory full, consume any fuel we found
                fuel.autoRefuel(CONFIG.minFuelToStart)
                
                -- Now drop non-fuel items to make room and continue
                for slot = 1, 15 do
                    if turtle.getItemCount(slot) > 0 then
                        turtle.select(slot)
                        if not turtle.refuel(0) then
                            turtle.drop()
                        end
                    end
                end
                
                -- Check again for empty slot
                for slot = 1, 15 do
                    if turtle.getItemCount(slot) == 0 then
                        emptySlot = slot
                        break
                    end
                end
                
                if not emptySlot then
                    -- Still full (all fuel?), we're done
                    break
                end
            end
            
            turtle.select(emptySlot)
            if turtle.suck(64) then
                -- Got an item, check if it's fuel
                if turtle.refuel(0) then
                    -- It's fuel! Consume it immediately
                    turtle.refuel()
                    print(string.format("Refueled! Fuel: %d", fuel.getLevel()))
                else
                    -- Not fuel - keep it in inventory for now, don't put back yet
                    -- This prevents pulling the same item repeatedly
                    table.insert(nonFuelSlots, emptySlot)
                end
            else
                -- Chest is empty
                chestEmpty = true
            end
        end
        
        -- Now put all non-fuel items back into chest
        for _, slot in ipairs(nonFuelSlots) do
            if turtle.getItemCount(slot) > 0 then
                turtle.select(slot)
                turtle.drop()
            end
        end
        
        -- Also drop any other non-fuel items that might be in inventory
        for slot = 1, 15 do
            local detail = turtle.getItemDetail(slot)
            if detail then
                turtle.select(slot)
                if not turtle.refuel(0) then
                    turtle.drop()
                end
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
    
    -- Face the original mining direction first (direction 0)
    -- then turn around to face the chest behind the start position
    movement.turnTo(0)
    movement.turnAround()
    
    -- Deposit items and restock supplies
    depositAndRestock()
    
    -- Turn back to face mining direction
    movement.turnAround()
    
    -- Return to mining position
    print("Returning to mining position...")
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
-- Checks all 6 directions (front, back, left, right, up, down)
-- and recursively mines any ore veins found
local function checkForOres()
    if not CONFIG.checkOreVeins then return 0 end
    
    local oresFound = 0
    
    -- Check front - use recursive vein mining
    local front = miningUtils.inspectForward()
    if miningUtils.isOre(front) then
        oresFound = oresFound + miningUtils.checkAndMineOres(movement)
        stats.oresMined = stats.oresMined + 1
    end
    
    -- Check back (behind us)
    movement.turnAround()
    local back = miningUtils.inspectForward()
    if miningUtils.isOre(back) then
        oresFound = oresFound + miningUtils.checkAndMineOres(movement)
        stats.oresMined = stats.oresMined + 1
    end
    movement.turnAround()  -- Face forward again
    
    -- Check left
    movement.turnLeft()
    local left = miningUtils.inspectForward()
    if miningUtils.isOre(left) then
        oresFound = oresFound + miningUtils.checkAndMineOres(movement)
        stats.oresMined = stats.oresMined + 1
    end
    
    -- Check right (turn 180 from left)
    movement.turnAround()
    local right = miningUtils.inspectForward()
    if miningUtils.isOre(right) then
        oresFound = oresFound + miningUtils.checkAndMineOres(movement)
        stats.oresMined = stats.oresMined + 1
    end
    movement.turnLeft()  -- Face forward again
    
    -- Check up
    local up = miningUtils.inspectUp()
    if miningUtils.isOre(up) then
        miningUtils.digUp()
        movement.up(false)
        oresFound = oresFound + 1 + miningUtils.checkAndMineOres(movement)
        movement.down(false)
        stats.oresMined = stats.oresMined + 1
    end
    
    -- Check down  
    local down = miningUtils.inspectDown()
    if miningUtils.isOre(down) then
        miningUtils.digDown()
        movement.down(false)
        oresFound = oresFound + 1 + miningUtils.checkAndMineOres(movement)
        movement.up(false)
        stats.oresMined = stats.oresMined + 1
    end
    
    return oresFound
end

--- Check if there's already a torch above
local function hasTorchAbove()
    local success, block = turtle.inspectUp()
    if success then
        return block.name:match("torch") ~= nil
    end
    return false
end

--- Check if there's already a torch at a position (checks above from floor level)
local function hasTorchAtCurrentColumn()
    -- From floor level, check if there's a torch anywhere in this column
    local success, block = turtle.inspectUp()
    if success and block.name:match("torch") then
        return true
    end
    return false
end

--- Mine using the vertical snake pattern (1x3 tunnel with maximum ore exposure)
-- Pattern: At each forward step, turtle moves up/down in a snake to check all faces
--   Floor level (y=0):  check below + horizontal
--   Middle level (y=1): check horizontal (this is where forward movement happens)
--   Upper level (y=2):  check above + horizontal
--
-- Movement per step:
--   1. From floor: check ores at floor level (down, sides)
--   2. Dig up, move up to middle
--   3. Dig forward, move forward (advancing the tunnel)
--   4. Dig up again, move up to ceiling level
--   5. Check ores at ceiling level (up, sides)
--   6. Dig down (clear middle), move down to middle
--   7. Dig down (clear floor), move down to floor
--   8. Check ores at floor level
--   9. Place torch at floor level if needed
--   10. Repeat
--
-- This creates a 1x3 tunnel and checks all 6 directions at 2 different heights
local function mineSnakeStep(checkOres, placeTorch)
    -- === PHASE 1: Check ores at current floor position (before moving) ===
    if checkOres then
        checkForOres()
    end
    
    -- === PHASE 2: Move up to mining level and advance forward ===
    -- We mine from the middle height (y+1) so we can clear above and below
    miningUtils.digUp()
    stats.blocksMined = stats.blocksMined + 1
    movement.up(false)
    
    -- Dig forward and move into new column
    if turtle.detect() then
        miningUtils.digForward()
        stats.blocksMined = stats.blocksMined + 1
    end
    movement.forward(true)
    
    -- === PHASE 3: Clear and check ceiling level ===
    -- Dig up to ceiling, move up
    miningUtils.digUp()
    stats.blocksMined = stats.blocksMined + 1
    movement.up(false)
    
    -- Check ores at ceiling level (especially above us)
    if checkOres then
        checkForOres()
    end
    
    -- === PHASE 4: Clear middle and floor, move back down ===
    -- Move down to middle level
    movement.down(false)
    
    -- Dig down to clear floor level
    miningUtils.digDown()
    stats.blocksMined = stats.blocksMined + 1
    
    -- Move down to floor level
    movement.down(false)
    
    -- === PHASE 5: Check ores at floor level and place torch ===
    if checkOres then
        checkForOres()
    end
    
    -- Place torch at floor level (will be on the floor or wall)
    local existingTorch = hasTorchAtCurrentColumn()
    if placeTorch and getTorchCount() > 0 and not existingTorch then
        turtle.select(CONFIG.torchSlot)
        -- Place torch on the floor behind us for best lighting
        movement.turnAround()
        if not turtle.place() then
            -- If can't place behind, try below (on the ground)
            turtle.placeDown()
        end
        movement.turnAround()
    end
    
    -- Periodic cleanup
    if inventory.emptySlots() < 4 then
        inventory.dropJunk()
    end
end

--- Mine a simple 2-tall tunnel step with optional pokeholes
-- Standard 1x2 tunnel (wiki-recommended) with pokehole technique for extra ore exposure
local function mineSimpleTunnelStep(checkOres, placeTorch, stepNumber)
    -- Dig forward and move into the space
    digForwardAndMove()
    
    -- Check if there's a torch above before digging
    -- If there's already a torch, we're in an existing tunnel - skip digging up
    local existingTorch = hasTorchAbove()
    
    if not existingTorch then
        -- ALWAYS dig up to ensure 2-block tall tunnel
        -- This handles cases where gravel falls after we move
        miningUtils.digUp()
        if turtle.detectUp() then
            -- Still blocked? Try again (handles gravel)
            miningUtils.digUp()
            stats.blocksMined = stats.blocksMined + 1
        end
    end
    
    -- Check for ores if enabled (front, up, down)
    if checkOres then
        checkForOres()
    end
    
    -- Pokehole mining: Every N blocks, dig 1-block holes to left and right
    -- This exposes extra ore faces without mining full tunnels (wiki "Layout 6")
    if CONFIG.usePokeholes and stepNumber and (stepNumber % CONFIG.pokeholeInterval == 0) then
        -- Dig pokehole to the left
        movement.turnLeft()
        local leftBlock = miningUtils.inspectForward()
        if leftBlock then
            miningUtils.digForward()
            stats.blocksMined = stats.blocksMined + 1
            -- Check if we exposed ore in the pokehole
            if checkOres and miningUtils.isOre(miningUtils.inspectForward()) then
                miningUtils.checkAndMineOres(movement)
            end
        end
        
        -- Dig pokehole to the right (turn 180)
        movement.turnAround()
        local rightBlock = miningUtils.inspectForward()
        if rightBlock then
            miningUtils.digForward()
            stats.blocksMined = stats.blocksMined + 1
            -- Check if we exposed ore in the pokehole
            if checkOres and miningUtils.isOre(miningUtils.inspectForward()) then
                miningUtils.checkAndMineOres(movement)
            end
        end
        
        -- Turn back to face forward
        movement.turnLeft()
    end
    
    -- Place torch if needed (and we have torches, and no torch already there)
    if placeTorch and getTorchCount() > 0 and not existingTorch then
        turtle.select(CONFIG.torchSlot)
        turtle.placeUp()
    end
    
    -- Periodic cleanup
    if inventory.emptySlots() < 4 then
        inventory.dropJunk()
    end
end

--- Mine a tunnel step using configured method
local function mineTunnelStep(checkOres, placeTorch, stepNumber)
    if CONFIG.useSnakeMining then
        mineSnakeStep(checkOres, placeTorch)
    else
        mineSimpleTunnelStep(checkOres, placeTorch, stepNumber)
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
        
        -- Mine one step forward (pass step number for pokehole timing)
        mineTunnelStep(CONFIG.checkOreVeins, placeTorch, step)
        
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
            -- Main tunnel doesn't need pokeholes (branches cover those areas)
            mineTunnelStep(true, step == CONFIG.branchSpacing + 1, nil)
        end
        
        -- Mine right branch
        branchNum = branchNum + 1
        print(string.format("Mining branch %d (right)...", branchNum))
        local branchStartPos = movement.getPosition()  -- Remember Y level before branch
        movement.turnRight()
        mineBranch(CONFIG.branchLength)
        
        -- Return to main tunnel
        -- Note: We don't check fuel here because:
        -- 1. mineBranch already ensured we have enough fuel to return
        -- 2. If we went home mid-branch, depositAndRestock waits for fuel
        movement.turnAround()
        print("Returning to main tunnel...")
        for step = 1, CONFIG.branchLength do
            movement.forward(true)
        end
        -- Ensure we're at the correct Y level (snake mining should end at floor level)
        local currentPos = movement.getPosition()
        while currentPos.y > branchStartPos.y do
            movement.down(false)
            currentPos = movement.getPosition()
        end
        while currentPos.y < branchStartPos.y do
            movement.up(false)
            currentPos = movement.getPosition()
        end
        
        -- Mine left branch
        branchNum = branchNum + 1
        print(string.format("Mining branch %d (left)...", branchNum))
        -- Already facing back, so turn right to face left branch
        movement.turnRight()
        mineBranch(CONFIG.branchLength)
        
        -- Return to main tunnel
        movement.turnAround()
        print("Returning to main tunnel...")
        for step = 1, CONFIG.branchLength do
            movement.forward(true)
        end
        -- Ensure we're at the correct Y level
        currentPos = movement.getPosition()
        while currentPos.y > branchStartPos.y do
            movement.down(false)
            currentPos = movement.getPosition()
        end
        while currentPos.y < branchStartPos.y do
            movement.up(false)
            currentPos = movement.getPosition()
        end
        movement.turnRight()  -- Face forward again
    end
    
    -- Return home
    print("Mining complete! Returning home...")
    movement.goHome(true)
    
    -- Face original direction then turn to chest
    movement.turnTo(0)
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
    if CONFIG.useSnakeMining then
        print("Mining mode: SNAKE (1x3 tunnel)")
    elseif CONFIG.usePokeholes then
        print(string.format("Mining mode: POKEHOLE (1x2 tunnel + holes every %d blocks)", CONFIG.pokeholeInterval))
    else
        print("Mining mode: SIMPLE (1x2 tunnel)")
    end
    print("")
    
    -- Check fuel
    if not fuel.isUnlimited() then
        -- Pokeholes add ~2 extra blocks mined per interval
        local pokeholeExtra = CONFIG.usePokeholes and (CONFIG.branchLength / CONFIG.pokeholeInterval * 2) or 0
        local totalDistance = CONFIG.branchLength * CONFIG.branchCount * 4 + 
                              CONFIG.branchCount * CONFIG.branchSpacing * 2 +
                              CONFIG.branchCount * 2 * pokeholeExtra
        print(string.format("Estimated fuel needed: %d", math.ceil(totalDistance)))
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
    -- At startup, facing should be 0 (forward), so turnAround faces chest
    movement.turnAround()
    if isChestInFront() then
        print("Chest detected!")
    else
        printError("WARNING: No chest detected behind turtle!")
        print("Place a chest behind the turtle for deposits.")
        print("Press Enter to continue anyway, or add chest first.")
        read()
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
