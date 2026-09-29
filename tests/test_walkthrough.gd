extends Node
## Headless walkthrough test: plays the GOOD and the OMINOUS path through the
## real rooms (clicking hotspots via Room.perform, combining via the HUD and
## stepping through Rosa's dialogue balloon), checking GameState along the way.
##
## Run from the project folder:
##   godot --headless res://tests/TestWalkthrough.tscn
## Exit code 0 = all passed, 1 = something failed.

const TITLE := "res://scenes/UI/TitleScreen.tscn"
const APARTMENT := "res://scenes/rooms/Room_Apartment.tscn"
const STREET := "res://scenes/rooms/Room_Street.tscn"
const AIRPORT := "res://scenes/rooms/Room_Airport.tscn"

var passed: int = 0
var failed: int = 0


func _ready() -> void:
	if get_tree().current_scene == self:
		# Changing rooms frees the current scene, so run from a copy parked on the root.
		var runner: Node = (load(scene_file_path) as PackedScene).instantiate()
		runner.name = "TestRunner"
		get_tree().root.add_child.call_deferred(runner)
		return
	Engine.time_scale = 6.0 # Speed up speech timers, fades and tweens.
	await _run_all()
	print("\n==== RESULT: %d passed, %d failed ====" % [passed, failed])
	Engine.time_scale = 1.0
	get_tree().quit(1 if failed > 0 else 0)


func check(condition: bool, what: String) -> void:
	if condition:
		passed += 1
		print("  PASS  ", what)
	else:
		failed += 1
		print("  FAIL  ", what)
		push_error("TEST FAILED: " + what)


# --- Helpers -------------------------------------------------------------------

func scene_path() -> String:
	var scene: Node = get_tree().current_scene
	return scene.scene_file_path if scene else ""


func room() -> Room:
	return get_tree().current_scene as Room


func hotspot(hotspot_name: String) -> Hotspot:
	return room().get_node("Hotspots/" + hotspot_name) as Hotspot


## Wait until nothing is going on (no fade, cutscene, dialogue or speech).
func settle(max_seconds: float = 30.0) -> void:
	var start: int = Time.get_ticks_msec()
	await get_tree().physics_frame
	await get_tree().physics_frame
	while Time.get_ticks_msec() - start < max_seconds * 1000.0:
		var speaking: bool = false
		for label: Node in get_tree().get_nodes_in_group("speech_labels"):
			if (label as SpeechLabel).is_speaking():
				speaking = true
		if not GameState.is_busy() and not speaking:
			break
		await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame


func go(path: String, spawn: String) -> void:
	await RoomChanger.change_room(path, spawn)
	await settle()


## Click a hotspot as if Dave had walked there (optionally using an item on it).
func click(hotspot_name: String, item_id: String = "") -> void:
	room().perform(hotspot(hotspot_name), item_id)
	await settle()


## Step through an open dialogue balloon. `choices` are text snippets picked in order.
func run_dialogue(choices: Array = [], seen_responses: Array = []) -> void:
	var start: int = Time.get_ticks_msec()
	await get_tree().process_frame
	await get_tree().process_frame
	while GameState.in_dialogue and Time.get_ticks_msec() - start < 30000:
		var balloon: Node = _find_balloon()
		if balloon and balloon.dialogue_line:
			var line: DialogueLine = balloon.dialogue_line
			if balloon.dialogue_label.is_typing:
				balloon.dialogue_label.skip_typing()
			elif line.responses.size() > 0 and balloon.responses_menu.visible:
				# Only responses whose [if ...] condition passed are shown to the player.
				var allowed: Array = line.responses.filter(func(r: DialogueResponse) -> bool: return r.is_allowed)
				var pick: DialogueResponse = allowed[allowed.size() - 1]
				for r: DialogueResponse in allowed:
					seen_responses.append(r.text)
				if choices.size() > 0:
					var wanted: String = choices.pop_front()
					for r: DialogueResponse in allowed:
						if r.text.contains(wanted):
							pick = r
				print("        > ", pick.text)
				balloon._on_responses_menu_response_selected(pick)
			elif balloon.is_waiting_for_input:
				print("        ", line.character, ": ", line.text)
				balloon.next(line.next_id)
		await get_tree().process_frame
	await settle()


func _find_balloon() -> Node:
	for child: Node in get_tree().current_scene.get_children():
		if child.get("dialogue_line") != null or child.has_method("apply_dialogue_line"):
			return child
	return null


## Shared first half: solve the apartment.
func solve_apartment() -> void:
	check(scene_path() == APARTMENT, "New Game starts in the apartment")
	await click("FrontDoor")
	check(scene_path() == APARTMENT, "Door stays shut without postcard + passport")
	await click("Postcard")
	check(GameState.has_item("postcard"), "Picked up the postcard")
	check(not hotspot("Postcard").is_active(), "Postcard hotspot hidden after pickup")
	await click("Desk")
	check(GameState.has_item("uv_torch"), "Found the UV torch in the desk")
	await click("Bookshelf")
	check(GameState.has_item("passport"), "Found the passport in the bookshelf")
	await click("Desk")
	check(GameState.inventory.count("uv_torch") == 1, "Desk doesn't give a second torch")
	await click("FrontDoor")
	check(scene_path() == APARTMENT, "Door still shut before decoding")
	# Combine like the player: click torch in the bar, then click the postcard.
	Hud.click_item("uv_torch")
	check(GameState.selected_item == "uv_torch", "UV torch held on cursor")
	Hud.click_item("postcard")
	await settle()
	check(GameState.has_item("decoded_postcard") and not GameState.has_item("postcard"), "UV torch + postcard = decoded postcard")
	check(GameState.selected_item == "", "Selection cleared after combining")
	await click("FrontDoor")
	check(scene_path() == STREET, "Front door leads to the street")


