--- Tree Farmer Harvest Module
-- Handles tree detection, cutting, navigation, and item collection
-- 
-- GRID LAYOUT (corridor-based, avoids walking through saplings):
--   - Turtle starts at [H] facing NORTH
--   - Corridors are at Z=0, 3, 6 (spacing+1 apart)
--   - Trees are at Z=1, 4, 7 (one block SOUTH of each corridor)
--   - Turtle walks EAST along corridor, faces SOUTH to access trees
--
--   Top-down view (turtle starts at H facing north):
--
--       X=0   X=1   X=4   X=7
--   Z=0 [H]→ [.]→ [.]→ [.]   ← Corridor 0 (turtle walks east-west here)
--   Z=1      [T]   [T]   [T]   ← Tree row 0 (turtle faces SOUTH to access)
--   Z=2                        
--   Z=3 [.]→ [.]→ [.]→ [.]   ← Corridor 1
--   Z=4      [T]   [T]   [T]   ← Tree row 1
--   Z=5                        
--   Z=6 [.]→ [.]→ [.]→ [.]   ← Corridor 2
--   Z=7      [T]   [T]   [T]   ← Tree row 2
--
--   Trees at: X = 1, 1+spacing, 1+spacing*2, ...
--             Z = 1, 1+rowSpacing, 1+rowSpacing*2, ...
--   Corridors: Z = 0, rowSpacing, rowSpacing*2, ...
--
-- The turtle NEVER walks through tree positions because trees are always
-- 1 block south of the corridor it's walking on.
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
    
    local startPos = movement.getPosition()
    logInfo("cutTreeUp: Starting at (%d,%d,%d), maxHeight=%d", 
        startPos.x, startPos.y, startPos.z, maxHeight)
    
    -- Dig the base log in front of us
    if turtle.detect() then
        local success, blockData = turtle.inspect()
        if success and core.isLog(blockData) then
            logDebug("Digging base log: %s", blockData.name)
            turtle.dig()
            logsMined = logsMined + 1
        end
    end
    
    -- Move into the tree's position
    if not movement.forward() then
        logWarn("Could not move into tree position")
        return logsMined, 0
    end
    
    local treePos = movement.getPosition()
    logDebug("Moved into tree position: (%d,%d,%d)", treePos.x, treePos.y, treePos.z)
    
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
                logDebug("Height %d: Log above - %s", heightClimbed, blockData.name)
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
                logDebug("Height %d: Branch log - %s", heightClimbed, blockData.name)
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
            logWarn("Cannot move up, stuck at height %d", heightClimbed)
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
    
    local endPos = movement.getPosition()
    logInfo("cutTreeUp complete: %d logs, climbed %d, now at (%d,%d,%d)", 
        logsMined, heightClimbed, endPos.x, endPos.y, endPos.z)
    
    return logsMined, heightClimbed
end

--- Return to ground level (y=0)
-- @return boolean Success
function M.returnToGround()
    local movement = core.libs.movement
    local pos = movement.getPosition()
    
    logDebug("returnToGround: Starting at Y=%d", pos.y)
    
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
    local pos = movement.getPosition()
    local facing = movement.getFacing()
    
    logInfo("harvestTree: pos=(%d,%d,%d) facing=%d", pos.x, pos.y, pos.z, facing)
    
    -- Check what's in front
    local success, blockData = turtle.inspect()
    
    if not success then
        -- Nothing there - empty position
        logInfo("harvestTree: Empty position (nothing in front)")
        return 0, false
    end
    
    logInfo("harvestTree: Block in front = %s", blockData.name)
    
    if core.isSapling(blockData) then
        logInfo("harvestTree: Sapling present - tree not grown yet")
        return 0, true  -- Has content, don't replant
    end
    
    if not core.isLog(blockData) then
        logInfo("harvestTree: Non-tree block, skipping: %s", blockData.name)
        return 0, true  -- Something there, don't replant
    end
    
    -- It's a log! Harvest the tree
    logInfo("harvestTree: LOG DETECTED - beginning harvest")
    
    local logs, height = M.cutTreeUp()
    logInfo("harvestTree: cutTreeUp returned %d logs, %d height", logs, height)
    
    M.returnToGround()
    M.backToPath()
    M.collectDrops()
    
    if logs > 0 then
        core.stats.treesHarvested = core.stats.treesHarvested + 1
        core.stats.logsCollected = core.stats.logsCollected + logs
        logInfo("harvestTree: COMPLETE - %d logs from %d height (total: %d trees, %d logs)",
            logs, height, core.stats.treesHarvested, core.stats.logsCollected)
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

