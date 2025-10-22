-- ============================================================================
-- Fizzlebee's Treasure Tracker - UI Settings Module
-- Copyright (c) 2025 Vivian Voss (Fizzlebee) <Boulder Dash Heroes>
-- Licensed under the BSD 3-Clause License (see LICENSE file)
-- ============================================================================
-- DEPENDENCIES:
--   - Core.lua: FTT (global table), FTT.L, FTT.settings
--   - Core.lua: FTT:SaveSettings()
--   - UI/Main.lua: FTT.frame, FTT:AutoSizeButton()
--   - UI/Tracker.lua: FTT:UpdateDisplay()
-- EXPORTS:
--   - FTT.settingsFrame → Used by UI/Main.lua (settings button)
--   - FTT.confirmFrame → Used by reset button
--   - FTT:UpdateSettingsUI() → Called by Core.lua:Initialize()
--   - FTT:ApplySettings() → Called by checkbox handlers and Core.lua
--   - FTT:UpdateResizeButton() → Called by ApplySettings()
-- ============================================================================

local addonName, addon = ...
local FTT = _G.FizzlebeesTreasureTracker
local L = FTT.L

-- ============================================================================
-- SETTINGS FRAME
-- ============================================================================

local settingsFrame = CreateFrame("Frame", "FizzlebeesTreasureTrackerSettings", UIParent, "BackdropTemplate")
settingsFrame:SetSize(350, 800)  -- Height increased by 40px
settingsFrame:SetPoint("CENTER", 0, 80)  -- Start higher on screen
settingsFrame:SetFrameStrata("DIALOG")
settingsFrame:SetClampedToScreen(true)
settingsFrame:SetMovable(true)
settingsFrame:EnableMouse(true)
settingsFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 10, right = 10, top = 10, bottom = 10 }
})
settingsFrame:SetBackdropColor(0, 0, 0, 0.9)
settingsFrame:SetBackdropBorderColor(0.8, 0.6, 0, 1)
settingsFrame:Hide()
FTT.settingsFrame = settingsFrame

-- Settings Title
local settingsTitle = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
settingsTitle:SetPoint("TOP", 0, -20)
settingsTitle:SetText(L["SETTINGS"])
settingsTitle:SetTextColor(1, 0.82, 0)

-- Addon Name
local addonNameText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
addonNameText:SetPoint("TOP", settingsTitle, "BOTTOM", 0, -10)
addonNameText:SetText("|cffFFD700Fizzlebee's Treasure Tracker v1.0|r")
addonNameText:SetTextColor(1, 0.82, 0)

-- API Info
local apiText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
apiText:SetPoint("TOP", addonNameText, "BOTTOM", 0, -2)
apiText:SetText("|cffFFD700WoW API 11.0.2 (TWW)|r")
apiText:SetTextColor(1, 0.82, 0)

-- Author Name (Mage Blue)
local authorText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
authorText:SetPoint("TOP", apiText, "BOTTOM", 0, -8)
authorText:SetText("|cff3FC7EBFizzlebee|r")
authorText:SetTextColor(0.247, 0.78, 0.92)

-- Guild Name (Mage Blue)
local guildText = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
guildText:SetPoint("TOP", authorText, "BOTTOM", 0, -2)
guildText:SetText("|cff3FC7EB<Boulder Dash Heroes>|r")
guildText:SetTextColor(0.247, 0.78, 0.92)

-- ============================================================================
-- ITEM FILTER INPUT
-- ============================================================================

local itemFilterLabel = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
itemFilterLabel:SetPoint("TOP", guildText, "BOTTOM", 0, -15)
itemFilterLabel:SetPoint("LEFT", settingsFrame, "LEFT", 20, 0)
itemFilterLabel:SetText(L["ITEM_FILTER"] .. ":")
itemFilterLabel:SetTextColor(1, 0.82, 0)

