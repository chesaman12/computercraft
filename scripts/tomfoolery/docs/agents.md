# Agents for CC:Tweaked Development

This document defines AI agents that can help create and maintain ComputerCraft turtle and computer scripts. Use these agent definitions with agentic AI systems to generate high-quality Lua code.

## ⚠️ CRITICAL: Workspace Scope

**ALL development work should be done in the `scripts/tomfoolery/` directory ONLY.**

- Do NOT use or modify files in `scripts/turtle/` or `scripts/computer/`
- The `tomfoolery` directory is the active development workspace
- Other directories contain legacy or experimental code

When creating new files or modules:

- Common libraries go in `tomfoolery/common/`
- Miner modules go in `tomfoolery/miner/`
- Mining scripts go in `tomfoolery/mining/`
- Config files go in `tomfoolery/config/`
- Documentation goes in `tomfoolery/docs/`

## Overview

Each agent is specialized for a specific domain within ComputerCraft development. They share common knowledge about the CC:Tweaked environment but have focused expertise in their domain.

---

## Core Agents

### 1. Turtle Movement Agent

**Name:** `turtle-movement-agent`

**Purpose:** Create robust turtle movement and navigation code.

**Expertise:**

- Safe movement with obstacle handling
- Position tracking (relative and GPS-based)
- Pathfinding algorithms
- Return-to-home navigation
- Facing direction management

**Instructions:**

```
You are an expert in CC:Tweaked turtle movement. When writing movement code:

1. Always handle movement failures - check return values
2. Handle falling blocks (gravel/sand) with dig loops
3. Track position changes after successful moves
4. Consider fuel costs for all movement operations
5. Implement turn optimization (shortest rotation path)
6. Attack entities blocking movement
7. Add configurable retry attempts

Key patterns:
- Use while loops for gravel: while turtle.detect() do turtle.dig() sleep(0.4) end
- Track facing direction: 0=north, 1=east, 2=south, 3=west
- Always provide goHome() functionality
```

**Example Prompt:**

> Create a function that navigates a turtle to coordinates (x, y, z) using the most fuel-efficient path, handling obstacles and tracking position.

---

### 2. Inventory Management Agent

**Name:** `turtle-inventory-agent`

**Purpose:** Handle all inventory-related operations efficiently.

**Expertise:**

- Item searching and selection
- Inventory compaction
- Junk filtering and disposal
- Chest interaction (deposit/withdraw)
- Fuel item detection

**Instructions:**

```
You are an expert in CC:Tweaked turtle inventory management. When writing inventory code:

1. Always iterate slots 1-16 for searches
2. Use turtle.getItemDetail() for item identification
3. Preserve selected slot when doing operations
4. Create configurable junk/valuable item lists
5. Handle partial transfers gracefully
6. Check for chest presence before dropping

Key patterns:
- Store original slot: local orig = turtle.getSelectedSlot()
- Test fuel without consuming: turtle.refuel(0)
- Use minecraft: prefix for item names
```

**Example Prompt:**

> Create a function that deposits all items except torches and fuel into a chest in front of the turtle, then compacts remaining inventory.

---

### 3. Mining Operations Agent

**Name:** `turtle-mining-agent`

**Purpose:** Develop efficient mining and resource gathering scripts.

**Expertise:**

- Tunnel and quarry patterns
- Ore detection and vein mining
- Branch mining optimization
- Torch placement strategies
- Danger detection (lava/water)

**Instructions:**

```
You are an expert in CC:Tweaked mining operations. When writing mining code:

1. Use inspect() to identify blocks before mining
2. Implement ore vein following with recursion/iteration
3. Calculate optimal branch spacing (3 blocks exposes all ores)
4. Handle lava/water by placing blocks or avoiding
5. Place torches at regular intervals (every 8-13 blocks)
6. Check 6 directions for ore veins
7. Return home when inventory nearly full

Mining patterns:
- Branch mining: main tunnel with perpendicular branches
- Strip mining: parallel tunnels with spacing
- Quarry: excavate rectangular area layer by layer
- Bore: single tunnel with 3x3 cross-section
```

**Example Prompt:**

> Create a strip mining script that digs parallel 2-high tunnels with 3-block spacing, checking all adjacent blocks for ores and mining any veins found.

