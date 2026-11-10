extends Node3D
class_name Zone3D
# ============================================================
# Versión 3D de Zone.gd.
#
# Diferencia clave frente al original 2D: el "fondo" ya no es una
# imagen plana generada por código — es una escena 3D real (el cuarto
# armado a mano en el editor con el Classic 64 Pack / HorrorPackFBX)
# que se instancia como hija de esta escena vía `room_scene`.
#
# Todo lo demás (HUD, diario, menú de pausa, velo de corrupción,
# aviso de "Has llegado a...", música con crossfade) se reutiliza tal
# cual del original: es lógica de estado, no depende de 2D vs 3D.
#
# Dentro de cada room_scene coloca a mano:
#   - Un Position3D llamado "Spawn" (o el que sea, ajusta spawn_point_path)
#   - Los Interactable3D sobre cada objeto examinable
#   - Los ExitArea3D sobre cada puerta/vano hacia otra zona
#   - Al menos una luz (OmniLight/SpotLight) para la ambientación real;
#     la de este script es solo un respaldo para no quedar a oscuras.
# ============================================================

@export var zone_id: String = ""
@export var spawn_point_path: NodePath
@export var room_scene: PackedScene

const PlayerScene = preload("res://scenes3d/Player3D.tscn")
const MaterialFixer = preload("res://scripts3d/MaterialFixer.gd")

func _ready():
	GameManager.current_zone_id = zone_id
	GameManager.game_over = false
	var gz := GameManager.GAMEPLAY.zone
	MusicManager.set_tension(_zone_music_tension(), gz.crossfade_duration)
	MusicManager.play("climax" if zone_id == "pozo" else "fondo")

	_add_room()
	_apply_zone_fog()
	_add_lighting_fallback()
	_add_corruption_overlay()
	# Defer player spawn to after child room _ready() creates spawn markers
	call_deferred("_spawn_player_deferred")
	# Texturas vacías y metalizado por defecto de los .glb (ver MaterialFixer.gd)
	MaterialFixer.fix(self)
	_spawn_ui()
	_announce_arrival()

func _spawn_player_deferred() -> void:
	_spawn_player()

func _apply_zone_fog() -> void:
	# Single source of truth for fog: GameManager.ZONE_FOG
	# Disable any WorldEnvironment from the room scene, apply our centralized fog
	var fog_data: Dictionary = GameManager.ZONE_FOG.get(zone_id)
	if fog_data == null:
		return
	# Remove existing WorldEnvironment from room
	for child in get_children():
		if child is WorldEnvironment:
			child.queue_free()
	var env := Environment.new()
	env.background_mode = fog_data.bg_mode
	env.background_color = fog_data.bg_color
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = fog_data.ambient_color
	env.ambient_light_energy = fog_data.ambient_energy
	env.fog_enabled = fog_data.enabled
	env.fog_mode = fog_data.mode
	env.fog_light_color = fog_data.light_color
	env.fog_depth_begin = fog_data.depth_begin
	env.fog_depth_end = fog_data.depth_end
	env.fog_depth_curve = fog_data.depth_curve
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)

func _announce_arrival():
	if GameManager.last_announced_zone == zone_id:
		return
	GameManager.last_announced_zone = zone_id
	GameManager.show_message("Has llegado a: " + GameManager.ZONE_NAMES.get(zone_id, zone_id))

func _add_room():
	if room_scene == null:
		push_warning("Zone3D '%s' no tiene room_scene asignada todavía." % zone_id)
		return
	var room = room_scene.instantiate()
	# La escalera de la casa principal termina a 1.53 m. El ático debe
	# continuar desde esa altura para que la transición no teletransporte
	# al jugador de vuelta al nivel del suelo.
	var gz := GameManager.GAMEPLAY.zone
	if zone_id == "atico":
		room.position.y = gz.atico_floor_height
	add_child(room)

	# Añadir colisión de suelo en runtime (CSG use_collision no funciona en runtime Godot 4)
	var ground = StaticBody3D.new()
	ground.name = "GroundCollision"
	var shape = BoxShape3D.new()
	shape.size = gz.ground_collision_size
	ground.position = gz.ground_collision_position
	var col_shape = CollisionShape3D.new()
	col_shape.shape = shape
	ground.add_child(col_shape)
	add_child(ground)

