# Gyrinx HTML Structure Reference

**IMPORTANT:** Gyrinx is open source! Repository: https://github.com/gyrinx-app/gyrinx

## Key Finding: Table-Based Structure (Not Heading-Based)

The parser was originally written expecting heading-based HTML structure like:
```html
<h5>Weapons</h5>
<table>...</table>

<h5>Skills</h5>
<ul>...</ul>
```

**ACTUAL STRUCTURE** uses Django templates with table rows:
```html
<table class="table table-sm table-borderless table-fixed mb-0">
  <thead>
    <tr>
      <th>M</th><th>WS</th><!-- characteristics -->
    </tr>
  </thead>
  <tbody>
    <tr><!-- characteristic values --></tr>
  </tbody>
  <tbody class="table-group-divider">
    <tr class="fs-7">
      <th scope="row" colspan="4">Rules</th>
      <td colspan="8">Gang Hierarchy (Leader), Gang Leader, ...</td>
    </tr>
    <tr class="fs-7">
      <th scope="row" colspan="4">Skills</th>
      <td colspan="8">Dodge, Lightning Reflexes, Spring Up</td>
    </tr>
    <tr class="fs-7">
      <th scope="row" colspan="4">Gear</th>
      <td colspan="8">Mesh armour (15¢), Armoured undersuit (25¢), ...</td>
    </tr>
  </tbody>
</table>
```

## Source Templates

From https://github.com/gyrinx-app/gyrinx/tree/main/gyrinx/core/templates/core/includes/

### Fighter Card Structure

1. **Main template**: `fighter_card_content_inner.html`
   - Lines 22-39: Rules row with `<th scope="row">Rules</th>` followed by `<td>` with comma-separated rules
   - Lines 59-79: XP row, then Skills row with `<th scope="row">Skills</th>`
   - Lines 209-228: Gear row with `<th scope="row">Gear</th>`

2. **Weapons table**: `list_fighter_weapons.html`
   - Has separate table structure with `<th scope="col">Weapons</th>` header
   - Rows contain weapon name in first `<td>`, followed by stat columns

### Data Extraction Patterns

#### Rules
```html
<tr class="fs-7">
  <th scope="row" colspan="X">Rules</th>
  <td colspan="Y">
    <span>Gang Hierarchy (Leader)</span>, <span>Gang Leader</span>, ...
  </td>
</tr>
```
- Search for: `<th scope="row"` followed by `Rules</th>`
- Extract: `<td>` content after Rules label
- Format: Comma-separated, may be in `<span>` tags or plain text

#### Skills
```html
<tr class="fs-7">
  <th scope="row" colspan="X">Skills</th>
  <td colspan="Y">
    <span>Dodge</span>, <span>Lightning Reflexes</span>, <span>Spring Up</span>
  </td>
</tr>
```
- Search for: `<th scope="row"` followed by `Skills</th>`
- Extract: `<td>` content after Skills label
- Format: Comma-separated skill names

#### Gear/Equipment
```html
<tr class="fs-7">
  <th scope="row" colspan="X">Gear</th>
  <td colspan="Y">
    <span>Mesh armour (15¢)</span>, <span>Armoured undersuit (25¢)</span>, ...
  </td>
</tr>
```
- Search for: `<th scope="row"` followed by `Gear</th>`
- Extract: `<td>` content after Gear label
- Format: Comma-separated, includes cost in parentheses with ¢ symbol
- NOTE: Gyrinx uses "Gear" not "Equipment" in the table labels

#### Weapons

**CRITICAL: Multi-Profile Weapon Structure**

Weapons with multiple ammo types/profiles (e.g., Shotgun, Grenade Launcher) are structured in a **single tbody** with **multiple rowspan rows**:

```html
<table class="table table-sm table-borderless mb-0 fs-7">
  <thead class="table-group-divider">
    <tr>
      <th scope="col">Weapons</th>
      <th class="text-center" scope="col">S</th>
      <th class="text-center" scope="col">L</th>
      <!-- 8 stat columns: S, L, S, L, Str, AP, D, Am -->
    </tr>
  </thead>
  <tbody class="table-group-divider">
    <!-- FIRST rowspan = Main weapon -->
    <tr>
      <td rowspan="2">Shotgun (30¢)</td>
      <td class="text-center fs-7">4"</td>
      <td class="text-center fs-7">12"</td>
      <!-- stats for first profile -->
    </tr>
    <tr>
      <td colspan="8">blast, knockback, rapid fire (1)</td>
    </tr>
    
    <!-- SUBSEQUENT rowspans = Ammo type profiles -->
    <tr>
      <td rowspan="2">- scatter ammo</td>
      <td class="text-center fs-7">-</td>
      <td class="text-center fs-7">-</td>
      <!-- stats for scatter ammo -->
    </tr>
    <tr>
      <td colspan="8">scatter</td>
    </tr>
    
    <tr>
      <td rowspan="2">- solid ammo</td>
      <td class="text-center fs-7">-</td>
      <td class="text-center fs-7">-</td>
      <!-- stats for solid ammo -->
    </tr>
    <tr>
      <td colspan="8">knockback</td>
    </tr>
    
    <!-- More ammo types... -->
  </tbody>
</table>
```

