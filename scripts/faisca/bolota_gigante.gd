class_name BolotaGigante
extends Node3D
## A Bolota gigante rolando, o momento especial da 1-1 (item 9 da lista do Faísca, 2026-11-11: "uma Bolota gigante
## rolando atrás dele"). Na Ponte Fofa, quando o Faísca passa pelo gatilho, ela cai do céu atrás dele e desce rolando
## pelo caminho, um pouco mais devagar do que ele corre. Se alcançar, ele fica achatadinho (de desenho) e volta para o
## começo do trecho, sem perder coração, e ela some para cair de novo quando ele voltar. No fim do caminho tem uma
## curva que ela não consegue fazer: segue reto, cai nas nuvens e o prêmio aparece (a fase faz isso no `vencida`).
## A bola gira inteira, com listras lilases; a cara (os olhos, o sorriso e a antena) fica sempre virada para a frente.

signal comecou
signal pegou
signal vencida

const RAIO := 2.6
const VELOCIDADE := 5.0
const ACELERA := 2.5
## Distância (no caminho) até onde ela pega quem está na frente.
const ALCANCE := RAIO + 0.3

## O caminho do pé dela, do começo até depois da beira (onde ela cai).
var caminho := PackedVector3Array()
var gatilho_centro := Vector3.ZERO
var gatilho_tamanho := Vector3(6, 4, 3)
## Onde o Faísca volta quando ela alcança.
var retorno := Vector3.ZERO
## "esperando", "rolando", "voltando" ou "vencida".
var estado := "esperando"
var vezes_que_pegou := 0
var avanco := 0.0
var _curva: Curve3D
var _vel := 0.0
var _corpo: Node3D
var _rosto: Node3D
var _jogador: Jogador
var _som: AudioStreamPlayer3D
var _tremer := 0.0


func _ready() -> void:
	_curva = Curve3D.new()
	_curva.bake_interval = 0.4
	for p in caminho:
		_curva.add_point(p)
	_montar_visual()
	hide()
	var gatilho := Area3D.new()
	gatilho.collision_layer = 0
	gatilho.collision_mask = Fase.CAMADA_JOGADOR
	gatilho.monitorable = false
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = gatilho_tamanho
	cs.shape = caixa
	gatilho.add_child(cs)
	add_child(gatilho)
	gatilho.top_level = true
	gatilho.global_position = gatilho_centro
	gatilho.body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador and corpo.controle_ligado:
			comecar(corpo))


## Cai do céu no começo do caminho e começa a rolar atrás do Faísca.
func comecar(j: Jogador) -> void:
	if estado != "esperando":
		return
	estado = "rolando"
	_jogador = j
	avanco = 0.0
	_vel = 1.0
	var p := _curva.sample_baked(0.0) + Vector3.UP * RAIO
	global_position = p + Vector3.UP * 10.0
	scale = Vector3.ONE
	show()
	var tw := create_tween()
	tw.tween_property(self, "global_position", p, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		Sfx.play_at(get_parent(), "bonk", global_position, 4.0, 0.0)
		Fx.dust(get_parent(), global_position - Vector3.UP * RAIO)
		if is_instance_valid(_jogador):
			_jogador.tremidinha(0.6))
	_som = Sfx.play_at(get_parent(), "rolar", global_position, -2.0, 0.0)
	if _som:
		_som.finished.disconnect(_som.queue_free)
		_som.finished.connect(_som.play)
	comecou.emit()


func _physics_process(delta: float) -> void:
	if _som and is_instance_valid(_som):
		_som.global_position = global_position
	if estado != "rolando" or avanco < 0.0:
		return
	# Espera o tombo do céu terminar (o tween) antes de rolar.
	if global_position.y > _curva.sample_baked(0.0).y + RAIO + 0.2 and avanco == 0.0:
		return
	_vel = move_toward(_vel, VELOCIDADE, ACELERA * delta)
	avanco += _vel * delta
	var fim := _curva.get_baked_length()
	if avanco >= fim:
		_cair()
		return
	var p := _curva.sample_baked(avanco)
	var frente := (_curva.sample_baked(minf(avanco + 0.6, fim)) - p)
	frente.y = 0.0
	frente = frente.normalized() if frente.length() > 0.01 else Vector3.FORWARD
	global_position = p + Vector3.UP * RAIO
	_corpo.rotate(Vector3.UP.cross(frente).normalized(), _vel * delta / RAIO)
	_rosto.rotation.y = atan2(frente.x, frente.z)
	var j := _jogador
	if not is_instance_valid(j):
		return
	var d := j.global_position - global_position
	var longe := Vector2(d.x, d.z).length()
	_tremer -= delta
	if longe < 10.0 and _tremer <= 0.0:
		_tremer = 0.2
		j.tremidinha(0.35 * (1.0 - longe / 10.0))
	if j.controle_ligado and longe < ALCANCE and d.y > -RAIO - 1.0 and d.y < RAIO * 0.8:
		_pegar()


