-- Fizzlebee's Treasure Tracker - Chinese Traditional Locale
local addonName = ...
local L = _G[addonName .. "_Locale"]
if not L or GetLocale() ~= "zhTW" then return end

-- General
L["TITLE"] = "Fizzlebee's Treasure Tracker"
L["CLOSE"] = "關閉"
L["RESET"] = "重置數據"
L["SESSION"] = "當前"
L["TOTAL"] = "總計"
L["DURATION"] = "持續時間"
L["KILLS_PER_SECOND"] = "擊殺/秒"
L["KILLS_PER_HOUR"] = "擊殺/小時"
L["DAMAGE_PER_SECOND"] = "DPS"
L["SETTINGS"] = "設定"
L["COLLAPSE"] = "摺疊"
L["EXPAND"] = "展開"
L["CLEAR"] = "清除"
L["CONFIRM"] = "確認"
L["CANCEL"] = "取消"

-- Item Filter
L["ITEM_FILTER"] = "物品過濾器（物品ID）"
L["ITEM_FILTER_HINT"] = "隱藏除此ID外的所有物品"

-- Settings
L["FILTER_BY_ZONE"] = "按區域過濾"
L["SHOW_INACTIVE"] = "顯示舊的"
L["HIDE_INACTIVE"] = "隱藏舊的"
L["SHOW_BORDER"] = "顯示邊框"
L["AUTO_HEIGHT"] = "自動高度"
L["AUTO_WIDTH"] = "自動寬度"
L["MIN_ITEM_QUALITY"] = "最低物品品質"
L["QUALITY_ALL"] = "全部"
L["QUALITY_GREEN"] = "綠色+"
L["QUALITY_BLUE"] = "藍色+"
L["QUALITY_PURPLE"] = "紫色+"
L["LOCK_POSITION"] = "鎖定位置"
L["SHOW_ALL_HIDDEN"] = "顯示隱藏"
L["SHOW_DEBUG"] = "調試模式"
L["SHOW_GOLD_LINE"] = "顯示金幣行"
L["SHOW_QUALITY_LINE"] = "顯示品質行"
L["SHOW_DURATION_LINE"] = "顯示持續時間行"
L["SHOW_KILLS_LINE"] = "顯示擊殺行"
L["SHOW_DPS_LINE"] = "顯示DPS行"

-- Tooltips & Messages
L["HIDE_MOB_TOOLTIP"] = "在當前會話中隱藏此生物"
L["PER_KILL"] = "每次擊殺"
L["LOADED_MESSAGE"] = "已載入！使用 /ftt 切換"
L["ALL_DATA_RESET"] = "所有數據已重置"
L["ALL_HIDDEN_RESTORED"] = "所有隱藏的生物已恢復"
L["HIDING_MOB"] = "隱藏生物"
L["KILL_MOBS_TEXT"] = "擊殺生物以開始追蹤..."

-- Confirmation Dialog
L["RESET_CONFIRM_TITLE"] = "重置數據"
L["RESET_CONFIRM_TEXT"] = "您確定要重置所有數據嗎？此操作無法撤消！"
