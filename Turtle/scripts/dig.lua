write("dig up or down? (R to L) u,d: ")
direction = read()
write("length: ")
length = tonumber(read())
write("width: ")
width = tonumber(read())
write("depth/height: ")
depth = tonumber(read())

turn = "left"

function forwardAndDig()
	--Digs until the turtle can move forward, to deal with gravel and sand.
	repeat
		turtle.dig()
	until turtle.forward() == true
end

function digUpOrDown()
	if direction == "u" then
		turtle.digUp()
	else
		turtle.digDown()
	end
end

function adjustOrientation()
	if turn == "left" then
		turtle.turnLeft()
		forwardAndDig()
		turtle.turnLeft()
		
		turn = "right"
	else
		turtle.turnRight()
		forwardAndDig()
		turtle.turnRight()		
		turn = "left"
	end
end

for i=1,depth do
	for j=1,length do
		for k=1,width-1 do
			digUpOrDown()
			forwardAndDig()
		end
		
		digUpOrDown()
		
		if j ~= length then
			adjustOrientation()			
		end
		
	end
	
	if direction == "u" then
		turtle.up()
	else
		turtle.down()
	end	
	
	if turn == "left" then
		turtle.turnLeft()
		turtle.turnLeft()
	else
		turtle.turnRight()
		turtle.turnRight()		
	end
end

os.reboot()