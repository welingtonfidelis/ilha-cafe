class_name Canhao
extends Node3D
## Canhão de nuvem (o cannon_base do Platformer Pack), pedido do usuário em 2026-10-29 ("as fases estão muito
## curtas"). O Faísca anda até o canhão e entra, o canhão se encolhe e faz "bum" com confete, e ele sai voando num
## arco alto até `destino`, girando, sem controle, e pousa lá. É o "uau" do fim da 1-1. O canhão olha para +Z (a
## boca do cano fica desse lado) e se vira sozinho para o destino.

signal disparou

const VOO := 2.2
const ALTURA_VOO := 12.0
const BOCA := Vector3(0, 2.6, 1.4)

var destino := Vector3.ZERO
var cor := "blue"
## Outro modelo no lugar do cannon_base (o canhão de bolas de neve do Holiday Bits na 3-1), com a escala dele.
var modelo := ""
var escala_modelo := 1.2
var voando := false
## Trancado (a 1-1, item 12: a saída das Ilhas das Argolas só abre passando pelas quatro argolas): uma rolha no cano e
## uma luzinha por argola na base, que acende com cada uma; com todas, a rolha salta e o canhão fica pronto.
var travado := false
var luzes_acesas := 0
var _rolha: Node3D
var _luzes: Array[MeshInstance3D] = []
var _area: Area3D
var _modelo: Node3D
var _jogador: Jogador
var _de := Vector3.ZERO
var _tempo := 0.0
var _espera := 0.0


func _ready() -> void:
	var para := destino - global_position
	rotation.y = atan2(para.x, para.z)
	_modelo = load(modelo if modelo != "" else Fase.PLATAFORMA + "cannon_base_%s.gltf" % cor).instantiate()
	_modelo.scale = Vector3.ONE * escala_modelo
	# Só a base é sólida: encostando no cano, o Faísca já entra nele.
	add_child(Fase.so_enfeite(_modelo))
	var corpo := StaticBody3D.new()
	corpo.collision_layer = 1
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(2.4, 0.7, 2.4)
	cs.shape = caixa
	cs.position.y = 0.35
	corpo.add_child(cs)
	add_child(corpo)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = Fase.CAMADA_JOGADOR
	var forma := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 1.9
	cil.height = 3.0
	forma.shape = cil
	forma.position.y = 1.5
	area.add_child(forma)
	add_child(area)
	_area = area
	area.body_entered.connect(func(corpo_que_entrou: Node3D) -> void:
		if corpo_que_entrou is Jogador and not voando and not travado and _espera <= 0.0 and corpo_que_entrou.controle_ligado:
			entrar(corpo_que_entrou))


## Tranca o canhão com uma rolha e `n` luzinhas apagadas, nas `cores` das argolas.
func travar(cores: Array) -> void:
	travado = true
	# Enfeite: a rolha não segura nada (quem pisa no canhão entra pela área dele).
	_rolha = Fase.so_enfeite(Node3D.new())
	add_child(_rolha)
	_rolha.position = BOCA + Vector3(0, 0.1, -0.1)
	_rolha.rotation.x = 0.75
	var rolha := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.62
	cil.bottom_radius = 0.52
	cil.height = 0.7
	rolha.mesh = cil
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("c8904a")
	m.roughness = 0.9
	rolha.material_override = m
	_rolha.add_child(rolha)
	for i in cores.size():
		var luz := MeshInstance3D.new()
		var bola := SphereMesh.new()
		bola.radius = 0.18
		bola.height = 0.36
		luz.mesh = bola
		var ml := StandardMaterial3D.new()
		ml.albedo_color = Color("4a4658")
		ml.emission = Fase.cor_da_argola(String(cores[i]))
		luz.material_override = ml
		var a := PI + (i - (cores.size() - 1) * 0.5) * 0.45
		luz.position = Vector3(sin(a) * 1.35, 0.75, cos(a) * 1.35)
		add_child(luz)
		_luzes.append(luz)


