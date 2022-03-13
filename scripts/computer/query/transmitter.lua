function main()
    rednet.open('top')
    transmittionLoop()
end

function getCords()
    while true do
        local x,y,z = gps.locate()
        if x ~= nil and y ~= nil and z ~= nil then
            return x,y,z
        end
    end
end

function transmittionLoop()
    print('monitoring gps cords..')
    while true do
        local x,y,z = getCords()

        if z >= 1513 then
            print('OUT_OF_CONVEYOR')
            rednet.broadcast('OUT_OF_CONVEYOR')
            os.sleep(30);
        end

        if y < 7 then
            print('HIT_BOTTOM')
            rednet.broadcast('HIT_BOTTOM')
        end

        if y > 95 then
            os.sleep(30);
            print('HIT_TOP')
            rednet.broadcast('HIT_TOP')
        end
        os.sleep(1);
    end
end

main()