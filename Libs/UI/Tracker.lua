-- ============================================================================
-- Fizzlebee's Treasure Tracker - UI Tracker Module
-- Copyright (c) 2025 Vivian Voss (Fizzlebee) <Boulder Dash Heroes>
-- Licensed under the BSD 3-Clause License (see LICENSE file)
-- ============================================================================
-- DEPENDENCIES:
--   - Core.lua: FTT (global table), FTT.L, FTT.settings, FTT.ENTRY_WIDTH, etc.
--   - Core.lua: FTT:SaveSettings(), FTT:DebugPrint()
--   - UI/Main.lua: FTT.frame, FTT.scrollFrame, FTT.scrollChild, FTT.emptyText, FTT.durationFrame
-- EXPORTS:
--   - FTT:UpdateDisplay() → Called by Events.lua, Settings.lua, Core.lua
--   - FTT:GetEntry(index) → Called by UpdateDisplay
--   - FTT:CollapseTracker() → Called by UI/Main.lua (collapse button)
--   - FTT:ExpandTracker() → Called by UI/Main.lua (collapse button)
-- ============================================================================

local addonName, addon = ...
local FTT = _G.FizzlebeesTreasureTracker
local L = FTT.L

-- Local references to constants for faster access
local ENTRY_WIDTH = FTT.ENTRY_WIDTH
local FRAME_WIDTH = FTT.FRAME_WIDTH
local FRAME_PADDING = FTT.FRAME_PADDING
local ITEM_LEFT_OFFSET = FTT.ITEM_LEFT_OFFSET
local ITEM_RIGHT_PADDING = FTT.ITEM_RIGHT_PADDING
local ITEM_LINE_WIDTH = FTT.ITEM_LINE_WIDTH

-- ============================================================================
-- ENTRY POOL MANAGEMENT
-- ============================================================================

-- Function to get or create an entry from the pool
-- CALLED BY: UpdateDisplay()
function FTT:GetEntry(index)
    if not self.entryPool[index] then
        local entry = CreateFrame("Frame", nil, self.scrollChild, "BackdropTemplate")
        entry:SetSize(ENTRY_WIDTH, 25)
        entry:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false,
            edgeSize = 12,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        entry:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        entry:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

        -- Header button
        entry.header = CreateFrame("Button", nil, entry)
        entry.header:SetAllPoints()

        entry.icon = entry.header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        entry.icon:SetPoint("LEFT", 8, 0)
        entry.icon:SetText("+")
        entry.icon:SetTextColor(0.8, 0.8, 0.8)

        entry.text = entry.header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        entry.text:SetPoint("LEFT", 25, 0)
        entry.text:SetPoint("RIGHT", -30, 0)  -- Make room for hide button
        entry.text:SetJustifyH("LEFT")
        entry.text:SetTextColor(1, 0.82, 0)

        -- Hide button (eye icon) - must be created AFTER header to be on top
        entry.hideBtn = CreateFrame("Button", nil, entry)
        entry.hideBtn:SetSize(20, 20)
        entry.hideBtn:SetPoint("RIGHT", -5, 0)
        entry.hideBtn:SetFrameLevel(entry:GetFrameLevel() + 2)  -- Higher level than header
        entry.hideBtn:SetNormalTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
        entry.hideBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
        entry.hideBtn:EnableMouse(true)  -- Explicitly enable mouse
        entry.hideBtn:RegisterForClicks("LeftButtonUp")
        entry.hideBtn:SetScript("OnClick", function()
            if entry.mobName then
                FTT:DebugPrint("|cffFFD700FTT:|r " .. L["HIDING_MOB"] .. ": " .. entry.mobName)
                FTT.hiddenMobs[entry.mobName] = true
                FTT:UpdateDisplay()
            end
        end)
        entry.hideBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["HIDE_MOB_TOOLTIP"], 1, 1, 1)
            GameTooltip:Show()
        end)
        entry.hideBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- Details frame
        entry.details = CreateFrame("Frame", nil, entry)
        entry.details:SetPoint("TOPLEFT", entry, "BOTTOMLEFT", 0, 0)
        entry.details:SetPoint("TOPRIGHT", entry, "BOTTOMRIGHT", 0, 0)
        entry.details:SetHeight(1)
        entry.details:Hide()
        entry.details.lines = {}

        entry.expanded = false
        entry.mobName = nil  -- Will be set in UpdateDisplay
        entry.header:SetScript("OnClick", function()
            -- Toggle expanded state for this specific mob
            if entry.mobName then
                local isExpanded = FTT.expandedMobs[entry.mobName]
                FTT.expandedMobs[entry.mobName] = not isExpanded
                FTT:UpdateDisplay()
            end
        end)

        self.entryPool[index] = entry
    end
    return self.entryPool[index]
