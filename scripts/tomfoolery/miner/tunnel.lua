--- Tunnel mining module for smart mining turtle
-- Single-step mining functions for different tunnel styles
-- @module miner.tunnel

local M = {}

local core = nil

--- Initialize with core module reference
-- @param coreModule table The miner.core module
function M.init(coreModule)
    core = coreModule
end

-- ============================================
-- ORE DETECTION HELPERS
-- ============================================

--- Check and mine ore in a direction
-- @param inspectFn function Inspector function
-- @param digFn function Dig function
-- @param moveFn function|nil Move into space function
-- @param returnFn function|nil Return from space function
-- @return number Number of ores mined
local function checkAndMineOre(inspectFn, digFn, moveFn, returnFn)
    if not core.config.checkOreVeins then return 0 end
    
    local block = inspectFn()
    if core.mining.isOre(block) then
        digFn()
        if moveFn then
            moveFn()
            local mined = core.mining.checkAndMineOres(core.movement)
            if returnFn then returnFn() end
            core.stats.oresMined = core.stats.oresMined + 1 + mined
            return 1 + mined
        else
            core.stats.oresMined = core.stats.oresMined + 1
            return 1
        end
    end
    return 0
end

--- Check left wall for ore
function M.checkLeftOre()
    core.movement.turnLeft()
    local result = checkAndMineOre(
        core.mining.inspectForward,
        function() core.mining.digForward() end,
        function() core.movement.forward(false) end,
        function() core.movement.back() end
    )
    core.movement.turnRight()
    return result
end

--- Check right wall for ore
function M.checkRightOre()
    core.movement.turnRight()
    local result = checkAndMineOre(
        core.mining.inspectForward,
        function() core.mining.digForward() end,
        function() core.movement.forward(false) end,
        function() core.movement.back() end
    )
    core.movement.turnLeft()
    return result
end

--- Check below for ore
function M.checkDownOre()
    return checkAndMineOre(
        core.mining.inspectDown,
        function() core.mining.digDown() end,
        function() core.movement.down(false) end,
        function() core.movement.up(false) end
    )
end

--- Check above for ore
function M.checkUpOre()
    return checkAndMineOre(
        core.mining.inspectUp,
        function() core.mining.digUp() end,
        function() core.movement.up(false) end,
        function() core.movement.down(false) end
    )
end

--- Check in front for ore
function M.checkFrontOre()
    return checkAndMineOre(
        core.mining.inspectForward,
        function() core.mining.digForward() end,
        function() core.movement.forward(false) end,
        function() core.movement.back() end
    )
end

--- Explore a pokehole: check all 5 directions for ore
function M.explorePokeholeOres()
    M.checkFrontOre()
    M.checkLeftOre()
    M.checkRightOre()
    M.checkUpOre()
    M.checkDownOre()
end

-- ============================================
-- DIGGING HELPERS
-- ============================================

--- Dig forward and move, handling gravel
-- @return boolean Success
function M.digAndMoveForward()
    if turtle.detect() then
        core.mining.digForward()
        core.stats.blocksMined = core.stats.blocksMined + 1
    end
    return core.movement.forward(true)
end

--- Dig up and update stats
function M.digUp()
    if turtle.detectUp() then
        core.mining.digUp()
        core.stats.blocksMined = core.stats.blocksMined + 1
        return true
    end
    return false
end

--- Dig down and update stats
function M.digDown()
    if turtle.detectDown() then
        core.mining.digDown()
        core.stats.blocksMined = core.stats.blocksMined + 1
        return true
    end
    return false
end

-- ============================================
-- TUNNEL STEP FUNCTIONS
-- ============================================

--- Mine one step of a simple 1x2 tunnel with optional pokeholes
-- @param checkOres boolean Check for ore veins
-- @param placeTorch boolean Place torch this step
-- @param stepNumber number Current step (for pokehole timing)
function M.mineSimpleStep(checkOres, placeTorch, stepNumber)
    local existingTorch = core.hasTorchAbove()
    
    -- Floor level checks
    if checkOres then
        M.checkDownOre()
        M.checkLeftOre()
        M.checkRightOre()
    end
    
    -- Move to head height
    if not existingTorch then
        M.digUp()
    end
    core.movement.up(false)
    
    -- Head height checks
    if checkOres then
        M.checkLeftOre()
        M.checkRightOre()
        M.checkUpOre()
    end
    
    -- Return to floor
    core.movement.down(false)
    
    -- Place torch
    if placeTorch and core.getTorchCount() > 0 and not existingTorch then
        turtle.select(core.config.torchSlot)
        turtle.placeUp()
    end
    
    -- Pokehole mining
    if core.config.usePokeholes and stepNumber and (stepNumber % core.config.pokeholeInterval == 0) then
        -- Left pokehole
        core.movement.turnLeft()
        if turtle.detect() then
            core.mining.digForward()
            core.stats.blocksMined = core.stats.blocksMined + 1
        end
        core.movement.forward(true)
        if checkOres then M.explorePokeholeOres() end
        core.movement.back()
        core.movement.turnRight()
        
        -- Right pokehole
        core.movement.turnRight()
        if turtle.detect() then
            core.mining.digForward()
            core.stats.blocksMined = core.stats.blocksMined + 1
        end
        core.movement.forward(true)
        if checkOres then M.explorePokeholeOres() end
        core.movement.back()
        core.movement.turnLeft()
    end
    
    -- Advance forward
    M.digAndMoveForward()
    
    -- Clear headroom (gravel may have fallen)
    if not core.hasTorchAbove() and turtle.detectUp() then
        M.digUp()
    end
    
    -- Periodic inventory cleanup
    if core.inventory.emptySlots() < 4 then
        core.inventory.dropJunk()
    end
end

--- Mine one step of a 1x3 snake tunnel (maximum ore exposure)
-- @param checkOres boolean Check for ore veins
-- @param placeTorch boolean Place torch this step
function M.mineSnakeStep(checkOres, placeTorch)
    -- Check ores at floor
    if checkOres then
        M.checkDownOre()
        M.checkLeftOre()
        M.checkRightOre()
    end
    
    -- Move up and forward
    M.digUp()
    core.movement.up(false)
    M.digAndMoveForward()
    
    -- Move to ceiling
    M.digUp()
    core.movement.up(false)
    
    -- Check ores at ceiling
    if checkOres then
        M.checkUpOre()
        M.checkLeftOre()
        M.checkRightOre()
    end
    
    -- Return to floor
    core.movement.down(false)
    M.digDown()
    core.movement.down(false)
    
    -- Check floor ores again
    if checkOres then
        M.checkDownOre()
        M.checkLeftOre()
        M.checkRightOre()
    end
    
    -- Place torch
    local existingTorch = core.hasTorchAbove()
    if placeTorch and core.getTorchCount() > 0 and not existingTorch then
        turtle.select(core.config.torchSlot)
        core.movement.turnAround()
        if not turtle.place() then
            turtle.placeDown()
        end
        core.movement.turnAround()
    end
    
    -- Cleanup
    if core.inventory.emptySlots() < 4 then
        core.inventory.dropJunk()
    end
end

--- Mine one tunnel step using configured method
-- @param checkOres boolean Check for ore veins
-- @param placeTorch boolean Place torch this step
-- @param stepNumber number Current step number
function M.mineStep(checkOres, placeTorch, stepNumber)
    if core.config.useSnakeMining then
        M.mineSnakeStep(checkOres, placeTorch)
    else
        M.mineSimpleStep(checkOres, placeTorch, stepNumber)
    end
end

return M
