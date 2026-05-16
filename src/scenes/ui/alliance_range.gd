extends Node2D

## Alliance Range Indicator - Shows 200px alliance zone circle

const RANGE_RADIUS: float = 200.0

var tower_ref: Tower = null

func _ready() -> void:
	modulate = Color(1, 1, 0.5, 0.15)
	z_index = -5
	visible = false

func set_tower(tower: Tower) -> void:
	tower_ref = tower

func show_alliance_range(show: bool) -> void:
	visible = show

func _process(delta: float) -> void:
	if tower_ref and is_instance_valid(tower_ref):
		global_position = tower_ref.global_position

func _draw() -> void:
	if visible:
		draw_arc(Vector2.ZERO, RANGE_RADIUS, 0, TAU, 64, Color(1, 1, 0.5, 0.2), 3.0)