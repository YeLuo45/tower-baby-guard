extends Enemy

## Veggie Enemy - High HP tank enemy
## HP: High, Speed: Medium

func _ready() -> void:
	super._ready()
	enemy_name = "Veggie"
	max_health = 200.0
	speed = 70.0  # Medium
	health = max_health
	base_speed = speed
	reward = 20
	
	add_to_group("enemies")
