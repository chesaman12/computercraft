--- Core module for smart mining turtle
-- Configuration, state tracking, statistics, and shared utilities
-- @module miner.core

local M = {}

-- ============================================
-- CONFIGURATION
-- ============================================

M.config = {
    -- Square mining parameters
    squareSize = 25,
    branchSpacing = 3,
    tunnelHeight = 2,
    
    -- Pokehole mining (wiki "Layout 6")
    usePokeholes = true,
    pokeholeInterval = 4,
    
    -- Snake mining (NOT recommended - less efficient)
    useSnakeMining = false,
    
    -- Mining dimension mode: mine everything except junk (stone, deepslate, dirt)
    -- instead of only mining specific ores
    miningDimensionMode = true,
    
    -- Behavior
    placeFloors = false,
    placeTorches = true,
    torchInterval = 8,
    torchSlot = 16,
    checkOreVeins = true,
    
    -- Safety
    minFuelToStart = 500,
    fuelReserve = 200,
    fuelCheckInterval = 5,
    inventoryThreshold = 2,
    
    -- Home position
    homeX = 0,
    homeY = 0,
    homeZ = 0,
    
    -- Computed at runtime
    adjustedSquareSize = nil,
}

-- ============================================
-- STATE
-- ============================================

M.stats = {
    blocksMined = 0,
    oresMined = 0,
    tripsHome = 0,
    startTime = 0,
}

-- ============================================
-- DEPENDENCIES (set by init)
-- ============================================

M.movement = nil
M.inventory = nil
M.mining = nil
M.fuel = nil

--- Initialize core with required dependencies
-- @param deps table {movement, inventory, mining, fuel}
function M.init(deps)
    M.movement = deps.movement
    M.inventory = deps.inventory
    M.mining = deps.mining
    M.fuel = deps.fuel
    M.stats.startTime = os.clock()
end

--- Parse command line arguments
-- @param args table Command line arguments
function M.parseArgs(args)
    if args[1] then
        M.config.squareSize = tonumber(args[1]) or M.config.squareSize
    end
    if args[2] then
        M.config.branchSpacing = tonumber(args[2]) or M.config.branchSpacing
    end
end

-- ============================================
-- UTILITIES
-- ============================================

--- Get torch count from designated slot
-- @return number Torch count
function M.getTorchCount()
    local detail = turtle.getItemDetail(M.config.torchSlot)
    if detail and detail.name:match("torch") then
        return detail.count
    end
    return 0
end

--- Check if block in front is a chest
-- @return boolean
function M.isChestInFront()
    local success, block = turtle.inspect()
    return success and block.name:match("chest") ~= nil
end

--- Check if there's a torch above current position
-- @return boolean
function M.hasTorchAbove()
    local success, block = turtle.inspectUp()
    return success and block.name:match("torch") ~= nil
end

--- Calculate fuel needed to return home
-- @return number Fuel needed
function M.fuelNeededForReturn()
    local pos = M.movement.getPosition()
    local distance = math.abs(pos.x) + math.abs(pos.y) + math.abs(pos.z)
    return distance + M.config.fuelReserve
end

--- Check if we have enough fuel to continue safely
-- @return boolean
function M.hasSafeFuel()
    if M.fuel.isUnlimited() then
        return true
    end
    
    local needed = M.fuelNeededForReturn()
    if M.fuel.getLevel() < needed then
        M.fuel.autoRefuel(needed)
    end
    
    return M.fuel.getLevel() >= needed
end

--- Check if we should return home for any reason
-- @return boolean, string|nil Whether to return, reason
function M.shouldReturnHome()
    local pos = M.movement.getPosition()
    local fuelNeeded = M.fuelNeededForReturn()
    
    if M.inventory.emptySlots() <= M.config.inventoryThreshold then
        return true, "inventory full"
    end
    
    if not M.fuel.isUnlimited() and M.fuel.getLevel() < fuelNeeded then
        return true, "low fuel"
    end
    
    if M.config.placeTorches and M.getTorchCount() == 0 then
        return true, "out of torches"
    end
    
    return false
end

--- Calculate adjusted square size for proper branch spacing
-- @param targetSize number Requested size
-- @return number, number Adjusted size, number of branches
function M.calculateAdjustedSize(targetSize)
    local spacing = M.config.branchSpacing + 1
    local numBranches = math.floor((targetSize - 2 - spacing) / spacing)
    if numBranches < 1 then numBranches = 1 end
    local adjustedSize = 2 + spacing * (numBranches + 1)
    return adjustedSize, numBranches
end

-- ============================================
-- STATUS DISPLAY
-- ============================================

--- Print current mining status
function M.printStatus()
    term.clear()
    term.setCursorPos(1, 1)
    
    local pos = M.movement.getPosition()
    local elapsed = os.clock() - M.stats.startTime
    local fuelLevel = M.fuel.getLevel()
    local fuelLimit = M.fuel.getLimit()
    
    print("=== Smart Miner Status ===")
    print(string.format("Position: %d, %d, %d", pos.x, pos.y, pos.z))
    if fuelLevel == "unlimited" then
        print("Fuel: Unlimited")
    else
        print(string.format("Fuel: %d / %d", fuelLevel, fuelLimit))
    end
    print(string.format("Torches: %d (slot %d)", M.getTorchCount(), M.config.torchSlot))
    print(string.format("Empty slots: %d / 16", M.inventory.emptySlots()))
    print(string.format("Blocks mined: %d", M.stats.blocksMined))
    print(string.format("Ores found: %d", M.stats.oresMined))
    print(string.format("Return trips: %d", M.stats.tripsHome))
    print(string.format("Elapsed: %.0fs", elapsed))
end

return M
