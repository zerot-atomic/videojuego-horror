extends CanvasLayer

const SCREAMER_IMAGE := preload("res://art3d/thewrapper/screamer_face.png")
const SCREAMER_AUDIO := preload("res://audio/scream_distorted.wav")

var _active := false
var _texture: TextureRect
var _audio: AudioStreamPlayer
var _flash: ColorRect

func _ready() -> void:
	layer = 100
	_texture = TextureRect.new()
	_texture.texture = SCREAMER_IMAGE
	_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_texture.visible = false
	add_child(_texture)
	_flash = ColorRect.new()
	_flash.color = Color(0.58, 0.015, 0.035, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)
	_audio = AudioStreamPlayer.new()
	_audio.stream = SCREAMER_AUDIO
	_audio.volume_db = -7.0
	add_child(_audio)

func trigger() -> void:
	if _active:
		return
	_active = true
	_audio.play()
	_texture.visible = true
	var tween := create_tween()
	tween.set_loops(5)
	tween.tween_property(_flash, "color:a", 0.30, 0.035)
	tween.tween_property(_flash, "color:a", 0.0, 0.06)
	tween.tween_interval(0.055)
	await get_tree().create_timer(0.92).timeout
	var fade := create_tween()
	fade.tween_property(_texture, "modulate:a", 0.0, 0.18)
	await fade.finished
	_texture.visible = false
	_texture.modulate.a = 1.0
	_flash.color.a = 0.0
	_active = false
