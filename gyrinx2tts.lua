-- Necromunda Gyrinx Bridge v2.2.0
-- Interactive TTS script for displaying Necromunda gang rosters from Gyrinx.app
-- Multi-Player Ready: Each player can spawn independent gang tokens, player-specific dialogs

-- Configuration
local GANG_URL = ""
local GANG_NAME = ""
local CAMPAIGN_URL = ""

-- State management
local gangFighters = {}
local selectedFighterIndex = nil
local inputActive = false
local activationState = nil  -- nil, "ready", or "activated"
local showWeaponProfiles = true  -- Toggle full weapon stats vs names only
local showSkills = true  -- Toggle skills display
local showRules = true  -- Toggle rules display
local showCredits = false  -- Toggle credit values display
local campaignGangs = {}  -- Store extracted campaign gangs

-- Dracula theme colors for TTS
local COLORS = {
    cyan = "8be9fd",
    purple = "bd93f9",
    red = "ff5555",
    yellow = "f1fa8c",
    green = "50fa7b",
    pink = "ff79c6",
    orange = "ffb86c",
    comment = "6272a4"
}

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

-- Decode HTML entities (both named and numeric)
local function decodeHTMLEntities(text)
    if not text then return "" end
    
    -- Decode numeric entities (hex format: &#xHH; or &#xHHHH;)
    -- Process character-by-character to avoid pattern complexity issues
    local result = {}
    local i = 1
    while i <= #text do
        if text:sub(i, i+2) == "&#x" or text:sub(i, i+1) == "&#" then
            local isHex = text:sub(i, i+2) == "&#x"
            local startPos = isHex and i+3 or i+2
            local endPos = text:find(";", startPos, true)
            
            if endPos then
                local numStr = text:sub(startPos, endPos-1)
                local num = tonumber(numStr, isHex and 16 or 10)
                if num and num > 0 and num < 65536 then
                    -- Convert numeric entity to character
                    -- Common entities we care about:
                    -- &#x27; or &#39; = apostrophe (')
                    -- &#x2C; or &#44; = comma (,)
                    -- &#x22; or &#34; = quote (")
                    -- &#x2D; or &#45; = hyphen (-)
                    if num == 39 then
                        result[#result + 1] = "'"
                    elseif num == 44 then
                        result[#result + 1] = ","
                    elseif num == 34 then
                        result[#result + 1] = '"'
                    elseif num == 45 then
                        result[#result + 1] = "-"
                    elseif num == 38 then
                        result[#result + 1] = "&"
                    elseif num == 60 then
                        result[#result + 1] = "<"
                    elseif num == 62 then
                        result[#result + 1] = ">"
                    elseif num == 32 or num == 160 then
                        result[#result + 1] = " "
                    elseif num < 127 then
                        -- ASCII printable character
                        result[#result + 1] = string.char(num)
                    else
                        -- For Unicode beyond ASCII, just skip it or use placeholder
                        result[#result + 1] = "?"
                    end
                    i = endPos + 1
                else
                    -- Invalid numeric entity, keep as-is
                    result[#result + 1] = text:sub(i, i)
                    i = i + 1
                end
            else
                -- No closing semicolon, keep as-is
                result[#result + 1] = text:sub(i, i)
                i = i + 1
            end
        else
            result[#result + 1] = text:sub(i, i)
            i = i + 1
        end
    end
    text = table.concat(result)
    
    -- Decode named entities
    text = text:gsub("&quot;", '"')
    text = text:gsub("&apos;", "'")
    text = text:gsub("&amp;", "&")
    text = text:gsub("&lt;", "<")
    text = text:gsub("&gt;", ">")
    text = text:gsub("&nbsp;", " ")
    
    return text
end

-- Clean HTML tags and decode entities (safe for very large strings)
local function cleanText(text)
    if not text then return "" end
    
    -- For very long strings, use character-by-character processing
    -- Lower threshold to catch problematic 11-13KB cards with complex HTML
    local isLarge = #text > 10000
    
    if isLarge then
        -- Simple character-by-character tag removal for large strings
        local result = {}
        local inTag = false
        for i = 1, #text do
            local char = text:sub(i, i)
            if char == '<' then
                inTag = true
            elseif char == '>' then
                inTag = false
            elseif not inTag then
                result[#result + 1] = char
            end
        end
        text = table.concat(result)
        
        -- Decode HTML entities even for large strings (safe character-by-character approach)
        text = decodeHTMLEntities(text)
        
        -- Simple trim without patterns for large strings
        -- Remove leading whitespace
        local startPos = 1
        while startPos <= #text do
            local char = text:sub(startPos, startPos)
            if char ~= ' ' and char ~= '\t' and char ~= '\n' and char ~= '\r' then
                break
            end
            startPos = startPos + 1
        end
        
        -- Remove trailing whitespace
        local endPos = #text
        while endPos >= startPos do
            local char = text:sub(endPos, endPos)
            if char ~= ' ' and char ~= '\t' and char ~= '\n' and char ~= '\r' then
                break
            end
            endPos = endPos - 1
        end
        
        if startPos > endPos then
            return ""
        end
        
        return text:sub(startPos, endPos)
    end
    
    -- Normal pattern-based cleaning for smaller strings
    -- Wrap in pcall to handle pattern complexity errors gracefully
    local success, result
    
    success, result = pcall(function() return text:gsub("<[^>]+>", "") end)
    text = success and result or text
    
    -- Decode HTML entities
    text = decodeHTMLEntities(text)
    
    -- Clean up any remaining tag fragments
    text = text:gsub("[<>]", "")
    
    success, result = pcall(function() return text:gsub("%s+", " ") end)
    text = success and result or text
    
    success, result = pcall(function() return text:gsub("^%s*(.-)%s*$", "%1") end)
    text = success and result or text
    
    return text
end

-- Extract weapon name, removing cost annotations
local function extractWeaponName(tdContent)
    local cleaned = cleanText(tdContent)
    cleaned = cleaned:gsub("%s*%([+-]?[%d¢]+%)%s*$", "")
    cleaned = cleaned:gsub("%s*%([+-]?[%d¢]+%)%s*", "")
    cleaned = cleaned:gsub("^%s*(.-)%s*$", "%1")
    return cleaned
end

-- Safe plain text search (no pattern matching)
local function findPlain(haystack, needle, start)
    return haystack:find(needle, start or 1, true)
end

-- Helper function to sum cost/XP strings (e.g., "50¢" + "100¢" = "150¢")
local function sumCostOrXP(val1, val2)
    -- Extract numeric values
    local num1 = tonumber(val1:match('%d+')) or 0
    local num2 = tonumber(val2:match('%d+')) or 0
    local sum = num1 + num2
    
    -- Determine suffix (¢ for cost, XP for experience)
    if val1:find('¢', 1, true) or val2:find('¢', 1, true) then
        return sum .. "¢"
    elseif val1:find('XP', 1, true) or val2:find('XP', 1, true) then
        return sum .. " XP"
    else
        return tostring(sum)
    end
end

--------------------------------------------------------------------------------
-- PARSING FUNCTIONS
--------------------------------------------------------------------------------

-- Extract weapons from a fighter card
local function extractWeapons(cardHtml)
    local weapons = {}
    local debugMode = false  -- Enable debug output
    
    -- Find weapons table header
    local weaponStart = findPlain(cardHtml, 'scope="col">')
    local searchPos = 1
    local foundWeaponsHeader = false
    
    while weaponStart do
        local thEnd = findPlain(cardHtml, '</th>', weaponStart)
        if thEnd then
            local headerContent = cardHtml:sub(weaponStart, thEnd)
            if findPlain(headerContent, 'Weapons') then
                foundWeaponsHeader = true
                break
            end
        end
        searchPos = weaponStart + 10
        weaponStart = findPlain(cardHtml, 'scope="col">', searchPos)
    end
    
    if not foundWeaponsHeader then 
        if debugMode then print("DEBUG: No weapons header found") end
        return weapons 
    end
    
    -- Search backwards for table start
    local tableStart = nil
    local searchBack = weaponStart - 1
    local searchLimit = math.max(1, weaponStart - 1000)
    
    while searchBack > searchLimit do
        local checkPos = cardHtml:sub(searchBack, searchBack + 6)
        if checkPos:sub(1, 6) == "<table" then
            local nextChar = cardHtml:sub(searchBack + 6, searchBack + 6)
            if nextChar == " " or nextChar == ">" then
                tableStart = searchBack
                break
            end
        end
        searchBack = searchBack - 1
    end
    
    if not tableStart then 
        if debugMode then print("DEBUG: No table start found") end
        return weapons 
    end
    
    -- Process tbody sections (CRITICAL: search for "<tbody" not "<tbody>")
    local pos = tableStart
    while true do
        local tbodyStart = findPlain(cardHtml, "<tbody", pos)
        if not tbodyStart then break end
        if tbodyStart > weaponStart + 15000 then break end
        
        local tbodyEnd = findPlain(cardHtml, "</tbody>", tbodyStart)
        if not tbodyEnd then break end
        
        local tbodyContent = cardHtml:sub(tbodyStart, tbodyEnd)
        
        -- Extract weapon rows with profile-trait pairing
        -- KEY INSIGHT: First rowspan in tbody = weapon, subsequent rowspans = profiles
        local rowPos = 1
        local currentWeapon = nil
        local pendingProfile = nil
        local isFirstRowspanInTbody = true  -- Track if we've seen a rowspan yet in this tbody
        
        while true do
            local rowStart = findPlain(tbodyContent, "<tr", rowPos)
            if not rowStart then break end
            
            local rowEnd = findPlain(tbodyContent, "</tr>", rowStart)
            if not rowEnd then break end
            
            local rowContent = tbodyContent:sub(rowStart, rowEnd)
            
            local firstTdStart = findPlain(rowContent, "<td")
            if firstTdStart then
                local firstTdEnd = findPlain(rowContent, "</td>", firstTdStart)
                if firstTdEnd then
                    local tdContent = rowContent:sub(firstTdStart, firstTdEnd)
                    local hasColspan = findPlain(tdContent, "colspan")
                    
                    if hasColspan then
                        local colspanValue = tdContent:match('colspan="(%d+)"')
                        
                        -- Both weapon names and traits use colspan="9"
                        -- Distinguish by checking if we have a pending profile (traits) or not (weapon name)
                        if colspanValue == "9" then
                            if pendingProfile then
                                -- This is a traits row (comes after a stats row)
                                local nameStart = findPlain(tdContent, ">")
                                if nameStart then
                                    local traitsText = cleanText(tdContent:sub(nameStart + 1, firstTdEnd - 1))
                                    if traitsText ~= "" and traitsText ~= "None" then
                                        pendingProfile.traits = traitsText
                                        if debugMode then print("DEBUG: Attached traits '" .. traitsText:sub(1,40) .. "' to profile") end
                                    end
                                end
                                pendingProfile = nil
                            else
                                -- This is a weapon name row (comes before stats rows)
                                local nameStart = findPlain(tdContent, ">")
                                if nameStart then
                                    local weaponName = extractWeaponName(tdContent:sub(nameStart + 1, firstTdEnd - 1))
                                    if weaponName ~= "" then
                                        currentWeapon = {name = weaponName, profiles = {}}
                                        weapons[#weapons + 1] = currentWeapon
                                        isFirstRowspanInTbody = false  -- Weapon name row counts as "first"
                                        if debugMode then print("DEBUG: Created weapon from colspan=9: " .. weaponName) end
                                    end
                                end
                            end
                        else
                            -- Other colspan values (shouldn't happen, but handle gracefully)
                            if debugMode then
                                print("DEBUG: Found colspan=" .. (colspanValue or "?") .. ", ignoring")
                            end
                        end
                    else
                        -- Stats row (has 9 total td cells: name + 8 stats)
                        local hasRowspan = findPlain(tdContent, "rowspan")
                        local profileName = nil
                        
                        if hasRowspan then
                            -- Row with rowspan = either weapon name or profile name (for shotguns with dashes)
                            local nameStart = findPlain(tdContent, ">")
                            if nameStart then
                                -- Extract full TD content (includes any nested tags)
                                local fullTdContent = tdContent:sub(nameStart + 1, firstTdEnd - 1)
                                local weaponName = extractWeaponName(fullTdContent)
                                
                                if debugMode and isFirstRowspanInTbody then
                                    print("DEBUG: First rowspan, extracted name: '" .. weaponName .. "' from content: " .. fullTdContent:sub(1, 80))
                                end
                                
                                -- Skip if weapon name is just a dash (not if HTML contains bi-dash icon class)
                                local isDashOnly = (weaponName == "-" or weaponName == "–" or weaponName == "—")
                                
                                -- Also check for nested links/spans (Grenade launcher case)
                                if weaponName == "" or weaponName:match("^%s*$") then
                                    -- Try to find text in nested <a> or other tags
                                    local linkText = fullTdContent:match('>([^<]+)</a>')
                                    if linkText then
                                        weaponName = extractWeaponName(linkText)
                                        if debugMode and isFirstRowspanInTbody then
                                            print("DEBUG: Extracted from nested link: '" .. weaponName .. "'")
                                        end
                                    end
                                end
                                
                                if weaponName ~= "" and not isDashOnly then
                                    -- Strip leading dash/hyphen (ammo type indicator)
                                    local trimmedName = weaponName:gsub("^%s*[%-–—]%s*", "")
                                    
                                    -- CORE LOGIC: First rowspan in tbody = weapon, rest = profiles
                                    if isFirstRowspanInTbody then
                                        -- This is the main weapon (e.g., "Shotgun", "Grenade launcher")
                                        currentWeapon = {name = trimmedName, profiles = {}}
                                        weapons[#weapons + 1] = currentWeapon
                                        isFirstRowspanInTbody = false
                                        if debugMode then print("DEBUG: Created weapon: " .. trimmedName) end
                                    else
                                        -- This is a profile/ammo type (e.g., "scatter ammo")
                                        profileName = trimmedName
                                    end
                                elseif debugMode and isFirstRowspanInTbody and weaponName == "" then
                                    print("DEBUG: First rowspan but weaponName is EMPTY!")
                                elseif debugMode and isFirstRowspanInTbody and isDashOnly then
                                    print("DEBUG: First rowspan but weaponName is just a dash, skipping")
                                end
                            end
                        else
                            -- No rowspan = additional profile row (grenade launcher style)
                            -- Extract profile name from first cell if we already have a weapon
                            if currentWeapon then
                                local nameStart = findPlain(tdContent, ">")
                                if nameStart then
                                    local nameContent = tdContent:sub(nameStart + 1, firstTdEnd - 1)
                                    local extractedName = extractWeaponName(nameContent)
                                    if extractedName ~= "" and not findPlain(nameContent, "bi-dash") then
                                        profileName = extractedName
                                    end
                                end
                            end
                        end
                        
                        -- Extract 8 stat columns
                        local stats = {}
                        local tdCount = 0
                        local tdPos = 1
                        
                        while true do
                            local tdStart = findPlain(rowContent, "<td", tdPos)
                            if not tdStart then break end
                            local tdEnd = findPlain(rowContent, "</td>", tdStart)
                            if not tdEnd then break end
                            
                            tdCount = tdCount + 1
                            if tdCount > 1 then
                                local tdContent2 = rowContent:sub(tdStart, tdEnd)
                                local valueStart = findPlain(tdContent2, ">")
                                if valueStart then
                                    stats[#stats + 1] = cleanText(tdContent2:sub(valueStart + 1, tdEnd - 1))
                                end
                            end
                            tdPos = tdEnd + 1
                        end
                        
                        -- Debug output for grenade launcher issues
                        if #stats ~= 8 and tdCount > 0 then
                            print("WARNING: Found " .. #stats .. " stats (expected 8) for weapon/profile: " .. tostring(profileName or "unnamed"))
                        end
                        
                        if #stats == 8 and currentWeapon then
                            pendingProfile = {
                                profile_name = profileName,
                                rg_short = stats[1],
                                rg_long = stats[2],
                                acc_short = stats[3],
                                acc_long = stats[4],
                                strength = stats[5],
                                ap = stats[6],
                                damage = stats[7],
                                ammo = stats[8],
                                traits = ""
                            }
                            currentWeapon.profiles[#currentWeapon.profiles + 1] = pendingProfile
                            if debugMode then 
                                print("DEBUG: Added profile '" .. (profileName or "default") .. "' to " .. currentWeapon.name)
                            end
                        elseif #stats == 8 and not currentWeapon then
                            if debugMode then print("DEBUG: Found 8 stats but no currentWeapon!") end
                        end
                    end
                end
            end
            
            rowPos = rowEnd + 1
        end
        
        pos = tbodyEnd + 1
    end
    
    if debugMode then 
        print("DEBUG: Extracted " .. #weapons .. " weapons total")
        for i, w in ipairs(weapons) do
            print("  - " .. w.name .. " (" .. #w.profiles .. " profiles)")
        end
    end
    
    return weapons
end

-- Extract table row data (Skills, Equipment, Rules, etc)
local function extractTableRowData(cardHtml, labelName)
    local data = {}
    local searchPos = 1
    
    while true do
        local thStart = findPlain(cardHtml, '<th scope="row"', searchPos)
        if not thStart then break end
        
        local thEnd = findPlain(cardHtml, '</th>', thStart)
        if thEnd then
            local thContent = cardHtml:sub(thStart, thEnd)
            
            if findPlain(thContent, labelName) then
                local tdStart = findPlain(cardHtml, '<td', thEnd)
                if tdStart then
                    local tdEnd = findPlain(cardHtml, '</td>', tdStart)
                    if tdEnd then
                        local tdContent = cardHtml:sub(tdStart, tdEnd)
                        
                        -- Simple HTML cleaning without patterns
                        local plainText = tdContent
                        plainText = plainText:gsub('<[^>]+>', '')
                        plainText = plainText:gsub('&nbsp;', ' ')
                        plainText = plainText:gsub('¢', 'credits')
                        plainText = plainText:gsub('[<>]', '')
                        plainText = plainText:gsub('^%s+', ''):gsub('%s+$', '')
                        
                        if plainText ~= '' and plainText ~= 'None' then
                            for item in plainText:gmatch('([^,]+)') do
                                item = item:gsub('^%s+', ''):gsub('%s+$', '')
                                if item ~= '' and item ~= 'Add' and item ~= 'Edit' and #item > 1 then
                                    data[#data + 1] = item
                                end
                            end
                        end
                        break
                    end
                end
            end
        end
        
        searchPos = thStart + 1
        if searchPos > 300000 then break end
    end
    
    return data
end

-- Extract XP from fighter card HTML
local function extractXP(cardHtml)
    -- Look for XP badge: class="badge text-bg-primary">VALUE XP</span>
    local xpStart = cardHtml:find('badge text%-bg%-primary')
    if xpStart then
        local badgeStart = cardHtml:find('>', xpStart)
        if badgeStart then
            local afterBadge = cardHtml:sub(badgeStart + 1, badgeStart + 100)
            local nextTag = afterBadge:find('<')
            if nextTag then
                local xpStr = afterBadge:sub(1, nextTag - 1)
                -- Clean and extract just the numeric XP value
                xpStr = xpStr:gsub("^%s+", ""):gsub("%s+$", "")
                -- Remove " XP" suffix if present to avoid duplication
                xpStr = xpStr:gsub("%s*XP$", "")
                log("[DEBUG] XP extraction: extracted xpStr: '" .. xpStr .. "'")
                if xpStr ~= "" then
                    return xpStr
                end
            end
        end
    end
    log("[DEBUG] XP extraction: badge not found in cardHtml")
    return "0"
end

-- Parse a single fighter card
local function parseFighterCard(cardId, cardHtml)
    local fighter = {
        id = cardId,
        name = "",
        fighter_type = "",
        category = "",
        cost = "",
        xp = nil,
        characteristics = {},
        weapons = {},
        skills = {},
        equipment = {},
        rules = {},
        injuries = {},
        genesmithing = {},  -- Goliath gang-specific
        cyberteknika = {},  -- Van Saar gang-specific
        powers = {},  -- Psyker powers
        is_vehicle = false,
        is_crew = false,
        vehicle_name = nil,
        linked_crew_name = nil  -- For vehicles: linked crew name from tooltip
    }
    
    -- Extract name
    local nameStart = findPlain(cardHtml, '<h3 class="h5 mb-0">')
    if nameStart then
        local nameEnd = findPlain(cardHtml, "</h3>", nameStart)
        if nameEnd then
            fighter.name = cleanText(cardHtml:sub(nameStart + 20, nameEnd - 1))
        end
    end
    
    -- Extract cost from badge (can be text-bg-warning OR text-bg-secondary)
    -- Pattern: class="badge text-bg-warning bg-warning">VALUE¢</div>
    -- or: class="badge text-bg-secondary bg-secondary">VALUE¢</div>
    local costStart = cardHtml:find('badge text%-bg%-warning bg%-warning')
    if not costStart then
        costStart = cardHtml:find('badge text%-bg%-secondary bg%-secondary')
    end
    
    if costStart then
        local badgeStart = cardHtml:find('>', costStart)
        if badgeStart then
            local afterBadge = cardHtml:sub(badgeStart + 1, badgeStart + 50)
            local nextTag = afterBadge:find('<')
            if nextTag then
                local costStr = afterBadge:sub(1, nextTag - 1)
                -- Clean whitespace
                costStr = costStr:gsub("^%s+", ""):gsub("%s+$", "")
                log("[DEBUG] Cost extraction: extracted costStr: '" .. costStr .. "'")
                if costStr ~= "" then
                    fighter.cost = costStr
                end
            end
        end
    end
    
    if fighter.cost == "" then
        log("[DEBUG] Cost extraction: badge not found, defaulting to 0")
        fighter.cost = "0"
    end
    
    -- Extract fighter type and category
    local typeStart = findPlain(cardHtml, '<div class="hstack gap-2">')
    if typeStart then
        local typeEnd = findPlain(cardHtml, "</div>", typeStart + 100)
        if typeEnd then
            local typeSection = cardHtml:sub(typeStart, typeEnd)
            local parenStart = findPlain(typeSection, "(")
            if parenStart then
                fighter.fighter_type = cleanText(typeSection:sub(1, parenStart - 1))
                local parenEnd = findPlain(typeSection, ")", parenStart)
                if parenEnd then
                    fighter.category = cleanText(typeSection:sub(parenStart + 1, parenEnd - 1))
                end
            else
                fighter.fighter_type = cleanText(typeSection)
            end
        end
    end
    
    -- Extract characteristics
    -- NOTE: Some fighter cards have multiple tables with the same class before characteristics
    -- We verify by checking for M, WS, BS headers to ensure we have the right table
    local charStart = findPlain(cardHtml, '<table class="table table-sm table-borderless table-fixed mb-0">')
    if charStart then
        local charEnd = findPlain(cardHtml, "</table>", charStart)
        if charEnd then
            local charTable = cardHtml:sub(charStart, charEnd)
            
            -- Verify this is the characteristics table by checking for M, WS, BS headers
            local hasMovement = findPlain(charTable, ">M</th>")
            local hasWS = findPlain(charTable, ">WS</th>")
            
            if not hasMovement or not hasWS then
                -- This is not the characteristics table, find the next one
                local nextTableStart = findPlain(cardHtml, '<table class="table table-sm table-borderless table-fixed mb-0">', charEnd)
                if nextTableStart then
                    charStart = nextTableStart
                    charEnd = findPlain(cardHtml, "</table>", charStart)
                    if charEnd then
                        charTable = cardHtml:sub(charStart, charEnd)
                    end
                end
            end
            
            -- Extract header row
            local charNames = {}
            local theadStart = findPlain(charTable, "<thead>")
            if theadStart then
                local theadEnd = findPlain(charTable, "</thead>", theadStart)
                if theadEnd then
                    local thead = charTable:sub(theadStart, theadEnd)
                    local pos = 1
                    while true do
                        local thStart = findPlain(thead, "<th", pos)
                        if not thStart then break end
                        local thEnd = findPlain(thead, "</th>", thStart)
                        if not thEnd then break end
                        local thContent = thead:sub(thStart, thEnd - 1)
                        local valueStart = findPlain(thContent, ">")
                        if valueStart then
                            local name = cleanText(thContent:sub(valueStart + 1))
                            if name ~= "" then
                                charNames[#charNames + 1] = name
                            end
                        end
                        pos = thEnd + 1
                    end
                end
            end
            
            -- Extract values
            local tbodyStart = findPlain(charTable, "<tbody>")
            if tbodyStart then
                local tbodyEnd = findPlain(charTable, "</tbody>", tbodyStart)
                if tbodyEnd then
                    local tbody = charTable:sub(tbodyStart, tbodyEnd)
                    local pos = 1
                    local valueIndex = 1
                    
                    while true do
                        local tdStart = findPlain(tbody, "<td", pos)
                        if not tdStart then break end
                        local tdEnd = findPlain(tbody, "</td>", tdStart)
                        if not tdEnd then break end
                        local tdContent = tbody:sub(tdStart, tdEnd - 1)
                        local valueStart = findPlain(tdContent, ">")
                        if valueStart then
                            local value = cleanText(tdContent:sub(valueStart + 1))
                            if charNames[valueIndex] then
                                fighter.characteristics[charNames[valueIndex]] = value
                            end
                            valueIndex = valueIndex + 1
                        end
                        pos = tdEnd + 1
                    end
                end
            end
        end
    end
    
    -- Extract all data with error handling
    local success, result
    
    success, result = pcall(extractWeapons, cardHtml)
    if success then
        fighter.weapons = result
    else
        print("ERROR extracting weapons: " .. tostring(result))
        fighter.weapons = {}
    end
    
    -- Wrap table extraction in pcall to handle pattern complexity errors
    success, result = pcall(extractTableRowData, cardHtml, 'Skills')
    fighter.skills = success and result or {}
    
    success, result = pcall(extractTableRowData, cardHtml, 'Gear')
    fighter.equipment = success and result or {}
    
    success, result = pcall(extractTableRowData, cardHtml, 'Rules')
    fighter.rules = success and result or {}
    
    success, result = pcall(extractTableRowData, cardHtml, 'Injuries')
    fighter.injuries = success and result or {}
    
    -- Gang-specific categories
    success, result = pcall(extractTableRowData, cardHtml, 'Gene-smithing')
    fighter.genesmithing = success and result or {}
    
    success, result = pcall(extractTableRowData, cardHtml, 'Cyberteknika')
    if not success or #result == 0 then
        -- Try alternate spelling
        success, result = pcall(extractTableRowData, cardHtml, 'Archaeo-cyberteknika')
    end
    fighter.cyberteknika = success and result or {}
    
    -- Extract Powers (Psyker/Wyrd powers)
    success, result = pcall(extractTableRowData, cardHtml, 'Powers')
    fighter.powers = success and result or {}
    
    -- Extract Legendary Names (Orlock gang-specific)
    success, result = pcall(extractTableRowData, cardHtml, 'Legendary Names')
    if success and result and #result > 0 then
        -- Format: "Name (Trait)" - extract just the trait part inside the parenthesis
        local legendaryFull = result[1]
        local parenStart = findPlain(legendaryFull, "(")
        local parenEnd = findPlain(legendaryFull, ")")
        if parenStart and parenEnd then
            fighter.legendary_name = legendaryFull:sub(parenStart + 1, parenEnd - 1)
        else
            fighter.legendary_name = legendaryFull
        end
        log("DEBUG: Extracted legendary trait '" .. fighter.legendary_name .. "' for fighter: " .. fighter.name)
    end
    
    -- Detect if this is a vehicle (check fighter_type OR category for "Vehicle")
    local typeAndCategory = (fighter.fighter_type .. " " .. fighter.category):lower()
    if findPlain(typeAndCategory, "vehicle") then
        fighter.is_vehicle = true
        log("DEBUG: Detected VEHICLE: " .. fighter.name .. " (type: '" .. fighter.fighter_type .. "', category: '" .. fighter.category .. "')")
        
        -- Extract linked crew name from tooltip: title="This vehicle is linked to {name} via gear"
        local tooltipStart = findPlain(cardHtml, 'title="This vehicle is linked to ')
        if tooltipStart then
            local afterLinked = cardHtml:sub(tooltipStart + 33)  -- Skip past 'title="This vehicle is linked to '
            local viaGear = findPlain(afterLinked, ' via gear"')
            if viaGear then
                fighter.linked_crew_name = afterLinked:sub(1, viaGear - 1)
                log("DEBUG: Vehicle " .. fighter.name .. " is linked to crew: " .. fighter.linked_crew_name)
            end
        end
    else
        log("DEBUG: NOT a vehicle: " .. fighter.name .. " (type: '" .. fighter.fighter_type .. "', category: '" .. fighter.category .. "')")
    end
    
    -- Check if crew member (category is "Crew" OR has Vehicle Crew rule)
    if fighter.category:lower() == "crew" then
        fighter.is_crew = true
        log("DEBUG: Detected CREW: " .. fighter.name .. " (category is 'Crew')")
    else
        for _, rule in ipairs(fighter.rules) do
            if findPlain(rule, "Vehicle Crew") then
                fighter.is_crew = true
                log("DEBUG: Detected CREW: " .. fighter.name .. " (has Vehicle Crew rule)")
                break
            end
        end
    end
    
    success, result = pcall(extractXP, cardHtml)
    if success and result then
        fighter.xp = result
    end
    
    return fighter
end

-- Pair vehicle and crew cards into combined fighters
local function pairVehiclesWithCrew(fighters)
    local paired = {}
    local pairedIndices = {}
    
    log("DEBUG: pairVehiclesWithCrew called with " .. #fighters .. " fighters")
    
    -- Check for duplicate vehicle names and warn users
    local vehicleNames = {}
    local duplicates = {}
    for i, fighter in ipairs(fighters) do
        if fighter.is_vehicle then
            if vehicleNames[fighter.name] then
                duplicates[fighter.name] = true
            else
                vehicleNames[fighter.name] = true
            end
        end
    end
    
    if next(duplicates) then
        local dupList = {}
        for name in pairs(duplicates) do
            dupList[#dupList + 1] = name
        end
        log("WARNING: Multiple vehicles with the same name detected: " .. table.concat(dupList, ", "))
        log("WARNING: Please give each vehicle a unique name in Gyrinx.app for accurate crew pairing!")
        print("⚠️ WARNING: Multiple vehicles with the same name detected!")
        print("⚠️ Please give each vehicle a unique name in your Gyrinx.app roster for accurate crew pairing.")
    end
    
    -- Strategy: Iterate through vehicles and find their linked crew
    -- Priority: 1) Tooltip link (linked_crew_name), 2) Equipment name match, 3) Proximity
    
    -- FIRST PASS: Match vehicles with crew using tooltip links (most reliable)
    for i, fighter in ipairs(fighters) do
        if fighter.is_vehicle and fighter.linked_crew_name and not pairedIndices[i] then
            log("DEBUG: Vehicle '" .. fighter.name .. "' is linked to crew '" .. fighter.linked_crew_name .. "', searching for crew...")
            -- Find the crew member by name
            for j = 1, #fighters do
                if j ~= i and fighters[j].is_crew and not pairedIndices[j] then
                    if fighters[j].name:lower() == fighter.linked_crew_name:lower() then
                        local vehicleIndex = i
                        local crewIndex = j
                        local crew = fighters[crewIndex]
                        local vehicle = fighter
                        
                        log("DEBUG: Matched vehicle to crew via tooltip link: " .. vehicle.name .. " -> " .. crew.name)
                        
                        -- Create combined fighter with seamlessly merged characteristics
                        -- Vehicles have: M, Fr, Sd, Rr, HP, Hnd, Sv
                        -- Crew have: M, WS, BS, S, T, W, I, A, Ld, Cl, Wil, Int
                        -- Combined: M, BS, Fr, Sd, Rr, HP, Hnd, Sv, Ld, Cl, Wil, Int
                        local mergedCharacteristics = {}
                        
                        -- Take M from vehicle (vehicle movement)
                        if vehicle.characteristics["M"] then mergedCharacteristics["M"] = vehicle.characteristics["M"] end
                        
                        -- Take BS from crew (crew ballistic skill)
                        if crew.characteristics["BS"] then mergedCharacteristics["BS"] = crew.characteristics["BS"] end
                        
                        -- Take vehicle-specific stats: Fr, Sd, Rr (front/side/rear armor)
                        if vehicle.characteristics["Fr"] then mergedCharacteristics["Fr"] = vehicle.characteristics["Fr"] end
                        if vehicle.characteristics["Sd"] then mergedCharacteristics["Sd"] = vehicle.characteristics["Sd"] end
                        if vehicle.characteristics["Rr"] then mergedCharacteristics["Rr"] = vehicle.characteristics["Rr"] end
                        
                        -- Take vehicle HP, Hnd, Sv (hull points, handling, save)
                        if vehicle.characteristics["HP"] then mergedCharacteristics["HP"] = vehicle.characteristics["HP"] end
                        if vehicle.characteristics["Hnd"] then mergedCharacteristics["Hnd"] = vehicle.characteristics["Hnd"] end
                        if vehicle.characteristics["Sv"] then mergedCharacteristics["Sv"] = vehicle.characteristics["Sv"] end
                        
                        -- Take crew mental stats: Ld, Cl, Wil, Int
                        if crew.characteristics["Ld"] then mergedCharacteristics["Ld"] = crew.characteristics["Ld"] end
                        if crew.characteristics["Cl"] then mergedCharacteristics["Cl"] = crew.characteristics["Cl"] end
                        if crew.characteristics["Wil"] then mergedCharacteristics["Wil"] = crew.characteristics["Wil"] end
                        if crew.characteristics["Int"] then mergedCharacteristics["Int"] = crew.characteristics["Int"] end
                        
                        local combined = {
                            id = crew.id,
                            name = crew.name .. " piloting " .. vehicle.name,
                            fighter_type = crew.fighter_type,
                            category = crew.category,
                            cost = crew.cost,
                            xp = crew.xp or "0",
                            characteristics = mergedCharacteristics,
                            weapons = {},
                            skills = {},
                            equipment = {},
                            rules = {},
                            injuries = crew.injuries,
                            legendary_name = crew.legendary_name,
                            genesmithing = crew.genesmithing,
                            cyberteknika = crew.cyberteknika,
                            is_vehicle = false,
                            is_crew = false,
                            vehicle_name = vehicle.name
                        }
                        
                        -- Combine weapons from BOTH crew and vehicle
                        for _, w in ipairs(crew.weapons) do
                            combined.weapons[#combined.weapons + 1] = w
                        end
                        for _, w in ipairs(vehicle.weapons) do
                            combined.weapons[#combined.weapons + 1] = w
                        end
                        
                        -- Combine skills from crew
                        for _, s in ipairs(crew.skills) do
                            combined.skills[#combined.skills + 1] = s
                        end
                        
                        -- Combine equipment from BOTH crew and vehicle
                        for _, eq in ipairs(crew.equipment) do
                            combined.equipment[#combined.equipment + 1] = eq
                        end
                        for _, eq in ipairs(vehicle.equipment) do
                            combined.equipment[#combined.equipment + 1] = eq
                        end
                        
                        -- Combine rules from BOTH crew and vehicle
                        for _, r in ipairs(crew.rules) do
                            combined.rules[#combined.rules + 1] = r
                        end
                        for _, r in ipairs(vehicle.rules) do
                            combined.rules[#combined.rules + 1] = r
                        end
                        
                        paired[#paired + 1] = combined
                        pairedIndices[i] = true
                        pairedIndices[j] = true
                        break
                    end
                end
            end
        end
    end
    
    -- SECOND PASS: Handle remaining crew members (no tooltip link)
    for i, fighter in ipairs(fighters) do
        if fighter.is_crew and not pairedIndices[i] then
            local vehicleIndex = nil
            
            log("DEBUG: Crew '" .. fighter.name .. "' not paired via tooltip, trying equipment match...")

            
            -- Try to find vehicle by name match in crew equipment
            if not vehicleIndex then
                for _, equipItem in ipairs(fighter.equipment) do
                    local equipLower = equipItem:lower()
                    for j = 1, #fighters do
                        if j ~= i and fighters[j].is_vehicle and not pairedIndices[j] then
                            local vehicleNameLower = fighters[j].name:lower()
                            if findPlain(equipLower, vehicleNameLower) then
                                vehicleIndex = j
                                log("DEBUG: Matched crew to vehicle via equipment: " .. fighter.name .. " has '" .. equipItem .. "' -> " .. fighters[j].name)
                                break
                            end
                        end
                    end
                    if vehicleIndex then break end
                end
            end
            
            -- Fallback: if no equipment match, use closest unpaired vehicle
            if not vehicleIndex then
                local minDistance = math.huge
                for j = 1, #fighters do
                    if j ~= i and fighters[j].is_vehicle and not pairedIndices[j] then
                        local distance = math.abs(j - i)
                        if distance < minDistance then
                            minDistance = distance
                            vehicleIndex = j
                        elseif distance == minDistance then
                            -- Tiebreaker: prefer vehicle that appears earlier in list (lower index)
                            -- This matches Gyrinx's typical ordering where vehicle precedes its crew
                            if j < vehicleIndex then
                                vehicleIndex = j
                            end
                        end
                    end
                end
                if vehicleIndex then
                    log("DEBUG: Pairing crew with closest vehicle by proximity (distance=" .. math.abs(vehicleIndex - i) .. "): " .. fighter.name .. " -> " .. fighters[vehicleIndex].name)
                    print("Note: Paired " .. fighter.name .. " with " .. fighters[vehicleIndex].name .. " by proximity. For better accuracy, ensure each vehicle has a unique name.")
                end
            end
            
            if vehicleIndex then
                local crew = fighter
                local vehicle = fighters[vehicleIndex]
                
                log("DEBUG: Pairing crew '" .. crew.name .. "' with vehicle '" .. vehicle.name .. "'")
                
                -- Create combined fighter: "<crew> piloting <vehicle>"
                -- Vehicles have: M, Fr, Sd, Rr, HP, Hnd, Sv
                -- Crew have: M, WS, BS, S, T, W, I, A, Ld, Cl, Wil, Int
                -- Combined: M, BS, Fr, Sd, Rr, HP, Hnd, Sv, Ld, Cl, Wil, Int
                local mergedCharacteristics = {}
                
                -- Take M from vehicle (vehicle movement)
                if vehicle.characteristics["M"] then mergedCharacteristics["M"] = vehicle.characteristics["M"] end
                
                -- Take BS from crew (crew ballistic skill)
                if crew.characteristics["BS"] then mergedCharacteristics["BS"] = crew.characteristics["BS"] end
                
                -- Take vehicle-specific stats: Fr, Sd, Rr (front/side/rear armor)
                if vehicle.characteristics["Fr"] then mergedCharacteristics["Fr"] = vehicle.characteristics["Fr"] end
                if vehicle.characteristics["Sd"] then mergedCharacteristics["Sd"] = vehicle.characteristics["Sd"] end
                if vehicle.characteristics["Rr"] then mergedCharacteristics["Rr"] = vehicle.characteristics["Rr"] end
                
                -- Take vehicle HP, Hnd, Sv (hull points, handling, save)
                if vehicle.characteristics["HP"] then mergedCharacteristics["HP"] = vehicle.characteristics["HP"] end
                if vehicle.characteristics["Hnd"] then mergedCharacteristics["Hnd"] = vehicle.characteristics["Hnd"] end
                if vehicle.characteristics["Sv"] then mergedCharacteristics["Sv"] = vehicle.characteristics["Sv"] end
                
                -- Take crew mental stats: Ld, Cl, Wil, Int
                if crew.characteristics["Ld"] then mergedCharacteristics["Ld"] = crew.characteristics["Ld"] end
                if crew.characteristics["Cl"] then mergedCharacteristics["Cl"] = crew.characteristics["Cl"] end
                if crew.characteristics["Wil"] then mergedCharacteristics["Wil"] = crew.characteristics["Wil"] end
                if crew.characteristics["Int"] then mergedCharacteristics["Int"] = crew.characteristics["Int"] end
                
                local combined = {
                    id = crew.id,
                    name = crew.name .. " piloting " .. vehicle.name,
                    fighter_type = crew.fighter_type,
                    category = crew.category,
                    cost = crew.cost,
                    xp = crew.xp or "0",
                    characteristics = mergedCharacteristics,
                    weapons = {},
                    skills = {},
                    equipment = {},
                    rules = {},
                    injuries = crew.injuries,
                    legendary_name = crew.legendary_name,
                    genesmithing = crew.genesmithing,
                    cyberteknika = crew.cyberteknika,
                    is_vehicle = false,
                    is_crew = false,
                    vehicle_name = vehicle.name
                }
                
                -- Combine weapons from BOTH crew and vehicle
                for _, w in ipairs(crew.weapons) do
                    combined.weapons[#combined.weapons + 1] = w
                end
                for _, w in ipairs(vehicle.weapons) do
                    combined.weapons[#combined.weapons + 1] = w
                end
                
                -- Combine skills from crew
                for _, s in ipairs(crew.skills) do
                    combined.skills[#combined.skills + 1] = s
                end
                
                -- Combine equipment from BOTH crew and vehicle
                for _, eq in ipairs(crew.equipment) do
                    combined.equipment[#combined.equipment + 1] = eq
                end
                for _, eq in ipairs(vehicle.equipment) do
                    combined.equipment[#combined.equipment + 1] = eq
                end
                
                -- Combine rules from BOTH crew and vehicle
                for _, r in ipairs(crew.rules) do
                    combined.rules[#combined.rules + 1] = r
                end
                for _, r in ipairs(vehicle.rules) do
                    combined.rules[#combined.rules + 1] = r
                end
                
                paired[#paired + 1] = combined
                pairedIndices[i] = true
                pairedIndices[vehicleIndex] = true
            else
                -- Crew without vehicle, add as-is
                paired[#paired + 1] = fighter
                pairedIndices[i] = true
            end
        elseif not pairedIndices[i] then
            -- Regular fighter (not crew or vehicle, or unpaired vehicle)
            paired[#paired + 1] = fighter
            pairedIndices[i] = true
        end
    end
    
    return paired
end

-- Parse all fighter cards from HTML
local function parseFighters(html)
    local fighters = {}
    local pos = 1
    
    while true do
        -- Search for any card div (not just fighters, also exotic beasts and vehicles)
        -- Pattern: class="card g-col-12 (any grid classes) break-inside-avoid
        local cardStart = findPlain(html, 'class="card g-col-12', pos)
        if not cardStart then break end
        
        -- Verify it has break-inside-avoid (filter out non-fighter cards)
        local classEnd = findPlain(html, '"', cardStart + 15)
        local shouldProcessCard = false
        
        if classEnd then
            local classContent = html:sub(cardStart, classEnd)
            if findPlain(classContent, 'break-inside-avoid') then
                shouldProcessCard = true
            end
        end
        
        if shouldProcessCard then
            local idStart = findPlain(html, 'id="', cardStart)
            if not idStart then break end
            
            local idEnd = findPlain(html, '"', idStart + 4)
            local cardId = html:sub(idStart + 4, idEnd - 1)
            
            -- Skip stash, dead, retired fighters
            local nameCheck = html:sub(idEnd, idEnd + 800)
            local shouldSkip = false
            
            if findPlain(nameCheck, '<h3 class="h5 mb-0">Stash</h3>') or
               findPlain(nameCheck, 'bg-danger">%s*Dead%s*</span>') or
               findPlain(nameCheck, 'bg-secondary">%s*Retired%s*</span>') then
                shouldSkip = true
                log("DEBUG: Skipping card ID: " .. cardId .. " (Stash/Dead/Retired)")
            end
            
            if not shouldSkip then
                -- Find card boundaries
                local divCount = 1
                local i = findPlain(html, '>', cardStart) + 1
                
                while divCount > 0 and i < #html do
                    local nextOpen = findPlain(html, '<div', i)
                    local nextClose = findPlain(html, '</div>', i)
                    
                    if not nextClose then break end
                    
                    if nextOpen and nextOpen < nextClose then
                        divCount = divCount + 1
                        i = nextOpen + 4
                    else
                        divCount = divCount - 1
                        i = nextClose + 6
                    end
                end
                
                local cardContent = html:sub(cardStart, i - 1)
                
                -- Debug: Log card size for troubleshooting
                log("DEBUG: Parsing card ID: " .. cardId .. ", size: " .. #cardContent .. " chars")
                
                local success, fighter = pcall(parseFighterCard, cardId, cardContent)
                if success and fighter and fighter.name ~= "" then
                    fighters[#fighters + 1] = fighter
                elseif success and fighter then
                    log("DEBUG: Skipped fighter with empty name, ID: " .. cardId)
                else
                    log("DEBUG: Failed to parse card ID: " .. cardId .. ", error: " .. tostring(fighter))
                end
                
                pos = i
            else
                pos = idEnd + 1
            end
        else
            pos = cardStart + 20
        end
    end
    
    -- Pair vehicles with their crew members
    fighters = pairVehiclesWithCrew(fighters)
    
    return fighters
end

--------------------------------------------------------------------------------
-- FORMATTING FUNCTIONS
--------------------------------------------------------------------------------

-- Format fighter card for model description (streamlined format)
local function formatFighterCard(fighter)
    local lines = {}
    
    -- Header: Type, Category, Cost, XP (no redundant name) - purple for main info
    -- Add [EXOTIC BEAST] designation for pets, [VEHICLE+CREW] for combined units
    if fighter.category == "Exotic Beast" then
        lines[#lines + 1] = string.format("[%s][EXOTIC BEAST][-] | [%s]%s | %s | %s | XP %s[-]", 
            COLORS.orange, COLORS.purple, fighter.fighter_type, fighter.category, fighter.cost, fighter.xp or "0")
    elseif fighter.vehicle_name then
        -- This is a combined crew+vehicle unit
        lines[#lines + 1] = string.format("[%s][VEHICLE+CREW][-] | [%s]%s | %s | %s | XP %s[-]", 
            COLORS.pink, COLORS.purple, fighter.fighter_type, fighter.category, fighter.cost, fighter.xp or "0")
    else
        lines[#lines + 1] = string.format("[%s]%s | %s | %s | XP %s[-]", 
            COLORS.purple, fighter.fighter_type, fighter.category, fighter.cost, fighter.xp or "0")
    end
    lines[#lines + 1] = ""
    
    -- Characteristics (cyan headers, plain text values)
    -- Check if this is a vehicle/crew combo (has Fr, Sd, Rr vehicle stats)
    if fighter.vehicle_name and (fighter.characteristics["Fr"] or fighter.characteristics["HP"]) then
        -- Vehicle+Crew combined stats: M, BS, Fr, Sd, Rr, HP, Hnd, Sv on row 1
        -- Ld, Cl, Wil, Int on row 2
        local row1 = {"M", "BS", "Fr", "Sd", "Rr", "HP", "Hnd", "Sv"}
        local row2 = {"Ld", "Cl", "Wil", "Int"}
        
        local line1 = "[" .. COLORS.cyan .. "]M    BS   Fr   Sd   Rr   HP   Hnd  Sv  [-]"
        lines[#lines + 1] = line1
        
        local vals1 = {}
        for i, stat in ipairs(row1) do
            local val = fighter.characteristics[stat] or "-"
            vals1[#vals1 + 1] = string.format("  %-3s", val)
        end
        lines[#lines + 1] = table.concat(vals1, "")
        
        local line3 = "[" .. COLORS.cyan .. "]     Ld   Cl   Wil  Int [-]"
        lines[#lines + 1] = line3
        
        local vals2 = {"     "}
        for _, stat in ipairs(row2) do
            local val = fighter.characteristics[stat] or "-"
            vals2[#vals2 + 1] = string.format("  %-3s", val)
        end
        lines[#lines + 1] = table.concat(vals2, "")
        lines[#lines + 1] = ""
    else
        -- Normal fighter stats: M, WS, BS, S, T, W, I, A on row 1
        -- Ld, Cl, Wil, Int on row 2
        local row1 = {"M", "WS", "BS", "S", "T", "W", "I", "A"}
        local row2 = {"Ld", "Cl", "Wil", "Int"}
        
        local line1 = "[" .. COLORS.cyan .. "]M    WS   BS   S    T    W    I    A[-]"
        lines[#lines + 1] = line1
        
        local vals1 = {}
        for i, stat in ipairs(row1) do
            local val = fighter.characteristics[stat] or "-"
            if i == 1 then
                vals1[#vals1 + 1] = string.format("%-4s", val)
            else
                vals1[#vals1 + 1] = string.format("%-4s", val)
            end
        end
        lines[#lines + 1] = table.concat(vals1, " ")
        
        local line3 = "[" .. COLORS.cyan .. "]     Ld   Cl   Wil  Int[-]"
        lines[#lines + 1] = line3
        
        local vals2 = {"     "}
        for _, stat in ipairs(row2) do
            local val = fighter.characteristics[stat] or "-"
            vals2[#vals2 + 1] = string.format("%-4s", val)
        end
        lines[#lines + 1] = table.concat(vals2, " ")
        lines[#lines + 1] = ""
    end
    
    -- Weapons (red header, cyan weapon names, yellow stat headers, plain stats/traits)
    if #fighter.weapons > 0 then
        lines[#lines + 1] = string.format("[%s]Weapons[-]", COLORS.red)
        if showWeaponProfiles then
            -- Format stats with proper spacing (6-char columns)
            local function padStat(val, width)
                local s = tostring(val or "-")
                local len = #s
                local leftPad = math.floor((width - len) / 2)
                local rightPad = width - len - leftPad
                return string.rep(" ", leftPad) .. s .. string.rep(" ", rightPad)
            end
            
            -- Group identical weapons by creating a signature for comparison
            local function weaponSignature(weapon)
                local sig = weapon.name .. "|"
                for _, profile in ipairs(weapon.profiles) do
                    sig = sig .. (profile.profile_name or "") .. ","
                    sig = sig .. (profile.rg_short or "") .. ","
                    sig = sig .. (profile.rg_long or "") .. ","
                    sig = sig .. (profile.acc_short or "") .. ","
                    sig = sig .. (profile.acc_long or "") .. ","
                    sig = sig .. (profile.strength or "") .. ","
                    sig = sig .. (profile.ap or "") .. ","
                    sig = sig .. (profile.damage or "") .. ","
                    sig = sig .. (profile.ammo or "") .. ","
                    sig = sig .. (profile.traits or "") .. ";"
                end
                sig = sig .. (weapon.traits or "")
                return sig
            end
            
            local weaponGroups = {}
            local weaponOrder = {}
            for _, weapon in ipairs(fighter.weapons) do
                local sig = weaponSignature(weapon)
                if not weaponGroups[sig] then
                    weaponGroups[sig] = {weapon = weapon, count = 0}
                    weaponOrder[#weaponOrder + 1] = sig
                end
                weaponGroups[sig].count = weaponGroups[sig].count + 1
            end
            
            -- Full weapon profiles with stats
            for groupIdx, sig in ipairs(weaponOrder) do
                local group = weaponGroups[sig]
                local weapon = group.weapon
                local count = group.count
                
                -- Show weapon name with count if > 1
                if count > 1 then
                    lines[#lines + 1] = string.format("[%s]%dx %s[-]", COLORS.cyan, count, weapon.name)
                else
                    lines[#lines + 1] = string.format("[%s]%s[-]", COLORS.cyan, weapon.name)
                end
                
                -- Show stat headers once per weapon with yellow color (aligned to match padStat output)
                lines[#lines + 1] = string.format("[%s]  S      L      S      L    |    Str    Ap     D      Am   [-]", COLORS.yellow)
                
                for _, profile in ipairs(weapon.profiles) do
                    -- Show profile name if it exists (e.g., "Frag", "Krak")
                    if profile.profile_name and profile.profile_name ~= "" then
                        lines[#lines + 1] = string.format("[%s]%s[-]", COLORS.purple, profile.profile_name)
                    end
                    
                    -- Remove quotes from range values
                    local shortRange = (profile.rg_short or "-"):gsub('"', ''):gsub("'", '')
                    local longRange = (profile.rg_long or "-"):gsub('"', ''):gsub("'", '')
                    
                    local statsLine = string.format("%s %s %s %s|  %s %s %s %s",
                        padStat(shortRange, 6),
                        padStat(longRange, 6),
                        padStat(profile.acc_short, 6),
                        padStat(profile.acc_long, 6),
                        padStat(profile.strength, 6),
                        padStat(profile.ap, 6),
                        padStat(profile.damage, 6),
                        padStat(profile.ammo, 6)
                    )
                    lines[#lines + 1] = statsLine
                    
                    -- Traits in plain lowercase text, no color
                    if profile.traits and profile.traits ~= "" then
                        lines[#lines + 1] = "  " .. profile.traits:lower()
                    end
                end
                
                -- Add weapon-level traits if present
                if weapon.traits and weapon.traits ~= "" then
                    lines[#lines + 1] = "  " .. weapon.traits:lower()
                end
                
                -- Add spacing between weapons
                if groupIdx < #weaponOrder then
                    lines[#lines + 1] = ""
                end
            end
        else
            -- Weapon names only - group identical weapons with counts
            local weaponCounts = {}
            local weaponOrder = {}
            for _, weapon in ipairs(fighter.weapons) do
                if not weaponCounts[weapon.name] then
                    weaponCounts[weapon.name] = 0
                    weaponOrder[#weaponOrder + 1] = weapon.name
                end
                weaponCounts[weapon.name] = weaponCounts[weapon.name] + 1
            end
            
            local weaponNames = {}
            for _, name in ipairs(weaponOrder) do
                local count = weaponCounts[name]
                if count > 1 then
                    weaponNames[#weaponNames + 1] = count .. "x " .. name
                else
                    weaponNames[#weaponNames + 1] = name
                end
            end
            lines[#lines + 1] = "  " .. table.concat(weaponNames, ", ")
        end
        lines[#lines + 1] = ""
    end
    
    -- Skills (conditionally displayed) - purple header
    if showSkills and #fighter.skills > 0 then
        lines[#lines + 1] = string.format("[%s]Skills[-]", COLORS.purple)
        lines[#lines + 1] = "  " .. table.concat(fighter.skills, ", ")
        lines[#lines + 1] = ""
    end
    
    -- Equipment (green header)
    if #fighter.equipment > 0 then
        lines[#lines + 1] = string.format("[%s]Equipment[-]", COLORS.green)
        local equipmentList = {}
        for _, item in ipairs(fighter.equipment) do
            if showCredits then
                equipmentList[#equipmentList + 1] = item
            else
                -- Remove credit values in parentheses (e.g., "(15¢)", "(25 credits)")
                local filtered = item:gsub("%s*%([%d%.]+[¢c][^%)]*%)", "")
                filtered = filtered:gsub("%s*%([%d%.]+%s*credits?%)", "")
                equipmentList[#equipmentList + 1] = filtered
            end
        end
        lines[#lines + 1] = "  " .. table.concat(equipmentList, ", ")
        lines[#lines + 1] = ""
    end
    
    -- Rules (conditionally displayed) - pink header
    if showRules and #fighter.rules > 0 then
        lines[#lines + 1] = string.format("[%s]Rules[-]", COLORS.pink)
        lines[#lines + 1] = "  " .. table.concat(fighter.rules, ", ")
        lines[#lines + 1] = ""
    end
    
    -- Powers (Psyker/Wyrd powers) - purple header
    if fighter.powers and #fighter.powers > 0 then
        lines[#lines + 1] = string.format("[%s]Powers[-]", COLORS.purple)
        lines[#lines + 1] = "  " .. table.concat(fighter.powers, ", ")
        lines[#lines + 1] = ""
    end
    
    -- Gene-smithing (Goliath gang-specific) - orange header
    if fighter.genesmithing and #fighter.genesmithing > 0 then
        lines[#lines + 1] = string.format("[%s]Gene-smithing[-]", COLORS.orange)
        local geneList = {}
        for _, item in ipairs(fighter.genesmithing) do
            if showCredits then
                geneList[#geneList + 1] = item
            else
                -- Remove credit values in parentheses
                local filtered = item:gsub("%s*%([%d%.]+[¢c][^%)]*%)", "")
                filtered = filtered:gsub("%s*%([%d%.]+%s*credits?%)", "")
                geneList[#geneList + 1] = filtered
            end
        end
        lines[#lines + 1] = "  " .. table.concat(geneList, ", ")
        lines[#lines + 1] = ""
    end
    
    -- Cyberteknika (Van Saar gang-specific) - cyan header
    if fighter.cyberteknika and #fighter.cyberteknika > 0 then
        lines[#lines + 1] = string.format("[%s]Cyberteknika[-]", COLORS.cyan)
        local cyberList = {}
        for _, item in ipairs(fighter.cyberteknika) do
            if showCredits then
                cyberList[#cyberList + 1] = item
            else
                -- Remove credit values in parentheses
                local filtered = item:gsub("%s*%([%d%.]+[¢c][^%)]*%)", "")
                filtered = filtered:gsub("%s*%([%d%.]+%s*credits?%)", "")
                cyberList[#cyberList + 1] = filtered
            end
        end
        lines[#lines + 1] = "  " .. table.concat(cyberList, ", ")
        lines[#lines + 1] = ""
    end
    
    -- Vehicle equipment sections (Body, Drive, Engine, etc.)
    if fighter.vehicle and fighter.vehicle.equipment and #fighter.vehicle.equipment > 0 then
        -- Group equipment by section (Body, Drive, Engine, etc.)
        local currentSection = nil
        for _, item in ipairs(fighter.vehicle.equipment) do
            -- Check if this is a section header (ends with count like "(3/3)")
            if item:match("%((%d+)/(%d+)%)$") then
                currentSection = item
                lines[#lines + 1] = string.format("[%s]%s[-]", COLORS.orange, currentSection)
            else
                -- This is an item in the current section
                lines[#lines + 1] = "  " .. item
            end
        end
        lines[#lines + 1] = ""
    end
    
    -- Injuries (red header)
    if #fighter.injuries > 0 then
        lines[#lines + 1] = string.format("[%s]Injuries[-]", COLORS.red)
        lines[#lines + 1] = "  " .. table.concat(fighter.injuries, ", ")
        lines[#lines + 1] = ""
    end
    
    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------------
-- UI MANAGEMENT
--------------------------------------------------------------------------------

-- Create campaign gang selection buttons
local function createCampaignGangButtons()
    self.clearButtons()
    
    -- Title button (non-clickable) with white background
    self.createButton({
        click_function = "doNothing",
        function_owner = self,
        label = "Select Gang to Spawn",
        position = {0, 1, -2.5},
        width = 1800,
        height = 300,
        font_size = 160,
        color = {1, 1, 1},  -- White background
        font_color = {0, 0, 0}  -- Black text
    })
    
    -- Gang selection buttons in single column
    local buttonWidth = 2000
    local buttonHeight = 250
    local fontSize = 120
    local startZ = -2.0
    local zSpacing = 0.35
    
    for i, gang in ipairs(campaignGangs) do
        local zPos = startZ + (i * zSpacing)
        
        -- Truncate gang name if too long (35 chars)
        local displayName = gang.name
        if #displayName > 35 then
            displayName = displayName:sub(1, 35) .. "..."
        end
        
        -- Use gang color for button, or default green if no color
        local buttonColor = gang.color or {0.314, 0.980, 0.482}
        
        self.createButton({
            click_function = "spawnCampaignGang_" .. i,
            function_owner = self,
            label = displayName,
            position = {0, 1, zPos},
            width = buttonWidth,
            height = buttonHeight,
            font_size = fontSize,
            color = buttonColor,
            tooltip = gang.name  -- Full name in tooltip
        })
    end
    
    -- Clear/back button at bottom
    self.createButton({
        click_function = "clearCampaignGangs",
        function_owner = self,
        label = "Clear",
        position = {0, 1, startZ + ((#campaignGangs + 1) * zSpacing)},
        width = 1000,
        height = 300,
        font_size = 120,
        color = {1.0, 0.333, 0.333}  -- Red
    })
end

-- Create fighter selection buttons with dynamic layout
local function createFighterButtons()
    self.clearButtons()
    
    if #gangFighters == 0 then
        -- Show input URL button
        self.createButton({
            click_function = "showURLInput",
            function_owner = self,
            label = "Enter Campaign or Gang URL",
            position = {0, 1, -2},
            width = 1800,
            height = 500,
            font_size = 140,
            color = {0.5, 0.9, 0.9},
            tooltip = "Enter a Gyrinx.app campaign URL to spawn gangs, or gang URL to load fighters"
        })
        
        -- Show load button if URL is set
        if GANG_URL ~= "" then
            -- Use gang name if available, otherwise show "Load Gang"
            local gangLabel = "Load Gang"
            if GANG_NAME ~= "" then
                -- Shorten to 20 characters if needed
                if #GANG_NAME > 20 then
                    gangLabel = "Load " .. GANG_NAME:sub(1, 20) .. "..."
                else
                    gangLabel = "Load " .. GANG_NAME
                end
            end
            
            self.createButton({
                click_function = "loadGangData",
                function_owner = self,
                label = gangLabel,
                position = {0, 1, -1.2},
                width = 1200,
                height = 400,
                font_size = 150,
                color = {0.314, 0.980, 0.482}
            })
        end
        return
    end
    
    -- Refresh button at top (centered)
    self.createButton({
        click_function = "loadGangData",
        function_owner = self,
        label = "Refresh",
        position = {0, 1, -2.5},
        width = 800,
        height = 400,
        font_size = 120,
        color = {0.545, 0.910, 0.992}  -- Cyan
    })
    
    -- Row 1: Display toggles (spread out, unique colors)
    self.createButton({
        click_function = "toggleWeaponProfiles",
        function_owner = self,
        label = showWeaponProfiles and "Weapon Profiles" or "Weapon Names",
        position = {-2.1, 1, 2.3},
        width = 1050,
        height = 300,
        font_size = 95,
        color = showWeaponProfiles and {0.545, 0.910, 0.992} or {0.3, 0.3, 0.3},  -- Cyan when active
        tooltip = "Toggle full weapon profiles or names only"
    })
    
    self.createButton({
        click_function = "toggleSkills",
        function_owner = self,
        label = showSkills and "Skills" or "No Skills",
        position = {-0.6, 1, 2.3},
        width = 750,
        height = 300,
        font_size = 100,
        color = showSkills and {0.741, 0.576, 0.976} or {0.3, 0.3, 0.3},  -- Purple when active
        tooltip = "Toggle skills display"
    })
    
    self.createButton({
        click_function = "toggleRules",
        function_owner = self,
        label = showRules and "Rules" or "No Rules",
        position = {0.5, 1, 2.3},
        width = 750,
        height = 300,
        font_size = 100,
        color = showRules and {1.0, 0.475, 0.776} or {0.3, 0.3, 0.3},  -- Pink when active
        tooltip = "Toggle rules display"
    })
    
    self.createButton({
        click_function = "toggleCredits",
        function_owner = self,
        label = showCredits and "Credits" or "No Credits",
        position = {1.7, 1, 2.3},
        width = 750,
        height = 300,
        font_size = 95,
        color = showCredits and {0.945, 0.769, 0.059} or {0.3, 0.3, 0.3},  -- Orange when active
        tooltip = "Toggle credit values in equipment"
    })
    
    -- Row 2: Ready/Activated (smaller, above Copy to Model)
    self.createButton({
        click_function = "toggleReady",
        function_owner = self,
        label = "Ready",
        position = {-1.5, 1, 2.85},
        width = 550,
        height = 280,
        font_size = 110,
        color = activationState == "ready" and {0.314, 0.980, 0.482} or {0.3, 0.3, 0.3},  -- Green when active
        tooltip = "Mark fighter as Ready"
    })
    
    self.createButton({
        click_function = "toggleActivated",
        function_owner = self,
        label = "Activated",
        position = {-0.5, 1, 2.85},
        width = 650,
        height = 280,
        font_size = 100,
        color = activationState == "activated" and {1.0, 0.333, 0.333} or {0.3, 0.3, 0.3},  -- Red when active
        tooltip = "Mark fighter as Activated"
    })
    
    -- Row 2 continued: Copy to Model button (to the right)
    self.createButton({
        click_function = "copyToModelOnObject",
        function_owner = self,
        label = "Copy to Model",
        position = {1.0, 1, 2.85},
        width = 1400,
        height = 280,
        font_size = 130,
        color = {0.314, 0.980, 0.482},  -- Green
        tooltip = "Place a model on this tool, select a fighter, then click to copy"
    })
    
    -- Fighter selection grid (dynamic columns based on fighter count)
    -- Scale columns: 1-3 fighters = 1 col, 4-6 = 2 cols, 7-9 = 3 cols, 10+ = 4 cols
    local columns
    if #gangFighters <= 3 then
        columns = 1
    elseif #gangFighters <= 6 then
        columns = 2
    elseif #gangFighters <= 9 then
        columns = 3
    else
        columns = 4
    end
    
    local buttonWidth = 2400 / columns  -- Even wider buttons to prevent text overflow
    local horizontalSpacing = 5.0 / columns  -- Much more space between columns
    local verticalSpacing = 0.7  -- More vertical space between rows
    local startZ = -1.7
    local startX = -2.5 + (horizontalSpacing / 2)  -- Center the wider grid
    
    for i, fighter in ipairs(gangFighters) do
        local row = math.floor((i - 1) / columns)
        local col = (i - 1) % columns
        
        local color = {0.741, 0.576, 0.976}  -- Purple
        if i == selectedFighterIndex then
            color = {0.314, 0.980, 0.482}  -- Green when selected
        end
        
        -- Format button label with legendary name if present
        local buttonLabel = fighter.name
        if fighter.legendary_name then
            -- Show as "Legendary" Name for button
            buttonLabel = '"' .. fighter.legendary_name .. '" ' .. fighter.name
        end
        
        -- Truncate long names to prevent overflow (adjust based on button width)
        local maxLength = 18  -- Shorter to ensure no overflow
        if #buttonLabel > maxLength then
            buttonLabel = buttonLabel:sub(1, maxLength) .. "..."
        end
        
        -- Use smaller font for better fit with wrapping
        local fontSize = 80  -- Slightly smaller font
        
        self.createButton({
            click_function = "selectFighter_" .. i,
            function_owner = self,
            label = buttonLabel,
            position = {startX + (col * horizontalSpacing), 1, startZ + (row * verticalSpacing)},
            width = buttonWidth,
            height = 380,  -- Slightly taller to accommodate wrapping
            font_size = fontSize,
            color = color,
            tooltip = fighter.name .. " - " .. fighter.fighter_type .. " - " .. fighter.cost
        })
    end
end

-- Generate click handler functions for campaign gang spawning
local function ensureCampaignClickHandlers(count)
    for i = 1, count do
        local funcName = "spawnCampaignGang_" .. i
        if not _G[funcName] then
            _G[funcName] = function(_, playerColor)
                spawnGangFromCampaign(i, playerColor)
            end
        end
    end
end

-- Generate click handler functions for all fighters
local function ensureClickHandlers(count)
    for i = 1, count do
        if not _G["selectFighter_" .. i] then
            _G["selectFighter_" .. i] = function()
                selectFighter(i)
            end
        end
    end
end

--------------------------------------------------------------------------------
-- DATA FETCHING
--------------------------------------------------------------------------------

-- Dummy function for non-clickable buttons
function doNothing()
    -- Does nothing, used for display-only buttons
end

-- Show input dialog for gang URL (player-specific)
function showURLInput(_, playerColor)
    if inputActive then return end
    inputActive = true
    
    Player[playerColor].showInputDialog(
        "Enter Gyrinx.app URL (Campaign or Gang):",
        "",
        function(input, playerColor)
            inputActive = false
            if input and input ~= "" then
                -- Check if it's a campaign URL
                if input:match("gyrinx%.app/campaign/") then
                    -- Load campaign and show gang selection
                    CAMPAIGN_URL = input
                    loadCampaignGangs()
                else
                    -- Spawn a new gang token for this player
                    spawnNewGangToken(input, playerColor)
                    -- Clear the URL from the spawner so it's fresh for the next player
                    GANG_URL = ""
                    GANG_NAME = ""
                end
            end
        end
    )
end

-- Spawn a new gang token with the provided URL
function spawnNewGangToken(gangUrl, playerColor)
    local myPos = self.getPosition()
    local myRot = self.getRotation()
    
    -- Offset new token slightly from the spawner
    local spawnPos = {
        x = myPos.x + 5,
        y = myPos.y + 1,
        z = myPos.z
    }
    
    -- Clone this object and modify the script state to include the gang URL and player color
    local objJson = self.getJSON()
    local objData = JSON.decode(objJson)
    
    -- Set the LuaScriptState to include the gang URL and player color
    local scriptState = JSON.encode({
        gang_url = gangUrl,
        auto_load = true,
        player_color = playerColor
    })
    objData.LuaScriptState = scriptState
    
    spawnObjectJSON({
        json = JSON.encode(objData),
        position = spawnPos,
        rotation = myRot,
        scale = self.getScale(),
        callback_function = function(spawnedObj)
            -- Set description
            spawnedObj.setDescription("Magic Cat Token - Necromunda Gyrinx Bridge")
        end
    })
    
    Player[playerColor].broadcast("Gang token spawned! Loading roster data...", {0.314, 0.980, 0.482})
end

-- Spawn a gang token from campaign selection
function spawnGangFromCampaign(gangIndex, playerColor)
    if not campaignGangs[gangIndex] then
        print("ERROR: Invalid gang index " .. gangIndex)
        return
    end
    
    local gang = campaignGangs[gangIndex]
    print(string.format("Spawning %s for %s player...", gang.name, playerColor))
    
    -- Get the magic cat token (GUID: 64c036)
    local magicCatToken = getObjectFromGUID("64c036")
    if not magicCatToken then
        Player[playerColor].broadcast("ERROR: Magic cat token not found (GUID: 64c036)", {1, 0.333, 0.333})
        return
    end
    
    local myPos = self.getPosition()
    local myRot = self.getRotation()
    
    -- Offset new token from spawner
    local spawnPos = {
        x = myPos.x + 5,
        y = myPos.y + 1,
        z = myPos.z
    }
    
    -- Clone the magic cat token
    local objJson = magicCatToken.getJSON()
    local objData = JSON.decode(objJson)
    
    -- Clear any existing script state
    objData.LuaScriptState = ""
    
    -- Tint the token based on gang color (or white if no color)
    if gang.color then
        objData.ColorDiffuse = {
            r = gang.color[1],
            g = gang.color[2],
            b = gang.color[3]
        }
    else
        -- Default to white if no color specified
        objData.ColorDiffuse = {
            r = 1,
            g = 1,
            b = 1
        }
    end
    
    spawnObjectJSON({
        json = JSON.encode(objData),
        position = spawnPos,
        rotation = myRot,
        scale = magicCatToken.getScale(),
        callback_function = function(spawnedObj)
            spawnedObj.setDescription("Necromunda Gang Token - " .. gang.name)
            
            -- Call setGangURLAndLoad on the spawned object after it's fully loaded
            Wait.frames(function()
                spawnedObj.call("setGangURLAndLoad", {
                    url = gang.url,
                    gangName = gang.name,
                    gangColor = gang.color,
                    gangRating = gang.rating
                })
            end, 5)
        end
    })
    
    Player[playerColor].broadcast(gang.name .. " token spawned! Loading roster...", {0.314, 0.980, 0.482})
end

-- Clear campaign selection
function clearCampaignGangs()
    campaignGangs = {}
    CAMPAIGN_URL = ""
    createFighterButtons()
    print("Campaign cleared. Ready to enter new URL.")
end

-- Load campaign gangs and show selection UI
function loadCampaignGangs()
    if CAMPAIGN_URL == "" then
        print("Please enter a campaign URL first!")
        return
    end
    
    print("Fetching campaign roster from Gyrinx.app...")
    
    WebRequest.get(CAMPAIGN_URL, function(webReturn)
        if webReturn.is_error then
            print("Error loading campaign: " .. webReturn.error)
            return
        end
        
        campaignGangs = {}
        local html = webReturn.text
        
        -- Find the "Gangs" heading section
        local gangsHeading = html:find('<h2[^>]*>%s*Gangs%s*</h2>')
        if not gangsHeading then
            -- Try alternate format
            gangsHeading = html:find('## Gangs', 1, true)
        end
        
        if not gangsHeading then
            print("Could not find Gangs section in campaign page")
            return
        end
        
        -- Find the next section heading to know where gangs section ends
        local nextSection = html:find('<h2', gangsHeading + 10)
        if not nextSection then
            nextSection = #html  -- Use end of document if no next section
        end
        
        -- Search for all gang links between gangs heading and next section
        local searchPos = gangsHeading
        
        while searchPos < nextSection do
            -- Find next <a href="/list/
            local linkStart = html:find('<a href="/list/', searchPos, true)
            if not linkStart or linkStart >= nextSection then break end
            
            -- Extract the full UUID (36 characters with hyphens)
            local uuidStart = linkStart + 15  -- Skip '<a href="/list/'
            local uuid = ""
            for i = 0, 35 do
                local char = html:sub(uuidStart + i, uuidStart + i)
                uuid = uuid .. char
            end
            
            -- Find the gang name inside the <a> tag
            local nameStart = html:find('>', linkStart, true)
            if not nameStart then break end
            nameStart = nameStart + 1
            
            local nameEnd = html:find('</a>', nameStart, true)
            if not nameEnd then break end
            
            local gangFullText = html:sub(nameStart, nameEnd - 1)
            gangFullText = cleanText(gangFullText)
            
            -- Extract just the gang name (before the •)
            local gangName = gangFullText
            local bulletPos = gangName:find('•')
            if bulletPos then
                gangName = gangName:sub(1, bulletPos - 1)
                gangName = cleanText(gangName)
            end
            
            -- Look for color badge span INSIDE the <a> tag content
            -- The structure is: <a href="/list/UUID"><span><span style="background-color: #XXXXXX">Gang Name</span></span></a>
            local gangColor = nil
            local linkContent = html:sub(nameStart, nameEnd)
            
            -- Search for background-color: # pattern and extract 6-char hex
            local colorPos = linkContent:find('background%-color:%s*#')
            if colorPos then
                -- Find where the # is
                local hashPos = linkContent:find('#', colorPos, true)
                if hashPos then
                    -- Extract next 6 characters after #
                    local hexColor = linkContent:sub(hashPos + 1, hashPos + 6)
                    -- Validate it's a proper hex color
                    if hexColor and #hexColor == 6 and hexColor:match('^[0-9a-fA-F]+$') then
                        -- Convert hex to RGB (0-1 range)
                        local r = tonumber(hexColor:sub(1, 2), 16) / 255
                        local g = tonumber(hexColor:sub(3, 4), 16) / 255
                        local b = tonumber(hexColor:sub(5, 6), 16) / 255
                        gangColor = {r, g, b}
                        print(string.format("Gang '%s' color: #%s (RGB: %.2f, %.2f, %.2f)", gangName, hexColor, r, g, b))
                    end
                end
            end
            
            if not gangColor then
                print(string.format("Gang '%s' - no color found, will use default", gangName))
            end
            
            -- Extract gang rating (credits) from inside the link content
            -- Look for pattern like "• 3884¢" in the <p> tag within the <a> tag
            local gangRating = "0¢"
            -- Search for digits followed by ¢ character - use findPlain to locate it
            local centPos = linkContent:find('¢', 1, true)
            if centPos then
                -- Search backwards from ¢ to find the number
                local numStart = centPos - 1
                while numStart > 0 do
                    local char = linkContent:sub(numStart, numStart)
                    if not char:match('%d') then
                        numStart = numStart + 1
                        break
                    end
                    numStart = numStart - 1
                end
                local credits = linkContent:sub(numStart, centPos - 1)
                if credits and credits:match('^%d+$') then
                    gangRating = credits .. "¢"
                    print(string.format("Gang '%s' rating: %s", gangName, gangRating))
                end
            end
            
            table.insert(campaignGangs, {
                name = gangName,
                url = "https://gyrinx.app/list/" .. uuid,
                id = uuid,
                color = gangColor,
                rating = gangRating
            })
            
            searchPos = nameEnd + 1
        end
        
        if #campaignGangs == 0 then
            print("No gangs found in campaign")
            return
        end
        
        print(string.format("Found %d gangs in campaign!", #campaignGangs))
        
        -- Use Wait.frames to prevent UI freezing
        Wait.frames(function()
            ensureCampaignClickHandlers(#campaignGangs)
            Wait.frames(function()
                createCampaignGangButtons()
                print("Campaign roster ready!")
            end, 1)
        end, 1)
    end)
end

-- Fetch gang data from Gyrinx.app
function loadGangData()
    if GANG_URL == "" or GANG_URL == "https://gyrinx.app/list/YOUR-GANG-ID" then
        print("Please enter a valid gang URL first!")
        return
    end
    
    print("Fetching gang roster from Gyrinx.app...")
    
    WebRequest.get(GANG_URL, function(webReturn)
        if webReturn.is_error then
            print("Error loading gang: " .. webReturn.error)
            return
        end
        
        -- Extract gang name from HTML (look for <h1> tag with gang name)
        local gangNameMatch = webReturn.text:match('<h1[^>]*>%s*([^<]+)%s*</h1>')
        if gangNameMatch and gangNameMatch ~= "" then
            GANG_NAME = cleanText(gangNameMatch)
            -- Set the object's name to the gang name
            self.setName(GANG_NAME)
        end
        
        gangFighters = parseFighters(webReturn.text)
        
        if #gangFighters == 0 then
            print("No fighters found. Check your gang URL.")
            createFighterButtons()
            return
        end
        
        Wait.frames(function()
            ensureClickHandlers(#gangFighters)
            createFighterButtons()
            local gangText = GANG_NAME ~= "" and (" - " .. GANG_NAME) or ""
            print(string.format("Loaded %d fighters%s!", #gangFighters, gangText))
        end, 1)
    end)
end

--------------------------------------------------------------------------------
-- FIGHTER SELECTION & MODEL INTERACTION
--------------------------------------------------------------------------------

-- Select a fighter
function selectFighter(fighterIndex)
    selectedFighterIndex = fighterIndex
    createFighterButtons()
    print("Selected: " .. gangFighters[fighterIndex].name)
end

-- Toggle activation states
function toggleReady()
    if activationState == "ready" then
        activationState = nil
    else
        activationState = "ready"
    end
    createFighterButtons()
end

function toggleActivated()
    if activationState == "activated" then
        activationState = nil
    else
        activationState = "activated"
    end
    createFighterButtons()
end

-- Toggle weapon profile display
function toggleWeaponProfiles()
    showWeaponProfiles = not showWeaponProfiles
    createFighterButtons()
end

-- Toggle skills display
function toggleSkills()
    showSkills = not showSkills
    createFighterButtons()
end

-- Toggle rules display
function toggleRules()
    showRules = not showRules
    createFighterButtons()
end

-- Toggle credits display
function toggleCredits()
    showCredits = not showCredits
    createFighterButtons()
end

-- Reset tool to initial state
function resetTool()
    gangFighters = {}
    selectedFighterIndex = nil
    activationState = nil
    GANG_URL = ""
    GANG_NAME = ""
    createFighterButtons()
    print("Tool reset. Enter a new gang URL.")
end

-- Get objects placed on this script object
local function getObjectsOnMe()
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
            
            if distance < 3 and objPos.y > myPos.y then
                objectsOnMe[#objectsOnMe + 1] = obj
            end
        end
    end
    
    return objectsOnMe
end

-- Copy selected fighter to models on object
function copyToModelOnObject()
    if not selectedFighterIndex then
        print("Please select a fighter first!")
        return
    end
    
    local objects = getObjectsOnMe()
    
    if #objects == 0 then
        print("Place a model on this object first!")
        return
    end
    
    local fighter = gangFighters[selectedFighterIndex]
    local cardText = formatFighterCard(fighter)
    
    -- Build display name with legendary name and activation state
    local displayName
    if fighter.legendary_name then
        displayName = "[" .. COLORS.yellow .. "]\"" .. fighter.legendary_name .. "\"[-] [" .. COLORS.cyan .. "]" .. fighter.name .. "[-]"
    else
        displayName = "[" .. COLORS.cyan .. "]" .. fighter.name .. "[-]"
    end
    if activationState == "ready" then
        displayName = displayName .. " - [50fa7b]Ready[-]"
    elseif activationState == "activated" then
        displayName = displayName .. " - [ff5555]Activated[-]"
    end
    
    local myPos = self.getPosition()
    local myRot = self.getRotation()
    
    -- Calculate spawn position based on button location (around edge of menu)
    local columns = math.min(math.ceil(#gangFighters / 10), 4)
    local idx = selectedFighterIndex - 1
    local column = idx % columns
    local row = math.floor(idx / columns)
    
    local buttonPosX = -1.5 + (column * 1.2)
    local buttonPosZ = -1.8 + (row * 0.45)
    
    -- Offset from button position to edge (left/right based on column, farther out)
    local xOffset = (column < columns / 2) and -5.5 or 5.5
    
    local localX = buttonPosX + xOffset
    local localZ = buttonPosZ
    
    -- Convert local coordinates to world space
    local rotRad = math.rad(myRot.y)
    local cosRot = math.cos(rotRad)
    local sinRot = math.sin(rotRad)
    
    local worldX = myPos.x + (localX * cosRot) - (localZ * sinRot)
    local worldZ = myPos.z + (localX * sinRot) + (localZ * cosRot)
    
    -- Spread models out to avoid collisions
    local modelSpacing = 3.0  -- Units between each model
    local modelOffset = 0
    
    for i, obj in ipairs(objects) do
        obj.setDescription(cardText)
        obj.setName(displayName)
        
        -- Offset each model in a line perpendicular to the edge
        local spreadX = worldX + (cosRot * modelOffset)
        local spreadZ = worldZ + (sinRot * modelOffset)
        
        -- Move to edge position with spacing
        obj.setPositionSmooth({x = spreadX, y = obj.getPosition().y, z = spreadZ})
        
        modelOffset = modelOffset + modelSpacing
        
        print("Applied " .. fighter.name .. "'s card to model")
    end
end

--------------------------------------------------------------------------------
-- TTS LIFECYCLE HOOKS
--------------------------------------------------------------------------------

-- Set gang URL and auto-load (called from campaign spawner)
function setGangURLAndLoad(params)
    GANG_URL = params.url
    GANG_NAME = params.gangName or ""
    local gangColor = params.gangColor
    local gangRating = params.gangRating or "0¢"
    gangFighters = {}
    selectedFighterIndex = nil
    showWeaponProfiles = true
    showSkills = true
    showRules = true
    showCredits = false
    
    -- Clear buttons immediately to avoid showing "Enter Campaign or Gang URL" button
    self.clearButtons()
    
    -- Set gang name with color highlighting if available
    if GANG_NAME ~= "" then
        if gangColor then
            -- Convert RGB to hex for rich text
            local r = math.floor(gangColor[1] * 255)
            local g = math.floor(gangColor[2] * 255)
            local b = math.floor(gangColor[3] * 255)
            local hexColor = string.format("%02x%02x%02x", r, g, b)
            self.setName("[" .. hexColor .. "]" .. GANG_NAME .. "[-]")
            
            -- Set description with rating in first line
            self.setDescription("Gang Rating: " .. gangRating .. "\n" .. GANG_NAME .. " - Necromunda Gang Roster")
        else
            self.setName(GANG_NAME)
            self.setDescription("Gang Rating: " .. gangRating .. "\n" .. GANG_NAME .. " - Necromunda Gang Roster")
        end
    end
    
    print("Loading roster for: " .. GANG_NAME .. " (" .. gangRating .. ")")
    loadGangData()
end

-- Save state between sessions
function onSave()
    local saveData = {
        gangURL = GANG_URL,
        gangName = GANG_NAME,
        selectedFighterIndex = selectedFighterIndex,
        activationState = activationState,
        showWeaponProfiles = showWeaponProfiles,
        showSkills = showSkills,
        showRules = showRules,
        showCredits = showCredits
    }
    return JSON.encode(saveData)
end

-- Load state and fetch gang data
function onLoad(saved_data)
    if saved_data ~= "" then
        local loaded = JSON.decode(saved_data)
        
        -- Check if this is a spawned token with auto-load enabled
        if loaded.auto_load and loaded.gang_url then
            GANG_URL = loaded.gang_url
            GANG_NAME = ""
            gangFighters = {}
            selectedFighterIndex = nil
            activationState = nil
            
            print("Necromunda Gyrinx Bridge loaded!")
            print("Auto-loading gang data...")
            
            -- Auto-load the gang data
            Wait.frames(function()
                loadGangData()
            end, 5)
            return
        end
        
        -- Normal saved state restoration
        GANG_URL = loaded.gangURL or GANG_URL
        GANG_NAME = loaded.gangName or GANG_NAME
        selectedFighterIndex = loaded.selectedFighterIndex
        activationState = loaded.activationState
        if loaded.showWeaponProfiles ~= nil then
            showWeaponProfiles = loaded.showWeaponProfiles
        end
        if loaded.showSkills ~= nil then
            showSkills = loaded.showSkills
        end
        if loaded.showRules ~= nil then
            showRules = loaded.showRules
        end
        if loaded.showCredits ~= nil then
            showCredits = loaded.showCredits
        end
    end
    
    print("Necromunda Gyrinx Bridge loaded!")
    print("Click to enter a Campaign or Gang URL.")
    
    -- Create initial UI (wait for user to enter URL and click Load Gang)
    createFighterButtons()
end
-- This script should be mirrored in the TTS plugin file: .tts/objects/magic cat token.64c036.lua
-- v2.4.1 starting on performance improvements.