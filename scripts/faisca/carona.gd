class_name Carona
extends AnimatableBody3D
## Viagem entre dois playgrounds que espera o Faísca (2-2 Nuvens de Algodão-Doce, 2026-10-30): a nuvem-carro e o
## teleférico. Fica parada em `de` até ele subir; um instante depois sai sozinha, acelera, freia e para em `ate`.
## - Se ele descer e subir de novo em `ate`, ela o leva de volta (é o atalho para quem quer voltar atrás de um
##   vaga-lume).
## - Vazia em `ate` por ESPERA_VAZIA, ela volta sozinha para `de`, para quem cair e voltar no posto andar de novo.
## - Quem chega em cima dela precisa descer antes de ela sair de novo do mesmo lugar.
## O nó fica no meio do chão, onde ele pisa. `tipo` "nuvem" é uma nuvem branca grande; "cabine" é a cabine rosa do
## teleférico, pendurada no cabo, com grade dos lados e aberta na frente e atrás. Na 2-3 (2026-10-30) vieram o "trem"
## (vagão chato com a locomotiva na frente), o "aviao" (avião de papel) e o "carrinho" (carrinho de corda); com
## `caminho` (uma lista de pontos), ela segue a linha por eles em vez da reta de `de` até `ate`, virando nas curvas.

signal saiu
signal chegou

const ESPERA_VAZIA := 8.0

var de := Vector3.ZERO
var ate := Vector3.ZERO
var velocidade := 5.0
var tipo := "nuvem"
## Pontos do caminho (opcional); o primeiro vira `de` e o último, `ate`.
var caminho: Array = []
## em_de, indo, em_ate, voltando
var estado := "em_de"
var _andado := 0.0
var _dentro := 0.0
var _vazio := 0.0
var _liberada := true
var _area: Area3D
var _curva: Curve3D


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	var dir := ate - de
	if caminho.size() >= 2:
		_curva = Curve3D.new()
		_curva.bake_interval = 0.4
		for p: Vector3 in caminho:
			_curva.add_point(p)
		de = caminho[0]
		ate = caminho[caminho.size() - 1]
		dir = caminho[1] - caminho[0]
	rotation.y = atan2(dir.x, dir.z)
	match tipo:
		"cabine":
			_montar_cabine()
		"trem":
			_montar_trem()
		"aviao":
			_montar_aviao()
		"carrinho":
			_montar_carrinho()
		_:
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


## Vagão chato vermelho com grade dos lados e a locomotiva verde na frente (Holiday Bits).
func _montar_trem() -> void:
	var vermelho := _material(Color("e94f4f"))
	var amarelo := _material(Color("ffc93a"))
	_caixa(Vector3(3.2, 0.4, 5.0), Vector3(0, -0.2, 0), vermelho, true)
	for lado in [-1.0, 1.0]:
		_caixa(Vector3(0.2, 0.6, 5.0), Vector3(lado * 1.5, 0.3, 0), amarelo, true)
		for frente in [-1.0, 1.0]:
			var roda := MeshInstance3D.new()
			var cil := CylinderMesh.new()
			cil.top_radius = 0.5
			cil.bottom_radius = 0.5
			cil.height = 0.3
			roda.mesh = cil
			roda.material_override = _material(Color("3a3150"))
			roda.rotation.z = PI / 2.0
			roda.position = Vector3(lado * 1.5, -0.6, frente * 1.6)
			add_child(roda)
	var loco: Node3D = load(Fase.QUARTO + "train_locomotive.gltf").instantiate()
	loco.scale = Vector3.ONE * 6.0
	loco.position = Vector3(0, -1.0, 5.4)
	add_child(loco)
	_caixa(Vector3(2.6, 3.6, 5.0), Vector3(0, 0.8, 5.6), _material(Color.WHITE), true).visible = false


