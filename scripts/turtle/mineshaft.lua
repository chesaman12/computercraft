turncheck = 0
movecheck = 0
count = 0
write("Width : ")
width = read()
widthmax = tonumber(width)
write("Length : ")
length = read()
lengthmax = tonumber(length)
write("Height : ")
height = read()
heightmax = tonumber(height)
total = width * length * height

-- Created by Maarten Bobbeldijk AKA : Maarten580. This is a beta version, I will try to continue on this API, so you can have more input.
keys = {["left"] = 203, ["right"] = 205, ["up"] = 200, ["down"] = 208, ["enter"] = 28, ["space"] = 57} -- This set the key number from keys in an array, just to make it more simple for me.
position = {["height"] = 1, ["width"] = 1} -- Position array
text = {} -- This makes the array
options = {} -- This makes the array
answers = {} -- This makes the array, here will be the answers be saved in
text[1] = "Mine vertical or horizontal?" -- This API use an array to collect the informatie, to make it easier for the user. Never start with text[0] or options[0] because LUA doesn't count it and it will brake this API.
options[1] = "vertical|horizontal|" -- Here can you enter the options the user can choose from, always end an option with a "|", so the compiler can recognize the option.
text[2] = "Auto-build enabled?"  -- to make the next option, you just need to use the next number then the previous, for example : you did made the first question called "text[1]", you simple do "text[2]". You need to use the numeric sequence otherwise you will break this API.
options[2] = "Yes|No|" -- ETC
answers[2] = 2 -- You can also recommend an answer by select insert the answer, ofcourse the user can still change the answer.
text[3] = "" -- To continue to your program, you need to make a new "question". This program will always use the last "question" to continue, whatever the text included.
options[3] = "Leave and send|" -- This is the message what the user let's know where to leave, again DON'T forgot the "|", because this compiled as an 
error = "" -- reserve for a veriable, if incase there is an error.

function positionCorrection() -- If the position goes outside the range, it will continue on the other side for example : position["width"] == 4 and there is no option 4, then it will go to option 1 and if position["width"] < 1 then it will go in this case to option number 3.
	local height = table.getn(text)
	local width = 0
	if position["height"] < 1 then position["height"] = height elseif position["height"] > height then position["height"] = 1 end
	for i=1, string.len(options[position["height"]]), 1 do
		if string.sub(options[position["height"]], i, i) == "|" then
			width = width+1
		end
	end
	if position["width"] < 1 then position["width"] = width elseif position["width"] > width then position["width"] = 1 end
end

function controller() -- This show the text and let's see what option is selected and answered.
	term.clear()
	if error ~=  "" then
		print(error.."\n")
	end
	
	for i=1, table.getn(text), 1 do
		if position["height"] == i then write("> ") end
		write(text[i] .. "\n   ")
		local optioncheck = 0
		local test = 0
		local optionamount = 1
		while string.sub(options[i], optioncheck, (optioncheck+1)) ~= "" do
			if string.sub(options[i], optioncheck, optioncheck) == "|" then
				if answers[i] == optionamount then
					write("(") -- If the option is between "([option])" then it means that the option is answered.
				end
				
				if optionamount == position["width"] and i == position["height"] then
					write("-"..string.sub(options[i], test, (optioncheck-1)).."-") -- If the option is between "-[option]-" then it means it's selected.
				else
					write(string.sub(options[i], test, (optioncheck-1)))
				end
				
				if answers[i] == optionamount then
					write(")")
				end
				
				if optioncheck ~= string.len(options[i]) then
					write("|")
				end
				
				test = optioncheck +1
				optionamount = optionamount + 1
			end
			optioncheck = optioncheck +1
		end
		print("")
	end
end

function complete() -- Checks if every question is answered, so yes, it will continue to the program.
	local check = 0
	for a=1, table.getn(text), 1 do
		if answers[a] ~= nil then check= check +1 end
	end
	if check == (table.getn(text)-1) then
		return true
	else
		error = "You don't have answered all questions!"
		return false
	end
end

controller()
whilecheck = 1
while true do -- Check for input from keyboard
	whilecheck = whilecheck + 1
	detect, key = os.pullEvent()
	if detect == "key" and key == keys["right"] then
		position["width"] = position["width"] +1
		positionCorrection()
	end
	
	if detect == "key" and key == keys["left"] then
		position["width"] = position["width"] -1
		positionCorrection()
	end
	
	if detect == "key" and key == keys["up"] then
		position["height"] = position["height"] -1
		positionCorrection()
	end
	
	if detect == "key" and key == keys["down"] then
		position["height"] = position["height"] +1
		positionCorrection()
	end
	
	if detect == "key" and key == keys["enter"] then
		if position["height"] == table.getn(text) then
			if complete() then
				break
			end
		else
			answers[position["height"]] = position["width"]
		end
	end
	controller()
end
term.clear()
 -- Still have more questions? Send me a message in youtube to the username : Maarten580

 type = answers[1]
 buildcheck = answers[2]

