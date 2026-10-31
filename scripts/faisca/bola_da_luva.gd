class_name BolaDaLuva
extends Node3D
## A bola de neve que a Luva de Neve joga (3-1 Pico Gelado, 2026-10-30; Jogador.jogar_bola_de_neve). Com `alvo`, ela vai
## sozinha até ele, fazendo uma curvinha: no sino, faz ele tocar (Sino.tocar); na Bolota, conta como arremesso, então
## acerta até o fantasma. Sem alvo, ela voa reto para a frente, cai um pouco e se desfaz.

const VELOCIDADE := 26.0
const VIDA_SEM_ALVO := 0.9

var alvo: Node3D
var vel := Vector3.ZERO
var _tempo := 0.0


## Onde a bola acerta: no meio do sino, no meio do corpo da Bolota.
static func ponto_de(no: Node3D) -> Vector3:
	if no is Sino:
		return (no as Sino).ponto()
	return no.global_position + Vector3.UP * 0.8


func _ready() -> void:
	Fase.so_enfeite(self)
	var modelo: Node3D = load("res://assets/faisca/neve/snowball.gltf").instantiate()
	modelo.scale = Vector3.ONE * 1.8
	add_child(modelo)


func _physics_process(delta: float) -> void:
	_tempo += delta
	if alvo and is_instance_valid(alvo) and not (alvo is Alvo and alvo.derrotado):
		var falta := ponto_de(alvo) - global_position
		if falta.length() < 1.0:
			_acertar()
			return
		# Vira para o alvo cada vez mais firme: sai com a curvinha do arremesso e chega reto.
		vel = vel.lerp(falta.normalized() * VELOCIDADE, 1.0 - exp(-(4.0 + _tempo * 12.0) * delta))
		if _tempo > 3.0:
			_desfazer()
			return
	else:
		vel.y -= 18.0 * delta
		if _tempo > VIDA_SEM_ALVO:
			_desfazer()
			return
	global_position += vel * delta
	rotation.x += delta * 9.0


func _acertar() -> void:
	if alvo is Sino:
		(alvo as Sino).tocar()
	elif alvo is Alvo:
		(alvo as Alvo).receber_golpe(1, global_position - vel.normalized(), 5.0, "arremesso")
	_desfazer()


## Puf de neve: confete branco e some.
func _desfazer() -> void:
	set_physics_process(false)
	Fx.confetti(get_parent(), global_position, 10, 1.6)
	queue_free()
