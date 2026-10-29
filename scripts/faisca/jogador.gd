class_name Jogador
extends CharacterBody3D
## O Faísca na mão do jogador. Anda com o analógico (devagar ou rápido, conforme a inclinação),
## pula com A (segurando o botão o pulo vai mais alto) e, segurando A na descida, flutua com
## os jatos dos tênis disparando um laser até o chão, como no Astro: o laser acerta quem estiver
## embaixo. Golpe no X (quadrado no PlayStation): soco, soco e chute no chão, e um giro no ar.
## Cair em cima de um inimigo é um pisão, que quica. Câmera no analógico direito ou no mouse.
## Tem 3 corações: encostar numa Bolota ou cair nas nuvens tira um. Sem corações ele dá um
## curto (faisquinhas e fumacinha) e volta no último posto com os 3 de novo; não tem fim de jogo.
## Base tirada do aventureiro da Ilha Cafuné. Na Parte 2 ele anda também pela ilha (ver Parte2).

signal vida_mudou(vida: int)

@export var velocidade := 6.5
@export var aceleracao := 14.0
@export var controle_no_ar := 0.55
@export var forca_pulo := 10.5
@export var gravidade := 26.0
## Multiplica a gravidade na descida, para o pulo não parecer de balão.
@export var gravidade_queda := 1.45
## Ainda dá para pular logo depois de sair da beirada.
@export var tempo_coiote := 0.12
## Apertar o pulo um pouco antes de pousar também vale.
@export var tempo_memoria_pulo := 0.12
@export var tempo_flutuar := 0.75
@export var sensibilidade_mouse := 0.0025
@export var velocidade_analogico := Vector2(3.0, 2.0)
@export var vibracao := true

const PITCH_MIN := -1.1
const PITCH_MAX := 0.3
const DISTANCIA_CAMERA := 7.5
const ALTURA_QUEDA := -12.0
const VIDA_MAX := 3
## Depois de levar dano, fica piscando e sem levar outro por este tempo.
const TEMPO_INVENCIVEL := 1.6

## Sequência do X no chão. As animações do KayKit têm preparo e volta longos; o golpe começa
## adiantado (`inicio`), mais rápido (`ritmo`), e acerta em `acerto` segundos.
const GOLPES := [
	{"anim": "luta/Melee_Unarmed_Attack_Punch_A", "inicio": 0.25, "ritmo": 1.8, "acerto": 0.17, "duracao": 0.33, "dano": 1, "empurrao": 1.5},
	{"anim": "luta/Melee_Unarmed_Attack_Punch_A", "inicio": 0.25, "ritmo": 2.0, "acerto": 0.15, "duracao": 0.3, "dano": 1, "empurrao": 1.5},
	{"anim": "luta/Melee_Unarmed_Attack_Kick", "inicio": 0.15, "ritmo": 1.6, "acerto": 0.19, "duracao": 0.42, "dano": 2, "empurrao": 9.0},
]
const ALCANCE_GOLPE := 1.8
## Altura máxima entre o meio do Faísca e o meio do inimigo para o golpe pegar.
const ALTURA_GOLPE := 1.6
const TEMPO_GIRO := 0.45
const ALCANCE_GIRO := 2.0
const ALCANCE_LASER := 25.0
## Inimigo a até esta distância, mais ou menos na frente, puxa a mira do golpe (ajuda criança).
const AJUDA_MIRA := 2.8

var robo: Robo
var visual: Node3D
var camera_pivo: Node3D
var camera_inclina: Node3D
var braco_camera: SpringArm3D
var camera: Camera3D
var controle_ligado := true
## Back (Share) volta ao começo da fase; na ilha o Back é o celular das crianças e fica desligado.
var pode_recomecar := true
var flutuando := false
var ponto_retorno := Vector3.ZERO
## Abaixo desta altura ele caiu (a fase diz onde ficam as nuvens).
var limite_queda := ALTURA_QUEDA
var vida := VIDA_MAX
## Começo da fase: desce do céu devagar, com os jatos ligados, até pisar no chão.
var pouso_suave := false
var yaw := 0.0
var pitch := -0.32
## Índice em GOLPES do golpe em andamento, ou -1.
var golpe_atual := -1
## Tempo que falta do giro no ar.
var girando := 0.0
## Para as capturas automáticas: analógico e botões simulados sem passar pelo Input
## (com um controle de verdade ligado, o analógico parado desfaz o evento simulado).
var forcar_direcao := Vector2.ZERO
var forcar_pulo := false
var forcar_golpe := false

