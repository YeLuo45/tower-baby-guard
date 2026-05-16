extends Node2D
## Particle weather system that spawns and renders weather particles
## Supports: rain, snow, sun rays, leaves, fireflies
class_name ParticleWeather

# Weather types
enum WeatherType {
	CLEAR = 0,
	RAIN = 1,
	SNOW = 2,
	SUNNY = 3,
	WINDY = 4,    # Leaves
	NIGHT = 5     # Fireflies
}

# Particle data structure
class WeatherParticle:
	var position: Vector2
	var velocity: Vector2
	var lifetime: float
	var age: float
	var size: float
	var color: Color
	var rotation: float
	var rotation_speed: float
	var type: WeatherType

# Configuration
@export var max_particles: int = 500
@export var spawn_rate: float = 30.0  # particles per second
@export var base_wind: Vector2 = Vector2.ZERO

# Weather settings by type
var _weather_configs: Dictionary = {
	WeatherType.CLEAR: {
		"spawn_rate": 0.0,
		"particle_speed": 0.0,
		"particle_size": 0.0,
		"particle_color": Color.WHITE,
		"wind": Vector2.ZERO,
		"lifetime": 5.0
	},
	WeatherType.RAIN: {
		"spawn_rate": 80.0,
		"particle_speed": 800.0,
		"particle_size": 2.0,
		"particle_color": Color(0.7, 0.85, 1.0, 0.6),
		"wind": Vector2(-50, 200),
		"lifetime": 2.0,
		"size_variance": 1.0
	},
	WeatherType.SNOW: {
		"spawn_rate": 40.0,
		"particle_speed": 60.0,
		"particle_size": 4.0,
		"particle_color": Color(1.0, 1.0, 1.0, 0.8),
		"wind": Vector2(20, 30),
		"lifetime": 8.0,
		"size_variance": 3.0
	},
	WeatherType.SUNNY: {
		"spawn_rate": 15.0,
		"particle_speed": 30.0,
		"particle_size": 6.0,
		"particle_color": Color(1.0, 0.95, 0.8, 0.3),
		"wind": Vector2(10, 5),
		"lifetime": 6.0,
		"size_variance": 2.0
	},
	WeatherType.WINDY: {
		"spawn_rate": 25.0,
		"particle_speed": 150.0,
		"particle_size": 5.0,
		"particle_color": Color(0.6, 0.4, 0.2, 0.7),
		"wind": Vector2(200, 50),
		"lifetime": 4.0,
		"size_variance": 2.5
	},
	WeatherType.NIGHT: {
		"spawn_rate": 20.0,
		"particle_speed": 20.0,
		"particle_size": 3.0,
		"particle_color": Color(0.9, 1.0, 0.6, 0.9),
		"wind": Vector2(5, 10),
		"lifetime": 10.0,
		"size_variance": 1.5
	}
}

# State
var _particles: Array[WeatherParticle] = []
var _current_weather: WeatherType = WeatherType.CLEAR
var _spawn_timer: float = 0.0
var _is_active: bool = false
var _screen_size: Vector2 = Vector2(1920, 1080)

# References
var _weather_manager_path: NodePath

signal weather_changed(new_weather: int)
signal particle_spawned(particle: Dictionary)
signal particle_count_updated(count: int)

func _ready() -> void:
	_setup_screen_size()
	_connect_weather_manager()

func _setup_screen_size() -> void:
	if has_node("/root/MainGame") or has_node("/root/World"):
		var world: Node = get_node_or_null("/root/MainGame") if has_node("/root/MainGame") else get_node("/root/World")
		if world and world.has_method("get_viewport_size"):
			_screen_size = world.get_viewport_size()

func _connect_weather_manager() -> void:
	# Try to connect to weather_manager if it exists
	if has_node("/root/weather_manager"):
		var weather_manager: Node = get_node("/root/weather_manager")
		if weather_manager.has_signal("weather_changed"):
			weather_manager.weather_changed.connect(_on_weather_manager_changed)
		if weather_manager.has_signal("weather_intensity_changed"):
			weather_manager.weather_intensity_changed.connect(_on_weather_intensity_changed)
	elif has_node("/root/WeatherManager"):
		var weather_manager: Node = get_node("/root/WeatherManager")
		if weather_manager.has_signal("weather_changed"):
			weather_manager.weather_changed.connect(_on_weather_manager_changed)

func _process(delta: float) -> void:
	if not _is_active:
		return
	
	_spawn_particles(delta)
	_update_particles(delta)
	queue_redraw()
	
	if _particles.size() != int(particle_count_updated.get_connections().size()):
		particle_count_updated.emit(_particles.size())

