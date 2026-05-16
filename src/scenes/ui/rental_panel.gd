extends PanelContainer

## Rental Panel - UI for friend rental system
## Shows friend avatars, affinity bars, rental buttons, and cooldown timers

@onready var friend_list: VBoxContainer = $MarginContainer/ScrollContainer/FriendList
@onready var cooldown_label: Label = $MarginContainer/CooldownSection/CooldownLabel
@onready var current_rental_section: PanelContainer = $MarginContainer/CurrentRentalSection

signal rental_requested(friend_type: FriendData.FriendType)

const FRIEND_CARD_SCENE = preload("res://src/scenes/ui/friend_card.tscn")

var friend_cards: Dictionary = {}
var cooldown_timer: Timer = null
var update_cooldown_ui: bool = true

func _ready() -> void:
	_set_as_filled(false)
	
	# Connect to friend system signals
	if FriendSystem:
		FriendSystem.affinity_updated.connect(_on_affinity_updated)
		FriendSystem.rental_started.connect(_on_rental_started)
		FriendSystem.rental_ended.connect(_on_rental_ended)
		FriendSystem.friend_unlocked.connect(_on_friend_unlocked)
	
	_create_friend_cards()
	_update_rental_section()
	_start_cooldown_timer()

func _create_friend_cards() -> void:
	# Clear existing
	for child in friend_list.get_children():
		child.queue_free()
	friend_cards.clear()
	
	# Create card for each friend type
	for friend_type in FriendData.FriendType.values():
		var card = _create_friend_card(friend_type)
		friend_list.add_child(card)
		friend_cards[friend_type] = card

func _create_friend_card(friend_type: FriendData.FriendType) -> Control:
	var friend = FriendData.get_friend_by_type(friend_type)
	var card = HBoxContainer.new()
	card.custom_minimum_size = Vector2(0, 80)
	
	# Avatar placeholder
	var avatar_rect = ColorRect.new()
	avatar_rect.custom_minimum_size = Vector2(60, 60)
	avatar_rect.color = _get_friend_color(friend_type)
	card.add_child(avatar_rect)
	
	# Info section
	var info_vbox = VBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = friend.friend_name
	name_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = friend.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_vbox.add_child(desc_label)
	
	# Affinity bar
	var affinity_container = HBoxContainer.new()
	var affinity_label = Label.new()
	affinity_label.text = "好感度: "
	affinity_label.add_theme_font_size_override("font_size", 12)
	affinity_container.add_child(affinity_label)
	
	var affinity_bar = ProgressBar.new()
	affinity_bar.custom_minimum_size = Vector2(100, 16)
	affinity_bar.max_value = 100
	affinity_bar.value = FriendSystem.get_affinity(friend_type) if FriendSystem else 20
	affinity_container.add_child(affinity_bar)
	
	info_vbox.add_child(affinity_container)
	card.add_child(info_vbox)
	
	# Action section
	var action_vbox = VBoxContainer.new()
	
	var bonus_label = Label.new()
	bonus_label.text = _get_bonus_text(friend.bonus_type, friend.bonus_percentage)
	bonus_label.add_theme_font_size_override("font_size", 11)
	action_vbox.add_child(bonus_label)
	
	var rental_button = Button.new()
	rental_button.text = "借租"
	rental_button.custom_minimum_size = Vector2(80, 32)
	rental_button.pressed.connect(_on_rental_button_pressed.bind(friend_type))
	action_vbox.add_child(rental_button)
	
	var interact_button = Button.new()
	interact_button.text = "互动"
	interact_button.custom_minimum_size = Vector2(80, 28)
	interact_button.pressed.connect(_on_interact_button_pressed.bind(friend_type))
	action_vbox.add_child(interact_button)
	
	card.add_child(action_vbox)
	
	# Store references
	card.set_meta("friend_type", friend_type)
	card.set_meta("affinity_bar", affinity_bar)
	card.set_meta("rental_button", rental_button)
	card.set_meta("interact_button", interact_button)
	card.set_meta("unlocked", FriendSystem.is_friend_unlocked(friend_type) if FriendSystem else false)
	
	_update_card_state(card, friend_type)
	
	return card

func _update_card_state(card: Control, friend_type: FriendData.FriendType) -> void:
	var is_unlocked = FriendSystem.is_friend_unlocked(friend_type) if FriendSystem else false
	var cooldown_ready = FriendSystem.is_rental_ready(friend_type) if FriendSystem else true
	var is_rented = FriendSystem and FriendSystem.get_current_rented_friend() == friend_type
	
	var rental_button: Button = card.get_meta("rental_button")
	var interact_button: Button = card.get_meta("interact_button")
	var affinity_bar: ProgressBar = card.get_meta("affinity_bar")
	
	if not is_unlocked:
		rental_button.text = "未解锁"
		rental_button.disabled = true
		interact_button.text = "未解锁"
		interact_button.disabled = true
		card.modulate = Color(0.5, 0.5, 0.5, 1.0)
	elif is_rented:
		rental_button.text = "使用中"
		rental_button.disabled = true
		interact_button.disabled = true
		card.modulate = Color(1.2, 1.2, 0.8, 1.0)
	elif not cooldown_ready:
		rental_button.text = "冷却中"
		rental_button.disabled = true
		interact_button.disabled = false
		card.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		rental_button.text = "借租"
		rental_button.disabled = false
		interact_button.disabled = false
		card.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	if affinity_bar and FriendSystem:
		affinity_bar.value = FriendSystem.get_affinity(friend_type)

