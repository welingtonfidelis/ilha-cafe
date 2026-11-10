class_name FarolIlha
extends Node3D
## O farol na ponta sudeste da ilha, a casa do Faísca (seção 11 do doc). Fica numa ilhota de pedra no mar,
## ligada à praia por uma passarela de madeira (os módulos do cais do Animated Cute Fish Pack), com a porta
## virada para a passarela. Montado em tempo de jogo, sem mexer na ilha gerada (scenes/ilha.tscn).
## Desde que o menu principal separou os dois jogos (2026-11-10), a abertura do jogo do Faísca (FaiscaJogo) monta o
## mesmo farol no mar à noite e acende a lâmpada (`aberto`).
## Na ilha ele é um mirante (item 2 da lista de melhorias, escolhido pelo usuário em 2026-11-10): aceso, com um
## binóculo de brinquedo na sacada, virado para a ilha. Na porta, B (ou E) sobe: a tela escurece e a vista passa a
## ser a do binóculo, lá do alto, com a máscara de dois círculos, os nomes dos lugares (praça, lanternas, cemitério,
## pista de kart) e a seta do objetivo. Os analógicos giram a vista, mirar (LT ou o botão direito) aproxima, e B de
## novo desce. A sacada de verdade é estreita (uns 60 cm entre a salinha da lâmpada e a beirada, a 13,6 m), por isso
## o aventureiro não anda lá em cima: fica na porta, sem controle, enquanto olha.

## Da praia para o mar, na diagonal sudeste. A beira da água fica perto de (150, 150); o fundo desce até
## uns -4 m em (167, 167).
const DIRECAO := Vector3(0.70710678, 0, 0.70710678)
const CENTRO := Vector3(161.5, 0, 161.5)
const RAIO := 7.0
## Topo da ilhota na altura do piso da passarela, para entrar sem degrau.
const TOPO := 0.45
const ESCALA := 4.5
const DOCKS := "res://assets/props/cais_peixes/%s.fbx"
const DOCK_SCALE := 0.75
const DOCK_DECK := 3.8
const PISO := 0.45
## Chão da sacada (medido com raios na colisão do modelo) e onde fica o binóculo, do centro para o lado da ilha. O
## vidro da lâmpada tem 1,9 m de raio: a câmera fica do lado de fora dele, na frente dos canos do binóculo.
const ALTURA_SACADA := 13.6
const RAIO_BINOCULO := 2.3
## Tamanho dos nomes na tela: fração da altura da tela com o binóculo sem aproximar.
const ALTURA_NOME := 0.05
## Campo de visão do binóculo e o de mirando (aproximado).
const FOV := 24.0
const FOV_PERTO := 10.0
const PITCH_MIN := -0.8
const PITCH_MAX := 0.3

## Na ilha, o main (para o aviso de fechado); na abertura do Faísca, nulo.
var game: Node
## Aceso, sem cadeado e com a porta brilhando.
var aberto := false
var modelo: FarolModelo
var _cadeado: Node3D
var _brilho_porta: OmniLight3D
var _aviso_espera := 0.0
## Olhando pelo binóculo.
var no_mirante := false
var binoculo: Node3D
var camera_mirante: Camera3D
var mascara: CanvasLayer
var nomes: Node3D
var _yaw := 0.0
var _pitch := 0.0
var _fov := FOV
var _trocando := false


func _ready() -> void:
	position = CENTRO
	# A porta (+Z do modelo) olha para a praia.
	var para_praia := -DIRECAO
	_ilhota()
	modelo = FarolModelo.new()
	modelo.escala = ESCALA
	modelo.solido = true
	modelo.position.y = TOPO
	modelo.rotation.y = atan2(para_praia.x, para_praia.z)
	add_child(modelo)
	_passarela()
	_porta()
	_montar_binoculo()
	atualizar()


