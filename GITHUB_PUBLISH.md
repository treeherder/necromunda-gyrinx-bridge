# GitHub Publishing Checklist

Your repository is ready to be published! Follow these steps:

## 1. Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `necromunda-gyrinx-bridge`
3. Description: `Tabletop Simulator script for fetching Necromunda gang rosters from Gyrinx.app`
4. Public repository (recommended for open source)
5. **Do NOT** initialize with README, .gitignore, or license (we have them)
6. Click "Create repository"

## 2. Configure Git User (if needed)

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Then amend the commits if needed:
git commit --amend --reset-author --no-edit
```

## 3. Add Remote and Push

Replace `yourusername` with your GitHub username:

```bash
git remote add origin https://github.com/yourusername/necromunda-gyrinx-bridge.git
git push -u origin main
```

## 4. Configure Repository Settings

### About Section
- Description: `Tabletop Simulator script for fetching Necromunda gang rosters from Gyrinx.app`
- Website: (optional) Link to your personal site
- Topics: `tabletop-simulator`, `necromunda`, `lua`, `warhammer`, `gyrinx`, `tts-scripting`

### Repository Settings
- Enable Issues ✓
- Enable Discussions ✓ (optional, for Q&A)
- Enable Wiki ✗ (not needed for single-file project)

## 5. Create First Release

1. Go to Releases → "Create a new release"
2. Tag: `v1.0.0`
3. Title: `Initial Release - v1.0.0`
4. Description: Copy from CHANGELOG.md
5. Attach `gyrinx2tts.lua` as a binary
6. Check "Set as the latest release"
7. Publish release

## 6. Add Topics and Labels

### Topics to Add
- tabletop-simulator
- necromunda
- lua
- tts
- warhammer
- gaming
- gyrinx
- gang-manager

### Issue Labels to Create
- `bug` - Something isn't working
- `enhancement` - New feature request
- `documentation` - Documentation improvements
- `help wanted` - Extra attention needed
- `good first issue` - Good for newcomers
- `gyrinx-api` - Related to Gyrinx.app parsing
- `tts-compatibility` - TTS-specific issues

## 7. Optional: Add Badges to README

Add these at the top of README.md:

```markdown
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/release/yourusername/necromunda-gyrinx-bridge.svg)](https://github.com/yourusername/necromunda-gyrinx-bridge/releases)
[![GitHub issues](https://img.shields.io/github/issues/yourusername/necromunda-gyrinx-bridge.svg)](https://github.com/yourusername/necromunda-gyrinx-bridge/issues)
```

## 8. Share Your Project

### Where to Share
- Reddit: r/Necromunda, r/TabletopSimulator
- Discord: Necromunda community servers, TTS modding servers
- TTS Workshop: Consider creating a Steam Workshop item
- Gyrinx.app Discord/Community (if they have one)

### Announcement Template
```
🎮 New Tool: Necromunda Gyrinx Bridge for TTS

I've created a Tabletop Simulator script that lets you import your Necromunda 
gang rosters from Gyrinx.app directly into TTS!

Features:
✓ One-click character card generation
✓ Full weapon stats with traits
✓ Skills, equipment, and injuries
✓ Beautiful Dracula theme colors
✓ Interactive button UI

Check it out: [GitHub Link]

Free and open source (MIT License). Feedback welcome!
```

## Files in Repository

Current structure:
```
necromunda-gyrinx-bridge/
├── .github/
│   └── copilot-instructions.md  # Development guide
├── .git/                         # Git repository data
├── .gitignore                    # Git ignore patterns
├── CHANGELOG.md                  # Version history
├── CONTRIBUTING.md               # Contribution guidelines
├── gyrinx2tts.lua               # Main TTS script (33KB)
├── LICENSE                       # MIT License
└── README.md                     # Project documentation
```

## Next Steps After Publishing

1. **Monitor Issues** - Respond to bug reports and feature requests
2. **Accept PRs** - Review and merge community contributions
3. **Update CHANGELOG** - Document all changes
4. **Tag Releases** - Use semantic versioning (v1.0.0, v1.1.0, etc.)
5. **Test Updates** - Always test in TTS before releasing
6. **Engage Community** - Respond to discussions and questions

## Maintenance Tips

- Test script after Gyrinx.app updates (HTML structure may change)
- Check compatibility with TTS updates
- Keep README examples current
- Update CHANGELOG for all releases
- Consider creating a dev branch for experimental features

## Future Enhancements

Ideas for v1.1.0+:
- Support for multiple gangs
- Export to different formats
- Advanced filtering/sorting
- Custom color themes
- Weapon profile comparisons
- Experience tracking
- Campaign mode integration

---

**You're all set!** Your project is clean, documented, and ready for the community. Good luck! 🚀
