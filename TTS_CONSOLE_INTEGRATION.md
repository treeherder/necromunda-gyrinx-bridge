# TTS Console Integration with VSCode

There's no direct integration, but here are effective workflows:

## Method 1: Copy Errors from TTS Console (Easiest)

The script now has enhanced error logging that shows:
- ✅ Exact function where error occurred
- ✅ Fighter name when parsing fails
- ✅ Full error message

**In TTS Console:**
1. Run your script
2. When error appears in red, **select the error text**
3. **Right-click → Copy**
4. Paste into VSCode terminal or a file

**Example error output:**
```
[ERROR] extractWeapons for 'bobby': attempt to call nil value
[ERROR] parseFighterCard for ID '12345-abc': invalid HTML structure
```

## Method 2: Create Error Log File

Add error tracking to collect all errors:

**In TTS console, run these commands:**
```lua
-- After script loads and errors occur
printErrors()     -- Shows all errors in copyable format
clearErrors()     -- Clear the log to start fresh
getLastError()    -- Get just the most recent error
```

Then copy the output to VSCode.

## Method 3: Use TTS Logs Folder

TTS writes console output to log files:

**Find TTS logs:**
- **Windows**: `%USERPROFILE%\Documents\My Games\Tabletop Simulator\Logs`
- **Mac**: `~/Library/Tabletop Simulator/Logs`
- **Linux**: `~/.local/share/Tabletop Simulator/Logs`

**Monitor in VSCode:**
```bash
# Open log in VSCode
code "~/Documents/My Games/Tabletop Simulator/Logs/Player.log"

# Or tail the log in terminal
tail -f "~/Documents/My Games/Tabletop Simulator/Logs/Player.log"
```

## Method 4: Screenshot/Photo for Complex Errors

If error is complex:
1. Press **PrtScn** or **Win+Shift+S** to capture TTS console
2. Save screenshot
3. Reference while debugging in VSCode

## Method 5: Use Test Script Instead (Best for Development)

**Instead of debugging in TTS, debug locally first:**

```bash
cd ~/projects/gyrinx2tts/necromunda-gyrinx-bridge
lua tests/test_tts_script.lua
```

**Advantages:**
- ✅ Errors appear directly in VSCode terminal
- ✅ Full Lua stack traces
- ✅ Instant iteration - no TTS reload needed
- ✅ Can add print statements anywhere
- ✅ Test with different gang URLs easily

**Only load into TTS after local testing passes.**

## Debugging Workflow

**Best practice:**

1. **Write code** in VSCode (`gyrinx2tts.lua`)
2. **Test locally**: `lua tests/test_tts_script.lua`
3. **Fix errors** shown in VSCode terminal
4. **Repeat** until working
5. **Copy to TTS** when local tests pass
6. **If TTS-specific error**, copy error text from TTS console to VSCode

## Error Categories

### Lua Syntax Errors
Show immediately in VSCode with red squiggles.

### Runtime Errors (Local)
Appear in terminal when running `lua tests/test_tts_script.lua`:
```
lua: gyrinx2tts.lua:123: attempt to index a nil value
stack traceback:
    gyrinx2tts.lua:123: in function 'extractWeapons'
    gyrinx2tts.lua:456: in function 'parseFighterCard'
```

### Runtime Errors (TTS)
Show in TTS console in red text. Copy to VSCode for analysis.

### Logic Errors
Use `debugLog()` statements to trace execution:
```lua
debugLog("Before weapon extraction", "HTML length: " .. #cardHtml)
local weapons = extractWeapons(cardHtml)
debugLog("After weapon extraction", "Found " .. #weapons .. " weapons")
```

## Quick Commands Reference

**In TTS Console:**
```lua
-- Set gang URL
setGangURL("https://gyrinx.app/list/YOUR_GANG_ID")

-- Run main function
displayGangRoster()

-- Check for errors
printErrors()

-- Clear error log
clearErrors()

-- Get specific error
getLastError()
```

**In VSCode Terminal:**
```bash
# Test script locally
lua tests/test_tts_script.lua

# Test with different gang
# (edit tests/test_tts_script.lua line 52 first)
lua tests/test_tts_script.lua

# Save output to file
lua tests/test_tts_script.lua > output.txt 2>&1
```

## Pro Tips

**Add timestamps to debugging:**
```lua
debugLog("Starting parse", os.date("%H:%M:%S"))
```

**Test specific functions locally:**
Create a test file:
```lua
-- test_single_function.lua
package.path = package.path .. ";./?.lua"
dofile("gyrinx2tts.lua")

local html = [[
<h3 class="h5 mb-0">Test Fighter</h3>
]]

local result = parseFighterCard("test-id", html)
print("Name:", result.name)
```

**Use VSCode's Problems panel:**
Press `Ctrl+Shift+M` to see all Lua syntax errors in one place.

**Multi-cursor editing:**
When you need to add debug statements to multiple places:
- `Ctrl+D` to select next occurrence
- `Alt+Click` to add cursor at click position
- Type once, edit multiple places
