# Necromunda Gyrinx Bridge for Tabletop Simulator

**v2.3.0 - Campaign Spawner**

A Tabletop Simulator (TTS) Lua script that fetches Necromunda gang rosters from [Gyrinx.app](https://gyrinx.app) and displays them as formatted character cards in TTS.

## Features

- 🎯 **Campaign Support** - Enter a campaign URL to spawn tokens for all gangs with their colors
- 👥 **Multi-Player Support** - Each player can spawn their own independent gang tokens
- 🎮 **In-Game UI** - Select fighters via interactive buttons in TTS
- 🎨 **Gang Colors** - Tokens automatically tinted with gang colors from Gyrinx
- 💰 **Gang Ratings** - Credit values displayed on each gang token
- 🎨 **Dracula Theme** - Beautiful color-coded character sheets
- 📊 **Complete Stats** - Characteristics, weapons (with full stats), skills, equipment, injuries, and more
- 🔄 **Live Updates** - Refresh gang data from Gyrinx.app without restarting TTS
- 🤖 **Auto-Assignment** - Place a model on the object and copy fighter data to it automatically
- 🚗 **Vehicle/Crew Pairing** - Automatically pairs vehicles with crew using tooltip data from Gyrinx
- 🏆 **Gang-Specific Features** - Gene-smithing (Goliath), Cyberteknika (Van Saar), Legendary Names (Orlock), Powers (Psykers)
- ↔️ **Smart Movement** - Models automatically move aside after data is applied

## Installation

1. In Tabletop Simulator, create or select an object (recommend using a tablet or card)
2. Right-click the object → **Scripting** → Open the Lua editor
3. Copy the entire contents of `gyrinx2tts.lua`
4. Paste into the TTS Lua editor
5. **Save & Play**

## First Use

1. Click the **"Enter Campaign or Gang URL"** button in TTS
2. Enter either:
   - **Campaign URL** (e.g., `https://gyrinx.app/campaign/YOUR-CAMPAIGN-UUID`) - Shows all gangs in the campaign
   - **Gang URL** (e.g., `https://gyrinx.app/list/YOUR-GANG-UUID`) - Directly loads a single gang
3. For campaign URLs:
   - Colored gang buttons appear showing each gang in the campaign
   - Click any gang button to spawn a token with that gang preloaded
   - Gang tokens are automatically tinted with the gang's color
4. For gang URLs:
   - A new token spawns with that gang loaded
   - Fighter buttons appear - click any fighter to select them

**Campaign Features:**
- Gang colors automatically extracted from Gyrinx and applied to buttons and tokens
- Gang ratings (credits) displayed on each token's description
- Gang names colored to match their assigned colors
- Select Gang to Spawn title has white background for visibility

**Multi-Player Usage**: Each player can spawn their own gang tokens independently. The spawner remains clean and can create unlimited gang tokens.

**Important:** Your gangs/campaigns must be set to **public** visibility on Gyrinx.app for the script to access them.

## Vehicle/Crew Support

The script automatically detects and pairs vehicles with their crew:

- **Tooltip-based pairing**: Uses Gyrinx's internal link data (most reliable)
- **Equipment matching**: Falls back to matching vehicle names in crew equipment
- **Proximity fallback**: Pairs closest unpaired vehicle/crew if no match found

**Best Practice**: Give each vehicle a unique name in Gyrinx for accurate pairing.

Combined units display as: `"crew name" piloting "vehicle name"` with [VEHICLE+CREW] designation.

## Usage

### In Tabletop Simulator:

1. **Load Gang** - Click "Refresh" to reload your roster from Gyrinx
2. **Select Fighter** - Click a fighter's name button to select them
3. **Mark Status** - Use "Ready" or "Activated" buttons to track fighter status
4. **Toggle Display** - Customize what shows: full weapon profiles, skills, rules, credits
5. **Copy to Model** - Place a miniature on the script object, then click "Copy to Model"
6. The fighter's data will be written to the model's description (hover to view)
7. The model automatically moves to the edge of the control panel

### Display Toggles

- **Full Wpn / Wpn Names** - Show complete weapon stats or just weapon names
- **Skills / No Skills** - Toggle skills display on/off
- **Rules / No Rules** - Toggle rules display on/off  
- **Credits / No Credits** - Toggle credit values in equipment/gene-smithing/cyberteknika

### Viewing Fighter Data

Hover over any model with copied data to see the full character card:
- Name, type, category, cost, XP
- All 12 characteristics (M, WS, BS, S, T, W, I, A, Ld, Cl, Wil, Int)
- Weapons with complete stats (range, accuracy, strength, AP, damage, ammo, traits)
- Skills, equipment, rules, injuries
- Gang-specific: Gene-smithing (Goliath), Cyberteknika (Van Saar), Legendary Names (Orlock)
- Vehicle stats if applicable (combined crew+vehicle units)

## Color Scheme

The script uses the Dracula (Emacs) color theme:

- **Cyan** (`#8be9fd`) - Fighter name, weapon names, characteristic headers
- **Yellow** (`#f1fa8c`) - Weapon stat headers (shown once per weapon)
- **Purple** (`#bd93f9`) - Category/type, skills, weapon profile names
- **Green** (`#50fa7b`) - Equipment, ready state
- **Pink** (`#ff79c6`) - Rules
- **Red** (`#ff5555`) - Section headers (Weapons, Injuries)

**Weapon Trait Formatting:**
- Trait keywords are displayed as plain lowercase text with no color styling
- Traits appear as comma-separated list below each weapon profile
- Two spaces indent from weapon stats for readability

## Example Output

```
Symboli Rudolf (Queen)
Leader | Cost: 270¢ | XP: 0 XP

M    WS   BS   S    T    W    I    A
5"   3+   3+   3    3    2    2    2  
     Ld   Cl   Wil  Int   
     5+   5+   6+   7+     

Weapons
Needle rifle
S      L      S      L      |  Str    Ap     D      Am   
9"     18"    +2     -      |  -      -2     -      6+
  scarce, silent, toxin

Power fist
S      L      S      L      |  Str    Ap     D      Am   
-      E      -      -      |  +3     -2     2      -
  melee, power, unwieldy

Skills
Dodge, Lightning Reflexes, Spring Up

Equipment
Mesh armour
```

## Technical Details

### TTS Environment Constraints

- No standard Lua libraries (`require()` not available)
- No file I/O operations
- Sandboxed environment with TTS-specific globals
- All parsing done with plain text search (no regex patterns)

### HTML Parsing

The script uses character-by-character HTML parsing to extract data from Gyrinx.app's Bootstrap 5 layout:

- Fighter cards identified by `<h3 class="h5 mb-0">` headers
- Characteristics extracted from table tbody cells
- Skills from `data-bs-toggle="tooltip"` spans
- Weapons from tbody sections with `rowspan="2"` patterns
- Equipment, rules, and injuries from badge spans

### API

While primarily designed for interactive use, the script exposes legacy functions:

```lua
-- Attach fighter data to any object by GUID
attachFighterCardToObject(object_guid, fighter_index)

-- Attach to currently selected object
attachToSelected(fighter_index)
```

## Troubleshooting

**"Failed to load gang data!"**
- Check that your gang URL is correct
- Ensure the gang is set to public on Gyrinx.app
- Verify TTS has internet access

**"No fighters found"**
- The gang may be empty
- HTML structure may have changed (check Gyrinx.app updates)

**Fighters missing stats**
- Some fighters may not have all fields filled out on Gyrinx.app
- Partial data will still display

**Weapons not showing stats**
- Verify the weapon has stats entered on Gyrinx.app
- Some weapons (like grenades) may not have full stat lines

## Contributing

This is a single-file monolithic TTS script. To modify:

1. Edit `gyrinx2tts.lua` in your preferred editor
2. Test by copying the entire file into TTS
3. Check the TTS console (Tab key) for errors
4. Submit pull requests with clear descriptions

### Development Notes

- See `.github/copilot-instructions.md` for detailed architecture notes
- All HTML parsing uses `string.find(pattern, pos, true)` for plain text search
- Character-by-character tag stripping avoids pattern complexity issues
- Button click functions must be generated as globals in `_G` namespace

## Limitations

- Gyrinx.app must have the gang set to public visibility
- Maximum 50 fighters supported (14 visible at once in button grid)
- Requires stable internet connection in TTS
- HTML structure changes in Gyrinx.app may break parsing

## Credits

- **Gyrinx.app** - Excellent Necromunda roster manager by the community
- **Tabletop Simulator** - Berserk Games
- **Necromunda** - Games Workshop
- **Dracula Theme** - Zeno Rocha

## Links

- [Gyrinx.app](https://gyrinx.app) - Necromunda roster manager
- [Tabletop Simulator](https://www.tabletopsimulator.com/)
- [Necromunda on Warhammer Community](https://www.warhammer-community.com/necromunda/)

## License

MIT License - See LICENSE file for details

---

**Note:** This is an unofficial fan-made tool. Necromunda is a trademark of Games Workshop Ltd. This project is not affiliated with, endorsed by, or sponsored by Games Workshop.

## Technical Details

- **Web Scraping**: Parses HTML from Gyrinx.app to extract fighter data
- **State Persistence**: Saves selected fighter between play sessions
- **Dynamic UI**: Buttons are generated based on loaded fighters (supports up to 50 fighters)
- **Multi-model Support**: Can apply stats to multiple models at once if multiple are placed on the object

## Credits

Created for Necromunda gang management in Tabletop Simulator.
Fighter data sourced from [Gyrinx.app](https://gyrinx.app).

This project provides a bridge between the Necromunda Gyrinx app and Tabletop Simulator, allowing users to fetch fighter data from the Gyrinx app and format it for use in Tabletop Simulator.

## Overview

The main script, `gyrinx2tts.lua`, is responsible for:

- Fetching fighter data from the Gyrinx app.
- Formatting the fighter data into cards suitable for Tabletop Simulator.
- Providing functions to attach fighter cards to objects in the game.

## Features

- **Fighter Class**: Contains methods for creating and formatting fighter cards.
- **Data Fetching**: Retrieves fighter data from the specified Gyrinx app URL.
- **Card Attachment**: Allows users to attach fighter cards to selected objects in Tabletop Simulator.

## Usage

1. **Setup**: Ensure you have Tabletop Simulator installed and running.
2. **Load the Script**: Load the `gyrinx2tts.lua` script in Tabletop Simulator.
3. **Fetch Fighter Data**: Use the command:
   ```
   fetchGangData('<GANG_URL>')
   ```
   Replace `<GANG_URL>` with the URL of your gang data from the Gyrinx app.

4. **Attach Fighter Card**: To attach a fighter card to a selected object, use:
   ```
   attachToSelected(fighter_number)
   ```
   Replace `fighter_number` with the index of the fighter you wish to attach.

## Commands

- `fetchGangData('<GANG_URL>')`: Fetches gang data from the specified URL.
- `attachToSelected(fighter_number)`: Attaches the specified fighter card to the currently selected object.

## Notes

- Ensure that the fighter data is correctly formatted in the Gyrinx app for optimal results.
- The script is designed to work with the latest version of Tabletop Simulator. Compatibility with older versions is not guaranteed.

## Development and Testing

The `tests/` directory contains debugging and testing tools:

- **`src/`** - Debug versions of the core modules (fetcher, parser, formatter, fighter)
- **`test_parser.lua`** - Unit tests for parser functions
- **`sample_data.html`** - Sample HTML data for testing
- **`config.lua`** - Configuration settings for debug/test runs
- **`output/`** - Directory for test output files

To run the debug/test tools:
```bash
cd tests
lua src/main.lua
```

See `tests/README_TESTS.md` for more details on the testing framework.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.