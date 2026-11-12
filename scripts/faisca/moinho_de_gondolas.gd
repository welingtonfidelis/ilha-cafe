class_name MoinhoDeGondolas
extends Node3D
## Moinho médio do Corredor dos Moinhos, na 3-3 Moinhos do Vento (2026-11-12, da maquete aprovada pelo usuário): a
## torre creme com o telhado colorido e, na frente, as quatro pás de madeira com as velas brancas, que levam quatro
## gôndolas de tábuas sempre niveladas, como uma roda-gigante. Começa travado; o soco no freio (o Ferrolho na janela
## do eixo, ao lado do topo de uma coluna de vento, que a fase põe) solta, e as pás voltam a girar devagar: a gôndola
## leva até perto da ilha seguinte.
## O nó fica no pé da torre; a roda fica na frente dela (o +Z do nó), no plano XY.

signal destravou

var raio_roda := 7.0
var altura_eixo := 9.6
var cor_telhado := Color("3f7fd9")
var travado := true
## Ângulo da roda (rad) e a velocidade dela girando (rad/s).
var angulo := 0.35
const VELOCIDADE := 0.3
const FRENTE := 2.6

var gondolas: Array[AnimatableBody3D] = []
var _roda: Node3D
var _velocidade := 0.0


func _ready() -> void:
	var creme := _mat(Color("efe6d8"))
	var madeira := _mat(Color("8a5a36"))
	var vela := _mat(Color("faf3e3"))
	# A torre (sólida) e o telhado.
	var torre := StaticBody3D.new()
	add_child(torre)
	var cil := CylinderMesh.new()
	cil.top_radius = 1.6
	cil.bottom_radius = 2.2
	cil.height = altura_eixo + 0.6
	var mi := MeshInstance3D.new()
	mi.mesh = cil
	mi.material_override = creme
	mi.position.y = cil.height * 0.5
	torre.add_child(mi)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 2.0
	forma.height = cil.height
	cs.shape = forma
	cs.position.y = cil.height * 0.5
	torre.add_child(cs)
	var telhado := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 2.3
	cone.height = 3.0
	telhado.mesh = cone
	telhado.material_override = _mat(cor_telhado)
	telhado.position.y = cil.height + 1.5
	add_child(Fase.so_enfeite(telhado))
	var porta := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 2.0, 0.2)
	porta.mesh = bm
	porta.material_override = madeira
	porta.position = Vector3(0, 1.0, 2.12)
	add_child(Fase.so_enfeite(porta))
	# A roda: o miolo laranja, as quatro varas com as velas.
	_roda = Node3D.new()
	_roda.position = Vector3(0, altura_eixo, FRENTE)
	add_child(Fase.so_enfeite(_roda))
	var miolo := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.75
	esfera.height = 1.5
	miolo.mesh = esfera
	miolo.material_override = _mat(Color("ff7a22"))
	_roda.add_child(miolo)
	var eixo := MeshInstance3D.new()
	var e := CylinderMesh.new()
	e.top_radius = 0.3
	e.bottom_radius = 0.3
	e.height = FRENTE
	eixo.mesh = e
	eixo.material_override = madeira
	eixo.rotation.x = PI / 2.0
	eixo.position.z = -FRENTE * 0.5
	_roda.add_child(eixo)
	for i in 4:
		var braco := Node3D.new()
		braco.rotation.z = i * PI / 2.0
		_roda.add_child(braco)
		var vara := MeshInstance3D.new()
		var vb := BoxMesh.new()
		vb.size = Vector3(0.3, raio_roda, 0.3)
		vara.mesh = vb
		vara.material_override = madeira
		vara.position.y = raio_roda * 0.5
		braco.add_child(vara)
		var pano := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(1.6, raio_roda * 0.62, 0.08)
		pano.mesh = pb
		pano.material_override = vela
		pano.position = Vector3(0.95, raio_roda * 0.55, -0.12)
		braco.add_child(pano)
	# As gôndolas: tábuas de 3 x 3 m com borda escura (sólidas, levam o Faísca), penduradas na ponta de cada vara.
	for i in 4:
		var g := AnimatableBody3D.new()
		# Quem move as gôndolas é o moinho (no _physics_process dele), por isso sem sync_to_physics: com ele ligado, a
		# posição voltava para a anterior a cada quadro (como no trem do farol).
		g.sync_to_physics = false
		add_child(g)
		var tabua := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(3.0, 0.45, 3.0)
		tabua.mesh = tb
		tabua.material_override = _mat(Color("b07a45"))
		g.add_child(tabua)
		var borda := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(3.15, 0.18, 3.15)
		borda.mesh = bb
		borda.material_override = _mat(Color("5a3a1e"))
		borda.position.y = -0.24
		g.add_child(borda)
		var gc := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = tb.size
		gc.shape = caixa
		g.add_child(gc)
		var corda := MeshInstance3D.new()
		var cc := CylinderMesh.new()
		cc.top_radius = 0.05
		cc.bottom_radius = 0.05
		cc.height = 1.0
		corda.mesh = cc
		corda.material_override = _mat(Color("3a3150"))
		corda.position.y = 0.72
		g.add_child(Fase.so_enfeite(corda))
		gondolas.append(g)
	_posicionar()


## Solta o freio: as pás voltam a girar devagar (o freio é da fase, que chama isto).
func destravar() -> void:
	if not travado:
		return
	travado = false
	Sfx.play_at(get_parent(), "vento", global_position + Vector3.UP * altura_eixo, 0.0, 0.05)
	Fx.confetti(get_parent(), _roda.global_position, 30, 4.0)
	destravou.emit()


## Onde fica (no mundo) o miolo da roda.
func eixo_global() -> Vector3:
	return _roda.global_position


func _physics_process(delta: float) -> void:
	_velocidade = move_toward(_velocidade, 0.0 if travado else VELOCIDADE, delta * 0.15)
	angulo -= _velocidade * delta
	# A cada quadro, mesmo parado: a física calcula a velocidade da gôndola pelo quanto ela andou desde o quadro de
	# antes. Movida só de vez em quando (no começo, ou num salto), ficava com uma velocidade velha e enorme, e quem
	# pulasse dela saía voando (visto no teste da 3-3).
	_posicionar()


## A roda no ângulo de agora, e cada gôndola pendurada (nivelada) na ponta da vara dela.
func _posicionar() -> void:
	_roda.rotation.z = angulo
	for i in gondolas.size():
		var a := angulo + i * PI / 2.0
		var local := Vector3(0, altura_eixo, FRENTE + 1.6) + Vector3(-sin(a), cos(a), 0) * raio_roda + Vector3.DOWN * 1.25
		gondolas[i].global_position = global_transform * local
		gondolas[i].global_rotation = Vector3(0, global_rotation.y, 0)


func _mat(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.7
	return m
