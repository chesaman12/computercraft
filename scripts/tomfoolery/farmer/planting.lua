--- Tree Farmer Planting Module
-- Provides planting utilities (main logic now in harvest.lua)
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
-- PASS-THROUGH FUNCTIONS
-- ============================================

-- These delegate to harvest module which now handles planting too

--- Set up the initial farm with saplings
-- @return number Number of saplings planted
function M.setupFarm()
    return harvest.setupFarm()
end

--- Replant all empty positions
-- @return number Number of saplings planted
function M.replantAllTrees()
    -- This is now integrated into harvestAllTrees with replant=true
    -- Just do a harvest pass with replanting enabled
    local logs, planted = harvest.harvestAllTrees(true)
    return planted
end

--- Select saplings from inventory
-- @return boolean True if saplings available
function M.selectSaplings()
    return harvest.selectSaplings()
end

--- Plant a sapling at current position
-- @return boolean Success
function M.plantSapling()
    return harvest.plantSapling()
end

return M
