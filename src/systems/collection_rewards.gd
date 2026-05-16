extends Node

## CollectionRewards - Manages milestone rewards for collection progress
## Triggers at 50%, 75%, and 100% collection completion

signal reward_claimed(reward_type: String, amount: int)
signal title_earned(title: String)
signal hidden_achievement_unlocked(achievement_id: String)

const MILESTONE_REWARDS = {
	50: {
		"gold": 100,
		"skill": null,
		"title": null,
		"achievement_id": "collector_novice",
	},
	75: {
		"gold": 300,
		"skill": "random",
		"title": null,
		"achievement_id": "collector_intermediate",
	},
	100: {
		"gold": 500,
		"skill": null,
		"title": "收藏大师",
		"achievement_id": "collector_master",
	},
}

# Achievement ID for the hidden "100% collection" achievement
const HIDDEN_COLLECTION_ACHIEVEMENT = "ultimate_collector"

func _ready() -> void:
	# Connect to collection system milestones
	CollectionSystem.milestone_reached.connect(_on_milestone_reached)

func _on_milestone_reached(milestone: int) -> void:
	claim_milestone_reward(milestone)

## Claim reward for a milestone
func claim_milestone_reward(milestone: int) -> void:
	if not MILESTONE_REWARDS.has(milestone):
		push_warning("CollectionRewards: Unknown milestone %d" % milestone)
		return
	
	var rewards = MILESTONE_REWARDS[milestone]
	
	# Claim gold
	if rewards.gold > 0:
		_claim_gold(rewards.gold)
	
	# Claim random skill (for 75% milestone)
	if rewards.skill == "random":
		_claim_random_skill()
	
	# Claim title (for 100% milestone)
	if rewards.title != null:
		_claim_title(rewards.title)
	
	# Unlock achievement
	if rewards.achievement_id != null:
		_unlock_reward_achievement(rewards.achievement_id)
	
	rewards_claimed.emit(milestone)

func _claim_gold(amount: int) -> void:
	if hasattr(GameState, "gold"):
		GameState.gold += amount
	reward_claimed.emit("gold", amount)
	print("CollectionRewards: +%d gold claimed!" % amount)

func _claim_random_skill() -> void:
	# Get all skills
	var all_skills = SkillData.get_all_skills()
	var locked_skills = all_skills.filter(func(s): return not s.get("unlocked", false))
	
	if locked_skills.size() > 0:
		var random_skill = locked_skills[randi() % locked_skills.size()]
		# Note: Actual skill unlock should be handled by skill_system
		# Just emit signal here
		print("CollectionRewards: Random skill unlocked: %s" % random_skill["name"])
		SkillSystem.unlock_skill(random_skill["id"])
	else:
		# All skills already unlocked, give bonus gold instead
		_claim_gold(100)
		print("CollectionRewards: All skills unlocked, gave +100 gold instead")

func _claim_title(title: String) -> void:
	title_earned.emit(title)
	print("CollectionRewards: Title earned: %s" % title)
	
	# Store title in persistence for display
	Persistence.set_value("player_title", title)
	Persistence.save_game()

func _unlock_reward_achievement(achievement_id: String) -> void:
	# Check if already unlocked
	if not Achievements.is_unlocked(achievement_id):
		Achievements._do_unlock(achievement_id)
		print("CollectionRewards: Achievement unlocked: %s" % achievement_id)

## Check if player qualifies for any unclaimed milestones
func check_pending_milestones() -> void:
	var percentage = CollectionSystem.get_progress_percentage()
	
	for milestone in MILESTONE_REWARDS.keys():
		if percentage >= milestone and not CollectionSystem.is_milestone_claimed(milestone):
			claim_milestone_reward(milestone)

## Get reward preview for a milestone
func get_reward_preview(milestone: int) -> Dictionary:
	if not MILESTONE_REWARDS.has(milestone):
		return {}
	
	var rewards = MILESTONE_REWARDS[milestone]
	var preview = {
		"milestone": milestone,
		"gold": rewards.gold,
		"skill": rewards.skill,
		"title": rewards.title,
		"achievement": rewards.achievement_id,
	}
	
	return preview

## Get all milestones and their claimed status
func get_milestone_status() -> Array:
	var status = []
	
	for milestone in MILESTONE_REWARDS.keys():
		status.append({
			"milestone": milestone,
			"claimed": CollectionSystem.is_milestone_claimed(milestone),
			"rewards": get_reward_preview(milestone),
		})
	
	return status