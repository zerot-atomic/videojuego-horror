extends Node3D

const DOOR_ASSET: PackedScene = preload("res://art3d/classic64_pack/Doors/door_plain.glb")

@export var hinge_yaw_degrees: float = 0.0
@export var door_offset: Vector3 = Vector3(0.685, 1.1, 0.0)
@export var leaf_scale: Vector3 = Vector3(1.5, 1.1, 1.0)
@export var swing_direction: float = 1.0
@export var open_angle_degrees: float = 88.0

var _hinge: Node3D
var _playing: bool = false

func _ready() -> void:
	var imported_scene: Node3D = DOOR_ASSET.instantiate()
	var leaf := imported_scene.find_child("Door", true, false) as Node3D
	if leaf == null:
		imported_scene.free()
		push_warning("No se encontró la hoja Door dentro de door_plain.glb")
		return
	leaf.owner = null
	leaf.get_parent().remove_child(leaf)
	_hinge = Node3D.new()
	_hinge.name = "BisagraAnimada"
	_hinge.rotation.y = deg_to_rad(hinge_yaw_degrees)
	add_child(_hinge)
	_hinge.add_child(leaf)
	leaf.transform = Transform3D.IDENTITY
	leaf.position = door_offset
	leaf.scale = leaf_scale
	imported_scene.free()

func play_transition() -> void:
	if _playing or _hinge == null:
		return
	_playing = true
	var open_tween := create_tween()
	open_tween.tween_property(
		_hinge,
		"rotation:y",
		deg_to_rad(hinge_yaw_degrees + open_angle_degrees * swing_direction),
		0.36
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await open_tween.finished
	await get_tree().create_timer(0.12).timeout
	var close_tween := create_tween()
	close_tween.tween_property(_hinge, "rotation:y", deg_to_rad(hinge_yaw_degrees), 0.32)
	close_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await close_tween.finished
	_playing = false