-- GRID LAYOUT (fixed to avoid walking through saplings):
--
--   The turtle walks along corridors at Z=0, 3, 6 (north of tree rows)
--   Trees are planted at Z=1, 4, 7 (one block south of corridors)
--
--   Top-down view:
--       X=0   X=1   X=4   X=7
--   Z=0 [H]→ [.]→ [.]→ [.]   ← Corridor 0 (turtle walks east-west here)
--   Z=1      [T]   [T]   [T]   ← Tree row 0 (turtle faces SOUTH to access)
--   Z=2                         
--   Z=3 [.]→ [.]→ [.]→ [.]   ← Corridor 1
--   Z=4      [T]   [T]   [T]   ← Tree row 1
--
--   Turtle walks EAST along corridor, then faces SOUTH to access each tree.
--   This ensures the turtle NEVER walks through tree/sapling positions.

--- Get the corridor Z position for a given tree row
-- Corridor is one block NORTH of the tree row
-- @param gridZ number Tree row index (0 to depth-1)  
-- @return number corridorZ The Z coordinate of the corridor
function M.getCorridorZ(gridZ)
    local rowSpacing = core.config.spacing + 1
    local corridorZ = gridZ * rowSpacing  -- Z=0, 3, 6, ... (north of trees)
    logDebug("getCorridorZ(gridZ=%d) = %d (rowSpacing=%d)", gridZ, corridorZ, rowSpacing)
    return corridorZ
end

--- Get the tree's Z position for a given row
-- Tree is one block SOUTH of the corridor
-- @param gridZ number Tree row index (0 to depth-1)
-- @return number treeZ The Z coordinate of the tree
function M.getTreeZ(gridZ)
    local rowSpacing = core.config.spacing + 1
    local treeZ = 1 + gridZ * rowSpacing  -- Z=1, 4, 7, ... (one south of corridor)
    logDebug("getTreeZ(gridZ=%d) = %d (rowSpacing=%d)", gridZ, treeZ, rowSpacing)
    return treeZ
end

--- Get the tree's X position within a row
-- @param gridX number Tree column index (0 to width-1)
-- @return number treeX The X coordinate of the tree
function M.getTreeX(gridX)
    local spacing = core.config.spacing + 1
    local treeX = 1 + gridX * spacing  -- First tree at X=1, then spaced apart
    logDebug("getTreeX(gridX=%d) = %d (spacing=%d)", gridX, treeX, spacing)
    return treeX
end

--- Navigate along the X=0 corridor to a specific Z position
-- @param targetZ number Target Z coordinate
function M.navigateCorridorTo(targetZ)
    local movement = core.libs.movement
    local pos = movement.getPosition()
    
    logInfo("navigateCorridorTo: target Z=%d | current pos=(%d,%d,%d)", 
        targetZ, pos.x, pos.y, pos.z)
    
    -- First ensure we're on the corridor (X=0)
    if pos.x ~= 0 then
        logInfo("Not on corridor (X=%d), moving to X=0", pos.x)
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
        pos = movement.getPosition()
        logDebug("Now at X=%d", pos.x)
    end
    
    -- Now move along corridor to target Z
    pos = movement.getPosition()
    local dz = targetZ - pos.z
    logDebug("Moving along corridor: dz=%d (from Z=%d to Z=%d)", dz, pos.z, targetZ)
    
    if dz > 0 then
        movement.turnTo(2)  -- South (into farm)
        for i = 1, dz do
            local ok = movement.forward(true)
            pos = movement.getPosition()
            logDebug("Corridor step %d/%d south: moved=%s, Z=%d", i, dz, tostring(ok), pos.z)
        end
    elseif dz < 0 then
        movement.turnTo(0)  -- North (toward home)
        for i = 1, -dz do
            local ok = movement.forward(true)
            pos = movement.getPosition()
            logDebug("Corridor step %d/%d north: moved=%s, Z=%d", i, -dz, tostring(ok), pos.z)
        end
    end
    
    pos = movement.getPosition()
    logInfo("navigateCorridorTo complete: now at (%d,%d,%d)", pos.x, pos.y, pos.z)
