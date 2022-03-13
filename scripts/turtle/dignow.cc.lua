print "Enderchest in slot 1,Torches in slot 15 (optional), Fuel in slot 16 (optional, allows turtle to eat found fuel as a last resort)."
print "How far is this mine?(x)"
local xSize = tonumber(io.read())
print "How high? (y)"
local ySize = tonumber(io.read())
print "How wide (to the left)? (z) (even numbers are more efficient)"
local zSize = tonumber(io.read())

while turtle.getItemCount(1) < 1 do
  print "Please put an ENDER CHEST in slot 1. Hit any key when done."
  os.pullEvent("char")
end



-- 0 = South, 1 = West, 2 = North, 3 = East
-- These are relative values, not necessarily the minecraft facing dir (which you need wireless for)
-- If the player isn't actually facing south, x and z will be inverted or reversed. That's OK.
local iDirection = 0

local xMovedFromOrigin = 0
local yMovedFromOrigin = 0
local zMovedFromOrigin = 0

local bHasTorches = turtle.getItemCount(15) > 0
local bHasFuel = turtle.getItemCount(16) > 0

function CheckFuel()
  if(bHasFuel == false) then
    return true
  end
  
  if turtle.getFuelLevel() <= 10 then
    turtle.select(16)
    turtle.refuel(1)
    if turtle.getFuelLevel() <= 10 then
      -- phase 2: low fuel, fueling failed, return home
    end
  end
  
  if turtle.getFuelLevel() <= 1 then
    print "OOF: Out Of Fuel :("
    print "I'm going to eat your coal"
    shell.run("refuel", "all")
    if turtle.getFuelLevel() <= 1 then
      print "I am STILL out of fuel...turtle starving..."
      print "going...dark..."
      print "...so...cold...sleepy..."
      turtle.sleep(120)
      return false
    end
  end

  return true  
end

function MoveForward()
  CheckFuel()

  if(turtle.forward()) then
    if iDirection == 0 then
      zMovedFromOrigin = zMovedFromOrigin + 1
    elseif iDirection == 1 then
      xMovedFromOrigin = xMovedFromOrigin - 1
    elseif iDirection == 2 then
      zMovedFromOrigin = zMovedFromOrigin - 1
    elseif iDirection == 3 then
      xMovedFromOrigin = xMovedFromOrigin + 1
    end
    return true
  else
    return false
  end
end

function TurnLeft()
  iDirection = iDirection - 1
  if(iDirection < 0) then
    iDirection = 3
  end
  turtle.turnLeft()
end

function TurnRight()
  iDirection = iDirection + 1
  if(iDirection > 3) then
    iDirection = 0
  end
  turtle.turnRight()
end

function MoveUp()
  CheckFuel()
  if(turtle.up()) then
    yMovedFromOrigin = yMovedFromOrigin + 1
    return true
  end
  return false
end

function MoveDown()
  CheckFuel()
  if(turtle.down()) then
    yMovedFromOrigin = yMovedFromOrigin - 1
    return true
  end
  return false
end

function PlaceTorch()
  if(bHasTorches == false) then
    return
  end

  if turtle.getItemCount(15) >= 1 then

  local iSaveDirection = iDirection
  while(iDirection ~= 2) do
    TurnRight()
  end
  
    turtle.select(15)
    turtle.place()

  while(iDirection ~= iSaveDirection) do
    TurnLeft()
  end

  end
end

function DigUp(iBlocks)
  if(iBlocks < 1) then
    return
  end
  for y = 1, iBlocks - 1 do
    while(MoveUp() == false) do
      turtle.digUp()
      turtle.suckUp() 
    end -- end while
  end -- end up/down
end

function DigDown(iBlocks)
  if(iBlocks < 1) then
    return
  end
  for y = 1, iBlocks - 1 do
    while(MoveDown() == false) do
      turtle.digDown()
      turtle.suckDown() 
    end -- end while
  end -- end up/down
end

function DigForward()
  while(MoveForward() == false) do
    turtle.dig()
    turtle.suck()
  end
end


function GoHome()
  
  DigDown(yMovedFromOrigin)
  
  if iDirection == 0 then
    TurnRight()
    TurnRight()
  elseif iDirection == 1 then
    TurnRight()
  elseif iDirection == 3 then
    TurnLeft()
  end
  
  for i = 1, zMovedFromOrigin do
    DigForward()
  end
  TurnLeft()

  for i = 1, xMovedFromOrigin do
    DigForward()
  end
  
end

function DumpInventoryToSlot1()
  while turtle.detectUp() do
    turtle.digUp()
  end
  turtle.select(1)
  while turtle.placeUp() == false do
    turtle.digUp()
  end
  
  local iLastInventorySlot = 16
  if(bHasTorches) then
    iLastInventorySlot = 14
  elseif(bHasFuel) then
    iLastInventorySlot = 15
  end
  
  for i = 2, iLastInventorySlot do
    turtle.select(i)
    turtle.dropUp()
  end
  turtle.select(1)
  turtle.digUp()
end




function Main()
  print("Mining " .. xSize .. ", " .. ySize .. ", " .. zSize)
  
  TurnLeft()
  local zMax = math.floor(zSize / 2)
  
  for x = 1, xSize do

    for z = 1, zMax do
      DigUp(ySize)
      DigForward()
      DigDown(ySize)

      if z < zMax then
        DigForward()
      end
      -- if we filled up almost all of the inventory (1 is ender chest so 2-10), dump inventory to chest
      if turtle.getItemCount(10) >= 1 then
        print("~" .. (x / xSize * 100) .. "% complete, " .. turtle.getFuelLevel()  .. " fuel remaining.")
        DumpInventoryToSlot1()
      end
    end -- end z axis

    -- if the face size wasn't even, we still have a single column to clear
    if(zSize % 2 ~= 0) then
      -- print("adjusting for odd face size")
      DigForward()
      DigUp(ySize)
      DigDown(ySize)
    end

    -- if we need to change the orientation of the cleared area, change right to left here
    if(x % 2 ~= 0) then
      TurnRight()
      DigForward()
      TurnRight()
    else
      TurnLeft()
      DigForward()
      TurnLeft()
    end

    if(x % 8 == 7) then
      PlaceTorch()
    end

  end -- end x axis
  
  print "Returning home now!"

  GoHome()
  DumpInventoryToSlot1()
end



Main() -- !