end

-- ============================================================================
-- ENTRY RESIZE FUNCTIONS
-- ============================================================================

-- Function to resize all visible entries to fill available width
-- CALLED BY: UpdateDisplay(), OnSizeChanged handler
function FTT:ResizeEntries()
    -- Calculate effective entry width based on current frame width
    local currentFrameWidth = self.frame:GetWidth()
    local effectiveEntryWidth = currentFrameWidth - FRAME_PADDING

    -- Ensure minimum width
    if effectiveEntryWidth < ENTRY_WIDTH then
        effectiveEntryWidth = ENTRY_WIDTH
    end

    -- Update all visible entry widths
    for i, entry in pairs(self.entryPool) do
        if entry and entry:IsShown() then
            entry:SetWidth(effectiveEntryWidth)
            -- Update all line buttons in this entry
            if entry.details and entry.details.lines then
                local itemLineWidth = effectiveEntryWidth - ITEM_RIGHT_PADDING
                for _, lineButton in ipairs(entry.details.lines) do
                    lineButton:SetWidth(itemLineWidth)
                end
            end
        end
    end

    -- Update scrollChild width to match entries
    self.scrollChild:SetWidth(effectiveEntryWidth)
end

-- ============================================================================
-- COLLAPSE/EXPAND FUNCTIONS
-- ============================================================================

-- Function to collapse the tracker (hide content)
-- CALLED BY: UI/Main.lua (collapse button)
function FTT:CollapseTracker()
    -- Save current height and width before collapsing
    self.savedHeight = self.frame:GetHeight()
    self.savedWidth = self.frame:GetWidth()

    -- Hide scroll frame and content
    self.scrollFrame:Hide()
    self.goldFrame:Hide()
    self.qualityFrame:Hide()
    self.kpsFrame:Hide()
    self.durationFrame:Hide()

    -- Set minimum height to show only title and buttons
    self.frame:SetHeight(60)
end

-- Function to expand the tracker (show content)
-- CALLED BY: UI/Main.lua (collapse button)
function FTT:ExpandTracker()
    -- Show scroll frame and content
    self.scrollFrame:Show()
    self.goldFrame:Show()
    self.qualityFrame:Show()
    self.kpsFrame:Show()
    self.durationFrame:Show()

    -- Restore previous height and width if saved
    if self.savedHeight and self.savedWidth then
        self.frame:SetSize(self.savedWidth, self.savedHeight)
    end

    -- Restore normal display
    self:UpdateDisplay()
end

-- ============================================================================
-- MAIN DISPLAY UPDATE FUNCTION
-- ============================================================================

-- Function to update the mob list display
-- CALLED BY: Events.lua, Settings.lua, Core.lua, collapse/expand functions
function FTT:UpdateDisplay()
    -- Wrap in pcall to catch any errors
    local success, err = pcall(function()
        self:UpdateDisplayInternal()
    end)

    if success then
        -- Update heartbeat timestamp on successful update
        self.lastUpdateTime = GetTime()
    else
        -- Error messages are always shown (critical for debugging user issues)
        FTT:InfoPrint("|cffFF0000FTT Error:|r UpdateDisplay failed: " .. tostring(err))
    end
end