func _add_lighting_fallback():
	# Luz de relleno mínima para que nunca quede el cuarto totalmente
	# negro mientras vas metiendo la iluminación real de cada cuarto
	# (velas, foco colgante, etc. — esa sí conviene dejarla dentro de
	# cada room_scene, no aquí).
	for child in get_children():
		if child is Light3D:
			return
	var light = OmniLight3D.new()
	var gz := GameManager.GAMEPLAY.zone
	light.light_energy = gz.fallback_light_energy
	light.omni_range = gz.fallback_light_range
	light.position = gz.fallback_light_position
	light.shadow_enabled = false
	add_child(light)

func _add_corruption_overlay():
	var overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 2
	add_child(overlay_layer)
	var overlay = ColorRect.new()
	var gz := GameManager.GAMEPLAY.zone
	overlay.color = Color.from_hsv(gz.corruption_overlay_hue, gz.corruption_overlay_saturation, gz.corruption_overlay_value, gz.corruption_overlay_alpha_base)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameManager.corruption_overlay = overlay

func _spawn_player():
	var p = PlayerScene.instantiate()
	add_child(p)
	var actual_spawn_path := spawn_point_path
	# Usar spawn_marker específico de la salida por la que se entró (si hay)
	if GameManager.pending_spawn_marker != "":
		var marker_path := NodePath("Room_" + zone_id + "/" + GameManager.pending_spawn_marker)
		if has_node(marker_path):
			actual_spawn_path = marker_path
		else:
			push_warning("[Zone3D] Spawn marker '%s' no encontrado en zona '%s', usando default" % [GameManager.pending_spawn_marker, zone_id])
		GameManager.pending_spawn_marker = ""
	# Fallback: laberinto desde campo_cultivo
	elif zone_id == "laberinto" and GameManager.previous_zone_id == "campo_cultivo":
		actual_spawn_path = NodePath("Room_laberinto/SpawnDesdeCampo")
	if actual_spawn_path != null and has_node(actual_spawn_path):
		var spawn = get_node(actual_spawn_path)
		# Offset Y para evitar que la cápsula nazca incrustada en el suelo (físicas "poseídas").
		var gz := GameManager.GAMEPLAY.zone
		p.global_position = spawn.global_position + Vector3(0, gz.spawn_y_offset, 0)
		# Nace mirando en la dirección del marcador (rotación Y del Marker3D).
		p.set_facing(spawn.rotation.y)
	if zone_id == "establo":
		var wrapper = get_node_or_null("Room_establo/Wrapper3D")
		if wrapper != null and wrapper.has_method("start_patrol"):
			wrapper.patrol_speed *= GameManager.enemy_difficulty_multiplier
			wrapper.search_speed *= GameManager.enemy_difficulty_multiplier
			var gz := GameManager.GAMEPLAY.zone
			wrapper.sight_range *= 1.0 + (GameManager.enemy_difficulty_multiplier - 1.0) * gz.labyrinth_sight_range_multiplier
			wrapper.attack_sanity_damage *= GameManager.enemy_difficulty_multiplier
			wrapper.start_patrol([
				Vector3(8.2, 0.0, -4.5),
				Vector3(3.5, 0.0, -4.5),
				Vector3(3.5, 0.0, 2.0),
				Vector3(8.2, 0.0, 2.0)
			], p)
	elif zone_id == "laberinto":
		var grapper = get_node_or_null("Room_laberinto/Wrapper3D")
		if grapper != null and grapper.has_method("start_chase"):
			# Scale chase speed based on difficulty - player sprint is base_run_speed * multiplier
			var gz := GameManager.GAMEPLAY.zone
			var player_sprint := float(GameManager.GAMEPLAY.player.run_speed) * float(GameManager.GAMEPLAY.labyrinth.run_multipliers.get(GameManager.difficulty_id, 1.0))
			grapper.chase_speed = player_sprint * gz.labyrinth_chase_speed_multiplier * GameManager.enemy_difficulty_multiplier
			grapper.attack_sanity_damage = gz.labyrinth_attack_sanity_damage * GameManager.enemy_difficulty_multiplier
			grapper.sight_range *= 1.0 + (GameManager.enemy_difficulty_multiplier - 1.0) * gz.labyrinth_sight_range_multiplier
			grapper.lose_time = gz.labyrinth_lose_time  # Slightly more forgiving
			grapper.start_chase(p, true, true)
	print("[Zone3D] Jugador creado en zona '", zone_id, "' posicion: ", p.position)

