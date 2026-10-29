class_name FarolIlha
extends Node3D
## O farol na ponta sudeste da ilha, a casa do Faísca (Parte 2, seção 11 do doc). Fica numa ilhota de pedra
## no mar, ligada à praia por uma passarela de madeira (os módulos do cais do Animated Cute Fish Pack), com
## a porta virada para a passarela. Na Parte 1 a porta tem cadeado; na Parte 2 só o Faísca entra (sinal
## `entrou`), e a criança que encosta na porta vê a troca de personagem já marcando o Faísca (main.gd,
## ask_for_faisca); escolhendo, ele aparece ali e entra. Montado em tempo de jogo pela Parte2,
## sem mexer na ilha gerada (scenes/ilha.tscn).

signal entrou

## Da praia para o mar, na diagonal sudeste. A beira da água fica perto de (150, 150); o fundo desce até
## uns -4 m em (167, 167).
const DIRECAO := Vector3(0.70710678, 0, 0.70710678)
const CENTRO := Vector3(161.5, 0, 161.5)
const RAIO := 7.0
## Topo da ilhota na altura do piso da passarela, para entrar sem degrau.
const TOPO := 0.45
const ESCALA := 4.5
const DOCKS := "res://assets/props/cais_peixes/%s.fbx"
const DOCK_SCALE := 0.75
const DOCK_DECK := 3.8
const PISO := 0.45

var parte2: Parte2
var modelo: FarolModelo
var _cadeado: Node3D
var _brilho_porta: OmniLight3D
var _aviso_espera := 0.0


func _ready() -> void:
	position = CENTRO
	# A porta (+Z do modelo) olha para a praia.
	var para_praia := -DIRECAO
	_ilhota()
	modelo = FarolModelo.new()
	modelo.escala = ESCALA
	modelo.solido = true
	modelo.position.y = TOPO
	modelo.rotation.y = atan2(para_praia.x, para_praia.z)
	add_child(modelo)
	_passarela()
	_porta()
	atualizar()


func _process(delta: float) -> void:
	_aviso_espera -= delta
	if _cadeado and _cadeado.visible:
		_cadeado.rotation.z = lerpf(_cadeado.rotation.z, 0.0, 1.0 - exp(-6.0 * delta))


## Cadeado na Parte 1; na Parte 2 a porta brilha ciano, chamando o Faísca.
func atualizar() -> void:
	var aberta := parte2 != null and parte2.aberta
	_cadeado.visible = not aberta
	_brilho_porta.visible = aberta
	modelo.acender(aberta)


## Onde o Faísca aparece ao sair (na frente da porta, virado para a praia) e para onde a seta aponta. Fica
## fora da área que faz entrar (senão ele entraria de novo na hora).
func porta() -> Vector3:
	return modelo.porta() - DIRECAO * 3.0


func _ilhota() -> void:
	var pedra := StaticBody3D.new()
	add_child(pedra)
	var mi := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.radial_segments = 11
	cil.rings = 1
	cil.top_radius = RAIO
	cil.bottom_radius = RAIO + 1.6
	cil.height = TOPO + 4.5
	mi.mesh = cil
	mi.material_override = _material(Color("8c8f9c"))
	mi.position.y = TOPO - cil.height * 0.5
	pedra.add_child(mi)
	var grama := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.radial_segments = 11
	disco.rings = 1
	disco.top_radius = RAIO - 0.4
	disco.bottom_radius = RAIO - 0.2
	disco.height = 0.16
	grama.mesh = disco
	grama.material_override = _material(Color("86c95f"))
	grama.position.y = TOPO + 0.02
	pedra.add_child(grama)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = RAIO
	forma.height = TOPO + 4.5
	cs.shape = forma
	cs.position.y = TOPO - forma.height * 0.5
	pedra.add_child(cs)
	# Pedrinhas soltas na beira, de enfeite.
	for k in 7:
		var a := TAU * k / 7.0 + 0.4
		if absf(angle_difference(a, atan2(-DIRECAO.z, -DIRECAO.x))) < 0.5:
			continue
		var p := MeshInstance3D.new()
		var bola := SphereMesh.new()
		bola.radius = 1.0
		bola.height = 1.4
		bola.radial_segments = 7
		bola.rings = 4
		p.mesh = bola
		p.material_override = mi.material_override
		p.position = Vector3(cos(a) * (RAIO + 0.6), -0.2, sin(a) * (RAIO + 0.6))
		p.scale = Vector3.ONE * (0.8 + 0.25 * (k % 3))
		add_child(p)


