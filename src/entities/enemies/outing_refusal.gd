extends Enemy

## OutingRefusal Enemy - Delayed spawn, refuses to move at start
## HP: High, Speed: Slow | Special: 3s delay at spawn, then rushes

@export var delay_duration: float = 3.0

var _delay_timer: float = 0.0
var _is_delayed: bool = true
var _original_speed: float

func _ready() -> void:
	super._ready()
	enemy_name = "OutingRefusal"
	max_health = 180.0
	speed = 60.0  # Slow but eventually moves fast
	_original_speed = speed
	base_speed = speed
	health = max_health
	reward = 35
	_delay_timer = delay_duration
	# Make semi-transparent while delayed
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.0, 0.5, 0.5, 0.5)  # Red-ish, transparent

func _process(delta: float) -> void:
	if not is_alive:
		return
	
	# Handle stun
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
		return
	
	# Handle delay at spawn
	if _is_delayed:
		_delay_timer -= delta
		if _delay_timer <= 0:
			_end_delay()
		return
	
	# Move along path - after delay, speed is doubled (rushes)
	var effective_speed = base_speed * slow_factor
	progress += effective_speed * delta
	
	# Check if reached end
	if progress_ratio >= 1.0:
		_reach_end()

func _end_delay() -> void:
	_is_delayed = false
	base_speed = _original_speed * 1.5  # Rushes after refusing
	speed = base_speed
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Normal opacity, red
