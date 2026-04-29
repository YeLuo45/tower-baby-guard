extends Enemy

## ScreenTime Enemy - Immune to slow effects
## HP: Medium, Speed: Medium, Special: Immune to slow

func _ready() -> void:
	super._ready()
	enemy_name = "ScreenTime"
	max_health = 120.0
	speed = 80.0  # Medium
	health = max_health
	base_speed = speed
	reward = 15
	
	add_to_group("enemies")

func apply_slow(factor: float, duration: float) -> void:
	# ScreenTime enemy is immune to slow effects
	pass
