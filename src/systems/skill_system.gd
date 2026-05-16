extends Node

## SkillSystem - Autoload managing skill activation, cooldowns, energy slots
## Handles 3 energy slots, skill effects application on tower attacks

const MAX_ENERGY_SLOTS: int = 3
const ENERGY_PER_SLOT: int = 100
const SKILL_COUNT_FOR_ACHIEVEMENT: int = 5  # Unlock achievement after 5 skills

# Energy slots (0, 1, 2)
var equipped_skills: Array = ["", "", ""]  # skill_id or empty string
var skill_cooldowns: Dictionary = {}  # skill_id -> remaining cooldown
var skill_active_timers: Dictionary = {}  # skill_id -> remaining active time
var shield_active: bool = false
var shield_timer: float = 0.0
var shield_cooldown: float = 0.0

# Session-unlocked skills (by level completion or gold purchase)
var unlocked_skills: Dictionary = {}  # skill_id -> true

signal skill_equipped(slot: int, skill_id: String)
signal skill_unequipped(slot: int)
signal skill_activated(skill_id: String, tower: Node)
signal skill_deactivated(skill_id: String)
signal energy_changed(current: int, max: int)
signal skill_unlocked(skill_id: String)

func _ready() -> void:
	_initialize_default_unlocks()
	_update_energy_signal()

func _process(delta: float) -> void:
	# Update cooldowns
	var to_remove = []
	for skill_id in skill_cooldowns:
		skill_cooldowns[skill_id] -= delta
		if skill_cooldowns[skill_id] <= 0:
			to_remove.append(skill_id)
	for skill_id in to_remove:
		skill_cooldowns.erase(skill_id)
	
	# Update active timers
	to_remove.clear()
	for skill_id in skill_active_timers:
		skill_active_timers[skill_id] -= delta
		if skill_active_timers[skill_id] <= 0:
			to_remove.append(skill_id)
	for skill_id in to_remove:
		skill_active_timers.erase(skill_id)
		skill_deactivated.emit(skill_id)
	
	# Update shield cooldown
	if shield_cooldown > 0:
		shield_cooldown -= delta
	if shield_active:
		shield_timer -= delta
		if shield_timer <= 0:
			shield_active = false

# Initialize default unlocked skills (first few for new players)
func _initialize_default_unlocks() -> void:
	# Start with basic skills unlocked
	unlocked_skills[SkillData.SKILL_IDS.RAPID_FIRE] = true
	unlocked_skills[SkillData.SKILL_IDS.WIDE_VISION] = true

# Get current total energy (based on equipped skills)
func get_current_energy() -> int:
	var used: int = 0
	for i in range(MAX_ENERGY_SLOTS):
		var skill_id = equipped_skills[i]
		if skill_id != "":
			var skill = SkillData.get_skill(skill_id)
			if not skill.is_empty():
				used += skill["energy_cost"]
	return ENERGY_PER_SLOT - used

func get_max_energy() -> int:
	return ENERGY_PER_SLOT

func _update_energy_signal() -> void:
	energy_changed.emit(get_current_energy(), get_max_energy())

# Check if a skill can be equipped in a slot
func can_equip(skill_id: String, slot: int) -> bool:
	if slot < 0 or slot >= MAX_ENERGY_SLOTS:
		return false
	if not unlocked_skills.has(skill_id) or not unlocked_skills[skill_id]:
		return false
	if equipped_skills[slot] == skill_id:
		return true  # Already equipped there
	
	# Check if already equipped in another slot
	for i in range(MAX_ENERGY_SLOTS):
		if equipped_skills[i] == skill_id:
			return false
	
	# Check energy cost
	var current_cost = 0
	for i in range(MAX_ENERGY_SLOTS):
		if equipped_skills[i] != "" and i != slot:
			var sid = equipped_skills[i]
			var sk = SkillData.get_skill(sid)
			if not sk.is_empty():
				current_cost += sk["energy_cost"]
	
	var new_skill = SkillData.get_skill(skill_id)
	if new_skill.is_empty():
		return false
	
	var total_cost = current_cost + new_skill["energy_cost"]
	return total_cost <= ENERGY_PER_SLOT