end

--- Walk east to a tree position, face south, check/harvest/plant, then return
-- Turtle must be on corridor (X=0) at the correct corridor Z
-- Tree is 1 block SOUTH of the corridor
-- @param treeX number The X position of the tree
-- @param doHarvest boolean Whether to harvest
-- @param doReplant boolean Whether to replant empty spots
-- @return number logs, boolean planted
function M.visitTree(treeX, doHarvest, doReplant)
    local movement = core.libs.movement
    local logs = 0
    local planted = false
    
    local startPos = movement.getPosition()
    local startFacing = movement.getFacing()
    logInfo("visitTree: treeX=%d, harvest=%s, replant=%s | startPos=(%d,%d,%d) facing=%d",
        treeX, tostring(doHarvest), tostring(doReplant), 
        startPos.x, startPos.y, startPos.z, startFacing)
    
    -- STEP 1: Walk EAST along corridor to the tree's X position
    -- Corridor is at current Z, tree is at same X but Z+1 (south)
    logDebug("Turning to face EAST (1) to walk along corridor")
    movement.turnTo(1)  -- East
    
    local pos = movement.getPosition()
    local stepsNeeded = treeX - pos.x
    logDebug("Need to walk %d steps east (pos.x=%d, treeX=%d)", stepsNeeded, pos.x, treeX)
    
    for i = 1, stepsNeeded do
        local moveOk = movement.forward(true)
        pos = movement.getPosition()
        logDebug("Step %d/%d: moved=%s, now at (%d,%d,%d)", 
            i, stepsNeeded, tostring(moveOk), pos.x, pos.y, pos.z)
        if not moveOk then
            logWarn("Blocked walking east at step %d", i)
        end
    end
    
    -- STEP 2: Face SOUTH - the tree is 1 block south of us
    logDebug("Turning to face SOUTH (2) to access tree")
    movement.turnTo(2)  -- South
    
    -- Now we're at X=treeX, Z=corridorZ, facing south
    -- The tree/sapling position is directly in front of us at Z=corridorZ+1
    pos = movement.getPosition()
    local facing = movement.getFacing()
    local expectedTreeZ = pos.z + 1
    logInfo("At tree approach: (%d,%d,%d) facing=%d, tree should be at (%d,%d,%d)",
        pos.x, pos.y, pos.z, facing, treeX, pos.y, expectedTreeZ)
    
    -- Check what's in front (should be tree position)
    local hasBlock, blockData = turtle.inspect()
    if hasBlock then
        logInfo("Block in front: %s", blockData.name)
    else
        logInfo("No block in front (air/empty)")
    end
    
    -- Also check what's below to understand terrain
    local hasGround, groundData = turtle.inspectDown()
    if hasGround then
        logDebug("Ground below: %s", groundData.name)
    else
        logDebug("Nothing below (hovering?)")
    end
    
    if doHarvest and hasBlock and core.isLog(blockData) then
        -- There's a tree! Harvest it
        logInfo("TREE DETECTED - Harvesting")
        local harvestLogs, hasContent = M.harvestTree()
        logs = harvestLogs
        logInfo("Harvested %d logs", logs)
        
        -- After harvesting, the spot is empty - replant
        if doReplant then
            logInfo("Attempting replant after harvest")
            if M.plantSapling() then
                planted = true
                logInfo("Replant SUCCESS")
            else
                logWarn("Replant FAILED after harvest")
            end
        end
    elseif hasBlock and core.isSapling(blockData) then
        -- Sapling already there - skip
        logInfo("Sapling already present: %s", blockData.name)
        planted = true  -- Consider it planted already
    elseif not hasBlock then
        -- Empty space - plant if requested
        if doReplant then
            logInfo("Empty spot, attempting to plant sapling...")
            if M.plantSapling() then
                planted = true
                logInfo("Plant SUCCESS")
            else
                logWarn("Plant FAILED (empty spot)")
            end
        else
            logDebug("Empty spot but replant=false, skipping")
        end
    elseif hasBlock then
        -- Some other block (not log, not sapling)
        logWarn("Unknown/unexpected block: %s", blockData.name)
    end
    
    -- STEP 3: Walk back WEST to corridor (X=0)
    logDebug("Returning to corridor (X=0)")
    movement.turnTo(3)  -- West
    pos = movement.getPosition()
    local stepsBack = pos.x
    logDebug("Walking %d steps west from X=%d", stepsBack, pos.x)
    for i = 1, stepsBack do
        local moveOk = movement.forward(true)
        pos = movement.getPosition()
        logDebug("Return step %d/%d: moved=%s, now at (%d,%d,%d)", 
            i, stepsBack, tostring(moveOk), pos.x, pos.y, pos.z)
    end
    
    pos = movement.getPosition()
    logInfo("visitTree complete: logs=%d, planted=%s, final pos=(%d,%d,%d)",
        logs, tostring(planted), pos.x, pos.y, pos.z)
    
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
    
    logInfo("returnHome: Starting from (%d, %d, %d) facing=%d", 
        pos.x, pos.y, pos.z, movement.getFacing())
    
    -- First get to ground level
    if pos.y ~= 0 then
        logInfo("Not at ground level (Y=%d), descending...", pos.y)
    end
    M.returnToGround()
    
    -- Navigate via corridor to home
    logInfo("Navigating to corridor Z=0")
    M.navigateCorridorTo(0)
    
    -- Face north (original direction)
    movement.turnTo(0)
    
    pos = movement.getPosition()
    logInfo("returnHome complete: now at (%d, %d, %d) facing=%d", 
        pos.x, pos.y, pos.z, movement.getFacing())
