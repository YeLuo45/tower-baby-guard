extends Tower

## Grandma Tower - Stuns enemies with "disapproving look"
## Role: Crowd Control/Stun

@export var stun_duration: float = 1.5

# Upgrade-related properties
var has_group_hush: bool = false

var alliance_bonus: float = 0.0
var stun_cooldown_base: float = 0.0

func _ready() -> void:
	super._ready()
	tower_name = "Grandma"
	cost = 125
	range = 125.0
	damage = 6.0
	attack_speed = 0.6
	max_health = 90.0
	health = max_health
	
	# Initialize upgrade system
	total_invested = cost
	upgrade_paths = [false, false, false]
	
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.9, 0.8, 0.6, 1.0)  # Warm gray for Grandma
	
	_apply_alliance_bonus()

func update_range_area() -> void:
	pass

func _apply_alliance_bonus() -> void:
	if AllianceSystem:
		alliance_bonus = AllianceSystem.get_alliance_bonus(self)
		# Full House: Grandma cooldown -2s
		if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.FULL_HOUSE):
			# This will be handled by reducing attack_cooldown
			pass

func _attack(target: Node2D) -> void:
	if target is Enemy:
		var actual_stun = stun_duration
		# Grandma's Wisdom: +0.5s stun duration
		if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.GRANDMAS_WISDOM):
			actual_stun += 0.5
		
		# Group Hush: stuns all enemies in range instead of just one
		if has_group_hush:
			var enemies = range_area.get_overlapping_bodies()
			for enemy in enemies:
				if enemy is Enemy:
					enemy.apply_stun(actual_stun)
					enemy.take_damage(damage)
		else:
			target.apply_stun(actual_stun)
			target.take_damage(damage)
		
		# Kitchen Party: Can stun 2 enemies per cooldown
		if ComboSystem and ComboSystem.should_grandma_double_stun(self):
			_stun_second_enemy()

func _stun_second_enemy() -> void:
	var enemies = range_area.get_overlapping_bodies()
	var enemy_count = 0
	for enemy in enemies:
		if enemy is Enemy and enemy_count < 1:
			enemy.apply_stun(stun_duration * 0.5)
			enemy_count += 1

# Method to reduce cooldown (called by combo system)
func reduce_cooldown(amount: float) -> void:
	attack_cooldown = max(0, attack_cooldown - amount)

# Invulnerability for Power Nap
func apply_invulnerability(duration: float) -> void:
	# Temporary invulnerability - prevent taking damage
	var original_health = health
	health = max_health  # Full heal during invuln
	await get_tree().create_timer(duration).timeout
	health = original_health