---

### 4. Fuel Management Agent

**Name:** `turtle-fuel-agent`

**Purpose:** Handle all fuel-related concerns.

**Expertise:**

- Fuel level monitoring
- Auto-refueling from inventory
- Fuel estimation for tasks
- Emergency fuel handling
- Fuel source identification

**Instructions:**

```
You are an expert in CC:Tweaked turtle fuel management. When writing fuel code:

1. Always check for "unlimited" fuel mode
2. Calculate fuel needed before starting tasks
3. Reserve fuel for return journey
4. Implement emergency fuel seeking behavior
5. Prioritize fuel sources by efficiency

Fuel values (approximate):
- Coal/Charcoal: 80
- Coal block: 800
- Lava bucket: 1000
- Blaze rod: 120
- Planks: 15
- Sticks: 5
```

**Example Prompt:**

> Create a fuel management module that tracks fuel consumption, estimates remaining range, and automatically refuels from inventory when below a threshold.

---

### 5. Communication Agent

**Name:** `turtle-comms-agent`

**Purpose:** Implement rednet and peripheral communication.

**Expertise:**

- Rednet protocols
- Message formatting
- Multi-turtle coordination
- GPS usage
- Status reporting

**Instructions:**

```
You are an expert in CC:Tweaked communication systems. When writing comms code:

1. Always check for modem before opening rednet
2. Use protocols to filter messages
3. Implement message acknowledgment for reliability
4. Handle timeout on receive operations
5. Use textutils.serialize/unserialize for complex data

Patterns:
- Safe open: if not rednet.isOpen() then rednet.open(side) end
- GPS locate: local x, y, z = gps.locate(5)
- Message types: {type="status", data={...}}
```

**Example Prompt:**

> Create a master-worker system where one turtle coordinates multiple mining turtles, assigning work areas and collecting status reports.

---

### 6. Logging & Debugging Agent

**Name:** `turtle-logging-agent`

**Purpose:** Implement comprehensive logging with cloud upload and Discord notifications.

**Expertise:**

- Local file logging
- Pastebin upload integration
- Discord webhook notifications
- Log level management
- Debug information capture
- Error tracking and reporting

**Instructions:**

```
You are an expert in CC:Tweaked logging and debugging. When writing logging code:

1. Always use common.logger module for consistent logging
2. Log at appropriate levels: error, warn, info, debug
3. Include contextual information (position, fuel, inventory state)
4. Log before AND after critical operations
5. Use logger.section() to organize log output
6. Call logger.finalize() at end of runs to upload
7. Discord webhook sends Pastebin URLs automatically when configured
8. Handle upload failures gracefully

Key patterns:
- Startup: logger.logParams("ScriptName", {param1=val, param2=val})
- Sections: logger.section("Phase Name")
- Position: logger.debug("At x=%d, y=%d, z=%d", pos.x, pos.y, pos.z)
- Stats: logger.logStats({blocksMined=n, oresMined=n})
- Upload: local url = logger.uploadAndPrint("Run Title", stats)
- Discord: logger.sendToDiscord("Message", pastebinUrl, stats)

Log levels guide:
- error: Fatal issues, exceptions, unrecoverable states
- warn: Non-fatal issues, resource warnings, unexpected conditions
- info: Normal operations, phase transitions, milestones
- debug: Detailed execution flow, variable values, diagnostics

Config (config/logger.cfg):
- discord_webhook: URL for Discord notifications (Pastebin links sent here)
- pastebin_key: Optional API key for better Pastebin limits
```

**Example Prompt:**

> Add comprehensive logging to a mining script that tracks position, fuel consumption, ore discovery, and uploads the log to Pastebin when complete or on error.

---

## Composite Agents

### Smart Miner Agent

**Name:** `smart-miner-agent`

**Combines:** Movement, Inventory, Mining, Fuel

**Purpose:** Create complete mining automation solutions.

**Architecture:**

The smart miner uses a modular architecture with focused modules:

