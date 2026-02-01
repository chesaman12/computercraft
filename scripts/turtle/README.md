# Turtle Scripts

A collection of CC:Tweaked turtle automation scripts organized into categories with shared modules.

> **Note:** This is the `turtle-overhaul` branch for testing. Once merged to main, update the installer URL below to use `main` instead of `turtle-overhaul`.

## Installation

On your turtle, run:

```
wget https://raw.githubusercontent.com/chesaman12/computercraft/turtle-overhaul/scripts/turtle/installer.lua installer
installer
```

## Usage

After installation, run `startup` to see the interactive menu, or run scripts directly:

```
mining/strip_miner
building/block
utility/move
```

## Structure

```
/turtle/
├── installer.lua      <- Downloads all files
├── startup.lua        <- Interactive menu
│
├── common/            <- Shared modules
│   ├── init.lua       <- Path resolution
│   ├── fuel.lua       <- Fuel management
│   ├── movement.lua   <- Movement utilities
│   ├── inventory.lua  <- Inventory management
│   └── input.lua      <- User input helpers
│
├── building/          <- Construction scripts
│   ├── block.lua      <- Build rectangular blocks
│   ├── wall.lua       <- Build perimeter walls
│   └── house.lua      <- Build complete house
│
├── mining/            <- Mining scripts
│   ├── dig.lua        <- Excavate rectangular area
│   ├── simple_miner.lua  <- 3D mining with torch placement
│   ├── stair_miner.lua   <- Staircase mining
│   └── strip_miner.lua   <- Ladder-pattern strip mining
│
└── utility/           <- Utility scripts
    ├── move.lua       <- Simple movement
    ├── refuel.lua     <- Refuel from inventory
    └── lava_refuel.lua <- Refuel using lava bucket
```

## Scripts

### Building Scripts

| Script | Description |
|--------|-------------|
| `building/block` | Creates a filled rectangular block. Place materials in slots 1-14. |
| `building/wall` | Creates a perimeter wall. Place materials in slots 1-14. |
| `building/house` | Builds a complete house with floor, walls, roof, and door. |

### Mining Scripts

| Script | Description |
|--------|-------------|
| `mining/dig` | Excavates a rectangular volume (length x width x depth). |
| `mining/simple_miner` | Mines a 3D area with optional torch placement. |
| `mining/stair_miner` | Mines in an alternating staircase pattern. |
| `mining/strip_miner` | Creates main corridor with side branches for ore exposure. |

### Utility Scripts

| Script | Description |
|--------|-------------|
| `utility/move` | Move the turtle in any direction by a specified distance. |
| `utility/refuel` | Refuel from all fuel items in inventory. |
| `utility/lava_refuel` | Refuel using lava bucket from tank below. |

## Shared Modules

The `common/` folder contains reusable modules:

- **fuel.lua** - Fuel checking, refueling, lava refueling
- **movement.lua** - Safe movement, digging through gravel/sand
- **inventory.lua** - Slot management, junk filtering
- **input.lua** - User input validation (numbers, yes/no, choices)

## Installer Commands

```
installer          # Install all files
installer update   # Re-download all files  
installer remove   # Uninstall everything
installer help     # Show usage
```

## Requirements

- CC:Tweaked 1.109.0+ (uses Lua 5.2 features)
- HTTP API enabled (for installer)
