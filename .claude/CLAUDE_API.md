# Fizzlebee's Treasure Tracker - Public API Documentation

**This document is mandatory reading for addon developers integrating with FTT.**

For main documentation, see [CLAUDE.md](CLAUDE.md)

---

## Overview

FTT provides a public API for other addons to integrate with font scaling and settings. This allows third-party addons to:
- Match FTT's font scaling
- React to FTT settings changes
- Create UI elements that automatically scale with FTT
- Access FTT's version information

**API Namespace:** `FizzlebeesTreasureTracker_API` (global table)

**Short Alias:** `FTT_API` (recommended for code readability)

---

## Quick Start

```lua
-- Check if FTT API is available
local FTT_API = _G.FizzlebeesTreasureTracker_API

if FTT_API and FTT_API:IsReady() then
    -- API is available, use it!
    local font = FTT_API:GetFont("Normal")
    local scaledHeight = FTT_API:ScaleValue(25)

    -- Register for settings changes
    FTT_API:RegisterSettingsCallback(function(key, value)
        print("FTT setting changed: " .. key .. " = " .. tostring(value))
    end)
else
    -- FTT not installed or not loaded yet
    print("FTT API not available")
end
```

---

## API Version

**Current API Version:** 1

The API version follows its own versioning scheme independent of FTT's SemVer version. Breaking changes to the API will increment this number.

```lua
FTT_API.VERSION = "1.0.0"      -- FTT addon version
FTT_API.API_VERSION = 1        -- API interface version
```

---

## Core Functions

### IsReady()

**Description:** Checks whether FTT is fully loaded and ready.

**Returns:** `boolean` - `true` if ready, `false` otherwise

**Example:**
```lua
if FTT_API and FTT_API:IsReady() then
    -- Safe to use API
end
```

**Note:** Always check this before using any other API functions.

---

### GetVersion()

**Description:** Returns FTT's current version string.

**Returns:** `string` - Version (e.g., "1.0.0")

**Example:**
```lua
local version = FTT_API:GetVersion()
print("FTT version: " .. version)  -- "FTT version: 1.0.0"
```

---

### GetAPIVersion()

**Description:** Returns the API interface version.

**Returns:** `number` - API version (e.g., 1)

**Example:**
```lua
local apiVersion = FTT_API:GetAPIVersion()
print("FTT API version: " .. apiVersion)  -- "FTT API version: 1"
```

---

### IsCompatible(requiredVersion)

**Description:** Checks whether the current API version is compatible with the required version.

**Parameters:**
- `requiredVersion` (number) - Required API version

**Returns:** `boolean` - `true` if compatible, `false` otherwise

**Example:**
```lua
if not FTT_API:IsCompatible(1) then
    print("ERROR: FTT API version mismatch! Please update FTT.")
    return
end
```

**Note:** API version compatibility follows a simple rule: current >= required.

---

## Font Scaling Functions

### GetFontScale()

**Description:** Returns the current font scale setting.

**Returns:** `number` - Font scale (0, 1, or 2)
- 0 = Small
- 1 = Medium (default)
- 2 = Large

**Example:**
```lua
local scale = FTT_API:GetFontScale()
if scale == 0 then
    print("FTT is using small fonts")
elseif scale == 1 then
    print("FTT is using medium fonts")
else
    print("FTT is using large fonts")
end
```

---

### GetScaleMultiplier()

**Description:** Returns the current scale multiplier based on font scale setting.

**Returns:** `number` - Multiplier (0.88, 1.0, or 1.12)

**Example:**
```lua
local multiplier = FTT_API:GetScaleMultiplier()
print("Current scale multiplier: " .. multiplier)
-- Output: "Current scale multiplier: 1.0" (if Medium selected)
```

**Multiplier Mapping:**
```lua
{
    [0] = 0.88,   -- Small
    [1] = 1.0,    -- Medium
    [2] = 1.12    -- Large
}
```

---

### ScaleValue(value)

**Description:** Scales a numeric value based on FTT's current font scale setting.

**Parameters:**
- `value` (number) - Value to scale

**Returns:** `number` - Scaled value (floored to integer)

**Example:**
```lua
local baseHeight = 25
local scaledHeight = FTT_API:ScaleValue(baseHeight)

-- If font scale is Medium (1.0):
-- scaledHeight = 25

-- If font scale is Large (1.12):
-- scaledHeight = 28  (25 * 1.12 = 28)

myFrame:SetHeight(scaledHeight)
```

---

### GetFont(size)

**Description:** Returns the appropriate WoW font object name for the given size category.

**Parameters:**
- `size` (string) - Font size category:
  - `"Large"` or `"L"` - Large headers
  - `"Normal"` or `"N"` - Normal text
  - `"Small"` or `"S"` - Small text
  - `"Highlight"` or `"H"` - Highlighted text

**Returns:** `string` - Font object name (e.g., "GameFontNormalLarge")

**Example:**
```lua
local fontNormal = FTT_API:GetFont("Normal")
myFontString:SetFontObject(fontNormal)

-- Or with shortcuts:
local fontLarge = FTT_API:GetFont("L")
headerText:SetFontObject(fontLarge)
```

