extends Node

## Achievement System - tracks player accomplishments (20 achievements)
## Divided into categories: Basic (8), Tower Master (5), Combo Master (4), Rare (3)

signal achievement_unlocked(achievement_id: String, achievement_name: String, category: String)

enum Category { BASIC, TOWER_MASTER, COMBO_MASTER, RARE }

const ACHIEVEMENTS: Array[Dictionary] = [
	# === BASIC (8) ===
	{"id": "first_steps", "name": "第一次", "desc": "Complete your first wave", "icon": "👶", "category": Category.BASIC},
	{"id": "home_defender", "name": "家园守护者", "desc": "Complete level 1", "icon": "🏠", "category": Category.BASIC},
	{"id": "goldrush", "name": "淘金者", "desc": "Earn 500 gold in one run", "icon": "💰", "category": Category.BASIC},
	{"id": "combo_starter", "name": "组合新手", "desc": "Trigger your first combo", "icon": "✨", "category": Category.BASIC},
	{"id": "upgrade_buyer", "name": "升级达人", "desc": "Purchase your first upgrade", "icon": "⬆️", "category": Category.BASIC},
	{"id": "perfectionist", "name": "完美主义者", "desc": "Complete a wave with full lives", "icon": "⭐", "category": Category.BASIC},
	{"id": "speedrunner", "name": "速通达人", "desc": "Complete wave 1-5 within 3 minutes", "icon": "⚡", "category": Category.BASIC},
	{"id": "veteran", "name": "老练家长", "desc": "Play 10 games", "icon": "🎖️", "category": Category.BASIC},
	
	# === TOWER MASTER (5) ===
	{"id": "mom_love", "name": "妈妈的爱", "desc": "Win with Mom tower as top killer", "icon": "👩", "category": Category.TOWER_MASTER},
	{"id": "dad_protect", "name": "爸爸的保护", "desc": "Win using only Dad towers", "icon": "👨", "category": Category.TOWER_MASTER},
	{"id": "grandma_wisdom", "name": "奶奶的智慧", "desc": "Stun 20 enemies in one run", "icon": "👵", "category": Category.TOWER_MASTER},
	{"id": "doctor_heal", "name": "医生的救治", "desc": "Emergency Room combo triggered", "icon": "🩺", "category": Category.TOWER_MASTER},
	{"id": "chef_special", "name": "厨师的特供", "desc": "Kill 10 enemies with Chef in one run", "icon": "👨‍🍳", "category": Category.TOWER_MASTER},
	
	# === COMBO MASTER (4) ===
	{"id": "full_house_achieved", "name": "四世同堂", "desc": "Trigger Full House combo", "icon": "🏡", "category": Category.COMBO_MASTER},
	{"id": "combo_chain", "name": "连锁反应", "desc": "Trigger 3 different combos in one wave", "icon": "🔗", "category": Category.COMBO_MASTER},
	{"id": "emergency_doctor", "name": "急诊室", "desc": "Emergency Room triggered 3 times total", "icon": "🚑", "category": Category.COMBO_MASTER},
	{"id": "master_chef", "name": "主厨的盛宴", "desc": "Family Meal triggered 5 times total", "icon": "🍳", "category": Category.COMBO_MASTER},
	
	# === RARE (3) ===
	{"id": "flawless_victory", "name": "完美胜利", "desc": "Complete level 1 with zero lives lost", "icon": "🌟", "category": Category.RARE},
	{"id": "economist", "name": "经济学家", "desc": "Finish with over 500 gold remaining", "icon": "📊", "category": Category.RARE},
	{"id": "all_towers", "name": "全员到齐", "desc": "Have all 5 tower types in one game", "icon": "🎯", "category": Category.RARE},
	{"id": "skill_collector", "name": "技能收集者", "desc": "Unlock 5 different skills", "icon": "📜", "category": Category.RARE},
]

# Session tracking for achievements
var _session_combos_this_wave: Array = []
var _session_combos_this_run: int = 0
var _session_stuns: int = 0

func _ready() -> void:
	# PersistenceSystem is an autoload, use it
	pass

## Check if achievement is unlocked
func is_unlocked(achievement_id: String) -> bool:
	return Persistence.is_achievement_unlocked(achievement_id)

