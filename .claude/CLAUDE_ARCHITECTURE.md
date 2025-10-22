# Fizzlebee's Treasure Tracker - Architecture Documentation

**This document is mandatory reading for developers working on FTT.**

For main documentation, see [CLAUDE.md](CLAUDE.md)

---

## File Structure

```
FizzlebeesTreasureTracker/
├── .claude/                        # Development workspace
│   ├── CLAUDE.md                   # Main documentation (BBC English)
│   ├── CLAUDE_DE.md                # Full German documentation (backup)
│   ├── CLAUDE_ARCHITECTURE.md      # This file - Architecture details
│   ├── CLAUDE_API.md               # API reference for developers
│   ├── CLAUDE_DEVELOPMENT.md       # Development workflow
│   ├── release.sh                  # Interactive release helper
│   └── release.ps1                 # Legacy PowerShell script (deprecated)
├── .github/
│   └── workflows/
│       └── release.yml             # GitHub Actions release workflow
├── Libs/                           # Core logic modules
│   ├── Core.lua                    # FTT main table, data management, settings
│   ├── API.lua                     # Public API for other addons
│   ├── Events.lua                  # WoW event handlers (Combat, Loot, Gold)
│   └── UI/                         # UI modules
│       ├── Main.lua                # Main window, gold/duration display
│       ├── Settings.lua            # Settings dialogue, checkboxes, sliders
│       └── Tracker.lua             # Mob list, accordion entries, entry pool
├── Locales/                        # Translations (10 languages)
│   ├── enUS.lua                    # English (default with fallback)
│   ├── deDE.lua                    # German
│   ├── frFR.lua                    # French
│   ├── esES.lua                    # Spanish
│   ├── ruRU.lua                    # Russian
│   ├── zhCN.lua                    # Chinese (Simplified)
│   ├── zhTW.lua                    # Chinese (Traditional)
│   ├── koKR.lua                    # Korean
│   ├── ptBR.lua                    # Portuguese (Brazilian)
│   └── itIT.lua                    # Italian
├── Textures/                       # Textures & assets
│   └── dot.tga                     # Circle texture for quality display
├── FizzlebeesTreasureTracker.toc   # Addon metadata & load order
├── FizzlebeesTreasureTracker.lua   # Slash commands & initialisation
├── README.md                       # User-facing documentation
├── PATCHNOTES.txt                  # Version history (plain text)
├── LICENSE                         # BSD 3-Clause licence
└── .gitignore                      # Git exclusion rules
```

---

## Load Order (TOC)

Files are loaded in this sequence (defined in `.toc`):

