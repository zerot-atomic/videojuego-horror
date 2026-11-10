extends RefCounted
# ============================================================
# Utilidades para construir cosas por codigo (casa, granero, granja).
#  - tex():            carga una textura (aunque no este importada).
#  - mat():            material con la textura "triplanar": la textura se
#                      reparte sola por tamaño real (metros), sin importar
#                      si la pared mide 3 o 12 metros. Asi no se estira.
#  - load_model():     instancia un .glb del proyecto y le arregla texturas.
# ============================================================

static func tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var t = load(path)
		if t is Texture2D:
			return t
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		if img != null:
			img.generate_mipmaps()
			return ImageTexture.create_from_image(img)
	push_warning("ProcTools: no encontre la textura " + path)
	return null

# tile_m = cuantos metros cubre UNA repeticion de la textura.
static func mat(texture_path: String, tint: Color = Color(1, 1, 1), tile_m: float = 1.6, roughness: float = 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var t := tex(texture_path)
	if t != null:
		m.albedo_texture = t
	m.albedo_color = tint
	m.roughness = roughness
	m.metallic = 0.0
	m.uv1_triplanar = true
	var s := 1.0 / tile_m
	m.uv1_scale = Vector3(s, s, s)
	return m

static func flat(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

static func glow(color: Color, energy: float = 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.roughness = 0.3
	return m

# Instancia un modelo .glb. Si por alguna razon aun no esta importado, lo
# lee directo del disco (asi nunca desaparece de la escena).
static func load_model(path: String) -> Node3D:
	var node: Node = null
	if ResourceLoader.exists(path):
		var ps = load(path)
		if ps is PackedScene:
			node = ps.instantiate()
	if node == null and FileAccess.file_exists(path):
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		if doc.append_from_file(ProjectSettings.globalize_path(path), st) == OK:
			node = doc.generate_scene(st)
			node.set("scene_file_path", path)
	if node == null:
		push_warning("ProcTools: no pude cargar el modelo " + path)
		return Node3D.new()
	var MF = load("res://scripts3d/MaterialFixer.gd")
	MF.fix(node)
	return node as Node3D

# Caja solida (con colision opcional) hecha con CSG.
static func box(parent: Node, size: Vector3, pos: Vector3, material: Material, collide: bool = false, node_name: String = "") -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.material = material
	b.use_collision = collide
	if node_name != "":
		b.name = node_name
	parent.add_child(b)
	return b

# Agujero (resta) dentro de una caja CSG padre. pos es relativo al centro del padre.
static func hole(parent: CSGBox3D, size: Vector3, pos: Vector3) -> CSGBox3D:
	var h := CSGBox3D.new()
	h.size = size
	h.position = pos
	h.operation = CSGShape3D.OPERATION_SUBTRACTION
	parent.add_child(h)
	return h
