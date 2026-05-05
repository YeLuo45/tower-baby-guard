extends Node

## Achievement System - tracks player accomplishments

signal achievement_unlocked(achievement_id: String, achievement_name: String)

const ACHIEVEMENTS: Array[Dictionary] = [
	{"id": "first_blood", "name": "First Blood", "desc": "Defeat your first enemy", "icon": "⚔️"},
	{"id": "wave_3_clear", "name": "Warming Up", "desc": "Complete wave 3", "icon": "🔥"},
	{"id": "wave_5_clear", "name": "Getting Tough", "desc": "Complete wave 5", "icon": "💪"},
	{"id": "wave_10_clear", "name": "Champion", "desc": "Complete all waves", "icon": "🏆"},
	{"id": "no_damage_wave", "name": "Perfect Defense", "desc": "Complete a wave without taking damage", "icon": "🛡️"},
	{"id": "speed_clear", "name": "Speed Demon", "desc": "Complete wave 5 in under 60 seconds", "icon": "⚡"},
	{"id": "all_towers", "name": "Full Arsenal", "desc": "Place all 5 tower types", "icon": "🎯"},
	{"id": "upgrade_tower", "name": "Power Up", "desc": "Upgrade a tower for the first time", "icon": "⬆️"},
	{"id": "sell_tower", "name": "Restructuring", "desc": "Sell a tower", "icon": "💰"},
	{"id": "level_2_unlock", "name": "New Horizons", "desc": "Unlock level 2", "icon": "🔓"},
]

var _unlocked: Array[String] = []
var _stats: Dictionary = {
	"enemies_killed": 0,
	"waves_completed": 0,
	"gold_earned": 0,
	"towers_placed": {},
	"towers_upgraded": 0,
	"towers_sold": 0,
	"damage_taken": 0,
	"wave_start_time": 0.0,
}

var _notifier: Node = null

func _ready() -> void:
	_load_achievements()

func set_notifier(node: Node) -> void:
	_notifier = node

func _load_achievements() -> void:
	var save_file = FileAccess.get_user://("achievements.dat", FileAccess.READ)
	if save_file:
		var count = save_file.get_8()
		for i in range(count):
			_unlocked.append(save_file.get_line())
		save_file.close()

func _save_achievements() -> void:
	var save_file = FileAccess.get_user://("achievements.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_8(_unlocked.size())
		for ach in _unlocked:
			save_file.store_line(ach)
		save_file.close()

func is_unlocked(achievement_id: String) -> bool:
	return _unlocked.has(achievement_id)

func unlock(achievement_id: String) -> bool:
	if _unlocked.has(achievement_id):
		return false
	
	_unlocked.append(achievement_id)
	_save_achievements()
	
	var ach = _get_achievement(achievement_id)
	if ach:
		achievement_unlocked.emit(achievement_id, ach["name"])
		_show_notification(ach)
	return true

func _get_achievement(achievement_id: String) -> Dictionary:
	for ach in ACHIEVEMENTS:
		if ach["id"] == achievement_id:
			return ach
	return {}

func _show_notification(ach: Dictionary) -> void:
	# Also print to console for now
	print("🏆 Achievement Unlocked: %s - %s" % [ach["name"], ach["desc"]])

# Stats tracking
func on_enemy_killed() -> void:
	_stats["enemies_killed"] += 1
	if _stats["enemies_killed"] == 1:
		unlock("first_blood")

func on_wave_completed(wave_num: int) -> void:
	_stats["waves_completed"] = wave_num
	if wave_num >= 3:
		unlock("wave_3_clear")
	if wave_num >= 5:
		unlock("wave_5_clear")
	if wave_num >= 10:
		unlock("wave_10_clear")

func on_tower_placed(tower_type: String) -> void:
	if not _stats["towers_placed"].has(tower_type):
		_stats["towers_placed"][tower_type] = 0
	_stats["towers_placed"][tower_type] += 1
	if _stats["towers_placed"].size() >= 5:
		unlock("all_towers")

func on_tower_upgraded() -> void:
	_stats["towers_upgraded"] += 1
	if _stats["towers_upgraded"] == 1:
		unlock("upgrade_tower")

func on_tower_sold() -> void:
	_stats["towers_sold"] += 1
	if _stats["towers_sold"] == 1:
		unlock("sell_tower")

func on_damage_taken(amount: int) -> void:
	_stats["damage_taken"] += amount

func on_level_unlocked(level: int) -> void:
	if level >= 2:
		unlock("level_2_unlock")

func check_no_damage_wave() -> void:
	if _stats["damage_taken"] == 0:
		unlock("no_damage_wave")

func get_unlocked_count() -> int:
	return _unlocked.size()

func get_total_count() -> int:
	return ACHIEVEMENTS.size()
