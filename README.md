# ComputerCraft Scripts

A collection of Lua scripts for [CC:Tweaked](https://tweaked.cc/) (ComputerCraft) mod in Minecraft. Includes turtle automation, mining programs, rednet communication systems, and utility scripts.

## Requirements

- Minecraft with [CC:Tweaked](https://modrinth.com/mod/gu7yAYhd) mod installed
- Works with both Forge and Fabric

## Project Structure

```
scripts/
├── turtle/           # Turtle automation programs
│   ├── dig.lua          # Configurable area excavation
│   ├── block.lua        # Block placement patterns  
│   ├── mineshaft.lua    # Mineshaft mining with menu system
│   ├── stairminer.lua   # Staircase mining pattern
│   ├── turtlerefuel.lua # Lava-based refueling system
│   ├── move.lua         # Simple movement commands
│   └── ...
├── computer/         # Computer programs
│   ├── gps/             # GPS utilities
│   │   ├── locate.lua      # GPS location finder
│   │   └── linkcords.lua   # Coordinate linking
│   └── query/           # Rednet query system
│       ├── transmitter.lua    # GPS-based position broadcaster
│       ├── receiver.lua       # Message receiver with redstone output
│       ├── pistonQueryController.lua  # Piston control logic
│       └── */startup.lua      # Device-specific startup scripts
└── tomfoolery/       # Experimental/fun scripts
    └── mining/          # Mining experiments
```

## Key Features

### Turtle Programs
- **Mining & Excavation**: Configurable 3D area mining with gravel/sand handling
- **Building**: Block placement patterns for walls, floors, structures
- **Fuel Management**: Automatic refueling from lava tanks
- **Movement Utilities**: Simple directional movement commands

### Computer Programs  
- **GPS Integration**: Position tracking and coordinate broadcasting
- **Rednet Communication**: Message-based control systems
- **Redstone Automation**: Computer-controlled redstone signals for Create mod integration

### Create Mod Integration
The query system is designed to work with Create mod machinery:
- Clutches, gearshifts, gantries controlled via redstone
- GPS-based position triggers (AT_TOP, AT_BOTTOM events)
- Automated quarry/mining operations

## Getting Started

1. Copy scripts to your in-game computer using `wget` or the file transfer feature
2. For turtles, ensure adequate fuel before running mining programs
3. For rednet systems, place wireless modems and configure sides appropriately

### Example: Running the excavation script
```
> dig
Dig up or down (u, d): d
Dig to the left or right (l, r): r
length: 10
width: 10
depth/height: 5
```

## Development

This project includes VS Code Copilot customization for CC:Tweaked development:

- `.github/copilot-instructions.md` - General coding guidelines
- `.github/instructions/*.instructions.md` - Language-specific rules
- `.github/skills/computercraft-lua/SKILL.md` - Comprehensive API knowledge

Enable in VS Code settings:
```json
{
  "chat.useAgentSkills": true,
  "github.copilot.chat.codeGeneration.useInstructionFiles": true
}
```

## Documentation

- [CC:Tweaked Wiki](https://tweaked.cc/) - Official API documentation
- [docs/cc-tweaked/](docs/cc-tweaked/) - Local documentation copy

## License

See [LICENSE](LICENSE) for details.