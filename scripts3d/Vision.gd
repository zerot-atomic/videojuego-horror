extends Node
class_name Vision

var _leaving := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	_build_vision_ui()

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.009, 0.018, 0.92)
	style.border_color = Color(0.34, 0.23, 0.40, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 24
	style.content_margin_top = 20
	style.content_margin_right = 24
	style.content_margin_bottom = 20
	return style

func _make_label_style(label: Label, size: int, color: Color = Color(0.92, 0.89, 0.94, 1.0)) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)

func _build_vision_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var bg := ColorRect.new()
	bg.color = Color(0.006, 0.004, 0.012, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	canvas.add_child(margin)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	margin.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var clue = GameManager.pending_vision
	var character_id := String(clue.get("character", ""))

	var title := Label.new()
	title.text = "VISIÓN DE PERSONAJE: " + character_id.capitalize()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_make_label_style(title, 24, Color(0.78, 0.64, 0.84, 0.96))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.035, 0.92))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(title)

	var portrait_path := "res://art3d/characters_portraits/%s.png" % character_id
	if character_id != "" and ResourceLoader.exists(portrait_path):
		var portrait := TextureRect.new()
		portrait.texture = load(portrait_path)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = Vector2(0, 180)
		portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(portrait)

	var body_scroll := ScrollContainer.new()
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(body_scroll)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	body_scroll.add_child(body)

	var text := Label.new()
	text.text = String(clue.get("vision_text", ""))
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_make_label_style(text, 16, Color(0.92, 0.89, 0.94, 0.95))
	body.add_child(text)

	var vision_line := String(clue.get("vision_line", ""))
	if vision_line != "":
		var line := Label.new()
		line.text = "— «" + vision_line + "»"
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_make_label_style(line, 18, Color(0.78, 0.64, 0.84, 0.95))
		body.add_child(line)

	if _is_mobile_platform():
		var continue_button := _make_continue_button()
		continue_button.pressed.connect(_continue_from_vision)
		vbox.add_child(continue_button)
	else:
		var hint := Label.new()
		hint.text = "Pulsa ENTER o A para continuar"
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_make_label_style(hint, 12, Color(0.62, 0.57, 0.66, 0.82))
		vbox.add_child(hint)

func _make_continue_button() -> Button:
	var button := Button.new()
	button.text = "CONTINUAR"
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.92, 0.89, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.82, 0.70, 0.91, 1.0))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.055, 0.043, 0.068, 0.92)
	normal.border_color = Color(0.27, 0.21, 0.32, 0.85)
	normal.set_border_width_all(1)
	normal.content_margin_left = 15
	normal.content_margin_right = 15
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

func _is_mobile_platform() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_continue_from_vision()

func _continue_from_vision() -> void:
	if _leaving:
		return
	_leaving = true
	get_tree().paused = false
	var next_scene: String = GameManager.ZONE_SCENES.get(GameManager.current_zone_id, "")
	if next_scene != "":
		get_tree().change_scene_to_file(next_scene)