func _spawn_ui():
	var hud = HUD.new()
	add_child(hud)
	GameManager.active_hud = hud

	var journal = Journal.new()
	add_child(journal)
	GameManager.active_journal = journal

	var pause_menu = PauseMenu.new()
	add_child(pause_menu)
	GameManager.active_pause_menu = pause_menu
	if GameManager.show_intro_on_next_zone:
		GameManager.show_intro_on_next_zone = false
		_show_intro_tutorial.call_deferred()

func _show_intro_tutorial() -> void:
	var layer := CanvasLayer.new()
	layer.name = "IntroduccionRapida"
	layer.layer = 40
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(0.006, 0.004, 0.012, 0.85)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(560, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_theme_stylebox_override("panel", _make_intro_panel_style())
	center.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	card.add_child(content)

	var eyebrow := Label.new()
	eyebrow.text = "EXPEDIENTE: LA GRANJA"
	eyebrow.add_theme_color_override("font_color", Color(0.78, 0.64, 0.84, 0.96))
	eyebrow.add_theme_font_size_override("font_size", 14)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(eyebrow)

	var title := Label.new()
	title.text = "INVESTIGACIÓN\nEN CURSO"
	title.add_theme_color_override("font_color", Color(0.96, 0.93, 0.96, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.035, 0.92))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_constant_override("line_spacing", -3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0, 1)
	rule.color = Color(0.55, 0.39, 0.63, 0.62)
	content.add_child(rule)

	var story := Label.new()
	story.text = "Eres el inspector enviado a investigar una granja aislada tras una serie de sucesos inexplicables. Explora la casa y sus alrededores, examina objetos y reúne pistas para reconstruir qué ocurrió."
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.add_theme_color_override("font_color", Color(0.92, 0.89, 0.94, 0.95))
	story.add_theme_font_size_override("font_size", 15)
	content.add_child(story)

	var instructions := Label.new()
	instructions.text = "Busca e interactúa con objetos para registrarlos en el Diario. Recorre cada habitación con cuidado: algunas pistas y herramientas te permitirán avanzar."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.add_theme_color_override("font_color", Color(0.92, 0.89, 0.94, 0.85))
	instructions.add_theme_font_size_override("font_size", 14)
	content.add_child(instructions)

	var controls := Label.new()
	controls.text = "WASD / stick izquierdo: moverte · E / A: interactuar · C / B: agacharse · Tab / Y: Diario · Shift / L-Stick: correr · Esc / Start: Pausa"
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.add_theme_color_override("font_color", Color(0.77, 0.67, 0.83, 0.9))
	controls.add_theme_font_size_override("font_size", 13)
	content.add_child(controls)

	var close := _make_intro_button("COMENZAR INVESTIGACIÓN")
	close.custom_minimum_size = Vector2(0, 50)
	close.pressed.connect(layer.queue_free)
	content.add_child(close)

	var footer := Label.new()
	footer.text = "UNA INTERPRETACIÓN LIBRE DE H. P. LOVECRAFT"
	footer.add_theme_color_override("font_color", Color(0.62, 0.57, 0.66, 0.82))
	footer.add_theme_font_size_override("font_size", 10)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(footer)

func _make_intro_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.009, 0.018, 0.92)
	style.border_color = Color(0.34, 0.23, 0.40, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style

func _make_intro_button(label_text: String) -> Button:
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

func _process(_delta):
	if GameManager.corruption_overlay:
		var pulse = Time.get_ticks_msec() / 1000.0
		var corruption = GameManager.corruption_level()
		var gz := GameManager.GAMEPLAY.zone
		var gc := GameManager.GAMEPLAY.corruption
		var hue = gz.corruption_overlay_hue + sin(pulse * gc.overlay_pulse_speed) * gc.overlay_hue_variance
		var alpha = corruption * (gc.overlay_alpha_base + sin(pulse * gc.overlay_pulse_speed * 3.7) * gc.overlay_alpha_variance)
		GameManager.corruption_overlay.color = Color.from_hsv(hue, gz.corruption_overlay_saturation, gz.corruption_overlay_value, alpha)

func _zone_music_tension() -> float:
	return {"camino_entrada": 0.08, "casa_principal": 0.16, "bosque": 0.34, "laberinto": 0.82, "campo_cultivo": 0.48, "establo": 0.62, "atico": 0.28, "pozo": 0.78, "crater_meteorito": 0.9}.get(zone_id, 0.35)
