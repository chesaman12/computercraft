# Strip Miner (parallel corridors, 1x3 height)

This document describes the algorithm implemented by `strip_miner.lua` for **parallel corridor mining** with **3-block rock gaps** and **1x3 corridor height**, plus end-of-run statistics (moves/turns/fuel/time).

## Goals

- Mine long, parallel corridors with minimal non-mining travel.
- Keep **3 blocks of rock** between corridors so a player can run and scan for ores.
- Maintain a **1-wide by 3-tall** tunnel profile.
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

1. Read parameters (`corridorLength`, `corridorCount`, `gap`, `returnHome`, `fullMode`).
2. Estimate required fuel and call `fuel.ensureFuel(...)`.
3. Mine `corridorCount` corridors of length `corridorLength`.
4. Between corridors, shift sideways by `gap + 1` blocks (connector at each end).
5. Optionally return to start.
6. Print statistics (time, moves, turns, fuel used).

## Corridor mining pattern

- The turtle mines the first corridor forward (+Z).
- At the end, it turns right, shifts +X by `gap + 1`, turns right again, and mines back (-Z).
- This creates a **snake pattern** with minimal backtracking.
- Each connector at the end is also mined (no “empty travel”).

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
    A[Start] --> B[Read user params]
    B --> C[Estimate required moves]
    C --> D{ensureFuel OK?}
    D -- no --> Z[Exit]
    D -- yes --> E[Init stats + progress]

    E --> F{corridor = 1..count}
    F --> G[Mine corridor length]
    G --> H{More corridors?}
    H -- yes --> I[Shift +X by gap+1]
    I --> F
    H -- no --> J{Return home?}

    J -- yes --> K[goTo(0,0)]
    J -- no --> L[Stay put]

    K --> M[Print stats + completion]
    L --> M
    M --> N[End]
```

## Snake pattern (top-down)

```mermaid
flowchart LR
    A[Start] --> B[Corridor 1 (+Z)] --> C[Shift +X]
    C --> D[Corridor 2 (-Z)] --> E[Shift +X]
    E --> F[Corridor 3 (+Z)] --> G[...]
```

## Notes / tuning suggestions

- `MAX_DIG_ATTEMPTS` controls how long the turtle retries around hard/temporary blocks.
- If the turtle often waits on `sleep(0.2)`, lowering sleep can speed mining, but increases CPU usage and can spam dig attempts.
- If you want maximum speed, consider an option to skip `turtle.suck()` calls (or only suck periodically) — that reduces API calls but can leave drops behind.
