extends Room
## Room 1 - Dave's apartment.
## Puzzle: pick up the postcard, find the UV torch (desk) and the passport
## (bookshelf), combine torch + postcard, then leave by the front door.


func on_room_ready() -> void:
	if not GameState.has_flag("intro_done"):
		GameState.set_flag("intro_done")
		say("Tuesday. Rain. No clients. Hang on... something's been pushed under my door.")


func on_interact(hotspot: Hotspot) -> bool:
	# The door is an ExitHotspot; we only step in to give a better "can't leave" line.
	if hotspot.name == "FrontDoor" and not (hotspot as ExitHotspot).can_use():
		say(_door_excuse())
		return true
	return false


func on_use_item(hotspot: Hotspot, item_id: String) -> bool:
	match [String(hotspot.name), item_id]:
		["FramedPhoto", "uv_torch"]:
			say("No hidden messages. Just Viktor's terrible haircut.")
			return true
		["FramedPhoto", "postcard"], ["FramedPhoto", "decoded_postcard"]:
			say("Same handwriting as the note on the back of this photo. It really is Viktor.")
			return true
		["Window", "uv_torch"]:
			say("Nothing glows out there except the kebab shop sign.")
			return true
		["FrontDoor", "passport"]:
			say("A passport isn't a key. Although in some countries...")
			return true
	return false


## Picks the most helpful reason for not leaving yet.
func _door_excuse() -> String:
	if not GameState.has_item("postcard") and not GameState.has_item("decoded_postcard"):
		return "Not yet. First, let's see what was pushed under the door."
	if GameState.has_item("postcard"):
		if GameState.has_item("uv_torch"):
			return "Viktor never sends plain postcards. My UV torch might show what he's really saying."
		return "Viktor never sends plain postcards. There's more to this one. Where's my old spy kit?"
	return "Not without my passport. I hid it where nobody ever looks... somewhere boring."
