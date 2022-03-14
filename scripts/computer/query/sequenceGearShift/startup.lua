function safeRednetOpen(modem_side)
    if not rednet.isOpen() then
        rednet.open(modem_side)
    end
end

function checkParams(modem_side)
    if modem_side == nil then
        return 'top'
    end

    return modem_side
end

function startReceiver(modem_side)
    modem_side = checkParams(modem_side)
    safeRednetOpen(modem_side)

    print('monitoring messages..')
    while true do
        local pcid,message = rednet.receive()
        if message and message == 'GANTRY_OFF' then
            redstone.setOutput('bottom', true)
            print('GANTRY_OFF: bottom true')
            os.sleep(1)
            redstone.setOutput('bottom', false)
            print('GANTRY_OFF: bottom false')
            os.sleep(1);
            rednet.broadcast('SEQUENCE_GEAR_SHIFT_TOGGLED')
        end
        os.sleep(1);
    end
end

startReceiver()