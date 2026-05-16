extends Node
## Manages Endless Mode for tower-baby-guard V9.
## Endless mode features infinite waves with progressive difficulty scaling,
## high score tracking, and endless-specific milestones.
class_name EndlessManager

# Endless mode state
var is_endless_active: bool = false
var endless_wave: int = 0
var endless_score: int = 0
var endless_high_score: int = 0
var endless_enemies_defeated: int = 0
var endless_towers_placed: int = 0
var endless_gold_earned: int = 0

# Difficulty scaling for endless mode
var endless_difficulty_multiplier: float = 1.0
var endless_spawn_rate_modifier: float = 1.0
var endless_wave_difficulty_increment: float = 0.08  # +8% per wave

# Endless run history
var endless_run_count: int = 0
var best_endless_wave: int = 0
var best_endless_score: int = 0

# Wave timing
var _wave_start_time: float = 0.0
var _total_endless_time: float = 0.0

# Endless mode configuration
const ENDLESS_STARTING_GOLD: int = 200
const ENDLESS_STARTING_LIVES: int = 20
const ENDLESS_SCORE_PER_ENEMY: int = 10
const ENDLESS_SCORE_PER_WAVE: int = 100
const ENDLESS_SCORE_COMBO_MULTIPLIER: float = 0.1
const ENDLESS_MAX_DIFFICULTY: float = 10.0

signal endless_started(wave: int)
signal endless_wave_started(wave: int, difficulty: float)
signal endless_wave_completed(wave: int, score_gain: int)
signal endless_score_updated(score: int)
signal endless_high_score_updated(score: int)
signal endless_ended(final_wave: int, final_score: int)
signal endless_milestone_achieved(milestone_id: String)

func _ready() -> void:
	_load_high_score()

## Start a new endless run
func start_endless() -> void:
	if is_endless_active:
		push_warning("[EndlessManager] Endless mode already active!")
		return
	
	is_endless_active = true
	endless_wave = 0
	endless_score = 0
	endless_enemies_defeated = 0
	endless_towers_placed = 0
	endless_gold_earned = 0
	endless_difficulty_multiplier = 1.0
	endless_spawn_rate_modifier = 1.0
	_wave_start_time = Time.get_ticks_msec() / 1000.0
	_total_endless_time = 0.0
	
	endless_run_count += 1
	endless_started.emit(endless_wave)
	_start_next_wave()

## Start the next endless wave
func _start_next_wave() -> void:
	endless_wave += 1
	
	# Apply wave-based difficulty scaling
	_apply_endless_difficulty()
	
	_wave_start_time = Time.get_ticks_msec() / 1000.0
	endless_wave_started.emit(endless_wave, endless_difficulty_multiplier)

## Complete current wave and start next
func complete_wave(score_bonus: int = 0) -> void:
	if not is_endless_active:
		return
	
	var wave_time := (Time.get_ticks_msec() / 1000.0) - _wave_start_time
	_total_endless_time += wave_time
	
	# Calculate wave score
	var wave_score := ENDLESS_SCORE_PER_WAVE + (endless_wave * 5) + score_bonus
	endless_score += wave_score
	
	endless_wave_completed.emit(endless_wave, wave_score)
	_check_endless_milestones()
	endless_score_updated.emit(endless_score)
	
	# Check for new high score
	if endless_score > endless_high_score:
		endless_high_score = endless_score
		endless_high_score_updated.emit(endless_high_score)
		_save_high_score()
	
	# Start next wave
	_start_next_wave()

## Apply progressive difficulty for endless mode
func _apply_endless_difficulty() -> void:
	# Difficulty scales with wave number, capped at maximum
	var target_difficulty := 1.0 + (endless_wave - 1) * endless_wave_difficulty_increment
	endless_difficulty_multiplier = minf(target_difficulty, ENDLESS_MAX_DIFFICULTY)
	
	# Spawn rate increases slightly faster
	endless_spawn_rate_modifier = 1.0 + (endless_wave - 1) * (endless_wave_difficulty_increment * 1.5)

## Record enemy defeat in endless mode
func record_enemy_defeated(gold_value: int = 0, combo: int = 0) -> void:
	if not is_endless_active:
		return
	
	endless_enemies_defeated += 1
	
	# Base score per enemy
	var enemy_score := ENDLESS_SCORE_PER_ENEMY
	
	# Combo bonus: extra score for consecutive kills
	if combo > 1:
		enemy_score += int(float(combo) * ENDLESS_SCORE_COMBO_MULTIPLIER * ENDLESS_SCORE_PER_ENEMY)
	
	endless_score += enemy_score
	
	if gold_value > 0:
		endless_gold_earned += gold_value

## Record tower placement in endless mode
func record_tower_placed() -> void:
	if not is_endless_active:
		return
	endless_towers_placed += 1

## End the endless run (game over)
func end_endless() -> void:
	if not is_endless_active:
		return
	
	is_endless_active = false
	
	# Update best records
	if endless_wave > best_endless_wave:
		best_endless_wave = endless_wave
	if endless_score > best_endless_score:
		best_endless_score = endless_score
	
	endless_ended.emit(endless_wave, endless_score)
	_save_high_score()

