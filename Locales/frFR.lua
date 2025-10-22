-- Fizzlebee's Treasure Tracker - French Locale
local addonName = ...
local L = _G[addonName .. "_Locale"]
if not L or GetLocale() ~= "frFR" then return end

-- General
L["TITLE"] = "Fizzlebee's Treasure Tracker"
L["CLOSE"] = "Fermer"
L["RESET"] = "Réinitialiser les données"
L["SESSION"] = "Session"
L["TOTAL"] = "Total"
L["DURATION"] = "Durée"
L["KILLS_PER_SECOND"] = "Morts/s"
L["KILLS_PER_HOUR"] = "Morts/h"
L["DAMAGE_PER_SECOND"] = "DPS"
L["SETTINGS"] = "Paramètres"
L["COLLAPSE"] = "Réduire"
L["EXPAND"] = "Développer"
L["CLEAR"] = "Effacer"
L["CONFIRM"] = "Confirmer"
L["CANCEL"] = "Annuler"

-- Item Filter
L["ITEM_FILTER"] = "Filtre d'objet (ID d'objet)"
L["ITEM_FILTER_HINT"] = "Masque tous les objets sauf cet ID"

-- Settings
L["FILTER_BY_ZONE"] = "Filtrer par zone"
L["SHOW_INACTIVE"] = "Afficher plus anciens"
L["HIDE_INACTIVE"] = "Masquer plus anciens"
L["SHOW_BORDER"] = "Afficher la bordure"
L["AUTO_HEIGHT"] = "Hauteur automatique"
L["AUTO_WIDTH"] = "Largeur automatique"
L["MIN_ITEM_QUALITY"] = "Qualité minimale d'objet"
L["QUALITY_ALL"] = "Tous"
L["QUALITY_GREEN"] = "Vert+"
L["QUALITY_BLUE"] = "Bleu+"
L["QUALITY_PURPLE"] = "Violet+"
L["LOCK_POSITION"] = "Verrouiller la position"
L["SHOW_ALL_HIDDEN"] = "Afficher les masqués"
L["SHOW_DEBUG"] = "Mode Debug"
L["SHOW_GOLD_LINE"] = "Afficher ligne d'or"
L["SHOW_QUALITY_LINE"] = "Afficher ligne de qualité"
L["SHOW_DURATION_LINE"] = "Afficher ligne de durée"
L["SHOW_KILLS_LINE"] = "Afficher ligne de morts"
L["SHOW_DPS_LINE"] = "Afficher ligne de DPS"

-- Tooltips & Messages
L["HIDE_MOB_TOOLTIP"] = "Masquer cette créature pour la session actuelle"
L["PER_KILL"] = "par kill"
L["LOADED_MESSAGE"] = "chargé! Utilisez /ftt pour basculer"
L["ALL_DATA_RESET"] = "Toutes les données réinitialisées"
L["ALL_HIDDEN_RESTORED"] = "Toutes les créatures masquées restaurées"
L["HIDING_MOB"] = "Masquage de la créature"
L["KILL_MOBS_TEXT"] = "Tuez des créatures pour commencer le suivi..."

-- Confirmation Dialog
L["RESET_CONFIRM_TITLE"] = "Réinitialiser les données"
L["RESET_CONFIRM_TEXT"] = "Êtes-vous sûr de vouloir réinitialiser toutes les données ? Cette action est irréversible !"
