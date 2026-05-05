extends CanvasLayer

## Level Select screen - choose which level to play

const LEVEL_SCENES: Array[String] = [
	"res://src/scenes/game.tscn",
	"res://src/scenes/game.tscn",
	"res://src/scenes/game.tscn",
]

const LEVEL_NAMES: Array[String] = ["Kitchen", "Bedroom", "Garden"]
const LEVEL_PATHS: Array[Curve2D] = [
	null,  # Level 1 uses default path
	null,  # Level 2 uses alternate path (future)
	null,  # Level 3 uses alternate path (future)
]

@onready var level_buttons: Array = [
	$LevelGrid/Level1/LevelBtn,
	$LevelGrid/Level2/LevelBtn,
	$LevelGrid/Level3/LevelBtn,
]

@onready var locked_labels: Array = [
	$LevelGrid/Level1/Locked,
	$LevelGrid/Level2/Locked,
	$LevelGrid/Level3/Locked,
]

@onready var levelBtns: Array = [
	$LevelGrid/Level1/LevelBtn,
	$LevelGrid/Level2/LevelBtn,
	$LevelGrid/Level3/LevelBtn,
]

var selected_level: int = 0

func _ready() -> void:
	_update_level_states()

func _update_level_states() -> void:
	for i in range(3):
		var unlocked = GameState.is_level_unlocked(i)
		level_buttons[i].disabled = not unlocked
		locked_labels[i].visible = not unlocked

func _on_level_1_pressed() -> void:
	_start_level(0)

func _on_level_2_pressed() -> void:
	_start_level(1)

func _on_level_3_pressed() -> void:
	_start_level(2)

func _start_level(level_index: int) -> void:
	if not GameState.is_level_unlocked(level_index):
		return
	selected_level = level_index
	GameState.current_level = level_index
	get_tree().change_scene_to_file(LEVEL_SCENES[level_index])

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/main_menu.tscn")
