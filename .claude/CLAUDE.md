# Fizzlebee's Treasure Tracker - Project Documentation

**Version:** 1.1.1
**API Version:** 1
**WoW Interface:** 11.0.5 (The War Within)
**Author:** Fizzlebee (Vivian Voss) - Boulder Dash Heroes
**Licence:** BSD 3-Clause
**Release Date:** 22nd October 2025

---

## ⚠️ IMPORTANT: Patch 11.0.5 Fix (22nd October 2025)

**CRITICAL ISSUE RESOLVED:** Following Patch 11.0.5, all timestamps utilising `GetTime()` were reset, resulting in all legacy mobs being displayed as "active".

**SOLUTION:** Migration to `time()` (Unix Timestamps) instead of `GetTime()`:

### Why `time()` Instead of `GetTime()`?

| Function | Description | Persistence | Problem |
|----------|-------------|-----------|---------|
| `GetTime()` | Seconds since WoW start | ❌ Reset upon each start | Timestamps become invalid after patch/restart |
| `time()` | Unix Timestamp (seconds since 1970) | ✅ Never reset | Stable across all patches |

**Example:**
```lua
-- INCORRECT (legacy):
mobs[mobName].lastKillTime = GetTime()  -- → 12345.67 (resets upon restart!)

-- CORRECT (current):
mobs[mobName].lastKillTime = time()     -- → 1729605000 (remains valid permanently!)
```

### Migration Upon Addon Load

```lua
function FTT:MigrateTimestamps()
    -- Detects legacy GetTime() values (< 1 billion = before 2001)
    -- Sets them to 0 → marks as "very old"
    -- Displays message: "Migrated X old timestamps to new system"
end
```

