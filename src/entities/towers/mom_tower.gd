extends Tower

## Mom Tower - Heals nearby towers periodically
## Role: Support/Healer

@export var heal_amount: float = 15.0
@export var heal_interval: float = 2.0
@export var heal_range: float = 120.0

var heal_timer: float = 0.0

func _ready() -> void:
	super._ready()
	tower_name = "Mom"
	cost = 100
	range = 150.0
	damage = 5.0
	attack_speed = 0.5
	max_health = 100.0
	health = max_health
	
	# Set visual appearance
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.0, 0.7, 0.9, 1.0)  # Pink for Mom

func _process(delta: float) -> void:
	super._process(delta)
	
	# Heal nearby towers
	heal_timer += delta
	if heal_timer >= heal_interval:
		heal_timer = 0.0
		_heal_nearby_towers()

func _heal_nearby_towers() -> void:
	var towers_in_range = range_area.get_overlapping_bodies()
	for body in towers_in_range:
		if body is Tower and body != self:
			body.heal(heal_amount)

func _attack(target: Node2D) -> void:
	# Mom doesn't attack enemies directly - she heals allies
	pass