var _coiote := 0.0
var _memoria_pulo := 0.0
var _flutuar_restante := 0.0
var _pulou := false
var _cortou_pulo := false
var _decolando := 0.0
var _pousando := 0.0
var _estava_no_ar := false
var _pulo_forcado_antes := false
var _golpe_tempo := 0.0
var _golpe_acertou := false
var _golpe_guardado := false
var _ultimo_golpe := -1
var _combo_janela := 0.0
var _giro_usado := false
var _giro_acertou := false
var _invencivel := 0.0
var _no_curto := false
var _feixes: Array[Node3D] = []
var _impactos: Array[MeshInstance3D] = []


func _ready() -> void:
	add_to_group("jogador")
	collision_layer = 1 << 1
	# Mundo, inimigos e os moradores da ilha (camada 5, a do Townsperson).
	collision_mask = 1 | Alvo.CAMADA | 1 << 4
	var forma := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.5
	capsula.height = 2.2
	forma.shape = capsula
	forma.position.y = 1.1
	add_child(forma)
	floor_snap_length = 0.35
	visual = Node3D.new()
	visual.name = "Visual"
	visual.rotation.y = PI  # o modelo do KayKit olha para +Z; começa de costas para a câmera
	add_child(visual)
	robo = Robo.new()
	visual.add_child(robo)
	_montar_camera()
	_montar_lasers()
	ponto_retorno = global_position


func _montar_camera() -> void:
	camera_pivo = Node3D.new()
	camera_pivo.name = "CameraPivo"
	camera_pivo.position.y = 1.6
	add_child(camera_pivo)
	camera_inclina = Node3D.new()
	camera_pivo.add_child(camera_inclina)
	braco_camera = SpringArm3D.new()
	braco_camera.spring_length = DISTANCIA_CAMERA
	braco_camera.collision_mask = 1
	braco_camera.margin = 0.3
	camera_inclina.add_child(braco_camera)
	camera = Camera3D.new()
	camera.fov = 60.0
	camera.current = true
	braco_camera.add_child(camera)


## Dois feixes (núcleo branco e brilho ciano, cilindros de 1 m esticados na altura) e um
## clarão onde cada um bate. Ficam no espaço do mundo (top_level), sempre na vertical.
func _montar_lasers() -> void:
	var nucleo := _material_laser(Color("e9feff"), 1.0, 6.0)
	var brilho := _material_laser(Color("2fe0ff"), 0.55, 4.0)
	var clarao := _material_laser(Color("8ff3ff"), 0.7, 4.0)
	for i in 2:
		var feixe := Node3D.new()
		feixe.name = "Laser%d" % i
		feixe.top_level = true
		feixe.visible = false
		add_child(feixe)
		for par in [[0.06, nucleo], [0.17, brilho]]:
			var mi := MeshInstance3D.new()
			var cil := CylinderMesh.new()
			cil.top_radius = par[0]
			cil.bottom_radius = par[0]
			cil.height = 1.0
			cil.radial_segments = 16
			mi.mesh = cil
			mi.material_override = par[1]
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			feixe.add_child(mi)
		_feixes.append(feixe)
		var imp := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = 0.32
		esfera.height = 0.1
		imp.mesh = esfera
		imp.material_override = clarao
		imp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		imp.top_level = true
		imp.visible = false
		add_child(imp)
		_impactos.append(imp)


