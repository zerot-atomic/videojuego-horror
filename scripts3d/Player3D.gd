extends CharacterBody3D
class_name Player3D
# ============================================================
# Versión 3D del inspector. Reemplaza a Player.gd (2D).
#
# Control direccional tipo consola: WASD, stick izquierdo y joystick táctil
# comparten un vector relativo a cámara; el personaje sigue la dirección.
# La cámara queda detrás y acompaña el giro con un poco de retraso suave.
# Shift corre y consume cordura cerca de zonas corruptas — se
# reutiliza GameManager.drain_sanity tal cual.
# E interactuar, Tab diario, Esc pausa: también reutilizados.
#
# Estructura de nodos esperada (armar en el editor, sin cambios
# respecto a antes):
#   Player3D (KinematicBody, este script)
#   ├── CollisionShape         (CapsuleShape, ~1.7m alto)
#   ├── MeshRoot (Spatial)     <- aquí se instancia inspector.glb
#   │                             ya rigueado, cuando lo tengas
#   ├── InteractionArea (Area)
#   │   └── CollisionShape     (esfera, radio ~1.2m)
#   └── CameraPivot (Spatial)  <- permanece anclado al jugador y acompaña
#       └── SpringArm             su posición y orientación.
#           └── Camera
# ============================================================

# Parámetros desde GameManager.GAMEPLAY (única fuente de verdad)
var speed: float
var run_speed: float
var crouch_speed: float
var backward_speed_factor: float
var rotation_speed: float
var camera_follow_speed: float
var gravity: float
var camera_distance: float
var camera_height: float
var camera_pitch_min: float
var camera_pitch_max: float
var _gp: Dictionary = {}  # Cached player gameplay params

# PARCHE PORT 4.x: "velocity" ya NO se declara aquí — CharacterBody3D (antes
# KinematicBody) ya trae su propia variable "velocity" integrada desde
# Godot 4. Declararla otra vez aquí causaba un error de compilación
# ("Member velocity redefined"). Todo el código de abajo sigue escribiendo
# en "velocity.x/y/z" igual que antes; ahora apunta directo a la del motor.
var vertical_velocity = 0.0
var facing_angle = 0.0     # ángulo del CUERPO (se actualiza en _physics_process)
var camera_yaw = 0.0       # ángulo de la CÁMARA (persigue a facing_angle con retraso, en _process)
var camera_pitch = -0.17
var nearby_interactables = []
var _crouch_playing_backwards: bool = false
var _shake_time: float = 0.0
var _threat_pressure: float = 0.0

@onready var interaction_area = $InteractionArea
@onready var body_collision: CollisionShape3D = $CollisionShape3D
@onready var camera_pivot = $CameraPivot
@onready var spring_arm = $CameraPivot/SpringArm3D
@onready var camera = $CameraPivot/SpringArm3D/Camera3D
@onready var mesh_root = $MeshRoot
@onready var anim_player = _find_anim_player()

func _ready():
	# Cargar parámetros centralizados
	var gp := GameManager.GAMEPLAY.player
	_gp = gp
	speed = gp.walk_speed
	run_speed = gp.run_speed
	crouch_speed = gp.crouch_speed
	backward_speed_factor = gp.backward_speed_factor
	rotation_speed = gp.rotation_speed
	camera_follow_speed = gp.camera_follow_speed
	gravity = gp.gravity
	camera_distance = gp.camera_distance
	camera_height = gp.camera_height
	camera_pitch_min = gp.camera_pitch_min
	camera_pitch_max = gp.camera_pitch_max

	# Los recursos de una escena se comparten entre instancias. Aislar esta
	# forma evita que una instancia agachada deje la cápsula encogida al cambiar de zona.
	if body_collision.shape != null:
		body_collision.shape = body_collision.shape.duplicate(true)
	_set_crouching(false)
	_load_stealth_animations()
	interaction_area.connect("area_entered", Callable(self, "_on_area_entered"))
	interaction_area.connect("area_exited", Callable(self, "_on_area_exited"))
	camera.current = true
	# El farol del inspector debe dar una lectura mínima a su silueta y al
	# suelo inmediato, sin reemplazar la iluminación oscura de cada escena.
	var lantern_light = OmniLight3D.new()
	lantern_light.light_color = gp.lantern_color
	lantern_light.light_energy = gp.lantern_energy
	lantern_light.omni_range = gp.lantern_range
	lantern_light.omni_attenuation = gp.lantern_attenuation
	lantern_light.shadow_enabled = false
	lantern_light.position = gp.lantern_position
	add_child(lantern_light)
	# Camara tipo Silent Hill 1: algo alta y retirada, lente algo abierta, y a lo lejos se pierde en la niebla.
	camera.fov = gp.camera_fov
	camera.near = gp.camera_near
	camera.far = gp.camera_far
	# El brazo de la cámara no debe chocar con el cuerpo del propio jugador.
	spring_arm.add_excluded_object(get_rid())
	spring_arm.spring_length = camera_distance

	# CameraPivot top-level: su transform es mundial, no se suma a la rotación del cuerpo.
	camera_pivot.set_as_top_level(true)
	camera_yaw = rotation.y
	facing_angle = rotation.y
	_update_camera()

	# PARCHE v12: las animaciones que vienen de Mixamo llegan sin repetirse.
	# Se ponen en bucle aqui para que Idle/Walk/Run no se congelen al terminar.
	if anim_player != null:
		for anim_name in anim_player.get_animation_list():
			anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if OS.has_feature("android") or DisplayServer.is_touchscreen_available():
		var touch_controls := MobileTouchControls.new()
		touch_controls.action_pressed.connect(_on_touch_action_pressed)
		add_child(touch_controls)