## Unlock an achievement
func _do_unlock(achievement_id: String) -> bool:
	var ach = _get_achievement(achievement_id)
	if ach.is_empty():
		return false
	
	var category_name = _get_category_name(ach["category"])
	var unlocked = Persistence.unlock_achievement(achievement_id)
	
	if unlocked:
		# Emit signal for popup
		achievement_unlocked.emit(achievement_id, ach["name"], category_name)
		# Show the popup if AchievementPopup is available
		_show_popup(ach)
		# Auto-save
		Persistence.save_game()
	
	return unlocked

func _show_popup(ach: Dictionary) -> void:
	var notifier = Engine.get_main_loop().root.find_child("AchievementNotifier", true, false)
	if notifier and notifier.has_method("show_achievement"):
		notifier.show_achievement(ach["icon"], ach["name"], ach["desc"])

func _get_achievement(achievement_id: String) -> Dictionary:
	for ach in ACHIEVEMENTS:
		if ach["id"] == achievement_id:
			return ach
	return {}

func _get_category_name(category: Category) -> String:
	match category:
		Category.BASIC: return "Basic"
		Category.TOWER_MASTER: return "Tower Master"
		Category.COMBO_MASTER: return "Combo Master"
		Category.RARE: return "Rare"
	return "Unknown"

func get_achievements_by_category(category: Category) -> Array:
	return ACHIEVEMENTS.filter(func(a): return a["category"] == category)

func get_all_achievements() -> Array:
	return ACHIEVEMENTS

func get_unlocked_achievements() -> Array:
	return ACHIEVEMENTS.filter(func(a): return is_unlocked(a["id"]))

func get_locked_achievements() -> Array:
	return ACHIEVEMENTS.filter(func(a): return not is_unlocked(a["id"]))

## === Event Handlers (called from game.gd) ===

func on_wave_started(wave_num: int) -> void:
	_session_combos_this_wave.clear()
	Persistence.record_wave_started(wave_num)
	check_achievements()

func on_wave_completed(wave_num: int) -> void:
	Persistence.record_wave_completed(wave_num)
	
	# first_steps - complete first wave
	if wave_num >= 1 and not is_unlocked("first_steps"):
		_do_unlock("first_steps")
	
	# home_defender - complete level 1 (all 10 waves)
	if wave_num >= 10:
		_do_unlock("home_defender")
	
	# perfectionist - wave with no lives lost
	if Persistence.session_stats["perfect_wave_this_run"]:
		_do_unlock("perfectionist")
	
	# speedrunner - waves 1-5 within 3 minutes (180 seconds)
	if wave_num >= 5:
		var elapsed = Time.get_unix_time_from_system() - Persistence.session_stats["wave_1_start_time"]
		if elapsed <= 180.0:
			_do_unlock("speedrunner")
	
	check_achievements()

func on_enemy_killed(tower_type: String) -> void:
	Persistence.record_enemy_killed(tower_type)
	
	# grandma_wisdom - stun 20 enemies
	# This should be called from grandma tower when stun lands
	if tower_type == "Grandma":
		_session_stuns += 1
		if _session_stuns >= 20:
			_do_unlock("grandma_wisdom")
	
	# chef_special - Chef kills 10
	if tower_type == "Chef":
		var chef_kills = Persistence.get_tower_kills_session("Chef")
		if chef_kills >= 10:
			_do_unlock("chef_special")
	
	check_achievements()

func on_tower_placed(tower_type: String) -> void:
	Persistence.record_tower_placed(tower_type)
	
	# all_towers - all 5 tower types in one game
	var placed_types = Persistence.session_stats["session_tower_types_placed"]
	if placed_types.size() >= 5:
		_do_unlock("all_towers")
	
	check_achievements()

func on_tower_upgraded() -> void:
	Persistence.record_upgrade_purchased()
	
	# upgrade_buyer - first upgrade
	if Persistence.session_stats["session_upgrades_bought"] >= 1:
		_do_unlock("upgrade_buyer")
	
	check_achievements()

func on_tower_sold() -> void:
	# No achievement for selling yet
	pass