func _material_laser(cor: Color, alfa: float, forca: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(cor, alfa)
	if alfa < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = cor
	m.emission_energy_multiplier = forca
	return m


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("menu"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("recomecar") and controle_ligado and pode_recomecar:
		voltar_ao_inicio()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and controle_ligado:
		yaw -= event.relative.x * sensibilidade_mouse
		pitch = clampf(pitch - event.relative.y * sensibilidade_mouse, PITCH_MIN, PITCH_MAX)


func _physics_process(delta: float) -> void:
	_olhar_com_analogico(delta)
	camera_pivo.rotation.y = yaw
	camera_inclina.rotation.x = pitch

	var entrada := forcar_direcao
	if controle_ligado and entrada == Vector2.ZERO:
		entrada = Input.get_vector("esquerda", "direita", "frente", "tras")
	var base := camera_pivo.global_transform.basis
	var frente := Vector3(-base.z.x, 0.0, -base.z.z).normalized()
	var direita := Vector3(base.x.x, 0.0, base.x.z).normalized()
	var dir := direita * entrada.x + frente * -entrada.y
	if dir.length() > 1.0:
		dir = dir.normalized()

	var no_chao := is_on_floor()
	var apertou_golpe := forcar_golpe or (controle_ligado and Input.is_action_just_pressed("golpe"))
	forcar_golpe = false
	if apertou_golpe:
		_golpear(no_chao, dir)
	_atualizar_golpes(delta, dir)
	var andar := dir * (0.25 if golpe_atual >= 0 else 1.0)

	var acel := aceleracao if no_chao else aceleracao * controle_no_ar
	var horizontal := Vector3(velocity.x, 0.0, velocity.z).lerp(andar * velocidade, 1.0 - exp(-acel * delta))
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	var segurando := forcar_pulo or (controle_ligado and Input.is_action_pressed("pular"))
	var apertou := (forcar_pulo and not _pulo_forcado_antes) or (controle_ligado and Input.is_action_just_pressed("pular"))
	_pulo_forcado_antes = forcar_pulo
	if apertou and golpe_atual < 0:
		_memoria_pulo = tempo_memoria_pulo
	if no_chao:
		_coiote = tempo_coiote
		_pulou = false
		_flutuar_restante = tempo_flutuar
		_giro_usado = false
	else:
		_coiote -= delta
	_memoria_pulo -= delta

	# Começa a flutuar na descida; depois de começar, segue enquanto segurar (ele sobe um pouquinho).
	var pode_flutuar := segurando and _flutuar_restante > 0.0 and girando <= 0.0 and (flutuando or velocity.y <= 0.0)
	flutuando = false
	if _memoria_pulo > 0.0 and _coiote > 0.0:
		velocity.y = forca_pulo
		_memoria_pulo = 0.0
		_coiote = 0.0
		_pulou = true
		_cortou_pulo = false
		_decolando = 0.2
	elif not no_chao:
		# Soltou o botão ainda subindo: o pulo fica mais baixo.
		if _pulou and not segurando and velocity.y > 0.0 and not _cortou_pulo:
			velocity.y *= 0.45
			_cortou_pulo = true
		if pode_flutuar:
			flutuando = true
			_flutuar_restante -= delta
			velocity.y = lerpf(velocity.y, 0.4, 1.0 - exp(-12.0 * delta))
		else:
			var g := gravidade * (gravidade_queda if velocity.y < 0.0 else 1.0)
			velocity.y = maxf(velocity.y - g * delta, -30.0)
	if pouso_suave:
		flutuando = true
		velocity.y = -2.5
	move_and_slide()
	# O chão de depois do movimento: logo depois de teleportar, o de antes ainda é o velho.
	if pouso_suave and is_on_floor():
		pouso_suave = false
		flutuando = false
	_pisao()

	var no_ar := not is_on_floor()
	if _estava_no_ar and not no_ar:
		_pousando = 0.18
	_estava_no_ar = no_ar
	if dir.length() > 0.1 and golpe_atual < 0 and girando <= 0.0:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-12.0 * delta))
	if global_position.y < limite_queda and not _no_curto:
		_caiu()
	if _invencivel > 0.0:
		_invencivel -= delta
		robo.visible = _invencivel <= 0.0 or fmod(_invencivel, 0.16) > 0.08

	_decolando -= delta
	_pousando -= delta
	robo.jatos(flutuando)
	_atualizar_lasers()
	_atualizar_animacao()


