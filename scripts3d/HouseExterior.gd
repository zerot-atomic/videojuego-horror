extends Node3D
# ============================================================
# Casa (o granero) vista desde afuera, armada por codigo.
#
# COMO SE COLOCA:
#   - El FRENTE mira hacia +Z del nodo. El origen del nodo es el centro de la
#     pared del frente, al nivel del suelo. El edificio crece hacia -Z.
#   - Gira el nodo (rotation.y) para que mire hacia donde quieras.
#   - La puerta queda al centro del frente. La salida (ExitArea3D) debe ir
#     justo en la puerta: usa puerta_en_mundo() para saber donde cae.
#
# Todo lo que se puede tocar esta en las variables de abajo (panel Inspector).
# ============================================================

const PT = preload("res://scripts3d/ProcTools.gd")
const WOOD := "res://art3d/classic64_pack/Wood/Materials/"
const ROCK := "res://art3d/classic64_pack/Rocks/Materials/"
const ROOF := "res://art3d/horror_pack/textures/weathered_brown_planks_diff_1k.jpg"
const GROSOR := 0.28       # grosor de los muros
const PISO_ALTO := 0.18    # altura del piso interior y del porche

@export_enum("casa", "granero") var estilo: String = "casa"
@export var ancho: float = 8.0
@export var fondo: float = 7.0
@export var alto_muros: float = 3.0
@export var ancho_puerta: float = 1.4
@export var alto_puerta: float = 2.3
@export var inclinacion_techo: float = 32.0   # grados
@export var con_porche: bool = true
@export var con_chimenea: bool = true
@export var luz_interior: bool = true
@export var puerta_cerrada: bool = false      # true = puerta de madera cerrada (no se puede entrar)
@export var color_muros: Color = Color(0.86, 0.83, 0.76)
@export var color_techo: Color = Color(0.62, 0.58, 0.55)
@export var color_detalle: Color = Color(0.80, 0.78, 0.72)

var _m_muro: StandardMaterial3D
var _m_oscuro: StandardMaterial3D
var _m_techo: StandardMaterial3D
var _m_piedra: StandardMaterial3D
var _m_detalle: StandardMaterial3D
var _m_vidrio: StandardMaterial3D

func _ready() -> void:
	_construir()

func puerta_en_mundo() -> Vector3:
	# centro de la puerta, un poco hacia afuera (sirve para colocar la salida)
	return to_global(Vector3(0, 1.2, 0.9))

func _construir() -> void:
	_m_muro = PT.mat(WOOD + "wood_planks_tan.png", color_muros, 1.6)
	_m_oscuro = PT.mat(WOOD + "wood_plank_2.png", Color(0.56, 0.48, 0.38), 1.6)
	_m_techo = PT.mat(ROOF, color_techo, 1.8)
	_m_piedra = PT.mat(ROCK + "rock_wall_1.png", Color(1, 1, 1), 1.5)
	_m_detalle = PT.flat(color_detalle, 1.0)
	_m_vidrio = PT.glow(Color(0.95, 0.80, 0.45), 0.55)

	var es_casa := estilo == "casa"
	_muros(es_casa)
	_zocalo()
	_interior()
	_techo(es_casa)
	if es_casa:
		if con_porche:
			_porche()
		if con_chimenea:
			_chimenea()
	else:
		_detalles_granero()
	if puerta_cerrada and es_casa:
		_hoja_de_puerta()

