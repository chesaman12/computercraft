--- Tree Farmer Harvest Module
-- Handles tree detection, cutting, navigation, and item collection
-- 
-- GRID LAYOUT (trees to front-right of home):
--   - Turtle starts at [H] facing NORTH (into the farm)
--   - Trees are planted in a grid to the FRONT and RIGHT of home
--   - Turtle navigates BETWEEN tree rows (not through them)
--
--   Top-down view (turtle starts facing up/north):
--
--       Z=0  [H] ← Home (chest behind)
--            ↑ 
--       Z=1  [.] ← Path row 0
--       Z=2  [T] [T] [T]  ← Tree row 0 (trees at X=1,4,7...)
--       Z=3  [.] ← Path row 1
--       Z=4  [T] [T] [T]  ← Tree row 1
--       Z=5  [.] ← Path row 2
--            ...
--
--   X axis: 0 = home column, trees at X = 1, 1+spacing, 1+spacing*2, etc.
--   Z axis: 0 = home, paths at Z = 1,3,5..., trees at Z = 2,4,6...
--
-- The turtle walks along paths and checks trees to its SOUTH (forward).
-- 
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
    if logger then logger.debug(fmt, ...) end
end

local function logInfo(fmt, ...)
    if logger then logger.info(fmt, ...) end
end

local function logWarn(fmt, ...)
    if logger then logger.warn(fmt, ...) end
end

-- ============================================
-- TREE CUTTING - FULL TREE SUPPORT
-- ============================================

--- Check if a block is part of a tree (log or leaves)
-- @param blockData table Block inspection data
-- @return boolean True if tree part
local function isTreePart(blockData)
    if not blockData then return false end
    return core.isLog(blockData) or core.isLeaves(blockData)
end

--- Dig through the tree upward, handling branches
-- Called when turtle is facing the tree's base log
-- @return number logsCollected, number heightClimbed
function M.cutTreeUp()
    local movement = core.libs.movement
    local logsMined = 0
    local heightClimbed = 0
    local maxHeight = core.config.maxTreeHeight + 3
    
    -- Dig the base log in front of us
    if turtle.detect() then
        local success, blockData = turtle.inspect()
        if success and core.isLog(blockData) then
            turtle.dig()
            logsMined = logsMined + 1
        end
    end
    
    -- Move into the tree's position
    if not movement.forward() then
        logDebug("Could not move into tree position")
        return logsMined, 0
    end
    
    -- Remember our facing so we can restore it
    local originalFacing = movement.getFacing()
    
    -- Climb up, mining all logs we find (including branches)
    local noLogCounter = 0
    while heightClimbed < maxHeight and noLogCounter < 3 do
        local foundLogThisLevel = false
        
        -- Check and dig up
        local success, blockData = turtle.inspectUp()
        if success then
            if core.isLog(blockData) then
                turtle.digUp()
                logsMined = logsMined + 1
                foundLogThisLevel = true
            elseif core.isLeaves(blockData) then
                turtle.digUp()  -- Clear leaves to continue
            end
        end
        
        -- Check all 4 horizontal directions for logs (handles branching)
        for turn = 0, 3 do
            success, blockData = turtle.inspect()
            if success and core.isLog(blockData) then
                turtle.dig()
                logsMined = logsMined + 1
                foundLogThisLevel = true
            elseif success and core.isLeaves(blockData) then
                -- Optionally dig leaves for faster sapling drops
                turtle.dig()
            end
            movement.turnRight()
        end
        
        -- Move up
        if turtle.detectUp() then
            -- Something above - try to dig
            turtle.digUp()
        end
        
        if not movement.up() then
            logDebug("Cannot move up, stuck at height %d", heightClimbed)
            break
        end
        heightClimbed = heightClimbed + 1
        
        -- Track if we're past the tree
        if foundLogThisLevel then
            noLogCounter = 0
        else
            noLogCounter = noLogCounter + 1
        end
    end
    
    -- Restore original facing
    movement.turnTo(originalFacing)
    
    return logsMined, heightClimbed
end

--- Return to ground level (y=0)
-- @return boolean Success
function M.returnToGround()
    local movement = core.libs.movement
    local pos = movement.getPosition()
    
    while pos.y > 0 do
        if turtle.detectDown() then
            turtle.digDown()
        end
        if not movement.down() then
            -- Try attacking in case mob is below
            turtle.attackDown()
            sleep(0.2)
            if not movement.down() then
                logDebug("Stuck at y=%d", pos.y)
                return false
            end
        end
        pos = movement.getPosition()
    end
    
    return true
