extends Room
## Room 3 - the airport terminal. Check in, then board at Gate 7.
## - Tipped off by Rosa? Use the decoded postcard on the watcher (or the bin next
##   to him) so he reads the fake "Reykjavik" front and leaves -> good ending.
## - Not tipped off? Dave boards, and the watcher phones it in -> ominous ending.

const GOOD_ENDING := "res://scenes/UI/EndCard_Good.tscn"
const OMINOUS_ENDING := "res://scenes/UI/EndCard_Ominous.tscn"

@onready var watcher: Hotspot = $Hotspots/Watcher
@onready var watcher_speech: SpeechLabel = $Hotspots/Watcher/SpeechLabel
@onready var clerk_speech: SpeechLabel = $Hotspots/CheckInDesk/Clerk/SpeechLabel
@onready var gate: Hotspot = $Hotspots/Gate


func on_room_ready() -> void:
	if not GameState.has_flag("airport_intro_done"):
		GameState.set_flag("airport_intro_done")
		if GameState.has_flag("tipped_off"):
			say("And there he is. Grey coat, newspaper. Rosa was right.")
		else:
			say("Airports. Forty years of tradecraft and I still hate the queues.")


func on_interact(hotspot: Hotspot) -> bool:
	match String(hotspot.name):
		"CheckInDesk":
			_check_in()
			return true
		"Gate":
			_try_board()
			return true
	return false


func on_use_item(hotspot: Hotspot, item_id: String) -> bool:
	if item_id == "decoded_postcard" and (hotspot.name == "Watcher" or hotspot.name == "Bin"):
		_try_decoy(hotspot)
		return true
	if item_id == "postcard" and (hotspot.name == "Watcher" or hotspot.name == "Bin"):
		say("I haven't even read it properly yet.")
		return true
	if hotspot.name == "CheckInDesk" and item_id == "passport":
		_check_in()
		return true
	if hotspot.name == "Gate" and item_id == "ticket":
		_try_board()
		return true
	if hotspot.name == "Watcher" and item_id == "boarding_pass":
		say("Give him back his pass? He'd know I'd been reading his mail.")
		return true
	return false


func _check_in() -> void:
	if GameState.has_item("ticket"):
		say("Already checked in. Seat 14C, aisle, near the exit.")
		return
	GameState.in_cutscene = true
	await say("One seat on the 11:40 to Havana, please. Aisle, near an exit, back to the wall.")
	await clerk_speech.say("Passport... thank you, sir. Seat 14C. Gate 7 is boarding now.")
	GameState.add_item("ticket")
	GameState.in_cutscene = false


func _try_decoy(target: Hotspot) -> void:
	if not GameState.has_flag("tipped_off"):
		if target.name == "Bin":
			say("Throw away Viktor's postcard? Why would I do that?")
		else:
			say("Hand a stranger Viktor's postcard? He's just a man with a newspaper.")
		return
	# Tipped off: let the watcher "find" the card with the fake Reykjavik message.
	GameState.in_cutscene = true
	GameState.remove_item("decoded_postcard")
	if target.name == "Bin":
		await say("Oops. Butterfingers. Oh well, it's only an old postcard.")
	else:
		await say("Excuse me, I think you dropped this.")
	await watcher_speech.say("'Greetings from Reykjavik... meet me at the old harbour.'")
	await watcher_speech.say("(on the phone) Change of plan. He's going to Reykjavik. Gate 3.")
	# He hurries off to the left, towards Gate 3.
	watcher.scale.x = -1.0
	var tween: Tween = create_tween()
	tween.tween_property(watcher, "position:x", -250.0, 2.0)
	await tween.finished
	GameState.set_flag("watcher_decoyed") # Hides him for good (hide_if_flag).
	await say("Enjoy Iceland, Mr Grau. Pack a jumper.")
	GameState.in_cutscene = false


func _try_board() -> void:
	if not GameState.has_item("ticket"):
		say("I should check in first. Even retired spies have to queue.")
		return
	if GameState.has_flag("tipped_off") and not GameState.has_flag("watcher_decoyed"):
		say("Rosa's grey coat is right there. I'm not boarding with a tail. I need to send him somewhere else first.")
		return
	_board_plane()


func _board_plane() -> void:
	GameState.in_cutscene = true
	await say("Havana, here I come.")
	# Dave walks through the gate and disappears.
	var tween: Tween = create_tween()
	tween.tween_property(player, "global_position", gate.global_position + Vector2(0, 150), 0.8)
	tween.parallel().tween_property(player, "modulate:a", 0.0, 0.8)
	await tween.finished
	await get_tree().create_timer(0.6).timeout
	if not GameState.has_flag("watcher_decoyed"):
		# Ominous ending: the watcher lowers his paper and makes a call.
		watcher.scale.x = -1.0
		await watcher_speech.say("(dials a number)")
		await watcher_speech.say("He's on the plane.")
		GameState.set_flag("ending", "ominous")
		GameState.in_cutscene = false
		go_to_room(OMINOUS_ENDING)
	else:
		GameState.set_flag("ending", "good")
		GameState.in_cutscene = false
		go_to_room(GOOD_ENDING)
