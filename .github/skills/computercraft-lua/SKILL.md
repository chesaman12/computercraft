---
name: computercraft-lua
description: Expert knowledge for developing CC:Tweaked ComputerCraft Lua scripts in Minecraft. Use when writing turtle automation, computer programs, rednet communication, peripheral control, or any Minecraft ComputerCraft code.
---

# ComputerCraft CC:Tweaked Development Skill

I am an expert in developing Lua scripts for CC:Tweaked (ComputerCraft) mod in Minecraft. I help create turtle automation, computer programs, rednet networks, and peripheral integrations.

## When to Use This Skill

- Writing turtle automation scripts (mining, building, farming)
- Creating computer programs for CC:Tweaked
- Setting up rednet/modem communication between computers
- Working with peripherals (monitors, modems, speakers, inventories)
- Debugging ComputerCraft-specific issues
- Understanding CC:Tweaked APIs and events

## Core Knowledge

### The CC:Tweaked Environment

CC:Tweaked provides programmable computers and turtles in Minecraft:

- **Computers**: Stationary terminals for running programs
- **Turtles**: Mobile robots that can move, mine, build, and interact
- **Pocket Computers**: Portable computers players can carry
- **Peripherals**: External devices (monitors, modems, speakers, drives)

### Lua Version

CC:Tweaked 1.109.0+ uses **Lua 5.2**. Key differences from 5.1:

- Use `...` for varargs (not `arg`)
- Use `_ENV` for environments (not `getfenv/setfenv`)
- No binary chunk support
- `goto` statement available

### API Categories

#### 1. Turtle API (Robotic Control)

```lua
-- Movement (all return success, errorMessage)
turtle.forward()    turtle.back()
turtle.up()         turtle.down()
turtle.turnLeft()   turtle.turnRight()

-- World Interaction
turtle.dig()        turtle.digUp()      turtle.digDown()
turtle.place()      turtle.placeUp()    turtle.placeDown()
turtle.attack()     turtle.attackUp()   turtle.attackDown()

-- Inventory (16 slots)
turtle.select(slot) -- 1-16
turtle.getItemDetail(slot?)
turtle.getItemCount(slot?)
turtle.transferTo(slot, count?)
turtle.drop(count?)     turtle.dropUp()     turtle.dropDown()
turtle.suck(count?)     turtle.suckUp()     turtle.suckDown()

-- Fuel System
turtle.getFuelLevel()   -- number or "unlimited"
turtle.getFuelLimit()
turtle.refuel(count?)   -- consume fuel items in selected slot

-- Inspection
turtle.inspect()        -- returns success, blockData
turtle.inspectUp()
turtle.inspectDown()
turtle.detect()         -- returns boolean
turtle.detectUp()
turtle.detectDown()

-- Comparison
turtle.compare()        -- compare block in front to selected slot
turtle.compareUp()
turtle.compareDown()
turtle.compareTo(slot)  -- compare selected slot to another slot

-- Crafting (requires crafty turtle)
turtle.craft(limit?)
```

#### 2. Event System

```lua
-- Pull events (yields execution)
local event, p1, p2, p3 = os.pullEvent(filter?)
local event, ... = os.pullEventRaw(filter?)  -- catches terminate

-- Common Events
-- "key", keyCode, isHeld
-- "key_up", keyCode
-- "char", character
-- "timer", timerId
-- "alarm", alarmId
-- "rednet_message", senderId, message, protocol
-- "modem_message", side, channel, replyChannel, message, distance
-- "turtle_inventory"
-- "peripheral", side
-- "peripheral_detach", side
-- "redstone"
-- "terminate"
-- "mouse_click", button, x, y
-- "monitor_touch", side, x, y
```

#### 3. Rednet Communication

```lua
-- Setup
rednet.open("back")  -- open modem on specified side
rednet.close()       -- close all modems

-- Sending
rednet.send(recipientId, message, protocol?)
rednet.broadcast(message, protocol?)

-- Receiving
local senderId, message, protocol = rednet.receive(protocolFilter?, timeout?)

-- DNS-like naming
rednet.host(protocol, hostname)
rednet.unhost(protocol)
rednet.lookup(protocol, hostname?) -- returns id or table of ids
```

#### 4. Peripheral API

```lua
-- Discovery
peripheral.getNames()           -- list all peripherals
peripheral.isPresent(side)
peripheral.getType(side)
peripheral.find(type, filter?)  -- returns wrapped peripheral(s)

-- Usage
local p = peripheral.wrap(side)
p.someMethod()
-- or
peripheral.call(side, "method", args...)

-- Common peripheral types:
-- "modem", "monitor", "speaker", "drive", "printer"
-- "command" (command computer), "computer" (networked computer)
-- "inventory" (chests, etc via generic peripheral)
```

#### 5. File System

