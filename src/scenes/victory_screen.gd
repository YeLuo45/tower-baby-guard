extends CanvasLayer

## Victory Screen - shown when all waves are completed

func _ready() -> void:
	pass

func _on_play_again_pressed() -> void:
	GameState.reset_game()
	get_tree().reload_current_scene()

func _on_back_pressed() -> void:
	GameState.reset_game()
	get_tree().change_scene_to_file("res://src/scenes/level_select.tscn")
