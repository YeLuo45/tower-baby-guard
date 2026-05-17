extends Node

## Wave Manager - handles enemy spawning and wave progression
## Manages spawn timing, wave composition, difficulty scaling, and BOSS waves

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()
signal boss_wave_started(boss_name: String)
signal boss_defeated()

# Default hardcoded waves (fallback)
const DEFAULT_WAVE_CONFIGS: Array[Dictionary] = [
	{"enemies": [{"type": "tantrum", "count": 5}], "spawn_delay": 2.0},
	{"enemies": [{"type": "tantrum", "count": 8}], "spawn_delay": 1.8},
	{"enemies": [{"type": "tantrum", "count": 6}, {"type": "bedtime", "count": 2}], "spawn_delay": 1.5},
	{"enemies": [{"type": "tantrum", "count": 5}, {"type": "veggie", "count": 3}], "spawn_delay": 1.5},
	{"enemies": [{"type": "bedtime", "count": 5}, {"type": "tantrum", "count": 5}], "spawn_delay": 1.3},
	{"enemies": [{"type": "veggie", "count": 5}, {"type": "screen_time", "count": 3}], "spawn_delay": 1.2},
	{"enemies": [{"type": "tantrum", "count": 8}, {"type": "bedtime", "count": 4}, {"type": "veggie", "count": 3}], "spawn_delay": 1.0},
	{"enemies": [{"type": "screen_time", "count": 6}, {"type": "veggie", "count": 4}, {"type": "bath_time", "count": 2}], "spawn_delay": 1.0},
	{"enemies": [{"type": "tantrum", "count": 10}, {"type": "bedtime", "count": 5}, {"type": "veggie", "count": 5}, {"type": "screen_time", "count": 5}, {"type": "bath_time", "count": 3}], "spawn_delay": 0.8},
	{"enemies": [{"type": "tantrum", "count": 12}, {"type": "bedtime", "count": 6}, {"type": "veggie", "count": 6}, {"type": "screen_time", "count": 6}, {"type": "bath_time", "count": 4}, {"type": "outing_refusal", "count": 3}], "spawn_delay": 0.7},
]

var WAVE_CONFIGS: Array[Dictionary] = DEFAULT_WAVE_CONFIGS.duplicate()

var current_wave_index: int = -1
var spawn_queue: Array[Dictionary] = []
var spawn_timer: float = 0.0
var is_spawning: bool = false
var is_wave_active: bool = false

@export var path_node: NodePath

# BOSS wave state
var _is_boss_wave: bool = false
var _boss_spawned: bool = false
var _boss: Node = null
var _active_boss_name: String = ""

# BOSS wave interval (every 10th wave, i.e. wave 10, 20, 30...)
const BOSS_WAVE_INTERVAL: int = 10

func _ready() -> void:
	GameState.game_over.connect(_on_game_over)
	GameState.victory.connect(_on_victory)

func start_next_wave() -> bool:
	if current_wave_index >= WAVE_CONFIGS.size() - 1:
		return false

	current_wave_index += 1
	is_wave_active = true
	is_spawning = true

	# Check if this is a BOSS wave
	_is_boss_wave = (current_wave_index + 1) % BOSS_WAVE_INTERVAL == 0
	_boss_spawned = false

	# Force Blizzard weather during boss wave
	if _is_boss_wave:
		if has_node("/root/WeatherManager"):
			WeatherManager.set_weather("blizzard")
		# Play boss BGM
		if has_node("/root/AudioManager"):
			AudioManager.play_boss_bgm()

	var config = WAVE_CONFIGS[current_wave_index]
	spawn_queue = _build_spawn_queue(config)
	spawn_timer = 0.0  # Spawn first enemy immediately

	wave_started.emit(current_wave_index + 1)
	GameState.next_wave()

	# Start battle BGM for non-boss waves
	if not _is_boss_wave:
		if has_node("/root/AudioManager"):
			AudioManager.play_battle_bgm()

	return true

func _build_spawn_queue(config: Dictionary) -> Array[Dictionary]:
	var queue: Array[Dictionary] = []

	for enemy_group in config["enemies"]:
		for i in range(enemy_group["count"]):
			queue.append({
				"type": enemy_group["type"],
				"hp_modifier": 1.0
			})

	queue.shuffle()
	return queue

func _process(delta: float) -> void:
	if not is_spawning or spawn_queue.is_empty():
		# Check if wave is complete (no enemies left)
		if is_wave_active and get_tree().get_nodes_in_group("enemies").is_empty():
			# Small delay before marking complete to allow for queue to empty
			if not _wave_complete_pending:
				_wave_complete_pending = true
				_wave_complete_timer = 0.5  # 0.5 second grace period
		return

	spawn_timer -= delta
	if spawn_timer <= 0:
		_spawn_next_enemy()

var _wave_complete_pending: bool = false
var _wave_complete_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if _wave_complete_pending:
		_wave_complete_timer -= delta
		if _wave_complete_timer <= 0:
			_wave_complete_pending = false
			if is_wave_active and get_tree().get_nodes_in_group("enemies").is_empty():
				is_wave_active = false
				wave_completed.emit(current_wave_index + 1)