# ---------------------------------------------------------------- muros
func _muros(es_casa: bool) -> void:
	var h := alto_muros
	# FRENTE (con hueco de puerta y, en la casa, dos ventanas)
	var frente := PT.box(self, Vector3(ancho, h, GROSOR), Vector3(0, h / 2.0, -GROSOR / 2.0), _m_muro, true, "MuroFrente")
	var hp := alto_puerta + 0.1
	PT.hole(frente, Vector3(ancho_puerta, hp, GROSOR + 0.4), Vector3(0, (alto_puerta - 0.1) / 2.0 - h / 2.0, 0))
	_marco_puerta()
	if es_casa:
		var vx := ancho / 2.0 - 1.9
		for s in [-1.0, 1.0]:
			PT.hole(frente, Vector3(1.1, 1.3, GROSOR + 0.4), Vector3(s * vx, 1.75 - h / 2.0, 0))
			_ventana(Vector3(s * vx, 1.75, 0), 0.0)

	# LADOS
	for s in [-1.0, 1.0]:
		var lado := PT.box(self, Vector3(GROSOR, h, fondo), Vector3(s * (ancho / 2.0 - GROSOR / 2.0), h / 2.0, -fondo / 2.0), _m_muro, true, "MuroLado")
		if es_casa:
			PT.hole(lado, Vector3(GROSOR + 0.4, 1.3, 1.1), Vector3(0, 1.75 - h / 2.0, 0))
			_ventana(Vector3(s * (ancho / 2.0 - GROSOR / 2.0), 1.75, -fondo / 2.0), s * 90.0)
		# Puerta lateral oeste (s = -1.0) para campo_cultivo
		if s == -1.0 and es_casa:
			var puerta_z := -fondo / 2.0 + fondo * 0.68  # ~z=+2.25 en interior
			PT.hole(lado, Vector3(GROSOR + 0.4, alto_puerta + 0.1, 1.3), Vector3(0, (alto_puerta - 0.1) / 2.0 - h / 2.0, puerta_z + fondo / 2.0))
			_ventana(Vector3(s * (ancho / 2.0 - GROSOR / 2.0), 1.75, -fondo / 2.0 + puerta_z + fondo / 2.0), s * 90.0)

	# FONDO
	PT.box(self, Vector3(ancho, h, GROSOR), Vector3(0, h / 2.0, -fondo + GROSOR / 2.0), _m_muro, true, "MuroFondo")

func _marco_puerta() -> void:
	var hp := alto_puerta + 0.1
	for s in [-1.0, 1.0]:
		PT.box(self, Vector3(0.14, hp, GROSOR + 0.1), Vector3(s * (ancho_puerta / 2.0 + 0.07), hp / 2.0, -GROSOR / 2.0), _m_oscuro)
	PT.box(self, Vector3(ancho_puerta + 0.42, 0.16, GROSOR + 0.1), Vector3(0, alto_puerta + 0.08, -GROSOR / 2.0), _m_oscuro)

# Puerta cerrada: una hoja de madera con perilla, con colision (no se puede pasar).
func _hoja_de_puerta() -> void:
	var hoja := PT.box(self, Vector3(ancho_puerta, alto_puerta, 0.12), Vector3(0, alto_puerta / 2.0, -GROSOR / 2.0 + 0.04), _m_oscuro, true, "PuertaCerrada")
	PT.box(hoja, Vector3(0.1, 0.1, 0.12), Vector3(ancho_puerta / 2.0 - 0.2, 0.0, 0.1), PT.flat(Color(0.55, 0.48, 0.3), 0.4))

# Ventana: hueco ya hecho en el muro; aqui va el vidrio con brillo, el marco y la cruz.
# 'rot' gira la ventana para muros laterales (el +Z local siempre apunta hacia afuera).
func _ventana(pos: Vector3, rot_deg: float) -> void:
	var w := Node3D.new()
	w.position = pos
	w.rotation_degrees = Vector3(0, rot_deg, 0)
	add_child(w)
	PT.box(w, Vector3(1.04, 1.24, 0.05), Vector3(0, 0, -GROSOR / 2.0 + 0.02), _m_vidrio)
	PT.box(w, Vector3(0.05, 1.24, 0.07), Vector3(0, 0, -GROSOR / 2.0 + 0.05), _m_oscuro)
	PT.box(w, Vector3(1.04, 0.05, 0.07), Vector3(0, 0, -GROSOR / 2.0 + 0.05), _m_oscuro)
	# marco exterior (pintura clara)
	var z := GROSOR / 2.0 + 0.0
	PT.box(w, Vector3(1.38, 0.12, 0.10), Vector3(0, 0.71, z), _m_detalle)
	PT.box(w, Vector3(1.38, 0.12, 0.10), Vector3(0, -0.71, z), _m_detalle)
	PT.box(w, Vector3(0.12, 1.30, 0.10), Vector3(-0.63, 0, z), _m_detalle)
	PT.box(w, Vector3(0.12, 1.30, 0.10), Vector3(0.63, 0, z), _m_detalle)