```lua
-- Reading/Writing
local file = fs.open("path", mode) -- "r", "w", "a", "rb", "wb", "ab"
local content = file.readAll()
file.write("data")
file.writeLine("line")
file.close()

-- File Operations
fs.exists(path)
fs.isDir(path)
fs.list(path)           -- returns table of names
fs.makeDir(path)
fs.delete(path)
fs.move(from, to)
fs.copy(from, to)
fs.getSize(path)
fs.getFreeSpace(path)
```

#### 6. HTTP (when enabled)

```lua
-- Synchronous
local response = http.get(url, headers?, binary?)
local body = response.readAll()
response.close()

local response = http.post(url, body, headers?, binary?)

-- Asynchronous (fires http_success or http_failure events)
http.request(url, body?, headers?, binary?, method?)

-- WebSockets
local ws = http.websocket(url, headers?)
ws.send(message)
local msg = ws.receive(timeout?)
ws.close()
```

#### 7. Term & Display

```lua
term.write(text)
term.clear()
term.clearLine()
term.setCursorPos(x, y)
term.getCursorPos()
term.getSize()
term.setTextColor(color)
term.setBackgroundColor(color)
term.scroll(n)

-- For monitors
local mon = peripheral.wrap("top")
mon.setTextScale(scale)  -- 0.5 to 5
term.redirect(mon)       -- redirect output to monitor
```

#### 8. Parallel Execution

```lua
-- Run until any function completes
parallel.waitForAny(func1, func2, ...)

-- Run until all functions complete
parallel.waitForAll(func1, func2, ...)
```

#### 9. Redstone API

```lua
-- Read redstone input from a side
redstone.getInput("top")      -- returns boolean
redstone.getAnalogInput("top") -- returns 0-15

-- Set redstone output
redstone.setOutput("left", true)
redstone.setAnalogOutput("left", 15)  -- 0-15

-- Bundled cable (if available)
redstone.getBundledInput("back")
redstone.setBundledOutput("back", colors.combine(colors.red, colors.blue))
```

#### 10. Colors API

```lua
-- Color constants for term, monitors, bundled cables
colors.white, colors.orange, colors.magenta, colors.lightBlue
colors.yellow, colors.lime, colors.pink, colors.gray
colors.lightGray, colors.cyan, colors.purple, colors.blue
colors.brown, colors.green, colors.red, colors.black

-- Bundled cable combinations
colors.combine(colors.red, colors.blue)
colors.subtract(combined, colors.red)
colors.test(combined, colors.blue)  -- returns boolean
```

### Best Practices

#### 1. Always Handle Failures

```lua
local function safeDig()
    local success, err = turtle.dig()
    if not success and err ~= "Nothing to dig here" then
        print("Dig failed: " .. tostring(err))
        return false
    end
    return true
end
```

#### 2. Yield Regularly

```lua
-- Prevent "Too long without yielding" error
for i = 1, 10000 do
    doWork()
    if i % 100 == 0 then
        sleep(0)  -- minimal yield
    end
end
```

#### 3. Manage Fuel

```lua
local function ensureFuel(minLevel)
    local fuel = turtle.getFuelLevel()
    if fuel == "unlimited" then return true end
    if fuel < minLevel then
        for slot = 1, 16 do
            turtle.select(slot)
            if turtle.refuel(0) then  -- test if item is fuel
                turtle.refuel()
            end
            if turtle.getFuelLevel() >= minLevel then
                return true
            end
        end
        return false
    end
    return true
end
```

#### 4. Use Require for Modules

```lua
-- utils.lua
local M = {}
function M.log(msg)
    print("[" .. os.date("%H:%M:%S") .. "] " .. msg)
end
return M

-- main.lua
local utils = require("utils")
utils.log("Started")
```

#### 5. Startup Scripts

```lua
-- startup.lua (runs on boot)
shell.run("bg_program")  -- run in background
shell.run("main")        -- run main program
```

#### 6. Packaging and Deployment

- Keep an entry point per program (`startup`, `startup.lua`, or `main.lua`).
- Organize helpers as modules and load with `require` from the same folder.
- Avoid spaces in file names to simplify `pastebin` and `wget` usage.
- Recommended loading options:
    - Pastebin: `pastebin put <file.lua>` then `pastebin get <id> <file.lua>`
    - Local HTTP server: `wget http://<host>:8000/path/file.lua file.lua`
    - World save copy: `saves/<world>/computercraft/computer/<id>/`
    - Disk drive: copy to floppy and use in-game `copy`/`cp`

### Common Patterns

#### Mining Turtle Pattern

```lua
local function mineForward()
    while turtle.detect() do
        turtle.dig()
        sleep(0.4)  -- wait for gravel/sand
    end
    return turtle.forward()
end
```

#### Event Server Pattern