func _spawn_next_enemy() -> void:
	if spawn_queue.is_empty():
		is_spawning = false
		return

	var enemy_data = spawn_queue.pop_front()
	var enemy_scene = _get_enemy_scene(enemy_data["type"])

	if enemy_scene and has_node("Path2D"):
		var path = get_node("Path2D") as Path2D
		var enemy = enemy_scene.instantiate()
		enemy.max_health *= enemy_data["hp_modifier"]
		enemy.health = enemy.max_health
		# Create a new PathFollow2D for this enemy
		var pf = PathFollow2D.new()
		pf.loop = false
		path.add_child(pf)
		pf.add_child(enemy)
		spawn_timer = get_spawn_delay()

	# Spawn BOSS after regular enemies if this is a BOSS wave and boss not yet spawned
	if _is_boss_wave and not _boss_spawned and spawn_queue.is_empty():
		_spawn_boss()

func _spawn_boss() -> void:
	_boss_spawned = true
	_is_boss_wave = false  # Clear flag after spawning

	var boss_scene = preload("res://src/entities/enemies/boss_enemy.tscn")
	if boss_scene and has_node("Path2D"):
		var path = get_node("Path2D") as Path2D
		var boss = boss_scene.instantiate()
		boss.max_health = 1500
		boss.health = 1500

		var pf = PathFollow2D.new()
		pf.loop = false
		pf.progress = 0  # Boss starts at beginning
		path.add_child(pf)
		pf.add_child(boss)

		_boss = boss
		_active_boss_name = boss.boss_name

		# Connect boss signals
		boss.boss_died.connect(_on_boss_died)
		boss.boss_phase_changed.connect(_on_boss_phase_changed)

		# Show boss health bar
		_show_boss_health_bar(boss.boss_name, boss.max_health)

		# Emit boss wave started
		boss_wave_started.emit(boss.boss_name)

		# Play boss roar SFX
		if has_node("/root/AudioManager"):
			AudioManager.play_boss_roar()

func _show_boss_health_bar(name: String, hp: float) -> void:
	if has_node("/root/BossHealthBar"):
		BossHealthBar.show_boss(name, hp)

func _on_boss_died() -> void:
	# Hide boss health bar
	if has_node("/root/BossHealthBar"):
		BossHealthBar.hide_boss()

	# Play boss death SFX
	if has_node("/root/AudioManager"):
		AudioManager.play_boss_death()

	# Reward bonus gold
	GameState.gold += 200

	# Emit boss defeat signal
	boss_defeated.emit()

	# Restore battle BGM
	if has_node("/root/AudioManager"):
		AudioManager.play_battle_bgm()

	# Check achievements
	if has_node("/root/Achievements"):
		Achievements.unlock_achievement("boss_slayer")

func _on_boss_phase_changed(new_phase: int) -> void:
	# Screen shake on phase change
	if has_node("/root/ScreenShake"):
		ScreenShake.screen_shake(0.3, 5.0)

func _get_enemy_scene(enemy_type: String) -> PackedScene:
	match enemy_type:
		"tantrum": return preload("res://src/entities/enemies/tantrum.tscn")
		"bedtime": return preload("res://src/entities/enemies/bedtime.tscn")
		"veggie": return preload("res://src/entities/enemies/veggie.tscn")
		"screen_time": return preload("res://src/entities/enemies/screen_time.tscn")
		"bath_time": return preload("res://src/entities/enemies/bath_time.tscn")
		"outing_refusal": return preload("res://src/entities/enemies/outing_refusal.tscn")
	return null

func check_wave_complete() -> bool:
	if not is_wave_active or is_spawning:
		return false
	if get_tree().get_nodes_in_group("enemies").is_empty():
		is_wave_active = false
		wave_completed.emit(current_wave_index + 1)
		return true
	return false

func get_spawn_delay() -> float:
	if current_wave_index >= 0 and current_wave_index < WAVE_CONFIGS.size():
		return WAVE_CONFIGS[current_wave_index]["spawn_delay"]
	return 1.0

func _on_game_over() -> void:
	is_spawning = false
	is_wave_active = false

	# Stop BGM
	if has_node("/root/AudioManager"):
		AudioManager.stop_bgm()

func _on_victory() -> void:
	is_spawning = false
	is_wave_active = false
	all_waves_completed.emit()

	# Stop BGM
	if has_node("/root/AudioManager"):
		AudioManager.stop_bgm()

func load_waves_from_level(level_data: Dictionary) -> void:
	var waves = level_data.get("waves", [])
	if waves.is_empty():
		WAVE_CONFIGS = DEFAULT_WAVE_CONFIGS.duplicate()
		return

	# Convert JSON wave format to WAVE_CONFIGS format
	WAVE_CONFIGS = []
	for wave in waves:
		var enemies = wave.get("enemies", [])
		var wave_config = {
			"enemies": enemies,
			"spawn_delay": wave.get("spawn_delay", 1.5)
		}
		WAVE_CONFIGS.append(wave_config)

func activate_boss_mode() -> void:
	_is_boss_wave = true
	# Force Blizzard weather during boss mode
	if has_node("/root/WeatherManager"):
		WeatherManager.set_weather("blizzard")

func is_boss_mode_active() -> bool:
	return _is_boss_wave or _boss_spawned

func is_current_boss_wave() -> bool:
	return _is_boss_wave