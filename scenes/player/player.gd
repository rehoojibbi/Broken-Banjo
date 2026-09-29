class_name Player
extends Node2D
## Point-and-click player. Call walk_to(target) and the player follows a
## NavigationAgent2D path to it, then emits `arrived`.
## Call say("text") to show a speech line above Dave's head.

signal arrived

@export var speed: float = 320.0 ## Walk speed in pixels/second (at max_scale).
@export var arrive_distance: float = 4.0

@export_group("Perspective")
@export var use_perspective_scale: bool = true
@export var far_y: float = 700.0 ## Y (global) where the player is smallest.
@export var near_y: float = 1040.0 ## Y (global) where the player is largest.
@export var min_scale: float = 0.65
@export var max_scale: float = 1.1
@export var scale_speed_with_perspective: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var speech: SpeechLabel = $SpeechLabel

var is_walking: bool = false


func _ready() -> void:
	nav_agent.path_desired_distance = arrive_distance
	nav_agent.target_desired_distance = arrive_distance
	_update_perspective()


func walk_to(target: Vector2) -> void:
	nav_agent.target_position = target
	is_walking = true


func stop() -> void:
	is_walking = false
	nav_agent.target_position = global_position


## Jump straight to a position (used when entering a room).
func teleport_to(pos: Vector2) -> void:
	global_position = pos
	stop()
	_update_perspective()


## Turn to face a point (e.g. the hotspot Dave is using).
func face_toward(pos: Vector2) -> void:
	if absf(pos.x - global_position.x) > 8.0:
		sprite.flip_h = pos.x < global_position.x


## Show a speech line. `await player.say("...")` waits until it disappears.
func say(text: String) -> void:
	await speech.say(text)


func skip_speech() -> void:
	speech.skip()


func _physics_process(delta: float) -> void:
	if not is_walking:
		return

	if nav_agent.is_navigation_finished():
		is_walking = false
		arrived.emit()
		return

	var next_pos: Vector2 = nav_agent.get_next_path_position()
	var to_next: Vector2 = next_pos - global_position
	var step: float = speed * delta
	if scale_speed_with_perspective and use_perspective_scale and max_scale > 0.0:
		step *= _perspective_factor() / max_scale

	if absf(to_next.x) > 0.5:
		sprite.flip_h = to_next.x < 0.0

	if to_next.length() <= step:
		global_position = next_pos
	else:
		global_position += to_next.normalized() * step

	_update_perspective()


func _perspective_factor() -> float:
	if not use_perspective_scale or is_equal_approx(far_y, near_y):
		return 1.0
	var t: float = clampf((global_position.y - far_y) / (near_y - far_y), 0.0, 1.0)
	return lerpf(min_scale, max_scale, t)


func _update_perspective() -> void:
	var s: float = _perspective_factor()
	sprite.scale = Vector2(s, s)
	# Keep the speech text just above Dave's head (the sprite is 160 px tall).
	if speech:
		speech.anchor_offset = Vector2(0, -170.0 * s - 10.0)
