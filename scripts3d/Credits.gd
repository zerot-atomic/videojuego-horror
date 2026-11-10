extends Node
class_name Credits
# ============================================================
# Créditos cinematográficos: imágenes con movimiento lento
# (efecto Ken Burns), fundidos cruzados, una frase de la historia
# por imagen y los créditos reales del proyecto.
#
# Toda la línea de tiempo se calcula en _process() a partir de un
# solo reloj (time). Así nunca hay dos bloques de texto a la vez
# y no depende de Tween (los retrasos de Tween en Godot 3.1
# dejaban todos los textos visibles y encimados).
#
# Esc / Enter / Espacio: saltar.
# Para cambiar textos o el orden, edita la lista SHOTS.
# ============================================================

const VIEW := Vector2(1672, 941)
const SHOT_TIME := 9.0      # duración de cada imagen (incluye el fundido)
const XFADE := 1.4          # fundido cruzado entre imágenes
const STEP := 7.6           # SHOT_TIME - XFADE: cada cuánto entra una imagen nueva
const DIR := "res://art3d/credits/"
const FONT_REG := "res://art3d/fonts/LiberationSerif-Regular.ttf"
const FONT_ITA := "res://art3d/fonts/LiberationSerif-Italic.ttf"

# img, caption (frase de la historia), role/name (crédito real),
# z0/z1 (zoom inicial/final), o0/o1 (paneo -1..1 en x,y)
var SHOTS := [
	{"img": "c01_impacto.jpg", "title": "LA COSECHA DEL COLOR", "subtitle": "Un relato de horror cósmico en una granja aislada",
	 "caption": "Una noche, algo cayó del cielo.",
	 "z0": 1.0, "z1": 1.06, "o0": Vector2(-1, 0), "o1": Vector2(1, 0)},
	{"img": "c02_piedra_a.jpg",
	 "caption": "Ningún instrumento logró clasificarla. Poco después, dejaron de responder.",
	 "role": "Inspirado libremente en", "name": "«El color que cayó del cielo», de H. P. Lovecraft",
	 "z0": 1.0, "z1": 1.06, "o0": Vector2(1, 0), "o1": Vector2(-1, 0)},
	{"img": "c03_piedra_b.jpg",
	 "caption": "Al calentar la muestra, se encogió hasta desaparecer.",
	 "role": "Diseño, guion y desarrollo", "name": "Carlos Fernando Martínez Hernández",
	 "z0": 1.0, "z1": 1.06, "o0": Vector2(-1, 0), "o1": Vector2(1, 0)},
	{"img": "c04_manzanas.jpg",
	 "caption": "La tierra dio frutos enormes, pero sabían a ceniza.",
	 "role": "Universidad Tecnológica de Puebla", "name": "Ingeniería en Desarrollo y Gestión de Software · Grupo 9C",
	 "z0": 1.0, "z1": 1.12, "o0": Vector2(-0.4, 0.2), "o1": Vector2(0.4, -0.2)},
	{"img": "c05_ventana_humo.jpg",
	 "caption": "De noche, los surcos brillaban como si retuvieran la luz.",
	 "role": "Motor de juego", "name": "Godot Engine",
	 "z0": 1.0, "z1": 1.12, "o0": Vector2(0, 0.3), "o1": Vector2(0, -0.3)},
	{"img": "c06_fotografia.jpg",
	 "caption": "En el último retrato, la familia sale movida, como si algo los hubiera hecho voltear.",
	 "role": "Música", "name": "Generada con Suno",
	 "z0": 1.12, "z1": 1.0, "o0": Vector2(-0.5, 0.3), "o1": Vector2(0.2, 0)},
	{"img": "c07_padre_establo.jpg",
	 "caption": "Nahum vio cómo su ganado se volvía gris y quebradizo.",
	 "role": "Arte, fondos y escenas", "name": "Generados con IA (Gemini y ChatGPT)",
	 "z0": 1.0, "z1": 1.12, "o0": Vector2(-0.5, 0), "o1": Vector2(0.3, 0)},
	{"img": "c08_madre_atico.jpg",
	 "caption": "Nabby ya solo miraba el círculo de luz sobre el piso del ático.",
	 "z0": 1.12, "z1": 1.0, "o0": Vector2(0.5, 0.2), "o1": Vector2(-0.2, 0)},
	{"img": "c09_hijo_bosque.jpg",
	 "caption": "Y el hijo se internó en el bosque, tras una luz que nadie más veía.",
	 "z0": 1.0, "z1": 1.14, "o0": Vector2(0, 0.3), "o1": Vector2(0, -0.1)},
	{"img": "c10_pozo_luz.jpg",
	 "caption": "Del pozo empezó a subir algo que no tenía nombre.",
	 "z0": 1.0, "z1": 1.14, "o0": Vector2(0.2, 0.4), "o1": Vector2(0, -0.2)},
	{"img": "c11_luz_al_cielo.jpg",
	 "caption": "La noche en que el color subió al cielo.",
	 "z0": 1.14, "z1": 1.0, "o0": Vector2(0.2, 0.5), "o1": Vector2(0, -0.2)},
	{"img": "c12_pozo_agrietado.jpg",
	 "caption": "Pero una parte se quedó, hundiéndose otra vez en la tierra.",
	 "z0": 1.0, "z1": 1.1, "o0": Vector2(0, 0), "o1": Vector2(0, 0.3)},
]


