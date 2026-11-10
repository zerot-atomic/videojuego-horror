extends Control
class_name TouchStick

signal vector_changed(value: Vector2)

@export var radius := 78.0
var _pointer_id := -1
var _value := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(radius * 2.5, radius * 2.5)

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, radius, Color(0.012, 0.009, 0.02, 0.30))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.78, 0.68, 0.86, 0.52), 2.0, true)
	draw_circle(center + _value * radius, radius * 0.38, Color(0.42, 0.28, 0.52, 0.78))
	draw_arc(center + _value * radius, radius * 0.38, 0.0, TAU, 48, Color(0.91, 0.84, 0.96, 0.66), 2.0, true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _pointer_id == -1:
			_pointer_id = event.index
			_update_from_position(_screen_to_local(event.position))
		elif not event.pressed and event.index == _pointer_id:
			_release_stick()
		accept_event()
	elif event is InputEventScreenDrag and event.index == _pointer_id:
		_update_from_position(_screen_to_local(event.position))
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _pointer_id == -1:
			_pointer_id = -2
			_update_from_position(event.position)
		elif not event.pressed and _pointer_id == -2:
			_release_stick()
		accept_event()
	elif event is InputEventMouseMotion and _pointer_id == -2 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_from_position(event.position)
		accept_event()

func _update_from_position(pointer: Vector2) -> void:
	var offset := pointer - size * 0.5
	_value = (offset / radius).limit_length(1.0)
	vector_changed.emit(_value)
	queue_redraw()

func _screen_to_local(viewport_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_position

func _release_stick() -> void:
	_pointer_id = -1
	_value = Vector2.ZERO
	vector_changed.emit(Vector2.ZERO)
	queue_redraw()
