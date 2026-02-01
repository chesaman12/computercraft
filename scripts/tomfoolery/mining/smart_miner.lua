--- Smart Mining Turtle Script
-- An optimized square perimeter mining turtle using wiki-recommended techniques
--
-- Features:
-- - Square perimeter mining: mines a complete square, then fills with parallel branches
-- - Auto-adjusts square size to ensure proper spacing (3 blocks between edges and branches)
-- - Standard 1x2 tunnels (1 wide, 2 tall) as recommended by Minecraft Wiki
-- - Efficient human-like mining pattern: checks both floor and ceiling levels
-- - Pokehole mining on ALL tunnels: Every 4 blocks, enters pokeholes and checks 5 directions
-- - Serpentine branch pattern: alternates east/west for efficient coverage
-- - Minimal turning: uses left/right checks instead of full 360 scans
-- - Keeps fuel in inventory for mobile refueling
-- - Tracks position and can return home safely
-- - Manages inventory, discards junk, deposits valuables in chest
-- - Places torches at regular intervals
--
-- Mining Pattern:
--   Phase 1 - Perimeter: Mine east -> north -> west -> south (back to origin)
--             Pokeholes are mined on the perimeter (facing inward)
--   Phase 2 - Branches: Serpentine pattern inside the square
--     - First branch starts 4 blocks inside the perimeter (3 blocks of stone between)
--     - Mine east across the square
--     - Move north (spacing+1 blocks), mine west
--     - Repeat until square is filled
--     - Last branch ends 4 blocks from the opposite edge
--
-- Size Adjustment:
--   The requested size is auto-adjusted to the nearest valid size that ensures:
--   - Exactly 3 blocks between perimeter and first branch
--   - Exactly 3 blocks between last branch and opposite perimeter
--   - All branches evenly spaced
--   Example: Requested 25 -> Adjusted to 26 (gives 5 branches)
--
-- Usage: smart_miner <size> [spacing]
--   size:    Target square size (will be auto-adjusted, default: 25)
--   spacing: Blocks between internal branches (default: 3)
--
-- IMPORTANT: Run from the root installation directory (where common/ is):
--   mining/smart_miner 25
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
    -- Square mining parameters
    -- The turtle mines a square perimeter, then fills it with parallel branches
    -- Size will be auto-adjusted to ensure proper spacing from edges
    squareSize = 25,        -- Target size of the square (will be rounded for proper spacing)
    branchSpacing = 3,      -- Blocks between internal branches (3 = every 4th block)
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
        CONFIG.squareSize = tonumber(tArgs[1]) or CONFIG.squareSize
    end
    if tArgs[2] then
        CONFIG.branchSpacing = tonumber(tArgs[2]) or CONFIG.branchSpacing
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
    
    -- Dump inventory into chest (keep slot 16 for torches, keep fuel for mobile refueling)
    for slot = 1, 15 do
        local detail = turtle.getItemDetail(slot)
        if detail then
            turtle.select(slot)
            -- Check if this item is fuel - if so, keep it!
            if not turtle.refuel(0) then
                -- Not fuel, deposit it
                turtle.drop()
            else
                -- It's fuel - keep in inventory for mobile refueling
                print(string.format("Keeping fuel in slot %d: %s", slot, detail.name))
            end
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
                    -- It's fuel! Keep ONE STACK in inventory for mobile refueling
                    -- Only consume what we need right now
                    local neededFuel = CONFIG.minFuelToStart - fuel.getLevel()
                    if neededFuel > 0 then
                        -- Try to refuel just what we need
                        turtle.refuel()
                        print(string.format("Refueled! Fuel: %d", fuel.getLevel()))
                    end
                    -- Keep the fuel stack - don't mark it for return!
                    -- This allows mobile refueling while mining
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
        
        -- Now put all non-fuel items back into chest (but KEEP fuel!)
        for _, slot in ipairs(nonFuelSlots) do
            if turtle.getItemCount(slot) > 0 then
                turtle.select(slot)
                turtle.drop()
            end
        end
        -- Note: Fuel stacks are NOT in nonFuelSlots, so they stay in inventory
        
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

