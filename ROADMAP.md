# Necromunda Gyrinx Bridge - Development Roadmap

**Last Updated:** November 20, 2025  
**Current Phase:** Phase 1 Complete - Console Display ✅

---

## Project Vision

Transform the Gyrinx Bridge from a console-only parser into a fully interactive Tabletop Simulator mod with rich UI, persistent state management, spawnable fighter cards, and advanced gameplay features for Necromunda campaigns.

---

## Phase 1: Core Parsing & Console Display ✅ COMPLETE

**Status:** ✅ **Completed November 20, 2025**

### Completed Features
- ✅ HTML parsing from Gyrinx.app (public gang URLs)
- ✅ Complete fighter data extraction:
  - Name, type, category, cost, XP
  - All 12 characteristics (M, WS, BS, S, T, W, I, A, Ld, Cl, Wil, Int)
  - Weapons with full profiles (range, accuracy, strength, AP, damage, ammo, traits)
  - Skills, equipment, rules, injuries
  - Special equipment (Cyberteknika, Genesmithing, Legendary Names)
- ✅ Multi-profile weapon support (alternate firing modes)
- ✅ Combi-weapon detection (paired weapons like combi-pistol)
- ✅ Dracula color theme for console output
- ✅ Debug mode with extensive logging
- ✅ Auto-load test gang on script start
- ✅ **Critical Fix:** HTML tag attribute handling (`<tbody>` → `<tbody`)

### Technical Achievements
- Plain text search (no regex) to avoid "pattern too complex" errors
- Whitespace-resilient HTML parsing
- Profile-trait pairing for weapon stats
- Backwards table search for weapons
- Error handling with `pcall()` wrappers
- Comprehensive documentation (600+ line parsing guide)

### Known Limitations
- Console output only (no UI yet)
- No persistent state between sessions
- No model interaction
- Manual gang URL configuration
- No activation tracking

---

## Phase 2: Interactive UI & Model Integration 🚧 NEXT

**Goal:** Transform console output into interactive buttons with model spawning and description writing.

### 2.1 Button UI System

**Priority:** HIGH  
**Complexity:** Medium

#### Features to Implement
- [ ] **Gang Load Button**
  - Fetch gang data from `GANG_URL`
  - Show loading state
  - Display fighter count on success
  - Error handling UI

- [ ] **Fighter Selection Grid**
  - Dynamic scaling based on gang size
  - Scrollable or multi-page layout for large gangs
  - Highlight selected fighter
  - Dynamic button generation from gang data

- [ ] **"Copy to Model" Button**
  - Detect miniatures placed on script object (3-unit radius)
  - Write formatted card to model's `description` field
  - Auto-move model 10 units away after copy
  - Success/error feedback

- [ ] **Refresh Button**
  - Reload gang data without restarting TTS
  - Preserve selected fighter if still exists

#### Technical Requirements
```lua
-- Button click functions MUST be global
-- Generate handlers for all fighters in gang (no artificial limit)
for i = 1, #gangFighters do
    _G["selectFighter_" .. i] = function()
        selectFighter(i)
    end
end

-- Create buttons with dynamic positioning
-- Calculate layout based on gang size
local columns = math.min(math.ceil(#gangFighters / 10), 4)  -- Max 4 columns
local buttonWidth = 2000 / columns
local spacing = 0.5

for i, fighter in ipairs(gangFighters) do
    local row = math.floor((i - 1) / columns)
    local col = (i - 1) % columns
    
    self.createButton({
        click_function = "selectFighter_" .. i,
        function_owner = self,
        label = fighter.name,
        position = {-1.5 + (col * 1.0), 1, -2 + (row * spacing)},
        width = buttonWidth,
        height = 400,
        font_size = 120,
        color = {0.8, 0.8, 0.8}
    })
end
```

#### Reference Format (from `example_card.md`)
```
[bbcode]M   WS  BS   S   T   W   I      A   
x"   x+   x+   x   x   x   x+   x         
[bbcode]Ld   Cl  Wil   Int    
x+   x+   x+   x+   

[cyan]Weapon Name[-]
[yellow]S      L      S      L      |  Str    Ap     D      Am   [-]
8"     16"    +1     -      |  4      -1     1      6+
  rapid fire (1), unwieldy, knockback
```

**Weapon Trait Formatting:**
- Trait keywords displayed as plain lowercase text list
- No color styling on traits
- Two spaces indent from weapon stats
- Comma-separated list format
- Per-profile traits shown after each profile's stats
- Weapon-level traits shown after all profiles

### 2.2 Rich Text Formatting for Model Descriptions

