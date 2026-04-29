extends Tower

## Grandma Tower - Stuns enemies with "disapproving look"
## Role: Crowd Control/Stun

@export var stun_duration: float = 1.5

func _ready() -> void:
	super._ready()
	tower_name = "Grandma"
	cost = 150
	range = 130.0
	damage = 6.0
	attack_speed = 0.6
	max_health = 90.0
	health = max_health
	
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.9, 0.8, 0.6, 1.0)  # Warm gray for Grandma

func _attack(target: Node2D) -> void:
	if target is Enemy:
		target.apply_stun(stun_duration)
		target.take_damage(damage)
