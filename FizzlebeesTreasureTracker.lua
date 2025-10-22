-- ============================================================================
-- Fizzlebee's Treasure Tracker - Main Initialization File
-- Copyright (c) 2025 Vivian Voss (Fizzlebee) <Boulder Dash Heroes>
-- Licensed under the BSD 3-Clause License (see LICENSE file)
-- ============================================================================
-- This file contains only slash command handlers and serves as the final
-- initialization point for the addon. All other functionality is loaded
-- from the Libs/ directory modules.
--
-- LOAD ORDER (defined in .toc):
--   1. Locales/*.lua (all localization files)
--   2. Libs/Core.lua (FTT table, constants, utilities, data management)
--   3. Libs/UI/Main.lua (main frame, gold/duration display)
--   4. Libs/UI/Settings.lua (settings frame, checkboxes, confirmation dialog)
--   5. Libs/UI/Tracker.lua (mob list display, entry pool, collapse/expand)
--   6. Libs/Events.lua (event handlers for combat, loot, gold tracking)
--   7. THIS FILE (slash commands)
-- ============================================================================

local addonName, addon = ...
local FTT = _G.FizzlebeesTreasureTracker

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

-- Suppress IDE warnings for WoW globals
---@diagnostic disable-next-line: undefined-global
local SlashCmdList = SlashCmdList

SLASH_FIZZLEBEESTREASURETRACKER1 = "/ftt"
SLASH_FIZZLEBEESTREASURETRACKER2 = "/treasure"

SlashCmdList["FIZZLEBEESTREASURETRACKER"] = function(msg)
    msg = msg:lower():trim()

    if msg == "debug" then
        -- Debug command: print session and total data
        FTT:DebugPrint("|cffFFD700FTT Debug:|r === Session Data ===")
        FTT:DebugPrint("|cffFFD700FTT Debug:|r Session Kills:")
        for mob, kills in pairs(FTT.sessionKills) do
            FTT:DebugPrint("  " .. mob .. ": " .. kills)
        end
        FTT:DebugPrint("|cffFFD700FTT Debug:|r Session Loot:")
        for mob, loot in pairs(FTT.sessionLoot) do
            FTT:DebugPrint("  " .. mob .. ":")
            for item, count in pairs(loot) do
                FTT:DebugPrint("    " .. item .. ": " .. count)
            end
        end
        if FizzlebeesTreasureTrackerDB and FizzlebeesTreasureTrackerDB.mobs then
            FTT:DebugPrint("|cffFFD700FTT Debug:|r === Total Data (All Time) ===")
            for mob, data in pairs(FizzlebeesTreasureTrackerDB.mobs) do
                FTT:DebugPrint("  " .. mob .. ": " .. data.kills .. " kills")
                for item, lootData in pairs(data.loot) do
                    FTT:DebugPrint("    " .. item .. ": " .. lootData.count)
                end
            end
        end
    elseif msg == "refresh" or msg == "reset" then
        -- Refresh command: reinitialize display without full reload
        FTT:InfoPrint("|cffFFD700FTT:|r Refreshing display...")
        FTT:UpdateGoldDisplay()
        FTT:UpdateDurationDisplay()
        FTT:UpdateDisplay()
        FTT:InfoPrint("|cffFFD700FTT:|r Display refreshed!")
    elseif msg == "help" then
        -- Help command: show available commands
        FTT:InfoPrint("|cffFFD700Fizzlebee's Treasure Tracker|r - Available Commands:")
        FTT:InfoPrint("  |cffFFD700/ftt|r or |cffFFD700/treasure|r - Toggle tracker window")
        FTT:InfoPrint("  |cffFFD700/ftt refresh|r - Refresh display (if tracker stops updating)")
        FTT:InfoPrint("  |cffFFD700/ftt debug|r - Print debug information")
        FTT:InfoPrint("  |cffFFD700/ftt help|r - Show this help message")
    elseif FTT.frame:IsShown() then
        -- Hide the tracker
        FTT.frame:Hide()
    else
        -- Show the tracker
        FTT.frame:Show()
        FTT:UpdateDisplay()  -- → Libs/UI/Tracker.lua:UpdateDisplay()
    end
end
