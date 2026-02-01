# Bot Gameplay Guide

This guide explains how to set up and use the turtle bots in-game. Each bot has its own section with setup instructions, configuration options, and expected behavior.

---

## Table of Contents

1. [General Setup](#general-setup)
2. [Installing Scripts](#installing-scripts)
3. [Smart Miner](#smart-miner)
4. [Troubleshooting](#troubleshooting)

---

## General Setup

### Requirements

All bots require:

- A **Mining Turtle** (turtle with pickaxe upgrade)
- **Fuel** (coal, charcoal, lava buckets, etc.)
- A **wireless modem** (optional, for GPS features)

### Fuel Basics

- Turtles need fuel to move (1 fuel = 1 block of movement)
- Coal provides 80 fuel, coal blocks provide 800
- Check fuel: `fuel` command or in-script display
- Refuel: Place fuel in inventory and run `refuel all`

---

## Installing Scripts

### Method 1: Installer Script (Recommended)

The easiest way to install all scripts at once:

```
wget https://raw.githubusercontent.com/chesaman12/computercraft/main/scripts/tomfoolery/installer.lua installer
installer
```

This downloads all common libraries, config files, and scripts automatically.

**Installer commands:**

```
installer          -- Install all files
installer update   -- Re-download all files
installer remove   -- Uninstall everything
```

### Method 2: Individual wget Downloads

Download specific files directly:

```
mkdir common
mkdir config
mkdir mining
wget https://raw.githubusercontent.com/YOUR_USER/computercraft/main/scripts/tomfoolery/common/movement.lua common/movement.lua
wget https://raw.githubusercontent.com/YOUR_USER/computercraft/main/scripts/tomfoolery/mining/smart_miner.lua mining/smart_miner.lua
```

### Method 3: Pastebin

If scripts are uploaded to Pastebin:

```
pastebin get XXXXXX smart_miner.lua
```

### Method 4: Disk Drive

For offline transfer or servers without HTTP:

1. Craft a **Disk Drive** and a **Floppy Disk**
2. Place the disk drive next to a computer with the scripts
3. Insert the floppy disk
4. Copy files to disk: `copy common disk/common`
5. Move the disk to the turtle's disk drive
6. Copy from disk: `copy disk/common common`

### Enabling HTTP on Your Server

HTTP must be enabled for wget/installer to work:

1. **Find the config file:**

    ```
    <server folder>/config/computercraft-server.toml
    ```

2. **Edit HTTP settings:**

    ```toml
    [http]
        enabled = true

    [[http.rules]]
        host = "*"
        action = "allow"
    ```

3. **Restart the server**

For older versions, edit `computercraft.cfg`:

```
http {
    B:enabled=true
}
```

---

## Smart Miner

**Script:** `mining/smart_miner.lua`

An advanced branch mining turtle that efficiently exposes ore faces and automatically returns to deposit items.

### Setup Instructions

#### Step 1: Position the Turtle

1. Dig down to your desired mining level:
    - **Y = 11**: Best for diamonds in worlds before 1.18
    - **Y = -59**: Best for deepslate diamonds in 1.18+ worlds
    - **Y = -53**: Good balance of diamond/redstone in 1.18+

2. Create a small room (at least 3x3) for the turtle's base

3. Place the turtle facing the direction you want it to mine

#### Step 2: Place the Deposit Chest

1. Place a **chest directly behind the turtle**
2. The turtle will return here to deposit items when inventory is full

```
     [Direction turtle faces →]

     [Chest] [Turtle] → → → (mining direction)
```

#### Step 3: Load Fuel and Supplies

1. Open the turtle (right-click)
2. Add fuel items to any slot (coal, charcoal, etc.)
3. (Optional) Add torches to **slot 16** for lighting
4. The turtle will auto-refuel from inventory as needed

#### Step 4: Configure Ore Detection (Optional)

If you're using mods with custom ores:

1. Edit the config file: `edit config/ores.cfg`
2. Add your modded ore IDs (see [Configuring Ores](#configuring-ores))

#### Step 5: Run the Script

**IMPORTANT:** Always run scripts from the root installation directory (where `common/`, `mining/`, `config/` folders are). Do NOT `cd` into the `mining/` folder first.

```
mining/smart_miner <length> [branches] [spacing]
```

**Parameters:**
| Parameter | Default | Description |
|-----------|---------|-------------|
| length | 50 | How far each branch extends |
| branches | 5 | Number of branches on each side of main tunnel |
| spacing | 3 | Blocks between branches (3 is optimal for ore exposure) |

**Examples:**

```
mining/smart_miner 50          -- 50-block branches, 5 per side, spacing 3
mining/smart_miner 100 10      -- 100-block branches, 10 per side
mining/smart_miner 30 8 2      -- 30-block branches, 8 per side, spacing 2
```

### Behavior

Once started, the turtle will:

1. **Mine a main tunnel** forward
2. **Create side branches** alternating left and right
3. **Detect and mine ore veins** - follows connected ores
4. **Discard junk** - drops cobblestone, dirt, gravel automatically
5. **Place torches** every 8 blocks (if torches in slot 16)
6. **Return to chest** when inventory is nearly full
7. **Deposit items** and return to continue mining
8. **Return home** when complete or if fuel is critically low

### Mining Pattern

The turtle creates an efficient branch mine pattern:

```
         ← Branch (50 blocks) →
         ========================
                                 |
    ─────────────────────────────┼── Main Tunnel
                                 |
         ========================
         ← Branch (50 blocks) →
              ↑
           3 blocks spacing (optimal for ore exposure)
```

With 3-block spacing, every ore vein within the mining area will have at least one block exposed to a tunnel.

### What Gets Kept vs. Discarded

**Kept (deposited in chest):**

- All ores and raw materials
- Diamonds, emeralds, lapis, redstone
- Coal, iron, gold, copper
- Any blocks not in the junk list

**Discarded (dropped in mine):**

- Cobblestone
- Dirt
- Gravel
- Stone variants (granite, diorite, andesite)
- Deepslate (regular, not ores)
- Tuff, Netherrack

### Configuring Ores

The turtle detects ores by checking block IDs. For modded ores:

1. Create/edit `config/ores.cfg`:

```
edit config/ores.cfg
```

2. Add one ore ID per line:

```
-- Custom ore configuration
-- Add mod ore IDs here, one per line
-- Format: modid:blockname

-- Create mod ores
create:zinc_ore
create:deepslate_zinc_ore

-- Mekanism ores
mekanism:osmium_ore
mekanism:deepslate_osmium_ore

-- Thermal ores
thermal:tin_ore
thermal:lead_ore
thermal:silver_ore
thermal:nickel_ore
```

3. The turtle loads this file on startup and adds these to its ore detection

**Finding Ore IDs:**

- Press F3 and look at a block to see its ID
- Or use: `turtle.inspect()` in the turtle terminal when facing a block

### Stopping the Turtle

- **Graceful stop:** Press `Ctrl+T` (terminate) - turtle will try to return home
- **Emergency stop:** Break the turtle (you'll need to pick it up)

### Tips for Best Results

1. **Start at optimal Y-level** for the ores you want
2. **Bring plenty of fuel** - a full mining run can use 2000+ fuel
3. **Use coal blocks** for efficiency (800 fuel each)
4. **Empty the chest** periodically if doing long mining sessions
5. **Keep torches stocked** in slot 16 to prevent mob spawns

---

## Troubleshooting

### Turtle Won't Move

- Check fuel level: `fuel`
- Add fuel and run: `refuel all`
- Check if path is blocked by entities

### Turtle Gets Lost

- If the turtle crashes mid-operation, it may lose position tracking
- Place it back at the starting chest and restart

### Inventory Fills Too Fast

- Make sure junk filtering is working
- Check if `config/ores.cfg` accidentally includes junk blocks
- Consider running with shorter branch lengths

### Script Errors

- Ensure all files are in the correct locations:
    - `common/movement.lua`
    - `common/inventory.lua`
    - `common/mining.lua`
    - `common/fuel.lua`
- Check for typos in the config file

### Modded Ores Not Detected

- Get the exact block ID using F3 debug screen
- Add to `config/ores.cfg` with exact spelling
- Block IDs are case-sensitive

---

## Adding New Bots

_This section will be expanded as new bots are added._

Future bots planned:

- Tree Farmer
- Crop Harvester
- Quarry Bot
- Builder Bot

---

_Last updated: January 2026_
