extends Node

## Combo System - Manages tower combo detection, activation and effects
## 8 combos implemented based on tower combinations in alliance zones

enum ComboType {
	FAMILY_MEAL,
	HOUSE_CALL,
	FULL_HOUSE,
	KITCHEN_PARTY,
	POWER_NAP,
	DADS_TIMEOUT,
	EMERGENCY_ROOM,
	GRANDMAS_WISDOM
}

const COMBO_NAMES = {
	ComboType.FAMILY_MEAL: "Family Meal",
	ComboType.HOUSE_CALL: "House Call",
	ComboType.FULL_HOUSE: "Full House",
	ComboType.KITCHEN_PARTY: "Kitchen Party",
	ComboType.POWER_NAP: "Power Nap",
	ComboType.DADS_TIMEOUT: "Dad's Timeout",
	ComboType.EMERGENCY_ROOM: "Emergency Room",
	ComboType.GRANDMAS_WISDOM: "Grandma's Wisdom"
}

const COMBO_COOLDOWNS = {
	ComboType.FAMILY_MEAL: 0.0,
	ComboType.HOUSE_CALL: 0.0,
	ComboType.FULL_HOUSE: 0.0,
	ComboType.KITCHEN_PARTY: 0.0,
	ComboType.POWER_NAP: 15.0,
	ComboType.DADS_TIMEOUT: 0.0,
	ComboType.EMERGENCY_ROOM: 20.0,
	ComboType.GRANDMAS_WISDOM: 0.0
}

var alliance_system = null
var active_combos: Dictionary = {}
var combo_cooldowns: Dictionary = {}
var combo_effects_active: Dictionary = {}

signal combo_activated(combo_type, towers: Array)
signal combo_deactivated(combo_type)
signal combo_effect_triggered(combo_type, effect_name: String)

func _ready() -> void:
	combo_cooldowns = COMBO_COOLDOWNS.duplicate()
	combo_effects_active = {}

func _process(delta: float) -> void:
	# Update cooldowns
	for combo in combo_cooldowns.keys():
		if combo_cooldowns[combo] > 0:
			combo_cooldowns[combo] -= delta
			if combo_cooldowns[combo] < 0:
				combo_cooldowns[combo] = 0

func setup(alliance_ref: Node) -> void:
	alliance_system = alliance_ref
	alliance_system.alliance_formed.connect(_on_alliance_formed)

func _on_alliance_formed(zone: Array) -> void:
	_check_combos_for_zone(zone)

func _check_combos_for_zone(zone: Array) -> void:
	if zone.size() < 2:
		return
	
	var types = alliance_system.count_tower_types(zone)
	var zone_id = _get_zone_id(zone)
	
	# Check each combo condition
	var detected_combo = _detect_combo(zone, types)
	
	if detected_combo >= 0:
		_activate_combo(detected_combo, zone, zone_id)
	else:
		# Deactivate any active combo for this zone
		if active_combos.has(zone_id):
			var old_combo = active_combos[zone_id]
			active_combos.erase(zone_id)
			combo_deactivated.emit(old_combo)

func _detect_combo(zone: Array, types: Dictionary):
	# Family Meal: Mom + Chef
	if types.has("Mom") and types.has("Chef"):
		return ComboType.FAMILY_MEAL
	
	# House Call: Mom + Doctor
	if types.has("Mom") and types.has("Doctor"):
		return ComboType.HOUSE_CALL
	
	# Full House: Mom + Dad + Grandma (all 3)
	if types.has("Mom") and types.has("Dad") and types.has("Grandma"):
		return ComboType.FULL_HOUSE
	
	# Kitchen Party: Chef + Grandma
	if types.has("Chef") and types.has("Grandma"):
		return ComboType.KITCHEN_PARTY
	
	# Power Nap: Mom + Grandma + Doctor (all 3)
	if types.has("Mom") and types.has("Grandma") and types.has("Doctor"):
		return ComboType.POWER_NAP
	
	# Dad's Timeout: Dad + Doctor
	if types.has("Dad") and types.has("Doctor"):
		return ComboType.DADS_TIMEOUT
	
	# Emergency Room: Mom + Chef + Doctor (all 3)
	if types.has("Mom") and types.has("Chef") and types.has("Doctor"):
		return ComboType.EMERGENCY_ROOM
	
	# Grandma's Wisdom: Grandma + any 2 others
	if types.has("Grandma") and zone.size() >= 3:
		return ComboType.GRANDMAS_WISDOM
	
	return -1  # No combo found

