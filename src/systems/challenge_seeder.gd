extends Node
## Challenge Seeder for tower-baby-guard V9 Daily Challenges.
## Generates deterministic, seeded challenges ensuring all players
## worldwide get the same challenge for a given date.
class_name ChallengeSeeder

# Challenge state
var _current_seed: int = 0
var _current_challenge: Dictionary = {}
var _today_date: String = ""

# Challenge definitions
var _challenge_pool: Array[Dictionary] = []
var _completed_challenges: Array[String] = []
var _challenge_history: Array[Dictionary] = []

# Daily challenge configuration
const CHALLENGE_DIFFICULTY_EASY: int = 1
const CHALLENGE_DIFFICULTY_MEDIUM: int = 2
const CHALLENGE_DIFFICULTY_HARD: int = 3
const CHALLENGE_DIFFICULTY_EXTREME: int = 4

const DAILY_CHALLENGE_FILE: String = "user://daily_challenge.save"

signal daily_challenge_loaded(challenge: Dictionary)
signal challenge_completed(challenge_id: String, score: int, stars: int)
signal challenge_reward_claimed(challenge_id: String, reward_type: String)
signal new_daily_challenge_available()

## Initialize challenge seeder and load challenge pool
func _ready() -> void:
	_setup_default_challenges()
	_load_challenge_data()
	_check_and_generate_daily_challenge()

## Set up the default challenge pool
func _setup_default_challenges() -> void:
	_challenge_pool = [
		# Easy challenges
		{
			"id": "speed_killer",
			"name": "Speed Killer",
			"description": "Defeat 50 enemies within the time limit",
			"difficulty": CHALLENGE_DIFFICULTY_EASY,
			"type": "elimination",
			"target": 50,
			"modifier": {"time_limit": 180.0, "spawn_boost": 1.2},
			"rewards": {"coins": 100, "stars": 1}
		},
		{
			"id": "economy_master",
			"name": "Economy Master",
			"description": "Earn 500 gold without placing any towers",
			"difficulty": CHALLENGE_DIFFICULTY_EASY,
			"type": "economic",
			"target": 500,
			"modifier": {"no_towers": true, "enemy_gold_boost": 2.0},
			"rewards": {"coins": 150, "stars": 1}
		},
		{
			"id": "tower_architect",
			"name": "Tower Architect",
			"description": "Place exactly 10 towers and survive 20 waves",
			"difficulty": CHALLENGE_DIFFICULTY_EASY,
			"type": "construction",
			"target": 10,
			"modifier": {"exact_towers": true, "waves_required": 20},
			"rewards": {"coins": 120, "stars": 1}
		},
		# Medium challenges
		{
			"id": "combo_master",
			"name": "Combo Master",
			"description": "Achieve a 50-hit combo in a single wave",
			"difficulty": CHALLENGE_DIFFICULTY_MEDIUM,
			"type": "skill",
			"target": 50,
			"modifier": {"combo_decay_slow": true},
			"rewards": {"coins": 250, "stars": 2}
		},
		{
			"id": "glass_cannon",
			"name": "Glass Cannon",
			"description": "Defeat 100 enemies with only 3 lives remaining",
			"difficulty": CHALLENGE_DIFFICULTY_MEDIUM,
			"type": "survival",
			"target": 100,
			"modifier": {"starting_lives": 5, "enemy_damage": 2.0},
			"rewards": {"coins": 300, "stars": 2}
		},
		{
			"id": "rapid_fire",
			"name": "Rapid Fire",
			"description": "Survive 30 waves with 50% faster enemy spawn rate",
			"difficulty": CHALLENGE_DIFFICULTY_MEDIUM,
			"type": "endurance",
			"target": 30,
			"modifier": {"spawn_rate": 1.5, "no_pause": true},
			"rewards": {"coins": 280, "stars": 2}
		},
		# Hard challenges
		{
			"id": "iron_defense",
			"name": "Iron Defense",
			"description": "Survive 25 waves with 1 life and 50% reduced tower damage",
			"difficulty": CHALLENGE_DIFFICULTY_HARD,
			"type": "survival",
			"target": 25,
			"modifier": {"starting_lives": 1, "tower_damage": 0.5},
			"rewards": {"coins": 500, "stars": 3}
		},
		{
			"id": "gold_rush",
			"name": "Gold Rush",
			"description": "Earn 2000 gold in under 3 minutes",
			"difficulty": CHALLENGE_DIFFICULTY_HARD,
			"type": "economic",
			"target": 2000,
			"modifier": {"time_limit": 180.0, "gold_bonus": 1.5},
			"rewards": {"coins": 450, "stars": 3}
		},
		{
			"id": "boss_slayer",
			"name": "Boss Slayer",
			"description": "Defeat 5 bosses with only basic towers",
			"difficulty": CHALLENGE_DIFFICULTY_HARD,
			"type": "elimination",
			"target": 5,
			"modifier": {"basic_towers_only": true, "boss_health": 1.5},
			"rewards": {"coins": 600, "stars": 3}
		},
		# Extreme challenges
		{
			"id": "impossible_odds",
			"name": "Impossible Odds",
			"description": "Survive 50 waves with 1 life and double enemy stats",
			"difficulty": CHALLENGE_DIFFICULTY_EXTREME,
			"type": "survival",
			"target": 50,
			"modifier": {"starting_lives": 1, "enemy_health": 2.0, "enemy_speed": 1.5},
			"rewards": {"coins": 1000, "stars": 5}
		},
		{
			"id": "speed_demon",
			"name": "Speed Demon",
			"description": "Complete 30 waves in under 5 minutes",
			"difficulty": CHALLENGE_DIFFICULTY_EXTREME,
			"type": "speed",
			"target": 30,
			"modifier": {"time_limit": 300.0, "fast_forward": 2.0},
			"rewards": {"coins": 1200, "stars": 5}
		},
		{
			"id": "perfectionist",
			"name": "Perfectionist",
			"description": "Defeat 200 enemies without missing any and with max difficulty",
			"difficulty": CHALLENGE_DIFFICULTY_EXTREME,
			"type": "skill",
			"target": 200,
			"modifier": {"no_misses": true, "max_difficulty": true},
			"rewards": {"coins": 1500, "stars": 5}
		}
	]