-- Internal update function with error handling
function FTT:UpdateDisplayInternal()
    -- Don't update if collapsed
    if self.isCollapsed then
        return
    end

    -- Hide all entries
    for _, entry in pairs(self.entryPool) do
        entry:Hide()
    end

    local mobs = FizzlebeesTreasureTrackerDB.mobs
    if not mobs then return end

    -- Remove player from mobs list if present (cleanup old data)
    local playerName = UnitName("player")
    if mobs[playerName] then
        mobs[playerName] = nil
    end
    if self.sessionKills[playerName] then
        self.sessionKills[playerName] = nil
    end
    if self.sessionLoot[playerName] then
        self.sessionLoot[playerName] = nil
    end

    -- Check if we have data
    local hasData = false
    for _ in pairs(mobs) do
        hasData = true
        break
    end

    if not hasData then
        self.emptyText:Show()
        self.scrollChild:SetHeight(1)
        -- Auto-size for empty state
        if self.settings and self.settings.autoSize then
            self.frame:SetSize(FRAME_WIDTH, 200)
        end
        return
    else
        self.emptyText:Hide()
    end

    -- Sort mobs by lastKillTime: newest kill first (top), oldest last (bottom)
    local sortedMobs = {}
    for mobName, _ in pairs(mobs) do
        table.insert(sortedMobs, mobName)
    end

    table.sort(sortedMobs, function(a, b)
        local lastKillA = mobs[a].lastKillTime or 0
        local lastKillB = mobs[b].lastKillTime or 0

        -- Sort by most recent kill time (higher = more recent = top)
        return lastKillA > lastKillB
    end)

    -- Separate mobs into active and inactive (using Unix timestamps now)
    local currentTime = time()
    local INACTIVE_THRESHOLD = 300  -- 5 minutes
    local activeMobs = {}
    local inactiveMobs = {}

    for _, mobName in ipairs(sortedMobs) do
        local mobData = mobs[mobName]
        local lastKillTime = mobData.lastKillTime or 0
        local timeSinceKill = currentTime - lastKillTime

        if lastKillTime > 0 and timeSinceKill <= INACTIVE_THRESHOLD then
            table.insert(activeMobs, mobName)
        else
            table.insert(inactiveMobs, mobName)
        end
    end

    -- Pre-calculate maximum width for ALL mobs (including inactive) to preserve width when toggling
    -- This is ALWAYS calculated, but only used to resize frame in auto-size mode
    local maxWidth = ENTRY_WIDTH

    -- Create temporary FontString to measure text width if not already created
    if not self.measureText then
        self.measureText = self.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.measureText:SetWordWrap(false)
        self.measureText:Hide()  -- Never show this, just for measuring
    end

    -- Measure width for all mobs (both active and inactive)
    for _, mobName in ipairs(sortedMobs) do
        local mobData = mobs[mobName]
        local sessionKills = self.sessionKills[mobName] or 0
        local totalKills = mobData.kills
        local headerText = string.format("%s: %d/%d", mobName, sessionKills, totalKills)

        self.measureText:SetFontObject(GameFontNormal)
        self.measureText:SetText(headerText)
        local textWidth = self.measureText:GetStringWidth()
        local iconWidth = 25  -- Width of +/- icon (left side)
        local hideButtonWidth = 30  -- Width of hide button (right side)
        local padding = 10  -- Additional padding
        local requiredWidth = iconWidth + textWidth + hideButtonWidth + padding
        if requiredWidth > maxWidth then
            maxWidth = requiredWidth
        end

        -- Also measure item names for this mob
        if mobData.loot then
            self.measureText:SetFontObject(GameFontNormalSmall)
            for itemName, _ in pairs(mobData.loot) do
                if not self.hiddenItems[itemName] then
                    self.measureText:SetText(itemName)
                    local itemNameWidth = self.measureText:GetStringWidth()
                    -- Calculate based on actual layout:
                    -- nameText: LEFT at +5, RIGHT at -105
                    -- countText: 50px wide, RIGHT at -55
                    -- ratioText: 50px wide, RIGHT at -5
                    local leftPadding = ITEM_LEFT_OFFSET + 5  -- Left offset + nameText left padding
                    local rightReserved = 105  -- Space reserved on right for count + ratio columns
                    local safetyBuffer = 10  -- Small additional buffer
                    local itemRequiredWidth = leftPadding + itemNameWidth + rightReserved + safetyBuffer
                    if itemRequiredWidth > maxWidth then
                        maxWidth = itemRequiredWidth
                    end
                end
            end
        end
    end

    -- Build combined display list
    local displayList = {}
    for _, mobName in ipairs(activeMobs) do
        table.insert(displayList, {mobName = mobName, isActive = true})
    end

    -- Add separator marker if there are inactive mobs
    if #inactiveMobs > 0 then
        table.insert(displayList, {isSeparator = true, count = #inactiveMobs})
    end

    -- Add inactive mobs if setting is enabled
    if self.settings.showInactiveMobs then
        for _, mobName in ipairs(inactiveMobs) do
            table.insert(displayList, {mobName = mobName, isActive = false})
        end
    end

    -- Display entries
    local yOffset = 0
    local visibleEntries = 0

    for index, item in ipairs(displayList) do
        -- Handle separator
        if item.isSeparator then
            -- Create or reuse toggle button
            if not self.inactiveToggleButton then
                local toggleBtn = CreateFrame("Button", nil, self.scrollChild)
                toggleBtn:SetSize(100, 20)  -- Small button

                -- Create FontString for the text
                local text = toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                text:SetAllPoints()  -- Fill the entire button
                text:SetJustifyH("RIGHT")  -- Right-align the text
                toggleBtn.text = text

                -- No background - completely transparent
                -- No hover highlight

                toggleBtn:SetScript("OnClick", function()
                    self.settings.showInactiveMobs = not self.settings.showInactiveMobs
                    self:SaveSettings()
                    self:UpdateDisplay()
                end)

                self.inactiveToggleButton = toggleBtn
            end

            local toggleBtn = self.inactiveToggleButton
            -- Clear previous anchors and position right-aligned
            toggleBtn:ClearAllPoints()
            toggleBtn:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", -5, -yOffset)

            -- Update button text based on state (simple text, no symbols)
            if self.settings.showInactiveMobs then
                toggleBtn.text:SetText(L["HIDE_INACTIVE"])
            else
                toggleBtn.text:SetText(L["SHOW_INACTIVE"])
            end
            toggleBtn.text:SetTextColor(1, 0.82, 0, 1)  -- Golden (same as title)

            toggleBtn:Show()
            toggleBtn.text:Show()  -- Ensure text is visible
            yOffset = yOffset + 20  -- Smaller height
        else
            -- Display mob entry
            local mobName = item.mobName
            local mobData = mobs[mobName]

            -- Skip hidden mobs (for current session)
            local isHidden = self.hiddenMobs[mobName]

            -- Filter by zone (if enabled) - this is separate from normal hidden mobs
            local isWrongZone = false
            if self.settings and self.settings.filterByZone then
                local currentMapID = C_Map.GetBestMapForUnit("player")
                local mobZoneID = mobData.zoneID
                if mobZoneID and currentMapID and mobZoneID ~= currentMapID then
                    isWrongZone = true
                end
            end

            if not isHidden and not isWrongZone then
            -- Check if this mob has the filtered item (if filter is active)
            local shouldShow = true
            if self.settings and self.settings.itemFilter and self.settings.itemFilter ~= "" then
                local hasFilteredItem = false
                for itemName, lootData in pairs(mobData.loot) do
                    -- Get item ID from the item link
                    local itemID = lootData.link:match("item:(%d+)")
                    if itemID == self.settings.itemFilter then
                        hasFilteredItem = true
                        break
                    end
                end

                -- Skip this mob if filter is active and it doesn't have the filtered item
                if not hasFilteredItem then
                    shouldShow = false
                end
            end

            if shouldShow then
                visibleEntries = visibleEntries + 1
                local entry = self:GetEntry(visibleEntries)
                entry.mobName = mobName

                -- Format: "Mob Name: Session/Total"
                local sessionKills = self.sessionKills[mobName] or 0
                local totalKills = mobData.kills
                local headerText = string.format("%s: %d/%d", mobName, sessionKills, totalKills)
                entry.text:SetText(headerText)

                -- Initialize expanded state for new mobs
                if self.expandedMobs[mobName] == nil then
                    -- Auto-expand if this mob has looted items
                    if mobData.autoExpanded then
                        self.expandedMobs[mobName] = true
                    else
                        self.expandedMobs[mobName] = false
                    end
                end

                -- Build loot details first to check if there are any loot entries
                local detailHeight = 0
                local lootIndex = 1

                -- Sort loot by drop rate
                local sortedLoot = {}
                for itemName, lootData in pairs(mobData.loot) do
                    -- Extract item ID for quality check and highlighting
                    local itemID = lootData.link:match("item:(%d+)")
                    local isHighlightedItem = self.highlightedItemID and itemID and tostring(itemID) == tostring(self.highlightedItemID)

                    -- Skip hidden items (but NEVER hide highlighted items)
                    if not self.hiddenItems[itemName] or isHighlightedItem then
                        -- Get item quality from link
                        local _, _, itemQuality = GetItemInfo(lootData.link)
                        local minQuality = self.settings and self.settings.minItemQuality or 0

                        -- Check if item meets quality threshold (or is highlighted)
                        local meetsQuality = isHighlightedItem or (itemQuality and itemQuality >= minQuality)

                        -- If filter is active, only show the filtered item
                        if self.settings and self.settings.itemFilter and self.settings.itemFilter ~= "" then
                            if itemID == self.settings.itemFilter then
                                if meetsQuality then
                                    table.insert(sortedLoot, {name = itemName, data = lootData})
                                end
                            end
                        else
                            -- No ID filter, just check quality
                            if meetsQuality then
                                table.insert(sortedLoot, {name = itemName, data = lootData})
                            end
                        end
                    end
                end
                table.sort(sortedLoot, function(a, b)
                    return (a.data.count / mobData.kills) > (b.data.count / mobData.kills)
                end)

                -- Set visual state based on expanded status and whether there's loot
                local hasLoot = #sortedLoot > 0
                local isExpanded = self.expandedMobs[mobName]
                entry.expanded = isExpanded

                -- Check if mob is inactive (older than 5 minutes) - using Unix time now
                local currentTime = time()
                local lastKillTime = mobData.lastKillTime or 0
                local timeSinceKill = currentTime - lastKillTime
                local INACTIVE_THRESHOLD = 300  -- 5 minutes
                local isInactive = (lastKillTime == 0 or timeSinceKill > INACTIVE_THRESHOLD)

                -- Apply transparency for inactive mobs
                if isInactive then
                    entry:SetAlpha(0.4)  -- 40% opacity for old mobs
                else
                    entry:SetAlpha(1.0)  -- 100% opacity for active mobs
                end

                if hasLoot then
                    -- Show +/- icon if there's loot
                    if isExpanded then
                        entry.icon:SetText("-")
                        entry:SetBackdropBorderColor(0.8, 0.6, 0, 1)
                    else
                        entry.icon:SetText("+")
                        entry:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                    end
                    -- Enable clicking when there's loot
                    entry.header:EnableMouse(true)
                else
                    -- Hide icon if there's no loot
                    entry.icon:SetText("")
                    entry:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
                    -- Disable clicking when there's no loot
                    entry.header:EnableMouse(false)
                    -- Make sure it's not expanded
                    entry.details:Hide()
                end

                -- Track vertical offset for dynamic positioning
                local itemYOffset = 0

                for _, item in ipairs(sortedLoot) do
                    if not entry.details.lines[lootIndex] then
                        -- Create a button frame for hover detection
                        local lineButton = CreateFrame("Button", nil, entry.details)
                        lineButton:SetSize(ITEM_LINE_WIDTH, 16)  -- Full width minus padding

                        -- Add highlight glow texture (pulsing effect for highlighted items)
                        local glowTexture = lineButton:CreateTexture(nil, "BACKGROUND")
                        glowTexture:SetAllPoints()
                        glowTexture:SetColorTexture(1, 0.85, 0.3, 0.35)  -- Perfect balance - yellow-orange
                        glowTexture:Hide()  -- Hidden until activated
                        lineButton.glowTexture = glowTexture

                        -- Create animation group for pulsing effect
                        local animGroup = glowTexture:CreateAnimationGroup()
                        animGroup:SetLooping("BOUNCE")
                        local alpha = animGroup:CreateAnimation("Alpha")
                        alpha:SetFromAlpha(0.3)  -- Noticeable minimum
                        alpha:SetToAlpha(0.55)   -- Clear maximum
                        alpha:SetDuration(1.5)   -- Elegant pulsing
                        alpha:SetSmoothing("IN_OUT")
                        lineButton.glowAnimation = animGroup

                        -- Add highlight texture for hover feedback
                        local highlight = lineButton:CreateTexture(nil, "HIGHLIGHT")  -- Use HIGHLIGHT layer
                        highlight:SetAllPoints()
                        highlight:SetColorTexture(1, 1, 1, 0.15)
                        lineButton:SetHighlightTexture(highlight)

                        -- Column 1: Item name (left-aligned, takes remaining space)
                        local nameText = lineButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        nameText:SetPoint("LEFT", lineButton, "LEFT", 5, 0)
                        nameText:SetPoint("RIGHT", lineButton, "RIGHT", -105, 0)  -- Leave 105px for two 50px columns + padding
                        nameText:SetJustifyH("LEFT")
                        nameText:SetWordWrap(false)

                        -- Column 2: Count (session/total) - fixed 50px width
                        local countText = lineButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        countText:SetPoint("RIGHT", lineButton, "RIGHT", -55, 0)  -- 55px from right (50px + 5px padding)
                        countText:SetWidth(50)
                        countText:SetJustifyH("RIGHT")

                        -- Column 3: Ratio (1:X) - fixed 50px width
                        local ratioText = lineButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        ratioText:SetPoint("RIGHT", lineButton, "RIGHT", -5, 0)  -- 5px from right edge
                        ratioText:SetWidth(50)
                        ratioText:SetJustifyH("RIGHT")

                        lineButton.nameText = nameText
                        lineButton.countText = countText
                        lineButton.ratioText = ratioText
                        entry.details.lines[lootIndex] = lineButton
                    end

                    local lineButton = entry.details.lines[lootIndex]
                    local nameText = lineButton.nameText
                    local countText = lineButton.countText
                    local ratioText = lineButton.ratioText

                    -- Get session and total loot counts
                    local sessionLootCount = 0
                    if self.sessionLoot[mobName] and self.sessionLoot[mobName][item.name] then
                        sessionLootCount = self.sessionLoot[mobName][item.name]
                    end
                    local totalLootCount = item.data.count

                    -- Calculate drops per kill (average)
                    local dropsPerKill = totalLootCount / mobData.kills

                    -- Set text for each column
                    nameText:SetText(item.name)
                    countText:SetText(string.format("%d/%d", sessionLootCount, totalLootCount))

                    -- Calculate ratio as 1:X
                    local ratio = dropsPerKill > 0 and (1 / dropsPerKill) or 999
                    ratioText:SetText(string.format("1:%d", math.floor(ratio)))

                    -- Fixed height for single line items (no wrapping now)
                    local lineHeight = 16

                    -- Position button dynamically based on previous items
                    lineButton:ClearAllPoints()
                    lineButton:SetPoint("TOPLEFT", ITEM_LEFT_OFFSET, -5 - itemYOffset)
                    lineButton:SetHeight(lineHeight)

                    -- Update offset for next item
                    itemYOffset = itemYOffset + lineHeight

                    -- Color coding based on ratio (1:X)
                    local r, g, b
                    local ratioValue = math.floor(ratio)
                    if ratioValue <= 10 then
                        r, g, b = 1, 1, 1  -- White (1:1 to 1:10)
                    elseif ratioValue <= 25 then
                        r, g, b = 0.4, 1, 0.4  -- Light Green (1:11 to 1:25)
                    elseif ratioValue <= 50 then
                        r, g, b = 1, 1, 0.4  -- Light Yellow (1:26 to 1:50)
                    elseif ratioValue <= 100 then
                        r, g, b = 1, 0.75, 0.4  -- Light Orange (1:51 to 1:100)
                    elseif ratioValue <= 200 then
                        r, g, b = 1, 0.5, 0.5  -- Light Red (1:101 to 1:200)
                    else
                        r, g, b = 0.8, 0.6, 1  -- Light Purple (1:201+)
                    end

                    -- Apply color to all three columns
                    nameText:SetTextColor(r, g, b)
                    countText:SetTextColor(r, g, b)
                    ratioText:SetTextColor(r, g, b)

                    -- Store item link and name for tooltip and hiding
                    lineButton.itemLink = item.data.link
                    lineButton.itemName = item.name

                    -- Get item ID from link and store as string for consistency
                    local itemID = item.data.link:match("item:(%d+)")
                    lineButton.itemID = itemID and tostring(itemID) or nil

                    -- Enable left-click and right-click
                    lineButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

                    -- Add click handler
                    lineButton:SetScript("OnClick", function(self, button)
                        -- Left-click in highlight mode: toggle highlight
                        if button == "LeftButton" and FTT.highlightMode and self.itemID then
                            -- Convert itemID to string for consistent comparison
                            local itemIDStr = tostring(self.itemID)

                            if FTT.highlightedItemID == itemIDStr then
                                -- Remove highlight
                                FTT.highlightedItemID = nil
                                FTT.settings.highlightedItemID = nil
                                FTT:InfoPrint("|cffFFD700FTT:|r " .. L["ITEM_UNHIGHLIGHTED"])
                            else
                                -- Set highlight (store as string for consistency)
                                FTT.highlightedItemID = itemIDStr
                                FTT.settings.highlightedItemID = itemIDStr
                                FTT:InfoPrint("|cffFFD700FTT:|r " .. L["ITEM_HIGHLIGHTED"] .. ": " .. self.itemName)
                            end
                            -- Save to DB
                            FTT:SaveSettings()
                            -- Deactivate highlight mode after selection
                            FTT.highlightMode = false
                            if FTT.highlightBtn then
                                FTT.highlightBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
                            end
                            FTT:UpdateDisplay()
                        -- Right-click: hide item
                        elseif button == "RightButton" and self.itemName then
                            FTT.hiddenItems[self.itemName] = true
                            FTT:UpdateDisplay()
                        end
                    end)

                    -- Apply glow effect if this item is highlighted
                    if lineButton.glowTexture and lineButton.glowAnimation then
                        -- Both itemID and highlightedItemID are stored as strings
                        local isHighlighted = FTT.highlightedItemID and lineButton.itemID and lineButton.itemID == FTT.highlightedItemID

                        if isHighlighted then
                            -- Show and animate glow
                            lineButton.glowTexture:Show()
                            if not lineButton.glowAnimation:IsPlaying() then
                                lineButton.glowAnimation:Play()
                            end
                        else
                            -- Hide glow
                            if lineButton.glowAnimation:IsPlaying() then
                                lineButton.glowAnimation:Stop()
                            end
                            lineButton.glowTexture:Hide()
                        end
                    end

                    -- Add tooltip scripts
                    lineButton:SetScript("OnEnter", function(self)
                        if self.itemLink then
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            GameTooltip:SetHyperlink(self.itemLink)
                            GameTooltip:Show()
                        end
                    end)
                    lineButton:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                    end)

                    nameText:Show()
                    countText:Show()
                    ratioText:Show()
                    lineButton:Show()
                    lootIndex = lootIndex + 1
                end

                -- Use the actual accumulated height from itemYOffset
                detailHeight = itemYOffset

                -- Hide unused lines
                for i = lootIndex, #entry.details.lines do
                    entry.details.lines[i]:Hide()
                end

                entry.details:SetHeight(detailHeight + 10)
                entry:SetPoint("TOPLEFT", 0, -yOffset)
                entry:Show()

                -- Show/hide details based on expanded state
                if entry.expanded then
                    entry.details:Show()
                else
                    entry.details:Hide()
                end

                yOffset = yOffset + 25
                if entry.expanded then
                    yOffset = yOffset + detailHeight + 10
                end
                end -- end if shouldShow
            end -- end if not isHidden and not isWrongZone
        end -- end else (mob entry, not separator)
    end -- end for displayList

    -- Hide toggle button if no inactive mobs
    if not (#inactiveMobs > 0) and self.inactiveToggleButton then
        self.inactiveToggleButton:Hide()
    end

    self.scrollChild:SetHeight(math.max(yOffset, 1))

    -- Apply auto-sizing if enabled (both width and height)
    if self.settings and self.settings.autoSize then
        local headerHeight = 80  -- Title + top margin
        local footerHeight = 80  -- Buttons + bottom margin
        local scrollHeight = math.min(yOffset, 400)  -- Cap at 400px content
        local totalHeight = headerHeight + scrollHeight + footerHeight
        local totalWidth = maxWidth + FRAME_PADDING
        self.frame:SetSize(math.max(totalWidth, FRAME_WIDTH), math.max(totalHeight, 200))
    end

    -- Resize all entries to fill available frame width (works in both modes)
    self:ResizeEntries()
end
