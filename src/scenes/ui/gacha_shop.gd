extends PanelContainer

## Gacha Shop - UI for gacha system
## Shows three egg types, pull buttons, pity counters, and history

@onready var normal_egg_btn: Button = $MarginContainer/VBox/EggContainer/NormalEgg
@onready var rare_egg_btn: Button = $MarginContainer/VBox/EggContainer/RareEgg
@onready var limited_egg_btn: Button = $MarginContainer/VBox/EggContainer/LimitedEgg

@onready var normal_info_label: Label = $MarginContainer/VBox/EggContainer/NormalEgg/EggInfo
@onready var rare_info_label: Label = $MarginContainer/VBox/EggContainer/RareEgg/EggInfo
@onready var limited_info_label: Label = $MarginContainer/VBox/EggContainer/LimitedEgg/EggInfo

@onready var history_container: VBoxContainer = $MarginContainer/VBox/HistorySection/HistoryList
@onready var close_btn: Button = $MarginContainer/VBox/CloseButton

signal shop_closed()

var is_pulling: bool = false
var pull_animation_timer: Timer = null

func _ready() -> void:
	_set_as_filled(false)
	
	# Connect signals
	if GachaSystem:
		GachaSystem.pull_completed.connect(_on_pull_completed)
		GachaSystem.pity_threshold_reached.connect(_on_pity_reached)
	
	# Set up egg buttons
	_setup_egg_button(NormalEgg, GachaData.GachaType.NORMAL, normal_info_label)
	_setup_egg_button(RareEgg, GachaData.GachaType.RARE, rare_info_label)
	_setup_egg_button(LimitedEgg, GachaData.GachaType.LIMITED, limited_info_label)
	
	# Close button
	close_btn.pressed.connect(_on_close_pressed)
	
	_update_ui()
	_refresh_history()

func _setup_egg_button(egg_btn: Button, gacha_type: GachaData.GachaType, info_label: Label) -> void:
	egg_btn.pressed.connect(_on_egg_pressed.bind(gacha_type, egg_btn))
	_update_egg_info(egg_btn, gacha_type, info_label)

func _update_egg_info(egg_btn: Button, gacha_type: GachaData.GachaType, info_label: Label) -> void:
	if not GachaSystem:
		return
	
	var info = GachaSystem.get_pool_info(gacha_type)
	var cost_text = ""
	
	if info["free_coupons"] > 0:
		cost_text = "免费 x%d" % info["free_coupons"]
	else:
		cost_text = "%d金币" % info["single_cost"]
	
	info_label.text = "%s\n%s" % [info["name"], cost_text]

func _update_ui() -> void:
	if not GachaSystem:
		return
	
	_update_egg_info(NormalEgg, GachaData.GachaType.NORMAL, normal_info_label)
	_update_egg_info(RareEgg, GachaData.GachaType.RARE, rare_info_label)
	_update_egg_info(LimitedEgg, GachaData.GachaType.LIMITED, limited_info_label)

func _on_egg_pressed(gacha_type: GachaData.GachaType, egg_btn: Button) -> void:
	if is_pulling:
		return
	
	# Show pull type selection menu
	_show_pull_options(gacha_type)

func _show_pull_options(gacha_type: GachaData.GachaType) -> void:
	var pool_info = GachaSystem.get_pool_info(gacha_type)
	
	# Create a simple confirmation
	var pull_type = _show_pull_type_dialog(gacha_type, pool_info)
	if pull_type == "":
		return
	
	match pull_type:
		"single":
			_execute_single_pull(gacha_type)
		"multi":
			_execute_multi_pull(gacha_type)

func _show_pull_type_dialog(gacha_type: GachaData.GachaType, pool_info: Dictionary) -> String:
	# For simplicity, we'll do single pulls for now
	# A more complete implementation would show a dialog
	return "single"

func _execute_single_pull(gacha_type: GachaData.GachaType) -> void:
	if not GachaSystem:
		return
	
	is_pulling = true
	
	# Play egg animation
	_play_egg_animation(gacha_type)
	
	# Execute pull after animation
	await get_tree().create_timer(0.5).timeout
	
	var rewards = GachaSystem.pull_single(gacha_type, true)
	if rewards.size() > 0:
		_show_reward_popup(gacha_type, rewards)

func _execute_multi_pull(gacha_type: GachaData.GachaType) -> void:
	if not GachaSystem:
		return
	
	is_pulling = true
	
	# Play egg animation
	_play_egg_animation(gacha_type)
	
	await get_tree().create_timer(0.8).timeout
	
	var rewards = GachaSystem.pull_multi(gacha_type)
	if rewards.size() > 0:
		_show_reward_popup(gacha_type, rewards)

