# Vampyre

**Vampyre** is a free implementation of the classic *Vampir* game for the **Agat-7** Soviet home computer (1987), itself inspired by the MS-DOS classic **Beast / Heads**. Written in **Ada 2022** using the **ncurses** library.

## Gameplay

The game takes place on a walled grid field scattered with pushable blocks.  
Your goal is to **trap all vampires** by surrounding them with blocks — a vampire is caught when it has no free cell to move to in any of its 8 directions.

| Symbol | Meaning |
|--------|---------|
| `0`    | Wall (indestructible border) |
| `W`    | Block (pushable) |
| `@`    | Player (you) |
| `V`    | Vampire |
| `X`    | Dead player (blinking during death animation) |

### Rules

- The **player** moves in 4 directions (arrow keys).
- Blocks can be **pushed in chains**: if a row of blocks has a free cell at the end, the whole row slides.
- Blocks **cannot be pushed through vampires** - if a vampire is in the path, the block chain cannot move.
- Vampires are **trapped and killed** when completely surrounded in all 8 directions by blocks or walls.
- **Vampires** chase the player and move in 8 directions, but their speed varies with the **day/night cycle**:
  - **Day**: vampires move once every **4 player steps**
  - **Night**: vampires move once every **2 player steps**
- The day/night cycle changes every **12 player steps**.
- A vampire that reaches the player causes a **loss of life**.
- Each level has an optional **time limit** (disabled by default, like the original).
- You start with **3 lives**. Losing all lives ends the game.
- There are **10 levels**. Each level adds one more vampire and removes a few blocks.
- At the start of the game, you can **select any level from 01 to 10** using arrow keys and Space.

## Controls

| Key | Action |
|-----|--------|
| ↑ ↓ ← → | Move player |
| `R` | Restart current level (lives are kept) |
| `Q` | Quit |
| **Level selection screen** |
| ↑ ↓ | Change selected level |
| Enter/Space | Confirm level selection |
| `Q` | Quit game |

## Requirements

- GNAT compiler (Ada 2022 standard)
- GPRbuild
- `ncursesada` library
  - Debian/Ubuntu: `sudo apt-get install libncursesada-dev`

## Build & Run

```bash
gprbuild -P vampyre.gpr
./dest/vampyre
```

## Project Structure

```
vampyre/
├── vampyre.gpr          GPRbuild project file
└── src/
    ├── settings.ads     All game constants (no magic numbers)
    ├── engine.ads/adb   Game logic: movement, AI, physics
    ├── renderer.ads/adb ncurses rendering
    └── main.adb         Entry point and game loop
```

## Configuration

All tunable parameters live in [`src/settings.ads`](src/settings.ads):

| Constant | Default | Description |
|----------|---------|-------------|
| `Char_Wall`| `'0'` | Wall symbol |
| `Char_Block`| `'W'`| Pushable block symbol |
| `Char_Player`| `'@'` | Player symbol |
| `Char_Vampire`| `'V'`| Vampire symbol |
| `Timer_Enabled`| `False` | Enable per-level time limit |
| `Game_Tick_Ms` | 100 | Main loop tick in ms |
| `Level_Time_Sec` | 120 | Time limit per level (when enabled) |
| `Start_Lives` | 3 | Starting lives |
| `Cycle_Length` | 12 | Player steps per day/night phase |
| `Vampire_Speed_Day` | 4 | Vampire moves every 4 steps during day |
| `Vampire_Speed_Night` | 2 | Vampire moves every 2 steps during night |
| `Max_Levels` | 10 | Number of levels |
| `Vampires_Start` | 2 | Vampires on level 1 |
| `Blocks_Start` | 60 | Blocks on level 1 |
| `Blocks_Step` | 2 | Blocks removed per level |

---

*Developed with Gemini as a demonstration of Ada 2022 for terminal game development.*
