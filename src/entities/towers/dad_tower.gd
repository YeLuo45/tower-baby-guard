extends Tower

## Dad Tower - Slows enemies with "stern look"
## Role: Crowd Control/Slow

@export var slow_factor: float = 0.5
@export var slow_duration: float = 2.0

func _ready() -> void:
	super._ready()
	tower_name = "Dad"
	cost = 100
	range = 140.0
	damage = 8.0
	attack_speed = 0.8
	max_health = 120.0
	health = max_health
	
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.6, 0.6, 0.9, 1.0)  # Blue-ish for Dad

func _attack(target: Node2D) -> void:
	if target is Enemy:
		target.apply_slow(slow_factor, slow_duration)
		target.take_damage(damage)