## Acende as primeiras `n` luzinhas; com todas, destrava.
func acender_luzes(n: int) -> void:
	if not travado:
		return
	for i in _luzes.size():
		var ml := _luzes[i].material_override as StandardMaterial3D
		var acesa := i < n
		if acesa and not ml.emission_enabled:
			ml.albedo_color = ml.emission
			ml.emission_enabled = true
			ml.emission_energy_multiplier = 2.0
			Sfx.play_at(get_parent(), "estrelinha", _luzes[i].global_position, -6.0, 0.0)
	luzes_acesas = n
	if n >= _luzes.size():
		destravar()


## A rolha salta com confete e o canhão fica pronto (quem já está em cima entra).
func destravar() -> void:
	if not travado:
		return
	travado = false
	if _rolha:
		var r := _rolha
		var tw := r.create_tween()
		tw.tween_property(r, "position", r.position + Vector3(0, 6, 3), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(r, "rotation:x", r.rotation.x + TAU * 2.0, 0.6)
		tw.tween_property(r, "scale", Vector3.ONE * 0.01, 0.25)
		tw.tween_callback(r.queue_free)
		_rolha = null
	Fx.confetti(get_parent(), to_global(BOCA), 40, 6.0)
	Sfx.play_at(get_parent(), "estouro", to_global(BOCA), 0.0, 0.0)


## O Faísca entra: some dentro do cano, o canhão se prepara e dispara.
func entrar(j: Jogador) -> void:
	voando = true
	_jogador = j
	j.controle_ligado = false
	j.velocity = Vector3.ZERO
	j.set_physics_process(false)
	j.global_position = to_global(BOCA) - Vector3.UP * 1.0
	j.robo.visible = false
	var para := destino - global_position
	para.y = 0.0
	j.yaw = atan2(-para.x, -para.z)
	j.visual.rotation.y = j.yaw + PI
	var tw := create_tween()
	tw.tween_property(_modelo, "scale", Vector3(1.35, 0.95, 1.35) * escala_modelo / 1.2, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_disparar)
	tw.tween_property(_modelo, "scale", Vector3.ONE * escala_modelo, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _disparar() -> void:
	var boca := to_global(BOCA)
	Fx.confetti(get_parent(), boca, 40, 6.0)
	Fx.dust(get_parent(), boca)
	Sfx.play_at(get_parent(), "pancada", boca, 0.0)
	_jogador.robo.visible = true
	_jogador.robo.animar("mov/Jump_Idle", 0.1)
	_de = boca
	_tempo = 0.0
	disparou.emit()


func _physics_process(delta: float) -> void:
	_espera -= delta
	# Destravou com o Faísca já em cima: ele entra.
	if not voando and not travado and _espera <= 0.0 and _area:
		for corpo in _area.get_overlapping_bodies():
			if corpo is Jogador and (corpo as Jogador).controle_ligado:
				entrar(corpo)
				break
	if not voando or not is_instance_valid(_jogador):
		return
	# Com o Faísca no canhão, o processo de física dele fica desligado: o canhão leva a câmera junto (dentro do cano
	# e no voo).
	if _de == Vector3.ZERO:
		_jogador.acompanhar_camera(delta)
		return
	_tempo += delta
	var t := clampf(_tempo / VOO, 0.0, 1.0)
	_jogador.global_position = ponto_do_voo(_de, destino, t)
	_jogador.visual.rotation.x = TAU * 2.0 * t
	_jogador.acompanhar_camera(delta)
	if t >= 1.0:
		_pousar()


## Onde o Faísca está no voo, de 0 (boca do canhão) a 1 (destino): um arco que sobe ALTURA_VOO no meio.
static func ponto_do_voo(de: Vector3, ate: Vector3, t: float) -> Vector3:
	return de.lerp(ate, t) + Vector3.UP * ALTURA_VOO * 4.0 * t * (1.0 - t)


func _pousar() -> void:
	var j := _jogador
	voando = false
	_de = Vector3.ZERO
	_espera = 1.0
	j.visual.rotation.x = 0.0
	j.global_position = destino
	j.velocity = Vector3.DOWN * 2.0
	j.set_physics_process(true)
	j.controle_ligado = true
	Fx.dust(get_parent(), destino)
	_jogador = null
