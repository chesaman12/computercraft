--Designate inventory slots
STONE_SLOT     		= 1
COBBLE_SLOT			= 2
GRAVEL_SLOT 		= 3
DIRT_SLOT 			= 4
SAND_SLOT 			= 5
TORCH_SLOT 			= 6
ENDER_CHEST_SLOT	= 7

INV_COUNT 			= 7						--total number of inventory slots		
FUEL_SLOT 			= 16
TOTAL_SLOTS         = 16                    --number of slots in the turtle

--Set globals
MIN_FUEL_COUNT		= 16 					--minimum number of fuel items
TORCH_SPACE			= 10 					--number of block before placing a torch

--Instantiate random shit
CURRENT_SLOT		= STONE_SLOT            --if the turtle is not facing stone
LAST_SLOT 			= STONE_SLOT            --then you are doing it wrong

DISTANCE 			= 0						--tracks total spaces moved forward
TORCHES_USED		= 0						
FUEL_USED 			= 0						--tracks units of fuel used, not blocks used
LAST_FUEL 			= 0						--previous FUEL_USED
ORE					= 0						--total amount of ore mined
TOTAL_BLOCKS		= 0						--total amount of blocks dug

--Hilbert variablesr
H_REPETITION		= 2						--Hilbert depth
H_SEG_LENGTH		= 3						--Length of Hilbert segment

-- Hilbert function 
function A(depth)  
   if depth < 1 then return end
   turtle.turnLeft()
   B(depth - 1)
   TunnelForward(H_SEG_LENGTH)
   turtle.turnRight()
   A(depth - 1)
   TunnelForward(H_SEG_LENGTH)
   A(depth - 1)
   turtle.turnRight()
   TunnelForward(H_SEG_LENGTH)
   B(depth - 1)
   turtle.turnLeft()
end
 
function B(depth)
 
   if depth < 1 then return end
   turtle.turnRight()
   A(depth - 1)
   TunnelForward(H_SEG_LENGTH)
   turtle.turnLeft()
   B(depth - 1)
   TunnelForward(H_SEG_LENGTH)
   B(depth - 1)
   turtle.turnLeft()
   TunnelForward(H_SEG_LENGTH)
   A(depth - 1)
   turtle.turnRight()
 
end
  
function BlockHandler( here )				
	if Detect(here) then
		if IsOre(here) then	MineOre(here) end
	end
end

function CheckInventory( onInit )
	print("Checking inventory...")	
	local n = 0
	local invThresh = 13						--dump inventory after this many slots are full
	local slotReorg = 14 								--number of slots to reorgainze
	
	for i = INV_COUNT+1, TOTAL_SLOTS - 1 do		--first consolidate fuel items into one slot
		Select(FUEL_SLOT)
		if turtle.compareTo(i) then
			turtle.select(i)
			CURRENT_SLOT = i
			turtle.transferTo(FUEL_SLOT)	
		end
		Select(LAST_SLOT)
	end
	
	for i = 1, slotReorg do
		if turtle.getItemCount(i) > 0 then		--slot used, reorganize, checking for duplicate slots
			n = n + 1
			CheckSlotDupes(i)
		end	
	end
	
	result = n
	
	if n > invThresh then 						--dump inventory into a chest after threshold level
		result = DumpInventory("forward") 
	end
	print("Done")
	return result
end	

function CheckSlotDupes ( index )	--check inventory slots for duplicate items, condense
	local i
	local begin	
	if index < INV_COUNT+1 then begin = INV_COUNT+1 
	else begin = index + 1 end
	Select(index)
	for i = begin, TOTAL_SLOTS - 1 do
		if turtle.compareTo(i) then
			turtle.select(i)
			CURRENT_SLOT = i
			turtle.transferTo(index)
		end 
	end 
	Select(LAST_SLOT)
end
	
function Compare( here )	--compare selected slot to block
	if here == "up" then return turtle.compareUp()
	elseif here == "down" then return turtle.compareDown()
	elseif here == "forward" then return turtle.compare() end return false end
 
function Detect ( here )	--detect if block is air/water/lava or mineable
	if here == "up" then return turtle.detectUp()
	elseif here == "down" then return turtle.detectDown()
	elseif here == "forward" then return turtle.detect() end return false end

function Drop ( thisSlot, thisMany )
	turtle.select(thisSlot)				--if thisMany == nil then everything will be dropped
	turtle.drop(thisMany)
end
	
