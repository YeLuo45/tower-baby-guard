extends Enemy

## Tantrum Enemy - Fast and weak, tantrum runner
## HP: Low, Speed: Fast

func _ready() -> void:
	super._ready()
	enemy_name = "Tantrum"
	max_health = 60.0
	speed = 120.0  # Fast
	health = max_health
	base_speed = speed
	reward = 10
	
	add_to_group("enemies")
