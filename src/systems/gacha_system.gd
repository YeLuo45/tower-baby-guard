extends Node

## Gacha System - Autoload managing gacha pulls, pity system, and inventory
## Handles all gacha-related mechanics including free coupons and history

const SAVE_SECTION = "gacha"

# Pool instances
var normal_pool: GachaData.GachaPool
var rare_pool: GachaData.GachaPool
var limited_pool: GachaData.GachaPool

# Pity counters
var normal_pity_counter: int = 0  # Resets after rare+ pull
var limited_pity_counter: int = 0  # Resets after limited pull

# Free coupons (daily reset)
var free_coupons_normal: int = 1
var free_coupons_rare: int = 0
var free_coupons_limited: int = 0
var last_coupon_reset_date: String = ""

# Inventory
var owned_rewards: Dictionary = {
	GachaData.RewardCategory.GOLD: 0,
	GachaData.RewardCategory.SKILL_FRAGMENT: 0,
	GachaData.RewardCategory.EXP: 0,
}
var owned_skins: Array = []
var owned_titles: Array = []
var owned_skills: Array = []

# Pull history (last 20 pulls)
var pull_history: Array = []
const MAX_HISTORY = 20

# Signals
signal pull_completed(gacha_type: GachaData.GachaType, rewards: Array)
signal pity_threshold_reached(gacha_type: GachaData.GachaType)
signal free_coupon_updated(pool_type: GachaData.GachaType, remaining: int)
signal inventory_updated()

func _ready() -> void:
	_initialize_pools()
	_load_gacha_data()
	_check_daily_reset()

func _initialize_pools() -> void:
	normal_pool = GachaData.create_normal_pool()
	rare_pool = GachaData.create_rare_pool()
	limited_pool = GachaData.create_limited_pool()

# Persistence
func _load_gacha_data() -> void:
	if not PersistenceSystem:
		return
	
	var config = ConfigFile.new()
	var err = config.load(PersistenceSystem.SAVE_FILE_PATH)
	
	if err != OK:
		return
	
	var section_keys = config.get_section_keys(SAVE_SECTION)
	for key in section_keys:
		match key:
			"normal_pity":
				normal_pity_counter = config.get_value(SAVE_SECTION, key)
			"limited_pity":
				limited_pity_counter = config.get_value(SAVE_SECTION, key)
			"free_coupons_normal":
				free_coupons_normal = config.get_value(SAVE_SECTION, key)
			"free_coupons_rare":
				free_coupons_rare = config.get_value(SAVE_SECTION, key)
			"free_coupons_limited":
				free_coupons_limited = config.get_value(SAVE_SECTION, key)
			"last_reset":
				last_coupon_reset_date = config.get_value(SAVE_SECTION, key)
			"history":
				pull_history = config.get_value(SAVE_SECTION, key)
			"skins":
				owned_skins = config.get_value(SAVE_SECTION, key)
			"titles":
				owned_titles = config.get_value(SAVE_SECTION, key)
			"skills":
				owned_skills = config.get_value(SAVE_SECTION, key)

func save_gacha_data() -> void:
	if not PersistenceSystem:
		return
	
	var config = ConfigFile.new()
	var err = config.load(PersistenceSystem.SAVE_FILE_PATH)
	
	if err != OK:
		return
	
	config.set_value(SAVE_SECTION, "normal_pity", normal_pity_counter)
	config.set_value(SAVE_SECTION, "limited_pity", limited_pity_counter)
	config.set_value(SAVE_SECTION, "free_coupons_normal", free_coupons_normal)
	config.set_value(SAVE_SECTION, "free_coupons_rare", free_coupons_rare)
	config.set_value(SAVE_SECTION, "free_coupons_limited", free_coupons_limited)
	config.set_value(SAVE_SECTION, "last_reset", last_coupon_reset_date)
	config.set_value(SAVE_SECTION, "history", pull_history)
	config.set_value(SAVE_SECTION, "skins", owned_skins)
	config.set_value(SAVE_SECTION, "titles", owned_titles)
	config.set_value(SAVE_SECTION, "skills", owned_skills)
	
	config.save(PersistenceSystem.SAVE_FILE_PATH)

