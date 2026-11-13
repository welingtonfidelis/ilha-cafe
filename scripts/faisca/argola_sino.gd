class_name ArgolaSino
extends Area3D
## Argola-sino da 3-3 Moinhos do Vento (2026-11-12): um aro laranja grande, de pé no meio de uma faixa de vento, com um
## sino amarelo pendurado em cima. Atravessar o aro (flutuando no vento) faz o sino tocar: o aro fica dourado, sai
## confete e a fase fica sabendo (`tocou`). São a tarefa das Ilhas do Vento. O nó fica no meio do aro, que olha para
## `para` (o rumo do vento).

signal tocou(a: ArgolaSino)

const RAIO := 2.2
var tocada := false

var _aro_mat: StandardMaterial3D
var _sino: Node3D
var _tempo := 0.0
var _balanco := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Fase.CAMADA_JOGADOR
	monitorable = false
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = RAIO - 0.3
	cil.height = 1.2
	cs.shape = cil
	cs.rotation.x = PI / 2.0
	add_child(cs)
	_aro_mat = StandardMaterial3D.new()
	_aro_mat.albedo_color = Color("ff7a22")
	_aro_mat.emission_enabled = true
	_aro_mat.emission = Color("ff7a22")
	_aro_mat.emission_energy_multiplier = 0.15
	var aro := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = RAIO - 0.28
	toro.outer_radius = RAIO + 0.28
	toro.rings = 48
	aro.mesh = toro
	aro.material_override = _aro_mat
	aro.rotation.x = PI / 2.0
	add_child(Fase.so_enfeite(aro))
	_sino = Node3D.new()
	_sino.position.y = RAIO + 0.35
	add_child(Fase.so_enfeite(_sino))
	var modelo: Node3D = load("res://assets/faisca/neve/bell.gltf").instantiate()
	modelo.scale = Vector3.ONE * 1.6
	modelo.position.y = -0.6
	_sino.add_child(modelo)
	var amarelo := StandardMaterial3D.new()
	amarelo.albedo_color = Color("ffd23f")
	amarelo.metallic = 0.4
	amarelo.roughness = 0.35
	for mi: MeshInstance3D in modelo.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = amarelo
	_tempo = randf() * 4.0
	body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador and not tocada:
			tocar())


## O sino toca: o aro fica dourado e aceso, sai confete e o "dlém".
func tocar() -> void:
	tocada = true
	_aro_mat.albedo_color = Color("ffd23f")
	_aro_mat.emission = Color("ffd23f")
	_aro_mat.emission_energy_multiplier = 1.2
	_balanco = 1.0
	Fx.confetti(get_parent(), global_position, 24, 3.0)
	Sfx.play_at(get_parent(), "sino", global_position, 2.0)
	tocou.emit(self)


func _process(delta: float) -> void:
	_tempo += delta
	_balanco = move_toward(_balanco, 0.0, delta * 0.6)
	_sino.rotation.z = sin(_tempo * (12.0 if _balanco > 0.0 else 2.0)) * (0.45 * _balanco + 0.08)
	if not tocada:
		_aro_mat.emission_energy_multiplier = 0.15 + 0.25 * (0.5 + 0.5 * sin(_tempo * 3.0))
