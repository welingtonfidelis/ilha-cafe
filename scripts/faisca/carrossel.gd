class_name Carrossel
extends AnimatableBody3D
## O carrossel da Praça do Carrossel (2-2 Nuvens de Algodão-Doce), o mini-marco do playground 3: a base redonda
## gira devagar e leva quem está em cima (o Faísca e as Bolotas), com o mastro dourado no meio, oito balas de goma
## subindo e descendo nos varões e o telhado listrado. O telhado tem uma aba larga e firme, um bolso de estrelinhas
## que só o Balão de Chiclete alcança. As balas e o cone do telhado também são sólidos (o revisor de física pegou
## em 2026-10-30 que o Faísca passava por dentro deles). O nó fica no meio de baixo da base.

const RAIO := 6.5
const ALTURA_BASE := 1.0
const ALTURA_ABA := 8.6

var velocidade := 0.25
var _balas: Array[Node3D] = []
var _formas_das_balas: Array[CollisionShape3D] = []
var _tempo := 0.0


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_cilindro(RAIO, RAIO + 0.2, ALTURA_BASE, ALTURA_BASE * 0.5, Color("fff3f8"), true)
	_cilindro(RAIO + 0.25, RAIO + 0.25, 0.25, ALTURA_BASE - 0.1, Color("ff6fa8"), false)
	_cilindro(0.6, 0.6, ALTURA_ABA - ALTURA_BASE, (ALTURA_ABA + ALTURA_BASE) * 0.5, Color("ffd23f"), true)
	_cilindro(RAIO + 1.0, RAIO + 1.0, 0.6, ALTURA_ABA + 0.3, Color("ff6fa8"), true)
	_cilindro(RAIO + 1.05, RAIO + 1.05, 0.15, ALTURA_ABA + 0.65, Color("ffffff"), false)
	# O cone do telhado, em listras de cores alternadas, no meio da aba: uma colisão de cone para os oito gomos.
	var cone_solido := CylinderMesh.new()
	cone_solido.top_radius = 0.05
	cone_solido.bottom_radius = 3.2
	cone_solido.height = 3.0
	cone_solido.radial_segments = 8
	var cs_cone := CollisionShape3D.new()
	cs_cone.shape = cone_solido.create_convex_shape()
	cs_cone.position.y = ALTURA_ABA + 0.6 + 1.5
	add_child(cs_cone)
	for i in 8:
		var gomo := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.05
		cone.bottom_radius = 3.2
		cone.height = 3.0
		cone.radial_segments = 8
		gomo.mesh = cone
		gomo.material_override = _material(Color("ffffff") if i % 2 == 0 else Color("ff8fc0"))
		gomo.position.y = ALTURA_ABA + 0.6 + 1.5
		gomo.rotation.y = TAU * i / 8.0
		gomo.scale = Vector3(1.0 - i * 0.002, 1.0, 1.0 - i * 0.002)
		add_child(gomo)
	var cores := [Color("ff9ccf"), Color("7ee0b8"), Color("ffd23f"), Color("8fd8ff")]
	for i in 8:
		var a := TAU * i / 8.0
		var varao := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = 0.1
		cil.bottom_radius = 0.1
		cil.height = ALTURA_ABA - ALTURA_BASE
		varao.mesh = cil
		varao.material_override = _material(Color("ffd23f"))
		varao.position = Vector3(cos(a) * 5.0, (ALTURA_ABA + ALTURA_BASE) * 0.5, sin(a) * 5.0)
		add_child(varao)
		var bala := MeshInstance3D.new()
		bala.mesh = Forma.superelipsoide(Vector3(0.8, 0.7, 0.8), 1.0, 1.0)
		bala.material_override = _material(cores[i % cores.size()])
		bala.position = Vector3(cos(a) * 5.0, 3.0, sin(a) * 5.0)
		add_child(bala)
		_balas.append(bala)
		var cs_bala := CollisionShape3D.new()
		var esfera := SphereShape3D.new()
		esfera.radius = 0.72
		cs_bala.shape = esfera
		cs_bala.position = bala.position
		add_child(cs_bala)
		_formas_das_balas.append(cs_bala)


func _cilindro(r_cima: float, r_baixo: float, altura: float, meio: float, cor: Color, solido: bool) -> void:
	var mi := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = r_cima
	cil.bottom_radius = r_baixo
	cil.height = altura
	cil.radial_segments = 40
	mi.mesh = cil
	mi.material_override = _material(cor)
	mi.position.y = meio
	add_child(mi)
	if solido:
		var cs := CollisionShape3D.new()
		var forma := CylinderShape3D.new()
		forma.radius = maxf(r_cima, r_baixo)
		forma.height = altura
		cs.shape = forma
		cs.position.y = meio
		add_child(cs)


func _material(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.5
	return m


## Altura da base e da aba do telhado, onde se pisa.
func topo_base() -> float:
	return global_position.y + ALTURA_BASE


func topo_aba() -> float:
	return global_position.y + ALTURA_ABA + 0.6


func _physics_process(delta: float) -> void:
	_tempo += delta
	rotation.y += velocidade * delta
	for i in _balas.size():
		_balas[i].position.y = 3.0 + sin(_tempo * 2.0 + i) * 0.8
		_formas_das_balas[i].position.y = _balas[i].position.y
