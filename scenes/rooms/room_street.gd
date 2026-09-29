extends Room
## Room 2 - the street outside Dave's building.
## Rosa (newsstand) gossips; show her the boarding pass from the gutter and she
## tips Dave off about the watcher (sets the "tipped_off" flag).

@onready var rosa: Hotspot = $Hotspots/Rosa


func on_room_ready() -> void:
	if not GameState.has_flag("street_intro_done"):
		GameState.set_flag("street_intro_done")
		say("Rosa's open. Rosa is always open.")


func on_interact(hotspot: Hotspot) -> bool:
	if hotspot.name == "Watcher" and GameState.has_flag("tipped_off"):
		say("Morning! Anything good in the paper? ...He pretends not to hear me. Amateur.")
		return true
	return false


func on_use_item(hotspot: Hotspot, item_id: String) -> bool:
	if hotspot.name == "Rosa":
		if item_id == "boarding_pass":
			start_dialogue(rosa.dialogue, "show_pass") # Jump straight to her reaction.
		else:
			say("Rosa would only sell it back to me with a markup.")
		return true
	if hotspot.name == "Watcher":
		if item_id == "boarding_pass":
			say("Hand it back and he'll know I've seen it. Not yet.")
		else:
			say("Not here, on my own doorstep.")
		return true
	return false
