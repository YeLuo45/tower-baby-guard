extends Enemy

## Bedtime Enemy - Sleeps periodically, becomes invulnerable while sleeping
## HP: Medium, Speed: Slow

@export var sleep_duration: float = 3.0
@export var wake_duration: float = 5.0

var is_sleeping: bool = false
var sleep_timer: float = 0.0
var was_sleeping: bool = false

func _ready() -> void:
	super._ready()
	enemy_name = "Bedtime"
	max_health = 100.0
	speed = 50.0  # Slow
	health = max_health
	base_speed = speed
	reward = 15
	
	sleep_timer = wake_duration  # Start awake
	
	add_to_group("enemies")

func _process(delta: float) -> void:
	if not is_alive:
		return
	
	sleep_timer -= delta
	
	if is_sleeping:
		# Check if should wake up
		if sleep_timer <= 0:
			is_sleeping = false
			sleep_timer = wake_duration
			was_sleeping = false
	else:
		# Check if should fall asleep
		if sleep_timer <= 0:
			is_sleeping = true
			sleep_timer = sleep_duration
			was_sleeping = true
	
	# If sleeping, don't move or take damage
	if is_sleeping:
		return
	
	# Calculate effective speed
	var effective_speed = base_speed * slow_factor
	
	# Move along path
	progress += effective_speed * delta
	
	# Check if reached end
	if progress_ratio >= 1.0:
		_reach_end()

func take_damage(amount: float) -> void:
	if is_sleeping:
		return  # Invulnerable while sleeping
	super.take_damage(amount)