**Priority:** HIGH  
**Complexity:** Low

#### TTS BBCode Colors (Dracula Theme)
```lua
local COLORS = {
    cyan = "8be9fd",      -- Fighter name, weapon names, characteristic headers
    purple = "bd93f9",    -- Type/category, skills, profile names
    red = "ff5555",       -- Section headers (Weapons, Injuries)
    yellow = "f1fa8c",    -- Weapon stat headers only
    green = "50fa7b",     -- Equipment, ready state
    pink = "ff79c6",      -- Rules
    orange = "ffb86c"     -- (unused)
}
```

**Weapon Display Rules:**
- Weapon names in cyan
- Stat headers (S, L, Str, Ap, D, Am) in yellow, shown once per weapon
- Profile names (e.g., "Frag", "Krak") in purple if present
- Stat values in plain text (no color)
- Trait keywords in plain lowercase text (no color, no brackets)

#### Format Function Pattern
```lua
function formatFighterCard(fighter)
    local lines = {}
    lines[#lines + 1] = string.format("[%s]%s[-] [%s](%s)[-]",
        COLORS.cyan, fighter.name, COLORS.yellow, fighter.cost)
    -- ... build card text ...
    return table.concat(lines, "\n")
end
```

### 2.3 Spatial Object Detection

**Priority:** HIGH  
**Complexity:** Medium

#### Detection Algorithm
```lua
function getObjectsOnMe()
    local myPos = self.getPosition()
    local objects = getAllObjects()
    local objectsOnMe = {}
    
    for _, obj in ipairs(objects) do
        if obj.guid ~= self.guid then
            local objPos = obj.getPosition()
            local distance = math.sqrt(
                (myPos.x - objPos.x)^2 + 
                (myPos.y - objPos.y)^2 + 
                (myPos.z - objPos.z)^2
            )
            
            -- Within 3 units and above the script object
            if distance < 3 and objPos.y > myPos.y then
                objectsOnMe[#objectsOnMe + 1] = obj
            end
        end
    end
    
    return objectsOnMe
end
```

#### Model Movement After Copy
```lua
function copyToModelOnObject()
    local objects = getObjectsOnMe()
    local fighter = gangFighters[selectedFighterIndex]
    local cardText = formatFighterCard(fighter)
    
    for _, obj in ipairs(objects) do
        obj.setDescription(cardText)
        obj.setName("[" .. COLORS.cyan .. "]" .. fighter.name .. "[-]")
        
        -- Move 10 units away in X direction
        local pos = obj.getPosition()
        obj.setPositionSmooth({x = pos.x + 10, y = pos.y, z = pos.z})
        
        printToAll("Applied " .. fighter.name .. "'s card to model", {0.3, 1, 0.3})
    end
end
```

### 2.4 State Persistence

**Priority:** MEDIUM  
**Complexity:** Low

#### Save/Load Pattern
```lua
local gangFighters = {}
local selectedFighterIndex = nil

function onSave()
    local saveData = {
        gangURL = GANG_URL,
        selectedFighterIndex = selectedFighterIndex
        -- Don't save gangFighters (too large, fetch on load)
    }
    return JSON.encode(saveData)
end

function onLoad(saved_data)
    if saved_data ~= "" then
        local loaded = JSON.decode(saved_data)
        selectedFighterIndex = loaded.selectedFighterIndex
        GANG_URL = loaded.gangURL or GANG_URL
    end
    
    -- Auto-fetch gang data after 2 seconds
    Wait.time(function()
        fetchGangData(GANG_URL)
    end, 2)
end
```

---

## Phase 3: Advanced Features 🔮 FUTURE

**Goal:** Add gameplay-enhancing features for campaign management.

### 3.1 Activation Tracking

**Priority:** MEDIUM  
**Complexity:** Low

#### Features
- [ ] "Ready" / "Activated" / "Reset" buttons per fighter
- [ ] Visual indicator on fighter buttons (green = ready, red = activated)


#### Implementation
```lua
local activationStates = {}  -- {[fighter_id] = "ready"|"activated"|nil}

function toggleActivation(fighterIndex)
    local id = gangFighters[fighterIndex].id
    if activationStates[id] == "ready" then
        activationStates[id] = "activated"
    elseif activationStates[id] == "activated" then
        activationStates[id] = nil
    else
        activationStates[id] = "ready"
    end
    createFighterButtons()  -- Refresh UI
end
```

### 3.2 Damage Tracking

**Priority:** MEDIUM  
**Complexity:** High