```lua
rednet.open("back")
rednet.host("myservice", "server1")

while true do
    local senderId, message, protocol = rednet.receive("myservice")
    if message.type == "request" then
        local response = handleRequest(message.data)
        rednet.send(senderId, {type="response", data=response}, "myservice")
    end
end
```

#### GPS Locate Pattern

```lua
local x, y, z = gps.locate(5)  -- 5 second timeout
if x then
    print(("Position: %d, %d, %d"):format(x, y, z))
else
    print("GPS unavailable")
end
```

#### User Input Pattern

```lua
write("length: ")
local length = tonumber(read())
write("direction (l, r): ")
local direction = read():lower()

-- Normalize input
if direction == "l" or direction == "left" then
    direction = "left"
elseif direction == "r" or direction == "right" then
    direction = "right"
end
```

#### Fuel Check with User Prompt

```lua
local MIN_FUEL_LEVEL = 100

local function verifyFuelLevel()
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel ~= "unlimited" and fuelLevel <= MIN_FUEL_LEVEL then
        write("Fuel level low. Insert fuel & press enter to continue.\n")
        read()
        shell.run("refuel", "all")
        print("New fuel level: " .. turtle.getFuelLevel())
    end
end
```

#### Gravel/Sand Safe Dig Pattern

```lua
-- Keep digging until block stops falling
local function digUntilEmpty()
    while turtle.detect() do
        turtle.dig()
        sleep(0.4)  -- wait for falling blocks
    end
end

local function forwardAndDig()
    repeat
        turtle.dig()
    until turtle.forward()
end
```

#### Redstone Control Loop

```lua
-- Monitor redstone and control outputs
while true do
    if redstone.getInput("top") then
        redstone.setOutput("left", true)
    end
    if redstone.getInput("right") then
        redstone.setOutput("left", false)
    end
    os.sleep(1)
end
```

#### Safe Rednet Open

```lua
local function safeRednetOpen(side)
    if not rednet.isOpen() then
        rednet.open(side or "top")
    end
end
```

#### GPS Position Transmitter

```lua
local function getCords()
    while true do
        local x, y, z = gps.locate()
        if x then return x, y, z end
        os.sleep(1)
    end
end

local function startTransmitter(topCord, bottomCord)
    safeRednetOpen("top")
    while true do
        local x, y, z = getCords()
        if y < bottomCord then
            rednet.broadcast("AT_BOTTOM")
            os.sleep(60)
        elseif y > topCord then
            rednet.broadcast("AT_TOP")
            os.sleep(60)
        end
        os.sleep(1)
    end
end
```

#### Message Receiver with Redstone Output

```lua
local function startReceiver(messageName, redstoneSide, value)
    safeRednetOpen("top")
    while true do
        local senderId, message = rednet.receive()
        if message == messageName then
            redstone.setOutput(redstoneSide, value)
        end
        os.sleep(1)
    end
end
```

#### Inventory Slot Rotation

```lua
local slot = 1

local function checkAndFillSlot()
    while turtle.getItemCount(slot) == 0 do
        slot = slot + 1
        if slot > 16 then
            slot = 1
        end
        turtle.select(slot)
    end
end
```

#### 3D Mining Loop Pattern

```lua
local turn = "left"

local function adjustOrientation()
    if turn == "left" then
        turtle.turnLeft()
        forwardAndDig()
        turtle.turnLeft()
        turn = "right"
    else
        turtle.turnRight()
        forwardAndDig()
        turtle.turnRight()
        turn = "left"
    end
end

-- Mine a 3D area
for depth = 1, maxDepth do
    for length = 1, maxLength do
        for width = 1, maxWidth - 1 do
            digUpOrDown()
            forwardAndDig()
        end
        digUpOrDown()
        if length ~= maxLength then
            adjustOrientation()
        end
    end
    -- Move to next layer
    if direction == "up" then turtle.up() else turtle.down() end
    turtle.turnLeft() turtle.turnLeft()  -- reverse direction
end
```

#### Tree Farming Patterns

