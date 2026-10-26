class_name Checkpoint
extends Area3D
## Ponto de retorno: a bandeira do KayKit Platformer Pack. Começa azul; ao passar perto ela
## troca para amarela com um pulinho, e é ali que o aventureiro volta quando fica tonto.

signal activated(checkpoint: Checkpoint)

const FLAG_OFF := "res://assets/props/platformer/blue/flag_A_blue.gltf"
const FLAG_ON := "res://assets/props/platformer/yellow/flag_A_yellow.gltf"
const FLAG_SCALE := 1.6
const COLOR_ON := Color("#ffd23f")

var active := false
var _flag_off: Node3D
var _flag_on: Node3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1  # jogador
	monitoring = true
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 4.0
	cyl.height = 3.0
	shape.shape = cyl
	shape.position.y = 1.5
	add_child(shape)
	_flag_off = load(FLAG_OFF).instantiate()
	_flag_on = load(FLAG_ON).instantiate()
	for flag in [_flag_off, _flag_on]:
		flag.scale = Vector3.ONE * FLAG_SCALE
		add_child(flag)
	_flag_on.visible = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Player and not active:
		activated.emit(self)


## silent: ativa sem festa (a bandeira inicial já começa ativa).
func set_active(on: bool, silent := false) -> void:
	active = on
	_flag_on.visible = on
	_flag_off.visible = not on
	if on and not silent:
		var shown := _flag_on
		shown.scale = Vector3(FLAG_SCALE, FLAG_SCALE * 0.3, FLAG_SCALE)
		var tw := create_tween()
		tw.tween_property(shown, "scale", Vector3.ONE * FLAG_SCALE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Fx.confetti(get_parent(), global_position + Vector3.UP * 3.0, 40, 5.0)
		Fx.popup_text(get_parent(), global_position + Vector3.UP * 3.8, "Ponto de retorno!", COLOR_ON)
		Sfx.play(get_parent(), "bandeira")


## Onde o aventureiro reaparece: ao lado da bandeira.
func spawn_position() -> Vector3:
	return global_position + global_basis * Vector3(0, 0.1, 2.0)