func _process(delta: float) -> void:
	_aviso_espera -= delta
	if _cadeado and _cadeado.visible:
		_cadeado.rotation.z = lerpf(_cadeado.rotation.z, 0.0, 1.0 - exp(-6.0 * delta))
	if not no_mirante:
		return
	if game.menu_state == "":
		# Os dois analógicos giram a vista (a criança tenta "andar" com o esquerdo); de perto, mais devagar.
		var olhar := Input.get_vector("olhar_esquerda", "olhar_direita", "olhar_cima", "olhar_baixo")
		olhar *= olhar.length()
		var andar := Input.get_vector("esquerda", "direita", "frente", "tras")
		var rapidez := 1.5 * Ajustes.rapidez_camera() * _fov / FOV
		_yaw -= (olhar.x + andar.x * 0.6) * rapidez * delta
		_pitch = clampf(_pitch - olhar.y * rapidez * 0.8 * Ajustes.sinal_vertical() * delta, PITCH_MIN, PITCH_MAX)
		var perto := Input.is_action_pressed("mirar")
		_fov = lerpf(_fov, FOV_PERTO if perto else FOV, 1.0 - exp(-6.0 * delta))
	camera_mirante.fov = _fov
	camera_mirante.rotation = Vector3(_pitch, _yaw, 0.0)
	_tamanho_dos_nomes()


## Os nomes têm tamanho fixo na tela, mas o fixo da Godot não conta o zoom: com o campo de visão estreito do binóculo
## eles ficavam enormes. Aqui o tamanho acompanha o campo de visão (aproximando, crescem só um pouco).
func _tamanho_dos_nomes() -> void:
	var meia := tan(deg_to_rad(_fov) * 0.5)
	var pixel := ALTURA_NOME * 2.0 * meia * pow(tan(deg_to_rad(FOV) * 0.5) / meia, 0.35) / 52.0
	for nome: Label3D in nomes.get_children():
		nome.pixel_size = pixel


func _unhandled_input(event: InputEvent) -> void:
	if game == null or game.menu_state != "" or _trocando:
		return
	if no_mirante:
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			var s: float = 0.0025 * Ajustes.rapidez_camera() * _fov / FOV
			_yaw -= event.relative.x * s
			_pitch = clampf(_pitch - event.relative.y * s * Ajustes.sinal_vertical(), PITCH_MIN, PITCH_MAX)
		elif event.is_action_pressed("interagir"):
			descer()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interagir") and pode_subir():
		subir()
		get_viewport().set_input_as_handled()


## A criança está a pé, na porta, e pode subir.
func pode_subir() -> bool:
	if game == null or _trocando or no_mirante:
		return false
	var p: Player = game.player
	return not p.dizzy and not p.in_vehicle and p.global_position.distance_to(porta()) < 3.2 and absf(p.global_position.y - porta().y) < 2.0


## O aviso de baixo da tela (o main mostra): subir na porta, descer lá de cima.
func dica(botao: String) -> String:
	if no_mirante:
		return "Aperte %s para descer do farol" % botao
	if pode_subir():
		return "Aperte %s para subir no farol e olhar no binóculo" % botao
	return ""


func subir() -> void:
	if game.in_combat():
		game.show_message("Agora não! Tem esqueleto por perto.", Color("#ff9d9d"), 1.6)
		return
	_trocando = true
	var p: Player = game.player
	p.input_enabled = false
	Sfx.play(game, "ui_ok", 0.0, 0.0)
	await _escurecer(1.0, 0.3)
	_montar_mirante()
	var para_ilha := -DIRECAO
	_yaw = atan2(-para_ilha.x, -para_ilha.z)
	_pitch = -0.12
	_fov = FOV
	camera_mirante.global_position = binoculo.global_position + Vector3.UP * 1.15 + para_ilha * 0.5
	camera_mirante.rotation = Vector3(_pitch, _yaw, 0.0)
	camera_mirante.fov = _fov
	camera_mirante.make_current()
	mascara.show()
	nomes.show()
	_tamanho_dos_nomes()
	game.set_hud_visible(false)
	no_mirante = true
	await _escurecer(0.0, 0.35)
	_trocando = false
	game.show_message("Mexa os analógicos para olhar a ilha. Mire para chegar mais perto!", Color("#8ff3ff"), 3.0)


