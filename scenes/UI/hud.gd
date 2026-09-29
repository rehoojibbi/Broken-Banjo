extends CanvasLayer
## Hud (autoload): the inventory bar, the hover name next to the cursor and the
## "held item" that follows the mouse. Rooms show it, menus hide it.
##   Left click an item  = pick it up on the cursor (or combine with the held item).
##   Right click an item = Dave looks at it.

const ITEM_SIZE := Vector2(150, 92)

@onready var bar: PanelContainer = $Bar
@onready var item_row: HBoxContainer = %ItemRow
@onready var hover_label: Label = $HoverLabel
@onready var cursor_item: PanelContainer = $CursorItem
@onready var cursor_item_label: Label = %CursorItemLabel

var _world_hover: String = "" ## Name of the hotspot under the mouse (set by the room).
var _hovered_item: String = "" ## Inventory item under the mouse.


func _ready() -> void:
	layer = 20
	hide() # The title screen doesn't want it; rooms call Hud.show().
	GameState.inventory_changed.connect(_rebuild_items, CONNECT_DEFERRED)
	GameState.selected_item_changed.connect(_on_selected_item_changed)
	_rebuild_items()
	_on_selected_item_changed("")


## Called by the room every frame with the hovered hotspot's name ("" = none).
func set_world_hover(hotspot_name: String) -> void:
	_world_hover = hotspot_name


## True while the mouse is over the inventory bar (rooms ignore it then).
func is_mouse_over_ui() -> bool:
	return visible and bar.get_global_rect().has_point(bar.get_global_mouse_position())


func _process(_delta: float) -> void:
	var mouse: Vector2 = bar.get_global_mouse_position()
	var target_name: String = _hovered_item_name() if _hovered_item != "" else _world_hover
	if GameState.is_busy():
		target_name = ""
	var held: String = GameState.selected_item

	# Hover text: "Postcard" or "Use UV torch on Postcard".
	var text: String = target_name
	if held != "":
		text = "Use %s on %s" % [ItemDB.get_item_name(held), target_name] if target_name != "" and _hovered_item != held else "Use %s on..." % ItemDB.get_item_name(held)
	hover_label.text = text
	hover_label.visible = text != "" and visible
	hover_label.reset_size()
	var screen: Vector2 = bar.get_viewport_rect().size
	var pos: Vector2 = mouse + Vector2(28, -56)
	pos.x = clampf(pos.x, 8.0, maxf(8.0, screen.x - hover_label.size.x - 8.0))
	pos.y = maxf(pos.y, 8.0)
	hover_label.position = pos

	# The held item follows the cursor.
	cursor_item.visible = held != ""
	cursor_item.position = mouse + Vector2(18, 18)


func _hovered_item_name() -> String:
	return ItemDB.get_item_name(_hovered_item)


func _rebuild_items() -> void:
	for child: Node in item_row.get_children():
		item_row.remove_child(child) # Remove now so the new buttons can reuse the names.
		child.queue_free()
	_hovered_item = ""
	for item_id: String in GameState.inventory:
		item_row.add_child(_make_item_button(item_id))
	_on_selected_item_changed(GameState.selected_item)


## A placeholder item icon: a coloured square with the item's name on it.
func _make_item_button(item_id: String) -> Button:
	var button := Button.new()
	button.name = item_id
	button.text = ItemDB.get_item_name(item_id)
	button.custom_minimum_size = ITEM_SIZE
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color.BLACK)
	button.add_theme_color_override("font_hover_color", Color.BLACK)
	button.add_theme_color_override("font_pressed_color", Color.BLACK)
	var color: Color = ItemDB.get_color(item_id)
	button.add_theme_stylebox_override("normal", _item_style(color, Color(0.1, 0.1, 0.1)))
	button.add_theme_stylebox_override("hover", _item_style(color.lightened(0.2), Color.WHITE))
	button.add_theme_stylebox_override("pressed", _item_style(color.darkened(0.2), Color.WHITE))
	button.gui_input.connect(_on_item_gui_input.bind(item_id))
	button.mouse_entered.connect(func() -> void: _hovered_item = item_id)
	button.mouse_exited.connect(func() -> void:
		if _hovered_item == item_id:
			_hovered_item = "")
	return button


func _item_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	return style


func _on_item_gui_input(event: InputEvent, item_id: String) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or GameState.is_busy():
		return
	if mb.button_index == MOUSE_BUTTON_LEFT:
		click_item(item_id)
	elif mb.button_index == MOUSE_BUTTON_RIGHT:
		look_at_item(item_id)
	bar.accept_event()


## Left click on an inventory item (public so tests can call it).
func click_item(item_id: String) -> void:
	var held: String = GameState.selected_item
	if held == "":
		GameState.select_item(item_id) # Pick it up on the cursor.
	elif held == item_id:
		GameState.clear_selection() # Clicking the same item puts it back.
	else:
		var line: String = GameState.combine_items(held, item_id)
		GameState.clear_selection()
		GameState.say_requested.emit(line)


## Right click on an inventory item.
func look_at_item(item_id: String) -> void:
	GameState.clear_selection()
	GameState.say_requested.emit(ItemDB.get_look_text(item_id))


func _on_selected_item_changed(item_id: String) -> void:
	if item_id != "":
		cursor_item_label.text = ItemDB.get_item_name(item_id)
		cursor_item.add_theme_stylebox_override("panel", _item_style(ItemDB.get_color(item_id), Color.WHITE))
	# Highlight the held item in the bar.
	for button: Node in item_row.get_children():
		(button as Button).modulate = Color(1, 1, 1, 0.45) if button.name == item_id else Color.WHITE
