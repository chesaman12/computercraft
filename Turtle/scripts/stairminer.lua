-- dig forward
-- move forward
-- dig down
-- dig up
-- move up
-- dig up

function beginUp()
    turtle.dig()
    turtle.forward()
    turtle.digDown()
    turtle.digUp()
    turtle.up()
    turtle.digUp();
end

-- dig forward
-- move forward
-- dig down
-- move dowm
-- dig down
-- move dowm
-- dig down
-- move dowm

function beginDown()
    turtle.dig()
    turtle.forward()
    turtle.digDown()
    turtle.down()
    turtle.digDown()
    turtle.down()
    turtle.digDown()
    turtle.down()
end

print("How far? (digs forward and down first)")
distance = tonumber(read())

for i = 1, distance, 1 do
    if i%2 == 0 then
        beginDown()
    else 
        beginUp()
    end
end