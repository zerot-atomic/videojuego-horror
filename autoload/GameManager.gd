extends Node
# ============================================================
# GameManager (Autoload / Singleton) — versión Godot 3.x
# Estado global de "La Cosecha del Color":
# cordura, temporizador de corrupción, pistas, visiones,
# guardado/carga y determinación de finales.
# ============================================================

const SAVE_PATH := "user://savegame.json"
const SETTINGS_PATH := "user://settings.json"

# --- Configuración (Opciones) ---
var master_volume: float = 1.0   # 0.0 - 1.0
var fullscreen: bool = false

# --- Estado de juego ---
var max_sanity: float = 100.0
var sanity: float = 100.0
var difficulty_id: String = "normal"
var sanity_drain_multiplier: float = 1.0
var terror_multiplier: float = 1.0

# Duración total antes de que la corrupción "gane" (segundos).
var corruption_time_limit: float = 900.0 # 15 minutos
var corruption_time_elapsed: float = 0.0

const DIFFICULTIES := {
	"story": {
		"name": "Modo Historia",
		"description": "Explora con calma. La cordura cae poco y la corrupción tarda más.",
		"sanity_drain": 0.35, "time_limit": 1800.0, "terror": 0.65, "enemy": 0.78,
	},
	"normal": {
		"name": "Normal",
		"description": "La experiencia de terror equilibrada, con presión gradual.",
		"sanity_drain": 1.0, "time_limit": 900.0, "terror": 1.0, "enemy": 1.0,
	},
		"hard": {
		"name": "Difícil",
		"description": "La cordura se agota antes y Grapper reacciona con más intensidad.",
			"sanity_drain": 1.35, "time_limit": 1200.0, "terror": 1.3, "enemy": 1.12,
	},
	"lovecraft": {
		"name": "Lovecraft",
		"description": "Horror cósmico extremo: recursos escasos, presión intensa y poca tolerancia al error. Siempre es posible sobrevivir.",
			"sanity_drain": 1.8, "time_limit": 1200.0, "terror": 1.65, "enemy": 1.22,
	},
}
var enemy_difficulty_multiplier: float = 1.0

# --- Niebla centralizada (única fuente de verdad) ---
# Silent Hill style: fog siempre activo, parámetros por zona
const ZONE_FOG := {
	"camino_entrada": {
		"enabled": true, "mode": Environment.FOG_MODE_DEPTH,
		"light_color": Color(0.55, 0.50, 0.45, 1),
		"depth_begin": 5.0, "depth_end": 35.0, "depth_curve": 1.0,
		"bg_mode": 1, "bg_color": Color(0.55, 0.52, 0.48, 1),
		"ambient_color": Color(0.72, 0.65, 0.58, 1), "ambient_energy": 0.75,
	},
	"casa_principal": {
		"enabled": true, "mode": Environment.FOG_MODE_DEPTH,
		"light_color": Color(0.40, 0.35, 0.32, 1),
		"depth_begin": 6.0, "depth_end": 40.0, "depth_curve": 1.0,
		"bg_mode": 1, "bg_color": Color(0.03, 0.025, 0.035, 1),
		"ambient_color": Color(0.48, 0.42, 0.38, 1), "ambient_energy": 0.52,
	},
	"campo_cultivo": {
		"enabled": true, "mode": Environment.FOG_MODE_DEPTH,
		"light_color": Color(0.42, 0.38, 0.32, 1),
		"depth_begin": 4.0, "depth_end": 30.0, "depth_curve": 1.0,
		"bg_mode": 1, "bg_color": Color(0.45, 0.42, 0.38, 1),
		"ambient_color": Color(0.65, 0.58, 0.52, 1), "ambient_energy": 0.65,
	},
	"pozo": {
		"enabled": true, "mode": Environment.FOG_MODE_DEPTH,
		"light_color": Color(0.25, 0.20, 0.28, 1),
		"depth_begin": 2.0, "depth_end": 15.0, "depth_curve": 1.0,
		"bg_mode": 1, "bg_color": Color(0.02, 0.015, 0.025, 1),
		"ambient_color": Color(0.30, 0.25, 0.30, 1), "ambient_energy": 0.30,
	},
	"crater_meteorito": {
		"enabled": true, "mode": Environment.FOG_MODE_DEPTH,
		"light_color": Color(0.50, 0.35, 0.42, 1),
		"depth_begin": 3.0, "depth_end": 25.0, "depth_curve": 1.0,
		"bg_mode": 1, "bg_color": Color(0.25, 0.15, 0.20, 1),
		"ambient_color": Color(0.55, 0.35, 0.40, 1), "ambient_energy": 0.55,
	},
	"establo": {
		"enabled": true, "mode": Environment.FOG_MODE_DEPTH,
		"light_color": Color(0.42, 0.38, 0.34, 1),
		"depth_begin": 4.0, "depth_end": 28.0, "depth_curve": 1.0,
		"bg_mode": 1, "bg_color": Color(0.18, 0.15, 0.12, 1),
		"ambient_color": Color(0.42, 0.35, 0.30, 1), "ambient_energy": 0.45,
	},
	"atico": {
		"enabled": true, "mode": Environment.FOG_MODE_DEPTH,
		"light_color": Color(0.50, 0.45, 0.40, 1),
		"depth_begin": 5.0, "depth_end": 35.0, "depth_curve": 1.0,
		"bg_mode": 1, "bg_color": Color(0.20, 0.18, 0.16, 1),
		"ambient_color": Color(0.50, 0.45, 0.40, 1), "ambient_energy": 0.50,
	},
	"bosque": {
		"enabled": true, "mode": Environment.FOG_MODE_DEPTH,
		"light_color": Color(0.40, 0.48, 0.38, 1),
		"depth_begin": 3.0, "depth_end": 22.0, "depth_curve": 1.0,
		"bg_mode": 1, "bg_color": Color(0.10, 0.15, 0.10, 1),
		"ambient_color": Color(0.35, 0.45, 0.35, 1), "ambient_energy": 0.40,
	},
	"laberinto": {
		"enabled": true, "mode": Environment.FOG_MODE_DEPTH,
		"light_color": Color(0.25, 0.22, 0.28, 1),
		"depth_begin": 3.0, "depth_end": 20.0, "depth_curve": 1.0,
		"bg_mode": 1, "bg_color": Color(0.002, 0.002, 0.004, 1),
		"ambient_color": Color(0.16, 0.13, 0.20, 1), "ambient_energy": 0.34,
	},
}

