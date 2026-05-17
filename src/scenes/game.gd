extends Node2D

## Main game scene controller
## Handles game initialization, tower placement, and wave management

@onready var tower_grid: Node2D = $TowerGrid
@onready var wave_manager: Node = $WaveManager
@onready var combat_system: Node = $CombatSystem
@onready var hud: CanvasLayer = $HUD
@onready var path_2d: Path2D = $Path2D
@onready var audio_system: Node = $AudioSystem

# Story and Event systems
@onready var story_vignette: CanvasLayer = $StoryVignette
@onready var event_system: Node = $EventSystem

var selected_tower_type: String = ""
var preview_tower: Sprite2D = null
var can_place_tower: bool = false
var selected_tower: Tower = null

var _wave_story_shown: Dictionary = {}  # Track which stories have been shown
var _pending_story: String = ""  # Story to show before next wave

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
	"dad": 75,
	"grandma": 125,
	"doctor": 150,
	"chef": 175,
}

# Alliance and Combo systems
var alliance_system: Node = null
var combo_system: Node = null
var combo_meter: Control = null
var alliance_range_circle: Node2D = null

# Upgrade panel
var upgrade_panel: Control = null

func _ready() -> void:
	GameState.start_game()
	_setup_grid_cells()
	_setup_wave_manager()
	_setup_combo_meter()
	_setup_alliance_range_indicator()
	_setup_upgrade_panel()
	_connect_signals()
	
	# Create preview tower for placement
	preview_tower = $PreviewTower
	
	# Get references to autoloaded systems
	alliance_system = get_node("/root/AllianceSystem")
	combo_system = get_node("/root/ComboSystem")
	
	# Connect combo system signals
	combo_system.combo_activated.connect(_on_combo_activated)
	combo_system.combo_effect_triggered.connect(_on_combo_effect_triggered)
	
	# Connect story system
	story_vignette.story_dismissed.connect(_on_story_dismissed)
	
	# Load level data if available
	_load_level_data()

func _setup_combo_meter() -> void:
	var combo_meter_scene = preload("res://src/scenes/ui/combo_meter.tscn")
	combo_meter = combo_meter_scene.instantiate()
	combo_meter.name = "ComboMeter"
	hud.add_child(combo_meter)
	combo_meter.setup(combo_system, alliance_system)

func _setup_alliance_range_indicator() -> void:
	alliance_range_circle = preload("res://src/scenes/ui/alliance_range.tscn").instantiate()
	alliance_range_circle.name = "AllianceRangeCircle"
	add_child(alliance_range_circle)
	alliance_range_circle.show_alliance_range(false)

func _setup_upgrade_panel() -> void:
	var upgrade_panel_scene = preload("res://src/scenes/ui/upgrade_panel.tscn")
	upgrade_panel = upgrade_panel_scene.instantiate()
	upgrade_panel.name = "UpgradePanel"
	upgrade_panel.visible = false
	add_child(upgrade_panel)
	
	# Connect signals
	upgrade_panel.panel_closed.connect(_on_upgrade_panel_closed)
	upgrade_panel.upgrade_purchased.connect(_on_upgrade_purchased)

func _on_upgrade_panel_closed() -> void:
	selected_tower = null

func _on_upgrade_purchased(tower: Tower, path_index: int) -> void:
	# Update HUD
	hud.update_tower_info("Upgrade purchased for %s!" % tower.tower_name)

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
	wave_manager.boss_wave_started.connect(_on_boss_wave_started)
	wave_manager.boss_defeated.connect(_on_boss_defeated)

	# Connect audio
	combat_system.enemy_killed.connect(_on_enemy_killed_audio)

	# Connect achievements
	Achievements.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_enemy_killed_audio(enemy: Enemy, reward: int) -> void:
	if has_node("/root/AudioManager"):
		AudioManager.play_enemy_death()
		AudioManager.play_coin()
	Achievements.on_enemy_killed()
	Achievements.on_gold_earned(reward)
	# Track gold earnings
	Persistence.record_gold_earned(reward)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_left_click()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_tower_selection()
	elif event is InputEventMouseMotion:
		_update_preview_position()

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
		if has_node("/root/AudioManager"):
			AudioManager.play_tower_place()
		Achievements.on_tower_placed(selected_tower_type)
		
		# Register with alliance system
		if alliance_system:
			alliance_system.register_tower(tower)
		
		# Track tower placement for achievements
		Persistence.record_tower_placed(tower.tower_name)
		Achievements.on_tower_placed(tower.tower_name)
		
		hud.update_tower_info("Placed %s Tower" % selected_tower_type.capitalize())
		
		# Show alliance range briefly
		if alliance_range_circle:
			alliance_range_circle.set_tower(tower)
			alliance_range_circle.show_alliance_range(true)
			await get_tree().create_timer(2.0).timeout
			alliance_range_circle.show_alliance_range(false)