## Avião de papel branco, deitado, com o bico para a frente (+Z) e uma quilha embaixo.
func _montar_aviao() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bico := Vector3(0, 0, 3.4)
	var meio := Vector3(0, 0, -1.4)
	var asas := [Vector3(-2.6, 0.25, -2.4), Vector3(2.6, 0.25, -2.4)]
	for asa: Vector3 in asas:
		for v in [bico, asa, meio]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	for v in [bico, meio, Vector3(0, -1.0, -1.8)]:
		st.set_normal(Vector3.RIGHT)
		st.add_vertex(v)
	var papel := StandardMaterial3D.new()
	papel.albedo_color = Color("fbfbff")
	papel.cull_mode = BaseMaterial3D.CULL_DISABLED
	papel.roughness = 0.9
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = papel
	add_child(mi)
	var dobra := MeshInstance3D.new()
	var linha := BoxMesh.new()
	linha.size = Vector3(0.08, 0.06, 4.8)
	dobra.mesh = linha
	dobra.material_override = _material(Color("c9d4e8"))
	dobra.position = Vector3(0, 0.03, 1.0)
	add_child(dobra)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(3.4, 0.3, 4.8)
	cs.shape = forma
	cs.position = Vector3(0, -0.15, 0.4)
	add_child(cs)


## Carrinho de corda azul: chão com grade dos lados, o capô na frente, quatro rodas e a chave de corda atrás.
func _montar_carrinho() -> void:
	var azul := _material(Color("3f8fe0"))
	_caixa(Vector3(3.2, 0.3, 4.4), Vector3(0, -0.15, 0), azul, true)
	for lado in [-1.0, 1.0]:
		_caixa(Vector3(0.2, 0.7, 4.4), Vector3(lado * 1.5, 0.35, 0), azul, true)
		for frente in [-1.0, 1.0]:
			var roda := MeshInstance3D.new()
			var cil := CylinderMesh.new()
			cil.top_radius = 0.7
			cil.bottom_radius = 0.7
			cil.height = 0.5
			roda.mesh = cil
			roda.material_override = _material(Color("2b2140"))
			roda.rotation.z = PI / 2.0
			roda.position = Vector3(lado * 1.7, -0.4, frente * 1.5)
			add_child(roda)
	_caixa(Vector3(3.2, 1.0, 1.2), Vector3(0, 0.5, 2.8), _material(Color("e94f4f")), true)
	_caixa(Vector3(2.6, 0.7, 0.1), Vector3(0, 1.35, 2.2), _material(Color("bfe3ff")), false)
	_caixa(Vector3(0.25, 1.2, 0.25), Vector3(0, 0.6, -2.4), _material(Color("ffc93a")), false)
	_caixa(Vector3(1.4, 0.25, 0.25), Vector3(0, 1.2, -2.4), _material(Color("ffc93a")), false)


func _caixa(tamanho: Vector3, pos: Vector3, material: Material, solida: bool) -> MeshInstance3D:
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
	return mi


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
	var total := _curva.get_baked_length() if _curva else de.distance_to(ate)
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
			var s := 0.5 - 0.5 * cos(PI * _andado)
			if _curva:
				# Posição e giro juntos num transform só: mudando um e depois o outro, o corpo animado ficava só com o
				# giro (achado na sonda do trenzinho, em 2026-10-30).
				var d := s * total
				var tg := _curva.sample_baked(minf(d + 0.6, total), true) - _curva.sample_baked(maxf(d - 0.6, 0.0), true)
				var giro := atan2(tg.x, tg.z) if Vector2(tg.x, tg.z).length() > 0.05 else rotation.y
				global_transform = Transform3D(Basis(Vector3.UP, giro), _curva.sample_baked(d, true))
			else:
				global_position = de.lerp(ate, s)
			if (estado == "indo" and _andado >= 1.0) or (estado == "voltando" and _andado <= 0.0):
				estado = "em_ate" if estado == "indo" else "em_de"
				_liberada = not dentro
				_vazio = 0.0
				chegou.emit()
