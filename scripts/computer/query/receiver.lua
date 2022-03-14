function main()
    startReceiver('AT_TOP', 'bottom', true, 'top')
end

function checkParams(message_name, redstone_side, restone_value, modem_side)
    if message_name == nil then
        error('error: message_name required')
    end

    if redstone_side == nil then
        error('error: redstone_side required')
    end

    if restone_value == nil then
        error('error: restone_value required')
    end

    if modem_side == nil then
        modem_side = 'top'
    end

    return modem_side
end

function safeRednetOpen(modem_side)
    if not rednet.isOpen() then
        rednet.open(modem_side)
    end
end

function startReceiver(message_name, redstone_side, restone_value, modem_side)
    safeRednetOpen()
    modem_side = checkParams(message_name, redstone_side, restone_value, modem_side)

    print('monitoring messages..')
    while true do
        local pcid,message = rednet.receive()
        if message and message == message_name then
            print('setting output: ' .. redstone_side .. ' ' .. tostring(restone_value))
            redstone.setOutput(redstone_side, restone_value)
        end
        os.sleep(1);
    end
end

main()

-- up, time to go forward
-- AT_TOP
-- CLUTCH_ON
-- GANTRY_OFF
-- SEQUENCE_GEAR_SHIFT_TOGGLED

-- gone forward, time to go down
-- GANTRY_ON
-- CLUTCH_OFF
-- GEAR_SHIFT_OFF

-- at bottom, time to go up
-- AT_BOTTOM
-- GEAR_SHIFT_ON