--- Check for ore and mine vein if found
-- Helper function to reduce code duplication
local function checkAndMineOre(inspectFunc, digFunc, moveFunc, returnFunc)
    if not CONFIG.checkOreVeins then return 0 end
    
    local block = inspectFunc()
    if miningUtils.isOre(block) then
        digFunc()
        if moveFunc then
            moveFunc()
            local mined = miningUtils.checkAndMineOres(movement)
            if returnFunc then returnFunc() end
            stats.oresMined = stats.oresMined + 1 + mined
            return 1 + mined
        else
            stats.oresMined = stats.oresMined + 1
            return 1
        end
    end
    return 0
end

--- Check left wall for ore (efficient: single turn)
local function checkLeftOre()
    movement.turnLeft()
    local result = checkAndMineOre(
        miningUtils.inspectForward,
        function() miningUtils.digForward() end,
        function() movement.forward(false) end,
        function() movement.back() end
    )
    movement.turnRight()
    return result
end

--- Check right wall for ore (efficient: single turn)
local function checkRightOre()
    movement.turnRight()
    local result = checkAndMineOre(
        miningUtils.inspectForward,
        function() miningUtils.digForward() end,
        function() movement.forward(false) end,
        function() movement.back() end
    )
    movement.turnLeft()
    return result
end

--- Check block below for ore
local function checkDownOre()
    return checkAndMineOre(
        miningUtils.inspectDown,
        function() miningUtils.digDown() end,
        function() movement.down(false) end,
        function() movement.up(false) end
    )
end

--- Check block above for ore
local function checkUpOre()
    return checkAndMineOre(
        miningUtils.inspectUp,
        function() miningUtils.digUp() end,
        function() movement.up(false) end,
        function() movement.down(false) end
    )
end

--- Check block in front for ore
local function checkFrontOre()
    return checkAndMineOre(
        miningUtils.inspectForward,
        function() miningUtils.digForward() end,
        function() movement.forward(false) end,
        function() movement.back() end
    )
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

--- Explore a pokehole: enter it and check all 5 directions for ore
-- @param direction string "left" or "right"
local function explorePokeholeOres()
    -- Inside the pokehole, check all 5 directions:
    -- front (deeper into wall), left, right, up, down
    checkFrontOre()
    checkLeftOre()
    checkRightOre()
    checkUpOre()
    checkDownOre()
end

--- Mine a tunnel step mimicking efficient human mining pattern
-- Pattern per step:
--   1. At floor: check below, left, right
--   2. Dig up and move up to head height
--   3. At head height: check left, right, ceiling
--   4. Move down to floor
--   5. Place torch above if needed
--   6. If pokehole step: dig left pokehole, enter, check 5 dirs, return
--   7. If pokehole step: dig right pokehole, enter, check 5 dirs, return
--   8. Dig forward and move forward
local function mineSimpleTunnelStep(checkOres, placeTorch, stepNumber)
    -- Check if there's a torch above (existing tunnel)
    local existingTorch = hasTorchAbove()
    
    -- === FLOOR LEVEL CHECKS ===
    if checkOres then
        -- Check below (floor ore)
        checkDownOre()
        -- Check left wall at floor level
        checkLeftOre()
        -- Check right wall at floor level
        checkRightOre()
    end
    
    -- === MOVE UP TO HEAD HEIGHT ===
    if not existingTorch then
        miningUtils.digUp()
        stats.blocksMined = stats.blocksMined + 1
    end
    movement.up(false)
    
    -- === HEAD HEIGHT CHECKS ===
    if checkOres then
        -- Check left wall at head height
        checkLeftOre()
        -- Check right wall at head height
        checkRightOre()
        -- Check ceiling
        checkUpOre()
    end
    
    -- === MOVE BACK DOWN TO FLOOR ===
    movement.down(false)
    
    -- === PLACE TORCH ===
    if placeTorch and getTorchCount() > 0 and not existingTorch then
        turtle.select(CONFIG.torchSlot)
        turtle.placeUp()
    end
    
    -- === POKEHOLE MINING ===
    -- Every N blocks, dig pokeholes and explore them for ore
    if CONFIG.usePokeholes and stepNumber and (stepNumber % CONFIG.pokeholeInterval == 0) then
        -- Left pokehole: dig, enter, check all directions, return
        movement.turnLeft()
        if turtle.detect() then
            miningUtils.digForward()
            stats.blocksMined = stats.blocksMined + 1
        end
        movement.forward(true)  -- Enter the pokehole
        if checkOres then
            explorePokeholeOres()
        end
        movement.back()  -- Return to tunnel
        movement.turnRight()  -- Face forward
        
        -- Right pokehole: dig, enter, check all directions, return
        movement.turnRight()
        if turtle.detect() then
            miningUtils.digForward()
            stats.blocksMined = stats.blocksMined + 1
        end
        movement.forward(true)  -- Enter the pokehole
        if checkOres then
            explorePokeholeOres()
        end
        movement.back()  -- Return to tunnel
        movement.turnLeft()  -- Face forward
    end
    
    -- === DIG FORWARD AND ADVANCE ===
    digForwardAndMove()
    
    -- Ensure headroom (handle gravel that may have fallen)
    if not hasTorchAbove() and turtle.detectUp() then
        miningUtils.digUp()
        stats.blocksMined = stats.blocksMined + 1
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

