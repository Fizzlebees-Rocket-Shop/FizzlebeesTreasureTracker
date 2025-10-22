-- ============================================================================
-- Fizzlebee's Treasure Tracker - Events Module
-- Copyright (c) 2025 Vivian Voss (Fizzlebee) <Boulder Dash Heroes>
-- Licensed under the BSD 3-Clause License (see LICENSE file)
-- ============================================================================
-- DEPENDENCIES:
--   - Core.lua: FTT:RecordKill(), FTT:RecordLoot(), FTT:DebugPrint(), FTT:FormatMoney()
--   - UI.lua: FTT:UpdateDisplay(), FTT:UpdateGoldDisplay()
-- EXPORTS:
--   - Event Handlers (registered automatically via WoW event system)
-- ============================================================================

local addonName, addon = ...
local FTT = _G.FizzlebeesTreasureTracker

-- ============================================================================
-- LOCAL VARIABLES
-- ============================================================================

local currentTarget = nil
local recentKills = {} -- Track recent kills with timestamps
local goldQueue = {} -- Separate queue for gold tracking
local damagedMobs = {} -- Track all mobs we've damaged (for AoE)
local currentLootTarget = nil -- The mob being looted right now
local LOOT_WINDOW = 5 -- Seconds window to associate loot with kills
local DAMAGE_WINDOW = 10 -- Seconds to remember damaged mobs

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get the next mob to loot
-- Used for fallback when C_Loot.GetLootSourceInfo is not available
local function GetNextLootTarget()
    -- Clean up old kills (older than LOOT_WINDOW seconds)
    local currentTime = GetTime()
    local i = 1
    while i <= #recentKills do
        if currentTime - recentKills[i].time > LOOT_WINDOW then
            table.remove(recentKills, i)
        else
            i = i + 1
        end
    end

    -- Return the most recent kill (if any)
    if #recentKills > 0 then
        local target = recentKills[1].name
        table.remove(recentKills, 1) -- Remove it so next loot goes to next mob
        return target
    end

    -- Fallback to currentTarget
    return currentTarget
end

-- ============================================================================
-- EVENT FRAME & HANDLERS
-- ============================================================================

local eventFrame = CreateFrame("Frame")

