extends CanvasLayer
class_name Journal

var list_label
var panel
var is_open := false

func _ready():
	layer = 6

	panel = PanelContainer.new()
	panel.anchor_left = 0.07
	panel.anchor_top = 0.08
	panel.anchor_right = 0.93
	panel.anchor_bottom = 0.92
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(panel)
	panel.visible = false

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var title = Label.new()
	title.text = "DIARIO DE PISTAS"
	title.add_theme_color_override("font_color", Color(0.78, 0.64, 0.84, 0.96))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.035, 0.92))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_button := _make_menu_button("CERRAR")
	close_button.custom_minimum_size = Vector2(120, 44)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(_close_from_button)
	header.add_child(close_button)

	list_label = RichTextLabel.new()
	list_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_label.bbcode_enabled = true
	list_label.add_theme_color_override("font_color", Color(0.92, 0.89, 0.94, 1.0))
	list_label.add_theme_font_size_override("font_size", 15)
	list_label.add_theme_color_override("font_color", Color(0.92, 0.89, 0.94, 1.0))
	vbox.add_child(list_label)

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.009, 0.018, 0.96)
	style.border_color = Color(0.45, 0.32, 0.52, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 24
	style.content_margin_right = 24
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

func refresh():
	var text = ""
	for entry in GameManager.journal_entries:
		text += "[b]%s[/b]\n%s\n\n" % [entry.name, entry.description]
	if text == "":
		text = "[i]Aún no has encontrado ninguna pista.[/i]"

	if GameManager.inventory_entries.size() > 0:
		text += "\n[b]OBJETOS[/b]\n"
		for item in GameManager.inventory_entries:
			text += "[b]%s[/b]\n%s\n\n" % [item.name, item.description]

	list_label.text = text

func toggle():
	is_open = not is_open
	panel.visible = is_open
	if is_open:
		refresh()

func _close_from_button() -> void:
	if is_open:
		GameManager.toggle_journal()