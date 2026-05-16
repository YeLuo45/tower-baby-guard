extends Node
## Gift box reward system - spawns and manages gift boxes with random rewards.
class_name GiftBoxSystem

# Gift box configuration
const GIFT_BOX_SCENE: String = "res://src/scenes/gift_box.tscn"
const MIN_SPAWN_INTERVAL: float = 30.0
const MAX_SPAWN_INTERVAL: float = 90.0
const BASE_DURATION: float = 15.0
const RARE_DURATION: float = 10.0
const LEGENDARY_DURATION: float = 8.0

# Reward tiers
enum RewardTier { COMMON, RARE, EPIC, LEGENDARY }

# Active gift boxes
var _active_boxes: Array[Node] = []
var _spawn_timer: float = 0.0
var _next_spawn_time: float = 0.0
var _is_spawning_enabled: bool = true

# Reward tables by tier
var _reward_tables: Dictionary = {
	RewardTier.COMMON: [
		{ "type": "gold", "amount": 50, "weight": 40 },
		{ "type": "gold", "amount": 100, "weight": 30 },
		{ "type": "health", "amount": 10, "weight": 20 },
		{ "type": "shield", "amount": 1, "weight": 10 }
	],
	RewardTier.RARE: [
		{ "type": "gold", "amount": 200, "weight": 30 },
		{ "type": "gold", "amount": 300, "weight": 20 },
		{ "type": "health", "amount": 25, "weight": 20 },
		{ "type": "shield", "amount": 2, "weight": 15 },
		{ "type": "speed_boost", "duration": 5, "weight": 15 }
	],
	RewardTier.EPIC: [
		{ "type": "gold", "amount": 500, "weight": 25 },
		{ "type": "gold", "amount": 750, "weight": 15 },
		{ "type": "shield", "amount": 3, "weight": 20 },
		{ "type": "damage_boost", "duration": 8, "weight": 20 },
		{ "type": "tower_freeze", "duration": 10, "weight": 20 }
	],
	RewardTier.LEGENDARY: [
		{ "type": "gold", "amount": 1000, "weight": 20 },
		{ "type": "gold", "amount": 1500, "weight": 15 },
		{ "type": "ultimate_shield", "duration": 15, "weight": 20 },
		{ "type": "combo_multiplier", "multiplier": 2, "duration": 10, "weight": 25 },
		{ "type": "boss_damage", "amount": 500, "weight": 20 }
	]
}

# Tier spawn weights
const TIER_WEIGHTS := {
	RewardTier.COMMON: 60,
	RewardTier.RARE: 25,
	RewardTier.EPIC: 12,
	RewardTier.LEGENDARY: 3
}

signal gift_box_spawned(box: Node, tier: int)
signal gift_box_collected(box: Node, reward: Dictionary)
signal gift_box_expired(box: Node)
signal all_boxes_collected()

func _ready() -> void:
	_reset_spawn_timer()

func _process(delta: float) -> void:
	if not _is_spawning_enabled:
		return
	
	_spawn_timer += delta
	if _spawn_timer >= _next_spawn_time:
		_spawn_random_gift_box()
		_reset_spawn_timer()

func _reset_spawn_timer() -> void:
	_spawn_timer = 0.0
	_next_spawn_time = randf_range(MIN_SPAWN_INTERVAL, MAX_SPAWN_INTERVAL)

## Spawn a gift box at a specific position
func spawn_gift_box(global_position: Vector2, tier: RewardTier = RewardTier.COMMON) -> Node:
	var box := _create_box_instance(tier)
	if not box:
		push_warning("[GiftBoxSystem] Failed to create gift box instance")
		return null
	
	box.global_position = global_position
	_set_box_duration(box, tier)
	_active_boxes.append(box)
	gift_box_spawned.emit(box, tier)
	
	# Connect signals
	if box.has_signal("collected"):
		box.connect("collected", _on_box_collected.bind(box))
	if box.has_signal("expired"):
		box.connect("expired", _on_box_expired.bind(box))
	
	# Add to scene tree if we have a valid tree
	if get_tree() and get_tree().root:
		get_tree().root.add_child(box)
	
	return box

## Spawn a random tier gift box
func _spawn_random_gift_box() -> Node:
	var tier := _roll_tier()
	var spawn_pos := _get_spawn_position()
	return spawn_gift_box(spawn_pos, tier)

## Roll for random tier based on weights
func _roll_tier() -> RewardTier:
	var roll := randf() * 100.0
	var cumulative := 0.0
	
	for tier in TIER_WEIGHTS:
		cumulative += TIER_WEIGHTS[tier]
		if roll <= cumulative:
			return tier as RewardTier
	
	return RewardTier.COMMON

## Create box instance from scene or generate inline
func _create_box_instance(tier: RewardTier) -> Node:
	var scene_path := GIFT_BOX_SCENE
	if ResourceLoader.exists(scene_path):
		var packed_scene := load(scene_path) as PackedScene
		if packed_scene:
			return packed_scene.instantiate()
	
	# Fallback: create a simple Area2D-based box
	var box := Area2D.new()
	box.set_script(load("res://src/systems/gift_box_system.gd").get_script())
	
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	box.add_child(collision)
	
	var sprite := Sprite2D.new()
	sprite.modulate = _get_tier_color(tier)
	box.add_child(sprite)
	
	return box

