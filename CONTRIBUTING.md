# Contributing to Necromunda Gyrinx Bridge

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Getting Started

### Prerequisites
- Tabletop Simulator installed
- Basic understanding of Lua programming
- Familiarity with TTS scripting environment
- Access to Gyrinx.app for testing

### Understanding the Codebase
- Read `.github/copilot-instructions.md` for architecture details
- This is a **single-file TTS script** - not a traditional Lua project
- No `require()` statements or external modules
- All parsing uses plain text search (no regex patterns)

## How to Contribute

### Reporting Bugs
1. Check if the issue already exists in GitHub Issues
2. Include:
   - TTS version number
   - Full error message from TTS console (Tab key)
   - Example Gyrinx.app gang URL (if public)
   - Steps to reproduce
   - Expected vs actual behavior

### Suggesting Features
1. Open a GitHub Issue with the "enhancement" label
2. Describe the feature and why it would be useful
3. Include mockups or examples if applicable
4. Consider TTS environment limitations

### Pull Requests

#### Before You Start
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make sure you understand TTS-specific constraints

#### Development Workflow
1. Edit `gyrinx2tts.lua` in your preferred editor
2. Copy the entire file contents to TTS:
   - Right-click your test object → Scripting
   - Paste the code
   - Click Save & Play
3. Test thoroughly in TTS:
   - Check console (Tab key) for errors
   - Test with multiple fighters
   - Test all button interactions
   - Verify data displays correctly
4. Test with multiple gangs if possible

#### Code Style
- Use 4-space indentation (not tabs)
- Add comments for complex logic
- Use descriptive variable names
- Keep functions focused and concise
- Match existing code style

#### Critical Guidelines
- **Never use Lua patterns** - Use `string.find(pattern, pos, true)` with true flag
- **No require() statements** - TTS doesn't support them
- **No file I/O** - TTS sandbox restriction
- **Character-by-character parsing** - For complex HTML structures
- **Test in TTS** - Not standalone Lua
- **Button functions must be global** - Use `_G["funcName"]` pattern

#### Commit Messages
Follow conventional commits format:
```
type(scope): brief description

Longer explanation if needed

- Bullet points for details
- Breaking changes noted
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
```
feat(weapons): add support for exotic weapon traits
fix(parsing): handle empty skill cells correctly
docs(readme): add troubleshooting section
```

#### Pull Request Process
1. Update CHANGELOG.md with your changes
2. Update README.md if adding features
3. Ensure all changes are tested in TTS
4. Submit PR with clear description:
   - What changed
   - Why it changed
   - How to test it
   - Screenshots/videos if applicable
5. Link related issues
6. Wait for review

## Development Tips

### Testing HTML Parsing
```bash
# Download gang page for inspection
curl -s "https://gyrinx.app/list/YOUR-GANG-UUID" -o test_gang.html

# Search for specific patterns
grep -A 10 "pattern" test_gang.html

# Extract specific sections
sed -n '1000,2000p' test_gang.html
```

### Debugging in TTS
- Use `print()` statements liberally
- Check TTS console with Tab key
- Use `printToAll()` for user-visible messages
- Test with gangs of different sizes
- Test with fighters missing various fields

### Common Pitfalls
1. **Pattern matching** - Will fail in TTS, use plain find
2. **HTML structure changes** - Gyrinx.app may update their layout
3. **Missing data** - Not all fighters have all fields filled
4. **Button limits** - Only 14 fighters visible at once
5. **Global namespace** - Button functions need unique names

## HTML Structure Reference

### Fighter Cards
```html
<h3 class="h5 mb-0">Fighter Name</h3>
```

### Characteristics Table
```html
<table class="table table-sm table-borderless">
  <tbody>
    <tr>
      <td>5"</td><td>3+</td>... (12 cells)
    </tr>
  </tbody>
</table>
```

### Skills
```html
<th>Skills</th>
<td>
  <span data-bs-toggle="tooltip">Skill Name</span>
</td>
```

### Weapons
```html
<tbody>
  <tr>
    <td rowspan="2">Weapon Name (cost)</td>
    <td>9"</td><td>18"</td>... (8 stat cells)
  </tr>
  <tr>
    <td colspan="9">Traits text</td>
  </tr>
</tbody>
```

## Questions?

- Open a GitHub Discussion
- Check existing Issues
- Read `.github/copilot-instructions.md`

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn
- Credit others' contributions
- This is a hobby project - be patient

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
