extends Node

## Event System - triggers special events during gameplay
## Events: screen_flash, gold_rain, boss_mode, etc.

signal event_triggered(event_type: String, params: Dictionary)
signal screen_flash_started(duration: float)
signal screen_flash_ended()
signal gold_rain_started(amount: int)
signal boss_mode_started()
signal boss_mode_ended()

var active_effects: Array[String] = []

func _ready() -> void:
	active_effects = []

func trigger_event(event_data: Dictionary) -> void:
	var event_type = event_data.get("type", "")
	var trigger = event_data.get("trigger", "")
	var message = event_data.get("message", "")
	
	match event_type:
		"screen_flash":
			var duration = event_data.get("duration", 1.0)
			_trigger_screen_flash(duration, message)
		"gold_rain":
			var amount = event_data.get("amount", 50)
			_trigger_gold_rain(amount)
		"boss_mode":
			_trigger_boss_mode(message)
		"spawn_side":
			var side = event_data.get("side", "left")
			_trigger_spawn_side(side)
		"fog_of_war":
			var duration = event_data.get("duration", 5.0)
			_trigger_fog_of_war(duration)
		"speed_up":
			var duration = event_data.get("duration", 10.0)
			var multiplier = event_data.get("multiplier", 1.3)
			_trigger_speed_up(duration, multiplier)
		_:
			push_warning("EventSystem: Unknown event type: " + event_type)
	
	event_triggered.emit(event_type, event_data)

func _trigger_screen_flash(duration: float, message: String) -> void:
	active_effects.append("screen_flash")
	screen_flash_started.emit(duration)
	
	# Flash effect handled by game.gd connecting to this signal
	# Duration is passed so game knows how long
	
	if message != "":
		_show_event_message(message)
	
	await get_tree().create_timer(duration).timeout
	active_effects.erase("screen_flash")
	screen_flash_ended.emit()

func _trigger_gold_rain(amount: int) -> void:
	active_effects.append("gold_rain")
	gold_rain_started.emit(amount)
	
	# Add gold to GameState
	GameState.gold += amount
	
	_show_event_message("+" + str(amount) + " gold!")
	
	await get_tree().create_timer(2.0).timeout
	active_effects.erase("gold_rain")

func _trigger_boss_mode(message: String) -> void:
	active_effects.append("boss_mode")
	boss_mode_started.emit()
	
	if message != "":
		_show_event_message(message)

func _trigger_spawn_side(side: String) -> void:
	# This event is handled by wave_manager to spawn from sides
	event_triggered.emit("spawn_side", {"side": side})

func _trigger_fog_of_war(duration: float) -> void:
	active_effects.append("fog_of_war")
	event_triggered.emit("fog_of_war", {"duration": duration})
	
	await get_tree().create_timer(duration).timeout
	active_effects.erase("fog_of_war")
	event_triggered.emit("fog_of_war_end", {})

func _trigger_speed_up(duration: float, multiplier: float) -> void:
	active_effects.append("speed_up")
	event_triggered.emit("speed_up", {"duration": duration, "multiplier": multiplier})
	
	await get_tree().create_timer(duration).timeout
	active_effects.erase("speed_up")
	event_triggered.emit("speed_up_end", {})

func _show_event_message(text: String) -> void:
	event_triggered.emit("show_message", {"message": text})

func is_effect_active(effect_name: String) -> bool:
	return active_effects.has(effect_name)

func clear_all_effects() -> void:
	active_effects.clear()