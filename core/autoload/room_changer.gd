extends CanvasLayer
## RoomChanger (autoload): swaps scenes with a quick fade to black.
## Usage: RoomChanger.change_room("res://scenes/rooms/Room_Street.tscn", "from_apartment")

const FADE_TIME: float = 0.25 ## Seconds for each half of the fade.

var is_changing: bool = false
var _fade: ColorRect


func _ready() -> void:
	layer = 90 # Above the HUD, below nothing.
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)


## Fade out, load the new scene (placing Dave at spawn_name), fade back in.
func change_room(scene_path: String, spawn_name: String = "") -> void:
	if is_changing:
		return
	is_changing = true
	GameState.transitioning = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP # Swallow clicks while dark.

	await _fade_to(1.0)
	GameState.spawn_point = spawn_name
	GameState.clear_selection()
	var err: Error = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("RoomChanger: could not load %s (error %d)" % [scene_path, err])
	# Give the new scene a couple of frames to set itself up.
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0)

	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.transitioning = false
	is_changing = false


func _fade_to(alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "modulate:a", alpha, FADE_TIME)
	await tween.finished