func _load_stealth_animations() -> void:
	if anim_player == null:
		return
	var library: AnimationLibrary = anim_player.get_animation_library("")
	if library == null:
		library = AnimationLibrary.new()
		anim_player.add_animation_library("", library)
	for entry in [
		["res://art3d/characters/animations/crouched_walking.fbx", "CrouchWalk"],
		["res://art3d/characters/animations/running_crawl.fbx", "CrouchRun"]
	]:
		var packed: PackedScene = load(entry[0])
		if packed == null:
			continue
		var source_root := packed.instantiate()
		var source_player: AnimationPlayer = source_root.find_child("AnimationPlayer", true, false)
		if source_player != null and source_player.has_animation("mixamo_com"):
			var clip: Animation = source_player.get_animation("mixamo_com").duplicate(true)
			# Evita importar traslación de raíz de los FBX de Mixamo: el rig puede
			# desplazarse verticalmente durante el ciclo y separarse de la cápsula.
			for track in range(clip.get_track_count() - 1, -1, -1):
				var source_path := clip.track_get_path(track)
				var root_property := source_path.get_subname_count() > 0 and source_path.get_subname(source_path.get_subname_count() - 1) == "position"
				var root_node := source_path.get_name_count() <= 2
				if clip.track_get_type(track) == Animation.TYPE_POSITION_3D and root_property and root_node:
					clip.remove_track(track)
					continue
				clip.track_set_path(track, NodePath("RootNode/" + String(clip.track_get_path(track))))
			clip.loop_mode = Animation.LOOP_LINEAR
			if library.has_animation(entry[1]):
				library.remove_animation(entry[1])
			library.add_animation(entry[1], clip)
		source_root.free()

var crouching: bool = false

func is_crouching() -> bool:
	return crouching

func get_noise_radius() -> float:
	var gp := GameManager.GAMEPLAY.interaction
	if crouching:
		return gp.crouch_noise_radius
	return gp.run_noise_radius if Input.is_action_pressed("run") else gp.walk_noise_radius

func get_effective_run_speed() -> float:
	var multiplier := 1.0
	if GameManager.current_zone_id == "laberinto":
		multiplier = float(GameManager.GAMEPLAY.labyrinth.run_multipliers.get(GameManager.difficulty_id, 1.0))
	return run_speed * multiplier

func _set_crouching(value: bool) -> void:
	var gp := GameManager.GAMEPLAY.player
	var capsule := body_collision.shape as CapsuleShape3D
	var next_state := value
	if not value and crouching and capsule != null and is_inside_tree():
		var headroom := PhysicsShapeQueryParameters3D.new()
		var stand_shape := CapsuleShape3D.new()
		stand_shape.radius = capsule.radius
		stand_shape.height = gp.stand_capsule_height
		headroom.shape = stand_shape
		headroom.transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 0.94, 0))
		headroom.exclude = [get_rid()]
		headroom.collision_mask = collision_mask
		if not get_world_3d().direct_space_state.intersect_shape(headroom, 1).is_empty():
			next_state = true
	crouching = next_state
	if capsule != null:
		# La cápsula mantiene su base en el mismo plano. Evita que el motor
		# resuelva penetración con el suelo empujando al CharacterBody hacia arriba.
		capsule.height = gp.crouch_capsule_height if crouching else gp.stand_capsule_height
		body_collision.position.y = capsule.height * 0.5 + gp.collision_y_offset

