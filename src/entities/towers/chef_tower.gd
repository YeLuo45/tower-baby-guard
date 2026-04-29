extends Tower

## Chef Tower - Area of Effect damage to all enemies in range
## Role: Damage/AoE

@export var aoe_damage: float = 12.0
@export var aoe_range: float = 100.0

func _ready() -> void:
	super._ready()
	tower_name = "Chef"
	cost = 175
	range = 120.0
	damage = 12.0
	attack_speed = 0.7
	max_health = 110.0
	health = max_health
	
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.0, 0.5, 0.2, 1.0)  # Orange for Chef

func _attack(target: Node2D) -> void:
	# AoE attack - damage all enemies in range
	var enemies_in_range = range_area.get_overlapping_bodies()
	for enemy in enemies_in_range:
		if enemy is Enemy:
			enemy.take_damage(aoe_damage)
