# world_select.gd - World selection screen for tower-baby-guard
# Displays 3 world cards with scene buttons, stars, and progress
extends Control

signal world_scene_selected(world_index: int, scene_index: int)
signal back_pressed()

# World display names (Chinese)
const WORLD_NAMES := ["世界一：温馨家庭", "世界二：精彩户外", "世界三：节日庆典"]

# World themes for card styling
const WORLD_THEMES := [
	{"bg": Color(0.15, 0.18, 0.22, 1.0), "border": Color(0.4, 0.6, 0.8, 1.0)},
	{"bg": Color(0.18, 0.15, 0.12, 1.0), "border": Color(0.8, 0.6, 0.4, 1.0)},
	{"bg": Color(0.15, 0.18, 0.15, 1.0), "border": Color(0.4, 0.8, 0.6, 1.0)}
]

var _world_cards: Array[Control] = []
var _world_scenes: Array[Array] = []  # _world_scenes[world_idx][scene_idx] = level_data
var _scene_stars: Array[Array] = []   # _scene_stars[world_idx][scene_idx] = stars (0-3)
var _world_unlocked: Array[bool] = [true, false, false]

func _ready() -> void:
	_load_world_scenes()
	_setup_ui()

func _load_world_scenes() -> void:
	# Load all levels and group by world
	var all_levels = LevelLoader.get_level_list()

	# Initialize
	_world_scenes = [[], [], []]
	_scene_stars = [[], [], []]

	# World unlock tracking
	var world_completed: Array[bool] = [false, false, false]

	for level in all_levels:
		var world_idx = level.get("world", 1) - 1
		if world_idx < 0 or world_idx >= 3:
			continue

		_world_scenes[world_idx].append(level)

		# Load stars from persistence (default 0)
		var key = "world_%d_scene_%d_stars" % [world_idx, _world_scenes[world_idx].size() - 1]
		var stars = 0  # Stars tracked separately in game state
		_scene_stars[world_idx].append(stars)

		# Track completion for world unlock
		if stars > 0:
			world_completed[world_idx] = true

	# Sort scenes within each world by level_index
	for i in range(3):
		_world_scenes[i].sort_custom(func(a, b):
			return a.get("level_index", 0) < b.get("level_index", 0)
		)

	# Unlock next world if previous is completed
	_world_unlocked = [true, false, false]
	if world_completed[0] and _world_scenes[0].size() >= 3:
		_world_unlocked[1] = true
	if world_completed[1] and _world_scenes[1].size() >= 3:
		_world_unlocked[2] = true

func _setup_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.1, 0.15, 1.0)
	add_child(bg)

	# Title
	var title := Label.new()
	title.name = "Title"
	title.text = "选择世界"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 20)
	title.size = Vector2(900, 60)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.7, 1))
	add_child(title)

	# Back button
	var back_btn := Button.new()
	back_btn.name = "BackBtn"
	back_btn.text = "返回"
	back_btn.position = Vector2(20, 20)
	back_btn.custom_minimum_size = Vector2(100, 40)
	back_btn.pressed.connect(func(): back_pressed.emit())
	add_child(back_btn)

	# HBox for world cards
	var hbox := HBoxContainer.new()
	hbox.name = "WorldCards"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 40)
	hbox.position = Vector2(40, 100)
	hbox.size = Vector2(900, 420)
	add_child(hbox)

	# Create world cards
	for i in range(3):
		var card := _create_world_card(i)
		_world_cards.append(card)
		hbox.add_child(card)