-- Item Filter Hint Text
local itemFilterHint = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
itemFilterHint:SetPoint("TOPLEFT", itemFilterLabel, "BOTTOMLEFT", 0, -2)
itemFilterHint:SetText(L["ITEM_FILTER_HINT"])
itemFilterHint:SetTextColor(0.7, 0.7, 0.7)
itemFilterHint:SetJustifyH("LEFT")

local itemFilterBox = CreateFrame("EditBox", nil, settingsFrame, "InputBoxTemplate")
itemFilterBox:SetSize(195, 25)
itemFilterBox:SetPoint("TOPLEFT", itemFilterHint, "BOTTOMLEFT", 5, -10)
itemFilterBox:SetAutoFocus(false)
itemFilterBox:SetMaxLetters(10)
itemFilterBox:SetNumeric(true)
itemFilterBox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    FTT.settings.itemFilter = self:GetText()
    FTT:SaveSettings()  -- → Core.lua:SaveSettings()
    FTT:UpdateDisplay()  -- → Tracker.lua:UpdateDisplay()
end)
itemFilterBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)
FTT.itemFilterBox = itemFilterBox

local clearFilterBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
clearFilterBtn:SetSize(60, 25)
clearFilterBtn:SetPoint("LEFT", itemFilterBox, "RIGHT", 10, 0)
clearFilterBtn:SetText(L["CLEAR"])
FTT:AutoSizeButton(clearFilterBtn, 60, 20)  -- → UI/Main.lua:AutoSizeButton()
clearFilterBtn:SetScript("OnClick", function()
    itemFilterBox:SetText("")
    FTT.settings.itemFilter = ""
    FTT:SaveSettings()  -- → Core.lua:SaveSettings()
    FTT:UpdateDisplay()  -- → Tracker.lua:UpdateDisplay()
end)

-- ============================================================================
-- CHECKBOXES
-- ============================================================================

-- Checkbox handler function - called when checkbox changes (by user or programmatically)
local function HandleCheckboxChange(settingKey, affectsLayout)
    -- Save to DB
    FTT:SaveSettings()  -- → Core.lua:SaveSettings()

    -- Check if this is a header line visibility setting
    local isHeaderLineSetting = (settingKey == "showGoldLine" or settingKey == "showQualityLine" or
                                  settingKey == "showDurationLine" or settingKey == "showKillsLine")

    -- Apply the change
    if isHeaderLineSetting then
        FTT:UpdateHeaderLayout()  -- → Update header line positions and visibility
        FTT:UpdateDisplay()  -- → Refresh the mob list
    elseif affectsLayout then
        FTT:ApplySettings()  -- → Reapplies border, resize button, and calls UpdateDisplay
    else
        FTT:UpdateDisplay()  -- → Just refresh the mob list
    end
end

-- Checkbox helper function with relative positioning
-- affectsLayout: true if this setting changes frame appearance (border, size, etc.)
--                false if it only affects content filtering (zone filter, debug, etc.)
local function CreateCheckboxRelative(parent, anchorFrame, yOffset, labelText, settingKey, affectsLayout)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    if anchorFrame then
        checkbox:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, yOffset)
    else
        checkbox:SetPoint("TOPLEFT", 20, yOffset)
    end
    checkbox:SetSize(24, 24)

    local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    label:SetText(labelText)
    label:SetJustifyH("LEFT")

    checkbox:SetScript("OnClick", function(self)
        FTT.settings[settingKey] = self:GetChecked()
        HandleCheckboxChange(settingKey, affectsLayout)
    end)

    return checkbox
end

local checkboxSpacing = -7  -- Reduced by 8px (from -15 to -7)

-- Filter by Zone Checkbox (does NOT affect layout, only filters content)
local filterByZoneCheckbox = CreateCheckboxRelative(settingsFrame, itemFilterBox, -15, L["FILTER_BY_ZONE"], "filterByZone", false)
FTT.filterByZoneCheckbox = filterByZoneCheckbox

-- Transparent Mode Checkbox (DOES affect layout)
local transparentModeCheckbox = CreateCheckboxRelative(settingsFrame, filterByZoneCheckbox, checkboxSpacing, L["TRANSPARENT_MODE"], "transparentMode", true)
FTT.transparentModeCheckbox = transparentModeCheckbox

