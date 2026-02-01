---
applyTo: "**/*.lua"
name: ComputerCraft Lua
description: Guidelines for writing CC:Tweaked Lua scripts for Minecraft
---

# ComputerCraft CC:Tweaked Lua Coding Guidelines

## Runtime Environment
- Target Lua 5.2 (CC:Tweaked 1.109.0+)
- Code runs in Minecraft's ComputerCraft mod environment
- All scripts execute on in-game computers or turtles

## Essential Patterns

### Event Loop Pattern
```lua
while true do
    local event, param1, param2 = os.pullEvent()
    if event == "key" then
        -- handle key press
    elseif event == "timer" then
        -- handle timer
    end
end
```

### Safe Turtle Movement
```lua
local function safeForward()
    while not turtle.forward() do
        if turtle.detect() then
            turtle.dig()
        else
            sleep(0.5)
        end
    end
end
```

### Fuel Check Before Operations
```lua
local function ensureFuel(needed)
    if turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < needed then
        turtle.refuel()
    end
    return turtle.getFuelLevel() >= needed or turtle.getFuelLevel() == "unlimited"
end
```

### Peripheral Wrapping
```lua
local modem = peripheral.find("modem")
if not modem then
    error("No modem attached!")
end
```

## API Quick Reference

### Turtle (16 inventory slots)
- Movement: `forward`, `back`, `up`, `down`, `turnLeft`, `turnRight`
- Actions: `dig`, `place`, `attack`, `suck`, `drop`
- Suffixes: none (front), `Up`, `Down`
- Returns: `success: boolean, errorMessage?: string`

### Rednet Communication
```lua
rednet.open("right")  -- open modem on right side
rednet.broadcast("hello", "myProtocol")
local senderId, message, protocol = rednet.receive("myProtocol", 5)
```

### Timers
```lua
local timerId = os.startTimer(5)  -- 5 second timer
local event, id = os.pullEvent("timer")
if id == timerId then
    -- timer fired
end
```

## Common Mistakes to Avoid

1. **Forgetting to yield** - Long loops must call `sleep()` or `os.pullEvent()` to prevent "Too long without yielding"
2. **Not checking return values** - Turtle functions can fail silently
3. **Using global variables** - Always use `local` for better performance
4. **Hardcoding key codes** - Use `keys.enter` instead of `28`
5. **Ignoring fuel** - Turtles need fuel to move (except in creative)

## Workspace References
- Documentation: [docs/cc-tweaked/](docs/cc-tweaked/)
- Example scripts: [scripts/turtle/](scripts/turtle/)
- API stubs: [docs/cc-tweaked/stub/](docs/cc-tweaked/stub/)
