# Multi-Player Usage Guide

## v2.2.0 - Multi-Player Ready

This version enables multiple players to use the Gyrinx Bridge simultaneously without conflicts.

## How It Works

### Single Spawner Token
- Place one Gyrinx Bridge token on the table (the "spawner")
- This spawner remains clean and reusable
- It only has the "Spawn New Gang" button

### Player-Specific Dialogs
- When a player clicks "Spawn New Gang", only they see the URL input dialog
- Other players are not interrupted or shown the dialog
- Each player enters their own gang URL independently

### Independent Gang Tokens
- Each gang URL spawns a **brand new token**
- The new token appears 5 units to the right, 1 unit up from the spawner
- Each gang token has its own:
  - Fighter roster
  - Selected fighter
  - Activation states
  - Display toggles
  - Models and data

### No Interference
- Multiple players can load different gangs at the same time
- Each player's gang token is completely independent
- Changes to one gang don't affect others
- No shared state or data conflicts

## Setup for Multi-Player Game

1. **Host Setup**: Place one Gyrinx Bridge spawner token on the table
2. **Player 1**: Clicks "Spawn New Gang", enters their Gyrinx URL
3. **Player 2**: Clicks "Spawn New Gang" on the spawner, enters their URL
4. **Player 3+**: Same process - unlimited gang tokens can be spawned

Each player now has their own gang token to manage their roster!

## Example Scenario

**4-player Necromunda campaign:**
- Spawner token in center of table
- Player 1 (Green) spawns their Goliath gang → token appears to the right
- Player 2 (Blue) spawns their Escher gang → another token appears
- Player 3 (Red) spawns their Van Saar gang → third token appears
- Player 4 (Yellow) spawns their Orlock gang → fourth token appears

Each player manages their own token independently!

## Benefits

✅ **No Dialog Conflicts**: Each player only sees their own URL input
✅ **Independent State**: Each gang has its own data, no cross-contamination
✅ **Unlimited Tokens**: Spawn as many gangs as needed
✅ **Clean Spawner**: Original token stays empty and reusable
✅ **Easy Cleanup**: Delete individual gang tokens when done

## Technical Details

- Uses `Player[playerColor].showInputDialog()` for player-specific visibility
- Spawns tokens using `spawnObjectJSON()` with cloned configuration
- Each spawned token gets its own `GANG_URL` variable
- Tokens load their gang data independently via WebRequest