func _play_egg_animation(gacha_type: GachaData.GachaType) -> void:
	var egg_btn: Button
	match gacha_type:
		GachaData.GachaType.NORMAL:
			egg_btn = NormalEgg
		GachaData.GachaType.RARE:
			egg_btn = RareEgg
		GachaData.GachaType.LIMITED:
			egg_btn = LimitedEgg
	
	if egg_btn:
		var tween = create_tween()
		tween.tween_property(egg_btn, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(egg_btn, "scale", Vector2(0.9, 0.9), 0.1)
		tween.tween_property(egg_btn, "scale", Vector2(1.0, 1.0), 0.1)

func _show_reward_popup(gacha_type: GachaData.GachaType, rewards: Array) -> void:
	# Create reward display
	var popup = _create_reward_popup(rewards)
	add_child(popup)
	
	# Center the popup
	popup.position = Vector2(
		(size.x - popup.size.x) / 2,
		(size.y - popup.size.y) / 2
	)
	
	# Auto-close after delay
	await get_tree().create_timer(3.0).timeout
	if popup and is_instance_valid(popup):
		popup.queue_free()
	
	is_pulling = false
	_refresh_history()

func _create_reward_popup(rewards: Array) -> Control:
	var popup = PanelContainer.new()
	popup.custom_minimum_size = Vector2(300, 200)
	popup.color = Color(0.1, 0.1, 0.2, 0.95)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	
	var title = Label.new()
	title.text = "恭喜获得!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	for reward in rewards:
		var reward_info = GachaData.get_reward_display_info(reward)
		var reward_label = Label.new()
		reward_label.text = reward_info["name"]
		reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_label.add_theme_color_override("font_color", reward_info["rarity_color"])
		reward_label.add_theme_font_size_override("font_size", 16)
		vbox.add_child(reward_label)
	
	var close_hint = Label.new()
	close_hint.text = "点击任意处关闭"
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_hint.add_theme_font_size_override("font_size", 12)
	close_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(close_hint)
	
	popup.add_child(vbox)
	
	# Make clickable to close
	var click_area = Control.new()
	click_area.custom_minimum_size = popup.custom_minimum_size
	click_area.pressed.connect(func(): popup.queue_free() if is_instance_valid(popup) else null)
	popup.add_child(click_area)
	click_area.lower_than_above.connect(move_child.bind(click_area, 0))
	
	return popup

func _on_pull_completed(gacha_type: GachaData.GachaType, rewards: Array) -> void:
	_update_ui()

func _on_pity_reached(gacha_type: GachaData.GachaType) -> void:
	# Show pity notification
	_show_pity_notification(gacha_type)

func _show_pity_notification(gacha_type: GachaData.GachaType) -> void:
	var pool_name = ""
	match gacha_type:
		GachaData.GachaType.NORMAL:
			pool_name = "普通扭蛋"
		GachaData.GachaType.LIMITED:
			pool_name = "限定扭蛋"
	
	# Flash notification (simple implementation)
	var notification = Label.new()
	notification.text = "保底触发! %s" % pool_name
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	add_child(notification)
	
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(notification):
		notification.queue_free()

func _refresh_history() -> void:
	# Clear existing history
	for child in history_container.get_children():
		child.queue_free()
	
	if not GachaSystem:
		return
	
	var history = GachaSystem.get_pull_history()
	
	if history.is_empty():
		var empty_label = Label.new()
		empty_label.text = "暂无抽取记录"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		history_container.add_child(empty_label)
		return
	
	# Show last 5 items
	var count = mini(5, history.size())
	for i in range(count):
		var entry = history[i]
		var reward_info = GachaData.get_reward_display_info(entry)
		
		var history_item = HBoxContainer.new()
		
		var icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.color = _get_category_color(entry["category"])
		history_item.add_child(icon)
		
		var name_label = Label.new()
		name_label.text = reward_info["name"]
		name_label.add_theme_color_override("font_color", reward_info["rarity_color"])
		history_item.add_child(name_label)
		
		history_container.add_child(history_item)

func _get_category_color(category: GachaData.RewardCategory) -> Color:
	match category:
		GachaData.RewardCategory.GOLD:
			return Color(1.0, 0.84, 0.0)
		GachaData.RewardCategory.SKILL_FRAGMENT:
			return Color(0.7, 0.7, 0.7)
		GachaData.RewardCategory.EXP:
			return Color(0.4, 1.0, 0.4)
		GachaData.RewardCategory.SKILL:
			return Color(0.3, 0.5, 1.0)
		GachaData.RewardCategory.SKIN:
			return Color(0.5, 0.3, 1.0)
		GachaData.RewardCategory.TITLE:
			return Color(0.2, 0.8, 0.8)
		GachaData.RewardCategory.LIMITED_SKIN:
			return Color(1.0, 0.6, 0.1)
		GachaData.RewardCategory.LEGENDARY_TITLE:
			return Color(1.0, 0.8, 0.0)
	return Color.WHITE

func _on_close_pressed() -> void:
	shop_closed.emit()
	queue_free()