func _activate_combo(combo: ComboType, zone: Array, zone_id: String) -> void:
	# Check cooldown
	if combo_cooldowns[combo] > 0 and combo != ComboType.POWER_NAP and combo != ComboType.EMERGENCY_ROOM:
		return
	
	active_combos[zone_id] = combo
	combo_activated.emit(combo, zone)
	
	# Apply combo effects
	_apply_combo_effects(combo, zone)
	
	# Start cooldown
	if COMBO_COOLDOWNS[combo] > 0:
		combo_cooldowns[combo] = COMBO_COOLDOWNS[combo]

func _get_zone_id(zone: Array) -> String:
	var ids: Array = []
	for tower in zone:
		ids.append(tower.get_instance_id())
	return str(ids)

func _apply_combo_effects(combo: ComboType, zone: Array) -> void:
	match combo:
		ComboType.FAMILY_MEAL:
			_apply_family_meal(zone)
		ComboType.HOUSE_CALL:
			_apply_house_call(zone)
		ComboType.FULL_HOUSE:
			_apply_full_house(zone)
		ComboType.KITCHEN_PARTY:
			_apply_kitchen_party(zone)
		ComboType.POWER_NAP:
			_apply_power_nap(zone)
		ComboType.DADS_TIMEOUT:
			_apply_dads_timeout(zone)
		ComboType.EMERGENCY_ROOM:
			_apply_emergency_room(zone)
		ComboType.GRANDMAS_WISDOM:
			_apply_grandmas_wisdom(zone)

func _apply_family_meal(zone: Array) -> void:
	# Chef's AoE becomes "Nourishing AoE" — heals allies for 50% of damage dealt
	for tower in zone:
		if tower.tower_name == "Chef":
			tower.set_meta("combo_nourishing_aoe", true)
			tower.set_meta("nourishing_heal_percent", 0.5)

func _apply_house_call(zone: Array) -> void:
	# Doctor's attacks heal lowest HP allied tower for 30% of damage
	for tower in zone:
		if tower.tower_name == "Doctor":
			tower.set_meta("combo_house_call", true)
			tower.set_meta("house_call_heal_percent", 0.3)

func _apply_full_house(zone: Array) -> void:
	# All towers +20% attack speed, Grandma's stun cooldown -2s
	for tower in zone:
		tower.attack_speed *= 1.2
		if tower.tower_name == "Grandma":
			# Reduce cooldown by 2 seconds (assumes cooldown system exists)
			if tower.has_method("reduce_cooldown"):
				tower.reduce_cooldown(2.0)

func _apply_kitchen_party(zone: Array) -> void:
	# Chef attacks 30% faster, Grandma stuns 2 enemies per cooldown
	for tower in zone:
		if tower.tower_name == "Chef":
			tower.attack_speed *= 1.3
		if tower.tower_name == "Grandma":
			tower.set_meta("combo_double_stun", true)

func _apply_power_nap(zone: Array) -> void:
	# Every 15 seconds, all allied towers become invulnerable for 1s
	var timer = Timer.new()
	timer.name = "PowerNapTimer"
	timer.wait_time = 15.0
	timer.autostart = true
	timer.timeout.connect(func(): _trigger_power_nap(zone))
	
	# Store reference to cleanup later
	for tower in zone:
		if not tower.has_meta("combo_power_nap"):
			tower.set_meta("combo_power_nap_timer", timer)
	add_child(timer)

func _trigger_power_nap(zone: Array) -> void:
	for tower in zone:
		if tower.has_method("apply_invulnerability"):
			tower.apply_invulnerability(1.0)
	combo_effect_triggered.emit(ComboType.POWER_NAP, "invulnerability")

func _apply_dads_timeout(zone: Array) -> void:
	# Doctor's targets are slowed additional 20% after Doctor attack
	for tower in zone:
		if tower.tower_name == "Doctor":
			tower.set_meta("combo_dads_timeout", true)
			tower.set_meta("extra_slow_percent", 0.2)