func _create_world_card(world_idx: int) -> Control:
	var card := Control.new()
	card.name = "WorldCard%d" % world_idx
	card.custom_minimum_size = Vector2(280, 400)
	card.size = card.custom_minimum_size

	var unlocked: bool = _world_unlocked[world_idx]
	var scenes: Array = _world_scenes[world_idx] if world_idx < _world_scenes.size() else []
	var stars: Array = _scene_stars[world_idx] if world_idx < _scene_stars.size() else []

	var theme = WORLD_THEMES[world_idx] if world_idx < WORLD_THEMES.size() else WORLD_THEMES[0]

	# Panel background
	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _create_card_style(unlocked, theme))
	card.add_child(panel)

	# World name
	var name_label := Label.new()
	name_label.name = "WorldName"
	name_label.text = WORLD_NAMES[world_idx] if world_idx < WORLD_NAMES.size() else "World %d" % (world_idx + 1)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, 12)
	name_label.size = Vector2(280, 40)
	name_label.add_theme_font_size_override("font_size", 20)
	if not unlocked:
		name_label.add_theme_color_override("font_color", Color.GRAY)
	else:
		name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.7, 1))
	card.add_child(name_label)

	# Scenes container
	var scenes_vbox := VBoxContainer.new()
	scenes_vbox.name = "Scenes"
	scenes_vbox.position = Vector2(15, 65)
	scenes_vbox.add_theme_constant_override("separation", 12)
	card.add_child(scenes_vbox)

	# Create scene entries (up to 3)
	for j in range(3):
		var scene_hbox := HBoxContainer.new()
		scene_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		scenes_vbox.add_child(scene_hbox)

		var scene_data = scenes[j] if j < scenes.size() else null
		var scene_stars = stars[j] if j < stars.size() else 0

		var btn := Button.new()
		if scene_data:
			btn.text = scene_data.get("scene_name", "Scene %d" % (j + 1))
		else:
			btn.text = "???"
		btn.custom_minimum_size = Vector2(200, 50)
		btn.disabled = not unlocked or scene_data == null
		btn.pressed.connect(_on_scene_button_pressed.bind(world_idx, j))
		scene_hbox.add_child(btn)

		# Stars
		var stars_str = ""
		for s in range(3):
			stars_str += "★" if s < scene_stars else "☆"

		var stars_label := Label.new()
		stars_label.text = stars_str
		if scene_stars > 0:
			stars_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			stars_label.add_theme_color_override("font_color", Color.GRAY)
		stars_label.add_theme_font_size_override("font_size", 18)
		scene_hbox.add_child(stars_label)

	# Progress info
	var total_stars := 0
	for s in stars:
		total_stars += s

	var progress_label := Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.position = Vector2(15, 350)
	progress_label.size = Vector2(250, 20)
	progress_label.text = "Total Stars: %d/9" % total_stars
	progress_label.add_theme_font_size_override("font_size", 14)
	progress_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	card.add_child(progress_label)

	# Locked overlay
	var locked_overlay := ColorRect.new()
	locked_overlay.name = "LockedOverlay"
	locked_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	locked_overlay.color = Color(0.2, 0.2, 0.2, 0.8)
	locked_overlay.visible = not unlocked
	card.add_child(locked_overlay)

	# Lock icon
	if not unlocked:
		var lock_label := Label.new()
		lock_label.name = "LockLabel"
		lock_label.text = "🔒 通关前一世界解锁"
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_label.position = Vector2(0, 180)
		lock_label.size = Vector2(280, 40)
		lock_label.add_theme_font_size_override("font_size", 16)
		lock_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
		card.add_child(lock_label)

	return card

func _create_card_style(unlocked: bool, theme: Dictionary) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if unlocked:
		style.bg_color = theme.get("bg", Color(0.15, 0.18, 0.22, 1.0))
		style.border_color = theme.get("border", Color(0.4, 0.6, 0.8, 1.0))
	else:
		style.bg_color = Color(0.1, 0.1, 0.12, 1.0)
		style.border_color = Color(0.25, 0.25, 0.25, 1.0)
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style

func _on_scene_button_pressed(world_idx: int, scene_idx: int) -> void:
	if world_idx >= _world_scenes.size() or scene_idx >= _world_scenes[world_idx].size():
		return

	var level_data = _world_scenes[world_idx][scene_idx]
	GameState.current_level_data = level_data
	GameState.start_level(scene_idx, level_data)
	get_tree().change_scene_to_file("res://src/scenes/game.tscn")