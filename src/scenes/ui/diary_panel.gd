extends CanvasLayer

## Baby Diary Panel - shows all achievements with filtering
## Accessed from main menu or pause menu

signal closed

const CATEGORY_ALL: int = -1
const CATEGORY_BASIC: int = 0
const CATEGORY_TOWER: int = 1
const CATEGORY_COMBO: int = 2
const CATEGORY_RARE: int = 3

var _current_filter: int = CATEGORY_ALL

@onready var grid: GridContainer = $Panel/VBox/Scroll/AchievementGrid
@onready var filter_all: Button = $Panel/VBox/FilterBar/FilterAll
@onready var filter_basic: Button = $Panel/VBox/FilterBar/FilterBasic
@onready var filter_tower: Button = $Panel/VBox/FilterBar/FilterTower
@onready var filter_combo: Button = $Panel/VBox/FilterBar/FilterCombo
@onready var filter_rare: Button = $Panel/VBox/FilterBar/FilterRare

func _ready() -> void:
	# Connect filter buttons
	filter_all.pressed.connect(_on_filter_all)
	filter_basic.pressed.connect(_on_filter_basic)
	filter_tower.pressed.connect(_on_filter_tower)
	filter_combo.pressed.connect(_on_filter_combo)
	filter_rare.pressed.connect(_on_filter_rare)
	$Panel/VBox/CloseBtn.pressed.connect(_on_close)
	
	_refresh_achievements()

func _refresh_achievements() -> void:
	# Clear existing items
	for child in grid.get_children():
		child.queue_free()
	
	var achievements = Achievements.get_all_achievements()
	var filtered = achievements
	
	match _current_filter:
		CATEGORY_BASIC:
			filtered = achievements.filter(func(a): return a["category"] == Achievements.Category.BASIC)
		CATEGORY_TOWER:
			filtered = achievements.filter(func(a): return a["category"] == Achievements.Category.TOWER_MASTER)
		CATEGORY_COMBO:
			filtered = achievements.filter(func(a): return a["category"] == Achievements.Category.COMBO_MASTER)
		CATEGORY_RARE:
			filtered = achievements.filter(func(a): return a["category"] == Achievements.Category.RARE)
	
	for ach in filtered:
		var item = _create_achievement_item(ach)
		grid.add_child(item)
	
	# Update count label
	var unlocked = Achievements.get_unlocked_count()
	var total = Achievements.get_total_count()
	$Panel/VBox/CountLabel.text = "%d / %d 解锁" % [unlocked, total]

func _create_achievement_item(ach: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 80)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.95, 0.92, 0.85, 0.9)
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.set_border_width_all(2)
	
	var style_unlocked = StyleBoxFlat.new()
	style_unlocked.bg_color = Color(1, 0.95, 0.8, 1)
	style_unlocked.corner_radius_top_left = 8
	style_unlocked.corner_radius_top_right = 8
	style_unlocked.corner_radius_bottom_right = 8
	style_unlocked.corner_radius_bottom_left = 8
	style_unlocked.set_border_width_all(2)
	style_unlocked.border_color = Color(0.8, 0.6, 0.2, 1)
	
	var is_unlocked = Achievements.is_unlocked(ach["id"])
	
	if is_unlocked:
		panel.theme_override_styles/panel = style_unlocked
	else:
		panel.theme_override_styles/panel = style_normal
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)
	
	# Icon
	var icon_label = Label.new()
	icon_label.text = ach["icon"]
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.custom_minimum_size = Vector2(50, 50)
	if not is_unlocked:
		icon_label.modulate = Color(0.5, 0.5, 0.5, 0.5)
	hbox.add_child(icon_label)
	
	# Text container
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	
	var name_label = Label.new()
	name_label.text = ach["name"]
	name_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1, 1) if is_unlocked else Color(0.5, 0.5, 0.5, 1))
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = ach["desc"]
	desc_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3, 1) if is_unlocked else Color(0.6, 0.6, 0.6, 1))
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	if is_unlocked:
		var date = Achievements.get_achievement_unlock_date(ach["id"])
		var date_label = Label.new()
		date_label.text = "✓ %s" % date
		date_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.2, 1))
		date_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(date_label)
	else:
		var locked_label = Label.new()
		locked_label.text = "○ 未解锁"
		locked_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		locked_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(locked_label)
	
	hbox.add_child(vbox)
	
	return panel

func _on_filter_all() -> void:
	_current_filter = CATEGORY_ALL
	_refresh_achievements()

func _on_filter_basic() -> void:
	_current_filter = CATEGORY_BASIC
	_refresh_achievements()

func _on_filter_tower() -> void:
	_current_filter = CATEGORY_TOWER
	_refresh_achievements()

func _on_filter_combo() -> void:
	_current_filter = CATEGORY_COMBO
	_refresh_achievements()

func _on_filter_rare() -> void:
	_current_filter = CATEGORY_RARE
	_refresh_achievements()

func _on_close() -> void:
	closed.emit()
	queue_free()