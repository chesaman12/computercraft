-- Dome and sphere builder.
-- Copyright (C) 2012 Timothy Goddard
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
-- the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
-- FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
-- COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
-- IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- usage: sdbuild <type> <radius> [-c]
-- type should be either dome or sphere
-- radius is distance from centre - total width is actually 2 * radius + 1
-- the structure will be built with its lowest point on the level the turtle is at
-- the block the turtle starts on will be the horizontal centre
-- if -c is passed, will only calculate number of blocks required and not build

local arg = { ... }

type = arg[1]
radius = tonumber(arg[2])

cost_only = false
blocks = 0
if arg[3] == "-c" then
  cost_only = true
end

-- Navigation features
-- allow the turtle to move while tracking its position
-- this allows us to just give a destination point and have it go there

positionx = radius
positiony = radius
facing = 0

function turnRightTrack()
  turtle.turnRight()
  facing = facing + 1
  if facing >= 4 then
    facing = 0
  end
end

function turnLeftTrack()
  turtle.turnLeft()
  facing = facing - 1
  if facing < 0 then
    facing = 3
  end
end

function safeForward()
  success = false
  while not success do
    success = turtle.forward()
    if not success then
      print("Blocked attempting to move forward.")
      print("Please clear and press enter to continue.")
      io.read()
    end
  end
end

function safeBack()
  success = false
  while not success do
    success = turtle.back()
    if not success then
      print("Blocked attempting to move back.")
      print("Please clear and press enter to continue.")
      io.read()
    end
  end
end

function safeUp()
  success = false
  while not success do
    success = turtle.up()
    if not success then
      print("Blocked attempting to move up.")
      print("Please clear and press enter to continue.")
      io.read()
    end
  end
end

function moveY(targety)
  if targety == positiony then
    return
  end
  
  if (facing ~= 0 and facing ~= 2) then -- check axis
    turnRightTrack()
  end
  
  while targety > positiony do
    if facing == 0 then
      safeForward()
    else
      safeBack()
    end
    positiony = positiony + 1
  end
  
  while targety < positiony do
    if facing == 2 then
      safeForward()
    else
      safeBack()
    end
    positiony = positiony - 1
  end
end

function moveX(targetx)
  if targetx == positionx then
    return
  end
  
  if (facing ~= 1 and facing ~= 3) then -- check axis
    turnRightTrack()
  end
  
  while targetx > positionx do
    if facing == 1 then
      safeForward()
    else
      safeBack()
    end
    positionx = positionx + 1
  end
  
  while targetx < positionx do
    if facing == 3 then
      safeForward()
    else
      safeBack()
    end
    positionx = positionx - 1
  end
end

function navigateTo(targetx, targety)
  -- Cost calculation mode - don't move
  if cost_only then
    return
  end
  
  if facing == 0 or facing == 2 then -- Y axis
    moveY(targety)
    moveX(targetx)
  else
    moveX(targetx)
    moveY(targety)
  end
end

cslot = 1
function placeBlock()
  -- Cost calculation mode - don't move
  blocks = blocks + 1
  if cost_only then
    return
  end
  
  if turtle.getItemCount(cslot) == 0 then
    foundSlot = false
    while not foundSlot do
      for i = 1,9 do
        if turtle.getItemCount(i) > 0 then
          foundSlot = i
          break
        end
      end
      if not foundSlot then
        -- No resources
        print("Out of building materials. Please refill and press enter to continue.")
        io.read()
      end
    end
    cslot = foundSlot
    turtle.select(foundSlot)
  end
  
  turtle.placeDown()
end

-- Main dome and sphere building routine

width = radius * 2 + 1
sqrt3 = 3 ^ 0.5
boundary_radius = radius + 1.0
boundary2 = boundary_radius ^ 2

if type == "dome" then
  zstart = radius
elseif type == "sphere" then
  zstart = 0
else
  print("Usage: sdbuild <shape> <radius> [-c]")
  os.exit(1)
end
zend = width - 1

-- This loop is for each vertical layer through the sphere or dome.
for z = zstart,zend do
  if not cost_only then
    safeUp()
  end
  print("Layer " .. z)
  cz2 = (radius - z) ^ 2
  
  limit_offset_y = (boundary2 - cz2) ^ 0.5
  max_offset_y = math.ceil(limit_offset_y)
  
  -- We do first the +x side, then the -x side to make movement efficient
  for side = 0,1 do
    -- On the right we go from small y to large y, on the left reversed
    -- This makes us travel clockwise around each layer
    if (side == 0) then
      ystart = radius - max_offset_y
      yend = radius + max_offset_y
      ystep = 1
    else
      ystart = radius + max_offset_y
      yend = radius - max_offset_y
      ystep = -1
    end
    
    for y = ystart,yend,ystep do
      cy2 = (radius - y) ^ 2
      
      remainder2 = (boundary2 - cz2 - cy2)
      
      
      if remainder2 >= 0 then
        -- This is the maximum difference in x from the centre we can be without definitely being outside the radius
        max_offset_x = math.ceil((boundary2 - cz2 - cy2) ^ 0.5)
        
        -- Only do either the +x or -x side
        if (side == 0) then
          -- +x side
          xstart = radius
          xend = radius + max_offset_x
        else
          -- -x side
          xstart = radius - max_offset_x
          xend = radius - 1
        end
        
        -- Reverse direction we traverse xs when in -y side
        if y > radius then
          temp = xstart
          xstart = xend
          xend = temp
          xstep = -1
        else
          xstep = 1
        end
        
        for x = xstart,xend,xstep do
          cx2 = (radius - x) ^ 2
          distance_to_centre = (cx2 + cy2 + cz2) ^ 0.5
          -- Only blocks within the radius but still within 1 3d-diagonal block of the edge are eligible
          if distance_to_centre < boundary_radius and distance_to_centre + sqrt3 >= boundary_radius then
            offsets = {{0, 1, 0}, {0, -1, 0}, {1, 0, 0}, {-1, 0, 0}, {0, 0, 1}, {0, 0, -1}}
            for i=1,6 do
              offset = offsets[i]
              dx = offset[1]
              dy = offset[2]
              dz = offset[3]
              if ((radius - (x + dx)) ^ 2 + (radius - (y + dy)) ^ 2 + (radius - (z + dz)) ^ 2) ^ 0.5 >= boundary_radius then
                -- This is a point to use
                navigateTo(x, y)
                placeBlock()
                break
              end
            end
          end
        end
      end
    end
  end
end

-- Return to where we started in x,y place and turn to face original direction
-- Don't change vertical place though - should be solid under us!
navigateTo(radius, radius)
while (facing > 0) do
  turnLeftTrack()
end

print("Blocks used: " .. blocks)
