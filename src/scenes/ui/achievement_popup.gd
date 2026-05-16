extends CanvasLayer

## Achievement Popup - shows achievement unlock notifications
## Slides in from top, displays for 3 seconds, fades out

var _queue: Array[Dictionary] = []
var _is_showing: bool = false

func _ready() -> void:
	visible = false

static func show_achievement(icon: String, name: String, desc: String) -> void:
	# Get the achievement popup instance
	var popup = Engine.get_main_loop().root.find_child("AchievementPopup", true, false)
	if popup:
		popup._add_to_queue({"icon": icon, "name": name, "desc": desc})

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
	$Panel/VBox/HBox/Icon.text = ach["icon"]
	$Panel/VBox/Name.text = ach["name"]
	$Panel/VBox/Desc.text = ach["desc"]
	
	# Animate in from top
	var tween = create_tween()
	modulate = Color(1, 1, 1, 0)
	$Panel.position.y = -100
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property($Panel, "position:y", 20, 0.3).set_ease(Tween.EASE_OUT)
	
	# Auto-hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	_hide_and_continue()

func _hide_and_continue() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property($Panel, "position:y", -100, 0.3).set_ease(Tween.EASE_IN)
	await tween.finished
	_show_next()