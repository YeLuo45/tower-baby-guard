extends CanvasLayer

## HUD - displays game information and tower selection buttons

@onready var gold_label: Label = $TopPanel/HBox/GoldBox/GoldLabel
@onready var lives_label: Label = $TopPanel/HBox/LivesBox/LivesLabel
@onready var wave_label: Label = $TopPanel/HBox/WaveBox/WaveLabel
@onready var start_wave_button: Button = $TopPanel/HBox/StartWaveButton
@onready var tower_info_label: Label = $TowerInfoPanel/TowerInfoLabel

@onready var mom_tower_btn: Button = $BottomPanel/TowerSelectBox/MomTowerBtn
@onready var dad_tower_btn: Button = $BottomPanel/TowerSelectBox/DadTowerBtn
@onready var grandma_tower_btn: Button = $BottomPanel/TowerSelectBox/GrandmaTowerBtn
@onready var doctor_tower_btn: Button = $BottomPanel/TowerSelectBox/DoctorTowerBtn
@onready var chef_tower_btn: Button = $BottomPanel/TowerSelectBox/ChefTowerBtn

var current_game: Node2D = null

func _ready() -> void:
	current_game = get_tree().get_current_scene()
	update_gold(GameState.gold)
	update_lives(GameState.lives)
	update_wave(GameState.current_wave)

func update_gold(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount
	
	# Update button states based on affordability
	var costs = {
		"mom": 100,
		"dad": 100,
		"grandma": 150,
		"doctor": 200,
		"chef": 175
	}
	
	mom_tower_btn.disabled = GameState.gold < costs["mom"]
	dad_tower_btn.disabled = GameState.gold < costs["dad"]
	grandma_tower_btn.disabled = GameState.gold < costs["grandma"]
	doctor_tower_btn.disabled = GameState.gold < costs["doctor"]
	chef_tower_btn.disabled = GameState.gold < costs["chef"]

func update_lives(amount: int) -> void:
	lives_label.text = "Lives: %d" % amount
	if amount <= 5:
		lives_label.modulate = Color(1, 0.2, 0.2, 1)
	elif amount <= 10:
		lives_label.modulate = Color(1, 0.7, 0.2, 1)
	else:
		lives_label.modulate = Color(1, 1, 1, 1)

func update_wave(wave: int) -> void:
	wave_label.text = "Wave: %d/%d" % [wave, GameState.MAX_WAVES]

func update_tower_info(info: String) -> void:
	tower_info_label.text = info

func clear_tower_info() -> void:
	tower_info_label.text = "Select a tower to place"

func set_wave_button_enabled(enabled: bool) -> void:
	start_wave_button.disabled = not enabled

func _on_start_wave_pressed() -> void:
	if current_game:
		current_game.start_next_wave()

func _on_mom_tower_selected() -> void:
	if current_game:
		current_game.select_tower("mom")

func _on_dad_tower_selected() -> void:
	if current_game:
		current_game.select_tower("dad")

func _on_grandma_tower_selected() -> void:
	if current_game:
		current_game.select_tower("grandma")

func _on_doctor_tower_selected() -> void:
	if current_game:
		current_game.select_tower("doctor")

func _on_chef_tower_selected() -> void:
	if current_game:
		current_game.select_tower("chef")
