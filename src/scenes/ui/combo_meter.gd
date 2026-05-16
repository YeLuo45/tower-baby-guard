extends Control

## Combo Meter UI - displays 8 combo slots with filled/unfilled state

@onready var combo_container: HBoxContainer = $ComboContainer
@onready var combo_slots: Array = []

var combo_system = null
var alliance_system = null

const COMBO_ORDER = [
	"Family Meal",    # Mom + Chef
	"House Call",     # Mom + Doctor
	"Full House",     # Mom + Dad + Grandma
	"Kitchen Party",  # Chef + Grandma
	"Power Nap",      # Mom + Grandma + Doctor
	"Dad's Timeout",  # Dad + Doctor
	"Emergency Room", # Mom + Chef + Doctor
	"Grandma's Wisdom" # Grandma + any 2
]

var slot_states: Array = []

func _ready() -> void:
	_create_combo_slots()
	slot_states.resize(8)
	slot_states.fill(false)

func _create_combo_slots() -> void:
	for i in range(8):
		var slot = _create_slot(i)
		combo_container.add_child(slot)
		combo_slots.append(slot)

func _create_slot(index: int) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(70, 40)
	
	var label = Label.new()
	label.text = COMBO_ORDER[index]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.theme_default_font_size = 9
	
	panel.add_child(label)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_right = 4
	style_normal.corner_radius_bottom_left = 4
	
	var style_active = StyleBoxFlat.new()
	style_active.bg_color = Color(1.0, 0.5, 0.1, 0.9)
	style_active.corner_radius_top_left = 4
	style_active.corner_radius_top_right = 4
	style_active.corner_radius_bottom_right = 4
	style_active.corner_radius_bottom_left = 4
	
	panel.add_theme_stylebox_override("panel", style_normal)
	panel.set_meta("style_normal", style_normal)
	panel.set_meta("style_active", style_active)
	panel.set_meta("index", index)
	
	return panel

func setup(combo_sys_ref: Node, alliance_sys_ref: Node) -> void:
	combo_system = combo_sys_ref
	alliance_system = alliance_sys_ref
	
	if combo_system:
		combo_system.combo_activated.connect(_on_combo_activated)
		combo_system.combo_deactivated.connect(_on_combo_deactivated)

func _on_combo_activated(combo_type: int, towers: Array) -> void:
	var slot_index = _combo_type_to_index(combo_type)
	if slot_index >= 0 and slot_index < combo_slots.size():
		_set_slot_active(slot_index, true)
		_animate_activation(slot_index)

func _on_combo_deactivated(combo_type: int) -> void:
	var slot_index = _combo_type_to_index(combo_type)
	if slot_index >= 0 and slot_index < combo_slots.size():
		_set_slot_active(slot_index, false)

func _combo_type_to_index(combo_type: int) -> int:
	# Map ComboType enum to slot index
	match combo_type:
		0: return 0  # FAMILY_MEAL
		1: return 1  # HOUSE_CALL
		2: return 2  # FULL_HOUSE
		3: return 3  # KITCHEN_PARTY
		4: return 4  # POWER_NAP
		5: return 5  # DADS_TIMEOUT
		6: return 6  # EMERGENCY_ROOM
		7: return 7  # GRANDMAS_WISDOM
	return -1

func _set_slot_active(index: int, active: bool) -> void:
	if index < 0 or index >= combo_slots.size():
		return
	
	var slot = combo_slots[index]
	var style_normal = slot.get_meta("style_normal")
	var style_active = slot.get_meta("style_active")
	
	if active:
		slot.add_theme_stylebox_override("panel", style_active)
	else:
		slot.add_theme_stylebox_override("panel", style_normal)
	
	slot_states[index] = active

func _animate_activation(index: int) -> void:
	var slot = combo_slots[index]
	var tween = create_tween()
	tween.tween_property(slot, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.1)

func update_from_game_state() -> void:
	if not combo_system or not alliance_system:
		return
	
	# Update all slots based on current game state
	for i in range(8):
		# This will be called when alliances change
		pass

func show_combo_activation_effect(combo_name: String) -> void:
	# Create floating text effect
	var label = Label.new()
	label.text = combo_name + "!"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.8, 0.2, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	
	add_child(label)
	label.add_theme_stylebox_override("normal", style)
	
	# Position near center of screen
	label.position = Vector2(500, 300)
	
	# Animate
	var tween = create_tween()
	tween.tween_property(label, "position:y", 250, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(label.queue_free)