end

-- ============================================
-- FULL HARVEST PASS
-- ============================================

--- Process a single tree at the current position (facing south toward tree)
-- Does NOT move - just inspects, harvests, and plants
-- @param doHarvest boolean Whether to harvest trees
-- @param doReplant boolean Whether to replant empty spots
-- @return number logs, boolean planted
local function processTreeAtPosition(doHarvest, doReplant)
    local movement = core.libs.movement
    local logs = 0
    local planted = false
    
    local pos = movement.getPosition()
    local facing = movement.getFacing()
    
    -- Check what's in front (should be tree position - 1 block south)
    local hasBlock, blockData = turtle.inspect()
    if hasBlock then
        logDebug("Block in front: %s", blockData.name)
    else
        logDebug("No block in front (air/empty)")
    end
    
    if doHarvest and hasBlock and core.isLog(blockData) then
        -- There's a tree! Harvest it
        logInfo("TREE DETECTED - Harvesting")
        local harvestLogs, hasContent = M.harvestTree()
        logs = harvestLogs
        logInfo("Harvested %d logs", logs)
        
        -- After harvesting, the spot is empty - replant
        if doReplant then
            logDebug("Attempting replant after harvest")
            if M.plantSapling() then
                planted = true
                logInfo("Replant SUCCESS")
            else
                logWarn("Replant FAILED after harvest")
            end
        end
    elseif hasBlock and core.isSapling(blockData) then
        -- Sapling already there - skip
        logDebug("Sapling already present: %s", blockData.name)
        planted = true  -- Consider it planted already
    elseif not hasBlock then
        -- Empty space - plant if requested
        if doReplant then
            logDebug("Empty spot, attempting to plant sapling...")
            if M.plantSapling() then
                planted = true
                logInfo("Plant SUCCESS")
            else
                logWarn("Plant FAILED (empty spot)")
            end
        end
    elseif hasBlock then
        -- Some other block (not log, not sapling)
        logWarn("Unknown/unexpected block: %s", blockData.name)
    end
    
    return logs, planted
