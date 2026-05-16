# world_select.gd - World selection screen for tower-baby-guard V7
# Displays 3 world cards with scene buttons, stars, and progress
extends Control

signal world_scene_selected(world_index: int, scene_index: int)

const WORLD_DATA := [
	{"name": "Grassland", "unlocked": true, "stars": [2, 1, 0]},
	{"name": "Desert", "unlocked": false, "stars": [0, 0, 0]},
	{"name": "Volcano", "unlocked": false, "stars": [0, 0, 0]}
]

var _world_cards: Array[Control] = []

func _ready() -> void:
	_setup_ui()

func _setup_ui() -> void:
	# Title
	var title := Label.new()
	title.name = "Title"
	title.text = "Select World"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 20)
	title.size = Vector2(900, 60)
	title.add_theme_font_size_override("font_size", 36)
	add_child(title)
	
	# HBox for world cards
	var hbox := HBoxContainer.new()
	hbox.name = "WorldCards"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 30)
	hbox.position = Vector2(50, 100)
	hbox.size = Vector2(800, 400)
	add_child(hbox)
	
	# Create world cards
	for i in range(3):
		var card := _create_world_card(WORLD_DATA[i], i)
		_world_cards.append(card)
		hbox.add_child(card)

func _create_world_card(data: Dictionary, world_index: int) -> Control:
	var card := Control.new()
	card.name = data["name"] + "Card"
	card.custom_minimum_size = Vector2(250, 380)
	card.size = card.custom_minimum_size
	
	var unlocked: bool = data["unlocked"]
	var stars: Array = data["stars"]
	
	# Panel background
	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _create_card_style(unlocked))
	card.add_child(panel)
	
	# World name
	var name_label := Label.new()
	name_label.name = "WorldName"
	name_label.text = data["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.position = Vector2(0, 16)
	name_label.size = Vector2(250, 40)
	name_label.add_theme_font_size_override("font_size", 24)
	if not unlocked:
		name_label.add_theme_color_override("font_color", Color.GRAY)
	card.add_child(name_label)
	
	# Scenes container
	var scenes_vbox := VBoxContainer.new()
	scenes_vbox.name = "Scenes"
	scenes_vbox.position = Vector2(15, 70)
	scenes_vbox.add_theme_constant_override("separation", 15)
	card.add_child(scenes_vbox)
	
	# Create 3 scene entries
	for j in range(3):
		var scene_hbox := HBoxContainer.new()
		scene_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		scenes_vbox.add_child(scene_hbox)
		
		var btn := Button.new()
		btn.text = "Scene %d" % (j + 1)
		btn.custom_minimum_size = Vector2(180, 45)
		btn.disabled = not unlocked
		btn.pressed.connect(_on_scene_button_pressed.bind(world_index, j))
		scene_hbox.add_child(btn)
		
		var stars_str := ""
		for s in range(3):
			stars_str += "★" if s < stars[j] else "☆"
		
		var stars_label := Label.new()
		stars_label.text = stars_str
		if stars[j] > 0:
			stars_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			stars_label.add_theme_color_override("font_color", Color.GRAY)
		stars_label.add_theme_font_size_override("font_size", 18)
		scene_hbox.add_child(stars_label)
	
	# Progress bar
	var progress := ProgressBar.new()
	progress.name = "ProgressBar"
	progress.position = Vector2(15, 330)
	progress.custom_minimum_size = Vector2(220, 20)
	progress.max_value = 9.0
	var total_stars := 0
	for s in stars:
		total_stars += s
	progress.value = float(total_stars)
	progress.percent_visible = false
	card.add_child(progress)
	
	# Locked overlay
	var locked_overlay := ColorRect.new()
	locked_overlay.name = "LockedOverlay"
	locked_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	locked_overlay.color = Color(0.2, 0.2, 0.2, 0.7)
	locked_overlay.visible = not unlocked
	card.add_child(locked_overlay)
	
	return card

func _create_card_style(unlocked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if unlocked:
		style.bg_color = Color(0.15, 0.18, 0.22, 1.0)
		style.border_color = Color(0.4, 0.6, 0.8, 1.0)
	else:
		style.bg_color = Color(0.12, 0.12, 0.14, 1.0)
		style.border_color = Color(0.3, 0.3, 0.3, 1.0)
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style

func _on_scene_button_pressed(world_index: int, scene_index: int) -> void:
	world_scene_selected.emit(world_index, scene_index)