# --- Parámetros de juego centralizados (única fuente de verdad) ---
# Todos los valores de velocidad, sensibilidad, tiempos y daño viven aquí.
# Los scripts leen de GameManager.GAMEPLAY en lugar de tener @export duplicados.
const GAMEPLAY := {
	"player": {
		"walk_speed": 3.2,
		"run_speed": 6.0,
		"crouch_speed": 1.45,
		"backward_speed_factor": 0.6,
		"rotation_speed": 2.0,
		"camera_follow_speed": 2.6,
		"body_turn_speed": 12.0,
		"gravity": -18.0,
		"camera_distance": 4.3,
		"camera_height": 1.6,
		"camera_pitch_min": -0.5,
		"camera_pitch_max": 0.6,
		"crouch_capsule_height": 1.10,
		"stand_capsule_height": 1.8,
		"collision_y_offset": 0.04,
		"camera_fov": 66.0,
		"camera_near": 0.1,
		"camera_far": 150.0,
		"floor_snap_length": 0.35,
		"anim_idle_speed_scale": 0.45,
		"threat_distance_threshold": 24.0,
		"lantern_energy": 1.35,
		"lantern_range": 4.0,
		"lantern_attenuation": 1.4,
		"lantern_color": Color(1.0, 0.78, 0.55),
		"lantern_position": Vector3(0.0, 1.45, 0.12),
		"movement_response": 72.0,
		"movement_deceleration": 84.0,
		"story_speed_multiplier": 1.12,
	},
	"enemy_wrapper": {
		"patrol_speed": 1.9,
		"search_speed": 2.8,
		"chase_speed": 5.2,
		"turn_speed": 3.5,
		"attack_range": 1.3,
		"attack_cooldown": 1.6,
		"attack_sanity_damage": 40.0,
		"sight_range": 15.0,
		"sight_fov_deg": 110.0,
		"crouch_sight_factor": 0.45,
		"grass_sight_factor": 0.5,
		"lose_time": 4.0,
		"lose_range": 26.0,
		"scream_cooldown": 20.0,
		"stumble_chance": 0.35,
		"stumble_duration": 1.4,
		"stumble_cooldown_time": 3.0,
		"gravity": -18.0,
	},
	"labyrinth": {
		"world_size": 60.0,
		"wall_height": 3.3,
		"wall_thickness": 0.42,
		"exit_width": 3.5,
		"exit_height": 3.3,
		"exit_depth": 1.5,
		"exit_spawn_offset": 2.5,
		"run_multipliers": {"story": 1.12, "normal": 1.08, "hard": 1.22, "lovecraft": 1.30},
		"chase_close_ratio": {"story": 0.82, "normal": 0.92, "hard": 1.05, "lovecraft": 1.05},
		"chase_far_ratio": {"story": 0.94, "normal": 1.08, "hard": 1.11, "lovecraft": 1.14},
		"stumble_distance_threshold": 3.5,
		"stumble_distance_range": 9.5,
		"cell_size": 6.67,
		"difficulty_config": {
			"story": {"cols": 7, "rows": 7, "seed": 11},
			"normal": {"cols": 9, "rows": 9, "seed": 23},
			"hard": {"cols": 11, "rows": 11, "seed": 37},
			"lovecraft": {"cols": 13, "rows": 13, "seed": 51},
		},
		"grapper_min_distance_cells": 6,
		"light_fill_height": 2.5,
		"light_fill_color": Color(0.38, 0.24, 0.62),
		"light_fill_energy": 1.1,
		"light_fill_range": 32.0,
		"max_dead_end_markers": 6,
		"max_junction_guides": 8,
		"ambient_dead_trees": 8,
		"ambient_stumps": 6,
		"ambient_mushrooms": 8,
		"ambient_rocks": 10,
	},
	"hud": {
		"sanity_bar_width": 200,
		"corruption_pulse_speed": 0.19,
		"message_duration": 3.0,
		"pickup_notification_duration": 4.0,
	},
	"zone": {
		"crossfade_duration": 1.8,
		"atico_floor_height": 1.53,
		"ground_collision_size": Vector3(200.0, 1.0, 200.0),
		"ground_collision_position": Vector3(0, -0.5, 0),
		"fallback_light_energy": 0.6,
		"fallback_light_range": 12.0,
		"fallback_light_position": Vector3(0, 2.5, 0),
		"corruption_overlay_hue": 0.74,
		"corruption_overlay_saturation": 0.36,
		"corruption_overlay_value": 0.34,
		"corruption_overlay_alpha_base": 0.0,
		"spawn_y_offset": 0.1,
		"establo_patrol_speed_multiplier": 1.0,
		"labyrinth_chase_speed_multiplier": 1.05,
		"labyrinth_attack_sanity_damage": 24.0,
		"labyrinth_sight_range_multiplier": 0.65,
		"labyrinth_lose_time": 3.0,
	},
	"sanity": {
		"max_sanity": 100.0,
		"regen_rate_low_corruption": 1.5,
		"run_drain_per_sec_high_corruption": 8.0,
	},
	"corruption": {
		"time_limit_base": 900.0,
		"overlay_hue_base": 0.74,
		"overlay_hue_variance": 0.07,
		"overlay_saturation": 0.36,
		"overlay_value": 0.34,
		"overlay_alpha_base": 0.16,
		"overlay_alpha_variance": 0.025,
		"overlay_pulse_speed": 0.7,
	},
	"interaction": {
		"interaction_radius": 1.2,
		"crouch_noise_radius": 3.0,
		"walk_noise_radius": 9.0,
		"run_noise_radius": 18.0,
	},
}

