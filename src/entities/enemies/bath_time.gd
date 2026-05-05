extends Enemy

## BathTime Enemy - Periodically becomes invulnerable while bathing
## HP: Medium, Speed: Medium | Special: 3s invuln every 8s

@export var bath_duration: float = 3.0
@export var bath_interval: float = 8.0

var _bath_timer: float = 0.0
var _is_bathing: bool = false
var _original_modulate: Color

func _ready() -> void:
	super._ready()
	enemy_name = "BathTime"
	max_health = 80.0
	speed = 85.0
	health = max_health
	base_speed = speed
	reward = 25
	_bath_timer = bath_interval  # Start after first interval
	_original_modulate = Color(0.4, 0.7, 1.0, 1.0)  # Water blue
	if has_node("Sprite2D"):
		$Sprite2D.modulate = _original_modulate

func _process(delta: float) -> void:
	if not is_alive:
		return
	
	# Handle stun
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
		return
	
	# Handle bath state
	if _is_bathing:
		_bath_timer -= delta
		if _bath_timer <= 0:
			_end_bath()
		return  # Don't move while bathing
	
	# Move along path
	var effective_speed = base_speed * slow_factor
	progress += effective_speed * delta
	
	# Check if reached end
	if progress_ratio >= 1.0:
		_reach_end()

func _start_bath() -> void:
	_is_bathing = true
	_bath_timer = bath_duration
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(0.6, 0.9, 1.0, 0.6)  # Lighter, semi-transparent
	# Invulnerable during bath - emit signal for visual feedback

func _end_bath() -> void:
	_is_bathing = false
	_bath_timer = bath_interval
	if has_node("Sprite2D"):
		$Sprite2D.modulate = _original_modulate

func take_damage(amount: float) -> void:
	if _is_bathing:
		# Show "splash" effect but no damage
		return
	
	super.take_damage(amount)

func _process_bath_state(delta: float) -> void:
	if _is_bathing:
		_bath_timer -= delta
		if _bath_timer <= 0:
			_end_bath()
