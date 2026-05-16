extends Node

## Friend System - Autoload managing friend list, affinity, and rental cooldowns
## Handles friend interactions, affinity gain, and rental tower mechanics

const SAVE_SECTION = "friends"

# Friend data storage: friend_type -> Dictionary with affinity and rental data
var friend_data: Dictionary = {}

# Rental state
var rented_friend_type: FriendData.FriendType = null
var current_rental_tower: Node = null

# Daily interaction tracking
var daily_interactions: Dictionary = {}  # friend_type -> interaction count today
var last_interaction_date: String = ""

signal friend_unlocked(friend_type: FriendData.FriendType)
signal affinity_updated(friend_type: FriendData.FriendType, new_affinity: int)
signal rental_started(friend_type: FriendData.FriendType, tower: Node)
signal rental_ended(friend_type: FriendData.FriendType)
signal cooldown_ready(friend_type: FriendData.FriendType)

func _ready() -> void:
	_initialize_friends()
	_load_friend_data()
	
	# Check for daily reset
	var today = _get_current_date()
	if last_interaction_date != today:
		_reset_daily_interactions()
		last_interaction_date = today

func _initialize_friends() -> void:
	# Initialize all friends with default data
	for friend_type in FriendData.FriendType.values():
		if not friend_data.has(friend_type):
			friend_data[friend_type] = {
				"affinity": 20,  # Starting affinity
				"unlocked": friend_type == FriendData.FriendType.NEIGHBOR_MOM,  # First friend unlocked by default
				"last_rental_time": 0.0,
				"total_rentals": 0
			}

func _reset_daily_interactions() -> void:
	daily_interactions.clear()

# Persistence integration
func _load_friend_data() -> void:
	if not PersistenceSystem:
		return
	
	var config = ConfigFile.new()
	var err = config.load(PersistenceSystem.SAVE_FILE_PATH)
	
	if err != OK:
		return
	
	# Load friend data from persistence
	var section_keys = config.get_section_keys(SAVE_SECTION)
	for friend_type_str in section_keys:
		var friend_type = int(friend_type_str)
		var data_dict = config.get_value(SAVE_SECTION, friend_type_str)
		if friend_data.has(friend_type):
			friend_data[friend_type] = data_dict

func save_friend_data() -> void:
	if not PersistenceSystem:
		return
	
	var config = ConfigFile.new()
	var err = config.load(PersistenceSystem.SAVE_FILE_PATH)
	
	if err != OK:
		return
	
	# Save friend data to persistence
	for friend_type in friend_data.keys():
		config.set_value(SAVE_SECTION, str(friend_type), friend_data[friend_type])
	
	config.save(PersistenceSystem.SAVE_FILE_PATH)

# Friend access
func get_friend_data(friend_type: FriendData.FriendType) -> Dictionary:
	return friend_data.get(friend_type, {})

func is_friend_unlocked(friend_type: FriendData.FriendType) -> bool:
	var data = get_friend_data(friend_type)
	return data.get("unlocked", false)

func get_affinity(friend_type: FriendData.FriendType) -> int:
	var data = get_friend_data(friend_type)
	return data.get("affinity", 20)

func set_affinity(friend_type: FriendData.FriendType, value: int) -> void:
	if not friend_data.has(friend_type):
		return
	
	var clamped_value = clamp(value, 0, 100)
	friend_data[friend_type]["affinity"] = clamped_value
	affinity_updated.emit(friend_type, clamped_value)
	save_friend_data()

func modify_affinity(friend_type: FriendData.FriendType, delta: int) -> void:
	var current = get_affinity(friend_type)
	set_affinity(friend_type, current + delta)

# Unlock friend
func unlock_friend(friend_type: FriendData.FriendType, cost: int) -> bool:
	if not friend_data.has(friend_type):
		return false
	
	if is_friend_unlocked(friend_type):
		return false
	
	# Check wave requirement
	var required_wave = FriendData.get_friend_by_type(friend_type).unlock_wave
	var current_wave = 1  # Default if no wave system
	
	if WaveManager:
		current_wave = WaveManager.current_wave
	
	if current_wave < required_wave:
		return false
	
	# Deduct cost and unlock
	friend_data[friend_type]["unlocked"] = true
	friend_data[friend_type]["affinity"] = 20  # Reset to default on unlock
	save_friend_data()
	friend_unlocked.emit(friend_type)
	return true

