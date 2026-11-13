class_name BocaDoFogao
extends Area3D
## Boca do fogão gigante (2-1 Cozinha Gigante): fica um tempo apagada e um tempo acesa, com o anel vermelho e
## umas chaminhas. Acesa, encostar tira um coração ("ai, quente!") e dá um pulinho para fora. Apagada, dá para
## passar por cima. Um instante antes de acender, o anel já fica laranja. O nó fica no meio do anel, no tampo.

const APAGADA := 2.4
const AVISO := 0.6
const ACESA := 2.0

var raio := 2.6
var atraso := 0.0
var acesa := false
var _t := 0.0
var _anel: MeshInstance3D
var _mat: StandardMaterial3D
var _chamas: Node3D
var _luz: OmniLight3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = Fase.CAMADA_JOGADOR
	_t = atraso
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = raio
	cil.height = 1.6
	cs.shape = cil
	cs.position.y = 0.8
	add_child(cs)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color("3a3440")
	_mat.emission_enabled = true
	_mat.emission = Color("ff4a1c")
	_mat.emission_energy_multiplier = 0.0
	_anel = MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = raio * 0.55
	toro.outer_radius = raio
	_anel.mesh = toro
	_anel.material_override = _mat
	_anel.scale = Vector3(1, 0.35, 1)
	_anel.position.y = 0.08
	add_child(_anel)
	_chamas = Node3D.new()
	_chamas.visible = false
	add_child(_chamas)
	var fogo := StandardMaterial3D.new()
	fogo.albedo_color = Color("ff9a2e")
	fogo.emission_enabled = true
	fogo.emission = Color("ff7a1a")
	fogo.emission_energy_multiplier = 2.5
	for i in 10:
		var a := TAU * i / 10.0
		var chama := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.28
		cone.height = 0.9
		chama.mesh = cone
		chama.material_override = fogo
		chama.position = Vector3(cos(a), 0.45, sin(a)) * Vector3(raio * 0.78, 1, raio * 0.78)
		_chamas.add_child(chama)
	_luz = OmniLight3D.new()
	_luz.light_color = Color("ff8a3a")
	_luz.omni_range = raio * 2.5
	_luz.light_energy = 0.0
	_luz.position.y = 1.0
	add_child(_luz)


func _physics_process(delta: float) -> void:
	_t += delta
	var f := fposmod(_t, APAGADA + ACESA)
	acesa = f >= APAGADA
	var aviso := f >= APAGADA - AVISO and not acesa
	_mat.emission_energy_multiplier = 3.0 if acesa else (1.0 if aviso else 0.0)
	_chamas.visible = acesa
	_luz.light_energy = 2.0 if acesa else 0.0
	if acesa:
		for c in _chamas.get_children():
			(c as Node3D).scale.y = 0.8 + randf() * 0.5
		for corpo in get_overlapping_bodies():
			if corpo is Jogador:
				(corpo as Jogador).receber_dano(global_position)
