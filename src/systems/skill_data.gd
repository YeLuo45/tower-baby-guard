extends Resource
class_name SkillData

## SkillData - Resource subclass defining all 17 tower skills
## Each skill has: id, name, icon, description, effect stats, cost, unlock conditions

# Skill IDs (unique identifiers)
const SKILL_IDS = {
	RAPID_FIRE = "rapid_fire",
	CRITICAL_STRIKE = "critical_strike",
	SPLASH_DAMAGE = "splash_damage",
	PIERCE = "pierce",
	CHAIN_LIGHTNING = "chain_lightning",
	FREEZE = "freeze",
	SLOWING_AURA = "slowing_aura",
	SHIELD = "shield",
	GOLD_RUSH = "gold_rush",
	WIDE_VISION = "wide_vision",
	TAUNT = "taunt",
	VAMPIRE = "vampire",
	DOUBLE_SHOT = "double_shot",
	EXPLOSIVE = "explosive",
	TIME_WARP = "time_warp",
	LUCKY_STAR = "lucky_star",
	COMBO_MASTER = "combo_master",
}

# Skill categories
enum Category {
	ATTACK,      # Damage enhancement skills
	DEFENSE,     # Slow, freeze, shield skills
	UTILITY,     # Gold, vision, taunt, etc.
}

# Unlock type
enum UnlockType {
	LEVEL_COMPLETE,  # Unlock by completing levels
	GOLD_COST,      # Unlock by spending gold
}

