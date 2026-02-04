# Bot Gameplay Guide

This guide explains how to set up and use the turtle bots in-game. Each bot has its own section with setup instructions, configuration options, and expected behavior.

---

## Table of Contents

1. [General Setup](#general-setup)
2. [Installing Scripts](#installing-scripts)
3. [Smart Miner](#smart-miner)
4. [Tree Farmer](#tree-farmer)
5. [Logging and Log Uploads](#logging-and-log-uploads)
6. [Troubleshooting](#troubleshooting)

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
wget https://raw.githubusercontent.com/chesaman12/computercraft/tom-branch/scripts/tomfoolery/installer.lua installer
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
mining/smart_miner <size> [spacing] [--upload]
```

**Parameters:**
| Parameter | Default | Description |
|-----------|---------|-------------|
| size | 25 | Target square size for the mine |
| spacing | 3 | Blocks between branches (3 is optimal for ore exposure) |
| --upload | off | Upload log to Pastebin when complete |

**Examples:**

```
mining/smart_miner 25              -- 25x25 square, spacing 3
mining/smart_miner 50 --upload     -- 50x50 square, upload log when done
mining/smart_miner 30 2            -- 30x30 square, spacing 2
mining/smart_miner 40 3 --upload   -- 40x40 square, spacing 3, upload log
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
6. **Use --upload flag** to get a log URL for debugging issues

---

## Tree Farmer

**Script:** `farming/tree_farmer.lua`

An automated tree farming turtle that plants, harvests, and replants saplings in a configurable grid layout.

### Setup Instructions

#### Step 1: Choose a Location

1. Find or create a flat area for your tree farm
2. Ensure adequate vertical clearance (at least 10 blocks for birch/oak)
3. Trees need light to grow - outdoors is best, or add torches

#### Step 2: Position the Turtle

1. Place the turtle at one corner of your farm area
2. The turtle should face into the farm (the direction trees will be planted)

```
     [Chest] [Turtle] → → → (farming area)
```

#### Step 3: Place the Deposit Chest

1. Place a **chest directly behind the turtle**
2. The turtle returns here to deposit logs when inventory fills up

#### Step 4: Load Saplings and Fuel

1. Open the turtle (right-click)
2. Place **saplings in slot 1** - at least enough for your grid (e.g., 25 for 5x5)
3. Add **fuel items** (coal, charcoal, wood) to any other slot
4. Recommended: 64+ saplings for initial setup

#### Step 5: Run the Script

**IMPORTANT:** Run scripts from the root installation directory.

```
farming/tree_farmer <width> <depth> [tree_type] [--setup] [--upload]
```

**Parameters:**
| Parameter | Default | Description |
|-----------|---------|-------------|
| width | 5 | Number of trees in X direction |
| depth | 5 | Number of trees in Z direction |
| tree_type | birch | Tree type: birch, oak, spruce, jungle, acacia |
| --setup | off | Initial setup mode - plants all saplings |
| --upload | off | Upload log to Pastebin when complete |

**Examples:**

```
farming/tree_farmer 5 5 --setup           -- 5x5 birch farm, initial setup
farming/tree_farmer 7 7 oak --setup       -- 7x7 oak farm, initial setup
farming/tree_farmer 5 5 --upload          -- Harvest existing 5x5 farm
farming/tree_farmer 4 6 birch --upload    -- 4x6 birch farm with logging
```

### First-Time Setup

For a new tree farm, use the `--setup` flag:

```
farming/tree_farmer 5 5 birch --setup
```

This will:

1. Navigate to each grid position
2. Plant a sapling at each location
3. Wait for trees to start growing
4. Begin the harvest loop

### Behavior

Once running, the turtle will continuously:

1. **Traverse the farm grid** in a serpentine pattern
2. **Detect grown trees** by checking for log blocks
3. **Harvest trees** by cutting upward through the trunk
4. **Collect drops** (saplings, sticks, apples from oak)
5. **Return to ground level** after each tree
6. **Replant missing saplings** at empty positions
7. **Deposit logs** when inventory is nearly full
8. **Wait between passes** for trees to regrow (2 minutes default)

### Grid Layout

The turtle plants trees with optimal spacing for the tree type:

```
     [T] - - - [T] - - - [T]     T = Tree position
      |         |         |      - = Empty space (3 blocks for birch)
      |         |         |
     [T] - - - [T] - - - [T]     Grid moves left-to-right,
      |         |         |      then advances one row
      |         |         |
     [T] - - - [T] - - - [T]
```

**Spacing by tree type:**
| Tree Type | Spacing | Notes |
|-----------|---------|-------|
| Birch | 3 blocks | Best for automation - uniform height |
| Oak | 3 blocks | May grow large variants (harder to harvest) |
| Spruce | 3 blocks | Tall trees, consistent |
| Jungle | 3 blocks | Low sapling return, may need external supply |
| Acacia | 4 blocks | Irregular shape, needs more space |

### Recommended Tree Types

**Best: Birch**

- Most uniform height (5-7 blocks)
- Consistent sapling drops
- Easy to fully harvest from ground
- Fast growth

**Good: Oak (Small)**

- Compact when small
- Can drop apples
- Risk: May grow large/branching variant

**Avoid: Dark Oak**

- Requires 2x2 sapling placement
- Low sapling return rate
- Not currently supported by this script

### Self-Sustaining Operation

The turtle collects saplings from leaf decay. To maintain sustainability:

1. **Birch/Spruce**: Usually self-sustaining (4+ saplings per tree average)
2. **Oak**: Usually self-sustaining, plus drops apples
3. **Jungle**: Often needs external sapling supply (low drop rate)

The script warns if sapling count drops below the minimum threshold (10 by default).

### Tips for Best Results

1. **Use birch trees** for most reliable automation
2. **Start with plenty of saplings** - at least 2x your grid size
3. **Check fuel regularly** - tree farming uses less fuel than mining but still needs it
4. **Empty the chest** periodically for large farms
5. **Outdoor farms** grow faster (more light)
6. **Add torches** around the farm to prevent mob spawns at night

---

## Logging and Log Uploads

All scripts log their activity to local files and can upload logs to Pastebin for sharing and debugging.

### Log Files

Logs are saved to `/logs/<script_name>.log` automatically. You can view them with:

```
edit /logs/smart_miner.log
```

### Uploading Logs to Pastebin

#### Method 1: Use --upload Flag

Add `--upload` when running any script:

```
mining/smart_miner 25 --upload
```

The script will upload the log to Pastebin when it completes (or if it crashes) and display a URL.

#### Method 2: Manual Upload

Use the upload utility after running a script:

```
upload_log                    -- Upload most recent log
upload_log smart_miner.log    -- Upload specific log
upload_log --list             -- List available logs
```

### Sharing Logs for Help

When you encounter issues:

1. Run your script with `--upload` flag
2. Copy the Pastebin URL displayed at the end
3. Share the URL when asking for help

The log includes:

- Computer ID and label
- All configuration parameters
- Timestamps for every operation
- Fuel levels and inventory states
- Position tracking
- Error messages with locations
- Final statistics

### Log Configuration

Edit `config/logger.cfg` to customize logging:

```
# Log levels: error, warn, info, debug
min_level = debug

# Print to terminal while logging
echo = true

# Pastebin API key (required for uploads)
# Get one at: https://pastebin.com/doc_api
# pastebin_key = YOUR_API_KEY

# Discord webhook - log URLs are automatically sent here
discord_webhook = https://discordapp.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN
```

### Discord Integration

When a Discord webhook is configured, every log upload automatically sends the Pastebin URL to your Discord channel. This ensures you never lose the link even if the turtle's screen clears.

The Discord message includes:

- Computer ID and label
- Current fuel level
- Run statistics (blocks mined, ores found, etc.)
- Direct link to the full Pastebin log

To set up Discord notifications:

1. In Discord, go to your channel settings → Integrations → Webhooks
2. Create a new webhook and copy the URL
3. Add it to `config/logger.cfg`:
    ```
    discord_webhook = https://discordapp.com/api/webhooks/...
    ```

### Common Upload Errors

If you see: `Upload failed: Unprocessable Entity`, it usually means:

- **Missing or invalid Pastebin API key** (`pastebin_key` not set)
- **Payload too large** (logs exceeded 512 KB)

Set `pastebin_key` in `config/logger.cfg` and retry. Logs are auto-truncated if they exceed the size limit.

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
    - `common/logger.lua`
- Check for typos in the config file
- **Run with --upload and share the log URL for help**

### Modded Ores Not Detected

- Get the exact block ID using F3 debug screen
- Add to `config/ores.cfg` with exact spelling
- Block IDs are case-sensitive

### Getting Debug Logs

If something goes wrong:

1. Re-run the script with `--upload` flag
2. The log will be uploaded even on errors
3. Share the Pastebin URL for detailed debugging

---

## Adding New Bots

_This section will be expanded as new bots are added._

Future bots planned:

- Tree Farmer
- Crop Harvester
- Quarry Bot
- Builder Bot

---

_Last updated: February 2026_
