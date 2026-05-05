extends CanvasLayer

## Main Menu - entry point of the game

@onready var play_btn: Button = $VBox/PlayBtn
@onready var title_label: Label = $VBox/TitleLabel

const LEVEL_ICONS: Array[String] = ["Kitchen", "Bedroom", "Garden"]

func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/level_select.tscn")
