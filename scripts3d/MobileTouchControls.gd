extends CanvasLayer
class_name MobileTouchControls

signal action_pressed(action: String)

const MOVE_ACTIONS := ["turn_left", "turn_right", "move_forward", "move_backward"]
var _held_actions: Array[String] = []

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_stick(root)
	_build_action_pad(root)

func _process(_delta: float) -> void:
	var should_show := not get_tree().paused and not GameManager.journal_open
	if visible and not should_show:
		_release_movement()
	visible = should_show

func _build_stick(root: Control) -> void:
	var stick := TouchStick.new()
	stick.name = "JoystickMovimiento"
	stick.anchor_left = 0.025
	stick.anchor_top = 0.66
	stick.anchor_right = 0.30
	stick.anchor_bottom = 0.98
	stick.vector_changed.connect(_set_movement_vector)
	root.add_child(stick)

func _build_action_pad(root: Control) -> void:
	var actions := GridContainer.new()
	actions.name = "AccionesTactiles"
	actions.columns = 2
	actions.anchor_left = 0.715
	actions.anchor_top = 0.70
	actions.anchor_right = 0.975
	actions.anchor_bottom = 0.97
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	root.add_child(actions)
	actions.add_child(_make_action_button("USAR", "interact"))
	actions.add_child(_make_hold_button("CORRER", "run"))
	actions.add_child(_make_action_button("AGACHARSE", "crouch"))
	actions.add_child(_make_action_button("DIARIO", "journal"))
	var pause := _make_action_button("PAUSA", "pause")
	pause.anchor_left = 0.88
	pause.anchor_top = 0.035
	pause.anchor_right = 0.975
	pause.anchor_bottom = 0.12
	root.add_child(pause)

func _set_movement_vector(value: Vector2) -> void:
	for action in MOVE_ACTIONS:
		Input.action_release(action)
		_held_actions.erase(action)
	if value.x < -0.04:
		Input.action_press("turn_left", -value.x)
		_track_action("turn_left")
	elif value.x > 0.04:
		Input.action_press("turn_right", value.x)
		_track_action("turn_right")
	if value.y < -0.04:
		Input.action_press("move_forward", -value.y)
		_track_action("move_forward")
	elif value.y > 0.04:
		Input.action_press("move_backward", value.y)
		_track_action("move_backward")

func _release_movement() -> void:
	for action in _held_actions:
		Input.action_release(action)
	_held_actions.clear()

func _make_hold_button(label: String, action: String) -> Button:
	var button := _make_button(label)
	button.button_down.connect(_hold_action.bind(action))
	button.button_up.connect(_release_action.bind(action))
	return button

func _make_action_button(label: String, action: String) -> Button:
	var button := _make_button(label)
	button.pressed.connect(_emit_action.bind(action))
	return button

func _make_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(74, 62)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(0.92, 0.89, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.82, 0.70, 0.91, 1.0))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.055, 0.043, 0.068, 0.92)
	normal.border_color = Color(0.27, 0.21, 0.32, 0.85)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(18)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.15, 0.10, 0.18, 0.97)
	hover.border_color = Color(0.64, 0.43, 0.73, 0.96)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.22, 0.13, 0.27, 0.98)
	pressed.border_color = Color(0.72, 0.52, 0.82, 1.0)
	button.add_theme_stylebox_override("pressed", pressed)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.035, 0.03, 0.04, 0.74)
	disabled.border_color = Color(0.14, 0.12, 0.15, 0.72)
	button.add_theme_stylebox_override("disabled", disabled)
	return button

func _hold_action(action: String) -> void:
	Input.action_press(action)
	_track_action(action)

func _track_action(action: String) -> void:
	if not _held_actions.has(action):
		_held_actions.append(action)

func _release_action(action: String) -> void:
	Input.action_release(action)
	_held_actions.erase(action)

func _emit_action(action: String) -> void:
	action_pressed.emit(action)
