extends Resource
class_name GachaData

## Gacha Data - Resource class defining gacha pools and reward pools
## Three egg types: Normal, Rare, Limited

enum GachaType {
	NORMAL,   # Common rewards: gold, skill fragments, exp
	RARE,     # Better rewards: skills, rare skins, titles
	LIMITED   # Premium rewards: limited skins, legendary titles, lots of gold
}

enum RewardCategory {
	GOLD,
	SKILL_FRAGMENT,
	EXP,
	SKILL,
	SKIN,
	TITLE,
	LIMITED_SKIN,
	LEGENDARY_TITLE
}

# Gacha pool definition
class GachaPool:
	var pool_type: GachaType
	var display_name: String
	var description: String
	var icon_color: Color
	var single_cost: int = 100        # Gold cost for single pull
	var multi_cost: int = 900         # Gold cost for 10-pull (10% discount)
	var free_coupons: int = 1         # Daily free coupons
	var weights: Array = []           # Reward weight entries
	
	func _init(type: GachaType, name: String, desc: String, color: Color):
		pool_type = type
		display_name = name
		description = desc
		icon_color = color
	
	func add_weight(reward_id: String, category: RewardCategory, weight: float, 
				   min_value: int = 0, max_value: int = 0, metadata: Dictionary = {}) -> void:
		weights.append({
			"reward_id": reward_id,
			"category": category,
			"weight": weight,
			"min_value": min_value,
			"max_value": max_value,
			"metadata": metadata
		})

# Reward definition
class GachaReward:
	var reward_id: String
	var category: RewardCategory
	var display_name: String
	var description: String
	var icon_path: String
	var rarity: int  # 0-5, higher = more rare
	var quantity: int = 1
	
	func _init(id: String, cat: RewardCategory, name: String, desc: String, 
			  rarity_val: int = 1):
		reward_id = id
		category = cat
		display_name = name
		description = desc
		rarity = rarity_val

# Create normal gacha pool
static func create_normal_pool() -> GachaPool:
	var pool = GachaPool.new(
		GachaType.NORMAL,
		"普通扭蛋",
		"包含金币、经验药水、技能碎片",
		Color(0.7, 0.7, 0.7, 1.0)
	)
	pool.single_cost = 100
	pool.multi_cost = 900
	
	# Gold rewards (common)
	pool.add_weight("gold_small", RewardCategory.GOLD, 30.0, 50, 100)
	pool.add_weight("gold_medium", RewardCategory.GOLD, 15.0, 100, 200)
	
	# Skill fragments (common)
	pool.add_weight("fragment_attack", RewardCategory.SKILL_FRAGMENT, 20.0, 1, 1)
	pool.add_weight("fragment_defense", RewardCategory.SKILL_FRAGMENT, 15.0, 1, 1)
	pool.add_weight("fragment_speed", RewardCategory.SKILL_FRAGMENT, 10.0, 1, 1)
	
	# Experience (common)
	pool.add_weight("exp_small", RewardCategory.EXP, 10.0, 50, 100)
	
	return pool

# Create rare gacha pool
static func create_rare_pool() -> GachaPool:
	var pool = GachaPool.new(
		GachaType.RARE,
		"稀有扭蛋",
		"包含随机技能、稀有皮肤、特殊称号",
		Color(0.3, 0.5, 1.0, 1.0)
	)
	pool.single_cost = 500
	pool.multi_cost = 4500
	
	# Full skills (rare)
	pool.add_weight("skill_fireball", RewardCategory.SKILL, 8.0, 1, 1)
	pool.add_weight("skill_ice_blast", RewardCategory.SKILL, 8.0, 1, 1)
	pool.add_weight("skill_lightning", RewardCategory.SKILL, 7.0, 1, 1)
	pool.add_weight("skill_heal", RewardCategory.SKILL, 7.0, 1, 1)
	pool.add_weight("skill_shield", RewardCategory.SKILL, 6.0, 1, 1)
	
	# Rare skins
	pool.add_weight("skin_red_mom", RewardCategory.SKIN, 10.0, 1, 1)
	pool.add_weight("skin_blue_dad", RewardCategory.SKIN, 10.0, 1, 1)
	pool.add_weight("skin_green_grandma", RewardCategory.SKIN, 8.0, 1, 1)
	
	# Titles
	pool.add_weight("title_brave", RewardCategory.TITLE, 10.0, 1, 1)
	pool.add_weight("title_wise", RewardCategory.TITLE, 8.0, 1, 1)
	pool.add_weight("title_speedster", RewardCategory.TITLE, 7.0, 1, 1)
	
	return pool

