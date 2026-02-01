# Turtle Capabilities Analysis

This document provides a comprehensive overview of what CC:Tweaked turtles can do and what can be automated through scripting.

## What is a Turtle?

A turtle is a programmable robot in the ComputerCraft/CC:Tweaked Minecraft mod. It runs Lua scripts and can move through the world, interact with blocks and entities, and communicate with other computers.

## Core Capabilities

### 1. Movement (Requires Fuel)

Turtles can move in 6 directions:

- **Forward/Back**: Move horizontally in facing direction
- **Up/Down**: Move vertically
- **Turn Left/Right**: Rotate 90 degrees (no fuel cost)

**Fuel System:**

- Most turtles require fuel to move (configurable by server)
- Common fuel sources: coal, charcoal, lava buckets, blaze rods
- 1 coal = 80 fuel units = 80 movements
- Creative turtles have unlimited fuel

**Movement Limitations:**

- Cannot move through solid blocks (must dig first)
- Cannot move into unloaded chunks
- Movement can be blocked by entities (mobs, players)
- Bedrock and some protected blocks cannot be broken

### 2. Block Interaction

**Digging (Mining):**

- `dig()`, `digUp()`, `digDown()` - Mine blocks
- Handles falling blocks (gravel/sand) automatically with loops
- Cannot mine bedrock or some mod-protected blocks
- Requires appropriate tool for some blocks (e.g., pickaxe for obsidian)

**Placing:**

- `place()`, `placeUp()`, `placeDown()` - Place blocks from inventory
- Can place most placeable blocks
- Orientation matters for directional blocks

**Block Detection:**

- `detect()`, `detectUp()`, `detectDown()` - Check if block exists
- `inspect()`, `inspectUp()`, `inspectDown()` - Get block details (name, metadata)
- `compare()` - Compare block to selected inventory slot

### 3. Inventory Management

Turtles have **16 inventory slots**:

- `select(slot)` - Select active slot (1-16)
- `getItemCount(slot)` - Count items in slot
- `getItemDetail(slot)` - Get item name, count, metadata
- `transferTo(slot, count)` - Move items between slots
- `drop()`, `dropUp()`, `dropDown()` - Drop items into world/chests
- `suck()`, `suckUp()`, `suckDown()` - Pick up items/take from chests

### 4. Entity Interaction

- `attack()`, `attackUp()`, `attackDown()` - Attack entities
- Useful for mob farms and automated defense
- Can collect drops after killing

### 5. Crafting (Crafty Turtles Only)

- `craft(count)` - Craft items using 3x3 grid in inventory
- Slots 1-3, 5-7, 9-11 form the crafting grid
- Other slots must be empty or contain the output

### 6. Equipment

Turtles can have tools equipped:

- **Mining Turtles**: Have pickaxe, can mine any block
- **Melee Turtles**: Have sword, deal more attack damage
- **Farming Turtles**: Have hoe, can till soil
- **Felling Turtles**: Have axe, efficient at wood

Advanced turtles can have tools on both sides.

## Communication Capabilities

### Rednet (Wireless Networking)

With a wireless modem:

- `rednet.send(id, message, protocol)` - Send to specific computer
- `rednet.broadcast(message, protocol)` - Send to all computers
- `rednet.receive(protocol, timeout)` - Wait for messages
- `rednet.host(protocol, hostname)` - Register as DNS name

**Use Cases:**

- Coordinating multiple turtles
- Remote control systems
- Status reporting to base
- GPS positioning

### GPS System

- `gps.locate(timeout)` - Get world coordinates (requires GPS network)
- Enables absolute positioning for navigation
- Requires 4+ GPS host computers in range

## Peripheral Integration

Turtles can interact with peripherals:

- **Modems**: Wireless/wired communication
- **Monitors**: Display output remotely
- **Inventories**: Automated storage systems
- **Redstone**: Control redstone signals

## What Can Be Scripted

### Automation Tasks

| Task               | Difficulty | Description                          |
| ------------------ | ---------- | ------------------------------------ |
| **Mining**         | Easy       | Dig tunnels, quarries, branch mines  |
| **Tree Farming**   | Easy       | Chop and replant trees               |
| **Crop Farming**   | Medium     | Plant, harvest, replant crops        |
| **Mob Farming**    | Medium     | Kill mobs and collect drops          |
| **Building**       | Medium     | Construct structures from blueprints |
| **Sorting**        | Easy       | Organize items into chests           |
| **Item Transport** | Easy       | Move items between locations         |
| **Strip Mining**   | Medium     | Efficient ore exposure patterns      |
| **Tunnel Boring**  | Medium     | Create transportation tunnels        |
| **Wall Building**  | Easy       | Construct walls and barriers         |

### Advanced Automation

| Task                   | Difficulty | Description                        |
| ---------------------- | ---------- | ---------------------------------- |
| **Swarm Mining**       | Hard       | Multiple turtles working together  |
| **Blueprint Building** | Hard       | Complex structure construction     |
| **Self-Replication**   | Expert     | Turtles that build more turtles    |
| **Automated Bases**    | Expert     | Full base automation systems       |
| **GPS Networks**       | Medium     | Self-maintaining GPS constellation |

## Scripting Patterns

### Essential Patterns Every Script Should Use

1. **Fuel Management**: Always check fuel before operations
2. **Error Handling**: Check return values of all turtle functions
3. **Position Tracking**: Track location for return-home capability
4. **Inventory Management**: Handle full inventory gracefully
5. **Gravel/Sand Handling**: Loop dig operations for falling blocks

### Sample Script Structure

```lua
-- Load libraries
local movement = require("common.movement")
local inventory = require("common.inventory")
local fuel = require("common.fuel")

-- Configuration
local CONFIG = {
    -- parameters here
}

-- State tracking
local state = {
    position = {x=0, y=0, z=0},
    -- more state
}

-- Main work function
local function doWork()
    -- Implement task
end

-- Safety wrapper
local function main()
    -- Check prerequisites
    if not fuel.hasEnough(estimatedDistance) then
        fuel.waitForFuel(needed)
    end

    -- Do work with error handling
    local success, err = pcall(doWork)

    -- Always try to return home
    movement.goHome(true)

    if not success then
        printError(err)
    end
end

main()
```

## Limitations and Considerations

### Cannot Do

- Move through unloaded chunks (chunk loading required)
- Break bedrock or world-protected blocks
- Move faster than 1 block per tick (0.05 seconds)
- Act while chunk is unloaded
- Have more than 16 inventory slots
- See entities without attacking/collision

### Performance Considerations

- Minimum 0.05 second delay between movements
- Large operations need chunk loaders
- Network messages have size limits
- Complex scripts may need yielding (`sleep(0)`)

### Multiplayer Considerations

- Chunk loading affects turtle operation
- Protection mods may block turtle actions
- Server lag affects response times

## Recommended Script Categories

Based on capabilities, organize scripts into:

1. **common/** - Shared libraries (movement, inventory, fuel, mining utilities)
2. **mining/** - Resource gathering scripts
3. **farming/** - Crop and tree automation
4. **building/** - Construction scripts
5. **transport/** - Item moving and sorting
6. **utility/** - Helper programs (GPS, refuel, etc.)

## Getting Started

1. Place turtle and add fuel
2. Run `edit startup` to create boot script
3. Use `require()` to load common libraries
4. Test movement and basic operations
5. Build up to complex automation

## Resources

- Official Wiki: https://tweaked.cc/
- API Reference: `docs/cc-tweaked/`
- Example Scripts: `scripts/turtle/`
