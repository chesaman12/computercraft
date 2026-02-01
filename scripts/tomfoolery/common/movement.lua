--- Movement module for turtle navigation
-- Provides safe movement functions with position tracking and obstacle handling
-- @module movement

local M = {}

--- Current position tracking (relative to start position)
local position = { x = 0, y = 0, z = 0 }

--- Current facing direction (0 = north, 1 = east, 2 = south, 3 = west)
local facing = 0

--- Direction vectors for each facing direction
local DIRECTIONS = {
    [0] = { x = 0, z = -1 },  -- North
    [1] = { x = 1, z = 0 },   -- East
    [2] = { x = 0, z = 1 },   -- South
    [3] = { x = -1, z = 0 }   -- West
}

--- Get current position
-- @return table Position with x, y, z coordinates
function M.getPosition()
    return { x = position.x, y = position.y, z = position.z }
end

--- Get current facing direction
-- @return number Facing direction (0-3)
function M.getFacing()
    return facing
end

--- Set current position (for GPS calibration)
-- @param x number X coordinate
-- @param y number Y coordinate
-- @param z number Z coordinate
function M.setPosition(x, y, z)
    position.x = x
    position.y = y
    position.z = z
end

--- Set current facing direction
-- @param dir number Direction (0-3)
function M.setFacing(dir)
    facing = dir % 4
end

--- Turn left
-- @return boolean Success
function M.turnLeft()
    local success = turtle.turnLeft()
    if success then
        facing = (facing - 1) % 4
    end
    return success
end

--- Turn right
-- @return boolean Success
function M.turnRight()
    local success = turtle.turnRight()
    if success then
        facing = (facing + 1) % 4
    end
    return success
end

--- Turn to face a specific direction
-- @param targetDir number Target direction (0-3)
function M.turnTo(targetDir)
    targetDir = targetDir % 4
    local diff = (targetDir - facing) % 4
    if diff == 1 then
        M.turnRight()
    elseif diff == 2 then
        M.turnRight()
        M.turnRight()
    elseif diff == 3 then
        M.turnLeft()
    end
end

--- Turn around (180 degrees)
function M.turnAround()
    M.turnRight()
    M.turnRight()
end

--- Safely move forward, handling obstacles
-- @param dig boolean Whether to dig obstacles (default: false)
-- @param maxAttempts number Maximum retry attempts (default: 10)
-- @return boolean Success
-- @return string|nil Error message if failed
function M.forward(dig, maxAttempts)
    dig = dig or false
    maxAttempts = maxAttempts or 10
    
    for attempt = 1, maxAttempts do
        local success, err = turtle.forward()
        if success then
            local dir = DIRECTIONS[facing]
            position.x = position.x + dir.x
            position.z = position.z + dir.z
            return true
        end
        
        if turtle.detect() then
            if dig then
                turtle.dig()
                sleep(0.4)  -- Wait for gravel/sand
            else
                return false, "Block in way"
            end
        elseif turtle.attack() then
            -- Entity was in the way, attacked it
            sleep(0.2)
        else
            sleep(0.5)
        end
    end
    return false, "Failed after " .. maxAttempts .. " attempts"
end

--- Safely move backward
-- @return boolean Success
-- @return string|nil Error message if failed
function M.back()
    local success, err = turtle.back()
    if success then
        local dir = DIRECTIONS[facing]
        position.x = position.x - dir.x
        position.z = position.z - dir.z
    end
    return success, err
end

--- Safely move up, handling obstacles
-- @param dig boolean Whether to dig obstacles (default: false)
-- @param maxAttempts number Maximum retry attempts (default: 10)
-- @return boolean Success
-- @return string|nil Error message if failed
function M.up(dig, maxAttempts)
    dig = dig or false
    maxAttempts = maxAttempts or 10
    
    for attempt = 1, maxAttempts do
        local success, err = turtle.up()
        if success then
            position.y = position.y + 1
            return true
        end
        
        if turtle.detectUp() then
            if dig then
                turtle.digUp()
                sleep(0.4)  -- Wait for gravel/sand
            else
                return false, "Block above"
            end
        elseif turtle.attackUp() then
            sleep(0.2)
        else
            sleep(0.5)
        end
    end
    return false, "Failed after " .. maxAttempts .. " attempts"
end

--- Safely move down, handling obstacles
-- @param dig boolean Whether to dig obstacles (default: false)
-- @param maxAttempts number Maximum retry attempts (default: 10)
-- @return boolean Success
-- @return string|nil Error message if failed
function M.down(dig, maxAttempts)
    dig = dig or false
    maxAttempts = maxAttempts or 10
    
    for attempt = 1, maxAttempts do
        local success, err = turtle.down()
        if success then
            position.y = position.y - 1
            return true
        end
        
        if turtle.detectDown() then
            if dig then
                turtle.digDown()
                sleep(0.2)
            else
                return false, "Block below"
            end
        elseif turtle.attackDown() then
            sleep(0.2)
        else
            sleep(0.5)
        end
    end
    return false, "Failed after " .. maxAttempts .. " attempts"
end

--- Calculate distance from start position
-- @return number Distance (Manhattan distance)
function M.distanceFromStart()
    return math.abs(position.x) + math.abs(position.y) + math.abs(position.z)
end

--- Navigate to a specific position relative to start
-- @param targetX number Target X coordinate
-- @param targetY number Target Y coordinate
-- @param targetZ number Target Z coordinate
-- @param dig boolean Whether to dig through obstacles
-- @return boolean Success
function M.goTo(targetX, targetY, targetZ, dig)
    -- Move Y first (up/down)
    while position.y < targetY do
        if not M.up(dig) then return false end
    end
    while position.y > targetY do
        if not M.down(dig) then return false end
    end
    
    -- Move X
    if position.x < targetX then
        M.turnTo(1)  -- East
        while position.x < targetX do
            if not M.forward(dig) then return false end
        end
    elseif position.x > targetX then
        M.turnTo(3)  -- West
        while position.x > targetX do
            if not M.forward(dig) then return false end
        end
    end
    
    -- Move Z
    if position.z < targetZ then
        M.turnTo(2)  -- South
        while position.z < targetZ do
            if not M.forward(dig) then return false end
        end
    elseif position.z > targetZ then
        M.turnTo(0)  -- North
        while position.z > targetZ do
            if not M.forward(dig) then return false end
        end
    end
    
    return true
end

--- Return to start position
-- @param dig boolean Whether to dig through obstacles
-- @return boolean Success
function M.goHome(dig)
    return M.goTo(0, 0, 0, dig)
end

return M
