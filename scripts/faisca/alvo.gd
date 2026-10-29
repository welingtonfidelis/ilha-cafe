class_name Alvo
extends CharacterBody3D
## Inimigo de treino da cena de teste: bolota roxa de um olho só, meio brava. Leva 3 de dano;
## a cada acerto pisca, dá um pulinho e é empurrada. Derrotada, estoura em estrelinhas e volta
## depois de alguns segundos. Golpes, laser dos pés e pisão chamam `receber_golpe`.
## A Bolota das fases (`Bolota`) herda daqui: anda, encosta e não volta depois de derrotada.
## O Faísca agarra pela antena (Y), gira em volta dele e arremessa (pedido do usuário em 2026-10-29, movimentos
## do Astro): agarrada ela não anda nem machuca; voando, estoura no que bater e acerta quem estiver no caminho.

signal derrotada(alvo: Alvo)

const CAMADA := 1 << 2
## Tudo o que os golpes acertam fica neste grupo, com `derrotado` e `receber_golpe` (o baú também).
const GRUPO := "alvos"

@export var vida_max := 3
@export var volta_depois := 4.0
## Derrotada, volta depois de `volta_depois` (treino) ou sai quicando pequenininha (fases).
@export var volta := true

var vida := 3
var derrotado := false
## Folga do alcance dos golpes além do centro (o baú grande tem mais).
var raio_golpe := 0.6
var visual: Node3D
## Na mão do Faísca (ele põe no lugar a cada quadro) e voando depois de arremessada.
var agarrada := false
var voando := false

var _corpo: Node3D
var _mat_corpo: StandardMaterial3D
var _empurrao := Vector3.ZERO
var _imune := 0.0
var _piscar := 0.0
var _amasso := 0.0
var _origem := Vector3.ZERO
var _tempo := 0.0
var _gravidade := 26.0
## Último ponto do voo com chão embaixo: se estourar em cima do vazio, as estrelinhas caem aqui.
var _sobre_chao := Vector3.ZERO
var _voo := 0.0


func _ready() -> void:
	add_to_group(GRUPO)
	collision_layer = CAMADA
	collision_mask = 1
	_origem = global_position
	_tempo = randf() * 10.0
	vida = vida_max
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.62
	cs.shape = esfera
	cs.position.y = 0.62
	add_child(cs)
	visual = Node3D.new()
	add_child(visual)
	_corpo = Node3D.new()
	visual.add_child(_corpo)
	_montar_visual()


func _montar_visual() -> void:
	_mat_corpo = _material(Color("9b5de5"))
	_mat_corpo.emission = Color.WHITE
	_mat_corpo.emission_energy_multiplier = 1.2
	var escuro := _material(Color("3d2e5c"))
	_parte(Forma.superelipsoide(Vector3(0.62, 0.56, 0.62), 0.9, 0.9), _mat_corpo, Vector3(0, 0.62, 0))
	_parte(Forma.superelipsoide(Vector3(0.36, 0.3, 0.18), 1.0, 1.0), _material(Color("c9a7ff")), Vector3(0, 0.5, 0.46))
	_parte(_esfera(0.21), _material(Color.WHITE, 0.2), Vector3(0, 0.8, 0.48))
	_parte(_esfera(0.095), _material(Color("1b1530"), 0.15), Vector3(0, 0.8, 0.66))
	for lado in [-1.0, 1.0]:
		# Sobrancelha em V: cara de brava.
		_parte(_capsula(0.045, 0.22), escuro, Vector3(0.1 * lado, 1.04, 0.5), Vector3(0, 0, PI / 2 + 0.45 * lado))
		_parte(Forma.superelipsoide(Vector3(0.16, 0.08, 0.2), 1.0, 1.0), escuro, Vector3(0.26 * lado, 0.07, 0.08))
	var haste := CylinderMesh.new()
	haste.top_radius = 0.025
	haste.bottom_radius = 0.025
	haste.height = 0.3
	_parte(haste, escuro, Vector3(0, 1.28, 0))
	_parte(_esfera(0.08), _material(Color("ff5a6e")), Vector3(0, 1.45, 0))


