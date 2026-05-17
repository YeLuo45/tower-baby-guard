extends Node

## Persistence System - ConfigFile based save/load for player data
## Manages persistent stats, session stats, and achievements persistence

const SAVE_FILE_PATH = "user://babyguard_save.cfg"

# Persistent stats (across sessions)
var persistent_stats: Dictionary = {
	"total_games_played": 0,
	"total_waves_survived": 0,
	"total_enemies_defeated": 0,
	"total_gold_earned": 0,
	"total_time_played_seconds": 0,
	"best_wave_reached": 0,
	"best_level": 0,
	"last_played_date": "",
	# Tower kill stats
	"mom_kills": 0,
	"dad_kills": 0,
	"grandma_kills": 0,
	"doctor_kills": 0,
	"chef_kills": 0,
	# Special stats
	"perfect_waves": 0,
	"zero_lives_lost_runs": 0,
	"combo_activations": 0,
	"upgrades_purchased": 0,
	# Combo-specific counters (persistent)
	"emergency_room_triggers": 0,
	"family_meal_triggers": 0,
}

# Session stats (reset each game)
var session_stats: Dictionary = {
	"session_waves_survived": 0,
	"session_enemies_defeated": 0,
	"session_gold_earned": 0,
	"session_start_time": 0.0,
	"session_tower_kills": {},
	"session_combos_triggered": 0,
	"session_upgrades_bought": 0,
	"session_tower_types_placed": [],
	"perfect_wave_this_run": true,  # Track if player hasn't lost lives this wave
	"lives_lost_this_wave": 0,
	"wave_start_time": 0.0,
	"wave_1_start_time": 0.0,  # For speedrunner achievement
}

# Achievements unlocked with dates
var achievements_unlocked: Dictionary = {}

# Level stars (world_X_scene_Y -> stars 0-3)
var level_stars: Dictionary = {}

signal stats_loaded
signal stats_saved

func _ready() -> void:
	load_game()

## Load game from ConfigFile
func load_game() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILE_PATH)
	
	if err != OK:
		# New game, start with defaults
		_initialize_defaults()
		return
	
	# Load player section
	var player_section = config.get_section_keys("player")
	for key in player_section:
		if persistent_stats.has(key):
			persistent_stats[key] = config.get_value("player", key)
	
	# Load stats section
	var stats_section = config.get_section_keys("stats")
	for key in stats_section:
		if persistent_stats.has(key):
			persistent_stats[key] = config.get_value("stats", key)
	
	# Load achievements
	var achievements_section = config.get_section_keys("achievements")
	for key in achievements_section:
		achievements_unlocked[key] = config.get_value("achievements", key)

	# Load level stars
	var stars_section = config.get_section_keys("level_stars")
	for key in stars_section:
		level_stars[key] = config.get_value("level_stars", key)
	
	stats_loaded.emit()

## Initialize default values for new player
func _initialize_defaults() -> void:
	persistent_stats["last_played_date"] = _get_current_date()
	achievements_unlocked = {}

## Save game to ConfigFile
func save_game() -> void:
	var config = ConfigFile.new()
	
	# Update last played date
	persistent_stats["last_played_date"] = _get_current_date()
	
	# Save player section
	config.set_value("player", "total_games_played", persistent_stats["total_games_played"])
	config.set_value("player", "total_waves_survived", persistent_stats["total_waves_survived"])
	config.set_value("player", "total_enemies_defeated", persistent_stats["total_enemies_defeated"])
	config.set_value("player", "total_gold_earned", persistent_stats["total_gold_earned"])
	config.set_value("player", "total_time_played_seconds", persistent_stats["total_time_played_seconds"])
	config.set_value("player", "best_wave_reached", persistent_stats["best_wave_reached"])
	config.set_value("player", "best_level", persistent_stats["best_level"])
	config.set_value("player", "last_played_date", persistent_stats["last_played_date"])
	
	# Save stats section
	config.set_value("stats", "mom_kills", persistent_stats["mom_kills"])
	config.set_value("stats", "dad_kills", persistent_stats["dad_kills"])
	config.set_value("stats", "grandma_kills", persistent_stats["grandma_kills"])
	config.set_value("stats", "doctor_kills", persistent_stats["doctor_kills"])
	config.set_value("stats", "chef_kills", persistent_stats["chef_kills"])
	config.set_value("stats", "perfect_waves", persistent_stats["perfect_waves"])
	config.set_value("stats", "zero_lives_lost_runs", persistent_stats["zero_lives_lost_runs"])
	config.set_value("stats", "combo_activations", persistent_stats["combo_activations"])
	config.set_value("stats", "upgrades_purchased", persistent_stats["upgrades_purchased"])
	config.set_value("stats", "emergency_room_triggers", persistent_stats["emergency_room_triggers"])
	config.set_value("stats", "family_meal_triggers", persistent_stats["family_meal_triggers"])
	
	# Save achievements
	for ach_id in achievements_unlocked:
		config.set_value("achievements", ach_id + "_unlocked", true)
		config.set_value("achievements", ach_id + "_date", achievements_unlocked[ach_id])

	# Save level stars
	for star_key in level_stars:
		config.set_value("level_stars", star_key, level_stars[star_key])
	
	var err = config.save(SAVE_FILE_PATH)
	if err == OK:
		stats_saved.emit()
	else:
		push_warning("Failed to save game: error %d" % err)

