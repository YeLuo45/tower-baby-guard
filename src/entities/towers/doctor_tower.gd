extends Tower

## Doctor Tower - High single-target DPS
## Role: Damage/High DPS

var alliance_bonus: float = 0.0

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
	
	_apply_alliance_bonus()

func _apply_alliance_bonus() -> void:
	if AllianceSystem:
		alliance_bonus = AllianceSystem.get_alliance_bonus(self)
		# Full House: +20% attack speed
		if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.FULL_HOUSE):
			attack_speed *= 1.2

func _attack(target: Node2D) -> void:
	if target is Enemy:
		target.take_damage(damage)
		
		# House Call: Heal lowest HP ally for 30% of damage
		if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.HOUSE_CALL):
			ComboSystem.on_doctor_attack(self, target, damage)
		
		# Dad's Timeout: Additional 20% slow
		if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.DADS_TIMEOUT):
			ComboSystem.on_doctor_attack(self, target, damage)

func take_damage(amount: float) -> void:
	health -= amount
	health_bar.value = health
	if health <= 0:
		_destroy()
	else:
		# Emergency Room trigger
		if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.EMERGENCY_ROOM):
			ComboSystem.on_tower_damaged(self, amount)
