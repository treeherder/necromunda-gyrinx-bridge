# TTS Debugging Guide

## Setup

You have the **Tabletop Simulator Lua** extension installed. This workspace is configured for TTS development.

## Testing Locally

Test the script without loading into TTS:

```bash
lua tests/test_tts_script.lua
```

This uses mocked TTS globals (`WebRequest`, `printToAll`, `Wait`) to simulate the TTS environment.

## Loading into TTS

### Method 1: Save & Play (Recommended)

1. Open Tabletop Simulator
2. Open VSCode with `gyrinx2tts.lua`
3. Press **Ctrl+Shift+P** (or Cmd+Shift+P on Mac)
4. Type "TTS: Save and Play"
5. Select `gyrinx2tts.lua`

The extension will:
- Save your file
- Send it to TTS
- Reload TTS scripts automatically

### Method 2: Manual Copy

1. Open TTS
2. Objects → Scripting → Global
3. Copy contents of `gyrinx2tts.lua`
4. Paste into TTS editor
5. Click "Save & Play"

## Using in TTS

### Setting Your Gang URL

In TTS chat or by clicking a button:
```lua
setGangURL("https://gyrinx.app/list/YOUR_GANG_ID_HERE")
```

### Displaying Gang Roster

Create a button that calls:
```lua
displayGangRoster()
```

Or run directly in TTS console:
```lua
displayGangRoster()
```

## TTS Extension Features

### Available Commands

Press **Ctrl+Shift+P** to access:
- `TTS: Save and Play` - Save file and reload in TTS
- `TTS: Get Scripts` - Download current scripts from TTS
- `TTS: Create XML UI File` - Create UI layout
- `TTS: Execute Lua Code` - Run code in TTS console

### Keyboard Shortcuts

- **Ctrl+Alt+L** - Save and Play (reload TTS)
- **Ctrl+Alt+G** - Get Scripts from TTS

### Console Panel

The extension adds a TTS Console panel at the bottom showing:
- Script execution output
- Errors and warnings
- `printToAll()` messages

## Debugging Tips

### Pattern Too Complex Errors

Our script uses `string.find(text, pattern, 1, true)` to avoid pattern matching:
- 4th parameter `true` = plain text search
- No pattern complexity issues
- Safe for large HTML strings

### Testing Different Gangs

Edit `tests/test_tts_script.lua` line 52:
```lua
setGangURL("https://gyrinx.app/list/YOUR_GANG_ID")
```

### Checking Parser Output

Run the test locally to see parsed data before loading into TTS:
```bash
lua tests/test_tts_script.lua | less
```

### Common Issues

**"WebRequest failed"**
- Check gang URL is correct
- Verify TTS has internet access
- Check URL format: `https://gyrinx.app/list/GANG_ID`

**"No fighters found"**
- Gang may be empty
- Dead/retired fighters are automatically skipped
- Check Gyrinx website to verify gang has active fighters

**"Pattern too complex"**
- Should not happen - we use plain text search
- If it does, report as a bug

## File Structure

```
necromunda-gyrinx-bridge/
├── gyrinx2tts.lua           # Main TTS script (load this into TTS)
├── drafts/
│   └── bridgedraft1.lua     # Original version (archived)
├── tests/
│   ├── test_tts_script.lua  # Local test harness
│   ├── src/
│   │   ├── parser_v2.lua    # Parser used to develop TTS script
│   │   ├── fighter.lua      # Fighter class for testing
│   │   └── fetcher.lua      # HTTP fetcher for testing
│   └── debug_*.lua          # Various debug scripts
└── .vscode/
    ├── settings.json        # TTS extension config
    ├── launch.json          # Debug configuration
    └── tasks.json           # Test tasks
```

## Next Steps

1. **Test locally**: `lua tests/test_tts_script.lua`
2. **Load into TTS**: Use "TTS: Save and Play" command
3. **Set your gang URL**: `setGangURL("https://...")`
4. **Display roster**: `displayGangRoster()`
