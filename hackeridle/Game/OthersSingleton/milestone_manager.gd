extends Node

const ACH_FIRST_MILLION_KNOWLEDGE := "achievement_first_million_knowledge"
const ACH_FIRST_MILLION_GOLD := "achievement_first_million_gold"
const ACH_BRAIN_LVL_10 := "achievement_brain_lvl_10"
const ACH_BRAIN_LVL_50 := "achievement_brain_lvl_50"
const ACH_FIRST_REBIRTH := "achievement_first_rebirth"
const ACH_JAIL_FIRST_TIME := "achievement_jail_first_time"

const THRESHOLD_MILLION: float = 1000000.0

const HACKING_MILESTONE_IDS := {
	"achievement_hdmi": true,
	"achievement_wifi_ephad": true,
	"achievement_MIT_flathouse": true,
	"achievement_privilege_escalation_opaline": true,
	"achievement_dns_exfiltration": true,
	"achievement_APT_mirador": true
}

var unlocked: Dictionary = {}
var _pending_news_entries: Array[Dictionary] = []

signal s_milestone_unlocked(milestone_id: String)
signal s_milestone_news_requested(short_id: String, date: Array)


func _ready() -> void:
	if Player.has_signal("s_earn_knowledge_point") and not Player.s_earn_knowledge_point.is_connected(_on_earn_knowledge_point):
		Player.s_earn_knowledge_point.connect(_on_earn_knowledge_point)
	if Player.has_signal("s_earn_gold") and not Player.s_earn_gold.is_connected(_on_earn_gold):
		Player.s_earn_gold.connect(_on_earn_gold)
	if Player.has_signal("s_earn_brain_level") and not Player.s_earn_brain_level.is_connected(_on_earn_brain_level):
		Player.s_earn_brain_level.connect(_on_earn_brain_level)
	sync_from_player_state()


func unlock(milestone_id: String, date: Array = []) -> bool:
	if milestone_id == "":
		return false
	if unlocked.get(milestone_id, false):
		return false
	unlocked[milestone_id] = true
	s_milestone_unlocked.emit(milestone_id)
	var safe_date: Array = date if not date.is_empty() else TimeManager.current_date
	var short_id := milestone_id.trim_prefix("achievement_")
	var entry := {"short_id": short_id, "date": safe_date}
	_pending_news_entries.append(entry)
	s_milestone_news_requested.emit(short_id, safe_date)
	return true


func is_unlocked(milestone_id: String) -> bool:
	return bool(unlocked.get(milestone_id, false))


func notify_first_jail(date: Array = []) -> void:
	unlock(ACH_JAIL_FIRST_TIME, date)


func notify_first_rebirth(date: Array = []) -> void:
	unlock(ACH_FIRST_REBIRTH, date)


func notify_hack_unlocked(item_name: String, date: Array = []) -> void:
	var milestone_id := "achievement_%s" % str(item_name)
	if not HACKING_MILESTONE_IDS.has(milestone_id):
		return
	unlock(milestone_id, date)


func sync_from_player_state() -> void:
	if Player.knowledge_point >= THRESHOLD_MILLION:
		unlock(ACH_FIRST_MILLION_KNOWLEDGE, TimeManager.current_date)
	if Player.gold >= THRESHOLD_MILLION:
		unlock(ACH_FIRST_MILLION_GOLD, TimeManager.current_date)
	if Player.brain_level >= 10:
		unlock(ACH_BRAIN_LVL_10, TimeManager.current_date)
	if Player.brain_level >= 50:
		unlock(ACH_BRAIN_LVL_50, TimeManager.current_date)
	if Player.nb_of_rebirth >= 1:
		unlock(ACH_FIRST_REBIRTH, TimeManager.current_date)


func _on_earn_knowledge_point(total_value: float) -> void:
	if total_value >= THRESHOLD_MILLION:
		unlock(ACH_FIRST_MILLION_KNOWLEDGE, TimeManager.current_date)


func _on_earn_gold(total_value: float) -> void:
	if total_value >= THRESHOLD_MILLION:
		unlock(ACH_FIRST_MILLION_GOLD, TimeManager.current_date)


func _on_earn_brain_level(level: int) -> void:
	if level >= 10:
		unlock(ACH_BRAIN_LVL_10, TimeManager.current_date)
	if level >= 50:
		unlock(ACH_BRAIN_LVL_50, TimeManager.current_date)


func consume_pending_news_entries() -> Array[Dictionary]:
	var copy := _pending_news_entries.duplicate(true)
	_pending_news_entries.clear()
	return copy


func _save_data() -> Dictionary:
	return {
		"unlocked": unlocked.duplicate(true),
		"pending_news_entries": _pending_news_entries.duplicate(true)
	}


func _load_data(content: Dictionary) -> void:
	unlocked = {}
	if content.has("unlocked") and content["unlocked"] is Dictionary:
		unlocked = (content["unlocked"] as Dictionary).duplicate(true)
	_pending_news_entries = []
	if content.has("pending_news_entries") and content["pending_news_entries"] is Array:
		_pending_news_entries = (content["pending_news_entries"] as Array).duplicate(true)
	sync_from_player_state()