-- Register events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("LOOT_CLOSED")
eventFrame:RegisterEvent("CHAT_MSG_MONEY")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- Main event handler
eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- ========================================================================
    -- ADDON_LOADED
    -- ========================================================================
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            FTT:Initialize()  -- → Libs/Core.lua (loads settings from DB)
            FTT:InitializeSettings()  -- → Libs/UI/Settings.lua (sets UI AND applies settings)
            FTT:UpdateHeaderLayout()  -- → Libs/Core.lua (updates header line positions based on settings)
            FTT:UpdateGoldDisplay()  -- → Libs/UI/Main.lua
            FTT:UpdateQualityDisplay()  -- → Libs/UI/Main.lua
            FTT:UpdateDurationDisplay()  -- → Libs/UI/Main.lua
            -- Note: InitializeSettings() calls UpdateSettingsUI() and ApplySettings()
            -- ApplySettings() calls UpdateDisplay() internally

            -- Start heartbeat monitoring timer (checks every 30 seconds)
            FTT.heartbeatTimer = C_Timer.NewTicker(30, function()
                FTT:CheckHeartbeat()
            end)
        end

    -- ========================================================================
    -- COMBAT_LOG_EVENT_UNFILTERED - Track damage and kills
    -- ========================================================================
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName = CombatLogGetCurrentEventInfo()

        -- Clean up old damaged mobs
        local currentTime = GetTime()
        for guid, data in pairs(damagedMobs) do
            if currentTime - data.time > DAMAGE_WINDOW then
                damagedMobs[guid] = nil
            end
        end

        -- Track damage from player (for AoE tracking and DPS calculation)
        local playerGUID = UnitGUID("player")
        if subEvent and destName and destGUID and sourceGUID == playerGUID then
            -- Don't track damage to self
            if destGUID ~= playerGUID then
                -- Track damage for all damage types
                if subEvent == "SWING_DAMAGE" or
                   subEvent == "SPELL_DAMAGE" or
                   subEvent == "RANGE_DAMAGE" or
                   subEvent == "SPELL_PERIODIC_DAMAGE" then
                    currentTarget = destName
                    -- Track ALL mobs we damage (for AoE)
                    damagedMobs[destGUID] = {
                        name = destName,
                        time = GetTime()
                    }

                    -- Extract damage amount safely using table unpacking
                    local combatInfo = {CombatLogGetCurrentEventInfo()}
                    local amount = nil

                    if subEvent == "SWING_DAMAGE" then
                        -- SWING_DAMAGE: position 12 is damage amount
                        amount = combatInfo[12]
                    else
                        -- SPELL_DAMAGE/RANGE_DAMAGE/SPELL_PERIODIC_DAMAGE: position 15 is damage amount
                        amount = combatInfo[15]
                    end

                    if amount and type(amount) == "number" and amount > 0 then
                        FTT.sessionDamage = FTT.sessionDamage + amount
                        FTT.totalDamage = FTT.totalDamage + amount
                    end
                end
            end
        end

        -- Track deaths - now tracks ALL mobs we damaged
        if subEvent == "UNIT_DIED" and destName and destGUID then
            -- Don't track player's own death (playerGUID already defined above)
            if destGUID ~= playerGUID then
                -- Check if we damaged this mob
                if damagedMobs[destGUID] then
                    FTT:RecordKill(destName)  -- → Libs/Core.lua:RecordKill()
                    -- Add to recent kills list with timestamp
                    table.insert(recentKills, {
                        name = destName,
                        time = GetTime()
                    })
                    -- Also add to gold queue for CHAT_MSG_MONEY tracking
                    table.insert(goldQueue, {
                        name = destName,
                        time = GetTime()
                    })
                    -- Remove from damaged list
                    damagedMobs[destGUID] = nil
                    FTT:UpdateDisplay()  -- → Libs/UI.lua:UpdateDisplay()
                end
            end
        end

    -- ========================================================================
    -- LOOT_OPENED - Process loot from killed mobs
    -- ========================================================================
    elseif event == "LOOT_OPENED" then
        -- Process loot - can contain items from multiple mobs (area loot)
        local numItems = GetNumLootItems()
        FTT:DebugPrint("|cffFF00FFFTT Debug:|r LOOT_OPENED - NumItems: " .. tostring(numItems))

        for i = 1, numItems do
            local itemLink = GetLootSlotLink(i)
            FTT:DebugPrint("|cffFF00FFFTT Debug:|r Slot " .. i .. " - itemLink: " .. tostring(itemLink))

            if itemLink then
                local texture, item, quantity, currencyID, quality, locked = GetLootSlotInfo(i)
                FTT:DebugPrint("|cffFF00FFFTT Debug:|r Slot " .. i .. " - quantity: " .. tostring(quantity))

                -- Try to get the source of this specific loot slot
                -- In area loot, different slots can be from different mobs
                local lootSourceInfo = nil
                local mobName = nil

                -- Check if C_Loot.GetLootSourceInfo exists
                if C_Loot and C_Loot.GetLootSourceInfo then
                    FTT:DebugPrint("|cffFF00FFFTT Debug:|r C_Loot.GetLootSourceInfo exists, calling it...")
                    local success, result = pcall(C_Loot.GetLootSourceInfo, i)
                    if success then
                        lootSourceInfo = result
                        FTT:DebugPrint("|cffFF00FFFTT Debug:|r Successfully called GetLootSourceInfo")
                    else
                        FTT:DebugPrint("|cffFF0000FTT Debug:|r Error calling GetLootSourceInfo: " .. tostring(result))
                    end
                else
                    FTT:DebugPrint("|cffFF0000FTT Debug:|r C_Loot.GetLootSourceInfo does not exist!")
                end

                if lootSourceInfo then
                    FTT:DebugPrint("|cffFF00FFFTT Debug:|r lootSourceInfo exists, name: " .. tostring(lootSourceInfo.name))
                else
                    FTT:DebugPrint("|cffFF00FFFTT Debug:|r lootSourceInfo is nil")
                end

                if lootSourceInfo and lootSourceInfo.name then
                    -- We have the exact mob name for this item!
                    mobName = lootSourceInfo.name
                    FTT:DebugPrint("|cffFF00FFFTT Debug:|r Using lootSourceInfo name: " .. mobName)
                else
                    -- Fallback: use next from queue
                    mobName = GetNextLootTarget()
                    FTT:DebugPrint("|cffFF00FFFTT Debug:|r Using GetNextLootTarget: " .. tostring(mobName))
                end

                if mobName then
                    FTT:DebugPrint("|cff00FF00FTT Debug:|r Recording loot: " .. itemLink .. " from " .. mobName)

                    -- Check if this is a new kill (important for group play)
                    -- If we're looting a mob that's not in our recent kills list, count it as a kill
                    local isNewKill = true
                    for _, killData in ipairs(recentKills) do
                        if killData.name == mobName then
                            isNewKill = false
                            break
                        end
                    end

                    -- If this is a new kill (e.g., someone else in group killed it), record it
                    if isNewKill then
                        FTT:RecordKill(mobName)
                        table.insert(recentKills, {
                            name = mobName,
                            time = GetTime()
                        })
                        FTT:DebugPrint("|cff00FF00FTT Debug:|r New group kill detected: " .. mobName)
                    end

                    FTT:RecordLoot(mobName, itemLink, quantity or 1)  -- → Libs/Core.lua:RecordLoot()
                else
                    FTT:DebugPrint("|cffFF0000FTT Debug:|r NO MOBNAME for slot " .. i)
                end
            end
        end
        FTT:UpdateDisplay()  -- → Libs/UI.lua:UpdateDisplay()
        FTT:UpdateQualityDisplay()  -- Update quality statistics

    -- ========================================================================
    -- LOOT_CLOSED
    -- ========================================================================
    elseif event == "LOOT_CLOSED" then
        -- Nothing to do - items were already tracked in LOOT_OPENED
        currentLootTarget = nil

    -- ========================================================================
    -- CHAT_MSG_MONEY - Track gold looted
    -- ========================================================================
    elseif event == "CHAT_MSG_MONEY" then
        -- Track total gold looted
        local message = ...
        if message then
            -- Parse gold amount from message
            -- German: "Ihr erhaltet Beute: 47 Silber 55 Kupfer" or "66 Silber 28 Kupfer"
            -- English: "You loot 1 Gold 23 Silver 45 Copper"

            local totalCopper = 0

            -- Try to find gold
            local gold = tonumber(message:match("(%d+)%s*Gold")) or tonumber(message:match("(%d+)%s*|cffffd700Gold|r"))
            if gold then
                totalCopper = totalCopper + (gold * 10000)
            end

            -- Try to find silver
            local silver = tonumber(message:match("(%d+)%s*Silber")) or tonumber(message:match("(%d+)%s*Silver")) or tonumber(message:match("(%d+)%s*|cffc7c7cfSilber|r"))
            if silver then
                totalCopper = totalCopper + (silver * 100)
            end

            -- Try to find copper/bronze
            local copper = tonumber(message:match("(%d+)%s*Kupfer")) or tonumber(message:match("(%d+)%s*Copper")) or tonumber(message:match("(%d+)%s*|cffeda55fKupfer|r"))
            if copper then
                totalCopper = totalCopper + copper
            end

            if totalCopper > 0 then
                FTT.sessionGold = FTT.sessionGold + totalCopper
                FTT.totalGold = FTT.totalGold + totalCopper
                FizzlebeesTreasureTrackerDB.totalGold = FTT.totalGold
                FTT:UpdateGoldDisplay()  -- → Libs/UI.lua:UpdateGoldDisplay()
                FTT:DebugPrint("|cff00FF00FTT Debug:|r Looted " .. FTT:FormatMoney(totalCopper))
            end
        end

    -- ========================================================================
    -- ZONE_CHANGED_NEW_AREA
    -- ========================================================================
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        -- Update display when zone changes (to filter mobs by zone if enabled)
        if FTT.settings and FTT.settings.filterByZone then
            FTT:UpdateDisplay()  -- → Libs/UI.lua:UpdateDisplay()
        end

    -- ========================================================================
    -- PLAYER_LOGOUT - Save session data
    -- ========================================================================
    elseif event == "PLAYER_LOGOUT" then
        -- Save total duration before logout
        if FTT.sessionStartTime > 0 then
            local sessionDuration = GetTime() - FTT.sessionStartTime
            FTT.totalDuration = FTT.totalDuration + sessionDuration
            FizzlebeesTreasureTrackerDB.totalDuration = FTT.totalDuration
        end

        -- Save total damage before logout
        FizzlebeesTreasureTrackerDB.totalDamage = FTT.totalDamage

        -- Save total quality counts before logout
        FizzlebeesTreasureTrackerDB.totalQuality = FTT.totalQuality

        -- Note: We now use time() (Unix timestamps) instead of GetTime()
        -- No need to save lastGetTime anymore
    end
end)