func _physics_process(delta: float) -> void:
	_tempo += delta
	_imune -= delta
	_piscar -= delta
	_amasso = move_toward(_amasso, 0.0, delta * 2.5)
	_mat_corpo.emission_enabled = _piscar > 0.0
	var respira := sin(_tempo * 4.0) * 0.04
	_corpo.scale = Vector3(1.0 + _amasso - respira, 1.0 - _amasso + respira, 1.0 + _amasso - respira)
	if derrotado or agarrada:
		return
	if voando:
		_voar(delta)
		return
	var andar := _andar(delta)
	velocity.x = _empurrao.x + andar.x
	velocity.z = _empurrao.z + andar.z
	_empurrao = _empurrao.lerp(Vector3.ZERO, 1.0 - exp(-6.0 * delta))
	if not is_on_floor():
		velocity.y -= _gravidade * delta
	move_and_slide()
	if global_position.y < _origem.y - 20.0:
		_voltar()
	var jogador := get_tree().get_first_node_in_group("jogador") as Node3D
	if jogador and _olhar_jogador():
		var d := jogador.global_position - global_position
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(d.x, d.z), 1.0 - exp(-5.0 * delta))


## O Faísca pegou pela antena: para de andar, sai do caminho dele e treme as perninhas.
func ser_agarrada() -> void:
	agarrada = true
	collision_layer = 0
	_empurrao = Vector3.ZERO
	velocity = Vector3.ZERO
	_piscar = 0.12


## Solta sem arremessar (o Faísca levou um golpe segurando): cai de pé onde está.
func ser_solta() -> void:
	agarrada = false
	collision_layer = CAMADA
	visual.rotation = Vector3.ZERO
	velocity = Vector3.ZERO


## Arremessada com a velocidade `vel`: voa rodando até bater em alguma coisa.
func ser_arremessada(vel: Vector3) -> void:
	agarrada = false
	voando = true
	_voo = 0.0
	_sobre_chao = global_position
	velocity = vel
	# Sem colisão com o Faísca, só com o mundo.
	collision_layer = 0
	collision_mask = 1


func _voar(delta: float) -> void:
	_voo += delta
	velocity.y -= _gravidade * delta
	visual.rotation.x += 14.0 * delta
	move_and_slide()
	var espaco := get_world_3d().direct_space_state
	var abaixo := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.6, global_position + Vector3.DOWN * 6.0, 1))
	if not abaixo.is_empty():
		_sobre_chao = global_position
	# Acertou alguém (ou o baú, a parede rachada, a alavanca): os dois levam, e ela estoura.
	var meio := global_position + Vector3.UP * 0.62
	for outro in get_tree().get_nodes_in_group(GRUPO):
		if outro == self or outro.derrotado or (outro is Alvo and (outro as Alvo).agarrada):
			continue
		var centro: Vector3 = (outro as Node3D).global_position + Vector3.UP * 0.6
		if meio.distance_to(centro) < 0.62 + float(outro.raio_golpe) + 0.2:
			outro.receber_golpe(2, global_position, 8.0)
			_estourar()
			return
	# Bateu no chão ou numa parede, caiu longe demais ou voou tempo demais.
	if get_slide_collision_count() > 0 or global_position.y < _sobre_chao.y - 4.0 or _voo > 2.5:
		_estourar()


## Fim do voo: estoura em estrelinhas. Em cima do vazio, estoura no último ponto que tinha chão embaixo.
func _estourar() -> void:
	voando = false
	collision_mask = 1
	if global_position.y < _sobre_chao.y - 0.5 or get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.6, global_position + Vector3.DOWN * 6.0, 1)).is_empty():
		global_position = _sobre_chao
	visual.rotation = Vector3.ZERO
	vida = 0
	_derrotar()


## Quanto a bolota anda sozinha (a de treino fica parada).
func _andar(_delta: float) -> Vector3:
	return Vector3.ZERO


func _olhar_jogador() -> bool:
	return true


