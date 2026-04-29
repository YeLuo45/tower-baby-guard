extends Node

## Wave Manager - handles enemy spawning and wave progression
## Manages spawn timing, wave composition, and difficulty scaling

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()

const WAVE_CONFIGS: Array[Dictionary] = [
	{"enemies": [{"type": "tantrum", "count": 5}], "spawn_delay": 2.0},
	{"enemies": [{"type": "tantrum", "count": 8}], "spawn_delay": 1.8},
	{"enemies": [{"type": "tantrum", "count": 6}, {"type": "bedtime", "count": 2}], "spawn_delay": 1.5},
	{"enemies": [{"type": "tantrum", "count": 5}, {"type": "veggie", "count": 3}], "spawn_delay": 1.5},
	{"enemies": [{"type": "bedtime", "count": 5}, {"type": "tantrum", "count": 5}], "spawn_delay": 1.3},
	{"enemies": [{"type": "veggie", "count": 5}, {"type": "screen_time", "count": 3}], "spawn_delay": 1.2},
	{"enemies": [{"type": "tantrum", "count": 8}, {"type": "bedtime", "count": 4}, {"type": "veggie", "count": 3}], "spawn_delay": 1.0},
	{"enemies": [{"type": "screen_time", "count": 6}, {"type": "veggie", "count": 4}], "spawn_delay": 1.0},
	{"enemies": [{"type": "tantrum", "count": 10}, {"type": "bedtime", "count": 5}, {"type": "veggie", "count": 5}, {"type": "screen_time", "count": 5}], "spawn_delay": 0.8},
	{"enemies": [{"type": "tantrum", "count": 12}, {"type": "bedtime", "count": 6}, {"type": "veggie", "count": 6}, {"type": "screen_time", "count": 6}], "spawn_delay": 0.7, "boss_modifier": 2.0},
]

var current_wave_index: int = -1
var spawn_queue: Array[Dictionary] = []
var spawn_timer: float = 0.0
var is_spawning: bool = false
var is_wave_active: bool = false

@export var path_node: NodePath

func _ready() -> void:
	GameState.game_over.connect(_on_game_over)
	GameState.victory.connect(_on_victory)

func start_next_wave() -> bool:
	if current_wave_index >= WAVE_CONFIGS.size() - 1:
		return false
	
	current_wave_index += 1
	is_wave_active = true
	is_spawning = true
	
	var config = WAVE_CONFIGS[current_wave_index]
	spawn_queue = _build_spawn_queue(config)
	spawn_timer = 0.0
	
	wave_started.emit(current_wave_index + 1)
	GameState.next_wave()
	return true

func _build_spawn_queue(config: Dictionary) -> Array[Dictionary]:
	var queue: Array[Dictionary] = []
	var boss_modifier = config.get("boss_modifier", 1.0)
	
	for enemy_group in config["enemies"]:
		for i in range(enemy_group["count"]):
			queue.append({
				"type": enemy_group["type"],
				"hp_modifier": boss_modifier
			})
	
	queue.shuffle()
	return queue

func _process(delta: float) -> void:
	if not is_spawning or spawn_queue.is_empty():
		return
	
	spawn_timer -= delta
	if spawn_timer <= 0:
		_spawn_next_enemy()

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
		add_child(enemy)
		enemy.follow_path(path)

func _get_enemy_scene(enemy_type: String) -> PackedScene:
	match enemy_type:
		"tantrum": return preload("res://src/entities/enemies/tantrum.tscn")
		"bedtime": return preload("res://src/entities/enemies/bedtime.tscn")
		"veggie": return preload("res://src/entities/enemies/veggie.tscn")
		"screen_time": return preload("res://src/entities/enemies/screen_time.tscn")
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

func _on_victory() -> void:
	is_spawning = false
	is_wave_active = false
	all_waves_completed.emit()
