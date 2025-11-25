# Quick TTS Integration Guide

## Testing Your Script

### Option 1: Test Locally First (Recommended)
```bash
lua tests/test_tts_script.lua
```
This runs the script with mocked TTS functions to verify it works.

### Option 2: Load into TTS Manually

**Step-by-step:**

1. **Open Tabletop Simulator**

2. **Open the Global Script Editor**
   - In TTS, go to: **Modding** → **Scripting Editor**
   - Or press **`** (backtick/tilde key)

3. **Copy Script to TTS**
   - In VSCode, open `gyrinx2tts.lua`
   - Select All (`Ctrl+A`) and Copy (`Ctrl+C`)
   - Paste into TTS Global script editor
   
4. **Save & Play**
   - Click the **"Save & Play"** button in TTS editor
   - This reloads the script

5. **Test It**
   - Open TTS Console (press `~` or click console icon)
   - Type: `setGangURL("https://gyrinx.app/list/9a226e9c-1127-47a4-b7fb-e73748479d1e")`
   - Press Enter
   - Type: `displayGangRoster()`
   - Press Enter
   - Watch the chat for your gang roster!

### Option 3: Using TTS Extension (If Commands Work)

If your TTS extension commands are working:
1. Open `gyrinx2tts.lua` in VSCode
2. Press **Ctrl+Shift+P** (Command Palette)
3. Look for commands starting with "Tabletop Simulator" or "TTS"
4. Try: "Tabletop Simulator Lua: Save and Play"

**Common TTS Extension Commands:**
- `Tabletop Simulator Lua: Save and Play`
- `Tabletop Simulator Lua: Get Lua Scripts`
- `Tabletop Simulator Lua: Open TTS Console`

## Quick Test

Test locally right now:
```bash
cd ~/projects/gyrinx2tts/necromunda-gyrinx-bridge
lua tests/test_tts_script.lua
```

## What You Should See in TTS

When you run `displayGangRoster()`, you'll see colored text in chat:
- **Cyan** - Fighter names
- **Purple** - Fighter types (Road Captain, Ganger, etc.)
- **Yellow** - Costs
- **Green** - Characteristics (M, WS, BS, etc.)
- **Pink** - Weapon names
- **Orange** - Section headers (Weapons, Skills, Equipment, Rules)

## Troubleshooting

**"Command not found" in VSCode**
- Just copy/paste manually into TTS (Option 2 above)
- Extension commands vary by version

**"WebRequest failed" in TTS**
- Make sure you're connected to internet
- Check the gang URL is correct
- URL format: `https://gyrinx.app/list/GANG_ID`

**"No fighters found"**
- Gang might be empty or all fighters dead/retired
- Check the gang on Gyrinx website first

**Want to test without TTS?**
- Use `lua tests/test_tts_script.lua` anytime
- Edit the gang URL in that file to test different gangs
