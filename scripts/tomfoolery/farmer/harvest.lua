--- Tree Farmer Harvest Module
-- Handles tree detection, cutting, and item collection
-- @module farmer.harvest

local M = {}

local core = nil
local logger = nil

-- ============================================
-- INITIALIZATION
-- ============================================

--- Initialize harvest module with dependencies
-- @param coreModule table The farmer.core module
function M.init(coreModule)
    core = coreModule
    
    -- Try to load logger (optional)
    local ok, log = pcall(require, "common.logger")
    if ok then
        logger = log
    end
end

-- ============================================
-- LOGGING HELPERS
-- ============================================

local function logDebug(fmt, ...)
    if logger then
        logger.debug(fmt, ...)
    end
end

local function logInfo(fmt, ...)
    if logger then
        logger.info(fmt, ...)
    end
end

-- ============================================
-- TREE CUTTING
-- ============================================

--- Dig up through a tree trunk until we hit non-log
-- @return number Number of logs mined
function M.cutTreeUp()
    local logsMined = 0
    local movement = core.libs.movement
    
    -- First dig the base log in front
    if turtle.detect() then
        turtle.dig()
        logsMined = logsMined + 1
    end
    
    -- Move into tree position
    if not movement.forward() then
        logDebug("Could not move into tree position")
        return logsMined
    end
    
    -- Dig up until no more logs
    while true do
        local success, blockData = turtle.inspectUp()
        if success and core.isLog(blockData) then
            turtle.digUp()
            logsMined = logsMined + 1
            if not movement.up() then
                logDebug("Could not move up while cutting")
                break
            end
        else
            -- No more logs above
            break
        end
    end
    
    return logsMined
end

