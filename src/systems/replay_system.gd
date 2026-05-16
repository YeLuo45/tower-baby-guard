extends Node
## Replay System for tower-baby-guard V9.
## Records game sessions and enables ghost replay playback for competitive play.
class_name ReplaySystem

# Replay state
enum ReplayState { IDLE, RECORDING, PLAYING }
var _state: ReplayState = ReplayState.IDLE

# Recording data
var _recorded_inputs: Array[Dictionary] = []
var _recording_start_time: float = 0.0
var _current_recording: Dictionary = {}

# Playback data
var _playback_inputs: Array[Dictionary] = []
var _playback_index: int = 0
var _playback_start_time: float = 0.0
var _is_paused: bool = false

# Ghost visualization
var _ghost_node: Node = null
var _ghost_scene: PackedScene = null

# Replay metadata
var _replay_version: String = "1.0.0"
var _game_version: String = "V9"
var _replay_name: String = ""
var _player_id: String = ""

# Replay configuration
const MAX_REPLAY_FRAMES: int = 3600 * 60  # 60 minutes at 60fps
const INPUT_RECORD_INTERVAL: float = 1.0 / 60.0  # 60fps input recording

signal replay_started(replay_name: String)
signal replay_paused()
signal replay_resumed()
signal replay_ended()
signal replay_progress_updated(progress: float)
signal ghost_spawned(ghost_node: Node)
signal ghost_despawned()

## Start recording a new replay
func start_recording(replay_name: String = "", player_id: String = "") -> void:
	if _state != ReplayState.IDLE:
		push_warning("[ReplaySystem] Cannot start recording: not idle")
		return
	
	_replay_name = replay_name
	_player_id = player_id
	_recorded_inputs.clear()
	_recording_start_time = Time.get_ticks_msec() / 1000.0
	_current_recording = {
		"version": _replay_version,
		"game_version": _game_version,
		"name": _replay_name,
		"player_id": _player_id,
		"start_time": _recording_start_time,
		"frames": [],
		"metadata": {}
	}
	_state = ReplayState.RECORDING
	replay_started.emit(_replay_name)

## Record an input frame during gameplay
func record_input(input_data: Dictionary) -> void:
	if _state != ReplayState.RECORDING:
		return
	
	var current_time := (Time.get_ticks_msec() / 1000.0) - _recording_start_time
	var frame_data := {
		"time": current_time,
		"input": input_data
	}
	_recorded_inputs.append(frame_data)
	
	# Safety limit
	if _recorded_inputs.size() >= MAX_REPLAY_FRAMES:
		stop_recording()

## Stop recording and finalize the replay
func stop_recording() -> Dictionary:
	if _state != ReplayState.RECORDING:
		push_warning("[ReplaySystem] Not currently recording")
		return {}
	
	_current_recording["frames"] = _recorded_inputs.duplicate(true)
	_current_recording["end_time"] = Time.get_ticks_msec() / 1000.0
	_current_recording["duration"] = _current_recording["end_time"] - _current_recording["start_time"]
	_current_recording["frame_count"] = _recorded_inputs.size()
	
	_state = ReplayState.IDLE
	replay_ended.emit()
	
	var finished_replay := _current_recording.duplicate(true)
	_current_recording.clear()
	_recorded_inputs.clear()
	
	return finished_replay

## Save a replay to file
func save_replay(replay_data: Dictionary, file_path: String) -> bool:
	if replay_data.is_empty():
		push_warning("[ReplaySystem] Cannot save empty replay")
		return false
	
	var json_str := JSON.stringify(replay_data)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()
		return true
	else:
		push_error("[ReplaySystem] Failed to save replay to: " + file_path)
		return false

## Load a replay from file
func load_replay(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		push_error("[ReplaySystem] Replay file not found: " + file_path)
		return {}
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("[ReplaySystem] Failed to open replay: " + file_path)
		return {}
	
	var json_str := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_str) != OK:
		push_error("[ReplaySystem] Failed to parse replay JSON")
		return {}
	
	var replay_data: Dictionary = json.data
	if not _validate_replay(replay_data):
		push_error("[ReplaySystem] Invalid or incompatible replay format")
		return {}
	
	return replay_data

