# Testing ComputerCraft Scripts

This guide explains how to test and validate your Lua scripts before deploying them to turtles in-game.

---

## Table of Contents

1. [Syntax Checking](#syntax-checking)
2. [Local Testing with Lua](#local-testing-with-lua)
3. [CC:Tweaked Emulators](#cctweaked-emulators)
4. [VS Code Integration](#vs-code-integration)
5. [Common Errors](#common-errors)

---

## Syntax Checking

### Using luac (Lua Compiler)

The Lua compiler can check syntax without running the code:

```bash
# Check a single file
luac -p scripts/tomfoolery/mining/smart_miner.lua

# Check all Lua files in a directory
find scripts/tomfoolery -name "*.lua" -exec luac -p {} \;

# PowerShell equivalent
Get-ChildItem -Path scripts/tomfoolery -Filter "*.lua" -Recurse | ForEach-Object { luac -p $_.FullName }
```

**No output = no syntax errors**

If there's an error, you'll see:

```
luac: smart_miner.lua:58: unexpected symbol near '...'
```

### Installing Lua on Windows

1. Download from: https://luabinaries.sourceforge.net/
2. Or use Scoop: `scoop install lua`
3. Or use Chocolatey: `choco install lua`

### Installing Lua on Linux/Mac

```bash
# Ubuntu/Debian
sudo apt install lua5.2

# macOS
brew install lua@5.2
```

**Note:** CC:Tweaked uses Lua 5.2, so use `lua5.2` or `luac5.2` if available.

---

## Local Testing with Lua

You can run scripts locally, but CC:Tweaked APIs won't be available. Create mock APIs for testing:

### Basic Mock Setup

Create a file `test/mock_turtle.lua`:

```lua
-- Mock turtle API for local testing
turtle = {
    forward = function() print("turtle.forward()") return true end,
    back = function() print("turtle.back()") return true end,
    up = function() print("turtle.up()") return true end,
    down = function() print("turtle.down()") return true end,
    turnLeft = function() print("turtle.turnLeft()") return true end,
    turnRight = function() print("turtle.turnRight()") return true end,
    dig = function() print("turtle.dig()") return true end,
    digUp = function() print("turtle.digUp()") return true end,
    digDown = function() print("turtle.digDown()") return true end,
    detect = function() return false end,
    detectUp = function() return false end,
    detectDown = function() return false end,
    inspect = function() return false, nil end,
    inspectUp = function() return false, nil end,
    inspectDown = function() return false, nil end,
    select = function(slot) return true end,
    getSelectedSlot = function() return 1 end,
    getItemCount = function(slot) return 0 end,
    getItemDetail = function(slot) return nil end,
    getFuelLevel = function() return 1000 end,
    getFuelLimit = function() return 20000 end,
    refuel = function(count) return true end,
    place = function() return true end,
    placeUp = function() return true end,
    placeDown = function() return true end,
    drop = function() return true end,
    dropUp = function() return true end,
    dropDown = function() return true end,
    suck = function() return true end,
    suckUp = function() return true end,
    suckDown = function() return true end,
    transferTo = function(slot, count) return true end,
}

-- Mock other CC APIs
os.pullEvent = function(filter) return filter, 1 end
os.clock = function() return 0 end
sleep = function(t) end

fs = {
    exists = function(path) return false end,
    open = function(path, mode) return nil end,
    makeDir = function(path) end,
    list = function(path) return {} end,
}

term = {
    clear = function() end,
    setCursorPos = function(x, y) end,
    getCursorPos = function() return 1, 1 end,
    getSize = function() return 51, 19 end,
    write = function(text) io.write(text) end,
}

function write(text) io.write(text) end
function printError(text) print("ERROR: " .. text) end
function read() return io.read() end
```

### Running Tests

```bash
# Load mocks then your script
lua -e "dofile('test/mock_turtle.lua')" scripts/tomfoolery/common/movement.lua
```

---

## CC:Tweaked Emulators

For full testing with real CC:Tweaked APIs, use an emulator:

### CraftOS-PC (Recommended)

A standalone CC:Tweaked emulator that runs on your desktop.

**Installation:**

- Download from: https://www.craftos-pc.cc/
- Available for Windows, Mac, Linux

**Usage:**

1. Launch CraftOS-PC
2. Mount your scripts folder:
    ```
    mount scripts /path/to/scripts/tomfoolery
    ```
3. Run your scripts as if on a real turtle

**Features:**

- Full CC:Tweaked API support
- Multiple computer/turtle windows
- Peripheral emulation
- Screenshot and recording

### Copy-Cat (Web-Based)

Browser-based emulator - no installation needed.

- URL: https://copy-cat.squiddev.cc/
- Paste code directly into the editor
- Good for quick tests

---

## VS Code Integration

### Lua Language Server

Install the Lua extension for syntax checking and IntelliSense:

1. Install extension: `sumneko.lua`
2. Create `.vscode/settings.json`:

```json
{
	"Lua.runtime.version": "Lua 5.2",
	"Lua.diagnostics.globals": [
		"turtle",
		"fs",
		"http",
		"os",
		"term",
		"shell",
		"rednet",
		"peripheral",
		"gps",
		"colors",
		"colours",
		"keys",
		"textutils",
		"parallel",
		"redstone",
		"sleep",
		"write",
		"print",
		"printError",
		"read"
	],
	"Lua.workspace.library": ["docs/cc-tweaked/stub"]
}
```

This tells the Lua extension about CC:Tweaked global APIs.

### Pre-commit Syntax Check

Create a script to check all files before committing:

**check-syntax.ps1** (PowerShell):

```powershell
$errors = 0
Get-ChildItem -Path scripts/tomfoolery -Filter "*.lua" -Recurse | ForEach-Object {
    $result = & luac -p $_.FullName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR in $($_.FullName):" -ForegroundColor Red
        Write-Host $result
        $errors++
    }
}
if ($errors -eq 0) {
    Write-Host "All files OK!" -ForegroundColor Green
} else {
    Write-Host "$errors file(s) with errors" -ForegroundColor Red
    exit 1
}
```

**check-syntax.sh** (Bash):

```bash
#!/bin/bash
errors=0
for file in $(find scripts/tomfoolery -name "*.lua"); do
    if ! luac -p "$file" 2>&1; then
        echo "ERROR in $file"
        ((errors++))
    fi
done
if [ $errors -eq 0 ]; then
    echo "All files OK!"
else
    echo "$errors file(s) with errors"
    exit 1
fi
```

---

## Common Errors

### "unexpected symbol near '...'"

**Cause:** Using `...` (varargs) inside a regular function instead of at file scope.

**Wrong:**

```lua
local function parseArgs()
    local args = { ... }  -- ERROR: ... not available here
end
```

**Correct:**

```lua
local tArgs = { ... }  -- Capture at file scope

local function parseArgs()
    local args = tArgs  -- Use the captured table
end
```

### "attempt to index global 'turtle' (a nil value)"

**Cause:** Running script outside of CC:Tweaked environment.

**Solution:** Use an emulator or create mock APIs (see above).

### "module 'xxx' not found"

**Cause:** `require()` can't find the module.

**Explanation:** In CC:Tweaked, `require()` resolves paths relative to the **running script's directory**, not the current working directory. If you run `mining/smart_miner.lua`, it will look for `mining/common/movement.lua` instead of `common/movement.lua`.

**Solutions:**

1. **Run scripts from the root directory:**

    ```
    -- CORRECT
    mining/smart_miner 50

    -- WRONG (don't cd into subdirectories)
    cd mining
    smart_miner 50
    ```

2. **Add path setup boilerplate** to scripts in subdirectories:

    ```lua
    local function setupPaths()
        local scriptPath = shell.getRunningProgram()
        local scriptDir = scriptPath:match("(.*/)" ) or ""
        local rootDir = scriptDir:match("(.*/)[^/]+/$") or ""
        package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path
    end
    setupPaths()
    ```

3. Check file exists at the expected path
4. Check `package.path` includes your directories

### "too long without yielding"

**Cause:** Long loop without any yielding operation.

**Solution:** Add `sleep(0)` or `os.pullEvent()` in long loops:

```lua
for i = 1, 10000 do
    doWork()
    if i % 100 == 0 then
        sleep(0)  -- Yield to prevent timeout
    end
end
```

---

## Quick Reference

| Task            | Command                                                             |
| --------------- | ------------------------------------------------------------------- |
| Check syntax    | `luac -p file.lua`                                                  |
| Check all files | `Get-ChildItem -Recurse -Filter *.lua \| % { luac -p $_.FullName }` |
| Run with mocks  | `lua -e "dofile('test/mock.lua')" yourscript.lua`                   |
| Full emulation  | Use CraftOS-PC                                                      |

---

## Recommended Workflow

1. **Write code** in VS Code with Lua extension
2. **Check syntax** with `luac -p` before committing
3. **Test logic** in CraftOS-PC emulator
4. **Deploy** via installer to real turtle
5. **Debug** in-game if needed

This catches most errors before you're underground with a stuck turtle!
