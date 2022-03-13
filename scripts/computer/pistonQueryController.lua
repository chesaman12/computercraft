while true do
    -- if redstone from top
    -- out left
    if redstone.getInput('top') then
        redstone.setOutput('left', true);
    end

    -- if redstone from the right
    -- stop out left
    if redstone.getInput('right') then
        redstone.setOutput('left', false);
    end

    os.sleep(1)
end
