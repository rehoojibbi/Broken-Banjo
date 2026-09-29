class_name Room
extends Node2D
## Base script for every playable room.
## Handles mouse clicks, hover names, walking Dave to hotspots and running
## their actions. Each room script says `extends Room` and can override
## on_room_ready(), on_interact() and on_use_item() for its own puzzles.
##
## Expected children: Player, NavigationRegion2D, Hotspots (Hotspot nodes)
## and SpawnPoints (Marker2D nodes named like "start" or "from_street").

@onready var player: Player = $Player
@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var spawn_points: Node = $SpawnPoints

var _pending_action: Callable = Callable() ## Runs when Dave arrives at his target.


func _ready() -> void:
	GameState.current_room = scene_file_path
	_place_player_at_spawn()
	player.arrived.connect(_on_player_arrived)
	GameState.say_requested.connect(_on_say_requested)
	Hud.show()
	on_room_ready()


# --- Override these in your room script -------------------------------------

## Called once the room is set up (good place for an intro line).
func on_room_ready() -> void:
	pass


## Left click on a hotspot (after walking there). Return true if you handled it,
## false to let the hotspot do its default action.
func on_interact(_hotspot: Hotspot) -> bool:
	return false


## An inventory item was used on a hotspot. Return true if you handled it.
func on_use_item(_hotspot: Hotspot, _item_id: String) -> bool:
	return false


# --- Helpers room scripts can call --------------------------------------------

## Make Dave say a line. `await say("...")` to wait for it.
func say(text: String) -> void:
	await player.say(text)


## Open a Dialogue Manager conversation and wait until it ends.
func start_dialogue(resource: Resource, cue: String = "start") -> void:
	# We pass GameState in explicitly so the .dialogue file can always use it.
	DialogueManager.show_dialogue_balloon(resource, cue, [{ "GameState": GameState }])
	await DialogueManager.dialogue_ended


## Fade to another room. spawn_name is a Marker2D under that room's SpawnPoints.
func go_to_room(scene_path: String, spawn_name: String = "") -> void:
	RoomChanger.change_room(scene_path, spawn_name)


## Walk Dave to a point (snapped onto the walkable area).
func walk_to_point(target: Vector2) -> void:
	player.walk_to(snap_to_walkable(target))


func snap_to_walkable(point: Vector2) -> Vector2:
	var map_rid: RID = nav_region.get_navigation_map()
	if NavigationServer2D.map_get_iteration_id(map_rid) == 0:
		return point # Navigation map not ready yet (first frame).
	return NavigationServer2D.map_get_closest_point(map_rid, point)


## The topmost active hotspot under a point, or null.
func hotspot_at(point: Vector2) -> Hotspot:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var best: Hotspot = null
	for hit: Dictionary in get_world_2d().direct_space_state.intersect_point(query, 32):
		var hotspot := hit["collider"] as Hotspot
		if hotspot and hotspot.is_active() and (best == null or hotspot.hover_priority > best.hover_priority):
			best = hotspot
	return best


## Run what happens when Dave reaches a hotspot (also used by the tests).
func perform(hotspot: Hotspot, item_id: String = "") -> void:
	if not is_instance_valid(hotspot) or not hotspot.is_active():
		return
	player.face_toward(hotspot.global_position)
	if item_id == "":
		if not on_interact(hotspot):
			hotspot.interact(self)
	else:
		if not on_use_item(hotspot, item_id) and not hotspot.use_item(self, item_id):
			say(ItemDB.random_fail_line())


## Right click: Dave looks at the hotspot.
func look_at_hotspot(hotspot: Hotspot) -> void:
	player.face_toward(hotspot.global_position)
	say(hotspot.look_text if hotspot.look_text != "" else "Nothing special about the %s." % hotspot.display_name.to_lower())


# --- Input ----------------------------------------------------------------------

func _process(_delta: float) -> void:
	# Tell the HUD what's under the mouse so it can show a name label.
	var hovered: Hotspot = null
	if not GameState.is_busy() and not Hud.is_mouse_over_ui():
		hovered = hotspot_at(get_global_mouse_position())
	Hud.set_world_hover(hovered.display_name if hovered else "")


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed:
		return
	if GameState.is_busy():
		# During cutscenes a left click skips the current line of speech.
		if GameState.in_cutscene and mb.button_index == MOUSE_BUTTON_LEFT:
			get_tree().call_group("speech_labels", "skip")
		return
	var click_pos: Vector2 = get_global_mouse_position()
	var hotspot: Hotspot = hotspot_at(click_pos)

	if mb.button_index == MOUSE_BUTTON_LEFT:
		player.skip_speech() # Clicking hurries Dave's current line along.
		if hotspot:
			# Walk over, then interact (or use the held item on it).
			var item_id: String = GameState.selected_item
			GameState.clear_selection()
			_pending_action = perform.bind(hotspot, item_id)
			walk_to_point(hotspot.get_walk_position())
		else:
			_pending_action = Callable()
			walk_to_point(click_pos)
		get_viewport().set_input_as_handled()

	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		if GameState.selected_item != "":
			GameState.clear_selection() # Right click drops the held item.
		elif hotspot:
			player.skip_speech()
			look_at_hotspot(hotspot)
		get_viewport().set_input_as_handled()


func _on_player_arrived() -> void:
	if _pending_action.is_valid():
		var action: Callable = _pending_action
		_pending_action = Callable()
		action.call()


func _on_say_requested(text: String) -> void:
	say(text)


func _place_player_at_spawn() -> void:
	var marker: Node2D = null
	if GameState.spawn_point != "":
		marker = spawn_points.get_node_or_null(NodePath(GameState.spawn_point)) as Node2D
	if marker == null and spawn_points.get_child_count() > 0:
		marker = spawn_points.get_child(0) as Node2D # Fall back to the first spawn point.
	if marker:
		player.teleport_to(marker.global_position)
