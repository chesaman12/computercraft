--- Mining utilities module for turtles
-- Provides safe digging, ore detection, and mining patterns
-- @module mining

local M = {}

--- List of ore blocks that should be mined when found
M.ORES = {
    ["minecraft:coal_ore"] = true,
    ["minecraft:deepslate_coal_ore"] = true,
    ["minecraft:iron_ore"] = true,
    ["minecraft:deepslate_iron_ore"] = true,
    ["minecraft:copper_ore"] = true,
    ["minecraft:deepslate_copper_ore"] = true,
    ["minecraft:gold_ore"] = true,
    ["minecraft:deepslate_gold_ore"] = true,
    ["minecraft:redstone_ore"] = true,
    ["minecraft:deepslate_redstone_ore"] = true,
    ["minecraft:lapis_ore"] = true,
    ["minecraft:deepslate_lapis_ore"] = true,
    ["minecraft:diamond_ore"] = true,
    ["minecraft:deepslate_diamond_ore"] = true,
    ["minecraft:emerald_ore"] = true,
    ["minecraft:deepslate_emerald_ore"] = true,
    ["minecraft:nether_gold_ore"] = true,
    ["minecraft:nether_quartz_ore"] = true,
    ["minecraft:ancient_debris"] = true,
}

--- Blocks that indicate air/void (don't mine, can move through)
M.AIR_BLOCKS = {
    ["minecraft:air"] = true,
    ["minecraft:cave_air"] = true,
    ["minecraft:void_air"] = true,
}

--- Dangerous blocks to avoid (lava, water)
M.DANGER_BLOCKS = {
    ["minecraft:lava"] = true,
    ["minecraft:flowing_lava"] = true,
    ["minecraft:water"] = true,
    ["minecraft:flowing_water"] = true,
}

--- Safely dig forward, handling gravel/sand
-- @return boolean Success
function M.digForward()
    while turtle.detect() do
        local success = turtle.dig()
        if not success then
            return false
        end
        sleep(0.4)  -- Wait for falling blocks
    end
    return true
end

--- Safely dig up, handling gravel/sand
-- @return boolean Success
function M.digUp()
    while turtle.detectUp() do
        local success = turtle.digUp()
        if not success then
            return false
        end
        sleep(0.4)  -- Wait for falling blocks
    end
    return true
end

--- Safely dig down
-- @return boolean Success
function M.digDown()
    if turtle.detectDown() then
        return turtle.digDown()
    end
    return true  -- Nothing to dig
end

--- Inspect block in front
-- @return table|nil Block data or nil if no block
function M.inspectForward()
    local success, data = turtle.inspect()
    if success then
        return data
    end
    return nil
end

--- Inspect block above
-- @return table|nil Block data or nil if no block
function M.inspectUp()
    local success, data = turtle.inspectUp()
    if success then
        return data
    end
    return nil
end

--- Inspect block below
-- @return table|nil Block data or nil if no block
function M.inspectDown()
    local success, data = turtle.inspectDown()
    if success then
        return data
    end
    return nil
end

--- Check if a block is an ore
-- @param blockData table Block data from inspect
-- @param oreList table|nil Custom ore list (optional)
-- @return boolean True if block is an ore
function M.isOre(blockData, oreList)
    if not blockData then return false end
    oreList = oreList or M.ORES
    return oreList[blockData.name] == true
end

--- Check if a block is dangerous
-- @param blockData table Block data from inspect
-- @return boolean True if block is dangerous
function M.isDangerous(blockData)
    if not blockData then return false end
    return M.DANGER_BLOCKS[blockData.name] == true
end

--- Check for ores in all directions and mine them
-- @param movement table Movement module reference
-- @param oreList table|nil Custom ore list (optional)
-- @return number Number of ores mined
function M.checkAndMineOres(movement, oreList)
    oreList = oreList or M.ORES
    local mined = 0
    
    -- Check front
    local front = M.inspectForward()
    if M.isOre(front, oreList) then
        M.digForward()
        movement.forward(false)
        mined = mined + 1 + M.checkAndMineOres(movement, oreList)  -- Recursive vein mining
        movement.back()
    end
    
    -- Check up
    local up = M.inspectUp()
    if M.isOre(up, oreList) then
        M.digUp()
        movement.up(false)
        mined = mined + 1 + M.checkAndMineOres(movement, oreList)
        movement.down(false)
    end
    
    -- Check down
    local down = M.inspectDown()
    if M.isOre(down, oreList) then
        M.digDown()
        movement.down(false)
        mined = mined + 1 + M.checkAndMineOres(movement, oreList)
        movement.up(false)
    end
    
    -- Check left
    movement.turnLeft()
    front = M.inspectForward()
    if M.isOre(front, oreList) then
        M.digForward()
        movement.forward(false)
        mined = mined + 1 + M.checkAndMineOres(movement, oreList)
        movement.back()
    end
    
    -- Check right (turn 180 from left)
    movement.turnAround()
    front = M.inspectForward()
    if M.isOre(front, oreList) then
        M.digForward()
        movement.forward(false)
        mined = mined + 1 + M.checkAndMineOres(movement, oreList)
        movement.back()
    end
    
    -- Return to original facing
    movement.turnLeft()
    
    return mined
end

--- Check all directions for danger (lava/water)
-- @return boolean True if danger detected
-- @return string|nil Direction of danger
function M.checkForDanger()
    local front = M.inspectForward()
    if M.isDangerous(front) then
        return true, "front"
    end
    
    local up = M.inspectUp()
    if M.isDangerous(up) then
        return true, "up"
    end
    
    local down = M.inspectDown()
    if M.isDangerous(down) then
        return true, "down"
    end
    
    return false, nil
end

--- Mine a 3x3 area at current position
-- @return boolean Success
function M.mine3x3()
    -- Dig current column
    M.digUp()
    M.digDown()
    
    -- This is a placeholder - would need movement module
    -- to properly implement 3x3 mining
    return true
end

--- Place a torch if available
-- @param direction string Direction ("front", "up", "down")
-- @return boolean Success
function M.placeTorch(direction)
    local originalSlot = turtle.getSelectedSlot()
    
    -- Find torch in inventory
    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot)
        if detail and detail.name == "minecraft:torch" then
            turtle.select(slot)
            local success
            if direction == "up" then
                success = turtle.placeUp()
            elseif direction == "down" then
                success = turtle.placeDown()
            else
                success = turtle.place()
            end
            turtle.select(originalSlot)
            return success
        end
    end
    
    turtle.select(originalSlot)
    return false
end

--- Count specific block types found nearby
-- @return table Summary of nearby blocks
function M.scanNearby()
    local blocks = {}
    
    local function addBlock(data)
        if data then
            if blocks[data.name] then
                blocks[data.name] = blocks[data.name] + 1
            else
                blocks[data.name] = 1
            end
        end
    end
    
    addBlock(M.inspectForward())
    addBlock(M.inspectUp())
    addBlock(M.inspectDown())
    
    return blocks
end

return M
