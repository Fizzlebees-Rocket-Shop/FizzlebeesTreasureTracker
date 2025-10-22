# Fizzlebee's Treasure Tracker - Development Guide

**This document is mandatory reading for developers contributing to FTT.**

For main documentation, see [CLAUDE.md](CLAUDE.md)

---

## Development Workflow

### 1. Testing

```bash
/ftt                  # Open tracker
/ftt debug            # Check sessionKills/sessionLoot
/reload               # Reload UI (tests persistence)
/console scriptErrors 1  # Enable Lua errors
```

### 2. Debugging

```lua
-- In Settings: Enable "Debug Mode" checkbox
FTT:DebugPrint("Test message")  -- Will only output when showDebug = true
```

### 3. Performance Profiling

```lua
-- Measure UpdateDisplay() performance
local start = debugprofilestop()
FTT:UpdateDisplay()
local elapsed = debugprofilestop() - start
print("UpdateDisplay took " .. elapsed .. "ms")
```

### 4. Settings Reset

```lua
/ftt
-- Click Settings (cog icon)
-- Click "Reset Data" (bottom)
-- Confirm
```

---

## Slash Commands Cheat-Sheet

```bash
/ftt                  # Toggle tracker window
/treasure             # Alias for /ftt
/ftt debug            # Output debug info (sessionKills, totalData)
/ftt refresh          # Refresh display (recovery mechanism)
/ftt help             # Show help text
```

---

## Known Issues & Solutions

### Problem: UpdateDisplay() Stops

**Symptom:** Tracker no longer updates after kill/loot

**Solution:** `/ftt refresh` or auto-recovery (heartbeat system)

**Cause:** Rare WoW error in event handler

---

### Problem: Incorrect Loot Assignment

**Symptom:** Items assigned to wrong mob

**Solution:**
- Check whether `C_Loot.GetLootSourceInfo()` available
- If yes: Used (should be correct)
- If no: Uses `recentKills` queue (can be wrong with fast multi-kills)

**Workaround:** Loot slower (wait 1-2 seconds between kills)

---

### Problem: Highlighted Item Disappears

**Symptom:** Highlighted item no longer displayed

**Cause:** Quality filter hides item

**Solution:** Highlight logic ignores quality filter (`meetsQuality = true` for highlighted items)

**Workaround:** If problem persists: Set quality filter to "All"

---

### Problem: Width Too Narrow for Long Item Names

**Symptom:** Item names are truncated

**Solution 1:** Enable auto-size → Frame automatically adjusts
**Solution 2:** Disable auto-size → Manually widen window (resize handle)

---

## Extension Possibilities

### 1. New Features

**CSV Export:**
```lua
-- In Settings: "Export CSV" button
-- Exports mobs/loot as CSV for Excel/Sheets
```

**Whisper Commands:**
```lua
-- Reacts to whispers: "!ftt Mob Name"
-- Sends drop rates as whisper back
```

**WeakAuras Integration:**
```lua
-- Custom trigger: FTT.highlightedItemID
-- Shows notification on loot of highlighted item
```

---

### 2. New Languages

1. Copy `Locales/enUS.lua` to `Locales/XX.lua`
2. Change `GetLocale() ~= "XX"` to new locale
3. Translate all strings
4. Add to `.toc`: `Locales\XX.lua`

---

### 3. New Settings

**Step 1:** Add to `Core.lua`:
```lua
FTT.settings = {
    ...
    myNewSetting = false
}
```

**Step 2:** Create checkbox in `Settings.lua`:
```lua
local myCheckbox = CreateCheckboxRelative(
    settingsFrame,
    previousCheckbox,
    -7,
    "My Setting",
    "myNewSetting",
    false  -- affects layout
)
```

**Step 3:** Use setting in `Tracker.lua`:
```lua
if FTT.settings.myNewSetting then
    -- Do something
end
```

---

## Important Design Decisions

### Why Entry Pool System?

**Problem:** Creating frames is expensive. With 50+ mobs, creating frames every `UpdateDisplay()` causes lag.

**Solution:** Reuse frames. Create once, hide/show as needed.

**Implementation:**
```lua
function FTT:GetEntry(index)
    if not self.entryPool[index] then
        -- Create new frame (only happens once)
        local entry = CreateFrame(...)
        self.entryPool[index] = entry
    end
    -- Reuse existing frame
    return self.entryPool[index]
end
```

---

### Why time() Instead of GetTime()?

**Problem:** WoW patches reset `GetTime()` to 0, invalidating all timestamps.

**Solution:** Use Unix timestamps via `time()` - never reset.

**Example:**
```lua
-- INCORRECT:
mobs[mobName].lastKillTime = GetTime()  -- 12345.67
-- After patch: 0.00 → All timestamps invalid!

-- CORRECT:
mobs[mobName].lastKillTime = time()     -- 1729605000
-- After patch: 1729605120 → Still valid!
```

**When to Use GetTime():**
```lua
-- OK for session-relative times:
FTT.sessionStartTime = GetTime()
local sessionDuration = GetTime() - FTT.sessionStartTime
```

---

### Why Heartbeat System?

**Problem:** In rare cases, `UpdateDisplay()` can stop running due to WoW errors.

**Solution:** Monitor `lastUpdateTime`. If >60s without update + recent activity, auto-refresh.