func on_combo_triggered(combo_name: String) -> void:
	Persistence.record_combo_triggered()
	_session_combos_this_run += 1
	
	# combo_starter - first combo
	_do_unlock("combo_starter")
	
	# Track combos per wave
	if not _session_combos_this_wave.has(combo_name):
		_session_combos_this_wave.append(combo_name)
	
	# combo_chain - 3 different combos in one wave
	if _session_combos_this_wave.size() >= 3:
		_do_unlock("combo_chain")
	
	# full_house_achieved
	if combo_name == "Full House":
		_do_unlock("full_house_achieved")
	
	# emergency_doctor - Emergency Room triggered 3 times total
	if combo_name == "Emergency Room":
		Persistence.record_emergency_room_triggered()
		if Persistence.persistent_stats["emergency_room_triggers"] >= 3:
			_do_unlock("emergency_doctor")
	
	# master_chef - Family Meal triggered 5 times total
	if combo_name == "Family Meal":
		Persistence.record_family_meal_triggered()
		if Persistence.persistent_stats["family_meal_triggers"] >= 5:
			_do_unlock("master_chef")
	
	check_achievements()

func on_emergency_room_triggered() -> void:
	# doctor_heal - Emergency Room triggered
	_do_unlock("doctor_heal")
	check_achievements()

func on_gold_earned(amount: int) -> void:
	# goldrush - 500 gold in one run
	var total = Persistence.session_stats["session_gold_earned"]
	if total >= 500 and not is_unlocked("goldrush"):
		_do_unlock("goldrush")
	check_achievements()

func on_game_end(victory: bool, lives_remaining: int, gold_remaining: int) -> void:
	# veteran - 10 games
	if Persistence.persistent_stats["total_games_played"] >= 10:
		_do_unlock("veteran")
	
	# economist - finish with >500 gold
	if victory and gold_remaining > 500:
		_do_unlock("economist")
	
	# flawless_victory - level 1 with no HP lost (all 10 waves, full lives)
	if victory and lives_remaining >= 20:
		_do_unlock("flawless_victory")
	
	# mom_love - Mom tower top killer
	var tower_kills = Persistence.session_stats["session_tower_kills"]
	if tower_kills.size() > 0:
		var top_type = ""
		var top_kills = 0
		for t in tower_kills:
			if tower_kills[t] > top_kills:
				top_kills = tower_kills[t]
				top_type = t
		if top_type == "Mom" and victory:
			_do_unlock("mom_love")
	
	# dad_protect - only Dad towers placed
	var placed_types = Persistence.session_stats["session_tower_types_placed"]
	if placed_types.size() == 1 and placed_types[0] == "Dad" and victory:
		_do_unlock("dad_protect")
	
	# Merge session to persistent
	Persistence.merge_session_to_persistent()
	Persistence.save_game()
	check_achievements()

func on_stun_applied() -> void:
	_session_stuns += 1
	if _session_stuns >= 20:
		_do_unlock("grandma_wisdom")

func on_skill_unlocked(skill_count: int) -> void:
	if skill_count >= 5:
		_do_unlock("skill_collector")

func on_lives_changed(old_lives: int, new_lives: int) -> void:
	if new_lives < old_lives:
		Persistence.record_lives_lost(old_lives - new_lives)

## Master check function (can be called periodically)
func check_achievements() -> void:
	pass  # Achievements are checked inline with events for performance

## Get achievement progress info
func get_achievement_progress(achievement_id: String) -> Dictionary:
	var ach = _get_achievement(achievement_id)
	if ach.is_empty():
		return {}
	
	var progress = {"current": 0, "target": 1, "unlocked": is_unlocked(achievement_id)}
	
	match achievement_id:
		"veteran":
			progress["current"] = Persistence.persistent_stats["total_games_played"]
			progress["target"] = 10
		"grandma_wisdom":
			progress["current"] = _session_stuns
			progress["target"] = 20
		"chef_special":
			progress["current"] = Persistence.get_tower_kills_session("Chef")
			progress["target"] = 10
		"emergency_doctor":
			progress["current"] = Persistence.persistent_stats["emergency_room_triggers"]
			progress["target"] = 3
		"master_chef":
			progress["current"] = Persistence.persistent_stats["family_meal_triggers"]
			progress["target"] = 5
		"goldrush":
			progress["current"] = Persistence.session_stats["session_gold_earned"]
			progress["target"] = 500
		"economist":
			progress["current"] = 0  # Only known at game end
			progress["target"] = 500
	
	return progress

func get_unlocked_count() -> int:
	return get_unlocked_achievements().size()

func get_total_count() -> int:
	return ACHIEVEMENTS.size()