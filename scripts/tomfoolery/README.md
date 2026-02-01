# Tomfoolery - ComputerCraft Automation Scripts

A modular collection of CC:Tweaked Lua scripts for automating tasks in Minecraft.

## Directory Structure

```
tomfoolery/
├── common/           # Shared libraries and utilities
│   ├── movement.lua    # Turtle movement and navigation
│   ├── inventory.lua   # Inventory management and filtering
│   ├── mining.lua      # Mining utilities and ore detection
│   ├── fuel.lua        # Fuel management
│   └── config.lua      # Configuration file loader
│
├── miner/            # Smart miner modules
│   ├── core.lua        # Configuration, state, statistics
│   ├── home.lua        # Home navigation, deposits, restocking
│   ├── tunnel.lua      # Tunnel step functions, ore checking
│   └── patterns.lua    # Mining patterns (perimeter, branches)
│
├── config/           # Configuration files
│   ├── ores.cfg        # Ore block IDs to detect and mine
│   └── junk.cfg        # Junk block IDs to discard
│
├── mining/           # Mining automation entry points
│   └── smart_miner.lua # Advanced branch mining with ore detection
│
├── docs/             # Documentation
│   ├── gameplay_guide.md   # In-game setup and usage guide
│   ├── turtle_capabilities.md  # What turtles can do
│   └── agents.md              # AI agent definitions for development
│
└── README.md         # This file
```

## Common Libraries

### movement.lua

Position-tracking movement with obstacle handling.

```lua
local movement = require("common.movement")

-- Move with position tracking
movement.forward(true)  -- dig obstacles
movement.up(false)      -- don't dig, fail if blocked

-- Navigate to coordinates
movement.goTo(10, -5, 20, true)

-- Return to start position
movement.goHome(true)
```

### inventory.lua

Inventory management with junk filtering.

```lua
local inventory = require("common.inventory")

-- Check inventory state
if inventory.isFull() then
    inventory.dropJunk()  -- Drop cobblestone, dirt, etc.
end

-- Find and select items
if inventory.selectItem("minecraft:torch") then
    turtle.place()
end

-- Auto-refuel from inventory
inventory.autoRefuel(1000)
```

### mining.lua

Mining utilities and ore detection.

```lua
local mining = require("common.mining")

-- Safe digging (handles gravel/sand)
mining.digForward()

-- Ore detection
local block = mining.inspectForward()
if mining.isOre(block) then
    mining.digForward()
end

-- Place torch
mining.placeTorch("up")
```

### fuel.lua

Fuel management and monitoring.

```lua
local fuel = require("common.fuel")

-- Check fuel status
if fuel.isLow(100) then
    fuel.autoRefuel(500)
end

-- Estimate return fuel
local needed = fuel.estimateReturnFuel(movement.getPosition())
```

## Mining Scripts

### smart_miner.lua

An advanced square perimeter mining script that:

- Mines a square perimeter, then fills with parallel branch tunnels
- Auto-adjusts size for proper spacing (3 blocks between edges/branches)
- Uses pokehole mining (wiki-recommended) for optimal ore exposure
- Tracks position and returns home when inventory is full or fuel is low
- Deposits items in a chest at start position
- Detects and follows ore veins
- Manages fuel automatically (idles at home if empty)
- Discards junk blocks (cobblestone, dirt, gravel)
- Places torches at regular intervals (mandatory)

**Architecture:**

The smart miner uses a modular design:

- `miner/core.lua` - Configuration, state, statistics
- `miner/home.lua` - Home navigation, deposits, restocking
- `miner/tunnel.lua` - Tunnel step functions, ore checking
- `miner/patterns.lua` - Mining patterns (perimeter, branches)
- `mining/smart_miner.lua` - Entry point orchestrator

**Usage:**

```
mining/smart_miner <size> [spacing]

  size    - Target square size (auto-adjusted for proper spacing, default: 25)
  spacing - Blocks between branches (default: 3)
```

**Setup:**