-- Background Opacity Slider (only enabled when transparentMode is ON)
local opacitySlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
opacitySlider:SetPoint("TOPLEFT", transparentModeCheckbox, "BOTTOMLEFT", 0, -20)
opacitySlider:SetWidth(300)
opacitySlider:SetMinMaxValues(0, 2)
opacitySlider:SetValueStep(1)
opacitySlider:SetObeyStepOnDrag(true)
opacitySlider.tooltipText = L["BACKGROUND_OPACITY"]

-- Slider label
local opacityLabel = opacitySlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
opacityLabel:SetPoint("BOTTOMLEFT", opacitySlider, "TOPLEFT", 0, 0)
opacityLabel:SetText(L["BACKGROUND_OPACITY"])

-- Slider value text (shows 0%, 15%, 30%)
local opacityValueText = opacitySlider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
opacityValueText:SetPoint("BOTTOMRIGHT", opacitySlider, "TOPRIGHT", 0, 0)

-- Function to update value text
local function UpdateOpacityText(value)
    local percentages = {[0] = "0%", [1] = "15%", [2] = "30%"}
    opacityValueText:SetText(percentages[value] or "0%")
end

opacitySlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5) -- Round to nearest integer
    FTT.settings.backgroundOpacity = value
    UpdateOpacityText(value)
    HandleCheckboxChange("backgroundOpacity", true) -- Affects layout (background appearance)
end)

FTT.opacitySlider = opacitySlider
FTT.opacityValueText = opacityValueText

-- Font Scale Slider (affects layout - changes font sizes)
local fontScaleSlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
fontScaleSlider:SetPoint("TOPLEFT", opacitySlider, "BOTTOMLEFT", 0, -30)
fontScaleSlider:SetWidth(300)
fontScaleSlider:SetMinMaxValues(0, 2)
fontScaleSlider:SetValueStep(1)
fontScaleSlider:SetObeyStepOnDrag(true)
fontScaleSlider.tooltipText = L["FONT_SCALE"]

-- Slider label
local fontScaleLabel = fontScaleSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fontScaleLabel:SetPoint("BOTTOMLEFT", fontScaleSlider, "TOPLEFT", 0, 0)
fontScaleLabel:SetText(L["FONT_SCALE"])

-- Slider value text (shows Klein, Mittel, Groß)
local fontScaleValueText = fontScaleSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
fontScaleValueText:SetPoint("BOTTOMRIGHT", fontScaleSlider, "TOPRIGHT", 0, 0)

-- Function to update value text
local function UpdateFontScaleText(value)
    local sizes = {[0] = "Klein", [1] = "Mittel", [2] = "Groß"}
    fontScaleValueText:SetText(sizes[value] or "Mittel")
end

fontScaleSlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5) -- Round to nearest integer
    local oldValue = FTT.settings.fontScale
    FTT.settings.fontScale = value
    UpdateFontScaleText(value)

    -- Save setting
    FTT:SaveSettings()

    -- Apply font scaling immediately (no reload needed!)
    if oldValue ~= value and FTT.ApplyFontScaling then
        FTT:ApplyFontScaling()  -- → Core.lua:ApplyFontScaling()
    end

    -- Fire API callbacks for external addons
    if FTT.FireAPICallbacks then
        FTT:FireAPICallbacks("fontScale")
    end
end)

FTT.fontScaleSlider = fontScaleSlider
FTT.fontScaleValueText = fontScaleValueText

-- Minimum Item Quality Slider (filters items by quality)
-- Slider positions: 0=Alle (links), 1=Grün, 2=Blau, 3=Lila (rechts)
local qualitySlider = CreateFrame("Slider", nil, settingsFrame, "OptionsSliderTemplate")
qualitySlider:SetPoint("TOPLEFT", fontScaleSlider, "BOTTOMLEFT", 0, -30)
qualitySlider:SetWidth(300)
qualitySlider:SetMinMaxValues(0, 3)  -- 4 positions: 0, 1, 2, 3
qualitySlider:SetValueStep(1)
qualitySlider:SetObeyStepOnDrag(true)
qualitySlider.tooltipText = L["MIN_ITEM_QUALITY"]

