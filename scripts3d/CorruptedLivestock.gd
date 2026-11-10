extends Node3D

const COAT := Color(0.76, 0.77, 0.73)
const ASH := Color(0.28, 0.30, 0.29)

func _ready() -> void:
	var pale := _material(COAT)
	var ash := _material(ASH)
	_add_carcass(Vector3(3.0, 0.0, 1.8), 0.0, pale, ash)
	_add_carcass(Vector3(-3.8, 0.0, -1.0), -0.4, pale, ash)
	_add_carcass(Vector3(7.0, 0.0, -2.2), 0.65, pale, ash)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material

func _add_carcass(origin: Vector3, yaw: float, coat: Material, ash: Material) -> void:
	var body := Node3D.new()
	body.position = origin
	body.rotation.y = yaw
	add_child(body)
	_add_sphere(body, Vector3(0, 0.38, 0), Vector3(0.92, 0.42, 0.48), coat)
	_add_sphere(body, Vector3(0.82, 0.38, 0.02), Vector3(0.28, 0.3, 0.29), coat)
	_add_sphere(body, Vector3(0.96, 0.2, 0.02), Vector3(0.2, 0.09, 0.2), ash)
	# Las patas quedan vencidas, con el mismo tono seco y ceniciento del relato.
	for offset in [Vector3(-0.55, 0.06, -0.34), Vector3(-0.40, 0.05, 0.34), Vector3(0.45, 0.08, -0.3), Vector3(0.34, 0.04, 0.32)]:
		var leg := CSGCylinder3D.new()
		leg.radius = 0.075
		leg.height = 0.48
		leg.sides = 5
		leg.position = offset
		leg.rotation.z = 1.1 if offset.x < 0.0 else -0.9
		leg.material = ash
		leg.use_collision = false
		body.add_child(leg)
	# Manchas de polvo gris: la silueta se reconoce sin introducir texturas nuevas.
	_add_sphere(body, Vector3(-0.2, 0.69, -0.1), Vector3(0.3, 0.035, 0.22), ash)
	_add_sphere(body, Vector3(0.25, 0.71, 0.16), Vector3(0.22, 0.03, 0.17), ash)

func _add_sphere(parent: Node3D, at: Vector3, dimensions: Vector3, material: Material) -> void:
	var mesh := CSGSphere3D.new()
	mesh.radius = 0.5
	mesh.radial_segments = 8
	mesh.rings = 5
	mesh.position = at
	mesh.scale = dimensions * 2.0
	mesh.material = material
	mesh.use_collision = false
	parent.add_child(mesh)
