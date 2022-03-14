function main()
    startTransimitter(90)
end

function getCords()
    local call_count = 0;
    while true do
        local x,y,z = gps.locate()
        if x ~= nil and y ~= nil and z ~= nil then
            return x,y,z
        end

        if call_count > 60 then
            print('gps location has exceeded a high call count!')
            print('got location ' .. x .. ' ' .. y .. ' ' .. z)
            os.sleep(5);
        end
        os.sleep(1);
    end
end

function checkParams(top_cord, bottom_cord, modem_side)
    if top_cord == nil then
        error('error: bottom_cord required')
    end

    if modem_side == nil then
        modem_side = 'top'
    end

    if bottom_cord == nil then
        bottom_cord = 7
    end

    return top_cord, bottom_cord, modem_side
end

function safeRednetOpen(modem_side)
    if not rednet.isOpen() then
        rednet.open(modem_side)
    end
end

function startTransimitter(top_cord, bottom_cord, modem_side)
    top_cord, bottom_cord, modem_side = checkParams(top_cord, bottom_cord, modem_side)
    safeRednetOpen(modem_side)

    print('monitoring gps cords..')
    while true do
        local x,y,z = getCords()
        print(x .. ' ' .. y)
        if y < bottom_cord then
            print('AT_BOTTOM')
            rednet.broadcast('AT_BOTTOM')
            os.sleep(60);
        end

        if y > top_cord then
            print('AT_TOP')
            rednet.broadcast('AT_TOP')
            os.sleep(60);
        end
        os.sleep(1);
    end
end

main()