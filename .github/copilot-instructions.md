# ComputerCraft CC:Tweaked Lua Development Instructions

This workspace contains Lua scripts for CC:Tweaked (ComputerCraft) in Minecraft. All code should target the CC:Tweaked runtime environment.

## Language & Runtime

- Use **Lua 5.2** syntax (CC:Tweaked 1.109.0+ uses Lua 5.2)
- Use `...` for varargs, not the deprecated `arg` pseudo-argument
- Use `_ENV` for environment manipulation, not `getfenv`/`setfenv`
- Binary chunk loading (`string.dump`) is not supported

## Key APIs Reference

### Global Functions
- `sleep(seconds)` - Pause execution (yields, minimum 0.05s)
- `read(replaceChar?, history?, completeFn?, default?)` - Read user input
- `print(...)` / `write(text)` - Output to terminal
- `printError(...)` - Print in red for errors

### Event System (Critical)
- `os.pullEvent(filter?)` - Wait for events (stops on terminate)
- `os.pullEventRaw(filter?)` - Wait for events (handles terminate yourself)
- Always handle events in a `while true do` loop for continuous operation
- Common events: `key`, `char`, `timer`, `rednet_message`, `turtle_inventory`, `peripheral`, `redstone`, `modem_message`

### Turtle API (for turtle computers)
- Movement: `turtle.forward()`, `turtle.back()`, `turtle.up()`, `turtle.down()`, `turtle.turnLeft()`, `turtle.turnRight()`
- Digging: `turtle.dig()`, `turtle.digUp()`, `turtle.digDown()`
- Placing: `turtle.place()`, `turtle.placeUp()`, `turtle.placeDown()`
- Inventory: `turtle.select(slot)`, `turtle.getItemDetail(slot?)`, `turtle.getItemCount(slot?)`
- Fuel: `turtle.getFuelLevel()`, `turtle.getFuelLimit()`, `turtle.refuel(count?)`
- Inspection: `turtle.inspect()`, `turtle.inspectUp()`, `turtle.inspectDown()`
- Crafting: `turtle.craft(limit?)` - requires crafty turtle upgrade
- All movement/action functions return `boolean, string?` (success, error message)

### Rednet / Modem Communication
- `rednet.open(side)` / `rednet.close(side?)` - Open/close modem
- `rednet.send(recipient, message, protocol?)` - Send to specific computer
- `rednet.broadcast(message, protocol?)` - Send to all computers
- `rednet.receive(protocol?, timeout?)` - Wait for message
- Use `modem_message` event for raw modem communication

### Peripheral API
- `peripheral.find(type)` - Find peripheral by type (e.g., "modem", "monitor")
- `peripheral.wrap(side)` - Wrap peripheral on specific side
- `peripheral.getNames()` - List all connected peripherals
- `peripheral.call(name, method, ...)` - Call method on peripheral

### File System
- `fs.open(path, mode)` - Open file ("r", "w", "a", "rb", "wb", "ab")
- `fs.exists(path)`, `fs.isDir(path)`, `fs.list(path)`
- `fs.makeDir(path)`, `fs.delete(path)`, `fs.move(from, to)`, `fs.copy(from, to)`

### HTTP (when enabled)
- `http.get(url, headers?, binary?)` - GET request
- `http.post(url, body, headers?, binary?)` - POST request
- `http.request(url, body?, headers?, binary?, method?)` - Async request

### GPS
- `gps.locate(timeout?, debug?)` - Get current position (requires GPS constellation)

### Useful Utilities
- `textutils.serialize(t)` / `textutils.unserialize(s)` - Table serialization
- `textutils.serializeJSON(t)` / `textutils.unserializeJSON(s)` - JSON handling
- `parallel.waitForAny(...)` / `parallel.waitForAll(...)` - Run functions in parallel
- `os.startTimer(seconds)` - Start a timer, returns timer ID
- `os.setAlarm(time)` - Set alarm for in-game time

## Coding Patterns

### Always check return values
```lua
local success, err = turtle.forward()
if not success then
    print("Failed to move: " .. (err or "unknown error"))
end
```

### Use local variables
```lua
local function myFunction()
    local count = 0
    -- prefer local over global
end
```

### Module pattern with require
```lua
-- mymodule.lua
local M = {}
function M.doSomething() end
return M

-- main.lua
local mymodule = require("mymodule")
mymodule.doSomething()
```

### Startup files
- `startup.lua` or `startup` runs automatically when computer boots
- Use for initializing programs, servers, or daemons

### Fuel management for turtles
- Always check fuel before long operations
- Refuel from inventory: `turtle.refuel()`
- Check fuel: `if turtle.getFuelLevel() < 100 then ... end`

## Setup, Packaging, and Loading Scripts

### Packaging Conventions
- Keep each program in a dedicated folder with a clear entry point (e.g., `startup`, `startup.lua`, or `main.lua`).
- Put reusable code in modules and load with `require`. Prefer shallow folder structures to keep `require` paths simple.
- Avoid spaces in filenames to make `wget`/`pastebin` usage painless.

### Loading Scripts into the Game (Choose One)

1) Pastebin (quickest for single files)
- Upload from dev machine: `pastebin put <file.lua>` and note the returned ID
- In-game: `pastebin get <id> <file.lua>` or `pastebin run <id>`

2) Local HTTP server (best for multiple files)
- Host from dev machine: `python -m http.server` (or any static server)
- In-game: `wget http://<host>:8000/path/file.lua file.lua`
- Requires HTTP enabled in CC:Tweaked config (Pastebin also uses HTTP)

3) World save copy (fastest for bulk sync)
- Copy files directly into `saves/<world>/computercraft/computer/<id>/`
- Keep the same folder structure as on disk

4) Disk drive workflow (portable)
- Copy files to a floppy disk, then use in-game `copy` or `cp` to move to the computer

## File Structure Convention

- `/scripts/turtle/` - Turtle-specific programs
- `/scripts/computer/` - Regular computer programs
- Use `.lua` extension for all scripts
- Use descriptive names (e.g., `miningTunnel.lua`, `turtlerefuel.lua`)

## Documentation Reference

- Official wiki: https://tweaked.cc/
- API docs in workspace: `docs/cc-tweaked/`