# Create limited gacha pool
static func create_limited_pool() -> GachaPool:
	var pool = GachaPool.new(
		GachaType.LIMITED,
		"限定扭蛋",
		"节日限定皮肤、传说称号、海量金币",
		Color(1.0, 0.6, 0.1, 1.0)
	)
	pool.single_cost = 1000
	pool.multi_cost = 9000
	
	# Limited skins (very rare)
	pool.add_weight("skin_limited_spring", RewardCategory.LIMITED_SKIN, 5.0, 1, 1)
	pool.add_weight("skin_limited_summer", RewardCategory.LIMITED_SKIN, 4.0, 1, 1)
	pool.add_weight("skin_limited_autumn", RewardCategory.LIMITED_SKIN, 3.0, 1, 1)
	pool.add_weight("skin_limited_winter", RewardCategory.LIMITED_SKIN, 3.0, 1, 1)
	
	# Legendary titles
	pool.add_weight("title_legendary_hero", RewardCategory.LEGENDARY_TITLE, 5.0, 1, 1)
	pool.add_weight("title_legendary_master", RewardCategory.LEGENDARY_TITLE, 4.0, 1, 1)
	pool.add_weight("title_legendary_champion", RewardCategory.LEGENDARY_TITLE, 3.0, 1, 1)
	
	# Big gold rewards
	pool.add_weight("gold_large", RewardCategory.GOLD, 15.0, 500, 800)
	pool.add_weight("gold_huge", RewardCategory.GOLD, 8.0, 800, 1000)
	
	return pool

# Get all pools
static func get_all_pools() -> Array[GachaPool]:
	return [
		create_normal_pool(),
		create_rare_pool(),
		create_limited_pool()
	]

static func get_pool(type: GachaType) -> GachaPool:
	match type:
		GachaType.NORMAL:
			return create_normal_pool()
		GachaType.RARE:
			return create_rare_pool()
		GachaType.LIMITED:
			return create_limited_pool()
	return create_normal_pool()

# Pity system definitions
static func get_normal_pity_limit() -> int:
	return 10  # 10th pull guaranteed rare or above

static func get_limited_pity_limit() -> int:
	return 50  # 50th pull guaranteed limited

# Get reward display info
static func get_reward_display_info(reward: Dictionary) -> Dictionary:
	var info = {
		"name": "",
		"description": "",
		"rarity_color": Color.WHITE,
		"icon_path": ""
	}
	
	var category = reward.get("category")
	
	match category:
		RewardCategory.GOLD:
			info["name"] = "金币 x%d" % reward.get("quantity", 1)
			info["description"] = "游戏货币"
			info["rarity_color"] = Color(1.0, 0.84, 0.0, 1.0)  # Gold
		RewardCategory.SKILL_FRAGMENT:
			info["name"] = "技能碎片"
			info["description"] = "可用于合成技能"
			info["rarity_color"] = Color(0.7, 0.7, 0.7, 1.0)  # Gray
		RewardCategory.EXP:
			info["name"] = "经验值 x%d" % reward.get("quantity", 1)
			info["description"] = "用于升级"
			info["rarity_color"] = Color(0.4, 1.0, 0.4, 1.0)  # Green
		RewardCategory.SKILL:
			info["name"] = "技能: %s" % reward.get("reward_id", "Unknown")
			info["description"] = "完整的技能"
			info["rarity_color"] = Color(0.3, 0.5, 1.0, 1.0)  # Blue
		RewardCategory.SKIN:
			info["name"] = "皮肤: %s" % reward.get("reward_id", "Unknown")
			info["description"] = "稀有皮肤"
			info["rarity_color"] = Color(0.5, 0.3, 1.0, 1.0)  # Purple
		RewardCategory.TITLE:
			info["name"] = "称号: %s" % reward.get("reward_id", "Unknown")
			info["description"] = "特殊称号"
			info["rarity_color"] = Color(0.2, 0.8, 0.8, 1.0)  # Cyan
		RewardCategory.LIMITED_SKIN:
			info["name"] = "限定皮肤: %s" % reward.get("reward_id", "Unknown")
			info["description"] = "节日限定，绝版皮肤"
			info["rarity_color"] = Color(1.0, 0.6, 0.1, 1.0)  # Orange
		RewardCategory.LEGENDARY_TITLE:
			info["name"] = "传说称号: %s" % reward.get("reward_id", "Unknown")
			info["description"] = "传说级称号"
			info["rarity_color"] = Color(1.0, 0.8, 0.0, 1.0)  # Gold
	
	return info