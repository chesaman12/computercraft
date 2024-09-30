dofile("./basicTurtleCommands.lua")

-- Function to dig tunnel in front of the turtle
-- That is 2 blocks high and 1 block wide
-- And has a depth of X blocks
-- Function to dig a tunnel 2 blocks high, 1 block wide, and X blocks deep
function digTunnel(depth, returnToStart)
    for i = 1, depth do
        -- Dig forward
        digBlock()
        moveForward()
        
        -- Dig block above
        digBlockAbove()
        
        -- Place torch every 6 blocks
        if i % 5 == 0 then
            placeTorchOnLeftWall()
        end
    end
    
    -- Return to the start of the tunnel
    if returnToStart then
        for i = 1, depth do
            moveBackward()
        end
    end
end

-- Function to place a torch on the left wall
-- The turtle will turn left, move up, place a torch, move down, and turn right
function placeTorchOnLeftWall()
    selectItem("minecraft:torch")
    turnLeft()
    placeBlockAbove()
    turnRight()
end
