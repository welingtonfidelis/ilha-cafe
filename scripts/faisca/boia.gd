class_name Boia
extends AnimatableBody3D
## O que boia na enchente da 2-1 (a cozinha alagando, item 9 da lista do Faísca, 2026-11-11): a esponja, o prato,
## o patinho de borracha e o pote de sorvete. Com o chão seco, fica deitada no chão xadrez (o topo abaixo de
## `limite_queda`, pisar nela é cair); com a água, sobe junto e balança devagar, e vira o caminho. O nó fica no meio
## do topo, onde se pisa; a colisão fica embaixo dele.

## "esponja", "prato", "patinho" ou "pote".
var tipo := "esponja"
## Quanto o topo fica acima da água, boiando.
var acima := 0.5
## Altura do topo com o chão seco (a peça deitada no chão).
var seca := 1.4
var enchente: Enchente
var _balanco := 0.0
var _visual: Node3D

const ALTURAS := {"esponja": [1.4, 0.5], "prato": [0.8, 0.35], "patinho": [1.6, 1.0], "pote": [2.8, 2.0]}


func _ready() -> void:
	var a: Array = ALTURAS[tipo]
	seca = a[0]
	acima = a[1]
	_balanco = fmod(absf(position.x * 1.7 + position.z * 0.9), TAU)
	_visual = Node3D.new()
	add_child(_visual)
	match tipo:
		"esponja":
			_caixa(Vector3(4.2, 1.05, 3.2), Vector3(0, -0.875, 0), Color("ffd84a"), 0.9)
			_caixa(Vector3(4.2, 0.35, 3.2), Vector3(0, -0.175, 0), Color("5fc46a"), 1.0)
			_colisao_caixa(Vector3(4.2, 1.4, 3.2), Vector3(0, -0.7, 0))
		"prato":
			var modelo: Node3D = load(Fase.COZINHA + "plate.gltf").instantiate()
			modelo.scale = Vector3.ONE * 8.0
			modelo.position.y = -0.8
			_visual.add_child(modelo)
			_colisao_cilindro(3.7, 0.8, -0.4)
		"patinho":
			_patinho()
		"pote":
			var branco := _mat(Color("fff3f6"), 0.5)
			var tampa := _mat(Color("ff8fb8"), 0.45)
			_malha(_cilindro(2.2, 2.0, 2.5), Vector3(0, -1.55, 0), branco)
			_malha(_cilindro(2.35, 2.35, 0.3), Vector3(0, -0.15, 0), tampa)
			# A faixa rosa em volta (por fora do pote, sem encostar na parede dele).
			_malha(_cilindro(2.2, 2.16, 0.5), Vector3(0, -1.4, 0), tampa)
			_colisao_cilindro(2.3, 2.8, -1.4)
	position.y = seca


func _physics_process(delta: float) -> void:
	if enchente == null:
		return
	var na_agua := enchente.nivel + acima
	if na_agua <= seca:
		position.y = seca
		_visual.rotation = Vector3.ZERO
		return
	_balanco += delta * 2.2
	position.y = na_agua + sin(_balanco) * 0.05
	# Só o desenho inclina um tiquinho (a colisão fica reta, para não escorregar quem está em cima).
	_visual.rotation = Vector3(sin(_balanco * 0.7) * 0.03, 0, cos(_balanco * 0.9) * 0.03)


## Na água agora (e não deitada no chão seco).
func boiando() -> bool:
	return enchente != null and enchente.nivel + acima > seca


## O patinho de borracha: corpo amarelo, a cabeça na frente (para -Z), o bico laranja e os olhinhos. Pisa-se nas
## costas; a cabeça é sólida.
func _patinho() -> void:
	var amarelo := _mat(Color("ffd23f"), 0.35)
	var laranja := _mat(Color("ff8a2a"), 0.4)
	var preto := _mat(Color("1b1530"), 0.2)
	var corpo := MeshInstance3D.new()
	corpo.mesh = Forma.superelipsoide(Vector3(2.0, 1.3, 2.6), 0.8, 1.0)
	corpo.material_override = amarelo
	corpo.position = Vector3(0, -1.25, 0.2)
	_visual.add_child(corpo)
	# O rabinho levantado atrás.
	var rabo := MeshInstance3D.new()
	rabo.mesh = Forma.superelipsoide(Vector3(0.8, 0.7, 0.7), 1.0, 1.0)
	rabo.material_override = amarelo
	rabo.position = Vector3(0, -0.15, 2.6)
	rabo.rotation.x = -0.5
	_visual.add_child(rabo)
	var cabeca := MeshInstance3D.new()
	cabeca.mesh = Forma.superelipsoide(Vector3(1.15, 1.1, 1.1), 1.0, 1.0)
	cabeca.material_override = amarelo
	cabeca.position = Vector3(0, 0.9, -1.9)
	_visual.add_child(cabeca)
	var bico := MeshInstance3D.new()
	bico.mesh = Forma.superelipsoide(Vector3(0.6, 0.25, 0.6), 1.0, 1.0)
	bico.material_override = laranja
	bico.position = Vector3(0, 0.75, -3.0)
	_visual.add_child(bico)
	for lado in [-1.0, 1.0]:
		var olho := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.16
		s.height = 0.32
		olho.mesh = s
		olho.material_override = preto
		olho.position = Vector3(0.55 * lado, 1.2, -2.85)
		_visual.add_child(olho)
	_colisao_caixa(Vector3(3.4, 1.6, 4.2), Vector3(0, -0.8, 0.3))
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 1.1
	cs.shape = esfera
	cs.position = Vector3(0, 0.9, -1.9)
	add_child(cs)


func _caixa(tamanho: Vector3, pos: Vector3, cor: Color, aspereza: float) -> void:
	var b := BoxMesh.new()
	b.size = tamanho
	_malha(b, pos, _mat(cor, aspereza))


func _malha(malha: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = mat
	mi.position = pos
	_visual.add_child(mi)
	return mi


func _cilindro(r_cima: float, r_baixo: float, altura: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_cima
	c.bottom_radius = r_baixo
	c.height = altura
	c.radial_segments = 40
	return c


func _mat(cor: Color, aspereza: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = aspereza
	return m


func _colisao_caixa(tamanho: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamanho
	cs.shape = forma
	cs.position = pos
	add_child(cs)


func _colisao_cilindro(raio: float, altura: float, y: float) -> void:
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = raio
	forma.height = altura
	cs.shape = forma
	cs.position.y = y
	add_child(cs)
