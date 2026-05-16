extends Tower

## Chef Tower - Area of Effect damage to all enemies in range
## Role: Damage/AoE

@export var aoe_damage: float = 12.0
@export var aoe_range: float = 100.0

# Upgrade-related properties
var has_splash_damage: bool = false

var alliance_bonus: float = 0.0

func _ready() -> void:
	super._ready()
	tower_name = "Chef"
	cost = 175
	range = 150.0
	damage = 12.0
	attack_speed = 0.7
	max_health = 110.0
	health = max_health
	
	# Initialize upgrade system
	total_invested = cost
	upgrade_paths = [false, false, false]
	
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.0, 0.5, 0.2, 1.0)  # Orange for Chef
	
	_apply_alliance_bonus()

func update_range_area() -> void:
	pass

func _apply_alliance_bonus() -> void:
	if AllianceSystem:
		alliance_bonus = AllianceSystem.get_alliance_bonus(self)
		# Kitchen Party: Chef attacks 30% faster
		if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.KITCHEN_PARTY):
			attack_speed *= 1.3

func _attack(target: Node2D) -> void:
	# AoE attack - damage all enemies in range
	var enemies_in_range = range_area.get_overlapping_bodies()
	var total_damage = 0.0
	for enemy in enemies_in_range:
		if enemy is Enemy:
			enemy.take_damage(aoe_damage)
			total_damage += aoe_damage
	
	# Splash Damage: attacks bounce to 2 nearby enemies for 50% damage
	if has_splash_damage and enemies_in_range.size() > 1:
		_splash_damage(enemies_in_range, aoe_damage * 0.5)
	
	# Family Meal: Nourishing AoE - heals allies for 50% of damage dealt
	if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.FAMILY_MEAL):
		ComboSystem.on_chef_aoe_damage(self, total_damage)

func _splash_damage(enemies: Array, splash_damage: float) -> void:
	var splashed = 0
	for enemy in enemies:
		if splashed >= 2:
			break
		if enemy is Enemy and enemy != current_target:
			enemy.take_damage(splash_damage)
			splashed += 1

# Override to allow double targeting for Kitchen Party
func get_targets_for_stun() -> Array:
	var targets = range_area.get_overlapping_bodies()
	targets = targets.filter(func(e): return e is Enemy)
	return targets
