extends PanelContainer

## EquipmentPanel - UI panel for managing equipped skills
## Shows skill icons, equipment status, energy consumption, and unlock buttons

@onready var energy_bar: ProgressBar = $MarginContainer/VBoxContainer/EnergyBar
@onready var energy_label: Label = $MarginContainer/VBoxContainer/EnergyLabel
@onready var skill_grid: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/SkillGrid
@onready var slot_container: HBoxContainer = $MarginContainer/VBoxContainer/SlotContainer
@onready var unlock_panel: PanelContainer = $MarginContainer/VBoxContainer/UnlockPanel

const SKILL_ICON_SCENE = preload("res://src/scenes/ui/skill_icon.tscn")
const SLOT_SIZE = 64

var _skill_icons: Array = []
var _slot_icons: Array = []
var _unlock_buttons: Array = []

func _ready() -> void:
	_setup_slot_display()
	_refresh_energy_display()
	_populate_skill_list()
	_populate_unlock_panel()
	_connect_signals()

func _connect_signals() -> void:
	if SkillSystem:
		SkillSystem.energy_changed.connect(_on_energy_changed)
		SkillSystem.skill_equipped.connect(_on_skill_equipped)
		SkillSystem.skill_unequipped.connect(_on_skill_unequipped)
		SkillSystem.skill_unlocked.connect(_on_skill_unlocked)
	if SkillUnlock:
		SkillUnlock.skill_unlock_completed.connect(_on_skill_unlock_completed)
		SkillUnlock.skill_unlock_failed.connect(_on_skill_unlock_failed)

func _setup_slot_display() -> void:
	_slot_icons.clear()
	for i in range(SkillSystem.MAX_ENERGY_SLOTS):
		var slot_btn = Button.new()
		slot_btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot_btn.pressed.connect(_on_slot_clicked.bind(i))
		slot_container.add_child(slot_btn)
		_slot_icons.append(slot_btn)
	_update_slot_display()

func _update_slot_display() -> void:
	for i in range(SkillSystem.MAX_ENERGY_SLOTS):
		var skill_id = SkillSystem.get_equipped_skill(i)
		var btn = _slot_icons[i]
		if skill_id != "":
			var skill = SkillData.get_skill(skill_id)
			if not skill.is_empty():
				btn.text = skill["icon"]
				btn.tooltip_text = skill["name"] + "\n" + skill["description"]
			else:
				btn.text = str(i + 1)
				btn.tooltip_text = "Empty Slot"
		else:
			btn.text = str(i + 1)
			btn.tooltip_text = "Empty Slot"

func _refresh_energy_display() -> void:
	var current = SkillSystem.get_current_energy()
	var max_energy = SkillSystem.get_max_energy()
	energy_bar.max_value = max_energy
	energy_bar.value = current
	energy_label.text = "Energy: %d / %d" % [current, max_energy]

func _populate_skill_list() -> void:
	# Clear existing children
	for child in skill_grid.get_children():
		child.queue_free()
	
	_skill_icons.clear()
	
	# Add all unlocked skills to the grid
	for skill in SkillData.get_all_skills():
		var icon = _create_skill_icon(skill)
		skill_grid.add_child(icon)
		_skill_icons.append(icon)

