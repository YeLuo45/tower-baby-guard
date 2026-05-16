extends PanelContainer

## Upgrade Panel UI - Shows 3 upgrade paths for selected tower
## Handles upgrade purchases and displays current upgrade state

signal upgrade_purchased(tower: Tower, path_index: int)
signal panel_closed()

@onready var header: HBoxContainer = $MarginContainer/VBox/Header
@onready var tower_name_label: Label = $MarginContainer/VBox/Header/TowerName
@onready var max_badge: Label = $MarginContainer/VBox/Header/MaxBadge
@onready var path1_btn: Button = $MarginContainer/VBox/UpgradePaths/Path1Btn
@onready var path2_btn: Button = $MarginContainer/VBox/UpgradePaths/Path2Btn
@onready var path3_btn: Button = $MarginContainer/VBox/UpgradePaths/Path3Btn
@onready var sell_label: Label = $MarginContainer/VBox/Footer/SellLabel
@onready var close_btn: Button = $MarginContainer/VBox/Footer/CloseBtn

var current_tower: Tower = null
var upgrade_system = null
var path_buttons: Array = []

func _ready() -> void:
	path_buttons = [path1_btn, path2_btn, path3_btn]
	
	# Get upgrade system reference (autoload singleton)
	upgrade_system = UpgradeSystem
	
	close_btn.pressed.connect(_on_close_pressed)

func show_panel(tower: Tower) -> void:
	current_tower = tower
	visible = true
	
	# Update header
	tower_name_label.text = "%s Tower" % tower.tower_name
	
	# Check if maxed
	var is_maxed = upgrade_system and upgrade_system.is_tower_maxed(tower)
	max_badge.visible = is_maxed
	
	# Update upgrade paths
	_update_upgrade_paths()
	
	# Update sell value
	_update_sell_value()
	
	# Position above tower
	_update_position(tower)

func hide_panel() -> void:
	visible = false
	current_tower = null
	panel_closed.emit()

func _update_position(tower: Tower) -> void:
	var tower_pos = tower.get_global_position()
	var viewport_size = get_viewport_rect().size
	
	# Position panel above tower
	var panel_pos = tower_pos + Vector2(0, -180)
	
	# Clamp to viewport
	panel_pos.x = clamp(panel_pos.x, 160, viewport_size.x - 160)
	panel_pos.y = clamp(panel_pos.y, 200, viewport_size.y - 200)
	
	global_position = panel_pos

func _update_upgrade_paths() -> void:
	if not current_tower:
		return
	
	var upgrade_data = upgrade_system.get_upgrade_status(current_tower) if upgrade_system else []
	
	for i in range(3):
		var btn = path_buttons[i]
		if i < upgrade_data.size():
			var data = upgrade_data[i]
			_update_path_button(btn, data["name"], data["desc"], data["cost"], data["purchased"], data["can_afford"])
		else:
			btn.text = "Unknown"
			btn.disabled = true

func _update_path_button(btn: Button, name: String, desc: String, cost: int, purchased: bool, can_afford: bool) -> void:
	if purchased:
		btn.text = "✓ %s (Purchased)" % name
		btn.disabled = true
		btn.modulate = Color(0.5, 0.8, 0.5, 1)
	else:
		btn.text = "%s - %sg\n%s" % [name, cost, desc]
		btn.disabled = not can_afford
		btn.modulate = Color(1, 1, 1, 1) if can_afford else Color(0.5, 0.5, 0.5, 1)

func _update_sell_value() -> void:
	if not current_tower:
		return
	
	var sell_value = upgrade_system.calculate_sell_value(current_tower) if upgrade_system else int(current_tower.cost * 0.5)
	sell_label.text = "Sell: %sg" % sell_value

func _on_path1_pressed() -> void:
	_purchase_upgrade(0)

func _on_path2_pressed() -> void:
	_purchase_upgrade(1)

func _on_path3_pressed() -> void:
	_purchase_upgrade(2)

func _purchase_upgrade(path_index: int) -> void:
	if not current_tower or not upgrade_system:
		return
	
	if upgrade_system.purchase_upgrade(current_tower, path_index):
		upgrade_purchased.emit(current_tower, path_index)
		
		# Play VFX on tower
		_play_upgrade_vfx()
		
		# Refresh panel
		_update_upgrade_paths()
		_update_sell_value()
		
		# Check if now maxed
		var is_maxed = upgrade_system.is_tower_maxed(current_tower)
		max_badge.visible = is_maxed

func _play_upgrade_vfx() -> void:
	if not current_tower:
		return
	
	# Create golden glow effect
	var tween = current_tower.create_tween()
	tween.tween_property(current_tower, "modulate", Color(1.3, 1.1, 0.5, 1), 0.2)
	tween.tween_property(current_tower, "modulate", Color(1, 1, 1, 1), 0.3)

func _on_close_pressed() -> void:
	hide_panel()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			hide_panel()
		# Close on click outside panel (when clicking empty space)
		elif event.button_index == MOUSE_BUTTON_LEFT and not is_mouse_in_panel():
			hide_panel()

func is_mouse_in_panel() -> bool:
	var mouse_pos = get_global_mouse_position()
	var rect = get_global_rect()
	return rect.has_point(mouse_pos)