## Validate replay data structure
func _validate_replay(data: Dictionary) -> bool:
	if not data.has("version") or not data.has("frames"):
		return false
	if not data.has("game_version") or data["game_version"] != _game_version:
		push_warning("[ReplaySystem] Replay game version mismatch")
		# Allow loading but warn
	return true

## Start playing back a replay
func start_playback(replay_data: Dictionary, ghost_scene: PackedScene = null) -> void:
	if _state != ReplayState.IDLE:
		push_warning("[ReplaySystem] Cannot start playback: not idle")
		return
	
	if replay_data.is_empty() or not replay_data.has("frames"):
		push_error("[ReplaySystem] Invalid replay data for playback")
		return
	
	_playback_inputs = replay_data["frames"]
	_playback_index = 0
	_playback_start_time = Time.get_ticks_msec() / 1000.0
	_is_paused = false
	_replay_name = replay_data.get("name", "Unnamed Replay")
	
	# Set up ghost if scene provided
	if ghost_scene:
		_ghost_scene = ghost_scene
		_spawn_ghost()
	
	_state = ReplayState.PLAYING
	replay_started.emit(_replay_name)

## Spawn ghost visualization node
func _spawn_ghost() -> void:
	if not _ghost_scene:
		return
	
	if _ghost_node:
		_despawn_ghost()
	
	_ghost_node = _ghost_scene.instantiate()
	if _ghost_node:
		ghost_spawned.emit(_ghost_node)

## Despawn ghost visualization
func _despawn_ghost() -> void:
	if _ghost_node:
		if is_instance_valid(_ghost_node):
			_ghost_node.queue_free()
		_ghost_node = null
		ghost_despawned.emit()

## Get current playback input for a given time
func get_playback_input_at_time(game_time: float) -> Dictionary:
	if _state != ReplayState.PLAYING or _playback_inputs.is_empty():
		return {}
	
	# Binary search for the closest frame at or before game_time
	var left := 0
	var right := _playback_inputs.size() - 1
	
	while left < right:
		var mid := (left + right + 1) / 2
		if _playback_inputs[mid]["time"] <= game_time:
			left = mid
		else:
			right = mid - 1
	
	if left < _playback_inputs.size():
		return _playback_inputs[left].get("input", {})
	
	return {}

## Get interpolated playback input between frames
func get_interpolated_input(game_time: float) -> Dictionary:
	if _state != ReplayState.PLAYING or _playback_inputs.is_empty():
		return {}
	
	# Find surrounding frames
	var frame_before: Dictionary = {}
	var frame_after: Dictionary = {}
	var t: float = 0.0
	
	for i in range(_playback_inputs.size() - 1):
		var current_time := _playback_inputs[i]["time"]
		var next_time := _playback_inputs[i + 1]["time"]
		
		if current_time <= game_time and game_time < next_time:
			frame_before = _playback_inputs[i].get("input", {})
			frame_after = _playback_inputs[i + 1].get("input", {})
			t = (game_time - current_time) / (next_time - current_time)
			break
	
	if frame_before.is_empty():
		return get_playback_input_at_time(game_time)
	
	# Interpolate position inputs
	var result := frame_before.duplicate()
	if frame_before.has("position") and frame_after.has("position"):
		var pos_before: Vector2 = frame_before["position"]
		var pos_after: Vector2 = frame_after["position"]
		result["position"] = pos_before.lerp(pos_after, t)
	
	return result

