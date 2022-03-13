function back(x)
  for i=1,x do
    turtle.back()
  end
end

function down(x)
  for i=1,x do
    turtle.down()
  end
end

function forwardAndDig()
	--Digs until the turtle can move forward, to deal with gravel and sand.
	repeat
		turtle.dig()
	until turtle.forward() == true
end

write("width: ")
width = read()
write("height: ")
height = read()
write("length: ")
length = read()

slot = 1

for i=1,width do
	for j=1,height do
	  for k=1,length do
		-- make sure we have enough to place
		if turtle.getItemCount(slot) == 0 then
		  slot = slot + 1
		  turtle.select(slot)
		end

		if not turtle.compareDown() then
		  turtle.digDown()
		end		
		
		turtle.placeDown()
		forwardAndDig()
	  end
	  turtle.up()
	  back(length)
	end
	
	turtle.turnLeft()
	forwardAndDig()
	turtle.turnRight() 
	down(height)
end

os.reboot()