## Start new session
func start_session() -> void:
	session_stats = {
		"session_waves_survived": 0,
		"session_enemies_defeated": 0,
		"session_gold_earned": 0,
		"session_start_time": Time.get_unix_time_from_system(),
		"session_tower_kills": {},
		"session_combos_triggered": 0,
		"session_upgrades_bought": 0,
		"session_tower_types_placed": [],
		"perfect_wave_this_run": true,
		"lives_lost_this_wave": 0,
		"wave_start_time": Time.get_unix_time_from_system(),
		"wave_1_start_time": 0.0,
	}

## Merge session stats into persistent stats (on game end)
func merge_session_to_persistent() -> void:
	persistent_stats["total_games_played"] += 1
	persistent_stats["total_waves_survived"] += session_stats["session_waves_survived"]
	persistent_stats["total_enemies_defeated"] += session_stats["session_enemies_defeated"]
	persistent_stats["total_gold_earned"] += session_stats["session_gold_earned"]
	
	# Update best wave
	if session_stats["session_waves_survived"] > persistent_stats["best_wave_reached"]:
		persistent_stats["best_wave_reached"] = session_stats["session_waves_survived"]
	
	# Update time played
	if session_stats["session_start_time"] > 0:
		var session_duration = Time.get_unix_time_from_system() - session_stats["session_start_time"]
		persistent_stats["total_time_played_seconds"] += int(session_duration)
	
	# Merge tower kills
	for tower_type in session_stats["session_tower_kills"]:
		var kills = session_stats["session_tower_kills"][tower_type]
		var key = tower_type.to_lower() + "_kills"
		if persistent_stats.has(key):
			persistent_stats[key] += kills
	
	persistent_stats["combo_activations"] += session_stats["session_combos_triggered"]
	persistent_stats["upgrades_purchased"] += session_stats["session_upgrades_bought"]
	
	# Track perfect waves and zero lives lost runs
	if session_stats["perfect_wave_this_run"] and session_stats["lives_lost_this_wave"] == 0:
		persistent_stats["zero_lives_lost_runs"] += 1

## Session tracking methods
func record_enemy_killed(tower_type: String) -> void:
	session_stats["session_enemies_defeated"] += 1
	
	if not session_stats["session_tower_kills"].has(tower_type):
		session_stats["session_tower_kills"][tower_type] = 0
	session_stats["session_tower_kills"][tower_type] += 1

func record_gold_earned(amount: int) -> void:
	session_stats["session_gold_earned"] += amount

func record_combo_triggered() -> void:
	session_stats["session_combos_triggered"] += 1

func record_upgrade_purchased() -> void:
	session_stats["session_upgrades_bought"] += 1

func record_tower_placed(tower_type: String) -> void:
	if not session_stats["session_tower_types_placed"].has(tower_type):
		session_stats["session_tower_types_placed"].append(tower_type)

func record_wave_started(wave_num: int) -> void:
	if wave_num == 1:
		session_stats["wave_1_start_time"] = Time.get_unix_time_from_system()
	session_stats["wave_start_time"] = Time.get_unix_time_from_system()
	session_stats["perfect_wave_this_run"] = true  # Reset for new wave
	session_stats["lives_lost_this_wave"] = 0

func record_wave_completed(wave_num: int) -> void:
	session_stats["session_waves_survived"] = wave_num
	if session_stats["perfect_wave_this_run"]:
		persistent_stats["perfect_waves"] += 1

func record_lives_lost(amount: int) -> void:
	session_stats["perfect_wave_this_run"] = false
	session_stats["lives_lost_this_wave"] += amount

func record_emergency_room_triggered() -> void:
	persistent_stats["emergency_room_triggers"] += 1

func record_family_meal_triggered() -> void:
	persistent_stats["family_meal_triggers"] += 1

## Achievement unlock helpers
func is_achievement_unlocked(achievement_id: String) -> bool:
	return achievements_unlocked.has(achievement_id)

func unlock_achievement(achievement_id: String) -> bool:
	if achievements_unlocked.has(achievement_id):
		return false  # Already unlocked
	
	achievements_unlocked[achievement_id] = _get_current_date()
	return true

func get_achievement_unlock_date(achievement_id: String) -> String:
	return achievements_unlocked.get(achievement_id, "")

## Utility
func _get_current_date() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [datetime["year"], datetime["month"], datetime["day"]]

## Get stats for UI
func get_persistent_stat(key: String):
	return persistent_stats.get(key, 0)

func get_session_stat(key: String):
	return session_stats.get(key, 0)

func get_tower_kills_session(tower_type: String) -> int:
	return session_stats["session_tower_kills"].get(tower_type, 0)

func get_tower_kills_persistent(tower_type: String) -> int:
	var key = tower_type.to_lower() + "_kills"
	return persistent_stats.get(key, 0)

## Level stars management
func record_level_stars(world_idx: int, scene_idx: int, stars: int) -> void:
	var key = "world_%d_scene_%d" % [world_idx, scene_idx]
	var current_stars = level_stars.get(key, 0)
	# Only update if new stars is higher (preserve best)
	if stars > current_stars:
		level_stars[key] = stars

func get_level_stars(world_idx: int, scene_idx: int) -> int:
	var key = "world_%d_scene_%d" % [world_idx, scene_idx]
	return level_stars.get(key, 0)