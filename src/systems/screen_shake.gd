extends Node2D
## Screen shake effect controller using Camera2D.offset via sin() wave

var _camera: Camera2D
var _shake_amplitude: float = 0.0
var _shake_duration: float = 0.0
var _shake_timer: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	_camera = get_node_or_null("..") as Camera2D
	if not _camera and get_parent() is Camera2D:
		_camera = get_parent() as Camera2D

func _process(delta: float) -> void:
	if _shake_timer > 0:
		_shake_timer -= delta
		var progress := _shake_timer / _shake_duration if _shake_duration > 0 else 0
		var decay := sin(progress * PI * 8) * progress  # sin wave with decay
		_shake_offset = Vector2(
			sin(_shake_timer * 40) * _shake_amplitude * decay,
			cos(_shake_timer * 40) * _shake_amplitude * decay
		)
		_camera.offset = _shake_offset
	else:
		_shake_timer = 0
		_camera.offset = Vector2.ZERO

## Shake with amplitude (pixels) and duration (seconds)
func shake(amplitude: float, duration: float) -> void:
	_shake_amplitude = amplitude
	_shake_duration = duration
	_shake_timer = duration

## Combo shake based on combo level (3-5→3px/0.1s, 6-7→6px/0.2s, 8→10px/0.3s+flash)
func combo_shake(level: int) -> void:
	if level >= 8:
		shake(10.0, 0.3)
		flash_screen()
	elif level >= 6:
		shake(6.0, 0.2)
	elif level >= 3:
		shake(3.0, 0.1)

## BOSS attack shake: 5px/0.15s
func boss_attack() -> void:
	shake(5.0, 0.15)

## BOSS phase shake: 15px/0.5s
func boss_phase() -> void:
	shake(15.0, 0.5)

## Screen flash effect (for level 8 combo)
func flash_screen() -> void:
	var flash := Color(1.0, 1.0, 1.0, 0.3)
	var overlay := ColorRect.new()
	overlay.color = flash
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(overlay)
	await get_tree().create_timer(0.05).timeout
	overlay.queue_free()