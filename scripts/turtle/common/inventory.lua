--- Inventory management utilities for turtles
-- @module inventory

local M = {}

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

--- Count empty slots
-- @return number Number of empty slots
function M.countEmptySlots()
    local count = 0
    for slot = 1, 16 do
        if turtle.getItemCount(slot) == 0 then
            count = count + 1
        end
    end
    return count
end

--- Find next slot with items, starting from current slot
-- @param startSlot number Starting slot (defaults to 1)
-- @return number Slot with items, wraps around to 1 if needed
function M.findNextFilledSlot(startSlot)
    startSlot = startSlot or 1
    local slot = startSlot
    
    repeat
        if turtle.getItemCount(slot) > 0 then
            return slot
        end
        slot = slot + 1
        if slot > 16 then
            slot = 1
        end
    until slot == startSlot
    
    return startSlot
end

--- Select next slot with items for placing
-- @param currentSlot number Current slot number
-- @return number New selected slot
function M.selectNextFilled(currentSlot)
    currentSlot = currentSlot or turtle.getSelectedSlot()
    
    while turtle.getItemCount(currentSlot) == 0 do
        currentSlot = currentSlot + 1
        if currentSlot > 16 then
            currentSlot = 1
        end
        turtle.select(currentSlot)
    end
    
    return currentSlot
end

--- Drop items matching a list of junk item IDs
-- @param junkList table Table with item IDs as keys (e.g., {["minecraft:cobblestone"] = true})
-- @param excludeSlot number Slot to exclude from dropping (optional)
function M.dropJunk(junkList, excludeSlot)
    excludeSlot = excludeSlot or 0
    
    for slot = 1, 16 do
        if slot ~= excludeSlot then
            local detail = turtle.getItemDetail(slot)
            if detail and junkList[detail.name] then
                turtle.select(slot)
                turtle.drop()
            end
        end
    end
    turtle.select(1)
end

--- Dump all items to chest in front
-- @param excludeSlot number Slot to exclude from dumping (e.g., fuel slot)
function M.dumpToChest(excludeSlot)
    excludeSlot = excludeSlot or 0
    
    for slot = 1, 16 do
        if slot ~= excludeSlot then
            turtle.select(slot)
            turtle.drop()
        end
    end
    turtle.select(1)
end

--- Load junk list from file
-- @param path string Path to junk list file
-- @param defaultList string Default content if file doesn't exist
-- @return table Table with item IDs as keys
function M.loadJunkList(path, defaultList)
    if not fs.exists(path) and defaultList then
        local handle = fs.open(path, "w")
        handle.write(defaultList)
        handle.close()
    end

    local items = {}
    if fs.exists(path) then
        local handle = fs.open(path, "r")
        while true do
            local line = handle.readLine()
            if not line then
                break
            end
            line = line:gsub("^%s+", ""):gsub("%s+$", "")
            if line ~= "" and line:sub(1, 1) ~= "#" then
                items[line] = true
            end
        end
        handle.close()
    end
    return items
end

return M
