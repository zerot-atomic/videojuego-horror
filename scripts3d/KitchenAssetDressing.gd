extends Node3D

const COOKSTOVE := preload("res://art3d/extras/PSX_Horror_Farm/cookstove.glb")
const PUMP_SINK := preload("res://art3d/extras/PSX_Horror_Farm/pump_sink.glb")
const HOOSIER := preload("res://art3d/extras/PSX_Horror_Farm/hoosier.glb")
const ICEBOX := preload("res://art3d/extras/PSX_Horror_Farm/icebox.glb")
const WALL_CALENDAR := preload("res://art3d/extras/PSX_Horror_Farm/calendar_farm.glb")

func _ready() -> void:
	# Sustituye los volúmenes de prueba de la cocina por muebles de escala real.
	var room := get_parent()
	for placeholder in ["Refrigerador_Cocina", "Mostrador_Cocina", "Cubierta_Fregadero", "Tina_Fregadero", "Grifo_Fregadero"]:
		var old := room.get_node_or_null("Dressing/" + placeholder)
		if old != null:
			old.queue_free()
	_add_prop(ICEBOX, "NeveraDeHielo", Vector3(0.45, 0.0, -5.75), 0.0, 0.92, Vector3(0.9, 1.5, 0.9))
	_add_prop(COOKSTOVE, "EstufaDeHierro", Vector3(2.45, 0.0, -5.7), 0.0, 0.92, Vector3(1.0, 1.25, 0.9))
	_add_prop(PUMP_SINK, "FregaderoDeBomba", Vector3(4.55, 0.0, -5.7), 0.0, 0.92, Vector3(1.0, 1.0, 0.9))
	_add_prop(HOOSIER, "AlacenaHoosier", Vector3(6.65, 0.0, -5.65), 0.0, 0.9, Vector3(1.2, 1.8, 0.85))
	# Piezas murales discretas; la manivela interactiva permanece visible junto al fregadero.
	_add_prop(WALL_CALENDAR, "CalendarioDeGranja", Vector3(1.3, 1.55, -7.45), 0.0, 0.82)

func _add_prop(scene: PackedScene, prop_name: String, at: Vector3, yaw: float, scale_factor: float, collider_size: Vector3 = Vector3.ZERO) -> void:
	var prop := scene.instantiate()
	prop.name = prop_name
	prop.position = at
	prop.rotation.y = yaw
	prop.scale = Vector3.ONE * scale_factor
	add_child(prop)
	if collider_size != Vector3.ZERO:
		var body := StaticBody3D.new()
		body.name = prop_name + "Collision"
		body.position = at + Vector3(0.0, collider_size.y * 0.5, 0.0)
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = collider_size
		collision.shape = box
		body.add_child(collision)
		add_child(body)