**Font Selection Logic:**
```lua
-- Small scale (0.88):
{
    Large = "GameFontNormal",
    Normal = "GameFontNormalSmall",
    Small = "GameFontNormalSmall",
    Highlight = "GameFontHighlightSmall"
}

-- Medium scale (1.0):
{
    Large = "GameFontNormalLarge",
    Normal = "GameFontNormal",
    Small = "GameFontNormalSmall",
    Highlight = "GameFontHighlight"
}

-- Large scale (1.12):
{
    Large = "GameFontNormalHuge",
    Normal = "GameFontNormalLarge",
    Small = "GameFontNormal",
    Highlight = "GameFontHighlightLarge"
}
```

---

### GetAllFonts()

**Description:** Returns a table containing all font object names for the current scale.

**Returns:** `table` - Font table with keys: `Large`, `Normal`, `Small`, `Highlight`

**Example:**
```lua
local fonts = FTT_API:GetAllFonts()
print("Large font: " .. fonts.Large)
print("Normal font: " .. fonts.Normal)
print("Small font: " .. fonts.Small)
print("Highlight font: " .. fonts.Highlight)
```

---

## Settings Functions

### GetSettings()

**Description:** Returns a **copy** of FTT's current settings table.

**Returns:** `table` - Settings table (copy, not reference)

**Example:**
```lua
local settings = FTT_API:GetSettings()

if settings.transparentMode then
    print("FTT is in transparent mode")
end

if settings.fontScale == 2 then
    print("FTT is using large fonts")
end
```

**Available Settings:**
```lua
{
    transparentMode = false,      -- boolean
    backgroundOpacity = 0,        -- number (0-2)
    fontScale = 1,                -- number (0, 1, 2)
    autoSize = true,              -- boolean
    lockPosition = false,         -- boolean
    itemFilter = "",              -- string (item ID)
    filterByZone = true,          -- boolean
    showDebug = false,            -- boolean
    showInactiveMobs = true,      -- boolean
    highlightedItemID = nil,      -- string (item ID)
    minItemQuality = 0,           -- number (0-4)
    showGoldLine = true,          -- boolean
    showQualityLine = true,       -- boolean
    showDurationLine = true,      -- boolean
    showKillsLine = true          -- boolean
}
```

**Note:** This returns a **copy**, not a reference. Modifying the returned table will **not** affect FTT's settings.

---

### RegisterSettingsCallback(callback, [event])

**Description:** Registers a callback function to be called when FTT settings change.

**Parameters:**
- `callback` (function) - Function to call when settings change
  - Signature: `function(settingKey, newValue)`
- `event` (string, optional) - Specific setting key to watch (e.g., "fontScale")
  - If omitted, callback fires for **all** setting changes

**Returns:** `number` - Callback ID (use for unregistering)

**Example:**
```lua
-- Watch all settings changes:
local callbackID = FTT_API:RegisterSettingsCallback(function(key, value)
    print("FTT setting changed: " .. key .. " = " .. tostring(value))
end)

-- Watch only font scale changes:
local fontCallbackID = FTT_API:RegisterSettingsCallback(function(key, value)
    print("Font scale changed to: " .. value)
    -- Update your addon's UI here
    MyAddon:UpdateFontSizes()
end, "fontScale")
```

**Callback Signature:**
```lua
function callback(settingKey, newValue)
    -- settingKey: string (e.g., "fontScale")
    -- newValue: any (depends on setting type)
end
```

---

### UnregisterSettingsCallback(callbackID)

**Description:** Unregisters a previously registered settings callback.

**Parameters:**
- `callbackID` (number) - Callback ID returned by `RegisterSettingsCallback()`

**Returns:** `boolean` - `true` if successfully unregistered, `false` otherwise

**Example:**
```lua
local callbackID = FTT_API:RegisterSettingsCallback(myCallback, "fontScale")

-- Later, when you want to stop listening:
FTT_API:UnregisterSettingsCallback(callbackID)
```

---

## Helper Functions

### CreateScaledFrame(frameType, parent, [template])

**Description:** Creates a frame that automatically scales with FTT's font scale.

**Parameters:**
- `frameType` (string) - Frame type (e.g., "Frame", "Button")
- `parent` (frame) - Parent frame
- `template` (string, optional) - Template name

**Returns:** `frame` - Created frame

**Example:**
```lua
local myFrame = FTT_API:CreateScaledFrame("Frame", UIParent, "BackdropTemplate")
myFrame:SetSize(FTT_API:ScaleValue(200), FTT_API:ScaleValue(100))
```

**Note:** The frame itself doesn't auto-scale. You still need to apply `ScaleValue()` to sizes.

---

### CreateScaledFontString(parent, size)

**Description:** Creates a font string with FTT's current font for the given size.

**Parameters:**
- `parent` (frame) - Parent frame
- `size` (string) - Font size category ("Large", "Normal", "Small", "Highlight")

**Returns:** `fontstring` - Created font string

**Example:**
```lua
local text = FTT_API:CreateScaledFontString(myFrame, "Normal")
text:SetPoint("CENTER")
text:SetText("Hello, World!")
```

