extends PathFollow2D

## Base Enemy class - all enemies inherit from this
## Handles movement along path, health, and status effects

class_name Enemy

@export var enemy_name: String = "Enemy"
@export var max_health: float = 100.0
@export var speed: float = 80.0
@export var reward: int = 10

var health: float = 100.0
var is_alive: bool = true
var is_slowed: bool = false
var is_stunned: bool = false
var slow_factor: float = 1.0
var stun_timer: float = 0.0

var base_speed: float = 80.0

signal enemy_died(enemy: Enemy, reward: int)
signal enemy_reached_end(enemy: Enemy)
signal health_changed(current: float, maximum: float)

func _ready() -> void:
	health = max_health
	base_speed = speed
	add_to_group("enemies")

func _process(delta: float) -> void:
	if not is_alive:
		return
	
	# Handle stun
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
		return
	
	# Calculate effective speed
	var effective_speed = base_speed * slow_factor
	
	# Move along path
	progress += effective_speed * delta
	
	# Check if reached end
	if progress_ratio >= 1.0:
		_reach_end()

func take_damage(amount: float) -> void:
	if not is_alive:
		return
	
	health -= amount
	health_changed.emit(health, max_health)
	
	# Show floating damage number
	_show_damage_number(amount)
	
	if health <= 0:
		die()

func _show_damage_number(amount: float) -> void:
	var label = Label.new()
	label.text = "-%d" % int(amount)
	label.add_theme_font_size_override("font_size", 16)
	label.modulate = Color(1, 0.3, 0.3, 1)  # Red
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Position above enemy
	var world_pos = get_global_position()
	label.position = world_pos + Vector2(0, -40)
	
	# Add to scene root so it moves with world
	get_tree().root.add_child(label)
	
	# Animate: float up and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", world_pos + Vector2(0, -70), 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().on_finish(func(): label.queue_free())

func apply_slow(factor: float, duration: float) -> void:
	# Override in subclasses for immunity (e.g., ScreenTime enemy)
	slow_factor = factor
	is_slowed = true
	await get_tree().create_timer(duration).timeout
	if is_slowed:
		slow_factor = 1.0
		is_slowed = false

func apply_stun(duration: float) -> void:
	if is_stunned:
		return
	is_stunned = true
	stun_timer = duration

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	_show_gold_reward()
	_death_animation()

func _death_animation() -> void:
	# Scale down and fade out before queue_free
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.chain().on_finish(func():
		enemy_died.emit(self, reward)
		queue_free()
	)

func _show_gold_reward() -> void:
	var label = Label.new()
	label.text = "+%d" % reward
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = Color(1, 0.9, 0.2, 1)  # Gold color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var world_pos = get_global_position()
	label.position = world_pos + Vector2(0, -30)
	
	get_tree().root.add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", world_pos + Vector2(0, -60), 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.chain().on_finish(func(): label.queue_free())

func _reach_end() -> void:
	is_alive = false
	enemy_reached_end.emit(self)
	GameState.lives -= 1
	queue_free()

func get_health_percentage() -> float:
	return health / max_health if max_health > 0 else 0.0
