class_name Posto
extends Area3D
## Posto de recarga: a bandeira azul do pacote Platformer. Encostar troca pela amarela, solta
## umas estrelinhas e vira o ponto de volta do Faísca (quedas e curtos voltam aqui).
## O ponto de volta é chão firme perto da bandeira, com folga de MARGEM até qualquer beira: o posto
## procura sozinho (na frente primeiro, depois girando para os lados e para trás), para nunca devolver o
## Faísca na beirada, onde ele cairia de novo (o usuário viu isso na 1-1 em 2026-10-28).
## A área que acende é larga (RAIO_AREA) e alta, para passar perto ou por cima já valer (pedido de 2026-10-29).

signal aceso(posto: Posto)

## Distância do ponto de volta até a beira mais perto, em todas as direções.
const MARGEM := 1.6
## Raio e altura da área que acende a bandeira (era 1,6 x 3 m; a das bandeiras da ilha tem 4 m de raio).
const RAIO_AREA := 3.2
const ALTURA_AREA := 6.0
## Ordem de procura: distância da bandeira e giro a partir da frente (em oitavos de volta).
const DISTANCIAS := [1.8, 2.6, 1.2, 3.4]
const GIROS := [0, 1, -1, 2, -2, 3, -3, 4]

var acendido := false
## Ponto de volta já procurado (INF enquanto a física não deixou procurar).
var _ponto := Vector3.INF
var _apagada: Node3D
var _acesa: Node3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = Fase.CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = RAIO_AREA
	forma.height = ALTURA_AREA
	cs.shape = forma
	# Um pouco abaixo do pé da bandeira também conta (chegando por uma rampa ou degrau mais baixo).
	cs.position.y = ALTURA_AREA * 0.5 - 1.0
	add_child(cs)
	_apagada = load(Fase.PLATAFORMA + "flag_A_blue.gltf").instantiate()
	_acesa = load(Fase.PLATAFORMA + "flag_A_yellow.gltf").instantiate()
	for b in [_apagada, _acesa]:
		b.scale = Vector3.ONE * 1.4
		add_child(b)
	_acesa.hide()
	body_entered.connect(_encostou)
	_procurar_ponto.call_deferred()


## Onde o Faísca reaparece: chão firme perto da bandeira, longe da beira.
func ponto() -> Vector3:
	return _ponto if _ponto != Vector3.INF else global_position + Vector3.UP * 0.1


## Depois de dois quadros de física (a colisão das peças já conta), testa os lugares em volta da bandeira e
## fica com o primeiro de chão firme. Sem nenhum, fica a própria bandeira.
func _procurar_ponto() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	var espaco := get_world_3d().direct_space_state
	var frente := global_basis.z
	frente.y = 0.0
	frente = frente.normalized() if frente.length() > 0.01 else Vector3.BACK
	for d in DISTANCIAS:
		for g in GIROS:
			var chao := chao_firme(espaco, global_position + frente.rotated(Vector3.UP, TAU * g / 8.0) * d, global_position.y)
			if chao != Vector3.INF:
				_ponto = chao + Vector3.UP * 0.1
				return
	_ponto = global_position + Vector3.UP * 0.1


## Chão firme em `p` (devolve onde) se houver chão embaixo, perto da altura `altura`, e também a MARGEM em
## oito direções, sem degrau grande; senão INF. Também serve aos testes, para conferir qualquer ponto de volta.
static func chao_firme(espaco: PhysicsDirectSpaceState3D, p: Vector3, altura: float) -> Vector3:
	var meio := _chao(espaco, Vector3(p.x, altura, p.z))
	if meio == Vector3.INF or absf(meio.y - altura) > 1.2:
		return Vector3.INF
	for k in 8:
		var a := TAU * k / 8.0
		var volta := _chao(espaco, meio + Vector3(cos(a), 0, sin(a)) * MARGEM)
		if volta == Vector3.INF or absf(volta.y - meio.y) > 0.6:
			return Vector3.INF
	return meio


static func _chao(espaco: PhysicsDirectSpaceState3D, p: Vector3) -> Vector3:
	var consulta := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.5, p + Vector3.DOWN * 3.0, 1)
	var batida := espaco.intersect_ray(consulta)
	return batida.position if not batida.is_empty() else Vector3.INF


func _encostou(corpo: Node3D) -> void:
	if corpo is Jogador and not acendido:
		acender()


func acender() -> void:
	acendido = true
	_apagada.hide()
	_acesa.show()
	_acesa.scale = Vector3.ONE * 0.6
	create_tween().tween_property(_acesa, "scale", Vector3.ONE * 1.4, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ffd23f")
	mat.emission_enabled = true
	mat.emission = Color("ffb800")
	mat.emission_energy_multiplier = 1.5
	var malha := Forma.estrela(0.18, 0.08, 0.09)
	for i in 8:
		var e := MeshInstance3D.new()
		e.mesh = malha
		e.material_override = mat
		add_child(e)
		e.position = Vector3(0, 2.6, 0)
		var a := TAU * i / 8.0
		var tw := e.create_tween().set_parallel()
		tw.tween_property(e, "position", Vector3(cos(a) * 1.6, 3.2 + randf() * 0.6, sin(a) * 1.6), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(e, "scale", Vector3.ONE * 0.01, 0.35).set_delay(0.25)
		tw.chain().tween_callback(e.queue_free)
	aceso.emit(self)