-- Slider label
local qualityLabel = qualitySlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
qualityLabel:SetPoint("BOTTOMLEFT", qualitySlider, "TOPLEFT", 0, 0)
qualityLabel:SetText(L["MIN_ITEM_QUALITY"])

-- Slider value text (shows All, Green+, Blue+, Purple+)
local qualityValueText = qualitySlider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
qualityValueText:SetPoint("BOTTOMRIGHT", qualitySlider, "TOPRIGHT", 0, 0)

-- Function to update value text
local function UpdateQualityText(value)
    local qualities = {
        [0] = L["QUALITY_ALL"],    -- Quality 0 (all)
        [2] = L["QUALITY_GREEN"],  -- Quality 2 (uncommon+)
        [3] = L["QUALITY_BLUE"],   -- Quality 3 (rare+)
        [4] = L["QUALITY_PURPLE"]  -- Quality 4 (epic+)
    }
    qualityValueText:SetText(qualities[value] or L["QUALITY_ALL"])
end

qualitySlider:SetScript("OnValueChanged", function(self, value)
    value = math.floor(value + 0.5)

    -- Map slider positions to quality values: 0=All(0), 1=Green(2), 2=Blue(3), 3=Purple(4)
    local qualityMap = {[0] = 0, [1] = 2, [2] = 3, [3] = 4}
    local mappedValue = qualityMap[value] or 0

    FTT.settings.minItemQuality = mappedValue
    UpdateQualityText(mappedValue)
    HandleCheckboxChange("minItemQuality", true)
end)

FTT.qualitySlider = qualitySlider
FTT.qualityValueText = qualityValueText

-- Header Line Visibility Checkboxes (affect layout dynamically)
local showGoldLineCheckbox = CreateCheckboxRelative(settingsFrame, qualitySlider, -30, L["SHOW_GOLD_LINE"], "showGoldLine", true)
FTT.showGoldLineCheckbox = showGoldLineCheckbox

local showQualityLineCheckbox = CreateCheckboxRelative(settingsFrame, showGoldLineCheckbox, checkboxSpacing, L["SHOW_QUALITY_LINE"], "showQualityLine", true)
FTT.showQualityLineCheckbox = showQualityLineCheckbox

local showDurationLineCheckbox = CreateCheckboxRelative(settingsFrame, showQualityLineCheckbox, checkboxSpacing, L["SHOW_DURATION_LINE"], "showDurationLine", true)
FTT.showDurationLineCheckbox = showDurationLineCheckbox

local showKillsLineCheckbox = CreateCheckboxRelative(settingsFrame, showDurationLineCheckbox, checkboxSpacing, L["SHOW_KILLS_LINE"], "showKillsLine", true)
FTT.showKillsLineCheckbox = showKillsLineCheckbox

-- Auto Size Checkbox (DOES affect layout - controls both width and height)
local autoSizeCheckbox = CreateCheckboxRelative(settingsFrame, showKillsLineCheckbox, checkboxSpacing, L["AUTO_SIZE"], "autoSize", true)
FTT.autoSizeCheckbox = autoSizeCheckbox

-- Lock Position Checkbox (DOES affect layout - enables/disables dragging)
local lockPositionCheckbox = CreateCheckboxRelative(settingsFrame, autoSizeCheckbox, checkboxSpacing, L["LOCK_POSITION"], "lockPosition", true)
FTT.lockPositionCheckbox = lockPositionCheckbox

-- Show Debug Checkbox (does NOT affect layout, only debug output)
local showDebugCheckbox = CreateCheckboxRelative(settingsFrame, lockPositionCheckbox, checkboxSpacing, L["SHOW_DEBUG"], "showDebug", false)
FTT.showDebugCheckbox = showDebugCheckbox

