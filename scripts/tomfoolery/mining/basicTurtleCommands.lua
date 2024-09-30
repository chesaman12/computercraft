-- Use variables from script args
-- local tArgs = { ... }
-- local length = tonumber( tArgs[1] )

-- MOVEMENT FUNCTIONS

-- Function to move the turtle forward
function moveForward()
    return turtle.forward()
end

-- Function to move the turtle backward
function moveBackward()
    return turtle.back()
end

-- Function to move the turtle up
function moveUp()
    return turtle.up()
end

-- Function to move the turtle down
function moveDown()
    return turtle.down()
end

-- Function to turn the turtle left
function turnLeft()
    return turtle.turnLeft()
end

-- Function to turn the turtle right
function turnRight()
    return turtle.turnRight()
end

-- DIGGING FUNCTIONS

-- Function to dig the block in front of the turtle
function digBlock()
    return turtle.dig()
end

-- Function to dig the block above the turtle
function digBlockAbove()
    return turtle.digUp()
end

-- Function to dig the block below the turtle
function digBlockBelow()
    return turtle.digDown()
end

-- PLACING FUNCTIONS

-- Function to place the block in front of the turtle
function placeBlock()
    return turtle.place()
end

-- Function to place the block above the turtle
function placeBlockAbove()
    return turtle.placeUp()
end

-- Function to place the block below the turtle
function placeBlockBelow()
    return turtle.placeDown()
end

-- Function to select a slot (1-16)
function selectSlot(slot)
    return turtle.select(slot)
end

-- Function to find and select a slot containing a specific item
function selectItem(itemName)
    for slot = 1, 16 do
        local itemDetail = turtle.getItemDetail(slot)
        if itemDetail and itemDetail.name == itemName then
            turtle.select(slot)
            return true
        end
    end
    print("Item not found in inventory: " .. itemName)
    return false
end

-- INSPECTING FUNCTIONS
-- The data table returned by inspect functions contains:
-- name: the name of the block
-- count: the number of blocks in the stack
-- damage: the damage value of the block
-- nbt: the NBT data of the block
-- displayName: the display name of the block
-- blockEntityTag: the block entity tag of the block
-- canPlace: a boolean indicating if the block can be placed
-- canDestroy: a boolean indicating if the block can be destroyed

-- Function to inspect the block in front of the turtle
function inspectBlock()
    local success, data = turtle.inspect()
    if success then
        return data
    else
        return nil
    end
end

-- Function to read the block in front of the turtle and print the item name
function readAndPrintBlock()
    local blockData = inspectBlock()
    if blockData then
        print("Block in front: " .. blockData.name)
    else
        print("No block in front.")
    end
end

-- Function to inspect the block above the turtle
function inspectBlockAbove()
    local success, data = turtle.inspectUp()
    if success then
        return data
    else
        return nil
    end
end

-- Function to inspect the block below the turtle
function inspectBlockBelow()
    local success, data = turtle.inspectDown()
    if success then
        return data
    else
        return nil
    end
end

-- ATTACKING FUNCTIONS

-- Function to attack the entity in front of the turtle
function attack()
    return turtle.attack()
end

-- Function to attack the entity above the turtle
function attackUp()
    return turtle.attackUp()
end

-- Function to attack the entity below the turtle
function attackDown()
    return turtle.attackDown()
end

-- SUCKING FUNCTIONS

-- Function to suck items from the block in front of the turtle
function suck()
    return turtle.suck()
end

-- Function to suck items from the block above the turtle
function suckUp()
    return turtle.suckUp()
end

-- Function to suck items from the block below the turtle
function suckDown()
    return turtle.suckDown()
end

-- DROPPING FUNCTIONS

-- Function to drop items in front of the turtle
function drop()
    return turtle.drop()
end

-- Function to drop items above the turtle
function dropUp()
    return turtle.dropUp()
end

-- Function to drop items below the turtle
function dropDown()
    return turtle.dropDown()
end

-- INVENTORY MANAGEMENT FUNCTIONS

-- Function to select a slot (1-16)
function selectSlot(slot)
    return turtle.select(slot)
end

-- Function to get the number of items in the specified slot
function getItemCount(slot)
    return turtle.getItemCount(slot)
end

-- Function to get the remaining space in the specified slot
function getItemSpace(slot)
    return turtle.getItemSpace(slot)
end

-- Function to transfer items to another slot
function transferTo(slot, count)
    return turtle.transferTo(slot, count)
end

-- FUEL MANAGEMENT FUNCTIONS

-- Function to refuel the turtle using items in the selected slot
function refuel(count)
    return turtle.refuel(count)
end

-- Function to get the current fuel level of the turtle
function getFuelLevel()
    return turtle.getFuelLevel()
end

-- Function to get the maximum fuel level of the turtle
function getFuelLimit()
    return turtle.getFuelLimit()
end

-- CRAFTING FUNCTION

-- Function to craft items using the turtle's inventory
function craft(quantity)
    return turtle.craft(quantity)
end
