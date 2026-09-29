class_name ExitHotspot
extends Hotspot
## A door or exit. Left click walks there and changes room, unless the
## requirements aren't met, in which case Dave says locked_text.

@export_file("*.tscn") var target_room: String = "" ## Room scene to go to.
@export var target_spawn: String = "" ## Marker2D name under the target room's SpawnPoints.
@export var required_items: PackedStringArray = [] ## Dave must carry all of these.
@export var required_flags: PackedStringArray = [] ## ...and all of these flags must be set.
@export_multiline var locked_text: String = "I'm not leaving yet."


func can_use() -> bool:
	for item_id: String in required_items:
		if not GameState.has_item(item_id):
			return false
	for flag_name: String in required_flags:
		if not GameState.has_flag(flag_name):
			return false
	return true


func interact(room: Room) -> void:
	if can_use():
		room.go_to_room(target_room, target_spawn)
	else:
		room.say(locked_text)
