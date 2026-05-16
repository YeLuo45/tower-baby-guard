extends Resource
class_name CollectionData

## CollectionData - Resource subclass defining all 108 collectible items
## Categories: Enemies (11), Towers (60), Achievements (20), Skills (17)
## Used by CollectionSystem autoload to track collection progress

# Collection item types
enum ItemType {
	ENEMY,
	TOWER,
	ACHIEVEMENT,
	SKILL
}

# Enemy sub-types
enum EnemyType {
	NORMAL,
	ELITE,
	BOSS
}

# Tower upgrade levels (0=base, 1-4=purchased upgrades)
# 3 paths × 5 levels each = 15 forms per tower type

# ============================================
# ENEMY DEFINITIONS (11 total)
# ============================================
# Normal monsters: 5 types
# Elite monsters: 3 types
# Boss monsters: 3 types

static func get_enemies() -> Array[Dictionary]:
	return [
		# === NORMAL MONSTERS (5) ===
		{
			"id": "enemy_tantrum",
			"name": "Tantrum",
			"desc": "A crying child with low HP but fast movement. Gets triggered easily.",
			"icon": "😢",
			"type": ItemType.ENEMY,
			"sub_type": EnemyType.NORMAL,
			"hp": 50,
			"speed": 120,
			"reward": 5,
			"unlocked": false,
		},
		{
			"id": "enemy_bedtime",
			"name": "Bedtime Battle",
			"desc": "A sleepy child who becomes invulnerable during 'sleep' phases.",
			"icon": "😴",
			"type": ItemType.ENEMY,
			"sub_type": EnemyType.NORMAL,
			"hp": 80,
			"speed": 60,
			"reward": 10,
			"unlocked": false,
		},
		{
			"id": "enemy_veggie",
			"name": "Veggie Hater",
			"desc": "A stubborn child with high HP who refuses vegetables.",
			"icon": "🥦",
			"type": ItemType.ENEMY,
			"sub_type": EnemyType.NORMAL,
			"hp": 150,
			"speed": 80,
			"reward": 15,
			"unlocked": false,
		},
		{
			"id": "enemy_screen_time",
			"name": "Screen Addict",
			"desc": "A distracted child immune to slow effects when watching screens.",
			"icon": "📱",
			"type": ItemType.ENEMY,
			"sub_type": EnemyType.NORMAL,
			"hp": 100,
			"speed": 80,
			"reward": 12,
			"special": "immune_to_slow",
			"unlocked": false,
		},
		{
			"id": "enemy_outing_refusal",
			"name": "Home Body",
			"desc": "A clingy child who moves slowly but is worth more gold.",
			"icon": "🏠",
			"type": ItemType.ENEMY,
			"sub_type": EnemyType.NORMAL,
			"hp": 70,
			"speed": 50,
			"reward": 20,
			"unlocked": false,
		},
		
		# === ELITE MONSTERS (3) ===
		{
			"id": "enemy_bath_time",
			"name": "Bath Time Hero",
			"desc": "An elite child who resists stun effects and has increased HP.",
			"icon": "🛁",
			"type": ItemType.ENEMY,
			"sub_type": EnemyType.ELITE,
			"hp": 300,
			"speed": 90,
			"reward": 30,
			"special": "stun_resist",
			"unlocked": false,
		},
		{
			"id": "enemy_timeout_titan",
			"name": "Timeout Titan",
			"desc": "An elite who starts with a brief invulnerability shield.",
			"icon": "⏰",
			"type": ItemType.ENEMY,
			"sub_type": EnemyType.ELITE,
			"hp": 400,
			"speed": 70,
			"reward": 40,
			"special": "shield_start",
			"unlocked": false,
		},
		{
			"id": "enemy tantrum_king",
			"name": "Tantrum King",
			"desc": "An elite version of Tantrum with double HP and speed aura.",
			"icon": "👑",
			"type": ItemType.ENEMY,
			"sub_type": EnemyType.ELITE,
			"hp": 500,
			"speed": 150,
			"reward": 50,
			"special": "speed_aura",
			"unlocked": false,
		},
		
		# === BOSS MONSTERS (3) ===
		{
			"id": "enemy_boss_tantrum",
			"name": "Mega Tantrum",
			"desc": "BOSS: A massive tantrum with 3 phases. Gets faster as HP decreases.",
			"icon": "😡",
			"type": ItemType.ENEMY,
			"sub_type": EnemyType.BOSS,
			"hp": 2000,
			"speed": 100,
			"reward": 200,
			"phases": 3,
			"unlocked": false,
		},
		{
			"id": "enemy_boss_veggie",
			"name": "Veggiezilla",
			"desc": "BOSS: An enormous child who spawns mini veggies when HP drops.",
			"icon": "🥬",
			"type": ItemType.ENEMY,
			"sub_type": EnemyType.BOSS,
			"hp": 3000,
			"speed": 50,
			"reward": 250,
			"phases": 3,
			"special": "spawns_minions",
			"unlocked": false,
		},
		{
			"id": "enemy_boss_screen",
			"name": "Screen Lord",
			"desc": "BOSS: A digital tyrant who hacks towers to disable them temporarily.",
			"icon": "🖥️",
			"type": ItemType.ENEMY,
			"sub_type": EnemyType.BOSS,
			"hp": 2500,
			"speed": 80,
			"reward": 300,
			"phases": 3,
			"special": "hacks_towers",
			"unlocked": false,
		},
	]