**Affected Files:**
- [Core.lua:558-596](Libs/Core.lua#L558-L596) - Migration & GetCurrentTime()
- [Core.lua:285](Libs/Core.lua#L285) - RecordKill() utilises time()
- [Core.lua:300](Libs/Core.lua#L300) - Auto-Collapse utilises time()
- [Tracker.lua:272](Libs/UI/Tracker.lua#L272) - Active/Inactive Check utilises time()
- [Tracker.lua:515](Libs/UI/Tracker.lua#L515) - Transparency Check utilises time()

### 🔧 Further Important Fixes in v1.0.1

**Debug Output System:**
- ✅ All `print()` replaced with `FTT:DebugPrint()` or `FTT:InfoPrint()`
- ✅ Debug messages only visible when "Debug Mode" checkbox enabled
- ✅ Info messages (Load, Migration, User Actions) always visible
- ✅ Error messages always visible (critical for debugging)

**Print Helpers:**
```lua
FTT:DebugPrint(...)  -- Only with showDebug=true
FTT:InfoPrint(...)   -- Always visible
```

See: [GOLDEN RULE #1](#-golden-rule-1-always-conceal-debug-output-behind-settings)

---

## 📋 Versioning System (Semantic Versioning)

FTT utilises **Semantic Versioning (SemVer)** for clear, standardised version numbering:

```
1.0.0
│ │ │
│ │ └─── PATCH - Bug fixes, minor changes
│ └───── MINOR - New features (backwards compatible)
└─────── MAJOR - Breaking changes
```

### Version Breakdown:

| Component | Meaning | When to Increment | Example |
|-----------|---------|-------------------|---------|
| **MAJOR** | Breaking changes | API changes, incompatible updates | 1.0.0 → 2.0.0 |
| **MINOR** | New features | New functionality (backwards compatible) | 1.0.0 → 1.1.0 |
| **PATCH** | Bug fixes | Bug fixes, small improvements | 1.0.0 → 1.0.1 |

### Version Examples:

```
1.0.0   - Initial stable release
1.0.1   - Hotfix for critical bug
1.1.0   - New feature added (e.g., DPS tracking)
1.1.1   - Bug fix in DPS feature
2.0.0   - Major redesign or API breaking change
```

### Why SemVer?

**Advantages:**
- ✅ Industry-standard format
- ✅ Clear communication of change severity
- ✅ Compatible with all addon platforms (CurseForge, Wago, WoWInterface)
- ✅ Automatic tooling support (GitHub Releases, CI/CD)
- ✅ Predictable version ordering

**Previous System (Deprecated):**
```
1.0.251022.0842  ❌ Non-standard, confusing for tooling
```

**Current System:**
```
1.0.0  ✅ Clean, standard-compliant
```

---

## 📋 Quick Reference - GOLDEN RULES

When developing/extending FTT, **ALWAYS** observe the following rules:

| # | Rule | Description | Example |
|---|------|-------------|---------|
| 1️⃣ | **Debug Behind Setting** | Never use `print()` directly, always `FTT:DebugPrint()` | `FTT:DebugPrint("Debug: ...")` |
| 2️⃣ | **time() Instead of GetTime()** | For persistent timestamps ALWAYS use `time()` | `lastKillTime = time()` |
| 3️⃣ | **InfoPrint for Users** | User messages with `FTT:InfoPrint()` | `FTT:InfoPrint("Data reset")` |
| 4️⃣ | **Always Display Errors** | Never conceal errors | `FTT:InfoPrint("Error: ...")` |
| 5️⃣ | **BBC English MANDATORY** | Documentation & Comments ONLY in BBC English! | "colour" not "color" |

**Important:**
- ❌ `print("DEBUG: ...")` → User sees spam
- ✅ `FTT:DebugPrint("DEBUG: ...")` → Only with checkbox
- ❌ `GetTime()` for lastKillTime → Reset after patch!
- ✅ `time()` for lastKillTime → Stable across patches
- ❌ American English: "color", "behavior" → INCORRECT!
- ✅ BBC English: "colour", "behaviour" → CORRECT!

See details: [Golden Rules](#important-notes-for-developers)

---

## 📦 Release Process (GitHub Actions)

### Philosophy: Automated Releases via GitHub

The `.claude/` directory serves as the **development workspace** for this project. It contains:

- **CLAUDE.md** - Comprehensive project documentation (BBC English)
- **CLAUDE_DE.md** - German version of documentation (backup)
- **release.sh** - Interactive release helper script
- **release.ps1** - Legacy PowerShell release script (deprecated)
- **Any temporary development files** - Scripts, notes, experiments

**Design Principle:** *Keep the project root clean for end-users.*

When players download FizzlebeesTreasureTracker, they should receive **only the AddOn files** necessary for WoW to function. Development materials, internal documentation, and release tooling are irrelevant to end-users and would merely clutter their AddOns directory.

By housing all development artefacts within `.claude/`, we achieve:
- ✅ Clean project structure for distribution
- ✅ Single exclusion rule for releases (`.claude/*`, `.git/`, `.github/`)
- ✅ Logical grouping of development resources
- ✅ No confusion for end-users about which files matter

### Release Workflow Overview

**Every git push with a version tag triggers an automated GitHub Release:**

1. Developer runs interactive helper script: `.claude/release.sh`
2. Script asks: "patch / minor / major?"
3. Script updates TOC file with new version
4. Script creates git commit and tag (e.g., `v1.0.1`)
5. Script pushes to GitHub
6. **GitHub Actions automatically:**
   - Creates filtered ZIP (excludes `.claude/`, `.git/`, `.github/`, `.gitignore`, `release/`)
   - Creates GitHub Release with changelog
   - Attaches ZIP as downloadable asset

**No manual ZIP creation needed. No manual GitHub Release creation. Fully automated.**

---

### Release Helper Script

**Location:** `.claude/release.sh`

**Purpose:** Interactive script that guides you through the release process.

#### Usage

```bash
# Navigate to project directory
cd "c:/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/FizzlebeesTreasureTracker"

# Run release helper
./.claude/release.sh
```

#### Interactive Prompts

```
================================================================================
 Fizzlebee's Treasure Tracker - Interactive Release Helper
================================================================================

Current version: 1.0.0

What type of release would you like to create?

  patch  - Bug fixes, small changes        (1.0.0 → 1.0.1)
  minor  - New features, backwards compatible (1.0.0 → 1.1.0)
  major  - Breaking changes               (1.0.0 → 2.0.0)

Release type [patch/minor/major]: patch

Version bump: 1.0.0 → 1.0.1

Create release v1.0.1? [y/N]: y

[INFO] Updating TOC file...
[OK]   TOC file updated to version 1.0.1
[INFO] Creating git commit...
[INFO] Creating git tag v1.0.1...
[OK]   Git commit and tag created
[INFO] Pushing to GitHub...
[OK]   Pushed to GitHub
[OK]   GitHub Actions is now building the release

================================================================================
 Release v1.0.1 created successfully!
================================================================================

[OK]   GitHub Actions is now building the release
[INFO] Monitor progress: https://github.com/Fizzlebees-Rocket-Shop/FizzlebeesTreasureTracker/actions
[INFO] Release will be available at: https://github.com/Fizzlebees-Rocket-Shop/FizzlebeesTreasureTracker/releases/tag/v1.0.1
```

#### What the Script Does

1. **Reads Current Version** - Extracts from `FizzlebeesTreasureTracker.toc`
2. **Prompts for Release Type** - patch / minor / major
3. **Calculates Next Version** - Following SemVer rules
4. **Updates TOC File** - Modifies `## Version:` and `## X-Date:`
5. **Creates Git Commit** - Message: `chore: bump version to X.Y.Z`
6. **Creates Git Tag** - Format: `vX.Y.Z` (e.g., `v1.0.1`)
7. **Pushes to GitHub** - Triggers GitHub Actions workflow

---

### GitHub Actions Workflow

**Location:** `.github/workflows/release.yml`

**Trigger:** Git tag push matching `v*.*.*` (e.g., `v1.0.0`, `v1.2.3`)

#### Workflow Steps

1. **Checkout Repository** - Fetches all code
2. **Extract Version** - Removes `v` prefix from tag (`v1.0.1` → `1.0.1`)
3. **Create Release ZIP** - Excludes:
   - `.claude/` (development files)
   - `.git/` (version control)
   - `.github/` (CI/CD workflows)
   - `.gitignore` (git configuration)
   - `*.zip` (old releases)
   - `release/` (temporary build directory)
4. **Extract Changelog** - From `PATCHNOTES.txt` (first 50 lines)
5. **Create GitHub Release** - Automatic release creation
6. **Upload ZIP Asset** - Attaches `FizzlebeesTreasureTracker-1.0.1.zip`

#### Workflow Output

```yaml
Name: Fizzlebee's Treasure Tracker v1.0.1
Tag: v1.0.1
Assets:
  - FizzlebeesTreasureTracker-1.0.1.zip
Body: [Changelog from PATCHNOTES.txt]
```

---

### Release Checklist

**Before Creating Release:**

1. ✅ **Test all changes in-game** - Ensure functionality works
2. ✅ **Update PATCHNOTES.txt** - Document changes clearly (plain text format)
3. ✅ **Commit all changes** - `git add . && git commit -m "feat: description"`
4. ✅ **Push to GitHub** - `git push` (without tag yet)
5. ✅ **Review Golden Rules compliance** - BBC English, debug prints, etc.

**Create Release:**

```bash
# Run interactive release helper
./.claude/release.sh

# Follow prompts:
# 1. Choose release type (patch/minor/major)
# 2. Confirm version bump
# 3. Script handles the rest automatically
```

**After Release:**

1. ✅ **Monitor GitHub Actions** - Check build succeeds
   - URL: https://github.com/Fizzlebees-Rocket-Shop/FizzlebeesTreasureTracker/actions
2. ✅ **Verify GitHub Release** - Check ZIP attachment
   - URL: https://github.com/Fizzlebees-Rocket-Shop/FizzlebeesTreasureTracker/releases
3. ✅ **Test ZIP locally** - Download and test in WoW
4. ✅ **Distribute to platforms** - CurseForge, Wago, WoWInterface (optional)

---

### Version Bump Examples

#### Patch Release (Bug Fix)

```bash
# Current: 1.0.0
# Scenario: Fixed bug in DPS calculation

./.claude/release.sh
> patch
> y

# Result: 1.0.1
# Git tag: v1.0.1
# GitHub Release: FizzlebeesTreasureTracker-1.0.1.zip
```

#### Minor Release (New Feature)

```bash
# Current: 1.0.1
# Scenario: Added new tracking feature

./.claude/release.sh
> minor
> y

# Result: 1.1.0
# Git tag: v1.1.0
# GitHub Release: FizzlebeesTreasureTracker-1.1.0.zip
```

#### Major Release (Breaking Change)

```bash
# Current: 1.1.0
# Scenario: Complete UI redesign

./.claude/release.sh
> major
> y

# Result: 2.0.0
# Git tag: v2.0.0
# GitHub Release: FizzlebeesTreasureTracker-2.0.0.zip
```

---

### Troubleshooting

**Problem:** "Not a git repository"

**Solution:** Ensure you're in the project root directory:
```bash
cd "c:/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/FizzlebeesTreasureTracker"
pwd  # Should show project path
```

**Problem:** "Permission denied" when running release.sh

**Solution:** Make script executable:
```bash
chmod +x .claude/release.sh
```

**Problem:** GitHub Actions workflow fails

**Solution:** Check workflow logs:
1. Visit: https://github.com/Fizzlebees-Rocket-Shop/FizzlebeesTreasureTracker/actions
2. Click failed workflow
3. Review error messages
4. Common issues:
   - Invalid TOC file syntax
   - Missing PATCHNOTES.txt
   - Permissions issue (check repository settings)

**Problem:** ZIP still contains `.claude/` folder

**Solution:** Check workflow file (`.github/workflows/release.yml`):
```yaml
# Should have exclusion in rsync:
--exclude='.claude/' \
--exclude='.git/' \
--exclude='.github/' \
--exclude='.gitignore' \
--exclude='release/'
```

**Problem:** Version number not updated in TOC

**Solution:** Check `release.sh` script updated TOC correctly:
```bash
grep "## Version:" FizzlebeesTreasureTracker.toc
# Should show: ## Version: X.Y.Z
```

**Problem:** Empty `release/` folder appears in ZIP

**Solution:** Ensure `--exclude='release/'` is present in the rsync command within `.github/workflows/release.yml`. This prevents the temporary build directory from being copied into itself.

---

### Manual Release (Emergency Fallback)

If GitHub Actions is unavailable, use legacy PowerShell script:

```powershell
# DEPRECATED - Only use if GitHub Actions fails
.\.claude\release.ps1 -Version "1.0.1"
```

**Note:** This creates ZIP locally but does NOT create GitHub Release. You'll need to manually upload to GitHub.

---

### PATCHNOTES.txt Format

**Location:** `PATCHNOTES.txt` (project root)

**Format:** Plain text (not Markdown) - simple, focused, easy to read

**Philosophy:**
- ✅ Plain text for universal compatibility
- ✅ Minimal formatting (ASCII boxes, line separators)
- ✅ Focused content (no excessive detail)
- ✅ Quick to write and update

**Template:**

```
================================================================================
Fizzlebee's Treasure Tracker - Patch Notes
================================================================================

Version X.Y.Z (YYYY-MM-DD)
--------------------------------------------------------------------------------

Brief description of the release.

NEW FEATURES:
- Feature 1
- Feature 2

BUG FIXES:
- Fix 1
- Fix 2

TECHNICAL:
- Technical detail 1
- Technical detail 2

PREVIOUS RELEASES:
--------------------------------------------------------------------------------

Version X.Y.Z (YYYY-MM-DD) - Brief title
- Change 1
- Change 2

================================================================================
```

**Updating PATCHNOTES.txt:**

1. Add new version at the **top** (newest first)
2. Move previous version to "PREVIOUS RELEASES" section
3. Keep formatting consistent (80-character lines, ASCII boxes)
4. Use simple bullet points (no fancy Markdown)
5. Be concise and factual

**Example Update:**

```bash
# Before release, edit PATCHNOTES.txt:
nano PATCHNOTES.txt

# Add new version at top:
Version 1.0.1 (2025-10-23)
--------------------------------------------------------------------------------

Fixed critical bug in DPS calculation.

BUG FIXES:
- Fixed DPS showing incorrect values after combat reset
- Corrected damage tracking for SPELL_PERIODIC_DAMAGE events

# Save and commit:
git add PATCHNOTES.txt
git commit -m "docs: update patchnotes for v1.0.1"
```

**GitHub Actions Integration:**

The release workflow automatically extracts the first 50 lines of PATCHNOTES.txt and includes them in the GitHub Release body. This provides users with immediate changelog visibility without opening separate files.

---

## Additional Documentation

This main documentation covers the essentials: Golden Rules, Versioning, and Release Process.

**For detailed technical information, please refer to the following scope-specific documents (mandatory reading for developers):**

- **[CLAUDE_ARCHITECTURE.md](CLAUDE_ARCHITECTURE.md)** - File structure, module descriptions, design patterns, data structures
- **[CLAUDE_API.md](CLAUDE_API.md)** - Complete public API reference for addon developers
- **[CLAUDE_DEVELOPMENT.md](CLAUDE_DEVELOPMENT.md)** - Development workflow, testing, debugging, known issues
- **[CLAUDE_DE.md](CLAUDE_DE.md)** - Complete German documentation (full technical backup)

**This modular structure ensures:**
- ✅ Smaller, focused files (easier to navigate)
- ✅ No loss of information (everything preserved in scope files)
- ✅ Better maintainability (update only relevant sections)
- ✅ Mandatory reading paths clear (architecture → API → development)

**This documentation follows BBC English standards as specified in Golden Rule #5.**

---

## Important Notes for Developers

### 🇬🇧 GOLDEN RULE #0: BBC English MANDATORY (Most Important Rule!)

**ALL documentation and code comments MUST be written in BBC English!**

**Not merely vocabulary, but also tone and style:**

#### Vocabulary Differences:

| ❌ American English | ✅ BBC English | Usage |
|---------------------|----------------|-------|
| color | colour | Code comments, docs |
| behavior | behaviour | Code comments, docs |
| center | centre | Code comments, docs |
| optimize | optimise | Code comments, docs |
| analyze | analyse | Code comments, docs |
| defense | defence | Code comments, docs |
| license | licence (noun) | Documentation |
| gray | grey | Code comments, docs |

#### Tone and Style:

**❌ American Style (informal, direct):**
```
// This function rocks! It totally fixes the bug.
// We're gonna make this work no matter what.
```

**✅ BBC Style (formal, precise):**
```
-- This function addresses the issue effectively.
-- This implementation ensures correct behaviour.
```

#### Sentence Structure:

**❌ American:**
```
// Gets the item from the database
// Fixes bug where mobs don't show up
```

**✅ BBC English:**
```
-- Retrieves the item from the database
-- Corrects issue whereby mobs fail to appear
```

#### Important Phrases:

| ❌ Avoid | ✅ Use Instead |
|---------|----------------|
| "We'll fix this" | "This shall be corrected" |
| "Let's do X" | "One ought to perform X" |
| "This is gonna work" | "This shall function correctly" |
| "It's broken" | "This is non-functional" |
| "Get the data" | "Retrieve the data" |
| "Make sure" | "Ensure" |
| "Check if" | "Verify whether" |

#### Documentation Style:

**PATCHNOTES.txt, README.md, CLAUDE.md:**
- Formal and precise
- Passive constructions where appropriate
- "One should" instead of "You should"
- "This has been corrected" instead of "We fixed this"

**Code Comments:**
```lua
-- ❌ American Style:
-- This function gets all the mobs and sorts them by kill time.
-- It's super fast because we use a cache.

-- ✅ BBC English Style:
-- Retrieves all registered mobs and arranges them by kill timestamp.
-- Performance is optimised through caching mechanisms.
```

#### Why BBC English?

1. **Professionalism**: More formal, precise tone
2. **Internationality**: Globally recognised standard
3. **Consistency**: Uniform style throughout the project
4. **Clarity**: Less colloquial, more precise

#### Mandatory Checklist Before Each Commit:

- [ ] All new comments in BBC English?
- [ ] All documentation in BBC English?
- [ ] No American spellings (color, behavior)?
- [ ] Formal tone (no "gonna", "wanna", etc.)?

---

### 🔧 GOLDEN RULE #1: Always Conceal Debug Output Behind Settings

**NEVER use `print()` directly for debug messages!**

```lua
-- ❌ INCORRECT - Debug spam visible to user:
print("DEBUG: UpdateDisplay called")

-- ✅ CORRECT - Only visible when Debug checkbox enabled:
FTT:DebugPrint("DEBUG: UpdateDisplay called")
```

**Print Helpers in Core.lua:**

```lua
-- For debug messages (only visible with showDebug=true):
function FTT:DebugPrint(...)
    if self.settings and self.settings.showDebug then
        print(...)
    end
end

-- For important user messages (always visible):
function FTT:InfoPrint(...)
    print(...)
end
```

**Usage:**

| Type | Function | When to Use |
|------|----------|-------------|
| **Debug** | `FTT:DebugPrint(...)` | Debug info, tracing, development |
| **Info** | `FTT:InfoPrint(...)` | Load messages, migrations, confirmations |
| **Error** | `FTT:InfoPrint(...)` | Errors (always display!) |

**Examples:**

```lua
-- ✅ Debug (only with checkbox):
FTT:DebugPrint("|cffFFD700FTT Debug:|r LOOT_OPENED fired")
FTT:DebugPrint("|cffFFD700FTT Debug:|r UpdateDisplay called")

-- ✅ Info (always display):
FTT:InfoPrint("|cffFFD700FTT:|r Migrated 42 old timestamps")
FTT:InfoPrint("|cffFFD700FTT:|r Item highlighted: [Item Name]")
FTT:InfoPrint("|cffFFD700FTT:|r All data reset")

-- ✅ Error (always display):
FTT:InfoPrint("|cffFF0000FTT Error:|r UpdateDisplay failed: " .. err)
```

**Settings Checkbox:**
- Settings → "Debug Mode" checkbox
- Slash command: `/ftt debug` (displays debug info)

---

### ⚠️ GOLDEN RULE #2: NEVER Use `GetTime()` for Persistent Timestamps!

**Problem:**
```lua
-- INCORRECT - GetTime() resets upon each WoW start!
local timestamp = GetTime()  -- → 12345.67
-- After /reload or patch: 0.00 → ALL OLD DATA INVALID!
```

**Solution:**
```lua
-- CORRECT - time() is Unix timestamp and never resets
local timestamp = time()  -- → 1729605000 (22nd Oct 2024, 14:30 UTC)
-- After /reload or patch: 1729605120 → STILL VALID!
```

### Usage in FTT:

**For persistent timestamps (SavedVariables):**
```lua
-- Saving:
mobs[mobName].lastKillTime = time()

-- Comparing:
local currentTime = time()
local timeSinceKill = currentTime - mobs[mobName].lastKillTime
if timeSinceKill > 300 then
    -- Older than 5 minutes
end
```

**For session times (not persisted):**
```lua
-- GetTime() is acceptable for session duration, as only relative:
FTT.sessionStartTime = GetTime()
local sessionDuration = GetTime() - FTT.sessionStartTime
```

### Migrating Legacy AddOns:

If you have other addons utilising `GetTime()` for persistent data:

```lua
function MigrateOldTimestamps()
    local UNIX_TIME_THRESHOLD = 1000000000  -- ~Sep 2001

    for key, data in pairs(MySavedVariables) do
        if data.timestamp and data.timestamp < UNIX_TIME_THRESHOLD then
            -- Legacy GetTime()-based data
            data.timestamp = 0  -- Mark as invalid
            -- Or: data.timestamp = time() - 86400  -- Mark as "yesterday"
        end
    end
end
```

---

## Contact

**Bug Reports:** GitHub Issues
**In-Game:** Fizzlebee (Boulder Dash Heroes, EU Server)

---

*Generated for Fizzlebee's Treasure Tracker v1.0.0*
*Last Updated: 2025-10-22*
*Complete technical documentation available in CLAUDE_DE.md (German)*
