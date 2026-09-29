extends Control
## End card shown after the demo's last scene. The two ending scenes
## (EndCard_Good / EndCard_Ominous) use this same script with different text.

@export var heading: String = "The End"
@export_multiline var body: String = ""

@onready var heading_label: Label = %Heading
@onready var body_label: Label = %Body
@onready var restart_button: Button = %RestartButton


func _ready() -> void:
	Hud.hide()
	heading_label.text = heading
	body_label.text = body
	restart_button.pressed.connect(_on_restart_pressed)
	restart_button.grab_focus()


func _on_restart_pressed() -> void:
	GameState.reset()
	RoomChanger.change_room(GameState.TITLE_SCREEN)
