-- Fizzlebee's Treasure Tracker - Chinese Simplified Locale
local addonName = ...
local L = _G[addonName .. "_Locale"]
if not L or GetLocale() ~= "zhCN" then return end

-- General
L["TITLE"] = "Fizzlebee's Treasure Tracker"
L["CLOSE"] = "关闭"
L["RESET"] = "重置数据"
L["SESSION"] = "当前"
L["TOTAL"] = "总计"
L["DURATION"] = "持续时间"
L["KILLS_PER_SECOND"] = "击杀/秒"
L["KILLS_PER_HOUR"] = "击杀/小时"
L["DAMAGE_PER_SECOND"] = "DPS"
L["SETTINGS"] = "设置"
L["COLLAPSE"] = "折叠"
L["EXPAND"] = "展开"
L["CLEAR"] = "清除"
L["CONFIRM"] = "确认"
L["CANCEL"] = "取消"

-- Item Filter
L["ITEM_FILTER"] = "物品过滤器（物品ID）"
L["ITEM_FILTER_HINT"] = "隐藏除此ID外的所有物品"

-- Settings
L["FILTER_BY_ZONE"] = "按区域过滤"
L["SHOW_INACTIVE"] = "显示旧的"
L["HIDE_INACTIVE"] = "隐藏旧的"
L["SHOW_BORDER"] = "显示边框"
L["AUTO_HEIGHT"] = "自动高度"
L["AUTO_WIDTH"] = "自动宽度"
L["MIN_ITEM_QUALITY"] = "最低物品品质"
L["QUALITY_ALL"] = "全部"
L["QUALITY_GREEN"] = "绿色+"
L["QUALITY_BLUE"] = "蓝色+"
L["QUALITY_PURPLE"] = "紫色+"
L["LOCK_POSITION"] = "锁定位置"
L["SHOW_ALL_HIDDEN"] = "显示隐藏"
L["SHOW_DEBUG"] = "调试模式"
L["SHOW_GOLD_LINE"] = "显示金币行"
L["SHOW_QUALITY_LINE"] = "显示品质行"
L["SHOW_DURATION_LINE"] = "显示持续时间行"
L["SHOW_KILLS_LINE"] = "显示击杀行"
L["SHOW_DPS_LINE"] = "显示DPS行"

-- Tooltips & Messages
L["HIDE_MOB_TOOLTIP"] = "在当前会话中隐藏此生物"
L["PER_KILL"] = "每次击杀"
L["LOADED_MESSAGE"] = "已加载！使用 /ftt 切换"
L["ALL_DATA_RESET"] = "所有数据已重置"
L["ALL_HIDDEN_RESTORED"] = "所有隐藏的生物已恢复"
L["HIDING_MOB"] = "隐藏生物"
L["KILL_MOBS_TEXT"] = "击杀生物以开始追踪..."

-- Confirmation Dialog
L["RESET_CONFIRM_TITLE"] = "重置数据"
L["RESET_CONFIRM_TEXT"] = "您确定要重置所有数据吗？此操作无法撤消！"
