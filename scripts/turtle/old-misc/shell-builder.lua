-- MOVEMENT FUNCTIONS ----------------------------------------------------------------

-- Function to move up once, ensuring there is no block above
-- returns true if the turtle successfully moved up
--         false if the turtle couldn't move up
-- throws an error if the block above cannot be dug
function digAndMoveUp()
    -- Check if there's a block above and dig it out if necessary
    if turtle.detectUp() then
        if not turtle.digUp() then
            error("Failed to dig block above. It might be unbreakable.")
        end
    end
    
    -- Attempt to move up
    if not turtle.up() then
        return false
    end
    
    return true
end

-- Function to turn the turtle to the left
-- returns true if the turtle successfully turned left
function turnLeft()
    return turtle.turnLeft()
end

-- Function to turn the turtle to the right
-- returns true if the turtle successfully turned right
function turnRight()
    return turtle.turnRight()
end

-- Function to turn the turtle around (180 degrees)
-- returns true if the turtle successfully turned around
function turnAround()
    turnLeft()
    turnLeft()
    return true
end


-- Function to dig in front of the turtle and then move forward
-- returns true if the turtle successfully moved forward
--         false if the turtle couldn't move forward
-- throws an error if the block cannot be dug
function digAndMoveForward()
    -- Dig the block in front if there is one
    if turtle.detect() then
        if not turtle.dig() then
            error("Failed to dig block in front. It might be unbreakable.")
        end
    end
    
    -- Attempt to move forward
    if not turtle.forward() then
        return false
    end
    
    return true
end

-- Function to place a block below the turtle
-- returns true if the block was successfully placed
--         false if no blocks are in the selected slot
-- throws an error if the block cannot be placed
function placeBlockBelow()
    -- Check if there are any blocks in the selected slot
    if turtle.getItemCount() <= 0 then
        return false
    end
    
    -- Check if there's a block below and dig it out if necessary
    if turtle.detectDown() then
        if not turtle.digDown() then
            error("Failed to dig block below. It might be unbreakable.")
        end
    end
    
    -- Attempt to place the block
    if not turtle.placeDown() then
        error("Failed to place block. There might still be an obstacle below.")
    end
    
    return true
end

-- SLOT FUNCTIONS ----------------------------------------------------------------

-- Function to detect the item in a specific slot
-- returns the item name or nil if the slot is empty
function getNameOfItemInSlot(slotItemNumber)
    turtle.select(slotItemNumber)
    local itemDetail = turtle.getItemDetail()
    
    if itemDetail then
        return itemDetail.name
    else
        return nil
    end
end

-- Function to select a specific slot
-- Returns true if the slot was successfully selected, false otherwise
function selectSlot(slotNumber)
    if slotNumber < 1 or slotNumber > 16 then
        print("Invalid slot number. Please choose a number between 1 and 16.")
        return false
    end
    
    return turtle.select(slotNumber)
end

-- USER INPUT FUNCTIONS ----------------------------------------------------------------

-- Function to get user input for a specific axis dimension
function getAxisInput(axisName)
    while true do
        print("Enter the " .. axisName .. " dimension (positive number):")
        local input = read()
        local number = tonumber(input)
        
        if number and number > 0 then
            return number
        else
            print("Invalid input. Please enter a positive number.")
        end
    end
end

-- Function to get dimensions for all axes
-- returns a table with the following keys:
-- - x: the depth (x-axis)
-- - y: the width (y-axis)
-- - z: the height (z-axis)
function getDimensionsInput()
    local dimensions = {}
    dimensions.x = getAxisInput("height")
    dimensions.y = getAxisInput("width")
    dimensions.z = getAxisInput("length")
    return dimensions
end

-- Function to get user input for direction (left or right)
-- returns "left" or "right"
function getLeftOrRightInput()
    while true do
        print("Enter the direction (left/l or right/r):")
        local input = string.lower(read())
        
        if input == "left" or input == "l" then
            return "left"
        elseif input == "right" or input == "r" then
            return "right"
        else
            print("Invalid input. Please enter 'left', 'l', 'right', or 'r'.")
        end
    end
end

-- Function to get user input for floor/ceiling options
-- returns "n", "f", "c", or "b"
function getFloorCeilingInput()
    while true do
        print("Want a floor, ceiling, both, or none?")
        print("b - Both floor and ceiling")
        print("f - Floor only")
        print("c - Ceiling only")
        print("n - None (or hit enter)")
        local input = string.lower(read())
        
        if input == "n" or input == "" then
            return "n"
        elseif input == "f" or input == "c" or input == "b" then
            return input
        else
            print("Invalid input. Please enter 'n', 'f', 'c', 'b', or leave empty for none.")
        end
    end
