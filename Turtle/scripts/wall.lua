write("width: ")
width = read()
write("length: ")
length = read()
write("height: ")
height = read()

slot = 1

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
	-- check our slot - if it is empty, use the next one to avoid using one that we move forward over
	checkAndFillSlot()

	--Digs until the turtle can move forward, to deal with gravel and sand.
	repeat
		turtle.dig()
	until turtle.forward() == true
end

function checkAndPlace()
	if not turtle.compareDown() then
		turtle.digDown()
	end		
	turtle.placeDown()
end

function makeWall(distance)
	for j=1,distance do
		checkAndFillSlot()

		checkAndPlace()
		
		forwardAndDig()
	end
end

-- place the first block where we start at
checkAndPlace()

for i=1,height do
	makeWall(width-1)
	turtle.turnRight()
	makeWall(length-1)
	turtle.turnRight()
	makeWall(width-1)
	turtle.turnRight()
	makeWall(length-1)
	turtle.turnRight()

	turtle.up()
end

os.reboot()