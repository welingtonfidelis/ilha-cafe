class_name CarrinhoDaFuga
extends CarrinhoDeMina
## A fuga no carrinho de mina, o momento especial da 1-2 (item 9 da lista do Faísca, 2026-11-11): o mesmo carrinho de
## sempre, mas num trilho comprido e cheio de curvas, de sobe e desce, pendurado no escuro da caverna. Só sai com a
## estação ligada (as duas lanternas acesas pelo laser). O Faísca vai sentado (o carrinho leva ele, como o canhão: o
## processo de física dele fica desligado), e o pulo (A) é só para cima, dentro do carrinho, sem cair para fora: no
## primeiro teste, solto no carrinho, ele saía voando nas curvas. Andando, o túnel desmorona atrás (pedras caindo,
## poeira, o ronco e o controle tremendo), e a câmera vai por trás, virando junto nas curvas. As estrelinhas ficam no
## trilho (pegam sozinhas) e, mais alto, em arcos que só se pegam pulando. Na chegada, ele desce na frente do carrinho.

## Os pontos do trilho, do começo (a estação) ao fim.
var caminho := PackedVector3Array()
## A estação ligada: sem isso, o carrinho não sai.
var ligado := false
## Pedras que já caíram atrás dele (para os testes).
var pedras := 0
var _curva: Curve3D
var _faisca: Jogador
## O pulo dentro do carrinho: a altura e a velocidade dele, e o botão de antes (para pegar só a hora de apertar).
var _salto := 0.0
var _salto_vel := 0.0
var _pulo_antes := false
const PULO := 8.5
const GRAVIDADE_PULO := 24.0
var _pedra := 0.0
var _tremor := 0.0
var _som: AudioStreamPlayer3D
var _malha_pedra: Mesh
var _lampioes: Array[OmniLight3D] = []


func _ready() -> void:
	de = caminho[0]
	ate = caminho[caminho.size() - 1]
	# Curvas macias: cada ponto ganha alças na direção do vizinho de antes para o de depois (sem elas, o trilho seria
	# feito de retas com quinas).
	_curva = Curve3D.new()
	_curva.bake_interval = 0.5
	for i in caminho.size():
		var antes := caminho[maxi(i - 1, 0)]
		var depois := caminho[mini(i + 1, caminho.size() - 1)]
		var alca := (depois - antes) * 0.22
		_curva.add_point(caminho[i], -alca, alca)
	super()
	_pousar_em(0.0)
	_malha_pedra = Miudezas3D.pedrinha()
	# Duas lanternas no carrinho, que acendem com a estação ligada.
	for lado in [-1.0, 1.0]:
		var l := OmniLight3D.new()
		l.light_color = Color("ffc070")
		l.light_energy = 0.0
		l.omni_range = 7.0
		l.position = Vector3(lado * 0.9, BORDA + 0.4, COMPRIMENTO * 0.5)
		add_child(l)
		_lampioes.append(l)


## A estação liga: as lanternas acendem e o carrinho fica pronto para sair.
func ligar() -> void:
	if ligado:
		return
	ligado = true
	for l in _lampioes:
		create_tween().tween_property(l, "light_energy", 1.6, 0.6)
	Sfx.play_at(get_parent(), "remontar", global_position, -2.0)


func comprimento() -> float:
	return _curva.get_baked_length()


## Onde fica o ponto do trilho a `andado` metros do começo.
func ponto(andado: float) -> Vector3:
	return _curva.sample_baked(clampf(andado, 0.0, comprimento()))


func _pousar_em(andado: float) -> void:
	var p := ponto(andado)
	var frente := ponto(andado + 0.8) - ponto(andado - 0.8)
	if frente.length() < 0.01:
		frente = Vector3.FORWARD
	global_transform = Transform3D(Basis.looking_at(-frente.normalized(), Vector3.UP), p)


func _physics_process(delta: float) -> void:
	var total := comprimento()
	match estado:
		"parado":
			_dentro = _dentro + delta if ligado and com_faisca() else 0.0
			if _dentro > 0.4:
				estado = "indo"
				_andado = 0.0
				_faisca = _quem_esta_dentro()
				if _faisca:
					_faisca.set_physics_process(false)
					_faisca.controle_ligado = false
					_faisca.velocity = Vector3.ZERO
					_salto = 0.0
					_salto_vel = 0.0
				saiu.emit()
				Sfx.play_at(get_parent(), "remontar", global_position, -4.0)
				_som = Sfx.play_at(get_parent(), "rolar", global_position, -6.0, 0.0)
				if _som:
					_som.finished.disconnect(_som.queue_free)
					_som.finished.connect(_som.play)
		"indo":
			var falta := total - _andado
			var v := minf(VELOCIDADE, minf(VELOCIDADE * (_andado / (VELOCIDADE * ACELERA * 0.5) + 0.15), sqrt(maxf(falta, 0.0) * 6.0) + 0.3))
			_andado = minf(_andado + v * delta, total)
			_pousar_em(_andado)
			_levar_faisca(delta)
			_desmoronar(delta)
			if _andado >= total:
				estado = "chegou"
				_vazio = 0.0
				_descer_faisca()
				_parar_som()
				chegou.emit()
				Sfx.play_at(get_parent(), "bonk", global_position, -2.0)
		"chegou":
			_vazio = 0.0 if com_faisca() else _vazio + delta
			if _vazio > 2.0:
				estado = "voltando"
		"voltando":
			_andado = maxf(_andado - VELOCIDADE * 1.6 * delta, 0.0)
			_pousar_em(_andado)
			if _andado <= 0.0:
				estado = "parado"
				_dentro = 0.0
	if _som and is_instance_valid(_som):
		_som.global_position = global_position


