# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.3.0] - 2025-11-24 🎯 Campaign Spawner

### Added
- **Campaign URL Support**: Enter a campaign URL to see all gangs in the campaign
- **Gang Selection UI**: Single-column button layout showing all gangs with their colors
- **Gang Color Extraction**: Automatically extracts and applies gang colors from Gyrinx HTML
- **Gang Rating Display**: Shows gang credits (e.g., "3884¢") in token description
- **Colored Gang Names**: Gang names displayed in their assigned colors using rich text format
- **Auto-spawning**: Click a gang button to spawn a new token with that gang preloaded
- **Gang Token Tinting**: Spawned tokens are immediately tinted with the gang's color
- White background on "Select Gang to Spawn" title for better visibility

### Changed
- Initial button now says "Enter Campaign or Gang URL" for clarity
- Loading message updated to "Fetching gang roster" for accuracy
- Gang selection buttons use actual gang colors from Gyrinx data
- Token descriptions now include gang rating on first line
- Campaign parsing optimized with Wait.frames() for better UI responsiveness

### Technical
- HTML parsing extracts gang colors from `background-color: #XXXXXX` within `<a>` tags
- Gang rating extraction finds `¢` character and searches backwards for digits
- Hex color conversion to RGB (0-1 range) for TTS ColorDiffuse property
- Dynamic click handler generation for up to 50 campaign gangs
- Player-specific dialogs maintain multi-player compatibility

## [2.2.0] - 2025-11-21 ✨ Multi-Player Ready

### Added
- **Multi-Player Support**: Each player can now spawn independent gang tokens
  - Player-specific URL dialogs using `Player[playerColor].showInputDialog()` (only visible to clicking player)
  - Each gang URL spawns a brand new token with independent state and data
  - Multiple players can load different gangs simultaneously without interference
  - No more dialog conflicts or shared state between players
- **Spawn New Gang Button**: Button now clearly labeled "Spawn New Gang" instead of "Enter Gang URL"
- Automatic token spawning at offset position (5 units to the right, 1 unit up)

### Changed
- URL input dialog now player-specific instead of always showing to Player 1
- Each gang list creates its own independent token rather than reusing existing one
- Spawner token remains clean and can spawn unlimited gang tokens

## [2.1.0] - 2025-11-21

### Added
- **Tooltip-based vehicle/crew pairing**: Vehicles now extract linked crew name from Gyrinx HTML tooltips (`title="This vehicle is linked to {name} via gear"`)
- Two-pass pairing algorithm: PASS 1 = tooltip links (guaranteed correct), PASS 2 = equipment/proximity fallback for unpaired crew
- Vehicle-centric iteration order ensures tooltip links pair before proximity fallback
- **Powers support**: Psyker/Wyrd powers now extracted and displayed (e.g., "Misfortune" for Deathmaiden)
- Legendary Names support for Orlock gang (displays trait from "Legendary Names" field)
- Enhanced debug logging for vehicle/crew pairing diagnostics
- Warning messages for duplicate vehicle names (requires unique names for accurate pairing)
- Gang-specific categories with credit toggles: Gene-smithing (Goliath), Cyberteknika (Van Saar), Legendary Names (Orlock), Powers (Psykers)
- Combined crew+vehicle units display as "[VEHICLE+CREW]" designation
- **Seamless vehicle+crew characteristic merging**: Vehicle stats (M, BS, Fr, Sd, Rr, HP, Hnd, Sv) + crew mental stats (Ld, Cl, Wil, Int)
- Combined weapons, equipment, and rules from both crew and vehicle
- Gang name extraction from HTML and display on Load button
- Improved model spacing (5.5 units from tool, 3 units between models) to prevent collisions
- **Reorganized UI layout**: Better button spacing, unique colors for all toggles, larger fonts

### Changed
- Vehicle pairing now prioritized: 1) Tooltip link (most reliable), 2) Equipment name match, 3) Proximity
- Fighter structure: Added `linked_crew_name` field for tooltip-based pairing, added `powers` field
- Crew detection enhanced: Checks both category="Crew" AND "Vehicle Crew" rule
- Proximity fallback now uses tiebreaker (prefers earlier vehicle index to match Gyrinx ordering)
- Combined fighters now use crew cost/XP only (not summed with vehicle)
- **Weapon stat alignment fixed**: Headers now properly align with stat values using correct spacing
- Button layout reorganized: Row 1 = toggles (Weapon Profiles/Skills/Rules/Credits), Row 2 = Ready/Activated/Copy to Model
- Toggle buttons now have unique colors: Weapon Profiles (Cyan), Skills (Purple), Rules (Pink), Credits (Orange)

### Fixed
- Vehicle-crew pairing reversed issue (dozer was pairing with wrong vehicle)
- Proximity fallback executing when tooltip data available
- XP display showing "0 XP XP" (removed duplicate suffix)
- Credit values persisting when toggle disabled
- **Weapon stat headers now align perfectly with stat values** (fixed spacing issues)
- Vehicle+crew characteristic display now shows unified stat block with correct format
- Model collision issues resolved with improved spacing algorithm
- Powers category now properly extracted and displayed for all psyker fighters

### Removed
- Border class detection code (unused, never functional)
- Obsolete NOTE comments about future pet/vehicle linking

## [1.0.0] - 2025-11-16

### Added
- Initial release of Necromunda Gyrinx Bridge for Tabletop Simulator
- Interactive button UI for fighter selection
- Auto-fetch gang data from Gyrinx.app on load
- Complete fighter stat card formatting with Dracula color theme
- Full weapon stats display (range, accuracy, strength, AP, damage, ammo, traits)
- Skills extraction from tooltip spans
- Equipment, rules, and injuries parsing
- Model auto-movement (10 units in X direction after copy)
- Persistent fighter selection between sessions
- Support for up to 50 fighters (14 visible at once)
- Refresh button to reload gang data
- "Copy to Model" button for easy data application
- Spatial detection for models placed on script object
- Rich text color formatting:
  - Cyan (#8be9fd) for fighter names and headers
  - Green (#50fa7b) for equipment and weapon stat headers
  - Pink (#ff79c6) for rules
  - Purple (#bd93f9) for skills and categories
  - Red (#ff5555) for weapons and injuries headers
  - Yellow (#f1fa8c) for weapon names
- HTML parsing using plain text search (no regex)
- Character-by-character tag removal for TTS compatibility
- HTML entity decoding (&quot;, &amp;, &nbsp;, etc.)
- Legacy API functions for advanced users

### Technical
- Single-file monolithic TTS Lua script
- No external dependencies (pure TTS environment)
- Bootstrap 5 HTML structure parsing
- Fighter data structure with metatables
- Dynamic button generation via global namespace
- WebRequest async callback pattern
- State persistence via onSave/onLoad hooks

[1.0.0]: https://github.com/yourusername/necromunda-gyrinx-bridge/releases/tag/v1.0.0
