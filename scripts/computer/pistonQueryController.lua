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


-- create a gps system using the following:
-- http://www.computercraft.info/forums2/index.php?/topic/3088-how-to-guide-gps-global-position-system/

-- add computers ontop of create blocks that require a redstone
-- and will be listening for signal transimition
-- IE gearshift, pulley, clutch

-- add a wireless modem to call computers

-- using the gps system, add a computer (client connection) to the
-- query that will act as a broadcaster and sends messages
-- based in its z coord (as a startup script, with infinte looping)
-- See notes on gps and the rednet API
-- https://tweaked.cc/module/rednet.html

-- for computers that are listening for a signal transimition,
-- excute function upon recieving a specific message / action

-- messages / action types
--      LOWER_QUERY
--      RAISE_QUERY
--      EXTEND_QUERY
--      PAUSE_JOB
--      RESUME_JOB

-- using the actions types from the broadcaaster,
-- related metadata / payload can be included

-- broadcaster metadata / payload event structure
-- {actionType: string, payload: table}

-- based on action/event, computer will emmit a redstone signal below / beside
-- it based on start configuration

-- note: we can monitor a buffer chest with open OpenPeripheral to see
-- if we should pause the query (IE, storage system is full)

-- OTHER
-- add a chunk loader to the querry
-- add a console log with giant text indicating what the computer action is
    -- the computer above the clutch will be sending pause/resume
    -- so we can display something to indicate this with possible logging
    -- of events as they happen
