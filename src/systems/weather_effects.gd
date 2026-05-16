extends Node
## Applies weather modifiers to towers and enemies
## Reads signals from weather_manager and applies gameplay effects
class_name WeatherEffects

# Weather modifier configurations
# Each weather type affects towers/enemies differently
var _weather_modifiers: Dictionary = {
	# WeatherType enums mapped to modifier effects
	0: {  # CLEAR
		"tower_damage_mult": 1.0,
		"tower_range_mult": 1.0,
		"tower_speed_mult": 1.0,
		"enemy_speed_mult": 1.0,
		"enemy_health_mult": 1.0,
		"enemy_accuracy_mult": 1.0,
		"spawn_rate_mult": 1.0,
		"gold_bonus": 0.0
	},
	1: {  # RAIN
		"tower_damage_mult": 0.9,
		"tower_range_mult": 1.1,
		"tower_speed_mult": 0.85,
		"enemy_speed_mult": 1.15,
		"enemy_health_mult": 1.0,
		"enemy_accuracy_mult": 0.8,
		"spawn_rate_mult": 1.2,
		"gold_bonus": 0.1
	},
	2: {  # SNOW
		"tower_damage_mult": 1.1,
		"tower_range_mult": 0.95,
		"tower_speed_mult": 1.2,
		"enemy_speed_mult": 0.6,
		"enemy_health_mult": 0.9,
		"enemy_accuracy_mult": 1.0,
		"spawn_rate_mult": 0.8,
		"gold_bonus": 0.15
	},
	3: {  # SUNNY
		"tower_damage_mult": 1.15,
		"tower_range_mult": 1.0,
		"tower_speed_mult": 1.1,
		"enemy_speed_mult": 1.1,
		"enemy_health_mult": 1.1,
		"enemy_accuracy_mult": 1.1,
		"spawn_rate_mult": 1.0,
		"gold_bonus": 0.05
	},
	4: {  # WINDY (Leaves)
		"tower_damage_mult": 0.95,
		"tower_range_mult": 1.15,
		"tower_speed_mult": 0.9,
		"enemy_speed_mult": 1.25,
		"enemy_health_mult": 0.95,
		"enemy_accuracy_mult": 0.7,
		"spawn_rate_mult": 1.3,
		"gold_bonus": 0.0
	},
	5: {  # NIGHT (Fireflies)
		"tower_damage_mult": 1.05,
		"tower_range_mult": 0.9,
		"tower_speed_mult": 1.0,
		"enemy_speed_mult": 0.8,
		"enemy_health_mult": 1.15,
		"enemy_accuracy_mult": 1.2,
		"spawn_rate_mult": 0.9,
		"gold_bonus": 0.2
	}
}

# Current state
var _current_weather: int = 0
var _weather_intensity: float = 1.0
var _active_modifiers: Dictionary = {}
var _affected_towers: Array[Node] = []
var _affected_enemies: Array[Node] = []

# Buff/Debuff tracking
var _active_buffs: Dictionary = {}
var _buff_timers: Dictionary = {}

# Signal connections
var _weather_manager: Node = null
var _is_connected: bool = false

# Broadcast signals for other systems
signal weather_effect_applied(effect_type: String, value: float)
signal tower_modifier_changed(tower: Node, damage_mult: float, range_mult: float, speed_mult: float)
signal enemy_modifier_changed(enemy: Node, speed_mult: float, health_mult: float, accuracy_mult: float)
signal gold_bonus_applied(bonus: float)
signal weather_buff_started(buff_type: String, duration: float)
signal weather_buff_ended(buff_type: String)

func _ready() -> void:
	_connect_weather_manager()
	_apply_modifiers_for_weather(_current_weather)

## Connect to weather manager if it exists
func _connect_weather_manager() -> void:
	_weather_manager = get_node_or_null("/root/weather_manager")
	if _weather_manager == null:
		_weather_manager = get_node_or_null("/root/WeatherManager")
	
	if _weather_manager != null:
		if _weather_manager.has_signal("weather_changed"):
			_weather_manager.weather_changed.connect(_on_weather_changed)
			_is_connected = true
		if _weather_manager.has_signal("weather_intensity_changed"):
			_weather_manager.weather_intensity_changed.connect(_on_weather_intensity_changed)
		if _weather_manager.has_signal("weather_buff_triggered"):
			_weather_manager.weather_buff_triggered.connect(_on_weather_buff_triggered)
	else:
		# Poll for weather manager periodically if not found
		call_deferred("_poll_for_weather_manager")