-- ============================================================================
-- SHOW ALL HIDDEN BUTTON
-- ============================================================================

-- Reset Button (at the very bottom)
local resetBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
resetBtn:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", 15, 15)
resetBtn:SetPoint("BOTTOMRIGHT", settingsFrame, "BOTTOMRIGHT", -15, 15)
resetBtn:SetHeight(30)
resetBtn:SetText(L["RESET"])
resetBtn:GetFontString():SetJustifyH("CENTER")
resetBtn:SetScript("OnClick", function()
    FTT.confirmFrame:Show()
end)

-- Horizontal Line above Reset button
local hrTexture = settingsFrame:CreateTexture(nil, "ARTWORK")
hrTexture:SetPoint("BOTTOMLEFT", resetBtn, "TOPLEFT", -3, 10)
hrTexture:SetPoint("BOTTOMRIGHT", resetBtn, "TOPRIGHT", 3, 10)
hrTexture:SetHeight(1)
hrTexture:SetColorTexture(0.8, 0.6, 0, 0.5)

-- Show All Hidden Mobs Button
local showAllBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelButtonTemplate")
showAllBtn:SetPoint("BOTTOMLEFT", hrTexture, "TOPLEFT", 10, 10)
showAllBtn:SetPoint("BOTTOMRIGHT", hrTexture, "TOPRIGHT", -10, 10)
showAllBtn:SetHeight(30)
showAllBtn:SetText(L["SHOW_ALL_HIDDEN"])
showAllBtn:GetFontString():SetJustifyH("CENTER")
showAllBtn:SetScript("OnClick", function()
    FTT.hiddenMobs = {}
    FTT.hiddenItems = {}
    FTT:UpdateDisplay()  -- → Tracker.lua:UpdateDisplay()
    FTT:InfoPrint("|cffFFD700FTT:|r " .. L["ALL_HIDDEN_RESTORED"])
end)

-- ============================================================================
-- SETTINGS FRAME CONTROLS
-- ============================================================================

-- Settings Close Button
local settingsCloseBtn = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
settingsCloseBtn:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -5, -5)
settingsCloseBtn:SetSize(32, 32)
settingsCloseBtn:SetScript("OnClick", function()
    settingsFrame:Hide()
end)

-- Make settings frame draggable
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
settingsFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

-- ============================================================================
-- CONFIRMATION DIALOG
-- ============================================================================

local confirmFrame = CreateFrame("Frame", "FizzlebeesTreasureTrackerConfirm", UIParent, "BackdropTemplate")
confirmFrame:SetSize(350, 150)
confirmFrame:SetPoint("CENTER", settingsFrame, "CENTER", 0, 0)
confirmFrame:SetFrameStrata("FULLSCREEN_DIALOG")
confirmFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 10, right = 10, top = 10, bottom = 10 }
})
confirmFrame:SetBackdropColor(0, 0, 0, 1)
confirmFrame:SetBackdropBorderColor(1, 0, 0, 1)
confirmFrame:Hide()
FTT.confirmFrame = confirmFrame

-- Confirmation Title
local confirmTitle = confirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
confirmTitle:SetPoint("TOP", 0, -20)
confirmTitle:SetText(L["RESET_CONFIRM_TITLE"])
confirmTitle:SetTextColor(1, 0, 0)

-- Confirmation Text
local confirmText = confirmFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
confirmText:SetPoint("TOP", confirmTitle, "BOTTOM", 0, -15)
confirmText:SetWidth(310)
confirmText:SetText(L["RESET_CONFIRM_TEXT"])
confirmText:SetJustifyH("CENTER")
confirmText:SetWordWrap(true)

