extends Node
## Tracks and manages world progress across waves, levels, and milestones.
class_name WorldProgress

# World state
var current_world: int = 1
var current_level: int = 1
var current_wave: int = 0
var total_waves: int = 10

# Progress tracking
var enemies_defeated: int = 0
var towers_placed: int = 0
var gold_earned: int = 0
var total_damage_dealt: int = 0

# Milestone tracking
var milestones_achieved: Array[String] = []
var wave_completion_times: Array[float] = []

# Difficulty scaling
var difficulty_multiplier: float = 1.0
var enemy_spawn_rate_modifier: float = 1.0

# World/Level configuration
const MAX_WORLDS: int = 7
const MAX_LEVELS_PER_WORLD: int = 10
const WAVES_PER_LEVEL: int = 10

signal wave_started(wave: int, total: int)
signal wave_completed(wave: int, time_elapsed: float)
signal level_completed(level: int, world: int)
signal world_completed(world: int)
signal milestone_achieved(milestone_id: String)
signal progress_updated()

func _ready() -> void:
	_reset_progress()

func _reset_progress() -> void:
	current_world = 1
	current_level = 1
	current_wave = 0
	total_waves = WAVES_PER_LEVEL
	enemies_defeated = 0
	towers_placed = 0
	gold_earned = 0
	total_damage_dealt = 0
	milestones_achieved = []
	wave_completion_times = []
	difficulty_multiplier = 1.0
	enemy_spawn_rate_modifier = 1.0

## Start the next wave
func start_wave() -> void:
	current_wave += 1
	var time_elapsed := _get_wave_time()
	wave_completion_times.append(time_elapsed)
	wave_started.emit(current_wave, total_waves)
	progress_updated.emit()

## Complete current wave and advance
func complete_wave() -> void:
	var time_elapsed := _get_wave_time() if wave_completion_times.size() < current_wave else 0.0
	wave_completed.emit(current_wave, time_elapsed)
	
	if current_wave >= total_waves:
		_complete_level()
	else:
		progress_updated.emit()

func _complete_level() -> void:
	level_completed.emit(current_level, current_world)
	
	# Advance to next level or world
	if current_level >= MAX_LEVELS_PER_WORLD:
		_complete_world()
	else:
		current_level += 1
		current_wave = 0
		_apply_difficulty_scaling()
		progress_updated.emit()

func _complete_world() -> void:
	world_completed.emit(current_world)
	
	if current_world >= MAX_WORLDS:
		push_warning("[WorldProgress] Reached maximum world!")
	else:
		current_world += 1
		current_level = 1
		current_wave = 0
		_apply_difficulty_scaling()
		progress_updated.emit()

## Record enemy defeat
func record_enemy_defeated(gold_value: int = 0, damage: int = 0) -> void:
	enemies_defeated += 1
	if gold_value > 0:
		gold_earned += gold_value
	if damage > 0:
		total_damage_dealt += damage
	_check_milestones()
	progress_updated.emit()

## Record tower placement
func record_tower_placed() -> void:
	towers_placed += 1
	_check_milestones()
	progress_updated.emit()

## Record gold earned
func record_gold(amount: int) -> void:
	gold_earned += amount
	progress_updated.emit()

## Record damage dealt
func record_damage(amount: int) -> void:
	total_damage_dealt += amount
	progress_updated.emit()