function DumpInventory( here ) --drops chest and fills it
	local i, g, result
	result = -1
	print("Placing chest...")
	RemoveBlock("forward")
	Place(ENDER_CHEST_SLOT, here)
	for i = INV_COUNT+1, TOTAL_SLOTS - 1 do
		print(i)
		Drop(i, 64)
		sleep(.1)
	end
	Select(LAST_SLOT)
	FuelCheck()
	g = turtle.getItemCount(FUEL_SLOT)		--dump fuel items if we have too many
	if g > MIN_FUEL_COUNT then
		Drop(FUEL_SLOT, g - MIN_FUEL_COUNT)
		Select(LAST_SLOT)
	end
	DigAndMove("forward")
	BlockHandler("forward")
	BlockHandler("up")
	BlockHandler("down")
	Right(BlockHandler, "forward")
	Left(BlockHandler, "forward")
	turtle.back()
	return result
end 

function Dig( here )
	TOTAL_BLOCKS = TOTAL_BLOCKS + 1  --stats
	if here == "up" then return turtle.digUp()
	elseif here == "down" then return turtle.digDown()
	elseif here == "forward" then return turtle.dig() end end

function DigAndMove ( here )
	RemoveBlock(here)
	if here == "forward" then return turtle.forward()
	elseif here == "up" then return turtle.up()
	elseif here == "down" then return turtle.down()
	end 
end	
	
function FuelCheck()					--checks fuel level
	local GC = turtle.getItemCount
	print("Fuel: " .. turtle.getFuelLevel())
	Stats("fuel")
	if turtle.getFuelLevel() < 100 then
		Select(FUEL_SLOT)
		print("Refueling " .. (GC(FUEL_SLOT) - 1) .. " units")
		return turtle.refuel(GC(FUEL_SLOT) - 1) 
	end 
	Select(LAST_SLOT)
end
		
function InitFuel()  					--used on first run
	print("Checking fuel")
	LAST_FUEL = turtle.getFuelLevel()
	return FuelCheck() end
	
function IsFull ( )						--checks to see if inventory is full
	local n, i
	for i = INV_COUNT+1, TOTAL_SLOTS-1 do
		if turtle.getItemCount(i) > 0 then
		else 
			return false 
		end 
	end 
	return true 
end	
	
function IsOre(here)					--cycles through inventory slots and compares to a block
						
	local i
	local result = nil
	if Compare(here) then  				
		if CURRENT_SLOT > INV_COUNT then result = true
		else result = false
		end
	else
		for i = 1, TOTAL_SLOTS - 1 do
			turtle.select(i)
			CURRENT_SLOT = i
			if Compare(here) then
				if i > INV_COUNT then result = true
					break
				else result = false 
					break
				end
			end
		end
	end
	if result == nil then result = true end
	return result
end

function Left( doThis, here )  			--turn left, call a function, turn right	
	local result
	local doIt = doThis	
	turtle.turnLeft()
	result = doIt(here)
	turtle.turnRight()
	return result
end

function MineOre( here )				--remove surrounding vein	
	local m = MineOre						--declaring functions locally is supposed to be 
	local a = 0								--much faster in lua
	local RB = RemoveBlock
	local M = Move
	local R = Right
	local BH = BlockHandler
	local RH = RotateH
	local TS = Select
	local TB = turtle.back
	local P = Place
	local D = turtle.down
	local U = turtle.up
	
	RB(here)						--get ore and move in	
	M(here)
	if here == "forward" then				--send surrounding area to the BlockHandler
		R(BH, "forward")
		BH("up")
		Left(BH, "forward")
		BH("down")
		BH("forward")	
	else 
		RH(BH, "forward")
		BH(here)
	end	

	if here == "forward" then				--covering up our tracks
		TB()
		P(COBBLE_SLOT, here)
	elseif here == "up" then
		D()
		P(COBBLE_SLOT, here)
	elseif here == "down" then
		U()
		P(COBBLE_SLOT, here)
	end
end
 
function Move ( here )
	if here == "up" then return turtle.up()
	elseif here == "forward" then return turtle.forward()
	elseif here == "down" then return turtle.down()
	end 
end

function Place( thisSlot, here )					--places block up, forward or down.  fills in with gravel below
	Select(thisSlot)
	if here == "forward" then return turtle.place()
	elseif here == "down" then 
		local t = turtle.getItemCount(GRAVEL_SLOT) 		
		turtle.placeDown()	
		Select(GRAVEL_SLOT)												
		if not turtle.detectDown() then
			while i < t do
				Place("down")						
				if t == 1 then return true
				else return false
				end
				t = t + 1
			end
		else turtle.placeDown()
		end
	elseif here == "up" then return turtle.placeUp() 
	end
	Select(LAST_SLOT)
	return false 
end
 