func _quem_esta_dentro() -> Jogador:
	for corpo in _area.get_overlapping_bodies():
		if corpo is Jogador:
			return corpo
	return null


## Leva o Faísca sentado no fundo do carrinho, virado para a frente, com o pulo só para cima; a câmera vai por trás,
## virando com o carrinho nas curvas.
func _levar_faisca(delta: float) -> void:
	if not is_instance_valid(_faisca):
		return
	var pulo := Input.is_action_pressed("pular") or _faisca.forcar_pulo
	if pulo and not _pulo_antes and _salto <= 0.0:
		_salto_vel = PULO
		_faisca.robo.animar("mov/Jump_Idle", 0.1)
		Sfx.play(_faisca, "faisca_pulo", -4.0)
	_pulo_antes = pulo
	if _salto > 0.0 or _salto_vel > 0.0:
		_salto += _salto_vel * delta
		_salto_vel -= GRAVIDADE_PULO * delta
		if _salto <= 0.0:
			_salto = 0.0
			_salto_vel = 0.0
			_faisca.robo.animar("geral/Idle_A", 0.15)
	var frente := ponto(_andado + 3.0) - ponto(_andado)
	frente.y = 0.0
	frente = frente.normalized() if frente.length() > 0.01 else Vector3.FORWARD
	_faisca.global_position = global_transform * Vector3(0, FUNDO + 0.05, 0) + Vector3.UP * _salto
	_faisca.visual.rotation.y = atan2(frente.x, frente.z)
	_faisca.camera_guiada = {"yaw": atan2(-frente.x, -frente.z), "pitch": -0.32, "distancia": 8.5, "carrinho": true}
	_faisca.acompanhar_camera(delta)


## Chegou: o Faísca desce na frente do carrinho, na estação, com o controle de volta e a câmera solta.
func _descer_faisca() -> void:
	if not is_instance_valid(_faisca):
		return
	var frente := ponto(comprimento()) - ponto(comprimento() - 1.0)
	frente.y = 0.0
	frente = frente.normalized() if frente.length() > 0.01 else Vector3.FORWARD
	_soltar_camera()
	_faisca.global_position = ponto(comprimento()) + frente * 2.6 + Vector3.UP * 0.1
	_faisca.velocity = Vector3.ZERO
	_faisca.set_physics_process(true)
	_faisca.controle_ligado = true
	_faisca.robo.animar("geral/Idle_A", 0.15)
	_faisca = null


func _soltar_camera() -> void:
	if is_instance_valid(_faisca) and _faisca.camera_guiada.get("carrinho", false):
		_faisca.camera_guiada = {}


## O túnel desmoronando atrás: pedras caindo do alto no trilho, uns metros atrás, com poeira e o controle tremendo.
func _desmoronar(delta: float) -> void:
	_tremor -= delta
	if is_instance_valid(_faisca) and _tremor <= 0.0:
		_tremor = 0.3
		_faisca.tremidinha(0.2)
	_pedra -= delta
	if _pedra > 0.0 or _andado < 6.0:
		return
	_pedra = 0.22
	pedras += 1
	var onde := ponto(_andado - 6.5) + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
	var mi := MeshInstance3D.new()
	mi.mesh = _malha_pedra
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("5a5468")
	m.roughness = 1.0
	mi.material_override = m
	mi.scale = Vector3.ONE * randf_range(3.5, 6.0)
	mi.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
	get_parent().add_child(Fase.so_enfeite(mi))
	mi.global_position = onde + Vector3.UP * 8.0
	var tw := mi.create_tween()
	tw.tween_property(mi, "global_position", onde, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: Fx.dust(get_parent(), onde))
	tw.tween_interval(1.2)
	tw.tween_property(mi, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(mi.queue_free)


func _parar_som() -> void:
	if _som and is_instance_valid(_som):
		_som.stop()
		_som.queue_free()
	_som = null