## Leva um golpe vindo de `de`. Fica imune um instante, para o laser não tirar vida a cada quadro.
func receber_golpe(dano: int, de: Vector3, forca := 6.0) -> bool:
	if derrotado or _imune > 0.0 or agarrada or voando:
		return false
	vida -= dano
	_imune = 0.25
	_piscar = 0.12
	_amasso = 0.35
	var dir := global_position - de
	dir.y = 0.0
	_empurrao = dir.normalized() * forca if dir.length() > 0.05 else Vector3.ZERO
	velocity.y = 3.5
	if vida <= 0:
		_derrotar()
	return true


func _derrotar() -> void:
	derrotado = true
	collision_layer = 0
	_estrelinhas()
	derrotada.emit(self)
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector3.ONE * 1.3, 0.08)
	tw.tween_property(visual, "scale", Vector3.ONE * 0.01, 0.12)
	tw.tween_callback(visual.hide)
	if volta:
		tw.tween_interval(volta_depois)
		tw.tween_callback(_voltar)
	else:
		tw.tween_callback(_sair_quicando)


## Vira uma bolotinha envergonhada que sai quicando para longe e some.
func _sair_quicando() -> void:
	var mini := Node3D.new()
	add_child(mini)
	mini.top_level = true
	mini.global_position = global_position
	var corpo := MeshInstance3D.new()
	corpo.mesh = Forma.superelipsoide(Vector3(0.2, 0.18, 0.2), 0.9, 0.9)
	corpo.material_override = _material(Color("9b5de5"))
	corpo.position.y = 0.18
	mini.add_child(corpo)
	var olho := MeshInstance3D.new()
	olho.mesh = _esfera(0.07)
	olho.material_override = _material(Color.WHITE, 0.2)
	olho.position = Vector3(0, 0.24, 0.15)
	mini.add_child(olho)
	var a := randf() * TAU
	var passo := Vector3(cos(a), 0, sin(a)) * 1.2
	mini.rotation.y = atan2(passo.x, passo.z)
	var tw := mini.create_tween()
	for i in 4:
		var de := mini.global_position + passo * i
		tw.tween_property(mini, "global_position", de + passo * 0.5 + Vector3.UP * 0.7, 0.16).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(mini, "global_position", de + passo, 0.16).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(mini, "scale", Vector3.ONE * 0.01, 0.2)
	tw.tween_callback(mini.queue_free)


func _voltar() -> void:
	agarrada = false
	voando = false
	visual.rotation = Vector3.ZERO
	global_position = _origem
	velocity = Vector3.ZERO
	_empurrao = Vector3.ZERO
	vida = vida_max
	derrotado = false
	collision_layer = CAMADA
	visual.show()
	visual.scale = Vector3.ONE * 0.01
	create_tween().tween_property(visual, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _estrelinhas() -> void:
	var malha := Forma.estrela(0.16, 0.07, 0.08)
	var mat := _material(Color("ffd23f"), 0.3)
	mat.emission_enabled = true
	mat.emission = Color("ffb800")
	mat.emission_energy_multiplier = 1.0
	var centro := global_position + Vector3(0, 0.7, 0)
	for i in 7:
		var e := MeshInstance3D.new()
		e.mesh = malha
		e.material_override = mat
		e.top_level = true
		add_child(e)
		e.global_position = centro
		var a := TAU * i / 7.0
		var tw := e.create_tween().set_parallel()
		tw.tween_property(e, "global_position", centro + Vector3(cos(a) * 1.4, 0.9 + randf() * 0.6, sin(a) * 1.4), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(e, "rotation:y", TAU, 0.45)
		tw.tween_property(e, "scale", Vector3.ONE * 0.01, 0.3).set_delay(0.2)
		tw.chain().tween_callback(e.queue_free)


func _parte(malha: Mesh, mat: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	_corpo.add_child(mi)
	return mi


func _material(cor: Color, rugosidade := 0.45) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugosidade
	return m


func _esfera(raio: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = raio
	s.height = raio * 2.0
	return s


func _capsula(raio: float, altura: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = raio
	c.height = altura
	return c
