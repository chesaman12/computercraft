--- Mining utilities module for turtles
-- Provides safe digging, ore detection, and mining patterns
-- @module mining

local M = {}

--- Mining dimension mode: when true, mines everything except junk blocks
-- instead of only mining blocks in the ore list
M.miningDimensionMode = false

-- Try to load config module for external ore lists
local configLoaded, config = pcall(require, "common.config")

--- Default ore blocks (used if config file not found)
local DEFAULT_ORES = {
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

--- Load ores from config file, falling back to defaults
local function loadOres()
    if configLoaded and config.exists("ores.cfg") then
        local ores = config.loadSet("ores.cfg")
        -- Check if we got any ores
        local count = 0
        for _ in pairs(ores) do count = count + 1 end
        if count > 0 then
            return ores
        end
    end
    return DEFAULT_ORES
end

--- List of ore blocks that should be mined when found
-- Loaded from config/ores.cfg if available, otherwise uses defaults
M.ORES = loadOres()

--- Default junk blocks for mining dimension (only these are ignored)
local MINING_DIMENSION_JUNK = {
    ["minecraft:stone"] = true,
    ["minecraft:deepslate"] = true,
    ["minecraft:dirt"] = true,
}

--- Load junk blocks from config file
local function loadJunk()
    if configLoaded and config.exists("junk.cfg") then
        local junk = config.loadSet("junk.cfg")
        local count = 0
        for _ in pairs(junk) do count = count + 1 end
        if count > 0 then
            return junk
        end
    end
    return MINING_DIMENSION_JUNK
end

--- List of junk blocks to ignore in mining dimension mode
M.JUNK = loadJunk()

--- Reload junk blocks from config file
function M.reloadJunk()
    M.JUNK = loadJunk()
    local count = 0
    for _ in pairs(M.JUNK) do count = count + 1 end
    return count
end

--- Check if a block is junk (should be ignored)
-- @param blockData table Block data from inspect
-- @param junkList table|nil Custom junk list (optional)
-- @return boolean True if block is junk
function M.isJunk(blockData, junkList)
    if not blockData then return true end  -- No block = treat as junk (air)
    junkList = junkList or (M.miningDimensionMode and MINING_DIMENSION_JUNK or M.JUNK)
    return junkList[blockData.name] == true
end

--- Check if a block is valuable (not junk, should be mined)
-- Used in mining dimension mode
-- @param blockData table Block data from inspect
-- @return boolean True if block should be mined
function M.isValuable(blockData)
    if not blockData then return false end
    -- Air blocks are never valuable
    if M.AIR_BLOCKS[blockData.name] then return false end
    -- In mining dimension mode, anything that's not junk is valuable
    return not MINING_DIMENSION_JUNK[blockData.name]
end

--- Enable mining dimension mode
-- In this mode, the turtle mines everything except junk blocks
function M.enableMiningDimensionMode()
    M.miningDimensionMode = true
end

--- Disable mining dimension mode (back to ore whitelist)
function M.disableMiningDimensionMode()
    M.miningDimensionMode = false
end

--- Reload ores from config file
-- Call this after editing config/ores.cfg
function M.reloadOres()
    M.ORES = loadOres()
    local count = 0
    for _ in pairs(M.ORES) do count = count + 1 end
    return count
end

--- Add an ore to the detection list (runtime only)
-- @param oreName string Block ID (e.g., "minecraft:diamond_ore")
function M.addOre(oreName)
    M.ORES[oreName] = true
end

--- Remove an ore from the detection list (runtime only)
-- @param oreName string Block ID
function M.removeOre(oreName)
    M.ORES[oreName] = nil
end

--- Get list of all registered ores
-- @return table Array of ore names
function M.getOreList()
    local list = {}
    for name in pairs(M.ORES) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

--- Print all registered ores
function M.printOres()
    print("=== Registered Ores ===")
    local list = M.getOreList()
    for _, name in ipairs(list) do
        print("  " .. name)
    end
    print(string.format("Total: %d ores", #list))
end

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

--- Check if a block should be mined
-- In normal mode: returns true if block is in the ore list
-- In mining dimension mode: returns true if block is NOT junk
-- @param blockData table Block data from inspect
-- @param oreList table|nil Custom ore list (optional, ignored in mining dimension mode)
-- @return boolean True if block should be mined
function M.isOre(blockData, oreList)
    if not blockData then return false end
    
    -- Mining dimension mode: mine everything except junk
    if M.miningDimensionMode then
        return M.isValuable(blockData)
    end
    
    -- Normal mode: only mine ores in the whitelist
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

--- Maximum depth for ore vein following
M.MAX_VEIN_DEPTH = 16

--- Check for ores in all directions and mine them
-- @param movement table Movement module reference
-- @param oreList table|nil Custom ore list (optional)
-- @param depth number|nil Current recursion depth (internal use)
-- @return number Number of ores mined
function M.checkAndMineOres(movement, oreList, depth)
    oreList = oreList or M.ORES
    depth = depth or 0
    
    -- Prevent infinite recursion / going too deep into veins
    if depth >= M.MAX_VEIN_DEPTH then
        return 0
    end
    
    local mined = 0
    
    -- Check front
    local front = M.inspectForward()
    if M.isOre(front, oreList) then
        M.digForward()
        movement.forward(false)
        mined = mined + 1 + M.checkAndMineOres(movement, oreList, depth + 1)  -- Recursive vein mining
        movement.back()
    end
    
    -- Check up
    local up = M.inspectUp()
    if M.isOre(up, oreList) then
        M.digUp()
        movement.up(false)
        mined = mined + 1 + M.checkAndMineOres(movement, oreList, depth + 1)
        movement.down(false)
    end
    
    -- Check down
    local down = M.inspectDown()
    if M.isOre(down, oreList) then
        M.digDown()
        movement.down(false)
        mined = mined + 1 + M.checkAndMineOres(movement, oreList, depth + 1)
        movement.up(false)
    end
    
    -- Check left
    movement.turnLeft()
    front = M.inspectForward()
    if M.isOre(front, oreList) then
        M.digForward()
        movement.forward(false)
        mined = mined + 1 + M.checkAndMineOres(movement, oreList, depth + 1)
        movement.back()
    end
    
    -- Check right (turn 180 from left)
    movement.turnAround()
    front = M.inspectForward()
    if M.isOre(front, oreList) then
        M.digForward()
        movement.forward(false)
        mined = mined + 1 + M.checkAndMineOres(movement, oreList, depth + 1)
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
