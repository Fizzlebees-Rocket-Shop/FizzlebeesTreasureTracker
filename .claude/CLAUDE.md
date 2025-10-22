# Fizzlebee's Treasure Tracker - Projekt Dokumentation

**Version:** 1.0.0
**API Version:** 1
**WoW Interface:** 11.0.2.05 (The War Within)
**Author:** Fizzlebee (Vivian Voss) - Boulder Dash Heroes
**License:** BSD 3-Clause
**Release Date:** 22. Oktober 2025

---

## ⚠️ WICHTIG: Patch 11.0.5 Fix (22. Oktober 2025)

**KRITISCHES PROBLEM GELÖST:** Nach Patch 11.0.5 wurden alle Timestamps mit `GetTime()` zurückgesetzt, was dazu führte dass alle alten Mobs als "aktiv" angezeigt wurden.

**LÖSUNG:** Migration auf `time()` (Unix Timestamps) statt `GetTime()`:

### Warum `time()` statt `GetTime()`?

| Funktion | Beschreibung | Persistenz | Problem |
|----------|-------------|-----------|---------|
| `GetTime()` | Sekunden seit WoW-Start | ❌ Reset bei jedem Start | Timestamps werden ungültig nach Patch/Restart |
| `time()` | Unix Timestamp (Sekunden seit 1970) | ✅ Niemals Reset | Stabil über alle Patches hinweg |

**Beispiel:**
```lua
-- FALSCH (alt):
mobs[mobName].lastKillTime = GetTime()  -- → 12345.67 (wird bei Restart zurückgesetzt!)

-- RICHTIG (neu):
mobs[mobName].lastKillTime = time()     -- → 1729605000 (bleibt für immer gültig!)
```

### Migration beim Addon-Load

```lua
function FTT:MigrateTimestamps()
    -- Erkennt alte GetTime()-Werte (< 1 Milliarde = vor 2001)
    -- Setzt sie auf 0 → markiert als "sehr alt"
    -- Gibt Message aus: "Migrated X old timestamps to new system"
end
```