end

--- Harvest and replant all trees in the grid (optimized movement)
-- Walks along each corridor row, visiting trees in sequence
-- @param doReplant boolean Whether to replant empty positions
-- @return number totalLogs, number saplingsPlanted
function M.harvestAllTrees(doReplant)
    local movement = core.libs.movement
    local totalLogs = 0
    local planted = 0
    
    core.state.phase = "harvesting"
    local passNum = core.stats.harvestPasses + 1
    
    logInfo("========================================")
    logInfo("HARVEST PASS #%d STARTING", passNum)
    logInfo("========================================")
    logInfo("Grid: %d x %d trees (width x depth)", core.config.width, core.config.depth)
    logInfo("Spacing: %d blocks between trees", core.config.spacing)
    logInfo("Replant mode: %s", tostring(doReplant))
    
    local startPos = movement.getPosition()
    local startFacing = movement.getFacing()
    logInfo("Start position: (%d,%d,%d) facing=%d", 
        startPos.x, startPos.y, startPos.z, startFacing)
    logInfo("Fuel at start: %s", tostring(turtle.getFuelLevel()))
    logInfo("Saplings at start: %d", core.countSaplings())
    
    local spacing = core.config.spacing + 1  -- blocks between tree centers
    
    -- Visit each row
    for z = 0, core.config.depth - 1 do
        logInfo("--- Row Z=%d (grid row %d/%d) ---", z, z+1, core.config.depth)
        
        -- Navigate to this row's corridor
        local corridorZ = M.getCorridorZ(z)
        M.navigateCorridorTo(corridorZ)
        
        -- Now walk east along corridor, visiting each tree
        -- Trees are at X = 1, 1+spacing, 1+2*spacing, ...
        movement.turnTo(1)  -- Face east
        
        for x = 0, core.config.width - 1 do
            core.state.currentX = x
            core.state.currentZ = z
            
            local treeX = M.getTreeX(x)
            local pos = movement.getPosition()
            
            -- Walk east to this tree's X position
            local stepsNeeded = treeX - pos.x
            logDebug("Tree [%d,%d]: walking %d steps east to X=%d", x, z, stepsNeeded, treeX)
            
            for i = 1, stepsNeeded do
                movement.forward(true)
            end
            
            -- Now at tree's X, face south to access the tree
            movement.turnTo(2)  -- South
            
            pos = movement.getPosition()
            logInfo("Tree [%d,%d] at (%d,%d,%d): treeX=%d", x, z, pos.x, pos.y, pos.z, treeX)
            
            -- Process this tree (harvest/plant)
            local logs, didPlant = processTreeAtPosition(true, doReplant)
            totalLogs = totalLogs + logs
            if didPlant then planted = planted + 1 end
            
            logInfo("Tree [%d,%d] result: logs=%d, planted=%s (totals: logs=%d, planted=%d)",
                x, z, logs, tostring(didPlant), totalLogs, planted)
            
            -- Face east again to continue along corridor
            movement.turnTo(1)  -- East
            
            -- Check inventory
            if core.isInventoryFull() then
                logInfo("Inventory full, returning to deposit")
                M.returnHome()
                return totalLogs, planted
            end
            
            sleep(0.05)
        end
        
        -- Row complete - return to corridor X=0 for next row
        logInfo("Row Z=%d complete, returning to X=0", z)
        movement.turnTo(3)  -- West
        local pos = movement.getPosition()
        for i = 1, pos.x do
            movement.forward(true)
        end
        
        logDebug("Back at X=0")
    end
    
    core.stats.harvestPasses = core.stats.harvestPasses + 1
    core.state.phase = "idle"
    
    -- Consolidate saplings
    local saplings = core.consolidateSaplings()
    logInfo("========================================")
    logInfo("HARVEST PASS COMPLETE")
    logInfo("========================================")
    logInfo("Total logs: %d, Total planted: %d, Saplings in inventory: %d", totalLogs, planted, saplings)
    logInfo("Fuel remaining: %s", tostring(turtle.getFuelLevel()))
    
    return totalLogs, planted
