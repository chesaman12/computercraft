--- Tree Farmer Core Module
-- Configuration, state tracking, and utility functions for tree farming
-- @module farmer.core

local M = {}

-- ============================================
-- CONFIGURATION
-- ============================================

--- Default configuration values
M.config = {
    -- Farm dimensions
    width = 5,           -- Number of trees in X direction
    depth = 5,           -- Number of trees in Z direction
    
    -- Tree spacing (blocks between saplings)
    -- 2 blocks for same-type trees, 4 for mixed
    spacing = 3,         -- 3 blocks between trees (4 block grid)
    
    -- Wait time between harvest passes (seconds)
    harvestInterval = 120,
    
    -- Maximum tree height to expect (birch is 5-7, oak 4-7)
    maxTreeHeight = 8,
    
    -- Slot assignments
    saplingSlot = 1,     -- Keep saplings in slot 1
    torchSlot = 16,      -- Optional torches in slot 16
    
    -- Minimum saplings to keep for replanting
    minSaplings = 10,
    
    -- Drop excess saplings if inventory is full
    dropExcessSaplings = false,
    
    -- Fuel safety threshold
    minFuel = 200,
    
    -- Tree type (for detection)
    treeType = "birch",  -- birch, oak, spruce, jungle, acacia, dark_oak
}

--- Statistics tracking
M.stats = {
    treesHarvested = 0,
    logsCollected = 0,
    saplingsCollected = 0,
    saplingsPlanted = 0,
    harvestPasses = 0,
    applesCollected = 0,
    sticksCollected = 0,
}

--- Current state
M.state = {
    running = true,
    currentX = 0,        -- Current grid position (0-indexed)
    currentZ = 0,
    phase = "idle",      -- idle, harvesting, planting, depositing
}

-- ============================================
-- TREE TYPE DEFINITIONS
-- ============================================

--- Block IDs for different tree types
M.TREE_TYPES = {
    oak = {
        sapling = "minecraft:oak_sapling",
        log = "minecraft:oak_log",
        leaves = "minecraft:oak_leaves",
        spacing = 2,
        maxHeight = 7,
        canDropApples = true,
    },
    birch = {
        sapling = "minecraft:birch_sapling",
        log = "minecraft:birch_log",
        leaves = "minecraft:birch_leaves",
        spacing = 2,
        maxHeight = 7,
        canDropApples = false,
    },
    spruce = {
        sapling = "minecraft:spruce_sapling",
        log = "minecraft:spruce_log",
        leaves = "minecraft:spruce_leaves",
        spacing = 2,
        maxHeight = 7,
        canDropApples = false,
    },
    jungle = {
        sapling = "minecraft:jungle_sapling",
        log = "minecraft:jungle_log",
        leaves = "minecraft:jungle_leaves",
        spacing = 2,
        maxHeight = 7,
        canDropApples = false,
    },
    acacia = {
        sapling = "minecraft:acacia_sapling",
        log = "minecraft:acacia_log",
        leaves = "minecraft:acacia_leaves",
        spacing = 4,  -- Acacia needs more space due to shape
        maxHeight = 8,
        canDropApples = false,
    },
    dark_oak = {
        sapling = "minecraft:dark_oak_sapling",
        log = "minecraft:dark_oak_log",
        leaves = "minecraft:dark_oak_leaves",
        spacing = 4,  -- 2x2 planting required
        maxHeight = 11,
        canDropApples = true,
    },
    cherry = {
        sapling = "minecraft:cherry_sapling",
        log = "minecraft:cherry_log",
        leaves = "minecraft:cherry_leaves",
        spacing = 4,
        maxHeight = 8,
        canDropApples = false,
    },
}

--- Get current tree type info
-- @return table Tree type definition
function M.getTreeInfo()
    return M.TREE_TYPES[M.config.treeType] or M.TREE_TYPES.birch
end

-- ============================================
-- DEPENDENCY INJECTION
-- ============================================

M.libs = {}

--- Initialize core with dependencies
-- @param deps table Dependencies {movement, inventory, fuel}
function M.init(deps)
    M.libs.movement = deps.movement
    M.libs.inventory = deps.inventory
    M.libs.fuel = deps.fuel
end

-- ============================================
-- DETECTION FUNCTIONS
-- ============================================

--- Check if a block is a log of the current tree type
-- @param blockData table Block inspect data
-- @return boolean True if it's a matching log
function M.isLog(blockData)
    if not blockData then return false end
    local treeInfo = M.getTreeInfo()
    return blockData.name == treeInfo.log
end

--- Check if a block is leaves of the current tree type
-- @param blockData table Block inspect data
-- @return boolean True if it's matching leaves
function M.isLeaves(blockData)
    if not blockData then return false end
    local treeInfo = M.getTreeInfo()
    return blockData.name == treeInfo.leaves