func _poll_for_weather_manager() -> void:
	await get_tree().create_timer(2.0).timeout
	_connect_weather_manager()

## Handle weather change from weather_manager
func _on_weather_changed(new_weather: int) -> void:
	var old_weather: int = _current_weather
	_current_weather = new_weather
	
	# Remove old weather effects
	_remove_weather_effects(old_weather)
	
	# Apply new weather effects
	_apply_modifiers_for_weather(new_weather)
	
	# Broadcast changes
	_broadcast_tower_changes()
	_broadcast_enemy_changes()

## Handle weather intensity change
func _on_weather_intensity_changed(intensity: float) -> void:
	_weather_intensity = clamp(intensity, 0.0, 2.0)
	_apply_modifiers_for_weather(_current_weather)

## Handle weather buff triggered
func _on_weather_buff_triggered(buff_type: String, duration: float) -> void:
	_start_weather_buff(buff_type, duration)

## Apply modifiers for a specific weather type
func _apply_modifiers_for_weather(weather: int) -> void:
	if not _weather_modifiers.has(weather):
		return
	
	var base_mods: Dictionary = _weather_modifiers[weather]
	
	# Apply intensity scaling
	for key: String in base_mods:
		_active_modifiers[key] = base_mods[key] * _weather_intensity
	
	# Apply special weather effects
	match weather:
		1:  # RAIN
			_apply_rain_effects()
		2:  # SNOW
			_apply_snow_effects()
		3:  # SUNNY
			_apply_sunny_effects()
		4:  # WINDY
			_apply_windy_effects()
		5:  # NIGHT
			_apply_night_effects()
		0:  # CLEAR
			_apply_clear_effects()

## Apply rain-specific effects
func _apply_rain_effects() -> void:
	# Rain creates slippery conditions
	# Towers have reduced accuracy, enemies move faster
	weather_effect_applied.emit("rain_slippery", 0.15)
	
	# Add fire risk reduction (enemies take less fire damage)
	weather_effect_applied.emit("fire_resistance", 0.3)

## Apply snow-specific effects
func _apply_snow_effects() -> void:
	# Snow slows everything but improves tower aiming (steadier)
	weather_effect_applied.emit("snow_slow", 0.4)
	weather_effect_applied.emit("aim_steady", 0.2)

## Apply sunny-specific effects
func _apply_sunny_effects() -> void:
	# Sun energizes everything - bonus to all stats
	weather_effect_applied.emit("solar_energy", 0.1)

## Apply windy-specific effects
func _apply_windy_effects() -> void:
	# Wind blows projectiles off course, enemies become erratic
	weather_effect_applied.emit("wind_drift", 0.25)
	weather_effect_applied.emit("erratic_movement", 0.3)

## Apply night-specific effects
func _apply_night_effects() -> void:
	# Reduced visibility, but enemies have less awareness
	weather_effect_applied.emit("night_vision", -0.2)
	weather_effect_applied.emit("enemy_blind", 0.15)

## Apply clear weather effects
func _apply_clear_effects() -> void:
	# All bonuses return to baseline
	weather_effect_applied.emit("clear_weather", 0.0)

## Remove weather effects from previous weather
func _remove_weather_effects(old_weather: int) -> void:
	# Clear any temporary buffs from old weather
	match old_weather:
		1:  # Rain
			_end_buff("rain_bonus")
		2:  # Snow
			_end_buff("snow_protection")
		3:  # Sunny
			_end_buff("solar_charge")
		4:  # Windy
			_end_buff("wind_shield")
		5:  # Night
			_end_buff("night_vision_boost")

## Get current modifier value
func get_modifier(key: String) -> float:
	return _active_modifiers.get(key, 1.0)

## Get all current modifiers
func get_all_modifiers() -> Dictionary:
	return _active_modifiers.duplicate()

## Get tower damage modifier
func get_tower_damage_mod() -> float:
	return _active_modifiers.get("tower_damage_mult", 1.0)

## Get tower range modifier
func get_tower_range_mod() -> float:
	return _active_modifiers.get("tower_range_mult", 1.0)

