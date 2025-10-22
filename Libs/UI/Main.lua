-- ============================================================================
-- Fizzlebee's Treasure Tracker - UI Main Module
-- Copyright (c) 2025 Vivian Voss (Fizzlebee) <Boulder Dash Heroes>
-- Licensed under the BSD 3-Clause License (see LICENSE file)
-- ============================================================================
-- DEPENDENCIES:
--   - Core.lua: FTT (global table), FTT.L, FTT.settings, FTT.ENTRY_WIDTH, etc.
--   - Core.lua: FTT:SavePosition(), FTT:SaveFrameSize()
--   - Core.lua: FTT:FormatMoney(), FTT:FormatDuration()
-- EXPORTS:
--   - FTT:UpdateGoldDisplay() → Called by Events.lua
--   - FTT:UpdateDurationDisplay() → Called internally
--   - Main frame, scrollFrame, scrollChild (via FTT table)
-- ============================================================================

local addonName, addon = ...
local FTT = _G.FizzlebeesTreasureTracker
local L = FTT.L

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Helper function to auto-size buttons based on text width
-- Used by Settings.lua
function FTT:AutoSizeButton(button, minWidth, padding)
    minWidth = minWidth or 80
    padding = padding or 20

    local fontString = button:GetFontString()
    if fontString then
        local textWidth = fontString:GetStringWidth()
        local buttonWidth = math.max(textWidth + padding, minWidth)
        button:SetWidth(buttonWidth)
    end
end

-- ============================================================================
-- MAIN FRAME CREATION
-- ============================================================================

-- Create main frame
local frame = CreateFrame("Frame", "FizzlebeesTreasureTrackerFrame", UIParent, "BackdropTemplate")
frame:SetSize(FTT.FRAME_WIDTH, 500)
frame:SetPoint("CENTER")
frame:SetFrameStrata("MEDIUM")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 10, right = 10, top = 10, bottom = 10 }
})
frame:SetBackdropColor(0, 0, 0, 0.85)
frame:SetBackdropBorderColor(0.8, 0.6, 0, 1)

-- Store in FTT for access from other modules
FTT.frame = frame

-- Title
local title = frame:CreateFontString(nil, "OVERLAY", FTT:GetFont("L"))
title:SetPoint("TOPLEFT", FTT:S(20), FTT:S(-20))
title:SetText(L["TITLE"])
title:SetTextColor(1, 0.82, 0)
title:SetJustifyH("LEFT")
FTT.titleText = title  -- Store for dynamic font scaling

-- Collapse/Expand Button (+/- icon, top right)
local collapseBtn = CreateFrame("Button", nil, frame)
collapseBtn:SetSize(24, 24)
collapseBtn:SetPoint("TOPRIGHT", -15, -15)
collapseBtn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
collapseBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
FTT.collapseBtn = collapseBtn
FTT.isCollapsed = false

collapseBtn:SetScript("OnClick", function()
    FTT.isCollapsed = not FTT.isCollapsed
    if FTT.isCollapsed then
        -- Collapsed: show only title and buttons
        collapseBtn:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
        FTT:CollapseTracker()  -- → Tracker.lua
    else
        -- Expanded: show everything
        collapseBtn:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
        FTT:ExpandTracker()  -- → Tracker.lua
    end
end)
collapseBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if FTT.isCollapsed then
        GameTooltip:SetText(L["EXPAND"] or "Expand", 1, 1, 1)
    else
        GameTooltip:SetText(L["COLLAPSE"] or "Collapse", 1, 1, 1)
    end
    GameTooltip:Show()
end)
collapseBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Highlight Item Button (edit/pen icon, left of collapse button)
local highlightBtn = CreateFrame("Button", nil, frame)
highlightBtn:SetSize(24, 24)
highlightBtn:SetPoint("RIGHT", collapseBtn, "LEFT", -5, 0)
highlightBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")  -- Pen/Edit icon
highlightBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
FTT.highlightBtn = highlightBtn

highlightBtn:SetScript("OnClick", function()
    FTT.highlightMode = not FTT.highlightMode

    if FTT.highlightMode then
        -- Activate highlight mode - change button color to indicate active
        highlightBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Down")
        print("|cffFFD700FTT:|r " .. L["HIGHLIGHT_MODE_ACTIVE"])
    else
        -- Deactivate highlight mode
        highlightBtn:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")
    end

    -- Update display to show/hide highlights
    FTT:UpdateDisplay()
end)

highlightBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["HIGHLIGHT_ITEM_TOOLTIP"], 1, 1, 1, 1, true)
    GameTooltip:Show()
end)

highlightBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Settings Button (gear icon, left of highlight button)
local settingsBtn = CreateFrame("Button", nil, frame)
settingsBtn:SetSize(24, 24)
settingsBtn:SetPoint("RIGHT", highlightBtn, "LEFT", -5, 0)
settingsBtn:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")
settingsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
settingsBtn:SetScript("OnClick", function()
    if FTT.settingsFrame then
        if FTT.settingsFrame:IsShown() then
            FTT.settingsFrame:Hide()
        else
            FTT.settingsFrame:Show()
        end
    end
end)
settingsBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["SETTINGS"] or "Settings", 1, 1, 1)
    GameTooltip:Show()
end)
settingsBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- ============================================================================
-- GOLD DISPLAY
-- ============================================================================

local goldFrame = CreateFrame("Frame", nil, frame)
goldFrame:SetSize(FTT.INFO_FRAME_WIDTH, 20)
goldFrame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
goldFrame:Show()  -- Ensure it's visible
FTT.goldFrame = goldFrame  -- Store for Tracker.lua

-- Session gold text (left column)
local sessionGoldText = goldFrame:CreateFontString(nil, "OVERLAY", FTT:GetFont("S"))
sessionGoldText:SetPoint("LEFT", goldFrame, "LEFT", 0, 0)
sessionGoldText:SetText(L["SESSION"] .. ":")
sessionGoldText:SetJustifyH("LEFT")
FTT.sessionGoldText = sessionGoldText  -- Store for dynamic font scaling

-- Total gold text (right column)
local totalGoldText = goldFrame:CreateFontString(nil, "OVERLAY", FTT:GetFont("S"))
totalGoldText:SetPoint("LEFT", sessionGoldText, "RIGHT", FTT:S(20), 0)
totalGoldText:SetText(L["TOTAL"] .. ":")
totalGoldText:SetJustifyH("LEFT")
FTT.totalGoldText = totalGoldText  -- Store for dynamic font scaling

-- Function to update gold display
-- CALLED BY: Events.lua (CHAT_MSG_MONEY handler)
function FTT:UpdateGoldDisplay()
    sessionGoldText:SetText(L["SESSION"] .. ": " .. self:FormatMoney(self.sessionGold))  -- → Core.lua:FormatMoney()
    totalGoldText:SetText(L["TOTAL"] .. ": " .. self:FormatMoney(self.totalGold))
end

-- ============================================================================
-- QUALITY STATISTICS DISPLAY (Items by rarity)
-- ============================================================================
-- Positioned on its own line below gold display

local qualityFrame = CreateFrame("Frame", nil, frame)
qualityFrame:SetSize(FTT.INFO_FRAME_WIDTH, 20)
qualityFrame:SetPoint("TOPLEFT", goldFrame, "BOTTOMLEFT", 0, 0)
qualityFrame:Show()
FTT.qualityFrame = qualityFrame

-- Session quality text (left column)
local sessionQualityText = qualityFrame:CreateFontString(nil, "OVERLAY", FTT:GetFont("S"))
sessionQualityText:SetPoint("LEFT", qualityFrame, "LEFT", 0, 0)
sessionQualityText:SetText(L["SESSION"] .. ": ")
sessionQualityText:SetJustifyH("LEFT")
FTT.sessionQualityText = sessionQualityText

-- Total quality text (right column)
local totalQualityText = qualityFrame:CreateFontString(nil, "OVERLAY", FTT:GetFont("S"))
totalQualityText:SetPoint("LEFT", sessionQualityText, "RIGHT", FTT:S(20), 0)
totalQualityText:SetText(L["TOTAL"] .. ": ")
totalQualityText:SetJustifyH("LEFT")
FTT.totalQualityText = totalQualityText