var game_over: bool = false
var journal_open: bool = false
var show_intro_on_next_zone: bool = false

var current_zone_id: String = "camino_entrada"
var previous_zone_id: String = ""

var clues_found: Dictionary = {}      # clue_id -> true
var journal_entries: Array = []       # [{name, description}]
var visions_seen: Dictionary = {"padre": false, "madre": false, "hijo": false}
var pending_vision: Dictionary = {}

# --- Inventario (sección 22.1: puzles de objetos combinables) ---
# Los objetos viven en la misma tabla CLUES (con is_item = true) y se
# integran al Diario existente en una sección aparte; no hay ventana
# de inventario nueva.
var inventory: Dictionary = {}        # item_id -> true
var inventory_entries: Array = []     # [{name, description}]

# Referencias a nodos de UI activos de la zona actual (los asigna Zone.gd)
var active_journal = null
var active_pause_menu = null
var active_hud = null
var corruption_overlay: ColorRect = null

# --- Mensajes de confirmación (aviso inferior tipo "Has recogido una nota") ---
# message_carry guarda mensajes que deben mostrarse en la PRÓXIMA escena
# (por ejemplo al cambiar de zona o volver de una Visión).
var message_carry: Array = []
var last_announced_zone: String = ""
const ICON_DIR := "res://art3d/icons/"