# Orienta al jugador (y a la cámara, que va detrás) hacia un ángulo dado.
# Lo usa Zone3D para que nazcas mirando hacia el centro del cuarto.
func set_facing(angle: float) -> void:
	facing_angle = angle
	camera_yaw = angle
	rotation.y = angle
	_update_camera()   # sin esto, la cámara "viajaría" desde su posición anterior al teletransportar

# El importador de glTF suele meter el AnimationPlayer un nivel adentro,
# dentro del nodo raíz de la escena importada e instanciada bajo MeshRoot.
# Esto busca en ambos niveles para no depender de una ruta exacta.
func _find_anim_player():
	if mesh_root == null:
		return null
	for child in mesh_root.get_children():
		if child is AnimationPlayer:
			return child
		for grandchild in child.get_children():
			if grandchild is AnimationPlayer:
				return grandchild
			for great_grandchild in grandchild.get_children():
				if great_grandchild is AnimationPlayer:
					return great_grandchild
	return null

func _on_area_entered(area):
	if area.has_method("interact"):
		nearby_interactables.append(area)

func _on_area_exited(area):
	if area in nearby_interactables:
		nearby_interactables.erase(area)

func _physics_process(delta):
	if GameManager.game_over or GameManager.journal_open:
		velocity.x = 0
		velocity.z = 0
		_apply_gravity(delta)
		set_velocity(velocity)
		set_up_direction(Vector3.UP)
		move_and_slide()
		_update_animation(false, delta)
		return

	var running: bool = _apply_tank_movement(delta)

	if running and GameManager.corruption_level() > 0.3:
		GameManager.drain_sanity(delta * 8.0)

	_apply_gravity(delta)
	set_velocity(velocity)
	set_up_direction(Vector3.UP)
	floor_stop_on_slope = false
	max_slides = 4
	floor_max_angle = deg_to_rad(46)
	# Mantiene el cuerpo pegado a los peldaños/rampa cuando sube por la casa.
	floor_snap_length = _gp.floor_snap_length
	# TODOConverter3To4 infinite_inertia were removed in Godot 4 - previous value `false`
	move_and_slide()
	_update_animation(running, delta)

func _process(delta):
	# El yaw acompaña siempre el giro del inspector, con el suavizado original.
	camera_yaw = lerp_angle(camera_yaw, facing_angle, clamp(camera_follow_speed * delta, 0.0, 1.0))
	_update_camera()

func _apply_gravity(delta):
	if is_on_floor():
		vertical_velocity = -0.5
	else:
		vertical_velocity += gravity * delta
	velocity.y = vertical_velocity

func _apply_tank_movement(delta) -> bool:
	# Tank controls puros (Silent Hill 1 / RE clásico):
	# W/S = adelante/atrás relativo al cuerpo
	# A/D = girar personaje (tanque)
	var move_forward := Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	var turn_input := Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")

	var running: bool = Input.is_action_pressed("run") and abs(move_forward) > 0.01
	var current_speed: float = (crouch_speed * 0.8 if running else crouch_speed) if crouching else (run_speed if running else speed)

	if GameManager.current_zone_id == "laberinto":
		if running:
			current_speed *= float(GameManager.GAMEPLAY.labyrinth.run_multipliers.get(GameManager.difficulty_id, 1.0))
		elif GameManager.difficulty_id == "story":
			current_speed *= _gp.story_speed_multiplier

	# Girar el personaje (tanque)
	if abs(turn_input) > 0.01:
		facing_angle -= turn_input * rotation_speed * delta
		rotation.y = facing_angle

	# Movimiento adelante/atrás relativo al cuerpo
	if abs(move_forward) > 0.01:
		var direction := 1.0 if move_forward > 0 else -backward_speed_factor
		var forward_dir := Vector3(sin(facing_angle), 0.0, cos(facing_angle))
		var target_velocity := forward_dir * current_speed * direction
		var planar_velocity := Vector3(velocity.x, 0.0, velocity.z)
		var response: float = _gp.movement_response
		planar_velocity = planar_velocity.move_toward(target_velocity, response * delta)
		velocity.x = planar_velocity.x
		velocity.z = planar_velocity.z
	else:
		# Desaceleración suave al soltar
		var planar_velocity := Vector3(velocity.x, 0.0, velocity.z)
		planar_velocity = planar_velocity.move_toward(Vector3.ZERO, _gp.movement_deceleration * delta)
		velocity.x = planar_velocity.x
		velocity.z = planar_velocity.z

	return running