## Módulos do cais da praia até a ilhota, com piso a PISO, paredes invisíveis no lugar da corda e uma rampa
## na areia, como o cais do sul.
func _passarela() -> void:
	var giro := atan2(-DIRECAO.x, -DIRECAO.z)
	var raiz := Node3D.new()
	raiz.name = "Passarela"
	add_child(raiz)
	# A passarela sai da beira da ilhota em direção à praia (eixo +Z da raiz).
	raiz.position = -DIRECAO * (RAIO - 0.6)
	raiz.rotation.y = giro
	var corpo := StaticBody3D.new()
	raiz.add_child(corpo)
	var z := 0.0
	var origem_y := PISO - DOCK_DECK * DOCK_SCALE
	# Um módulo comprido (uns 17 m) chega da ilhota até a areia.
	for i in 1:
		var dock: Node3D = load(DOCKS % "Dock_Long").instantiate()
		var aabb := _aabb(dock)
		var comprimento := aabb.size.z * DOCK_SCALE
		var meia := aabb.size.x * DOCK_SCALE * 0.5 * 0.86
		dock.scale = Vector3.ONE * DOCK_SCALE
		dock.position = Vector3(-aabb.get_center().x * DOCK_SCALE, origem_y, z - aabb.position.z * DOCK_SCALE)
		raiz.add_child(dock)
		var meio := z + comprimento * 0.5
		_caixa(corpo, Vector3(meia * 2.0, 0.3, comprimento), Vector3(0, PISO - 0.15, meio))
		for lado in [-1.0, 1.0]:
			_caixa(corpo, Vector3(0.3, 1.2, comprimento), Vector3(lado * meia, PISO + 0.6, meio))
		z += comprimento - 0.15
	# Emenda entre o piso e a grama da ilhota, e a rampa até a areia.
	_caixa(corpo, Vector3(3.0, 0.4, 1.6), Vector3(0, PISO - 0.2, -0.6))
	var rampa := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(3.0, 0.3, 5.0)
	rampa.shape = caixa
	rampa.position = Vector3(0, PISO - 0.55, z + 2.2)
	rampa.rotation.x = atan2(PISO + 0.25, 5.0)
	corpo.add_child(rampa)


func _porta() -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1 << 1
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(3.2, 3.0, 1.6)
	cs.shape = caixa
	area.add_child(cs)
	add_child(area)
	area.global_position = modelo.porta() + Vector3.UP * 1.5 - DIRECAO * 0.4
	area.global_rotation.y = modelo.rotation.y
	area.body_entered.connect(_tocou)
	# Cadeado dourado na frente da porta (a porta do pacote é parte da torre e não abre).
	_cadeado = Node3D.new()
	add_child(_cadeado)
	_cadeado.global_position = modelo.porta() + Vector3.UP * 1.25 - DIRECAO * 0.15
	_cadeado.rotation.y = modelo.rotation.y
	var ouro := _material(Color("ffc93c"))
	ouro.metallic = 0.6
	ouro.roughness = 0.3
	var corpo := MeshInstance3D.new()
	var bloco := BoxMesh.new()
	bloco.size = Vector3(0.7, 0.6, 0.25)
	corpo.mesh = bloco
	corpo.material_override = ouro
	_cadeado.add_child(corpo)
	var alca := MeshInstance3D.new()
	var anel := TorusMesh.new()
	anel.inner_radius = 0.18
	anel.outer_radius = 0.27
	alca.mesh = anel
	alca.material_override = ouro
	alca.rotation.x = PI / 2.0
	alca.position.y = 0.35
	_cadeado.add_child(alca)
	_brilho_porta = OmniLight3D.new()
	_brilho_porta.light_color = FarolModelo.LUZ
	_brilho_porta.light_energy = 2.0
	_brilho_porta.omni_range = 4.0
	add_child(_brilho_porta)
	_brilho_porta.global_position = modelo.porta() + Vector3.UP * 1.4 - DIRECAO * 0.8


func _tocou(corpo: Node3D) -> void:
	if corpo is Jogador and parte2 and parte2.aberta:
		entrou.emit()
		return
	if not corpo is Player or _aviso_espera > 0.0:
		return
	_aviso_espera = 2.5
	var game := parte2.game
	if parte2.aberta:
		# Abre a troca de personagem já no Faísca (de kart ou de skate, só o aviso).
		if corpo.in_vehicle or corpo.skating:
			game.show_message("Só o Faísca entra no farol! Troque de personagem na pausa", Color("#8ff3ff"), 2.4)
		else:
			game.ask_for_faisca()
	else:
		_cadeado.rotation.z = 0.35
		game.show_message("O farol está fechado", Color(1, 1, 1, 0.9), 1.8)


func _caixa(corpo: StaticBody3D, tamanho: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = tamanho
	cs.shape = caixa
	cs.position = pos
	corpo.add_child(cs)


func _aabb(no: Node3D) -> AABB:
	var caixa := AABB()
	var primeiro := true
	for mi in no.find_children("*", "MeshInstance3D", true, false):
		var t := Transform3D.IDENTITY
		var n: Node = mi
		while n != no:
			t = (n as Node3D).transform * t
			n = n.get_parent()
		var a: AABB = t * (mi as MeshInstance3D).get_aabb()
		caixa = a if primeiro else caixa.merge(a)
		primeiro = false
	return caixa


func _material(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.85
	return m