function drop()
 for i=3,9,1 do
  if turtle.getItemSpace(i) == 0 then
   turtle.select(i)
   turtle.drop()
   turtle.select(2)
  end
 end
end

function reset(width)
 if turncheck == 0 then
  turtle.turnLeft()
  sleep(0.2)
  turtle.turnLeft()
  sleep(0.2)
  for i=0,lengthmax,1 do
   dig()
  end
 end
 turtle.turnLeft()
 sleep(0.2)
 for i=0,(width-1),1 do
  dig()
 end
 sleep(0.2)
 turtle.turnLeft()
 turncheck = 0
end

function dig(forward)
	if type == 1 then
		if turtle.detect() == true then
			turtle.dig()
			drop()
			sleep(0.2)
			turtle.forward() 
		else
			turtle.forward()
		end
	else
		if turtle.detect() then
			turtle.select(1)
			if turtle.compare() ~= true then
				turtle.dig()
				if forward == true then
					turtle.forward()
				end
				drop()
			else
				while turtle.compare() == true do
					turtle.select(2)
					turtle.dig()
					turtle.select(1)
					drop()
					sleep(1)
				end
			end
			turtle.select(2)
			sleep(0.2)
		elseif forward == true then
			turtle.forward()
		end
	end
end

function build(w, l, h)
 term.clear()
 count=count+1
 print("Width : "..w)
 print("Height : "..h)
 print("Length : "..l.."\n")
 print("Count : "..count.. " Total : "..total)
 print("Completed : "..((count / total)*100).."%")
 print(buildcheck)
 if buildcheck == 1 then
  if h == heightmax then
  turtle.select(2)
   if turtle.detectDown() == false then
    turtle.placeDown()
   end
  elseif (heightmax - (h-1)) == heightmax then
   if turtle.detectUp() == false then
    turtle.placeUp()
   end
  end
 
  if (w) == 1 then
   turtle.select(2)
   if movecheck == 0 then
    turtle.turnLeft()
    sleep(0.2)
    if turtle.detect() == false then
     turtle.place()
    end
    turtle.turnRight()
    sleep(0.2)
   else
    turtle.turnRight()
    sleep(0.2)
    if turtle.detect() == false then
     turtle.place()
    end
    turtle.turnLeft()
    sleep(0.2)
   end
  end
  
   if (w) == widthmax then
   turtle.select(2)
   if movecheck == 0 then
    turtle.turnRight()
    sleep(0.2)
    if turtle.detect() == false then
     turtle.place()
    end
    turtle.turnLeft()
    sleep(0.2)
   else
    turtle.turnLeft()
    sleep(0.2)
    if turtle.detect() == false then
     turtle.place()
    end
    turtle.turnRight()
    sleep(0.2)
   end
  end
 end
end

function turn()
 if turncheck == 0 then
  turtle.turnLeft()
  sleep(0.2)
  dig()
  sleep(0.2)
  turtle.turnLeft()
  turncheck = 1
  print("left")
 else
  turtle.turnRight()
  sleep(0.2)
  dig()
  sleep(0.2)
  turtle.turnRight()
  turncheck = 0  
  print("right")
 end
end

function hmove()
 if movecheck == 0 then
  turtle.turnRight()
  sleep(0.2)
  dig(true)
  sleep(0.2)
  turtle.turnLeft()
 else
  turtle.turnLeft()
  sleep(0.2)
  dig(true)
  sleep(0.2)
  turtle.turnRight() 
 end
end

function vmove(direction)
	if direction == "down" then
		if turtle.detectDown() then
			turtle.digDown("down")
			drop()
			sleep(0.2)
			turtle.down()
		else
			turtle.down()
		end
	elseif direction == "up" then
		if turtle.detectUp() then
			turtle.digUp()
			drop()
			sleep(0.2)
			turtle.up()
		else
			turtle.up()
		end
	end
end

if type == 1 then
	heightmax = heightmax - 1
	widthmax = widthmax -1
	lengthmax = lengthmax -2
	for height=0,heightmax,1 do
		for width=0,widthmax,1 do
			for length=0,lengthmax,1 do
				dig()
				build(width, length, height)
			end
			if width ~= widthmax then
				turn()
				build(width, length, height)
			end
		end
		reset(widthmax) 
		if heightmax ~= height then
			vmove("down")
			build(width, length, height)
		end
	end
	build(width, length, height)
else
	width = 2
	for length=1,lengthmax,1 do
		for height=2,heightmax,1 do
			vmove("up")
		end
		dig()
		for height=1,heightmax,1 do
			dig()
			build((width-1), length, height)
			for width=2,widthmax,1 do
				hmove()
				dig()
				build((width), length, height)
			end
			
			if height ~= heightmax then
				vmove("down")
			elseif length ~= lengthmax then
				dig(true)
			end
			
			if movecheck == 0 then
				movecheck = 1
			else
				movecheck = 0
			end
		end
	end
end
sleep(2)
term.clear()
print("Digging done.")