const ZONE_NAMES := {
	"camino_entrada": "Camino de Entrada",
	"casa_principal": "Casa Principal",
	"campo_cultivo": "Campo de Cultivo",
	"pozo": "El Pozo",
	"crater_meteorito": "Cráter del Meteorito",
	"establo": "Establo",
	"atico": "Ático",
	"bosque": "Bosque",
	"laberinto": "El Laberinto",
}

# --- Rutas de escenas por zona ---
# Apuntando ya a las escenas 3D (scenes3d/Zone3D_*.tscn). Las 2D originales
# (scenes/Zone*.tscn) se quedan en el proyecto sin usar, por si quieres
# comparar o regresar a ellas temporalmente.
const ZONE_SCENES := {
	"camino_entrada": "res://scenes3d/Zone3D_camino_entrada.tscn",
	"casa_principal": "res://scenes3d/Zone3D_casa_principal.tscn",
	"campo_cultivo": "res://scenes3d/Zone3D_campo_cultivo.tscn",
	"pozo": "res://scenes3d/Zone3D_pozo.tscn",
	"crater_meteorito": "res://scenes3d/Zone3D_crater_meteorito.tscn",
	"establo": "res://scenes3d/Zone3D_establo.tscn",
	"atico": "res://scenes3d/Zone3D_atico.tscn",
	"bosque": "res://scenes3d/Zone3D_bosque.tscn",
	"laberinto": "res://scenes3d/Zone3D_laberinto.tscn",
}

# --- Salidas entre zonas: zona -> lista de {x, y, target} ---
# Coordenadas ajustadas al plano fijo de 1672x941 y a la composición real
# de cada fondo (art/backgrounds/*.png).
const EXITS := {
	"camino_entrada": [
		{"x": 1230.0, "y": 430.0, "target": "casa_principal"}, # puerta de la granja, arriba a la derecha
		{"x": 1600.0, "y": 470.0, "target": "crater_meteorito"}, # linde de la cerca hacia el campo, derecha
	],
	"casa_principal": [
		{"x": 60.0, "y": 420.0, "target": "campo_cultivo"}, # puerta/marco a la izquierda del cuarto
		{"x": 1600.0, "y": 280.0, "target": "atico"}, # escalera oculta junto a la chimenea
		{"x": 100.0, "y": 800.0, "target": "camino_entrada"}, # vuelta al camino de entrada (puerta principal)
	],
	"campo_cultivo": [
		{"x": 900.0, "y": 640.0, "target": "pozo"}, # camino entre los surcos hacia el pozo
		{"x": 1300.0, "y": 260.0, "target": "establo"}, # el establo se ve al fondo, arriba a la derecha
		{"x": 40.0, "y": 250.0, "target": "laberinto", "requires_item": "aceite_lampara",
		 "locked_message": "Está demasiado oscuro para internarse ahí sin algo que alumbre el camino."}, # linde del bosque, arriba a la izquierda
		{"x": 100.0, "y": 800.0, "target": "casa_principal"}, # vuelta a la casa principal (puerta lateral)
	],
	"pozo": [],
	"crater_meteorito": [
		{"x": 150.0, "y": 650.0, "target": "camino_entrada"}, # vuelta al camino de entrada
	],
	"establo": [
		{"x": 150.0, "y": 820.0, "target": "campo_cultivo"}, # puerta del establo
	],
	"atico": [
		{"x": 700.0, "y": 850.0, "target": "casa_principal"}, # escalera de vuelta
	],
	"bosque": [
		{"x": 1500.0, "y": 780.0, "target": "laberinto"}, # el sendero se deforma y conduce al laberinto
	],
	"laberinto": [
		{"x": 1500.0, "y": 780.0, "target": "bosque"}, # salida al bosque
		{"x": 100.0, "y": 800.0, "target": "campo_cultivo"}, # salida al campo de cultivo
	],
}