## Get tower attack speed modifier
func get_tower_speed_mod() -> float:
	return _active_modifiers.get("tower_speed_mult", 1.0)

## Get enemy speed modifier
func get_enemy_speed_mod() -> float:
	return _active_modifiers.get("enemy_speed_mult", 1.0)

## Get enemy health modifier
func get_enemy_health_mod() -> float:
	return _active_modifiers.get("enemy_health_mult", 1.0)

## Get enemy accuracy modifier
func get_enemy_accuracy_mod() -> float:
	return _active_modifiers.get("enemy_accuracy_mult", 1.0)

## Get spawn rate modifier
func get_spawn_rate_mod() -> float:
	return _active_modifiers.get("spawn_rate_mult", 1.0)

## Get gold bonus multiplier
func get_gold_bonus() -> float:
	return _active_modifiers.get("gold_bonus", 0.0)

## Register a tower for weather effect updates
func register_tower(tower: Node) -> void:
	if not _affected_towers.has(tower):
		_affected_towers.append(tower)
		_apply_weather_to_tower(tower)

## Unregister a tower
func unregister_tower(tower: Node) -> void:
	_affected_towers.erase(tower)

## Register an enemy for weather effect updates
func register_enemy(enemy: Node) -> void:
	if not _affected_enemies.has(enemy):
		_affected_enemies.append(enemy)
		_apply_weather_to_enemy(enemy)

## Unregister an enemy
func unregister_enemy(enemy: Node) -> void:
	_affected_enemies.erase(enemy)

## Apply current weather effects to a tower
func _apply_weather_to_tower(tower: Node) -> void:
	var damage_mod: float = get_tower_damage_mod()
	var range_mod: float = get_tower_range_mod()
	var speed_mod: float = get_tower_speed_mod()
	
	# Emit signal for tower to process
	tower_modifier_changed.emit(tower, damage_mod, range_mod, speed_mod)
	
	# Call methods if tower has them
	if tower.has_method("apply_weather_modifiers"):
		tower.apply_weather_modifiers(damage_mod, range_mod, speed_mod)
	elif tower.has_method("set_weather_damage_mod"):
		tower.set_weather_damage_mod(damage_mod)
	if tower.has_method("set_weather_range_mod"):
		tower.set_weather_range_mod(range_mod)
	if tower.has_method("set_weather_speed_mod"):
		tower.set_weather_speed_mod(speed_mod)

## Apply current weather effects to an enemy
func _apply_weather_to_enemy(enemy: Node) -> void:
	var speed_mod: float = get_enemy_speed_mod()
	var health_mod: float = get_enemy_health_mod()
	var accuracy_mod: float = get_enemy_accuracy_mod()
	
	# Emit signal for enemy to process
	enemy_modifier_changed.emit(enemy, speed_mod, health_mod, accuracy_mod)
	
	# Call methods if enemy has them
	if enemy.has_method("apply_weather_modifiers"):
		enemy.apply_weather_modifiers(speed_mod, health_mod, accuracy_mod)
	if enemy.has_method("set_weather_speed_mod"):
		enemy.set_weather_speed_mod(speed_mod)
	if enemy.has_method("set_weather_health_mod"):
		enemy.set_weather_health_mod(health_mod)
	if enemy.has_method("set_weather_accuracy_mod"):
		enemy.set_weather_accuracy_mod(accuracy_mod)

## Broadcast tower changes to all registered towers
func _broadcast_tower_changes() -> void:
	for tower: Node in _affected_towers:
		if is_instance_valid(tower):
			_apply_weather_to_tower(tower)

## Broadcast enemy changes to all registered enemies
func _broadcast_enemy_changes() -> void:
	for enemy: Node in _affected_enemies:
		if is_instance_valid(enemy):
			_apply_weather_to_enemy(enemy)

## Start a timed weather buff
func _start_weather_buff(buff_type: String, duration: float) -> void:
	if _active_buffs.has(buff_type):
		# Refresh existing buff
		_buff_timers[buff_type] = duration
	else:
		_active_buffs[buff_type] = true
		_buff_timers[buff_type] = duration
		weather_buff_started.emit(buff_type, duration)
		_apply_buff_effects(buff_type, true)
	
	# Start timer if not already running
	if not has_node("BuffTimer"):
		var timer: Timer = Timer.new()
		timer.name = "BuffTimer"
		timer.wait_time = 1.0
		timer.timeout.connect(_on_buff_timer_tick)
		add_child(timer)
		timer.start()