1. **Locales/*.lua** (All translations)
2. **Libs/Core.lua** (FTT table, constants, utilities, data management)
3. **Libs/API.lua** (Public API)
4. **Libs/UI/Main.lua** (Main window, gold/duration display)
5. **Libs/UI/Settings.lua** (Settings dialogue)
6. **Libs/UI/Tracker.lua** (Mob list, entry pool)
7. **Libs/Events.lua** (Event handlers)
8. **FizzlebeesTreasureTracker.lua** (Slash commands)

---

## Module Descriptions

### 1. Core.lua

**Path:** `Libs/Core.lua`

**Purpose:** Central logic, data management, settings, utilities

**Dependencies:**
- `Locales/*.lua` (L table)

**Exports:**
- `FTT` (global table)
- `FTT:DebugPrint()`
- `FTT:InfoPrint()`
- `FTT:FormatMoney()` / `FTT:FormatDuration()` / `FTT:FormatNumber()`
- `FTT:RecordKill()` / `FTT:RecordLoot()`
- `FTT:SaveSettings()` / `FTT:SavePosition()` / `FTT:SaveFrameSize()`
- `FTT:RestorePosition()` / `FTT:RestoreFrameSize()`
- `FTT:S(value)` - Font scaling
- `FTT:GetFont(size)` - Font object selection
- `FTT:ApplyFontScaling()` - Apply font scaling to UI
- `FTT:UpdateHeaderLayout()` - Update header line layout
- `FTT:RecalculateQualityFromDatabase()` - Recalculate quality statistics

**Important Constants:**
```lua
FTT.ENTRY_WIDTH = 320        -- Width of accordion entries
FTT.SCROLLBAR_PADDING = 40   -- Scrollbar width
FTT.FRAME_PADDING = 70       -- Total padding (including scrollbar + margins)
FTT.FRAME_WIDTH = 390        -- Main window width
FTT.ITEM_LEFT_OFFSET = 8     -- Left offset for item lines
FTT.ITEM_RIGHT_PADDING = 8   -- Right padding for item lines
FTT.ITEM_LINE_WIDTH = 312    -- Width of item lines
FTT.INFO_FRAME_WIDTH = 340   -- Width for gold/duration displays
```

**Session Tracking:**
```lua
FTT.sessionKills = {}        -- Kills in current session (mobName -> count)
FTT.sessionLoot = {}         -- Loot in current session (mobName -> {itemName -> count})
FTT.sessionGold = 0          -- Gold in current session (in copper)
FTT.totalGold = 0            -- Gold total (in copper)
FTT.sessionQuality = {}      -- Quality counter session (green, blue, purple, orange)
FTT.totalQuality = {}        -- Quality counter total
FTT.sessionStartTime = 0     -- Session start (GetTime())
FTT.totalDuration = 0        -- Total duration (seconds)
FTT.sessionDamage = 0        -- Damage in current session
FTT.totalDamage = 0          -- Total damage overall
FTT.expandedMobs = {}        -- Which mobs are expanded (mobName -> true/false)
FTT.hiddenMobs = {}          -- Which mobs are hidden (mobName -> true)
FTT.hiddenItems = {}         -- Which items are hidden (itemName -> true)
FTT.entryPool = {}           -- Pool of reusable entry frames
FTT.highlightedItemID = nil  -- Highlighted item (itemID as string)
FTT.highlightMode = false    -- Highlight mode active (waiting for user selection)
```

**Font Scaling:**
```lua
FTT.SCALE_MULTIPLIERS = {[0] = 0.88, [1] = 1.0, [2] = 1.12}

function FTT:S(value)
    -- Scales value based on fontScale setting
    local scale = self.settings.fontScale or 1
    return math.floor(value * self.SCALE_MULTIPLIERS[scale])
end

function FTT:GetFont(size)
    -- Selects WoW font object based on scale & size
    -- size: "L" (Large), "N" (Normal), "S" (Small), "H" (Highlight)
    -- Returns: Font name (e.g., "GameFontNormal")
end
```

**Default Settings:**
```lua
FTT.settings = {
    transparentMode = false,      -- Transparent (no border)
    backgroundOpacity = 0,        -- Background opacity (0-2)
    fontScale = 1,                -- Font size (0=Small, 1=Medium, 2=Large)
    autoSize = true,              -- Auto-size (width+height)
    lockPosition = false,         -- Position locked
    itemFilter = "",              -- Item ID filter
    filterByZone = true,          -- Filter by zone
    showDebug = false,            -- Debug mode
    showInactiveMobs = true,      -- Show old mobs (>5 min)
    highlightedItemID = nil,      -- Highlighted item (itemID)
    minItemQuality = 0,           -- Min. quality (0=All, 2=Green+, 3=Blue+, 4=Purple+)
    showGoldLine = true,          -- Show gold line
    showQualityLine = true,       -- Show quality line
    showDurationLine = true,      -- Show duration line
    showKillsLine = true          -- Show kills/s + kills/h + DPS line
}
```

**Heartbeat System:**
```lua
FTT.lastUpdateTime = 0           -- Last successful UpdateDisplay() call
FTT.heartbeatEnabled = true      -- Heartbeat monitoring enabled

function FTT:CheckHeartbeat()
    -- Checks every 30 seconds whether UpdateDisplay() still functions
    -- Performs auto-refresh if >60s no updates (recovery mechanism)
end
```

---

### 2. API.lua

**See [CLAUDE_API.md](CLAUDE_API.md) for complete API reference.**

---

### 3. Events.lua

**Path:** `Libs/Events.lua`

**Purpose:** WoW event handlers (Combat, Loot, Gold)

**Dependencies:**
- `Core.lua`: FTT:RecordKill(), FTT:RecordLoot(), FTT:DebugPrint()
- `UI/Main.lua`: FTT:UpdateDisplay(), FTT:UpdateGoldDisplay()

**Registered Events:**
- `ADDON_LOADED` - Addon initialisation
- `COMBAT_LOG_EVENT_UNFILTERED` - Damage & kill tracking
- `LOOT_OPENED` - Loot capturing
- `LOOT_CLOSED` - Cleanup
- `CHAT_MSG_MONEY` - Gold tracking
- `PLAYER_LOGOUT` - Save session data
- `ZONE_CHANGED_NEW_AREA` - Update zone filter

**Important Local Variables:**
```lua
local currentTarget = nil         -- Current target
local recentKills = {}            -- Recent kills with timestamps
local goldQueue = {}              -- Separate queue for gold tracking
local damagedMobs = {}            -- All damaged mobs (for AoE)
local currentLootTarget = nil     -- Currently looted mob
local LOOT_WINDOW = 5             -- Seconds window for loot assignment
local DAMAGE_WINDOW = 10          -- Seconds for damage tracking
```

---

### 4. UI/Main.lua

**Path:** `Libs/UI/Main.lua`

**Purpose:** Main window, gold/duration/DPS display, buttons

**UI Structure:**
```
FizzlebeesTreasureTrackerFrame (Main window)
├── titleText (Title)
├── settingsBtn (Cog icon)
├── highlightBtn (Pencil icon)
├── collapseBtn (+/- icon)
├── goldFrame (Gold display)
│   ├── sessionGoldText ("Session: XX")
│   └── totalGoldText ("Total: XX")
├── qualityFrame (Quality display)
│   ├── sessionQualityText ("Session: X⚫ X⚫ X⚫")
│   └── totalQualityText ("Total: X⚫ X⚫ X⚫")
├── durationFrame (Duration display)
│   ├── sessionDurationText ("Session: HH:MM:SS")
│   └── totalDurationText ("Total: HH:MM:SS")
├── kpsFrame (Kills/DPS display)
│   ├── kpsText ("Kills/s: X.XX")
│   ├── kphText ("Kills/h: XXX")
│   └── dpsText ("DPS: X.XX") -- Same line, right of kills/h
├── scrollFrame (Scroll container)
│   └── scrollChild (Mob list)
│       └── emptyText ("Kill mobs to start tracking...")
└── resizeButton (Resize handle, bottom right)
```

---

### 5. UI/Settings.lua

**Path:** `Libs/UI/Settings.lua`

**Purpose:** Settings dialogue, checkboxes, sliders, confirmation dialogue

**See [CLAUDE_DEVELOPMENT.md](CLAUDE_DEVELOPMENT.md) for settings development details.**

---

### 6. UI/Tracker.lua

**Path:** `Libs/UI/Tracker.lua`

**Purpose:** Mob list, accordion entries, entry pool system

**Exports:**
- `FTT:UpdateDisplay()` - Update mob list (main function!)
- `FTT:GetEntry(index)` - Get entry from pool/create
- `FTT:ResizeEntries()` - Resize all entries to new width
- `FTT:CollapseTracker()` - Collapse tracker
- `FTT:ExpandTracker()` - Expand tracker

**Entry Pool System:**
```lua
-- Reusable frames (performance optimisation)
FTT.entryPool = {}

function FTT:GetEntry(index)
    if not self.entryPool[index] then
        -- Creates new entry frame:
        local entry = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
        entry:SetSize(ENTRY_WIDTH, 25)
        -- ... setup header, hide button, details frame ...
        self.entryPool[index] = entry
    end
    return self.entryPool[index]
end
```

---

## Important Design Patterns

### 1. Entry Pool System

**Problem:** Performance issue with many mob entries (frame creation is expensive)

**Solution:** Reusable frame pool
- `FTT.entryPool[index]` stores all entries
- When hiding: Frame is recycled (not deleted)
- On next `UpdateDisplay()`: Existing entry is reused
- **Advantage:** No frame creation after initial creation

### 2. Heartbeat System

**Problem:** UpdateDisplay() can stop in rare cases (e.g., due to WoW error)

**Solution:** Heartbeat monitoring
- Every 30 seconds: `FTT:CheckHeartbeat()`
- Checks whether `lastUpdateTime` > 60 seconds old
- If yes + recent activity: Auto-refresh

### 3. Font Scaling

**Problem:** Large UI elements on small monitors, small text on large monitors

**Solution:** Dynamic font scaling
- User selects Small/Medium/Large
- `FTT:S(value)` scales all values
- `FTT:GetFont(size)` selects appropriate WoW fonts
- `FTT:ApplyFontScaling()` updates ALL UI elements **without reload**

### 4. Auto-Collapse/Expand

**Problem:** Too many old mobs clog the list

**Solution:** Auto-collapse system
- On kill: Mob is expanded (`FTT.expandedMobs[mobName] = true`)
- After 5 minutes: Mob is automatically collapsed
- On addon load: All mobs >5 min are collapsed
- **User override:** User can manually expand (stays until session end)

### 5. Inactive Toggle

**Problem:** Old mobs (>5 min) clog list, but user sometimes wants to see them

**Solution:** Separator with toggle button
- Mobs >5 min = "Inactive"
- Separator shows count of inactive mobs
- Button: "Show Older" / "Hide Older"
- Inactive mobs have 40% opacity (visually dimmed)

### 6. Item Highlighting

**Problem:** User farms specific item and wants to track it across all mobs

**Solution:** Persistent item highlighting
- User clicks pencil button (activates highlight mode)
- User clicks item (saved as `highlightedItemID`)
- Item gets pulsing glow effect (animation)
- Highlighted items ignore quality filter (ALWAYS shown)
- Highlight persists across sessions (saved in DB)

### 7. Quality Filter

**Problem:** User wants to see only rare items (Green+, Blue+, Purple+)

**Solution:** Quality slider with smart filtering
- Slider: All, Green+, Blue+, Purple+
- Filters items in `UpdateDisplay()`
- **Exception:** Highlighted items are ALWAYS shown
- Mobs without visible items are automatically hidden

### 8. Transparent Mode

**Problem:** Border hides game world, user wants more visibility

**Solution:** Transparent mode with opacity slider
- Normal mode: Border + 85% background
- Transparent mode: No border + 0-30% background (3 levels)
- Scrollbar is hidden in transparent mode (otherwise looks odd)

---

## Performance Optimisations

### 1. Entry Pool
- Reduces frame creation to initial creation
- Recycles frames instead of creating new ones

### 2. Width Calculation
- Uses temporary FontString (`measureText`) for measuring
- Caches measurements for session

### 3. Loot Assignment
- Uses `C_Loot.GetLootSourceInfo()` for exact mob assignment (Area Loot)
- Fallback queue for older WoW versions

### 4. AoE Tracking
- `damagedMobs` table tracks all damaged mobs
- Cleanup after 10 seconds (prevents memory leak)

### 5. Update Throttling
- `UpdateDurationDisplay()` only every 1 second
- `UpdateDisplay()` only on relevant events (not every second)

### 6. pcall Wrapper
- `UpdateDisplay()` is wrapped in pcall()
- On error: Heartbeat recovery activates

---

## Data Structure (SavedVariables)

**Variable:** `FizzlebeesTreasureTrackerDB`

**Structure:**
```lua
FizzlebeesTreasureTrackerDB = {
    mobs = {
        ["Mob Name 1"] = {
            kills = 42,
            lastKillTime = 1234567890,  -- time() (Unix timestamp)
            zoneID = 2112,  -- C_Map.GetBestMapForUnit("player")
            autoExpanded = true,
            loot = {
                ["Item Name 1"] = {
                    count = 5,
                    link = "|cffa335ee|Hitem:12345...|h[Item Name 1]|h|r"
                },
                -- ...
            }
        },
        -- ...
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

    totalGold = 123456,       -- Copper
    totalDuration = 7200,     -- Seconds
    totalDamage = 9876543,    -- Total damage dealt

    totalQuality = {
        green = 42,
        blue = 12,
        purple = 3,
        orange = 0
    },

    settings = {
        -- ... (see Core.lua for complete list)
    }
}
```

---

**For API reference, see [CLAUDE_API.md](CLAUDE_API.md)**
**For development workflow, see [CLAUDE_DEVELOPMENT.md](CLAUDE_DEVELOPMENT.md)**
**For main documentation, see [CLAUDE.md](CLAUDE.md)**

---

*This documentation follows BBC English standards as specified in Golden Rule #5.*
