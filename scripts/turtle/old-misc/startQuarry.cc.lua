modemSide = nil
monitorSide = nil
monitorType = 0

local function cleanUp()
  if monitorSide then
    term.restore()
  end
  if modemSide then
    rednet.close(modemSide)
  end
end
local function error(message)
  if term.isColor() then
    term.setTextColor(colors.red)
  end
  print("ERROR: " .. message)
  if term.isColor() then
    term.setTextColor(colors.white)
  end
  cleanUp()
end
local function printColor(message, color)
  if term.isColor() then
    term.setTextColor(color)
  end
  print(message)
  if term.isColor() then
    term.setTextColor(colors.white)
  end
end
local function print_usage()
  print("Usage: startQuarry [num_turtles [quarry_width quarry_length]")
  cleanUp()
end

local argv = {...}
local numTurtles = 2
local width = 16
local length = 16
if #argv >= 1 then
  numTurtles = tonumber(argv[1])
end
if #argv == 3 then
  width = tonumber(argv[2])
  length = tonumber(argv[3])
end
if #argv == 2 or #argv > 3 then
  print_usage()
  return
end

for x,side in pairs(redstone.getSides()) do
  if peripheral.getType(side) == "modem" then
    modemSide = side
  elseif peripheral.getType(side) == "monitor" then
    monitorSide = side
  end
end

if not monitorSide then
  print("No monitor connected")
  print("will use computer for output")
else
  term.redirect(peripheral.wrap(monitorSide))
  term.clear()
  term.setCursorPos(1,1)
  if term.isColor() then
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
  end
end

if not modemSide then
  error("no modem connected")
  return
end
rednet.open(modemSide)

print("Looking for a master turtle")
rednet.broadcast("QUARRYINIT")
turtleID, message = rednet.receive(5)
if not turtleID then
  error("failed to detect a turtle")
  return
end
while message ~= "QUARRYREPLY" do
  turleID, message = rednet.receive(5)
  if not turtleID then
    error("failed to detect a turtle")
    return
  end
end

printColor("turtle detected, quarry starting", colors.lime)
rednet.send(turtleID, tostring(numTurtles))
rednet.send(turtleID, tostring(width))
rednet.send(turtleID, tostring(length))

turtleID = {}
nextTurtleID = 1
while true do
  id, message = rednet.receive()
  if message == "ERRNOTUR" then
    error("not enough turtles")
    return
  elseif message == "QUARRYDONE" then
    break
  elseif message == "TURREG" then
    turtleID[id] = nextTurtleID
    nextTurtleID = nextTurtleID + 1
    printColor("Turtle " .. turtleID[id] .. " starting up", colors.yellow)
  elseif message == "TURREFUEL" then
    printColor("Turtle " .. turtleID[id] .. " refuelling", colors.yellow)
  elseif message == "TURUNLOAD" then
    printColor("Turtle " .. turtleID[id] .. " unloading cargo", colors.yellow)
  elseif message == "TURSTART" then
    printColor("Turtle " .. turtleID[id] .. " starting to dig", colors.purple)
  elseif message == "TURDONE" then
    printColor("Turtle " .. turtleID[id] .. " done digging", colors.purple)
  end
end

term.clear()
term.setCursorPos(1,1)
printColor("Quarry complete", colors.lime)
cleanUp()