## Alcançou: o Faísca fica achatadinho, volta para o começo do trecho (sem perder coração) e ela some.
func _pegar() -> void:
	estado = "voltando"
	vezes_que_pegou += 1
	pegou.emit()
	var j := _jogador
	j.controle_ligado = false
	Sfx.play_at(get_parent(), "bonk", j.global_position, 2.0, 0.0)
	j.robo.expressao("dor", 0.9)
	var tw := j.create_tween()
	tw.tween_property(j.robo, "scale", Vector3(1.5, 0.2, 1.5), 0.08)
	tw.tween_interval(0.5)
	tw.tween_callback(func() -> void:
		j.teleportar(retorno)
		j.robo.scale = Vector3.ONE
		j.controle_ligado = true)
	_parar_som()
	var tw2 := create_tween()
	tw2.tween_property(self, "scale", Vector3.ONE * 0.01, 0.4).set_delay(0.3)
	tw2.tween_callback(func() -> void:
		hide()
		scale = Vector3.ONE
		estado = "esperando")


## Chegou à curva que não faz: segue reto, cai nas nuvens rodando e some.
func _cair() -> void:
	estado = "vencida"
	_parar_som()
	var fim := _curva.sample_baked(_curva.get_baked_length())
	var antes := _curva.sample_baked(maxf(_curva.get_baked_length() - 1.0, 0.0))
	var frente := (fim - antes)
	frente.y = 0.0
	frente = frente.normalized() if frente.length() > 0.01 else Vector3.FORWARD
	var tw := create_tween()
	tw.tween_property(self, "global_position", global_position + frente * 6.0 + Vector3.DOWN * 3.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "global_position", global_position + frente * 9.0 + Vector3.DOWN * 30.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "scale", Vector3.ONE * 0.3, 1.2)
	tw.tween_callback(func() -> void:
		Sfx.play_at(get_parent(), "bolota_estoura", global_position, 0.0, 0.0)
		hide())
	Sfx.play_at(get_parent(), "golpe_ar", global_position, 0.0, 0.0)
	vencida.emit()


func _parar_som() -> void:
	if _som and is_instance_valid(_som):
		_som.stop()
		_som.queue_free()
	_som = null


func _montar_visual() -> void:
	_corpo = Node3D.new()
	add_child(_corpo)
	var roxo := _mat(Color("9b5de5"), 0.6)
	var lilas := _mat(Color("c9a7ff"), 0.6)
	var corpo := MeshInstance3D.new()
	corpo.mesh = Forma.superelipsoide(Vector3(RAIO, RAIO, RAIO), 1.0, 1.0, -PI / 2.0, 20, 32)
	corpo.material_override = roxo
	_corpo.add_child(corpo)
	# Listras lilases: três anéis em volta, que mostram a bola girando.
	for k in 3:
		var anel := MeshInstance3D.new()
		var toro := TorusMesh.new()
		toro.inner_radius = RAIO * 0.98
		toro.outer_radius = RAIO * 1.04
		toro.rings = 36
		toro.ring_segments = 8
		anel.mesh = toro
		anel.material_override = lilas
		anel.rotation = Vector3(PI / 2.0, TAU * k / 3.0, 0)
		_corpo.add_child(anel)
	# A cara, sempre para a frente: olhos grandes, sobrancelhas de quem está correndo atrás e o sorrisão.
	_rosto = Node3D.new()
	add_child(_rosto)
	var branco := _mat(Color.WHITE, 0.2)
	var preto := _mat(Color("1b1530"), 0.2)
	for lado in [-1.0, 1.0]:
		var olho := MeshInstance3D.new()
		olho.mesh = _esfera(0.62)
		olho.material_override = branco
		olho.position = Vector3(0.85 * lado, 0.7, RAIO - 0.25)
		_rosto.add_child(olho)
		var pupila := MeshInstance3D.new()
		pupila.mesh = _esfera(0.3)
		pupila.material_override = preto
		pupila.position = Vector3(0.8 * lado, 0.75, RAIO + 0.25)
		_rosto.add_child(pupila)
		var sobrancelha := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.12
		cap.height = 0.9
		sobrancelha.mesh = cap
		sobrancelha.material_override = preto
		sobrancelha.position = Vector3(0.85 * lado, 1.55, RAIO - 0.35)
		sobrancelha.rotation = Vector3(0, 0, PI / 2.0 + 0.35 * lado)
		_rosto.add_child(sobrancelha)
	var boca := MeshInstance3D.new()
	var meia := TorusMesh.new()
	meia.inner_radius = 0.55
	meia.outer_radius = 0.75
	boca.mesh = meia
	boca.material_override = _mat(Color("5a1e3c"), 0.4)
	boca.position = Vector3(0, -0.45, RAIO - 0.35)
	boca.rotation = Vector3(PI / 2.0, 0, 0)
	boca.scale = Vector3(1.0, 1.0, 0.55)
	_rosto.add_child(boca)
	var haste := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.08
	cil.bottom_radius = 0.1
	cil.height = 1.3
	haste.mesh = cil
	haste.material_override = _mat(Color("3d2e5c"), 0.5)
	haste.position = Vector3(0, RAIO + 0.55, 0)
	_rosto.add_child(haste)
	var bolinha := MeshInstance3D.new()
	bolinha.mesh = _esfera(0.32)
	bolinha.material_override = _mat(Color("ff5a6e"), 0.4)
	bolinha.position = Vector3(0, RAIO + 1.3, 0)
	_rosto.add_child(bolinha)


func _mat(cor: Color, rugosidade: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugosidade
	return m


func _esfera(raio: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = raio
	s.height = raio * 2.0
	return s
