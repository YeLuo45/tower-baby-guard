extends Control

## BOSS health bar displayed at top-center during BOSS wave

signal phase_changed(phase: int)

const PHASE_COLORS := {
	1: Color("#22c55e"),  # green
	2: Color("#eab308"),  # yellow
	3: Color("#ef4444")   # red
}

var _max_hp: float = 2000.0
var _current_hp: float = 2000.0
var _phase: int = 1
var _shake_tween: Tween = null

@onready var _name_label: Label = $VBox/NameLabel
@onready var _hp_bar: ProgressBar = $VBox/HPBar
@onready var _phase_label: Label = $VBox/PhaseLabel

func _ready() -> void:
	visible = false
	_hp_bar.max_value = _max_hp
	_hp_bar.value = _max_hp
	_update_phase()

func show_boss(name: String, hp: float) -> void:
	_name_label.text = name
	_max_hp = hp
	_current_hp = hp
	_hp_bar.max_value = hp
	_hp_bar.value = hp
	_phase = 1
	_update_phase()
	visible = true

func hide_boss() -> void:
	visible = false

func take_damage(damage: float) -> void:
	_current_hp = max(0, _current_hp - damage)
	_hp_bar.value = _current_hp
	
	var old_phase := _phase
	_update_phase()
	
	if _phase != old_phase:
		phase_changed.emit(_phase)
		_screen_shake()

func _update_phase() -> void:
	var hp_percent := _current_hp / _max_hp if _max_hp > 0 else 0
	
	if hp_percent > 0.6:
		_phase = 1
	elif hp_percent > 0.3:
		_phase = 2
	else:
		_phase = 3
	
	_hp_bar.modulate = PHASE_COLORS[_phase]
	_phase_label.text = "Phase %d" % _phase

func _screen_shake() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	
	var tween := create_tween()
	var base_pos := Vector2(640, 40)
	var offset := Vector2(randf_range(-5, 5), randf_range(-3, 3))
	tween.tween_property(self, "position", offset, 0.1)
	tween.tween_property(self, "position", Vector2.ZERO, 0.1)
	_shake_tween = tween