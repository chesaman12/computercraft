function safeRednetOpen(modem_side)
    if not rednet.isOpen() then
        rednet.open(modem_side)
    end
end

function checkParams(modem_side)
    if modem_side == nil then
        modem_side = 'top'
    end

    return modem_side
end

function startReceiver(modem_side)
    modem_side = checkParams(modem_side)
    safeRednetOpen(modem_side)

    print('monitoring messages..')
    while true do
        local pcid,message = rednet.receive()
        if message and message == 'AT_TOP' then
            redstone.setOutput('bottom', true)
            print('AT_TOP: bottom true')
            os.sleep(1);
            rednet.broadcast('CLUTCH_ON')
        end

        if message and message == 'GANTRY_ON' then
            redstone.setOutput('bottom', false)
            print('GANTRY_ON: bottom false')
            os.sleep(1);
            rednet.broadcast('CLUTCH_OFF')
        end
        os.sleep(1);
    end
end

startReceiver()