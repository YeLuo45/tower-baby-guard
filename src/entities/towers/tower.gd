extends Node2D

## Base Tower class - all towers inherit from this
## Handles targeting, attacking, and tower mechanics

class_name Tower

@export var tower_name: String = "Tower"
@export var cost: int = 100
@export var range: float = 150.0
@export var damage: float = 10.0
@export var attack_speed: float = 1.0  # attacks per second

var health: float = 100.0
var max_health: float = 100.0
var is_active: bool = true
var current_target: Node2D = null

var attack_cooldown: float = 0.0
var tower_level: int = 1

@onready var range_area: Area2D = $RangeArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

# Upgrade system properties
var upgrade_paths: Array = [false, false, false]  # 3 paths, true if purchased
var total_invested: int = 0  # Base cost + all upgrade costs (for sell value)

signal tower_placed(tower: Tower)
signal tower_upgraded(tower: Tower, new_level: int)
signal tower_sold(tower: Tower, refund: int)
signal target_acquired(target: Node2D)
signal upgrade_applied(path_index: int)

func _ready() -> void:
	range_area.body_entered.connect(_on_body_entered)
	range_area.body_exited.connect(_on_body_exited)
	health_bar.max_value = max_health
	health_bar.value = health
	
	# Initialize total_invested with base cost
	total_invested = cost

func update_range_area() -> void:
	# Override in subclasses if range area needs updating
	pass

func _process(delta: float) -> void:
	if not is_active:
		return
	
	attack_cooldown -= delta
	if attack_cooldown <= 0:
		_find_target()
		if current_target and is_instance_valid(current_target):
			_attack(current_target)
			attack_cooldown = 1.0 / attack_speed

func _find_target() -> void:
	var enemies_in_range = range_area.get_overlapping_bodies()
	if enemies_in_range.is_empty():
		current_target = null
		return
	
	# Simple targeting - closest enemy
	var closest: Node2D = null
	var closest_dist: float = INF
	for enemy in enemies_in_range:
		if enemy.is_in_group("enemies") and enemy.is_alive:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest = enemy
				closest_dist = dist
	
	current_target = closest
	if current_target:
		target_acquired.emit(current_target)

func _attack(target: Node2D) -> void:
	# Override in subclasses for specific attack behavior
	pass

## Tower attack callback - applies skill effects
func _on_tower_attack(enemy: Node, damage: float) -> Dictionary:
	if SkillSystem:
		return SkillSystem.apply_skill_effects(self, enemy, damage)
	return {"final_damage": damage}

func take_damage(amount: float) -> void:
	health -= amount
	health_bar.value = health
	if health <= 0:
		_destroy()

func heal(amount: float) -> void:
	health = min(health + amount, max_health)
	health_bar.value = health

func upgrade() -> void:
	tower_level += 1
	max_health += 50
	health = max_health
	damage += 5
	attack_speed += 0.2
	tower_upgraded.emit(self, tower_level)

func get_upgrade_cost() -> int:
	return int(cost * tower_level * 0.75)

func get_sell_value() -> int:
	return int(total_invested * 0.5)

func sell() -> int:
	var refund = get_sell_value()
	tower_sold.emit(self, refund)
	queue_free()
	return refund

func _destroy() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	pass

func _on_body_exited(body: Node2D) -> void:
	pass
