-- Fizzlebee's Treasure Tracker - Korean Locale
local addonName = ...
local L = _G[addonName .. "_Locale"]
if not L or GetLocale() ~= "koKR" then return end

-- General
L["TITLE"] = "Fizzlebee's Treasure Tracker"
L["CLOSE"] = "닫기"
L["RESET"] = "데이터 초기화"
L["SESSION"] = "세션"
L["TOTAL"] = "총계"
L["DURATION"] = "기간"
L["KILLS_PER_SECOND"] = "킬/초"
L["KILLS_PER_HOUR"] = "킬/시간"
L["DAMAGE_PER_SECOND"] = "DPS"
L["SETTINGS"] = "설정"
L["COLLAPSE"] = "접기"
L["EXPAND"] = "펼치기"
L["CLEAR"] = "지우기"
L["CONFIRM"] = "확인"
L["CANCEL"] = "취소"

-- Item Filter
L["ITEM_FILTER"] = "아이템 필터 (아이템 ID)"
L["ITEM_FILTER_HINT"] = "이 ID를 제외한 모든 아이템 숨기기"

-- Treasure
L["TREASURE_NAME"] = "보물 %s"  -- %s = 지역 이름

-- Settings
L["FILTER_BY_ZONE"] = "지역별 필터"
L["SHOW_INACTIVE"] = "오래된 항목 표시"
L["HIDE_INACTIVE"] = "오래된 항목 숨기기"
L["SHOW_BORDER"] = "테두리 표시"
L["AUTO_HEIGHT"] = "자동 높이"
L["AUTO_WIDTH"] = "자동 너비"
L["MIN_ITEM_QUALITY"] = "최소 아이템 품질"
L["QUALITY_ALL"] = "모두"
L["QUALITY_GREEN"] = "녹색+"
L["QUALITY_BLUE"] = "파란색+"
L["QUALITY_PURPLE"] = "보라색+"
L["LOCK_POSITION"] = "위치 잠금"
L["SHOW_ALL_HIDDEN"] = "숨긴 항목 표시"
L["SHOW_DEBUG"] = "디버그 모드"
L["SHOW_GOLD_LINE"] = "골드 라인 표시"
L["SHOW_QUALITY_LINE"] = "품질 라인 표시"
L["SHOW_DURATION_LINE"] = "기간 라인 표시"
L["SHOW_KILLS_LINE"] = "킬 라인 표시"
L["SHOW_DPS_LINE"] = "DPS 라인 표시"

-- Tooltips & Messages
L["HIDE_MOB_TOOLTIP"] = "현재 세션에서 이 몬스터 숨기기"
L["PER_KILL"] = "처치당"
L["LOADED_MESSAGE"] = "로드됨! /ftt로 전환하세요"
L["ALL_DATA_RESET"] = "모든 데이터 초기화됨"
L["ALL_HIDDEN_RESTORED"] = "숨긴 몬스터 모두 복원됨"
L["HIDING_MOB"] = "몬스터 숨기는 중"
L["KILL_MOBS_TEXT"] = "몬스터를 처치하여 추적을 시작하세요..."

-- Confirmation Dialog
L["RESET_CONFIRM_TITLE"] = "데이터 초기화"
L["RESET_CONFIRM_TEXT"] = "모든 데이터를 초기화하시겠습니까? 이 작업은 되돌릴 수 없습니다!"