var time := 0.0
var finishing := false
var music_faded := false
var current_text_index := -1

var sprites := []
var infos := []
var starts := []
var text_labels := []

var title_lbl: Label
var sub_lbl: Label
var role_lbl: Label
var name_lbl: Label
var cap_lbl: Label
var thanks_lbl: Label
var whisper_lbl: Label
var end_black: ColorRect
var veil: ColorRect

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = false
	# Si vienen de un final, la música sigue; desde el menú entra la del clímax.
	if MusicManager.current != "bueno" and MusicManager.current != "malo":
		MusicManager.play("climax", true, 2.0)

	var world = CanvasLayer.new()
	world.layer = 0
	add_child(world)
	var fx = CanvasLayer.new()
	fx.layer = 1
	add_child(fx)
	var ui = CanvasLayer.new()
	ui.layer = 2
	add_child(ui)

	var black = ColorRect.new()
	black.color = Color(0, 0, 0, 1)
	black.size = VIEW
	world.add_child(black)

	for i in range(SHOTS.size()):
		_build_shot(SHOTS[i], i, world)

	_build_fx(fx)
	_build_text(ui)

func _build_shot(shot: Dictionary, index: int, world: CanvasLayer) -> void:
	starts.append(index * STEP)
	var tex = load(DIR + shot.img)
	if tex == null:
		sprites.append(null)
		infos.append({})
		return
	var sz = tex.get_size()
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.visible = false
	world.add_child(spr)
	sprites.append(spr)
	infos.append({
		"sz": sz,
		"s0": max(VIEW.x / sz.x, VIEW.y / sz.y),
		"z0": shot.get("z0", 1.0), "z1": shot.get("z1", 1.1),
		"o0": shot.get("o0", Vector2.ZERO), "o1": shot.get("o1", Vector2.ZERO),
	})

func _build_fx(fx: CanvasLayer) -> void:
	# Degradado inferior (franjas apiladas) + franja oscura para el texto.
	for i in range(14):
		var band = ColorRect.new()
		band.color = Color(0, 0, 0, 0.06)
		var y = 540.0 + i * 14.0
		band.position = Vector2(0, y)
		band.size = Vector2(VIEW.x, VIEW.y - y)
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fx.add_child(band)
	var strip = ColorRect.new()
	strip.color = Color(0, 0, 0, 0.55)
	strip.position = Vector2(0, 742)
	strip.size = Vector2(VIEW.x, VIEW.y - 742)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.add_child(strip)
	# Velo violeta-verdoso que respira muy despacio (el "color").
	veil = ColorRect.new()
	veil.color = Color(0.45, 0.15, 0.6, 0.0)
	veil.size = VIEW
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.add_child(veil)
	# Fundido a negro del final.
	end_black = ColorRect.new()
	end_black.color = Color(0, 0, 0, 1)
	end_black.size = VIEW
	end_black.modulate = Color(1, 1, 1, 0)
	end_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.add_child(end_black)

