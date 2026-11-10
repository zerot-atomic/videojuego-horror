extends Node
class_name Ending

@export var is_good: bool = true

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = false
	MusicManager.play("bueno" if is_good else "malo", true, 2.0)

	var canvas = CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)

	var bg = TextureRect.new()
	bg.texture = load("res://art3d/backgrounds/pozo.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var grade := ColorRect.new()
	grade.name = "GradeCinematografico"
	grade.color = Color(0.025, 0.012, 0.035, 0.3)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(grade)

	var tint = ColorRect.new()
	tint.color = Color(0.06, 0.2, 0.12, 0.5) if is_good else Color(0.22, 0.06, 0.06, 0.5)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(tint)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 0)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var eyebrow = Label.new()
	eyebrow.text = "LA COSECHA DEL COLOR"
	eyebrow.add_theme_color_override("font_color", Color(0.78, 0.64, 0.84, 0.96))
	eyebrow.add_theme_font_size_override("font_size", 14)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(eyebrow)

	var title = Label.new()
	title.text = "FINAL BUENO — A TIEMPO" if is_good else "FINAL MALO — DEMASIADO TARDE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.96, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.035, 0.92))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var text = Label.new()
	if is_good:
		text.text = "El inspector reunió las piezas a tiempo y comprendió, al fin, qué le ocurrió a la familia Gardner."
	else:
		text.text = "El tiempo se agotó. El color terminó por consumir la granja, y con ella, cualquier respuesta."
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_color_override("font_color", Color(0.92, 0.89, 0.94, 0.95))
	text.add_theme_font_size_override("font_size", 16)
	vbox.add_child(text)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer2)

	var credits_btn = _make_menu_button("VER CRÉDITOS")
	credits_btn.connect("pressed", Callable(self, "_go_to_credits"))
	vbox.add_child(credits_btn)

	var menu_btn = _make_menu_button("VOLVER AL MENÚ PRINCIPAL")
	menu_btn.connect("pressed", Callable(self, "_go_to_menu"))
	vbox.add_child(menu_btn)

	var footer := Label.new()
	footer.text = "UNA INTERPRETACIÓN LIBRE DE H. P. LOVECRAFT"
	footer.add_theme_color_override("font_color", Color(0.62, 0.57, 0.66, 0.82))
	footer.add_theme_font_size_override("font_size", 10)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(footer)

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.009, 0.018, 0.88)
	style.border_color = Color(0.34, 0.23, 0.40, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style

func _make_menu_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 15)
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

func _go_to_menu():
	get_tree().change_scene_to_file("res://scenes3d/MainMenu3D.tscn")

func _go_to_credits():
	get_tree().change_scene_to_file("res://scenes3d/Credits3D.tscn")