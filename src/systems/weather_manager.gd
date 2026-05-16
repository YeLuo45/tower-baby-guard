# WeatherManager.gd - Autoload singleton for tower-baby-guard V8 weather system
# Manages dynamic weather states with fade transitions and game mechanics integration
extends Node

# Weather types enum
enum WeatherType {
	SUNNY,
	RAINY,
	WINDY,
	NIGHT,
	BLIZZARD
}

# Current weather state
var _current_weather: WeatherType = WeatherType.SUNNY
var _target_weather: WeatherType = WeatherType.SUNNY
var _is_transitioning := false

# Timer and duration
var _weather_timer := 0.0
var _weather_duration := 60.0
var _weather_intensity := 1.0

# Transition state
var _transition_timer := 0.0
var _transition_duration := 5.0
var _transition_progress := 0.0

# Color interpolation
var _current_sky_color := Color.WHITE
var _current_ambient_color := Color.WHITE
var _target_sky_color := Color.WHITE
var _target_ambient_color := Color.WHITE

# Weather data configuration
const WEATHER_DATA := {
	WeatherType.SUNNY: {
		"colors": {
			"sky": Color(0.53, 0.81, 0.98),      # Light blue
			"ambient": Color(1.0, 0.98, 0.90),   # Warm white
			"fog": Color(0.90, 0.95, 1.0),
			"overlay": Color(1.0, 0.95, 0.85)    # Sunny tint
		},
		"mechanics": {
			"enemy_speed_mult": 1.2,              # 20% faster enemies
			"gold_bonus": 1.1,                   # 10% more gold
			"tower_attack_mult": 1.0,             # No change
			"enemy_health_mult": 1.0,            # No change
			"spawn_rate_mult": 1.3,              # 30% more spawns
			"experience_bonus": 1.0
		},
		"particles": {
			"type": "dust",
			"emission_rate": 5,
			"speed": 2.0,
			"lifetime": 3.0,
			"spread": 0.3,
			"gravity": -0.1
		},
		"audio": "sunny",
		"light_energy": 1.2
	},
	WeatherType.RAINY: {
		"colors": {
			"sky": Color(0.25, 0.35, 0.50),      # Dark grey-blue
			"ambient": Color(0.50, 0.55, 0.60),  # Cool grey
			"fog": Color(0.40, 0.45, 0.55),
			"overlay": Color(0.60, 0.70, 0.85)   # Rainy tint
		},
		"mechanics": {
			"enemy_speed_mult": 0.7,             # 30% slower
			"gold_bonus": 1.5,                   # 50% more gold
			"tower_attack_mult": 1.3,             # 30% faster attack
			"enemy_health_mult": 1.0,
			"spawn_rate_mult": 0.8,              # 20% fewer spawns
			"experience_bonus": 1.2
		},
		"particles": {
			"type": "rain",
			"emission_rate": 100,
			"speed": 15.0,
			"lifetime": 1.0,
			"spread": 0.1,
			"gravity": 20.0
		},
		"audio": "rain",
		"light_energy": 0.5
	},
	WeatherType.WINDY: {
		"colors": {
			"sky": Color(0.60, 0.75, 0.90),      # Light grey-blue
			"ambient": Color(0.85, 0.88, 0.92), # Cool light
			"fog": Color(0.75, 0.80, 0.88),
			"overlay": Color(0.80, 0.88, 0.95)  # Windy tint
		},
		"mechanics": {
			"enemy_speed_mult": 1.4,             # 40% faster
			"gold_bonus": 1.2,                   # 20% more gold
			"tower_attack_mult": 0.8,             # 20% slower attack
			"enemy_health_mult": 0.85,           # 15% less health
			"spawn_rate_mult": 1.2,              # 20% more spawns
			"experience_bonus": 1.1
		},
		"particles": {
			"type": "leaves",
			"emission_rate": 30,
			"speed": 8.0,
			"lifetime": 4.0,
			"spread": 0.8,
			"gravity": 0.5
		},
		"audio": "wind",
		"light_energy": 0.9
	},
	WeatherType.NIGHT: {
		"colors": {
			"sky": Color(0.05, 0.08, 0.18),      # Deep blue-black
			"ambient": Color(0.20, 0.22, 0.30), # Dark blue
			"fog": Color(0.08, 0.10, 0.20),
			"overlay": Color(0.10, 0.12, 0.25)   # Night tint
		},
		"mechanics": {
			"enemy_speed_mult": 0.9,             # 10% slower
			"gold_bonus": 2.0,                   # 100% more gold
			"tower_attack_mult": 1.5,             # 50% faster attack
			"enemy_health_mult": 1.2,            # 20% more health
			"spawn_rate_mult": 0.6,              # 40% fewer spawns
			"experience_bonus": 1.5
		},
		"particles": {
			"type": "stars",
			"emission_rate": 20,
			"speed": 0.0,
			"lifetime": 10.0,
			"spread": 1.0,
			"gravity": 0.0
		},
		"audio": "night",
		"light_energy": 0.3
	},
	WeatherType.BLIZZARD: {
		"colors": {
			"sky": Color(0.85, 0.88, 0.95),      # White-grey
			"ambient": Color(0.90, 0.92, 0.95), # Cold white
			"fog": Color(0.95, 0.95, 1.0),
			"overlay": Color(0.95, 0.97, 1.0)   # Blizzard tint
		},
		"mechanics": {
			"enemy_speed_mult": 0.4,             # 60% slower
			"gold_bonus": 2.5,                   # 150% more gold
			"tower_attack_mult": 0.5,             # 50% slower attack
			"enemy_health_mult": 1.5,            # 50% more health
			"spawn_rate_mult": 0.4,              # 60% fewer spawns
			"experience_bonus": 2.0
		},
		"particles": {
			"type": "snow",
			"emission_rate": 200,
			"speed": 5.0,
			"lifetime": 5.0,
			"spread": 0.5,
			"gravity": -2.0
		},
		"audio": "blizzard",
		"light_energy": 0.6
	}
}