func _make_label(font_path: String, size: int, color: Color, pos: Vector2, width: float, height: float, center: bool, ui: CanvasLayer) -> Label:
	var lab = Label.new()
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lab.add_theme_color_override("font_color", color)
	lab.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.035, 0.92))
	lab.add_theme_constant_override("shadow_offset_x", 2)
	lab.add_theme_constant_override("shadow_offset_y", 3)
	# PARCHE PORT 4.x: en Godot 4 ya no existe FontFile.font_data ni
	# FontFile.size/outline_size — la fuente se carga directa (el .ttf YA
	# es un Font listo para usar) y el tamaño/contorno se ponen como
	# "theme overrides" sobre el Label, no sobre el recurso de fuente.
	if ResourceLoader.exists(font_path):
		var f = load(font_path)
		lab.add_theme_font_override("font", f)
		lab.add_theme_constant_override("outline_size", 2)
		lab.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lab.add_theme_font_size_override("font_size", size)
	lab.set_meta("base_size", size)
	lab.position = pos
	lab.size = Vector2(width, height)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	lab.modulate = Color(1, 1, 1, 0)
	ui.add_child(lab)
	return lab

func _build_text(ui: CanvasLayer) -> void:
	var cream = Color(0.97, 0.93, 0.85)
	var gold = Color(0.88, 0.75, 0.52)
	var lilac = Color(0.82, 0.74, 0.92)
	title_lbl = _make_label(FONT_REG, 96, cream, Vector2(0, 330), VIEW.x, 120, true, ui)
	sub_lbl = _make_label(FONT_ITA, 36, lilac, Vector2(0, 452), VIEW.x, 50, true, ui)
	role_lbl = _make_label(FONT_ITA, 30, gold, Vector2(110, 756), 1450, 40, false, ui)
	name_lbl = _make_label(FONT_REG, 44, cream, Vector2(110, 794), 1450, 60, false, ui)
	cap_lbl = _make_label(FONT_ITA, 30, Color(0.9, 0.88, 0.94), Vector2(0, 876), VIEW.x, 44, true, ui)
	text_labels = [title_lbl, sub_lbl, role_lbl, name_lbl, cap_lbl]

	thanks_lbl = _make_label(FONT_REG, 64, cream, Vector2(0, 390), VIEW.x, 90, true, ui)
	thanks_lbl.text = "Gracias por jugar"
	whisper_lbl = _make_label(FONT_ITA, 34, lilac, Vector2(0, 490), VIEW.x, 50, true, ui)
	whisper_lbl.text = "El color sigue ahí abajo."

	var hint = _make_label(FONT_ITA, 20, Color(1, 1, 1, 0.6), Vector2(VIEW.x - 280, 16), 260, 30, false, ui)
	hint.text = "Esc / Enter: saltar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.modulate = Color(1, 1, 1, 0.5)
	var asset_credit = _make_label(FONT_ITA, 17, Color(0.86, 0.82, 0.74, 0.82), Vector2(28, VIEW.y - 42), VIEW.x - 56, 32, false, ui)
	asset_credit.text = "PSX Horror Farm Kit Free by heyheythere - https://heyheythere.itch.io/psx-horror-farm-kit-free - CC BY 4.0"

func _set_text(lab: Label, text: String, max_w: float) -> void:
	# Ajusta el tamaño de letra para que el texto SIEMPRE quepa en una línea.
	# PARCHE PORT 4.x: el tamaño ya no vive en el recurso de fuente, se
	# mide pasando el tamaño como parámetro y se aplica con un override.
	lab.text = text
	var base = int(lab.get_meta("base_size"))
	var font = lab.get_theme_font("font")
	var final_size = base
	if font:
		var w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, base).x
		if w > max_w:
			final_size = int(max(14.0, floor(base * max_w / w)))
	lab.add_theme_font_size_override("font_size", final_size)