**Parsing Rules for Multi-Profile Weapons:**

1. **Each tbody section = One weapon** (may have multiple profiles)
2. **First `<td rowspan>` in tbody = Main weapon name** (e.g., "Shotgun (30¢)")
   - Create new weapon object
   - Strip cost notation: `(30¢)`, `(+15¢)`, `(-10¢)`
3. **Subsequent `<td rowspan>` in same tbody = Profile/Ammo type** (e.g., "- scatter ammo")
   - Add as profile under current weapon
   - Strip leading dash: `- scatter ammo` → `scatter ammo`
   - Store as `profile_name` field
4. **Rows with `colspan="8"` or `colspan="9"` = Traits row**
   - Attach to the profile from previous stats row
   - Store as lowercase, comma-separated text (no color styling)
5. **Stats rows have 8 `<td>` cells** (weapon name + 8 stats)
   - Extract: Range S, Range L, Acc S, Acc L, Str, AP, D, Am

**Example Result Structure:**
```lua
{
  name = "Shotgun",
  profiles = {
    {
      profile_name = nil,  -- Main profile (default ammo)
      rg_short = "4\"",
      rg_long = "12\"",
      strength = "3",
      ap = "-",
      damage = "2",
      ammo = "4+",
      traits = "blast, knockback, rapid fire (1)"
    },
    {
      profile_name = "scatter ammo",
      rg_short = "-",
      rg_long = "-",
      strength = "3",
      ap = "-",
      damage = "1",
      ammo = "4+",
      traits = "scatter"
    },
    {
      profile_name = "solid ammo",
      rg_short = "-",
      rg_long = "-",
      strength = "4",
      ap = "-1",
      damage = "2",
      ammo = "6+",
      traits = "knockback"
    }
    -- More profiles...
  }
}
```

**Simple Single-Profile Weapons:**
```html
<tbody class="table-group-divider">
  <tr>
    <td rowspan="2">Autopistol (10¢)</td>
    <td class="text-center fs-7">12"</td>
    <td class="text-center fs-7">24"</td>
    <!-- stats -->
  </tr>
  <tr>
    <td colspan="8">rapid fire (1)</td>
  </tr>
</tbody>
```
- Single tbody, single rowspan
- Creates one weapon with one profile (no profile_name)

## Common Pitfalls

1. ❌ **DON'T** search for `<h5>Weapons</h5>`, `<h5>Skills</h5>`, `<h5>Rules</h5>` - these don't exist
2. ❌ **DON'T** expect `<ul><li>` lists for skills/rules - they use table rows
3. ✅ **DO** search for `<th scope="row">` followed by label like "Skills</th>", "Gear</th>", "Rules</th>"
4. ✅ **DO** extract content from `<td>` that follows the label
5. ✅ **DO** split by commas and strip HTML tags to get individual items
6. ✅ **DO** handle both plain text and `<span>`-wrapped content

## Filter Patterns

### Fighters to Skip
- Stash card: `<h3 class="h5 mb-0">Stash</h3>`
- Dead fighters: `bg-danger">Dead</span>`
- Retired fighters: `bg-secondary">Retired</span>`

### Card Identification
- Cards start with: `class="card g-col-12 g-col-md-6 g-col-xl-4 break-inside-avoid`
- Each card has: `id="<fighter_id>"`

## Parser Implementation Notes

### extractSkills() Pattern
```lua
-- Search for: <th scope="row" ... >Skills</th>
-- Then find following: <td>...</td>
-- Strip HTML tags, split by commas
```

### extractEquipment() Pattern  
```lua
-- Search for: <th scope="row" ... >Gear</th>
-- Multiple rows possible (different gear categories)
-- Strip HTML, handle currency symbols (¢)
```

### extractRules() Pattern
```lua
-- Search for: <th scope="row" ... >Rules</th>
-- Usually first row in tbody.table-group-divider
-- Comma-separated rule names
```

