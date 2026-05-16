extends Tower

## Doctor Tower - High single-target DPS
## Role: Damage/High DPS

# Upgrade-related properties
var crit_chance: float = 0.0  # 0 to 1, chance to crit for 2x damage

var alliance_bonus: float = 0.0

func _ready() -> void:
	super._ready()
	tower_name = "Doctor"
	cost = 150
	range = 250.0
	damage = 25.0
	attack_speed = 1.2
	max_health = 100.0
	health = max_health
	
	# Initialize upgrade system
	total_invested = cost
	upgrade_paths = [false, false, false]
	
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.9, 1.0, 0.9, 1.0)  # White/Green for Doctor
	
	_apply_alliance_bonus()

func update_range_area() -> void:
	pass

func _apply_alliance_bonus() -> void:
	if AllianceSystem:
		alliance_bonus = AllianceSystem.get_alliance_bonus(self)
		# Full House: +20% attack speed
		if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.FULL_HOUSE):
			attack_speed *= 1.2

func _attack(target: Node2D) -> void:
	if target is Enemy:
		# Calculate damage with critical hit
		var actual_damage = damage
		if crit_chance > 0 and randf() < crit_chance:
			actual_damage *= 2.0  # Critical hit = 2x damage
		
		target.take_damage(actual_damage)
		
		# House Call: Heal lowest HP ally for 30% of damage
		if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.HOUSE_CALL):
			ComboSystem.on_doctor_attack(self, target, actual_damage)
		
		# Dad's Timeout: Additional 20% slow
		if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.DADS_TIMEOUT):
			ComboSystem.on_doctor_attack(self, target, actual_damage)

func take_damage(amount: float) -> void:
	health -= amount
	health_bar.value = health
	if health <= 0:
		_destroy()
	else:
		# Emergency Room trigger
		if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.EMERGENCY_ROOM):
			ComboSystem.on_tower_damaged(self, amount)
