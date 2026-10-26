class_name Fish
extends Node3D
## Peixe fofo (Quaternius, CC0) nadando em círculo logo abaixo da água, com um balanço de leve. Os que
## podem pular dão um saltinho fora d'água de vez em quando ("tchibum" pequeno).

const MODELS := "res://assets/peixes/%s.fbx"
const WATER_Y := -0.6
const JUMP_TIME := 1.1
const JUMP_HEIGHT := 1.3

@export var model_name := "Clownfish"
@export var model_scale := 0.17
@export var center := Vector3.ZERO
@export var radius := 4.0
@export var depth := 0.5
@export var speed := 1.2
@export var can_jump := false

var _angle := 0.0
var _dir := 1.0
var _time := 0.0
var _jump := -1.0
var _next_jump := 0.0
var _model: Node3D
var _ap: AnimationPlayer
var _anims := {}


func _ready() -> void:
	add_to_group(&"peixes")
	_model = load(MODELS % model_name).instantiate()
	_model.scale = Vector3.ONE * model_scale
	add_child(_model)
	_ap = _model.find_child("AnimationPlayer", true, false)
	if _ap:
		for full in _ap.get_animation_list():
			var short := String(full).get_slice("|", String(full).get_slice_count("|") - 1)
			_anims[short] = full
			if short.begins_with("Swimming"):
				_ap.get_animation(full).loop_mode = Animation.LOOP_LINEAR
		_play("Swimming_Normal")
		_ap.seek(randf(), true)
	_angle = randf() * TAU
	_dir = 1.0 if randf() < 0.5 else -1.0
	_time = randf() * 10.0
	_next_jump = randf_range(6.0, 20.0)


func _play(short: String) -> void:
	if _ap and _anims.has(short) and _ap.current_animation != _anims[short]:
		_ap.play(_anims[short], 0.2)


func _process(delta: float) -> void:
	_time += delta
	_angle += _dir * speed / maxf(radius, 0.5) * delta
	var pos := center + Vector3(cos(_angle), 0, sin(_angle)) * radius
	var tangent := Vector3(-sin(_angle), 0, cos(_angle)) * _dir
	pos.y = WATER_Y - depth + sin(_time * 1.7) * 0.08
	if can_jump:
		_next_jump -= delta
		if _jump < 0.0 and _next_jump <= 0.0:
			_jump = 0.0
			_play("Out_Of_Water")
			_splash()
		if _jump >= 0.0:
			_jump += delta
			var t := _jump / JUMP_TIME
			pos.y = WATER_Y - depth + sin(PI * t) * (JUMP_HEIGHT + depth)
			if t >= 1.0:
				_jump = -1.0
				_next_jump = randf_range(10.0, 25.0)
				_play("Swimming_Normal")
				_splash()
	global_position = pos
	if tangent.length() > 0.01:
		var pitch := 0.0
		if _jump >= 0.0:
			pitch = -cos(PI * _jump / JUMP_TIME) * 0.9
		global_basis = Basis(Vector3.UP, atan2(tangent.x, tangent.z)) * Basis(Vector3.RIGHT, pitch)


func _splash() -> void:
	var at := Vector3(global_position.x, WATER_Y + 0.05, global_position.z)
	Fx.bubble_pop(get_parent(), at)
	Sfx.play_at(get_parent(), "splash", at, -8.0)
