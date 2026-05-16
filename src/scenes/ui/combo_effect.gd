extends Node2D

## Visual effect shown when a Combo is triggered

var _life_timer: float = 0.0
var _duration: float = 1.0

func _process(delta: float) -> void:
	if _life_timer <= 0:
		return
	
	_life_timer -= delta
	queue_redraw()
	
	if _life_timer <= 0:
		queue_free()

func show_effect(pos: Vector2, combo_level: int, combo_color: Color) -> void:
	global_position = pos
	_life_timer = _duration
	modulate = combo_color
	scale = Vector2(1.0 + combo_level * 0.1, 1.0 + combo_level * 0.1)

func _draw() -> void:
	if _life_timer <= 0:
		return
	
	var alpha := _life_timer / _duration
	var radius := 40.0 * (1.0 - _life_timer / _duration * 0.3)
	var color := Color(modulate.r, modulate.g, modulate.b, alpha * 0.6)
	
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius + 5, 0, TAU, 32, Color(color.r, color.g, color.b, alpha * 0.3), 2.0)