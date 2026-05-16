extends CanvasLayer

## Story System - displays narrative vignettes between waves
## Shows semi-transparent overlay with story text

signal story_completed()
signal story_dismissed()

@export var typewriter_speed: float = 0.03
@export var fade_duration: float = 0.5

var current_text: String = ""
var typewriter_position: int = 0
var is_displaying: bool = false

@onready var panel: PanelContainer = $PanelContainer
@onready var story_label: Label = $PanelContainer/Margin/VBox/StoryLabel
@onready var continue_btn: Button = $PanelContainer/Margin/VBox/ContinueBtn
@onready var overlay: ColorRect = $Overlay

func _ready() -> void:
	panel.visible = false
	overlay.visible = false
	continue_btn.pressed.connect(_on_continue_pressed)
	
	# Allow clicking anywhere to dismiss
	overlay.gui_input.connect(_on_overlay_click)

func show_story(text: String) -> void:
	if text == "" or text == null:
		story_completed.emit()
		return
	
	current_text = text
	typewriter_position = 0
	story_label.text = ""
	is_displaying = true
	
	# Show overlay and panel
	overlay.visible = true
	panel.visible = true
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.85, fade_duration)
	tween.tween_property(panel, "modulate:a", 1.0, fade_duration)
	
	# Start typewriter effect
	_start_typewriter()

func _start_typewriter() -> void:
	var timer = Timer.new()
	timer.name = "TypewriterTimer"
	timer.wait_time = typewriter_speed
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(_on_typewriter_tick)
	timer.start()

func _on_typewriter_tick() -> void:
	if typewriter_position < current_text.length():
		typewriter_position += 1
		story_label.text = current_text.substr(0, typewriter_position)
	else:
		# Finished typing
		var timer = get_node_or_null("TypewriterTimer")
		if timer:
			timer.stop()
			timer.queue_free()
		is_displaying = false

func _on_continue_pressed() -> void:
	_dismiss()

func _on_overlay_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if not is_displaying:
			_dismiss()
		elif is_displaying:
			# Skip typewriter effect
			var timer = get_node_or_null("TypewriterTimer")
			if timer:
				timer.stop()
				timer.queue_free()
			story_label.text = current_text
			is_displaying = false

func _dismiss() -> void:
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, fade_duration)
	tween.tween_property(overlay, "modulate:a", 0.0, fade_duration)
	await tween.finished
	
	panel.visible = false
	overlay.visible = false
	panel.modulate.a = 1.0
	overlay.modulate.a = 1.0
	
	story_completed.emit()
	story_dismissed.emit()

func is_showing() -> bool:
	return panel.visible