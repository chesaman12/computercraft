```skill
---
name: cc-logging
description: Expert knowledge for adding configurable logging to CC:Tweaked Lua scripts. Use when implementing logging, debugging output, or audit trails for turtle/computer programs.
---

# CC:Tweaked Logging Skill

I am an expert in implementing configurable logging for CC:Tweaked projects, including file-based logs, terminal output, log levels, and installer integration.

## When to Use This Skill

- Adding logging to new or existing CC:Tweaked scripts
- Debugging turtle programs that run unattended
- Creating audit trails for automation scripts
- Setting up configurable verbosity levels
- Integrating logging with installer scripts

---

## Logger Module Location

The logger module lives at `common/logger.lua` and is required like any other common module:

```lua
local logger = require("common.logger")
```

---

## Log Levels

Four severity levels are available (lower = more severe):

| Level | Value | Use Case |
|-------|-------|----------|
| `error` | 1 | Script-stopping failures, unbreakable blocks, movement failures |
| `warn` | 2 | Recoverable issues: low fuel, inventory full |
| `info` | 3 | Key events: start, complete, return to chest |
| `debug` | 4 | Verbose: every movement, turn, dig action |

The `min_level` config controls which messages are logged. Setting `min_level = warn` logs only `error` and `warn` messages.

---

## Configuration

### Config File: `/config/logger.cfg`

```cfg
# Logger configuration
# min_level: error, warn, info, debug
# echo: true/false - print to terminal
# log_path: path to log file (default: /logs/<program>.log)

min_level = info
echo = true
```

### Runtime Overrides

Set globals before requiring the logger to override config file:

```lua
_G.LOG_LEVEL = "debug"    -- Override min_level
_G.LOG_ECHO = false       -- Override echo
_G.LOG_PATH = "/logs/custom.log"  -- Override log path
```

### Priority Order

1. `_G.LOG_*` globals (highest)
2. `/config/logger.cfg` file
3. Built-in defaults (lowest)

---

## Logger API

### Basic Logging

```lua
local logger = require("common.logger")

logger.error("Failed to move: %s", errorMessage)
logger.warn("Fuel low: %d remaining", fuelLevel)
logger.info("Mining started: %d blocks", totalBlocks)
logger.debug("Moved to x=%d z=%d", posX, posZ)
```

### Format Strings

All log functions support `string.format` syntax:

```lua
logger.info("Position: x=%d, y=%d, z=%d", x, y, z)
logger.debug("Found %s in slot %d", itemName, slot)
```

### Utility Functions

```lua
logger.getLogPath()     -- Returns current log file path
logger.setLevel(level)  -- Change level at runtime ("error"/"warn"/"info"/"debug")
logger.setEcho(bool)    -- Enable/disable terminal output
logger.clear()          -- Delete the current log file
```

---

## Log Output Format

Each log line includes:

```
[D1 14:30] [INFO] Mining started: 50 blocks
[D1 14:31] [DEBUG] Moved forward to x=1 z=5
[D1 14:32] [WARN] Fuel low (45), returning home
```

Format: `[Day Time] [LEVEL] Message`

---

## File Locations

- **Log files:** `/logs/<program>.log` (e.g., `/logs/strip_miner.log`)
- **Config file:** `/config/logger.cfg`

The logger auto-creates `/logs/` directory if missing.

---

## Adding Logging to Scripts

### Recommended Log Points

| Event | Level | Example |
|-------|-------|---------|
| Script start | `info` | `"Starting strip mine: spine=%d branches=%d"` |
| Script complete | `info` | `"Mining complete (%d steps)"` |
| Script abort | `warn` | `"Aborted at step %d/%d"` |
| Movement failure | `error` | `"Cannot move forward at x=%d z=%d"` |
| Fuel warning | `warn` | `"Fuel low (%d), returning home"` |
| Inventory full | `info`/`debug` | `"Inventory full, returning to chest"` |
| Each movement | `debug` | `"Moved forward to x=%d z=%d"` |
| Each turn | `debug` | `"Turned left, now facing %d"` |
| Each dig | `debug` | `"Digging ahead at x=%d z=%d"` |
| Branch start/end | `debug` | `"Starting branch (length=%d)"` |

### Example: Adding to a Movement Function

```lua
local function moveForward()
    local attempts = 0
    while not turtle.forward() do
        if turtle.detect() then
            logger.debug("Obstacle, digging at x=%d z=%d", posX, posZ)
            turtle.dig()
        else
            sleep(0.2)
        end
        attempts = attempts + 1
        if attempts > 10 then
            logger.error("Cannot move forward at x=%d z=%d", posX, posZ)
            return false
        end
    end
    updatePosition()
    logger.debug("Moved to x=%d z=%d", posX, posZ)
    return true
end
```

---

## Installer Integration

### Adding Logger to Installer

1. Add to files list:

```lua
local files = {
    { path = "common/logger.lua", required = true },
    -- ... other files
}
```

2. Add directories:

```lua
local directories = {
    "common",
    "config",
    "logs",
    -- ... other dirs
}
```

3. Add config prompt function:

```lua
local loggerConfigTemplate = [[
# Logger configuration
min_level = %s
echo = %s
]]

local function promptLoggerConfig()
    print("Logger Configuration")
    print("--------------------")
    print("")
    print("Log levels: 1) error  2) warn  3) info  4) debug")
    write("Select log level (1-4, default 3): ")
    local levelInput = read()
    local levelNum = tonumber(levelInput)
    local levels = { "error", "warn", "info", "debug" }
    local minLevel = levels[levelNum] or "info"
    
    write("Print logs to terminal? (y/n, default y): ")
    local echoInput = read():lower()
    local echo = (echoInput ~= "n" and echoInput ~= "no") and "true" or "false"
    
    print("")
    return minLevel, echo
