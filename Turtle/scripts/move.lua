write("direction (f,b,l,r,u,d): ")
direction = read()
write("distance: ")
distance = read()

if direction == "f" then
  for i=1,distance do
    turtle.forward()
  end
elseif direction == "b" then
  for i=1,distance do
    turtle.back()
  end
elseif direction == "u" then
  for i=1,distance do
    turtle.up()
  end
elseif direction == "d" then
  for i=1,distance do
    turtle.down()
  end
elseif direction == "l" then
  for i=1,distance do
    turtle.turnLeft()
  end
elseif direction == "r" then
  for i=1,distance do
    turtle.turnRight()
  end  
end

os.reboot()
