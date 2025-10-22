-- ============================================================================
-- Fizzlebee's Treasure Tracker - Core Module
-- Copyright (c) 2025 Vivian Voss (Fizzlebee) <Boulder Dash Heroes>
-- Licensed under the BSD 3-Clause License (see LICENSE file)
-- ============================================================================
-- DEPENDENCIES:
--   - Locales/*.lua: L (localization table)
-- EXPORTS:
--   - FTT (global table)
--   - FTT:DebugPrint()
--   - FTT:FormatMoney()
--   - FTT:FormatDuration()
--   - FTT:RecordKill() → Used by Events.lua
--   - FTT:RecordLoot() → Used by Events.lua
--   - FTT:SaveSettings() → Used by UI.lua
--   - FTT:SavePosition() → Used by UI.lua
--   - FTT:SaveFrameSize() → Used by UI.lua
--   - FTT:RestorePosition() → Used by UI.lua
--   - FTT:RestoreFrameSize() → Used by UI.lua
-- ============================================================================

local addonName, addon = ...

-- ============================================================================
-- GLOBAL FTT TABLE & CONSTANTS
-- ============================================================================

-- Create global FTT table
local FTT = {}
_G.FizzlebeesTreasureTracker = FTT

-- Get localization table
local L = _G[addonName .. "_Locale"]
FTT.L = L

-- Layout Constants (change these to scale the entire UI)
FTT.ENTRY_WIDTH = 320  -- Width of accordion entries
FTT.SCROLLBAR_PADDING = 40  -- Scrollbar width
FTT.FRAME_PADDING = 70  -- Total frame padding (includes scrollbar + margins)
FTT.FRAME_WIDTH = FTT.ENTRY_WIDTH + FTT.FRAME_PADDING  -- 390px
FTT.ITEM_LEFT_OFFSET = 8  -- Left offset for item lines
FTT.ITEM_RIGHT_PADDING = 8  -- Right padding for item lines
FTT.ITEM_LINE_WIDTH = FTT.ENTRY_WIDTH - FTT.ITEM_RIGHT_PADDING  -- 312px
FTT.INFO_FRAME_WIDTH = FTT.ENTRY_WIDTH + 20  -- 340px (for gold/duration displays)

-- ============================================================================
-- SESSION & DATA TRACKING
-- ============================================================================

FTT.sessionKills = {} -- Track kills in current session
FTT.sessionLoot = {} -- Track loot in current session
FTT.sessionTreasureLootCount = {} -- Track number of treasure loot events per treasure in current session (treasures only!)
FTT.sessionGold = 0 -- Track total gold in session (in copper)
FTT.totalGold = 0 -- Track total gold overall (in copper)
FTT.sessionDamage = 0 -- Track total damage in session
FTT.totalDamage = 0 -- Track total damage overall
FTT.sessionQuality = {green = 0, blue = 0, purple = 0, orange = 0} -- Track item quality counts in session
FTT.totalQuality = {green = 0, blue = 0, purple = 0, orange = 0} -- Track item quality counts overall
FTT.sessionStartTime = 0 -- Track when session started (in seconds)
FTT.totalDuration = 0 -- Track total farming duration (in seconds)
FTT.expandedMobs = {} -- Track which mobs are expanded (mobName -> true/false)
FTT.hiddenMobs = {} -- Track which mobs are hidden for this session (mobName -> true)
FTT.hiddenItems = {} -- Track which items are hidden (itemName -> true)
FTT.entryPool = {} -- Pool of reusable entry frames for mob list (used by UI/Tracker.lua)
FTT.highlightedItemID = nil -- Track highlighted item ID (for visual emphasis across all mobs)
FTT.highlightMode = false -- Track if highlight mode is active (waiting for user to select item)

-- Heartbeat system for auto-recovery
FTT.lastUpdateTime = 0 -- Track last successful UpdateDisplay() call
FTT.heartbeatEnabled = true -- Enable/disable heartbeat monitoring

-- Default settings
FTT.settings = {
    transparentMode = false,  -- Transparent mode (no border/background when enabled)
    backgroundOpacity = 0,  -- Background opacity: 0 = 0% black, 1 = 15% black, 2 = 30% black (only when transparentMode is true)
    fontScale = 1,  -- Font scale: 0 = Klein (-12%), 1 = Mittel (default), 2 = Groß (+12%)
    autoSize = true,  -- Auto-size both width and height (when disabled, shows resize handle) - DEFAULT: ON
    lockPosition = false,
    itemFilter = "",
    filterByZone = true,  -- Filter mobs by current zone - DEFAULT: ON
    showDebug = false,
    showInactiveMobs = true,  -- Show mobs older than 5 minutes
    highlightedItemID = nil,  -- Highlighted item ID (persists across sessions)
    minItemQuality = 0,  -- Minimum item quality to display: 0 = All, 2 = Green, 3 = Blue, 4 = Purple (highlighted item always shows)
    showGoldLine = true,  -- Show gold line in header - DEFAULT: ON
    showQualityLine = true,  -- Show quality statistics line in header - DEFAULT: ON
    showDurationLine = true,  -- Show duration line in header - DEFAULT: ON
    showKillsLine = true  -- Show kills/s, kills/h, and DPS line in header - DEFAULT: ON
}

-- ============================================================================
-- FONT SCALING SYSTEM
-- ============================================================================

-- Scale multipliers for UI elements
-- 0 = Klein (-12%), 1 = Mittel (default), 2 = Groß (+12%)
FTT.SCALE_MULTIPLIERS = {[0] = 0.88, [1] = 1.0, [2] = 1.12}

---
-- Get scaled value based on current font scale setting
-- @param value (number) The base value to scale
-- @return (number) The scaled value (rounded to integer)
function FTT:S(value)
    local scale = self.settings.fontScale or 1
    return math.floor(value * self.SCALE_MULTIPLIERS[scale])
end

---
-- Get appropriate font object for current scale
-- @param size (string) Font size: "L" (Large), "N" (Normal), "S" (Small), "H" (Highlight)
-- @return (string) WoW font object name
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

---
-- Apply font scaling to all UI elements dynamically (without reload)
-- CALLED BY: Settings.lua when fontScale slider changes
function FTT:ApplyFontScaling()
    -- Main UI FontStrings
    if self.titleText then self.titleText:SetFontObject(self:GetFont("L")) end
    if self.sessionGoldText then self.sessionGoldText:SetFontObject(self:GetFont("S")) end
    if self.totalGoldText then self.totalGoldText:SetFontObject(self:GetFont("S")) end
    if self.sessionQualityText then self.sessionQualityText:SetFontObject(self:GetFont("S")) end
    if self.totalQualityText then self.totalQualityText:SetFontObject(self:GetFont("S")) end
    if self.kpsText then self.kpsText:SetFontObject(self:GetFont("S")) end
    if self.kphText then self.kphText:SetFontObject(self:GetFont("S")) end
    if self.dpsText then self.dpsText:SetFontObject(self:GetFont("S")) end
    if self.sessionDurationText then self.sessionDurationText:SetFontObject(self:GetFont("S")) end
    if self.totalDurationText then self.totalDurationText:SetFontObject(self:GetFont("S")) end
    if self.emptyText then self.emptyText:SetFontObject(self:GetFont("N")) end

    -- Tracker entries (mob list) - these are created dynamically
    if self.entryPool then
        for _, entry in pairs(self.entryPool) do
            if entry.icon then entry.icon:SetFontObject(self:GetFont("L")) end
            if entry.text then entry.text:SetFontObject(self:GetFont("N")) end

            -- Item lines in expanded entries
            if entry.details and entry.details.lines then
                for _, lineButton in pairs(entry.details.lines) do
                    if lineButton.nameText then lineButton.nameText:SetFontObject(self:GetFont("S")) end
                    if lineButton.countText then lineButton.countText:SetFontObject(self:GetFont("S")) end
                    if lineButton.ratioText then lineButton.ratioText:SetFontObject(self:GetFont("S")) end
                end
            end
        end
    end

    -- Inactive toggle button
    if self.inactiveToggleButton and self.inactiveToggleButton.text then
        self.inactiveToggleButton.text:SetFontObject(self:GetFont("S"))
    end

    -- Refresh display to apply any layout changes
    if self.UpdateDisplay then
        self:UpdateDisplay()
    end
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Helper function for debug prints
-- USAGE: FTT:DebugPrint("message")
-- IMPORTANT: Always use this for debug messages, never raw print()!
function FTT:DebugPrint(...)
    if self.settings and self.settings.showDebug then
        print(...)
    end
end

-- Info print helper (always prints, for important user-facing messages)
-- USAGE: FTT:InfoPrint("message")
-- Use for: Load messages, migration notices, important warnings
function FTT:InfoPrint(...)
    print(...)
end

-- Heartbeat checker - monitors addon health and auto-recovers if needed
function FTT:CheckHeartbeat()
    if not self.heartbeatEnabled then
        return
    end

    -- Check if UpdateDisplay has been called in the last 60 seconds
    local currentTime = GetTime()
    local timeSinceLastUpdate = currentTime - self.lastUpdateTime

    -- If more than 60 seconds without an update AND we have active data, try to recover
    if timeSinceLastUpdate > 60 and FizzlebeesTreasureTrackerDB and FizzlebeesTreasureTrackerDB.mobs then
        -- Check if we actually have any recent kills (last 5 minutes)
        local hasRecentActivity = false
        for mobName, mobData in pairs(FizzlebeesTreasureTrackerDB.mobs) do
            if mobData.lastKillTime and (currentTime - mobData.lastKillTime) < 300 then
                hasRecentActivity = true
                break
            end
        end

        -- Only auto-refresh if there's recent activity (to avoid false positives)
        if hasRecentActivity then
            self:DebugPrint("|cffFFD700FTT Heartbeat:|r No updates for " .. math.floor(timeSinceLastUpdate) .. "s, auto-refreshing...")
            self:DebugPrint("|cffFFD700FTT:|r Display auto-refreshed (heartbeat recovery)")

            -- Perform refresh
            if self.UpdateGoldDisplay then self:UpdateGoldDisplay() end
            if self.UpdateDurationDisplay then self:UpdateDurationDisplay() end
            if self.UpdateDisplay then self:UpdateDisplay() end
        end
    end
end

-- Function to format money with icons (copper to gold/silver/copper display)
-- CALLED BY: UI.lua (UpdateGoldDisplay)
function FTT:FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local bronze = copper % 100

    local text = ""
    if gold > 0 then
        text = text .. gold .. "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t "
    end
    if silver > 0 or gold > 0 then
        text = text .. silver .. "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t "
    end
    if bronze > 0 or (gold == 0 and silver == 0) then
        text = text .. bronze .. "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t"
    end

    return text
end

-- Function to format duration (seconds to HH:MM:SS)
-- CALLED BY: UI.lua (UpdateDurationDisplay)
function FTT:FormatDuration(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- ============================================================================
-- DATA MANAGEMENT FUNCTIONS
-- ============================================================================

-- Record a mob kill
-- CALLED BY: Events.lua (COMBAT_LOG_EVENT_UNFILTERED handler)
function FTT:RecordKill(mobName)
    if not mobName or mobName == "" then return end

    -- Start session timer on first kill
    if self.sessionStartTime == 0 then
        self.sessionStartTime = GetTime()
    end

    local mobs = FizzlebeesTreasureTrackerDB.mobs

    -- Get current zone/map ID
    local currentMapID = C_Map.GetBestMapForUnit("player")

    if not mobs[mobName] then
        mobs[mobName] = {
            kills = 0,
            loot = {},
            lastKillTime = 0,
            zoneID = currentMapID
        }
    end

    -- Increment total kills
    mobs[mobName].kills = mobs[mobName].kills + 1

    -- Update last kill time and zone (using Unix timestamp now)
    mobs[mobName].lastKillTime = time()
    mobs[mobName].zoneID = currentMapID  -- Update zone in case mob moves

    -- Increment session kills
    if not self.sessionKills[mobName] then
        self.sessionKills[mobName] = 0
    end
    self.sessionKills[mobName] = self.sessionKills[mobName] + 1

    -- Auto-expand the mob that was just killed
    self.expandedMobs[mobName] = true

    -- Auto-collapse mobs older than 5 minutes (300 seconds)
    local currentTime = time()
    for checkMobName, checkMobData in pairs(mobs) do
        if checkMobData.lastKillTime and checkMobData.lastKillTime > 0 and (currentTime - checkMobData.lastKillTime) > 300 then
            -- Collapse this mob
            self.expandedMobs[checkMobName] = false
        end
    end
end

-- Record loot from a mob or treasure
-- CALLED BY: Events.lua (LOOT_OPENED handler)
function FTT:RecordLoot(mobName, itemID, itemLink, quantity, isTreasure)
    self:DebugPrint("|cffFFFF00FTT RecordLoot:|r mobName=" .. tostring(mobName) .. ", itemID=" .. tostring(itemID) .. ", itemLink=" .. tostring(itemLink) .. ", quantity=" .. tostring(quantity) .. ", isTreasure=" .. tostring(isTreasure))

    if not mobName or not itemID then
        self:DebugPrint("|cffFF0000FTT RecordLoot:|r Early return - mobName or itemID is nil")
        return
    end

    -- Start session timer on first loot
    if self.sessionStartTime == 0 then
        self.sessionStartTime = GetTime()
        self:DebugPrint("|cffFFFF00FTT RecordLoot:|r Started session timer")
    end

    -- Get current zone for treasure/mob tracking
    local currentMapID = C_Map.GetBestMapForUnit("player")

    local mobs = FizzlebeesTreasureTrackerDB.mobs
    if not mobs[mobName] then
        -- Create new entry for treasure or mob
        mobs[mobName] = {
            kills = 0,
            loot = {},
            isTreasure = isTreasure or false,
            lastSeen = time(),
            lootCount = 0,  -- Track number of loot events for treasures
            zoneID = currentMapID  -- Store zone ID for filtering
        }
        self:DebugPrint("|cffFFFF00FTT RecordLoot:|r Created new entry for " .. mobName .. " (isTreasure=" .. tostring(isTreasure) .. ", zoneID=" .. tostring(currentMapID) .. ")")
    else
        -- Entry exists, ensure isTreasure flag is set if this is treasure loot
        if isTreasure and not mobs[mobName].isTreasure then
            mobs[mobName].isTreasure = true
            self:DebugPrint("|cffFFFF00FTT RecordLoot:|r Updated isTreasure flag for existing entry: " .. mobName)
        end
    end

    -- Update lastSeen, lootCount, and zoneID for treasures (they don't have lastKillTime or kills)
    if isTreasure then
        mobs[mobName].lastSeen = time()
        mobs[mobName].lootCount = (mobs[mobName].lootCount or 0) + 1
        mobs[mobName].zoneID = currentMapID  -- Update zone in case player moves

        -- Track session treasure loot count (number of treasure chests opened this session)
        if not self.sessionTreasureLootCount[mobName] then
            self.sessionTreasureLootCount[mobName] = 0
        end
        self.sessionTreasureLootCount[mobName] = self.sessionTreasureLootCount[mobName] + 1

        self:DebugPrint("|cffFFFF00FTT RecordLoot:|r Updated lastSeen and lootCount for treasure: " .. mobName .. " (sessionTreasureLootCount=" .. self.sessionTreasureLootCount[mobName] .. ", totalLootCount=" .. mobs[mobName].lootCount .. ", zoneID=" .. tostring(currentMapID) .. ")")
    end

    -- CRITICAL: Use itemID as database key for consistency
    -- itemID is always stable (e.g., "12345"), unlike itemLink which varies by format
    -- Store itemLink for display purposes only
    local itemName = GetItemInfo(itemLink) or itemID  -- For display/debug purposes
    self:DebugPrint("|cffFFFF00FTT RecordLoot:|r itemName: " .. tostring(itemName) .. ", itemID: " .. tostring(itemID))

    local loot = mobs[mobName].loot

    -- Initialize total loot tracking (use itemID as key)
    if not loot[itemID] then
        loot[itemID] = {
            count = 0,
            link = itemLink  -- Store link for display
        }
        self:DebugPrint("|cffFFFF00FTT RecordLoot:|r Created new loot entry for " .. itemName)
    end

    -- Increment total loot count
    loot[itemID].count = loot[itemID].count + (quantity or 1)
    self:DebugPrint("|cffFFFF00FTT RecordLoot:|r Total count for " .. itemName .. ": " .. loot[itemID].count)

    -- Track session loot (use itemID as key)
    if not self.sessionLoot[mobName] then
        self.sessionLoot[mobName] = {}
    end
    if not self.sessionLoot[mobName][itemID] then
        self.sessionLoot[mobName][itemID] = 0
    end
    self.sessionLoot[mobName][itemID] = self.sessionLoot[mobName][itemID] + (quantity or 1)
    self:DebugPrint("|cffFFFF00FTT RecordLoot:|r Session count for " .. itemName .. ": " .. self.sessionLoot[mobName][itemID])

    -- Track item quality statistics
    local _, _, itemQuality = GetItemInfo(itemLink)
    if itemQuality then
        local qty = quantity or 1
        if itemQuality == 2 then -- Uncommon (Green)
            self.sessionQuality.green = self.sessionQuality.green + qty
            self.totalQuality.green = self.totalQuality.green + qty
        elseif itemQuality == 3 then -- Rare (Blue)
            self.sessionQuality.blue = self.sessionQuality.blue + qty
            self.totalQuality.blue = self.totalQuality.blue + qty
        elseif itemQuality == 4 then -- Epic (Purple)
            self.sessionQuality.purple = self.sessionQuality.purple + qty
            self.totalQuality.purple = self.totalQuality.purple + qty
        elseif itemQuality == 5 then -- Legendary (Orange)
            self.sessionQuality.orange = self.sessionQuality.orange + qty
            self.totalQuality.orange = self.totalQuality.orange + qty
        end
    end

    -- Auto-expand this mob's entry when first item is looted
    if not mobs[mobName].autoExpanded then
        mobs[mobName].autoExpanded = true
        self:DebugPrint("|cffFFFF00FTT RecordLoot:|r Auto-expanded " .. mobName)
    end
end

-- Record gold from a mob or treasure
-- CALLED BY: Events.lua (LOOT_OPENED handler for gold slots)
function FTT:RecordGold(mobName, amount)
    self:DebugPrint("|cffFFD700FTT RecordGold:|r mobName=" .. tostring(mobName) .. ", amount=" .. tostring(amount))

    if not mobName or not amount or amount <= 0 then
        self:DebugPrint("|cffFF0000FTT RecordGold:|r Early return - invalid parameters")
        return
    end

    local mobs = FizzlebeesTreasureTrackerDB.mobs

    -- Ensure mob entry exists
    if not mobs[mobName] then
        mobs[mobName] = {
            kills = 0,
            loot = {},
            gold = 0,  -- Total gold from this mob
            sessionGold = 0,  -- Gold in current session
            isTreasure = mobName:match("^Treasure Find ") and true or false,
            lastSeen = time(),
            lootCount = 0
        }
        self:DebugPrint("|cffFFD700FTT RecordGold:|r Created new entry for " .. mobName)
    end

    -- Initialize gold fields if they don't exist (for old entries)
    if not mobs[mobName].gold then
        mobs[mobName].gold = 0
    end
    if not mobs[mobName].sessionGold then
        mobs[mobName].sessionGold = 0
    end

    -- Track gold
    mobs[mobName].gold = mobs[mobName].gold + amount
    mobs[mobName].sessionGold = mobs[mobName].sessionGold + amount

    self:DebugPrint("|cffFFD700FTT RecordGold:|r Updated gold for " .. mobName .. " - session: " .. self:FormatMoney(mobs[mobName].sessionGold) .. ", total: " .. self:FormatMoney(mobs[mobName].gold))
end

-- Update header layout based on visibility settings
-- CALLED BY: Settings.lua when header line checkboxes change
function FTT:UpdateHeaderLayout()
    if not self.goldFrame then return end  -- Not initialized yet

    local currentY = -5  -- Start position after title
    local lineHeight = 20

    -- Gold line
    if self.settings.showGoldLine then
        self.goldFrame:Show()
        self.goldFrame:ClearAllPoints()
        self.goldFrame:SetPoint("TOPLEFT", self.titleText, "BOTTOMLEFT", 0, currentY)
        currentY = currentY - lineHeight
    else
        self.goldFrame:Hide()
    end

    -- Quality line
    if self.settings.showQualityLine then
        self.qualityFrame:Show()
        self.qualityFrame:ClearAllPoints()
        if self.settings.showGoldLine then
            self.qualityFrame:SetPoint("TOPLEFT", self.goldFrame, "BOTTOMLEFT", 0, 0)
        else
            self.qualityFrame:SetPoint("TOPLEFT", self.titleText, "BOTTOMLEFT", 0, currentY)
        end
        currentY = currentY - lineHeight
    else
        self.qualityFrame:Hide()
    end

    -- Duration line
    if self.settings.showDurationLine then
        self.durationFrame:Show()
        self.durationFrame:ClearAllPoints()
        -- Find the last visible frame above this
        if self.settings.showQualityLine then
            self.durationFrame:SetPoint("TOPLEFT", self.qualityFrame, "BOTTOMLEFT", 0, 0)
        elseif self.settings.showGoldLine then
            self.durationFrame:SetPoint("TOPLEFT", self.goldFrame, "BOTTOMLEFT", 0, 0)
        else
            self.durationFrame:SetPoint("TOPLEFT", self.titleText, "BOTTOMLEFT", 0, currentY)
        end
        currentY = currentY - lineHeight
    else
        self.durationFrame:Hide()
    end

    -- Kills line
    if self.settings.showKillsLine then
        self.kpsFrame:Show()
        self.kpsFrame:ClearAllPoints()
        -- Find the last visible frame above this
        if self.settings.showDurationLine then
            self.kpsFrame:SetPoint("TOPLEFT", self.durationFrame, "BOTTOMLEFT", 0, 0)
        elseif self.settings.showQualityLine then
            self.kpsFrame:SetPoint("TOPLEFT", self.qualityFrame, "BOTTOMLEFT", 0, 0)
        elseif self.settings.showGoldLine then
            self.kpsFrame:SetPoint("TOPLEFT", self.goldFrame, "BOTTOMLEFT", 0, 0)
        else
            self.kpsFrame:SetPoint("TOPLEFT", self.titleText, "BOTTOMLEFT", 0, currentY)
        end
        currentY = currentY - lineHeight
    else
        self.kpsFrame:Hide()
    end

    -- Reposition scrollFrame after the last visible header line
    self.scrollFrame:ClearAllPoints()
    if self.settings.showKillsLine then
        self.scrollFrame:SetPoint("TOPLEFT", self.kpsFrame, "BOTTOMLEFT", 0, -10)
    elseif self.settings.showDurationLine then
        self.scrollFrame:SetPoint("TOPLEFT", self.durationFrame, "BOTTOMLEFT", 0, -10)
    elseif self.settings.showQualityLine then
        self.scrollFrame:SetPoint("TOPLEFT", self.qualityFrame, "BOTTOMLEFT", 0, -10)
    elseif self.settings.showGoldLine then
        self.scrollFrame:SetPoint("TOPLEFT", self.goldFrame, "BOTTOMLEFT", 0, -10)
    else
        self.scrollFrame:SetPoint("TOPLEFT", self.titleText, "BOTTOMLEFT", 0, -10)
    end
    self.scrollFrame:SetPoint("BOTTOMRIGHT", -40, 20)
end

-- Recalculate total quality counts from database
-- CALLED BY: Initialize() when totalQuality is all zeros
function FTT:RecalculateQualityFromDatabase()
    local quality = {green = 0, blue = 0, purple = 0, orange = 0}

    -- Iterate through all mobs in database
    for mobName, mobData in pairs(FizzlebeesTreasureTrackerDB.mobs) do
        if mobData.loot then
            -- Iterate through all loot items
            for itemName, lootData in pairs(mobData.loot) do
                local _, _, itemQuality = GetItemInfo(lootData.link)
                if itemQuality then
                    local count = lootData.count or 0
                    if itemQuality == 2 then -- Uncommon (Green)
                        quality.green = quality.green + count
                    elseif itemQuality == 3 then -- Rare (Blue)
                        quality.blue = quality.blue + count
                    elseif itemQuality == 4 then -- Epic (Purple)
                        quality.purple = quality.purple + count
                    elseif itemQuality == 5 then -- Legendary (Orange)
                        quality.orange = quality.orange + count
                    end
                end
            end
        end
    end

    -- Update totalQuality and save to DB
    self.totalQuality = quality
    FizzlebeesTreasureTrackerDB.totalQuality = quality

    self:DebugPrint(string.format("Recalculated quality from DB: Green=%d, Blue=%d, Purple=%d, Orange=%d",
        quality.green, quality.blue, quality.purple, quality.orange))
end

-- ============================================================================
-- SETTINGS PERSISTENCE
-- ============================================================================

-- Save settings to database
-- CALLED BY: UI.lua (Settings checkboxes, item filter)
function FTT:SaveSettings()
    FizzlebeesTreasureTrackerDB.settings = self.settings
end

-- Save frame position
-- CALLED BY: UI.lua (OnDragStop)
function FTT:SavePosition()
    local frame = _G["FizzlebeesTreasureTrackerFrame"]
    if not frame then return end

    local point, _, relativePoint, x, y = frame:GetPoint()
    FizzlebeesTreasureTrackerDB.position = {
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y
    }
end

-- Restore frame position
-- CALLED BY: UI.lua (Initialize)
function FTT:RestorePosition()
    local frame = _G["FizzlebeesTreasureTrackerFrame"]
    if not frame then return end

    local pos = FizzlebeesTreasureTrackerDB.position
    if pos and pos.point then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    end
end

-- Save frame size
-- CALLED BY: UI.lua (OnSizeChanged)
function FTT:SaveFrameSize(width, height)
    if not FizzlebeesTreasureTrackerDB.frameSize then
        FizzlebeesTreasureTrackerDB.frameSize = {}
    end
    FizzlebeesTreasureTrackerDB.frameSize.width = width
    FizzlebeesTreasureTrackerDB.frameSize.height = height
end

-- Restore frame size
-- CALLED BY: UI.lua (Initialize)
function FTT:RestoreFrameSize()
    local frame = _G["FizzlebeesTreasureTrackerFrame"]
    if not frame then return end

    local size = FizzlebeesTreasureTrackerDB.frameSize
    if size and size.width and size.height then
        frame:SetSize(size.width, size.height)
    end
end

-- ============================================================================
-- TIME MANAGEMENT (Fix for Patch 11.0.5)
-- ============================================================================

-- Use time() (Unix timestamp) instead of GetTime() for persistence
-- time() returns seconds since Unix epoch and is never reset by WoW
-- GetTime() returns seconds since WoW started and CAN be reset by patches

-- Function to get current timestamp (Unix time)
function FTT:GetCurrentTime()
    return time()
end

-- Function to migrate old GetTime()-based timestamps to time()-based timestamps
function FTT:MigrateTimestamps()
    local mobs = FizzlebeesTreasureTrackerDB.mobs
    if not mobs then return end

    local currentUnixTime = time()
    local migratedCount = 0

    -- Detect old GetTime()-based timestamps (they are much smaller than Unix time)
    -- Unix time is ~1.7 billion seconds (since 1970)
    -- GetTime() is usually < 1 million seconds (since WoW start)
    local UNIX_TIME_THRESHOLD = 1000000000  -- ~2001-09-09 (way before WoW existed)

    for mobName, mobData in pairs(mobs) do
        if mobData.lastKillTime and mobData.lastKillTime < UNIX_TIME_THRESHOLD then
            -- This is an old GetTime()-based timestamp, mark as very old
            mobData.lastKillTime = 0
            migratedCount = migratedCount + 1
        end
    end

    if migratedCount > 0 then
        -- This is an important user-facing message about data migration
        self:InfoPrint("|cffFFD700FTT:|r |cffFF6600Migrated " .. migratedCount .. " old timestamps to new system.|r")
        self:InfoPrint("|cffFFD700FTT:|r Old mobs from before patch 11.0.5 are now marked as inactive.")
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

-- Initialize database and load saved data
-- CALLED BY: Init.lua (ADDON_LOADED event)
function FTT:Initialize()
    -- Initialize saved variables
    if not FizzlebeesTreasureTrackerDB then
        FizzlebeesTreasureTrackerDB = {
            mobs = {},
            position = nil,
            totalGold = 0,
            totalDuration = 0,
            totalDamage = 0,
            totalQuality = {green = 0, blue = 0, purple = 0, orange = 0},
            settings = {}
        }
    end

    -- Migrate old GetTime()-based timestamps to time()-based timestamps (Patch 11.0.5 fix)
    self:MigrateTimestamps()

    -- Ensure mobs table exists
    if not FizzlebeesTreasureTrackerDB.mobs then
        FizzlebeesTreasureTrackerDB.mobs = {}
    end

    -- Ensure totalGold exists
    if not FizzlebeesTreasureTrackerDB.totalGold then
        FizzlebeesTreasureTrackerDB.totalGold = 0
    end

    -- Ensure totalDuration exists
    if not FizzlebeesTreasureTrackerDB.totalDuration then
        FizzlebeesTreasureTrackerDB.totalDuration = 0
    end

    -- Ensure totalDamage exists
    if not FizzlebeesTreasureTrackerDB.totalDamage then
        FizzlebeesTreasureTrackerDB.totalDamage = 0
    end

    -- Ensure totalQuality exists
    if not FizzlebeesTreasureTrackerDB.totalQuality then
        FizzlebeesTreasureTrackerDB.totalQuality = {green = 0, blue = 0, purple = 0, orange = 0}
    end

    -- Ensure settings table exists
    if not FizzlebeesTreasureTrackerDB.settings then
        FizzlebeesTreasureTrackerDB.settings = {}
    end

    -- Migrate old settings to new names (for backwards compatibility)
    local dbSettings = FizzlebeesTreasureTrackerDB.settings

    -- Migrate showBorder -> transparentMode (inverted logic!)
    if dbSettings.showBorder ~= nil and dbSettings.transparentMode == nil then
        dbSettings.transparentMode = not dbSettings.showBorder  -- Inverted!
        dbSettings.showBorder = nil  -- Remove old key
    end

    -- Migrate autoHeight + autoWidth -> autoSize
    if (dbSettings.autoHeight ~= nil or dbSettings.autoWidth ~= nil) and dbSettings.autoSize == nil then
        -- Only enable autoSize if BOTH were true
        dbSettings.autoSize = (dbSettings.autoHeight == true and dbSettings.autoWidth == true)
        dbSettings.autoHeight = nil  -- Remove old keys
        dbSettings.autoWidth = nil
    end

    -- Merge DB settings with defaults (DB settings take precedence)
    -- This preserves user settings while adding new defaults for missing keys
    for key, defaultValue in pairs(self.settings) do
        if dbSettings[key] ~= nil then
            -- Use saved value from DB
            self.settings[key] = dbSettings[key]
        else
            -- Use default value and save it to DB
            dbSettings[key] = defaultValue
        end
    end

    -- Load highlighted item ID DIRECTLY from DB (bypass settings merge issue)
    -- This ensures the highlighted item persists across sessions
    if dbSettings.highlightedItemID then
        self.highlightedItemID = dbSettings.highlightedItemID
        -- Also update settings to match
        self.settings.highlightedItemID = dbSettings.highlightedItemID
        self:DebugPrint("Loaded highlighted item ID: " .. tostring(self.highlightedItemID))
    else
        self.highlightedItemID = nil
    end

    -- Load total gold from DB
    self.totalGold = FizzlebeesTreasureTrackerDB.totalGold or 0
    self.sessionGold = 0

    -- Load total duration from DB
    self.totalDuration = FizzlebeesTreasureTrackerDB.totalDuration or 0
    self.sessionStartTime = 0

    -- Load total damage from DB
    self.totalDamage = FizzlebeesTreasureTrackerDB.totalDamage or 0
    self.sessionDamage = 0

    -- Load total quality from DB
    self.totalQuality = FizzlebeesTreasureTrackerDB.totalQuality or {green = 0, blue = 0, purple = 0, orange = 0}
    self.sessionQuality = {green = 0, blue = 0, purple = 0, orange = 0}

    -- If totalQuality is all zeros but database has loot, recalculate from database
    if self.totalQuality.green == 0 and self.totalQuality.blue == 0 and
       self.totalQuality.purple == 0 and self.totalQuality.orange == 0 then
        self:RecalculateQualityFromDatabase()
    end

    -- Auto-collapse all mobs from previous sessions (older than 5 minutes)
    local currentTime = time()
    local INACTIVE_THRESHOLD = 300  -- 5 minutes
    if FizzlebeesTreasureTrackerDB.mobs then
        for mobName, mobData in pairs(FizzlebeesTreasureTrackerDB.mobs) do
            -- For treasures, use lastSeen; for mobs, use lastKillTime
            local isTreasure = mobData.isTreasure or mobName:match("^Treasure Find ")
            local lastActivity = isTreasure and (mobData.lastSeen or 0) or (mobData.lastKillTime or 0)
            local timeSince = currentTime - lastActivity

            -- If no lastActivity (old data) or older than 5 minutes, collapse
            if lastActivity == 0 or timeSince > INACTIVE_THRESHOLD then
                self.expandedMobs[mobName] = false
            end
        end
    end

    -- Load message (important user-facing message)
    self:InfoPrint("|cffFFD700" .. L["TITLE"] .. "|r " .. L["LOADED_MESSAGE"])
end
