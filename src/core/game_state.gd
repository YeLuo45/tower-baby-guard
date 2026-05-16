extends Node

## Global game state singleton
## Manages gold, lives, current wave, and game status

signal gold_changed(amount: int)
signal lives_changed(amount: int)
signal wave_changed(wave: int)
signal game_over()
signal victory()
signal level_completed(level: int)

var gold: int = 200:
	set(value):
		gold = value
		gold_changed.emit(gold)

var lives: int = 20:
	set(value):
		var old_lives = lives
		lives = value
		lives_changed.emit(lives)
		if lives <= 0:
			game_over.emit()
		elif value < old_lives:
			Achievements.on_lives_changed(old_lives, value)

var current_wave: int = 0
var is_paused: bool = false
var is_game_active: bool = false
var current_level: int = 0
var game_start_lives: int = 20

# Level data from JSON
var current_level_data: Dictionary = {}
var wave_definitions: Array = []
var event_queue: Array = []

const MAX_WAVES: int = 10
const MAX_LEVELS: int = 3

# Level unlock system - unlocked levels stored in user settings
var _unlocked_levels: Array[int] = [0]  # Level 0 always unlocked

func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	_load_progress()
	# Initialize persistence system session
	Persistence.start_session()

func _load_progress() -> void:
	# Load from user:// (persistent storage)
	var save_file = FileAccess.get_user://("savegame.dat", FileAccess.READ)
	if save_file:
		var unlocked_count = save_file.get_8()
		_unlocked_levels.clear()
		for i in range(unlocked_count):
			_unlocked_levels.append(save_file.get_8())
		save_file.close()
	else:
		_unlocked_levels = [0]  # Default: only level 0 unlocked

func _save_progress() -> void:
	var save_file = FileAccess.get_user://("savegame.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_8(_unlocked_levels.size())
		for level in _unlocked_levels:
			save_file.store_8(level)
		save_file.close()

func is_level_unlocked(level_index: int) -> bool:
	return _unlocked_levels.has(level_index)

func unlock_level(level_index: int) -> void:
	if not _unlocked_levels.has(level_index) and level_index < MAX_LEVELS:
		_unlocked_levels.append(level_index)
		_save_progress()

func start_game() -> void:
	_set_initial_state()
	Persistence.start_session()

func start_level(level_index: int, level_data: Dictionary) -> void:
	_set_initial_state()
	current_level = level_index
	current_level_data = level_data
	wave_definitions = level_data.get("waves", [])
	event_queue = level_data.get("events", [])
	
	# Apply level initial settings
	var initial_gold = level_data.get("initial_gold", 200)
	var initial_lives = level_data.get("initial_lives", 20)
	gold = initial_gold
	lives = initial_lives
	game_start_lives = initial_lives
	
	Persistence.start_session()

func _set_initial_state() -> void:
	gold = 200
	lives = 20
	game_start_lives = 20
	current_wave = 0
	is_paused = false
	is_game_active = true
	current_level_data = {}
	wave_definitions = []
	event_queue = []

func next_wave() -> void:
	current_wave += 1
	wave_changed.emit(current_wave)
	if current_wave >= MAX_WAVES:
		victory.emit()
		_complete_level()

func _complete_level() -> void:
	level_completed.emit(current_level)
	# Unlock next level
	if current_level < MAX_LEVELS - 1:
		unlock_level(current_level + 1)

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused

func reset_game() -> void:
	gold = 200
	lives = 20
	current_wave = 0
	is_paused = false
	is_game_active = false