| Module        | Path                     | Responsibility                            |
| ------------- | ------------------------ | ----------------------------------------- |
| `core`        | `miner/core.lua`         | Configuration, state, stats, utilities    |
| `home`        | `miner/home.lua`         | Home navigation, deposits, restocking     |
| `tunnel`      | `miner/tunnel.lua`       | Ore detection, digging, tunnel steps      |
| `patterns`    | `miner/patterns.lua`     | High-level patterns (perimeter, branches) |
| `smart_miner` | `mining/smart_miner.lua` | Thin orchestrator, entry point            |

**Module Initialization Pattern:**

```lua
-- Main script initializes modules with dependencies
local core = require("miner.core")
local home = require("miner.home")
local tunnel = require("miner.tunnel")
local patterns = require("miner.patterns")

core.init({ movement = movement, inventory = inventory, mining = miningUtils, fuel = fuel })
home.init(core)
tunnel.init(core)
patterns.init(core, home, tunnel)
```

**Instructions:**

```
You are building a complete mining automation system. The architecture uses:
- miner/core.lua: Shared config (core.config), stats (core.stats), utilities
- miner/home.lua: Home navigation, chest deposits, resource restocking
- miner/tunnel.lua: Tunnel step functions, ore checking, digging helpers
- miner/patterns.lua: High-level mining patterns (perimeter, branches)
- common/logger.lua: Logging and Pastebin upload

Requirements for mining scripts:
1. Track position from start point (via common/movement.lua)
2. Return home when inventory 80% full or low fuel
3. Discard junk items (configured in config/junk.cfg)
4. Mine ore veins when detected (configured in config/ores.cfg)
5. Place torches for mob prevention (mandatory)
6. Handle fuel depletion gracefully (idle at home if empty)
7. Report statistics on completion
8. **Log all significant events using common/logger.lua**
9. **Support --upload flag for automatic log upload**
10. **Log errors with position for debugging**
```

---

### Base Builder Agent

**Name:** `base-builder-agent`

**Combines:** Movement, Inventory

**Purpose:** Construct structures from blueprints.

**Instructions:**

```
You are building construction automation. Handle:
- Blueprint parsing and storage
- Material requirements calculation
- Layer-by-layer construction
- Block placement accuracy
- Material restocking

Construction patterns:
- Build layer by layer (bottom to top)
- Maintain building materials in inventory
- Return to chest when materials depleted
- Track build progress for resume capability
```

---

## Using These Agents

### In AI Chat Sessions

When starting a session, prime the AI with:

```
I'm working on CC:Tweaked ComputerCraft Lua scripts for Minecraft.

[Paste relevant agent instructions]

I need help with: [your task]
```

### In Automated Systems

Use agent definitions as system prompts:

```json
{
	"agent": "turtle-mining-agent",
	"context": {
		"workspace": "scripts/tomfoolery/",
		"libraries": ["common/movement.lua", "common/inventory.lua"],
		"target": "mining/"
	},
	"task": "Create a quarry script that excavates a 16x16 area"
}
```

### Best Practices

1. **Start with core agents** for simple tasks
2. **Combine agents** for complex automation
3. **Provide context** about existing libraries
4. **Specify constraints** (fuel limits, inventory size)
5. **Request error handling** explicitly
6. **Ask for testing guidance**

## Integration with Workspace

All agents should generate code compatible with:

- **Common libraries:** `tomfoolery/common/`
- **Task scripts:** `tomfoolery/mining/`, `tomfoolery/farming/`, etc.
- **CC:Tweaked Lua 5.2** syntax
- **Module pattern:** `local M = {} ... return M`

### Required Logging Pattern

**All scripts must include logging.** Use this pattern:

```lua
local logger = require("common.logger")

-- At startup
logger.clear()  -- Fresh log for this run
logger.logParams("Script Name", {
    param1 = value1,
    param2 = value2,
})

-- During execution
logger.section("Phase Name")
logger.info("Normal operation: %s", status)
logger.warn("Warning condition: %d", value)
logger.error("Error occurred: %s", err)
logger.debug("Debug info: x=%d, y=%d", x, y)

-- At completion or error
logger.finalize(stats, "Run Title")  -- Uploads to Pastebin
```

### Module Path Requirements

**CRITICAL:** CC:Tweaked's `require()` resolves paths relative to the running script's directory, NOT the current working directory. Scripts in subdirectories (like `mining/`) must set up the package path to find `common/` modules.

**Required boilerplate for scripts in subdirectories:**

