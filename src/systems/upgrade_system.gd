extends Node

## Upgrade System - Manages tower upgrade paths and costs
## Each tower has 3 upgrade paths that can be purchased with gold

# Signal when upgrade is purchased
signal upgrade_purchased(tower: Tower, path_index: int)
signal upgrade_panel_requested(tower: Tower)

# Upgrade costs and effects per tower type
const UPGRADE_DATA: Dictionary = {
	"mom": {
		"paths": [
			{"name": "Intensive Care", "cost": 75, "desc": "Heal amount +50%"},
			{"name": "Wide Reach", "cost": 60, "desc": "Range +50px"},
			{"name": "Overflow Love", "cost": 100, "desc": "Heal overflow passes to nearest tower"}
		]
	},
	"dad": {
		"paths": [
			{"name": "Deep Freeze", "cost": 75, "desc": "Slow amount +60%"},
			{"name": "Wide Zone", "cost": 60, "desc": "Range +50px"},
			{"name": "Frozen Ground", "cost": 100, "desc": "Slow includes 1s freeze"}
		]
	},
	"grandma": {
		"paths": [
			{"name": "Deep Sleep", "cost": 75, "desc": "Stun duration +2s"},
			{"name": "Wide Range", "cost": 60, "desc": "Range +50px"},
			{"name": "Group Hush", "cost": 100, "desc": "Stuns all enemies in range"}
		]
	},
	"doctor": {
		"paths": [
			{"name": "Surgery", "cost": 75, "desc": "DPS +50%"},
			{"name": "Long Reach", "cost": 60, "desc": "Range +50px"},
			{"name": "Critical Care", "cost": 100, "desc": "+20% critical hit chance"}
		]
	},
	"chef": {
		"paths": [
			{"name": "Gourmet", "cost": 75, "desc": "AoE damage +50%"},
			{"name": "Wide Spread", "cost": 60, "desc": "Range +50px"},
			{"name": "Splash Damage", "cost": 100, "desc": "Attacks bounce to 2 enemies at 50%"}
		]
	}
}

# Get upgrade data for a tower type
func get_upgrade_data(tower_type: String) -> Dictionary:
	return UPGRADE_DATA.get(tower_type.to_lower(), {"paths": []})

# Get cost for a specific upgrade path
func get_upgrade_cost(tower_type: String, path_index: int) -> int:
	var data = get_upgrade_data(tower_type)
	if data["paths"].size() > path_index:
		return data["paths"][path_index]["cost"]
	return 0

# Check if player can afford upgrade
func can_afford_upgrade(tower_type: String, path_index: int) -> bool:
	var cost = get_upgrade_cost(tower_type, path_index)
	return GameState.gold >= cost

# Purchase upgrade for tower
func purchase_upgrade(tower: Tower, path_index: int) -> bool:
	var tower_type = tower.tower_name.to_lower()
	var cost = get_upgrade_cost(tower_type, path_index)
	
	if not can_afford_upgrade(tower_type, path_index):
		return false
	
	if tower.upgrade_paths[path_index]:
		return false  # Already purchased
	
	# Deduct gold
	GameState.gold -= cost
	
	# Track investment
	tower.total_invested += cost
	
	# Mark path as purchased
	tower.upgrade_paths[path_index] = true
	
	# Apply upgrade effect
	_apply_upgrade_effect(tower, path_index)
	
	upgrade_purchased.emit(tower, path_index)
	return true

# Apply upgrade effect to tower based on path
func _apply_upgrade_effect(tower: Tower, path_index: int) -> void:
	var tower_type = tower.tower_name.to_lower()
	
	match tower_type:
		"mom":
			_apply_mom_upgrade(tower, path_index)
		"dad":
			_apply_dad_upgrade(tower, path_index)
		"grandma":
			_apply_grandma_upgrade(tower, path_index)
		"doctor":
			_apply_doctor_upgrade(tower, path_index)
		"chef":
			_apply_chef_upgrade(tower, path_index)

func _apply_mom_upgrade(tower: Tower, path_index: int) -> void:
	match path_index:
		0:  # Intensive Care - heal +50%
			tower.heal_amount *= 1.5
		1:  # Wide Reach - range +50px
			tower.range += 50
			tower.update_range_area()
		2:  # Overflow Love - handled in heal logic
			tower.has_overflow_love = true

func _apply_dad_upgrade(tower: Tower, path_index: int) -> void:
	match path_index:
		0:  # Deep Freeze - slow +60% (50% -> 80% slow = slow_factor 0.5 -> 0.2)
			tower.slow_factor = 0.2  # 80% slow
		1:  # Wide Zone - range +50px
			tower.range += 50
			tower.update_range_area()
		2:  # Frozen Ground - slow includes freeze
			tower.has_frozen_ground = true

func _apply_grandma_upgrade(tower: Tower, path_index: int) -> void:
	match path_index:
		0:  # Deep Sleep - stun +2s
			tower.stun_duration += 2.0
		1:  # Wide Range - range +50px
			tower.range += 50
			tower.update_range_area()
		2:  # Group Hush - stuns all in range
			tower.has_group_hush = true

func _apply_doctor_upgrade(tower: Tower, path_index: int) -> void:
	match path_index:
		0:  # Surgery - DPS +50%
			tower.damage *= 1.5
		1:  # Long Reach - range +50px
			tower.range += 50
			tower.update_range_area()
		2:  # Critical Care - +20% crit
			tower.crit_chance = 0.2

func _apply_chef_upgrade(tower: Tower, path_index: int) -> void:
	match path_index:
		0:  # Gourmet - AoE damage +50%
			tower.aoe_damage *= 1.5
		1:  # Wide Spread - range +50px
			tower.range += 50
			tower.update_range_area()
		2:  # Splash Damage - bounces to 2 enemies
			tower.has_splash_damage = true

# Calculate sell value (50% of total invested)
func calculate_sell_value(tower: Tower) -> int:
	return int(tower.total_invested * 0.5)

# Check if tower is max level (all paths purchased)
func is_tower_maxed(tower: Tower) -> bool:
	for path in tower.upgrade_paths:
		if not path:
			return false
	return true

# Get upgrade status for UI display
func get_upgrade_status(tower: Tower) -> Array:
	var result = []
	var tower_type = tower.tower_name.to_lower()
	var data = get_upgrade_data(tower_type)
	
	for i in range(3):
		if i < tower.upgrade_paths.size():
			var purchased = tower.upgrade_paths[i]
			var cost = data["paths"][i]["cost"] if i < data["paths"].size() else 0
			var name = data["paths"][i]["name"] if i < data["paths"].size() else ""
			var desc = data["paths"][i]["desc"] if i < data["paths"].size() else ""
			result.append({
				"index": i,
				"name": name,
				"desc": desc,
				"cost": cost,
				"purchased": purchased,
				"can_afford": GameState.gold >= cost
			})
		else:
			result.append({"index": i, "purchased": false, "can_afford": false})
	
	return result