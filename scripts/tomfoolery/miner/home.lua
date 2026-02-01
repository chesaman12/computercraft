--- Home management module for smart mining turtle
-- Handles chest deposits, restocking, and idling for resources
-- @module miner.home

local M = {}

local core = nil

--- Initialize with core module reference
-- @param coreModule table The miner.core module
function M.init(coreModule)
    core = coreModule
end

--- Wait for user to provide a resource (fuel or torches)
-- @param resource string "fuel" or "torches"
local function idleForResource(resource)
    print("")
    print("========================================")
    print("  IDLE: Waiting for " .. resource)
    print("========================================")
    print("")
    print("Add more " .. resource .. " to the chest and press Enter.")
    
    while true do
        read()
        
        if resource == "fuel" then
            -- Try consuming fuel from inventory first
            for slot = 1, 15 do
                if turtle.getItemCount(slot) > 0 then
                    turtle.select(slot)
                    if turtle.refuel(0) then
                        turtle.refuel()
                    end
                end
            end
            
            -- Try to get fuel from chest
            if core.fuel.getLevel() < core.config.minFuelToStart and core.isChestInFront() then
                M.pullFuelFromChest()
            end
            
            if core.fuel.getLevel() >= core.config.minFuelToStart then
                print("Fuel replenished! Resuming...")
                return true
            end
            print(string.format("Still need %d fuel.", core.config.minFuelToStart - core.fuel.getLevel()))
            
        elseif resource == "torches" then
            if core.isChestInFront() then
                turtle.select(core.config.torchSlot)
                turtle.suck(64)
            end
            
            if core.getTorchCount() > 0 then
                print("Torches replenished! Resuming...")
                return true
            end
            print("No torches found. Add torches to the chest.")
        end
    end
end

--- Pull fuel items from chest, returning non-fuel items
function M.pullFuelFromChest()
    local nonFuelSlots = {}
    local attempts = 0
    
    while core.fuel.getLevel() < core.config.minFuelToStart and attempts < 27 do
        attempts = attempts + 1
        
        -- Find empty slot
        local emptySlot = nil
        for slot = 1, 15 do
            if turtle.getItemCount(slot) == 0 then
                emptySlot = slot
                break
            end
        end
        
        if not emptySlot then
            -- Return non-fuel items to free space
            for _, slot in ipairs(nonFuelSlots) do
                if turtle.getItemCount(slot) > 0 then
                    turtle.select(slot)
                    turtle.drop()
                end
            end
            nonFuelSlots = {}
            
            for slot = 1, 15 do
                if turtle.getItemCount(slot) == 0 then
                    emptySlot = slot
                    break
                end
            end
            if not emptySlot then break end
        end
        
        turtle.select(emptySlot)
        if turtle.suck(64) then
            if turtle.refuel(0) then
                turtle.refuel()
            else
                table.insert(nonFuelSlots, emptySlot)
            end
        else
            break -- Chest empty
        end
    end
    
    -- Return non-fuel items
    for _, slot in ipairs(nonFuelSlots) do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            turtle.drop()
        end
    end
end

--- Deposit items and restock supplies
-- @return boolean Success
function M.depositAndRestock()
    -- Ensure chest exists
    if not core.isChestInFront() then
        print("")
        printError("  ERROR: No chest found!")
        print("Place a chest and press Enter.")
        
        while not core.isChestInFront() do
            read()
        end
        print("Chest detected!")
    end
    
    -- Drop junk first
    core.inventory.dropJunk()
    
    -- Deposit non-fuel items (keep fuel for mobile refueling)
    for slot = 1, 15 do
        local detail = turtle.getItemDetail(slot)
        if detail then
            turtle.select(slot)
            if not turtle.refuel(0) then
                turtle.drop()
            end
        end
    end
    
    -- Refuel from inventory if needed
    if not core.fuel.isUnlimited() and core.fuel.getLevel() < core.config.minFuelToStart then
        core.fuel.autoRefuel(core.config.minFuelToStart)
    end
    
    -- Pull more fuel from chest if still needed
    if not core.fuel.isUnlimited() and core.fuel.getLevel() < core.config.minFuelToStart then
        M.pullFuelFromChest()
        
        -- Drop any remaining non-fuel items
        for slot = 1, 15 do
            local detail = turtle.getItemDetail(slot)
            if detail then
                turtle.select(slot)
                if not turtle.refuel(0) then
                    turtle.drop()
                end
            end
        end
    end
    
    -- Restock torches
    if core.config.placeTorches and core.getTorchCount() < 32 then
        turtle.select(core.config.torchSlot)
        turtle.suck(64)
    end
    
    core.stats.tripsHome = core.stats.tripsHome + 1
    
    -- Idle if still missing resources
    local fuelOk = core.fuel.isUnlimited() or core.fuel.getLevel() >= core.config.minFuelToStart
    local torchesOk = not core.config.placeTorches or core.getTorchCount() > 0
    
    if not fuelOk then
        idleForResource("fuel")
    end
    if not torchesOk then
        idleForResource("torches")
    end
    
    return true
end

--- Navigate home, deposit, then return to saved position
function M.returnHomeAndDeposit()
    local pos = core.movement.getPosition()
    local savedPos = { x = pos.x, y = pos.y, z = pos.z }
    local savedFacing = core.movement.getFacing()
    
    print("Returning home to deposit...")
    
    core.movement.goHome(true)
    core.movement.turnTo(0)
    core.movement.turnAround()
    
    M.depositAndRestock()
    
    core.movement.turnAround()
    
    print("Returning to mining position...")
    core.movement.goTo(savedPos.x, savedPos.y, savedPos.z, true)
    core.movement.turnTo(savedFacing)
    
    print("Resuming mining...")
end

--- Ensure chest is behind turtle, prompt if not
function M.verifyChest()
    core.movement.turnAround()
    if core.isChestInFront() then
        print("Chest detected!")
    else
        printError("WARNING: No chest detected behind turtle!")
        print("Place a chest behind the turtle for deposits.")
        print("Press Enter to continue.")
        read()
    end
    core.movement.turnAround()
end

return M
