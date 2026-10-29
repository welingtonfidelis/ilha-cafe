class_name Bolota
extends Alvo
## Bolota das fases: a mesma bolota roxa do treino, mas anda devagar até o Faísca quando ele
## chega perto, e encostar nele tira um coração. Pode começar dormindo (ronca bolhinhas e só
## acorda com o Faísca bem perto ou levando um golpe). Não sai da ilha dela: na beirada para.
## Derrotada, a fase solta 3 estrelinhas no lugar e ela sai quicando pequenininha.

@export var dormindo := false
@export var velocidade := 2.2
## Começa a seguir o Faísca a esta distância e desiste a esta outra.
@export var ve_de := 7.5
@export var desiste_de := 11.0

const ACORDA_DE := 3.2
const ALCANCE_TOQUE := 1.05

## Distância em que encostar tira coração (a Bolotona, grande, tem mais).
var alcance_toque := ALCANCE_TOQUE

var _seguindo := false
## Depois de encostar no Faísca ou levar um golpe, fica um tempinho parada.
var _pausa := 0.0
var _bolhas := 0.0
var _zzz: Node3D


func _ready() -> void:
	volta = false
	super()
	if dormindo:
		_corpo.rotation.x = 0.25


func _physics_process(delta: float) -> void:
	super(delta)
	if derrotado:
		return
	_pausa -= delta
	var jogador := get_tree().get_first_node_in_group("jogador") as Jogador
	if jogador == null:
		return
	var d := jogador.global_position - global_position
	var longe := Vector2(d.x, d.z).length()
	if dormindo:
		_roncar(delta)
		if longe < ACORDA_DE and absf(d.y) < 2.0:
			_acordar()
		return
	# Encostou: tira um coração. Quem vem caindo por cima é pisão, não toque.
	if _pausa <= 0.0 and longe < alcance_toque and d.y > -0.6 and d.y < 1.0:
		if jogador.receber_dano(global_position):
			_pausa = 1.0
			_amasso = 0.25
	if not _seguindo and longe < ve_de and absf(d.y) < 2.5:
		_seguindo = true
	elif _seguindo and (longe > desiste_de or absf(d.y) > 4.0):
		_seguindo = false


func receber_golpe(dano: int, de: Vector3, forca := 6.0) -> bool:
	if dormindo:
		_acordar()
	var levou := super(dano, de, forca)
	if levou:
		_pausa = 0.6
	return levou


func _andar(_delta: float) -> Vector3:
	if dormindo or _pausa > 0.0 or not is_on_floor():
		return Vector3.ZERO
	var alvo := _origem
	if _seguindo:
		var jogador := get_tree().get_first_node_in_group("jogador") as Node3D
		if jogador:
			alvo = jogador.global_position
	var d := alvo - global_position
	d.y = 0.0
	if d.length() < (0.8 if _seguindo else 0.3):
		return Vector3.ZERO
	var dir := d.normalized()
	# Na beirada da ilha ela para (olha um passo à frente e para baixo).
	var frente := global_position + dir * 0.9 + Vector3.UP * 0.5
	var consulta := PhysicsRayQueryParameters3D.create(frente, frente + Vector3.DOWN * 1.6, 1)
	if get_world_3d().direct_space_state.intersect_ray(consulta).is_empty():
		return Vector3.ZERO
	return dir * (velocidade if _seguindo else velocidade * 0.6)


func _olhar_jogador() -> bool:
	return not dormindo


func _acordar() -> void:
	if not dormindo:
		return
	dormindo = false
	_seguindo = true
	_pausa = 0.5
	velocity.y = 4.0
	create_tween().tween_property(_corpo, "rotation:x", 0.0, 0.2)
	if _zzz:
		_zzz.queue_free()
		_zzz = null


## Dormindo: balança devagar e solta bolhinhas que sobem e estouram.
func _roncar(delta: float) -> void:
	_corpo.rotation.z = sin(_tempo * 1.5) * 0.06
	_bolhas -= delta
	if _bolhas > 0.0:
		return
	_bolhas = 0.9
	if _zzz == null:
		_zzz = Node3D.new()
		visual.add_child(_zzz)
	var bolha := MeshInstance3D.new()
	bolha.mesh = _esfera(0.09)
	var m := _material(Color(0.85, 0.95, 1.0, 0.6), 0.1)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bolha.material_override = m
	_zzz.add_child(bolha)
	bolha.position = Vector3(0.15, 1.1, 0.4)
	var tw := bolha.create_tween().set_parallel()
	tw.tween_property(bolha, "position", Vector3(0.35, 2.0, 0.5), 1.4)
	tw.tween_property(bolha, "scale", Vector3.ONE * 2.2, 1.4)
	tw.chain().tween_callback(bolha.queue_free)