## Check date and generate daily challenge if needed
func _check_and_generate_daily_challenge() -> void:
	var current_date := _get_current_date_string()
	
	if current_date != _today_date:
		_today_date = current_date
		_current_seed = _generate_daily_seed(current_date)
		_current_challenge = _generate_challenge_from_seed(_current_seed)
		daily_challenge_loaded.emit(_current_challenge)
		new_daily_challenge_available.emit()

## Generate a deterministic seed from date string
func _generate_daily_seed(date_string: String) -> int:
	# Use date to generate reproducible seed
	var hash_value: int = 0
	for i in range(date_string.length()):
		hash_value = hash_value * 31 + date_string.unicode_at(i)
	
	# Ensure positive seed
	return abs(hash_value)

## Generate a challenge from seed (deterministic)
func _generate_challenge_from_seed(seed: int) -> Dictionary:
	# Seeded random number generator
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	
	# Select challenge based on day of week (ensures variety while deterministic)
	var day_of_week := _get_day_of_week()
	var challenge_index: int
	
	# Distribute difficulty across week
	match day_of_week:
		0: # Sunday - Extreme
			challenge_index = _select_challenge_by_difficulty(rng, CHALLENGE_DIFFICULTY_EXTREME)
		1, 2: # Monday, Tuesday - Hard
			challenge_index = _select_challenge_by_difficulty(rng, CHALLENGE_DIFFICULTY_HARD)
		3, 4: # Wednesday, Thursday - Medium
			challenge_index = _select_challenge_by_difficulty(rng, CHALLENGE_DIFFICULTY_MEDIUM)
		5, 6: # Friday, Saturday - Easy
			challenge_index = _select_challenge_by_difficulty(rng, CHALLENGE_DIFFICULTY_EASY)
		_:
			challenge_index = rng.randi() % _challenge_pool.size()
	
	var base_challenge: Dictionary = _challenge_pool[challenge_index].duplicate(true)
	
	# Apply seed-based modifier variations
	base_challenge["seed"] = seed
	base_challenge["date"] = _today_date
	base_challenge["id"] = base_challenge["id"] + "_" + _today_date.replace("-", "")
	
	# Adjust target numbers slightly based on seed
	var seed_modifier := (seed % 20 - 10) / 100.0  # -10% to +10%
	if base_challenge.has("target"):
		var original_target: int = base_challenge["target"]
		base_challenge["target"] = int(float(original_target) * (1.0 + seed_modifier))
	
	return base_challenge

