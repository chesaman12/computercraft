--- Mining patterns module for smart mining turtle
-- High-level mining patterns: perimeter, branches, square mine
-- @module miner.patterns

local M = {}

local core = nil
local home = nil
local tunnel = nil

--- Initialize with module references
-- @param coreModule table The miner.core module
-- @param homeModule table The miner.home module
-- @param tunnelModule table The miner.tunnel module
function M.init(coreModule, homeModule, tunnelModule)
    core = coreModule
    home = homeModule
    tunnel = tunnelModule
end

-- ============================================
-- SAFETY CHECKS
-- ============================================

--- Perform safety checks and return home if needed
-- @return boolean True if returned home
local function safetyCheck()
    if not core.hasSafeFuel() then
        print("WARNING: Fuel getting low, returning home...")
        home.returnHomeAndDeposit()
        return true
    end
    
    if core.inventory.emptySlots() <= core.config.inventoryThreshold then
        print("Inventory full, returning home...")
        home.returnHomeAndDeposit()
        return true
    end
    
    if core.config.placeTorches and core.getTorchCount() == 0 then
        print("Out of torches, returning home...")
        home.returnHomeAndDeposit()
        return true
    end
    
    return false
end

-- ============================================
-- BRANCH MINING
-- ============================================

--- Mine a single branch (straight tunnel)
-- @param length number Length of the branch
function M.mineBranch(length)
    local stepsSinceCheck = 0
    
    for step = 1, length do
        stepsSinceCheck = stepsSinceCheck + 1
        
        -- Periodic safety checks
        if stepsSinceCheck >= core.config.fuelCheckInterval then
            stepsSinceCheck = 0
            safetyCheck()
        end
        
        -- Determine torch placement
        local placeTorch = core.config.placeTorches and (step % core.config.torchInterval == 0)
        
        if placeTorch and core.getTorchCount() == 0 then
            print("Out of torches! Returning home...")
            home.returnHomeAndDeposit()
        end
        
        -- Mine one step
        tunnel.mineStep(core.config.checkOreVeins, placeTorch, step)
        
        -- Update display
        if step % 10 == 0 then
            core.printStatus()
        end
    end
end

-- ============================================
-- PERIMETER MINING
-- ============================================

--- Mine one side of the perimeter
-- @param length number Length of this side
local function minePerimeterSide(length)
    print(string.format("Mining perimeter side: %d blocks", length))
    
    for step = 1, length do
        safetyCheck()
        
        local placeTorch = core.config.placeTorches and (step % core.config.torchInterval == 0)
        if placeTorch and core.getTorchCount() == 0 then
            home.returnHomeAndDeposit()
        end
        
        tunnel.mineStep(core.config.checkOreVeins, placeTorch, step)
        
        if step % 10 == 0 then
            core.printStatus()
        end
    end
end

--- Mine the square perimeter (east -> north -> west -> south)
-- @param size number The square size
function M.minePerimeter(size)
    print("=== Mining Square Perimeter ===")
    print(string.format("Square size: %d x %d", size, size))
    sleep(1)
    
    -- East side
    print("Mining EAST side...")
    minePerimeterSide(size)
    core.movement.turnLeft()
    
    -- North side
    print("Mining NORTH side...")
    minePerimeterSide(size)
    core.movement.turnLeft()
    
    -- West side
    print("Mining WEST side...")
    minePerimeterSide(size)
    core.movement.turnLeft()
    
    -- South side (back to origin)
    print("Mining SOUTH side...")
    minePerimeterSide(size)
    core.movement.turnLeft()
    
    print("Perimeter complete!")
end

-- ============================================
-- INTERNAL BRANCHES
-- ============================================

--- Mine all internal branches (parallel tunnels filling the square)
function M.mineInternalBranches()
    local adjustedSize = core.config.adjustedSquareSize
    local _, numBranches = core.calculateAdjustedSize(core.config.squareSize)
    
    -- branchSpacing is the north-south spacing between branches
    local branchSpacing = core.config.branchSpacing + 1
    
    -- Branches start 1 block inside the perimeter and span nearly the full width
    local edgeMargin = 1  -- 1 block inside the perimeter on each side
    local branchLength = adjustedSize - (2 * edgeMargin)
    
    print("=== Mining Internal Branches ===")
    print(string.format("  Branches: %d, Length: %d", numBranches, branchLength))
    print(string.format("  Spacing: %d, EdgeMargin: %d", branchSpacing, edgeMargin))
    
    if numBranches < 1 or branchLength < 1 then
        print("ERROR: Invalid branch parameters!")
        print(string.format("  adjustedSize=%d, branchLength=%d", adjustedSize, branchLength))
        return
    end
    
    sleep(1)
    
    for branchNum = 1, numBranches do
        print(string.format("\n====== BRANCH %d of %d ======", branchNum, numBranches))
        
        safetyCheck()
        
        -- Go home and face east
        print("Returning to origin...")
        core.movement.goHome(true)
        core.movement.turnTo(0)
        
        -- Calculate branch Z position (north-south offset from origin)
        -- First branch at branchSpacing, then every branchSpacing blocks after
        local branchZ = branchSpacing + (branchNum - 1) * branchSpacing
        
        print(string.format("Target: X=%d, Z=%d", edgeMargin, branchZ))
        
        -- Mine east to edgeMargin (just 1 block inside the perimeter)
        print(string.format("Mining EAST %d blocks...", edgeMargin))
        for i = 1, edgeMargin do
            core.mining.digForward()
            turtle.digUp()
            core.movement.forward(true)
        end
        
        -- Turn north and mine to branchZ
        core.movement.turnLeft()
        print(string.format("Mining NORTH %d blocks...", branchZ))
        for i = 1, branchZ do
            core.mining.digForward()
            turtle.digUp()
            core.movement.forward(true)
        end
        
        -- Turn east and mine the branch
        core.movement.turnRight()
        print(string.format("Mining BRANCH %d blocks EAST...", branchLength))
        M.mineBranch(branchLength)
        
        print(string.format("Branch %d complete!", branchNum))
    end
    
    print("\n=== All internal branches complete! ===")
end

-- ============================================
-- SQUARE MINING PATTERN
-- ============================================

--- Execute the complete square mining pattern
function M.squareMine()
    local adjustedSize, numBranches = core.calculateAdjustedSize(core.config.squareSize)
    core.config.adjustedSquareSize = adjustedSize
    
    print(string.format("Square mining: %d x %d (%d branches)", adjustedSize, adjustedSize, numBranches))
    sleep(2)
    
    -- Phase 1: Mine the perimeter
    M.minePerimeter(adjustedSize)
    
    -- Restock before branches
    print("Perimeter done! Restocking...")
    core.movement.goHome(true)
    core.movement.turnTo(0)
    core.movement.turnAround()
    home.depositAndRestock()
    core.movement.turnAround()
    
    -- Phase 2: Mine internal branches
    M.mineInternalBranches()
    
    -- Return home
    print("Mining complete! Returning home...")
    core.movement.goHome(true)
    core.movement.turnTo(0)
    core.movement.turnAround()
    home.depositAndRestock()
end

return M