# ---------------------------------------------------------------- zocalo e interior
func _zocalo() -> void:
	var zh := 0.4
	var y := zh / 2.0
	# frente: dos tramos, dejando libre la puerta
	var izq0 := -ancho / 2.0 - 0.06
	var izq1 := -ancho_puerta / 2.0 - 0.2
	PT.box(self, Vector3(izq1 - izq0, zh, 0.16), Vector3((izq0 + izq1) / 2.0, y, -0.02), _m_piedra)
	PT.box(self, Vector3(izq1 - izq0, zh, 0.16), Vector3(-(izq0 + izq1) / 2.0, y, -0.02), _m_piedra)
	for s in [-1.0, 1.0]:
		PT.box(self, Vector3(0.12, zh, fondo + 0.12), Vector3(s * ancho / 2.0, y, -fondo / 2.0), _m_piedra)
	PT.box(self, Vector3(ancho + 0.12, zh, 0.12), Vector3(0, y, -fondo), _m_piedra)

func _interior() -> void:
	# Piso y techo para que, al mirar por la puerta, no se vea el vacio.
	PT.box(self, Vector3(ancho - 2 * GROSOR, PISO_ALTO, fondo - 2 * GROSOR), Vector3(0, PISO_ALTO / 2.0, -fondo / 2.0), _m_oscuro, true, "PisoInterior")
	PT.box(self, Vector3(ancho - 0.1, 0.15, fondo - 0.1), Vector3(0, alto_muros - 0.075, -fondo / 2.0), _m_oscuro)
	if luz_interior:
		var l := OmniLight3D.new()
		l.position = Vector3(0, alto_muros - 0.8, -fondo / 2.0)
		l.light_color = Color(1.0, 0.72, 0.42)
		l.light_energy = 0.9
		l.omni_range = maxf(ancho, fondo) * 0.9
		l.shadow_enabled = false
		add_child(l)

# ---------------------------------------------------------------- techo a dos aguas
func _techo(es_casa: bool) -> void:
	var th := 0.14
	var ov := 0.55 if es_casa else 0.65
	var theta := deg_to_rad(inclinacion_techo)
	var half := ancho / 2.0
	var rise := tan(theta) * half
	var base_y := alto_muros

	# triangulo de fachada (con el mismo revestimiento de los muros)
	var pr := CSGPolygon3D.new()
	pr.polygon = PackedVector2Array([Vector2(-half, 0), Vector2(half, 0), Vector2(0, rise)])
	pr.mode = CSGPolygon3D.MODE_DEPTH
	pr.depth = fondo
	pr.material = _m_muro
	pr.position = Vector3(0, base_y, 0)
	add_child(pr)

	# dos aguas
	for s in [-1.0, 1.0]:
		var eave_x: float = s * (half + ov)
		var eave_y: float = rise - (half + ov) * tan(theta)
		var mid := Vector2(eave_x / 2.0, (rise + eave_y) / 2.0)
		var n := Vector2(s * sin(theta), cos(theta))
		var c := mid + n * (th / 2.0)
		var largo := (half + ov) / cos(theta)
		var losa := PT.box(self, Vector3(largo, th, fondo + 2.0 * ov), Vector3(c.x, base_y + c.y, -fondo / 2.0), _m_techo, false, "Techo")
		losa.rotation = Vector3(0, 0, -s * theta)
	# cumbrera
	PT.box(self, Vector3(0.34, 0.12, fondo + 2.0 * ov), Vector3(0, base_y + rise + 0.07, -fondo / 2.0), _m_oscuro)

