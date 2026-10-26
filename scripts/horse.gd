extends Node3D
## Cavalo do pasto (Medieval Hexagon). O modelo é uma peça inteira, sem esqueleto: pastar é inclinar o
## corpo para a frente de vez em quando, e de vez em quando ele vira devagar para outro lado.

const MODEL := "res://assets/props/cavalos/%s.gltf"
## O cavalo do pacote é uma peça de tabuleiro de 0,77 m de comprimento: 3x fica com 2,3 m, um pônei.
const SCALE := 3.0

@export var model_name := "horse_A"

var _model: Node3D
var _time := 0.0
var _turn_to := 0.0


func _ready() -> void:
	_model = load(MODEL % model_name).instantiate()
	_model.scale = Vector3.ONE * SCALE
	add_child(_model)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.7, 1.6, 2.2)
	cs.shape = box
	cs.position.y = 0.8
	body.add_child(cs)
	add_child(body)
	_time = randf() * 10.0
	_turn_to = rotation.y


func _process(delta: float) -> void:
	_time += delta
	# Pasta (inclina para a frente) uns segundos, levanta, olha em volta.
	var graze := clampf(sin(_time * 0.45) * 1.6, 0.0, 1.0)
	_model.rotation.x = graze * 0.18 + sin(_time * 3.1) * 0.01 * graze
	if fmod(_time, 9.0) < delta:
		_turn_to = rotation.y + randf_range(-0.8, 0.8)
	rotation.y = lerp_angle(rotation.y, _turn_to, 1.0 - exp(-0.6 * delta))
