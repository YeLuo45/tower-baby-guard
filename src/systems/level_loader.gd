extends Node

## Level Loader - loads JSON level definitions
## Handles level validation and wave definitions

const LEVELS_PATH = "res://levels/"

static func get_level_list() -> Array[Dictionary]:
	var levels: Array[Dictionary] = []
	var dir = DirAccess.open(LEVELS_PATH)
	if dir == null:
		push_warning("LevelLoader: Cannot open levels directory")
		return _get_default_levels()
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var level = load_level(file_name)
			if level != null:
				levels.append(level)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	# Sort by level_id
	levels.sort_custom(func(a, b): return a.get("level_index", 0) < b.get("level_index", 0))
	return levels

static func load_level(file_name: String) -> Dictionary:
	var path = LEVELS_PATH + file_name
	if not FileAccess.file_exists(path):
		push_warning("LevelLoader: File not found: " + path)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("LevelLoader: Cannot open file: " + path)
		return {}
	
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_str)
	if parse_result != OK:
		push_warning("LevelLoader: JSON parse error in " + file_name + ": " + json.get_error_message())
		return {}
	
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("LevelLoader: Invalid level format in " + file_name)
		return {}
	
	# Validate required fields
	if not _validate_level(data):
		push_warning("LevelLoader: Level validation failed for " + file_name)
		return {}
	
	# Set default values
	data["level_index"] = _get_level_index(file_name)
	return data

static func _validate_level(data: Dictionary) -> bool:
	var required = ["level_id", "name", "waves"]
	for key in required:
		if not data.has(key):
			push_warning("LevelLoader: Missing required field: " + key)
			return false
	if typeof(data["waves"]) != TYPE_ARRAY:
		return false
	return true

static func _get_level_index(file_name: String) -> int:
	# Extract index from filename like "level_01_home.json" -> 0
	# Or "home.json" -> 0 (for world_N/ directory files)
	var pattern = RegEx.new()
	pattern.compile("level_(\\d+)")
	var result = pattern.search(file_name)
	if result:
		return result.get_string(1).to_int() - 1

	# Try scene_index from level data (set after loading)
	# This is a fallback for files without level_N prefix
	var num_pattern = RegEx.new()
	num_pattern.compile("(\\d+)")
	result = num_pattern.search(file_name)
	if result:
		return result.get_string(1).to_int() - 1

	return 0

static func _get_default_levels() -> Array[Dictionary]:
	# Fallback hardcoded levels if levels/ directory doesn't exist
	return [
		{
			"level_id": "home_01",
			"level_index": 0,
			"name": "宝宝的生日派对",
			"difficulty": "easy",
			"initial_gold": 200,
			"initial_lives": 20,
			"map_theme": "home",
			"waves": _get_home_waves()
		}
	]

static func _get_home_waves() -> Array:
	return [
		{"wave_number": 1, "enemies": [{"type": "tantrum", "count": 5}], "spawn_delay": 2.0},
		{"wave_number": 2, "enemies": [{"type": "tantrum", "count": 8}], "spawn_delay": 1.8},
		{"wave_number": 3, "enemies": [{"type": "tantrum", "count": 6}, {"type": "bedtime", "count": 2}], "spawn_delay": 1.5},
		{"wave_number": 4, "enemies": [{"type": "tantrum", "count": 5}, {"type": "veggie", "count": 3}], "spawn_delay": 1.5},
		{"wave_number": 5, "enemies": [{"type": "bedtime", "count": 5}, {"type": "tantrum", "count": 5}], "spawn_delay": 1.3},
		{"wave_number": 6, "enemies": [{"type": "veggie", "count": 5}, {"type": "screen_time", "count": 3}], "spawn_delay": 1.2},
		{"wave_number": 7, "enemies": [{"type": "tantrum", "count": 8}, {"type": "bedtime", "count": 4}, {"type": "veggie", "count": 3}], "spawn_delay": 1.0},
		{"wave_number": 8, "enemies": [{"type": "screen_time", "count": 6}, {"type": "veggie", "count": 4}], "spawn_delay": 1.0},
		{"wave_number": 9, "enemies": [{"type": "tantrum", "count": 10}, {"type": "bedtime", "count": 5}, {"type": "veggie", "count": 5}], "spawn_delay": 0.8},
		{"wave_number": 10, "enemies": [{"type": "tantrum", "count": 12}, {"type": "bedtime", "count": 6}, {"type": "veggie", "count": 6}], "spawn_delay": 0.7, "boss_modifier": 2.0}
	]

static func get_wave_count(level_data: Dictionary) -> int:
	return level_data.get("waves", []).size()

static func get_wave_config(level_data: Dictionary, wave_number: int) -> Dictionary:
	var waves = level_data.get("waves", [])
	if wave_number > 0 and wave_number <= waves.size():
		return waves[wave_number - 1]
	return {}

static func get_story_text(level_data: Dictionary, trigger: String) -> String:
	return level_data.get(trigger, "")

static func get_events_for_wave(level_data: Dictionary, wave_number: int) -> Array:
	var events = level_data.get("events", [])
	return events.filter(func(e): return e.get("trigger", "") == "wave_%d_start" % wave_number)