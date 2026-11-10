extends Node
class_name MainMenu

var settings_menu
var difficulty_layer: CanvasLayer
var title_root: Control
var menu_root: Control
var intro_cover: ColorRect
var background: TextureRect
var tagline_label: Label
var _tagline_rng := RandomNumberGenerator.new()
var _tagline_elapsed := 0.0
var _tagline_interval := 900.0

const TITLE_IMAGE := "res://art3d/backgrounds/title_farm_purple.png"
const TAGLINE_CONFIG := "user://menu_tagline.cfg"
const TAGLINES: Array[String] = [
	"La tierra responde. La granja no.",
	"Algo acecha donde termina la luz.",
	"El color no cayó del cielo: encontró la tierra.",
	"No mires el pozo demasiado tiempo.",
	"Lo que duerme bajo el campo ya conoce tu nombre.",
	"Las ventanas están vacías. Alguien sigue mirando.",
	"No todas las voces vienen de la casa.",
	"La cosecha empezó antes de que llegaras.",
	"Bajo las raíces, algo sigue respirando.",
	"Si oyes que te llaman, no contestes."
]

func _ready() -> void:
	_tagline_rng.randomize()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = false
	MusicManager.play("fondo")

	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	_build_animated_backdrop(canvas)
	_build_title_and_menu(canvas)

	settings_menu = SettingsMenu.new()
	add_child(settings_menu)
	_build_difficulty_selector()

	intro_cover = ColorRect.new()
	intro_cover.color = Color(0.006, 0.004, 0.012, 1.0)
	intro_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(intro_cover)
	await get_tree().process_frame
	background.pivot_offset = background.size * 0.5
	_start_intro_animation()

func _build_animated_backdrop(canvas: CanvasLayer) -> void:
	background = TextureRect.new()
	background.name = "PortadaAnimada"
	background.texture = load(TITLE_IMAGE)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)

	var grade := ColorRect.new()
	grade.name = "GradeCinematografico"
	grade.color = Color(0.025, 0.012, 0.035, 0.20)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(grade)

	var cosmic_glow := ColorRect.new()
	cosmic_glow.name = "ResplandorCosmico"
	cosmic_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cosmic_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var glow_shader := Shader.new()
	glow_shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 center = vec2(0.735, 0.245);
	float d = distance(UV, center);
	float pulse = 0.72 + 0.28 * sin(TIME * 0.72);
	float glow = exp(-d * 13.0) * pulse * 0.115;
	COLOR = vec4(0.70, 0.36, 0.94, glow);
}
"""
	var glow_material := ShaderMaterial.new()
	glow_material.shader = glow_shader
	cosmic_glow.material = glow_material
	canvas.add_child(cosmic_glow)

	var mist := ColorRect.new()
	mist.name = "NieblaEnMovimiento"
	mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mist.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mist_shader := Shader.new()
	mist_shader.code = """