--- Mine one side of the perimeter
-- @param length number Length of this side
local function minePerimeterSide(length)
    print(string.format("Mining perimeter side: %d blocks", length))
    for step = 1, length do
        -- Safety check
        if not hasSafeFuel() then
            returnHomeAndDeposit()
        end
        
        -- Check inventory
        if inventory.isFull(2) then
            print("Inventory full, returning home...")
            returnHomeAndDeposit()
        end
        
        -- Determine torch placement
        local placeTorch = CONFIG.placeTorches and (step % CONFIG.torchInterval == 0)
        if placeTorch and getTorchCount() == 0 then
            print("Out of torches! Returning home...")
            returnHomeAndDeposit()
        end
        
        -- Mine one step with pokeholes (pass step number to enable pokeholes on perimeter too)
        mineTunnelStep(CONFIG.checkOreVeins, placeTorch, step)
        
        if step % 10 == 0 then
            printStatus()
        end
    end
end

--- Mine the square perimeter (east -> north -> west -> south back to origin)
-- @param size number The adjusted square size to mine
local function mineSquarePerimeter(size)
    print("=== Mining Square Perimeter ===")
    print(string.format("Adjusted square size: %d x %d", size, size))
    sleep(1)
    
    -- East side (we start facing forward which is "east" in our coordinate system)
    print("Mining EAST side...")
    minePerimeterSide(size)
    
    -- Turn left to face north
    movement.turnLeft()
    
    -- North side
    print("Mining NORTH side...")
    minePerimeterSide(size)
    
    -- Turn left to face west
    movement.turnLeft()
    
    -- West side
    print("Mining WEST side...")
    minePerimeterSide(size)
    
    -- Turn left to face south
    movement.turnLeft()
    
    -- South side (back to origin)
    print("Mining SOUTH side...")
    minePerimeterSide(size)
    
    -- Turn left to face east again (original direction)
    movement.turnLeft()
    
    print("Perimeter complete! Now at origin facing east.")
end

