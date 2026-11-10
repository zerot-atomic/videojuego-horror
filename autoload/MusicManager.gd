extends Node
# ============================================================
# MusicManager (Autoload) — música de fondo con crossfade.
# Vive fuera de las escenas, así la música NO se corta al
# cambiar de zona, entrar a una Visión o pasar a los créditos.
#   MusicManager.play("fondo")   -> exploración
#   MusicManager.play("climax")  -> El Pozo
#   MusicManager.play("bueno")   -> Final Bueno "A Tiempo"
#   MusicManager.play("malo")    -> Final Malo "Demasiado Tarde"
# Si la pista pedida ya está sonando, no la reinicia.
# ============================================================

const TRACKS := {
	"fondo": "res://audio/musica_fondo.ogg",
	"climax": "res://audio/climax_pozo.ogg",
	"persecucion": "res://audio/persecucion.ogg",
	"bueno": "res://audio/final_bueno.ogg",
	"malo": "res://audio/final_malo.ogg",
}
const SILENT_DB := -60.0

var current: String = ""
var _players: Array = []
var _active: int = 0
var _tween: Tween = null
var _tension_tween: Tween = null
var _tension: float = 0.15

func _ready() -> void:
	# La música sigue sonando aunque el juego esté en pausa (menú de pausa).
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(2):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -16.0
		add_child(p)
		_players.append(p)

func _exit_tree() -> void:
	if _tween != null and _tween.is_running():
		_tween.kill()
	if _tension_tween != null and _tension_tween.is_running():
		_tension_tween.kill()
	for player in _players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	_players.clear()
	current = ""
	# PARCHE PORT 4.x: Tween ya no es un Node (no se agrega con add_child).
	# Ahora se crea uno nuevo con create_tween() cada vez que hace falta.

func play(track: String, loop: bool = true, fade: float = 1.5) -> void:
	if track == current and _players[_active].playing:
		return
	var path = TRACKS.get(track, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if stream == null:
		return
	stream.set("loop", loop)

	if _tween:
		_tween.kill()
	var old = _players[_active]
	_active = 1 - _active
	var incoming = _players[_active]
	incoming.stop()
	incoming.stream = stream
	incoming.volume_db = SILENT_DB
	incoming.play()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(incoming, "volume_db", _volume_for_tension(), fade).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if old.playing:
		_tween.tween_property(old, "volume_db", SILENT_DB, fade).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_tween.chain().tween_callback(old.stop)
	current = track

func set_tension(value: float, fade: float = 0.6) -> void:
	var new_tension := clampf(value, 0.0, 1.0)
	if absf(new_tension - _tension) < 0.025:
		return
	_tension = new_tension
	if _players.is_empty():
		return
	var p: AudioStreamPlayer = _players[_active]
	if not p.playing:
		return
	if _tension_tween:
		_tension_tween.kill()
	_tension_tween = create_tween()
	_tension_tween.tween_property(p, "volume_db", _volume_for_tension(), fade).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _volume_for_tension() -> float:
	return lerpf(-16.0, -2.0, _tension)

func set_threat_pressure(pressure: float, base_track: String, base_tension: float) -> void:
	var intensity := clampf(pressure, 0.0, 1.0)
	if intensity > 0.06:
		if ResourceLoader.exists(TRACKS["persecucion"]) and current != "persecucion":
			_tension = maxf(base_tension, 0.75 + intensity * 0.25)
			play("persecucion", true, 0.8)
		set_tension(maxf(base_tension, 0.48 + intensity * 0.52), 0.35)
		return
	if current == "persecucion":
		_tension = base_tension
		play(base_track, true, 1.0)
	set_tension(base_tension, 0.9)

func fade_out(duration: float = 2.0) -> void:
	if _tween:
		_tween.kill()
	for i in range(_players.size()):
		if i != _active and _players[i].playing:
			_players[i].stop()
	var p = _players[_active]
	if p.playing:
		_tween = create_tween()
		_tween.tween_property(p, "volume_db", SILENT_DB, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_tween.tween_callback(p.stop)
	current = ""
