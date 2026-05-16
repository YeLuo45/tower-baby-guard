# weather_overlay.gd - Weather overlay for tower-baby-guard V8
# Controls color transitions for weather effects (Overlay + Ambient layers)
extends Control

# Weather types
enum WeatherType {
	CLEAR,
	CLOUDY,
	RAIN,
	STORM,
	FOG,
	NIGHT
}

# Color pairs for each weather type: [overlay_color, ambient_color]
const WEATHER_COLORS := {
	WeatherType.CLEAR: [Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0)],
	WeatherType.CLOUDY: [Color(0.3, 0.3, 0.35, 0.3), Color(0.4, 0.4, 0.45, 0.2)],
	WeatherType.RAIN: [Color(0.15, 0.2, 0.35, 0.5), Color(0.2, 0.25, 0.4, 0.3)],
	WeatherType.STORM: [Color(0.05, 0.05, 0.15, 0.7), Color(0.1, 0.1, 0.2, 0.5)],
	WeatherType.FOG: [Color(0.5, 0.5, 0.55, 0.4), Color(0.6, 0.6, 0.65, 0.3)],
	WeatherType.NIGHT: [Color(0.02, 0.02, 0.08, 0.6), Color(0.05, 0.05, 0.15, 0.4)]
}

@onready var overlay_rect: ColorRect = $Overlay
@onready var ambient_rect: ColorRect = $Ambient

var _current_weather: WeatherType = WeatherType.CLEAR
var _overlay_color: Color = Color.TRANSPARENT
var _ambient_color: Color = Color.TRANSPARENT


func _ready() -> void:
	# Ensure fullscreen coverage
	size = get_tree().root.size
	overlay_rect.size = size
	ambient_rect.size = size


func set_weather(type: WeatherType, from_type: WeatherType, progress: float, intensity: float) -> void:
	"""
	Transition weather overlay colors.
	
	Args:
		type: Target weather type
		from_type: Source weather type for interpolation
		progress: Transition progress (0.0 to 1.0)
		intensity: Effect intensity multiplier (0.0 to 1.0)
	"""
	_current_weather = type
	
	var to_pair: Array = WEATHER_COLORS[type]
	var from_pair: Array = WEATHER_COLORS[from_type]
	
	var to_overlay: Color = to_pair[0]
	var to_ambient: Color = to_pair[1]
	var from_overlay: Color = from_pair[0]
	var from_ambient: Color = from_pair[1]
	
	# Interpolate between weather states
	var interp_overlay := from_overlay.lerp(to_overlay, progress)
	var interp_ambient := from_ambient.lerp(to_ambient, progress)
	
	# Apply intensity multiplier to alpha
	_overlay_color = interp_overlay
	_ambient_color = interp_ambient
	
	_overlay_color.a *= intensity
	_ambient_color.a *= intensity
	
	overlay_rect.color = _overlay_color
	ambient_rect.color = _ambient_color