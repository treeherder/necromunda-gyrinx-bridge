# Using TTS Plugin Get/Save Scripts Feature

## Setup for Plugin Sync

The TTS extension can sync scripts between TTS and VSCode, but it requires specific setup:

### Prerequisites
1. Tabletop Simulator must be **running**
2. Must have a **saved game** in TTS (scripts are saved with games)
3. Extension needs to connect to TTS's scripting editor

### Initial Setup

**1. Load your script into TTS first:**
- Open TTS
- Objects → Scripting → Global
- Paste `gyrinx2tts.lua` content
- Click "Save & Play"
- **Save the game**: Games → Save & Apply

**2. Get scripts from TTS to VSCode:**
- In VSCode: `Ctrl+Shift+P`
- Type: "Tabletop Simulator Lua: Get Lua Scripts"
- Select your save game
- Extension creates files in workspace

**3. Now you can edit and sync:**
- Edit `Global.-1.ttslua` (or similar) in VSCode
- `Ctrl+Shift+P` → "Tabletop Simulator Lua: Save and Play"
- Script uploads to TTS and reloads

## File Naming Convention

TTS plugin expects files named like:
- `Global.-1.ttslua` - Global script
- `ObjectName.guid.ttslua` - Object scripts

## Why Your Script Doesn't Auto-Sync

Your `gyrinx2tts.lua`:
- ✅ Is a standalone development file
- ❌ Doesn't have TTS file naming
- ❌ Isn't linked to a TTS save game
- ✅ Works perfectly for development/testing

## Recommended: Keep Current Workflow

**For your use case (single script development):**

✅ **Keep doing:**
1. Develop in `gyrinx2tts.lua`
2. Test with `lua tests/test_tts_script.lua`
3. Manually copy to TTS when ready

❌ **Don't need plugin sync because:**
- Single file is simpler
- Local testing is faster
- Manual copy is quick enough
- No complex multi-object scripts

## When to Use Plugin Sync

Use "Get/Save Scripts" when:
- Multiple objects with different scripts
- Frequently switching between TTS and VSCode
- Working on an existing complex mod
- Collaborating with others on TTS mods

## Manual Copy Workflow (Current - Recommended)

```
┌─────────────┐
│   VSCode    │  1. Edit gyrinx2tts.lua
│             │  2. Test: lua tests/test_tts_script.lua
└──────┬──────┘
       │
       │ Ctrl+A, Ctrl+C
       ▼
┌─────────────┐
│     TTS     │  3. Paste into Global script
│             │  4. Save & Play
└─────────────┘
```

## Plugin Sync Workflow (Alternative)

```
┌─────────────┐
│     TTS     │  1. Initial: Save game with script
└──────┬──────┘
       │
       │ Get Lua Scripts
       ▼
┌─────────────┐
│   VSCode    │  2. Edit Global.-1.ttslua
│             │  3. Save and Play (uploads)
└──────┬──────┘
       │
       │ Auto-reload
       ▼
┌─────────────┐
│     TTS     │  4. Script updated in game
└─────────────┘
```

## Troubleshooting Plugin Sync

**"Get Lua Scripts" does nothing:**
- Is TTS running?
- Is scripting editor open? (Press `` ` ``)
- Is a game loaded/saved?
- Try: Save current game in TTS first

**"Save and Play" fails:**
- File must be named `Global.-1.ttslua` or similar
- TTS must be running
- May need to "Get Scripts" first to establish connection

## Check Plugin Commands

Press `Ctrl+Shift+P` and type "Tabletop" to see all available commands:
- Tabletop Simulator Lua: Get Lua Scripts
- Tabletop Simulator Lua: Save and Play  
- Tabletop Simulator Lua: Create TTS Lua File
- Tabletop Simulator Lua: Execute Lua Code

## Bottom Line

Your current workflow is fine! The plugin's sync features are optional convenience features for complex mods. For single-script development:

**Your workflow is actually better** because:
1. ✅ Local testing is instant
2. ✅ Full Lua error messages in terminal
3. ✅ No TTS connection required during development
4. ✅ Simple file structure
5. ✅ Easy version control

Only switch to plugin sync if you need rapid TTS iteration.
