extends Control
## Title screen: New Game starts a fresh run in Dave's apartment.

@onready var new_game_button: Button = %NewGameButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	Hud.hide()
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	GameState.reset()
	RoomChanger.change_room(GameState.FIRST_ROOM, GameState.FIRST_SPAWN)
