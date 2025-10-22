-- Fizzlebee's Treasure Tracker - English (Default) Locale
local addonName = ...

-- Create locale table with metatable for missing keys
local L = setmetatable({}, {
    __index = function(t, k)
        return k -- Fallback: return the key itself if translation missing
    end
})

-- General
L["TITLE"] = "Fizzlebee's Treasure Tracker"
L["CLOSE"] = "Close"
L["RESET"] = "Reset Data"
L["SESSION"] = "Session"
L["TOTAL"] = "Total"
L["DURATION"] = "Duration"
L["KILLS_PER_SECOND"] = "Kills/s"
L["KILLS_PER_HOUR"] = "Kills/h"
L["DAMAGE_PER_SECOND"] = "DPS"
L["SETTINGS"] = "Settings"
L["COLLAPSE"] = "Collapse"
L["EXPAND"] = "Expand"
L["CLEAR"] = "Clear"
L["CONFIRM"] = "Confirm"
L["CANCEL"] = "Cancel"

-- Item Filter
L["ITEM_FILTER"] = "Item Filter (Item-ID)"
L["ITEM_FILTER_HINT"] = "Hides all items except this ID"

-- Treasure
L["TREASURE_NAME"] = "Treasure %s"  -- %s = zone name

-- Settings
L["FILTER_BY_ZONE"] = "Filter by Zone"
L["SHOW_INACTIVE"] = "Show Older"
L["HIDE_INACTIVE"] = "Hide Older"
L["TRANSPARENT_MODE"] = "Transparent Mode"
L["BACKGROUND_OPACITY"] = "Background Opacity"
L["FONT_SCALE"] = "Font Size"
L["MIN_ITEM_QUALITY"] = "Minimum Item Quality"
L["QUALITY_ALL"] = "All"
L["QUALITY_GREEN"] = "Green+"
L["QUALITY_BLUE"] = "Blue+"
L["QUALITY_PURPLE"] = "Purple+"
L["AUTO_SIZE"] = "Auto Size"
L["LOCK_POSITION"] = "Lock Position"
L["SHOW_ALL_HIDDEN"] = "Show Hidden"
L["SHOW_DEBUG"] = "Debug Mode"
L["SHOW_GOLD_LINE"] = "Show Gold Line"
L["SHOW_QUALITY_LINE"] = "Show Quality Line"
L["SHOW_DURATION_LINE"] = "Show Duration Line"
L["SHOW_KILLS_LINE"] = "Show Kills Line"
L["SHOW_DPS_LINE"] = "Show DPS Line"

-- Tooltips & Messages
L["HIDE_MOB_TOOLTIP"] = "Hide this mob for current session"
L["HIGHLIGHT_ITEM_TOOLTIP"] = "Highlight an item to watch. Click the button and then select your desired item."
L["HIGHLIGHT_MODE_ACTIVE"] = "Highlight mode active - Click an item to mark it"
L["ITEM_HIGHLIGHTED"] = "Item highlighted"
L["ITEM_UNHIGHLIGHTED"] = "Item highlight removed"
L["PER_KILL"] = "per kill"
L["LOADED_MESSAGE"] = "loaded! Use /ftt to toggle"
L["ALL_DATA_RESET"] = "All data reset"
L["ALL_HIDDEN_RESTORED"] = "All hidden mobs restored"
L["HIDING_MOB"] = "Hiding mob"
L["KILL_MOBS_TEXT"] = "Kill mobs to start tracking..."

-- Confirmation Dialog
L["RESET_CONFIRM_TITLE"] = "Reset Data"
L["RESET_CONFIRM_TEXT"] = "Are you sure you want to reset all data? This cannot be undone!"

-- Export locale table to global namespace
_G[addonName .. "_Locale"] = L