## Spawn particles based on current weather
func _spawn_particles(delta: float) -> void:
	var config: Dictionary = _weather_configs.get(_current_weather, _weather_configs[WeatherType.CLEAR])
	var rate: float = config.get("spawn_rate", 0.0)
	
	if rate <= 0:
		return
	
	_spawn_timer += delta * rate
	
	while _spawn_timer >= 1.0 and _particles.size() < max_particles:
		_spawn_single_particle(config)
		_spawn_timer -= 1.0

## Spawn a single weather particle
func _spawn_single_particle(config: Dictionary) -> void:
	var particle := WeatherParticle.new()
	
	# Random spawn position along top and sides
	var spawn_edge := randi() % 4
	match spawn_edge:
		0:  # Top
			particle.position = Vector2(randf() * _screen_size.x, -20)
		1:  # Right
			particle.position = Vector2(_screen_size.x + 20, randf() * _screen_size.y)
		2:  # Bottom
			particle.position = Vector2(randf() * _screen_size.x, _screen_size.y + 20)
		3:  # Left
			particle.position = Vector2(-20, randf() * _screen_size.y)
	
	# Calculate velocity based on weather type
	var base_speed: float = config.get("particle_speed", 100.0)
	var wind: Vector2 = config.get("wind", Vector2.ZERO) + base_wind
	particle.velocity = _get_weather_velocity(wind, base_speed)
	
	# Set particle properties
	particle.lifetime = config.get("lifetime", 5.0)
	particle.age = 0.0
	
	var size_base: float = config.get("particle_size", 3.0)
	var size_var: float = config.get("size_variance", 1.0)
	particle.size = size_base + randf() * size_var
	
	particle.color = config.get("particle_color", Color.WHITE)
	
	particle.rotation = randf() * TAU
	particle.rotation_speed = randf_range(-2.0, 2.0)
	particle.type = _current_weather
	
	_particles.append(particle)
	
	var emit_data := {
		"position": particle.position,
		"type": particle.type,
		"size": particle.size
	}
	particle_spawned.emit(emit_data)

## Get velocity based on weather type
func _get_weather_velocity(wind: Vector2, speed: float) -> Vector2:
	match _current_weather:
		WeatherType.RAIN:
			return Vector2(wind.x, speed + wind.y).normalized() * (speed + randf() * 200)
		WeatherType.SNOW:
			return wind.normalized() * speed + Vector2(randf_range(-20, 20), randf_range(10, 30))
		WeatherType.SUNNY:
			return Vector2(randf_range(-10, 10), randf_range(5, 15))
		WeatherType.WINDY:
			return wind.normalized() * (speed + randf() * 100)
		WeatherType.NIGHT:
			return Vector2(randf_range(-10, 10), randf_range(-5, 15))
		_:
			return Vector2.ZERO

## Update all particles
func _update_particles(delta: float) -> void:
	var to_remove: Array[int] = []
	
	for i: int in range(_particles.size()):
		var p: WeatherParticle = _particles[i]
		
		# Update age
		p.age += delta
		
		# Check lifetime
		if p.age >= p.lifetime:
			to_remove.append(i)
			continue
		
		# Update position based on type
		_update_particle_movement(p, delta)
		
		# Update rotation
		p.rotation += p.rotation_speed * delta
		
		# Remove if off screen
		if _is_off_screen(p.position):
			to_remove.append(i)
	
	# Remove dead particles in reverse order
	for i: int in range(to_remove.size() - 1, -1, -1):
		_particles.remove_at(to_remove[i])

## Update particle movement based on weather type
func _update_particle_movement(p: WeatherParticle, delta: float) -> void:
	var wind: Vector2 = _weather_configs.get(_current_weather, {}).get("wind", Vector2.ZERO) + base_wind
	
	match _current_weather:
		WeatherType.RAIN:
			# Rain falls straight with slight wind influence
			p.position += (Vector2(wind.x, 800) * delta)
		
		WeatherType.SNOW:
			# Snow drifts gently with gravity
			p.position += p.velocity * delta
			p.position.x += sin(p.age * 2.0) * 10.0 * delta  # Wobble
		
		WeatherType.SUNNY:
			# Sun rays filter down slowly
			p.position += Vector2(sin(p.age * 3.0) * 5.0, 20) * delta
		
		WeatherType.WINDY:
			# Leaves blow in wind direction with tumbling
			p.position += p.velocity * delta
			p.rotation += delta * 5.0
		
		WeatherType.NIGHT:
			# Fireflies drift with subtle pulsing
			p.position += p.velocity * delta
			p.position.x += sin(p.age * 4.0 + p.position.y * 0.01) * 2.0 * delta
		
		_:
			p.position += p.velocity * delta