func _create_skill_icon(skill: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	btn.text = skill["icon"]
	
	var skill_id = skill["id"]
	var is_unlocked = SkillSystem.is_skill_unlocked(skill_id)
	var is_equipped = SkillSystem.is_skill_equipped(skill_id)
	
	if not is_unlocked:
		btn.modulate = Color(0.3, 0.3, 0.3, 1.0)
		btn.disabled = true
		btn.tooltip_text = skill["name"] + "\n[LOCKED]\n" + SkillData.get_unlock_text(skill)
	elif is_equipped:
		btn.modulate = Color(1.0, 1.0, 0.5, 1.0)  # Yellow tint for equipped
		btn.tooltip_text = skill["name"] + "\n[EQUIPPED]\n" + skill["description"]
	else:
		btn.tooltip_text = skill["name"] + "\n" + skill["description"]
		btn.pressed.connect(_on_skill_icon_clicked.bind(skill_id))
	
	# Add cost label
	var cost_label = Label.new()
	cost_label.text = str(skill["energy_cost"])
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_label.vertical_text_alignment = VERTICAL_ALIGNMENT_BOTTOM
	cost_label.position = Vector2(SLOT_SIZE - 12, SLOT_SIZE - 16)
	btn.add_child(cost_label)
	
	return btn

func _populate_unlock_panel() -> void:
	# Clear existing
	for child in unlock_panel.get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	unlock_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "Locked Skills"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var locked = SkillUnlock.get_locked_skills()
	if locked.is_empty():
		var no_locked = Label.new()
		no_locked.text = "All skills unlocked!"
		no_locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(no_locked)
		return
	
	for skill in locked:
		var row = HBoxContainer.new()
		
		var icon = Label.new()
		icon.text = skill["icon"]
		row.add_child(icon)
		
		var name_label = Label.new()
		name_label.text = skill["name"]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		
		var unlock_btn = Button.new()
		if skill["unlock_type"] == SkillData.UnlockType.GOLD_COST:
			unlock_btn.text = "%d Gold" % skill["unlock_value"]
			unlock_btn.pressed.connect(_on_unlock_clicked.bind(skill["id"]))
		else:
			unlock_btn.text = SkillData.get_unlock_text(skill)
			unlock_btn.disabled = true  # Level-based unlocks auto-apply
		row.add_child(unlock_btn)
		
		vbox.add_child(row)

func _on_slot_clicked(slot_index: int) -> void:
	var current_skill = SkillSystem.get_equipped_skill(slot_index)
	if current_skill != "":
		# Unequip current skill
		SkillSystem.unequip_skill(slot_index)
	else:
		# Show skill selection - for now just cycle through unlocked skills
		_show_skill_selector(slot_index)

func _show_skill_selector(slot_index: int) -> void:
	# Simple implementation - equip next available skill
	var unlocked = SkillData.get_all_skills().filter(
		func(s): return SkillSystem.is_skill_unlocked(s["id"]) and not SkillSystem.is_skill_equipped(s["id"])
	)
	if not unlocked.is_empty():
		SkillSystem.equip_skill(unlocked[0]["id"], slot_index)

func _on_skill_icon_clicked(skill_id: String) -> void:
	# Find first empty slot and equip there
	for i in range(SkillSystem.MAX_ENERGY_SLOTS):
		if SkillSystem.get_equipped_skill(i) == "":
			if SkillSystem.can_equip(skill_id, i):
				SkillSystem.equip_skill(skill_id, i)
				break

func _on_unlock_clicked(skill_id: String) -> void:
	SkillUnlock.try_unlock_with_gold(skill_id)

func _on_energy_changed(current: int, max_energy: int) -> void:
	_refresh_energy_display()

func _on_skill_equipped(slot: int, skill_id: String) -> void:
	_update_slot_display()
	_refresh_skill_list()
	_refresh_energy_display()

func _on_skill_unequipped(slot: int) -> void:
	_update_slot_display()
	_refresh_skill_list()
	_refresh_energy_display()

func _on_skill_unlocked(skill_id: String) -> void:
	_populate_skill_list()
	_populate_unlock_panel()

func _on_skill_unlock_completed(skill_id: String) -> void:
	_populate_skill_list()
	_populate_unlock_panel()

func _on_skill_unlock_failed(skill_id: String, reason: String) -> void:
	# Could show notification
	pass

func _refresh_skill_list() -> void:
	for icon in _skill_icons:
		var btn = icon as Button
		if btn and btn.pressed.is_connected(_on_skill_icon_clicked):
			btn.pressed.disconnect(_on_skill_icon_clicked)
	_populate_skill_list()

func get_equipped_skill_ids() -> Array:
	return SkillSystem.get_all_equipped_skills()