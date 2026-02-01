write("length: ")
length = tonumber(read())
write("width: ")
width = tonumber(read())
write("height: ")
height = tonumber(read())
write("direction (l, r): ")
local turn = read():lower()

slot = 1

function normalizeUserInput()
	if turn == "l" or turn == "left" then
		turn = "left"
	elseif turn == "r" or turn == "right" then
		turn = "right"
	end
end

-- make sure we have enough to place
function checkAndFillSlot()
	while turtle.getItemCount(slot) == 0 do
		slot = slot + 1
		if slot > 16 then
			slot = 1
		end
		
		turtle.select(slot)
	end
end

function forwardAndDig()
	checkAndFillSlot()

	--Digs until the turtle can move forward, to deal with gravel and sand.
	repeat
		turtle.dig()
	until turtle.forward() == true
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

function digAndPlace()
	if not turtle.compareDown() then
		turtle.digDown()
	end		

	turtle.placeDown()
end

function main()
	normalizeUserInput()

	for i=1,height do
		for j=1,length do
			for k=1,width-1 do
				digAndPlace()
				
				forwardAndDig()
			end
			
			digAndPlace()
			
			if j ~= length then
				adjustOrientation()			
			end
			
		end
		
		turtle.up()
		
		if turn == "left" then
			turtle.turnLeft()
			turtle.turnLeft()
		else
			turtle.turnRight()
			turtle.turnRight()		
		end
	end
	
	os.reboot()
end

main()
