--version 1.0.3 - Added "would you like to refuel" feature 
--Created by Kolacats-- --place Blocks in the 1st slot to the 14th slot
--fuel 15th slot but really can go anywhere, and a door in the 16th slot
print("Created by Kolacats. (C) 2013 all rights reserved") --prints all the important information
print("License information: http://www.gnu.org/licenses/gpl.txt") --link to my licence
local fstart = turtle.getFuelLevel() --Gets the fuel level at start
function fuel() --This creates a function called Fuel
  for i=1,16 do
    turtle.select(i)
    turtle.refuel()
  end
end
print("Would you like to refuel (yes or no)[REMEMBER A WOOD IS FUEL!]: ")-- wood is a fuel
refuel = read()
if(refuel == "yes") then
  print("refuelling...") --says that its refuelling
  fuel()
end
write("what do you want the length and width to be: ") 
lw = read() --User sets the value of lw
oe = lw -- this sets the lw value to oe
lw = lw - 1 --takes away 1 from the value lw or does not work properly.
write("How high do you want it to be: ")
h = read() --User sets the value of h which mean hight.
local fend = turtle.getFuelLevel() --Gets the fuel level at end
amountrefueled = fend - fstart -- takes the fuel at the end from the start.
print("refueled: "..amountrefueled) --says how much it has refuelled
print("New fuel level: "..turtle.getFuelLevel()) --says how much fuel it has
n = 1 --sets n to 1
function item() --creates function called item
  if turtle.getItemCount(n) < 1 then --sees if the items in the "n" slot is less then 1
    n = n + 1 --if it was then adds 1 to n
    turtle.select(n) --selects the next slot 
  end
end
r = 0 --sets r to 0
function window()
  print("Building Windows")
end
function roof() --creates a function called roof
  item() 
  for i=1,lw do --a loop which sets the value of i to 1-lw
    wall()
    if(r < 1) then --sees if r is less then 1
      turtle.turnRight() --if successful it does this code
      turtle.forward()
      turtle.turnRight()
      r = r + 1 --adds 1 to r
      else 
      turtle.turnLeft() --if r was 1 or more does this code
      turtle.forward()
      turtle.turnLeft()
      r = 0 --sets r to 0
    end
  end
end
function floor() --creates a function called floor
  item()
  for i=1,lw do --a loop which sets the value of i to 1-lw
    floorWall()
    if(r < 1) then --sees if r is less than 1
      turtle.turnLeft() --if success then does this code
      turtle.forward()
      turtle.turnLeft()
      r = r + 1 --adds 1 to r
      else 
      turtle.turnRight() --if r was 1 or more then does this code
      turtle.forward()
      turtle.turnRight()
      r = 0 --sets r to 0
    end
  end
end
function floorWall() --creates a function called floorwall
  for i=1,lw do --a loop which sets i to the value 1 - lw
    turtle.digDown() 
    turtle.placeDown()
    turtle.forward()
    item()
  end
end
function wall() --makes a function called wall
  for i=1,lw do --a loop which sets i to the value 1 - lw
    turtle.forward()
    turtle.placeDown()
    item()
  end
end
function walls()
  if(oe % 2) == 0 then
    turtle.up()
    wall()
    turtle.turnLeft()
    wall()
    turtle.turnLeft()
    wall()
    turtle.turnLeft()
    wall()
    turtle.turnLeft()
    else
    turtle.up()
    wall()
    turtle.turnRight()
    wall()
    turtle.turnRight()
    wall()
    turtle.turnRight()
    wall()
    turtle.turnRight()
  end  
end
function door() --makes a function called door
  lw = lw / 2 --divides lw by 2
  turtle.turnLeft()
  for i=1,lw do --a loop that sets the value of i to 1 - lw
    turtle.forward()
  end
  turtle.turnRight()
  turtle.dig()
  turtle.up()
  turtle.dig()
  turtle.down()
  turtle.select(16)
  turtle.place()
end
turtle.select(1) --selects slot 1
floor()
for i=1,h do --a loop which sets the value of i to 1 - h
  walls()
end
roof()
turtle.back()
for i=1,h do --a loop which sets the value of i to 1 - h
  turtle.down()
end
door()
turtle.turnRight()
for i=1,lw do
  turtle.forward()
end
turtle.turnLeft()
print("Finished house") --prints "Finished house"