func _cancel_tower_selection() -> void:
	selected_tower_type = ""
	selected_tower = null
	preview_tower.visible = false
	$TowerActionPanel.visible = false
	hud.clear_tower_info()

func _handle_left_click() -> void:
	var mouse_pos = get_global_mouse_position()
	
	# If placing a tower
	if selected_tower_type != "":
		_place_tower_at_mouse()
		return
	
	# Check if clicking on existing tower
	var towers = tower_grid.get_children().filter(func(c): return c is Tower)
	for tower in towers:
		if tower.position.distance_to(mouse_pos) < GRID_SIZE / 2:
			_show_upgrade_panel(tower)
			return
	
	# Clicked on empty space - close panel
	_close_all_panels()
	selected_tower = null

func _show_upgrade_panel(tower: Tower) -> void:
	selected_tower = tower
	
	# Hide old TowerActionPanel if visible
	$TowerActionPanel.visible = false
	
	# Show upgrade panel
	if upgrade_panel:
		upgrade_panel.show_panel(tower)

func _close_all_panels() -> void:
	$TowerActionPanel.visible = false
	if upgrade_panel:
		upgrade_panel.hide_panel()

func _show_tower_action_panel(tower: Tower) -> void:
	selected_tower = tower
	var panel = $TowerActionPanel
	var vbox = panel.get_node("VBox")
	
	vbox.get_node("TowerName").text = "%s Tower" % tower.tower_name.capitalize()
	vbox.get_node("TowerLevel").text = "Level %d" % tower.tower_level
	
	var upgrade_cost = tower.get_upgrade_cost()
	vbox.get_node("UpgradeBtn").text = "Upgrade (%dg)" % upgrade_cost
	vbox.get_node("UpgradeBtn").disabled = GameState.gold < upgrade_cost
	
	var sell_value = tower.get_sell_value()
	vbox.get_node("SellBtn").text = "Sell (%dg)" % sell_value
	
	# Position near tower
	panel.position = tower.position + Vector2(40, -80)
	panel.visible = true

func _on_upgrade_tower_pressed() -> void:
	if selected_tower == null:
		return
	var cost = selected_tower.get_upgrade_cost()
	if GameState.gold < cost:
		return
	GameState.gold -= cost
	selected_tower.upgrade()
	Achievements.on_tower_upgraded()
	_show_tower_action_panel(selected_tower)  # Refresh panel
	hud.update_tower_info("Upgraded %s to Level %d!" % [selected_tower.tower_name, selected_tower.tower_level])

func _on_sell_tower_pressed() -> void:
	if selected_tower == null:
		return
	Achievements.on_tower_sold()
	var refund = selected_tower.sell()
	GameState.gold += refund
	$TowerActionPanel.visible = false
	selected_tower = null
	hud.update_tower_info("Tower sold for %dg" % refund)

func _on_cancel_tower_action() -> void:
	$TowerActionPanel.visible = false
	selected_tower = null
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
	audio_system.notify_game_over()
	# Track game end for achievements
	Achievements.on_game_end(false, GameState.lives, GameState.gold)

func _on_victory() -> void:
	$VictoryScreen.visible = true
	audio_system.notify_victory()
	# Track game end for achievements
	Achievements.on_game_end(true, GameState.lives, GameState.gold)

func _on_wave_started(wave_number: int) -> void:
	hud.update_wave(wave_number)
	hud.set_wave_button_enabled(false)
	Achievements.on_wave_started(wave_number)
	if has_node("/root/AudioManager"):
		AudioManager.play_wave_start()

