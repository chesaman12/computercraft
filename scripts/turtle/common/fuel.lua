--- Fuel management utilities for turtles
-- @module fuel

local M = {}

--- Minimum fuel level before requiring refuel
M.MIN_FUEL_LEVEL = 100

--- Check if fuel level is adequate and prompt for refuel if needed
-- @param minNeeded number Minimum fuel level required (defaults to MIN_FUEL_LEVEL)
-- @return boolean True if fuel is adequate
function M.ensureFuel(minNeeded)
    minNeeded = minNeeded or M.MIN_FUEL_LEVEL
    local fuel = turtle.getFuelLevel()
    
    if fuel == "unlimited" then
        return true
    end
    
    if fuel >= minNeeded then
        return true
    end

    print("Fuel low. Insert fuel and press enter to refuel.")
    read()
    shell.run("refuel", "all")

    fuel = turtle.getFuelLevel()
    if fuel == "unlimited" or fuel >= minNeeded then
        return true
    end

    print("Not enough fuel. Need at least " .. minNeeded .. ", have " .. fuel .. ".")
    return false
end

--- Verify fuel level and pause if too low
function M.verifyFuelLevel()
    local fuelLevel = turtle.getFuelLevel()

    if fuelLevel ~= "unlimited" and fuelLevel <= M.MIN_FUEL_LEVEL then
        write("Fuel level low. Insert fuel & press enter to continue.\n")
        read()
        shell.run("refuel", "all")
        write("New fuel level: " .. turtle.getFuelLevel() .. "\n")
    end
end

--- Attempt to refuel from inventory
-- @param amount number Amount of fuel items to consume (optional)
-- @return boolean True if refueling succeeded
function M.refuelFromInventory(amount)
    local currentSlot = turtle.getSelectedSlot()
    local refueled = false
    
    for slot = 1, 16 do
        turtle.select(slot)
        if turtle.refuel(amount or 0) then
            refueled = true
        end
    end
    
    turtle.select(currentSlot)
    return refueled
end

--- Find a bucket in the inventory
-- @return number|nil slot Slot number containing bucket, or nil
-- @return string|nil type Bucket type (minecraft:bucket or minecraft:lava_bucket)
function M.findBucket()
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item and (item.name == "minecraft:bucket" or item.name == "minecraft:lava_bucket") then
            return i, item.name
        end
    end
    return nil, nil
end

--- Refuel using lava from below (requires bucket)
-- @return boolean True if refueling succeeded
function M.refuelWithLava()
    local bucketSlot, bucketType = M.findBucket()
    if not bucketSlot then
        print("No bucket found in inventory")
        return false
    end

    turtle.select(bucketSlot)
    
    if bucketType == "minecraft:lava_bucket" then
        if not turtle.refuel(1) then
            print("Failed to refuel with lava")
            return false
        end
    else
        if not turtle.placeDown() then
            print("Failed to use bucket on tank below")
            return false
        end

        local item = turtle.getItemDetail()
        if not item or item.name ~= "minecraft:lava_bucket" then
            print("Failed to collect lava")
            return false
        end

        if not turtle.refuel(1) then
            print("Failed to refuel with lava")
            return false
        end
    end

    return true
end

return M
