# AudioManager.gd - Autoload singleton for tower-baby-guard
# Manages BGM and SFX playback with graceful degradation and BGM crossfade
extends Node

# BGM paths
const BGM_BATTLE := "res://audio/bgm/battle_theme.ogg"
const BGM_BOSS := "res://audio/bgm/boss_theme.ogg"

# SFX paths
const SFX_TOWER_PLACE := "res://audio/sfx/tower_place.wav"
const SFX_TOWER_ATTACK := "res://audio/sfx/tower_attack.wav"
const SFX_ENEMY_DEATH := "res://audio/sfx/enemy_death.wav"
const SFX_COIN := "res://audio/sfx/coin.wav"
const SFX_COMBO := "res://audio/sfx/combo.wav"
const SFX_UPGRADE := "res://audio/sfx/upgrade.wav"
const SFX_WAVE_START := "res://audio/sfx/wave_start.wav"
const SFX_BOSS_HIT := "res://audio/sfx/boss_hit.wav"
const SFX_BOSS_DEATH := "res://audio/sfx/boss_death.wav"
const SFX_BOSS_ROAR := "res://audio/sfx/boss_roar.wav"
const SFX_ACHIEVEMENT := "res://audio/sfx/achievement.wav"

# Audio stream players
var _bgm_player := AudioStreamPlayer.new()
var _bgm_fade_player := AudioStreamPlayer.new()
var _sfx_player := AudioStreamPlayer.new()

# BGM state
var _current_bgm := ""
var _crossfade_duration := 1.5
var _crossfade_tween: Tween = null

# Volume settings (0.0 to 1.0)
var _bgm_volume := 0.7
var _sfx_volume := 0.8

# Loaded audio streams cache for graceful degradation
var _bgm_streams := {}
var _sfx_streams := {}

func _ready() -> void:
	add_child(_bgm_player)
	add_child(_bgm_fade_player)
	add_child(_sfx_player)
	
	_bgm_player.volume_db = linear_to_db(_bgm_volume)
	_bgm_fade_player.volume_db = 0.0
	_sfx_player.volume_db = linear_to_db(_sfx_volume)
	
	# Bus assignment (use Master by default)
	_bgm_player.bus = "Master"
	_bgm_fade_player.bus = "Master"
	_sfx_player.bus = "Master"
	
	# Preload BGM files with graceful degradation
	_preload_bgm()
	_preload_sfx()

func _preload_bgm() -> void:
	var bgm_files := {
		"battle": BGM_BATTLE,
		"boss": BGM_BOSS
	}
	
	for key in bgm_files:
		var path: String = bgm_files[key]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream:
				_bgm_streams[key] = stream
			else:
				push_warning("[AudioManager] Failed to load BGM: " + path)
		else:
			push_warning("[AudioManager] BGM file not found: " + path)

func _preload_sfx() -> void:
	var sfx_files := {
		"tower_place": SFX_TOWER_PLACE,
		"tower_attack": SFX_TOWER_ATTACK,
		"enemy_death": SFX_ENEMY_DEATH,
		"coin": SFX_COIN,
		"combo": SFX_COMBO,
		"upgrade": SFX_UPGRADE,
		"wave_start": SFX_WAVE_START,
		"boss_hit": SFX_BOSS_HIT,
		"boss_death": SFX_BOSS_DEATH,
		"boss_roar": SFX_BOSS_ROAR,
		"achievement": SFX_ACHIEVEMENT
	}
	
	for key in sfx_files:
		var path: String = sfx_files[key]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream:
				_sfx_streams[key] = stream
			else:
				push_warning("[AudioManager] Failed to load SFX: " + path)
		else:
			push_warning("[AudioManager] SFX file not found: " + path)

# BGM Playback

func play_bgm(bgm_name: String) -> void:
	"""Play background music by name ('battle' or 'boss')."""
	if bgm_name == _current_bgm and _bgm_player.playing:
		return
	
	var stream: AudioStream = _bgm_streams.get(bgm_name)
	if not stream:
		push_warning("[AudioManager] BGM stream not available: " + bgm_name)
		return
	
	_crossfade_to_new_bgm(stream, bgm_name)

