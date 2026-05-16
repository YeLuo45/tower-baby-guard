extends CanvasLayer

## Gallery Panel - Main collection/gallery UI showing all 108 collectibles
## Categories: Enemies (11), Towers (60), Achievements (20), Skills (17)
## Features: Tab filtering, grid display, detail popup, progress bar

signal closed

# Tab indices
enum Tab { ENEMIES, TOWERS, ACHIEVEMENTS, SKILLS }

var _current_tab: Tab = Tab.ENEMIES
var _selected_item: Dictionary = {}

@onready var tab_buttons: HBoxContainer = $Panel/VBox/TabBar
@onready var grid: GridContainer = $Panel/VBox/Scroll/ItemGrid
@onready var progress_bar: ProgressBar = $Panel/VBox/ProgressBar
@onready var progress_label: Label = $Panel/VBox/ProgressLabel
@onready var detail_popup: Control = $DetailPopup
@onready var close_btn: Button = $Panel/VBox/CloseBtn

func _ready() -> void:
	# Connect tab buttons
	var tabs = tab_buttons.get_children()
	for i in tabs.size():
		var btn = tabs[i]
		if btn is Button:
			btn.pressed.connect(_on_tab_selected.bind(i))
	
	# Connect close button
	close_btn.pressed.connect(_on_close)
	
	# Setup detail popup close
	if detail_popup.has_node("CloseBtn"):
		detail_popup.get_node("CloseBtn").pressed.connect(_hide_detail_popup)
	
	# Initial refresh
	_refresh_grid()
	_update_progress()

## Tab selection handler
func _on_tab_selected(tab_index: int) -> void:
	_current_tab = tab_index
	_refresh_grid()
	_update_progress()

## Refresh the grid with current tab items
func _refresh_grid() -> void:
	# Clear existing items
	for child in grid.get_children():
		child.queue_free()
	
	# Get items for current tab
	var item_type: CollectionData.ItemType
	match _current_tab:
		Tab.ENEMIES:
			item_type = CollectionData.ItemType.ENEMY
		Tab.TOWERS:
			item_type = CollectionData.ItemType.TOWER
		Tab.ACHIEVEMENTS:
			item_type = CollectionData.ItemType.ACHIEVEMENT
		Tab.SKILLS:
			item_type = CollectionData.ItemType.SKILL
	
	var items = CollectionSystem.get_collection_for_ui(item_type)
	
	# Update grid columns based on item type
	if _current_tab == Tab.TOWERS:
		grid.columns = 4  # More towers, smaller items
	else:
		grid.columns = 3
	
	for item in items:
		var item_node = _create_item_card(item)
		grid.add_child(item_node)

## Create an item card for the grid
func _create_item_card(item: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 180)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Style based on locked/unlocked
	var style_locked = StyleBoxFlat.new()
	style_locked.bg_color = Color(0.85, 0.82, 0.78, 0.9)
	style_locked.corner_radius_top_left = 8
	style_locked.corner_radius_top_right = 8
	style_locked.corner_radius_bottom_right = 8
	style_locked.corner_radius_bottom_left = 8
	style_locked.set_border_width_all(1)
	style_locked.border_color = Color(0.6, 0.55, 0.5, 1)
	
	var style_unlocked = StyleBoxFlat.new()
	style_unlocked.bg_color = Color(1.0, 0.97, 0.9, 1)
	style_unlocked.corner_radius_top_left = 8
	style_unlocked.corner_radius_top_right = 8
	style_unlocked.corner_radius_bottom_right = 8
	style_unlocked.corner_radius_bottom_left = 8
	style_unlocked.set_border_width_all(2)
	style_unlocked.border_color = Color(0.9, 0.7, 0.3, 1)
	
	if item["unlocked"]:
		card.theme_override_styles/panel = style_unlocked
	else:
		card.theme_override_styles/panel = style_locked
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)
	
	# Icon
	var icon_label = Label.new()
	icon_label.text = item["icon"]
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.custom_minimum_size = Vector2(80, 80)
	icon_label.add_theme_font_size_override("font_size", 48)
	if not item["unlocked"]:
		icon_label.modulate = Color(0.4, 0.4, 0.4, 0.6)
	vbox.add_child(icon_label)
	
	# Name
	var name_label = Label.new()
	name_label.text = item["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	if item["unlocked"]:
		name_label.add_theme_color_override("font_color", Color(0.15, 0.12, 0.08, 1))
	else:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	name_label.custom_minimum_size = Vector2(140, 40)
	vbox.add_child(name_label)
	
	# Status indicator
	var status_label = Label.new()
	if item["unlocked"]:
		status_label.text = "✓ 已解锁"
		status_label.add_theme_color_override("font_color", Color(0.3, 0.6, 0.3, 1))
	else:
		status_label.text = "○ 未解锁"
		status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(status_label)
	
	# Click to show detail
	card.gui_input.connect(_on_card_clicked.bind(item))
	
	return card

## Handle card click - show detail popup
func _on_card_clicked(event: InputEvent, item: Dictionary) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_show_detail_popup(item)

## Show detail popup for an item
func _show_detail_popup(item: Dictionary) -> void:
	_selected_item = item
	detail_popup.visible = true
	
	# Update popup content
	var title_label = detail_popup.get_node_or_null("VBox/TitleLabel")
	var icon_label = detail_popup.get_node_or_null("VBox/IconLabel")
	var desc_label = detail_popup.get_node_or_null("VBox/DescLabel")
	var status_label = detail_popup.get_node_or_null("VBox/StatusLabel")
	
	if title_label:
		title_label.text = item["name"]
	if icon_label:
		icon_label.text = item["icon"]
		if not item["unlocked"]:
			icon_label.modulate = Color(0.4, 0.4, 0.4, 0.6)
	if desc_label:
		desc_label.text = item["desc"]
	if status_label:
		if item["unlocked"]:
			status_label.text = "已解锁于: %s" % item["unlock_date"]
			status_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2, 1))
		else:
			status_label.text = "尚未解锁"
			status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))

## Hide detail popup
func _hide_detail_popup() -> void:
	detail_popup.visible = false
	_selected_item = {}

## Update overall progress display
func _update_progress() -> void:
	var stats = CollectionSystem.get_gallery_stats()
	var percentage = stats["percentage"]
	var unlocked = stats["unlocked"]
	var total = stats["total"]
	
	progress_bar.value = percentage
	progress_label.text = "收集进度: %d / %d (%.1f%%)" % [unlocked, total, percentage]

## Close the gallery
func _on_close() -> void:
	closed.emit()
	queue_free()