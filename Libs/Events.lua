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
local L = _G[addonName .. "_Locale"]

-- ============================================================================
-- LOCAL VARIABLES
-- ============================================================================

local currentTarget = nil
local recentKills = {} -- Track recent kills with timestamps
local goldQueue = {} -- Separate queue for gold tracking
local damagedMobs = {} -- Track all mobs we've damaged (for AoE)
local currentLootTarget = nil -- The mob being looted right now
local currentLootGUID = nil -- The GUID of the loot source (captured in LOOT_READY)
local LOOT_WINDOW = 5 -- Seconds window to associate loot with kills
local DAMAGE_WINDOW = 10 -- Seconds to remember damaged mobs
local pendingItems = {} -- Items waiting for cache refresh to get proper itemID

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Process pending items that are waiting for itemID resolution
-- CALLED BY: OnUpdate timer (every 1 second)
local function ProcessPendingItems()
    if #pendingItems == 0 then
        return
    end

    local i = 1
    while i <= #pendingItems do
        local pending = pendingItems[i]
        local itemID = nil

        -- Try to extract itemID from the stored itemLink
        itemID = pending.itemLink:match("|Hitem:(%d+)")
        if not itemID then
            itemID = pending.itemLink:match("item:(%d+)")
        end
        if not itemID then
            -- Try GetItemInfoInstant with the full link
            local itemIDFromAPI = GetItemInfoInstant(pending.itemLink)
            if itemIDFromAPI then
                itemID = tostring(itemIDFromAPI)
            else
                -- Try with item name if link is in [Name] format
                local itemName = pending.itemLink:match("^%[(.+)%]$")
                if itemName then
                    itemIDFromAPI = GetItemInfoInstant(itemName)
                    if itemIDFromAPI then
                        itemID = tostring(itemIDFromAPI)
                    end
                end
            end
        end

        -- If we got an itemID, migrate the loot entry
        if itemID then
            FTT:DebugPrint("|cff00FF00ProcessPendingItems:|r Resolved itemID " .. itemID .. " for pending item " .. pending.itemLink)

            -- Get the mob's loot table
            local mobs = FizzlebeesTreasureTrackerDB.mobs
            if mobs[pending.mobName] and mobs[pending.mobName].loot then
                local loot = mobs[pending.mobName].loot

                -- Check if this item already exists under the old key
                if loot[pending.itemLink] then
                    -- Migrate: move from itemLink key to itemID key
                    if loot[itemID] then
                        -- Already exists with itemID key, merge counts
                        loot[itemID].count = loot[itemID].count + loot[pending.itemLink].count
                    else
                        -- Move to new key
                        loot[itemID] = loot[pending.itemLink]
                    end
                    -- Remove old key
                    loot[pending.itemLink] = nil

                    -- Update session loot as well
                    if FTT.sessionLoot[pending.mobName] then
                        if FTT.sessionLoot[pending.mobName][pending.itemLink] then
                            if FTT.sessionLoot[pending.mobName][itemID] then
                                FTT.sessionLoot[pending.mobName][itemID] = FTT.sessionLoot[pending.mobName][itemID] + FTT.sessionLoot[pending.mobName][pending.itemLink]
                            else
                                FTT.sessionLoot[pending.mobName][itemID] = FTT.sessionLoot[pending.mobName][pending.itemLink]
                            end
                            FTT.sessionLoot[pending.mobName][pending.itemLink] = nil
                        end
                    end

                    FTT:UpdateDisplay()
                end
            end

            -- Remove from pending list
            table.remove(pendingItems, i)
        else
            -- Still can't resolve, keep in list but check age
            if GetTime() - pending.timestamp > 30 then
                -- After 30 seconds, give up
                FTT:DebugPrint("|cffFF0000ProcessPendingItems:|r Giving up on pending item " .. pending.itemLink .. " after 30 seconds")
                table.remove(pendingItems, i)
            else
                i = i + 1
            end
        end
    end
end

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
eventFrame:RegisterEvent("LOOT_READY")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("LOOT_CLOSED")
eventFrame:RegisterEvent("CHAT_MSG_MONEY")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- OnUpdate handler for processing pending items
local timeSinceLastPendingCheck = 0
eventFrame:SetScript("OnUpdate", function(self, elapsed)
    timeSinceLastPendingCheck = timeSinceLastPendingCheck + elapsed
    if timeSinceLastPendingCheck >= 1.0 then  -- Check every 1 second
        ProcessPendingItems()
        timeSinceLastPendingCheck = 0
    end
end)