#### Features
- [ ] Track current Wounds (W) vs maximum
- [ ] Track current Ammo (Am) for each weapon
- [ ] Injury markers (Flesh Wound, Seriously Injured)
- [ ] Persist damage state between sessions
- [ ] "Reset Damage" button

#### UI Design
- Increment/decrement buttons for W and Am
- Visual indicators (color changes when wounded)
- Tooltips showing max values

### 3.3 Card Spawning System

**Priority:** LOW  
**Complexity:** High

#### Features
- [ ] Spawn physical TTS cards with fighter data
- [ ] Front face: Portrait + name + type
- [ ] Back face: Full stat block (formatted like console output)
- [ ] Custom card deck generation
- [ ] Card art integration (if available from Gyrinx.app)

#### Technical Challenges
- TTS card object creation (`spawnObject()`)
- Image URL handling (need hosted images)
- Card deck JSON structure
- Performance with 50+ cards

### 3.4 Campaign Management

**Priority:** LOW  
**Complexity:** Very High

#### Features
- [ ] Multi-gang support (switch between gangs)
- [ ] XP tracking with manual increment buttons
- [ ] Injury roll results (table lookup)
- [ ] Advancement tracking (new skills, stat increases)
- [ ] Gang rating calculation
- [ ] Territory management

#### Data Structure
```lua
local campaign = {
    gangs = {
        [gang_uuid] = {
            url = "https://gyrinx.app/list/...",
            name = "Joe's Van Saar",
            fighters = {...},
            territories = {...},
            credits = 1000
        }
    },
    currentGangUUID = nil
}
```

### 3.5 Weapon Profile Toggle

**Priority:** LOW  
**Complexity:** Low

#### Features
- [ ] "Show Weapon Profiles" toggle button
- [ ] When OFF: Show only weapon names (compact mode)
- [ ] When ON: Show full stats (current behavior)
- [ ] Per-user preference (saved state)

---

## Phase 4: Polish & Distribution 📦 FUTURE

**Goal:** Prepare for public release and community adoption.

### 4.1 User Experience

- [ ] Tooltips on all buttons explaining functionality
- [ ] Error messages with clear next steps
- [ ] Loading spinners / progress indicators
- [ ] Success/failure audio cues
- [ ] Keyboard shortcuts (if TTS supports)

### 4.2 Configuration UI

- [ ] In-game gang URL input field
- [ ] Gang name display
- [ ] Theme selector (Dracula / Classic / Custom)
- [ ] Debug mode toggle button
- [ ] Settings persistence

### 4.3 Documentation

- [ ] Video tutorial (YouTube)
- [ ] Quick start guide (in-game help button?)
- [ ] Troubleshooting FAQ
- [ ] Update Gyrinx.app HTML parsing guide
- [ ] Publish to Steam Workshop

### 4.4 Testing & QA

- [ ] Test with all Necromunda gang types (Orlock, Goliath, Escher, etc.)
- [ ] Test with vehicle gangs (different stat layout)
- [ ] Test with small gangs (5-10 fighters)
- [ ] Test with large gangs (50-100+ fighters)
- [ ] Test with empty gangs
- [ ] Test with private Gyrinx gangs (should error gracefully)
- [ ] Load testing (multiple rapid refreshes)
- [ ] UI performance testing with maximum gang size

---

## Technical Architecture

### File Structure
```
necromunda-gyrinx-bridge/
├── gyrinx2tts.lua                 # Main script (single file for TTS)
├── tests/
│   ├── tts-plugin/               # TTS plugin integration tests
│   │   ├── Global.-1.ttslua      # Test script with debug logging
│   │   ├── GYRINX_HTML_PARSING_GUIDE.md  # 600+ line reference
│   │   └── config.lua            # Test gang URLs
│   └── example_card.md           # Format reference
├── README.md                     # Installation & usage guide
├── CONTRIBUTING.md               # Development guidelines
├── CHANGELOG.md                  # Version history
├── TTS_PLUGIN_SYNC.md           # Plugin configuration
└── .github/
    └── copilot-instructions.md  # AI agent context
```

### Core Modules (Conceptual - actual is single file)

1. **Parser** (`parseFighters()`, `parseFighterCard()`)
   - HTML extraction
   - Weapon profile parsing
   - Special equipment detection

2. **Formatter** (`formatFighterCard()`)
   - BBCode generation
   - Color theming
   - Layout management

3. **UI Manager** (`createFighterButtons()`, `selectFighter()`)
   - Button generation
   - State management
   - Event handling

4. **Data Fetcher** (`fetchGangData()`)
   - WebRequest wrapper
   - Error handling
   - Async callback management

