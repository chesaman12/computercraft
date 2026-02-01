--- Inventory management module for turtles
-- Handles item management, filtering, and organization
-- @module inventory

local M = {}

-- Try to load config module for external lists
local configLoaded, config = pcall(require, "common.config")

--- Default list of items to discard (junk blocks)
local DEFAULT_JUNK = {
    ["minecraft:cobblestone"] = true,
    ["minecraft:dirt"] = true,
    ["minecraft:gravel"] = true,
    ["minecraft:sand"] = true,
    ["minecraft:netherrack"] = true,
    ["minecraft:cobbled_deepslate"] = true,
    ["minecraft:tuff"] = true,
    ["minecraft:granite"] = true,
    ["minecraft:diorite"] = true,
    ["minecraft:andesite"] = true,
    ["minecraft:stone"] = true,
    ["minecraft:deepslate"] = true,
}

--- Load junk list from config file, falling back to defaults
local function loadJunk()
    if configLoaded and config.exists("junk.cfg") then
        local junk = config.loadSet("junk.cfg")
        local count = 0
        for _ in pairs(junk) do count = count + 1 end
        if count > 0 then
            return junk
        end
    end
    return DEFAULT_JUNK
end

--- Junk items loaded from config/junk.cfg or defaults
M.JUNK_ITEMS = loadJunk()

--- Reload junk list from config file
function M.reloadJunk()
    M.JUNK_ITEMS = loadJunk()
    local count = 0
    for _ in pairs(M.JUNK_ITEMS) do count = count + 1 end
    return count
end

--- Add a junk item (runtime only)
-- @param itemName string Block ID
function M.addJunk(itemName)
    M.JUNK_ITEMS[itemName] = true
end

--- Remove a junk item (runtime only)
-- @param itemName string Block ID
function M.removeJunk(itemName)
    M.JUNK_ITEMS[itemName] = nil
end

--- Print all registered junk items
function M.printJunk()
    print("=== Junk Items ===")
    local list = {}
    for name in pairs(M.JUNK_ITEMS) do
        table.insert(list, name)
    end
    table.sort(list)
    for _, name in ipairs(list) do
        print("  " .. name)
    end
    print(string.format("Total: %d items", #list))
end

--- Valuable ores that should always be kept
M.VALUABLE_ITEMS = {
    ["minecraft:diamond"] = true,
    ["minecraft:emerald"] = true,
    ["minecraft:diamond_ore"] = true,
    ["minecraft:deepslate_diamond_ore"] = true,
    ["minecraft:emerald_ore"] = true,
    ["minecraft:deepslate_emerald_ore"] = true,
    ["minecraft:ancient_debris"] = true,
    ["minecraft:gold_ore"] = true,
    ["minecraft:deepslate_gold_ore"] = true,
    ["minecraft:iron_ore"] = true,
    ["minecraft:deepslate_iron_ore"] = true,
    ["minecraft:copper_ore"] = true,
    ["minecraft:deepslate_copper_ore"] = true,
    ["minecraft:coal_ore"] = true,
    ["minecraft:deepslate_coal_ore"] = true,
    ["minecraft:lapis_ore"] = true,
    ["minecraft:deepslate_lapis_ore"] = true,
    ["minecraft:redstone_ore"] = true,
    ["minecraft:deepslate_redstone_ore"] = true,
    ["minecraft:raw_iron"] = true,
    ["minecraft:raw_gold"] = true,
    ["minecraft:raw_copper"] = true,
    ["minecraft:coal"] = true,
    ["minecraft:diamond"] = true,
    ["minecraft:emerald"] = true,
    ["minecraft:lapis_lazuli"] = true,
    ["minecraft:redstone"] = true,
}

--- Check if inventory is full
-- @return boolean True if all slots have items
function M.isFull()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            return false
        end
    end
    return true
end

--- Check if inventory is empty
-- @return boolean True if no slots have items
function M.isEmpty()
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            return false
        end
    end
    return true
end

--- Count empty slots
-- @return number Number of empty slots
function M.emptySlots()
    local count = 0
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            count = count + 1
        end
    end
    return count
end

--- Count total items in inventory
-- @return number Total item count
function M.totalItems()
    local count = 0
    for slot = 1, 16 do
        count = count + turtle.getItemCount(slot)
    end
    return count
end

--- Find slot containing a specific item
-- @param itemName string The item name to find
-- @return number|nil Slot number or nil if not found
function M.findItem(itemName)
    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot)
        if detail and detail.name == itemName then
            return slot
        end
    end
    return nil
end

--- Find all slots containing a specific item
-- @param itemName string The item name to find
-- @return table Array of slot numbers
function M.findAllItems(itemName)
    local slots = {}
    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot)
        if detail and detail.name == itemName then
            table.insert(slots, slot)
        end
    end
    return slots
end

--- Select a slot containing a specific item
-- @param itemName string The item name to select
-- @return boolean True if item was found and selected
function M.selectItem(itemName)
    local slot = M.findItem(itemName)
    if slot then
        turtle.select(slot)
        return true
    end
    return false
