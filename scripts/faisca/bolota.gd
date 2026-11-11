class_name Bolota
extends Alvo
## Bolota das fases: a mesma bolota roxa do treino, mas anda devagar até o Faísca quando ele
## chega perto, e encostar nele tira um coração. Pode começar dormindo (ronca bolhinhas e só
## acorda com o Faísca bem perto ou levando um golpe). Não sai da ilha dela: na beirada para.
## Derrotada, a fase solta 3 estrelinhas no lugar e ela sai quicando pequenininha.
## Quando o Faísca dança perto (item 6 da lista do Faísca, 2026-11-11), ela para tudo para olhar: vira para ele,
## dança junto, solta coraçõezinhos e não encosta nele; quando a dança acaba, aplaude e volta ao que fazia.

@export var dormindo := false
@export var velocidade := 2.2
## Começa a seguir o Faísca a esta distância e desiste a esta outra.
@export var ve_de := 7.5
@export var desiste_de := 11.0

const ACORDA_DE := 3.2
## Os corpos se encostam a 1,12 m (a esfera da Bolota, 0,62 m, mais a cápsula do Faísca, 0,5 m): o toque vale um pouco
## além disso. Era 1,05 m, e com o Faísca parado ela encostava e nunca machucava (relato do usuário em 2026-11-11).
const ALCANCE_TOQUE := 1.25
## Até onde ela vê o Faísca dançando.
const ASSISTE_DE := 10.0

## Distância em que encostar tira coração (a Bolotona, grande, tem mais).
var alcance_toque := ALCANCE_TOQUE

var _seguindo := false
## Depois de encostar no Faísca ou levar um golpe, fica um tempinho parada.
var _pausa := 0.0
var _bolhas := 0.0
var _zzz: Node3D
## Olhando a dança do Faísca agora, e quantas vezes olhou (para os testes).
var assistindo := false
var vezes_que_assistiu := 0
## Altura dos coraçõezinhos (a Bolotona, grande, põe mais alto).
var altura_coracao := 1.6
var _coracao := 0.0
## Depois de olhar a dança, um instante parada e sem encostar (aplaudindo).
var _depois_da_danca := 0.0


func _ready() -> void:
	volta = false
	# Modo Fácil (Ajustes): anda mais devagar.
	if Ajustes.facil:
		velocidade *= 0.8
	super()
	if dormindo:
		_corpo.rotation.x = 0.25


func _physics_process(delta: float) -> void:
	super(delta)
	if derrotado or agarrada or voando:
		return
	_pausa -= delta
	_depois_da_danca -= delta
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
	var ve_danca := jogador.dancando > 0.0 and tonta <= 0.0 and longe < ASSISTE_DE and absf(d.y) < 3.0 and _pode_assistir()
	if ve_danca != assistindo:
		if ve_danca:
			_comecar_a_assistir()
		else:
			_parar_de_assistir()
	if assistindo:
		_assistir(delta)
		return
	# Encostou: tira um coração (tonta, não). Quem vem caindo por cima é pisão, não toque.
	if _pausa <= 0.0 and _depois_da_danca <= 0.0 and tonta <= 0.0 and longe < alcance_toque and d.y > -0.6 and d.y < 1.0:
		if jogador.receber_dano(global_position):
			_pausa = 1.0
			_amasso = 0.25
	if not _seguindo and longe < ve_de and absf(d.y) < 2.5:
		_seguindo = true
	elif _seguindo and (longe > desiste_de or absf(d.y) > 4.0):
		_seguindo = false


func receber_golpe(dano: int, de: Vector3, forca := 6.0, tipo := "") -> bool:
	if dormindo:
		_acordar()
	var levou := super(dano, de, forca, tipo)
	if levou:
		_pausa = 0.6
	return levou


func ser_agarrada() -> void:
	_acordar()
	super()


func _andar(_delta: float) -> Vector3:
	if dormindo or assistindo or _pausa > 0.0 or _depois_da_danca > 0.0 or not is_on_floor():
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
	return not dormindo and tonta <= 0.0


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


# --- olhando a dança (item 6) -----------------------------------------------------------

## Se agora dá para parar e olhar (o monstro no meio de uma corrida ou de um rasante, não).
func _pode_assistir() -> bool:
	return true


func _comecar_a_assistir() -> void:
	assistindo = true
	vezes_que_assistiu += 1
	_coracao = 0.3
	_empurrao = Vector3.ZERO


## A dança acabou (ou ele saiu de perto): aplaude com um pulinho e fica um instante parada antes de voltar.
func _parar_de_assistir() -> void:
	assistindo = false
	_corpo.rotation.z = 0.0
	_depois_da_danca = 0.8
	if is_on_floor():
		velocity.y = 3.0
	_aplaudir()


func _aplaudir() -> void:
	_amasso = 0.25


## Olhando: balança junto no ritmo e, de tempos em tempos, um coraçãozinho sobe da cabeça.
func _assistir(delta: float) -> void:
	_dancar_junto()
	_coracao -= delta
	if _coracao > 0.0:
		return
	_coracao = 0.9
	var c := MeshInstance3D.new()
	c.mesh = Fx.heart_mesh(0.22, 0.1)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("ff5d8f")
	m.emission_enabled = true
	m.emission = Color("ff5d8f")
	m.emission_energy_multiplier = 0.8
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	c.material_override = m
	c.top_level = true
	add_child(c)
	c.global_position = global_position + Vector3(randf_range(-0.25, 0.25), altura_coracao, randf_range(-0.25, 0.25))
	c.scale = Vector3.ONE * 0.3
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "global_position:y", c.global_position.y + 1.1, 1.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "rotation:y", randf_range(-0.6, 0.6), 1.1)
	tw.chain().tween_property(c, "scale", Vector3.ONE * 0.01, 0.2)
	tw.chain().tween_callback(c.queue_free)


## A Bolota roxa (sem animação) balança de um lado para o outro; o monstro troca isto pela animação de dança.
func _dancar_junto() -> void:
	_corpo.rotation.z = sin(_tempo * 7.0) * 0.18
