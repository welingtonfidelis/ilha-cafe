class_name Carona
extends AnimatableBody3D
## Viagem entre dois playgrounds que espera o Faísca (2-2 Nuvens de Algodão-Doce, 2026-10-30): a nuvem-carro e o
## teleférico. Fica parada em `de` até ele subir; um instante depois sai sozinha, acelera, freia e para em `ate`.
## - Se ele descer e subir de novo em `ate`, ela o leva de volta (é o atalho para quem quer voltar atrás de um
##   vaga-lume).
## - Vazia em `ate` por ESPERA_VAZIA, ela volta sozinha para `de`, para quem cair e voltar no posto andar de novo.
## - Quem chega em cima dela precisa descer antes de ela sair de novo do mesmo lugar.
## O nó fica no meio do chão, onde ele pisa. `tipo` "nuvem" é uma nuvem branca grande; "cabine" é a cabine rosa do
## teleférico, pendurada no cabo, com grade dos lados e aberta na frente e atrás.

signal saiu
signal chegou

const ESPERA_VAZIA := 8.0

var de := Vector3.ZERO
var ate := Vector3.ZERO
var velocidade := 5.0
var tipo := "nuvem"
## em_de, indo, em_ate, voltando
var estado := "em_de"
var _andado := 0.0
var _dentro := 0.0
var _vazio := 0.0
var _liberada := true
var _area: Area3D


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	var dir := ate - de
	rotation.y = atan2(dir.x, dir.z)
	if tipo == "cabine":
		_montar_cabine()
	else:
		_montar_nuvem()
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Fase.CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(2.8, 1.2, 2.8)
	cs.shape = caixa
	cs.position.y = 0.6
	_area.add_child(cs)
	add_child(_area)


func _montar_nuvem() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("ffffff")
	m.roughness = 1.0
	m.rim_enabled = true
	m.rim = 0.25
	for bola in [[Vector3(0, -0.45, 0), Vector3(2.5, 0.6, 2.5)], [Vector3(1.4, -0.25, 0.5), Vector3(1.4, 0.65, 1.4)],
			[Vector3(-1.3, -0.3, -0.4), Vector3(1.5, 0.6, 1.5)], [Vector3(0.2, -0.3, 1.4), Vector3(1.2, 0.55, 1.2)], [Vector3(-0.3, -0.3, -1.5), Vector3(1.2, 0.55, 1.2)]]:
		var mi := MeshInstance3D.new()
		mi.mesh = Forma.superelipsoide(bola[1], 1.0, 1.0)
		mi.material_override = m
		mi.position = bola[0]
		add_child(mi)
	# Uma bandeirinha laranja atrás: a cor do que mexe.
	var mastro := MeshInstance3D.new()
	var haste := CylinderMesh.new()
	haste.top_radius = 0.05
	haste.bottom_radius = 0.05
	haste.height = 1.8
	mastro.mesh = haste
	mastro.material_override = _material(Color("6a6478"))
	mastro.position = Vector3(0, 0.9, -2.0)
	add_child(mastro)
	var flamula := MeshInstance3D.new()
	var pano := BoxMesh.new()
	pano.size = Vector3(0.05, 0.5, 0.8)
	flamula.mesh = pano
	flamula.material_override = _material(Color("ff7a22"))
	flamula.position = Vector3(0, 1.55, -2.4)
	add_child(flamula)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 2.5
	cil.height = 0.8
	cs.shape = cil
	cs.position.y = -0.4
	add_child(cs)


func _montar_cabine() -> void:
	var rosa := _material(Color("ff9fd0"))
	var branco := _material(Color("fff6fb"))
	var ferro := _material(Color("4a4658"))
	ferro.metallic = 0.5
	_caixa(Vector3(3.4, 0.3, 3.4), Vector3(0, -0.15, 0), rosa, true)
	# Grade dos lados (com colisão, 0,7 m: ele não cai de lado), aberta na frente e atrás.
	for lado in [-1.0, 1.0]:
		_caixa(Vector3(0.15, 0.7, 3.4), Vector3(lado * 1.62, 0.35, 0), branco, true)
		for frente in [-1.0, 1.0]:
			_caixa(Vector3(0.15, 3.3, 0.15), Vector3(lado * 1.62, 1.65, frente * 1.62), ferro, false)
	_caixa(Vector3(3.8, 0.35, 3.8), Vector3(0, 3.45, 0), rosa, false)
	_caixa(Vector3(0.12, 1.6, 0.12), Vector3(0, 4.4, 0), ferro, false)
	_caixa(Vector3(1.0, 0.35, 0.5), Vector3(0, 5.2, 0), ferro, false)


func _caixa(tamanho: Vector3, pos: Vector3, material: Material, solida: bool) -> void:
	var mi := MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = tamanho
	mi.mesh = malha
	mi.material_override = material
	mi.position = pos
	add_child(mi)
	if solida:
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = tamanho
		cs.shape = forma
		cs.position = pos
		add_child(cs)


func _material(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.6
	return m


## O Faísca está em cima, em pé no chão dela.
func com_faisca() -> bool:
	for corpo in _area.get_overlapping_bodies():
		if corpo is Jogador and (corpo as Jogador).is_on_floor():
			return true
	return false


func _physics_process(delta: float) -> void:
	var total := de.distance_to(ate)
	var duracao := total / velocidade + 1.5
	var dentro := com_faisca()
	if not dentro:
		_liberada = true
	match estado:
		"em_de", "em_ate":
			_dentro = _dentro + delta if dentro and _liberada else 0.0
			_vazio = 0.0 if dentro else _vazio + delta
			if _dentro > 0.4 or (estado == "em_ate" and _vazio > ESPERA_VAZIA):
				estado = "indo" if estado == "em_de" else "voltando"
				_dentro = 0.0
				saiu.emit()
				Sfx.play_at(get_parent(), "faisca_mola", global_position, -6.0)
		"indo", "voltando":
			_andado = clampf(_andado + (delta if estado == "indo" else -delta) / duracao, 0.0, 1.0)
			global_position = de.lerp(ate, 0.5 - 0.5 * cos(PI * _andado))
			if (estado == "indo" and _andado >= 1.0) or (estado == "voltando" and _andado <= 0.0):
				estado = "em_ate" if estado == "indo" else "em_de"
				_liberada = not dentro
				_vazio = 0.0
				chegou.emit()