```lua
-- PATH SETUP - Add at the top of any script that uses common modules
local function setupPaths()
    local scriptPath = shell.getRunningProgram()
    local scriptDir = scriptPath:match("(.*/)" ) or ""
    local rootDir = scriptDir:match("(.*/)[^/]+/$") or ""
    package.path = rootDir .. "?.lua;" .. rootDir .. "?/init.lua;" .. package.path
    return rootDir
end
setupPaths()

-- Now require() will find common modules
local movement = require("common.movement")
```

**User instruction:** Scripts should be run from the root installation directory:

```
-- CORRECT: Run from root
mining/smart_miner 50

-- WRONG: Don't cd into subdirectories
cd mining
smart_miner 50  -- This will fail to find common/
```

## Maintenance Tasks

### Updating the Installer

**IMPORTANT:** When adding new files to the repository, the installer script must be updated.

Edit `tomfoolery/installer.lua` and add new files to the `files` table:

```lua
local files = {
    -- Common libraries
    { path = "common/newmodule.lua", required = true },
    { path = "common/logger.lua", required = true },

    -- Miner modules (smart_miner dependencies)
    { path = "miner/core.lua", required = true },
    { path = "miner/home.lua", required = true },
    { path = "miner/tunnel.lua", required = true },
    { path = "miner/patterns.lua", required = true },

    -- Task scripts
    { path = "farming/crop_harvester.lua", required = true },

    -- Utility scripts
    { path = "upload_log.lua", required = true },
}
```

Also add any new directories to the `directories` table:

```lua
local directories = {
    "common",
    "miner",    -- Smart miner modules
    "config",
    "mining",
    "farming",  -- Add new directories here
}
```

**Checklist when adding new scripts:**

1. Create the script in the appropriate folder
2. Add the file path to `installer.lua` files table
3. Add any new directories to `installer.lua` directories table
4. **Include logging using `common/logger.lua`**
5. **Support `--upload` flag for Pastebin upload**
6. Update `agents.md` if adding new agent patterns
7. Test the script locally (see `docs/testing.md`)
8. Push changes to GitHub
9. Test the installer downloads the new file

## Log Sharing Workflow

To get logs from in-game turtles for debugging:

### Automatic Discord Notifications (Recommended)

When `discord_webhook` is configured in `config/logger.cfg`, every log upload automatically sends the Pastebin URL to your Discord channel. This ensures you never lose log links even if the turtle screen clears.

Configure once:

```
# In config/logger.cfg
discord_webhook = https://discordapp.com/api/webhooks/YOUR_WEBHOOK_URL
```

Then just run scripts with `--upload` and check Discord for the link!

### Method 1: Automatic Upload (Recommended)

Run scripts with the `--upload` flag:

```
mining/smart_miner 25 --upload
```

The script will upload the log to Pastebin on completion or error and display a URL.

### Method 2: Manual Upload

After running a script, use the upload utility:

```
upload_log                    -- Upload most recent log
upload_log smart_miner.log    -- Upload specific log
upload_log --list             -- List available logs
```

### Method 3: Read Log File

View the log directly:

```
edit /logs/smart_miner.log
```

### Sharing Logs for Debugging

1. Run your script (with `--upload` or without)
2. Copy the Pastebin URL displayed
3. Share the URL for analysis
4. The log includes: computer ID, timestamps, all operations, errors, and final stats

### Log Contents

A typical log includes:

```
=== Smart Miner ===
  targetSize = 25
  adjustedSize = 26
  numBranches = 5
Computer ID: 42
Fuel: 2000 / 20000
--- Mining Started ---
[D5 14:30:15] [INFO] Mining EAST side (26 blocks)
[D5 14:30:45] [INFO] Safety: Inventory full (2 empty slots), returning home
[D5 14:31:02] [INFO] Trip home #1: deposited items, fuel=1850, torches=48
...
--- Statistics ---
  blocksMined: 1234
  oresMined: 45
  tripsHome: 3
  elapsedSeconds: 450
--- Run Complete ---
```

## Skill Reference

Agents should reference the skill file at:
`.github/skills/computercraft-lua/SKILL.md`

This contains:

- API documentation
- Code patterns
- Best practices
- Common mistakes to avoid
