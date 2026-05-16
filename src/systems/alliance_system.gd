extends Node

## Alliance System - Manages tower proximity and alliance zones
## Towers within 200px form an alliance and gain bonus effects

const ALLIANCE_RANGE: float = 200.0

signal alliance_formed(towers: Array)
signal alliance_broken(towers: Array)

var all_towers: Array = []
var alliance_zones: Array = []  # Array of arrays containing tower references

func _ready() -> void:
	# Timer to check alliances periodically
	var timer = Timer.new()
	timer.name = "AllianceTimer"
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(_check_alliances)
	add_child(timer)

func register_tower(tower: Node) -> void:
	if not all_towers.has(tower):
		all_towers.append(tower)
		tower.tree_exiting.connect(_on_tower_exiting.bind(tower))

func _on_tower_exiting(tower: Node) -> void:
	all_towers.erase(tower)

func _check_alliances() -> void:
	# Build alliance graph based on proximity
	var new_zones = _build_alliance_zones()
	
	# Check for changes
	if _zones_changed(new_zones):
		alliance_zones = new_zones
		_notify_alliance_changes(new_zones)

func _build_alliance_zones() -> Array:
	var zones: Array = []
	var processed: Array = []
	
	for tower in all_towers:
		if processed.has(tower):
			continue
		
		# BFS to find connected towers
		var zone: Array = []
		var queue: Array = [tower]
		
		while not queue.is_empty():
			var current = queue.pop_front()
			if processed.has(current):
				continue
			processed.append(current)
			zone.append(current)
			
			# Find all towers within alliance range
			for other in all_towers:
				if processed.has(other):
					continue
				if current.global_position.distance_to(other.global_position) <= ALLIANCE_RANGE:
					queue.append(other)
		
		if not zone.is_empty():
			zones.append(zone)
	
	return zones

func _zones_changed(new_zones: Array) -> bool:
	if new_zones.size() != alliance_zones.size():
		return true
	
	for i in range(new_zones.size()):
		if new_zones[i].size() != alliance_zones[i].size():
			return true
		for t in new_zones[i]:
			if not alliance_zones[i].has(t):
				return true
	return false

func _notify_alliance_changes(zones: Array) -> void:
	for zone in zones:
		alliance_formed.emit(zone)

func get_towers_in_range(tower: Node) -> Array:
	var result: Array = []
	for other in all_towers:
		if other != tower and is_instance_valid(other):
			if tower.global_position.distance_to(other.global_position) <= ALLIANCE_RANGE:
				result.append(other)
	return result

func get_alliance_zone(tower: Node) -> Array:
	for zone in alliance_zones:
		if zone.has(tower):
			return zone
	return []

func get_alliance_bonus(tower: Node) -> float:
	var zone = get_alliance_zone(tower)
	if zone.is_empty():
		return 0.0
	# +5% base stats per allied tower in range
	return (zone.size() - 1) * 0.05

func has_tower_type(zone: Array, type_name: String) -> bool:
	for t in zone:
		if t.tower_name == type_name:
			return true
	return false

func count_tower_types(zone: Array) -> Dictionary:
	var counts = {}
	for t in zone:
		var name = t.tower_name
		counts[name] = counts.get(name, 0) + 1
	return counts