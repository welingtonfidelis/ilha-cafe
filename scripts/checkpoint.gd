class_name Checkpoint
extends Area3D
## Ponto de retorno: uma bandeira. Ao passar perto, ela sobe e fica amarela; é ali que o
## aventureiro volta quando fica tonto. Montada com formas simples até termos a bandeira
## do KayKit Platformer Pack.

signal activated(checkpoint: Checkpoint)

const COLOR_OFF := Color("#8a93a6")
const COLOR_ON := Color("#ffd23f")

var active := false
var _flag: MeshInstance3D
var _flag_mat: StandardMaterial3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1  # jogador
	monitoring = true
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 2.4
	cyl.height = 3.0
	shape.shape = cyl
	shape.position.y = 1.5
	add_child(shape)

	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.45
	base_mesh.bottom_radius = 0.55
	base_mesh.height = 0.2
	base_mesh.material = Fx.flat_material(Color("#6b7280"), false)
	base.mesh = base_mesh
	base.position.y = 0.1
	add_child(base)

	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.06
	pole_mesh.bottom_radius = 0.06
	pole_mesh.height = 3.2
	pole_mesh.material = Fx.flat_material(Color("#f4f1e8"), false)
	pole.mesh = pole_mesh
	pole.position.y = 1.6
	add_child(pole)

	_flag = MeshInstance3D.new()
	var flag_mesh := BoxMesh.new()
	flag_mesh.size = Vector3(1.1, 0.7, 0.05)
	_flag_mat = Fx.flat_material(COLOR_OFF, false)
	flag_mesh.material = _flag_mat
	_flag.mesh = flag_mesh
	_flag.position = Vector3(0.6, 1.4, 0)
	add_child(_flag)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body is Player and not active:
		activated.emit(self)


## silent: ativa sem festa (a bandeira inicial já começa ativa).
func set_active(on: bool, silent := false) -> void:
	active = on
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_flag, "position:y", 2.8 if on else 1.4, 0.0 if silent else 0.6) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_flag_mat, "albedo_color", COLOR_ON if on else COLOR_OFF, 0.0 if silent else 0.3)
	if on and not silent:
		Fx.confetti(get_parent(), global_position + Vector3.UP * 3.0, 40, 5.0)
		Fx.popup_text(get_parent(), global_position + Vector3.UP * 3.6, "Ponto de retorno!", COLOR_ON)


## Onde o aventureiro reaparece: ao lado da bandeira.
func spawn_position() -> Vector3:
	return global_position + global_basis * Vector3(0, 0.1, 2.0)
