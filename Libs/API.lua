-- ============================================================================
-- Fizzlebee's Treasure Tracker - Public API
-- Copyright (c) 2025 Vivian Voss (Fizzlebee) <Boulder Dash Heroes>
-- Licensed under the BSD 3-Clause License (see LICENSE file)
-- ============================================================================
-- PUBLIC API for other addons to integrate with FTT
--
-- Usage from other addons:
--   local FTT_API = _G.FizzlebeesTreasureTracker_API
--   if FTT_API then
--       local scale = FTT_API:GetFontScale()
--       local font = FTT_API:GetFont("Normal")
--   end
-- ============================================================================

local addonName, addon = ...
local FTT = _G.FizzlebeesTreasureTracker

-- ============================================================================
-- API TABLE
-- ============================================================================

local FTT_API = {}
_G.FizzlebeesTreasureTracker_API = FTT_API

-- API Version (for compatibility checking)
FTT_API.VERSION = "1.0.0"
FTT_API.API_VERSION = 1

-- ============================================================================
-- FONT SCALING
-- ============================================================================

-- Scale multipliers for UI elements
-- 0 = Klein (-12%), 1 = Mittel (default), 2 = Groß (+12%)
FTT.SCALE_MULTIPLIERS = {[0] = 0.88, [1] = 1.0, [2] = 1.12}

---
-- Get scaled value based on current font scale setting
-- @param value (number) The base value to scale
-- @return (number) The scaled value (rounded to integer)
-- @usage local scaledHeight = FTT:S(25)  -- Returns 22, 25, or 28 depending on scale
function FTT:S(value)
    local scale = self.settings.fontScale or 1
    return math.floor(value * self.SCALE_MULTIPLIERS[scale])
end

---
-- Get appropriate font object for current scale
-- @param size (string) Font size: "L" (Large), "N" (Normal), "S" (Small), "H" (Highlight)
-- @return (string) WoW font object name
-- @usage local font = FTT:GetFont("N")  -- Returns "GameFontNormal" for medium scale
function FTT:GetFont(size)
    local scale = self.settings.fontScale or 1
    local fonts = {
        [0] = {  -- Klein (-12%)
            L = "GameFontNormal",           -- Large
            N = "GameFontNormalSmall",      -- Normal
            S = "GameFontNormalTiny",       -- Small
            H = "GameFontHighlightSmall"    -- Highlight
        },
        [1] = {  -- Mittel (DEFAULT)
            L = "GameFontNormalLarge",
            N = "GameFontNormal",
            S = "GameFontNormalSmall",
            H = "GameFontHighlight"
        },
        [2] = {  -- Groß (+12%)
            L = "GameFontNormalHuge",
            N = "GameFontNormalLarge",
            S = "GameFontNormal",
            H = "GameFontHighlightLarge"
        }
    }
    return fonts[scale][size] or fonts[1][size]  -- Fallback to medium
end

-- ============================================================================
-- PUBLIC API FUNCTIONS (for other addons)
-- ============================================================================

---
-- Get current font scale setting
-- @return (number) 0=Klein, 1=Mittel, 2=Groß
function FTT_API:GetFontScale()
    return FTT.settings and FTT.settings.fontScale or 1
end

---
-- Get scale multiplier for current setting
-- @return (number) Multiplier (0.88, 1.0, or 1.12)
function FTT_API:GetScaleMultiplier()
    local scale = self:GetFontScale()
    return FTT.SCALE_MULTIPLIERS[scale]
end

---
-- Scale a value based on current font scale
-- @param value (number) Base value
-- @return (number) Scaled value
function FTT_API:ScaleValue(value)
    return FTT:S(value)
end

---
-- Get font object name for current scale
-- @param size (string) "Large", "Normal", "Small", or "Highlight"
-- @return (string) Font object name
function FTT_API:GetFont(size)
    local shortSize = {
        Large = "L",
        Normal = "N",
        Small = "S",
        Highlight = "H"
    }
    return FTT:GetFont(shortSize[size] or "N")
end

---
-- Get all available font sizes for current scale
-- @return (table) {Large="...", Normal="...", Small="...", Highlight="..."}
function FTT_API:GetAllFonts()
    return {
        Large = self:GetFont("Large"),
        Normal = self:GetFont("Normal"),
        Small = self:GetFont("Small"),
        Highlight = self:GetFont("Highlight")
    }
end

---
-- Check if FTT is loaded and ready
-- @return (boolean) true if addon is ready
function FTT_API:IsReady()
    return FTT and FTT.settings ~= nil