# Skill definitions as class variables
static func get_all_skills() -> Array[Dictionary]:
	return [
		# === ATTACK SKILLS ===
		{
			"id": SKILL_IDS.RAPID_FIRE,
			"name": "Rapid Fire",
			"icon": "⚡",
			"description": "Attack speed +30%",
			"category": Category.ATTACK,
			"effect_type": "attack_speed",
			"effect_value": 0.30,
			"energy_cost": 1,
			"unlock_type": UnlockType.LEVEL_COMPLETE,
			"unlock_value": 1,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.CRITICAL_STRIKE,
			"name": "Critical Strike",
			"icon": "💥",
			"description": "Crit rate +20%, Crit damage +50%",
			"category": Category.ATTACK,
			"effect_type": "critical",
			"crit_rate": 0.20,
			"crit_damage": 1.50,
			"energy_cost": 2,
			"unlock_type": UnlockType.LEVEL_COMPLETE,
			"unlock_value": 2,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.SPLASH_DAMAGE,
			"name": "Splash Damage",
			"icon": "💫",
			"description": "Splash radius +50%",
			"category": Category.ATTACK,
			"effect_type": "splash",
			"effect_value": 0.50,
			"energy_cost": 2,
			"unlock_type": UnlockType.LEVEL_COMPLETE,
			"unlock_value": 3,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.PIERCE,
			"name": "Pierce",
			"icon": "🎯",
			"description": "Bullets pierce +1 enemy",
			"category": Category.ATTACK,
			"effect_type": "pierce",
			"effect_value": 1,
			"energy_cost": 1,
			"unlock_type": UnlockType.LEVEL_COMPLETE,
			"unlock_value": 4,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.CHAIN_LIGHTNING,
			"name": "Chain Lightning",
			"icon": "⚡",
			"description": "Lightning bounces 3 times",
			"category": Category.ATTACK,
			"effect_type": "chain",
			"effect_value": 3,
			"energy_cost": 3,
			"unlock_type": UnlockType.GOLD_COST,
			"unlock_value": 500,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.VAMPIRE,
			"name": "Vampire",
			"icon": "🧛",
			"description": "+10% lifesteal on kill",
			"category": Category.ATTACK,
			"effect_type": "lifesteal",
			"effect_value": 0.10,
			"energy_cost": 2,
			"unlock_type": UnlockType.LEVEL_COMPLETE,
			"unlock_value": 6,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.DOUBLE_SHOT,
			"name": "Double Shot",
			"icon": "🎱",
			"description": "Fire 2 bullets per attack",
			"category": Category.ATTACK,
			"effect_type": "double_shot",
			"effect_value": 2,
			"energy_cost": 2,
			"unlock_type": UnlockType.LEVEL_COMPLETE,
			"unlock_value": 8,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.EXPLOSIVE,
			"name": "Explosive",
			"icon": "💣",
			"description": "Bullets explode on impact",
			"category": Category.ATTACK,
			"effect_type": "explosive",
			"effect_value": 0.5,
			"energy_cost": 3,
			"unlock_type": UnlockType.GOLD_COST,
			"unlock_value": 800,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.LUCKY_STAR,
			"name": "Lucky Star",
			"icon": "⭐",
			"description": "5% chance to instant-kill",
			"category": Category.ATTACK,
			"effect_type": "lucky",
			"effect_value": 0.05,
			"energy_cost": 3,
			"unlock_type": UnlockType.GOLD_COST,
			"unlock_value": 1000,
			"unlocked": false,
		},
		
		# === DEFENSE SKILLS ===
		{
			"id": SKILL_IDS.FREEZE,
			"name": "Freeze",
			"icon": "❄️",
			"description": "Slow enemy -40% for 2s",
			"category": Category.DEFENSE,
			"effect_type": "freeze",
			"effect_value": 0.40,
			"duration": 2.0,
			"energy_cost": 1,
			"unlock_type": UnlockType.LEVEL_COMPLETE,
			"unlock_value": 2,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.SLOWING_AURA,
			"name": "Slowing Aura",
			"icon": "🌫️",
			"description": "Area slow -20% enemy speed",
			"category": Category.DEFENSE,
			"effect_type": "aura_slow",
			"effect_value": 0.20,
			"energy_cost": 2,
			"unlock_type": UnlockType.LEVEL_COMPLETE,
			"unlock_value": 5,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.SHIELD,
			"name": "Shield",
			"icon": "🛡️",
			"description": "Block 1 attack every 10s",
			"category": Category.DEFENSE,
			"effect_type": "shield",
			"effect_value": 1,
			"cooldown": 10.0,
			"energy_cost": 2,
			"unlock_type": UnlockType.LEVEL_COMPLETE,
			"unlock_value": 7,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.TIME_WARP,
			"name": "Time Warp",
			"icon": "⏰",
			"description": "All enemy speed -15%",
			"category": Category.DEFENSE,
			"effect_type": "time_warp",
			"effect_value": 0.15,
			"energy_cost": 3,
			"unlock_type": UnlockType.GOLD_COST,
			"unlock_value": 600,
			"unlocked": false,
		},
		
		# === UTILITY SKILLS ===
		{
			"id": SKILL_IDS.GOLD_RUSH,
			"name": "Gold Rush",
			"icon": "💰",
			"description": "+50% gold earned",
			"category": Category.UTILITY,
			"effect_type": "gold_bonus",
			"effect_value": 0.50,
			"energy_cost": 2,
			"unlock_type": UnlockType.LEVEL_COMPLETE,
			"unlock_value": 3,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.WIDE_VISION,
			"name": "Wide Vision",
			"icon": "👁️",
			"description": "All enemies visible 3s on spawn",
			"category": Category.UTILITY,
			"effect_type": "vision",
			"effect_value": 3.0,
			"energy_cost": 1,
			"unlock_type": UnlockType.LEVEL_COMPLETE,
			"unlock_value": 1,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.TAUNT,
			"name": "Taunt",
			"icon": "😡",
			"description": "Enemies prioritize this tower",
			"category": Category.UTILITY,
			"effect_type": "taunt",
			"effect_value": 1,
			"energy_cost": 2,
			"unlock_type": UnlockType.LEVEL_COMPLETE,
			"unlock_value": 9,
			"unlocked": false,
		},
		{
			"id": SKILL_IDS.COMBO_MASTER,
			"name": "Combo Master",
			"icon": "🔥",
			"description": "Combo duration +50%",
			"category": Category.UTILITY,
			"effect_type": "combo_duration",
			"effect_value": 0.50,
			"energy_cost": 2,
			"unlock_type": UnlockType.LEVEL_COMPLETE,
			"unlock_value": 10,
			"unlocked": false,
		},
	]

# Get skill by ID
static func get_skill(skill_id: String) -> Dictionary:
	for skill in get_all_skills():
		if skill["id"] == skill_id:
			return skill
	return {}

# Get skills by category
static func get_skills_by_category(category: Category) -> Array[Dictionary]:
	return get_all_skills().filter(func(s): return s["category"] == category)

# Get skill unlock cost description
static func get_unlock_text(skill: Dictionary) -> String:
	if skill["unlock_type"] == UnlockType.LEVEL_COMPLETE:
		return "Complete Level %d" % skill["unlock_value"]
	else:
		return "Purchase for %d gold" % skill["unlock_value"]