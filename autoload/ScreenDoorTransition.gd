extends CanvasLayer

const BLACK := Color(0.0, 0.0, 0.0, 1.0)

var _cover: ColorRect
var _door_root: Control
var _door_frame: ColorRect
var _door_leaf: ColorRect
var _trap_root: Control
var _trap_frame: ColorRect
var _trap_leaf: ColorRect
var _busy := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_cover = ColorRect.new()
	_cover.color = Color(0, 0, 0, 0)
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cover)
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_door()

func _build_door() -> void:
	_door_root = Control.new()
	_door_root.visible = false
	_door_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_door_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.add_child(_door_root)
	_door_frame = ColorRect.new()
	_door_frame.color = Color(0.27, 0.25, 0.22)
	_door_frame.set_anchors_preset(Control.PRESET_CENTER)
	_door_frame.position = Vector2(-155, -260)
	_door_frame.size = Vector2(310, 520)
	_door_frame.pivot_offset = _door_frame.size * 0.5
	_door_root.add_child(_door_frame)
	var inset := ColorRect.new()
	inset.color = Color(0.075, 0.07, 0.065)
	inset.position = Vector2(9, 9)
	inset.size = Vector2(292, 502)
	_door_frame.add_child(inset)
	_door_leaf = ColorRect.new()
	_door_leaf.color = Color(0.19, 0.145, 0.105)
	_door_leaf.position = Vector2(0, 0)
	_door_leaf.size = inset.size
	_door_leaf.pivot_offset = Vector2(0, inset.size.y * 0.5)
	inset.add_child(_door_leaf)
	for y in [34.0, 148.0, 262.0, 376.0]:
		var plank := ColorRect.new()
		plank.color = Color(0.24, 0.185, 0.13, 0.75)
		plank.position = Vector2(10, y)
		plank.size = Vector2(272, 4)
		_door_leaf.add_child(plank)
	var knob := ColorRect.new()
	knob.color = Color(0.52, 0.40, 0.19)
	knob.position = Vector2(266, 245)
	knob.size = Vector2(10, 18)
	_door_leaf.add_child(knob)
	_build_trapdoor()

func _build_trapdoor() -> void:
	_trap_root = Control.new()
	_trap_root.visible = false
	_trap_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trap_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.add_child(_trap_root)
	_trap_frame = ColorRect.new()
	_trap_frame.color = Color(0.25, 0.19, 0.12)
	_trap_frame.set_anchors_preset(Control.PRESET_CENTER)
	_trap_frame.position = Vector2(-190, -190)
	_trap_frame.size = Vector2(380, 380)
	_trap_frame.pivot_offset = _trap_frame.size * 0.5
	_trap_root.add_child(_trap_frame)
	var opening := ColorRect.new()
	opening.color = Color(0.025, 0.02, 0.018)
	opening.position = Vector2(13, 13)
	opening.size = Vector2(354, 354)
	_trap_frame.add_child(opening)
	_trap_leaf = ColorRect.new()
	_trap_leaf.color = Color(0.17, 0.115, 0.07)
	_trap_leaf.position = Vector2(0, 0)
	_trap_leaf.size = opening.size
	_trap_leaf.pivot_offset = Vector2(_trap_leaf.size.x * 0.5, 0)
	opening.add_child(_trap_leaf)
	for x in [28.0, 104.0, 180.0, 256.0]:
		var plank := ColorRect.new()
		plank.color = Color(0.25, 0.17, 0.10, 0.9)
		plank.position = Vector2(x, 10)
		plank.size = Vector2(8, 334)
		_trap_leaf.add_child(plank)
	var hinge := ColorRect.new()
	hinge.color = Color(0.48, 0.37, 0.20)
	hinge.position = Vector2(0, 0)
	hinge.size = Vector2(354, 9)
	_trap_leaf.add_child(hinge)

func is_transitioning() -> bool:
	return _busy

func transition_to_zone(zone_id: String, player: Node = null, exit_area: Node = null, style: String = "door") -> void:
	if _busy:
		return
	if not GameManager.ZONE_SCENES.has(zone_id):
		_abort_transition(player, exit_area, "Zona de destino desconocida: " + zone_id)
		return
	var destination: String = GameManager.ZONE_SCENES[zone_id]
	if not ResourceLoader.exists(destination):
		_abort_transition(player, exit_area, "No se encontró la escena de destino: " + destination)
		return

	# Extract spawn_marker from exit_area if available
	var spawn_marker: String = ""
	if is_instance_valid(exit_area) and exit_area.has_property("spawn_marker"):
		spawn_marker = exit_area.get("spawn_marker")

	_busy = true
	if is_instance_valid(player):
		if player is CharacterBody3D:
			(player as CharacterBody3D).velocity = Vector3.ZERO
		player.set_physics_process(false)
	_cover.color = Color(0, 0, 0, 0)
	_door_root.visible = false
	_trap_root.visible = false
	_door_frame.scale = Vector2(0.24, 0.24)
	_door_leaf.scale = Vector2.ONE
	_trap_frame.scale = Vector2(0.24, 0.24)
	_trap_leaf.rotation_degrees = 0.0
	var fade_in := create_tween()
	fade_in.tween_property(_cover, "color:a", 1.0, 0.3)
	await fade_in.finished
	await get_tree().create_timer(0.2).timeout

	if style == "trapdoor":
		_trap_root.visible = true
		var approach_hatch := create_tween()
		approach_hatch.tween_property(_trap_frame, "scale", Vector2(1.3, 1.3), 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		await approach_hatch.finished
		await get_tree().create_timer(0.16).timeout
		var open_hatch := create_tween()
		open_hatch.tween_property(_trap_leaf, "rotation_degrees", -108.0, 0.62).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await open_hatch.finished
		await get_tree().create_timer(0.28).timeout
		var close_hatch := create_tween()
		close_hatch.tween_property(_trap_leaf, "rotation_degrees", 0.0, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await close_hatch.finished
	else:
		_door_root.visible = true
		var approach := create_tween()
		approach.tween_property(_door_frame, "scale", Vector2(1.35, 1.35), 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		await approach.finished
		await get_tree().create_timer(0.16).timeout
		var open_door := create_tween()
		open_door.tween_property(_door_leaf, "scale:x", 0.035, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await open_door.finished
		await get_tree().create_timer(0.24).timeout
		var close_door := create_tween()
		close_door.tween_property(_door_leaf, "scale:x", 1.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await close_door.finished

	var change_error: Error = GameManager.change_zone(zone_id, spawn_marker)
	if change_error != OK:
		_abort_transition(player, exit_area, "No se pudo cargar la zona %s (error %d)." % [zone_id, change_error])
		return
	# SceneTree aplica el cambio al final del frame; el autoload sobrevive al
	# borrado de la escena anterior y termina siempre la animación.
	await get_tree().process_frame
	await get_tree().process_frame
	_door_root.visible = false
	_trap_root.visible = false
	var fade_out := create_tween()
	fade_out.tween_property(_cover, "color:a", 0.0, 0.52).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_out.finished
	_busy = false

func _abort_transition(player: Node, exit_area: Node, message: String) -> void:
	push_error("ScreenDoorTransition: " + message)
	_door_root.visible = false
	_trap_root.visible = false
	_cover.color = Color(0, 0, 0, 0)
	_busy = false
	if is_instance_valid(exit_area) and exit_area.has_method("cancel_transition"):
		exit_area.cancel_transition(player)
	elif is_instance_valid(player):
		player.set_physics_process(true)

