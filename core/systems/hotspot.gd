class_name Hotspot
extends Area2D
## Something in a room Dave can look at and interact with.
##
## Setup: add a CollisionPolygon2D (or CollisionShape2D) child for the clickable
## area, and optionally a Marker2D child called "WalkTo" for where Dave stands.
##   Left click  = walk there, then do the default action (pickup / talk / use_text).
##   Right click = look (Dave says look_text).
## Room scripts can override on_interact()/on_use_item() for special puzzle logic.

@export var display_name: String = "Thing" ## Shown next to the cursor on hover.
@export_multiline var look_text: String = "" ## Said on right click.
@export_multiline var use_text: String = "" ## Said on left click if there's no other action.
@export var hover_priority: int = 0 ## When hotspots overlap, the highest priority wins.

@export_group("Pickup")
@export var pickup_item: String = "" ## Item id from ItemDB. Leave empty if this isn't a pickup.
@export_multiline var pickup_text: String = "" ## Said when picking it up.
@export var hide_on_pickup: bool = true ## Off for containers (drawer, bookshelf...).
@export_multiline var empty_text: String = "" ## Said on later clicks if it stays visible.

@export_group("Talk")
@export var dialogue: Resource ## A .dialogue file: left click starts this conversation.
@export var dialogue_cue: String = "start"

@export_group("Visibility")
@export var hide_if_flag: String = "" ## Hotspot disappears once this flag is set.
@export var show_if_flag: String = "" ## Hotspot only appears once this flag is set.


func _ready() -> void:
	monitoring = false # We only need to be found by mouse queries.
	refresh_visibility()
	GameState.flag_changed.connect(_on_flag_changed)


func _on_flag_changed(_flag_name: String, _value: Variant) -> void:
	refresh_visibility()


## Show/hide based on flags (e.g. a picked-up postcard stays gone on re-entry).
func refresh_visibility() -> void:
	var active: bool = true
	if pickup_item != "" and hide_on_pickup and is_taken():
		active = false
	if hide_if_flag != "" and GameState.has_flag(hide_if_flag):
		active = false
	if show_if_flag != "" and not GameState.has_flag(show_if_flag):
		active = false
	visible = active


## True if this hotspot can currently be hovered/clicked.
func is_active() -> bool:
	return is_visible_in_tree()


## Where Dave walks to before using this hotspot.
func get_walk_position() -> Vector2:
	var marker := get_node_or_null("WalkTo") as Node2D
	return marker.global_position if marker else global_position


## The flag that remembers this pickup was taken, e.g. "taken_passport".
func get_taken_flag() -> String:
	return "taken_" + pickup_item


func is_taken() -> bool:
	return GameState.has_flag(get_taken_flag())


## Default left-click action. `room` is the Room this hotspot lives in.
func interact(room: Room) -> void:
	if pickup_item != "":
		if not is_taken():
			GameState.add_item(pickup_item)
			GameState.set_flag(get_taken_flag()) # Also hides us via refresh_visibility().
			room.say(pickup_text if pickup_text != "" else "I'll take that.")
		else:
			room.say(empty_text if empty_text != "" else "Nothing else in there.")
	elif dialogue != null:
		room.start_dialogue(dialogue, dialogue_cue)
	elif use_text != "":
		room.say(use_text)
	else:
		room.say("I don't see how to use that.")


## Default "use item on me". Return true if it did something.
## (Most item logic lives in the room script's on_use_item instead.)
func use_item(_room: Room, _item_id: String) -> bool:
	return false
