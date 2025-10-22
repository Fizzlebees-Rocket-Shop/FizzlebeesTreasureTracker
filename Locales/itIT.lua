-- Fizzlebee's Treasure Tracker - Italian Locale
local addonName = ...
local L = _G[addonName .. "_Locale"]
if not L or GetLocale() ~= "itIT" then return end

-- General
L["TITLE"] = "Fizzlebee's Treasure Tracker"
L["CLOSE"] = "Chiudi"
L["RESET"] = "Ripristina dati"
L["SESSION"] = "Sessione"
L["TOTAL"] = "Totale"
L["DURATION"] = "Durata"
L["KILLS_PER_SECOND"] = "Uccisioni/s"
L["KILLS_PER_HOUR"] = "Uccisioni/h"
L["DAMAGE_PER_SECOND"] = "DPS"
L["SETTINGS"] = "Impostazioni"
L["COLLAPSE"] = "Comprimi"
L["EXPAND"] = "Espandi"
L["CLEAR"] = "Cancella"
L["CONFIRM"] = "Conferma"
L["CANCEL"] = "Annulla"

-- Item Filter
L["ITEM_FILTER"] = "Filtro Oggetto (ID Oggetto)"
L["ITEM_FILTER_HINT"] = "Nasconde tutti gli oggetti tranne questo ID"

-- Settings
L["FILTER_BY_ZONE"] = "Filtra per Zona"
L["SHOW_INACTIVE"] = "Mostra più vecchi"
L["HIDE_INACTIVE"] = "Nascondi più vecchi"
L["SHOW_BORDER"] = "Mostra Bordo"
L["AUTO_HEIGHT"] = "Altezza Automatica"
L["AUTO_WIDTH"] = "Larghezza Automatica"
L["MIN_ITEM_QUALITY"] = "Qualità minima oggetto"
L["QUALITY_ALL"] = "Tutti"
L["QUALITY_GREEN"] = "Verde+"
L["QUALITY_BLUE"] = "Blu+"
L["QUALITY_PURPLE"] = "Viola+"
L["LOCK_POSITION"] = "Blocca Posizione"
L["SHOW_ALL_HIDDEN"] = "Mostra Nascosti"
L["SHOW_DEBUG"] = "Modalità Debug"
L["SHOW_GOLD_LINE"] = "Mostra linea oro"
L["SHOW_QUALITY_LINE"] = "Mostra linea qualità"
L["SHOW_DURATION_LINE"] = "Mostra linea durata"
L["SHOW_KILLS_LINE"] = "Mostra linea uccisioni"
L["SHOW_DPS_LINE"] = "Mostra linea DPS"

-- Tooltips & Messages
L["HIDE_MOB_TOOLTIP"] = "Nascondi questa creatura per la sessione corrente"
L["PER_KILL"] = "per uccisione"
L["LOADED_MESSAGE"] = "caricato! Usa /ftt per alternare"
L["ALL_DATA_RESET"] = "Tutti i dati ripristinati"
L["ALL_HIDDEN_RESTORED"] = "Tutte le creature nascoste ripristinate"
L["HIDING_MOB"] = "Nascondendo creatura"
L["KILL_MOBS_TEXT"] = "Uccidi creature per iniziare il tracciamento..."

-- Confirmation Dialog
L["RESET_CONFIRM_TITLE"] = "Ripristina dati"
L["RESET_CONFIRM_TEXT"] = "Sei sicuro di voler ripristinare tutti i dati? Questa azione non può essere annullata!"
