extends Node

const BINDINGS_PATH := "user://input_bindings.cfg"
const BINDINGS_VERSION := 2
const ACTIONS := ["move_forward", "move_backward", "turn_left", "turn_right", "run", "crouch", "interact", "journal", "pause"]

const DEFAULT_BINDINGS := {
	"move_forward": [{"kind": "key", "code": KEY_W}, {"kind": "key", "code": KEY_UP}, {"kind": "axis", "axis": JOY_AXIS_LEFT_Y, "value": -1.0}],
	"move_backward": [{"kind": "key", "code": KEY_S}, {"kind": "key", "code": KEY_DOWN}, {"kind": "axis", "axis": JOY_AXIS_LEFT_Y, "value": 1.0}],
	"turn_left": [{"kind": "key", "code": KEY_A}, {"kind": "key", "code": KEY_LEFT}, {"kind": "axis", "axis": JOY_AXIS_LEFT_X, "value": -1.0}],
	"turn_right": [{"kind": "key", "code": KEY_D}, {"kind": "key", "code": KEY_RIGHT}, {"kind": "axis", "axis": JOY_AXIS_LEFT_X, "value": 1.0}],
	"run": [{"kind": "key", "code": KEY_SHIFT}, {"kind": "button", "button": JOY_BUTTON_LEFT_STICK}],
	"crouch": [{"kind": "key", "code": KEY_C}, {"kind": "button", "button": JOY_BUTTON_B}],
	"interact": [{"kind": "key", "code": KEY_E}, {"kind": "button", "button": JOY_BUTTON_A}],
	"journal": [{"kind": "key", "code": KEY_TAB}, {"kind": "button", "button": JOY_BUTTON_Y}],
	"pause": [{"kind": "key", "code": KEY_ESCAPE}, {"kind": "button", "button": JOY_BUTTON_START}]
}

const ACTION_LABELS := {
	"move_forward": "Avanzar",
	"move_backward": "Retroceder",
	"turn_left": "Girar a la izquierda",
	"turn_right": "Girar a la derecha",
	"run": "Correr",
	"crouch": "Agacharse",
	"interact": "Interactuar",
	"journal": "Diario",
	"pause": "Pausa"
}

var _config := ConfigFile.new()
var _custom_bindings: Dictionary = {}

func _ready() -> void:
	_register_actions()
	_add_ui_gamepad_defaults()
	_load_custom_bindings()

func _register_actions() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.22)
		else:
			InputMap.action_set_deadzone(action, 0.22)
		InputMap.action_erase_events(action)
		for data in DEFAULT_BINDINGS[action]:
			var event := _event_from_data(data)
			if event != null:
				InputMap.action_add_event(action, event)

func _add_ui_gamepad_defaults() -> void:
	var directions := {
		"ui_up": [{"kind": "axis", "axis": JOY_AXIS_LEFT_Y, "value": -1.0}, {"kind": "button", "button": JOY_BUTTON_DPAD_UP}],
		"ui_down": [{"kind": "axis", "axis": JOY_AXIS_LEFT_Y, "value": 1.0}, {"kind": "button", "button": JOY_BUTTON_DPAD_DOWN}],
		"ui_left": [{"kind": "axis", "axis": JOY_AXIS_LEFT_X, "value": -1.0}, {"kind": "button", "button": JOY_BUTTON_DPAD_LEFT}],
		"ui_right": [{"kind": "axis", "axis": JOY_AXIS_LEFT_X, "value": 1.0}, {"kind": "button", "button": JOY_BUTTON_DPAD_RIGHT}],
		"ui_accept": [{"kind": "button", "button": JOY_BUTTON_A}],
		"ui_cancel": [{"kind": "button", "button": JOY_BUTTON_B}]
	}
	for action in directions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for data in directions[action]:
			var event := _event_from_data(data)
			if event != null and not _contains_event(action, event):
				InputMap.action_add_event(action, event)

func _contains_event(action: String, candidate: InputEvent) -> bool:
	for event in InputMap.action_get_events(action):
		if event.as_text() == candidate.as_text():
			return true
	return false

func _load_custom_bindings() -> void:
	if _config.load(BINDINGS_PATH) != OK:
		return
	# Version migration: discard inverted bindings from v1
	var saved_version := int(_config.get_value("meta", "version", 0))
	if saved_version < BINDINGS_VERSION:
		print("[InputProfiles] Bindings version %d < %d, discarding inverted user bindings" % [saved_version, BINDINGS_VERSION])
		_config.clear()
		_config.save(BINDINGS_PATH)
		return
	for action in ACTIONS:
		var custom: Dictionary = _config.get_value("bindings", action, {})
		if typeof(custom) != TYPE_DICTIONARY:
			continue
		for kind in custom:
			var event := _event_from_data(custom[kind])
			if event == null:
				continue
			_replace_event_kind(action, kind, event)
		_custom_bindings[action] = custom