## Get tier color for visual identification
func _get_tier_color(tier: RewardTier) -> Color:
	match tier:
		RewardTier.COMMON:
			return Color.WHITE
		RewardTier.RARE:
			return Color.BLUE
		RewardTier.EPIC:
			return Color.PURPLE
		RewardTier.LEGENDARY:
			return Color.ORANGE
	return Color.WHITE

## Set box duration based on tier
func _set_box_duration(box: Node, tier: RewardTier) -> void:
	var duration := BASE_DURATION
	match tier:
		RewardTier.RARE:
			duration = RARE_DURATION
		RewardTier.LEGENDARY:
			duration = LEGENDARY_DURATION
		RewardTier.EPIC:
			duration = (RARE_DURATION + LEGENDARY_DURATION) / 2.0
	
	# Store duration for timer-based expiry
	if box.has_method("set_duration"):
		box.set_duration(duration)

## Get random spawn position within play area
func _get_spawn_position() -> Vector2:
	var viewport := get_viewport_rect()
	var margin: float = 100.0
	return Vector2(
		randf_range(margin, viewport.size.x - margin),
		randf_range(margin, viewport.size.y - margin)
	)

## Handle box collection
func _on_box_collected(box: Node, reward: Dictionary) -> void:
	if box in _active_boxes:
		_active_boxes.erase(box)
	gift_box_collected.emit(box, reward)
	
	if _active_boxes.size() == 0:
		all_boxes_collected.emit()

## Handle box expiry
func _on_box_expired(box: Node) -> void:
	if box in _active_boxes:
		_active_boxes.erase(box)
	gift_box_expired.emit(box)
	
	if _active_boxes.size() == 0:
		all_boxes_collected.emit()

## Roll for a random reward from a tier
func roll_reward(tier: RewardTier) -> Dictionary:
	var table: Array = _reward_tables.get(tier, [])
	if table.is_empty():
		return { "type": "none" }
	
	var total_weight := 0.0
	for entry in table:
		total_weight += entry.get("weight", 1.0)
	
	var roll := randf() * total_weight
	var cumulative := 0.0
	
	for entry in table:
		cumulative += entry.get("weight", 1.0)
		if roll <= cumulative:
			return entry.duplicate(true)
	
	return table[0].duplicate(true)

## Get reward display name
func get_reward_display_name(reward: Dictionary) -> String:
	match reward.get("type", ""):
		"gold":
			return "Gold x%d" % reward.get("amount", 0)
		"health":
			return "Health Pack x%d" % reward.get("amount", 0)
		"shield":
			return "Shield (%d stacks)" % reward.get("amount", 0)
		"speed_boost":
			return "Speed Boost (%ds)" % reward.get("duration", 0)
		"damage_boost":
			return "Damage Boost (%ds)" % reward.get("duration", 0)
		"tower_freeze":
			return "Tower Freeze (%ds)" % reward.get("duration", 0)
		"ultimate_shield":
			return "Ultimate Shield (%ds)" % reward.get("duration", 0)
		"combo_multiplier":
			return "2x Combo (%ds)" % reward.get("duration", 0)
		"boss_damage":
			return "Boss Damage x%d" % reward.get("amount", 0)
	return "Unknown Reward"

## Spawn a guaranteed legendary box (for special events)
func spawn_legendary_box(position: Vector2) -> Node:
	return spawn_gift_box(position, RewardTier.LEGENDARY)

## Spawn a guaranteed epic box
func spawn_epic_box(position: Vector2) -> Node:
	return spawn_gift_box(position, RewardTier.EPIC)

## Clear all active boxes
func clear_all_boxes() -> void:
	for box in _active_boxes:
		if is_instance_valid(box):
			box.queue_free()
	_active_boxes.clear()

## Enable/disable spawning
func set_spawning_enabled(enabled: bool) -> void:
	_is_spawning_enabled = enabled
	if enabled:
		_reset_spawn_timer()

## Get current active box count
func get_active_box_count() -> int:
	return _active_boxes.size()

## Get all active boxes
func get_active_boxes() -> Array[Node]:
	return _active_boxes.duplicate()

## Apply reward to game state (connect to your game manager)
func apply_reward(reward: Dictionary) -> bool:
	match reward.get("type", ""):
		"gold":
			_add_gold(reward.get("amount", 0))
			return true
		"health":
			_restore_health(reward.get("amount", 0))
			return true
		"shield":
			_add_shield(reward.get("amount", 0))
			return true
		"speed_boost":
			_apply_speed_boost(reward.get("duration", 0))
			return true
		"damage_boost":
			_apply_damage_boost(reward.get("duration", 0))
			return true
		"tower_freeze":
			_apply_tower_freeze(reward.get("duration", 0))
			return true
		"ultimate_shield":
			_apply_ultimate_shield(reward.get("duration", 0))
			return true
		"combo_multiplier":
			_apply_combo_multiplier(reward.get("multiplier", 1), reward.get("duration", 0))
			return true
		"boss_damage":
			_apply_boss_damage(reward.get("amount", 0))
			return true
	return false

# Override these methods to integrate with your game systems
func _add_gold(amount: int) -> void:
	pass

func _restore_health(amount: int) -> void:
	pass

func _add_shield(stacks: int) -> void:
	pass

func _apply_speed_boost(duration: float) -> void:
	pass

func _apply_damage_boost(duration: float) -> void:
	pass

func _apply_tower_freeze(duration: float) -> void:
	pass

func _apply_ultimate_shield(duration: float) -> void:
	pass

func _apply_combo_multiplier(multiplier: int, duration: float) -> void:
	pass

func _apply_boss_damage(amount: int) -> void:
	pass