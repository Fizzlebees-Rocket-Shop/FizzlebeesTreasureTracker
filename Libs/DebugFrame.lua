-- ==============================================================================
-- Fizzlebee's Treasure Tracker - Debug Frame
-- Copyright (c) 2025 Vivian Voss (Fizzlebee) <Boulder Dash Heroes>
-- Licensed under the BSD 3-Clause License (see LICENSE file)
-- ==============================================================================
-- This creates a dedicated debug output window for FTT
-- ==============================================================================

local addonName = "FizzlebeesTreasureTracker"
local FTT = _G.FizzlebeesTreasureTracker

-- Initialize debug frame (will be called from main .lua after FTT is loaded)
function FTT:InitDebugFrame()
    if not self then
        print("ERROR: FTT not initialized")
        return
    end

    -- Create debug frame
    FTT.debugFrame = CreateFrame("Frame", "FTTDebugFrame", UIParent, "BackdropTemplate")
    FTT.debugFrame:SetSize(500, 400)
    FTT.debugFrame:SetPoint("CENTER", 200, 0)
    FTT.debugFrame:SetMovable(true)
    FTT.debugFrame:EnableMouse(true)
    FTT.debugFrame:RegisterForDrag("LeftButton")
    FTT.debugFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    FTT.debugFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    FTT.debugFrame:Hide()

    -- Backdrop
    FTT.debugFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    FTT.debugFrame:SetBackdropColor(0, 0, 0, 0.95)

    -- Title
    local title = FTT.debugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("FTT Debug Console")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, FTT.debugFrame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)

    -- Clear button
    local clearBtn = CreateFrame("Button", nil, FTT.debugFrame, "UIPanelButtonTemplate")
    clearBtn:SetSize(80, 22)
    clearBtn:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -5, 0)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        for i = 1, FTT.debugLineCount do
            FTT.debugLines[i]:SetText("")
            FTT.debugLines[i]:Hide()
        end
        FTT.debugLineCount = 0
    end)

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, FTT.debugFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 15)
    FTT.debugScrollFrame = scrollFrame

    -- Content frame inside scroll frame
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(450, 1)
    scrollFrame:SetScrollChild(contentFrame)
    FTT.debugContentFrame = contentFrame

    -- Create text lines for debug output
    FTT.debugLines = {}
    FTT.debugLineCount = 0
    local MAX_LINES = 200

    for i = 1, MAX_LINES do
        local line = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        line:SetPoint("TOPLEFT", 0, -(i - 1) * 14)
        line:SetWidth(450)
        line:SetJustifyH("LEFT")
        line:SetText("")
        line:Hide()
        FTT.debugLines[i] = line
    end

    -- Function to add a debug line
    function FTT:DebugLog(text)
        if not self.settings.showDebug then return end

        -- Ensure debug frame is visible
        if not self.debugFrame:IsShown() then
            self.debugFrame:Show()
        end

        -- Add new line
        self.debugLineCount = self.debugLineCount + 1
        if self.debugLineCount > MAX_LINES then
            -- Shift all lines up
            for i = 1, MAX_LINES - 1 do
                self.debugLines[i]:SetText(self.debugLines[i + 1]:GetText())
            end
            self.debugLineCount = MAX_LINES
        end

        -- Set text with timestamp
        local timestamp = date("%H:%M:%S")
        self.debugLines[self.debugLineCount]:SetText("[" .. timestamp .. "] " .. text)
        self.debugLines[self.debugLineCount]:Show()

        -- Update content frame height
        self.debugContentFrame:SetHeight(self.debugLineCount * 14)

        -- Scroll to bottom
        self.debugScrollFrame:SetVerticalScroll(self.debugScrollFrame:GetVerticalScrollRange())
    end

    -- Slash command to toggle debug frame
    SLASH_FTTDEBUG1 = "/fttdebug"
    SlashCmdList["FTTDEBUG"] = function()
        if self.debugFrame:IsShown() then
            self.debugFrame:Hide()
        else
            self.debugFrame:Show()
        end
    end

    print("FTT: Debug Frame initialized! Use /fttdebug to open.")
end