-- Confirm Button
local confirmYesBtn = CreateFrame("Button", nil, confirmFrame, "UIPanelButtonTemplate")
confirmYesBtn:SetSize(120, 30)
confirmYesBtn:SetPoint("BOTTOM", confirmFrame, "BOTTOM", -65, 20)
confirmYesBtn:SetText(L["CONFIRM"])
confirmYesBtn:GetFontString():SetJustifyH("CENTER")
confirmYesBtn:SetScript("OnClick", function()
    if FizzlebeesTreasureTrackerDB then
        FizzlebeesTreasureTrackerDB.mobs = {}
        FizzlebeesTreasureTrackerDB.totalGold = 0
        FizzlebeesTreasureTrackerDB.totalDuration = 0
    end
    FTT.sessionKills = {}
    FTT.sessionLoot = {}
    FTT.sessionGold = 0
    FTT.totalGold = 0
    FTT.sessionStartTime = 0
    FTT.totalDuration = 0
    FTT:UpdateDisplay()  -- → Tracker.lua:UpdateDisplay()
    FTT:UpdateGoldDisplay()  -- → UI/Main.lua:UpdateGoldDisplay()
    FTT:UpdateDurationDisplay()  -- → UI/Main.lua:UpdateDurationDisplay()
    FTT:InfoPrint("|cffFFD700FTT:|r " .. L["ALL_DATA_RESET"])
    confirmFrame:Hide()
end)

-- Cancel Button
local confirmNoBtn = CreateFrame("Button", nil, confirmFrame, "UIPanelButtonTemplate")
confirmNoBtn:SetSize(120, 30)
confirmNoBtn:SetPoint("BOTTOM", confirmFrame, "BOTTOM", 65, 20)
confirmNoBtn:SetText(L["CANCEL"])
confirmNoBtn:GetFontString():SetJustifyH("CENTER")
confirmNoBtn:SetScript("OnClick", function()
    confirmFrame:Hide()
end)

-- ============================================================================
-- SETTINGS FUNCTIONS
-- ============================================================================

-- Function to update settings UI from saved settings (visual only)
-- CALLED BY: InitializeSettings()
function FTT:UpdateSettingsUI()
    if self.transparentModeCheckbox then
        self.transparentModeCheckbox:SetChecked(self.settings.transparentMode)
    end
    if self.opacitySlider then
        self.opacitySlider:SetValue(self.settings.backgroundOpacity or 0)
        -- Update text and enable/disable based on transparentMode
        local percentages = {[0] = "0%", [1] = "15%", [2] = "30%"}
        self.opacityValueText:SetText(percentages[self.settings.backgroundOpacity] or "0%")

        -- Enable/disable slider based on transparentMode
        -- Slider is ONLY enabled when transparentMode is ON
        if self.settings.transparentMode then
            self.opacitySlider:Enable()
            self.opacitySlider:SetAlpha(1.0)
        else
            self.opacitySlider:Disable()
            self.opacitySlider:SetAlpha(0.4)
        end
    end
    if self.fontScaleSlider then
        self.fontScaleSlider:SetValue(self.settings.fontScale or 1)
        -- Update text
        local sizes = {[0] = "Klein", [1] = "Mittel", [2] = "Groß"}
        self.fontScaleValueText:SetText(sizes[self.settings.fontScale] or "Mittel")
    end
    if self.qualitySlider then
        -- Reverse map quality values to slider positions: 0 -> 0, 2 -> 1, 3 -> 2, 4 -> 3
        local reverseMap = {[0] = 0, [2] = 1, [3] = 2, [4] = 3}
        local sliderPos = reverseMap[self.settings.minItemQuality] or 0
        self.qualitySlider:SetValue(sliderPos)
        -- Update text
        local qualities = {
            [0] = L["QUALITY_ALL"],
            [2] = L["QUALITY_GREEN"],
            [3] = L["QUALITY_BLUE"],
            [4] = L["QUALITY_PURPLE"]
        }
        self.qualityValueText:SetText(qualities[self.settings.minItemQuality] or L["QUALITY_ALL"])
    end
    if self.showGoldLineCheckbox then
        self.showGoldLineCheckbox:SetChecked(self.settings.showGoldLine)
    end
    if self.showQualityLineCheckbox then
        self.showQualityLineCheckbox:SetChecked(self.settings.showQualityLine)
    end
    if self.showDurationLineCheckbox then
        self.showDurationLineCheckbox:SetChecked(self.settings.showDurationLine)
    end
    if self.showKillsLineCheckbox then
        self.showKillsLineCheckbox:SetChecked(self.settings.showKillsLine)
    end
    if self.autoSizeCheckbox then
        self.autoSizeCheckbox:SetChecked(self.settings.autoSize)
    end
    if self.lockPositionCheckbox then
        self.lockPositionCheckbox:SetChecked(self.settings.lockPosition)
    end
    if self.showDebugCheckbox then
        self.showDebugCheckbox:SetChecked(self.settings.showDebug)
    end
    if self.filterByZoneCheckbox then
        self.filterByZoneCheckbox:SetChecked(self.settings.filterByZone)
    end
    if self.itemFilterBox then
        self.itemFilterBox:SetText(self.settings.itemFilter or "")
    end