# Particle system references
var _particle_systems := {}

func _ready() -> void:
	_setup_particle_systems()
	_initialize_weather(WeatherType.SUNNY)

func _setup_particle_systems() -> void:
	# Create GPUParticles2D or CPUParticles2D for each weather type
	# These would be attached to a world environment or overlay node
	pass

func _initialize_weather(type: WeatherType) -> void:
	_current_weather = type
	_target_weather = type
	var data := WEATHER_DATA[type]
	_current_sky_color = data["colors"]["sky"]
	_current_ambient_color = data["colors"]["ambient"]
	_target_sky_color = _current_sky_color
	_target_ambient_color = _current_ambient_color

# Main weather setter
func set_weather(type: WeatherType, duration: float, intensity: float = 1.0) -> void:
	if type == _current_weather and not _is_transitioning:
		# Refresh current weather duration
		_weather_duration = duration
		_weather_intensity = intensity
		_weather_timer = 0.0
		return
	
	_target_weather = type
	_weather_duration = duration
	_weather_intensity = clamp(intensity, 0.1, 2.0)
	_weather_timer = 0.0
	
	_start_transition()

func _start_transition() -> void:
	if _is_transitioning:
		return
	
	_is_transitioning = true
	_transition_timer = 0.0
	_transition_progress = 0.0
	
	# Set target colors
	var target_data := WEATHER_DATA[_target_weather]
	_target_sky_color = target_data["colors"]["sky"]
	_target_ambient_color = target_data["colors"]["ambient"]
	
	# Emit signal for UI/systems to react
	emit_signal("weather_transition_started", _current_weather, _target_weather)

func _process(delta: float) -> void:
	# Handle transition fade
	if _is_transitioning:
		_update_transition(delta)
	
	# Handle weather timer
	_weather_timer += delta
	if _weather_timer >= _weather_duration and not _is_transitioning:
		_weather_timer = 0.0
		_determine_next_weather()

func _update_transition(delta: float) -> void:
	_transition_timer += delta
	_transition_progress = clamp(_transition_timer / _transition_duration, 0.0, 1.0)
	
	# Ease out cubic for smooth transition
	var eased_progress := 1.0 - pow(1.0 - _transition_progress, 3.0)
	
	# Interpolate colors
	_current_sky_color = _current_sky_color.lerp(_target_sky_color, eased_progress)
	_current_ambient_color = _current_ambient_color.lerp(_target_ambient_color, eased_progress)
	
	# Update environment (if WorldEnvironment exists)
	_apply_weather_colors()
	
	if _transition_progress >= 1.0:
		_complete_transition()

func _complete_transition() -> void:
	_is_transitioning = false
	_current_weather = _target_weather
	_current_sky_color = _target_sky_color
	_current_ambient_color = _target_ambient_color
	
	# Emit transition complete signal
	emit_signal("weather_transition_completed", _current_weather)

func _apply_weather_colors() -> void:
	# Update WorldEnvironment if it exists
	var env := get_node_or_null("/root/Main/WorldEnvironment")
	if env and env.has_method("set_weather_colors"):
		env.set_weather_colors(_current_sky_color, _current_ambient_color)

func _determine_next_weather() -> void:
	# 50% chance to keep current weather, 50% chance to switch
	if randf() < 0.5:
		# Keep current weather, just reset timer
		return
	
	# Pick a random different weather
	var all_types := WeatherType.values()
	all_types.erase(_current_weather)
	var next_type := all_types[randi() % all_types.size()]
	
	set_weather(next_type, _weather_duration, _weather_intensity)

# Public getters
func get_current_weather() -> WeatherType:
	return _current_weather

func get_weather_mechanics() -> Dictionary:
	return WEATHER_DATA[_current_weather]["mechanics"].duplicate(true)

func get_mechanic(modifier: String) -> float:
	var mechanics := WEATHER_DATA[_current_weather]["mechanics"]
	return mechanics.get(modifier, 1.0)

func get_weather_intensity() -> float:
	return _weather_intensity

func is_transitioning() -> bool:
	return _is_transitioning

func get_transition_progress() -> float:
	return _transition_progress

func get_weather_colors() -> Dictionary:
	return {
		"sky": _current_sky_color,
		"ambient": _current_ambient_color,
		"overlay": WEATHER_DATA[_current_weather]["colors"]["overlay"],
		"fog": WEATHER_DATA[_current_weather]["colors"]["fog"]
	}

func get_particle_config() -> Dictionary:
	return WEATHER_DATA[_current_weather]["particles"].duplicate(true)

# Utility functions
func get_weather_name(type: WeatherType) -> String:
	match type:
		WeatherType.SUNNY: return "Sunny"
		WeatherType.RAINY: return "Rainy"
		WeatherType.WINDY: return "Windy"
		WeatherType.NIGHT: return "Night"
		WeatherType.BLIZZARD: return "Blizzard"
	return "Unknown"

func get_weather_type_from_name(name: String) -> WeatherType:
	match name.to_lower():
		"sunny": return WeatherType.SUNNY
		"rainy": return WeatherType.RAINY
		"windy": return WeatherType.WINDY
		"night": return WeatherType.NIGHT
		"blizzard": return WeatherType.BLIZZARD
	return WeatherType.SUNNY

# Signals
signal weather_transition_started(from_weather: WeatherType, to_weather: WeatherType)
signal weather_transition_completed(new_weather: WeatherType)
signal weather_mechanics_changed(mechanics: Dictionary)