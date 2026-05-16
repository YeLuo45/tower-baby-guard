extends PathFollow2D

## Boss Enemy - 大块头宝宝
## 3 phases: normal → summoning → berserk

class_name BossEnemy

signal boss_damaged(damage: float, current_hp: float)
signal boss_phase_changed(new_phase: int)
signal boss_died()

@export var boss_name: String = "大块头宝宝"
@export var max_health: float = 2000.0
@export var base_speed: float = 30.0
@export var attack_interval: float = 3.0
@export var attack_damage: float = 50.0

var health: float = 2000.0
var phase: int = 1
var is_alive: bool = true
var _phase_timers: Array[float] = [0.0, 0.0, 0.0]
var _attack_timer: float = 0.0
var _gold_drop_timer: float = 0.0
var _is_berserk: bool = false

const PHASE_THRESHOLDS := [0.6, 0.3]  # 60%, 30%

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	add_to_group("boss")
	attack_interval = 3.0

func _process(delta: float) -> void:
	if not is_alive:
		return
	
	_progress_phase()
	_move(delta)
	_attack(delta)
	_berserk_gold_drop(delta)

func _move(delta: float) -> void:
	var speed := base_speed
	if _is_berserk:
		speed *= 1.5
	progress += speed * delta
	
	if progress_ratio >= 1.0:
		_reach_end()

func _progress_phase() -> void:
	var hp_ratio := health / max_health
	var new_phase := 1
	if hp_ratio <= PHASE_THRESHOLDS[1]:
		new_phase = 3
	elif hp_ratio <= PHASE_THRESHOLDS[0]:
		new_phase = 2
	
	if new_phase != phase:
		_set_phase(new_phase)

func _set_phase(p: int) -> void:
	phase = p
	boss_phase_changed.emit(phase)
	
	match phase:
		2:
			attack_interval = 2.0  # Faster attacks
			_summon_minions()
		3:
			_is_berserk = true
			attack_interval = 1.0

func _summon_minions() -> void:
	# Phase 2: spawn 2 small tantrum enemies
	if has_node("/root/Main/WaveManager"):
		var wm = get_node("/root/Main/WaveManager")
		for i in range(2):
			var enemy_scene = preload("res://src/entities/enemies/tantrum.tscn")
			var enemy = enemy_scene.instantiate()
			enemy.max_health *= 0.5
			enemy.health = enemy.max_health
			var pf = PathFollow2D.new()
			pf.loop = false
			pf.progress = max(0, progress - 100)
			if has_node("Path2D"):
				var path = get_node("Path2D")
				path.add_child(pf)
				pf.add_child(enemy)

func _attack(delta: float) -> void:
	_attack_timer += delta
	if _attack_timer >= attack_interval:
		_attack_timer = 0.0
		_do_boss_attack()

func _do_boss_attack() -> void:
	# BOSS attack damages a random tower or the base
	GameState.lives -= 1
	# Screen shake on boss attack is handled in wave_manager or game scene

func _berserk_gold_drop(delta: float) -> void:
	if not _is_berserk:
		return
	_gold_drop_timer += delta
	if _gold_drop_timer >= 1.0:
		_gold_drop_timer = 0.0
		GameState.gold += 10

func take_damage(amount: float) -> void:
	if not is_alive:
		return
	
	health -= amount
	boss_damaged.emit(amount, health)
	_show_damage_number(amount)
	
	if health <= 0:
		die()

func _show_damage_number(amount: float) -> void:
	var label = Label.new()
	label.text = "-%d" % int(amount)
	label.add_theme_font_size_override("font_size", 20)
	label.modulate = Color(1, 0.2, 0.2, 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var world_pos = get_global_position()
	label.position = world_pos + Vector2(0, -50)
	get_tree().root.add_child(label)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", world_pos + Vector2(0, -80), 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().on_finish(func(): label.queue_free())

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	boss_died.emit()
	GameState.gold += 100  # Bonus gold
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.05, 0.05), 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.chain().on_finish(func():
		queue_free()
	)

func _reach_end() -> void:
	is_alive = false
	GameState.lives = 0
	queue_free()