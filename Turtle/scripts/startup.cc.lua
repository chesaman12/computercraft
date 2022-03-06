termID = nil
--turtle direction. 0 means not facing that direction
yDirection = 1
xDirection = 0
--turtle relative positioning
curx = 0
cury = -3
curdepth = 0

--send a message to the terminal
local function sendMessage(message)
  if termID ~= -1 then
    rednet.send(termId, message)
  end
end

--[[
these functions cause the turtle to place
an enderchest above and either use fuel in
the enderchest, or dump their cargo into it]]
local function refuel()
  sendMessage("TURREFUEL")
  turtle.select(1)
  turtle.placeUp()
  turtle.suckUp()
  turtle.refuel()
  turtle.dropUp()
  turtle.digUp()
end
local function unload()
  sendMessage("TURUNLOAD")
  turtle.select(2)
  turtle.placeUp()
  for slot=3,16,1 do
    turtle.select(slot)
    while turtle.getItemCount(slot) ~= 0 do
      turtle.dropUp()
    end
  end
  turtle.select(2)
  turtle.digUp()
end

--[[
These are separate functions here 
to keep track of the turtle's current 
direction between turns]]
local function turnRight()
  if xDirection == 0 then
    xDirection = yDirection
    yDirection = 0
  else
    yDirection = -1 * xDirection
    xDirection = 0
  end
  turtle.turnRight()
end
local function turnLeft()
  if xDirection == 0 then
    xDirection = -1 * yDirection
    yDirection = 0
  else
    yDirection = xDirection
    xDirection = 0
  end
  turtle.turnLeft()
end

--[[
these functions incorporate a check for full cargo
and then a call to unload]]
local function digUp()
  if turtle.getItemCount(16) ~= 0 then
    unload()
  end
  return turtle.digUp()
end
local function digDown()
  if turtle.getItemCount(16) ~= 0 then
    unload()
  end
  return turtle.digDown()
end
local function digForward()
  if turtle.getItemCount(16) ~= 0 then
    unload()
  end
  return turtle.dig()
end

--[[
Here, first a check on the fuel level. Too
low and refuel is called. Then, if a block is
in the way, the appropriate dig method is called.
Finally, the turtle is moved, and the relative
position is updated]]
local function moveUp()
  while turtle.getFuelLevel() < 100 do
    refuel()
  end
  if turtle.detectUp() then
    dug = digUp()
    if not dug then
      return false
    end
  end
  moved = false
  while not moved do
    moved = turtle.up()
  end
  curdepth = curdepth - 1
  return true
end
local function moveDown()
  while turtle.getFuelLevel() < 100 do
    refuel()
  end
  if turtle.detectDown() then
    dug = digDown()
    if not dug then
      return false
    end
  end
  moved = false
  while not moved do
    moved = turtle.down()
  end
  curdepth = curdepth + 1
  return true
end
local function moveForward()
  while turtle.getFuelLevel() < 100 do
    refuel()
  end
  if turtle.detect() then
    dug = digForward()
    if not dug then
      return false
    end
  end
  moved = false
  while not moved do
    moved = turtle.forward()
  end
  curx = curx + xDirection
  cury = cury + yDirection
  return true
end

--load the parameters from the file 'params'
paramFile = io.open(disk.getMountPath("bottom") .. "/params")
termID = tonumber(paramFile:read("*l"))
width = tonumber(paramFile:read("*l"))
length = tonumber(paramFile:read("*l"))
startx = tonumber(paramFile:read("*l"))
starty = tonumber(paramFile:read("*l"))
paramFile:close()

--open a connection to the rednet
if termID ~= -1 then
  rednet.open("right")
end

--register with the terminal
sendMessage("TURREG")

--grab the enderchests from the right and left
turtle.select(1)
turnRight()
turtle.suck()
turtle.drop(turtle.getItemCount(1) - 1)
turnLeft()
turtle.select(2)
turnLeft()
turtle.suck()
turtle.drop(turtle.getItemCount(2) - 1)
turnRight()

--move to the start position
moveUp()
while cury ~= starty do
  moveForward()
end
if startx < 0 then
  turnLeft()
  while curx ~= startx do
    moveForward()
  end
  turnRight()
elseif startx > 0 then
  turnRight()
  while curx ~= startx do
    moveForward()
  end
  turnLeft()
end
moveDown()
--tell terminal you are about to start digging
sendMessage("TURSTART")

--man I wish lua had labeled breaks
stillDigging = true
while true do
  --start next level down
  stillDigging = moveDown()
  if not stillDigging then break end

  for col=2,width,1 do
    for row=2,length,1 do
      stillDigging = moveForward()
      if not stillDigging then break end
    end
    if not stillDigging then break end
    if yDirection == 1 then
      turnRight()
      stillDigging = moveForward()
      turnRight()
    else
      turnLeft()
      stillDigging = moveForward()
      turnLeft()
    end
    if not stillDigging then break end
  end
  if not stillDigging then break end

  for row=2,length,1 do
    stillDigging = moveForward()
    if not stillDigging then break end
  end
  if not stillDigging then break end

  --go back to start position
  if yDirection == 1 then --ended at back
    turnRight()
    turnRight()
    for row=2,length,1 do
      moveForward()
    end
  end
  turnRight()
  for col=2,width,1 do
    moveForward()
  end
  turnRight()
end

--tell terminal you are done digging
sendMessage("TURDONE")
--[[
go back home(because of the randomness
about when turtles will finish, I have them
constantly check for other turtles in their
way and wait]]
unload()
while yDirection ~= 1 do
  turnRight()
end
while curdepth ~= 0 do
  moveUp()
end
while turtle.detectUp() do end
moveUp()
if curx < 0 then
  turnRight()
  while curx ~= 0 do
    while turtle.detect() do end
    moveForward()
  end
  turnRight()
else
  turnLeft()
  while curx ~= 0 do
    while turtle.detect() do end
    moveForward()
  end
  turnLeft()
end
while cury ~= -1 do
  while turtle.detect() do end
  moveForward()
end

--do a fancy little dance to return the enderchests
while turtle.detectDown() do end
moveDown()
turnLeft()
while turtle.detect() do end
moveForward()
turnRight()
while turtle.detect() do end
moveForward()
turtle.select(1)
turtle.drop()
--[[
at this point, we can no longer risk 
calling refuel, as we have dropped of
the enderchest, so use the normal
turtle.turn and turtle.move methods]]
turtle.turnRight()
while turtle.detect() do end
turtle.forward()
while turtle.detect() do end
turtle.forward()
turtle.turnLeft()
turtle.select(2)
turtle.drop()
while turtle.detectUp() do end
turtle.up()
while turtle.detect() do end
turtle.forward()
turtle.turnLeft()
while turtle.detect() do end
turtle.forward()
while turtle.detectDown() do end
turtle.down()

if termID ~= -1 then
  rednet.close("right")
end