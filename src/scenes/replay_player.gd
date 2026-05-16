# ReplayPlayer.gd - Replay playback controller for tower-baby-guard V9
# Handles recorded replay playback with play/pause, speed control, and timeline scrubbing
extends Control

# Signals
signal playback_started
signal playback_paused
signal playback_stopped
signal playback_speed_changed(speed: float)
signal timeline_changed(current_time: float)
signal event_emitted(event_type: String, event_data: Dictionary)

# Replay data
var replay_data: Dictionary = {
	"title": "Untitled Replay",
	"duration": 0.0,
	"events": []  # Array of {time, type, data}
}

# Playback state
var is_playing: bool = false
var playback_speed: float = 1.0
var current_time: float = 0.0
var _last_process_time: float = 0.0

# Playback speeds available
const SPEEDS: Array[float] = [1.0, 2.0, 4.0]

# UI Components
@onready var title_label: Label = $VBox/TitleLabel
@onready var play_pause_button: Button = $VBox/ControlBar/PlayPauseButton
@onready var speed_option: OptionButton = $VBox/ControlBar/SpeedOption
@onready var time_label: Label = $VBox/Timeline/TimeLabel
@onready var timeline_slider: ProgressBar = $VBox/Timeline/TimelineSlider

func _ready() -> void:
	_setup_ui()
	_update_time_display()

func _setup_ui() -> void:
	# Set up speed option button
	speed_option.clear()
	for speed in SPEEDS:
		speed_option.add_item("%dx" % speed)
	speed_option.selected = 0  # Default to 1x
	
	# Connect signals
	play_pause_button.pressed.connect(_on_play_pause_pressed)
	speed_option.item_selected.connect(_on_speed_changed)
	timeline_slider.drag_started.connect(_on_timeline_drag_started)
	timeline_slider.drag_ended.connect(_on_timeline_drag_ended)
	
	# Configure timeline slider
	timeline_slider.max_value = 100.0
	timeline_slider.step = 0.1

func _process(delta: float) -> void:
	if not is_playing:
		return
	
	var previous_time := current_time
	current_time += delta * playback_speed
	
	# Clamp to duration
	if replay_data.get("duration", 0.0) > 0:
		current_time = min(current_time, replay_data["duration"])
	
	# Update timeline
	_update_timeline_position()
	
	# Emit events that occurred during this frame
	_emit_events_between(previous_time, current_time)
	
	# Check for end of replay
	if current_time >= replay_data.get("duration", 0.0):
		stop()

func _emit_events_between(from_time: float, to_time: float) -> void:
	var events: Array = replay_data.get("events", [])
	for event in events:
		var event_time: float = event.get("time", 0.0)
		if event_time > from_time and event_time <= to_time:
			var event_type: String = event.get("type", "")
			var event_data: Dictionary = event.get("data", {})
			event_emitted.emit(event_type, event_data)

# Public API

func load_replay(data: Dictionary) -> void:
	replay_data = data
	current_time = 0.0
	is_playing = false
	
	# Update UI
	title_label.text = data.get("title", "Untitled Replay")
	_update_time_display()
	_update_timeline_position()
	
	# Reset play button
	play_pause_button.text = "Play"

func play() -> void:
	if is_playing:
		return
	is_playing = true
	_last_process_time = Time.get_ticks_msec() / 1000.0
	play_pause_button.text = "Pause"
	playback_started.emit()

func pause() -> void:
	if not is_playing:
		return
	is_playing = false
	play_pause_button.text = "Play"
	playback_paused.emit()

func stop() -> void:
	is_playing = false
	current_time = 0.0
	play_pause_button.text = "Play"
	_update_time_display()
	_update_timeline_position()
	playback_stopped.emit()

func seek_to(time: float) -> void:
	var previous_time := current_time
	current_time = clamp(time, 0.0, replay_data.get("duration", 0.0))
	_update_time_display()
	_update_timeline_position()
	timeline_changed.emit(current_time)
	
	# Emit events that should now be active at this time
	if current_time > previous_time:
		_emit_events_between(previous_time, current_time)

func set_speed(speed: float) -> void:
	if speed in SPEEDS:
		playback_speed = speed
		# Update option button selection
		var index: int = SPEEDS.find(speed)
		if index >= 0:
			speed_option.selected = index
		playback_speed_changed.emit(playback_speed)

func get_current_time() -> float:
	return current_time

func get_duration() -> float:
	return replay_data.get("duration", 0.0)

func get_speed() -> float:
	return playback_speed

# UI Updates

func _update_time_display() -> void:
	var duration: float = replay_data.get("duration", 0.0)
	var minutes: int = int(current_time) / 60
	var seconds: int = int(current_time) % 60
	var ms: int = int((current_time - floor(current_time)) * 100)
	time_label.text = "%02d:%02d.%02d" % [minutes, seconds, ms]

func _update_timeline_position() -> void:
	var duration: float = replay_data.get("duration", 0.0)
	if duration > 0:
		timeline_slider.value = (current_time / duration) * 100.0
	else:
		timeline_slider.value = 0.0

# Signal Handlers

func _on_play_pause_pressed() -> void:
	if is_playing:
		pause()
	else:
		play()

func _on_speed_changed(index: int) -> void:
	if index >= 0 and index < SPEEDS.size():
		set_speed(SPEEDS[index])

func _on_timeline_drag_started(_value: bool) -> void:
	if is_playing:
		pause()  # Pause while scrubbing

func _on_timeline_drag_ended(_value: bool) -> void:
	var duration: float = replay_data.get("duration", 0.0)
	var target_time: float = (timeline_slider.value / 100.0) * duration
	seek_to(target_time)