## Check if position is off screen
func _is_off_screen(pos: Vector2) -> bool:
	var margin: float = 100.0
	return pos.x < -margin or pos.x > _screen_size.x + margin or \
		   pos.y < -margin or pos.y > _screen_size.y + margin

## Draw particles
func _draw() -> void:
	for p: WeatherParticle in _particles:
		var alpha: float = 1.0 - (p.age / p.lifetime)
		var draw_color := Color(p.color.r, p.color.g, p.color.b, p.color.a * alpha)
		
		match _current_weather:
			WeatherType.RAIN:
				# Draw rain as a line
				var rain_length: float = p.size * 4
				var end_pos: Vector2 = p.position + Vector2(-2, rain_length)
				draw_line(p.position, end_pos, draw_color, 1.0)
			
			WeatherType.SNOW:
				# Draw snow as a circle
				draw_circle(p.position, p.size, draw_color)
			
			WeatherType.SUNNY:
				# Draw sun ray as a glowing circle
				draw_circle(p.position, p.size, draw_color)
				# Add glow effect with larger, more transparent circle
				draw_circle(p.position, p.size * 2.0, Color(draw_color.r, draw_color.g, draw_color.b, draw_color.a * 0.3))
			
			WeatherType.WINDY:
				# Draw leaf as a small ellipse
				_draw_leaf(p.position, p.size, p.rotation, draw_color)
			
			WeatherType.NIGHT:
				# Draw firefly with pulsing glow
				var pulse: float = (sin(p.age * 5.0) + 1.0) * 0.5
				var glow_size: float = p.size * (1.0 + pulse * 0.5)
				draw_circle(p.position, glow_size, draw_color)
				draw_circle(p.position, glow_size * 1.5, Color(draw_color.r, draw_color.g, draw_color.b, draw_color.a * 0.4))
			
			_:
				draw_circle(p.position, p.size, draw_color)

## Draw a leaf shape
func _draw_leaf(pos: Vector2, size: float, rotation: float, color: Color) -> void:
	var points: Array[Vector2] = []
	var leaf_length: float = size * 2.0
	
	# Simple leaf shape
	for i: int in range(6):
		var t: float = float(i) / 5.0
		var x: float = cos(t * PI) * leaf_length * 0.5
		var y: float = sin(t * PI) * size
		points.append(Vector2(x, y))
	
	# Transform points
	var transform := Transform2D(rotation, pos)
	var transformed: Array[Vector2] = []
	for pt: Vector2 in points:
		transformed.append(transform * pt)
	
	# Draw as polygon
	if transformed.size() >= 3:
		draw_polygon(PackedVector2Array(transformed), color)

## Set the current weather type
func set_weather(type: WeatherType) -> void:
	if _current_weather == type:
		return
	
	_current_weather = type
	_is_active = type != WeatherType.CLEAR
	
	# Clear particles when weather changes to clear
	if not _is_active:
		_particles.clear()
	
	weather_changed.emit(type)

## Get current weather type
func get_weather() -> WeatherType:
	return _current_weather

## Set weather intensity (affects spawn rate and particle count)
func set_weather_intensity(intensity: float) -> void:
	intensity = clamp(intensity, 0.0, 2.0)
	
	# Modify spawn rate based on intensity
	for key: int in _weather_configs:
		var config: Dictionary = _weather_configs[key].duplicate()
		config["spawn_rate"] *= intensity
		_weather_configs[key] = config

## Start the weather system
func start() -> void:
	_is_active = true

## Stop the weather system
func stop() -> void:
	_is_active = false

## Clear all particles
func clear_particles() -> void:
	_particles.clear()

## Get particle count
func get_particle_count() -> int:
	return _particles.size()

## Set screen size for spawn bounds
func set_screen_size(size: Vector2) -> void:
	_screen_size = size

## Set base wind offset
func set_base_wind(wind: Vector2) -> void:
	base_wind = wind

## Handle weather manager signal
func _on_weather_manager_changed(new_weather: int) -> void:
	if new_weather >= 0 and new_weather < WeatherType.size():
		set_weather(new_weather)

## Handle weather intensity signal
func _on_weather_intensity_changed(intensity: float) -> void:
	set_weather_intensity(intensity)

## Get current particle data for external systems
func get_particle_data() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for p: WeatherParticle in _particles:
		data.append({
			"position": p.position,
			"velocity": p.velocity,
			"age": p.age,
			"lifetime": p.lifetime,
			"size": p.size,
			"type": p.type
		})
	return data