# ============================================
# TOWER DEFINITIONS (60 total)
# 4 tower types × 15 upgrade forms each
# ============================================

static func get_towers() -> Array[Dictionary]:
	var towers: Array[Dictionary] = []
	var tower_types = ["mom", "dad", "grandma", "doctor", "chef"]
	var tower_names = {
		"mom": "Mom Tower",
		"dad": "Dad Tower", 
		"grandma": "Grandma Tower",
		"doctor": "Doctor Tower",
		"chef": "Chef Tower"
	}
	var tower_icons = {
		"mom": "👩",
		"dad": "👨",
		"grandma": "👵",
		"doctor": "🩺",
		"chef": "👨‍🍳"
	}
	var tower_descs = {
		"mom": "Heals nearby towers. Upgrade paths: Intensive Care, Wide Reach, Overflow Love",
		"dad": "Slows enemies. Upgrade paths: Deep Freeze, Wide Zone, Frozen Ground",
		"grandma": "Stuns enemies. Upgrade paths: Deep Sleep, Wide Range, Group Hush",
		"doctor": "High DPS. Upgrade paths: Surgery, Long Reach, Critical Care",
		"chef": "AoE damage. Upgrade paths: Gourmet, Wide Spread, Splash Damage"
	}
	
	for tower_type in tower_types:
		# Create 15 upgrade forms for each tower type
		# Form 0: Base (no upgrades)
		# Form 1-3: One upgrade purchased
		# Form 4-6: Two upgrades purchased
		# Form 7-9: Three upgrades purchased (full)
		# Form 10-12: Max level with强化
		# Form 13-14: Ultimate forms
		
		# Upgrade path names for each tower
		var path_names = []
		var path_names_by_tower = {
			"mom": ["Intensive Care", "Wide Reach", "Overflow Love"],
			"dad": ["Deep Freeze", "Wide Zone", "Frozen Ground"],
			"grandma": ["Deep Sleep", "Wide Range", "Group Hush"],
			"doctor": ["Surgery", "Long Reach", "Critical Care"],
			"chef": ["Gourmet", "Wide Spread", "Splash Damage"]
		}
		path_names = path_names_by_tower[tower_type]
		
		# Generate all 15 forms
		# Forms 0-2: 1 upgrade purchased (from 3 paths)
		for i in range(3):
			towers.append({
				"id": "tower_%s_form_%d" % [tower_type, i + 1],
				"name": "%s +%s" % [tower_names[tower_type], path_names[i]],
				"desc": "Tier 1: Base %s with %s upgrade" % [tower_names[tower_type], path_names[i]],
				"icon": tower_icons[tower_type],
				"type": ItemType.TOWER,
				"tower_type": tower_type,
				"form_index": i + 1,
				"upgrades": [i],
				"tier": 1,
				"unlocked": false,
			})
		
		# Forms 3-5: 2 upgrades purchased
		var two_upgrade_combos = [[0, 1], [0, 2], [1, 2]]
		for idx in range(3):
			var combo = two_upgrade_combos[idx]
			var names = [path_names[combo[0]], path_names[combo[1]]]
			towers.append({
				"id": "tower_%s_form_%d" % [tower_type, idx + 4],
				"name": "%s +%s/+%s" % [tower_names[tower_type], names[0], names[1]],
				"desc": "Tier 2: %s with %s and %s" % [tower_names[tower_type], names[0], names[1]],
				"icon": tower_icons[tower_type],
				"type": ItemType.TOWER,
				"tower_type": tower_type,
				"form_index": idx + 4,
				"upgrades": combo,
				"tier": 2,
				"unlocked": false,
			})
		
		# Forms 6-8: All 3 upgrades (full)
		towers.append({
			"id": "tower_%s_form_%d" % [tower_type, 7],
			"name": "%s Full Power" % tower_names[tower_type],
			"desc": "Tier 3: %s with all upgrades maxed" % tower_names[tower_type],
			"icon": tower_icons[tower_type],
			"type": ItemType.TOWER,
			"tower_type": tower_type,
			"form_index": 7,
			"upgrades": [0, 1, 2],
			"tier": 3,
			"unlocked": false,
		})
		
		# Forms 9-14: Level 4-5 enhanced versions (6 forms)
		# Level 4 forms (repeatable upgrades at higher tiers)
		var enhanced_names = ["Supreme", "Ultimate", "Legendary", "Mythic", "Divine", "Transcendent"]
		for idx in range(6):
			towers.append({
				"id": "tower_%s_form_%d" % [tower_type, idx + 9],
				"name": "%s %s" % [tower_names[tower_type], enhanced_names[idx]],
				"desc": "Tier %d: Enhanced %s at maximum power" % [4 + idx / 2, tower_names[tower_type]],
				"icon": tower_icons[tower_type],
				"type": ItemType.TOWER,
				"tower_type": tower_type,
				"form_index": idx + 9,
				"upgrades": [0, 1, 2],
				"tier": 4 + idx / 2,
				"enhanced": true,
				"enhance_index": idx,
				"unlocked": false,
			})
	
	return towers