5. **Model Manager** (`copyToModelOnObject()`, `getObjectsOnMe()`)
   - Spatial queries
   - Object manipulation
   - Position calculations

### Key TTS API Constraints

- **No standard Lua libraries** (`require()` unavailable)
- **Event-driven lifecycle** (`onLoad()`, `onSave()`, button clicks)
- **Global button functions** (must use `_G["funcName"]` pattern)
- **Async network** (`WebRequest.get()` with callbacks)
- **State persistence** (`JSON.encode()` / `JSON.decode()`)

---

## Success Metrics

### Phase 2 (Next)
- ✅ Button UI functional with fighter selection
- ✅ Model description writing works reliably
- ✅ Auto-movement after copy
- ✅ Gang data refreshable without restart
- ✅ State persists between sessions

### Phase 3 (Future)
- ✅ Activation tracking used in real games
- ✅ Damage tracking reduces manual bookkeeping
- ✅ Card spawning provides physical tokens
- ✅ Multi-gang support enables campaign play
- ✅ Supports gangs of any size (tested up to 100+ fighters)

### Phase 4 (Release)
- ✅ 100+ users via Steam Workshop
- ✅ 5+ community-submitted bug reports (and fixes)
- ✅ Documentation covers 90% of common issues
- ✅ Compatible with latest Gyrinx.app HTML structure

---

## Known Issues & Limitations

### Current (Phase 1)
- Console output only (no interactivity)
- HTML structure tightly coupled to Gyrinx.app (breaks if they update)
- Gang must be public (no authentication support)
- Very large gangs (100+ fighters) may have UI performance issues

### Future Challenges
- **HTML brittleness**: Gyrinx.app updates will break parsing
  - *Solution:* Comprehensive test suite, version detection
- **Image hosting**: Card spawning needs image URLs
  - *Solution:* Placeholder images, Imgur integration?
- **Performance**: Very large gangs (100+ fighters) may cause UI lag
  - *Solution:* Lazy loading, button pooling, optimized refresh
- **TTS API limits**: Description length, object count
  - *Solution:* Text truncation, cleanup routines, object pooling

---

## Community & Contribution

### How to Contribute

1. **Test with your gang:** Report bugs with gang URL
2. **Submit HTML samples:** Help update parsing guide
3. **Request features:** Open GitHub issues
4. **Code contributions:** See `CONTRIBUTING.md`
5. **Documentation:** Improve guides, add examples

### Communication Channels
- GitHub Issues: Bug reports & feature requests
- Discord: Real-time help & discussion (TODO: create server)
- Steam Workshop: Reviews & ratings (TODO: publish)

---

## References

### Internal Documentation
- `GYRINX_HTML_PARSING_GUIDE.md` - Comprehensive HTML structure reference
- `.github/copilot-instructions.md` - AI agent coding guidelines
- `TTS_PLUGIN_SYNC.md` - Plugin auto-sync configuration
- `CONTRIBUTING.md` - Development workflow

### External Resources
- [Gyrinx.app GitHub](https://github.com/gyrinx-app/gyrinx) - Open source roster manager
- [TTS API Reference](https://api.tabletopsimulator.com/) - Lua scripting docs
- [Necromunda Rules](https://www.warhammer-community.com/necromunda/) - Game reference
- [Dracula Theme](https://draculatheme.com/) - Color scheme source

---

## Version History

### v2.1 (Current - November 20, 2025)
- ✅ Phase 2 Complete: Interactive UI with model integration
- ✅ **CRITICAL FIX:** Multi-profile weapon parsing (shotguns, grenade launchers)
  - Fixed weapon extraction to use `isFirstRowspanInTbody` flag
  - First rowspan in tbody = weapon, subsequent rowspans = profiles
  - Historical cases: Special Week's grenade launcher, Orlock shotgun (4 ammo types)
- ✅ All fighter data fields extracting correctly
- ✅ Comprehensive documentation updated with multi-profile weapon structure
- 🎯 Ready for Phase 3 features

### v1.1 (November 20, 2025)
- ✅ Complete Phase 1: Console parsing functional
- ✅ Initial multi-profile weapon support
- 🐛 Bug: Multi-ammo weapons creating separate weapon entries

### v1.0 (Initial - November 16, 2025)
- Initial HTML parsing prototype
- Basic console output
- Dracula color theme

---

**Next Steps:**
1. Implement button UI system (2.1)
2. Add rich text formatting (2.2)
3. Build spatial object detection (2.3)
4. Add state persistence (2.4)

**Timeline:** Phase 2 target completion ~2-3 weeks of active development