end

---
-- Get current settings (read-only copy)
-- @return (table) Copy of current settings
function FTT_API:GetSettings()
    if not FTT or not FTT.settings then return {} end

    -- Return a shallow copy to prevent external modifications
    local copy = {}
    for key, value in pairs(FTT.settings) do
        copy[key] = value
    end
    return copy
end

---
-- Register a callback for when settings change
-- @param callback (function) Function to call when settings change
-- @param event (string|nil) Specific setting to watch, or nil for all
-- @return (number) Callback ID (for unregistering)
function FTT_API:RegisterSettingsCallback(callback, event)
    if not FTT.apiCallbacks then
        FTT.apiCallbacks = {}
        FTT.apiCallbackID = 0
    end

    FTT.apiCallbackID = FTT.apiCallbackID + 1
    FTT.apiCallbacks[FTT.apiCallbackID] = {
        callback = callback,
        event = event
    }

    return FTT.apiCallbackID
end

---
-- Unregister a settings callback
-- @param callbackID (number) ID returned from RegisterSettingsCallback
function FTT_API:UnregisterSettingsCallback(callbackID)
    if FTT.apiCallbacks then
        FTT.apiCallbacks[callbackID] = nil
    end
end

---
-- Fire callbacks when settings change (internal use)
-- @param settingKey (string) The setting that changed
function FTT:FireAPICallbacks(settingKey)
    if not self.apiCallbacks then return end

    for id, data in pairs(self.apiCallbacks) do
        if not data.event or data.event == settingKey then
            local success, err = pcall(data.callback, settingKey, self.settings[settingKey])
            if not success then
                print("|cffFF0000FTT API Error:|r Callback failed: " .. tostring(err))
            end
        end
    end
end

-- ============================================================================
-- ADDON INTEGRATION HELPERS
-- ============================================================================

---
-- Create a frame that inherits FTT's font scaling
-- @param frameType (string) Frame type (e.g., "Frame", "Button")
-- @param parent (frame) Parent frame
-- @param template (string|nil) Frame template
-- @return (frame) Created frame with FTT scaling
function FTT_API:CreateScaledFrame(frameType, parent, template)
    local frame = CreateFrame(frameType, nil, parent, template)

    -- Add scaling helper methods
    frame.FTT_S = function(value) return FTT:S(value) end
    frame.FTT_GetFont = function(size) return FTT_API:GetFont(size) end

    return frame
end

---
-- Create a FontString with FTT scaling
-- @param parent (frame) Parent frame
-- @param size (string) "Large", "Normal", or "Small"
-- @return (fontstring) Created fontstring
function FTT_API:CreateScaledFontString(parent, size)
    local font = self:GetFont(size or "Normal")
    return parent:CreateFontString(nil, "OVERLAY", font)
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

---
-- Get addon version
-- @return (string) Version string
function FTT_API:GetVersion()
    return self.VERSION
end

---
-- Get API version (for compatibility)
-- @return (number) API version number
function FTT_API:GetAPIVersion()
    return self.API_VERSION
end

---
-- Print debug info about FTT state
function FTT_API:DebugInfo()
    print("|cffFFD700FTT API Debug Info:|r")
    print("  Version: " .. self.VERSION)
    print("  API Version: " .. self.API_VERSION)
    print("  Ready: " .. tostring(self:IsReady()))
    if self:IsReady() then
        print("  Font Scale: " .. self:GetFontScale())
        print("  Scale Multiplier: " .. self:GetScaleMultiplier())
        local fonts = self:GetAllFonts()
        print("  Fonts:")
        for size, font in pairs(fonts) do
            print("    " .. size .. ": " .. font)
        end
    end
end

-- ============================================================================
-- COMPATIBILITY & MIGRATION
-- ============================================================================

---
-- Check if API version is compatible
-- @param requiredVersion (number) Minimum API version required
-- @return (boolean) true if compatible
function FTT_API:IsCompatible(requiredVersion)
    return self.API_VERSION >= requiredVersion
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Export internal functions to FTT namespace (for internal use)
-- This allows FTT's own code to use the same scaling functions
FTT.GetFont = FTT.GetFont or function(self, size) return FTT_API:GetFont(size) end
FTT.S = FTT.S or function(self, value) return FTT_API:ScaleValue(value) end

print("|cffFFD700FTT:|r API " .. FTT_API.VERSION .. " loaded (API v" .. FTT_API.API_VERSION .. ")")
