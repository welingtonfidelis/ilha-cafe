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
var voando := false
var _modelo: Node3D
var _jogador: Jogador
var _de := Vector3.ZERO
var _tempo := 0.0
var _espera := 0.0


func _ready() -> void:
	var para := destino - global_position
	rotation.y = atan2(para.x, para.z)
	_modelo = load(Fase.PLATAFORMA + "cannon_base_%s.gltf" % cor).instantiate()
	_modelo.scale = Vector3.ONE * 1.2
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
	area.body_entered.connect(func(corpo_que_entrou: Node3D) -> void:
		if corpo_que_entrou is Jogador and not voando and _espera <= 0.0 and corpo_que_entrou.controle_ligado:
			entrar(corpo_que_entrou))


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
	tw.tween_property(_modelo, "scale", Vector3(1.35, 0.95, 1.35), 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_disparar)
	tw.tween_property(_modelo, "scale", Vector3.ONE * 1.2, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


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
	if not voando or _de == Vector3.ZERO:
		return
	_tempo += delta
	var t := clampf(_tempo / VOO, 0.0, 1.0)
	_jogador.global_position = ponto_do_voo(_de, destino, t)
	_jogador.visual.rotation.x = TAU * 2.0 * t
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