```lua
-- Tree type detection
local TREE_TYPES = {
    birch = { log = "minecraft:birch_log", sapling = "minecraft:birch_sapling" },
    oak = { log = "minecraft:oak_log", sapling = "minecraft:oak_sapling" },
    spruce = { log = "minecraft:spruce_log", sapling = "minecraft:spruce_sapling" },
}

local function isLog(blockData, treeType)
    return blockData and blockData.name == TREE_TYPES[treeType].log
end

-- Harvest tree by cutting upward
local function harvestTree()
    local logs = 0

    -- Cut base and move into tree position
    turtle.dig()
    turtle.forward()

    -- Cut upward until no more logs
    while true do
        local success, blockData = turtle.inspectUp()
        if success and isLog(blockData, "birch") then
            turtle.digUp()
            turtle.up()
            logs = logs + 1
        else
            break
        end
    end

    -- Return to ground
    while not turtle.detectDown() do
        turtle.down()
    end
    turtle.back()

    return logs
end

-- Collect drops (saplings, sticks, apples)
local function collectDrops()
    while turtle.suck() do end
    while turtle.suckDown() do end
end

-- Plant sapling if position is empty
local function plantSapling()
    if not turtle.detect() then  -- Nothing in front
        turtle.select(1)  -- Saplings in slot 1
        return turtle.place()
    end
    return false
end

-- Grid traversal for farm
local function traverseFarm(width, depth, spacing, callback)
    local gridSpacing = spacing + 1

    for z = 0, depth - 1 do
        local goingRight = (z % 2 == 0)

        for x = 0, width - 1 do
            local actualX = goingRight and x or (width - 1 - x)

            -- Move to position and call handler
            -- (navigation code would go here)
            callback(actualX, z)

            sleep(0.1)  -- Yield to prevent timeout
        end
    end
end
```

## Resources

- Official Wiki: https://tweaked.cc/
- GitHub: https://github.com/cc-tweaked/CC-Tweaked
- Workspace docs: `docs/cc-tweaked/`
- Example scripts: `scripts/turtle/`, `scripts/computer/`

## Tomfoolery Project Structure

**IMPORTANT:** All development work should be done in `scripts/tomfoolery/` ONLY. Do not use or modify files in `scripts/turtle/` or `scripts/computer/`.

The `scripts/tomfoolery/` project uses a modular architecture:

```
tomfoolery/
├── common/           # Shared utility libraries
│   ├── movement.lua  # Position tracking, safe movement
│   ├── inventory.lua # Item management, junk filtering
│   ├── mining.lua    # Ore detection, safe digging
│   ├── fuel.lua      # Fuel management, auto-refuel
│   ├── config.lua    # Config file loading
│   └── logger.lua    # Logging with Pastebin upload
├── miner/            # Smart miner modules
│   ├── core.lua      # Config, state, stats, utilities
│   ├── home.lua      # Home navigation, deposits, restocking
│   ├── tunnel.lua    # Tunnel step functions, ore checking
│   └── patterns.lua  # Mining patterns (perimeter, branches)
├── farmer/           # Tree farmer modules
│   ├── core.lua      # Config, state, tree type definitions
│   ├── harvest.lua   # Tree cutting, drop collection
│   └── planting.lua  # Sapling placement, replanting
├── mining/           # Mining entry point scripts
│   └── smart_miner.lua  # Branch mining orchestrator
├── farming/          # Farming entry point scripts
│   └── tree_farmer.lua  # Tree farm orchestrator
├── config/           # Runtime configuration
│   ├── ores.cfg      # Ore block list
│   ├── junk.cfg      # Junk block list
│   └── logger.cfg    # Logging + Discord webhook config
├── upload_log.lua    # Upload logs to Pastebin
└── installer.lua     # Downloads all files from GitHub
```

### Logging Pattern (Required)

All scripts should include comprehensive logging for debugging:

```lua
local logger = require("common.logger")

-- At startup
logger.clear()  -- Fresh log for this run
logger.logParams("Script Name", {
    param1 = value1,
    param2 = value2,
})

-- Log sections for organization
logger.section("Phase Name")

-- Log at appropriate levels
logger.info("Normal operation: %s", status)
logger.warn("Warning: fuel low at %d", fuelLevel)
logger.error("Error: %s", errorMessage)
logger.debug("Position: x=%d, y=%d, z=%d", x, y, z)

-- At end of run (uploads to Pastebin + sends to Discord)
logger.finalize(stats, "Run Title")
```

Log levels:

- **error**: Fatal issues, exceptions, unrecoverable states
- **warn**: Resource warnings, unexpected but recoverable conditions
- **info**: Normal operations, phase changes, milestones
- **debug**: Detailed flow, variable values, diagnostics

### Discord Integration

Configure `discord_webhook` in `config/logger.cfg` to automatically receive Pastebin URLs in Discord when logs are uploaded. This prevents losing log links when turtle screens clear.

```lua
-- config/logger.cfg
discord_webhook = https://discordapp.com/api/webhooks/YOUR_WEBHOOK_URL
```

Pastebin uploads require `pastebin_key`:

```lua
-- config/logger.cfg
pastebin_key = YOUR_API_KEY
```

### Module Dependency Pattern

Modules use dependency injection via `init()` functions:

```lua
-- In miner/core.lua
local M = {}
M.movement = nil  -- Set by init()

function M.init(deps)
    M.movement = deps.movement
    M.inventory = deps.inventory
end

-- In smart_miner.lua (entry point)
local core = require("miner.core")
core.init({ movement = movement, inventory = inventory })
```

This pattern allows modules to be tested independently and avoids circular dependencies.
