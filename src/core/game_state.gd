extends Node

## Global game state singleton
## Manages gold, lives, current wave, and game status

signal gold_changed(amount: int)
signal lives_changed(amount: int)
signal wave_changed(wave: int)
signal game_over()
signal victory()

var gold: int = 200:
	set(value):
		gold = value
		gold_changed.emit(gold)

var lives: int = 20:
	set(value):
		lives = value
		lives_changed.emit(lives)
		if lives <= 0:
			game_over.emit()

var current_wave: int = 0
var is_paused: bool = false
var is_game_active: bool = false

const MAX_WAVES: int = 10

func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS

func start_game() -> void:
	gold = 200
	lives = 20
	current_wave = 0
	is_paused = false
	is_game_active = true

func next_wave() -> void:
	current_wave += 1
	wave_changed.emit(current_wave)
	if current_wave >= MAX_WAVES:
		victory.emit()

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused

func reset_game() -> void:
	gold = 200
	lives = 20
	current_wave = 0
	is_paused = false
	is_game_active = false