## Põe o Faísca parado em `pos` (testes e capturas). No quadro seguinte o is_on_floor ainda
## é o do lugar antigo: esperar uns 0,2 s antes de apertar o pulo, senão o coiote faz pular.
func teleportar(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	_memoria_pulo = 0.0
	golpe_atual = -1
	girando = 0.0


## Encostou numa Bolota (ou outra coisa que machuca) vinda de `de`: tira um coração, empurra
## para trás e deixa piscando um pouco.
func receber_dano(de: Vector3) -> bool:
	if _invencivel > 0.0 or _no_curto or not controle_ligado:
		return false
	_perder_coracao()
	var empurrao := global_position - de
	empurrao.y = 0.0
	empurrao = empurrao.normalized() if empurrao.length() > 0.05 else -_frente()
	velocity = empurrao * 7.0 + Vector3.UP * 6.0
	golpe_atual = -1
	_tremer(0.6, 0.8, 0.25)
	return true


## Ganha um coração (até 3). Devolve se pegou.
func curar() -> bool:
	if vida >= VIDA_MAX:
		return false
	vida += 1
	vida_mudou.emit(vida)
	return true


## Mola: joga para o alto. Soltar o botão não corta esse pulo, e dá para flutuar na descida.
func lancar(forca: float) -> void:
	velocity.y = forca
	_pulou = true
	_cortou_pulo = true
	_coiote = 0.0
	_memoria_pulo = 0.0
	_flutuar_restante = tempo_flutuar
	_giro_usado = false
	_decolando = 0.2
	_tremer(0.3, 0.3, 0.1)


func _perder_coracao() -> void:
	vida -= 1
	_invencivel = TEMPO_INVENCIVEL
	vida_mudou.emit(vida)
	if vida <= 0:
		_dar_curto()


## Caiu nas nuvens: volta no último posto e perde um coração (se for o último, o curto é lá).
func _caiu() -> void:
	voltar_ao_inicio()
	_perder_coracao()


## Sem corações: faisquinhas, fumacinha e volta no posto com os 3 corações.
func _dar_curto() -> void:
	_no_curto = true
	controle_ligado = false
	velocity = Vector3.ZERO
	golpe_atual = -1
	girando = 0.0
	_fumacinha()
	await get_tree().create_timer(1.3).timeout
	voltar_ao_inicio()
	vida = VIDA_MAX
	vida_mudou.emit(vida)
	_invencivel = TEMPO_INVENCIVEL
	_no_curto = false
	controle_ligado = true


func _fumacinha() -> void:
	var fumaca := StandardMaterial3D.new()
	fumaca.albedo_color = Color(0.85, 0.85, 0.9, 0.85)
	fumaca.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var faisca := StandardMaterial3D.new()
	faisca.albedo_color = Color("ffe066")
	faisca.emission_enabled = true
	faisca.emission = Color("ffd23f")
	faisca.emission_energy_multiplier = 3.0
	var centro := global_position + Vector3.UP * 1.8
	for i in 10:
		var e := MeshInstance3D.new()
		var bola := SphereMesh.new()
		var e_faisca := i % 2 == 0
		bola.radius = 0.06 if e_faisca else 0.28
		bola.height = bola.radius * 2.0
		e.mesh = bola
		e.material_override = faisca if e_faisca else fumaca
		e.top_level = true
		add_child(e)
		e.global_position = centro
		var a := TAU * i / 10.0
		var destino := centro + (Vector3(cos(a) * 1.2, 0.6 + randf() * 0.8, sin(a) * 1.2) if e_faisca else Vector3(cos(a) * 0.4, 1.4 + randf() * 0.6, sin(a) * 0.4))
		var tw := e.create_tween().set_parallel()
		tw.tween_property(e, "global_position", destino, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(e, "scale", Vector3.ONE * (0.01 if e_faisca else 2.2), 0.9)
		tw.chain().tween_callback(e.queue_free)


func voltar_ao_inicio() -> void:
	global_position = ponto_retorno
	velocity = Vector3.ZERO
	visual.rotation.y = PI
	yaw = 0.0
	pitch = -0.32
	golpe_atual = -1
	girando = 0.0


# --- golpes ----------------------------------------------------------------------

func _golpear(no_chao: bool, dir: Vector3) -> void:
	if not no_chao:
		if not _giro_usado and girando <= 0.0:
			girando = TEMPO_GIRO
			_giro_usado = true
			_giro_acertou = false
			velocity.y = maxf(velocity.y, 3.0)
		return
	if golpe_atual >= 0 and _golpe_tempo < GOLPES[golpe_atual].duracao * 0.6:
		_golpe_guardado = true
		return
	var proximo := 0
	if golpe_atual >= 0 or _combo_janela > 0.0:
		proximo = (maxi(golpe_atual, _ultimo_golpe) + 1) % GOLPES.size()
	_iniciar_golpe(proximo, dir)


func _iniciar_golpe(i: int, dir: Vector3) -> void:
	golpe_atual = i
	_ultimo_golpe = i
	_golpe_tempo = 0.0
	_golpe_acertou = false
	_golpe_guardado = false
	var alvo := _alvo_proximo()
	if alvo:
		var d := alvo.global_position - global_position
		visual.rotation.y = atan2(d.x, d.z)
	elif dir.length() > 0.1:
		visual.rotation.y = atan2(dir.x, dir.z)
	var g: Dictionary = GOLPES[i]
	robo.animar_desde(g.anim, g.inicio, 0.05, g.ritmo)


func _atualizar_golpes(delta: float, dir: Vector3) -> void:
	_combo_janela -= delta
	if golpe_atual >= 0:
		var g: Dictionary = GOLPES[golpe_atual]
		_golpe_tempo += delta
		if not _golpe_acertou and _golpe_tempo >= g.acerto:
			_golpe_acertou = true
			_acertar(ALCANCE_GOLPE, deg_to_rad(75.0), ALTURA_GOLPE, g.dano, g.empurrao)
		if _golpe_tempo >= g.duracao:
			if _golpe_guardado and golpe_atual < GOLPES.size() - 1:
				_iniciar_golpe(golpe_atual + 1, dir)
			else:
				golpe_atual = -1
				_golpe_guardado = false
				_combo_janela = 0.3
	if girando > 0.0:
		girando -= delta
		visual.rotation.y += TAU / TEMPO_GIRO * delta
		if not _giro_acertou and girando < TEMPO_GIRO - 0.1:
			_giro_acertou = true
			_acertar(ALCANCE_GIRO, PI, 2.4, 1, 6.0)


## Acerta os inimigos dentro do alcance, na frente (até `angulo` para cada lado).
func _acertar(alcance: float, angulo: float, altura: float, dano: int, empurrao: float) -> bool:
	var f := _frente()
	var meio := global_position + Vector3.UP * 1.1
	var acertou := false
	for alvo in get_tree().get_nodes_in_group(Alvo.GRUPO):
		if alvo.derrotado:
			continue
		var d: Vector3 = alvo.global_position + Vector3.UP * 0.6 - meio
		if absf(d.y) > altura:
			continue
		d.y = 0.0
		if d.length() > alcance + float(alvo.raio_golpe):
			continue
		if angulo < PI and d.length() > 0.3 and f.angle_to(d.normalized()) > angulo:
			continue
		if alvo.receber_golpe(dano, global_position, empurrao):
			acertou = true
	if acertou:
		_tremer(0.3, 0.6, 0.12)
	return acertou


## Inimigo (ou baú) mais perto, mais ou menos na frente: o golpe vira para ele.
func _alvo_proximo() -> Node3D:
	var f := _frente()
	var melhor: Node3D = null
	var menor := AJUDA_MIRA + 0.6
	for alvo in get_tree().get_nodes_in_group(Alvo.GRUPO):
		if alvo.derrotado:
			continue
		var d: Vector3 = alvo.global_position - global_position
		if absf(d.y) > ALTURA_GOLPE:
			continue
		d.y = 0.0
		if d.length() < menor and (d.length() < 0.3 or f.angle_to(d.normalized()) < deg_to_rad(80.0)):
			menor = d.length()
			melhor = alvo
	return melhor


## Caiu em cima de um inimigo: tira 2 de vida e quica de volta para o alto.
func _pisao() -> void:
	for k in get_slide_collision_count():
		var col := get_slide_collision(k)
		var alvo := col.get_collider() as Alvo
		if alvo and col.get_normal().y > 0.6:
			if alvo.receber_golpe(2, global_position + Vector3.UP * 2.0, 3.0):
				velocity.y = forca_pulo * 0.8
				_pulou = true
				_cortou_pulo = true
				_flutuar_restante = tempo_flutuar
				_giro_usado = false
				_decolando = 0.2
				_tremer(0.4, 0.5, 0.15)
			return


func _frente() -> Vector3:
	var f := visual.global_basis.z
	f.y = 0.0
	return f.normalized()


# --- laser dos pés ------------------------------------------------------------------

## Enquanto flutua, um laser sai de cada tênis direto para baixo até bater no chão ou num
## inimigo; quem estiver embaixo leva dano (a imunidade curta do inimigo dá o ritmo).
func _atualizar_lasers() -> void:
	var espaco := get_world_3d().direct_space_state
	for i in 2:
		_feixes[i].visible = flutuando
		_impactos[i].visible = flutuando
		if not flutuando:
			continue
		var de := robo.ponta_do_pe(i)
		var ate := de + Vector3.DOWN * ALCANCE_LASER
		var consulta := PhysicsRayQueryParameters3D.create(de, ate, 1 | Alvo.CAMADA | Fase.CAMADA_LUZ, [get_rid()])
		var batida := espaco.intersect_ray(consulta)
		if not batida.is_empty():
			ate = batida.position
			if batida.collider is Alvo and batida.collider.receber_golpe(1, de, 2.5):
				_tremer(0.2, 0.3, 0.08)
			elif batida.collider.has_method("acender"):
				batida.collider.acender()
		var largura := 1.0 + randf() * 0.3
		_feixes[i].global_transform = Transform3D(Basis.from_scale(Vector3(largura, maxf(de.y - ate.y, 0.01), largura)), (de + ate) / 2.0)
		_impactos[i].global_position = ate + Vector3.UP * 0.03
		_impactos[i].scale = Vector3.ONE * (0.8 + randf() * 0.4)


## Fim do laser `i` (para os testes).
func ponta_do_laser(i: int) -> Vector3:
	return _impactos[i].global_position


func _tremer(fraco: float, forte: float, duracao: float) -> void:
	if not vibracao:
		return
	for d in Input.get_connected_joypads():
		Input.start_joy_vibration(d, fraco, forte, duracao)


func _olhar_com_analogico(delta: float) -> void:
	if not controle_ligado:
		return
	var olhar := Input.get_vector("olhar_esquerda", "olhar_direita", "olhar_cima", "olhar_baixo")
	olhar *= olhar.length()
	yaw -= olhar.x * velocidade_analogico.x * delta
	pitch = clampf(pitch - olhar.y * velocidade_analogico.y * delta, PITCH_MIN, PITCH_MAX)


func _atualizar_animacao() -> void:
	# Sem controle (comemorando, por exemplo) quem escolhe a animação é quem tirou o controle.
	# Durante o golpe, a animação é a do golpe.
	if not controle_ligado or golpe_atual >= 0:
		return
	var vel_h := Vector2(velocity.x, velocity.z).length()
	if _decolando > 0.0:
		robo.animar("mov/Jump_Start", 0.05)
	elif not is_on_floor():
		robo.animar("mov/Jump_Idle", 0.15)
	elif _pousando > 0.0 and vel_h < 2.0:
		robo.animar("mov/Jump_Land", 0.05)
	elif vel_h > 3.5:
		robo.animar("mov/Running_A", 0.15, vel_h / velocidade * 1.1)
	elif vel_h > 0.3:
		robo.animar("mov/Walking_A", 0.15, maxf(vel_h / 2.5, 0.6))
	else:
		robo.animar("geral/Idle_A", 0.2)
