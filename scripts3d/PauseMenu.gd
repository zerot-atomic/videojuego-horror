extends CanvasLayer
class_name PauseMenu

var panel
var is_open := false
var settings_menu

func _ready():
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 340)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -160
	panel.offset_top = -170
	panel.offset_right = 160
	panel.offset_bottom = 170
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(panel)
	panel.visible = false

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.92, 0.89, 0.94, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.035, 0.92))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 1)
	rule.color = Color(0.55, 0.39, 0.63, 0.62)
	vbox.add_child(rule)

	var resume_btn = _make_menu_button("REANUDAR")
	resume_btn.connect("pressed", Callable(self, "toggle"))
	vbox.add_child(resume_btn)

	var save_btn = _make_menu_button("GUARDAR PARTIDA")
	save_btn.connect("pressed", Callable(GameManager, "save_game"))
	vbox.add_child(save_btn)

	var options_btn = _make_menu_button("OPCIONES")
	options_btn.connect("pressed", Callable(self, "_on_options"))
	vbox.add_child(options_btn)

	var menu_btn = _make_menu_button("MENÚ PRINCIPAL")
	menu_btn.connect("pressed", Callable(self, "_go_to_menu"))
	vbox.add_child(menu_btn)

	settings_menu = SettingsMenu.new()
	add_child(settings_menu)

func _make_menu_button(label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(0.96, 0.94, 0.98, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 1.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.88, 0.78, 0.94, 1.0))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.07, 0.05, 0.09, 0.95)
	normal.border_color = Color(0.35, 0.27, 0.42, 0.92)
	normal.set_border_width_all(1)
	normal.content_margin_left = 15
	normal.content_margin_right = 15
	button.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.18, 0.12, 0.22, 0.98)
	hover.border_color = Color(0.72, 0.52, 0.82, 0.98)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.28, 0.18, 0.34, 0.99)
	pressed.border_color = Color(0.80, 0.62, 0.88, 1.0)
	button.add_theme_stylebox_override("pressed", pressed)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.04, 0.035, 0.05, 0.8)
	disabled.border_color = Color(0.18, 0.15, 0.2, 0.8)
	button.add_theme_stylebox_override("disabled", disabled)
	return button

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.009, 0.018, 0.95)
	style.border_color = Color(0.55, 0.39, 0.63, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style

func _on_options():
	settings_menu.toggle()

func _go_to_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes3d/MainMenu3D.tscn")

func toggle():
	is_open = not is_open
	panel.visible = is_open
	get_tree().paused = is_open
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if is_open else Input.MOUSE_MODE_HIDDEN)