end

--- Back out of tree position to the path
-- @return boolean Success  
function M.backToPath()
    local movement = core.libs.movement
    
    if not movement.back() then
        -- Can't go back - turn around and dig forward
        movement.turnAround()
        movement.forward(true)
        movement.turnAround()
    end
    return true
end

--- Harvest a single tree
-- Turtle must be facing the tree position (log should be directly in front)
-- @return number logs, boolean hadContent
function M.harvestTree()
    local movement = core.libs.movement
    
    -- Check what's in front
    local success, blockData = turtle.inspect()
    
    if not success then
        -- Nothing there - empty position
        logDebug("Empty position")
        return 0, false
    end
    
    if core.isSapling(blockData) then
        logDebug("Sapling present - tree not grown")
        return 0, true  -- Has content, don't replant
    end
    
    if not core.isLog(blockData) then
        logDebug("Non-tree block: %s", blockData.name)
        return 0, true  -- Something there, don't replant
    end
    
    -- It's a log! Harvest the tree
    logInfo("Found tree - harvesting")
    
    local logs, height = M.cutTreeUp()
    M.returnToGround()
    M.backToPath()
    M.collectDrops()
    
    if logs > 0 then
        core.stats.treesHarvested = core.stats.treesHarvested + 1
        core.stats.logsCollected = core.stats.logsCollected + logs
        logInfo("Harvested: %d logs from %d height", logs, height)
    end
    
    return logs, false  -- Harvested, so now empty - can replant
end

-- ============================================
-- ITEM COLLECTION
-- ============================================

--- Collect dropped items from nearby
function M.collectDrops()
    local movement = core.libs.movement
    local collected = 0
    
    -- Suck from all directions
    while turtle.suck() do collected = collected + 1 end
    while turtle.suckDown() do collected = collected + 1 end
    while turtle.suckUp() do collected = collected + 1 end
    
    -- Turn around and suck (items may scatter)
    movement.turnAround()
    while turtle.suck() do collected = collected + 1 end
    movement.turnAround()
    
    return collected
end

-- ============================================
-- NAVIGATION
-- ============================================

--- Calculate the path position to stand when checking a tree
-- @param gridX number Tree grid X index (0 to width-1)
-- @param gridZ number Tree grid Z index (0 to depth-1)
-- @return number pathX, number pathZ (world coordinates)
function M.getTreeCheckPosition(gridX, gridZ)
    local spacing = core.config.spacing + 1  -- Total grid cell size
    
    -- Trees are at:
    --   X = 1 + gridX * spacing  (offset 1 from home, then spacing apart)
    --   Z = 2 + gridZ * (spacing + 1)  (first tree row at Z=2, then path+tree alternating)
    --
    -- We stand one block NORTH of the tree (Z - 1)
    local treeX = 1 + gridX * spacing
    local treeZ = 2 + gridZ * (spacing + 1)
    
    return treeX, treeZ - 1  -- Stand north of tree
end

--- Navigate to a world position
-- @param targetX number Target X coordinate
-- @param targetZ number Target Z coordinate
function M.navigateToPosition(targetX, targetZ)
    local movement = core.libs.movement
    local pos = movement.getPosition()
    
    -- Move in X first (less likely to hit trees)
    local dx = targetX - pos.x
    if dx > 0 then
        movement.turnTo(1)  -- East
        for i = 1, dx do
            if not movement.forward(true) then
                logDebug("Blocked moving east")
            end
        end
    elseif dx < 0 then
        movement.turnTo(3)  -- West
        for i = 1, -dx do
            if not movement.forward(true) then
                logDebug("Blocked moving west")
            end
        end
    end
    
    -- Then move in Z
    pos = movement.getPosition()
    local dz = targetZ - pos.z
    if dz > 0 then
        movement.turnTo(2)  -- South (into farm)
        for i = 1, dz do
            if not movement.forward(true) then
                logDebug("Blocked moving south")
            end
        end
    elseif dz < 0 then
        movement.turnTo(0)  -- North (toward home)
        for i = 1, -dz do
            if not movement.forward(true) then
                logDebug("Blocked moving north")
            end
        end
    end
end