func _on_wave_completed(wave_number: int) -> void:
	hud.set_wave_button_enabled(true)
	Achievements.on_wave_completed(wave_number)
	if wave_number < GameState.MAX_WAVES:
		hud.update_tower_info("Wave %d complete! Prepare for the next wave!" % wave_number)

func _on_boss_wave_started(boss_name: String) -> void:
	hud.update_tower_info("WARNING: %s has appeared!" % boss_name)
	if has_node("/root/AudioManager"):
		AudioManager.play_boss_roar()

func _on_boss_defeated() -> void:
	hud.update_tower_info("Boss defeated! +200 gold bonus!")
	if has_node("/root/AudioManager"):
		AudioManager.play_boss_death()

func _on_all_waves_completed() -> void:
	pass

func _on_combo_activated(combo_type, towers: Array) -> void:
	var combo_name = ComboSystem.COMBO_NAMES.get(combo_type, "Unknown")
	Achievements.on_combo_triggered(combo_name)

func _on_combo_effect_triggered(combo_type, effect_name: String) -> void:
	# Special handling for Emergency Room
	if effect_name == "heal_all":
		Achievements.on_emergency_room_triggered()

func start_next_wave() -> void:
	wave_manager.start_next_wave()

func restart_game() -> void:
	get_tree().reload_current_scene()

func _on_achievement_unlocked(achievement_id: String, achievement_name: String) -> void:
	hud.update_tower_info("🏆 Achievement: %s" % achievement_name)

func _load_level_data() -> void:
	if GameState.current_level_data.is_empty():
		return
	
	# Configure wave manager with level's wave definitions
	var level_waves = GameState.current_level_data.get("waves", [])
	if not level_waves.is_empty():
		wave_manager.load_waves_from_level(GameState.current_level_data)
	
	# Show story before first wave if exists
	var story_key = "story_before_wave_1"
	var initial_story = GameState.current_level_data.get(story_key, "")
	if initial_story != "":
		_show_story_for_wave(1, initial_story)

func _show_story_for_wave(wave_num: int, text: String) -> void:
	if text == "" or _wave_story_shown.get(wave_num, false):
		return
	_wave_story_shown[wave_num] = true
	_pending_story = text
	story_vignette.show_story(text)

func _on_story_dismissed() -> void:
	# After story is dismissed, we can allow starting the wave
	# The HUD button should be already disabled until story is done
	pass

func _check_and_show_story(wave_num: int) -> void:
	# Check if there's a story text for this wave
	var level_data = GameState.current_level_data
	if level_data.is_empty():
		return
	
	var story_key = "story_before_wave_%d" % wave_num
	var story_text = level_data.get(story_key, "")
	
	if story_text != "" and not _wave_story_shown.get(wave_num, false):
		_show_story_for_wave(wave_num, story_text)
		return
	
	# Also check for events
	_trigger_events_for_wave(wave_num)

func _trigger_events_for_wave(wave_num: int) -> void:
	var events = LevelLoader.get_events_for_wave(GameState.current_level_data, wave_num)
	for event_data in events:
		event_system.trigger_event(event_data)
		var event_type = event_data.get("type", "")
		_handle_event_effect(event_type, event_data)

func _handle_event_effect(event_type: String, event_data: Dictionary) -> void:
	match event_type:
		"screen_flash":
			_do_screen_flash(event_data.get("duration", 1.0))
		"gold_rain":
			_do_gold_rain(event_data.get("amount", 50))
		"boss_mode":
			_do_boss_mode()
		"show_message":
			hud.update_tower_info(event_data.get("message", ""))

func _do_screen_flash(duration: float) -> void:
	var flash_rect = ColorRect.new()
	flash_rect.name = "FlashEffect"
	flash_rect.color = Color.WHITE
	flash_rect.anchor_right = 1.0
	flash_rect.anchor_bottom = 1.0
	flash_rect.show()
	add_child(flash_rect)
	
	var tween = create_tween()
	tween.tween_property(flash_rect, "modulate:a", 0.0, duration / 2)
	await tween.finished
	flash_rect.queue_free()

func _do_gold_rain(amount: int) -> void:
	hud.update_tower_info("+" + str(amount) + " gold! (gold rain)")
	# Gold is already added by EventSystem

func _do_boss_mode() -> void:
	hud.update_tower_info("BOSS MODE ACTIVATED!")
	wave_manager.activate_boss_mode()
