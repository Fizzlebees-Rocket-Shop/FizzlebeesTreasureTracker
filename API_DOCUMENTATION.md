# Fizzlebee's Treasure Tracker - API Documentation

**Version:** 1.0.0
**API Version:** 1

---

## Overview

FTT provides a public API that allows other addons to integrate with its font scaling system and settings. This enables consistent UI styling across multiple addons.

---

## Getting Started

### Check if FTT is available

```lua
local FTT_API = _G.FizzlebeesTreasureTracker_API

if not FTT_API then
    print("FTT is not installed!")
    return
end

-- Check if ready (settings loaded)
if not FTT_API:IsReady() then
    print("FTT is loading...")
    return
end

-- Check API compatibility
if not FTT_API:IsCompatible(1) then
    print("FTT API version is too old!")
    return
end
```

---

## Font Scaling

### Get Current Font Scale

```lua
local scale = FTT_API:GetFontScale()
-- Returns: 0 (Klein), 1 (Mittel), 2 (Groß)

local multiplier = FTT_API:GetScaleMultiplier()
-- Returns: 0.88, 1.0, or 1.12
```

### Scale Values

```lua
-- Scale any numeric value based on user's font scale setting
local scaledHeight = FTT_API:ScaleValue(25)
-- Returns: 22 (klein), 25 (mittel), or 28 (groß)

local scaledPadding = FTT_API:ScaleValue(10)
-- Returns: 9, 10, or 11
```

### Get Font Objects

```lua
-- Get single font
local font = FTT_API:GetFont("Normal")
-- Options: "Large", "Normal", "Small", "Highlight"
-- Returns: WoW font object name (e.g., "GameFontNormal")

-- Get all fonts at once
local fonts = FTT_API:GetAllFonts()
-- Returns: {Large="...", Normal="...", Small="...", Highlight="..."}
```

**Font Size Mapping:**

| User Setting | Large | Normal | Small | Highlight |
|-------------|-------|--------|-------|-----------|
| Klein (0) | GameFontNormal | GameFontNormalSmall | GameFontNormalTiny | GameFontHighlightSmall |
| Mittel (1) | GameFontNormalLarge | GameFontNormal | GameFontNormalSmall | GameFontHighlight |
| Groß (2) | GameFontNormalHuge | GameFontNormalLarge | GameFontNormal | GameFontHighlightLarge |

---

## Settings Access

### Read Settings

```lua
-- Get copy of all settings (read-only)
local settings = FTT_API:GetSettings()

-- Access specific setting
if settings.transparentMode then
    print("FTT is in transparent mode")
end
```

**Available Settings:**
- `fontScale` (number): 0, 1, or 2
- `transparentMode` (boolean)
- `backgroundOpacity` (number): 0, 1, or 2
- `autoSize` (boolean)
- `lockPosition` (boolean)
- `filterByZone` (boolean)
- `showDebug` (boolean)
- `showInactiveMobs` (boolean)

### Watch for Changes

```lua
-- Register callback for all setting changes
local callbackID = FTT_API:RegisterSettingsCallback(function(settingKey, newValue)
    print("Setting changed: " .. settingKey .. " = " .. tostring(newValue))
end)

-- Register callback for specific setting
local fontCallbackID = FTT_API:RegisterSettingsCallback(function(settingKey, newValue)
    print("Font scale changed to: " .. newValue)
    -- Update your addon's UI here
end, "fontScale")

-- Unregister when done
FTT_API:UnregisterSettingsCallback(callbackID)
```

---

## Helper Functions

### Create Scaled Frames

```lua
-- Create a frame that automatically uses FTT scaling
local myFrame = FTT_API:CreateScaledFrame("Frame", UIParent)

-- Use built-in scaling helpers
myFrame:SetSize(myFrame.FTT_S(300), myFrame.FTT_S(200))
```

### Create Scaled FontStrings

```lua
-- Create a fontstring with FTT's font
local text = FTT_API:CreateScaledFontString(myFrame, "Normal")
text:SetPoint("CENTER")
text:SetText("Hello from another addon!")
```

---

## Complete Example: Integrated Addon