end




-- MAIN BUILDING FUNCTIONS ----------------------------------------------------------------
function buildWalls(dimensions, direction)
    local height = dimensions.x
    for i = 1, height do
        buildWall(dimensions, direction)
    end
end

function buildWall(dimensions, direction)
    digAndMoveUp()
    placeRow(dimensions.z)

    if direction == "left" then
        turnLeft()
        digAndMoveForward()
    else
        turnRight()
        digAndMoveForward()
    end

    placeRow(dimensions.y - 1)
    if direction == "left" then
        turnLeft()
        digAndMoveForward()
    else
        turnRight()
        digAndMoveForward()
    end

    placeRow(dimensions.z - 1)
    if direction == "left" then
        turnLeft()
        digAndMoveForward()
    else
        turnRight()
        digAndMoveForward()
    end

    placeRow(dimensions.y - 1)
    if direction == "left" then
        turnLeft()
    else
        turnRight()
    end
end

-- Function to place a floor or ceiling
function placeLayer(dimensions, direction)
    for y = 1, dimensions.y do
        if not placeRow(dimensions.z) then
            return false
        end
        
        if y < dimensions.y then
            if not moveToNextRow(y, direction) then
                return false
            end
        end
    end

    if direction == "left" then
        turnLeft()
    else
        turnRight()
    end

    for y = 1, dimensions.y - 1 do
        digAndMoveForward()
    end

    if direction == "left" then
        turnLeft()
    else
        turnRight()
    end

    return true
end

function placeRow(length)
    local startSlot = turtle.getSelectedSlot()
    local currentSlot = startSlot

    for z = 1, length do
        if not placeBlockBelow() then
            print("Failed to place block. Checking inventory...")
            if not checkInventoryAndPlace(currentSlot, startSlot) then
                return false
            end
        end
        
        if z < length then
            if not digAndMoveForward() then
                print("Unable to move forward. Aborting.")
                return false
            end
        end
    end
    return true
end

function checkInventoryAndPlace(currentSlot, startSlot)
    repeat
        currentSlot = (currentSlot % 16) + 1
        selectSlot(currentSlot)
        if placeBlockBelow() then
            return true
        end
    until currentSlot == startSlot

    if currentSlot == startSlot then
        print("Out of blocks. Please refill and press Enter to continue.")
        turtle.read()
        if not placeBlockBelow() then
            print("Still unable to place block. Aborting.")
            return false
        end
    end
    return true
end

function moveToNextRow(row, direction)
    print("Moving to next row. Current row:", row, "Direction:", direction)
    
    if direction == "left" then
        if row % 2 == 1 then
            turnLeft()
            if not digAndMoveForward() then
                print("Unable to move to next row. Aborting.")
                return false
            end
            turnLeft()
        else
            turnRight()
            if not digAndMoveForward() then
                print("Unable to move to next row. Aborting.")
                return false
            end
            turnRight()
        end
    else -- direction == "right"
        if row % 2 == 1 then
            turnRight()
            if not digAndMoveForward() then
                print("Unable to move to next row. Aborting.")
                return false
            end
            turnRight()
        else
            turnLeft()
            if not digAndMoveForward() then
                print("Unable to move to next row. Aborting.")
                return false
            end
            turnLeft()
        end
    end
    
    return true
end

-- MAIN FUNCTIONS ----------------------------------------------------------------

-- Function to handle the building process based on user input
function handleBuildingProcess(direction, dimensions, floorCeiling)
    if floorCeiling == "f" then 
        placeLayer(dimensions, direction)
        buildWalls(dimensions, direction)
    elseif floorCeiling == "c" then
        buildWalls(dimensions, direction)
        placeLayer(dimensions, direction)
    elseif floorCeiling == "b" then
        placeLayer(dimensions, direction)
        buildWalls(dimensions, direction)  
        placeLayer(dimensions, direction)
    else
        buildWalls(dimensions, direction)
    end
end


-- Main function to run the shell builder
function main()
    local direction = getLeftOrRightInput()
    local dimensions = getDimensionsInput()
    local floorCeiling = getFloorCeilingInput()

    -- todo build walls doesn't work, need to replace buildWalls and buildWallSegment
    handleBuildingProcess(direction, dimensions, floorCeiling)
end

-- Call the main function to start the program
main()

