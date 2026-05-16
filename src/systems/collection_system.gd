extends Node

## CollectionSystem - Autoload singleton managing all 108 collection items
## Tracks unlock states, collection progress, and triggers rewards at 50%/75%/100%

signal collection_updated(category: String, unlocked: int, total: int)
signal item_unlocked(item_id: String, item_data: Dictionary)
signal milestone_reached(milestone: int)  # 50, 75, 100
signal rewards_claimed(milestone: int)

const SAVE_KEY = "collection_unlocked"
const MILESTONES = [50, 75, 100]  # Percentage milestones

var _unlocked_items: Dictionary = {}  # item_id -> unlock_timestamp
var _claimed_milestones: Array = []  # Already claimed milestones

func _ready() -> void:
	_load_collection()

## Load collection state from Persistence
func _load_collection() -> void:
	if Persistence.has_key(SAVE_KEY):
		var data = Persistence.get_value(SAVE_KEY, {})
		if data is Dictionary:
			_unlocked_items = data.get("items", {})
			_claimed_milestones = data.get("claimed_milestones", [])

## Save collection state to Persistence
func save_collection() -> void:
	Persistence.set_value(SAVE_KEY, {
		"items": _unlocked_items,
		"claimed_milestones": _claimed_milestones
	})
	Persistence.save_game()

## Check if item is unlocked
func is_unlocked(item_id: String) -> bool:
	return _unlocked_items.has(item_id)

## Unlock a collection item
func unlock_item(item_id: String, item_data: Dictionary) -> bool:
	if _unlocked_items.has(item_id):
		return false  # Already unlocked
	
	_unlocked_items[item_id] = _get_timestamp()
	item_unlocked.emit(item_id, item_data)
	collection_updated.emit(_get_category_name(item_data), get_unlocked_count(), get_total_count())
	
	# Check milestones
	_check_milestones()
	
	# Auto-save
	save_collection()
	return true

## Get all unlocked items
func get_unlocked_items() -> Array:
	return _unlocked_items.keys()

## Get collection progress
func get_unlocked_count() -> int:
	return _unlocked_items.size()

func get_total_count() -> int:
	return CollectionData.get_total_count()  # 108

func get_progress_percentage() -> float:
	var total = get_total_count()
	if total == 0:
		return 0.0
	return (float(_unlocked_items.size()) / float(total)) * 100.0

func get_progress_string() -> String:
	return "%d / %d (%.1f%%)" % [get_unlocked_count(), get_total_count(), get_progress_percentage()]

## Get count by item type
func get_unlocked_count_by_type(item_type: CollectionData.ItemType) -> int:
	var count = 0
	for item_id in _unlocked_items.keys():
		var item = CollectionData.get_item(item_id)
		if not item.is_empty() and item.get("type") == item_type:
			count += 1
	return count

func get_total_count_by_type(item_type: CollectionData.ItemType) -> int:
	return CollectionData.get_count_by_type(item_type)

## Check and trigger milestones
func _check_milestones() -> void:
	var percentage = get_progress_percentage()
	
	for milestone in MILESTONES:
		if percentage >= milestone and not _claimed_milestones.has(milestone):
			_claim_milestone(milestone)

func _claim_milestone(milestone: int) -> void:
	_claimed_milestones.append(milestone)
	milestone_reached.emit(milestone)
	
	# Trigger rewards through CollectionRewards
	CollectionRewards.claim_milestone_reward(milestone)
	
	# Auto-save
	save_collection()

## Check if milestone is claimed
func is_milestone_claimed(milestone: int) -> bool:
	return _claimed_milestones.has(milestone)

## Get next unclaimed milestone
func get_next_milestone() -> int:
	for milestone in MILESTONES:
		if not _claimed_milestones.has(milestone):
			return milestone
	return -1  # All claimed

## Get time formatted timestamp
func _get_timestamp() -> String:
	var dt = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d" % [dt["year"], dt["month"], dt["day"], dt["hour"], dt["minute"]]

func _get_category_name(item_data: Dictionary) -> String:
	match item_data.get("type"):
		CollectionData.ItemType.ENEMY:
			return "Enemies"
		CollectionData.ItemType.TOWER:
			return "Towers"
		CollectionData.ItemType.ACHIEVEMENT:
			return "Achievements"
		CollectionData.ItemType.SKILL:
			return "Skills"
	return "Unknown"

## === CONVENIENCE METHODS FOR GAME INTEGRATION ===

## Call when enemy is encountered for first time
func on_enemy_encountered(enemy_id: String) -> void:
	var item = CollectionData.get_item("enemy_" + enemy_id)
	if not item.is_empty() and not is_unlocked("enemy_" + enemy_id):
		unlock_item("enemy_" + enemy_id, item)

## Call when tower is placed/upgraded to new form
func on_tower_form_unlocked(tower_type: String, form_index: int) -> void:
	var item_id = "tower_%s_form_%d" % [tower_type, form_index]
	var item = CollectionData.get_item(item_id)
	if not item.is_empty() and not is_unlocked(item_id):
		unlock_item(item_id, item)

## Call when achievement is unlocked
func on_achievement_unlocked(achievement_id: String) -> void:
	var item = CollectionData.get_item(achievement_id)
	if not item.is_empty() and not is_unlocked(achievement_id):
		unlock_item(achievement_id, item)

## Call when skill is unlocked
func on_skill_unlocked(skill_id: String) -> void:
	var item = CollectionData.get_item(skill_id)
	if not item.is_empty() and not is_unlocked(skill_id):
		unlock_item(skill_id, item)

## Get collection data for UI display
func get_collection_for_ui(item_type: CollectionData.ItemType) -> Array:
	var items = CollectionData.get_items_by_type(item_type)
	var result = []
	
	for item in items:
		result.append({
			"id": item["id"],
			"name": item["name"],
			"desc": item["desc"],
			"icon": item["icon"],
			"unlocked": is_unlocked(item["id"]),
			"unlock_date": _unlocked_items.get(item["id"], ""),
		})
	
	return result

## Get gallery statistics
func get_gallery_stats() -> Dictionary:
	return {
		"total": get_total_count(),
		"unlocked": get_unlocked_count(),
		"percentage": get_progress_percentage(),
		"enemies_unlocked": get_unlocked_count_by_type(CollectionData.ItemType.ENEMY),
		"enemies_total": get_total_count_by_type(CollectionData.ItemType.ENEMY),
		"towers_unlocked": get_unlocked_count_by_type(CollectionData.ItemType.TOWER),
		"towers_total": get_total_count_by_type(CollectionData.ItemType.TOWER),
		"achievements_unlocked": get_unlocked_count_by_type(CollectionData.ItemType.ACHIEVEMENT),
		"achievements_total": get_total_count_by_type(CollectionData.ItemType.ACHIEVEMENT),
		"skills_unlocked": get_unlocked_count_by_type(CollectionData.ItemType.SKILL),
		"skills_total": get_total_count_by_type(CollectionData.ItemType.SKILL),
		"milestones_claimed": _claimed_milestones,
		"next_milestone": get_next_milestone(),
	}