end

--- Check if a block is a sapling of the current tree type
-- @param blockData table Block inspect data
-- @return boolean True if it's a matching sapling
function M.isSapling(blockData)
    if not blockData then return false end
    local treeInfo = M.getTreeInfo()
    return blockData.name == treeInfo.sapling
end

--- Check if we have a tree in front (log present)
-- @return boolean True if tree detected
function M.detectTree()
    local success, blockData = turtle.inspect()
    return success and M.isLog(blockData)
end

--- Check if sapling is planted in front
-- @return boolean True if sapling present
function M.detectSapling()
    local success, blockData = turtle.inspect()
    return success and M.isSapling(blockData)
end

-- ============================================
-- GRID CALCULATIONS
-- ============================================

--- Calculate total farm size in blocks
-- @return number, number Width and depth in blocks
function M.getFarmSize()
    local gridSpacing = M.config.spacing + 1  -- +1 for the tree itself
    local width = (M.config.width - 1) * gridSpacing
    local depth = (M.config.depth - 1) * gridSpacing
    return width, depth
end

--- Calculate total number of tree positions
-- @return number Total trees
function M.getTotalTrees()
    return M.config.width * M.config.depth
end

--- Convert grid position to relative world offset
-- @param gridX number Grid X (0-indexed)
-- @param gridZ number Grid Z (0-indexed)
-- @return number, number Relative X and Z offset from home
function M.gridToWorld(gridX, gridZ)
    local gridSpacing = M.config.spacing + 1
    return gridX * gridSpacing, gridZ * gridSpacing
end

--- Estimate fuel needed for one complete harvest pass
-- @return number Estimated fuel cost
function M.estimateFuelCost()
    local width, depth = M.getFarmSize()
    local totalTrees = M.getTotalTrees()
    
    -- Movement to visit all trees (serpentine path)
    local horizontalMoves = width + depth * M.config.width
    
    -- Vertical moves (up and down for each tree)
    local verticalMoves = totalTrees * M.config.maxTreeHeight * 2
    
    -- Return trip buffer
    local returnBuffer = width + depth
    
    return horizontalMoves + verticalMoves + returnBuffer + 50  -- +50 safety margin
end

-- ============================================
-- INVENTORY HELPERS
-- ============================================

--- Count saplings in inventory
-- @return number Total sapling count
function M.countSaplings()
    local treeInfo = M.getTreeInfo()
    local count = 0
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == treeInfo.sapling then
            count = count + item.count
        end
    end
    return count
end

--- Consolidate saplings to slot 1
-- @return number Total saplings after consolidation
function M.consolidateSaplings()
    local treeInfo = M.getTreeInfo()
    local originalSlot = turtle.getSelectedSlot()
    
    -- First, ensure slot 1 has saplings or is empty
    turtle.select(1)
    local slot1 = turtle.getItemDetail(1)
    if slot1 and slot1.name ~= treeInfo.sapling then
        -- Slot 1 has non-sapling, find empty slot to move it
        for i = 2, 16 do
            if turtle.getItemCount(i) == 0 then
                turtle.transferTo(i)
                break
            end
        end
    end
    
    -- Now consolidate saplings from other slots to slot 1
    for slot = 2, 16 do
        local item = turtle.getItemDetail(slot)
        if item and item.name == treeInfo.sapling then
            turtle.select(slot)
            turtle.transferTo(1)
        end
    end
    
    turtle.select(originalSlot)
    return M.countSaplings()
end

--- Check if inventory is nearly full (14+ slots used)
-- @return boolean True if inventory nearly full
function M.isInventoryFull()
    local usedSlots = 0
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            usedSlots = usedSlots + 1
        end
    end
    return usedSlots >= 14
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

--- Print current statistics
function M.printStats()
    print("=== Tree Farmer Stats ===")
    print(string.format("  Passes: %d", M.stats.harvestPasses))
    print(string.format("  Trees harvested: %d", M.stats.treesHarvested))
    print(string.format("  Logs collected: %d", M.stats.logsCollected))
    print(string.format("  Saplings: +%d / -%d", 
        M.stats.saplingsCollected, M.stats.saplingsPlanted))
    if M.stats.applesCollected > 0 then
        print(string.format("  Apples: %d", M.stats.applesCollected))
    end
    print(string.format("  Current saplings: %d", M.countSaplings()))
end

--- Reset statistics
function M.resetStats()
    M.stats.treesHarvested = 0
    M.stats.logsCollected = 0
    M.stats.saplingsCollected = 0
    M.stats.saplingsPlanted = 0
    M.stats.harvestPasses = 0
    M.stats.applesCollected = 0
    M.stats.sticksCollected = 0
end

return M