end

-- Function to initialize settings on addon load
-- Sets UI checkboxes AND applies the settings (as if user clicked them)
-- CALLED BY: Events.lua (ADDON_LOADED)
function FTT:InitializeSettings()
    -- First, update the UI to match saved settings
    self:UpdateSettingsUI()

    -- Then, trigger the handlers to actually apply the settings
    -- This simulates as if the user had clicked each checkbox

    -- Apply layout-affecting settings (need ApplySettings)
    -- We just call ApplySettings once which handles all layout changes
    self:ApplySettings()
end

-- Function to apply settings to the UI
-- CALLED BY: Checkbox handlers, Core.lua
function FTT:ApplySettings()
    -- Apply transparent mode (border visibility)
    if not self.settings then return end

    local frame = self.frame  -- → UI/Main.lua:frame

    -- transparentMode = true means NO border (transparent with opacity slider)
    -- transparentMode = false means WITH border (normal mode, fixed background)
    if self.settings.transparentMode then
        -- Transparent mode: No border, background opacity controlled by slider
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = nil,
            tile = false,
            tileSize = 0,
            edgeSize = 0,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })

        -- Apply background opacity based on slider setting
        -- 0 = 0% black (fully transparent), 1 = 15% black, 2 = 30% black
        local opacityValue = self.settings.backgroundOpacity or 0
        local alphaValues = {[0] = 0.0, [1] = 0.15, [2] = 0.30}
        local alpha = alphaValues[opacityValue] or 0.0
        frame:SetBackdropColor(0, 0, 0, alpha)

        -- Hide scrollbar when transparent
        if self.scrollFrame and self.scrollFrame.ScrollBar then
            self.scrollFrame.ScrollBar:Hide()
        end

        -- Enable opacity slider in transparent mode
        if self.opacitySlider then
            self.opacitySlider:Enable()
            self.opacitySlider:SetAlpha(1.0)
        end
    else
        -- Normal mode: Show border and fixed background (85% opacity)
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

        -- Show scrollbar when border is visible
        if self.scrollFrame and self.scrollFrame.ScrollBar then
            self.scrollFrame.ScrollBar:Show()
        end

        -- Disable opacity slider in normal mode
        if self.opacitySlider then
            self.opacitySlider:Disable()
            self.opacitySlider:SetAlpha(0.4)
        end
    end

    -- Update resize button visibility based on auto-sizing settings
    self:UpdateResizeButton()

    -- Apply auto height/width (will be updated in UpdateDisplay)
    self:UpdateDisplay()  -- → Tracker.lua:UpdateDisplay()
end

-- Function to update resize button visibility
-- CALLED BY: ApplySettings()
function FTT:UpdateResizeButton()
    if not self.resizeButton then return end

    -- Show/hide resize button based on auto-size setting
    if self.settings.autoSize then
        -- Auto size enabled: hide resize button and disable manual resizing
        self.resizeButton:Hide()
        self.frame:SetResizable(false)
    else
        -- Auto size disabled: show resize button and enable manual resizing
        self.resizeButton:Show()
        self.frame:SetResizable(true)
    end
end