--- Return to home position (0, 0)
function M.returnHome()
    local movement = core.libs.movement
    local pos = movement.getPosition()
    
    logDebug("Returning home from (%d, %d, %d)", pos.x, pos.y, pos.z)
    
    -- First get to ground level
    M.returnToGround()
    
    -- Then navigate to 0,0
    M.navigateToPosition(0, 0)
    
    -- Face north (original direction)
    movement.turnTo(0)
    
    logDebug("Arrived home")
end

-- ============================================
-- FULL HARVEST PASS
-- ============================================

--- Harvest and replant all trees in the grid
-- @param doReplant boolean Whether to replant empty positions
-- @return number totalLogs, number saplingsPlanted
function M.harvestAllTrees(doReplant)
    local movement = core.libs.movement
    local totalLogs = 0
    local planted = 0
    
    core.state.phase = "harvesting"
    logInfo("Starting harvest pass #%d", core.stats.harvestPasses + 1)
    
    -- Visit each tree position
    for z = 0, core.config.depth - 1 do
        for x = 0, core.config.width - 1 do
            core.state.currentX = x
            core.state.currentZ = z
            
            -- Get position to stand
            local standX, standZ = M.getTreeCheckPosition(x, z)
            M.navigateToPosition(standX, standZ)
            
            -- Face south to look at tree
            movement.turnTo(2)
            
            -- Check and harvest
            local logs, hasContent = M.harvestTree()
            totalLogs = totalLogs + logs
            
            -- Replant if empty and requested
            if not hasContent and doReplant then
                if M.plantSapling() then
                    planted = planted + 1
                end
            end
            
            -- Check inventory
            if core.isInventoryFull() then
                logInfo("Inventory full, returning to deposit")
                M.returnHome()
                return totalLogs, planted
            end
            
            sleep(0.05)
        end
    end
    
    core.stats.harvestPasses = core.stats.harvestPasses + 1
    core.state.phase = "idle"
    
    -- Consolidate saplings
    local saplings = core.consolidateSaplings()
    logInfo("Pass complete: %d logs, %d planted, %d saplings", totalLogs, planted, saplings)
    
    return totalLogs, planted
end

-- ============================================
-- PLANTING (integrated for simplicity)
-- ============================================

--- Select saplings from inventory
-- @return boolean True if saplings available
function M.selectSaplings()
    local treeInfo = core.getTreeInfo()
    
    -- Check slot 1 first
    turtle.select(1)
    local item = turtle.getItemDetail(1)
    if item and item.name == treeInfo.sapling then
        return true
    end
    
    -- Search other slots and transfer to slot 1
    for slot = 2, 16 do
        item = turtle.getItemDetail(slot)
        if item and item.name == treeInfo.sapling then
            turtle.select(slot)
            turtle.transferTo(1)
            turtle.select(1)
            return true
        end
    end
    
    return false
end

--- Plant a sapling at current facing direction
-- @return boolean Success
function M.plantSapling()
    if not M.selectSaplings() then
        logWarn("No saplings available")
        return false
    end
    
    if turtle.place() then
        core.stats.saplingsPlanted = core.stats.saplingsPlanted + 1
        logDebug("Planted sapling")
        return true
    else
        logDebug("Failed to place sapling")
        return false
    end
end

--- Set up initial farm (plant all saplings)
-- @return number Number planted
function M.setupFarm()
    local movement = core.libs.movement
    local planted = 0
    
    core.state.phase = "planting"
    logInfo("Setting up farm: %dx%d grid", core.config.width, core.config.depth)
    
    local available = core.countSaplings()
    local needed = core.getTotalTrees()
    
    if available < needed then
        logWarn("Not enough saplings: have %d, need %d", available, needed)
    end
    
    for z = 0, core.config.depth - 1 do
        for x = 0, core.config.width - 1 do
            local standX, standZ = M.getTreeCheckPosition(x, z)
            M.navigateToPosition(standX, standZ)
            
            -- Face south to place sapling
            movement.turnTo(2)
            
            if M.plantSapling() then
                planted = planted + 1
                logDebug("Planted at grid (%d, %d)", x, z)
            else
                logWarn("Ran out of saplings at (%d, %d)", x, z)
                break
            end
            
            sleep(0.05)
        end
        
        if core.countSaplings() == 0 then
            break
        end
    end
    
    M.returnHome()
    core.state.phase = "idle"
    logInfo("Farm setup complete: %d saplings planted", planted)
    
    return planted
end

return M