-- Main event handler
eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- ========================================================================
    -- ADDON_LOADED
    -- ========================================================================
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            FTT:Initialize()  -- → Libs/Core.lua (loads settings from DB)

            -- DATABASE MIGRATION v2: Add isTreasure flag to existing treasure entries (v1.1.0)
            if not FizzlebeesTreasureTrackerDB.dbVersion or FizzlebeesTreasureTrackerDB.dbVersion < 2 then
                local mobs = FizzlebeesTreasureTrackerDB.mobs
                if mobs then
                    local migratedCount = 0
                    for mobName, mobData in pairs(mobs) do
                        -- Check if this is a treasure entry by name pattern (legacy formats from all languages)
                        if mobName:match("^Schätze:") or mobName:match("^Schatz:") or mobName:match("^Schatzfund ")
                           or mobName:match("^Treasure Find ") or mobName:match("^Trouvaille de trésor ")
                           or mobName:match("^Hallazgo de tesoro ") or mobName:match("^Achado de tesouro ")
                           or mobName:match("^Находка сокровищ ") or mobName:match("^宝藏发现 ") or mobName:match("^寶藏發現 ")
                           or mobName:match("^보물 발견 ") or mobName:match("^Scoperta di tesori ") then
                            if not mobData.isTreasure then
                                mobData.isTreasure = true
                                -- Ensure lastSeen exists for old treasure entries
                                if not mobData.lastSeen then
                                    mobData.lastSeen = mobData.lastKillTime or time()
                                end
                                migratedCount = migratedCount + 1
                            end
                        end
                    end
                    if migratedCount > 0 then
                        FTT:InfoPrint("|cff00FF00FTT Migration v2:|r Updated " .. migratedCount .. " treasure entries")
                    end
                end
                FizzlebeesTreasureTrackerDB.dbVersion = 2
            end

            -- DATABASE MIGRATION v3: Migrate loot keys from itemName to itemLink (v1.1.0)
            if FizzlebeesTreasureTrackerDB.dbVersion < 3 then
                local mobs = FizzlebeesTreasureTrackerDB.mobs
                if mobs then
                    local totalItemsMigrated = 0
                    for mobName, mobData in pairs(mobs) do
                        if mobData.loot then
                            local newLoot = {}
                            local itemsMigrated = 0
                            for key, lootData in pairs(mobData.loot) do
                                -- Check if this is an old-style key (plain item name without link format)
                                if lootData.link and not key:match("|H") then
                                    -- This is old format: key is item name, not item link
                                    -- Use the stored link as the new key
                                    newLoot[lootData.link] = lootData
                                    itemsMigrated = itemsMigrated + 1
                                else
                                    -- Already new format or no link stored, keep as-is
                                    newLoot[key] = lootData
                                end
                            end
                            if itemsMigrated > 0 then
                                mobData.loot = newLoot
                                totalItemsMigrated = totalItemsMigrated + itemsMigrated
                                FTT:DebugPrint("|cff00FF00FTT Migration v3:|r Migrated " .. itemsMigrated .. " loot items for " .. mobName)
                            end
                        end
                    end
                    if totalItemsMigrated > 0 then
                        FTT:InfoPrint("|cff00FF00FTT Migration v3:|r Migrated " .. totalItemsMigrated .. " loot entries to itemLink keys")
                    end
                end
                FizzlebeesTreasureTrackerDB.dbVersion = 3
            end

            -- DATABASE MIGRATION v4: Migrate loot keys from itemLink to itemID (v1.1.0)
            if FizzlebeesTreasureTrackerDB.dbVersion < 4 then
                local mobs = FizzlebeesTreasureTrackerDB.mobs
                if mobs then
                    local totalItemsMigrated = 0
                    for mobName, mobData in pairs(mobs) do
                        if mobData.loot then
                            local newLoot = {}
                            local itemsMigrated = 0
                            for key, lootData in pairs(mobData.loot) do
                                -- Extract itemID from the stored link
                                local itemID = nil
                                if lootData.link then
                                    -- Try to extract from full link format: |Hitem:12345:...|h
                                    itemID = lootData.link:match("|Hitem:(%d+)")
                                    if not itemID then
                                        -- Try simple format: item:12345:...
                                        itemID = lootData.link:match("item:(%d+)")
                                    end
                                end

                                if itemID then
                                    -- Use itemID as new key
                                    newLoot[itemID] = lootData
                                    itemsMigrated = itemsMigrated + 1
                                else
                                    -- Could not extract itemID, keep old key
                                    newLoot[key] = lootData
                                    FTT:DebugPrint("|cffFF0000FTT Migration v4:|r Could not extract itemID from link: " .. tostring(lootData.link))
                                end
                            end
                            if itemsMigrated > 0 then
                                mobData.loot = newLoot
                                totalItemsMigrated = totalItemsMigrated + itemsMigrated
                                FTT:DebugPrint("|cff00FF00FTT Migration v4:|r Migrated " .. itemsMigrated .. " loot items to itemID keys for " .. mobName)
                            end
                        end
                    end
                    if totalItemsMigrated > 0 then
                        FTT:InfoPrint("|cff00FF00FTT Migration v4:|r Migrated " .. totalItemsMigrated .. " loot entries to itemID keys")
                    end
                end
                FizzlebeesTreasureTrackerDB.dbVersion = 4
            end

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
    -- LOOT_READY - Capture GUID before loot window opens
    -- ========================================================================
    elseif event == "LOOT_READY" then
        -- Try multiple methods to capture the GUID
        currentLootGUID = UnitGUID("target")

        -- If target doesn't work, try mouseover
        if not currentLootGUID then
            currentLootGUID = UnitGUID("mouseover")
        end

        if FTT.settings.showDebug then
            FTT:DebugPrint("|cff00FFFFTT Debug:|r LOOT_READY - Target GUID: " .. tostring(UnitGUID("target")))
            FTT:DebugPrint("|cff00FFFFTT Debug:|r LOOT_READY - Mouseover GUID: " .. tostring(UnitGUID("mouseover")))
            FTT:DebugPrint("|cff00FFFFTT Debug:|r LOOT_READY - Using GUID: " .. tostring(currentLootGUID))
        end

    -- ========================================================================
    -- LOOT_OPENED - Process loot from killed mobs
    -- ========================================================================
    elseif event == "LOOT_OPENED" then
        -- Process loot - can contain items from multiple mobs (area loot)
        local numItems = GetNumLootItems()

        -- HEURISTIC: Determine if this is treasure loot
        local isTreasure = false
        if currentLootGUID then
            if currentLootGUID:match("^GameObject") then
                -- Explicit GameObject GUID → definitely a treasure
                isTreasure = true
            elseif currentLootGUID:match("^Creature") then
                -- Creature GUID → definitely NOT a treasure (it's a mob)
                isTreasure = false
            elseif currentLootGUID:match("^Pet") then
                -- Pet GUID → ambiguous, check recentKills
                -- If no recent kills, pet is looting a treasure chest
                if #recentKills == 0 then
                    isTreasure = true
                else
                    isTreasure = false
                end
            elseif #recentKills == 0 then
                -- Unknown GUID type, no recent kills → probably treasure
                isTreasure = true
            end
        else
            -- No GUID captured - need fallback heuristics
            -- Try to get GUID again from mouseover/target
            local fallbackGUID = UnitGUID("mouseover") or UnitGUID("target")
            if fallbackGUID then
                if fallbackGUID:match("^GameObject") then
                    isTreasure = true
                elseif fallbackGUID:match("^Creature") then
                    isTreasure = false
                elseif #recentKills == 0 then
                    isTreasure = true
                end
            elseif #recentKills == 0 then
                -- No GUID, no recent kills → probably a treasure chest
                isTreasure = true
            else
                -- No GUID but recent kills exist - check if any recent kill was very recent (< 2 seconds)
                -- If the most recent kill was longer ago, this is likely a treasure
                local mostRecentKillTime = 0
                for _, killData in ipairs(recentKills) do
                    if killData.time > mostRecentKillTime then
                        mostRecentKillTime = killData.time
                    end
                end
                local timeSinceLastKill = GetTime() - mostRecentKillTime
                if timeSinceLastKill > 2 then
                    -- Last kill was more than 2 seconds ago, this is probably a treasure
                    isTreasure = true
                    FTT:DebugPrint("|cffFFAA00HEURISTIC:|r No GUID, but last kill was " .. string.format("%.1f", timeSinceLastKill) .. "s ago → treating as treasure")
                end
            end
        end

        -- If this is treasure, create a zone-based name (all treasures in same zone grouped together)
        -- IMPORTANT: Store in database using ENGLISH name (for consistency), localize only in UI
        local treasureName = nil
        if isTreasure then
            local mapID = C_Map.GetBestMapForUnit("player")
            if mapID then
                local mapInfo = C_Map.GetMapInfo(mapID)
                local zoneName = mapInfo and mapInfo.name or "Unknown"
                -- Always use English "Treasure Find" as database key
                treasureName = string.format("Treasure Find %s", zoneName)
            end

            -- Fallback if zone is unavailable
            if not treasureName then
                treasureName = "Treasure Find Unknown"
            end
        end

        -- DEBUG: Get loot target info (only if debug mode is enabled)
        if FTT.settings.showDebug then
            FTT:DebugPrint("|cffFFFF00=== LOOT_OPENED DEBUG ===|r")
            FTT:DebugPrint("|cffFF00FFNumItems:|r " .. tostring(numItems))
            FTT:DebugPrint("|cffFF00FFGUID:|r " .. tostring(currentLootGUID))
            FTT:DebugPrint("|cffFF00FFRecent Kills:|r " .. tostring(#recentKills))
            FTT:DebugPrint("|cffFF00FFIs Treasure:|r " .. tostring(isTreasure))
            if treasureName then
                FTT:DebugPrint("|cffFF00FFTreasure Name:|r " .. treasureName)
            end

            if currentLootGUID then
                local guidType = strsplit("-", currentLootGUID)
                FTT:DebugPrint("|cffFF00FFGUID Type:|r " .. tostring(guidType))
                FTT:DebugPrint("|cffFF00FFFull GUID:|r " .. currentLootGUID)

                -- Check if it's a GameObject (treasure chest)
                if currentLootGUID:match("^GameObject") then
                    FTT:DebugPrint("|cff00FF00>>> THIS IS A TREASURE/GAMEOBJECT! <<<|r")
                end
            else
                FTT:DebugPrint("|cffFF0000WARNING:|r No GUID captured in LOOT_READY!")
            end
            FTT:DebugPrint("|cffFFFF00=======================|r")
        end

        for i = 1, numItems do
            local itemLink = GetLootSlotLink(i)
            local texture, item, quantity, currencyID, quality, locked = GetLootSlotInfo(i)

            -- Handle currency/gold slots (itemLink is nil for gold)
            if not itemLink or itemLink == "" then
                -- Parse gold from the item string (e.g., "13 Gold\n79 Silber\n22 Kupfer")
                -- GetLootSlotMoney() doesn't exist in TWW, so we parse the string instead
                local money = 0
                if item and type(item) == "string" then
                    -- Parse gold amount (supports multiple languages)
                    local gold = item:match("(%d+)%s+[Gg]old")
                    if gold then
                        money = money + (tonumber(gold) * 10000)
                    end

                    -- Parse silver amount (German: Silber, English: Silver)
                    local silver = item:match("(%d+)%s+[Ss]ilber") or item:match("(%d+)%s+[Ss]ilver")
                    if silver then
                        money = money + (tonumber(silver) * 100)
                    end

                    -- Parse copper amount (German: Kupfer, English: Copper)
                    local copper = item:match("(%d+)%s+[Kk]upfer") or item:match("(%d+)%s+[Cc]opper")
                    if copper then
                        money = money + tonumber(copper)
                    end
                end

                if money and money > 0 then
                    -- This is a gold/money slot
                    -- Determine mob name for gold tracking
                    local goldMobName = nil
                    if isTreasure and treasureName then
                        goldMobName = treasureName
                    else
                        goldMobName = GetNextLootTarget()
                    end

                    -- Track gold globally
                    FTT.sessionGold = FTT.sessionGold + money
                    FTT.totalGold = FTT.totalGold + money

                    -- Track gold per mob
                    if goldMobName then
                        FTT:RecordGold(goldMobName, money)
                    end

                    if FTT.settings.showDebug then
                        FTT:DebugPrint("|cffFFD700Slot " .. i .. ":|r Gold looted: " .. FTT:FormatMoney(money) .. " from " .. tostring(goldMobName))
                    end
                else
                    -- Not a gold slot, skip it (might be other currency)
                    if FTT.settings.showDebug then
                        FTT:DebugPrint("|cffFF00FFSlot " .. i .. ":|r Skipping non-gold currency slot (item=" .. tostring(item) .. ")")
                    end
                end
            else
                -- CRITICAL: Extract item ID for consistent database key
                -- Try multiple methods to get itemID:
                -- 1. From full itemLink: |Hitem:12345:...|h[Name]|h|r
                -- 2. From bare itemLink: item:12345:0:0:0
                -- 3. From GetItemInfoInstant() using itemLink or item name
                local itemID = nil
                -- Try to extract from full link format
                itemID = itemLink:match("|Hitem:(%d+)")
                if not itemID then
                    -- Try to extract from simple format
                    itemID = itemLink:match("item:(%d+)")
                end
                if not itemID then
                    -- Try GetItemInfoInstant() with the full itemLink first
                    local itemIDFromAPI = GetItemInfoInstant(itemLink)
                    if itemIDFromAPI then
                        itemID = tostring(itemIDFromAPI)
                    else
                        -- If itemLink is just [ItemName], extract the name and try GetItemInfoInstant() with it
                        local itemName = itemLink:match("^%[(.+)%]$")
                        if itemName then
                            itemIDFromAPI = GetItemInfoInstant(itemName)
                            if itemIDFromAPI then
                                itemID = tostring(itemIDFromAPI)
                                FTT:DebugPrint("|cff00FF00Slot " .. i .. ":|r Extracted itemID from item name: " .. itemID)
                            end
                        end
                    end
                end

                -- If itemID extraction failed, use itemLink as fallback key AND add to pending queue
                -- This happens when item is not yet in cache
                local needsPendingResolution = false
                if not itemID then
                    itemID = itemLink  -- Use full link as key temporarily
                    needsPendingResolution = true
                    FTT:DebugPrint("|cffFFAA00Slot " .. i .. ":|r ItemID extraction failed, using itemLink as fallback key and adding to pending queue")
                end

                if FTT.settings.showDebug then
                    FTT:DebugPrint("|cffFF00FFSlot " .. i .. ":|r itemLink: " .. tostring(itemLink))
                    FTT:DebugPrint("|cffFF00FFSlot " .. i .. ":|r item string: " .. tostring(item))
                    FTT:DebugPrint("|cffFF00FFSlot " .. i .. ":|r itemID: " .. tostring(itemID))
                    FTT:DebugPrint("|cffFF00FFSlot " .. i .. ":|r quantity: " .. tostring(quantity))
                end

                if itemID then
                if FTT.settings.showDebug then
                    FTT:DebugPrint("|cffFF00FFSlot " .. i .. ":|r quantity: " .. tostring(quantity))
                end

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
                    if lootSourceInfo.guid then
                        FTT:DebugPrint("|cffFF00FFFTT Debug:|r lootSourceInfo.guid: " .. tostring(lootSourceInfo.guid))
                        local guidType = strsplit("-", lootSourceInfo.guid)
                        FTT:DebugPrint("|cffFF00FFFTT Debug:|r lootSourceInfo GUID Type: " .. tostring(guidType))

                        -- Check if this specific slot is from a GameObject
                        if lootSourceInfo.guid:match("^GameObject") then
                            FTT:DebugPrint("|cff00FF00>>> SLOT " .. i .. " IS FROM A TREASURE/GAMEOBJECT! <<<|r")
                        end
                    end
                else
                    FTT:DebugPrint("|cffFF00FFFTT Debug:|r lootSourceInfo is nil")
                end

                -- Determine the source name for this loot
                if isTreasure and treasureName then
                    -- Use treasure location instead of mob name
                    mobName = treasureName
                    FTT:DebugPrint("|cffFF00FFFTT Debug:|r Using treasure name: " .. mobName)
                elseif lootSourceInfo and lootSourceInfo.name then
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

                    -- Only count kills for non-treasure loot
                    if not isTreasure then
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
                    end

                    FTT:RecordLoot(mobName, itemID, itemLink, quantity or 1, isTreasure)  -- → Libs/Core.lua:RecordLoot()

                    -- If itemID couldn't be resolved, add to pending queue for later processing
                    if needsPendingResolution then
                        table.insert(pendingItems, {
                            mobName = mobName,
                            itemLink = itemLink,
                            timestamp = GetTime()
                        })
                        FTT:DebugPrint("|cffFFAA00FTT Debug:|r Added item to pending queue: " .. itemLink .. " (mob: " .. mobName .. ")")
                    end
                else
                    FTT:DebugPrint("|cffFF0000FTT Debug:|r NO MOBNAME for slot " .. i)
                end
                end  -- end if itemID
            end  -- end else (not gold)
        end  -- end for loop
        FTT:UpdateDisplay()  -- → Libs/UI.lua:UpdateDisplay()
        FTT:UpdateQualityDisplay()  -- Update quality statistics

    -- ========================================================================
    -- LOOT_CLOSED
    -- ========================================================================
    elseif event == "LOOT_CLOSED" then
        -- Nothing to do - items were already tracked in LOOT_OPENED
        currentLootTarget = nil
        currentLootGUID = nil

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
