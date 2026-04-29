extends Tower

## Doctor Tower - High single-target DPS
## Role: Damage/High DPS

func _ready() -> void:
	super._ready()
	tower_name = "Doctor"
	cost = 200
	range = 160.0
	damage = 25.0
	attack_speed = 1.2
	max_health = 100.0
	health = max_health
	
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.9, 1.0, 0.9, 1.0)  # White/Green for Doctor

func _attack(target: Node2D) -> void:
	if target is Enemy:
		target.take_damage(damage)
