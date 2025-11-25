# Debugging TTS Scripts in VSCode

## Debug Mode

The script now has `DEBUG_MODE = true` which adds debug logging throughout execution.

### What Debug Logging Shows

When running in TTS or locally, you'll see gray debug messages showing:
- When `displayGangRoster()` is called
- URL being fetched
- HTML size received
- Each fighter as it's parsed
- Total fighters found

**Example output:**
```
[DEBUG] displayGangRoster() called: URL: https://gyrinx.app/list/...
[DEBUG] WebRequest successful: HTML size: 64985 bytes
[DEBUG] Starting to parse HTML: HTML length: 64985
[DEBUG] Parsed fighter: #1: bobby (Road Captain)
[DEBUG] Parsed fighter: #2: Cyber-mastiff (Cyber-mastiff)
[DEBUG] Parse complete: Total fighters: 2
```

## Debugging Methods

### Method 1: Test Locally (Fastest)

```bash
lua tests/test_tts_script.lua
```

**Advantages:**
- Instant feedback
- Full debug output in terminal
- No need to launch TTS
- Edit and retest immediately

**To test different gangs:**
Edit `tests/test_tts_script.lua` line 52:
```lua
setGangURL("https://gyrinx.app/list/YOUR_GANG_ID")
```

### Method 2: TTS Console Output

1. Load script into TTS (copy/paste to Global script)
2. Save & Play
3. Open TTS Console (press `~` key)
4. Run: `displayGangRoster()`
5. Watch console for debug messages

Debug messages appear in gray text showing execution flow.

### Method 3: Add Custom Debug Points

Add `debugLog()` calls anywhere you want to inspect:

```lua
debugLog("My checkpoint", "value: " .. someVariable)
```

**Examples:**
```lua
-- Check if section found
local weaponStart = findPlain(cardHtml, "<h5>Weapons</h5>")
debugLog("Weapon section", weaponStart and "found" or "not found")

-- Count items
debugLog("Weapons extracted", #weapons)

-- Show variable value
debugLog("Fighter name", fighter.name)
```

## Common Debugging Scenarios

### No Fighters Found

Add debug after HTML fetch:
```lua
debugLog("HTML preview", html:sub(1, 500))  -- First 500 chars
```

Check if HTML structure matches expectations.

### Weapons Not Parsing

Add in `extractWeapons()`:
```lua
local weaponStart = findPlain(cardHtml, "<h5>Weapons</h5>")
debugLog("Weapon section found", weaponStart ~= nil)
```

### Specific Fighter Issues

Add in `parseFighterCard()`:
```lua
debugLog("Parsing fighter", fighter.name)
debugLog("Found weapons", #fighter.weapons)
debugLog("Found skills", #fighter.skills)
```

## Turning Debug Off

For production use in TTS, turn off debug mode:

**In `gyrinx2tts.lua` line 7:**
```lua
local DEBUG_MODE = false
```

This removes all debug messages but keeps the script working.

## VSCode Features for TTS

### 1. Syntax Checking
VSCode shows Lua syntax errors as you type.

### 2. Quick Testing
Press **Ctrl+`** (backtick) to open terminal, then:
```bash
lua tests/test_tts_script.lua
```

### 3. Search Across Files
Press **Ctrl+Shift+F** to search for functions or variables across all files.

### 4. Go to Definition
Click on a function while holding **Ctrl** to jump to its definition.

### 5. Find All References
Right-click on a function name → "Find All References" to see where it's used.

## Debugging Workflow

1. **Make changes** in `gyrinx2tts.lua`
2. **Test locally**: `lua tests/test_tts_script.lua`
3. **Check debug output** for issues
4. **Fix problems** and retest
5. **When working**, copy to TTS and test there
6. **Turn off debug mode** for final version

## Reading Debug Output

**Successful run:**
```
[DEBUG] displayGangRoster() called
[DEBUG] WebRequest successful: HTML size: 64985 bytes
[DEBUG] Starting to parse HTML
[DEBUG] Parsed fighter: #1: bobby (Road Captain)
[DEBUG] Parse complete: Total fighters: 2
Found 2 fighters
```

**Problem indicators:**
- `WebRequest failed` = URL or connection issue
- `HTML size: 0 bytes` = Empty response
- `Starting to parse` but no "Parsed fighter" = HTML structure mismatch
- `Parse complete: Total fighters: 0` = Pattern matching failed

## Pro Tips

**Quick debug toggle:**
At top of file, keep both lines:
```lua
-- local DEBUG_MODE = false  -- Production
local DEBUG_MODE = true      -- Development
```
Comment/uncomment to switch.

**Test with multiple gangs:**
Create test files for each gang URL you use frequently.

**Save debug output:**
```bash
lua tests/test_tts_script.lua > debug_output.txt
```
Then review the file.
