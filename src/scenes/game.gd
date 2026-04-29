extends Node2D

## Main game scene controller
## Handles game initialization, tower placement, and wave management

@onready var tower_grid: Node2D = $TowerGrid
@onready var wave_manager: Node = $WaveManager
@onready var combat_system: Node = $CombatSystem
@onready var hud: CanvasLayer = $HUD
@onready var path_2d: Path2D = $Path2D

var selected_tower_type: String = ""
var preview_tower: Sprite2D = null
var can_place_tower: bool = false

const GRID_SIZE: int = 64
const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 11

const TOWER_SCENES: Dictionary = {
	"mom": preload("res://src/entities/towers/mom_tower.tscn"),
	"dad": preload("res://src/entities/towers/dad_tower.tscn"),
	"grandma": preload("res://src/entities/towers/grandma_tower.tscn"),
	"doctor": preload("res://src/entities/towers/doctor_tower.tscn"),
	"chef": preload("res://src/entities/towers/chef_tower.tscn"),
}

const TOWER_COSTS: Dictionary = {
	"mom": 100,
	"dad": 100,
	"grandma": 150,
	"doctor": 200,
	"chef": 175,
}

func _ready() -> void:
	GameState.start_game()
	_setup_grid_cells()
	_setup_wave_manager()
	_connect_signals()
	
	# Create preview tower for placement
	preview_tower = $PreviewTower

func _setup_grid_cells() -> void:
	# Create grid cells for tower placement
	var grid_cells = tower_grid.get_node("GridCells")
	
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var cell_pos = Vector2(x * GRID_SIZE + GRID_SIZE / 2, y * GRID_SIZE + GRID_SIZE / 2)
			# Skip cells that overlap with the path
			if _is_on_path(cell_pos):
				continue
			
			var cell = StaticBody2D.new()
			cell.position = cell_pos
			cell.name = "Cell_%d_%d" % [x, y]
			
			var shape = RectangleShape2D.new()
			shape.size = Vector2(GRID_SIZE - 4, GRID_SIZE - 4)
			
			var collision = CollisionShape2D.new()
			collision.shape = shape
			cell.add_child(collision)
			
			# Add cell marker
			var marker = ColorRect.new()
			marker.size = Vector2(GRID_SIZE - 8, GRID_SIZE - 8)
			marker.position = Vector2(-(GRID_SIZE - 8) / 2, -(GRID_SIZE - 8) / 2)
			marker.color = Color(0.2, 0.3, 0.2, 0.3)
			cell.add_child(marker)
			
			grid_cells.add_child(cell)

func _is_on_path(pos: Vector2) -> bool:
	# Check if a position is near the path
	var path = path_2d.curve
	if path == null:
		return false
	
	for i in range(path.point_count - 1):
		var p1 = path.get_point_position(i)
		var p2 = path.get_point_position(i + 1)
		var closest = _closest_point_on_segment(pos, p1, p2)
		if pos.distance_to(closest) < GRID_SIZE:
			return true
	return false

func _closest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab = b - a
	var ap = p - a
	var t = ap.dot(ab) / ab.dot(ab)
	return a + ab * clamp(t, 0, 1)

func _setup_wave_manager() -> void:
	# Set the path node reference in wave manager
	wave_manager.path_node = path_2d.get_path()

func _connect_signals() -> void:
	GameState.gold_changed.connect(_on_gold_changed)
	GameState.lives_changed.connect(_on_lives_changed)
	GameState.wave_changed.connect(_on_wave_changed)
	GameState.game_over.connect(_on_game_over)
	GameState.victory.connect(_on_victory)
	
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.all_waves_completed.connect(_on_all_waves_completed)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_preview_position()
	elif event.is_action_pressed("place_tower") and selected_tower_type != "":
		_place_tower_at_mouse()
	elif event.is_action_pressed("cancel_action"):
		_cancel_tower_selection()

func _update_preview_position() -> void:
	if selected_tower_type == "" or preview_tower == null:
		return
	
	var mouse_pos = get_global_mouse_position()
	var grid_pos = _snap_to_grid(mouse_pos)
	preview_tower.position = grid_pos
	
	# Check if placement is valid
	can_place_tower = _can_place_tower_at(grid_pos)
	preview_tower.modulate = Color(1, 1, 1, 0.5) if can_place_tower else Color(1, 0.3, 0.3, 0.5)

func _snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		floor(pos.x / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2,
		floor(pos.y / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2
	)

func _can_place_tower_at(pos: Vector2) -> bool:
	# Check if there's already a tower at this position
	for child in tower_grid.get_children():
		if child is Tower and child.position == pos:
			return false
	
	# Check if on path
	if _is_on_path(pos):
		return false
	
	# Check if within bounds
	if pos.x < 0 or pos.x > GRID_WIDTH * GRID_SIZE or pos.y < 0 or pos.y > GRID_HEIGHT * GRID_SIZE:
		return false
	
	# Check gold
	var cost = TOWER_COSTS.get(selected_tower_type, 100)
	if GameState.gold < cost:
		return false
	
	return true

func _place_tower_at_mouse() -> void:
	if selected_tower_type == "":
		return
	
	var mouse_pos = get_global_mouse_position()
	var grid_pos = _snap_to_grid(mouse_pos)
	
	if not _can_place_tower_at(grid_pos):
		return
	
	var cost = TOWER_COSTS.get(selected_tower_type, 100)
	if GameState.gold < cost:
		return
	
	GameState.gold -= cost
	
	var scene = TOWER_SCENES.get(selected_tower_type)
	if scene:
		var tower = scene.instantiate()
		tower.position = grid_pos
		tower_grid.add_child(tower)
		
		# Notify combat system
		combat_system.register_tower(tower)
		
		hud.update_tower_info("Placed %s Tower" % selected_tower_type.capitalize())

func _cancel_tower_selection() -> void:
	selected_tower_type = ""
	preview_tower.visible = false
	hud.clear_tower_info()

func select_tower(type: String) -> void:
	selected_tower_type = type
	preview_tower.visible = true
	_update_preview_position()
	
	var cost = TOWER_COSTS.get(type, 100)
	hud.update_tower_info("%s Tower - Cost: %d gold" % [type.capitalize(), cost])

func _on_gold_changed(amount: int) -> void:
	hud.update_gold(amount)

func _on_lives_changed(amount: int) -> void:
	hud.update_lives(amount)

func _on_wave_changed(wave: int) -> void:
	hud.update_wave(wave)

func _on_game_over() -> void:
	$GameOverScreen.visible = true

func _on_victory() -> void:
	$VictoryScreen.visible = true

func _on_wave_started(wave_number: int) -> void:
	hud.update_wave(wave_number)
	hud.set_wave_button_enabled(false)

func _on_wave_completed(wave_number: int) -> void:
	hud.set_wave_button_enabled(true)
	if wave_number < GameState.MAX_WAVES:
		hud.update_tower_info("Wave %d complete! Prepare for the next wave!" % wave_number)

func _on_all_waves_completed() -> void:
	pass

func start_next_wave() -> void:
	wave_manager.start_next_wave()

func restart_game() -> void:
	get_tree().reload_current_scene()