# Daily reset check
func _check_daily_reset() -> void:
	var today = _get_current_date()
	if last_coupon_reset_date != today:
		_reset_daily_coupons()
		last_coupon_reset_date = today

func _reset_daily_coupons() -> void:
	free_coupons_normal = 1
	free_coupons_rare = 0
	free_coupons_limited = 0
	save_gacha_data()

# Pull methods
func pull_single(gacha_type: GachaData.GachaType, use_free: bool = true) -> Array:
	var pool = _get_pool(gacha_type)
	
	# Check free coupon
	if use_free and has_free_coupon(gacha_type):
		_use_free_coupon(gacha_type)
		return _execute_pull(gacha_type, pool, 1)
	
	# Check gold cost
	var cost = pool.single_cost
	if GameState and GameState.gold >= cost:
		GameState.gold -= cost
		return _execute_pull(gacha_type, pool, 1)
	
	return []  # Not enough gold

func pull_multi(gacha_type: GachaData.GachaType) -> Array:
	var pool = _get_pool(gacha_type)
	
	# Check gold cost (10-pull)
	var cost = pool.multi_cost
	if GameState and GameState.gold >= cost:
		GameState.gold -= cost
		return _execute_pull(gacha_type, pool, 10)
	
	return []

func _execute_pull(gacha_type: GachaData.GachaType, pool: GachaData.GachaPool, count: int) -> Array:
	var rewards: Array = []
	
	# Update pity counters
	if gacha_type == GachaData.GachaType.NORMAL:
		normal_pity_counter += count
	elif gacha_type == GachaData.GachaType.LIMITED:
		limited_pity_counter += count
	
	# Pull rewards
	for i in range(count):
		var reward = _roll_reward(pool, gacha_type)
		rewards.append(reward)
		_process_reward(reward)
		_add_to_history(gacha_type, reward)
	
	# Check pity
	_check_pity(gacha_type, rewards)
	
	save_gacha_data()
	pull_completed.emit(gacha_type, rewards)
	return rewards

func _roll_reward(pool: GachaData.GachaPool, gacha_type: GachaData.GachaType) -> Dictionary:
	var total_weight = 0.0
	for entry in pool.weights:
		total_weight += entry["weight"]
	
	var roll = randf() * total_weight
	var cumulative = 0.0
	
	for entry in pool.weights:
		cumulative += entry["weight"]
		if roll <= cumulative:
			return _create_reward_from_entry(entry)
	
	# Fallback to first entry
	return _create_reward_from_entry(pool.weights[0])

func _create_reward_from_entry(entry: Dictionary) -> Dictionary:
	var quantity = 1
	
	# Handle quantity ranges for certain rewards
	if entry["max_value"] > entry["min_value"]:
		quantity = randi() % (entry["max_value"] - entry["min_value"] + 1) + entry["min_value"]
	
	var reward = {
		"reward_id": entry["reward_id"],
		"category": entry["category"],
		"quantity": quantity,
		"weight": entry["weight"],
		"metadata": entry["metadata"]
	}
	
	return reward