**Implementation:**
```lua
FTT.heartbeatTimer = C_Timer.NewTicker(30, function()
    FTT:CheckHeartbeat()
end)

function FTT:CheckHeartbeat()
    local timeSinceUpdate = GetTime() - self.lastUpdateTime
    if timeSinceUpdate > 60 and recentActivity then
        -- Auto-refresh
        self:UpdateDisplay()
    end
end
```

---

### Why Highlight Item ID as String?

**Problem:** Lua number precision issues + DB serialisation.

**Solution:** Store item IDs as strings.

**Implementation:**
```lua
-- Extract item ID from link (returns string!):
local itemID = lootData.link:match("item:(%d+)")

-- Store as string:
FTT.highlightedItemID = tostring(itemID)

-- Compare as strings:
if itemID == FTT.highlightedItemID then
    -- Match!
end
```

---

## Multi-Mob Loot (Area Loot)

WoW's area loot can show items from multiple mobs simultaneously. FTT solves this via:

**Primary Method:**
```lua
-- C_Loot.GetLootSourceInfo(slotIndex) returns exact mob GUID
local sourceGUID, sourceName = C_Loot.GetLootSourceInfo(i)
```

**Fallback (older WoW versions):**
```lua
-- Use recentKills FIFO queue
local function GetNextLootTarget()
    if #recentKills > 0 then
        return table.remove(recentKills, 1).name
    end
    return nil
end
```

---

## Group Play Support

When user is in group and other players kill mobs:

**Problem:** User didn't damage mob, so not in `damagedMobs`.

**Solution:** On loot, check whether mob in `recentKills`. If not, call `FTT:RecordKill()` retroactively.

**Implementation:**
```lua
-- On LOOT_OPENED:
if not recentKills[mobName] then
    -- This is a group kill we didn't participate in
    FTT:RecordKill(mobName)
end
```

**Effect:** Group mates' kills are counted when looting.

---

## Gold Parsing

Gold messages are language-dependent:

**German:** "Ihr erhaltet Beute: 47 Silber 55 Kupfer"
**English:** "You loot 1 Gold 23 Silver 45 Copper"

**Implementation:**
```lua
-- Regex patterns for both languages
local gold = msg:match("(%d+)%s*Gold") or 0
local silver = msg:match("(%d+)%s*[Ss]ilber") or msg:match("(%d+)%s*[Ss]ilver") or 0
local copper = msg:match("(%d+)%s*[Kk]upfer") or msg:match("(%d+)%s*[Cc]opper") or 0

-- Convert to copper (1g = 10000c, 1s = 100c)
local totalCopper = (gold * 10000) + (silver * 100) + copper
```

---

## Font Scaling WITHOUT Reload

Normally, UI changes require `/reload`. Not in FTT!

**How It Works:**
```lua
function FTT:ApplyFontScaling()
    -- Update ALL font objects dynamically
    if self.titleText then
        self.titleText:SetFontObject(self:GetFont("L"))
    end
    if self.sessionGoldText then
        self.sessionGoldText:SetFontObject(self:GetFont("S"))
    end
    -- ... update all other fontstrings ...

    -- Refresh layout
    self:UpdateHeaderLayout()
    self:UpdateDisplay()
end
```

**Key:** `SetFontObject()` changes fonts dynamically without reload.

---

## Header Line Visibility

User can show/hide individual header lines:

**Settings:**
- `showGoldLine`
- `showQualityLine`
- `showDurationLine`
- `showKillsLine`

**Layout Function:**
```lua
function FTT:UpdateHeaderLayout()
    local yOffset = -30  -- Start position

    if self.settings.showGoldLine then
        self.goldFrame:Show()
        self.goldFrame:SetPoint("TOP", 0, yOffset)
        yOffset = yOffset - 30
    else
        self.goldFrame:Hide()
    end

    -- ... repeat for other lines ...

    -- Position scrollFrame below last visible line
    self.scrollFrame:SetPoint("TOP", 0, yOffset)
end
```

---

## Peculiarities

### 1. Multi-Mob Loot (Area Loot)

See above - uses `C_Loot.GetLootSourceInfo()` for exact assignment.

---

### 2. Group Play Support

See above - retroactive `RecordKill()` on loot.

---

### 3. Gold Parsing

See above - regex for DE + EN.

---

### 4. Font Scaling WITHOUT Reload

See above - dynamic `SetFontObject()`.

---

### 5. Highlight Item ID as String

See above - precision + serialisation.

---

### 6. Header Line Visibility

See above - dynamic layout via `UpdateHeaderLayout()`.

---

## Licence & Credits

**Licence:** BSD 3-Clause (see `LICENSE`)

**Author:** Fizzlebee (Vivian Voss) - Boulder Dash Heroes

**Acknowledgements:**
- WoW community for feedback
- Blizzard for WoW API
- Claude AI for code review

---

## Contact

**Bug Reports:** GitHub Issues
**In-Game:** Fizzlebee (Boulder Dash Heroes, EU Server)

---

**For architecture details, see [CLAUDE_ARCHITECTURE.md](CLAUDE_ARCHITECTURE.md)**
**For API reference, see [CLAUDE_API.md](CLAUDE_API.md)**
**For main documentation, see [CLAUDE.md](CLAUDE.md)**

---

*This documentation follows BBC English standards as specified in Golden Rule #5.*
