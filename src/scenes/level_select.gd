extends CanvasLayer

## Level Select screen - choose which level to play
## Loads level data from JSON files

const LEVEL_SCENES: Array[String] = [
	"res://src/scenes/game.tscn",
	"res://src/scenes/game.tscn",
	"res://src/scenes/game.tscn",
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

@onready var level_labels: Array = [
	$LevelGrid/Level1/LevelLabel,
	$LevelGrid/Level2/LevelLabel,
	$LevelGrid/Level3/LevelLabel,
]

@onready var subtitle_labels: Array = [
	$LevelGrid/Level1/Subtitle,
	$LevelGrid/Level2/Subtitle,
	$LevelGrid/Level3/Subtitle,
]

var selected_level: int = 0
var level_list: Array[Dictionary] = []

func _ready() -> void:
	_load_levels()
	_update_level_states()

func _load_levels() -> void:
	level_list = LevelLoader.get_level_list()
	
	# Update UI with level info
	for i in range(min(3, level_list.size())):
		var level_data = level_list[i]
		level_labels[i].text = level_data.get("name", "Level %d" % (i + 1))
		subtitle_labels[i].text = level_data.get("difficulty", "normal").capitalize()

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
	if level_index >= level_list.size():
		push_warning("LevelSelect: Level index %d out of range" % level_index)
		return
	
	selected_level = level_index
	var level_data = level_list[level_index]
	GameState.start_level(level_index, level_data)
	get_tree().change_scene_to_file(LEVEL_SCENES[level_index])

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/world_select.tscn")