# Equip a skill to a slot
func equip_skill(skill_id: String, slot: int) -> bool:
	if not can_equip(skill_id, slot):
		return false
	
	var previous_skill = equipped_skills[slot]
	equipped_skills[slot] = skill_id
	skill_equipped.emit(slot, skill_id)
	_update_energy_signal()
	return true

# Unequip a skill from a slot
func unequip_skill(slot: int) -> String:
	if slot < 0 or slot >= MAX_ENERGY_SLOTS:
		return ""
	var skill_id = equipped_skills[slot]
	if skill_id != "":
		equipped_skills[slot] = ""
		skill_unequipped.emit(slot)
		_update_energy_signal()
	return skill_id

# Get equipped skill at slot
func get_equipped_skill(slot: int) -> String:
	if slot < 0 or slot >= MAX_ENERGY_SLOTS:
		return ""
	return equipped_skills[slot]

# Get all equipped skill IDs
func get_all_equipped_skills() -> Array:
	return equipped_skills.filter(func(s): return s != "")

# Check if a skill is equipped
func is_skill_equipped(skill_id: String) -> bool:
	return equipped_skills.has(skill_id)

# Check if a skill is unlocked
func is_skill_unlocked(skill_id: String) -> bool:
	return unlocked_skills.get(skill_id, false)

# Get number of unlocked skills
func get_unlocked_count() -> int:
	return unlocked_skills.size()

# Unlock a skill
func unlock_skill(skill_id: String) -> bool:
	if unlocked_skills.has(skill_id) and unlocked_skills[skill_id]:
		return false
	unlocked_skills[skill_id] = true
	skill_unlocked.emit(skill_id)
	
	# Check achievement for unlocking N skills
	_check_skill_achievement()
	_save_unlock_state()
	return true

func _check_skill_achievement() -> void:
	var count = get_unlocked_count()
	# This will be integrated with achievement_system
	if count >= SKILL_COUNT_FOR_ACHIEVEMENT:
		AchievementSystem._do_unlock("skill_collector")

# Unlock skill by level completion
func unlock_skill_by_level(skill_id: String, level_completed: int) -> bool:
	var skill = SkillData.get_skill(skill_id)
	if skill.is_empty():
		return false
	if skill["unlock_type"] != SkillData.UnlockType.LEVEL_COMPLETE:
		return false
	if skill["unlock_value"] <= level_completed:
		return unlock_skill(skill_id)
	return false

# Unlock skill by gold purchase
func unlock_skill_by_gold(skill_id: String, current_gold: int) -> bool:
	var skill = SkillData.get_skill(skill_id)
	if skill.is_empty():
		return false
	if skill["unlock_type"] != SkillData.UnlockType.GOLD_COST:
		return false
	if current_gold >= skill["unlock_value"]:
		return unlock_skill(skill_id)
	return false

# Set skill on cooldown
func set_skill_cooldown(skill_id: String, cooldown: float) -> void:
	skill_cooldowns[skill_id] = cooldown

# Check if skill is on cooldown
func is_on_cooldown(skill_id: String) -> bool:
	return skill_cooldowns.has(skill_id) and skill_cooldowns[skill_id] > 0

# Get remaining cooldown
func get_cooldown_remaining(skill_id: String) -> float:
	return skill_cooldowns.get(skill_id, 0.0)

# Apply skill effects to a tower attack
# Called from tower.gd _on_tower_attack callback
func apply_skill_effects(tower: Node, enemy: Node, damage: float) -> Dictionary:
	var result = {
		"final_damage": damage,
		"crit_hit": false,
		"splash_targets": [],
		"pierce_count": 0,
		"chain_targets": [],
		"freeze_applied": false,
		"slow_applied": false,
		"lifesteal_amount": 0.0,
		"gold_bonus": 1.0,
		"instant_kill": false,
		"explosive_damage": 0.0,
	}
	
	for skill_id in get_all_equipped_skills():
		if is_on_cooldown(skill_id):
			continue
		
		var skill = SkillData.get_skill(skill_id)
		if skill.is_empty():
			continue
		
		_apply_skill_effect(skill, tower, enemy, result)
	
	# Apply shield if active
	if shield_active and shield_timer > 0:
		result["shield_blocked"] = true
		shield_active = false
		shield_timer = 0.0
	
	return result