func descer() -> void:
	_trocando = true
	Sfx.play(game, "ui_ok", 0.0, 0.0)
	await _escurecer(1.0, 0.3)
	no_mirante = false
	mascara.hide()
	nomes.hide()
	var p: Player = game.player
	var para_praia := -DIRECAO
	p.set_yaw(atan2(-para_praia.x, -para_praia.z))
	p.camera.make_current()
	game.set_hud_visible(true)
	p.input_enabled = true
	await _escurecer(0.0, 0.35)
	_trocando = false


func _escurecer(alfa: float, segundos: float) -> void:
	var fade: ColorRect = game.fade
	var tw := fade.create_tween()
	tw.tween_property(fade, "modulate:a", alfa, segundos)
	await tw.finished


## Binóculo de praça, de brinquedo: pé amarelo, corpo azul-piscina e os dois canos brancos para a ilha.
func _montar_binoculo() -> void:
	binoculo = Node3D.new()
	binoculo.name = "Binoculo"
	add_child(binoculo)
	var para_ilha := -DIRECAO
	binoculo.global_position = global_position + para_ilha * RAIO_BINOCULO + Vector3.UP * ALTURA_SACADA
	binoculo.rotation.y = atan2(para_ilha.x, para_ilha.z)
	var amarelo := _material(Color("ffc93c"))
	var azul := _material(Color("2fb5d6"))
	var branco := _material(Color("f4f4f6"))
	for spec in [[0.26, 0.26, 0.08, 0.04, azul], [0.07, 0.07, 1.0, 0.5, amarelo]]:
		var cil := CylinderMesh.new()
		cil.top_radius = spec[0]
		cil.bottom_radius = spec[1]
		cil.height = spec[2]
		var mi := MeshInstance3D.new()
		mi.mesh = cil
		mi.material_override = spec[4]
		mi.position.y = spec[3]
		binoculo.add_child(mi)
	var corpo := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(0.55, 0.32, 0.36)
	corpo.mesh = caixa
	corpo.material_override = azul
	corpo.position.y = 1.12
	binoculo.add_child(corpo)
	for lado in [-1.0, 1.0]:
		var cano := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.11
		c.bottom_radius = 0.12
		c.height = 0.34
		cano.mesh = c
		cano.material_override = branco
		cano.rotation.x = PI / 2.0
		cano.position = Vector3(0.14 * lado, 1.14, 0.3)
		binoculo.add_child(cano)


## A câmera do binóculo, a máscara de dois círculos e os nomes dos lugares (montados na primeira subida).
func _montar_mirante() -> void:
	if camera_mirante:
		return
	camera_mirante = Camera3D.new()
	camera_mirante.near = 0.1
	camera_mirante.far = 2000.0
	add_child(camera_mirante)
	# Abaixo da interface do main (camada 1): os menus e os avisos aparecem por cima da máscara.
	mascara = CanvasLayer.new()
	mascara.layer = 0
	add_child(mascara)
	var tela := ColorRect.new()
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tela.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sombra := ShaderMaterial.new()
	sombra.shader = Shader.new()
	sombra.shader.code = MASCARA
	tela.material = sombra
	mascara.add_child(tela)
	mascara.hide()
	nomes = Node3D.new()
	nomes.top_level = true
	add_child(nomes)
	var lugares: Array = [["Praça da Festa", Ending.PLAZA]]
	var story: Story = game.story
	if story:
		for d: Defense in story.defenses.values():
			lugares.append([d.nome, d.center])
	if game.kart_race:
		lugares.append(["Pista de kart", game.kart_race.paddock])
	for l in lugares:
		var nome := Label3D.new()
		nome.text = l[0]
		nome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		nome.fixed_size = true
		nome.no_depth_test = true
		nome.pixel_size = 0.0022
		nome.font_size = 52
		nome.outline_size = 16
		nome.modulate = Color("ffe680")
		nome.outline_modulate = Color(0.12, 0.08, 0.25, 0.9)
		nomes.add_child(nome)
		nome.global_position = (l[1] as Vector3) + Vector3.UP * 9.0
	nomes.hide()


