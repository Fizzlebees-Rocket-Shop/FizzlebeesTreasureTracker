# Fizzlebee's Treasure Tracker - Patch Notes

## Version 1.0.251022.0842 (22nd October 2025)

### 🔥 CRITICAL HOTFIX - Patch 11.0.5 Compatibility

**Issue:**
Following WoW Patch 11.0.5 on 22nd October 2025, all mob timestamps were reset, which resulted in:
- ❌ All inactive mobs (>5 minutes) being displayed as "active"
- ❌ Auto-collapse functionality ceasing to operate correctly
- ❌ Zone filter functioning incorrectly
- ❌ New kills failing to appear at the top of the list

**Root Cause:**
Blizzard reset `GetTime()` with Patch 11.0.5. This function returns seconds since WoW client start and is reset to 0 upon each patch/restart.

**Resolution:**
Migration to `time()` (Unix timestamps) - never resets, remains stable across all patches!

---

### ✅ Issues Corrected

#### 🕐 Timestamp System Completely Rebuilt
- **GetTime() → time() Migration**
  - All `lastKillTime` values now utilise Unix timestamps
  - Automatic detection of legacy GetTime()-based data
  - Migration upon initial start: Legacy data is set to 0 (marked as "very old")
  - Migration message in chat: "Migrated X old timestamps to new system"

- **Affected Areas:**
  - RecordKill() - Now stores timestamps using `time()`
  - Auto-Collapse - Now functions correctly across sessions
  - Active/Inactive Detection - Correct identification of old mobs (>5 Min)
  - Zone Filter - Now functioning correctly

#### 🔧 Debug Output System
- **All Debug Prints Concealed Behind Setting**
  - New function: `FTT:DebugPrint()` - Only visible with "Debug Mode" checkbox enabled
  - New function: `FTT:InfoPrint()` - Important user messages (always visible)
  - All direct `print()` calls removed
  - Consistent implementation throughout codebase

- **Debug Messages Only Visible When:**
  - Settings → "Debug Mode" checkbox is ticked
  - Or: `/ftt debug` command is executed

- **User Messages Remain Visible:**
  - Load Messages ("Addon loaded")
  - Migration Notices ("Migrated X timestamps")
  - User Actions ("Item highlighted", "Data reset")
  - Error Messages (ALWAYS visible!)

---

### 📝 Technical Details

#### Migration Logic
```lua
-- Detection of legacy GetTime() values:
-- GetTime() values: 0 - 999,999,999 (< 2001)
-- time() values: 1,729,605,000+ (from 2024 onwards)

if lastKillTime < 1000000000 then
    lastKillTime = 0  -- Mark as "very old"
end
```

#### Modified Files
- `Libs/Core.lua` - Migration, InfoPrint, Time Management
- `Libs/UI/Tracker.lua` - Active/Inactive Check, Print Statements
- `Libs/UI/Settings.lua` - Print Statements
- `Libs/UI/Main.lua` - (no modifications required)
- `Libs/Events.lua` - Cleanup
- `FizzlebeesTreasureTracker.lua` - Slash Commands
- `FizzlebeesTreasureTracker.toc` - Version Update

#### New Functions
```lua
-- Time Management:
FTT:GetCurrentTime()        -- Returns: time() (Unix Timestamp)
FTT:MigrateTimestamps()     -- Migrates legacy GetTime() values

-- Print Helpers:
FTT:DebugPrint(...)         -- Only with showDebug=true
FTT:InfoPrint(...)          -- Always visible
```

---

### 🎯 Important Notes

**Following the Update:**
1. Upon first login after update, you shall see:
   ```
   FTT: Migrated [number] old timestamps to new system.
   FTT: Old mobs from before patch 11.0.5 are now marked as inactive.
   ```
2. All legacy mobs (from prior to the update) shall be marked as "very old"
3. Henceforth, everything shall function correctly!

**Enabling Debug Mode:**
- Open Settings (Cog icon)
- Tick "Debug Mode" checkbox
- Or: Enter `/ftt debug` in chat

---

### 🐛 Known Issues

No known issues in this version.

---

### 📚 For Developers

**Golden Rules (MANDATORY!):**

1. **NEVER use `print()` directly!**
   ```lua
   ❌ print("DEBUG: ...")           -- User sees spam
   ✅ FTT:DebugPrint("DEBUG: ...")  -- Only with checkbox
   ```

2. **NEVER use `GetTime()` for persistent data!**
   ```lua
   ❌ lastKillTime = GetTime()  -- Resets after patch!
   ✅ lastKillTime = time()     -- Stable permanently!
   ```

3. **User Messages with InfoPrint:**
   ```lua
   ✅ FTT:InfoPrint("Data reset")      -- Always display
   ✅ FTT:InfoPrint("Error: " .. err)  -- Errors always display
   ```

4. **BBC English MANDATORY:**
   ```lua
   ❌ -- This function optimizes the color scheme
   ✅ -- This function optimises the colour scheme
   ```

See `CLAUDE.md` for complete documentation.

---

### 📦 Download & Installation

**CurseForge:** [Link when available]
**GitHub:** [Link when available]

**Manual Installation:**
1. Extract to `World of Warcraft\_retail_\Interface\AddOns\`
2. Restart WoW
3. Addon should be activated automatically

---

### 🔄 Migration from Older Versions

**From v1.0 → v1.0.251022.0842:**
- ✅ Automatic migration upon first start
- ✅ All data is preserved (Gold, Kills, Loot)
- ✅ Only timestamps are reset
- ⚠️ Old mobs shall be marked as "inactive" (>5 Min)

**No action required!** - Everything occurs automatically.

---

### 💬 Support & Feedback

**Bug Reports:** GitHub Issues
**In-Game:** Fizzlebee (Boulder Dash Heroes, EU-Server)
**Discord:** [If available]

---

### 👏 Credits

**Author:** Fizzlebee (Vivian Voss) - Boulder Dash Heroes
**Testing:** Community
**AI-Assisted Development:** Claude (Anthropic)

---

## Previous Versions

### Version 1.0 (20th January 2025)

**Initial Release**

- ✅ Mob Kill Tracking (Session & Total)
- ✅ Loot Tracking with Drop Rates (1:X Ratio)
- ✅ Gold Tracking (Session & Total)
- ✅ Quality Statistics (Green/Blue/Purple Items)
- ✅ Performance Metrics (Kills/s, Kills/h)
- ✅ Item Highlighting System
- ✅ Zone Filter
- ✅ Auto-Collapse (>5 Min)
- ✅ Transparent Mode
- ✅ Font Scaling (Small/Medium/Large)
- ✅ Public API for other AddOns
- ✅ 10 Languages (EN, DE, FR, ES, RU, CN, TW, KR, PT, IT)

**Features:**
- Accordion-style mob list
- Sorting by recency (newest first)
- Colour-coded drop rates
- Auto-expand upon new loot
- Draggable & resizable UI
- SavedVariables persistence
- Heartbeat monitoring system
- Entry pool system (performance optimisation)

---

*Last Updated: 22nd October 2025*
*WoW Interface Version: 11.0.2.05 (The War Within)*