func _crossfade_to_new_bgm(stream: AudioStream, bgm_name: String) -> void:
	# Cancel any existing crossfade
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	
	# If nothing playing, just start the new BGM
	if not _bgm_player.playing:
		_bgm_player.stream = stream
		_bgm_player.volume_db = linear_to_db(_bgm_volume)
		_bgm_player.play()
		_current_bgm = bgm_name
		return
	
	# Crossfade: fade out current, fade in new
	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	
	# Fade out current
	_crossfade_tween.tween_property(_bgm_player, "volume_db", -80.0, _crossfade_duration)
	
	# Fade in new
	_bgm_fade_player.stream = stream
	_bgm_fade_player.volume_db = -80.0
	_bgm_fade_player.play()
	_crossfade_tween.tween_property(_bgm_fade_player, "volume_db", linear_to_db(_bgm_volume), _crossfade_duration)
	
	await _crossfade_tween.finished
	
	# Swap players
	_bgm_player.stop()
	var temp := _bgm_player
	_bgm_player = _bgm_fade_player
	_bgm_fade_player = temp
	_current_bgm = bgm_name

func stop_bgm() -> void:
	"""Stop current BGM with fade out."""
	if _crossfade_tween and _crossfade_tween.is_valid():
		_crossfade_tween.kill()
	
	var tween := create_tween()
	tween.tween_property(_bgm_player, "volume_db", -80.0, 0.5)
	await tween.finished
	_bgm_player.stop()
	_current_bgm = ""

func play_battle_bgm() -> void:
	"""Play battle theme."""
	play_bgm("battle")

func play_boss_bgm() -> void:
	"""Play boss theme with crossfade from battle."""
	play_bgm("boss")

func pause_bgm() -> void:
	_bgm_player.stream_paused = true

func resume_bgm() -> void:
	_bgm_player.stream_paused = false

# SFX Playback

func play_sfx(sfx_name: String) -> void:
	"""Play a sound effect by name."""
	if _sfx_player.playing:
		_sfx_player.stop()
	
	var stream: AudioStream = _sfx_streams.get(sfx_name)
	if not stream:
		push_warning("[AudioManager] SFX stream not available: " + sfx_name)
		return
	
	_sfx_player.stream = stream
	_sfx_player.play()

# Individual SFX methods for convenience
func play_tower_place() -> void:
	play_sfx("tower_place")

func play_tower_attack() -> void:
	play_sfx("tower_attack")

func play_enemy_death() -> void:
	play_sfx("enemy_death")

func play_coin() -> void:
	play_sfx("coin")

func play_combo() -> void:
	play_sfx("combo")

func play_upgrade() -> void:
	play_sfx("upgrade")

func play_wave_start() -> void:
	play_sfx("wave_start")

func play_boss_hit() -> void:
	play_sfx("boss_hit")

func play_boss_death() -> void:
	play_sfx("boss_death")

func play_boss_roar() -> void:
	play_sfx("boss_roar")

func play_achievement() -> void:
	play_sfx("achievement")

# Volume Controls

func set_bgm_volume(volume: float) -> void:
	"""Set BGM volume (0.0 to 1.0)."""
	_bgm_volume = clamp(volume, 0.0, 1.0)
	_bgm_player.volume_db = linear_to_db(_bgm_volume)

func set_sfx_volume(volume: float) -> void:
	"""Set SFX volume (0.0 to 1.0)."""
	_sfx_volume = clamp(volume, 0.0, 1.0)
	_sfx_player.volume_db = linear_to_db(_sfx_volume)

func get_bgm_volume() -> float:
	return _bgm_volume

func get_sfx_volume() -> float:
	return _sfx_volume

# Utility

func is_bgm_playing() -> bool:
	return _bgm_player.playing

func get_current_bgm() -> String:
	return _current_bgm