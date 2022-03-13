-- assumes the following:
-- * clutch behind computer
-- * sequenced gearshift to the right (for extending)
-- * gearshift to the left (for raising/lowering)

function main()
    rednet.open('top')
    receiverLoop()
end

function receiverLoop()
    print('monitoring messages..')
    while true do
        local pcid,message = rednet.receive()
        if message then
            
        end
        os.sleep(1);
    end
end

main()