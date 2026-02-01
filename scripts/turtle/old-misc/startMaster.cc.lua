termID = nil

local function startTurtle(width, length, startx, starty)
  while turtle.detect() do
  end

  --if the turtle needs fuel, get it
  if turtle.getFuelLevel() < 100 and turtle.getItemCount(2) > 0 then
    turtle.select(2)
    turtle.placeUp()
    turtle.suckUp()
    turtle.refuel()
    turtle.digUp()
    turtle.select(1)
  end

  turtle.forward()
  paramsFile = io.open(disk.getMountPath("bottom") .. "/params", "w")
  if termID == nil then
    paramsFile:write("-1\n")
  else
    paramsFile:write(termID .. "\n")
  end
  paramsFile:write(width .. "\n" .. length .. "\n" .. startx .. "\n" .. starty)
  paramsFile:close()
  turtle.back()
    
  turtle.select(1)
  if turtle.getItemCount(1) == 0 then
    turtle.turnRight()
    turtle.turnRight()
    turtle.suck()
    turtle.turnLeft()
    turtle.turnLeft()
    if turtle.getItemCount(1) == 0 then
      if termID ~= nil then
        rednet.send(termID, "ERRNOTUR")
      else
        print("ERROR: not enough turtles")
      end
      return false
    end
  end
  turtle.place()
  peripheral.call("front", "turnOn")
  return true
end

local function distributeTurtles(numTurtles, width, length, startx, starty)
  if numTurtles == 1 then
    return startTurtle(width, length, startx, starty)
  else
    if width < length then
      firstGood = distributeTurtles(math.floor(numTurtles/2), width, math.floor(length/2), startx, starty)
      secondGood = distributeTurtles(math.ceil(numTurtles/2), width, math.ceil(length/2), startx, starty + math.floor(length/2))
      return firstGood or secondGood
    else
      firstGood = distributeTurtles(math.floor(numTurtles/2), math.floor(width/2), length, startx, starty)
      secondGood = distributeTurtles(math.ceil(numTurtles/2), math.ceil(width/2), length, startx + math.floor(width/2), starty)
      return firstGood or secondGood
    end
  end
end

local argv = { ... }
if #argv > 3 or #argv == 2 then
  print("Usage: startMaster [num_turtles [quarry_width quarry_length]]")
  return
end

numTurtles = 2
width = 16
length = 16
if #argv == 0 then
  rednet.open("right")
  termID,message = rednet.receive()
  while message ~= "QUARRYINIT" do
    termID,message = rednet.receive()
  end
  rednet.send(termID, "QUARRYREPLY")
  id, numTurtles = rednet.receive()
  id, width = rednet.receive()
  id, length = rednet.receive()
elseif #argv == 1 then
  numTurtles = argv[1]
else
  numTurtles = argv[1]
  width = argv[2]
  length = argv[3]
end

turtlesOut = distributeTurtles(tonumber(numTurtles), tonumber(width), tonumber(length), math.ceil(-1/2*tonumber(width)), 0)
if not turtlesOut then
  return
end

if turtle.getItemCount(1) > 0 then
  turtle.turnRight()
  turtle.turnRight()
  turtle.drop()
  turtle.turnLeft()
  turtle.turnLeft()
end

--wait for last turtle
while turtle.detect() do end

for i=1,tonumber(numTurtles),1 do
  while not turtle.detect() do end
  turtle.dig()
  turtle.turnRight()
  turtle.turnRight()
  turtle.drop()
  turtle.turnLeft()
  turtle.turnLeft()
end

if termID ~= nil then     --run through terminal
  rednet.send(termID, "QUARRYDONE")
  rednet.close("right")
end