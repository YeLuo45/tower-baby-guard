extends Tower

## Dad Tower - Slows enemies with "stern look"
## Role: Crowd Control/Slow

@export var slow_factor: float = 0.5
@export var slow_duration: float = 2.0

var alliance_bonus: float = 0.0
var aura_extension_multiplier: float = 1.0

func _ready() -> void:
	super._ready()
	tower_name = "Dad"
	cost = 100
	range = 140.0
	damage = 8.0
	attack_speed = 0.8
	max_health = 120.0
	health = max_health
	
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.6, 0.6, 0.9, 1.0)  # Blue-ish for Dad
	
	_apply_alliance_bonus()

func _apply_alliance_bonus() -> void:
	if AllianceSystem:
		alliance_bonus = AllianceSystem.get_alliance_bonus(self)
		# Check for Full House combo: +20% attack speed
		if ComboSystem and ComboSystem.is_combo_active(ComboSystem.ComboType.FULL_HOUSE):
			attack_speed *= 1.2
		# Shared Aura: Dad's slow aura extends by 50% when 2+ allies nearby
		var zone = AllianceSystem.get_alliance_zone(self)
		if zone.size() >= 3:
			aura_extension_multiplier = 1.5

func _attack(target: Node2D) -> void:
	if target is Enemy:
		var slow_duration_extended = slow_duration * aura_extension_multiplier
		target.apply_slow(slow_factor, slow_duration_extended)
		target.take_damage(damage)