## Check and unlock endless-specific milestones
func _check_endless_milestones() -> void:
	# Wave milestones
	if endless_wave == 10 and not _has_endless_milestone("endless_wave_10"):
		_unlock_endless_milestone("endless_wave_10")
	if endless_wave == 25 and not _has_endless_milestone("endless_wave_25"):
		_unlock_endless_milestone("endless_wave_25")
	if endless_wave == 50 and not _has_endless_milestone("endless_wave_50"):
		_unlock_endless_milestone("endless_wave_50")
	if endless_wave == 100 and not _has_endless_milestone("endless_wave_100"):
		_unlock_endless_milestone("endless_wave_100")
	
	# Score milestones
	if endless_score >= 5000 and not _has_endless_milestone("endless_score_5k"):
		_unlock_endless_milestone("endless_score_5k")
	if endless_score >= 10000 and not _has_endless_milestone("endless_score_10k"):
		_unlock_endless_milestone("endless_score_10k")
	if endless_score >= 50000 and not _has_endless_milestone("endless_score_50k"):
		_unlock_endless_milestone("endless_score_50k")
	
	# Enemy milestones
	if endless_enemies_defeated >= 100 and not _has_endless_milestone("endless_enemies_100"):
		_unlock_endless_milestone("endless_enemies_100")
	if endless_enemies_defeated >= 500 and not _has_endless_milestone("endless_enemies_500"):
		_unlock_endless_milestone("endless_enemies_500")

var _endless_milestones_unlocked: Array[String] = []

func _has_endless_milestone(milestone_id: String) -> bool:
	return milestone_id in _endless_milestones_unlocked

func _unlock_endless_milestone(milestone_id: String) -> void:
	_endless_milestones_unlocked.append(milestone_id)
	endless_milestone_achieved.emit(milestone_id)

## Get current endless progress percentage (to wave 100 goal)
func get_endless_progress() -> float:
	return clampf(float(endless_wave) / 100.0, 0.0, 1.0)

## Get current endless wave time
func get_wave_time() -> float:
	if not is_endless_active:
		return 0.0
	return (Time.get_ticks_msec() / 1000.0) - _wave_start_time

## Get total endless run time
func get_total_time() -> float:
	return _total_endless_time

## Get formatted endless time string (MM:SS)
func get_formatted_time() -> String:
	var total := _total_endless_time + get_wave_time() if is_endless_active else _total_endless_time
	var minutes := int(total) / 60
	var seconds := int(total) % 60
	return "%02d:%02d" % [minutes, seconds]

## Save high score to persistent storage
func _save_high_score() -> void:
	var save_path := "user://endless_highscore.save"
	var save_data := {
		"high_score": endless_high_score,
		"best_wave": best_endless_wave,
		"best_score": best_endless_score,
		"run_count": endless_run_count
	}
	var json_str := JSON.stringify(save_data)
	# Use FileAccess for Godot 4.x
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
	else:
		push_warning("[EndlessManager] Failed to save high score")

## Load high score from persistent storage
func _load_high_score() -> void:
	var save_path := "user://endless_highscore.save"
	if FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file:
			var json_str := file.get_as_text()
			file.close()
			var json := JSON.new()
			if json.parse(json_str) == OK:
				var data: Dictionary = json.data
				endless_high_score = data.get("high_score", 0)
				best_endless_wave = data.get("best_wave", 0)
				best_endless_score = data.get("best_score", 0)
				endless_run_count = data.get("run_count", 0)

## Get save data for endless mode
func get_save_data() -> Dictionary:
	return {
		"is_endless_active": is_endless_active,
		"endless_wave": endless_wave,
		"endless_score": endless_score,
		"endless_high_score": endless_high_score,
		"endless_enemies_defeated": endless_enemies_defeated,
		"endless_towers_placed": endless_towers_placed,
		"endless_gold_earned": endless_gold_earned,
		"endless_difficulty_multiplier": endless_difficulty_multiplier,
		"endless_spawn_rate_modifier": endless_spawn_rate_modifier,
		"best_endless_wave": best_endless_wave,
		"best_endless_score": best_endless_score,
		"endless_run_count": endless_run_count,
		"total_endless_time": _total_endless_time,
		"endless_milestones": _endless_milestones_unlocked.duplicate(true)
	}

## Load save data for endless mode
func load_save_data(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	
	is_endless_active = data.get("is_endless_active", false)
	endless_wave = data.get("endless_wave", 0)
	endless_score = data.get("endless_score", 0)
	endless_high_score = data.get("endless_high_score", 0)
	endless_enemies_defeated = data.get("endless_enemies_defeated", 0)
	endless_towers_placed = data.get("endless_towers_placed", 0)
	endless_gold_earned = data.get("endless_gold_earned", 0)
	endless_difficulty_multiplier = data.get("endless_difficulty_multiplier", 1.0)
	endless_spawn_rate_modifier = data.get("endless_spawn_rate_modifier", 1.0)
	best_endless_wave = data.get("best_endless_wave", 0)
	best_endless_score = data.get("best_score", 0)
	endless_run_count = data.get("endless_run_count", 0)
	_total_endless_time = data.get("total_endless_time", 0.0)
	_endless_milestones_unlocked = data.get("endless_milestones", []).duplicate(true)
	
	return true

## Force reset endless progress
func force_reset() -> void:
	is_endless_active = false
	endless_wave = 0
	endless_score = 0
	endless_enemies_defeated = 0
	endless_towers_placed = 0
	endless_gold_earned = 0
	endless_difficulty_multiplier = 1.0
	endless_spawn_rate_modifier = 1.0
	_total_endless_time = 0.0
	_endless_milestones_unlocked.clear()