-- Function to update quality display
-- Uses inline textures with vertex color for proper rendering
function FTT:UpdateQualityDisplay()
    -- Use filled circle texture with vertex coloring (9x9 = 36% smaller than 14x14)
    -- Syntax: |TTexture:size:size:xoffset:yoffset:dimx:dimy:coordx1:coordx2:coordy1:coordy2:r:g:b|t
    -- For vertex coloring, we use the extended format with RGB values (0-255)
    local circleTex = "Interface\\AddOns\\FizzlebeesTreasureTracker\\Textures\\dot"

    -- Green circle (RGB: 30, 255, 0 = #1eff00) with 2px left offset
    local greenCircle = string.format("|T%s:9:9:2:0:64:64:4:60:4:60:30:255:0|t", circleTex)
    -- Blue circle (RGB: 0, 112, 221 = #0070dd) with 2px left offset
    local blueCircle = string.format("|T%s:9:9:2:0:64:64:4:60:4:60:0:112:221|t", circleTex)
    -- Purple circle (RGB: 163, 53, 238 = #a335ee) with 2px left offset
    local purpleCircle = string.format("|T%s:9:9:2:0:64:64:4:60:4:60:163:53:238|t", circleTex)

    -- Format: count followed by colored dot - ALWAYS show all three qualities (even if 0)
    local sessionText = string.format("%s: %d%s %d%s %d%s",
        L["SESSION"],
        self.sessionQuality.green, greenCircle,
        self.sessionQuality.blue, blueCircle,
        self.sessionQuality.purple, purpleCircle)

    local totalText = string.format("%s: %d%s %d%s %d%s",
        L["TOTAL"],
        self.totalQuality.green, greenCircle,
        self.totalQuality.blue, blueCircle,
        self.totalQuality.purple, purpleCircle)

    sessionQualityText:SetText(sessionText)
    totalQualityText:SetText(totalText)
end

-- ============================================================================
-- DURATION DISPLAY
-- ============================================================================

-- Duration frame (after quality display)
local durationFrame = CreateFrame("Frame", nil, frame)
durationFrame:SetSize(FTT.INFO_FRAME_WIDTH, 20)
durationFrame:SetPoint("TOPLEFT", qualityFrame, "BOTTOMLEFT", 0, 0)
durationFrame:Show()  -- Ensure it's visible
FTT.durationFrame = durationFrame  -- Store for Tracker.lua

-- Session duration text (left column)
local sessionDurationText = durationFrame:CreateFontString(nil, "OVERLAY", FTT:GetFont("S"))
sessionDurationText:SetPoint("LEFT", durationFrame, "LEFT", 0, 0)
sessionDurationText:SetText(L["SESSION"] .. ": 00:00:00")
sessionDurationText:SetJustifyH("LEFT")
FTT.sessionDurationText = sessionDurationText  -- Store for dynamic font scaling

-- Total duration text (right column)
local totalDurationText = durationFrame:CreateFontString(nil, "OVERLAY", FTT:GetFont("S"))
totalDurationText:SetPoint("LEFT", sessionDurationText, "RIGHT", FTT:S(20), 0)
totalDurationText:SetText(L["TOTAL"] .. ": 00:00:00")
totalDurationText:SetJustifyH("LEFT")
FTT.totalDurationText = totalDurationText  -- Store for dynamic font scaling

-- ============================================================================
-- KILLS PER SECOND/HOUR DISPLAY
-- ============================================================================

-- Kills per second frame (after duration display)
local kpsFrame = CreateFrame("Frame", nil, frame)
kpsFrame:SetSize(FTT.INFO_FRAME_WIDTH, 20)
kpsFrame:SetPoint("TOPLEFT", durationFrame, "BOTTOMLEFT", 0, 0)
kpsFrame:Show()
FTT.kpsFrame = kpsFrame

-- Kills per second text (left column)
local kpsText = kpsFrame:CreateFontString(nil, "OVERLAY", FTT:GetFont("S"))
kpsText:SetPoint("LEFT", kpsFrame, "LEFT", 0, 0)
kpsText:SetText(L["KILLS_PER_SECOND"] .. ": 0.0")
kpsText:SetJustifyH("LEFT")
kpsText:SetTextColor(0.4, 1, 0.4)  -- Light green color
FTT.kpsText = kpsText  -- Store for dynamic font scaling

-- Kills per hour text (middle column)
local kphText = kpsFrame:CreateFontString(nil, "OVERLAY", FTT:GetFont("S"))
kphText:SetPoint("LEFT", kpsText, "RIGHT", FTT:S(20), 0)
kphText:SetText(L["KILLS_PER_HOUR"] .. ": 0")
kphText:SetJustifyH("LEFT")
kphText:SetTextColor(0.4, 1, 0.4)  -- Light green color
FTT.kphText = kphText  -- Store for dynamic font scaling

-- DPS text (right column, same line as kills)
local dpsText = kpsFrame:CreateFontString(nil, "OVERLAY", FTT:GetFont("S"))
dpsText:SetPoint("LEFT", kphText, "RIGHT", FTT:S(20), 0)
dpsText:SetText(L["DAMAGE_PER_SECOND"] .. ": 0")
dpsText:SetJustifyH("LEFT")
dpsText:SetTextColor(0.4, 1, 0.4)  -- Light green color
FTT.dpsText = dpsText  -- Store for dynamic font scaling

-- Function to update duration display
function FTT:UpdateDurationDisplay()
    local sessionDuration = 0
    if self.sessionStartTime > 0 then
        sessionDuration = GetTime() - self.sessionStartTime
    end
    sessionDurationText:SetText(L["SESSION"] .. ": " .. self:FormatDuration(sessionDuration))  -- → Core.lua:FormatDuration()
    totalDurationText:SetText(L["TOTAL"] .. ": " .. self:FormatDuration(self.totalDuration + sessionDuration))

    -- Calculate and display kills per second and per hour
    local totalKills = 0
    for _, kills in pairs(self.sessionKills) do
        totalKills = totalKills + kills
    end

    local kps = 0
    local kph = 0
    if sessionDuration > 0 then
        kps = totalKills / sessionDuration
        kph = (totalKills / sessionDuration) * 3600  -- Convert to per hour
    end

    kpsText:SetText(string.format("%s: %.2f", L["KILLS_PER_SECOND"], kps))
    kphText:SetText(string.format("%s: %d", L["KILLS_PER_HOUR"], math.floor(kph)))

    -- Calculate and display DPS
    if self.dpsText then
        local dps = 0
        if sessionDuration > 0 then
            dps = self.sessionDamage / sessionDuration
        end
        self.dpsText:SetText(string.format("%s: %s", L["DAMAGE_PER_SECOND"], self:FormatNumber(dps)))
    end
end

-- Function to format large numbers with K/M suffixes
function FTT:FormatNumber(number)
    if number >= 1000000 then
        return string.format("%.1fM", number / 1000000)
    elseif number >= 1000 then
        return string.format("%.1fK", number / 1000)
    else
        return string.format("%.0f", number)
    end
end

-- Update duration every second
local durationUpdateFrame = CreateFrame("Frame")
durationUpdateFrame:SetScript("OnUpdate", function(self, elapsed)
    self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
    if self.timeSinceLastUpdate >= 1 then
        FTT:UpdateDurationDisplay()
        self.timeSinceLastUpdate = 0
    end
end)

-- ============================================================================
-- SCROLL FRAME & MOB LIST
-- ============================================================================

local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", kpsFrame, "BOTTOMLEFT", 0, -10)
scrollFrame:SetPoint("BOTTOMRIGHT", -40, 20)
FTT.scrollFrame = scrollFrame

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(FTT.ENTRY_WIDTH, 1)
scrollFrame:SetScrollChild(scrollChild)
FTT.scrollChild = scrollChild  -- Store for Tracker.lua

-- Empty text
local emptyText = scrollFrame:CreateFontString(nil, "OVERLAY", FTT:GetFont("N"))
emptyText:SetPoint("CENTER", scrollFrame, "CENTER", 0, 0)
emptyText:SetText("|cff888888" .. L["KILL_MOBS_TEXT"] .. "|r")
emptyText:SetJustifyH("CENTER")
emptyText:SetJustifyV("MIDDLE")
FTT.emptyText = emptyText  -- Store for Tracker.lua

-- ============================================================================
-- FRAME DRAGGING & RESIZING
-- ============================================================================

-- Make frame draggable
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
    if not FTT.settings.lockPosition then
        self:StartMoving()
    end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    FTT:SavePosition()  -- → Core.lua:SavePosition()
end)

-- Make frame resizable
frame:SetResizable(true)
frame:SetResizeBounds(FTT.FRAME_WIDTH - 50, 200, 800, 800)

-- Create resize button (bottom right corner grip)
local resizeButton = CreateFrame("Button", nil, frame, "PanelResizeButtonTemplate")
resizeButton:SetPoint("BOTTOMRIGHT", -5, 5)
resizeButton:SetSize(16, 16)
resizeButton:Init(frame, FTT.FRAME_WIDTH - 50, 200, 800, 800)
FTT.resizeButton = resizeButton

-- Hook into resize to save size and update entries
frame:SetScript("OnSizeChanged", function(_, width, height)
    -- Save the new size if not using auto-sizing
    if FTT.settings then
        if not FTT.settings.autoSize then
            FTT:SaveFrameSize(width, height)  -- → Core.lua:SaveFrameSize()
            -- Resize entries to fill new frame width
            if FTT.ResizeEntries then
                FTT:ResizeEntries()  -- → Tracker.lua:ResizeEntries()
            end
        end
    end
end)
