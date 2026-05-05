extends Node

## Audio System - manages game sounds
## Provides sound hooks that can be connected to actual audio players or synthesized sounds

signal sound_played(sound_name: String)

func _ready() -> void:
	# Audio will be handled by connecting to actual sound effects
	# In HTML5 export, we can use Web Audio API via GDScript
	pass

func play_sound(sound_name: String) -> void:
	sound_played.emit(sound_name)
	# Sound is emitted as signal - connect HUD or other nodes to play actual audio
	# For HTML5, sounds would be played via JavaScript interop

# Called when tower is placed
func notify_tower_placed() -> void:
	play_sound("place")

# Called when tower attacks
func notify_attack() -> void:
	play_sound("attack")

# Called when enemy dies
func notify_enemy_death() -> void:
	play_sound("death")

# Called when gold is earned
func notify_gold() -> void:
	play_sound("gold")

# Called when wave starts
func notify_wave_start() -> void:
	play_sound("wave_start")

# Called on victory
func notify_victory() -> void:
	play_sound("victory")

# Called on game over
func notify_game_over() -> void:
	play_sound("game_over")
