local MIN_FUEL_LEVEL = 1650;

write("Dig up or down (u, d): ")
local direction = read():lower()
write("Dig to the left or right (l, r): ")
local turn = read():lower()
write("length: ")
local length = tonumber(read())
write("width: ")
local width = tonumber(read())
write("depth/height: ")
local depth = tonumber(read())

function main()
	normalizeUserInput()
	digLoop()
	positionBackToStart()
	os.reboot()
end

function normalizeUserInput()
	if turn == "l" or turn == "left" then
		turn = "left"
	elseif turn == "r" or turn == "right" then
		turn = "right"
	end
	
	if direction == "u" or direction == "up" then
		direction = "up"
	elseif direction == "d" or direction == "down" then
		direction = "down"
	end
end

function digLoop()
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
		verifyFuelLevel()
		
		if direction == "up" then
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
end

function positionBackToStart()
	for i=1,depth do
		if direction == "up" then
			turtle.down()
		else
			turtle.up()
		end
	end
end

-- util functions

function forwardAndDig()
	--Digs until the turtle can move forward, to deal with gravel and sand.
	repeat
		turtle.dig()
	until turtle.forward() == true
end

function digUpOrDown()
	verifyFuelLevel()
	if direction == "up" then
		turtle.digUp()
	else
		turtle.digDown()
	end
end

function adjustOrientation()
	verifyFuelLevel()
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

function verifyFuelLevel()
	local fuelLevel = turtle.getFuelLevel();

	if fuelLevel <= MIN_FUEL_LEVEL then
		write("Fuel level low. Insert fuel & press enter to continue.\n")
		read()
		shell.run("refuel", "all")
		write("New fuel level: " .. turtle.getFuelLevel() .. "\n")
	end
end

main()