## Check and unlock milestones
func _check_milestones() -> void:
	# Wave milestones
	if current_wave == 5 and "wave_5" not in milestones_achieved:
		_unlock_milestone("wave_5")
	if current_wave == 10 and "wave_10" not in milestones_achieved:
		_unlock_milestone("wave_10")
	
	# Enemy milestones
	if enemies_defeated >= 50 and "enemies_50" not in milestones_achieved:
		_unlock_milestone("enemies_50")
	if enemies_defeated >= 100 and "enemies_100" not in milestones_achieved:
		_unlock_milestone("enemies_100")
	if enemies_defeated >= 500 and "enemies_500" not in milestones_achieved:
		_unlock_milestone("enemies_500")
	
	# Tower milestones
	if towers_placed >= 10 and "towers_10" not in milestones_achieved:
		_unlock_milestone("towers_10")
	if towers_placed >= 25 and "towers_25" not in milestones_achieved:
		_unlock_milestone("towers_25")
	
	# Gold milestones
	if gold_earned >= 1000 and "gold_1k" not in milestones_achieved:
		_unlock_milestone("gold_1k")
	if gold_earned >= 5000 and "gold_5k" not in milestones_achieved:
		_unlock_milestone("gold_5k")
	
	# World/Level milestones
	if current_level >= 5 and "level_5" not in milestones_achieved:
		_unlock_milestone("level_5")
	if current_world >= 3 and "world_3" not in milestones_achieved:
		_unlock_milestone("world_3")

func _unlock_milestone(milestone_id: String) -> void:
	milestones_achieved.append(milestone_id)
	milestone_achieved.emit(milestone_id)
	progress_updated.emit()

## Apply difficulty scaling per level
func _apply_difficulty_scaling() -> void:
	# Increase difficulty per level completed
	var level_progress := (current_level - 1) + (current_world - 1) * MAX_LEVELS_PER_WORLD
	difficulty_multiplier = 1.0 + level_progress * 0.1
	enemy_spawn_rate_modifier = 1.0 + level_progress * 0.05

## Get wave elapsed time helper
func _get_wave_time() -> float:
	return 0.0  # Override in subclasses or connect to game timer

## Get progress percentage for current wave
func get_wave_progress() -> float:
	if total_waves <= 0:
		return 0.0
	return float(current_wave) / float(total_waves)

## Get overall world progress
func get_world_progress() -> float:
	var total_levels := MAX_WORLDS * MAX_LEVELS_PER_WORLD
	var completed := (current_world - 1) * MAX_LEVELS_PER_WORLD + (current_level - 1)
	return float(completed) / float(total_levels)

## Get current difficulty level description
func get_difficulty_description() -> String:
	if difficulty_multiplier < 1.2:
		return "Easy"
	elif difficulty_multiplier < 1.5:
		return "Normal"
	elif difficulty_multiplier < 2.0:
		return "Hard"
	else:
		return "Expert"

## Save progress to dictionary
func get_save_data() -> Dictionary:
	return {
		"current_world": current_world,
		"current_level": current_level,
		"current_wave": current_wave,
		"total_waves": total_waves,
		"enemies_defeated": enemies_defeated,
		"towers_placed": towers_placed,
		"gold_earned": gold_earned,
		"total_damage_dealt": total_damage_dealt,
		"milestones_achieved": milestones_achieved.duplicate(true),
		"wave_completion_times": wave_completion_times.duplicate(true),
		"difficulty_multiplier": difficulty_multiplier,
		"enemy_spawn_rate_modifier": enemy_spawn_rate_modifier
	}

## Load progress from dictionary
func load_save_data(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	
	current_world = data.get("current_world", 1)
	current_level = data.get("current_level", 1)
	current_wave = data.get("current_wave", 0)
	total_waves = data.get("total_waves", WAVES_PER_LEVEL)
	enemies_defeated = data.get("enemies_defeated", 0)
	towers_placed = data.get("towers_placed", 0)
	gold_earned = data.get("gold_earned", 0)
	total_damage_dealt = data.get("total_damage_dealt", 0)
	milestones_achieved = data.get("milestones_achieved", []).duplicate(true)
	wave_completion_times = data.get("wave_completion_times", []).duplicate(true)
	difficulty_multiplier = data.get("difficulty_multiplier", 1.0)
	enemy_spawn_rate_modifier = data.get("enemy_spawn_rate_modifier", 1.0)
	
	progress_updated.emit()
	return true

## Force reset all progress
func force_reset() -> void:
	_reset_progress()
	progress_updated.emit()