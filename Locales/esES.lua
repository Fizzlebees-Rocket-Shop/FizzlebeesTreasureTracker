-- Fizzlebee's Treasure Tracker - Spanish Locale
local addonName = ...
local L = _G[addonName .. "_Locale"]
if not L or (GetLocale() ~= "esES" and GetLocale() ~= "esMX") then return end

-- General
L["TITLE"] = "Fizzlebee's Treasure Tracker"
L["CLOSE"] = "Cerrar"
L["RESET"] = "Restablecer datos"
L["SESSION"] = "Sesión"
L["TOTAL"] = "Total"
L["DURATION"] = "Duración"
L["KILLS_PER_SECOND"] = "Muertes/s"
L["KILLS_PER_HOUR"] = "Muertes/h"
L["DAMAGE_PER_SECOND"] = "DPS"
L["SETTINGS"] = "Configuración"
L["COLLAPSE"] = "Contraer"
L["EXPAND"] = "Expandir"
L["CLEAR"] = "Limpiar"
L["CONFIRM"] = "Confirmar"
L["CANCEL"] = "Cancelar"

-- Item Filter
L["ITEM_FILTER"] = "Filtro de objeto (ID de objeto)"
L["ITEM_FILTER_HINT"] = "Oculta todos los objetos excepto este ID"

-- Settings
L["FILTER_BY_ZONE"] = "Filtrar por zona"
L["SHOW_INACTIVE"] = "Mostrar más antiguos"
L["HIDE_INACTIVE"] = "Ocultar más antiguos"
L["SHOW_BORDER"] = "Mostrar borde"
L["AUTO_HEIGHT"] = "Altura automática"
L["AUTO_WIDTH"] = "Anchura automática"
L["MIN_ITEM_QUALITY"] = "Calidad mínima del objeto"
L["QUALITY_ALL"] = "Todos"
L["QUALITY_GREEN"] = "Verde+"
L["QUALITY_BLUE"] = "Azul+"
L["QUALITY_PURPLE"] = "Morado+"
L["LOCK_POSITION"] = "Bloquear posición"
L["SHOW_ALL_HIDDEN"] = "Mostrar ocultos"
L["SHOW_DEBUG"] = "Modo Debug"
L["SHOW_GOLD_LINE"] = "Mostrar línea de oro"
L["SHOW_QUALITY_LINE"] = "Mostrar línea de calidad"
L["SHOW_DURATION_LINE"] = "Mostrar línea de duración"
L["SHOW_KILLS_LINE"] = "Mostrar línea de muertes"
L["SHOW_DPS_LINE"] = "Mostrar línea de DPS"

-- Tooltips & Messages
L["HIDE_MOB_TOOLTIP"] = "Ocultar esta criatura para la sesión actual"
L["PER_KILL"] = "por muerte"
L["LOADED_MESSAGE"] = "¡cargado! Usa /ftt para alternar"
L["ALL_DATA_RESET"] = "Todos los datos restablecidos"
L["ALL_HIDDEN_RESTORED"] = "Todas las criaturas ocultas restauradas"
L["HIDING_MOB"] = "Ocultando criatura"
L["KILL_MOBS_TEXT"] = "Mata criaturas para comenzar el seguimiento..."

-- Confirmation Dialog
L["RESET_CONFIRM_TITLE"] = "Restablecer datos"
L["RESET_CONFIRM_TEXT"] = "¿Estás seguro de que quieres restablecer todos los datos? ¡Esto no se puede deshacer!"