## Select a challenge index by difficulty
func _select_challenge_by_difficulty(rng: RandomNumberGenerator, difficulty: int) -> int:
	var matching_challenges: Array[int] = []
	for i in range(_challenge_pool.size()):
		if _challenge_pool[i].get("difficulty", 0) == difficulty:
			matching_challenges.append(i)
	
	if matching_challenges.is_empty():
		return rng.randi() % _challenge_pool.size()
	
	return matching_challenges[rng.randi() % matching_challenges.size()]

## Get current date as string
func _get_current_date_string() -> String:
	var datetime := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [datetime["year"], datetime["month"], datetime["day"]]

## Get day of week (0=Sunday, 6=Saturday)
func _get_day_of_week() -> int:
	var datetime := Time.get_datetime_dict_from_system()
	return datetime.get("weekday", 0)

## Get today's challenge
func get_daily_challenge() -> Dictionary:
	_check_and_generate_daily_challenge()
	return _current_challenge

## Get current seed
func get_current_seed() -> int:
	return _current_seed

## Check if a challenge is completed
func is_challenge_completed(challenge_id: String) -> bool:
	return challenge_id in _completed_challenges

## Complete a challenge with score
func complete_challenge(challenge_id: String, score: int) -> int:
	if challenge_id != _current_challenge.get("id", ""):
		push_warning("[ChallengeSeeder] Completing non-current challenge")
	
	if challenge_id in _completed_challenges:
		push_warning("[ChallengeSeeder] Challenge already completed")
		return 0
	
	_completed_challenges.append(challenge_id)
	
	# Calculate stars based on performance
	var stars := _calculate_stars(score)
	
	# Add to history
	_challenge_history.append({
		"id": challenge_id,
		"score": score,
		"stars": stars,
		"completed_at": Time.get_ticks_msec() / 1000.0
	})
	
	_save_challenge_data()
	challenge_completed.emit(challenge_id, score, stars)
	
	return stars

## Calculate stars earned based on score
func _calculate_stars(score: int) -> int:
	if _current_challenge.is_empty():
		return 0
	
	var target: int = _current_challenge.get("target", 0)
	var difficulty: int = _current_challenge.get("difficulty", CHALLENGE_DIFFICULTY_EASY)
	
	if target <= 0:
		return 1
	
	var achievement_ratio := float(score) / float(target)
	
	match difficulty:
		CHALLENGE_DIFFICULTY_EASY:
			if achievement_ratio >= 1.5:
				return 3
			elif achievement_ratio >= 1.0:
				return 2
			else:
				return 1
		CHALLENGE_DIFFICULTY_MEDIUM:
			if achievement_ratio >= 1.5:
				return 3
			elif achievement_ratio >= 1.0:
				return 2
			else:
				return 1
		CHALLENGE_DIFFICULTY_HARD:
			if achievement_ratio >= 1.2:
				return 3
			elif achievement_ratio >= 0.8:
				return 2
			else:
				return 1
		CHALLENGE_DIFFICULTY_EXTREME:
			if achievement_ratio >= 1.0:
				return 3
			elif achievement_ratio >= 0.7:
				return 2
			else:
				return 1
		_:
			return 1

## Get challenge rewards
func get_challenge_rewards(challenge_id: String) -> Dictionary:
	if challenge_id != _current_challenge.get("id", ""):
		return {}
	
	return _current_challenge.get("rewards", {"coins": 0, "stars": 0})

## Claim challenge reward
func claim_reward(challenge_id: String) -> Dictionary:
	if not is_challenge_completed(challenge_id):
		push_warning("[ChallengeSeeder] Cannot claim incomplete challenge")
		return {}
	
	var rewards: Dictionary = get_challenge_rewards(challenge_id)
	challenge_reward_claimed.emit(challenge_id, "coins")
	return rewards