func rebind(action: String, incoming: InputEvent) -> bool:
	if not ACTIONS.has(action):
		return false
	var event := incoming.duplicate() as InputEvent
	var kind := _event_kind(event)
	if kind == "":
		return false
	if event is InputEventKey:
		event.pressed = false
		event.echo = false
	elif event is InputEventJoypadButton:
		event.pressed = false
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		event.device = -1
	_replace_event_kind(action, kind, event)
	var custom: Dictionary = _custom_bindings.get(action, {}).duplicate(true)
	custom[kind] = _data_from_event(event)
	_custom_bindings[action] = custom
	_config.set_value("bindings", action, custom)
	_config.set_value("meta", "version", BINDINGS_VERSION)
	_config.save(BINDINGS_PATH)
	return true

func restore_defaults() -> void:
	_custom_bindings.clear()
	for action in ACTIONS:
		InputMap.action_erase_events(action)
		for data in DEFAULT_BINDINGS[action]:
			var event := _event_from_data(data)
			if event != null:
				InputMap.action_add_event(action, event)
	_config.clear()
	_config.set_value("meta", "version", BINDINGS_VERSION)
	_config.save(BINDINGS_PATH)

func get_action_label(action: String) -> String:
	var keyboard: Array[String] = []
	var controller: Array[String] = []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_label := event.as_text().replace(" (Physical)", "")
			if not keyboard.has(key_label):
				keyboard.append(key_label)
		elif event is InputEventJoypadButton:
			controller.append(_button_label(event.button_index))
		elif event is InputEventJoypadMotion:
			controller.append(_axis_label(event.axis, event.axis_value))
	var parts: Array[String] = []
	if not keyboard.is_empty():
		parts.append("Teclado: " + " / ".join(keyboard))
	if not controller.is_empty():
		parts.append("Mando: " + " / ".join(controller))
	return "   ·   ".join(PackedStringArray(parts))

func get_action_title(action: String) -> String:
	return String(ACTION_LABELS.get(action, action.capitalize()))

func _replace_event_kind(action: String, kind: String, replacement: InputEvent) -> void:
	for event in InputMap.action_get_events(action).duplicate():
		if _event_kind(event) == kind:
			InputMap.action_erase_event(action, event)
	InputMap.action_add_event(action, replacement)

func _event_kind(event: InputEvent) -> String:
	if event is InputEventKey:
		return "keyboard"
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return "joypad"
	return ""

func _event_from_data(data: Dictionary) -> InputEvent:
	match String(data.get("kind", "")):
		"key":
			var event := InputEventKey.new()
			event.physical_keycode = int(data.get("code", 0))
			event.keycode = int(data.get("keycode", event.physical_keycode))
			return event
		"button":
			var event := InputEventJoypadButton.new()
			event.button_index = int(data.get("button", 0))
			event.device = -1
			return event
		"axis":
			var event := InputEventJoypadMotion.new()
			event.axis = int(data.get("axis", 0))
			event.axis_value = float(data.get("value", 0.0))
			event.device = -1
			return event
	return null

func _data_from_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key := event as InputEventKey
		var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
		return {"kind": "key", "code": code, "keycode": key.keycode}
	if event is InputEventJoypadButton:
		return {"kind": "button", "button": event.button_index}
	if event is InputEventJoypadMotion:
		return {"kind": "axis", "axis": event.axis, "value": signf(event.axis_value)}
	return {}

func _button_label(button: int) -> String:
	match button:
		JOY_BUTTON_A: return "A / Cruz"
		JOY_BUTTON_B: return "B / Círculo"
		JOY_BUTTON_X: return "X / Cuadrado"
		JOY_BUTTON_Y: return "Y / Triángulo"
		JOY_BUTTON_LEFT_STICK: return "Pulsar stick izq."
		JOY_BUTTON_START: return "Start / Menú"
		_: return "Botón " + str(button)

func _axis_label(axis: int, value: float) -> String:
	var direction := "arriba" if value < 0.0 else "abajo"
	match axis:
		JOY_AXIS_LEFT_X: return "Stick izq. " + ("izq." if value < 0.0 else "der.")
		JOY_AXIS_LEFT_Y: return "Stick izq. " + direction
		_: return "Eje " + str(axis) + " " + direction
