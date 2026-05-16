extends Resource
class_name FriendData

## Friend Data - Resource class defining NPC friends for rental system
## 5 friends: neighbor mom, kindergarten teacher, uncle, grandpa, sister

enum FriendType {
	NEIGHBOR_MOM,    # +Gold bonus
	KINDERGARTEN_TEACHER,  # +Range bonus
	UNCLE,           # +Attack speed bonus
	GRANDPA,         # +Health bonus
	SISTER           # +Combo bonus
}

@export var friend_type: FriendType = FriendType.NEIGHBOR_MOM
@export var friend_name: String = "Friend"
@export var description: String = ""
@export var avatar_texture: Texture2D = null

# Base stats for rental tower
@export var base_damage: float = 15.0
@export var base_range: float = 120.0
@export var base_attack_speed: float = 1.0
@export var base_health: float = 100.0

# Affinity (好感度) system: 0-100
@export var affinity: int = 20  # Starting affinity
@export var max_affinity: int = 100

# Affinity bonuses scale with affinity level
# At 100 affinity: full bonus. At 0: no bonus.
func get_affinity_multiplier() -> float:
	return float(affinity) / float(max_affinity)

# Bonus type this friend provides
enum BonusType { GOLD, RANGE, ATTACK_SPEED, HEALTH, COMBO }

@export var bonus_type: BonusType = BonusType.GOLD
@export var bonus_percentage: float = 0.15  # 15% bonus at max affinity

func get_bonus_value(base_value: float) -> float:
	return base_value * bonus_percentage * get_affinity_multiplier()

# Daily interaction rewards affinity
@export var daily_affinity_gain: int = 5
@export var daily_affinity_cap: int = 10  # Max gain per day

# Unlock requirements
@export var unlock_wave: int = 5  # Wave required to unlock
@export var unlock_cost: int = 500  # Gold cost to unlock

# Rental cooldown in seconds (24 hours = 86400 seconds)
const RENTAL_COOLDOWN_SECONDS: int = 86400

# Create default friend instances
static func create_neighbor_mom() -> FriendData:
	var friend = FriendData.new()
	friend.friend_type = FriendType.NEIGHBOR_MOM
	friend.friend_name = "邻居妈妈"
	friend.description = "慈祥的邻居妈妈，总是带着点心来帮忙"
	friend.bonus_type = BonusType.GOLD
	friend.bonus_percentage = 0.20
	friend.base_damage = 12.0
	friend.base_range = 100.0
	friend.base_attack_speed = 0.8
	friend.base_health = 120.0
	friend.unlock_wave = 3
	friend.unlock_cost = 300
	return friend

static func create_kindergarten_teacher() -> FriendData:
	var friend = FriendData.new()
	friend.friend_type = FriendType.KINDERGARTEN_TEACHER
	friend.friend_name = "幼儿园老师"
	friend.description = "耐心的老师，善于组织小朋友们"
	friend.bonus_type = BonusType.RANGE
	friend.bonus_percentage = 0.25
	friend.base_damage = 10.0
	friend.base_range = 180.0
	friend.base_attack_speed = 0.7
	friend.base_health = 80.0
	friend.unlock_wave = 5
	friend.unlock_cost = 500
	return friend

static func create_uncle() -> FriendData:
	var friend = FriendData.new()
	friend.friend_type = FriendType.UNCLE
	friend.friend_name = "叔叔"
	friend.description = "酷酷的叔叔，玩游戏的专家"
	friend.bonus_type = BonusType.ATTACK_SPEED
	friend.bonus_percentage = 0.30
	friend.base_damage = 18.0
	friend.base_range = 110.0
	friend.base_attack_speed = 1.5
	friend.base_health = 90.0
	friend.unlock_wave = 8
	friend.unlock_cost = 800
	return friend

static func create_grandpa() -> FriendData:
	var friend = FriendData.new()
	friend.friend_type = FriendType.GRANDPA
	friend.friend_name = "爷爷"
	friend.description = "慈祥的爷爷，有着丰富的人生经验"
	friend.bonus_type = BonusType.HEALTH
	friend.bonus_percentage = 0.35
	friend.base_damage = 8.0
	friend.base_range = 100.0
	friend.base_attack_speed = 0.5
	friend.base_health = 200.0
	friend.unlock_wave = 10
	friend.unlock_cost = 1000
	return friend

static func create_sister() -> FriendData:
	var friend = FriendData.new()
	friend.friend_type = FriendType.SISTER
	friend.friend_name = "姐姐"
	friend.description = "活泼的姐姐，总是有新奇的点子"
	friend.bonus_type = BonusType.COMBO
	friend.bonus_percentage = 0.20
	friend.base_damage = 14.0
	friend.base_range = 130.0
	friend.base_attack_speed = 1.0
	friend.base_health = 100.0
	friend.unlock_wave = 12
	friend.unlock_cost = 1200
	return friend

static func get_all_friends() -> Array[FriendData]:
	return [
		create_neighbor_mom(),
		create_kindergarten_teacher(),
		create_uncle(),
		create_grandpa(),
		create_sister()
	]

static func get_friend_by_type(type: FriendType) -> FriendData:
	match type:
		FriendType.NEIGHBOR_MOM:
			return create_neighbor_mom()
		FriendType.KINDERGARTEN_TEACHER:
			return create_kindergarten_teacher()
		FriendType.UNCLE:
			return create_uncle()
		FriendType.GRANDPA:
			return create_grandpa()
		FriendType.SISTER:
			return create_sister()
	return create_neighbor_mom()