## End a weather buff
func _end_buff(buff_type: String) -> void:
	if _active_buffs.has(buff_type):
		_active_buffs.erase(buff_type)
		_buff_timers.erase(buff_type)
		_apply_buff_effects(buff_type, false)
		weather_buff_ended.emit(buff_type)

## Apply or remove buff effects
func _apply_buff_effects(buff_type: String, active: bool) -> void:
	match buff_type:
		"rain_bonus":
			# Rain bonus: extra gold during rain
			if active:
				gold_bonus_applied.emit(0.1)
		"snow_protection":
			# Snow protection: reduced enemy damage
			if active:
				weather_effect_applied.emit("protection", 0.2)
		"solar_charge":
			# Solar charge: towers deal extra damage
			if active:
				weather_effect_applied.emit("damage_boost", 0.15)
		"wind_shield":
			# Wind shield: reduces projectile hit chance
			if active:
				weather_effect_applied.emit("evasion", 0.25)
		"night_vision_boost":
			# Night vision boost: better accuracy at night
			if active:
				weather_effect_applied.emit("accuracy_boost", 0.2)

## Process buff timers
func _on_buff_timer_tick() -> void:
	var to_remove: Array[String] = []
	
	for buff_type: String in _buff_timers:
		_buff_timers[buff_type] -= 1.0
		if _buff_timers[buff_type] <= 0:
			to_remove.append(buff_type)
	
	for buff_type: String in to_remove:
		_end_buff(buff_type)
	
	# Stop timer if no more buffs
	if _active_buffs.is_empty():
		get_node("BuffTimer").stop()

## Calculate effective damage with weather modifiers
func calculate_damage(base_damage: float) -> float:
	return base_damage * get_tower_damage_mod()

## Calculate effective range with weather modifiers
func calculate_range(base_range: float) -> float:
	return base_range * get_tower_range_mod()

## Calculate effective attack speed with weather modifiers
func calculate_attack_speed(base_speed: float) -> float:
	return base_speed * get_tower_speed_mod()

## Calculate effective enemy speed with weather modifiers
func calculate_enemy_speed(base_speed: float) -> float:
	return base_speed * get_enemy_speed_mod()

## Calculate effective enemy health with weather modifiers
func calculate_enemy_health(base_health: float) -> float:
	return base_health * get_enemy_health_mod()

## Calculate gold earned with weather bonus
func calculate_gold_earned(base_gold: float) -> float:
	return base_gold * (1.0 + get_gold_bonus())

## Set custom modifier for testing
func set_custom_modifier(key: String, value: float) -> void:
	_active_modifiers[key] = value
	_broadcast_tower_changes()
	_broadcast_enemy_changes()

## Reset to current weather's default modifiers
func reset_modifiers() -> void:
	_apply_modifiers_for_weather(_current_weather)
	_broadcast_tower_changes()
	_broadcast_enemy_changes()

## Get current weather type
func get_current_weather() -> int:
	return _current_weather

## Get weather intensity
func get_weather_intensity() -> float:
	return _weather_intensity

## Check if a specific buff is active
func is_buff_active(buff_type: String) -> bool:
	return _active_buffs.has(buff_type)

## Get all active buff types
func get_active_buffs() -> Array[String]:
	return Array[String](_active_buffs.keys())

## Force weather change (for testing or story events)
func force_weather(weather: int, intensity: float = 1.0) -> void:
	_weather_intensity = intensity
	_on_weather_changed(weather)

## Get a description of current weather effects
func get_weather_description() -> String:
	var desc: String = ""
	
	match _current_weather:
		0: desc = "Clear skies - normal conditions"
		1: desc = "Rainy - slippery conditions, faster enemies, reduced tower damage"
		2: desc = "Snowy - slowed movement, steadier towers"
		3: desc = "Sunny - energized units, bonus damage"
		4: desc = "Windy - erratic enemies, drifted projectiles"
		5: desc = "Nighttime - reduced visibility, but enemies are more vulnerable"
	
	if _weather_intensity != 1.0:
		desc += " (Intensity: %.1fx)" % _weather_intensity
	
	return desc