1. Place turtle at desired mining level (Y=11 for diamonds in old worlds, Y=-59 for deepslate diamonds)
2. Place a chest behind the turtle for deposits
3. Add fuel to turtle inventory
4. Add torches to slot 16 (required)
5. Run: `mining/smart_miner 25`

For detailed in-game setup instructions, see [docs/gameplay_guide.md](docs/gameplay_guide.md).

## Configuration Files

The `config/` folder contains editable configuration files:

### config/ores.cfg

List of ore block IDs that the turtle will detect and mine. One block ID per line.

```
-- Vanilla ores (enabled by default)
minecraft:diamond_ore
minecraft:deepslate_diamond_ore

-- Modded ores (uncomment to enable)
-- create:zinc_ore
-- mekanism:osmium_ore
```

### config/junk.cfg

List of junk block IDs that the turtle will discard. One block ID per line.

```
minecraft:cobblestone
minecraft:dirt
minecraft:gravel
```

### Finding Block IDs

To find a block's ID for configuration:

1. Face the turtle toward the block
2. Open Lua interpreter: `lua`
3. Run: `turtle.inspect()`
4. Look for the `name` field in the output

Or press F3 in-game and look at a block to see its ID.

## Running Scripts

**Important:** Always run scripts from the tomfoolery root directory, not from subdirectories.

```bash
# CORRECT - Run from tomfoolery root:
cd /tomfoolery
mining/smart_miner 50

# WRONG - Don't cd into subdirectories:
cd /tomfoolery/mining
smart_miner 50   -- This will cause "module not found" errors!
```

This is because CC:Tweaked's `require()` resolves paths relative to the running script's location.

## Using the Libraries

Scripts in the root tomfoolery folder can use libraries directly:

```lua
-- Load modules
local movement = require("common.movement")
local inventory = require("common.inventory")
local mining = require("common.mining")
local fuel = require("common.fuel")
local config = require("common.config")

-- Your code here
```

Scripts in subdirectories (like `mining/`) need path setup. See the boilerplate in `smart_miner.lua`:

```lua
-- Path setup for scripts in subdirectories
local function setupPaths()
    local scriptPath = shell.getRunningProgram()
    local scriptDir = scriptPath:match("(.*/)" ) or ""
    local rootDir = scriptDir:match("(.*/)[^/]+/$") or ""
    package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path
    return rootDir
end
local ROOT_DIR = setupPaths()

-- Now require works normally
local movement = require("common.movement")
```

### Reloading Configuration

If you edit config files while the turtle is running:

```lua
local mining = require("common.mining")
local inventory = require("common.inventory")

-- Reload ore list
mining.reloadOres()

-- Reload junk list
inventory.reloadJunk()
```

## Extending the Library

### Adding New Modules

Create new module in `common/`:

```lua
-- common/mymodule.lua
local M = {}

function M.doSomething()
    -- Implementation
end

return M
```

### Creating Task Scripts

For scripts in the root folder:

```lua
-- tomfoolery/my_script.lua
local movement = require("common.movement")
local inventory = require("common.inventory")

local function main()
    -- Your logic
end

main()
```

For scripts in subdirectories (like `mining/`):

```lua
-- mining/my_miner.lua

-- Path setup (required for subdirectory scripts)
local function setupPaths()
    local scriptPath = shell.getRunningProgram()
    local scriptDir = scriptPath:match("(.*/)" ) or ""
    local rootDir = scriptDir:match("(.*/)[^/]+/$") or ""
    package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path
    return rootDir
end
local ROOT_DIR = setupPaths()

-- Now load modules normally
local movement = require("common.movement")
local inventory = require("common.inventory")

local function main()
    -- Your mining logic
end

main()
```

## Fuel Efficiency Tips

1. Coal: 80 fuel = 80 movements
2. Coal block: 800 fuel (most efficient)
3. Lava bucket: 1000 fuel
4. Branch mining at Y=11 or Y=-59 for diamonds

## Contributing

When adding new scripts:

1. Use the common libraries instead of direct turtle calls
2. Handle all error cases
3. Track position for return-home capability
4. Test fuel requirements before starting
5. Document usage in this README
