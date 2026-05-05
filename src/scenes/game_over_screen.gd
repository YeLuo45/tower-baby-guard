extends CanvasLayer

## Game Over Screen - shown when player loses all lives

func _ready() -> void:
	pass

func _on_restart_pressed() -> void:
	GameState.reset_game()
	get_tree().reload_current_scene()

func _on_back_pressed() -> void:
	GameState.reset_game()
	get_tree().change_scene_to_file("res://src/scenes/level_select.tscn")