---

## Debug Function

### DebugInfo()

**Description:** Prints debug information about FTT API to chat.

**Returns:** `nil`

**Example:**
```lua
FTT_API:DebugInfo()
```

**Output:**
```
=== FTT API Debug Info ===
Version: 1.0.0
API Version: 1
Font Scale: 1 (Medium)
Scale Multiplier: 1.0
Fonts: {Large="GameFontNormalLarge", Normal="GameFontNormal", ...}
Settings: {transparentMode=false, fontScale=1, ...}
```

---

## Complete Example

Here's a complete example of an addon that integrates with FTT's API:

```lua
local addonName = "MyAddon"
local MyAddon = {}

-- Initialize FTT API integration
function MyAddon:InitializeFTTIntegration()
    local FTT_API = _G.FizzlebeesTreasureTracker_API

    if not FTT_API then
        print("[MyAddon] FTT not installed")
        return
    end

    if not FTT_API:IsReady() then
        print("[MyAddon] FTT not ready yet")
        return
    end

    -- Check API compatibility
    if not FTT_API:IsCompatible(1) then
        print("[MyAddon] FTT API version mismatch!")
        return
    end

    -- Get FTT's current font scale
    local fontScale = FTT_API:GetFontScale()
    print("[MyAddon] FTT is using font scale: " .. fontScale)

    -- Create a frame that matches FTT's scaling
    local frame = CreateFrame("Frame", "MyAddonFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FTT_API:ScaleValue(300), FTT_API:ScaleValue(200))

    -- Create text with FTT's font
    local text = frame:CreateFontString(nil, "OVERLAY", FTT_API:GetFont("Normal"))
    text:SetPoint("CENTER")
    text:SetText("Scaled with FTT!")

    -- Register for font scale changes
    FTT_API:RegisterSettingsCallback(function(key, value)
        if key == "fontScale" then
            print("[MyAddon] FTT font scale changed to: " .. value)
            self:UpdateFontSizes()
        end
    end, "fontScale")

    print("[MyAddon] Successfully integrated with FTT API v" .. FTT_API:GetVersion())
end

-- Update font sizes when FTT's scale changes
function MyAddon:UpdateFontSizes()
    local FTT_API = _G.FizzlebeesTreasureTracker_API
    if not FTT_API or not FTT_API:IsReady() then return end

    -- Update your UI elements here
    local newFont = FTT_API:GetFont("Normal")
    MyAddonFrame.text:SetFontObject(newFont)

    -- Resize frame
    MyAddonFrame:SetSize(
        FTT_API:ScaleValue(300),
        FTT_API:ScaleValue(200)
    )
end

-- Hook into ADDON_LOADED
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == "FizzlebeesTreasureTracker" then
        -- FTT just loaded, initialize integration
        MyAddon:InitializeFTTIntegration()
    end
end)
```

---

## API Callback Events

Settings callbacks fire for the following setting keys:

| Setting Key | Type | Description |
|-------------|------|-------------|
| `transparentMode` | boolean | Transparent mode toggle |
| `backgroundOpacity` | number | Background opacity (0-2) |
| `fontScale` | number | Font scale (0, 1, 2) |
| `autoSize` | boolean | Auto-size toggle |
| `lockPosition` | boolean | Position lock toggle |
| `itemFilter` | string | Item ID filter |
| `filterByZone` | boolean | Zone filter toggle |
| `showDebug` | boolean | Debug mode toggle |
| `showInactiveMobs` | boolean | Show inactive mobs toggle |
| `highlightedItemID` | string | Highlighted item ID |
| `minItemQuality` | number | Minimum item quality (0-4) |
| `showGoldLine` | boolean | Show gold line toggle |
| `showQualityLine` | boolean | Show quality line toggle |
| `showDurationLine` | boolean | Show duration line toggle |
| `showKillsLine` | boolean | Show kills line toggle |

---

## API Limitations

**What the API Does NOT Provide:**

1. **Direct access to kill/loot data** - FTT's internal data structures are not exposed
2. **Ability to modify FTT's settings** - Settings can only be read, not written
3. **Access to FTT's UI frames** - Internal frame references are not exposed
4. **Event hooks** - Cannot hook into FTT's internal event handlers

**Why These Limitations Exist:**

- **Data integrity**: Prevents external addons from corrupting FTT's data
- **Encapsulation**: Internal implementation can change without breaking API
- **Performance**: Reduces coupling between addons
- **Security**: Prevents malicious addons from interfering with FTT

---

## Changelog

### API Version 1 (FTT 1.0.0)

- Initial release
- Font scaling functions
- Settings callback system
- Helper functions for UI creation

---

**For architecture details, see [CLAUDE_ARCHITECTURE.md](CLAUDE_ARCHITECTURE.md)**
**For development workflow, see [CLAUDE_DEVELOPMENT.md](CLAUDE_DEVELOPMENT.md)**
**For main documentation, see [CLAUDE.md](CLAUDE.md)**

---

*This documentation follows BBC English standards as specified in Golden Rule #5.*
