extends Tower

## Mom Tower - Heals nearby towers periodically
## Role: Support/Healer

@export var heal_amount: float = 15.0
@export var heal_interval: float = 2.0
@export var heal_range: float = 120.0

# Upgrade-related properties
var has_overflow_love: bool = false

var heal_timer: float = 0.0
var alliance_bonus: float = 0.0

func _ready() -> void:
	super._ready()
	tower_name = "Mom"
	cost = 100
	range = 150.0
	damage = 5.0
	attack_speed = 0.5
	max_health = 100.0
	health = max_health
	
	# Initialize upgrade system
	total_invested = cost
	upgrade_paths = [false, false, false]
	
	# Register with alliance system
	if "AllianceSystem" in get_tree().get_nodes_in_group(""):
		pass
	
	# Set visual appearance
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.0, 0.7, 0.9, 1.0)  # Pink for Mom
	
	# Check for alliance bonus
	_apply_alliance_bonus()

func update_range_area() -> void:
	# Mom's range is used for healing, update collision shape if needed
	pass

func _process(delta: float) -> void:
	super._process(delta)
	
	# Heal nearby towers (cross-heal effect for alliance)
	heal_timer += delta
	if heal_timer >= heal_interval:
		heal_timer = 0.0
		_heal_nearby_towers()

func _heal_nearby_towers() -> void:
	var towers_in_range = range_area.get_overlapping_bodies()
	var healed_this_tick = []
	for body in towers_in_range:
		if body is Tower and body != self:
			var heal_amount_to_apply = heal_amount * (1.0 + alliance_bonus)
			var old_health = body.health
			var heal_space = body.max_health - old_health
			var actual_heal = min(heal_amount_to_apply, heal_space)
			var overflow = heal_amount_to_apply - actual_heal
			
			body.heal(actual_heal)
			healed_this_tick.append(body)
			
			# Overflow Love: heal that exceeds max HP passes to nearest tower
			if has_overflow_love and overflow > 0:
				_pass_overflow_heal(body, overflow)
	
	# Cross-heal: also heal towers in alliance zone (not just nearby)
	if AllianceSystem:
		var alliance_zone = AllianceSystem.get_alliance_zone(self)
		for tower in alliance_zone:
			if tower != self and not healed_this_tick.has(tower):
				tower.heal(heal_amount * 0.5)  # Cross-heal is 50% of normal heal

func _pass_overflow_heal(source_tower: Tower, overflow: float) -> void:
	# Find nearest tower outside source_tower's range
	var nearest_tower: Tower = null
	var nearest_dist: float = INF
	
	for child in get_tree().get_nodes_in_group("towers"):
		if child is Tower and child != source_tower and child != self:
			var dist = source_tower.global_position.distance_to(child.global_position)
			if dist < nearest_dist:
				nearest_tower = child
				nearest_dist = dist
	
	if nearest_tower:
		nearest_tower.heal(overflow)

func _apply_alliance_bonus() -> void:
	if AllianceSystem:
		alliance_bonus = AllianceSystem.get_alliance_bonus(self)
		# Apply alliance bonus to stats
		heal_amount *= (1.0 + alliance_bonus)

func _attack(target: Node2D) -> void:
	# Mom doesn't attack enemies directly - she heals allies
	pass

func take_damage(amount: float) -> void:
	var old_health = health
	health -= amount
	health_bar.value = health
	if health <= 0:
		_destroy()
	else:
		# Trigger emergency room check if combo active
		if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.EMERGENCY_ROOM):
			ComboSystem.on_tower_damaged(self, amount)

func heal(amount: float) -> void:
	health = min(health + amount, max_health)
	health_bar.value = health
