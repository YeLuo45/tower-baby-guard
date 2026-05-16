extends CanvasLayer

## Main Menu - entry point of the game

@onready var play_btn: Button = $VBox/PlayBtn
@onready var diary_btn: Button = $VBox/DiaryBtn
@onready var title_label: Label = $VBox/TitleLabel

const LEVEL_ICONS: Array[String] = ["Kitchen", "Bedroom", "Garden"]

func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	diary_btn.pressed.connect(_on_diary_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/level_select.tscn")

func _on_diary_pressed() -> void:
	# Show the baby diary panel
	var diary_scene = preload("res://src/scenes/ui/diary_panel.tscn")
	var diary = diary_scene.instantiate()
	add_child(diary)