# ---------------------------------------------------------------- porche (casa)
func _porche() -> void:
	var pw := minf(ancho - 1.2, 5.4)
	var pd := 1.9
	PT.box(self, Vector3(pw, PISO_ALTO, pd), Vector3(0, PISO_ALTO / 2.0, pd / 2.0), _m_oscuro, true, "PorchePiso")
	PT.box(self, Vector3(pw * 0.55, 0.09, 0.45), Vector3(0, 0.045, pd + 0.225), _m_oscuro, true, "PorcheEscalon")
	for s in [-1.0, 1.0]:
		PT.box(self, Vector3(0.16, 2.3, 0.16), Vector3(s * (pw / 2.0 - 0.15), PISO_ALTO + 1.15, pd - 0.15), _m_detalle, true, "PorchePoste")
	var inc := deg_to_rad(7.0)
	var largo := pd + 0.35
	var losa := PT.box(self, Vector3(pw + 0.5, 0.12, largo), Vector3(0, 2.78 - (largo / 2.0) * tan(inc), largo / 2.0), _m_techo, false, "PorcheTecho")
	losa.rotation = Vector3(inc, 0, 0)

# ---------------------------------------------------------------- chimenea (casa)
func _chimenea() -> void:
	var theta := deg_to_rad(inclinacion_techo)
	var half := ancho / 2.0
	var rise := tan(theta) * half
	var cx := half - 1.3
	var cz := -fondo * 0.6
	var base_y := alto_muros - 0.1
	var roof_y := alto_muros + rise * (1.0 - absf(cx) / half)
	var top_y := roof_y + 1.0
	var sy := top_y - base_y
	PT.box(self, Vector3(0.95, sy, 0.95), Vector3(cx, base_y + sy / 2.0, cz), _m_piedra, false, "Chimenea")
	PT.box(self, Vector3(1.18, 0.14, 1.18), Vector3(cx, top_y + 0.07, cz), _m_oscuro)

# ---------------------------------------------------------------- granero
func _detalles_granero() -> void:
	var h := alto_muros
	# Portones de dos hojas: cerrados en el acceso exterior y deslizados a los
	# costados cuando la entrada del patio ya está abierta.
	var hoja_ancho := ancho_puerta * 0.5
	var diag := sqrt(hoja_ancho * hoja_ancho + alto_puerta * alto_puerta) - 0.2
	for i in 2:
		var s := -1.0 if i == 0 else 1.0
		var x := s * (hoja_ancho * 0.5) if puerta_cerrada else s * (ancho_puerta * 0.5 + hoja_ancho * 0.5 + 0.08)
		var gate := PT.box(self, Vector3(hoja_ancho, alto_puerta, 0.14), Vector3(x, alto_puerta / 2.0, 0.08), _m_oscuro, puerta_cerrada, "PortonCorredizo_%d" % i)
		# Junta central visible; las vetas de madera hacen el resto.
		var seam := PT.box(gate, Vector3(0.045, alto_puerta - 0.16, 0.035), Vector3(0.0, 0.0, 0.09), _m_detalle)
		seam.name = "JuntaVertical"
		var brace := PT.box(self, Vector3(0.10, diag, 0.045), Vector3(x, alto_puerta / 2.0, 0.17), _m_detalle)
		brace.rotation.z = -s * atan2(hoja_ancho, alto_puerta)
	# Riel y herrajes hacen legible el sistema corredizo desde el patio.
	PT.box(self, Vector3(ancho_puerta + 0.5, 0.12, 0.18), Vector3(0.0, alto_puerta + 0.10, 0.09), _m_detalle)
	for s in [-1.0, 1.0]:
		PT.box(self, Vector3(0.10, alto_puerta + 0.22, 0.16), Vector3(s * (ancho_puerta / 2.0 + 0.18), (alto_puerta + 0.22) / 2.0, 0.09), _m_detalle)
	# ventana del henil, en el triangulo de arriba
	var theta := deg_to_rad(inclinacion_techo)
	var rise := tan(theta) * ancho / 2.0
	var y := h + minf(rise * 0.38, 1.3)
	PT.box(self, Vector3(1.5, 1.7, 0.12), Vector3(0, y, 0.05), _m_detalle)
	PT.box(self, Vector3(1.26, 1.46, 0.14), Vector3(0, y, 0.07), PT.flat(Color(0.05, 0.04, 0.04)))