## Máscara do binóculo: preto fora de dois círculos lado a lado, com a borda macia.
const MASCARA := """
shader_type canvas_item;
void fragment() {
	vec2 tela = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 p = FRAGCOORD.xy;
	float r = tela.y * 0.43;
	vec2 meio = tela * 0.5;
	vec2 c1 = vec2(meio.x - r * 0.72, meio.y);
	vec2 c2 = vec2(meio.x + r * 0.72, meio.y);
	float d = min(distance(p, c1), distance(p, c2)) - r;
	COLOR = vec4(0.02, 0.02, 0.05, smoothstep(-14.0, 2.0, d));
}
"""


## Fechado, de cadeado; aberto, a lâmpada acende e a porta brilha ciano.
func atualizar() -> void:
	_cadeado.visible = not aberto
	_brilho_porta.visible = aberto
	modelo.acender(aberto)


## Onde o Faísca aparece ao sair (na frente da porta, virado para a praia) e para onde a seta aponta. Fica
## fora da área que faz entrar (senão ele entraria de novo na hora).
func porta() -> Vector3:
	return modelo.porta() - DIRECAO * 3.0


func _ilhota() -> void:
	var pedra := StaticBody3D.new()
	add_child(pedra)
	var mi := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.radial_segments = 11
	cil.rings = 1
	cil.top_radius = RAIO
	cil.bottom_radius = RAIO + 1.6
	cil.height = TOPO + 4.5
	mi.mesh = cil
	mi.material_override = _material(Color("8c8f9c"))
	mi.position.y = TOPO - cil.height * 0.5
	pedra.add_child(mi)
	var grama := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.radial_segments = 11
	disco.rings = 1
	disco.top_radius = RAIO - 0.4
	disco.bottom_radius = RAIO - 0.2
	disco.height = 0.16
	grama.mesh = disco
	grama.material_override = _material(Color("86c95f"))
	grama.position.y = TOPO + 0.02
	pedra.add_child(grama)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = RAIO
	forma.height = TOPO + 4.5
	cs.shape = forma
	cs.position.y = TOPO - forma.height * 0.5
	pedra.add_child(cs)
	# Pedrinhas soltas na beira, de enfeite.
	for k in 7:
		var a := TAU * k / 7.0 + 0.4
		if absf(angle_difference(a, atan2(-DIRECAO.z, -DIRECAO.x))) < 0.5:
			continue
		var p := MeshInstance3D.new()
		var bola := SphereMesh.new()
		bola.radius = 1.0
		bola.height = 1.4
		bola.radial_segments = 7
		bola.rings = 4
		p.mesh = bola
		p.material_override = mi.material_override
		p.position = Vector3(cos(a) * (RAIO + 0.6), -0.2, sin(a) * (RAIO + 0.6))
		p.scale = Vector3.ONE * (0.8 + 0.25 * (k % 3))
		add_child(p)