func _update_camera():
	# CameraPivot es top-level: posición y orientación se expresan en mundo,
	# como en la cámara previa a la beta.
	var threat_shake := _threat_camera_shake()
	var terror_scale: float = GameManager.terror_multiplier
	camera_pivot.global_position = global_position + Vector3(0, camera_height, 0) + threat_shake
	camera_pivot.global_rotation = Vector3(0, camera_yaw, 0)
	var shake_weight := _threat_pressure * _threat_pressure
	camera_pivot.rotation.z = sin(_shake_time * 1.35) * shake_weight * 0.018 * terror_scale
	camera_pivot.rotation.x = cos(_shake_time * 1.8) * shake_weight * 0.009 * terror_scale
	spring_arm.rotation.x = camera_pitch

func _threat_camera_shake() -> Vector3:
	var threat_distance := INF
	for threat in get_tree().get_nodes_in_group("gripper"):
		if is_instance_valid(threat) and threat is Node3D and threat.get("state") != null:
			if threat.get("state") == 0:
				continue
			threat_distance = minf(threat_distance, global_position.distance_to(threat.global_position))
	if threat_distance == INF or threat_distance >= _gp.threat_distance_threshold:
		_threat_pressure = 0.0
		MusicManager.set_threat_pressure(0.0, _zone_music_track(), _zone_music_tension())
		return Vector3.ZERO
	var pressure := 1.0 - clampf(threat_distance / _gp.threat_distance_threshold, 0.0, 1.0)
	_threat_pressure = pressure
	var musical_pressure: float = clampf(pressure * GameManager.terror_multiplier, 0.0, 1.0)
	MusicManager.set_threat_pressure(musical_pressure, _zone_music_track(), _zone_music_tension())
	_shake_time += get_process_delta_time() * (7.0 + pressure * 15.0)
	var amplitude := minf(0.17, pressure * pressure * 0.105 * GameManager.terror_multiplier)
	return Vector3(sin(_shake_time * 1.71) * amplitude, cos(_shake_time * 2.13) * amplitude * 0.55, 0.0)

func _zone_music_tension() -> float:
	return {"camino_entrada": 0.08, "casa_principal": 0.16, "bosque": 0.34, "laberinto": 0.82, "campo_cultivo": 0.48, "establo": 0.62, "atico": 0.28, "pozo": 0.78, "crater_meteorito": 0.9}.get(GameManager.current_zone_id, 0.35)

func _zone_music_track() -> String:
	return "climax" if GameManager.current_zone_id == "pozo" else "fondo"

func _update_animation(running, _delta = 0.016):
	# Solo si el .glb trae AnimationPlayer con "Idle"/"Walk"/"Run". Sin animaciones el
	# modelo se desliza quieto (a proposito: nada de balanceo de lado a lado).
	if anim_player == null:
		return
	var moving = Vector2(velocity.x, velocity.z).length() > 0.2
	var planar_velocity := Vector2(velocity.x, velocity.z)
	var forward_axis := Vector2(sin(facing_angle), cos(facing_angle))
	var backwards = crouching and moving and planar_velocity.dot(forward_axis) < -0.1
	var wanted = "CrouchWalk" if crouching else "Idle"
	if moving and not crouching:
		wanted = "Run" if running else "Walk"
	elif crouching and moving and running:
		wanted = "CrouchRun"
	if not anim_player.has_animation(wanted) and crouching:
		wanted = "Walk" if moving else "Idle"
	var direction_changed := crouching and backwards != _crouch_playing_backwards
	if anim_player.has_animation(wanted) and (anim_player.current_animation != wanted or direction_changed):
		anim_player.play(wanted, 0.2, -1.0 if backwards else 1.0, backwards)
		_crouch_playing_backwards = backwards
	if crouching and anim_player.current_animation == wanted:
		anim_player.speed_scale = 1.0 if moving else _gp.anim_idle_speed_scale
	else:
		anim_player.speed_scale = 1.0

func _unhandled_input(event):
	if GameManager.game_over:
		return
	if event.is_action_pressed("pause"):
		var pausing := not GameManager.journal_open
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if pausing else Input.MOUSE_MODE_HIDDEN)
		GameManager.toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("crouch"):
		_set_crouching(not crouching)
	elif event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("journal"):
		GameManager.toggle_journal()

func _on_touch_action_pressed(action: String) -> void:
	match action:
		"crouch":
			_set_crouching(not crouching)
		"interact":
			_try_interact()
		"journal":
			GameManager.toggle_journal()
		"pause":
			var pausing := not GameManager.journal_open
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if pausing else Input.MOUSE_MODE_HIDDEN)
			GameManager.toggle_pause()

func _try_interact():
	if GameManager.journal_open or nearby_interactables.is_empty():
		return
	var target = nearby_interactables[0]
	target.interact()
