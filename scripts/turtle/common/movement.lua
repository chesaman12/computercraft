--- Movement utilities for turtles
-- @module movement

local M = {}

--- Maximum dig attempts before giving up on unbreakable block
M.MAX_DIG_ATTEMPTS = 10

--- Move forward, digging any blocks in the way (handles gravel/sand)
-- @return boolean True if movement succeeded
function M.forwardAndDig()
    local attempts = 0
    repeat
        turtle.dig()
        turtle.suck()
        attempts = attempts + 1
        if attempts > M.MAX_DIG_ATTEMPTS then
            return false
        end
    until turtle.forward()
    return true
end

--- Move forward safely, digging and retrying
-- @return boolean True if movement succeeded
function M.moveForwardSafe()
    local attempts = 0
    while not turtle.forward() do
        if turtle.detect() then
            turtle.dig()
            turtle.suck()
        else
            sleep(0.2)
        end
        attempts = attempts + 1
        if attempts > M.MAX_DIG_ATTEMPTS then
            return false
        end
    end
    return true
end

--- Move forward digging a 1x2 tunnel (ahead and up)
-- @return boolean True if movement succeeded
function M.moveForward1x2()
    local attempts = 0
    
    -- Dig ahead
    while turtle.detect() do
        turtle.dig()
        turtle.suck()
        sleep(0.2)
        attempts = attempts + 1
        if attempts > M.MAX_DIG_ATTEMPTS then
            return false
        end
    end

    -- Dig up
    attempts = 0
    while turtle.detectUp() do
        turtle.digUp()
        turtle.suckUp()
        sleep(0.2)
        attempts = attempts + 1
        if attempts > M.MAX_DIG_ATTEMPTS then
            return false
        end
    end

    -- Move forward
    attempts = 0
    while not turtle.forward() do
        if turtle.detect() then
            turtle.dig()
            turtle.suck()
        else
            sleep(0.2)
        end
        attempts = attempts + 1
        if attempts > M.MAX_DIG_ATTEMPTS then
            return false
        end
    end

    return true
end

--- Dig until no block is detected (handles falling blocks)
function M.digUntilEmpty()
    while turtle.detect() do 
        turtle.dig()
        sleep(0.1)
    end
end

--- Move in a direction for a given distance
-- @param direction string Direction: f(orward), b(ack), u(p), d(own), l(eft), r(ight)
-- @param distance number Number of moves/turns
-- @return boolean True if all movements succeeded
function M.move(direction, distance)
    distance = distance or 1
    local d = direction:lower():sub(1, 1)
    
    for i = 1, distance do
        local success
        if d == "f" then
            success = turtle.forward()
        elseif d == "b" then
            success = turtle.back()
        elseif d == "u" then
            success = turtle.up()
        elseif d == "d" then
            success = turtle.down()
        elseif d == "l" then
            turtle.turnLeft()
            success = true
        elseif d == "r" then
            turtle.turnRight()
            success = true
        end
        
        if not success then
            return false
        end
    end
    return true
end

return M