--- Return to ground level and back out of tree position
-- @return boolean Success
function M.returnToGround()
    local movement = core.libs.movement
    local pos = movement.getPosition()
    
    -- Move down until we're at y=0
    while pos.y > 0 do
        -- Dig down if blocked (shouldn't happen normally)
        if turtle.detectDown() then
            turtle.digDown()
        end
        if not movement.down() then
            logDebug("Could not descend at y=%d", pos.y)
            return false
        end
        pos = movement.getPosition()
    end
    
    -- Back out of tree position
    if not movement.back() then
        -- If we can't go back, turn around and go forward
        movement.turnRight()
        movement.turnRight()
        movement.forward()
        movement.turnRight()
        movement.turnRight()
    end
    
    return true
end

--- Harvest a single tree (cut trunk and return to ground)
-- @return number Number of logs harvested
function M.harvestTree()
    logDebug("Harvesting tree")
    
    -- Check if there's actually a tree
    if not core.detectTree() then
        logDebug("No tree detected")
        return 0
    end
    
    local logs = M.cutTreeUp()
    M.returnToGround()
    
    if logs > 0 then
        core.stats.treesHarvested = core.stats.treesHarvested + 1
        core.stats.logsCollected = core.stats.logsCollected + logs
        logInfo("Harvested tree: %d logs", logs)
    end
    
    return logs
end

-- ============================================
-- LEAF BREAKING (OPTIONAL)
-- ============================================

--- Break leaves in front (optional, for faster sapling drops)
function M.breakLeavesFront()
    local success, blockData = turtle.inspect()
    if success and core.isLeaves(blockData) then
        turtle.dig()
    end
end

-- ============================================
-- ITEM COLLECTION
-- ============================================

--- Collect dropped items (saplings, sticks, apples)
-- Call this after harvesting to pick up drops
function M.collectDrops()
    local treeInfo = core.getTreeInfo()
    
    -- Suck items from ground (in front, below, and current position)
    local collected = false
    
    -- Try to suck from all directions
    while turtle.suck() do
        collected = true
    end
    while turtle.suckDown() do
        collected = true
    end
    
    -- Count what we collected
    if collected then
        M.countCollectedItems()
    end
    
    return collected
end

--- Count and track collected items in inventory
function M.countCollectedItems()
    local treeInfo = core.getTreeInfo()
    
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            if item.name == treeInfo.sapling then
                -- Saplings tracked via consolidation
            elseif item.name == "minecraft:apple" then
                core.stats.applesCollected = core.stats.applesCollected + item.count
            elseif item.name == "minecraft:stick" then
                core.stats.sticksCollected = core.stats.sticksCollected + item.count
            end
        end
    end
end

-- ============================================
-- FULL HARVEST PASS
-- ============================================

--- Harvest all trees in the farm grid
-- Uses serpentine path for efficiency
-- @return number Total logs harvested this pass
function M.harvestAllTrees()
    local movement = core.libs.movement
    local totalLogs = 0
    local gridSpacing = core.config.spacing + 1
    
    core.state.phase = "harvesting"
    logInfo("Starting harvest pass #%d", core.stats.harvestPasses + 1)
    
    local startFacing = movement.getFacing()
    
    -- Traverse grid in serpentine pattern
    for z = 0, core.config.depth - 1 do
        -- Determine direction for this row
        local goingRight = (z % 2 == 0)
        
        for x = 0, core.config.width - 1 do
            local actualX = goingRight and x or (core.config.width - 1 - x)
            
            core.state.currentX = actualX
            core.state.currentZ = z
            
            -- Navigate to tree position
            local worldX, worldZ = core.gridToWorld(actualX, z)
            M.navigateToPosition(worldX, worldZ)
            
            -- Face the tree (trees are planted in front of path)
            -- Actually, we'll be standing at tree position
            
            -- Try to harvest if there's a tree
            local logs = M.harvestTree()
            totalLogs = totalLogs + logs
            
            -- Collect any drops
            M.collectDrops()
            
            -- Check inventory
            if core.isInventoryFull() then
                logInfo("Inventory full, returning to deposit")
                return totalLogs
            end
            
            sleep(0.1)  -- Small yield
        end
    end
    
    core.stats.harvestPasses = core.stats.harvestPasses + 1
    core.state.phase = "idle"
    
    -- Consolidate saplings after harvest
    local saplings = core.consolidateSaplings()
    logInfo("Harvest pass complete: %d logs, %d saplings available", totalLogs, saplings)
    
    return totalLogs
end

--- Navigate to a specific position relative to home
-- @param targetX number Target X offset
-- @param targetZ number Target Z offset
function M.navigateToPosition(targetX, targetZ)
    local movement = core.libs.movement
    local pos = movement.getPosition()
    
    -- Calculate difference
    local dx = targetX - pos.x
    local dz = targetZ - pos.z
    
    -- Move in X direction first
    if dx > 0 then
        movement.turnTo(1)  -- East
        for i = 1, dx do
            if not movement.forward() then
                -- Obstacle, try to clear
                turtle.dig()
                movement.forward()
            end
        end
    elseif dx < 0 then
        movement.turnTo(3)  -- West
        for i = 1, -dx do
            if not movement.forward() then
                turtle.dig()
                movement.forward()
            end
        end
    end
    
    -- Move in Z direction
    if dz > 0 then
        movement.turnTo(2)  -- South
        for i = 1, dz do
            if not movement.forward() then
                turtle.dig()
                movement.forward()
            end
        end
    elseif dz < 0 then
        movement.turnTo(0)  -- North
        for i = 1, -dz do
            if not movement.forward() then
                turtle.dig()
                movement.forward()
            end
        end
    end
end

--- Return to home position (0, 0, 0)
function M.returnHome()
    local movement = core.libs.movement
    local pos = movement.getPosition()
    
    logDebug("Returning home from (%d, %d, %d)", pos.x, pos.y, pos.z)
    
    -- First return to ground level
    while pos.y > 0 do
        if turtle.detectDown() then
            turtle.digDown()
        end
        movement.down()
        pos = movement.getPosition()
    end
    
    -- Navigate to 0,0
    M.navigateToPosition(0, 0)
    
    -- Face original direction (north)
    movement.turnTo(0)
    
    logDebug("Arrived home")
end

return M