--- Calculate the adjusted square size to ensure proper branch spacing
-- The size is adjusted so that:
-- 1. There are exactly branchSpacing blocks between the perimeter and first branch
-- 2. There are exactly branchSpacing blocks between the last branch and opposite perimeter
-- 3. All internal branches are evenly spaced
-- @param targetSize number The requested square size
-- @return number The adjusted square size
local function calculateAdjustedSquareSize(targetSize)
    local spacing = CONFIG.branchSpacing + 1  -- +1 because we count the branch position too
    
    -- The square needs: 
    -- - 1 block for south perimeter wall
    -- - branchSpacing blocks before first branch  
    -- - N branches with (branchSpacing) blocks between each
    -- - branchSpacing blocks after last branch
    -- - 1 block for north perimeter wall
    -- 
    -- So: size = 2 + spacing + (numBranches - 1) * spacing + spacing
    --          = 2 + spacing * (numBranches + 1)
    --          = 2 + spacing + numBranches * spacing
    --
    -- Solving for numBranches given targetSize:
    -- numBranches = floor((targetSize - 2 - spacing) / spacing)
    -- Then recalculate actual size
    
    local numBranches = math.floor((targetSize - 2 - spacing) / spacing)
    if numBranches < 1 then numBranches = 1 end
    
    -- Actual size = perimeter (2) + initial gap (spacing) + branches-1 gaps + final gap
    -- = 2 + spacing + (numBranches - 1) * spacing + spacing
    -- = 2 + spacing * (numBranches + 1)
    local adjustedSize = 2 + spacing * (numBranches + 1)
    
    return adjustedSize, numBranches
end

