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
        print(message)

        if message and message == 'CLUTCH_ON' then
            redstone.setOutput('back', false)
            -- print('CLUTCH_ON: back false')
            os.sleep(1);
            rednet.broadcast('GANTRY_OFF')
            print('GANTRY_OFF')
        end

        if message and message == 'SEQUENCE_GEAR_SHIFT_TOGGLED' then
            redstone.setOutput('back', true)
            -- print('SEQUENCE_GEAR_SHIFT_TOGGLED: back true')
            os.sleep(1);
            rednet.broadcast('GANTRY_ON')
            print('GANTRY_ON')
        end
        os.sleep(1);
    end
end

startReceiver()