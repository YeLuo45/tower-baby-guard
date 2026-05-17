extends CanvasLayer

## Victory Screen - shown when player completes all waves
## Displays stars earned based on performance (lives remaining)

signal return_to_world_select()

var _stars_earned: int = 0
var _lives_remaining: int = 0
var _level_name: String = ""
var _world_index: int = 0
var _scene_index: int = 0

func _ready() -> void:
	visible = false

func show_victory(stars: int, lives: int, level_name: String, world_idx: int, scene_idx: int) -> void:
	_stars_earned = stars
	_lives_remaining = lives
	_level_name = level_name
	_world_index = world_idx
	_scene_index = scene_idx

	visible = true
	_update_display()

func _update_display() -> void:
	# Update stars display - find StarsLabel in VBoxContainer
	var vbox = $Panel/VBoxContainer
	if not vbox:
		return

	# Find or create stars label
	var stars_label = _find_child(vbox, "StarsLabel")
	if not stars_label:
		stars_label = Label.new()
		stars_label.name = "StarsLabel"
		stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars_label.add_theme_font_size_override("font_size", 48)
		vbox.add_child(stars_label)

	var stars_text = ""
	for i in range(3):
		stars_text += "★" if i < _stars_earned else "☆"
	stars_label.text = stars_text
	stars_label.add_theme_color_override("font_color", Color.YELLOW if _stars_earned > 0 else Color.GRAY)

	# Update level name
	var level_label = _find_child(vbox, "LevelNameLabel")
	if level_label:
		level_label.text = _level_name

	# Update lives remaining
	var lives_label = _find_child(vbox, "LivesLabel")
	if lives_label:
		lives_label.text = "剩余生命: %d" % _lives_remaining

	# Update star count text
	var count_label = _find_child(vbox, "StarCountLabel")
	if count_label:
		count_label.text = "获得 %d 颗星" % _stars_earned

func _find_child(node: Node, name: String) -> Node:
	for child in node.get_children():
		if child.name == name:
			return child
	return null

func _on_back_pressed() -> void:
	# Save stars to persistence before going back
	_save_stars()
	return_to_world_select.emit()
	get_tree().change_scene_to_file("res://src/scenes/world_select.tscn")

func _on_play_again_pressed() -> void:
	_save_stars()
	get_tree().reload_current_scene()

func _on_replay_pressed() -> void:
	_on_play_again_pressed()

func _save_stars() -> void:
	# Record stars in persistence (only if higher than current)
	if _world_index >= 0 and _scene_index >= 0:
		Persistence.record_level_stars(_world_index, _scene_index, _stars_earned)
		Persistence.save_game()