extends Node2D
## Room 01 - Beach. Left-click anywhere to walk; clicks outside the walkable
## area are snapped to the closest point on the navigation mesh.

@onready var player: Player = $Player
@onready var nav_region: NavigationRegion2D = $NavigationRegion2D


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_walk_to_click(get_global_mouse_position())
			get_viewport().set_input_as_handled()


func _walk_to_click(click_pos: Vector2) -> void:
	var map_rid: RID = nav_region.get_navigation_map()
	if NavigationServer2D.map_get_iteration_id(map_rid) == 0:
		return # Navigation map not synced yet.
	var target: Vector2 = NavigationServer2D.map_get_closest_point(map_rid, click_pos)
	player.walk_to(target)