## Módulos do cais da praia até a ilhota, com piso a PISO, paredes invisíveis no lugar da corda e uma rampa
## na areia, como o cais do sul.
func _passarela() -> void:
	var giro := atan2(-DIRECAO.x, -DIRECAO.z)
	var raiz := Node3D.new()
	raiz.name = "Passarela"
	add_child(raiz)
	# A passarela sai da beira da ilhota em direção à praia (eixo +Z da raiz).
	raiz.position = -DIRECAO * (RAIO - 0.6)
	raiz.rotation.y = giro
	var corpo := StaticBody3D.new()
	raiz.add_child(corpo)
	var z := 0.0
	var origem_y := PISO - DOCK_DECK * DOCK_SCALE
	# Um módulo comprido (uns 17 m) chega da ilhota até a areia.
	for i in 1:
		var dock: Node3D = load(DOCKS % "Dock_Long").instantiate()
		var aabb := _aabb(dock)
		var comprimento := aabb.size.z * DOCK_SCALE
		var meia := aabb.size.x * DOCK_SCALE * 0.5 * 0.86
		dock.scale = Vector3.ONE * DOCK_SCALE
		dock.position = Vector3(-aabb.get_center().x * DOCK_SCALE, origem_y, z - aabb.position.z * DOCK_SCALE)
		raiz.add_child(dock)
		var meio := z + comprimento * 0.5
		_caixa(corpo, Vector3(meia * 2.0, 0.3, comprimento), Vector3(0, PISO - 0.15, meio))
		for lado in [-1.0, 1.0]:
			_caixa(corpo, Vector3(0.3, 1.2, comprimento), Vector3(lado * meia, PISO + 0.6, meio))
		z += comprimento - 0.15
	# Emenda entre o piso e a grama da ilhota, e a rampa até a areia.
	_caixa(corpo, Vector3(3.0, 0.4, 1.6), Vector3(0, PISO - 0.2, -0.6))
	var rampa := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(3.0, 0.3, 5.0)
	rampa.shape = caixa
	rampa.position = Vector3(0, PISO - 0.55, z + 2.2)
	rampa.rotation.x = atan2(PISO + 0.25, 5.0)
	corpo.add_child(rampa)


func _porta() -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1 << 1
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(3.2, 3.0, 1.6)
	cs.shape = caixa
	area.add_child(cs)
	add_child(area)
	area.global_position = modelo.porta() + Vector3.UP * 1.5 - DIRECAO * 0.4
	area.global_rotation.y = modelo.rotation.y
	area.body_entered.connect(_tocou)
	# Cadeado dourado na frente da porta (a porta do pacote é parte da torre e não abre).
	_cadeado = Node3D.new()
	add_child(_cadeado)
	_cadeado.global_position = modelo.porta() + Vector3.UP * 1.25 - DIRECAO * 0.15
	_cadeado.rotation.y = modelo.rotation.y
	var ouro := _material(Color("ffc93c"))
	ouro.metallic = 0.6
	ouro.roughness = 0.3
	var corpo := MeshInstance3D.new()
	var bloco := BoxMesh.new()
	bloco.size = Vector3(0.7, 0.6, 0.25)
	corpo.mesh = bloco
	corpo.material_override = ouro
	_cadeado.add_child(corpo)
	var alca := MeshInstance3D.new()
	var anel := TorusMesh.new()
	anel.inner_radius = 0.18
	anel.outer_radius = 0.27
	alca.mesh = anel
	alca.material_override = ouro
	alca.rotation.x = PI / 2.0
	alca.position.y = 0.35
	_cadeado.add_child(alca)
	_brilho_porta = OmniLight3D.new()
	_brilho_porta.light_color = FarolModelo.LUZ
	_brilho_porta.light_energy = 2.0
	_brilho_porta.omni_range = 4.0
	add_child(_brilho_porta)
	_brilho_porta.global_position = modelo.porta() + Vector3.UP * 1.4 - DIRECAO * 0.8


## Fechado (sem o mirante), quem encosta na porta lê que está fechado.
func _tocou(corpo: Node3D) -> void:
	if not corpo is Player or _aviso_espera > 0.0 or game == null or aberto:
		return
	_aviso_espera = 2.5
	_cadeado.rotation.z = 0.35
	game.show_message("O farol está fechado", Color(1, 1, 1, 0.9), 1.8)


func _caixa(corpo: StaticBody3D, tamanho: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = tamanho
	cs.shape = caixa
	cs.position = pos
	corpo.add_child(cs)


func _aabb(no: Node3D) -> AABB:
	var caixa := AABB()
	var primeiro := true
	for mi in no.find_children("*", "MeshInstance3D", true, false):
		var t := Transform3D.IDENTITY
		var n: Node = mi
		while n != no:
			t = (n as Node3D).transform * t
			n = n.get_parent()
		var a: AABB = t * (mi as MeshInstance3D).get_aabb()
		caixa = a if primeiro else caixa.merge(a)
		primeiro = false
	return caixa


func _material(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.85
	return m