# --- Pistas por zona ---
# Ajustadas para calzar con "The Colour Out of Space" de H.P. Lovecraft
# (familia Gardner: Nahum el padre, Nabby la madre; el pozo como origen
# del color, la vegetación y el ganado volviéndose grises y quebradizos).
# is_key = true -> dispara una Visión de Personaje al examinarla.
# is_ending_trigger = true -> no es una pista coleccionable, decide el final.
const CLUES := {
	"camino_entrada": [
		{
			"id": "buzon", "msg": "Has recogido una carta", "name": "Buzón con una carta sin enviar",
			"x": 335.0, "y": 545.0, "is_key": false,
			"desc": "Un buzón viejo junto al sendero. Dentro hay una carta a un pariente en Arkham, nunca enviada: habla de una fruta que crece enorme y brillante, pero que sabe a ceniza.",
		},
	],
	"casa_principal": [
		{
			"id": "fotografias", "msg": "Has recogido una fotografía", "name": "Fotografías familiares",
			"x": 430.0, "y": 300.0, "is_key": false,
			"desc": "Retratos de la familia Gardner en mejores tiempos, antes de que cayera la piedra junto al pozo.",
		},
		{
			"id": "radio", "msg": "Has recogido una radio", "name": "Radio de onda corta",
			"x": 1230.0, "y": 430.0, "is_key": false,
			"desc": "Un aparato de radio. Al encenderlo solo se escucha estática distorsionada.",
		},
		{
			"id": "manivela_pozo", "msg": "Has recogido una manivela de hierro", "name": "Manivela de hierro",
			"x": 800.0, "y": 600.0, "is_item": true, "item_id": "manivela_pozo",
			"desc": "Una manivela de hierro cubierta de polvo, guardada en un cajón junto a las fotografías. Parece encajar en algún mecanismo.",
		},
		{
			"id": "aceite_lampara", "msg": "Has recogido una lata de aceite", "name": "Lata de aceite de lámpara",
			"x": 1450.0, "y": 750.0, "is_item": true, "item_id": "aceite_lampara",
			"desc": "Una lata medio llena de aceite para lámparas, junto a la chimenea.",
		},
	],
	"campo_cultivo": [
		{
			"id": "maquinaria", "msg": "Has examinado la maquinaria abandonada", "name": "Maquinaria agrícola abandonada",
			"x": 1180.0, "y": 430.0, "is_key": false,
			"desc": "Maquinaria detenida a medio camino, cubierta por un gris quebradizo que se desmorona al tocarlo. Las huellas de arrastre siguen hacia el establo.",
		},
	],
	"establo": [
		{
			"id": "ganado_establo", "msg": "Has examinado al ganado enfermo", "name": "Ganado enfermo en el establo",
			"x": 1050.0, "y": 600.0, "is_key": true, "character": "padre",
			"requires_item": "llave_oxidada",
			"locked_desc": "Un candado oxidado sella la reja del corral. Vas a necesitar algo para forzarlo.",
			"desc": "Lo que queda del ganado yace entre la paja, con la piel gris y quebradiza, encogida sobre los huesos como cerámica vieja a punto de romperse.",
			"vision_text": "Ves a Nahum Gardner intentando sacar al ganado del establo mientras la piel de los animales se encoge, se pone gris y se agrieta como cerámica vieja.",
			"vision_line": "Otra vez tú. Van tres esta semana.",
		},
		{
			"id": "marcas_establo", "msg": "Has examinado las marcas de los pesebres", "name": "Marcas en los pesebres",
			"x": 250.0, "y": 560.0, "is_key": false,
			"desc": "Arañazos profundos en la madera de los pesebres, a una altura que ningún animal de la granja debería alcanzar.",
		},
	],
	"atico": [
		{
			"id": "diario_madre", "msg": "Has recogido el diario de Nabby", "name": "Diario de Nabby Gardner",
			"x": 1350.0, "y": 600.0, "is_key": true, "character": "madre",
			"desc": "Sus últimas páginas ya no tienen frases completas, solo describen algo que se mueve entre las ramas sin que sople el viento, y a la propia familia encerrándola aquí arriba \"por su bien\".",
			"vision_text": "Ves a Nabby Gardner atada a la cama del ático, mirando fijamente el círculo de luz de la ventana, mientras algo en su expresión ya no es del todo suyo.",
			"vision_line": "Si no lo miro, no me mira. Si no lo nombro, no me nombra.",
		},
		{
			"id": "mecedora", "msg": "Has examinado la mecedora", "name": "Mecedora junto a la ventana",
			"x": 480.0, "y": 680.0, "is_key": false,
			"desc": "Una mecedora vieja, todavía meciéndose muy levemente, como si alguien acabara de dejarla.",
		},
	],
	"bosque": [
		{
			"id": "zapato_hijo", "msg": "Has recogido un zapato pequeño", "name": "Zapato pequeño entre las hojas",
			"x": 180.0, "y": 870.0, "is_key": true, "character": "hijo",
			"desc": "Un zapato infantil, abandonado junto a la raíz de un árbol. No hay más huellas alrededor, como si quien lo llevaba hubiera dejado de caminar de golpe.",
			"vision_text": "Ves al hijo internándose solo en el bosque, murmurando sobre \"los colores que se mueven entre los árboles\", fascinado y aterrado a la vez por una luz que nadie más puede ver.",
			"vision_line": "Aquí no hace tanto frío como en la casa. ¿Mamá?",
		},
	],
	"crater_meteorito": [
		{
			"id": "piedra_impacto", "msg": "Has examinado la piedra del cráter", "name": "La piedra del cráter",
			"x": 870.0, "y": 650.0, "is_key": false,
			"desc": "Un fragmento de roca aún incrustado en el cráter, recorrido por vetas de un color que cambia apenas se le mira fijamente, como si no terminara de decidir qué color es.",
		},
		{
			"id": "recorte_periodico", "msg": "Has recogido un recorte de periódico", "name": "Recorte de periódico",
			"x": 150.0, "y": 600.0, "is_key": false,
			"desc": "Un recorte enganchado en un tallo seco: investigadores de una universidad cercana examinaron una muestra de la piedra y no lograron clasificarla en ningún elemento conocido.",
		},
		{
			"id": "llave_oxidada", "msg": "Has recogido una llave oxidada", "name": "Llave oxidada",
			"x": 500.0, "y": 780.0, "is_item": true, "item_id": "llave_oxidada",
			"desc": "Una llave oxidada, casi soldada por el óxido, tirada entre los restos calcinados alrededor del cráter.",
		},
	],
	"pozo": [
		{
			"id": "descender", "name": "Descender al pozo",
			"x": 836.0, "y": 480.0, "is_ending_trigger": true, "ending_type": "decision",
			"requires_item": "manivela_pozo",
			"locked_desc": "Al mecanismo del pozo le falta una pieza; no puedes operarlo así.",
			"desc": "El origen de todo. Algo vive ahí abajo, y todavía puedes bajar a buscar a la familia.",
		},
		{
			"id": "retirarse", "name": "Retirarse",
			"x": 836.0, "y": 900.0, "is_ending_trigger": true, "ending_type": "retreat",
			"desc": "El camino de vuelta. Aún puedes irte sin bajar al pozo.",
		},
	],
}

