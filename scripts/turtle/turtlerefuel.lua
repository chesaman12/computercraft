-- Function to find a bucket in the inventory
local function findBucket()
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item and (item.name == "minecraft:bucket" or item.name == "minecraft:lava_bucket") then
            return i, item.name
        end
    end
    return nil, nil
end

-- Function to refuel using lava
local function refuelWithLava()
    local bucketSlot, bucketType = findBucket()
    if not bucketSlot then
        print("No bucket found in inventory")
        return false
    end

    turtle.select(bucketSlot)
    
    if bucketType == "minecraft:lava_bucket" then
        -- If the bucket is already full of lava, refuel directly
        if not turtle.refuel(1) then
            print("Failed to refuel with lava")
            return false
        end
    else
        -- Attempt to collect lava from the tank below
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

-- Main refueling loop
local initialFuel = turtle.getFuelLevel()
print("Initial fuel level: " .. initialFuel)

local fuelLimit = turtle.getFuelLimit()
print("Fuel limit: " .. fuelLimit)

while turtle.getFuelLevel() < fuelLimit do
    if not refuelWithLava() then
        print("Refueling failed")
        break
    end
    print("Current fuel level: " .. turtle.getFuelLevel())
end

local finalFuel = turtle.getFuelLevel()
print("Final fuel level: " .. finalFuel)
print("Fuel added: " .. (finalFuel - initialFuel))