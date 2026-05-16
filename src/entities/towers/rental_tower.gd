extends Tower

## Rental Tower - Temporary tower rented from friends
## Inherits from Tower base class, properties modified by friend bonuses

class_name RentalTower

@export var friend_type: FriendData.FriendType = FriendData.FriendType.NEIGHBOR_MOM
@export var rental_duration: float = 180.0  # 3 minutes rental duration
@export var is_rental_active: bool = false

var rental_timer: float = 0.0
var original_stats: Dictionary = {}

signal rental_expired(tower: RentalTower)

func _ready() -> void:
	super._ready()
	# Set tower name based on friend type
	var friend = FriendData.get_friend_by_type(friend_type)
	tower_name = friend.friend_name + "的塔楼"
	description = friend.description
	
	# Mark as rental tower
	add_to_group("rental_towers")

func _process(delta: float) -> void:
	super._process(delta)
	
	if is_rental_active:
		rental_timer -= delta
		if rental_timer <= 0:
			_execute_rental_expired()

func initialize_rental(friend_t: FriendData.FriendType, bonus_stats: Dictionary) -> void:
	friend_type = friend_t
	var friend = FriendData.get_friend_by_type(friend_t)
	
	# Apply friend bonus stats
	damage = bonus_stats.get("damage", friend.base_damage)
	range = bonus_stats.get("range", friend.base_range)
	attack_speed = bonus_stats.get("attack_speed", friend.base_attack_speed)
	health = bonus_stats.get("health", friend.base_health)
	max_health = health
	
	# Store original stats for reference
	original_stats = bonus_stats
	
	# Set tower name
	tower_name = friend.friend_name + "的塔楼"
	
	# Start rental timer
	rental_timer = rental_duration
	is_rental_active = true
	
	# Update range area
	update_range_area()

func start_rental() -> void:
	is_rental_active = true
	rental_timer = rental_duration
	is_active = true

func _execute_rental_expired() -> void:
	is_rental_active = false
	rental_expired.emit(self)
	
	# End rental in friend system
	if FriendSystem:
		FriendSystem.end_current_rental()
	
	# Expire and remove
	queue_free()

func get_remaining_time() -> float:
	return max(0.0, rental_timer)

func get_remaining_time_formatted() -> String:
	var remaining = get_remaining_time()
	var minutes = int(remaining) / 60
	var seconds = int(remaining) % 60
	return "%02d:%02d" % [minutes, seconds]

# Override upgrade to have rental-specific behavior
func upgrade() -> void:
	# Limited upgrades for rental towers (1 level only)
	if tower_level >= 2:
		return
	
	tower_level += 1
	max_health += 25
	health = max_health
	damage += 3
	attack_speed += 0.1
	tower_upgraded.emit(self, tower_level)

# Rental towers cannot be sold
func sell() -> int:
	return 0

func get_sell_value() -> int:
	return 0

# Apply skill effects
func _on_tower_attack(enemy: Node, damage: float) -> Dictionary:
	if SkillSystem:
		return SkillSystem.apply_skill_effects(self, enemy, damage)
	return {"final_damage": damage}

# Get friend type for UI display
func get_friend_name() -> String:
	var friend = FriendData.get_friend_by_type(friend_type)
	return friend.friend_name

func get_friend_avatar() -> Texture2D:
	var friend = FriendData.get_friend_by_type(friend_type)
	return friend.avatar_texture

func get_affinity_bonus_percentage() -> float:
	var friend = FriendData.get_friend_by_type(friend_type)
	var current_affinity = 20
	if FriendSystem:
		current_affinity = FriendSystem.get_affinity(friend_type)
	return friend.bonus_percentage * (float(current_affinity) / 100.0)