end

--- Check if an item is considered junk
-- @param itemName string The item name to check
-- @param junkList table|nil Custom junk list (optional)
-- @return boolean True if item is junk
function M.isJunk(itemName, junkList)
    junkList = junkList or M.JUNK_ITEMS
    return junkList[itemName] == true
end

--- Check if an item is valuable
-- @param itemName string The item name to check
-- @param valuableList table|nil Custom valuable list (optional)
-- @return boolean True if item is valuable
function M.isValuable(itemName, valuableList)
    valuableList = valuableList or M.VALUABLE_ITEMS
    return valuableList[itemName] == true
end

--- Drop all junk items
-- @param junkList table|nil Custom junk list (optional)
-- @param direction string Direction to drop ("forward", "up", "down", default: "down")
-- @return number Number of slots cleared
function M.dropJunk(junkList, direction)
    junkList = junkList or M.JUNK_ITEMS
    direction = direction or "down"
    
    local dropFunc
    if direction == "up" then
        dropFunc = turtle.dropUp
    elseif direction == "down" then
        dropFunc = turtle.dropDown
    else
        dropFunc = turtle.drop
    end
    
    local cleared = 0
    local originalSlot = turtle.getSelectedSlot()
    
    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot)
        if detail and junkList[detail.name] then
            turtle.select(slot)
            if dropFunc() then
                cleared = cleared + 1
            end
        end
    end
    
    turtle.select(originalSlot)
    return cleared
end

--- Compact inventory by consolidating stacks
function M.compact()
    local originalSlot = turtle.getSelectedSlot()
    
    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot)
        if detail then
            turtle.select(slot)
            -- Try to transfer to earlier slots with same item
            for targetSlot = 1, slot - 1 do
                local targetDetail = turtle.getItemDetail(targetSlot)
                if targetDetail and targetDetail.name == detail.name then
                    turtle.transferTo(targetSlot)
                    if turtle.getItemCount(slot) == 0 then
                        break
                    end
                end
            end
        end
    end
    
    turtle.select(originalSlot)
end

--- Dump entire inventory in a direction
-- @param direction string Direction to drop ("forward", "up", "down", default: "forward")
-- @param keepSlots table|nil Slots to keep (optional)
-- @return number Number of items dropped
function M.dumpAll(direction, keepSlots)
    direction = direction or "forward"
    keepSlots = keepSlots or {}
    
    local dropFunc
    if direction == "up" then
        dropFunc = turtle.dropUp
    elseif direction == "down" then
        dropFunc = turtle.dropDown
    else
        dropFunc = turtle.drop
    end
    
    local keepSet = {}
    for _, slot in ipairs(keepSlots) do
        keepSet[slot] = true
    end
    
    local dropped = 0
    local originalSlot = turtle.getSelectedSlot()
    
    for slot = 1, 16 do
        if not keepSet[slot] and turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            if dropFunc() then
                dropped = dropped + turtle.getItemCount(slot)
            end
        end
    end
    
    turtle.select(originalSlot)
    return dropped
end

--- Get inventory summary
-- @return table Summary with item counts
function M.getSummary()
    local summary = {}
    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot)
        if detail then
            if summary[detail.name] then
                summary[detail.name] = summary[detail.name] + detail.count
            else
                summary[detail.name] = detail.count
            end
        end
    end
    return summary
end

--- Print inventory summary to terminal
function M.printSummary()
    local summary = M.getSummary()
    print("=== Inventory Summary ===")
    for name, count in pairs(summary) do
        -- Remove minecraft: prefix for cleaner display
        local displayName = name:gsub("^minecraft:", "")
        print(string.format("  %s: %d", displayName, count))
    end
    print("Empty slots: " .. M.emptySlots())
end

--- Check if there's enough fuel
-- @param needed number Fuel level needed
-- @return boolean True if sufficient fuel
function M.hasFuel(needed)
    local level = turtle.getFuelLevel()
    if level == "unlimited" then
        return true
    end
    return level >= needed
end

--- Auto-refuel from inventory
-- @param targetLevel number Target fuel level (default: 1000)
-- @return boolean True if refueling succeeded
function M.autoRefuel(targetLevel)
    targetLevel = targetLevel or 1000
    
    local level = turtle.getFuelLevel()
    if level == "unlimited" or level >= targetLevel then
        return true
    end
    
    local originalSlot = turtle.getSelectedSlot()
    
    for slot = 1, 16 do
        turtle.select(slot)
        -- Check if item is fuel (refuel with 0 tests without consuming)
        if turtle.refuel(0) then
            while turtle.getFuelLevel() < targetLevel and turtle.getItemCount(slot) > 0 do
                turtle.refuel(1)
            end
            if turtle.getFuelLevel() >= targetLevel then
                turtle.select(originalSlot)
                return true
            end
        end
    end
    
    turtle.select(originalSlot)
    return turtle.getFuelLevel() >= targetLevel
end

return M