end

local function createLoggerConfig(minLevel, echo)
    local path = "config/logger.cfg"
    if not fs.exists(path) then
        local content = string.format(loggerConfigTemplate, minLevel, echo)
        local file = fs.open(path, "w")
        if file then
            file.write(content)
            file.close()
        end
    end
end
```

4. Call in main install flow:

```lua
createDirectories()
local minLevel, echo = promptLoggerConfig()
createLoggerConfig(minLevel, echo)
downloadFiles()
```

### Update Behavior

- `installer update` re-downloads all scripts
- Config (`/config/logger.cfg`) is preserved if it exists
- Log files (`/logs/*.log`) are never touched
- Users can manually edit config to change verbosity

---

## Viewing Logs

### In-Game

```
edit /logs/strip_miner.log
```

### Export via Pastebin

```
pastebin put /logs/strip_miner.log
```

This returns a pastebin ID you can view in a browser or share in chat.

### Clear Logs

```lua
local logger = require("common.logger")
logger.clear()
```

Or manually:

```
delete /logs/strip_miner.log
```

---

## Logger Module Implementation

The complete logger module at `common/logger.lua`:

```lua
--- Logger module for turtle scripts
-- Provides file and terminal logging with configurable levels
--
-- Config: /config/logger.cfg (key=value)
--   min_level = error|warn|info|debug (default: info)
--   echo = true|false (default: true)
--   log_path = path (default: /logs/<program>.log)
--
-- Override at runtime via _G.LOG_LEVEL, _G.LOG_ECHO, _G.LOG_PATH
--
-- @module logger

local M = {}

local LEVELS = {
    error = 1,
    warn  = 2,
    info  = 3,
    debug = 4,
}

local config = {
    min_level = "info",
    echo = true,
    log_path = nil,
}

local configLoaded = false

local function parseConfigFile(path)
    local result = {}
    if not fs.exists(path) then return result end
    local file = fs.open(path, "r")
    if not file then return result end
    local line = file.readLine()
    while line do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^#") then
            local key, value = line:match("^([^=]+)%s*=%s*(.*)$")
            if key and value then
                result[key:match("^%s*(.-)%s*$")] = value:match("^%s*(.-)%s*$")
            end
        end
        line = file.readLine()
    end
    file.close()
    return result
end

local function loadConfig()
    if configLoaded then return end
    configLoaded = true

    local fileConfig = parseConfigFile("/config/logger.cfg")
    if fileConfig.min_level and LEVELS[fileConfig.min_level] then
        config.min_level = fileConfig.min_level
    end
    if fileConfig.echo ~= nil then
        config.echo = (fileConfig.echo == "true")
    end
    if fileConfig.log_path and fileConfig.log_path ~= "" then
        config.log_path = fileConfig.log_path
    end

    if _G.LOG_LEVEL and LEVELS[_G.LOG_LEVEL] then
        config.min_level = _G.LOG_LEVEL
    end
    if _G.LOG_ECHO ~= nil then
        config.echo = _G.LOG_ECHO
    end
    if _G.LOG_PATH then
        config.log_path = _G.LOG_PATH
    end

    if not config.log_path then
        local prog = shell and shell.getRunningProgram() or "program"
        local name = prog:match("([^/]+)%.lua$") or prog:match("([^/]+)$") or "program"
        config.log_path = "/logs/" .. name .. ".log"
    end
end

local function ensureLogDir()
    local dir = config.log_path:match("(.+)/[^/]+$")
    if dir and not fs.exists(dir) then
        fs.makeDir(dir)
    end
end

local function timestamp()
    local time = os.time()
    local day = os.day()
    return string.format("D%d %s", day, textutils.formatTime(time, true))
end

local function log(level, fmt, ...)
    loadConfig()
    local levelNum = LEVELS[level] or 3
    local minNum = LEVELS[config.min_level] or 3
    if levelNum > minNum then return end

    local msg
    if select("#", ...) > 0 then
        msg = string.format(fmt, ...)
    else
        msg = tostring(fmt)
    end

    local line = string.format("[%s] [%s] %s", timestamp(), level:upper(), msg)

    if config.echo then
        if level == "error" then
            printError(line)
        else
            print(line)
        end
    end

    ensureLogDir()
    local file = fs.open(config.log_path, "a")
    if file then
        file.writeLine(line)
        file.close()
    end
end

function M.error(fmt, ...) log("error", fmt, ...) end
function M.warn(fmt, ...) log("warn", fmt, ...) end
function M.info(fmt, ...) log("info", fmt, ...) end
function M.debug(fmt, ...) log("debug", fmt, ...) end

function M.getLogPath()
    loadConfig()
    return config.log_path
end

function M.setLevel(level)
    if LEVELS[level] then config.min_level = level end
end

function M.setEcho(enabled)
    config.echo = enabled
end

function M.clear()
    loadConfig()
    if fs.exists(config.log_path) then
        fs.delete(config.log_path)
    end
end

return M
```

---

## Troubleshooting

### Logs Not Appearing

1. Check `min_level` in config — set to `debug` for verbose output
2. Verify `echo = true` if expecting terminal output
3. Check log file path: `print(logger.getLogPath())`

### Log File Too Large

```lua
logger.clear()  -- Delete current log file
```

Or set `min_level = warn` to reduce verbosity.

### Config Not Taking Effect

- Config is read once on first log call
- Restart the script after editing config
- Check for typos in config file (must be exact: `min_level`, `echo`)
```