# Rental system
func get_rental_cooldown_remaining(friend_type: FriendData.FriendType) -> float:
	var last_rental = friend_data[friend_type].get("last_rental_time", 0.0)
	var elapsed = Time.get_unix_time_from_system() - last_rental
	var remaining = FriendData.RENTAL_COOLDOWN_SECONDS - elapsed
	return max(0.0, remaining)

func is_rental_ready(friend_type: FriendData.FriendType) -> bool:
	return get_rental_cooldown_remaining(friend_type) <= 0.0

func start_rental(friend_type: FriendData.FriendType, tower: Node) -> bool:
	if not is_friend_unlocked(friend_type):
		return false
	
	if not is_rental_ready(friend_type):
		return false
	
	# End any current rental
	if current_rental_tower and is_instance_valid(current_rental_tower):
		end_current_rental()
	
	rented_friend_type = friend_type
	current_rental_tower = tower
	friend_data[friend_type]["last_rental_time"] = Time.get_unix_time_from_system()
	friend_data[friend_type]["total_rentals"] += 1
	save_friend_data()
	rental_started.emit(friend_type, tower)
	return true

func end_current_rental() -> void:
	if rented_friend_type != null and is_instance_valid(current_rental_tower):
		var ft = rented_friend_type
		current_rental_tower.queue_free()
		current_rental_tower = null
		rented_friend_type = null
		rental_ended.emit(ft)
		# Start cooldown
		_check_cooldown_complete(ft)

func _check_cooldown_complete(friend_type: FriendData.FriendType) -> void:
	# This would be called when cooldown timer completes
	cooldown_ready.emit(friend_type)

# Daily interaction - increases affinity
func perform_daily_interaction(friend_type: FriendData.FriendType) -> int:
	if not is_friend_unlocked(friend_type):
		return 0
	
	var today = _get_current_date()
	if last_interaction_date != today:
		_reset_daily_interactions()
		last_interaction_date = today
	
	# Check daily cap
	var today_count = daily_interactions.get(friend_type, 0)
	var friend = FriendData.get_friend_by_type(friend_type)
	if today_count >= friend.daily_affinity_cap:
		return 0  # Already maxed for today
	
	# Increment and apply
	daily_interactions[friend_type] = today_count + 1
	modify_affinity(friend_type, friend.daily_affinity_gain)
	
	return friend.daily_affinity_gain

# Get rental tower stats with friend bonuses
func get_rental_tower_stats(friend_type: FriendData.FriendType) -> Dictionary:
	var friend = FriendData.get_friend_by_type(friend_type)
	var data = get_friend_data(friend_type)
	var affinity_mult = float(data.get("affinity", 20)) / 100.0
	
	var stats = {
		"damage": friend.base_damage * (1.0 + friend.bonus_percentage * affinity_mult),
		"range": friend.base_range * (1.0 + friend.bonus_percentage * affinity_mult),
		"attack_speed": friend.base_attack_speed * (1.0 + friend.bonus_percentage * affinity_mult),
		"health": friend.base_health * (1.0 + friend.bonus_percentage * affinity_mult)
	}
	
	# Apply bonus type specific multiplier
	match friend.bonus_type:
		FriendData.BonusType.GOLD:
			stats["gold_bonus"] = friend.bonus_percentage * affinity_mult
		FriendData.BonusType.RANGE:
			stats["range"] *= 1.0 + friend.bonus_percentage * affinity_mult * 0.5
		FriendData.BonusType.ATTACK_SPEED:
			stats["attack_speed"] *= 1.0 + friend.bonus_percentage * affinity_mult * 0.3
		FriendData.BonusType.HEALTH:
			stats["health"] *= 1.0 + friend.bonus_percentage * affinity_mult * 0.5
		FriendData.BonusType.COMBO:
			stats["combo_chance"] = friend.bonus_percentage * affinity_mult
	
	return stats

# Check if any friend rental is active
func is_any_friend_rented() -> bool:
	return rented_friend_type != null and is_instance_valid(current_rental_tower)

func get_current_rented_friend() -> FriendData.FriendType:
	return rented_friend_type

# Utility
func _get_current_date() -> String:
	var datetime = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [datetime["year"], datetime["month"], datetime["day"]]

func format_cooldown_time(seconds: float) -> String:
	var hours = int(seconds) / 3600
	var minutes = (int(seconds) % 3600) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]

func get_all_unlocked_friends() -> Array[FriendData.FriendType]:
	var unlocked: Array[FriendData.FriendType] = []
	for friend_type in friend_data.keys():
		if is_friend_unlocked(friend_type):
			unlocked.append(friend_type)
	return unlocked