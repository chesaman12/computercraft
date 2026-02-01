--- Fuel management module for turtles
-- Handles fuel checking, refueling, and fuel level monitoring
-- @module fuel

local M = {}

--- Default minimum fuel threshold before warning
M.LOW_FUEL_THRESHOLD = 100

--- Default target fuel level when refueling
M.REFUEL_TARGET = 1000

--- Get current fuel level
-- @return number|string Fuel level or "unlimited"
function M.getLevel()
    return turtle.getFuelLevel()
end

--- Get fuel limit
-- @return number|string Fuel limit or "unlimited"
function M.getLimit()
    return turtle.getFuelLimit()
end

--- Check if fuel is unlimited (creative mode)
-- @return boolean True if unlimited fuel
function M.isUnlimited()
    return turtle.getFuelLevel() == "unlimited"
end

--- Check if fuel is low
-- @param threshold number|nil Custom threshold (default: LOW_FUEL_THRESHOLD)
-- @return boolean True if fuel is below threshold
function M.isLow(threshold)
    if M.isUnlimited() then
        return false
    end
    threshold = threshold or M.LOW_FUEL_THRESHOLD
    return turtle.getFuelLevel() < threshold
end

--- Check if there's enough fuel for a journey
-- @param distance number Required fuel (movements)
-- @param returnTrip boolean Whether to include return trip fuel
-- @return boolean True if enough fuel
function M.hasEnough(distance, returnTrip)
    if M.isUnlimited() then
        return true
    end
    local needed = distance
    if returnTrip then
        needed = needed * 2
    end
    return turtle.getFuelLevel() >= needed
end

--- Estimate fuel needed to return home
-- @param position table Position table with x, y, z
-- @return number Estimated fuel needed
function M.estimateReturnFuel(position)
    if not position then return 0 end
    return math.abs(position.x or 0) + 
           math.abs(position.y or 0) + 
           math.abs(position.z or 0)
end

--- Try to refuel from a specific slot
-- @param slot number Slot to refuel from
-- @param count number|nil Number of items to consume (default: all)
-- @return boolean Success
function M.refuelFromSlot(slot, count)
    local originalSlot = turtle.getSelectedSlot()
    turtle.select(slot)
    
    local success = turtle.refuel(count)
    
    turtle.select(originalSlot)
    return success
end

--- Auto-refuel from inventory
-- @param targetLevel number|nil Target fuel level (default: REFUEL_TARGET)
-- @return boolean True if target level reached
-- @return number New fuel level
function M.autoRefuel(targetLevel)
    targetLevel = targetLevel or M.REFUEL_TARGET
    
    if M.isUnlimited() then
        return true, "unlimited"
    end
    
    if turtle.getFuelLevel() >= targetLevel then
        return true, turtle.getFuelLevel()
    end
    
    local originalSlot = turtle.getSelectedSlot()
    
    for slot = 1, 16 do
        turtle.select(slot)
        -- Test if item is fuel without consuming
        if turtle.refuel(0) then
            while turtle.getFuelLevel() < targetLevel and turtle.getItemCount(slot) > 0 do
                turtle.refuel(1)
            end
            if turtle.getFuelLevel() >= targetLevel then
                break
            end
        end
    end
    
    turtle.select(originalSlot)
    return turtle.getFuelLevel() >= targetLevel, turtle.getFuelLevel()
end

--- Find fuel items in inventory
-- @return table Array of {slot, count, name} for fuel items
function M.findFuelItems()
    local fuelItems = {}
    local originalSlot = turtle.getSelectedSlot()
    
    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot)
        if detail then
            turtle.select(slot)
            if turtle.refuel(0) then
                table.insert(fuelItems, {
                    slot = slot,
                    count = detail.count,
                    name = detail.name
                })
            end
        end
    end
    
    turtle.select(originalSlot)
    return fuelItems
end

--- Calculate total potential fuel in inventory
-- @return number Approximate fuel value
function M.potentialFuel()
    -- Common fuel values (approximate)
    local fuelValues = {
        ["minecraft:coal"] = 80,
        ["minecraft:charcoal"] = 80,
        ["minecraft:coal_block"] = 800,
        ["minecraft:blaze_rod"] = 120,
        ["minecraft:lava_bucket"] = 1000,
        ["minecraft:stick"] = 5,
        ["minecraft:planks"] = 15,
    }
    
    local total = 0
    for slot = 1, 16 do
        local detail = turtle.getItemDetail(slot)
        if detail then
            -- Check known fuel values
            for pattern, value in pairs(fuelValues) do
                if detail.name:match(pattern) or detail.name == pattern then
                    total = total + (value * detail.count)
                    break
                end
            end
            -- Check for planks pattern
            if detail.name:match("planks") then
                total = total + (15 * detail.count)
            end
        end
    end
    
    return total
end

--- Print fuel status to terminal
function M.printStatus()
    local level = M.getLevel()
    local limit = M.getLimit()
    
    print("=== Fuel Status ===")
    if level == "unlimited" then
        print("  Fuel: Unlimited")
    else
        print(string.format("  Level: %d / %d", level, limit))
        print(string.format("  Percentage: %.1f%%", (level / limit) * 100))
        if M.isLow() then
            print("  WARNING: Fuel is low!")
        end
    end
end

--- Wait for user to add fuel (interactive)
-- @param targetLevel number Required fuel level
-- @return boolean True if fuel requirement met
function M.waitForFuel(targetLevel)
    targetLevel = targetLevel or M.REFUEL_TARGET
    
    while not M.isUnlimited() and turtle.getFuelLevel() < targetLevel do
        print(string.format("Need %d fuel, have %d", targetLevel, turtle.getFuelLevel()))
        print("Add fuel items and press Enter...")
        read()
        M.autoRefuel(targetLevel)
    end
    
    return true
end

return M