func _process_reward(reward: Dictionary) -> void:
	var category = reward["category"]
	var quantity = reward.get("quantity", 1)
	
	match category:
		GachaData.RewardCategory.GOLD:
			owned_rewards[GachaData.RewardCategory.GOLD] += quantity
			if GameState:
				GameState.gold += quantity
		GachaData.RewardCategory.EXP:
			owned_rewards[GachaData.RewardCategory.EXP] += quantity
		GachaData.RewardCategory.SKILL_FRAGMENT:
			owned_rewards[GachaData.RewardCategory.SKILL_FRAGMENT] += quantity
		GachaData.RewardCategory.SKILL:
			if not owned_skills.has(reward["reward_id"]):
				owned_skills.append(reward["reward_id"])
		GachaData.RewardCategory.SKIN:
			if not owned_skins.has(reward["reward_id"]):
				owned_skins.append(reward["reward_id"])
		GachaData.RewardCategory.TITLE:
			if not owned_titles.has(reward["reward_id"]):
				owned_titles.append(reward["reward_id"])
		GachaData.RewardCategory.LIMITED_SKIN:
			if not owned_skins.has(reward["reward_id"]):
				owned_skins.append(reward["reward_id"])
		GachaData.RewardCategory.LEGENDARY_TITLE:
			if not owned_titles.has(reward["reward_id"]):
				owned_titles.append(reward["reward_id"])
	
	inventory_updated.emit()

func _check_pity(gacha_type: GachaData.GachaType, rewards: Array) -> void:
	if gacha_type == GachaData.GachaType.NORMAL:
		if normal_pity_counter >= GachaData.get_normal_pity_limit():
			# Force a rare or higher reward on the last pull if not already
			var has_rare = false
			for r in rewards:
				if _is_rare_or_above(r):
					has_rare = true
					break
			if not has_rare and rewards.size() > 0:
				# Upgrade last reward to rare
				rewards[-1] = _force_rare_reward()
			normal_pity_counter = 0
			pity_threshold_reached.emit(gacha_type)
	
	elif gacha_type == GachaData.GachaType.LIMITED:
		if limited_pity_counter >= GachaData.get_limited_pity_limit():
			# Force a limited reward on the last pull if not already
			var has_limited = false
			for r in rewards:
				if _is_limited(r):
					has_limited = true
					break
			if not has_limited and rewards.size() > 0:
				rewards[-1] = _force_limited_reward()
			limited_pity_counter = 0
			pity_threshold_reached.emit(gacha_type)

func _is_rare_or_above(reward: Dictionary) -> bool:
	var category = reward["category"]
	return category in [
		GachaData.RewardCategory.SKILL,
		GachaData.RewardCategory.SKIN,
		GachaData.RewardCategory.TITLE,
		GachaData.RewardCategory.LIMITED_SKIN,
		GachaData.RewardCategory.LEGENDARY_TITLE
	]

func _is_limited(reward: Dictionary) -> bool:
	var category = reward["category"]
	return category in [
		GachaData.RewardCategory.LIMITED_SKIN,
		GachaData.RewardCategory.LEGENDARY_TITLE
	]

func _force_rare_reward() -> Dictionary:
	# Replace with a random rare+ reward
	var rare_pool_local = GachaData.create_rare_pool()
	var entry = rare_pool_local.weights[randi() % rare_pool_local.weights.size()]
	return _create_reward_from_entry(entry)

func _force_limited_reward() -> Dictionary:
	# Replace with a random limited reward
	var limited_pool_local = GachaData.create_limited_pool()
	# Only limited skin or legendary title
	var limited_entries = limited_pool_local.weights.filter(
		func(e): return e["category"] in [
			GachaData.RewardCategory.LIMITED_SKIN, 
			GachaData.RewardCategory.LEGENDARY_TITLE
		]
	)
	if limited_entries.size() > 0:
		var entry = limited_entries[randi() % limited_entries.size()]
		return _create_reward_from_entry(entry)
	# Fallback
	return _create_reward_from_entry(limited_pool_local.weights[0])

func _add_to_history(gacha_type: GachaData.GachaType, reward: Dictionary) -> void:
	var history_entry = {
		"gacha_type": gacha_type,
		"reward_id": reward["reward_id"],
		"category": reward["category"],
		"timestamp": Time.get_unix_time_from_system()
	}
	
	pull_history.push_front(history_entry)
	if pull_history.size() > MAX_HISTORY:
		pull_history.pop_back()