## Get challenge difficulty string
func get_difficulty_string(difficulty: int) -> String:
	match difficulty:
		CHALLENGE_DIFFICULTY_EASY:
			return "Easy"
		CHALLENGE_DIFFICULTY_MEDIUM:
			return "Medium"
		CHALLENGE_DIFFICULTY_HARD:
			return "Hard"
		CHALLENGE_DIFFICULTY_EXTREME:
			return "Extreme"
		_:
			return "Unknown"

## Get challenge modifiers as description
func get_challenge_modifiers_text(challenge: Dictionary) -> String:
	var modifiers: Dictionary = challenge.get("modifier", {})
	var lines: Array[String] = []
	
	if modifiers.get("time_limit", 0) > 0:
		var seconds: int = int(modifiers["time_limit"])
		lines.append("Time limit: %d:%02d" % [seconds / 60, seconds % 60])
	if modifiers.get("starting_lives", 0) > 0:
		lines.append("Starting lives: %d" % modifiers["starting_lives"])
	if modifiers.get("no_towers", false):
		lines.append("No towers allowed")
	if modifiers.get("basic_towers_only", false):
		lines.append("Basic towers only")
	if modifiers.get("spawn_rate", 1.0) != 1.0:
		lines.append("Spawn rate: %.1fx" % modifiers["spawn_rate"])
	if modifiers.get("enemy_health", 1.0) != 1.0:
		lines.append("Enemy health: %.1fx" % modifiers["enemy_health"])
	if modifiers.get("tower_damage", 1.0) != 1.0:
		lines.append("Tower damage: %.0f%%" % (modifiers["tower_damage"] * 100))
	
	return "\n".join(lines) if lines.size() > 0 else "No special modifiers"

## Get challenge by exact ID
func get_challenge_by_id(challenge_id: String) -> Dictionary:
	for challenge in _challenge_pool:
		if challenge["id"] == challenge_id:
			return challenge.duplicate(true)
	return {}

## Get all challenges of a specific difficulty
func get_challenges_by_difficulty(difficulty: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for challenge in _challenge_pool:
		if challenge.get("difficulty", 0) == difficulty:
			result.append(challenge.duplicate(true))
	return result

## Get random challenge (for practice mode)
func get_random_challenge() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var index := rng.randi() % _challenge_pool.size()
	return _challenge_pool[index].duplicate(true)

## Get challenge completion stats
func get_completion_stats() -> Dictionary:
	var total_stars: int = 0
	for entry in _challenge_history:
		total_stars += entry.get("stars", 0)
	
	return {
		"total_completed": _completed_challenges.size(),
		"total_stars": total_stars,
		"history_size": _challenge_history.size()
	}

## Save challenge data to file
func _save_challenge_data() -> void:
	var save_data := {
		"completed_challenges": _completed_challenges.duplicate(true),
		"challenge_history": _challenge_history.duplicate(true),
		"last_saved": Time.get_ticks_msec() / 1000.0
	}
	
	var json_str := JSON.stringify(save_data)
	var file := FileAccess.open(DAILY_CHALLENGE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
	else:
		push_warning("[ChallengeSeeder] Failed to save challenge data")

## Load challenge data from file
func _load_challenge_data() -> void:
	if FileAccess.file_exists(DAILY_CHALLENGE_FILE):
		var file := FileAccess.open(DAILY_CHALLENGE_FILE, FileAccess.READ)
		if file:
			var json_str := file.get_as_text()
			file.close()
			var json := JSON.new()
			if json.parse(json_str) == OK:
				var data: Dictionary = json.data
				_completed_challenges = data.get("completed_challenges", []).duplicate(true)
				_challenge_history = data.get("challenge_history", []).duplicate(true)

## Get save data for persistence
func get_save_data() -> Dictionary:
	return {
		"completed_challenges": _completed_challenges.duplicate(true),
		"challenge_history": _challenge_history.duplicate(true)
	}

## Load save data
func load_save_data(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	
	_completed_challenges = data.get("completed_challenges", []).duplicate(true)
	_challenge_history = data.get("challenge_history", []).duplicate(true)
	_save_challenge_data()
	return true

## Force reset
func force_reset() -> void:
	_completed_challenges.clear()
	_challenge_history.clear()
	_current_seed = 0
	_current_challenge.clear()
	_today_date = ""
	_save_challenge_data()