shader_type canvas_item;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise21(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 p = UV * vec2(5.0, 2.4);
	p.x += TIME * 0.035;
	p.y += sin(UV.x * 5.0 + TIME * 0.12) * 0.16;
	float n = noise21(p) * 0.65 + noise21(p * 2.1 + vec2(7.0, 3.0)) * 0.35;
	float band = 1.0 - smoothstep(0.53, 0.96, abs(UV.y - 0.69));
	float wisps = smoothstep(0.48, 0.78, n + sin(UV.x * 16.0 + TIME * 0.1) * 0.045);
	float alpha = band * wisps * 0.105;
	COLOR = vec4(0.56, 0.49, 0.68, alpha);
}
"""
	var mist_material := ShaderMaterial.new()
	mist_material.shader = mist_shader
	mist.material = mist_material
	canvas.add_child(mist)

func _build_title_and_menu(canvas: CanvasLayer) -> void:
	title_root = Control.new()
	title_root.name = "TituloIntro"
	title_root.anchor_left = 0.055
	title_root.anchor_top = 0.095
	title_root.anchor_right = 0.62
	title_root.anchor_bottom = 0.40
	title_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(title_root)

	var title_layout := VBoxContainer.new()
	title_layout.add_theme_constant_override("separation", 8)
	title_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_root.add_child(title_layout)

	var eyebrow := Label.new()
	eyebrow.text = "UN RELATO DE HORROR CÓSMICO"
	eyebrow.add_theme_color_override("font_color", Color(0.78, 0.64, 0.84, 0.96))
	eyebrow.add_theme_font_size_override("font_size", 16)
	title_layout.add_child(eyebrow)

	var title := Label.new()
	title.text = "LA COSECHA\nDEL COLOR"
	title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.96, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.035, 0.92))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_constant_override("line_spacing", -5)
	title_layout.add_child(title)

	tagline_label = Label.new()
	tagline_label.text = "La tierra responde. La granja no."
	tagline_label.add_theme_color_override("font_color", Color(0.82, 0.78, 0.84, 0.95))
	tagline_label.add_theme_font_size_override("font_size", 19)
	title_layout.add_child(tagline_label)
	_set_random_tagline(false)

	menu_root = Control.new()
	menu_root.name = "MenuIntro"
	menu_root.anchor_left = 0.70
	menu_root.anchor_top = 0.50
	menu_root.anchor_right = 0.96
	menu_root.anchor_bottom = 0.95
	canvas.add_child(menu_root)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.012, 0.009, 0.018, 0.78)
	panel_style.border_color = Color(0.34, 0.23, 0.40, 0.78)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(2)
	panel_style.content_margin_left = 22
	panel_style.content_margin_right = 22
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", panel_style)
	menu_root.add_child(panel)

	var menu_layout := VBoxContainer.new()
	menu_layout.add_theme_constant_override("separation", 10)
	panel.add_child(menu_layout)

	var menu_heading := Label.new()
	menu_heading.text = "INVESTIGACIÓN"
	menu_heading.add_theme_color_override("font_color", Color(0.77, 0.67, 0.83, 0.95))
	menu_heading.add_theme_font_size_override("font_size", 13)
	menu_layout.add_child(menu_heading)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 1)
	rule.color = Color(0.55, 0.39, 0.63, 0.62)
	menu_layout.add_child(rule)

	var new_btn := _make_menu_button("NUEVA PARTIDA")
	new_btn.connect("pressed", Callable(self, "_show_difficulty_selector"))
	menu_layout.add_child(new_btn)

	var load_btn := _make_menu_button("CARGAR PARTIDA")
	load_btn.disabled = not GameManager.has_save()
	load_btn.connect("pressed", Callable(GameManager, "load_game"))
	menu_layout.add_child(load_btn)

	var options_btn := _make_menu_button("OPCIONES")
	options_btn.connect("pressed", Callable(self, "_on_options"))
	menu_layout.add_child(options_btn)

	var credits_btn := _make_menu_button("CRÉDITOS")
	credits_btn.connect("pressed", Callable(self, "_on_credits"))
	menu_layout.add_child(credits_btn)

	var quit_btn := _make_menu_button("SALIR")
	quit_btn.connect("pressed", Callable(get_tree(), "quit"))
	menu_layout.add_child(quit_btn)

	var footer := Label.new()
	footer.text = "UNA INTERPRETACIÓN LIBRE DE H. P. LOVECRAFT"
	footer.add_theme_color_override("font_color", Color(0.62, 0.57, 0.66, 0.82))
	footer.add_theme_font_size_override("font_size", 10)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_layout.add_child(footer)

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

func _start_intro_animation() -> void:
	background.scale = Vector2.ONE
	title_root.modulate = Color(1, 1, 1, 0)
	menu_root.modulate = Color(1, 1, 1, 0)
	intro_cover.modulate = Color(1, 1, 1, 1)

	var opening := create_tween()
	opening.set_parallel(true)
	opening.tween_property(intro_cover, "modulate:a", 0.0, 2.2).set_delay(0.55)
	opening.tween_property(background, "scale", Vector2(1.055, 1.055), 13.0).set_delay(0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	opening.tween_property(title_root, "modulate:a", 1.0, 1.25).set_delay(1.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	opening.tween_property(menu_root, "modulate:a", 1.0, 1.0).set_delay(2.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	opening.chain().tween_property(background, "scale", Vector2(1.0, 1.0), 13.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	opening.set_loops()

func _process(delta: float) -> void:
	if tagline_label == null:
		return
	_tagline_elapsed += delta
	if _tagline_elapsed >= _tagline_interval:
		_set_random_tagline(true)

func _set_random_tagline(animated: bool) -> void:
	if tagline_label == null:
		return
	var config := ConfigFile.new()
	config.load(TAGLINE_CONFIG)
	var previous := String(config.get_value("intro", "last_tagline", ""))
	var choices: Array[String] = []
	for line in TAGLINES:
		if line != previous:
			choices.append(line)
	if choices.is_empty():
		choices = TAGLINES.duplicate()
	var selected: String = choices[_tagline_rng.randi_range(0, choices.size() - 1)]
	config.set_value("intro", "last_tagline", selected)
	config.save(TAGLINE_CONFIG)
	_tagline_elapsed = 0.0
	_tagline_interval = float(_tagline_rng.randi_range(15, 30) * 60)
	if not animated:
		tagline_label.text = selected
		return
	var tween := create_tween()
	tween.tween_property(tagline_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void: tagline_label.text = selected)
	tween.tween_property(tagline_label, "modulate:a", 1.0, 0.4)

func _build_difficulty_selector() -> void:
	difficulty_layer = CanvasLayer.new()
	difficulty_layer.layer = 20
	add_child(difficulty_layer)
	difficulty_layer.visible = false
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.012, 0.02, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	difficulty_layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	difficulty_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 0)
	center.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)
	var title := Label.new()
	title.text = "ELIGE TU DESCENSO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	var intro := Label.new()
	intro.text = "La dificultad cambia la cordura, la corrupción y la presión del perseguidor."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(intro)
	for id in ["story", "normal", "hard", "lovecraft"]:
		var profile: Dictionary = GameManager.DIFFICULTIES[id]
		var description := Label.new()
		description.text = String(profile.description)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		layout.add_child(description)
		var choice := Button.new()
		choice.text = String(profile.name)
		choice.custom_minimum_size = Vector2(560, 42)
		choice.connect("pressed", Callable(self, "_start_difficulty").bind(id))
		layout.add_child(choice)
	var back := Button.new()
	back.text = "Volver"
	back.custom_minimum_size = Vector2(220, 42)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.connect("pressed", Callable(self, "_hide_difficulty_selector"))
	layout.add_child(back)

func _show_difficulty_selector() -> void:
	difficulty_layer.visible = true

func _hide_difficulty_selector() -> void:
	difficulty_layer.visible = false

func _start_difficulty(id: String) -> void:
	difficulty_layer.visible = false
	GameManager.new_game(id)

func _on_options() -> void:
	settings_menu.toggle()

func _on_credits() -> void:
	get_tree().change_scene_to_file("res://scenes3d/Credits3D.tscn")
