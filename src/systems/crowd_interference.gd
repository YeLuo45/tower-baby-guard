extends Node
## Manages crowd interference effects - visual/audio distractions that affect gameplay.
class_name CrowdInterference

# Interference types
enum InterferenceType {
	NONE = 0,
	FLASH = 1,
	SHAKE = 2,
	STATIC = 4,
	COLOR_SHIFT = 8,
	SOUND_BURST = 16,
	ALL = 31
}

# State
var _active_interference: int = InterferenceType.NONE
var _interference_intensity: float = 1.0
var _interference_duration: float = 0.0
var _interference_timer: float = 0.0
var _is_active: bool = false

# Effect nodes
var _flash_overlay: ColorRect
var _static_overlay: TextureRect
var _shake_component: Node2D
var _color_filter: ColorRect

# Crowd behavior simulation
var _crowd_mood: float = 1.0  # 0.0 = hostile, 1.0 = supportive
var _excitement_level: float = 0.0  # 0.0 to 1.0
var _chant_timer: float = 0.0
var _chant_interval: float = 5.0

# Interference patterns
var _interference_patterns: Array[Dictionary] = []

signal interference_started(type: int, intensity: float)
signal interference_ended(type: int)
signal interference_updated(intensity: float)
signal crowd_mood_changed(mood: float)
signal crowd_excitement_changed(excitement: float)

func _ready() -> void:
	_setup_overlays()
	_initialize_patterns()

func _process(delta: float) -> void:
	if not _is_active:
		return
	
	_interference_timer -= delta
	_update_interference_effects()
	
	if _interference_timer <= 0:
		_end_interference()
	
	_update_crowd_behavior(delta)

func _setup_overlays() -> void:
	# Create flash overlay
	_flash_overlay = ColorRect.new()
	_flash_overlay.color = Color.TRANSPARENT
	_flash_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash_overlay)
	
	# Create static overlay (for TV/static effect)
	_static_overlay = TextureRect.new()
	_static_overlay.modulate = Color.TRANSPARENT
	_static_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_static_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_static_overlay)
	
	# Create color filter overlay
	_color_filter = ColorRect.new()
	_color_filter.color = Color.TRANSPARENT
	_color_filter.set_anchors_preset(Control.PRESET_FULL_RECT)
	_color_filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_color_filter)
	
	# Create shake component
	_shake_component = Node2D.new()
	add_child(_shake_component)

func _initialize_patterns() -> void:
	# Predefined interference patterns for variety
	_interference_patterns = [
		{ "type": InterferenceType.FLASH, "intensity": 0.5, "duration": 0.2, "frequency": 4.0 },
		{ "type": InterferenceType.FLASH | InterferenceType.SHAKE, "intensity": 0.7, "duration": 0.5, "frequency": 8.0 },
		{ "type": InterferenceType.STATIC, "intensity": 0.4, "duration": 1.0, "frequency": 2.0 },
		{ "type": InterferenceType.COLOR_SHIFT, "intensity": 0.3, "duration": 0.8, "frequency": 6.0 },
		{ "type": InterferenceType.SOUND_BURST, "intensity": 0.6, "duration": 0.3, "frequency": 1.0 },
		{ "type": InterferenceType.ALL, "intensity": 1.0, "duration": 0.1, "frequency": 10.0 }
	]

## Trigger interference with specific type and intensity
func trigger_interference(type: int, intensity: float, duration: float) -> void:
	if type == InterferenceType.NONE:
		return
	
	_active_interference = type
	_interference_intensity = clamp(intensity, 0.0, 1.0)
	_interference_duration = duration
	_interference_timer = duration
	_is_active = true
	
	interference_started.emit(type, intensity)

## Trigger a random interference pattern
func trigger_random_interference() -> void:
	if _interference_patterns.is_empty():
		return
	
	var pattern: Dictionary = _interference_patterns[randi() % _interference_patterns.size()]
	trigger_interference(
		pattern.get("type", InterferenceType.FLASH),
		pattern.get("intensity", 0.5),
		pattern.get("duration", 0.5)
	)

## Update interference visual/audio effects
func _update_interference_effects() -> void:
	var progress: float = _interference_timer / _interference_duration if _interference_duration > 0 else 0.0
	var current_intensity: float = _interference_intensity * progress
	
	interference_updated.emit(current_intensity)
	
	# Flash effect
	if _active_interference & InterferenceType.FLASH:
		var flash_alpha := sin(_interference_timer * 20.0) * 0.3 * current_intensity
		_flash_overlay.color = Color(1.0, 1.0, 1.0, abs(flash_alpha))
	
	# Static effect
	if _active_interference & InterferenceType.STATIC:
		_static_overlay.modulate = Color(1.0, 1.0, 1.0, current_intensity * 0.4)
	
	# Color shift effect
	if _active_interference & InterferenceType.COLOR_SHIFT:
		var shift := sin(_interference_timer * 15.0) * 0.1 * current_intensity
		_color_filter.color = Color(shift, -shift, shift, current_intensity * 0.2)
	
	# Shake effect
	if _active_interference & InterferenceType.SHAKE:
		_apply_shake(current_intensity)
	
	# Sound burst effect
	if _active_interference & InterferenceType.SOUND_BURST:
		_trigger_sound_burst(current_intensity)