# ============================================
# ACHIEVEMENT DEFINITIONS (20) - from achievement_system.gd
# ============================================

static func get_achievements() -> Array[Dictionary]:
	return [
		# === BASIC (8) ===
		{"id": "first_steps", "name": "第一次", "desc": "Complete your first wave", "icon": "👶", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "home_defender", "name": "家园守护者", "desc": "Complete level 1", "icon": "🏠", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "goldrush", "name": "淘金者", "desc": "Earn 500 gold in one run", "icon": "💰", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "combo_starter", "name": "组合新手", "desc": "Trigger your first combo", "icon": "✨", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "upgrade_buyer", "name": "升级达人", "desc": "Purchase your first upgrade", "icon": "⬆️", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "perfectionist", "name": "完美主义者", "desc": "Complete a wave with full lives", "icon": "⭐", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "speedrunner", "name": "速通达人", "desc": "Complete wave 1-5 within 3 minutes", "icon": "⚡", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "veteran", "name": "老练家长", "desc": "Play 10 games", "icon": "🎖️", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		
		# === TOWER MASTER (5) ===
		{"id": "mom_love", "name": "妈妈的爱", "desc": "Win with Mom tower as top killer", "icon": "👩", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "dad_protect", "name": "爸爸的保护", "desc": "Win using only Dad towers", "icon": "👨", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "grandma_wisdom", "name": "奶奶的智慧", "desc": "Stun 20 enemies in one run", "icon": "👵", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "doctor_heal", "name": "医生的救治", "desc": "Emergency Room combo triggered", "icon": "🩺", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "chef_special", "name": "厨师的特供", "desc": "Kill 10 enemies with Chef in one run", "icon": "👨‍🍳", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		
		# === COMBO MASTER (4) ===
		{"id": "full_house_achieved", "name": "四世同堂", "desc": "Trigger Full House combo", "icon": "🏡", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "combo_chain", "name": "连锁反应", "desc": "Trigger 3 different combos in one wave", "icon": "🔗", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "emergency_doctor", "name": "急诊室", "desc": "Emergency Room triggered 3 times total", "icon": "🚑", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "master_chef", "name": "主厨的盛宴", "desc": "Family Meal triggered 5 times total", "icon": "🍳", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		
		# === RARE (3) ===
		{"id": "flawless_victory", "name": "完美胜利", "desc": "Complete level 1 with zero lives lost", "icon": "🌟", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "economist", "name": "经济学家", "desc": "Finish with over 500 gold remaining", "icon": "📊", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "all_towers", "name": "全员到齐", "desc": "Have all 5 tower types in one game", "icon": "🎯", "type": ItemType.ACHIEVEMENT, "unlocked": false},
		{"id": "skill_collector", "name": "技能收集者", "desc": "Unlock 5 different skills", "icon": "📜", "type": ItemType.ACHIEVEMENT, "unlocked": false},
	]

# ============================================
# SKILL DEFINITIONS (17) - from skill_data.gd
# ============================================

static func get_skills() -> Array[Dictionary]:
	return [
		# === ATTACK SKILLS (9) ===
		{"id": "rapid_fire", "name": "Rapid Fire", "desc": "Attack speed +30%", "icon": "⚡", "type": ItemType.SKILL, "category": "ATTACK", "unlocked": false},
		{"id": "critical_strike", "name": "Critical Strike", "desc": "Crit rate +20%, Crit damage +50%", "icon": "💥", "type": ItemType.SKILL, "category": "ATTACK", "unlocked": false},
		{"id": "splash_damage", "name": "Splash Damage", "desc": "Splash radius +50%", "icon": "💫", "type": ItemType.SKILL, "category": "ATTACK", "unlocked": false},
		{"id": "pierce", "name": "Pierce", "desc": "Bullets pierce +1 enemy", "icon": "🎯", "type": ItemType.SKILL, "category": "ATTACK", "unlocked": false},
		{"id": "chain_lightning", "name": "Chain Lightning", "desc": "Lightning bounces 3 times", "icon": "⚡", "type": ItemType.SKILL, "category": "ATTACK", "unlocked": false},
		{"id": "vampire", "name": "Vampire", "desc": "+10% lifesteal on kill", "icon": "🧛", "type": ItemType.SKILL, "category": "ATTACK", "unlocked": false},
		{"id": "double_shot", "name": "Double Shot", "desc": "Fire 2 bullets per attack", "icon": "🎱", "type": ItemType.SKILL, "category": "ATTACK", "unlocked": false},
		{"id": "explosive", "name": "Explosive", "desc": "Bullets explode on impact", "icon": "💣", "type": ItemType.SKILL, "category": "ATTACK", "unlocked": false},
		{"id": "lucky_star", "name": "Lucky Star", "desc": "5% chance to instant-kill", "icon": "⭐", "type": ItemType.SKILL, "category": "ATTACK", "unlocked": false},
		
		# === DEFENSE SKILLS (5) ===
		{"id": "freeze", "name": "Freeze", "desc": "Slow enemy -40% for 2s", "icon": "❄️", "type": ItemType.SKILL, "category": "DEFENSE", "unlocked": false},
		{"id": "slowing_aura", "name": "Slowing Aura", "desc": "Area slow -20% enemy speed", "icon": "🌫️", "type": ItemType.SKILL, "category": "DEFENSE", "unlocked": false},
		{"id": "shield", "name": "Shield", "desc": "Block 1 attack every 10s", "icon": "🛡️", "type": ItemType.SKILL, "category": "DEFENSE", "unlocked": false},
		{"id": "time_warp", "name": "Time Warp", "desc": "All enemy speed -15%", "icon": "⏰", "type": ItemType.SKILL, "category": "DEFENSE", "unlocked": false},
		{"id": "slowing_aura_plus", "name": "Slowing Aura+", "desc": "Area slow -30% enemy speed", "icon": "🌫️", "type": ItemType.SKILL, "category": "DEFENSE", "unlocked": false},
		
		# === UTILITY SKILLS (3) ===
		{"id": "gold_rush", "name": "Gold Rush", "desc": "+50% gold earned", "icon": "💰", "type": ItemType.SKILL, "category": "UTILITY", "unlocked": false},
		{"id": "wide_vision", "name": "Wide Vision", "desc": "All enemies visible 3s on spawn", "icon": "👁️", "type": ItemType.SKILL, "category": "UTILITY", "unlocked": false},
		{"id": "combo_master", "name": "Combo Master", "desc": "Combo duration +50%", "icon": "🔥", "type": ItemType.SKILL, "category": "UTILITY", "unlocked": false},
	]

# ============================================
# HELPER FUNCTIONS
# ============================================

static func get_all_items() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	all.append_array(get_enemies())
	all.append_array(get_towers())
	all.append_array(get_achievements())
	all.append_array(get_skills())
	return all

static func get_items_by_type(item_type: ItemType) -> Array[Dictionary]:
	return get_all_items().filter(func(item): return item["type"] == item_type)

static func get_item(item_id: String) -> Dictionary:
	for item in get_all_items():
		if item["id"] == item_id:
			return item
	return {}

static func get_total_count() -> int:
	return get_all_items().size()  # Should be 108

static func get_count_by_type(item_type: ItemType) -> int:
	return get_items_by_type(item_type).size()