func _ready() -> void:
	load_settings()

func _process(delta: float) -> void:
	if game_over:
		return
	# No avanza la corrupción si el juego está en pausa (menú, visión, final)
	if get_tree().paused:
		return
	corruption_time_elapsed += delta
	if corruption_time_elapsed >= corruption_time_limit:
		trigger_ending(false)
		return
	# Regeneración leve de cordura si la corrupción local aún es baja.
	if corruption_level() < 0.3 and sanity < max_sanity:
		sanity = min(max_sanity, sanity + delta * 1.5)

func corruption_level() -> float:
	return clamp(corruption_time_elapsed / corruption_time_limit, 0.0, 1.0)

func drain_sanity(amount: float) -> void:
	sanity = max(0.0, sanity - amount * sanity_drain_multiplier)
	if sanity <= 0.0 and not game_over:
		trigger_ending(false)

func all_visions_seen() -> bool:
	return visions_seen.get("padre", false) and visions_seen.get("madre", false) and visions_seen.get("hijo", false)

func toggle_journal() -> void:
	if active_journal:
		active_journal.toggle()
		journal_open = active_journal.is_open

func toggle_pause() -> void:
	if active_pause_menu:
		active_pause_menu.toggle()

func _find_clue(clue_id: String):
	for zone_clues in CLUES.values():
		for c in zone_clues:
			if c.id == clue_id:
				return c
	return null