end

-- ============================================
-- PLANTING (integrated for simplicity)
-- ============================================

--- Select saplings from inventory
-- @return boolean True if saplings available
function M.selectSaplings()
    local treeInfo = core.getTreeInfo()
    local targetSapling = treeInfo.sapling
    
    logInfo("selectSaplings: Looking for '%s'", targetSapling)
    
    -- Log full inventory state
    logInfo("=== INVENTORY SCAN ===")
    local totalSaplings = 0
    local saplingSlots = {}
    
    for slot = 1, 16 do
        local item = turtle.getItemDetail(slot)
        if item then
            logDebug("  Slot %02d: %s x%d", slot, item.name, item.count)
            if item.name == targetSapling then
                totalSaplings = totalSaplings + item.count
                table.insert(saplingSlots, {slot=slot, count=item.count, exact=true})
            elseif item.name:match("sapling") then
                table.insert(saplingSlots, {slot=slot, count=item.count, exact=false, name=item.name})
            end
        else
            -- Empty slot
        end
    end
    
    logInfo("Found %d target saplings (%s) in %d slots", 
        totalSaplings, targetSapling, #saplingSlots)
    
    -- Try exact match first
    for _, slotInfo in ipairs(saplingSlots) do
        if slotInfo.exact then
            turtle.select(slotInfo.slot)
            logInfo("SELECTED slot %d: %s x%d (exact match)", 
                slotInfo.slot, targetSapling, slotInfo.count)
            return true
        end
    end
    
    -- Fallback to any sapling
    for _, slotInfo in ipairs(saplingSlots) do
        if not slotInfo.exact then
            turtle.select(slotInfo.slot)
            logWarn("SELECTED slot %d: %s x%d (FALLBACK - not target type!)", 
                slotInfo.slot, slotInfo.name, slotInfo.count)
            return true
        end
    end
    
    logWarn("NO SAPLINGS FOUND - inventory has 0 saplings of any type")
    return false
end

--- Plant a sapling at current facing direction
-- @return boolean Success
function M.plantSapling()
    local movement = core.libs.movement
    local pos = movement.getPosition()
    local facing = movement.getFacing()
    
    logInfo("=== PLANT SAPLING ATTEMPT ===")
    logInfo("Position: (%d, %d, %d), Facing: %d", pos.x, pos.y, pos.z, facing)
    
    -- Try to select saplings
    if not M.selectSaplings() then
        logWarn("PLANT FAILED: No saplings available in inventory")
        return false
    end
    
    -- Log what we have selected
    local slot = turtle.getSelectedSlot()
    local item = turtle.getItemDetail(slot)
    if not item then
        logWarn("PLANT FAILED: Selected slot %d is empty (race condition?)", slot)
        return false
    end
    logInfo("Selected: slot %d = %s x%d", slot, item.name, item.count)
    
    -- Check what's in front before placing
    local hasBlock, blockData = turtle.inspect()
    if hasBlock then
        logWarn("PLANT FAILED: Block already in front: %s", blockData.name)
        return false
    end
    logInfo("Front is clear (no block)")
    
    -- Check what's below us (turtle's ground)
    local hasGroundBelow, groundBelowData = turtle.inspectDown()
    local ourGround = hasGroundBelow and groundBelowData.name or "air/void"
    logInfo("Ground below US: %s", ourGround)
    
    -- Check what's in front and below (where sapling would be placed)
    -- We can't directly inspect this, but we can infer from Y level
    logInfo("Turtle Y level: %d (sapling will try to place at Y=%d in front)", pos.y, pos.y)
    
    -- Calculate where we expect to place
    local dx = ({[0]=0, [1]=1, [2]=0, [3]=-1})[facing] or 0
    local dz = ({[0]=-1, [1]=0, [2]=1, [3]=0})[facing] or 0
    logInfo("Placing towards: direction=%d (dx=%d, dz=%d), target block=(%d, %d, %d)",
        facing, dx, dz, pos.x + dx, pos.y, pos.z + dz)
    
    -- Attempt placement
    logInfo("Calling turtle.place()...")
    local success, err = turtle.place()
    
    if success then
        core.stats.saplingsPlanted = core.stats.saplingsPlanted + 1
        logInfo("PLANT SUCCESS! Sapling placed. Total planted: %d", core.stats.saplingsPlanted)
        
        -- Verify placement
        local verifyBlock, verifyData = turtle.inspect()
        if verifyBlock then
            logInfo("Verification: Block now in front = %s", verifyData.name)
        else
            logWarn("Verification FAILED: No block in front after placing?!")
        end
        
        return true
    else
        local errStr = tostring(err or "no error message")
        logWarn("PLANT FAILED: turtle.place() returned false")
        logWarn("  Error: %s", errStr)
        logWarn("  Item: %s from slot %d", item.name, slot)
        logWarn("  Position: (%d, %d, %d) facing %d", pos.x, pos.y, pos.z, facing)
        
        -- Additional diagnostics
        local remainingCount = turtle.getItemCount(slot)
        logWarn("  Remaining in slot: %d", remainingCount)
        
        -- Check if there's now a block (maybe something weird happened)
        local postBlock, postData = turtle.inspect()
        if postBlock then
            logWarn("  Post-attempt block in front: %s", postData.name)
        else
            logWarn("  Post-attempt: Still no block in front")
        end
        
        return false
    end
