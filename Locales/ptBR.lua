-- Fizzlebee's Treasure Tracker - Portuguese (Brazil) Locale
local addonName = ...
local L = _G[addonName .. "_Locale"]
if not L or GetLocale() ~= "ptBR" then return end

-- General
L["TITLE"] = "Fizzlebee's Treasure Tracker"
L["CLOSE"] = "Fechar"
L["RESET"] = "Resetar dados"
L["SESSION"] = "Sessão"
L["TOTAL"] = "Total"
L["DURATION"] = "Duração"
L["KILLS_PER_SECOND"] = "Mortes/s"
L["KILLS_PER_HOUR"] = "Mortes/h"
L["DAMAGE_PER_SECOND"] = "DPS"
L["SETTINGS"] = "Configurações"
L["COLLAPSE"] = "Recolher"
L["EXPAND"] = "Expandir"
L["CLEAR"] = "Limpar"
L["CONFIRM"] = "Confirmar"
L["CANCEL"] = "Cancelar"

-- Item Filter
L["ITEM_FILTER"] = "Filtro de Item (ID do Item)"
L["ITEM_FILTER_HINT"] = "Oculta todos os itens exceto este ID"

-- Settings
L["FILTER_BY_ZONE"] = "Filtrar por Zona"
L["SHOW_INACTIVE"] = "Mostrar mais antigos"
L["HIDE_INACTIVE"] = "Ocultar mais antigos"
L["SHOW_BORDER"] = "Mostrar Borda"
L["AUTO_HEIGHT"] = "Altura Automática"
L["AUTO_WIDTH"] = "Largura Automática"
L["MIN_ITEM_QUALITY"] = "Qualidade mínima do item"
L["QUALITY_ALL"] = "Todos"
L["QUALITY_GREEN"] = "Verde+"
L["QUALITY_BLUE"] = "Azul+"
L["QUALITY_PURPLE"] = "Roxo+"
L["LOCK_POSITION"] = "Travar Posição"
L["SHOW_ALL_HIDDEN"] = "Mostrar Ocultos"
L["SHOW_DEBUG"] = "Modo Debug"
L["SHOW_GOLD_LINE"] = "Mostrar linha de ouro"
L["SHOW_QUALITY_LINE"] = "Mostrar linha de qualidade"
L["SHOW_DURATION_LINE"] = "Mostrar linha de duração"
L["SHOW_KILLS_LINE"] = "Mostrar linha de mortes"
L["SHOW_DPS_LINE"] = "Mostrar linha de DPS"

-- Tooltips & Messages
L["HIDE_MOB_TOOLTIP"] = "Ocultar esta criatura para a sessão atual"
L["PER_KILL"] = "por morte"
L["LOADED_MESSAGE"] = "carregado! Use /ftt para alternar"
L["ALL_DATA_RESET"] = "Todos os dados resetados"
L["ALL_HIDDEN_RESTORED"] = "Todas as criaturas ocultas restauradas"
L["HIDING_MOB"] = "Ocultando criatura"
L["KILL_MOBS_TEXT"] = "Mate criaturas para começar o rastreamento..."

-- Confirmation Dialog
L["RESET_CONFIRM_TITLE"] = "Resetar dados"
L["RESET_CONFIRM_TEXT"] = "Tem certeza de que deseja resetar todos os dados? Isso não pode ser desfeito!"
