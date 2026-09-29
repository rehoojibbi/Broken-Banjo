extends Node
## GameState (autoload): everything the game remembers between rooms.
## Inventory, story flags, which room we're in and where Dave should appear.
## Access it from any script as `GameState`, e.g. `GameState.has_item("passport")`.

signal inventory_changed ## Emitted whenever an item is added or removed.
signal item_added(item_id: String)
signal item_removed(item_id: String)
signal flag_changed(flag_name: String, value: Variant)
signal selected_item_changed(item_id: String) ## "" means nothing is selected.
signal say_requested(text: String) ## Ask the current room to make Dave say something.

const TITLE_SCREEN := "res://scenes/UI/TitleScreen.tscn"
const FIRST_ROOM := "res://scenes/rooms/Room_Apartment.tscn"
const FIRST_SPAWN := "start"

var inventory: Array[String] = [] ## Item ids, in pickup order (see ItemDB).
var flags: Dictionary = {} ## Story flags, e.g. { "tipped_off": true }.
var current_room: String = "" ## Scene path of the room we're in.
var spawn_point: String = "" ## Name of the Marker2D (under SpawnPoints) to appear at.
var selected_item: String = "" ## Item currently held on the cursor.

# Things that stop the player from clicking around.
var in_dialogue: bool = false ## A Dialogue Manager balloon is open.
var in_cutscene: bool = false ## A scripted sequence is playing.
var transitioning: bool = false ## The screen is fading between rooms.


func _ready() -> void:
	# Track Dialogue Manager conversations so rooms can ignore clicks meanwhile.
	DialogueManager.dialogue_started.connect(func(_res: Resource) -> void: in_dialogue = true)
	DialogueManager.dialogue_ended.connect(func(_res: Resource) -> void: in_dialogue = false)


## Start a fresh game (used by New Game and Restart).
func reset() -> void:
	inventory.clear()
	flags.clear()
	current_room = ""
	spawn_point = ""
	in_dialogue = false
	in_cutscene = false
	clear_selection()
	inventory_changed.emit()


## True while the player shouldn't be able to click on things.
func is_busy() -> bool:
	return in_dialogue or in_cutscene or transitioning


# --- Inventory -------------------------------------------------------------

func add_item(item_id: String) -> void:
	if has_item(item_id):
		return
	inventory.append(item_id)
	item_added.emit(item_id)
	inventory_changed.emit()


func remove_item(item_id: String) -> void:
	if not has_item(item_id):
		return
	inventory.erase(item_id)
	if selected_item == item_id:
		clear_selection()
	item_removed.emit(item_id)
	inventory_changed.emit()


func has_item(item_id: String) -> bool:
	return inventory.has(item_id)


func select_item(item_id: String) -> void:
	selected_item = item_id
	selected_item_changed.emit(item_id)


func clear_selection() -> void:
	if selected_item == "":
		return
	selected_item = ""
	selected_item_changed.emit("")


## Try to combine two inventory items. Returns the line Dave should say.
func combine_items(item_a: String, item_b: String) -> String:
	var combo: Dictionary = ItemDB.find_combination(item_a, item_b)
	if combo.is_empty():
		return ItemDB.random_fail_line()
	for used_item: String in combo.get("remove", []):
		remove_item(used_item)
	add_item(combo["result"])
	for flag_name: String in combo.get("flags", []):
		set_flag(flag_name)
	return combo.get("text", "")


# --- Flags -----------------------------------------------------------------

func set_flag(flag_name: String, value: Variant = true) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)


func get_flag(flag_name: String, default_value: Variant = false) -> Variant:
	return flags.get(flag_name, default_value)


## True if the flag exists and is truthy (true, non-zero, non-empty...).
func has_flag(flag_name: String) -> bool:
	return flags.has(flag_name) and bool(flags[flag_name])
