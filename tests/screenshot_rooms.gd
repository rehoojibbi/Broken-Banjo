extends Node
## Takes a screenshot of every screen (needs a window, NOT --headless):
##   godot res://tests/ScreenshotRooms.tscn
## PNGs are saved to user://screenshots/ (the path is printed at the end).

var shots: Array = [
	{ "name": "01_title", "scene": "res://scenes/UI/TitleScreen.tscn" },
	{ "name": "02_apartment", "scene": "res://scenes/rooms/Room_Apartment.tscn", "spawn": "start" },
	{ "name": "03_street", "scene": "res://scenes/rooms/Room_Street.tscn", "spawn": "from_apartment" },
	{ "name": "04_street_rosa_dialogue", "scene": "res://scenes/rooms/Room_Street.tscn", "spawn": "from_apartment", "rosa": true },
	{ "name": "05_airport", "scene": "res://scenes/rooms/Room_Airport.tscn", "spawn": "from_street" },
	{ "name": "06_end_good", "scene": "res://scenes/UI/EndCard_Good.tscn" },
	{ "name": "07_end_ominous", "scene": "res://scenes/UI/EndCard_Ominous.tscn" },
]


func _ready() -> void:
	if get_tree().current_scene == self:
		var runner: Node = (load(scene_file_path) as PackedScene).instantiate()
		runner.name = "ScreenshotRunner"
		get_tree().root.add_child.call_deferred(runner)
		return
	DirAccess.make_dir_recursive_absolute("user://screenshots")
	for shot: Dictionary in shots:
		GameState.reset()
		# Give Dave a few items so the inventory bar isn't empty.
		for item_id: String in ["decoded_postcard", "uv_torch", "passport", "boarding_pass"]:
			GameState.add_item(item_id)
		GameState.set_flag("intro_done")
		GameState.set_flag("street_intro_done")
		GameState.set_flag("airport_intro_done")
		await RoomChanger.change_room(shot["scene"], shot.get("spawn", ""))
		await get_tree().create_timer(0.4).timeout
		var room := get_tree().current_scene as Room
		if room:
			if shot.get("rosa", false):
				room.start_dialogue(room.get_node("Hotspots/Rosa").dialogue, "start")
				await get_tree().create_timer(1.5).timeout
			else:
				room.player.say("Graybox test: this is how Dave's speech looks.")
				Hud.set_world_hover("")
				GameState.select_item("uv_torch")
				await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		var image: Image = get_viewport().get_texture().get_image()
		var path: String = "user://screenshots/%s.png" % shot["name"]
		image.save_png(path)
		print("Saved ", ProjectSettings.globalize_path(path))
		GameState.in_dialogue = false
	print("SCREENSHOTS DONE: ", ProjectSettings.globalize_path("user://screenshots"))
	get_tree().quit()