func _apply_skill_effect(skill: Dictionary, tower: Node, enemy: Node, result: Dictionary) -> void:
	match skill["effect_type"]:
		"attack_speed":
			# Handled in tower directly, this affects tower.attack_speed
			pass
		
		"critical":
			# Crit calculation - handled separately
			if randf() < skill["crit_rate"]:
				result["crit_hit"] = true
				result["final_damage"] *= skill["crit_damage"]
		
		"pierce":
			result["pierce_count"] = int(skill["effect_value"])
		
		"double_shot":
			# Handled in tower for firing multiple projectiles
			pass
		
		"splash":
			# Splash radius handled in tower explosion
			pass
		
		"chain":
			result["chain_targets"] = _find_chain_targets(enemy, int(skill["effect_value"]))
		
		"lifesteal":
			result["lifesteal_amount"] = skill["effect_value"]
		
		"gold_bonus":
			result["gold_bonus"] = 1.0 + skill["effect_value"]
		
		"freeze":
			if enemy.has_method("apply_freeze"):
				enemy.apply_freeze(skill["effect_value"], skill["duration"])
				result["freeze_applied"] = true
				set_skill_cooldown(skill["id"], 3.0)  # 3s cooldown
		
		"aura_slow":
			# Slowing aura handled globally
			pass
		
		"shield":
			if shield_cooldown <= 0 and not shield_active:
				shield_active = true
				shield_timer = skill["cooldown"]
				shield_cooldown = 0.0
		
		"time_warp":
			# Global enemy slow
			pass
		
		"lucky":
			if randf() < skill["effect_value"]:
				result["instant_kill"] = true
				result["final_damage"] = 99999.0
		
		"explosive":
			result["explosive_damage"] = damage * skill["effect_value"]
		
		"combo_duration":
			# Handled in combo_system
			pass
		
		"vision":
			# Handled in enemy spawn system
			pass
		
		"taunt":
			# Handled in enemy targeting
			pass
	
	skill_activated.emit(skill["id"], tower)

# Find chain lightning targets
func _find_chain_targets(initial_enemy: Node, bounces: int) -> Array:
	var targets: Array = []
	var current = initial_enemy
	var processed = [initial_enemy]
	
	for i in range(bounces):
		var closest: Node = null
		var closest_dist: float = 200.0  # Chain range
		
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if processed.has(enemy):
				continue
			if not is_instance_valid(enemy):
				continue
			if not enemy.has_method("is_alive") or not enemy.is_alive:
				continue
			
			var dist = current.global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest = enemy
				closest_dist = dist
		
		if closest:
			targets.append(closest)
			processed.append(closest)
			current = closest
		else:
			break
	
	return targets

# Get skill effect description for UI
func get_skill_effect_text(skill_id: String) -> String:
	var skill = SkillData.get_skill(skill_id)
	if skill.is_empty():
		return ""
	return skill["description"]

# Persistence integration
func get_save_data() -> Dictionary:
	return {
		"unlocked_skills": unlocked_skills,
		"equipped_skills": equipped_skills,
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("unlocked_skills"):
		unlocked_skills = data["unlocked_skills"]
	if data.has("equipped_skills"):
		equipped_skills = data["equipped_skills"]
	_update_energy_signal()

func _save_unlock_state() -> void:
	# Save to persistence system
	if Persistence:
		Persistence.persistent_stats["unlocked_skills"] = unlocked_skills.duplicate(true)
		Persistence.save_game()

# Called from AchievementSystem integration
func check_skill_unlock_achievements() -> void:
	var count = get_unlocked_count()
	if count >= 3:
		AchievementSystem._do_unlock("skill_collector")