func resolve_icon(clue_id: String, is_item: bool, is_locked: bool, icon_file: String = "") -> String:
	# Devuelve la ruta del ícono a usar (o "" si no hay ninguno todavía).
	# Mismo orden de búsqueda que Interactable.gd.
	var candidates = []
	if icon_file != "":
		candidates.append(ICON_DIR + icon_file)
	if clue_id != "":
		candidates.append(ICON_DIR + clue_id + ".png")
	if is_locked:
		candidates.append(ICON_DIR + "candado_generico.png")
	elif is_item:
		candidates.append(ICON_DIR + "objeto_generico.png")
	else:
		candidates.append(ICON_DIR + "pista_generica.png")
	for path in candidates:
		if ResourceLoader.exists(path):
			return path
	return ""

func _item_name(item_id: String) -> String:
	for zone_clues in CLUES.values():
		for c in zone_clues:
			if c.get("item_id", c.id) == item_id:
				return c.name
	return item_id

func _pickup_text(clue: Dictionary) -> String:
	return clue.get("msg", "Has examinado: " + clue.name)

func _locked_message(text: String) -> void:
	show_message(text, resolve_icon("", false, true), "Bloqueado")

func examine_clue(clue_id: String) -> void:
	var clue = _find_clue(clue_id)
	if clue == null:
		return

	if clue.get("is_ending_trigger", false):
		var req_end = clue.get("requires_item", "")
		if req_end != "" and not inventory.get(req_end, false):
			_locked_message(clue.get("locked_desc", "Todavía no puedes hacer esto."))
			return
		match clue.get("ending_type", ""):
			"decision":
				decide_ending()
			"retreat":
				trigger_ending(false)
		return

	if clues_found.get(clue_id, false):
		return

	var icon = resolve_icon(clue.id, clue.get("is_item", false), false, clue.get("icon", ""))

	# Objeto recogible (sección 22.1): va al inventario y a la sección
	# "Objetos" del Diario, no a las pistas narrativas.
	if clue.get("is_item", false):
		var item_id = clue.get("item_id", clue_id)
		inventory[item_id] = true
		inventory_entries.append({"name": clue.name, "description": clue.desc})
		clues_found[clue_id] = true
		show_message(_pickup_text(clue), icon, "Guardado en Objetos del Diario")
		save_game()
		return

	# Candado narrativo: pista/objeto que exige tener cierto item antes de
	# revelarse. No se marca como encontrada para poder reintentar luego.
	var req = clue.get("requires_item", "")
	if req != "" and not inventory.get(req, false):
		_locked_message(clue.get("locked_desc", "Parece que hace falta algo más para esto."))
		return

	clues_found[clue_id] = true
	journal_entries.append({"name": clue.name, "description": clue.desc})

	var used_icon = ""
	if req != "":
		used_icon = resolve_icon(req, true, false)

	if clue.get("is_key", false):
		visions_seen[clue.character] = true
		pending_vision = clue
		# La Visión es otra escena: los avisos se muestran al volver a la zona.
		if req != "":
			show_message("Has usado: " + _item_name(req), used_icon, "", true)
		show_message(_pickup_text(clue), icon, "Añadido al Diario", true)
		save_game()
		get_tree().change_scene_to_file("res://scenes3d/Vision3D.tscn")
	else:
		if req != "":
			show_message("Has usado: " + _item_name(req), used_icon)
		show_message(_pickup_text(clue), icon, "Añadido al Diario")
		save_game()

# Muestra un aviso inferior con ícono opcional. Si carry = true (o no hay HUD
# activo) el aviso se guarda y aparece en la siguiente escena con HUD.
func show_message(text: String, icon_path: String = "", sub: String = "", carry: bool = false) -> void:
	if carry or not is_instance_valid(active_hud):
		message_carry.append({"text": text, "icon": icon_path, "sub": sub})
	else:
		active_hud.show_message(text, icon_path, sub)

func decide_ending() -> void:
	if corruption_time_elapsed < corruption_time_limit and all_visions_seen():
		trigger_ending(true)
	else:
		trigger_ending(false)

func trigger_ending(good: bool) -> void:
	if game_over:
		return
	game_over = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes3d/EndingGood3D.tscn" if good else "res://scenes3d/EndingBad3D.tscn")

var pending_spawn_marker: String = ""

func change_zone(zone_id: String, spawn_marker: String = "") -> Error:
	if not ZONE_SCENES.has(zone_id):
		return ERR_INVALID_PARAMETER
	var destination: String = ZONE_SCENES[zone_id]
	if not ResourceLoader.exists(destination):
		return ERR_FILE_NOT_FOUND
	var old_zone := current_zone_id
	var old_previous_zone := previous_zone_id
	previous_zone_id = old_zone
	current_zone_id = zone_id
	pending_spawn_marker = spawn_marker
	var change_error: Error = get_tree().change_scene_to_file(destination)
	if change_error != OK:
		current_zone_id = old_zone
		previous_zone_id = old_previous_zone
		pending_spawn_marker = ""
		return change_error
	save_game()
	return OK

