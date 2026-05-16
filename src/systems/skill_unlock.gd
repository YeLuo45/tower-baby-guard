extends Node

## SkillUnlock - Handles skill unlock logic (level completion / gold purchase)

signal skill_unlock_requested(skill_id: String, unlock_type: int, cost: int)
signal skill_unlock_completed(skill_id: String)
signal skill_unlock_failed(skill_id: String, reason: String)

const ACHIEVEMENT_SKILL_COUNT = "skill_collector"

func _ready() -> void:
	# Connect to game state for level completion signals
	var game = get_tree().root.find_child("Game", true, false)
	if game and game.has_signal("level_completed"):
		game.level_completed.connect(_on_level_completed)

# Called when a level is completed
func _on_level_completed(level_num: int) -> void:
	_check_level_based_unlocks(level_num)

# Check and unlock skills that require level completion
func _check_level_based_unlocks(level_completed: int) -> void:
	for skill in SkillData.get_all_skills():
		if skill["unlock_type"] == SkillData.UnlockType.LEVEL_COMPLETE:
			if skill["unlock_value"] <= level_completed:
				if SkillSystem.unlock_skill(skill["id"]):
					skill_unlock_completed.emit(skill["id"])

# Attempt to unlock a skill by gold purchase
func try_unlock_with_gold(skill_id: String) -> bool:
	var skill = SkillData.get_skill(skill_id)
	if skill.is_empty():
		skill_unlock_failed.emit(skill_id, "Skill not found")
		return false
	
	if skill["unlock_type"] != SkillData.UnlockType.GOLD_COST:
		skill_unlock_failed.emit(skill_id, "Skill not purchasable with gold")
		return false
	
	if SkillSystem.is_skill_unlocked(skill_id):
		skill_unlock_failed.emit(skill_id, "Skill already unlocked")
		return false
	
	# Check if player has enough gold
	var player_gold = _get_player_gold()
	if player_gold < skill["unlock_value"]:
		skill_unlock_failed.emit(skill_id, "Not enough gold")
		return false
	
	# Deduct gold and unlock
	_deduct_player_gold(skill["unlock_value"])
	var unlocked = SkillSystem.unlock_skill(skill_id)
	
	if unlocked:
		skill_unlock_completed.emit(skill_id)
		# Record achievement progress
		AchievementSystem.on_skill_unlocked(SkillSystem.get_unlocked_count())
		return true
	else:
		# Refund gold if unlock failed
		_add_player_gold(skill["unlock_value"])
		skill_unlock_failed.emit(skill_id, "Unlock failed")
		return false

# Get available skills for unlock panel
func get_available_unlocks() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for skill in SkillData.get_all_skills():
		if not SkillSystem.is_skill_unlocked(skill["id"]):
			available.append(skill)
	return available

# Get all locked skills
func get_locked_skills() -> Array[Dictionary]:
	var locked: Array[Dictionary] = []
	for skill in SkillData.get_all_skills():
		if not SkillSystem.is_skill_unlocked(skill["id"]):
			locked.append(skill)
	return locked

# Get skills that can be unlocked with gold
func get_purchasable_skills(current_gold: int) -> Array[Dictionary]:
	var purchasable: Array[Dictionary] = []
	for skill in SkillData.get_all_skills():
		if skill["unlock_type"] == SkillData.UnlockType.GOLD_COST:
			if not SkillSystem.is_skill_unlocked(skill["id"]):
				if current_gold >= skill["unlock_value"]:
					purchasable.append(skill)
	return purchasable

# Get skills unlocked by level completion that are now available
func get_level_unlockable_skills(current_level: int) -> Array[Dictionary]:
	var unlockable: Array[Dictionary] = []
	for skill in SkillData.get_all_skills():
		if skill["unlock_type"] == SkillData.UnlockType.LEVEL_COMPLETE:
			if not SkillSystem.is_skill_unlocked(skill["id"]):
				if skill["unlock_value"] <= current_level:
					unlockable.append(skill)
	return unlockable

# Check if player meets requirements to unlock a specific skill
func can_unlock(skill_id: String) -> Dictionary:
	var result = {
		"can_unlock": false,
		"reason": "",
		"requirement": "",
	}
	
	var skill = SkillData.get_skill(skill_id)
	if skill.is_empty():
		result["reason"] = "Skill not found"
		return result
	
	if SkillSystem.is_skill_unlocked(skill_id):
		result["reason"] = "Already unlocked"
		return result
	
	match skill["unlock_type"]:
		SkillData.UnlockType.LEVEL_COMPLETE:
			result["requirement"] = "Complete Level %d" % skill["unlock_value"]
			result["reason"] = "Level requirement not met"
		SkillData.UnlockType.GOLD_COST:
			result["requirement"] = "%d gold" % skill["unlock_value"]
			var gold = _get_player_gold()
			if gold >= skill["unlock_value"]:
				result["can_unlock"] = true
				result["reason"] = "Ready to purchase"
			else:
				result["reason"] = "Not enough gold (have %d, need %d)" % [gold, skill["unlock_value"]]
	
	return result

# Get count of skills unlocked
func get_unlock_progress() -> Dictionary:
	var total = SkillData.get_all_skills().size()
	var unlocked = SkillSystem.get_unlocked_count()
	return {
		"unlocked": unlocked,
		"total": total,
		"percentage": float(unlocked) / float(total) * 100.0
	}

# Player gold management (integrate with GameState)
func _get_player_gold() -> int:
	if Persistence:
		return Persistence.session_stats.get("session_gold_earned", 0)
	return 0

func _deduct_player_gold(amount: int) -> void:
	if Persistence:
		var current = Persistence.session_stats.get("session_gold_earned", 0)
		Persistence.session_stats["session_gold_earned"] = max(0, current - amount)

func _add_player_gold(amount: int) -> void:
	if Persistence:
		var current = Persistence.session_stats.get("session_gold_earned", 0)
		Persistence.session_stats["session_gold_earned"] = current + amount
		AchievementSystem.on_gold_earned(amount)

# Called when wave is completed - check level-based unlocks
func on_wave_completed(wave_num: int) -> void:
	# Convert wave number to level (approximate)
	var level = (wave_num / 10) + 1
	_check_level_based_unlocks(level)

# Request unlock (UI button handler)
func request_unlock(skill_id: String) -> void:
	var skill = SkillData.get_skill(skill_id)
	if skill.is_empty():
		return
	
	match skill["unlock_type"]:
		SkillData.UnlockType.LEVEL_COMPLETE:
			skill_unlock_requested.emit(skill_id, SkillData.UnlockType.LEVEL_COMPLETE, 0)
		SkillData.UnlockType.GOLD_COST:
			skill_unlock_requested.emit(skill_id, SkillData.UnlockType.GOLD_COST, skill["unlock_value"])