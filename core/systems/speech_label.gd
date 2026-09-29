class_name SpeechLabel
extends Label
## Floating speech text that follows its parent (Dave or an NPC) and hides
## itself after a while. `await speech.say("Hello")` waits until the line is done.

signal finished ## The current line was hidden (timed out, skipped or replaced).

@export var anchor_offset: Vector2 = Vector2(0, -200) ## Where the text sits, relative to the parent.
@export var min_time: float = 1.8 ## Shortest time a line stays up (seconds).
@export var time_per_char: float = 0.055 ## Extra time per character.
@export var text_color: Color = Color(1, 0.95, 0.75)

var _timer: Timer


func _ready() -> void:
	add_to_group("speech_labels") # Lets cutscenes skip every line at once.
	top_level = true # Position in screen space, ignore the parent's transform.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	custom_minimum_size.x = 760.0
	add_theme_font_size_override("font_size", 34)
	add_theme_color_override("font_color", text_color)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 10)
	z_index = 100
	hide()
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_finish)
	add_child(_timer)


## Show a line. Await it if you want to wait until it has been read.
func say(line: String) -> void:
	if visible:
		_finish() # Replace whatever was being said.
	text = line
	size = Vector2(custom_minimum_size.x, 0) # Let the label shrink to fit the new text.
	show()
	_update_position()
	_timer.start(min_time + time_per_char * line.length())
	await finished


## Hide the current line early (e.g. when the player clicks).
func skip() -> void:
	if visible:
		_finish()


func is_speaking() -> bool:
	return visible


func _process(_delta: float) -> void:
	if visible:
		_update_position()


func _update_position() -> void:
	var parent_2d := get_parent() as Node2D
	if parent_2d == null:
		return
	var anchor: Vector2 = parent_2d.global_position + anchor_offset
	var pos: Vector2 = anchor - Vector2(size.x * 0.5, size.y)
	# Keep the text on screen.
	var screen: Vector2 = get_viewport_rect().size
	pos.x = clampf(pos.x, 10.0, maxf(10.0, screen.x - size.x - 10.0))
	pos.y = maxf(pos.y, 10.0)
	global_position = pos


func _finish() -> void:
	_timer.stop()
	hide()
	finished.emit()