func _apply_emergency_room(zone: Array) -> void:
	# If any allied tower drops below 20% HP, heal all for 30 HP (20s cooldown)
	for tower in zone:
		if tower.tower_name == "Mom" or tower.tower_name == "Chef" or tower.tower_name == "Doctor":
			tower.set_meta("combo_emergency_room", true)
		if tower.tower_name == "Mom":
			# Mom monitors HP
			if tower.has_method("connect_damage_handler"):
				tower.connect_damage_handler("_on_tower_damaged_emergency_room")

func _apply_grandmas_wisdom(zone: Array) -> void:
	# Grandma's stun duration +0.5s, all towers +10% damage
	for tower in zone:
		if tower.tower_name == "Grandma":
			if tower.has_meta("stun_duration"):
				tower.set_meta("stun_duration", tower.get_meta("stun_duration") + 0.5)
			else:
				tower.stun_duration += 0.5
		# All towers +10% damage
		tower.damage *= 1.1

# Called by Doctor tower when attacking
func on_doctor_attack(doctor: Node, target: Node, damage: float) -> void:
	if doctor.get_meta("combo_house_call", false):
		_heal_lowest_hp_tower(doctor, damage * doctor.get_meta("house_call_heal_percent", 0.3))
	
	if doctor.get_meta("combo_dads_timeout", false):
		if target.has_method("apply_extra_slow"):
			target.apply_extra_slow(doctor.get_meta("extra_slow_percent", 0.2))

func _heal_lowest_hp_tower(doctor: Node, amount: float) -> void:
	if not alliance_system:
		return
	var zone = alliance_system.get_alliance_zone(doctor)
	if zone.is_empty():
		return
	
	var lowest: Tower = null
	var lowest_hp: float = INF
	for tower in zone:
		if tower != doctor and is_instance_valid(tower):
			var hp_ratio = tower.health / tower.max_health
			if hp_ratio < lowest_hp:
				lowest_hp = hp_ratio
				lowest = tower
	
	if lowest:
		lowest.heal(amount)

# Called by Chef tower when doing AoE damage
func on_chef_aoe_damage(chef: Node, damage: float) -> void:
	if chef.get_meta("combo_nourishing_aoe", false):
		var heal_amount = damage * chef.get_meta("nourishing_heal_percent", 0.5)
		_heal_allied_towers(chef, heal_amount)

func _heal_allied_towers(chef: Node, amount: float) -> void:
	if not alliance_system:
		return
	var zone = alliance_system.get_alliance_zone(chef)
	for tower in zone:
		if tower != chef and is_instance_valid(tower):
			tower.heal(amount)

# Called when any tower takes damage
func on_tower_damaged(tower: Tower, damage: float) -> void:
	if tower.get_meta("combo_emergency_room", false):
		if tower.health / tower.max_health < 0.2:
			_trigger_emergency_room_heal(tower)

func _trigger_emergency_room_heal(tower: Tower) -> void:
	if combo_cooldowns[ComboType.EMERGENCY_ROOM] > 0:
		return
	
	if not alliance_system:
		return
	var zone = alliance_system.get_alliance_zone(tower)
	for t in zone:
		if is_instance_valid(t):
			t.heal(30.0)
	
	combo_cooldowns[ComboType.EMERGENCY_ROOM] = 20.0
	combo_effect_triggered.emit(ComboType.EMERGENCY_ROOM, "heal_all")

# Check if Grandma should stun 2 enemies
func should_grandma_double_stun(grandma: Node) -> bool:
	return grandma.get_meta("combo_double_stun", false)

func is_combo_active(combo: ComboType) -> bool:
	return active_combos.values().has(combo)

func get_active_combo_for_zone(zone_id: String) -> ComboType:
	return active_combos.get(zone_id)

func get_all_active_combos() -> Array:
	return active_combos.values()

func get_combo_status() -> Dictionary:
	var status = {}
	for combo in ComboType:
		status[combo] = {
			"active": is_combo_active(combo),
			"cooldown": combo_cooldowns[combo],
			"name": COMBO_NAMES[combo]
		}
	return status