end

--- Set up initial farm (plant all saplings)
-- @return number Number planted
function M.setupFarm()
    local movement = core.libs.movement
    local planted = 0
    
    core.state.phase = "planting"
    
    logInfo("========================================")
    logInfo("FARM SETUP STARTING")
    logInfo("========================================")
    logInfo("Grid: %d x %d trees", core.config.width, core.config.depth)
    logInfo("Spacing: %d blocks", core.config.spacing)
    logInfo("Tree type: %s", core.config.treeType)
    
    local available = core.countSaplings()
    local needed = core.getTotalTrees()
    
    logInfo("Saplings available: %d", available)
    logInfo("Saplings needed: %d", needed)
    logInfo("Fuel: %s", tostring(turtle.getFuelLevel()))
    
    if available < needed then
        logWarn("Not enough saplings: have %d, need %d", available, needed)
    end
    
    local startPos = movement.getPosition()
    logInfo("Start position: (%d,%d,%d)", startPos.x, startPos.y, startPos.z)
    
    -- Visit each row via corridor
    for z = 0, core.config.depth - 1 do
        logInfo("--- Setup Row Z=%d (%d/%d) ---", z, z+1, core.config.depth)
        
        local corridorZ = M.getCorridorZ(z)
        M.navigateCorridorTo(corridorZ)
        
        -- Plant each tree in this row using visitTree
        for x = 0, core.config.width - 1 do
            local treeX = M.getTreeX(x)
            
            logInfo("Setup tree [%d,%d]: treeX=%d", x, z, treeX)
            
            -- visitTree with harvest=false, replant=true will plant if empty
            local logs, didPlant = M.visitTree(treeX, false, true)
            
            if didPlant then
                planted = planted + 1
                logInfo("Planted at grid (%d, %d) - total planted: %d", x, z, planted)
            else
                logWarn("Failed to plant at grid (%d, %d)", x, z)
            end
            
            local remaining = core.countSaplings()
            logDebug("Saplings remaining: %d", remaining)
            
            if remaining == 0 then
                logWarn("Ran out of saplings!")
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
    
    logInfo("========================================")
    logInfo("FARM SETUP COMPLETE")
    logInfo("========================================")
    logInfo("Total saplings planted: %d / %d needed", planted, needed)
    logInfo("Fuel remaining: %s", tostring(turtle.getFuelLevel()))
    
    return planted
end

return M
