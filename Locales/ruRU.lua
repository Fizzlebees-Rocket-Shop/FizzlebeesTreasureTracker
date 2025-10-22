-- Fizzlebee's Treasure Tracker - Russian Locale
local addonName = ...
local L = _G[addonName .. "_Locale"]
if not L or GetLocale() ~= "ruRU" then return end

-- General
L["TITLE"] = "Fizzlebee's Treasure Tracker"
L["CLOSE"] = "Закрыть"
L["RESET"] = "Сбросить данные"
L["SESSION"] = "Сессия"
L["TOTAL"] = "Всего"
L["DURATION"] = "Длительность"
L["KILLS_PER_SECOND"] = "Убийств/с"
L["KILLS_PER_HOUR"] = "Убийств/ч"
L["DAMAGE_PER_SECOND"] = "DPS"
L["SETTINGS"] = "Настройки"
L["COLLAPSE"] = "Свернуть"
L["EXPAND"] = "Развернуть"
L["CLEAR"] = "Очистить"
L["CONFIRM"] = "Подтвердить"
L["CANCEL"] = "Отмена"

-- Item Filter
L["ITEM_FILTER"] = "Фильтр предметов (ID предмета)"
L["ITEM_FILTER_HINT"] = "Скрывает все предметы кроме этого ID"

-- Treasure
L["TREASURE_NAME"] = "Сокровище %s"  -- %s = название зоны

-- Settings
L["FILTER_BY_ZONE"] = "Фильтр по зоне"
L["SHOW_INACTIVE"] = "Показать старые"
L["HIDE_INACTIVE"] = "Скрыть старые"
L["SHOW_BORDER"] = "Показать рамку"
L["AUTO_HEIGHT"] = "Автоматическая высота"
L["AUTO_WIDTH"] = "Автоматическая ширина"
L["MIN_ITEM_QUALITY"] = "Минимальное качество предмета"
L["QUALITY_ALL"] = "Все"
L["QUALITY_GREEN"] = "Зелёный+"
L["QUALITY_BLUE"] = "Синий+"
L["QUALITY_PURPLE"] = "Фиолетовый+"
L["LOCK_POSITION"] = "Закрепить позицию"
L["SHOW_ALL_HIDDEN"] = "Показать скрытое"
L["SHOW_DEBUG"] = "Режим отладки"
L["SHOW_GOLD_LINE"] = "Показать строку золота"
L["SHOW_QUALITY_LINE"] = "Показать строку качества"
L["SHOW_DURATION_LINE"] = "Показать строку длительности"
L["SHOW_KILLS_LINE"] = "Показать строку убийств"
L["SHOW_DPS_LINE"] = "Показать строку DPS"

-- Tooltips & Messages
L["HIDE_MOB_TOOLTIP"] = "Скрыть это существо для текущей сессии"
L["PER_KILL"] = "за убийство"
L["LOADED_MESSAGE"] = "загружен! Используйте /ftt для переключения"
L["ALL_DATA_RESET"] = "Все данные сброшены"
L["ALL_HIDDEN_RESTORED"] = "Все скрытые существа восстановлены"
L["HIDING_MOB"] = "Скрытие существа"
L["KILL_MOBS_TEXT"] = "Убейте существ, чтобы начать отслеживание..."

-- Confirmation Dialog
L["RESET_CONFIRM_TITLE"] = "Сбросить данные"
L["RESET_CONFIRM_TEXT"] = "Вы уверены, что хотите сбросить все данные? Это действие необратимо!"