## Update ghost position during playback (call from _process)
func update_ghost_position() -> void:
	if _state != ReplayState.PLAYING or _is_paused or not _ghost_node:
		return
	
	var current_time := (Time.get_ticks_msec() / 1000.0) - _playback_start_time
	var input := get_interpolated_input(current_time)
	
	if input.has("position") and _ghost_node.has_method("set_ghost_position"):
		_ghost_node.set_ghost_position(input["position"])
	
	# Update replay progress
	var duration: float = 0.0
	if not _playback_inputs.is_empty():
		var last_frame: Dictionary = _playback_inputs[-1]
		duration = last_frame.get("time", 1.0)
	
	var progress: float = clampf(current_time / duration if duration > 0 else 0.0, 0.0, 1.0)
	replay_progress_updated.emit(progress)
	
	# Check if playback ended
	if current_time >= duration:
		stop_playback()

## Pause playback
func pause_playback() -> void:
	if _state != ReplayState.PLAYING:
		return
	_is_paused = true
	replay_paused.emit()

## Resume playback
func resume_playback() -> void:
	if _state != ReplayState.PLAYING or not _is_paused:
		return
	_is_paused = false
	replay_resumed.emit()

## Stop playback
func stop_playback() -> void:
	if _state != ReplayState.PLAYING:
		return
	
	_despawn_ghost()
	_playback_inputs.clear()
	_playback_index = 0
	_state = ReplayState.IDLE
	replay_ended.emit()

## Get current replay state
func get_state() -> ReplayState:
	return _state

## Check if currently recording
func is_recording() -> bool:
	return _state == ReplayState.RECORDING

## Check if currently playing
func is_playing() -> bool:
	return _state == ReplayState.PLAYING

## Get current playback progress (0.0 to 1.0)
func get_playback_progress() -> float:
	if _playback_inputs.is_empty():
		return 0.0
	
	var current_time := (Time.get_ticks_msec() / 1000.0) - _playback_start_time
	var last_frame: Dictionary = _playback_inputs[-1]
	var duration: float = last_frame.get("time", 1.0)
	
	return clampf(current_time / duration if duration > 0 else 0.0, 0.0, 1.0)

## Get remaining time in playback
func get_remaining_time() -> float:
	if _playback_inputs.is_empty():
		return 0.0
	
	var current_time := (Time.get_ticks_msec() / 1000.0) - _playback_start_time
	var last_frame: Dictionary = _playback_inputs[-1]
	var duration: float = last_frame.get("time", 0.0)
	
	return maxf(0.0, duration - current_time)

## List saved replays in a directory
func list_saved_replays(directory_path: String) -> Array[Dictionary]:
	var replays: Array[Dictionary] = []
	
	if not DirAccess.dir_exists_absolute(directory_path):
		return replays
	
	var dir := DirAccess.open(directory_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".replay"):
				var full_path := directory_path + "/" + file_name
				var replay_data: Dictionary = load_replay(full_path)
				if not replay_data.is_empty():
					replays.append({
						"name": replay_data.get("name", "Unnamed"),
						"file_path": full_path,
						"duration": replay_data.get("duration", 0.0),
						"frame_count": replay_data.get("frame_count", 0),
						"date": replay_data.get("start_time", 0.0)
					})
			file_name = dir.get_next()
		dir.list_dir_end()
	
	return replays

## Delete a saved replay
func delete_replay(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		return false
	
	var dir := DirAccess.open(file_path.get_base_dir())
	if dir:
		var result := dir.remove(file_path)
		return result == OK
	return false

## Get replay metadata summary
func get_replay_summary(replay_data: Dictionary) -> String:
	if replay_data.is_empty():
		return "Empty replay"
	
	var name: String = replay_data.get("name", "Unnamed")
	var duration: float = replay_data.get("duration", 0.0)
	var frames: int = replay_data.get("frame_count", 0)
	var minutes := int(duration) / 60
	var seconds := int(duration) % 60
	
	return "%s (%02d:%02d, %d frames)" % [name, minutes, seconds, frames]

## Force reset replay system
func force_reset() -> void:
	stop_recording()
	stop_playback()
	_recorded_inputs.clear()
	_current_recording.clear()
	_playback_inputs.clear()
	_state = ReplayState.IDLE