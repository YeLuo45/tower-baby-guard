extends Node

## Combat System - manages combat between towers and enemies
## Handles damage calculation, targeting priorities, and combat events

var registered_towers: Array[Tower] = []
var active_enemies: Array[Enemy] = []

signal enemy_killed(enemy: Enemy, reward: int)
signal combat_log(message: String)

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_cleanup_invalid_targets()

func register_tower(tower: Tower) -> void:
	if not registered_towers.has(tower):
		registered_towers.append(tower)
		combat_log.emit("Tower registered: %s" % tower.tower_name)

func unregister_tower(tower: Tower) -> void:
	registered_towers.erase(tower)

func register_enemy(enemy: Enemy) -> void:
	if not active_enemies.has(enemy):
		active_enemies.append(enemy)
		enemy.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(enemy: Enemy, reward: int) -> void:
	active_enemies.erase(enemy)
	GameState.gold += reward
	enemy_killed.emit(enemy, reward)
	combat_log.emit("Enemy killed! +%d gold" % reward)

func _cleanup_invalid_targets() -> void:
	# Remove invalid entries from lists
	registered_towers = registered_towers.filter(func(t): return is_instance_valid(t))
	active_enemies = active_enemies.filter(func(e): return is_instance_valid(e))

func get_nearest_enemy_to(pos: Vector2) -> Enemy:
	var nearest: Enemy = null
	var nearest_dist: float = INF
	
	for enemy in active_enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var dist = pos.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist
	
	return nearest

func get_enemies_in_range(pos: Vector2, range: float) -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	
	for enemy in active_enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var dist = pos.distance_to(enemy.global_position)
		if dist <= range:
			enemies.append(enemy)
	
	return enemies

func calculate_damage(tower: Tower, target: Enemy) -> float:
	# Apply any damage modifiers here
	var base_damage = tower.damage
	return base_damage

func apply_tower_effect(tower: Tower, target: Enemy) -> void:
	# Apply special tower effects
	match tower.tower_name:
		"Dad":
			target.apply_slow(0.5, 2.0)
		"Grandma":
			target.apply_stun(1.5)
		"Chef":
			# AoE is handled in chef_tower.gd directly
			pass