# --- The tests -----------------------------------------------------------------

func _run_all() -> void:
	print("\n== Title screen ==")
	await go(TITLE, "")
	check(scene_path() == TITLE, "Title screen loads")
	(get_tree().current_scene.get_node("%NewGameButton") as Button).pressed.emit()
	await settle()

	print("\n== Walking ==")
	check(scene_path() == APARTMENT, "New Game button opens the apartment")
	var target: Vector2 = Vector2(1400, 860)
	room().walk_to_point(target)
	var t0: int = Time.get_ticks_msec()
	while room().player.is_walking and Time.get_ticks_msec() - t0 < 15000:
		await get_tree().physics_frame
	check(room().player.global_position.distance_to(target) < 12.0, "Dave walks along the navmesh to a clicked point")
	room().walk_to_point(Vector2(1000, 300))
	await settle()
	t0 = Time.get_ticks_msec()
	while room().player.is_walking and Time.get_ticks_msec() - t0 < 15000:
		await get_tree().physics_frame
	check(room().player.global_position.y > 690.0, "Clicking the wall keeps Dave on the floor")
	check(room().hotspot_at(Vector2(1090, 400)) == hotspot("Bookshelf"), "Mouse query finds the bookshelf hotspot")
	check(room().hotspot_at(Vector2(365, 720)) == hotspot("Postcard"), "Mouse query finds the postcard on the floor")

	print("\n== GOOD path ==")
	await solve_apartment()
	await click("BuildingDoor")
	check(scene_path() == APARTMENT, "Can go back into the apartment")
	check(not hotspot("Postcard").is_active(), "Postcard stays gone on re-entry")
	check(room().player.global_position.distance_to(room().get_node("SpawnPoints/from_street").global_position) < 1.0, "Dave appears at the from_street spawn")
	await click("FrontDoor")
	check(scene_path() == STREET, "Back out to the street")
	await click("BoardingPass")
	check(GameState.has_item("boarding_pass"), "Picked up the boarding pass from the gutter")
	await click("Rosa")
	var seen_good: Array = []
	await run_dialogue(["See you"], seen_good)
	check(not seen_good.filter(func(t: String) -> bool: return t.contains("gutter")).is_empty(), "Boarding-pass option shown when Dave has the pass")
	await click("Rosa", "boarding_pass")
	check(GameState.in_dialogue, "Using the pass on Rosa opens the dialogue balloon")
	await run_dialogue()
	check(GameState.has_flag("tipped_off"), "Rosa tips Dave off (tipped_off flag)")
	await click("Rosa")
	await run_dialogue()
	check(not GameState.in_dialogue, "Talking to Rosa again ends cleanly")
	await click("Taxi")
	check(scene_path() == AIRPORT, "Taxi goes to the airport")
	await click("Gate")
	check(scene_path() == AIRPORT, "Can't board before checking in")
	await click("CheckInDesk")
	check(GameState.has_item("ticket"), "Check-in gives a plane ticket")
	await click("Gate")
	check(scene_path() == AIRPORT, "Tipped-off Dave refuses to board with the watcher around")
	await click("Watcher", "decoded_postcard")
	check(GameState.has_flag("watcher_decoyed"), "Decoy postcard sends the watcher away")
	check(not hotspot("Watcher").is_active(), "Watcher is gone")
	await click("Gate")
	await settle()
	check(scene_path() == "res://scenes/UI/EndCard_Good.tscn", "GOOD ENDING card shown")
	(get_tree().current_scene.get_node("%RestartButton") as Button).pressed.emit()
	await settle()
	check(scene_path() == TITLE, "Restart returns to the title screen")
	check(GameState.inventory.is_empty() and GameState.flags.is_empty(), "Restart resets GameState")

	print("\n== OMINOUS path ==")
	(get_tree().current_scene.get_node("%NewGameButton") as Button).pressed.emit()
	await settle()
	await solve_apartment()
	# Chat with Rosa WITHOUT picking up the boarding pass.
	await click("Rosa")
	var seen: Array = []
	await run_dialogue(["gossip", "odd", "See you"], seen)
	check(not GameState.has_flag("tipped_off"), "Plain chat with Rosa doesn't tip Dave off")
	check(seen.filter(func(t: String) -> bool: return t.contains("gutter")).is_empty(), "Boarding-pass option hidden without the pass")
	await click("Taxi")
	check(scene_path() == AIRPORT, "Taxi goes to the airport")
	await click("ExitDoors")
	check(scene_path() == STREET, "Airport exit returns to the street")
	await click("Taxi")
	check(scene_path() == AIRPORT, "Back at the airport")
	await click("Watcher", "decoded_postcard")
	check(not GameState.has_flag("watcher_decoyed") and GameState.has_item("decoded_postcard"), "Decoy doesn't work when not tipped off")
	await click("CheckInDesk")
	await click("Gate")
	await settle()
	check(scene_path() == "res://scenes/UI/EndCard_Ominous.tscn", "OMINOUS ENDING card shown")