```lua
-- MyAddon.lua
local addonName = "MyAddon"
local FTT_API = _G.FizzlebeesTreasureTracker_API

-- Create main frame
local frame = CreateFrame("Frame", addonName .. "Frame", UIParent, "BackdropTemplate")
frame:SetPoint("CENTER")

-- Function to update UI when FTT settings change
local function UpdateUI()
    if not FTT_API or not FTT_API:IsReady() then
        -- Fallback values if FTT not available
        frame:SetSize(300, 200)
        return
    end

    -- Use FTT's scaling
    local scale = FTT_API:ScaleValue
    frame:SetSize(scale(300), scale(200))

    -- Use FTT's fonts
    if not frame.title then
        frame.title = FTT_API:CreateScaledFontString(frame, "Large")
        frame.title:SetPoint("TOP", 0, scale(-10))
        frame.title:SetText("My Addon")
    end

    if not frame.text then
        frame.text = FTT_API:CreateScaledFontString(frame, "Normal")
        frame.text:SetPoint("CENTER")
        frame.text:SetText("Using FTT scaling!")
    end
end

-- Initial setup
UpdateUI()

-- Listen for FTT setting changes
if FTT_API then
    FTT_API:RegisterSettingsCallback(function(settingKey, newValue)
        if settingKey == "fontScale" then
            UpdateUI()  -- Rebuild UI when font scale changes
        end
    end, "fontScale")
end
```

---

## Utility Functions

### Version Information

```lua
-- Get addon version
local version = FTT_API:GetVersion()
-- Returns: "1.0.0"

-- Get API version (for compatibility)
local apiVersion = FTT_API:GetAPIVersion()
-- Returns: 1
```

### Debug Information

```lua
-- Print debug info to chat
FTT_API:DebugInfo()
-- Output:
--   FTT API Debug Info:
--     Version: 1.0.0
--     API Version: 1
--     Ready: true
--     Font Scale: 1
--     Scale Multiplier: 1.0
--     Fonts:
--       Large: GameFontNormalLarge
--       Normal: GameFontNormal
--       Small: GameFontNormalSmall
--       Highlight: GameFontHighlight
```

---

## Best Practices

### 1. Always Check Availability

```lua
local FTT_API = _G.FizzlebeesTreasureTracker_API
if not FTT_API or not FTT_API:IsReady() then
    -- Use fallback values
    return
end
```

### 2. Provide Fallbacks

```lua
local function GetScaledValue(value)
    if FTT_API and FTT_API:IsReady() then
        return FTT_API:ScaleValue(value)
    else
        return value  -- No scaling if FTT not available
    end
end
```

### 3. Clean Up Callbacks

```lua
-- On addon disable/logout
local function OnDisable()
    if myCallbackID then
        FTT_API:UnregisterSettingsCallback(myCallbackID)
    end
end
```

### 4. Respect User Settings

```lua
-- Don't modify FTT settings directly
-- ❌ BAD:
_G.FizzlebeesTreasureTracker.settings.fontScale = 2

-- ✅ GOOD: Only read settings
local settings = FTT_API:GetSettings()
if settings.fontScale == 2 then
    -- Adapt your UI
end
```

---

## Error Handling

```lua
-- Wrap API calls in pcall for safety
local success, result = pcall(function()
    return FTT_API:GetFont("Normal")
end)

if success then
    myFontString:SetFontObject(result)
else
    print("Error accessing FTT API: " .. tostring(result))
    myFontString:SetFontObject("GameFontNormal")  -- Fallback
end
```

---

## Changelog

### Version 1.0.0 (API v1)
- Initial public API release
- Font scaling system
- Settings callbacks
- Helper functions for frame/fontstring creation

---

## Support

- **Issues:** Report bugs related to the API
- **Author:** Fizzlebee (Vivian Voss) - Boulder Dash Heroes
- **License:** BSD 3-Clause

---

## Example Use Cases

### 1. Tooltip Addon Integration
```lua
-- Scale tooltip font based on FTT settings
local function FormatTooltip(tooltip)
    if FTT_API and FTT_API:IsReady() then
        GameTooltip:SetFontObject(FTT_API:GetFont("Small"))
    end
end
```

### 2. Custom Frame Scaling
```lua
-- Create a settings panel that matches FTT's scale
local panel = CreateFrame("Frame", nil, UIParent)
local S = FTT_API.ScaleValue

panel:SetSize(S(400), S(300))
-- All child elements use S() for consistent scaling
```

### 3. Dynamic Font Updates
```lua
-- Update fonts when user changes FTT settings
FTT_API:RegisterSettingsCallback(function()
    for _, fontString in pairs(myAddonFonts) do
        fontString:SetFontObject(FTT_API:GetFont("Normal"))
    end
end, "fontScale")
```