--- Mine all internal branches (parallel tunnels filling the square)
-- Uses a serpentine pattern: mine east, move north, mine west, move north, repeat
local function mineInternalBranches()
    -- Use the adjusted size stored by squareMine()
    local adjustedSize = CONFIG.adjustedSquareSize
    local _, numBranches = calculateAdjustedSquareSize(CONFIG.squareSize)
    
    -- Branch length calculation:
    -- We start at position (startOffset, startOffset) from origin
    -- We end at position (adjustedSize - startOffset - 1) 
    -- So length = adjustedSize - 2 * startOffset
    local startOffset = CONFIG.branchSpacing + 1
    local branchLength = adjustedSize - 2 * startOffset
    
    print("=== Mining Internal Branches ===")
    print(string.format("Adjusted square size: %d", adjustedSize))
    print(string.format("Branches: %d (spaced %d blocks apart)", numBranches, CONFIG.branchSpacing))
    print(string.format("Branch length: %d blocks each", branchLength))
    print(string.format("Starting offset: %d blocks from edge", startOffset))
    
    -- Sanity check
    if numBranches < 1 then
        print("ERROR: No branches to mine (numBranches < 1)!")
        return
    end
    if branchLength < 1 then
        print("ERROR: Branch length too short (branchLength < 1)!")
        return
    end
    
    sleep(1)
    
    -- We're at origin (southwest corner) facing east
    -- Need to move to the first branch starting position:
    -- - startOffset blocks east (into the interior, leaving proper gap from west wall)
    -- - startOffset blocks north (leaving proper gap from south wall)
    -- This area is UNMINED (interior of square), so we need to mine our way in
    
    print(string.format("Moving to first branch position (%d blocks in)...", startOffset))
    print("Step 1: Mining east into square...")
    
    -- Mine east into the square (2-tall tunnel through unmined interior)
    for i = 1, startOffset do
        print(string.format("  East step %d/%d", i, startOffset))
        miningUtils.digForward()   -- Dig block in front at floor level
        turtle.digUp()             -- Dig block above (head height)
        movement.forward(true)
    end
    
    -- Turn north and mine to first branch row
    print("Step 2: Turning north...")
    movement.turnLeft()
    
    print("Step 3: Mining north to first branch row...")
    for i = 1, startOffset do
        print(string.format("  North step %d/%d", i, startOffset))
        miningUtils.digForward()   -- Dig block in front at floor level
        turtle.digUp()             -- Dig block above (head height)
        movement.forward(true)
    end
    
    -- Turn east to start first branch
    print("Step 4: Turning east, ready for first branch...")
    movement.turnRight()
    
    -- Now we're at the starting position for branch 1, facing east
    -- Track which side we're on: true = at west side (go east), false = at east side (go west)
    local atWestSide = true
    
    for branchNum = 1, numBranches do
        -- Check safety
        if not hasSafeFuel() then
            print("Low fuel, returning home...")
            returnHomeAndDeposit()
        end
        
        -- Check inventory
        if inventory.isFull(2) then
            print("Inventory full, returning home...")
            returnHomeAndDeposit()
        end
        
        -- For branches after the first, move north to the next branch position
        if branchNum > 1 then
            -- We just finished mining a branch and are at the opposite side
            -- Turn to face north (depends on which side we're at)
            if atWestSide then
                -- We're at west side, facing east - turn left to face north
                movement.turnLeft()
            else
                -- We're at east side, facing west - turn right to face north
                movement.turnRight()
            end
            
            -- Mine north by spacing + 1 blocks to reach the next branch row
            -- This is through UNMINED stone between branches
            print(string.format("Mining north to branch %d...", branchNum))
            for step = 1, CONFIG.branchSpacing + 1 do
                if not hasSafeFuel() then returnHomeAndDeposit() end
                miningUtils.digForward()   -- Dig at floor level
                turtle.digUp()             -- Dig at head height  
                movement.forward(true)
            end
            
            -- Turn to face the mining direction for this branch
            if atWestSide then
                -- We were at west, now need to mine east
                movement.turnRight()  -- Face east
            else
                -- We were at east, now need to mine west  
                movement.turnLeft()   -- Face west
            end
        end
        
        -- Mine this branch
        local direction = atWestSide and "east" or "west"
        print(string.format("Mining branch %d/%d (%s)...", branchNum, numBranches, direction))
        mineBranch(branchLength)
        
        -- After mining, we're now at the opposite side
        atWestSide = not atWestSide
    end
    
    print("All internal branches complete!")
end

--- Main square mining pattern
-- Mines a square perimeter, then fills with parallel branches
local function squareMine()
    -- Calculate the adjusted square size for proper branch spacing
    local adjustedSize, numBranches = calculateAdjustedSquareSize(CONFIG.squareSize)
    
    print(string.format("Square mining pattern:"))
    print(string.format("  Requested size: %d", CONFIG.squareSize))
    print(string.format("  Adjusted size: %d x %d (for proper spacing)", adjustedSize, adjustedSize))
    print(string.format("  Branch spacing: %d blocks", CONFIG.branchSpacing))
    print(string.format("  Number of branches: %d", numBranches))
    print("")
    sleep(2)
    
    -- Store adjusted size in CONFIG for other functions to use
    CONFIG.adjustedSquareSize = adjustedSize
    
    -- Phase 1: Mine the perimeter
    mineSquarePerimeter(adjustedSize)
    
    -- Return home and restock before branches
    print("Perimeter done! Restocking...")
    movement.goHome(true)
    movement.turnTo(0)
    movement.turnAround()
    depositAndRestock()
    movement.turnAround()
    
    -- Phase 2: Mine internal branches
    mineInternalBranches()
    
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
    
    -- Calculate adjusted size for display
    local adjustedSize, numBranches = calculateAdjustedSquareSize(CONFIG.squareSize)
    local startOffset = CONFIG.branchSpacing + 1
    local branchLength = adjustedSize - 2 * startOffset
    
    print("=== Smart Mining Turtle ===")
    print(string.format("Requested size: %d | Adjusted: %d x %d", CONFIG.squareSize, adjustedSize, adjustedSize))
    print(string.format("Branch spacing: %d blocks (%d branches)", CONFIG.branchSpacing, numBranches))
    print(string.format("Branch length: %d blocks each", branchLength))
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
        -- Estimate fuel usage with adjusted values
        local pokeholeExtra = CONFIG.usePokeholes and ((4 * adjustedSize + numBranches * branchLength) / CONFIG.pokeholeInterval * 2) or 0
        local totalDistance = (4 * adjustedSize) +                -- Perimeter
                              (numBranches * branchLength) +      -- Mining branches
                              (numBranches * startOffset * 2) +   -- Moving to/between branches
                              pokeholeExtra
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
    movement.setFacing(0)  -- Assume facing east (into the mine)
    stats.startTime = os.clock()
    
    -- Start square mining pattern
    squareMine()
    
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
