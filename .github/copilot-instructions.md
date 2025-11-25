# Necromunda Gyrinx Bridge - AI Coding Agent Instructions

## Project Overview

This is a **Tabletop Simulator (TTS) Lua script** that bridges Gyrinx.app (Necromunda gang roster manager) with TTS. It's a single-file monolithic script (`gyrinx2tts.lua`) designed to run inside TTS's sandboxed Lua environment, not standalone Lua.

**Key Architecture Point**: This is NOT a standard Lua project. It's embedded in TTS and uses TTS-specific APIs that don't exist in standard Lua.

## TTS-Specific Constraints

### Environment Limitations
- **No standard library imports**: No `require()`, no external modules, no file I/O
- **TTS Global API only**: `WebRequest`, `Wait`, `getAllObjects()`, `getObjectFromGUID()`, `Player`, `JSON` are TTS-provided globals
- **Event-driven lifecycle**: Code executes via TTS callbacks: `onLoad(saved_data)`, `onSave()`, and button click functions
- **State persistence**: Use `onSave()`/`onLoad()` with `JSON.encode()`/`JSON.decode()` to persist state between sessions

### Critical TTS APIs Used
```lua
-- Network requests (async callback pattern)
WebRequest.get(url, function(webReturn) end)

-- Object manipulation
self.createButton({click_function, label, position, width, height, font_size, color})
self.clearButtons()
obj.setDescription(text)  -- Stores rich text on TTS objects
obj.setName(name)

-- Spatial queries
getAllObjects()           -- Returns all objects in scene
obj.getPosition()         -- Returns {x, y, z}

-- Async utilities
Wait.frames(function() end, frame_count)

-- User feedback
printToAll(message, rgb_color)
```

## Code Organization Pattern

The script follows a **functional, top-to-bottom** structure (no module system):

1. **Configuration constants** (lines 6-7): `GANG_URL`, `GANG_NAME`
2. **State variables** (lines 10-11): `gangFighters`, `selectedFighterIndex`
3. **Fighter class** (lines 14-147): OOP via metatables (`Fighter:new()`, `Fighter:formatCard()`)
4. **HTML parsing functions** (lines 167-364): `extractFighterCards()`, `parseFighterCard()`, `parseWeaponStats()`
5. **UI management** (lines 367-438): `createFighterButtons()` - dynamic button generation
6. **Data fetching** (lines 441-469): `fetchGangData()` - WebRequest wrapper
7. **Event handlers** (lines 472-498): `selectFighter()`, `refreshGangData()`, `copyToModelOnObject()`
8. **TTS lifecycle hooks** (lines 541-563): `onLoad()`, `onSave()`

## Critical Patterns to Follow

### 1. Dynamic Button Click Functions via Global Scope
TTS requires click functions to be **global** and **named as strings**:
```lua
-- Generate 50 click handlers at load time
for i = 1, 50 do
    _G["selectFighter_" .. i] = function()
        selectFighter(i)
    end
end

-- Reference in button config
self.createButton({
    click_function = "selectFighter_5",  -- String reference
    function_owner = self
})
```

### 2. HTML Parsing Without External Libraries
Uses **string pattern matching** (`string.gmatch`) to scrape Gyrinx.app HTML:
```lua
-- Extract nested HTML structures
for card_html in html:gmatch('<div class="card[^"]*" id="[^"]+">.-</div>%s*</div>%s*</div>') do
    local fighter_data = parseFighterCard(card_html)
end

-- HTML entity decoding via gsub (lines 174-180)
text = text:gsub("&quot;", '"')
text = text:gsub("&nbsp;", " ")
```

**Why this matters**: Changes to Gyrinx.app's HTML structure will break parsing. Pattern regex is tightly coupled to their Bootstrap 5 card layout.

### 3. Rich Text Formatting for TTS
TTS uses bracket notation for colored text in descriptions:
```lua
"[56f442]Stats[-]\n"        -- Green headers
"[dc61ed]Skills[-]\n"        -- Purple skills
"[e85545]Weapons[-]\n"       -- Red weapons
"[c6c930]Autogun[-]\n"       -- Yellow weapon names
```

### 4. Spatial Object Detection
Models are "on" the script object if within 3 units and Y position above it (lines 521-531):
```lua
local distance = math.sqrt((myPos.x - objPos.x)^2 + (myPos.y - objPos.y)^2 + (myPos.z - objPos.z)^2)
if distance < 3 and objPos.y > myPos.y then
    table.insert(objectsOnMe, obj)
end
```

### 5. UI Layout Constraints
Buttons are arranged in a **2-column grid** with hardcoded positions (lines 421-433):
- Max 14 fighters visible (7 rows × 2 columns)
- Left column X: -1.2, Right column X: 1.2
- Z spacing: 0.5 per row starting at -1.5

## Development Workflow

### Testing Changes
1. Edit `gyrinx2tts.lua`
2. Copy entire file to TTS: Right-click object → Scripting → Paste → Save & Play
3. Check TTS console (Tab key) for print() debug output
4. Test button interactions in-game

**No standalone execution**: This script cannot run outside TTS. The `main.lua` attachment you saw is from a test harness project, not this one.

### Debugging
- **Verbose logging**: All functions use `print()` extensively (e.g., lines 369-437)
- **Console access**: Tab key in TTS opens Lua console
- **Error handling**: Check `webReturn.is_error` for network failures (line 444)

### Common Modifications
- **Change gang roster**: Update `GANG_URL` constant (line 6)
- **Adjust button layout**: Modify `leftX`, `rightX`, `startZ`, `spacing` (lines 415-418)
- **Add fighter fields**: Update `Fighter:new()` data structure (lines 17-39) and `Fighter:formatCard()` (lines 43-136)
- **Fix HTML parsing**: Modify regex patterns in `parseFighterCard()` if Gyrinx.app HTML changes

## External Dependencies

- **Gyrinx.app API**: Unofficial web scraping (no documented API)
  - HTML structure based on Bootstrap 5 cards
  - Expects public gang roster URLs: `https://gyrinx.app/list/{uuid}`
  - Gang must be set to "public" visibility

## What NOT to Do

❌ Don't try to add `require()` statements - TTS doesn't support them  
❌ Don't use standard Lua file I/O (`io.open`, etc.) - sandbox restriction  
❌ Don't assume OOP inheritance - use simple metatables only  
❌ Don't use coroutines - TTS uses `Wait` API instead  
❌ Don't reference undefined globals - check TTS API docs for available functions

## Quick Reference: Key Functions

| Function | Purpose | When to Modify |
|----------|---------|----------------|
| `Fighter:formatCard()` | Generates rich text character sheet | Add/remove stat display fields |
| `parseFighterCard()` | Extracts fighter data from HTML | Gyrinx.app HTML structure changes |
| `createFighterButtons()` | Builds entire button UI | Change layout/add controls |
| `copyToModelOnObject()` | Spatial detection + data copy | Adjust detection radius/logic |
| `fetchGangData()` | Async HTTP wrapper | Add error handling/retries |

## Example: Adding a New Fighter Field

To display "Reputation" on fighter cards:

1. Add field to `Fighter:new()` (line ~38):
   ```lua
   reputation = data.reputation or 0,
   ```

2. Parse from HTML in `parseFighterCard()` (after line ~364):
   ```lua
   local rep_match = card_html:match('<span class="reputation">(%d+)</span>')
   if rep_match then
       data.reputation = tonumber(rep_match)
   end
   ```

3. Display in `Fighter:formatCard()` (after line ~75):
   ```lua
   card = card .. string.format("[56f442]Reputation: %d[-]\n", self.reputation)
   ```