func _get_friend_color(friend_type: FriendData.FriendType) -> Color:
	match friend_type:
		FriendData.FriendType.NEIGHBOR_MOM:
			return Color(1.0, 0.8, 0.8, 1.0)  # Pink
		FriendData.FriendType.KINDERGARTEN_TEACHER:
			return Color(0.8, 0.8, 1.0, 1.0)  # Blue
		FriendData.FriendType.UNCLE:
			return Color(0.8, 1.0, 0.8, 1.0)  # Green
		FriendData.FriendType.GRANDPA:
			return Color(1.0, 0.9, 0.7, 1.0)  # Yellow
		FriendData.FriendType.SISTER:
			return Color(1.0, 0.7, 1.0, 1.0)  # Purple
	return Color.WHITE

func _get_bonus_text(bonus_type: FriendData.BonusType, percentage: float) -> String:
	var pct = int(percentage * 100)
	match bonus_type:
		FriendData.BonusType.GOLD:
			return "金币+%d%%" % pct
		FriendData.BonusType.RANGE:
			return "范围+%d%%" % pct
		FriendData.BonusType.ATTACK_SPEED:
			return "攻速+%d%%" % pct
		FriendData.BonusType.HEALTH:
			return "生命+%d%%" % pct
		FriendData.BonusType.COMBO:
			return "Combo+%d%%" % pct
	return ""

func _on_rental_button_pressed(friend_type: FriendData.FriendType) -> void:
	rental_requested.emit(friend_type)

func _on_interact_button_pressed(friend_type: FriendData.FriendType) -> void:
	if not FriendSystem:
		return
	
	var gained = FriendSystem.perform_daily_interaction(friend_type)
	if gained > 0:
		# Show interaction feedback
		_show_interaction_feedback(friend_type, gained)

func _show_interaction_feedback(friend_type: FriendData.FriendType, amount: int) -> void:
	# Find the card and show feedback
	var card = friend_cards.get(friend_type)
	if card:
		# Simple visual feedback - flash the card
		var tween = create_tween()
		tween.tween_property(card, "modulate", Color(1.5, 1.5, 0.5, 1.0), 0.2)
		tween.tween_property(card, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _on_affinity_updated(friend_type: FriendData.FriendType, new_affinity: int) -> void:
	var card = friend_cards.get(friend_type)
	if card:
		var affinity_bar: ProgressBar = card.get_meta("affinity_bar")
		if affinity_bar:
			affinity_bar.value = new_affinity

func _on_rental_started(friend_type: FriendData.FriendType, tower: Node) -> void:
	_update_all_cards()
	_update_rental_section()

func _on_rental_ended(friend_type: FriendData.FriendType) -> void:
	_update_all_cards()
	_update_rental_section()

func _on_friend_unlocked(friend_type: FriendData.FriendType) -> void:
	_update_all_cards()

func _update_all_cards() -> void:
	for friend_type in friend_cards.keys():
		var card = friend_cards[friend_type]
		_update_card_state(card, friend_type)

func _update_rental_section() -> void:
	if not current_rental_section:
		return
	
	var rental_label = current_rental_section.get_node_or_null("RentalInfo")
	
	if FriendSystem and FriendSystem.is_any_friend_rented():
		current_rental_section.visible = true
		var current_friend = FriendSystem.get_current_rented_friend()
		var friend_data = FriendData.get_friend_by_type(current_friend)
		
		if rental_label:
			rental_label.text = "当前借租: %s的塔楼" % friend_data.friend_name
	else:
		current_rental_section.visible = false

func _start_cooldown_timer() -> void:
	cooldown_timer = Timer.new()
	cooldown_timer.wait_time = 1.0
	cooldown_timer.timeout.connect(_on_cooldown_tick)
	add_child(cooldown_timer)
	cooldown_timer.start()

func _on_cooldown_tick() -> void:
	if not FriendSystem:
		return
	
	# Update cooldown labels and button states
	for friend_type in friend_cards.keys():
		var card = friend_cards[friend_type]
		var cooldown_remaining = FriendSystem.get_rental_cooldown_remaining(friend_type)
		
		if cooldown_remaining > 0:
			var rental_button: Button = card.get_meta("rental_button")
			if rental_button and not rental_button.disabled:
				rental_button.text = FriendSystem.format_cooldown_time(cooldown_remaining)
		
		# Check if cooldown just completed
		if cooldown_remaining <= 0 and cooldown_remaining > -1:
			_update_card_state(card, friend_type)
	
	# Update main cooldown label
	_update_cooldown_label()

func _update_cooldown_label() -> void:
	if not cooldown_label:
		return
	
	var next_ready_text = "所有好友冷却中"
	var min_cooldown = INF
	
	for friend_type in friend_cards.keys():
		if FriendSystem.is_friend_unlocked(friend_type):
			var cooldown = FriendSystem.get_rental_cooldown_remaining(friend_type)
			if cooldown > 0 and cooldown < min_cooldown:
				min_cooldown = cooldown
	
	if min_cooldown < INF:
		next_ready_text = "下次可借租: %s" % FriendSystem.format_cooldown_time(min_cooldown)
	else:
		next_ready_text = "可借租"
	
	cooldown_label.text = next_ready_text

func _exit_tree() -> void:
	if cooldown_timer:
		cooldown_timer.stop()
		cooldown_timer.queue_free()