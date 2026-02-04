--- Tree Farmer Planting Module
-- Handles sapling placement and replanting
-- @module farmer.planting

local M = {}

local core = nil
local harvest = nil
local logger = nil

-- ============================================
-- INITIALIZATION
-- ============================================

--- Initialize planting module with dependencies
-- @param coreModule table The farmer.core module
-- @param harvestModule table The farmer.harvest module
function M.init(coreModule, harvestModule)
    core = coreModule
    harvest = harvestModule
    
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

local function logWarn(fmt, ...)
    if logger then
        logger.warn(fmt, ...)
    end
end

-- ============================================
-- SAPLING MANAGEMENT
-- ============================================

--- Select the sapling slot (slot 1)
-- @return boolean True if saplings available
function M.selectSaplings()
    local treeInfo = core.getTreeInfo()
    
    -- First try slot 1
    turtle.select(1)
    local item = turtle.getItemDetail(1)
    if item and item.name == treeInfo.sapling then
        return true
    end
    
    -- Search other slots
    for slot = 2, 16 do
        item = turtle.getItemDetail(slot)
        if item and item.name == treeInfo.sapling then
            turtle.select(slot)
            -- Transfer to slot 1
            turtle.transferTo(1)
            turtle.select(1)
            return true
        end
    end
    
    return false
end

--- Plant a sapling at current position (place down or forward)
-- @param direction string "forward" or "down"
-- @return boolean True if planted successfully
function M.plantSapling(direction)
    direction = direction or "forward"
    
    if not M.selectSaplings() then
        logWarn("No saplings available to plant")
        return false
    end
    
    local success
    if direction == "down" then
        -- Check if ground is suitable (dirt/grass)
        local hasBlock, blockData = turtle.inspectDown()
        if hasBlock then
            -- There's a block below - place on top of it by moving up first?
            -- Actually for planting, we place the sapling as a block
            success = turtle.placeDown()
        else
            success = turtle.placeDown()
        end
    else
        -- Place forward
        success = turtle.place()
    end
    
    if success then
        core.stats.saplingsPlanted = core.stats.saplingsPlanted + 1
        logDebug("Planted sapling")
        return true
    else
        logDebug("Failed to plant sapling")
        return false
    end
end

-- ============================================
-- REPLANTING LOGIC
-- ============================================

--- Check if position needs replanting
-- @return boolean True if position is empty (no tree or sapling)
function M.needsReplanting()
    -- Check if there's a tree or sapling in front
    local success, blockData = turtle.inspect()
    if not success then
        -- No block in front - might need planting
        return true
    end
    
    -- If it's a log or sapling, no planting needed
    if core.isLog(blockData) or core.isSapling(blockData) then
        return false
    end
    
    -- Something else is there
    return false
end

--- Replant a single position if needed
-- @return boolean True if replanted
function M.replantPosition()
    if M.needsReplanting() then
        return M.plantSapling("forward")
    end
    return false
end

-- ============================================
-- FULL REPLANTING PASS
-- ============================================

--- Visit all tree positions and replant missing saplings
-- @return number Number of saplings planted
function M.replantAllTrees()
    local movement = core.libs.movement
    local planted = 0
    
    core.state.phase = "planting"
    logInfo("Starting replanting pass")
    
    -- Consolidate saplings first
    local available = core.consolidateSaplings()
    logInfo("Saplings available: %d", available)
    
    if available < core.config.minSaplings then
        logWarn("Low on saplings (%d < %d minimum)", available, core.config.minSaplings)
    end
    
    -- Traverse grid
    for z = 0, core.config.depth - 1 do
        local goingRight = (z % 2 == 0)
        
        for x = 0, core.config.width - 1 do
            local actualX = goingRight and x or (core.config.width - 1 - x)
            
            -- Navigate to tree position
            local worldX, worldZ = core.gridToWorld(actualX, z)
            harvest.navigateToPosition(worldX, worldZ)
            
            -- Check and replant
            if M.needsReplanting() then
                if M.selectSaplings() then
                    if M.plantSapling("forward") then
                        planted = planted + 1
                    end
                else
                    logWarn("Out of saplings at grid (%d, %d)", actualX, z)
                    break
                end
            end
            
            sleep(0.1)
        end
        
        -- Check if we ran out of saplings
        if core.countSaplings() == 0 then
            break
        end
    end
    
    core.state.phase = "idle"
    logInfo("Replanting complete: %d saplings planted", planted)
    
    return planted
end

-- ============================================
-- INITIAL FARM SETUP
-- ============================================

--- Set up initial farm grid with saplings
-- Assumes turtle starts at corner of farm facing into farm
-- @return number Number of saplings planted
function M.setupFarm()
    local movement = core.libs.movement
    local planted = 0
    
    core.state.phase = "planting"
    logInfo("Setting up farm: %dx%d grid, spacing %d", 
        core.config.width, core.config.depth, core.config.spacing)
    
    local available = core.countSaplings()
    local needed = core.getTotalTrees()
    
    if available < needed then
        logWarn("Not enough saplings: have %d, need %d", available, needed)
    end
    
    -- Plant at each grid position
    for z = 0, core.config.depth - 1 do
        local goingRight = (z % 2 == 0)
        
        for x = 0, core.config.width - 1 do
            local actualX = goingRight and x or (core.config.width - 1 - x)
            
            -- Navigate to position
            local worldX, worldZ = core.gridToWorld(actualX, z)
            harvest.navigateToPosition(worldX, worldZ)
            
            -- Plant sapling
            if M.selectSaplings() then
                if M.plantSapling("forward") then
                    planted = planted + 1
                    logDebug("Planted at grid (%d, %d)", actualX, z)
                end
            else
                logWarn("Ran out of saplings during setup")
                break
            end
            
            sleep(0.1)
        end
        
        if core.countSaplings() == 0 then
            break
        end
    end
    
    -- Return home
    harvest.returnHome()
    
    core.state.phase = "idle"
    logInfo("Farm setup complete: %d saplings planted", planted)
    
    return planted
end

return M
