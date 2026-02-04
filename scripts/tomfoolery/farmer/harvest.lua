--- Tree Farmer Harvest Module
-- Handles tree detection, cutting, navigation, and item collection
-- 
-- GRID LAYOUT (trees to front-right of home):
--   - Turtle starts at [H] facing NORTH (into the farm)
--   - Trees are planted in a grid to the FRONT and RIGHT of home
--   - Turtle walks along X=0 column (safe corridor), turns EAST to access trees
--
--   Top-down view (turtle starts facing north/up):
--
--       X=0   X=1   X=4   X=7  ...
--   Z=0 [H]   
--   Z=1 [.]   [T]   [T]   [T]   ← Tree row 0
--   Z=4 [.]   [T]   [T]   [T]   ← Tree row 1 (spacing+1 apart)
--   Z=7 [.]   [T]   [T]   [T]   ← Tree row 2
--        ↑
--       Path column (turtle walks here)
--
--   Trees at: X = 1, 1+spacing, 1+spacing*2, ...
--             Z = 1, 1+rowSpacing, 1+rowSpacing*2, ...
--
-- Turtle walks north-south on X=0, turns east to check each tree in the row.
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
-- NAVIGATION - SAFE CORRIDOR-BASED
-- ============================================

-- The turtle walks along the X=0 corridor (north-south).
-- For each tree row, it faces EAST and walks to each tree position,
-- harvests/plants, then backs up along the same path.
-- This ensures it never walks through tree positions.

--- Get the corridor position (X=0) for a given tree row
-- @param gridZ number Tree row index (0 to depth-1)  
-- @return number pathZ The Z coordinate on the corridor
function M.getCorridorZ(gridZ)
    local rowSpacing = core.config.spacing + 1
    return 1 + gridZ * rowSpacing  -- First row at Z=1, then spaced apart
end

--- Get the tree's X position within a row
-- @param gridX number Tree column index (0 to width-1)
-- @return number treeX The X coordinate of the tree
function M.getTreeX(gridX)
    local spacing = core.config.spacing + 1
    return 1 + gridX * spacing  -- First tree at X=1, then spaced apart
end

--- Navigate along the X=0 corridor to a specific Z position
-- @param targetZ number Target Z coordinate
function M.navigateCorridorTo(targetZ)
    local movement = core.libs.movement
    local pos = movement.getPosition()
    
    -- First ensure we're on the corridor (X=0)
    if pos.x ~= 0 then
        -- Need to get back to corridor - go west
        if pos.x > 0 then
            movement.turnTo(3)  -- West
            for i = 1, pos.x do
                movement.forward(true)
            end
        else
            movement.turnTo(1)  -- East
            for i = 1, -pos.x do
                movement.forward(true)
            end
        end
    end
    
    -- Now move along corridor to target Z
    pos = movement.getPosition()
    local dz = targetZ - pos.z
    if dz > 0 then
        movement.turnTo(2)  -- South (into farm)
        for i = 1, dz do
            movement.forward(true)
        end
    elseif dz < 0 then
        movement.turnTo(0)  -- North (toward home)
        for i = 1, -dz do
            movement.forward(true)
        end
    end
end

--- Walk east to a tree position and return
-- Turtle must be on corridor (X=0) at the correct Z
-- @param treeX number The X position of the tree
-- @param doHarvest boolean Whether to harvest/plant
-- @return number logs, boolean planted
function M.visitTree(treeX, doHarvest, doReplant)
    local movement = core.libs.movement
    local logs = 0
    local planted = false
    
    -- Face east and walk to one block before tree
    movement.turnTo(1)  -- East
    local walkDistance = treeX - 1  -- Stop 1 block before tree (at X = treeX-1)
    
    for i = 1, walkDistance do
        if not movement.forward(true) then
            logWarn("Blocked walking to tree at X=%d", treeX)
        end
    end
    
    -- Now we're at X = treeX-1, facing east, tree is in front
    if doHarvest then
        local harvestLogs, hasContent = M.harvestTree()
        logs = harvestLogs
        
        -- Replant if empty and requested
        if not hasContent and doReplant then
            if M.plantSapling() then
                planted = true
            end
        end
    end
    
    -- Walk back to corridor (X=0)
    movement.turnTo(3)  -- West
    local pos = movement.getPosition()
    for i = 1, pos.x do
        movement.forward(true)
    end
    
    return logs, planted
end

--- Navigate to a world position (used for returning home)
-- @param targetX number Target X coordinate
-- @param targetZ number Target Z coordinate
function M.navigateToPosition(targetX, targetZ)
    local movement = core.libs.movement
    
    -- First get to corridor
    M.navigateCorridorTo(targetZ)
    
    -- If target is not on corridor, walk there
    if targetX ~= 0 then
        local pos = movement.getPosition()
        local dx = targetX - pos.x
        if dx > 0 then
            movement.turnTo(1)
            for i = 1, dx do movement.forward(true) end
        elseif dx < 0 then
            movement.turnTo(3)
            for i = 1, -dx do movement.forward(true) end
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
    
    -- Navigate via corridor to home
    M.navigateCorridorTo(0)
    
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
    
    -- Visit each row
    for z = 0, core.config.depth - 1 do
        -- Navigate to this row on the corridor
        local corridorZ = M.getCorridorZ(z)
        M.navigateCorridorTo(corridorZ)
        
        -- Visit each tree in this row (walking east, then back)
        for x = 0, core.config.width - 1 do
            core.state.currentX = x
            core.state.currentZ = z
            
            local treeX = M.getTreeX(x)
            local logs, didPlant = M.visitTree(treeX, true, doReplant)
            totalLogs = totalLogs + logs
            if didPlant then planted = planted + 1 end
            
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
    
    -- Visit each row via corridor
    for z = 0, core.config.depth - 1 do
        local corridorZ = M.getCorridorZ(z)
        M.navigateCorridorTo(corridorZ)
        
        -- Plant each tree in this row
        for x = 0, core.config.width - 1 do
            local treeX = M.getTreeX(x)
            
            -- Walk to tree position (but don't harvest, just plant)
            local movement = core.libs.movement
            movement.turnTo(1)  -- East
            local walkDistance = treeX - 1
            
            for i = 1, walkDistance do
                movement.forward(true)
            end
            
            -- Plant sapling
            if M.plantSapling() then
                planted = planted + 1
                logDebug("Planted at grid (%d, %d)", x, z)
            else
                logWarn("Ran out of saplings at (%d, %d)", x, z)
            end
            
            -- Walk back to corridor
            movement.turnTo(3)  -- West
            local pos = movement.getPosition()
            for i = 1, pos.x do
                movement.forward(true)
            end
            
            if core.countSaplings() == 0 then
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