### extractWeapons() Pattern
```lua
-- Search for: <th scope="col">Weapons</th>
-- Different structure: separate weapons table
-- CRITICAL: Each tbody = ONE weapon (may have multiple profiles)
-- First rowspan in tbody = weapon name
-- Subsequent rowspans in same tbody = profile names (ammo types)
-- Parse first <td> for name, subsequent <td> for stats

function extractWeapons(cardHtml)
    local weapons = {}
    
    -- Find weapons table
    -- Process each <tbody> section
    for each tbody do
        local currentWeapon = nil
        local isFirstRowspanInTbody = true  -- KEY FLAG
        
        for each <tr> in tbody do
            if has_colspan then
                -- Traits row (attach to pending profile)
            elseif has_rowspan then
                if isFirstRowspanInTbody then
                    -- Create NEW WEAPON
                    currentWeapon = {name = weaponName, profiles = {}}
                    isFirstRowspanInTbody = false
                else
                    -- Add PROFILE NAME (e.g., "scatter ammo")
                    profileName = weaponName  -- Strip leading dash
                end
                -- Extract 8 stats, create profile
            end
        end
    end
    
    return weapons
end
```

**Historical Cases:**
- **Special Week's Grenade Launcher** (Pretty Derby gang): One weapon, profiles for "frag" and "krak"
- **Orlock Shotgun**: One weapon, profiles for "scatter ammo", "solid ammo", "executioner ammo", "inferno ammo"
- **Simple weapons** (Autopistol, Stub Gun): One weapon, one unnamed profile

## Testing Data

Test gang: https://gyrinx.app/list/49527246-a948-4b1f-bd28-bb862aa93cf5 (Pretty Derby)
- 12 fighters
- 266KB HTML
- Has weapons, skills, gear, rules examples

## Version History

- 2025-11-20: **FIX** - Characteristics extraction substring bug
  - **Problem**: Fighter "Special Week" showing M="-" instead of M=5", all fighters affected
  - **Root Cause**: Incorrect substring calculation when extracting `<th>` and `<td>` content
    - Used `findPlain()` which returns START position of search string (e.g., `</th>`)
    - Then tried to compensate with hardcoded offsets like `thEnd - 4` which was incorrect
    - First characteristic name was extracted as `"th class=\"text-center border-bottom fs-7 \" scope=\"col"` instead of `"M"`
  - **Solution**: 
    - Use `thEnd - 1` to get content just before closing tag
    - Use `cleanText(content:sub(valueStart + 1))` to get everything after `>` character
    - Removed hardcoded offset calculations
  - **Pattern**:
    ```lua
    local thEnd = findPlain(thead, "</th>", thStart)
    local thContent = thead:sub(thStart, thEnd - 1)  -- Not thEnd - 4!
    local valueStart = findPlain(thContent, ">")
    local name = cleanText(thContent:sub(valueStart + 1))  -- Everything after >
    ```
  - **Test Case**: All fighters, verified with Special Week (Sister/Specialist) in Pretty Derby gang

- 2025-11-20: **CRITICAL FIX** - Multi-profile weapon parsing (shotguns, grenade launchers)
  - **Problem**: Grenade launcher profiles showing as separate weapons instead of grouped profiles
  - **Root Cause**: Both weapon names AND traits rows use `colspan="9"`, causing ambiguity
  - **Solution**: Use state-based disambiguation with `pendingProfile` flag:
    - If `pendingProfile` exists → current colspan="9" row is traits (attach to profile)
    - If `pendingProfile` is nil → current colspan="9" row is weapon name (create weapon)
  - **Additional Issue**: Bootstrap icon `<i class="bi-dash">` in HTML caused false positive in dash detection
    - Fixed by checking if cleaned text IS a dash, not if HTML contains "bi-dash" string
  - **Pattern**: `isFirstRowspanInTbody` flag distinguishes weapons (first rowspan) from profiles (subsequent rowspans)
  - **Test Cases**: 
    - Special Week's grenade launcher (4 profiles: frag, krak, choke gas, smoke)
    - Orlock shotgun (4 ammo types: scatter, solid, executioner, inferno)
  - **Display Format**: Weapon name in cyan (once), profile names in purple, traits in plain lowercase text
- 2024-11-20: Discovered actual structure via GitHub source code inspection
- 2024-11-20: Rewrote extractSkills(), extractEquipment(), extractRules() to use table row pattern
- 2024-11-20: Updated extractWeapons() to search for `<th scope="col">Weapons</th>`

## References

- GitHub: https://github.com/gyrinx-app/gyrinx
- Template path: `gyrinx/core/templates/core/includes/`
- Key file: `fighter_card_content_inner.html`
- Weapons file: `list_fighter_weapons.html`
