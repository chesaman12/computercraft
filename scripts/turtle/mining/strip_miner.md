# Strip Miner (symmetric grid, 1x3 height)

This document describes the algorithm implemented by `strip_miner.lua` for **symmetric grid mining** with **3-block rock gaps** and **1x3 corridor height**, plus end-of-run statistics (moves/turns/fuel/time).

## Goals

- Mine a **symmetric rectangular grid** of parallel corridors.
- Keep **3 blocks of rock** between corridors so a player can run and scan for ores.
- Maintain a **1-wide by 3-tall** tunnel profile.
- Both ends of the grid are connected (easy navigation).
- Handle inventory pressure according to `fullMode`.
- Stay safe on fuel by ensuring enough to return home.

## Coordinate model (internal)

The program maintains a simple relative coordinate system:

- Start position: `(x=0, z=0)`
- Facing direction `dir`:
  - `0`: +Z
  - `1`: +X
  - `2`: -Z
  - `3`: -X

Every successful `turtle.forward()` increments the corresponding axis.

## High-level algorithm

1. Show a pre-prompt hint about odd/even corridor counts.
2. Read parameters (`corridorLength`, `corridorCount`, `gap`, `mineRight`, `showLogs`, `returnHome`, `fullMode`).
3. Show efficiency tips based on corridor count (odd vs even, repositioning moves).
3. Estimate required fuel and call `fuel.ensureFuel(...)`.
4. **Phase 1**: Mine the perimeter rectangle (bottom bar → far corridor → top bar → near corridor).
5. **Phase 2**: Fill in interior corridors by branching off the bars.
6. Optionally return to start.
7. Print statistics (time, moves, turns, fuel used).

## Direction option

The `mineRight` parameter controls which way the grid expands:
- `true` (default): Mine to the **right** (+X direction)
- `false`: Mine to the **left** (-X direction)

This allows you to position the turtle on either side of an existing mine.

## Status screen

If `showLogs` is `false`, the script suppresses log output and shows a live status screen that updates during mining (progress, position, fuel, moves, turns, elapsed time).

## Efficiency guidance

When you enter the number of corridors, the script shows:
- **Odd corridor counts (3, 5, 7...)**: You end at a middle interior corridor, so return home is shorter on average.
- **Even corridor counts (4, 6, 8...)**: You end at the farther edge, so return home is longer.
- **Repositioning moves**: The script calculates how many moves will be spent walking back through already-mined corridors between interior corridor digs.

## Symmetric grid pattern

The turtle mines a clean rectangular outline first, then fills in the middle corridors:

```
Phase 1 (perimeter):
     x: 0 1 2 3 4 5 6 7 8
z=10:  ■ ■ ■ ■ ■ ■ ■ ■ ■   <- top bar
       ■               ■
       ■               ■   <- left + right corridors
       ■               ■
z=0:   ■ ■ ■ ■ ■ ■ ■ ■ ■   <- bottom bar (start here)

Phase 2 (interior):
     x: 0 1 2 3 4 5 6 7 8
z=10:  ■ ■ ■ ■ ■ ■ ■ ■ ■
       ■       ■       ■
       ■       ■       ■   <- middle corridor at x=4
       ■       ■       ■
z=0:   ■ ■ ■ ■ ■ ■ ■ ■ ■
```

This creates a **fully connected symmetric grid** that's easy for a player to navigate.

## 1x3 height clearing

Each forward move clears a 3-high column:

1. Mine forward one block.
2. Clear the block above.
3. Move up, clear the next block above, then move back down.

This creates a 1-wide, 3-tall corridor without changing the horizontal path.

## Inventory handling (`fullMode`)

When inventory becomes full:

- Always try `dropJunk()` first.
- If still full:
  - `1`: Pause and wait for user.
  - `2`: Return to chest at start, dump, then resume at previous location.
  - `3`: Continue anyway (risk: missing drops).

## Fuel handling

- At startup: `fuel.ensureFuel(estimatedMoves)`.
- Periodically during mining: if fuel is less than `distanceHome + 20`, return to start and stop.

## Statistics

The run prints:

- **Time**: wall-clock time measured via `os.epoch("utc")`.
- **Movements**: count of successful forward/up/down moves.
- **Turns**: count of left/right turns.
- **Fuel used**: `startFuel - endFuel` when fuel is finite.
- **Efficiency**: blocks per minute (based on the internal progress counter).

## Flow diagram (Mermaid)

```mermaid
flowchart TD
    A[Start at 0,0] --> B[Mine bottom bar +X]
    B --> C[Mine right corridor +Z]
    C --> D[Mine top bar -X]
    D --> E[Mine left corridor -Z]
    E --> F{More interior corridors?}
    
    F -- yes --> G[Navigate to next corridor x]
    G --> H[Mine corridor +Z]
    H --> I[Walk back -Z if more]
    I --> F
    
    F -- no --> J{Return home?}
    J -- yes --> K[goTo 0,0]
    J -- no --> L[Stay put]
    
    K --> M[Print stats]
    L --> M
    M --> N[End]
```

## Final shape (top-down)

```
■■■■■■■■■   z=length (top bar)
■   ■   ■
■   ■   ■   interior corridors
■   ■   ■
■■■■■■■■■   z=0 (bottom bar + start)
x=0   x=4   x=8
```

## Notes / tuning suggestions

- `MAX_DIG_ATTEMPTS` controls how long the turtle retries around hard/temporary blocks.
- If the turtle often waits on `sleep(0.2)`, lowering sleep can speed mining, but increases CPU usage and can spam dig attempts.
- If you want maximum speed, consider an option to skip `turtle.suck()` calls (or only suck periodically) — that reduces API calls but can leave drops behind.
