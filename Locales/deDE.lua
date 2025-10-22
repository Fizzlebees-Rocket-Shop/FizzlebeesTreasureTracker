-- Fizzlebee's Treasure Tracker - German Locale
local addonName = ...
local L = _G[addonName .. "_Locale"]
if not L or GetLocale() ~= "deDE" then return end

-- General
L["TITLE"] = "Fizzlebee's Treasure Tracker"
L["CLOSE"] = "Schließen"
L["RESET"] = "Daten zurücksetzen"
L["SESSION"] = "Sitzung"
L["TOTAL"] = "Gesamt"
L["DURATION"] = "Dauer"
L["KILLS_PER_SECOND"] = "Kills/s"
L["KILLS_PER_HOUR"] = "Kills/h"
L["DAMAGE_PER_SECOND"] = "DPS"
L["SETTINGS"] = "Einstellungen"
L["COLLAPSE"] = "Einklappen"
L["EXPAND"] = "Ausklappen"
L["CLEAR"] = "Löschen"
L["CONFIRM"] = "Bestätigen"
L["CANCEL"] = "Abbrechen"

-- Item Filter
L["ITEM_FILTER"] = "Item-Filter (Item-ID)"
L["ITEM_FILTER_HINT"] = "Blendet alle Items außer dieser ID aus"

-- Treasure
L["TREASURE_NAME"] = "Schatz %s"  -- %s = zone name

-- Settings
L["FILTER_BY_ZONE"] = "Nach Zone filtern"
L["SHOW_INACTIVE"] = "Ältere zeigen"
L["HIDE_INACTIVE"] = "Ältere ausblenden"
L["TRANSPARENT_MODE"] = "Transparenter Modus"
L["BACKGROUND_OPACITY"] = "Hintergrunddeckkraft"
L["FONT_SCALE"] = "Schriftgröße"
L["MIN_ITEM_QUALITY"] = "Minimale Itemqualität"
L["QUALITY_ALL"] = "Alle"
L["QUALITY_GREEN"] = "Grün+"
L["QUALITY_BLUE"] = "Blau+"
L["QUALITY_PURPLE"] = "Lila+"
L["AUTO_SIZE"] = "Automatische Größe"
L["LOCK_POSITION"] = "Position sperren"
L["SHOW_ALL_HIDDEN"] = "Verstecktes einblenden"
L["SHOW_DEBUG"] = "Debug Modus"
L["SHOW_GOLD_LINE"] = "Goldzeile anzeigen"
L["SHOW_QUALITY_LINE"] = "Qualitätszeile anzeigen"
L["SHOW_DURATION_LINE"] = "Dauerzeile anzeigen"
L["SHOW_KILLS_LINE"] = "Killszeile anzeigen"
L["SHOW_DPS_LINE"] = "DPS-Zeile anzeigen"

-- Tooltips & Messages
L["HIDE_MOB_TOOLTIP"] = "Diese Kreatur für aktuelle Sitzung ausblenden"
L["HIGHLIGHT_ITEM_TOOLTIP"] = "Markiere ein zu beobachtendes Item. Klicke auf den Button und wähle dann das Item Deiner Wahl."
L["HIGHLIGHT_MODE_ACTIVE"] = "Highlight-Modus aktiv - Klicke auf ein Item zum Markieren"
L["ITEM_HIGHLIGHTED"] = "Item markiert"
L["ITEM_UNHIGHLIGHTED"] = "Item-Markierung entfernt"
L["PER_KILL"] = "pro Kill"
L["LOADED_MESSAGE"] = "geladen! Nutze /ftt zum Umschalten"
L["ALL_DATA_RESET"] = "Alle Daten zurückgesetzt"
L["ALL_HIDDEN_RESTORED"] = "Alle ausgeblendeten Kreaturen wiederhergestellt"
L["HIDING_MOB"] = "Blende Kreatur aus"
L["KILL_MOBS_TEXT"] = "Töte Kreaturen um das Tracking zu starten..."

-- Confirmation Dialog
L["RESET_CONFIRM_TITLE"] = "Daten zurücksetzen"
L["RESET_CONFIRM_TEXT"] = "Bist du sicher, dass du alle Daten zurücksetzen möchtest? Dies kann nicht rückgängig gemacht werden!"