# Coupon methods
func has_free_coupon(gacha_type: GachaData.GachaType) -> bool:
	match gacha_type:
		GachaData.GachaType.NORMAL:
			return free_coupons_normal > 0
		GachaData.GachaType.RARE:
			return free_coupons_rare > 0
		GachaData.GachaType.LIMITED:
			return free_coupons_limited > 0
	return false

func get_free_coupon_count(gacha_type: GachaData.GachaType) -> int:
	match gacha_type:
		GachaData.GachaType.NORMAL:
			return free_coupons_normal
		GachaData.GachaType.RARE:
			return free_coupons_rare
		GachaData.GachaType.LIMITED:
			return free_coupons_limited
	return 0

func _use_free_coupon(gacha_type: GachaData.GachaType) -> void:
	match gacha_type:
		GachaData.GachaType.NORMAL:
			free_coupons_normal = max(0, free_coupons_normal - 1)
		GachaData.GachaType.RARE:
			free_coupons_rare = max(0, free_coupons_rare - 1)
		GachaData.GachaType.LIMITED:
			free_coupons_limited = max(0, free_coupons_limited - 1)
	free_coupon_updated.emit(gacha_type, get_free_coupon_count(gacha_type))

# Pool helpers
func _get_pool(gacha_type: GachaData.GachaType) -> GachaData.GachaPool:
	match gacha_type:
		GachaData.GachaType.NORMAL:
			return normal_pool
		GachaData.GachaType.RARE:
			return rare_pool
		GachaData.GachaType.LIMITED:
			return limited_pool
	return normal_pool

# Pity info
func get_normal_pity_progress() -> int:
	return normal_pity_counter % GachaData.get_normal_pity_limit()

func get_limited_pity_progress() -> int:
	return limited_pity_counter % GachaData.get_limited_pity_limit()

func get_pity_remaining(gacha_type: GachaData.GachaType) -> int:
	match gacha_type:
		GachaData.GachaType.NORMAL:
			return GachaData.get_normal_pity_limit() - normal_pity_counter
		GachaData.GachaType.LIMITED:
			return GachaData.get_limited_pity_limit() - limited_pity_counter
	return 0

# Inventory getters
func get_gold_count() -> int:
	return owned_rewards.get(GachaData.RewardCategory.GOLD, 0)

func get_skill_fragment_count() -> int:
	return owned_rewards.get(GachaData.RewardCategory.SKILL_FRAGMENT, 0)

func get_exp_count() -> int:
	return owned_rewards.get(GachaData.RewardCategory.EXP, 0)

func get_owned_skins() -> Array:
	return owned_skins.duplicate()

func get_owned_titles() -> Array:
	return owned_titles.duplicate()

func get_owned_skills() -> Array:
	return owned_skills.duplicate()

func get_pull_history() -> Array:
	return pull_history.duplicate()

# Utility
func _get_current_date() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [datetime["year"], datetime["month"], datetime["day"]]

func get_pool_info(gacha_type: GachaData.GachaType) -> Dictionary:
	var pool = _get_pool(gacha_type)
	return {
		"type": gacha_type,
		"name": pool.display_name,
		"description": pool.description,
		"single_cost": pool.single_cost,
		"multi_cost": pool.multi_cost,
		"free_coupons": get_free_coupon_count(gacha_type),
		"pity_progress": get_pity_progress(gacha_type),
		"pity_limit": get_pity_limit(gacha_type)
	}

func get_pity_progress(gacha_type: GachaData.GachaType) -> int:
	match gacha_type:
		GachaData.GachaType.NORMAL:
			return get_normal_pity_progress()
		GachaData.GachaType.RARE:
			return 0  # No pity for rare pool
		GachaData.GachaType.LIMITED:
			return get_limited_pity_progress()
	return 0

func get_pity_limit(gacha_type: GachaData.GachaType) -> int:
	match gacha_type:
		GachaData.GachaType.NORMAL:
			return GachaData.get_normal_pity_limit()
		GachaData.GachaType.RARE:
			return 0
		GachaData.GachaType.LIMITED:
			return GachaData.get_limited_pity_limit()
	return 0