function RemoveBlock( here )  			--removes block and any gravel/sand (sand/gravel from above falls down when mined)
	local failsafe = 0	
	if here == "down" then Dig("down")
	else 
		if Dig(here) == true then Select(GRAVEL_SLOT)
			if Compare(here) == true then failsafe = 0
				while Dig(here) and (failsafe < 16) do  --infinite loop protection
					sleep(.5)
					failsafe = failsafe + 1 
				end
			end
			Select(LAST_SLOT)
		end 
	end 
end

function Right ( doThis, here )  		--turn right, call a function, turn left
	 local result
	 local doIt = doThis	
	 turtle.turnRight()
	 result = doIt(here)
	 turtle.turnLeft()
	 return result end 

function RotateH( doThis, here ) 		--rotates and calls a function
	local result
	local doIt = doThis	
	turtle.turnRight()
	doIt(here)
	turtle.turnRight()
	doIt(here)
	turtle.turnRight()
	doIt(here)
	turtle.turnRight()
	doIt(here) end 

function Stats ( this, that )			--prints various stats
	FUEL_USED = FUEL_USED + LAST_FUEL - turtle.getFuelLevel()
	LAST_FUEL = turtle.getFuelLevel()
	if this == "distance" then
		DISTANCE = DISTANCE + 1
		if DISTANCE % 5 == 0 then	
			print(DISTANCE .. "m tunneled.")
			print(((TOTAL_BLOCKS + ORE) / DISTANCE) .. " blocks mined per tunnel section.")
			print((FUEL_USED/(TOTAL_BLOCKS + ORE)).. " fuel per block.")return true
		end
	elseif this == "torch" then TORCHES_USED = TORCHES_USED + 1
		return true
	elseif this == "fuel" then FUEL_USED = FUEL_USED + (LAST_FUEL - turtle.getFuelLevel())
		print(FUEL_USED .. " total fuel used.")
		print((FUEL_USED / DISTANCE) .. " fuel per m.")
		print((FUEL_USED / ORE) .. " fuel per extra ore.")
		print((turtle.getFuelLevel() /(FUEL_USED/DISTANCE)) .. "m's of fuel left.")
		return true
	elseif this == "ore" then ORE = ORE + 1
		print(ORE .. " extra ore mined.") 
		print((FUEL_USED / ORE) .. " per ore.") return true
	elseif this == "fuelchunks" then end return false end	

function Select ( slot )
	LAST_SLOT = CURRENT_SLOT
	turtle.select(slot)
	CURRENT_SLOT = slot
end
	
function TorchCheck()					--checks to see if torch needs to be placed
	local BH = BlockHandler
	if (DISTANCE % TORCH_SPACE) == 0 and turtle.getItemCount(TORCH_SLOT) > 0 then
		Stats("torch")	
		RemoveBlock("forward")
		turtle.forward()
		if turtle.detect() then BH("forward")
		else Place(COBBLE_SLOT, "forward")
		end
		if turtle.detectDown() then BH("down")
		else Place(COBBLE_SLOT, "down")
		end
		turtle.back()
		Place(TORCH_SLOT, "forward")
	end 
end 

function TunnelForward( thisFar )		--mine a 1x2 tunnel forward a given number of units
	local i
	for i = 1, thisFar do  					  
		if IsFull() then CheckInventory() end
		FuelCheck()
											--Coords		 Facing
		--turtle.now						-- 0,0,0			N								
		DigAndMove("forward")				-- 0,1,0			N
			BlockHandler("down")
			if not Detect("down") then Place(COBBLE_SLOT, "down") end
		turtle.turnLeft()					-- 0,1,0			W
			BlockHandler("forward")
			if not Detect("forward") then Place(COBBLE_SLOT, "forward") end
		DigAndMove("up")					-- 0,1,1			W
			BlockHandler("up")
			if not Detect("up") then Place(COBBLE_SLOT, "up") end
			BlockHandler("forward")
			if not Detect("forward") then Place(COBBLE_SLOT, "forward") end
		turtle.turnRight()					-- 0,1,1			N
		turtle.turnRight()					-- 0,1,1			E
			BlockHandler("forward")
			if not Detect("forward") then Place(COBBLE_SLOT, "forward") end
		turtle.down()						-- 0,1,0			E
			BlockHandler("forward")
			if not Detect("forward") then Place(COBBLE_SLOT, "forward") end
			TorchCheck()
		turtle.turnLeft()					-- 0,1,0			N
		Stats("distance")					--add one to distance travelled and display stats
	end
end

function main()
	InitFuel()
	local AA = A
	for i=1, H_REPETITION do
	AA(H_REPETITION) end
end

main()