## Apply screen shake offset
func _apply_shake(intensity: float) -> void:
	var shake_offset := Vector2(
		sin(_interference_timer * 50.0) * intensity * 10.0,
		cos(_interference_timer * 50.0) * intensity * 10.0
	)
	_shake_component.position = shake_offset

## Trigger audio interference burst
func _trigger_sound_burst(intensity: float) -> void:
	# Play interference sound effect if audio manager exists
	if has_node("/root/AudioManager"):
		var audio: Node = get_node("/root/AudioManager")
		if audio.has_method("play_interference"):
			audio.play_interference()

## End interference and cleanup
func _end_interference() -> void:
	var ended_type := _active_interference
	_active_interference = InterferenceType.NONE
	_is_active = false
	_interference_timer = 0.0
	
	# Reset all overlays
	_flash_overlay.color = Color.TRANSPARENT
	_static_overlay.modulate = Color.TRANSPARENT
	_color_filter.color = Color.TRANSPARENT
	_shake_component.position = Vector2.ZERO
	
	interference_ended.emit(ended_type)

## Update crowd behavior simulation
func _update_crowd_behavior(delta: float) -> void:
	_chant_timer += delta
	
	# Modify crowd mood based on interference
	if _is_active:
		_excitement_level = clamp(_excitement_level + delta * 0.1, 0.0, 1.0)
	else:
		_excitement_level = clamp(_excitement_level - delta * 0.05, 0.0, 1.0)
	
	# Random mood fluctuations
	if randf() < 0.01:
		_crowd_mood = clamp(_crowd_mood + randf_range(-0.1, 0.1), 0.0, 1.0)
		crowd_mood_changed.emit(_crowd_mood)
	
	if randf() < 0.01:
		_excitement_level = clamp(_excitement_level + randf_range(-0.05, 0.1), 0.0, 1.0)
		crowd_excitement_changed.emit(_excitement_level)
	
	# Trigger chant at intervals
	if _chant_timer >= _chant_interval and _excitement_level > 0.3:
		_trigger_crowd_chant()
		_chant_timer = 0.0
		_chant_interval = randf_range(3.0, 8.0) / (_excitement_level + 0.5)

## Trigger a crowd chant/cheer effect
func _trigger_crowd_chant() -> void:
	var chant_type := "cheer" if _crowd_mood > 0.5 else "boo"
	var intensity: float = _excitement_level * _crowd_mood
	
	match chant_type:
		"cheer":
			_trigger_supportive_effects(intensity)
		"boo":
			_trigger_hostile_effects(intensity)

## Apply supportive crowd effects (buffs)
func _trigger_supportive_effects(intensity: float) -> void:
	# Positive interference - can boost player
	if intensity > 0.7:
		trigger_interference(InterferenceType.FLASH, 0.2, 0.3)
	elif intensity > 0.4:
		trigger_interference(InterferenceType.COLOR_SHIFT, 0.1, 0.5)

## Apply hostile crowd effects (debuffs)
func _trigger_hostile_effects(intensity: float) -> void:
	# Negative interference - can hinder player
	if intensity > 0.7:
		trigger_interference(InterferenceType.STATIC | InterferenceType.SHAKE, 0.5, 0.8)
	elif intensity > 0.4:
		trigger_interference(InterferenceType.SOUND_BURST, 0.3, 0.4)

## Set interference pattern for wave/level
func set_interference_pattern(pattern_index: int) -> void:
	if pattern_index < _interference_patterns.size():
		var pattern: Dictionary = _interference_patterns[pattern_index]
		trigger_interference(
			pattern.get("type", InterferenceType.NONE),
			pattern.get("intensity", 0.5),
			pattern.get("duration", 1.0)
		)

## Force crowd mood (for story events)
func set_crowd_mood(mood: float) -> void:
	_crowd_mood = clamp(mood, 0.0, 1.0)
	crowd_mood_changed.emit(_crowd_mood)

## Force crowd excitement
func set_crowd_excitement(excitement: float) -> void:
	_excitement_level = clamp(excitement, 0.0, 1.0)
	crowd_excitement_changed.emit(_excitement_level)

## Get current interference state
func get_interference_state() -> Dictionary:
	return {
		"active": _is_active,
		"type": _active_interference,
		"intensity": _interference_intensity,
		"duration": _interference_duration,
		"timer": _interference_timer
	}

## Get crowd state
func get_crowd_state() -> Dictionary:
	return {
		"mood": _crowd_mood,
		"excitement": _excitement_level,
		"chant_interval": _chant_interval
	}

## Check if specific interference type is active
func has_interference_type(type: int) -> bool:
	return (_active_interference & type) != 0

## Add custom interference pattern
func add_pattern(pattern: Dictionary) -> void:
	_interference_patterns.append(pattern)

## Clear all patterns
func clear_patterns() -> void:
	_interference_patterns.clear()

## Stop all interference immediately
func stop_all() -> void:
	_end_interference()
	_crowd_mood = 0.5
	_excitement_level = 0.0
	_chant_timer = 0.0