func _apply_shot_text(shot: Dictionary) -> void:
	var has_title = shot.has("title")
	title_lbl.visible = has_title
	sub_lbl.visible = has_title
	if has_title:
		_set_text(title_lbl, shot.title, 1560.0)
		_set_text(sub_lbl, shot.subtitle, 1400.0)
	var has_role = shot.has("role")
	role_lbl.visible = has_role
	name_lbl.visible = has_role
	if has_role:
		_set_text(role_lbl, shot.role, 1450.0)
		_set_text(name_lbl, shot.name, 1450.0)
	cap_lbl.position.y = 876.0 if has_role else 826.0
	_set_text(cap_lbl, shot.get("caption", ""), 1560.0)

func _pos_for(sz: Vector2, sc: float, off: Vector2) -> Vector2:
	# Esquina superior izquierda para mirar hacia 'off' (-1..1 en cada eje).
	var slack = sz * sc - VIEW
	return Vector2(-slack.x * (0.5 + 0.5 * off.x), -slack.y * (0.5 + 0.5 * off.y))

func _process(delta: float) -> void:
	if finishing:
		return
	time += delta
	_update_shots()
	_update_text()
	_update_end()
	_update_veil()

func _update_shots() -> void:
	for i in range(sprites.size()):
		var spr = sprites[i]
		if spr == null:
			continue
		var local = time - starts[i]
		if local < 0.0 or local > SHOT_TIME + 0.1:
			spr.visible = false
			continue
		var info = infos[i]
		var fade_in = 2.0 if i == 0 else XFADE
		var a = clamp(local / fade_in, 0.0, 1.0)
		var p = clamp(local / (SHOT_TIME + 1.0), 0.0, 1.0)
		var z = lerp(info.z0, info.z1, p)
		var off = info.o0.lerp(info.o1, p)
		var sc = info.s0 * z
		spr.visible = true
		spr.modulate = Color(1, 1, 1, a)
		spr.scale = Vector2(sc, sc)
		spr.position = _pos_for(info.sz, sc, off)

func _update_text() -> void:
	# Un solo bloque de texto a la vez: el de la imagen "actual".
	var idx = int(clamp(floor(time / STEP), 0, SHOTS.size() - 1))
	if idx != current_text_index:
		current_text_index = idx
		_apply_shot_text(SHOTS[idx])
	var local = time - idx * STEP
	var delay = 2.5 if idx == 0 else 1.0
	var a_in = clamp((local - delay) / 0.8, 0.0, 1.0)
	var a_out = clamp((STEP - 0.2 - local) / 0.8, 0.0, 1.0)
	var a = min(a_in, a_out)
	for lab in text_labels:
		lab.modulate = Color(1, 1, 1, a)

func _update_end() -> void:
	var t_end = starts[starts.size() - 1] + SHOT_TIME
	end_black.modulate = Color(1, 1, 1, clamp((time - (t_end - 2.0)) / 2.0, 0.0, 1.0))
	var fin = clamp((time - (t_end + 0.5)) / 1.5, 0.0, 1.0)
	var fout = clamp(((t_end + 8.0) - time) / 1.5, 0.0, 1.0)
	var a = min(fin, fout)
	thanks_lbl.modulate = Color(1, 1, 1, a)
	whisper_lbl.modulate = Color(1, 1, 1, a)
	if time >= t_end + 2.0 and not music_faded:
		music_faded = true
		MusicManager.fade_out(5.0)
	if time >= t_end + 9.0:
		_finish()

func _update_veil() -> void:
	var s = 0.5 - 0.5 * cos(time * TAU / 10.0)
	var c = Color(0.45, 0.15, 0.6).lerp(Color(0.25, 0.5, 0.35), s)
	c.a = 0.14 * s
	veil.color = c

func _unhandled_input(event) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
			_finish()

func _finish() -> void:
	if finishing:
		return
	finishing = true
	get_tree().change_scene_to_file("res://scenes3d/MainMenu3D.tscn")
