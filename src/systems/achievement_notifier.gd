extends CanvasLayer

## Achievement Notifier - shows achievement popup notifications

var _queue: Array[Dictionary] = []
var _is_showing: bool = false

func _ready() -> void:
	visible = false

static func show_achievement(icon: String, name: String, desc: String) -> void:
	# This is called statically, so we need to get the instance
	var notifier = Engine.get_main_loop().root.find_child("AchievementNotifier", true, false)
	if notifier:
		notifier._add_to_queue({"icon": icon, "name": name, "desc": desc})

func _add_to_queue(achievement: Dictionary) -> void:
	_queue.append(achievement)
	if not _is_showing:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		visible = false
		_is_showing = false
		return
	
	_is_showing = true
	visible = true
	
	var ach = _queue.pop_front()
	$Panel/VBox/Icon.text = ach["icon"]
	$Panel/VBox/Name.text = ach["name"]
	$Panel/VBox/Desc.text = ach["desc"]
	
	# Animate in
	var tween = create_tween()
	modulate = Color(1, 1, 1, 0)
	$Panel.position.x = 800
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property($Panel, "position:x", 600, 0.3)
	
	# Auto-hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	_hide_and_continue()

func _hide_and_continue() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property($Panel, "position:x", 400, 0.3)
	await tween.finished
	_show_next()
