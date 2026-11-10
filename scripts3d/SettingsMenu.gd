extends CanvasLayer
class_name SettingsMenu

var panel: PanelContainer
var is_open := false
var waiting_action := ""
var waiting_button: Button

func _ready() -> void:
	layer = 10
	panel = PanelContainer.new()
	panel.anchor_left = 0.055
	panel.anchor_top = 0.045
	panel.anchor_right = 0.945
	panel.anchor_bottom = 0.955
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(panel)
	panel.visible = false

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	var title := Label.new()
	title.text = "CONFIGURACIÓN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.78, 0.64, 0.84, 0.96))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.035, 0.92))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_font_size_override("font_size", 26)
	layout.add_child(title)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(tabs)
	_build_general_tab(tabs)
	_build_controls_tab(tabs)

	var back_btn := _make_menu_button("GUARDAR Y VOLVER")
	back_btn.custom_minimum_size = Vector2(0, 46)
	back_btn.pressed.connect(_on_back)
	layout.add_child(back_btn)

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.009, 0.018, 0.9)
	style.border_color = Color(0.34, 0.23, 0.40, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
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

func _build_general_tab(tabs: TabContainer) -> void:
	var page := MarginContainer.new()
	page.name = "General"
	page.add_theme_constant_override("margin_left", 24)
	page.add_theme_constant_override("margin_right", 24)
	page.add_theme_constant_override("margin_top", 24)
	page.add_theme_constant_override("margin_bottom", 24)
	tabs.add_child(page)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	page.add_child(layout)

	var volume_title := Label.new()
	volume_title.text = "Volumen general"
	volume_title.add_theme_color_override("font_color", Color(0.92, 0.89, 0.94, 1.0))
	volume_title.add_theme_font_size_override("font_size", 15)
	layout.add_child(volume_title)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 1
	volume.value = round(GameManager.master_volume * 100.0)
	volume.value_changed.connect(_on_volume_changed)
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(volume)

	var fullscreen := CheckBox.new()
	fullscreen.text = "Pantalla completa"
	fullscreen.button_pressed = GameManager.fullscreen
	fullscreen.toggled.connect(_on_fullscreen_toggled)
	fullscreen.add_theme_color_override("font_color", Color(0.92, 0.89, 0.94, 1.0))
	fullscreen.add_theme_font_size_override("font_size", 15)
	layout.add_child(fullscreen)

	var description := Label.new()
	description.text = "Las preferencias y las reasignaciones de controles se guardan en este dispositivo."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", Color(0.77, 0.67, 0.83, 0.95))
	description.add_theme_font_size_override("font_size", 13)
	layout.add_child(description)

func _build_controls_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "Controles"
	page.add_theme_constant_override("separation", 8)
	tabs.add_child(page)
	var instructions := Label.new()
	instructions.text = "Controles tipo tanque (Silent Hill / Resident Evil clásico): W/Stick arriba = adelante, S/Stick abajo = atrás, A/Stick izq = girar izq, D/Stick der = girar der. Correr = Shift / L3 / botón CORRER (mantener). Selecciona Reasignar y pulsa una tecla o botón del mando; para asignar un eje, mueve el stick."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.add_theme_color_override("font_color", Color(0.77, 0.67, 0.83, 0.95))
	instructions.add_theme_font_size_override("font_size", 13)
	page.add_child(instructions)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 5)
	scroll.add_child(rows)
	for action in InputProfiles.ACTIONS:
		var row := HBoxContainer.new()
		row.name = "BindingRow_" + action
		row.add_to_group("input_binding_rows")
		row.set_meta("action", action)
		row.custom_minimum_size = Vector2(0, 48)
		row.add_theme_constant_override("separation", 12)
		rows.add_child(row)
		var name := Label.new()
		name.text = InputProfiles.get_action_title(action)
		name.custom_minimum_size = Vector2(210, 0)
		name.add_theme_color_override("font_color", Color(0.92, 0.89, 0.94, 1.0))
		name.add_theme_font_size_override("font_size", 14)
		row.add_child(name)
		var binding := Label.new()
		binding.name = "BindingLabel"
		binding.text = InputProfiles.get_action_label(action)
		binding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		binding.clip_text = true
		binding.add_theme_color_override("font_color", Color(0.77, 0.67, 0.83, 0.95))
		binding.add_theme_font_size_override("font_size", 13)
		row.add_child(binding)
		var change := _make_menu_button("Reasignar")
		change.name = "BindingButton"
		change.custom_minimum_size = Vector2(142, 42)
		change.pressed.connect(_begin_rebind.bind(action, change, binding))
		row.add_child(change)

	var reset := _make_menu_button("RESTAURAR CONTROLES PREDETERMINADOS")
	reset.custom_minimum_size = Vector2(0, 42)
	reset.pressed.connect(_reset_bindings)
	page.add_child(reset)

func _begin_rebind(action: String, button: Button, binding: Label) -> void:
	waiting_action = action
	waiting_button = button
	waiting_button.text = "Pulsa tecla o botón…"
	binding.text = "Esperando entrada…"

func _input(event: InputEvent) -> void:
	if waiting_action.is_empty():
		return
	var captured := false
	if event is InputEventKey and event.pressed and not event.echo:
		captured = InputProfiles.rebind(waiting_action, event)
	elif event is InputEventJoypadButton and event.pressed:
		captured = InputProfiles.rebind(waiting_action, event)
	elif event is InputEventJoypadMotion and absf(event.axis_value) >= 0.65:
		captured = InputProfiles.rebind(waiting_action, event)
	if captured:
		get_viewport().set_input_as_handled()
		_finish_rebind()

func _finish_rebind() -> void:
	if is_instance_valid(waiting_button):
		waiting_button.text = "Reasignar"
		var row := waiting_button.get_parent()
		var binding := row.get_node_or_null("BindingLabel") as Label
		if binding != null:
			binding.text = InputProfiles.get_action_label(waiting_action)
	waiting_action = ""
	waiting_button = null

func _reset_bindings() -> void:
	InputProfiles.restore_defaults()
	for row in get_tree().get_nodes_in_group("input_binding_rows"):
		var button := row.get_node_or_null("BindingButton") as Button
		var binding := row.get_node_or_null("BindingLabel") as Label
		if button != null:
			button.text = "Reasignar"
		if binding != null:
			binding.text = InputProfiles.get_action_label(String(row.get_meta("action")))
	waiting_action = ""
	waiting_button = null

func _on_volume_changed(value: float) -> void:
	GameManager.master_volume = value / 100.0
	GameManager.apply_settings()

func _on_fullscreen_toggled(pressed: bool) -> void:
	GameManager.fullscreen = pressed
	GameManager.apply_settings()

func _on_back() -> void:
	GameManager.save_settings()
	toggle()

func toggle() -> void:
	if waiting_action != "":
		waiting_action = ""
		waiting_button = null
	is_open = not is_open
	panel.visible = is_open