func set_difficulty(id: String) -> void:
	difficulty_id = id if DIFFICULTIES.has(id) else "normal"
	var profile: Dictionary = DIFFICULTIES[difficulty_id]
	sanity_drain_multiplier = float(profile.sanity_drain)
	corruption_time_limit = float(profile.time_limit)
	terror_multiplier = float(profile.terror)
	enemy_difficulty_multiplier = float(profile.enemy)

func get_difficulty_name() -> String:
	return String(DIFFICULTIES.get(difficulty_id, DIFFICULTIES["normal"]).name)

func new_game(selected_difficulty: String = "") -> void:
	if selected_difficulty != "":
		set_difficulty(selected_difficulty)
	else:
		set_difficulty(difficulty_id)
	sanity = max_sanity
	corruption_time_elapsed = 0.0
	game_over = false
	journal_open = false
	show_intro_on_next_zone = true
	clues_found.clear()
	journal_entries.clear()
	inventory.clear()
	inventory_entries.clear()
	message_carry.clear()
	last_announced_zone = ""
	visions_seen = {"padre": false, "madre": false, "hijo": false}
	current_zone_id = "camino_entrada"
	get_tree().paused = false
	save_game()
	get_tree().change_scene_to_file(ZONE_SCENES[current_zone_id])

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func apply_settings() -> void:
	var idx = AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(master_volume, 0.0001)))
		AudioServer.set_bus_mute(idx, master_volume <= 0.0)
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (fullscreen) else Window.MODE_WINDOWED

func save_settings() -> void:
	var data := {
		"master_volume": master_volume,
		"fullscreen": fullscreen,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	file.store_string(JSON.new().stringify(data))
	file.close()

func load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		var test_json_conv = JSON.new()
		test_json_conv.parse(file.get_as_text())
		var parsed = test_json_conv.get_data()
		file.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			master_volume = parsed.get("master_volume", 1.0)
			fullscreen = parsed.get("fullscreen", false)
		apply_settings()

func save_game() -> void:
	var data := {
		"sanity": sanity,
		"corruption_time_elapsed": corruption_time_elapsed,
		"current_zone_id": current_zone_id,
		"clues_found": clues_found,
		"journal_entries": journal_entries,
		"visions_seen": visions_seen,
		"inventory": inventory,
		"inventory_entries": inventory_entries,
		"difficulty_id": difficulty_id,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.new().stringify(data))
	file.close()

func load_game() -> void:
	if not has_save():
		new_game()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	var test_json_conv = JSON.new()
	test_json_conv.parse(text)
	var parsed = test_json_conv.get_data()
	if typeof(parsed) != TYPE_DICTIONARY:
		new_game()
		return
	set_difficulty(String(parsed.get("difficulty_id", "normal")))
	show_intro_on_next_zone = false
	sanity = parsed.get("sanity", max_sanity)
	corruption_time_elapsed = parsed.get("corruption_time_elapsed", 0.0)
	current_zone_id = parsed.get("current_zone_id", "camino_entrada")
	clues_found = parsed.get("clues_found", {})
	journal_entries = parsed.get("journal_entries", [])
	visions_seen = parsed.get("visions_seen", {"padre": false, "madre": false, "hijo": false})
	inventory = parsed.get("inventory", {})
	inventory_entries = parsed.get("inventory_entries", [])
	message_carry.clear()
	last_announced_zone = ""
	game_over = false
	get_tree().paused = false
	get_tree().change_scene_to_file(ZONE_SCENES.get(current_zone_id, ZONE_SCENES["camino_entrada"]))

# ============================================================
# Añadido para la migración a 3D (Interactable3D / ExitArea3D ya no
# reciben su data por parámetro desde Zone3D: la buscan ellos mismos
# aquí por clue_id, porque ahora viven como nodos colocados a mano
# en cada room_scene, no generados por código desde x,y).
# ============================================================
func get_clue_data(zone_id: String, clue_id: String) -> Dictionary:
	for clue in CLUES.get(zone_id, []):
		if clue.id == clue_id:
			return clue
	return {}
