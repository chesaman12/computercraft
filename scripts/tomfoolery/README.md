# Tomfoolery - ComputerCraft Automation Scripts

A modular collection of CC:Tweaked Lua scripts for automating tasks in Minecraft.

## Directory Structure

```
tomfoolery/
├── common/           # Shared libraries and utilities
│   ├── movement.lua    # Turtle movement and navigation
│   ├── inventory.lua   # Inventory management and filtering
│   ├── mining.lua      # Mining utilities and ore detection
│   └── fuel.lua        # Fuel management
│
├── mining/           # Mining automation scripts
│   ├── smart_miner.lua # Advanced branch mining with ore detection
│   ├── basicActions.lua     # (Legacy) Basic digging actions
│   ├── basicTurtleCommands.lua # (Legacy) Turtle command wrappers
│   └── miningTunnel.lua     # (Legacy) Simple tunnel script
│
├── docs/             # Documentation
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

An advanced branch mining script that:

- Creates efficient branch mine patterns (3-block spacing exposes all ores)
- Tracks position and returns home when inventory is full
- Deposits items in a chest at start position
- Detects and follows ore veins
- Manages fuel automatically
- Discards junk blocks (cobblestone, dirt, gravel)

**Usage:**

```
smart_miner <length> [branches] [spacing]

  length   - How far each branch extends (default: 50)
  branches - Number of branches on each side (default: 5)
  spacing  - Blocks between branches (default: 3)
```

**Setup:**

1. Place turtle at desired mining level (Y=11 for diamonds in old worlds, Y=-59 for deepslate diamonds)
2. Place a chest behind the turtle for deposits
3. Add fuel to turtle inventory
4. Optionally add torches to slot 16
5. Run: `smart_miner 50 10`

## Using the Libraries

From any script in the tomfoolery folder:

```lua
-- Add package path for common libraries
package.path = package.path .. ";/tomfoolery/?.lua"

-- Load modules
local movement = require("common.movement")
local inventory = require("common.inventory")
local mining = require("common.mining")
local fuel = require("common.fuel")

-- Your code here
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

Create scripts in appropriate folders:

```lua
-- mining/my_miner.lua
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