**Betroffene Dateien:**
- [Core.lua:558-596](Libs/Core.lua#L558-L596) - Migration & GetCurrentTime()
- [Core.lua:285](Libs/Core.lua#L285) - RecordKill() verwendet time()
- [Core.lua:300](Libs/Core.lua#L300) - Auto-Collapse verwendet time()
- [Tracker.lua:272](Libs/UI/Tracker.lua#L272) - Active/Inactive Check verwendet time()
- [Tracker.lua:515](Libs/UI/Tracker.lua#L515) - Transparency Check verwendet time()

### 🔧 Weitere wichtige Fixes in v1.0.1

**Debug-Ausgaben-System:**
- ✅ Alle `print()` durch `FTT:DebugPrint()` oder `FTT:InfoPrint()` ersetzt
- ✅ Debug-Messages nur sichtbar wenn "Debug Mode" Checkbox aktiv
- ✅ Info-Messages (Load, Migration, User-Actions) immer sichtbar
- ✅ Error-Messages immer sichtbar (kritisch für Debugging)

**Print-Helper:**
```lua
FTT:DebugPrint(...)  -- Nur mit showDebug=true
FTT:InfoPrint(...)   -- Immer sichtbar
```

Siehe: [GOLDENE REGEL #1](#-goldene-regel-1-debug-ausgaben-immer-hinter-settings-verstecken)

---

## 📋 Versioning System (Semantic Versioning)

FTT uses **Semantic Versioning (SemVer)** for clear, standardised version numbering:

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

**New System (Current):**
```
1.0.0  ✅ Clean, standard-compliant
```

---

## 📋 Quick Reference - GOLDENE REGELN

Beim Entwickeln/Erweitern von FTT **IMMER** folgende Regeln beachten:

| # | Regel | Beschreibung | Beispiel |
|---|-------|--------------|----------|
| 1️⃣ | **Debug hinter Setting** | Niemals `print()` direkt, immer `FTT:DebugPrint()` | `FTT:DebugPrint("Debug: ...")` |
| 2️⃣ | **time() statt GetTime()** | Für persistente Timestamps IMMER `time()` | `lastKillTime = time()` |
| 3️⃣ | **InfoPrint für User** | User-Messages mit `FTT:InfoPrint()` | `FTT:InfoPrint("Data reset")` |
| 4️⃣ | **Errors immer zeigen** | Fehler NIEMALS verstecken | `FTT:InfoPrint("Error: ...")` |
| 5️⃣ | **date für Datum** | IMMER `date` Command verwenden, nie raten! | `date +"%Y-%m-%d"` |
| 6️⃣ | **Patch Level generieren** | IMMER `date +"%y%m%d.%H%M"` für Patch Level | `251022.0842` |
| 7️⃣ | **BBC English MANDATORY** | Dokumentation & Comments NUR in BBC English! | "colour" nicht "color" |

**Wichtig:**
- ❌ `print("DEBUG: ...")` → User sieht Spam
- ✅ `FTT:DebugPrint("DEBUG: ...")` → Nur mit Checkbox
- ❌ `GetTime()` für lastKillTime → Reset nach Patch!
- ✅ `time()` für lastKillTime → Stabil über Patches
- ❌ Patch Level raten: `251022.0842` → FALSCH!
- ✅ Patch Level generieren: `date +"%y%m%d.%H%M"` → RICHTIG!
- ❌ American English: "color", "behavior" → FALSCH!
- ✅ BBC English: "colour", "behaviour" → RICHTIG!

Siehe Details: [Goldene Regeln](#wichtige-hinweise-für-entwickler)

---

## 📦 Release Process (GitHub Actions)

### Philosophy: Automated Releases via GitHub

The `.claude/` directory serves as the **development workspace** for this project. It contains:

- **CLAUDE.md** - Comprehensive project documentation
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
   - Creates filtered ZIP (excludes `.claude/`, `.git/`, `.github/`, `.gitignore`)
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
   - Missing PATCHNOTES.md
   - Permissions issue (check repository settings)

**Problem:** ZIP still contains `.claude/` folder

**Solution:** Check workflow file (`.github/workflows/release.yml`):
```yaml
# Should have exclusion in rsync:
--exclude='.claude/' \
--exclude='.git/' \
--exclude='.github/' \
--exclude='.gitignore'
```

**Problem:** Version number not updated in TOC

**Solution:** Check `release.sh` script updated TOC correctly:
```bash
grep "## Version:" FizzlebeesTreasureTracker.toc
# Should show: ## Version: X.Y.Z
```

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

## Projekt Übersicht

Fizzlebee's Treasure Tracker (FTT) ist ein World of Warcraft AddOn, das Mob-Kills und Loot-Drops trackt und statistische Analysen in Echtzeit anbietet. Es bietet eine dynamische, anpassbare UI mit automatischem Sizing, transparentem Modus, Font-Skalierung und einer öffentlichen API für andere AddOns.

### Hauptfunktionen

- **Mob Kill Tracking**: Zählt Kills pro Mob (Session & Total)
- **Loot Tracking**: Erfasst alle Loot-Items mit Drop-Raten (Ratio 1:X)
- **Gold Tracking**: Summiert gelootetes Gold (Session & Total)
- **Qualitätsstatistiken**: Zählt Items nach Seltenheit (Grün/Blau/Lila)
- **Performance-Metriken**: Kills pro Sekunde/Stunde
- **Item-Highlighting**: Markiert wichtige Items über alle Mobs hinweg
- **Zone-Filter**: Zeigt nur Mobs der aktuellen Zone
- **Auto-Collapse**: Alte Mobs (>5 Min) werden automatisch eingeklappt
- **Multi-Language**: Unterstützt 10 Sprachen (EN, DE, FR, ES, RU, CN, TW, KR, PT, IT)

---

## Dateistruktur

```
FizzlebeesTreasureTracker/
├── .claude/                        # Claude AI Dokumentation
│   └── CLAUDE.md                   # Diese Datei
├── Libs/                           # Core-Logik Module
│   ├── Core.lua                    # FTT-Haupttabelle, Datenmanagement, Settings
│   ├── API.lua                     # Öffentliche API für andere AddOns
│   ├── Events.lua                  # WoW-Event-Handler (Combat, Loot, Gold)
│   └── UI/                         # UI-Module
│       ├── Main.lua                # Hauptfenster, Gold/Duration-Display
│       ├── Settings.lua            # Settings-Dialog, Checkboxen, Sliders
│       └── Tracker.lua             # Mob-Liste, Accordion-Einträge, Entry-Pool
├── Locales/                        # Übersetzungen (10 Sprachen)
│   ├── enUS.lua                    # Englisch (Default mit Fallback)
│   ├── deDE.lua                    # Deutsch
│   ├── frFR.lua, esES.lua, ...    # Weitere Sprachen
│   └── ...
├── Textures/                       # Texturen & Assets
│   └── dot.tga                     # Kreis-Textur für Quality-Display
├── FizzlebeesTreasureTracker.toc   # AddOn Metadaten & Ladereihenfolge
├── FizzlebeesTreasureTracker.lua   # Slash-Commands & Initialisierung
├── API_DOCUMENTATION.md            # API-Dokumentation für Entwickler
└── LICENSE                         # BSD 3-Clause Lizenz
```

---

## Ladereihenfolge (TOC)

Die Dateien werden in dieser Reihenfolge geladen (definiert in `.toc`):

1. **Locales/*.lua** (Alle Übersetzungen)
2. **Libs/Core.lua** (FTT-Tabelle, Konstanten, Utilities, Datenmanagement)
3. **Libs/API.lua** (Öffentliche API)
4. **Libs/UI/Main.lua** (Hauptfenster, Gold/Duration-Display)
5. **Libs/UI/Settings.lua** (Settings-Dialog)
6. **Libs/UI/Tracker.lua** (Mob-Liste, Entry-Pool)
7. **Libs/Events.lua** (Event-Handler)
8. **FizzlebeesTreasureTracker.lua** (Slash-Commands)

---

## Module Beschreibung

### 1. Core.lua

**Pfad:** `Libs/Core.lua`

**Zweck:** Zentrale Logik, Datenmanagement, Settings, Utilities

**Abhängigkeiten:**
- `Locales/*.lua` (L-Tabelle)

**Exports:**
- `FTT` (global table)
- `FTT:DebugPrint()`
- `FTT:FormatMoney()` / `FTT:FormatDuration()`
- `FTT:RecordKill()` / `FTT:RecordLoot()`
- `FTT:SaveSettings()` / `FTT:SavePosition()` / `FTT:SaveFrameSize()`
- `FTT:RestorePosition()` / `FTT:RestoreFrameSize()`
- `FTT:S(value)` - Font-Skalierung
- `FTT:GetFont(size)` - Font-Objekt-Auswahl
- `FTT:ApplyFontScaling()` - Font-Skalierung auf UI anwenden
- `FTT:UpdateHeaderLayout()` - Header-Zeilen-Layout aktualisieren
- `FTT:RecalculateQualityFromDatabase()` - Qualitätsstatistiken neu berechnen

**Wichtige Konstanten:**
```lua
FTT.ENTRY_WIDTH = 320        -- Breite der Accordion-Einträge
FTT.SCROLLBAR_PADDING = 40   -- Scrollbar-Breite
FTT.FRAME_PADDING = 70       -- Gesamt-Padding (inkl. Scrollbar + Margins)
FTT.FRAME_WIDTH = 390        -- Hauptfenster-Breite
FTT.ITEM_LEFT_OFFSET = 8     -- Linker Offset für Item-Zeilen
FTT.ITEM_RIGHT_PADDING = 8   -- Rechter Padding für Item-Zeilen
FTT.ITEM_LINE_WIDTH = 312    -- Breite der Item-Zeilen
FTT.INFO_FRAME_WIDTH = 340   -- Breite für Gold/Duration-Displays
```

**Session-Tracking:**
```lua
FTT.sessionKills = {}        -- Kills in aktueller Session (mobName -> count)
FTT.sessionLoot = {}         -- Loot in aktueller Session (mobName -> {itemName -> count})
FTT.sessionGold = 0          -- Gold in aktueller Session (in Kupfer)
FTT.totalGold = 0            -- Gold gesamt (in Kupfer)
FTT.sessionQuality = {}      -- Quality-Zähler Session (green, blue, purple, orange)
FTT.totalQuality = {}        -- Quality-Zähler Total
FTT.sessionStartTime = 0     -- Session-Start (GetTime())
FTT.totalDuration = 0        -- Gesamtdauer (Sekunden)
FTT.expandedMobs = {}        -- Welche Mobs sind expandiert (mobName -> true/false)
FTT.hiddenMobs = {}          -- Welche Mobs sind versteckt (mobName -> true)
FTT.hiddenItems = {}         -- Welche Items sind versteckt (itemName -> true)
FTT.entryPool = {}           -- Pool wiederverwendbarer Entry-Frames
FTT.highlightedItemID = nil  -- Markiertes Item (itemID als String)
FTT.highlightMode = false    -- Highlight-Modus aktiv (wartet auf User-Auswahl)
```

**Font-Skalierung:**
```lua
FTT.SCALE_MULTIPLIERS = {[0] = 0.88, [1] = 1.0, [2] = 1.12}

function FTT:S(value)
    -- Skaliert Wert basierend auf fontScale-Setting
    local scale = self.settings.fontScale or 1
    return math.floor(value * self.SCALE_MULTIPLIERS[scale])
end

function FTT:GetFont(size)
    -- Wählt WoW-Font-Objekt basierend auf Scale & Größe
    -- size: "L" (Large), "N" (Normal), "S" (Small), "H" (Highlight)
    -- Returns: Font-Name (z.B. "GameFontNormal")
end
```

**Default Settings:**
```lua
FTT.settings = {
    transparentMode = false,      -- Transparent (kein Border)
    backgroundOpacity = 0,        -- Hintergrund-Deckkraft (0-2)
    fontScale = 1,                -- Schriftgröße (0=Klein, 1=Mittel, 2=Groß)
    autoSize = true,              -- Auto-Größe (Breite+Höhe)
    lockPosition = false,         -- Position gesperrt
    itemFilter = "",              -- Item-ID Filter
    filterByZone = true,          -- Nach Zone filtern
    showDebug = false,            -- Debug-Modus
    showInactiveMobs = true,      -- Zeige alte Mobs (>5 Min)
    highlightedItemID = nil,      -- Markiertes Item (itemID)
    minItemQuality = 0,           -- Min. Qualität (0=Alle, 2=Grün+, 3=Blau+, 4=Lila+)
    showGoldLine = true,          -- Gold-Zeile anzeigen
    showQualityLine = true,       -- Qualitäts-Zeile anzeigen
    showDurationLine = true,      -- Dauer-Zeile anzeigen
    showKillsLine = true          -- Kills/s + Kills/h Zeile anzeigen
}
```

**Heartbeat-System:**
```lua
FTT.lastUpdateTime = 0           -- Letzter erfolgreicher UpdateDisplay()-Aufruf
FTT.heartbeatEnabled = true      -- Heartbeat-Monitoring aktiviert

function FTT:CheckHeartbeat()
    -- Überprüft alle 30 Sekunden ob UpdateDisplay() noch funktioniert
    -- Führt Auto-Refresh durch wenn >60s keine Updates (Recovery-Mechanismus)
end
```

**Datenmanagement:**
```lua
function FTT:RecordKill(mobName)
    -- Erfasst Mob-Kill (Session + Total)
    -- Startet Session-Timer beim ersten Kill
    -- Speichert Zone-ID (C_Map.GetBestMapForUnit("player"))
    -- Auto-expandiert den Mob
    -- Auto-kollabiert alte Mobs (>5 Min)
end

function FTT:RecordLoot(mobName, itemLink, quantity)
    -- Erfasst Loot-Item (Session + Total)
    -- Tracked Qualitätsstatistiken (green, blue, purple, orange)
    -- Auto-expandiert Mob bei erstem Loot
end
```

**Initialisierung:**
```lua
function FTT:Initialize()
    -- Initialisiert FizzlebeesTreasureTrackerDB (SavedVariables)
    -- Lädt Settings aus DB
    -- Migriert alte Settings (showBorder -> transparentMode)
    -- Lädt totalGold, totalDuration, totalQuality
    -- Berechnet Quality-Stats neu falls nötig
    -- Auto-kollabiert alte Mobs (>5 Min)
end
```

---

### 2. API.lua

**Pfad:** `Libs/API.lua`

**Zweck:** Öffentliche API für andere AddOns (Font-Skalierung, Settings-Access)

**Exports:**
- `FizzlebeesTreasureTracker_API` (global table)
- `FTT_API.VERSION` = "1.0.0"
- `FTT_API.API_VERSION` = 1

**Hauptfunktionen:**
```lua
-- Font Scaling
FTT_API:GetFontScale()           -- Returns: 0, 1, oder 2
FTT_API:GetScaleMultiplier()     -- Returns: 0.88, 1.0, oder 1.12
FTT_API:ScaleValue(value)        -- Skaliert Wert
FTT_API:GetFont(size)            -- Returns: Font-Objekt ("Large", "Normal", "Small", "Highlight")
FTT_API:GetAllFonts()            -- Returns: {Large="...", Normal="...", ...}

-- Settings
FTT_API:GetSettings()            -- Returns: Copy der Settings
FTT_API:RegisterSettingsCallback(callback, event)  -- Callback bei Settings-Änderung
FTT_API:UnregisterSettingsCallback(callbackID)

-- Helpers
FTT_API:CreateScaledFrame(frameType, parent, template)  -- Frame mit FTT-Skalierung
FTT_API:CreateScaledFontString(parent, size)           -- FontString mit FTT-Font

-- Utilities
FTT_API:IsReady()                -- Addon bereit?
FTT_API:GetVersion()             -- Returns: "1.0.0"
FTT_API:GetAPIVersion()          -- Returns: 1
FTT_API:IsCompatible(version)    -- Kompatibilitätsprüfung
FTT_API:DebugInfo()              -- Gibt Debug-Info aus
```

**Verwendungsbeispiel:**
```lua
local FTT_API = _G.FizzlebeesTreasureTracker_API
if FTT_API and FTT_API:IsReady() then
    local font = FTT_API:GetFont("Normal")
    local scaledHeight = FTT_API:ScaleValue(25)
end
```

Siehe `API_DOCUMENTATION.md` für vollständige API-Dokumentation.

---

### 3. Events.lua

**Pfad:** `Libs/Events.lua`

**Zweck:** WoW-Event-Handler (Combat, Loot, Gold)

**Abhängigkeiten:**
- `Core.lua`: FTT:RecordKill(), FTT:RecordLoot(), FTT:DebugPrint()
- `UI/Main.lua`: FTT:UpdateDisplay(), FTT:UpdateGoldDisplay()

**Registrierte Events:**
- `ADDON_LOADED` - Addon-Initialisierung
- `COMBAT_LOG_EVENT_UNFILTERED` - Damage & Kill-Tracking
- `LOOT_OPENED` - Loot-Erfassung
- `LOOT_CLOSED` - Cleanup
- `CHAT_MSG_MONEY` - Gold-Tracking
- `PLAYER_LOGOUT` - Session-Daten speichern
- `ZONE_CHANGED_NEW_AREA` - Zone-Filter aktualisieren

**Wichtige Lokale Variablen:**
```lua
local currentTarget = nil         -- Aktuelles Target
local recentKills = {}            -- Letzte Kills mit Timestamps
local goldQueue = {}              -- Separate Queue für Gold-Tracking
local damagedMobs = {}            -- Alle gedamagten Mobs (für AoE)
local currentLootTarget = nil     -- Aktuell gelooteter Mob
local LOOT_WINDOW = 5             -- Sekunden-Fenster für Loot-Zuordnung
local DAMAGE_WINDOW = 10          -- Sekunden für Damage-Tracking
```

**COMBAT_LOG_EVENT_UNFILTERED:**
- Tracked Damage vom Player (SWING_DAMAGE, SPELL_DAMAGE, RANGE_DAMAGE, SPELL_PERIODIC_DAMAGE)
- Speichert alle gedamagten Mobs in `damagedMobs` (für AoE-Unterstützung)
- Bei UNIT_DIED: Prüft ob Mob in `damagedMobs`, ruft `FTT:RecordKill()`, fügt zu `recentKills` & `goldQueue` hinzu

**LOOT_OPENED:**
- Iteriert durch alle Loot-Slots (`GetNumLootItems()`)
- Versucht exakte Mob-Zuordnung via `C_Loot.GetLootSourceInfo(i)` (für Multi-Mob-Loot)
- Fallback: `GetNextLootTarget()` (verwendet `recentKills`-Queue)
- Erkennt neue Group-Kills (Mob nicht in `recentKills`)
- Ruft `FTT:RecordLoot()` für jedes Item

**CHAT_MSG_MONEY:**
- Parst Gold-Beträge aus Chat-Nachrichten (DE + EN)
- Regex: "(%d+)%s*Gold", "(%d+)%s*Silber/Silver", "(%d+)%s*Kupfer/Copper"
- Konvertiert zu Kupfer (1 Gold = 10000 Kupfer, 1 Silber = 100 Kupfer)
- Updated `FTT.sessionGold`, `FTT.totalGold`, `FizzlebeesTreasureTrackerDB.totalGold`

**PLAYER_LOGOUT:**
- Speichert `totalDuration` (sessionDuration + totalDuration)
- Speichert `totalQuality` (green, blue, purple, orange)

**ADDON_LOADED:**
```lua
FTT:Initialize()               -- Core.lua
FTT:InitializeSettings()       -- Settings.lua (UI + Apply)
FTT:UpdateHeaderLayout()       -- Core.lua
FTT:UpdateGoldDisplay()        -- UI/Main.lua
FTT:UpdateQualityDisplay()     -- UI/Main.lua
FTT:UpdateDurationDisplay()    -- UI/Main.lua

-- Startet Heartbeat-Timer (alle 30 Sekunden)
FTT.heartbeatTimer = C_Timer.NewTicker(30, function()
    FTT:CheckHeartbeat()
end)
```

---

### 4. UI/Main.lua

**Pfad:** `Libs/UI/Main.lua`

**Zweck:** Hauptfenster, Gold/Duration-Display, Buttons

**Abhängigkeiten:**
- `Core.lua`: FTT (global table), FTT.L, FTT.settings, Konstanten
- `Core.lua`: FTT:SavePosition(), FTT:SaveFrameSize()
- `Core.lua`: FTT:FormatMoney(), FTT:FormatDuration()

**Exports:**
- `FTT.frame` - Hauptfenster
- `FTT.scrollFrame` - Scroll-Container
- `FTT.scrollChild` - Scroll-Inhalt
- `FTT.emptyText` - "Kill mobs..." Text
- `FTT:UpdateGoldDisplay()` - Gold-Display aktualisieren
- `FTT:UpdateQualityDisplay()` - Qualitäts-Display aktualisieren
- `FTT:UpdateDurationDisplay()` - Dauer-Display aktualisieren
- `FTT:AutoSizeButton()` - Button-Breite basierend auf Text

**UI-Struktur:**
```
FizzlebeesTreasureTrackerFrame (Hauptfenster)
├── titleText (Titel)
├── settingsBtn (Zahnrad-Icon)
├── highlightBtn (Stift-Icon)
├── collapseBtn (+/- Icon)
├── goldFrame (Gold-Anzeige)
│   ├── sessionGoldText ("Session: XX")
│   └── totalGoldText ("Total: XX")
├── qualityFrame (Qualitäts-Anzeige)
│   ├── sessionQualityText ("Session: X⚫ X⚫ X⚫")
│   └── totalQualityText ("Total: X⚫ X⚫ X⚫")
├── durationFrame (Dauer-Anzeige)
│   ├── sessionDurationText ("Session: HH:MM:SS")
│   └── totalDurationText ("Total: HH:MM:SS")
├── kpsFrame (Kills-Anzeige)
│   ├── kpsText ("Kills/s: X.XX")
│   └── kphText ("Kills/h: XXX")
├── scrollFrame (Scroll-Container)
│   └── scrollChild (Mob-Liste)
│       └── emptyText ("Kill mobs to start tracking...")
└── resizeButton (Resize-Handle, unten rechts)
```

**Gold-Display:**
```lua
function FTT:UpdateGoldDisplay()
    sessionGoldText:SetText(L["SESSION"] .. ": " .. self:FormatMoney(self.sessionGold))
    totalGoldText:SetText(L["TOTAL"] .. ": " .. self:FormatMoney(self.totalGold))
end

function FTT:FormatMoney(copper)
    -- Konvertiert Kupfer zu "XX 🪙 XX 🪙 XX 🪙" Format
    -- Verwendet WoW-Icons: UI-GoldIcon, UI-SilverIcon, UI-CopperIcon
end
```

**Quality-Display:**
```lua
function FTT:UpdateQualityDisplay()
    -- Verwendet dot.tga Textur mit Vertex-Coloring
    -- Grün: RGB(30, 255, 0)
    -- Blau: RGB(0, 112, 221)
    -- Lila: RGB(163, 53, 238)
    -- Format: "Session: 5⚫ 3⚫ 1⚫" (Anzahl + farbiger Punkt)
end
```

**Duration-Display:**
```lua
function FTT:UpdateDurationDisplay()
    -- Session-Dauer: GetTime() - sessionStartTime
    -- Total-Dauer: totalDuration + sessionDuration
    -- Format: "HH:MM:SS"

    -- Berechnet auch Kills/s und Kills/h:
    local totalKills = sum(sessionKills)
    local kps = totalKills / sessionDuration
    local kph = kps * 3600
end

-- OnUpdate (1 Sekunde):
durationUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    if elapsed >= 1 then
        FTT:UpdateDurationDisplay()
    end
end)
```

**Buttons:**
- **settingsBtn**: Öffnet `FTT.settingsFrame`
- **highlightBtn**: Aktiviert Highlight-Modus (Stift-Icon), ändert zu "Down" wenn aktiv
- **collapseBtn**: Kollabiert/Expandiert Tracker (ruft `FTT:CollapseTracker()`/`FTT:ExpandTracker()`)

**Frame Dragging & Resizing:**
```lua
-- Dragging (nur wenn nicht lockPosition)
frame:SetScript("OnDragStart", function(self)
    if not FTT.settings.lockPosition then
        self:StartMoving()
    end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    FTT:SavePosition()
end)

-- Resizing (nur wenn nicht autoSize)
frame:SetScript("OnSizeChanged", function(_, width, height)
    if not FTT.settings.autoSize then
        FTT:SaveFrameSize(width, height)
        FTT:ResizeEntries()
    end
end)
```

---

### 5. UI/Settings.lua

**Pfad:** `Libs/UI/Settings.lua`

**Zweck:** Settings-Dialog, Checkboxen, Sliders, Confirmation-Dialog

**Abhängigkeiten:**
- `Core.lua`: FTT.L, FTT.settings, FTT:SaveSettings()
- `UI/Main.lua`: FTT.frame, FTT:AutoSizeButton()
- `UI/Tracker.lua`: FTT:UpdateDisplay()

**Exports:**
- `FTT.settingsFrame` - Settings-Dialog
- `FTT.confirmFrame` - Confirmation-Dialog
- `FTT:UpdateSettingsUI()` - Settings-UI aktualisieren
- `FTT:InitializeSettings()` - Settings initialisieren
- `FTT:ApplySettings()` - Settings anwenden
- `FTT:UpdateResizeButton()` - Resize-Button zeigen/verstecken

**Settings-UI:**
```
FizzlebeesTreasureTrackerSettings
├── settingsTitle ("Settings")
├── addonNameText ("Fizzlebee's Treasure Tracker v1.0")
├── apiText ("WoW API 11.0.2 (TWW)")
├── authorText ("Fizzlebee")
├── guildText ("<Boulder Dash Heroes>")
├── itemFilterLabel ("Item Filter (Item-ID):")
├── itemFilterBox (EditBox, numeric, max 10 chars)
├── clearFilterBtn ("Clear")
├── Checkboxes:
│   ├── filterByZoneCheckbox ("Filter by Zone")
│   ├── transparentModeCheckbox ("Transparent Mode")
│   ├── showGoldLineCheckbox ("Show Gold Line")
│   ├── showQualityLineCheckbox ("Show Quality Line")
│   ├── showDurationLineCheckbox ("Show Duration Line")
│   ├── showKillsLineCheckbox ("Show Kills Line")
│   ├── autoSizeCheckbox ("Auto Size")
│   ├── lockPositionCheckbox ("Lock Position")
│   └── showDebugCheckbox ("Debug Mode")
├── Sliders:
│   ├── opacitySlider (0-2: 0%, 15%, 30%)
│   ├── fontScaleSlider (0-2: Klein, Mittel, Groß)
│   └── qualitySlider (0-3: Alle, Grün+, Blau+, Lila+)
├── showAllBtn ("Show All Hidden")
├── hrTexture (Horizontale Linie)
├── resetBtn ("Reset Data")
└── settingsCloseBtn (X-Button)
```

**Checkbox-Handler:**
```lua
local function HandleCheckboxChange(settingKey, affectsLayout)
    FTT:SaveSettings()

    if settingKey == "showGoldLine" or settingKey == "showQualityLine" or
       settingKey == "showDurationLine" or settingKey == "showKillsLine" then
        FTT:UpdateHeaderLayout()  -- Header-Zeilen neu positionieren
        FTT:UpdateDisplay()
    elseif affectsLayout then
        FTT:ApplySettings()       -- Border, Resize-Button, UpdateDisplay
    else
        FTT:UpdateDisplay()       -- Nur Mob-Liste aktualisieren
    end
end
```

**Font-Scale-Slider:**
```lua
fontScaleSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)  -- Runden
    FTT.settings.fontScale = value
    FTT:SaveSettings()

    -- Sofortige Anwendung (OHNE Reload!)
    if FTT.ApplyFontScaling then
        FTT:ApplyFontScaling()
    end

    -- API-Callbacks feuern (für andere AddOns)
    if FTT.FireAPICallbacks then
        FTT:FireAPICallbacks("fontScale")
    end
end)
```

**Quality-Slider-Mapping:**
```lua
-- Slider-Positionen zu Quality-Werten:
local qualityMap = {
    [0] = 0,  -- Alle
    [1] = 2,  -- Grün+
    [2] = 3,  -- Blau+
    [3] = 4   -- Lila+
}
```

**Apply Settings:**
```lua
function FTT:ApplySettings()
    -- Transparent Mode
    if self.settings.transparentMode then
        -- Kein Border, Hintergrund mit Opacity-Slider (0%, 15%, 30%)
        frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = nil})
        local alphaValues = {[0] = 0.0, [1] = 0.15, [2] = 0.30}
        frame:SetBackdropColor(0, 0, 0, alphaValues[self.settings.backgroundOpacity])
        self.scrollFrame.ScrollBar:Hide()
        self.opacitySlider:Enable()
    else
        -- Normaler Modus: Border + fester Hintergrund (85%)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            ...
        })
        frame:SetBackdropColor(0, 0, 0, 0.85)
        self.scrollFrame.ScrollBar:Show()
        self.opacitySlider:Disable()
    end

    self:UpdateResizeButton()
    self:UpdateDisplay()
end
```

**Reset-Button:**
```lua
confirmYesBtn:SetScript("OnClick", function()
    FizzlebeesTreasureTrackerDB.mobs = {}
    FizzlebeesTreasureTrackerDB.totalGold = 0
    FizzlebeesTreasureTrackerDB.totalDuration = 0
    FTT.sessionKills = {}
    FTT.sessionLoot = {}
    FTT.sessionGold = 0
    FTT.totalGold = 0
    FTT.sessionStartTime = 0
    FTT.totalDuration = 0
    FTT:UpdateDisplay()
    FTT:UpdateGoldDisplay()
    FTT:UpdateDurationDisplay()
end)
```

---

### 6. UI/Tracker.lua

**Pfad:** `Libs/UI/Tracker.lua`

**Zweck:** Mob-Liste, Accordion-Einträge, Entry-Pool-System

**Abhängigkeiten:**
- `Core.lua`: FTT.L, FTT.settings, FTT.ENTRY_WIDTH, etc.
- `Core.lua`: FTT:SaveSettings(), FTT:DebugPrint()
- `UI/Main.lua`: FTT.frame, FTT.scrollFrame, FTT.scrollChild, FTT.emptyText

**Exports:**
- `FTT:UpdateDisplay()` - Mob-Liste aktualisieren (Hauptfunktion!)
- `FTT:GetEntry(index)` - Entry aus Pool holen/erstellen
- `FTT:ResizeEntries()` - Alle Entries auf neue Breite anpassen
- `FTT:CollapseTracker()` - Tracker einklappen
- `FTT:ExpandTracker()` - Tracker ausklappen

**Entry-Pool-System:**
```lua
-- Wiederverwendbare Frames (Performance-Optimierung)
FTT.entryPool = {}

function FTT:GetEntry(index)
    if not self.entryPool[index] then
        -- Erstellt neuen Entry-Frame:
        local entry = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        entry:SetSize(ENTRY_WIDTH, 25)
        entry:SetBackdrop({...})

        -- Header (Button für Expand/Collapse)
        entry.header = CreateFrame("Button", nil, entry)
        entry.icon = entry.header:CreateFontString(...)  -- "+/-"
        entry.text = entry.header:CreateFontString(...)  -- "Mob: X/Y"

        -- Hide-Button (X-Icon, rechts oben)
        entry.hideBtn = CreateFrame("Button", nil, entry)
        entry.hideBtn:SetNormalTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")

        -- Details-Frame (Items)
        entry.details = CreateFrame("Frame", nil, entry)
        entry.details.lines = {}  -- Line-Buttons für Items

        entry.expanded = false
        entry.mobName = nil

        self.entryPool[index] = entry
    end
    return self.entryPool[index]
end
```

**UpdateDisplay() - Hauptlogik:**

1. **Cleanup:**
   - Alle Entries verstecken
   - Player aus Mob-Liste entfernen (falls vorhanden)

2. **Empty State:**
   - Wenn keine Mobs: `emptyText` anzeigen

3. **Sortierung:**
   - Nach `lastKillTime` sortieren (neueste zuerst)

4. **Active/Inactive-Trennung:**
   - Active: `timeSinceKill <= 300` (5 Min)
   - Inactive: `timeSinceKill > 300`

5. **Width-Berechnung (für Auto-Size):**
   - Misst alle Mob-Namen und Item-Namen
   - Speichert `maxWidth` für Auto-Size-Modus

6. **Display-Liste erstellen:**
   - Active Mobs
   - Separator (wenn Inactive vorhanden)
   - Inactive Mobs (wenn `showInactiveMobs`)

7. **Entries rendern:**
   - Für jeden Mob: `GetEntry(index)`
   - Header: `"Mob Name: session/total"`
   - Loot sortieren (nach Drop-Rate)
   - Items filtern (nach Quality, Item-Filter, Hidden)
   - Item-Zeilen erstellen:
     - `nameText` (links, nimmt verbleibenden Platz)
     - `countText` (50px breit, session/total)
     - `ratioText` (50px breit, 1:X)
   - Farbcodierung basierend auf Ratio:
     - 1-10: Weiß
     - 11-25: Hellgrün
     - 26-50: Hellgelb
     - 51-100: Hellorange
     - 101-200: Hellrot
     - 201+: Helllila
   - Glow-Effekt für Highlighted Items (pulsierend)
   - Tooltips (GameTooltip)
   - Click-Handler:
     - Left-Click (Highlight-Modus): Toggle Highlight
     - Right-Click: Item verstecken

8. **Auto-Size (wenn aktiviert):**
   - Berechnet `totalHeight` basierend auf `yOffset`
   - Berechnet `totalWidth` basierend auf `maxWidth`
   - `frame:SetSize(totalWidth, totalHeight)`

9. **Resize-Entries:**
   - Passt alle Entries an neue Frame-Breite an

**Item-Zeile Struktur:**
```lua
lineButton (Button, 16px Höhe)
├── glowTexture (Highlight-Glow, pulsierend für markierte Items)
├── highlightTexture (Hover-Effekt)
├── nameText (links, LEFT +5, RIGHT -105)
├── countText (50px breit, RIGHT -55)  -- "5/12"
└── ratioText (50px breit, RIGHT -5)   -- "1:42"
```

**Separator-Button (Inactive-Toggle):**
```lua
if not self.inactiveToggleButton then
    local toggleBtn = CreateFrame("Button", nil, scrollChild)
    toggleBtn:SetSize(100, 20)
    toggleBtn.text = toggleBtn:CreateFontString(...)
    toggleBtn.text:SetJustifyH("RIGHT")  -- Rechts-aligniert

    toggleBtn:SetScript("OnClick", function()
        self.settings.showInactiveMobs = not self.settings.showInactiveMobs
        self:SaveSettings()
        self:UpdateDisplay()
    end)
end

-- Text: "Show Older" oder "Hide Older" (basierend auf State)
```

**Inactive-Mobs:**
- Alpha: 0.4 (40% Opacity)
- Active-Mobs: Alpha 1.0 (100%)

**Zone-Filter:**
```lua
if self.settings.filterByZone then
    local currentMapID = C_Map.GetBestMapForUnit("player")
    local mobZoneID = mobData.zoneID
    if mobZoneID and currentMapID and mobZoneID ~= currentMapID then
        isWrongZone = true  -- Skip
    end
end
```

**Item-Filter:**
```lua
if self.settings.itemFilter and self.settings.itemFilter ~= "" then
    -- Prüft ob Mob gefilterte Item-ID hat
    local hasFilteredItem = false
    for itemName, lootData in pairs(mobData.loot) do
        local itemID = lootData.link:match("item:(%d+)")
        if itemID == self.settings.itemFilter then
            hasFilteredItem = true
            break
        end
    end
    if not hasFilteredItem then
        shouldShow = false  -- Skip
    end
end
```

**Quality-Filter:**
```lua
local _, _, itemQuality = GetItemInfo(lootData.link)
local minQuality = self.settings.minItemQuality or 0
local meetsQuality = (itemQuality and itemQuality >= minQuality)

-- Highlighted Items IMMER zeigen (ignoriert Quality-Filter)
local isHighlightedItem = (itemID == FTT.highlightedItemID)
if isHighlightedItem then
    meetsQuality = true
end
```

**Collapse/Expand:**
```lua
function FTT:CollapseTracker()
    self.savedHeight = self.frame:GetHeight()
    self.savedWidth = self.frame:GetWidth()
    self.scrollFrame:Hide()
    self.goldFrame:Hide()
    self.qualityFrame:Hide()
    self.kpsFrame:Hide()
    self.durationFrame:Hide()
    self.frame:SetHeight(60)  -- Nur Titel + Buttons
end

function FTT:ExpandTracker()
    self.scrollFrame:Show()
    self.goldFrame:Show()
    self.qualityFrame:Show()
    self.kpsFrame:Show()
    self.durationFrame:Show()
    if self.savedHeight and self.savedWidth then
        self.frame:SetSize(self.savedWidth, self.savedHeight)
    end
    self:UpdateDisplay()
end
```

---

### 7. Locales (enUS.lua, deDE.lua, etc.)

**Pfad:** `Locales/*.lua`

**Zweck:** Übersetzungen (10 Sprachen)

**Struktur:**
```lua
-- enUS.lua (Default mit Fallback)
local L = setmetatable({}, {
    __index = function(t, k)
        return k  -- Fallback: Key selbst zurückgeben
    end
})

L["TITLE"] = "Fizzlebee's Treasure Tracker"
L["SESSION"] = "Session"
L["TOTAL"] = "Total"
-- ...

_G[addonName .. "_Locale"] = L

-- deDE.lua (Überschreibt nur bei deDE-Locale)
local L = _G[addonName .. "_Locale"]
if not L or GetLocale() ~= "deDE" then return end

L["SESSION"] = "Sitzung"
L["TOTAL"] = "Gesamt"
-- ...
```

**Unterstützte Sprachen:**
- `enUS.lua` - Englisch (Default)
- `deDE.lua` - Deutsch
- `frFR.lua` - Französisch
- `esES.lua` - Spanisch
- `ruRU.lua` - Russisch
- `zhCN.lua` - Chinesisch (Simplified)
- `zhTW.lua` - Chinesisch (Traditional)
- `koKR.lua` - Koreanisch
- `ptBR.lua` - Portugiesisch (Brasilianisch)
- `itIT.lua` - Italienisch

---

### 8. FizzlebeesTreasureTracker.lua (Main File)

**Pfad:** `FizzlebeesTreasureTracker.lua`

**Zweck:** Slash-Commands

**Slash-Commands:**
- `/ftt` oder `/treasure` - Toggle Tracker-Fenster
- `/ftt debug` - Debug-Info ausgeben
- `/ftt refresh` - Display refreshen (Recovery)
- `/ftt help` - Help-Text anzeigen

**Slash-Handler:**
```lua
SLASH_FIZZLEBEESTREASURETRACKER1 = "/ftt"
SLASH_FIZZLEBEESTREASURETRACKER2 = "/treasure"

SlashCmdList["FIZZLEBEESTREASURETRACKER"] = function(msg)
    msg = msg:lower():trim()

    if msg == "debug" then
        -- Gibt sessionKills, sessionLoot, totalData aus
    elseif msg == "refresh" or msg == "reset" then
        FTT:UpdateGoldDisplay()
        FTT:UpdateDurationDisplay()
        FTT:UpdateDisplay()
    elseif msg == "help" then
        -- Gibt verfügbare Commands aus
    else
        -- Toggle Tracker-Fenster
        if FTT.frame:IsShown() then
            FTT.frame:Hide()
        else
            FTT.frame:Show()
            FTT:UpdateDisplay()
        end
    end
end
```

---

## Datenstruktur (SavedVariables)

**Variable:** `FizzlebeesTreasureTrackerDB`

**Struktur:**
```lua
FizzlebeesTreasureTrackerDB = {
    mobs = {
        ["Mob Name 1"] = {
            kills = 42,
            lastKillTime = 1234567890.123,  -- GetTime()
            zoneID = 2112,  -- C_Map.GetBestMapForUnit("player")
            autoExpanded = true,
            loot = {
                ["Item Name 1"] = {
                    count = 5,
                    link = "|cffa335ee|Hitem:12345:0:0:0:0:0:0:0:80|h[Item Name 1]|h|r"
                },
                ["Item Name 2"] = {
                    count = 12,
                    link = "..."
                }
            }
        },
        ["Mob Name 2"] = { ... }
    },

    position = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0
    },

    frameSize = {
        width = 390,
        height = 500
    },

    totalGold = 123456,  -- Kupfer
    totalDuration = 7200,  -- Sekunden

    totalQuality = {
        green = 42,
        blue = 12,
        purple = 3,
        orange = 0
    },

    settings = {
        transparentMode = false,
        backgroundOpacity = 0,
        fontScale = 1,
        autoSize = true,
        lockPosition = false,
        itemFilter = "",
        filterByZone = true,
        showDebug = false,
        showInactiveMobs = true,
        highlightedItemID = "12345",  -- als String!
        minItemQuality = 0,
        showGoldLine = true,
        showQualityLine = true,
        showDurationLine = true,
        showKillsLine = true
    }
}
```

---

## Wichtige Design-Patterns

### 1. Entry-Pool-System

**Problem:** Performance-Issue bei vielen Mob-Entries (Frame-Creation ist teuer)

**Lösung:** Wiederverwendbare Frame-Pool
- `FTT.entryPool[index]` speichert alle Entries
- Beim Verstecken: Frame wird recycled (nicht gelöscht)
- Beim nächsten `UpdateDisplay()`: Vorhandener Entry wird wiederverwendet
- **Vorteil:** Keine Frame-Creation nach initialer Erstellung

### 2. Heartbeat-System

**Problem:** UpdateDisplay() kann in seltenen Fällen stoppen (z.B. durch WoW-Fehler)

**Lösung:** Heartbeat-Monitoring
- Alle 30 Sekunden: `FTT:CheckHeartbeat()`
- Prüft ob `lastUpdateTime` > 60 Sekunden alt
- Falls ja + recent activity: Auto-Refresh

### 3. Font-Skalierung

**Problem:** Große UI-Elemente auf kleinen Monitoren, kleine Texte auf großen Monitoren

**Lösung:** Dynamische Font-Skalierung
- User wählt Klein/Mittel/Groß
- `FTT:S(value)` skaliert alle Werte
- `FTT:GetFont(size)` wählt passende WoW-Fonts
- `FTT:ApplyFontScaling()` updated ALLE UI-Elemente **ohne Reload**

### 4. Auto-Collapse/Expand

**Problem:** Zu viele alte Mobs verstopfen die Liste

**Lösung:** Auto-Collapse-System
- Beim Kill: Mob wird expandiert (`FTT.expandedMobs[mobName] = true`)
- Nach 5 Minuten: Mob wird automatisch kollabiert
- Bei Addon-Load: Alle Mobs >5 Min werden kollabiert
- **User-Override:** User kann manuell expandieren (bleibt dann bis Session-Ende)

### 5. Inactive-Toggle

**Problem:** Alte Mobs (>5 Min) verstopfen Liste, aber User will sie manchmal sehen

**Lösung:** Separator mit Toggle-Button
- Mobs >5 Min = "Inactive"
- Separator zeigt Anzahl inaktiver Mobs
- Button: "Show Older" / "Hide Older"
- Inactive Mobs haben 40% Opacity (visuell gedimmt)

### 6. Item-Highlighting

**Problem:** User farmt spezifisches Item und will es über alle Mobs hinweg tracken

**Lösung:** Persistent Item-Highlighting
- User klickt Stift-Button (aktiviert Highlight-Modus)
- User klickt Item (wird als `highlightedItemID` gespeichert)
- Item bekommt pulsierenden Glow-Effekt (Animation)
- Highlighted Items ignorieren Quality-Filter (werden IMMER angezeigt)
- Highlight persists über Sessions (gespeichert in DB)

### 7. Quality-Filter

**Problem:** User will nur seltene Items sehen (Grün+, Blau+, Lila+)

**Lösung:** Quality-Slider mit Smart-Filtering
- Slider: Alle, Grün+, Blau+, Lila+
- Filtert Items in `UpdateDisplay()`
- **Ausnahme:** Highlighted Items werden IMMER gezeigt
- Mobs ohne sichtbare Items werden automatisch versteckt

### 8. Transparent-Modus

**Problem:** Border versteckt Spielwelt, User will mehr Sichtbarkeit

**Lösung:** Transparent-Modus mit Opacity-Slider
- Normal-Modus: Border + 85% Hintergrund
- Transparent-Modus: Kein Border + 0-30% Hintergrund (3 Stufen)
- Scrollbar wird im Transparent-Modus versteckt (sieht sonst komisch aus)

---

## Performance-Optimierungen

### 1. Entry-Pool
- Reduziert Frame-Creation auf initiale Erstellung
- Recycled Frames statt neue zu erstellen

### 2. Width-Berechnung
- Verwendet temporären FontString (`measureText`) zum Messen
- Cached Messungen für Session

### 3. Loot-Zuordnung
- Verwendet `C_Loot.GetLootSourceInfo()` für exakte Mob-Zuordnung (Area-Loot)
- Fallback-Queue für alte WoW-Versionen

### 4. AoE-Tracking
- `damagedMobs` table tracked alle gedamagten Mobs
- Cleanup nach 10 Sekunden (verhindert Memory-Leak)

### 5. Update-Throttling
- `UpdateDurationDisplay()` nur alle 1 Sekunde
- `UpdateDisplay()` nur bei relevanten Events (nicht jede Sekunde)

### 6. pcall-Wrapper
- `UpdateDisplay()` ist in pcall() gewrappt
- Bei Fehler: Heartbeat-Recovery greift

---

## Besonderheiten

### 1. Multi-Mob-Loot (Area-Loot)

WoW's Area-Loot kann Items von mehreren Mobs gleichzeitig zeigen. FTT löst das via:
- `C_Loot.GetLootSourceInfo(i)` gibt exakten Mob-Namen pro Slot
- Fallback: `recentKills`-Queue (FIFO)

### 2. Group-Play-Support

Wenn User in Gruppe ist und andere Spieler Mobs killen:
- Beim Looten: Prüft ob Mob in `recentKills`
- Falls nein: `FTT:RecordKill()` wird nachträglich aufgerufen
- **Effekt:** Groupmates' Kills werden beim Looten gezählt

### 3. Gold-Parsing

Gold-Nachrichten sind sprach-abhängig:
- Deutsch: "Ihr erhaltet Beute: 47 Silber 55 Kupfer"
- Englisch: "You loot 1 Gold 23 Silver 45 Copper"
- Regex-Patterns für beide Sprachen

### 4. Font-Skalierung OHNE Reload

Normalerweise benötigen UI-Änderungen ein `/reload`. Nicht bei FTT:
- `FTT:ApplyFontScaling()` iteriert durch ALLE UI-Elemente
- Updated FontObjects dynamisch via `SetFontObject()`
- Ruft `UpdateDisplay()` für Layout-Refresh

### 5. Highlight-Item-ID als String

**Wichtig:** `highlightedItemID` wird als String gespeichert (nicht Number):
```lua
local itemID = lootData.link:match("item:(%d+)")  -- Returns String!
FTT.highlightedItemID = tostring(itemID)  -- Ensure String
```

**Grund:** Lua-Number-Precision-Issues + DB-Serialisierung

### 6. Header-Line-Visibility

User kann einzelne Header-Zeilen ein/ausblenden:
- `showGoldLine`, `showQualityLine`, `showDurationLine`, `showKillsLine`
- `FTT:UpdateHeaderLayout()` repositioniert alle Zeilen dynamisch
- ScrollFrame wird unter der letzten sichtbaren Zeile angehängt

---

## Slash-Commands Cheat-Sheet

```bash
/ftt                  # Toggle Tracker-Fenster
/treasure             # Alias für /ftt
/ftt debug            # Debug-Info ausgeben (sessionKills, totalData)
/ftt refresh          # Display refreshen (Recovery-Mechanismus)
/ftt help             # Help-Text anzeigen
```

---

## Bekannte Probleme & Lösungen

### Problem: UpdateDisplay() stoppt

**Symptom:** Tracker updated nicht mehr nach Kill/Loot

**Lösung:** `/ftt refresh` oder Auto-Recovery (Heartbeat-System)

**Ursache:** Seltener WoW-Fehler in Event-Handler

### Problem: Falsche Loot-Zuordnung

**Symptom:** Items werden falschem Mob zugeordnet

**Lösung:**
- Prüfe ob `C_Loot.GetLootSourceInfo()` verfügbar ist
- Falls ja: Verwendet (sollte korrekt sein)
- Falls nein: Verwendet `recentKills`-Queue (kann bei schnellen Multi-Kills falsch sein)

**Workaround:** Loot langsamer (warte 1-2 Sekunden zwischen Kills)

### Problem: Highlighted Item verschwindet

**Symptom:** Highlighted Item wird nicht mehr angezeigt

**Ursache:** Quality-Filter versteckt Item

**Lösung:** Highlight-Logic ignoriert Quality-Filter (`meetsQuality = true` für Highlighted Items)

**Workaround:** Falls Problem besteht: Quality-Filter auf "Alle" setzen

### Problem: Breite zu schmal für lange Item-Namen

**Symptom:** Item-Namen werden abgeschnitten

**Lösung 1:** Auto-Size aktiviert → Frame passt sich automatisch an
**Lösung 2:** Auto-Size deaktiviert → Manuell Fenster verbreitern (Resize-Handle)

---

## API für externe AddOns

Siehe `API_DOCUMENTATION.md` für vollständige API-Dokumentation.

**Schnellstart:**
```lua
local FTT_API = _G.FizzlebeesTreasureTracker_API

if FTT_API and FTT_API:IsReady() then
    -- Font-Skalierung
    local font = FTT_API:GetFont("Normal")
    local scaledHeight = FTT_API:ScaleValue(25)

    -- Settings-Callback
    FTT_API:RegisterSettingsCallback(function(key, value)
        print("Setting changed: " .. key .. " = " .. tostring(value))
    end, "fontScale")
end
```

---

## Entwickler-Workflow

### 1. Testing

```bash
/ftt                  # Öffne Tracker
/ftt debug            # Check sessionKills/sessionLoot
/reload               # Reload UI (testet Persistence)
/console scriptErrors 1  # Enable Lua-Fehler
```

### 2. Debugging

```lua
-- In Settings: "Debug Mode" aktivieren
FTT:DebugPrint("Test message")  -- Wird nur ausgegeben wenn showDebug = true
```

### 3. Performance-Profiling

```lua
-- Measure UpdateDisplay() performance
local start = debugprofilestop()
FTT:UpdateDisplay()
local elapsed = debugprofilestop() - start
print("UpdateDisplay took " .. elapsed .. "ms")
```

### 4. Settings-Reset

```lua
/ftt
-- Klicke Settings (Zahnrad)
-- Klicke "Reset Data" (ganz unten)
-- Confirm
```

---

## Erweiterungsmöglichkeiten

### 1. Neue Features

**CSV-Export:**
```lua
-- In Settings: "Export CSV" Button
-- Exportiert mobs/loot als CSV für Excel/Sheets
```

**Whisper-Commands:**
```lua
-- Reagiert auf Whispers: "!ftt Mob Name"
-- Sendet Drop-Raten als Whisper zurück
```

**WeakAuras-Integration:**
```lua
-- Custom Trigger: FTT.highlightedItemID
-- Zeigt Notification bei Loot des Highlighted Items
```

### 2. Neue Sprachen

1. Kopiere `Locales/enUS.lua` nach `Locales/XX.lua`
2. Ändere `GetLocale() ~= "XX"` zu neuer Locale
3. Übersetze alle Strings
4. Füge zu `.toc` hinzu: `Locales\XX.lua`

### 3. Neue Settings

1. In `Core.lua`: Füge zu `FTT.settings` hinzu:
   ```lua
   FTT.settings = {
       ...
       myNewSetting = false
   }
   ```

2. In `Settings.lua`: Erstelle Checkbox:
   ```lua
   local myCheckbox = CreateCheckboxRelative(settingsFrame, previousCheckbox, -7, "My Setting", "myNewSetting", false)
   ```

3. In `Tracker.lua`: Verwende Setting:
   ```lua
   if FTT.settings.myNewSetting then
       -- Do something
   end
   ```

---

## Lizenz & Credits

**Lizenz:** BSD 3-Clause (siehe `LICENSE`)

**Author:** Fizzlebee (Vivian Voss) - Boulder Dash Heroes

**Danksagungen:**
- WoW-Community für Feedback
- Blizzard für WoW-API
- Claude AI für Code-Review

---

## Changelog

### Version 1.0.251022.0842 (22. Oktober 2025) - PATCH 11.0.5 HOTFIX
**KRITISCHER BUGFIX:**
- ⚠️ **GetTime() → time() Migration** - Behebt Timestamp-Reset nach Patch 11.0.5
- ✅ Alte Mobs (>5 Min) werden jetzt korrekt als "Inactive" markiert
- ✅ Neue Kills erscheinen sofort oben in der Liste
- ✅ Zone-Filter funktioniert wieder korrekt
- ✅ Auto-Collapse funktioniert über Sessions hinweg
- 🔧 Automatische Migration alter Daten beim ersten Start
- 📝 Migration-Message: "Migrated X old timestamps to new system"

**Technische Details:**
- `GetTime()` wurde durch `time()` ersetzt für alle `lastKillTime` Werte
- Neue Funktion: `FTT:MigrateTimestamps()` erkennt alte Daten
- Neue Funktion: `FTT:GetCurrentTime()` (Wrapper für `time()`)
- TOC Version: 110005

**Betroffene Dateien:**
- Core.lua (Zeit-Management, RecordKill, Auto-Collapse)
- Tracker.lua (Active/Inactive Check, Transparency)
- Events.lua (Cleanup)

**Migration-Logik:**
```lua
-- Alte GetTime()-Werte: 0 - 999.999.999 (< 2001)
-- Neue time()-Werte: 1.729.605.000+ (ab 2024)
if lastKillTime < 1000000000 then
    lastKillTime = 0  -- Als "sehr alt" markieren
end
```

### Version 1.0 (2025-01-20)
- Initial Release
- Mob-Tracking (Kill/Loot)
- Gold/Duration-Tracking
- Quality-Statistics
- Item-Highlighting
- Zone-Filter
- Auto-Collapse
- Transparent-Modus
- Font-Skalierung
- Public API
- 10 Sprachen

---

## Wichtige Hinweise für Entwickler

### 🇬🇧 GOLDENE REGEL #0: BBC English MANDATORY (Wichtigste Regel!)

**ALLE Dokumentation und Code-Comments MÜSSEN in BBC English geschrieben sein!**

**Nicht nur Vokabular, sondern auch Ton und Stil:**

#### Vokabular-Unterschiede:

| ❌ American English | ✅ BBC English | Verwendung |
|---------------------|----------------|------------|
| color | colour | Code-Comments, Docs |
| behavior | behaviour | Code-Comments, Docs |
| center | centre | Code-Comments, Docs |
| optimize | optimise | Code-Comments, Docs |
| analyze | analyse | Code-Comments, Docs |
| defense | defence | Code-Comments, Docs |
| license | licence (noun) | Dokumentation |
| gray | grey | Code-Comments, Docs |

#### Ton und Stil:

**❌ American Style (informell, direkt):**
```
// This function rocks! It totally fixes the bug.
// We're gonna make this work no matter what.
```

**✅ BBC Style (formell, präzise):**
```
-- This function addresses the issue effectively.
-- This implementation ensures correct behaviour.
```

#### Satzstruktur:

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

#### Wichtige Wendungen:

| ❌ Avoid | ✅ Use Instead |
|---------|----------------|
| "We'll fix this" | "This shall be corrected" |
| "Let's do X" | "One ought to perform X" |
| "This is gonna work" | "This shall function correctly" |
| "It's broken" | "This is non-functional" |
| "Get the data" | "Retrieve the data" |
| "Make sure" | "Ensure" |
| "Check if" | "Verify whether" |

#### Dokumentations-Stil:

**PATCHNOTES.md, README.md, CLAUDE.md:**
- Formell und präzise
- Passive Konstruktionen wo angebracht
- "One should" statt "You should"
- "This has been corrected" statt "We fixed this"

**Code-Comments:**
```lua
-- ❌ American Style:
-- This function gets all the mobs and sorts them by kill time.
-- It's super fast because we use a cache.

-- ✅ BBC English Style:
-- Retrieves all registered mobs and arranges them by kill timestamp.
-- Performance is optimised through caching mechanisms.
```

#### Warum BBC English?

1. **Professionalität**: Formeller, präziser Ton
2. **Internationalität**: Weltweit anerkannter Standard
3. **Konsistenz**: Einheitlicher Stil im gesamten Projekt
4. **Klarheit**: Weniger umgangssprachlich, präziser

#### Mandatory Checklist vor jedem Commit:

- [ ] Alle neuen Comments in BBC English?
- [ ] Alle Dokumentation in BBC English?
- [ ] Keine amerikanischen Schreibweisen (color, behavior)?
- [ ] Formeller Ton (keine "gonna", "wanna", etc.)?

---

### 🔧 GOLDENE REGEL #1: Debug-Ausgaben IMMER hinter Settings verstecken

**NIEMALS direkt `print()` für Debug-Messages verwenden!**

```lua
-- ❌ FALSCH - Debug-Spam für User sichtbar:
print("DEBUG: UpdateDisplay called")

-- ✅ RICHTIG - Nur sichtbar wenn Debug-Checkbox aktiv:
FTT:DebugPrint("DEBUG: UpdateDisplay called")
```

**Print-Helper in Core.lua:**

```lua
-- Für Debug-Messages (nur mit showDebug=true sichtbar):
function FTT:DebugPrint(...)
    if self.settings and self.settings.showDebug then
        print(...)
    end
end

-- Für wichtige User-Messages (immer sichtbar):
function FTT:InfoPrint(...)
    print(...)
end
```

**Verwendung:**

| Typ | Funktion | Wann verwenden |
|-----|----------|----------------|
| **Debug** | `FTT:DebugPrint(...)` | Debug-Info, Tracing, Development |
| **Info** | `FTT:InfoPrint(...)` | Load-Messages, Migrations, Bestätigungen |
| **Error** | `FTT:InfoPrint(...)` | Fehler (immer zeigen!) |

**Beispiele:**

```lua
-- ✅ Debug (nur mit Checkbox):
FTT:DebugPrint("|cffFFD700FTT Debug:|r LOOT_OPENED fired")
FTT:DebugPrint("|cffFFD700FTT Debug:|r UpdateDisplay called")

-- ✅ Info (immer zeigen):
FTT:InfoPrint("|cffFFD700FTT:|r Migrated 42 old timestamps")
FTT:InfoPrint("|cffFFD700FTT:|r Item highlighted: [Item Name]")
FTT:InfoPrint("|cffFFD700FTT:|r All data reset")

-- ✅ Error (immer zeigen):
FTT:InfoPrint("|cffFF0000FTT Error:|r UpdateDisplay failed: " .. err)
```

**Settings-Checkbox:**
- Settings → "Debug Mode" aktivieren
- Slash-Command: `/ftt debug` (zeigt Debug-Info)

---

### ⚠️ GOLDENE REGEL #2: NIEMALS `GetTime()` für persistente Timestamps verwenden!

**Problem:**
```lua
-- FALSCH - GetTime() wird bei jedem WoW-Start zurückgesetzt!
local timestamp = GetTime()  -- → 12345.67
-- Nach /reload oder Patch: 0.00 → ALLE ALTEN DATEN UNGÜLTIG!
```

**Lösung:**
```lua
-- RICHTIG - time() ist Unix-Timestamp und niemals reset
local timestamp = time()  -- → 1729605000 (22. Okt 2024, 14:30 UTC)
-- Nach /reload oder Patch: 1729605120 → WEITERHIN GÜLTIG!
```

### Verwendung in FTT:

**Für persistente Timestamps (SavedVariables):**
```lua
-- Speichern:
mobs[mobName].lastKillTime = time()

-- Vergleichen:
local currentTime = time()
local timeSinceKill = currentTime - mobs[mobName].lastKillTime
if timeSinceKill > 300 then
    -- Älter als 5 Minuten
end
```

**Für Session-Zeiten (nicht persistiert):**
```lua
-- GetTime() ist OK für Session-Dauer, da nur relativ:
FTT.sessionStartTime = GetTime()
local sessionDuration = GetTime() - FTT.sessionStartTime
```

### Migration alter AddOns:

Falls du andere AddOns hast die `GetTime()` für persistente Daten nutzen:

```lua
function MigrateOldTimestamps()
    local UNIX_TIME_THRESHOLD = 1000000000  -- ~Sep 2001

    for key, data in pairs(MySavedVariables) do
        if data.timestamp and data.timestamp < UNIX_TIME_THRESHOLD then
            -- Alte GetTime()-basierte Daten
            data.timestamp = 0  -- Als ungültig markieren
            -- Oder: data.timestamp = time() - 86400  -- Als "gestern" markieren
        end
    end
end
```

---

## Kontakt

**Bug-Reports:** GitHub Issues (falls Repository existiert)
**In-Game:** Fizzlebee (Boulder Dash Heroes, EU-Server)
**Discord:** (falls vorhanden)

---

*Generiert von Claude AI für Fizzlebee's Treasure Tracker v1.0.251022.0842*
*Letzte Aktualisierung: 2025-10-22 08:42*
*Patch 11.0.5 Hotfix dokumentiert*
