class_name Pescaria
extends Node3D
## Pescaria na ponta do cais (item 5 da lista de melhorias, 2026-11-10). Ao lado do pescador, um círculo dourado no
## chão, o balde e a caixa de pesca. No círculo, B (ou E) pega a vara: a câmera vai para trás do aventureiro, olhando
## o mar, e a boia voa para a água. Um peixe vem nadando por baixo, belisca a boia duas vezes e puxa: aparece o A
## grande em cima da boia, e é só apertar A (ou atirar) a tempo. Depois, apertar A sem parar enche a barra até o
## peixe pular para fora d'água. O cartão mostra o peixe, o nome, as estrelas, se é novo e a tira da coleção; o peixe
## dá moedas e o novo vai nadar no aquário da praia (Aquario). Não tem como perder: o peixe que escapa volta para o
## sorteio e, na barra, ele não consegue fugir. B guarda a vara.
## Os 17 peixes são os do Animated Cute Fish Pack (Quaternius, CC0), os mesmos que nadam no mar. A coleção fica na
## campanha ("peixes": quantos de cada um).

## Pegou um peixe (novo: a primeira vez daquele).
signal pescou(id: String, novo: bool)

## Os peixes: modelo, nome, raridade (1 a 3 estrelas) e a cor da bolinha na tira da coleção.
const PEIXES := [
	{"id": "Clownfish", "nome": "Peixe-palhaço", "raro": 1, "cor": Color("#ff8a2a")},
	{"id": "Goldfish", "nome": "Peixinho-dourado", "raro": 1, "cor": Color("#ffb02e")},
	{"id": "BlueGoldfish", "nome": "Peixinho-azul", "raro": 1, "cor": Color("#4aa8ff")},
	{"id": "Tetra", "nome": "Tetra-neon", "raro": 1, "cor": Color("#3fd0e0")},
	{"id": "CardinalFish", "nome": "Peixe-cardeal", "raro": 1, "cor": Color("#e8524f")},
	{"id": "Betta", "nome": "Betta", "raro": 1, "cor": Color("#8a5cd6")},
	{"id": "YellowTang", "nome": "Cirurgião-amarelo", "raro": 1, "cor": Color("#ffd23f")},
	{"id": "BlueTang", "nome": "Cirurgião-azul", "raro": 1, "cor": Color("#2f6fe0")},
	{"id": "ButterflyFish", "nome": "Peixe-borboleta", "raro": 2, "cor": Color("#ffe066")},
	{"id": "RoyalGramma", "nome": "Grama-real", "raro": 2, "cor": Color("#b45fd6")},
	{"id": "ZebraClownFish", "nome": "Palhaço-zebra", "raro": 2, "cor": Color("#f07a3a")},
	{"id": "Cowfish", "nome": "Peixe-vaca", "raro": 2, "cor": Color("#f0c040")},
	{"id": "ParrotFish", "nome": "Peixe-papagaio", "raro": 2, "cor": Color("#3fbf9f")},
	{"id": "MoorishIdol", "nome": "Ídolo-mouro", "raro": 3, "cor": Color("#f2f2e6")},
	{"id": "Koi", "nome": "Carpa koi", "raro": 3, "cor": Color("#ff7043")},
	{"id": "MandarinFish", "nome": "Peixe-mandarim", "raro": 3, "cor": Color("#2fb3a0")},
	{"id": "Puffer", "nome": "Baiacu", "raro": 3, "cor": Color("#e0c070")},
]
## Peso de cada raridade no sorteio, e a chance de o sorteio ser só entre os que ainda faltam (a coleção anda).
const PESOS := {1: 6.0, 2: 3.0, 3: 1.5}
const CHANCE_NOVO := 0.6
## Onde a criança fica, na ponta do cais (o piso do cais está a 0,45 m), e para onde olha.
const PONTO := Vector3(0.0, 0.45, 253.2)
const FRENTE := Vector3(0, 0, 1)
const RAIO := 2.4
const AGUA := Fish.WATER_Y
const PROPS := "res://assets/props/pesca/%s.gltf"
## A linha do KayKit é um fio de 1,91 m que desce do nó na ponta da vara.
const LINHA := 1.91
## Tempo do A grande na boia (no Modo Fácil, mais).
const JANELA := 1.8
const JANELA_FACIL := 3.0
## Quantos apertos de A enchem a barra, por raridade (no Modo Fácil, dois a menos).
const PUXOES := {1: 6, 2: 8, 3: 10}
## Quanto a barra esvazia por segundo sem apertar; nunca abaixo do chão (o peixe não foge na barra).
const ESVAZIA := 0.12
const CHAO_BARRA := 0.08
const MOEDAS_NOVO := {1: 5, 2: 8, 3: 12}
const MOEDAS_REPETIDO := 2

enum Fase { FORA, LANCANDO, ESPERANDO, FISGAR, PUXANDO, PEGOU, ESCAPOU }

## O main.
var game: Node
## O aquário da praia (nulo na arena e nos testes que não montam a ilha).
var aquario: Aquario
var fase := Fase.FORA
## Quantos de cada peixe já pegou.
var pegos := {}
## Nos testes: o próximo peixe (vazio: sorteado).
var forcar := ""
var camera: Camera3D
var boia: Node3D
var balde: Node3D
var placar: Label3D
## O peixe da vez (o que vem nadando, puxa e pula) e o último pego, no balde.
var peixe: Fish
var peixe_id := ""
var no_balde: Fish
## A barra de puxar, de 0 a 1.
var forca := 0.0
## Peças da tela (os testes olham).
var botao_a: BotaoA
var barra: ProgressBar
var cartao: PanelContainer
var cartao_nome: Label
var cartao_novo: Label
var _cartao_moedas: Label
var _cartao_conta: Label
var _estrelas: Array[MenuIcon] = []
var _tira: Array[Bolinha] = []
var _retrato: RetratoPeixe
var _hud: Control
var _trocando := false
var _tempo := 0.0
var _espera := 0.0
var _beliscou := 0
var _belisco := -10.0
var _de := Vector3.ZERO
var _alvo := Vector3.ZERO
var _voo_de := Vector3.ZERO
var _pulo_de := Vector3.ZERO
var _guardando := false


func _ready() -> void:
	var circulo := MeshInstance3D.new()
	var anel := TorusMesh.new()
	anel.inner_radius = 0.55
	anel.outer_radius = 0.72
	anel.rings = 32
	anel.ring_segments = 6
	circulo.mesh = anel
	circulo.material_override = Fx.glow_material(Color("#ffd23f"), 1.4)
	circulo.position = PONTO + Vector3.UP * 0.02
	circulo.scale = Vector3(1.0, 0.12, 1.0)
	add_child(circulo)
	balde = load(PROPS % "bucket_metal").instantiate()
	balde.scale = Vector3.ONE * 0.6
	balde.position = PONTO + Vector3(1.15, 0.0, -0.45)
	add_child(balde)
	var caixa: Node3D = load(PROPS % "fishing_tacklebox").instantiate()
	caixa.scale = Vector3.ONE * 0.6
	caixa.position = PONTO + Vector3(1.75, 0.0, 0.35)
	caixa.rotation.y = 0.5
	add_child(caixa)
	placar = Label3D.new()
	placar.font_size = 64
	placar.outline_size = 14
	placar.outline_modulate = Color(0.15, 0.08, 0.25)
	placar.modulate = Color("#ffd23f")
	placar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	placar.pixel_size = 0.007
	placar.position = PONTO + Vector3(1.3, 2.6, -0.6)
	add_child(placar)
	boia = Node3D.new()
	boia.name = "Boia"
	var vara: Node3D = load(PROPS % "fishing_rod").instantiate()
	var flutua: Node3D = vara.find_child("fishing_rod_floater", true, false)
	flutua.get_parent().remove_child(flutua)
	flutua.owner = null
	flutua.transform = Transform3D(Basis.from_scale(Vector3.ONE * 0.6), Vector3.ZERO)
	boia.add_child(flutua)
	vara.free()
	boia.visible = false
	add_child(boia)
	camera = Camera3D.new()
	camera.fov = 52.0
	add_child(camera)
	# Atrás e à direita do aventureiro (a vara fica na mão direita), de cima, olhando a boia na água.
	camera.look_at_from_position(PONTO + Vector3(-2.3, 3.2, -3.6), PONTO + FRENTE * 4.0 + Vector3(-0.6, -0.6, 0))
	_montar_tela()
	_atualizar_placar()


# --- entrar e sair -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if game == null or game.menu_state != "" or _trocando:
		return
	if not event.is_action_pressed("interagir"):
		return
	if fase != Fase.FORA:
		sair()
		get_viewport().set_input_as_handled()
	elif pode_entrar():
		entrar()
		get_viewport().set_input_as_handled()


## Pescando (ou entrando e saindo): o main deixa o aventureiro parado e sem mira.
func pescando() -> bool:
	return fase != Fase.FORA or _trocando


## A criança está a pé, no círculo da ponta do cais.
func pode_entrar() -> bool:
	if game == null or _trocando or fase != Fase.FORA:
		return false
	var p: Player = game.player
	return not p.dizzy and not p.in_vehicle and not p.parked and not p.using_phone \
			and Vector2(p.global_position.x - PONTO.x, p.global_position.z - PONTO.z).length() < RAIO \
			and absf(p.global_position.y - PONTO.y) < 1.5


## O aviso de baixo da tela (o main mostra).
func dica(botao: String) -> String:
	if _trocando:
		return ""
	if fase != Fase.FORA:
		return "Aperte %s para guardar a vara" % botao
	if pode_entrar():
		return "Aperte %s para pescar" % botao
	return ""


func entrar() -> void:
	if game.in_combat():
		game.show_message("Agora não! Tem esqueleto por perto.", Color("#ff9d9d"), 1.6)
		return
	_trocando = true
	var p: Player = game.player
	p.input_enabled = false
	Sfx.play(game, "ui_ok", 0.0, 0.0)
	await _escurecer(1.0, 0.25)
	p.global_position = PONTO + Vector3.UP * 0.05
	p.velocity = Vector3.ZERO
	p.set_yaw(atan2(-FRENTE.x, -FRENTE.z))
	p.pegar_vara(FRENTE)
	_preparar_linha()
	camera.make_current()
	game.set_hud_visible(false)
	_hud.show()
	placar.hide()
	await _escurecer(0.0, 0.3)
	_trocando = false
	_lancar()


func sair() -> void:
	if fase == Fase.FORA or _trocando:
		return
	_trocando = true
	Sfx.play(game, "ui_ok", 0.0, 0.0)
	await _escurecer(1.0, 0.25)
	fase = Fase.FORA
	_guardando = false
	if is_instance_valid(peixe):
		peixe.queue_free()
	peixe = null
	boia.visible = false
	_hud.hide()
	cartao.hide()
	placar.show()
	var p: Player = game.player
	p.guardar_vara()
	p.camera.make_current()
	game.set_hud_visible(true)
	p.input_enabled = true
	await _escurecer(0.0, 0.3)
	_trocando = false


func _escurecer(alfa: float, segundos: float) -> void:
	var fade: ColorRect = game.fade
	var tw := fade.create_tween()
	tw.tween_property(fade, "modulate:a", alfa, segundos)
	await tw.finished


# --- a pescaria --------------------------------------------------------------------

func _process(delta: float) -> void:
	if fase == Fase.FORA:
		return
	_tempo += delta
	match fase:
		Fase.LANCANDO:
			var t := clampf(_tempo / 0.7, 0.0, 1.0)
			var pos := _voo_de.lerp(_alvo, t)
			pos.y += sin(PI * t) * 2.2
			boia.global_position = pos
			if t >= 1.0:
				_caiu_na_agua()
		Fase.ESPERANDO:
			_esperando()
		Fase.FISGAR:
			boia.global_position = _alvo + Vector3(0, -0.3 + sin(_tempo * 18.0) * 0.05, 0)
			_nadar_para(_alvo + Vector3(0, -0.35, 0) - FRENTE * 0.25, delta, 18.0)
			if _apertou_a():
				_fisgou()
			elif _tempo > janela():
				_escapou()
		Fase.PUXANDO:
			_puxando(delta)
		Fase.PEGOU:
			_pegou_andando(delta)
		Fase.ESCAPOU:
			boia.global_position = _alvo + Vector3(0, sin(_tempo * 4.0) * 0.03, 0)
			if is_instance_valid(peixe):
				peixe.global_position += (_de - _alvo).normalized() * 5.0 * delta + Vector3.DOWN * 0.4 * delta
			if _tempo > 1.3:
				_lancar()
	_esticar_linha()
	_mostrar_botao()


func _lancar() -> void:
	fase = Fase.LANCANDO
	_tempo = 0.0
	_guardando = false
	if is_instance_valid(peixe):
		peixe.queue_free()
	peixe = null
	peixe_id = forcar if forcar != "" else sortear()
	_alvo = PONTO + FRENTE * randf_range(4.2, 5.4) + Vector3(randf_range(-1.8, -0.2), 0, 0)
	_alvo.y = AGUA
	_voo_de = _ponta_da_linha()
	boia.global_position = _voo_de
	boia.visible = true
	Sfx.play(game, "arremesso", -4.0)
	var p: Player = game.player
	if is_instance_valid(p.vara):
		p.vara.rotation = Vector3.ZERO


func _caiu_na_agua() -> void:
	Fx.bubble_pop(game, _alvo)
	Sfx.play_at(game, "splash", _alvo, -4.0)
	fase = Fase.ESPERANDO
	_tempo = 0.0
	_espera = randf_range(2.2, 4.2) * (0.7 if Ajustes.facil else 1.0)
	_beliscou = 0
	_belisco = -10.0
	peixe = Fish.new()
	peixe.model_name = peixe_id
	peixe.cardume = false
	add_child(peixe)
	peixe.set_process(false)
	var lado := Vector3(randf_range(-1.0, 1.0), 0, randf_range(0.4, 1.0)).normalized()
	_de = _alvo + lado * 3.5
	_de.y = AGUA - 0.45
	peixe.global_position = _de
	_virar(peixe, _alvo - _de)
	peixe._play("Swimming_Normal")


## O peixe vem chegando por baixo d'água e belisca a boia duas vezes antes de puxar.
func _esperando() -> void:
	var t := clampf(_tempo / _espera, 0.0, 1.0)
	var ate := _alvo + (_de - _alvo).normalized() * 0.3
	ate.y = AGUA - 0.35
	if is_instance_valid(peixe):
		var pos := _de.lerp(ate, smoothstep(0.0, 1.0, minf(t * 1.25, 1.0)))
		pos.y += sin(_tempo * 3.0) * 0.03
		peixe.global_position = pos
	var marcas := [0.72, 0.88]
	if _beliscou < marcas.size() and t >= marcas[_beliscou]:
		_beliscou += 1
		_belisco = _tempo
		Sfx.play_at(game, "bolha", _alvo, -8.0)
	var mergulho := -0.12 * maxf(0.0, 1.0 - (_tempo - _belisco) / 0.25)
	boia.global_position = _alvo + Vector3(0, sin(_tempo * 2.2) * 0.03 + mergulho, 0)
	if _tempo >= _espera:
		_morder()


func _morder() -> void:
	fase = Fase.FISGAR
	_tempo = 0.0
	Sfx.play(game, "alerta", 0.0, 0.0)
	Fx.bubble_pop(game, _alvo)
	_vibrar(0.7, 0.9, 0.3)
	if is_instance_valid(peixe):
		peixe._play("Swimming_Fast")


func _fisgou() -> void:
	fase = Fase.PUXANDO
	_tempo = 0.0
	forca = 0.2
	Vozes.falar(game, "fisgou")
	Sfx.play_at(game, "splash", _alvo, -2.0)
	Fx.bubble_pop(game, _alvo)
	_vibrar(0.5, 0.5, 0.2)
	game.show_message("Fisgou! Aperte A sem parar!" if game.player.using_gamepad else "Fisgou! Aperte Espaço sem parar!",
			Color("#8ff3ff"), 1.6)


func _escapou() -> void:
	fase = Fase.ESCAPOU
	_tempo = 0.0
	game.show_message("Escapou! Tenta de novo.", Color("#8ff3ff"), 1.4)
	Sfx.play_at(game, "splash", _alvo, -6.0)
	if is_instance_valid(peixe):
		_virar(peixe, _de - _alvo)


## Apertando A, a barra enche; o peixe e a boia vêm chegando para o cais, se debatendo.
func _puxando(delta: float) -> void:
	if _apertou_a():
		forca += 1.0 / puxoes()
		Sfx.play_at(game, "splash", boia.global_position, -12.0)
		Fx.bubble_pop(game, boia.global_position)
		_vibrar(0.3, 0.6, 0.1)
	forca = maxf(forca - ESVAZIA * (0.5 if Ajustes.facil else 1.0) * delta, CHAO_BARRA)
	barra.value = forca
	var perto := PONTO + FRENTE * 1.8
	perto.y = AGUA
	var pos := _alvo.lerp(perto, minf(forca, 1.0) * 0.75)
	boia.global_position = pos + Vector3(sin(_tempo * 13.0) * 0.12, sin(_tempo * 9.0) * 0.05 - 0.05, 0)
	if is_instance_valid(peixe):
		peixe.global_position = pos + Vector3(sin(_tempo * 11.0) * 0.2, -0.15, 0.15)
		peixe.global_basis = Basis(Vector3.UP, sin(_tempo * 20.0) * 0.6)
	var p: Player = game.player
	if is_instance_valid(p.vara):
		p.vara.rotation.z = sin(_tempo * 22.0) * 0.05
	if forca >= 1.0:
		_pegou()


func _pegou() -> void:
	fase = Fase.PEGOU
	_tempo = 0.0
	_guardando = false
	var novo := not pegos.has(peixe_id)
	pegos[peixe_id] = int(pegos.get(peixe_id, 0)) + 1
	var spec := dados(peixe_id)
	var moedas: int = MOEDAS_NOVO[spec.raro] if novo else MOEDAS_REPETIDO
	boia.visible = false
	var p: Player = game.player
	if is_instance_valid(p.vara):
		p.vara.rotation = Vector3.ZERO
	_pulo_de = peixe.global_position if is_instance_valid(peixe) else _alvo
	if is_instance_valid(peixe):
		peixe._play("Out_Of_Water")
	Fx.bubble_pop(game, _pulo_de)
	Sfx.play_at(game, "splash", _pulo_de, 0.0)
	Sfx.play(game, "estrelinha", -2.0 if novo else -8.0, 0.0)
	_vibrar(0.6, 0.6, 0.25)
	if game.story:
		game.story.add_coins(moedas, _no_ar() + Vector3.UP * 0.8)
	if novo:
		Fx.confetti(game, _no_ar(), 30, 3.0)
		Vozes.falar(game, "peixe_novo")
	_mostrar_cartao(peixe_id, novo, moedas)
	_atualizar_placar()
	if aquario:
		aquario.atualizar(pegos)
	pescou.emit(peixe_id, novo)
	if game.story:
		game.story.save()


## Onde o peixe pego fica no ar, na frente da câmera.
func _no_ar() -> Vector3:
	return PONTO + FRENTE * 2.4 + Vector3(-0.8, 0.4, 0)


## O peixe pula da água para a frente da câmera e fica girando; com A (ou sozinho), vai para o balde e a boia volta.
func _pegou_andando(delta: float) -> void:
	if not is_instance_valid(peixe):
		_lancar()
		return
	if _guardando:
		var t := clampf(_tempo / 0.45, 0.0, 1.0)
		var topo := balde.global_position + Vector3.UP * 0.55
		var pos := _no_ar().lerp(topo, t)
		pos.y += sin(PI * t) * 0.6
		peixe.global_position = pos
		peixe.scale = Vector3.ONE * lerpf(1.0, 0.5, t)
		if t >= 1.0:
			_no_balde()
			_lancar()
		return
	var t := clampf(_tempo / 0.6, 0.0, 1.0)
	var pos := _pulo_de.lerp(_no_ar(), t)
	pos.y += sin(PI * t) * 1.2
	peixe.global_position = pos
	peixe.rotate_y(delta * (8.0 if t < 1.0 else 1.6))
	if t >= 1.0 and ((_tempo > 1.2 and _apertou_a()) or _tempo > 3.4):
		_guardando = true
		_tempo = 0.0
		cartao.hide()
		Sfx.play(game, "bolha", -6.0)


func _no_balde() -> void:
	if is_instance_valid(no_balde):
		no_balde.queue_free()
	no_balde = peixe
	peixe = null
	no_balde.scale = Vector3.ONE * 0.5
	no_balde.global_position = balde.global_position + Vector3.UP * 0.5
	no_balde.global_basis = Basis(Vector3.UP, 0.6) * Basis(Vector3.RIGHT, -PI / 2.0)
	no_balde._play("Swimming_Normal")
	Sfx.play_at(game, "splash", balde.global_position, -10.0)


# --- regras ----------------------------------------------------------------------

func janela() -> float:
	return JANELA_FACIL if Ajustes.facil else JANELA


func puxoes() -> int:
	return int(PUXOES[dados(peixe_id).get("raro", 1)]) - (2 if Ajustes.facil else 0)


## Sorteia o próximo peixe: na maioria das vezes, um dos que faltam; os raros saem menos.
func sortear() -> String:
	var faltam := PEIXES.filter(func(p: Dictionary) -> bool: return not pegos.has(p.id))
	var lista: Array = faltam if not faltam.is_empty() and randf() < CHANCE_NOVO else PEIXES
	var total := 0.0
	for p: Dictionary in lista:
		total += PESOS[p.raro]
	var r := randf() * total
	for p: Dictionary in lista:
		r -= PESOS[p.raro]
		if r <= 0.0:
			return p.id
	return lista[-1].id


static func dados(id: String) -> Dictionary:
	for p: Dictionary in PEIXES:
		if p.id == id:
			return p
	return {}


## A coleção salva na campanha.
func carregar(salvos: Dictionary) -> void:
	pegos.clear()
	for id in salvos:
		if not dados(String(id)).is_empty():
			pegos[String(id)] = int(salvos[id])
	_atualizar_placar()
	if aquario:
		aquario.atualizar(pegos)


func _atualizar_placar() -> void:
	placar.text = "PESCARIA\n%d de %d peixes" % [pegos.size(), PEIXES.size()]


func _apertou_a() -> bool:
	return Input.is_action_just_pressed("pular") or Input.is_action_just_pressed("atirar")


func _vibrar(fraco: float, forte: float, segundos: float) -> void:
	if not Ajustes.vibracao:
		return
	for d in Input.get_connected_joypads():
		Input.start_joy_vibration(d, fraco, forte, segundos)


static func _virar(f: Node3D, para: Vector3) -> void:
	para.y = 0.0
	if para.length() > 0.01:
		f.global_basis = Basis(Vector3.UP, atan2(para.x, para.z))


func _nadar_para(ate: Vector3, delta: float, rapidez: float) -> void:
	if not is_instance_valid(peixe):
		return
	peixe.global_position = peixe.global_position.lerp(ate, 1.0 - exp(-4.0 * delta))
	peixe.global_basis = Basis(Vector3.UP, atan2(FRENTE.x, FRENTE.z) + PI + sin(_tempo * rapidez) * 0.35)


# --- a linha -----------------------------------------------------------------------

func _linha() -> Node3D:
	var p: Player = game.player
	if not is_instance_valid(p.vara):
		return null
	return p.vara.find_child("fishing_rod_line", true, false)


## A boia e o anzol da vara do aventureiro ficam escondidos: a boia que voa é a da Pescaria.
func _preparar_linha() -> void:
	var linha := _linha()
	if linha:
		for c in linha.get_children():
			(c as Node3D).visible = false


func _ponta_da_linha() -> Vector3:
	var linha := _linha()
	if linha:
		return linha.global_position
	return game.player.global_position + Vector3.UP * 2.0 + FRENTE


## O fio sai da ponta da vara até a boia (sem boia, pende um pouquinho).
func _esticar_linha() -> void:
	var linha := _linha()
	if linha == null:
		return
	_preparar_linha()
	var ponta := linha.global_position
	var ate := boia.global_position + Vector3.UP * 0.12 if boia.visible else ponta + Vector3.DOWN * 0.35
	var d := ate - ponta
	var dist := d.length()
	if dist < 0.05:
		return
	var y := -d / dist
	var ref := Vector3.UP if absf(y.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	linha.global_basis = Basis(x, y * (dist / LINHA), z)


# --- a tela ------------------------------------------------------------------------

func _montar_tela() -> void:
	_hud = Control.new()
	_hud.name = "Pescaria"
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.visible = false
	if game and game.get("ui_layer"):
		var camada: CanvasLayer = game.ui_layer
		camada.add_child(_hud)
		# Embaixo do escurecer e dos menus.
		camada.move_child(_hud, (game.fade as Node).get_index())
	else:
		add_child(_hud)
	barra = ProgressBar.new()
	barra.min_value = 0.0
	barra.max_value = 1.0
	barra.show_percentage = false
	barra.anchor_left = 0.5
	barra.anchor_right = 0.5
	barra.anchor_top = 1.0
	barra.anchor_bottom = 1.0
	barra.offset_left = -200
	barra.offset_right = 240
	barra.offset_top = -118
	barra.offset_bottom = -78
	var fundo := MenuKit.box(Color("#2b2b40"), 20)
	fundo.border_color = Color.WHITE
	fundo.set_border_width_all(4)
	barra.add_theme_stylebox_override("background", fundo)
	barra.add_theme_stylebox_override("fill", MenuKit.box(Color("#3fbf63"), 16))
	barra.visible = false
	_hud.add_child(barra)
	botao_a = BotaoA.new()
	botao_a.visible = false
	_hud.add_child(botao_a)
	cartao = PanelContainer.new()
	cartao.add_theme_stylebox_override("panel", MenuKit.panel_style())
	# Do lado direito, abaixo do aviso grande do meio (o das primeiras moedas) e longe do peixe no ar.
	cartao.anchor_left = 1.0
	cartao.anchor_right = 1.0
	cartao.offset_top = 250
	cartao.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	cartao.visible = false
	_hud.add_child(cartao)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 10)
	cartao.add_child(caixa)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 18)
	caixa.add_child(topo)
	_retrato = RetratoPeixe.new(Vector2(250, 180))
	topo.add_child(_retrato)
	var lado := VBoxContainer.new()
	lado.alignment = BoxContainer.ALIGNMENT_CENTER
	lado.add_theme_constant_override("separation", 6)
	lado.custom_minimum_size = Vector2(250, 0)
	topo.add_child(lado)
	cartao_novo = Label.new()
	cartao_novo.text = "NOVO!"
	cartao_novo.add_theme_font_size_override("font_size", 26)
	cartao_novo.add_theme_color_override("font_color", MenuKit.GOLD)
	lado.add_child(cartao_novo)
	cartao_nome = Label.new()
	cartao_nome.add_theme_font_size_override("font_size", 32)
	lado.add_child(cartao_nome)
	var estrelas := HBoxContainer.new()
	estrelas.add_theme_constant_override("separation", 4)
	lado.add_child(estrelas)
	for i in 3:
		var e := MenuIcon.new("estrela", MenuKit.GOLD, 34)
		estrelas.add_child(e)
		_estrelas.append(e)
	_cartao_moedas = Label.new()
	_cartao_moedas.add_theme_font_size_override("font_size", 22)
	_cartao_moedas.add_theme_color_override("font_color", MenuKit.GOLD)
	lado.add_child(_cartao_moedas)
	var tira := HBoxContainer.new()
	tira.alignment = BoxContainer.ALIGNMENT_CENTER
	tira.add_theme_constant_override("separation", 5)
	caixa.add_child(tira)
	for spec: Dictionary in PEIXES:
		var b := Bolinha.new()
		b.cor = spec.cor
		tira.add_child(b)
		_tira.append(b)
	_cartao_conta = Label.new()
	_cartao_conta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cartao_conta.add_theme_font_size_override("font_size", 20)
	_cartao_conta.add_theme_color_override("font_color", Color("#8ff3ff"))
	caixa.add_child(_cartao_conta)


func _mostrar_cartao(id: String, novo: bool, moedas: int) -> void:
	var spec := dados(id)
	cartao_nome.text = spec.nome
	cartao_novo.visible = novo
	for i in 3:
		_estrelas[i].modulate = Color.WHITE if i < spec.raro else Color(0.35, 0.35, 0.45)
	_cartao_moedas.text = "+%d moedas" % moedas
	for i in PEIXES.size():
		_tira[i].pego = pegos.has(PEIXES[i].id)
		_tira[i].destaque = PEIXES[i].id == id
		_tira[i].queue_redraw()
	_cartao_conta.text = "Aquário: %d de %d peixes" % [pegos.size(), PEIXES.size()]
	_retrato.mostrar(id)
	cartao.reset_size()
	cartao.offset_right = -24
	cartao.offset_left = -24 - cartao.get_combined_minimum_size().x
	cartao.show()


## O A grande: em cima da boia quando o peixe morde; do lado da barra enquanto puxa.
func _mostrar_botao() -> void:
	barra.visible = fase == Fase.PUXANDO
	botao_a.visible = fase == Fase.FISGAR or fase == Fase.PUXANDO
	if not botao_a.visible:
		return
	if botao_a.teclado == game.player.using_gamepad:
		botao_a.teclado = not game.player.using_gamepad
	if fase == Fase.FISGAR:
		var s := camera.unproject_position(boia.global_position + Vector3.UP * 0.4)
		botao_a.position = s - botao_a.size * 0.5 - Vector2(0, 50)
	else:
		botao_a.position = barra.global_position + Vector2(-botao_a.size.x - 16, (barra.size.y - botao_a.size.y) * 0.5)
	botao_a.queue_redraw()


## O botão A desenhado, pulsando (no teclado, a tecla "Espaço").
class BotaoA:
	extends Control
	var teclado := false:
		set(valor):
			teclado = valor
			size = Vector2(176, 60) if valor else Vector2(92, 92)
			pivot_offset = size * 0.5
	var _t := 0.0

	func _init() -> void:
		size = Vector2(92, 92)
		pivot_offset = size * 0.5
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		scale = Vector2.ONE * (1.0 + 0.1 * sin(_t * 10.0))

	func _draw() -> void:
		var c := size * 0.5
		var fonte := ThemeDB.fallback_font
		if teclado:
			var r := Rect2(Vector2.ZERO, size)
			draw_rect(r, Color.WHITE)
			draw_rect(r.grow(-4), Color("#3fbf63"))
			draw_string(fonte, Vector2(0, 41), "Espaço", HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, Color.WHITE)
			return
		draw_circle(c, 46, Color.WHITE)
		draw_circle(c, 40, Color("#3fbf63"))
		draw_string(fonte, Vector2(0, 62), "A", HORIZONTAL_ALIGNMENT_CENTER, size.x, 48, Color.WHITE)


## Uma bolinha da tira da coleção: colorida se já pegou, apagada se falta; a do peixe da vez, com anel.
class Bolinha:
	extends Control
	var cor := Color.WHITE
	var pego := false
	var destaque := false

	func _init() -> void:
		custom_minimum_size = Vector2(24, 24)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, 11.0, cor if pego else Color("#3b3b58"))
		draw_arc(c, 11.0, 0.0, TAU, 24, Color.WHITE if destaque else Color(1, 1, 1, 0.35), 3.0 if destaque else 1.5, true)


## O peixe do cartão: o modelo de verdade num mundinho próprio, de lado, balançando.
class RetratoPeixe:
	extends SubViewportContainer
	var _viewport: SubViewport
	var _camera: Camera3D
	var _peixe: Fish
	var _t := 0.0

	func _init(lado: Vector2) -> void:
		custom_minimum_size = lado
		stretch = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_viewport = SubViewport.new()
		_viewport.own_world_3d = true
		_viewport.msaa_3d = Viewport.MSAA_4X
		add_child(_viewport)
		var mundo := WorldEnvironment.new()
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color("#8fd0ff")
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.9, 0.95, 1.0)
		env.ambient_light_energy = 0.8
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		mundo.environment = env
		_viewport.add_child(mundo)
		var sol := DirectionalLight3D.new()
		sol.rotation_degrees = Vector3(-40, -60, 0)
		sol.light_energy = 1.1
		_viewport.add_child(sol)
		_camera = Camera3D.new()
		_camera.fov = 30.0
		_viewport.add_child(_camera)

	func mostrar(id: String) -> void:
		if is_instance_valid(_peixe):
			_peixe.queue_free()
		_peixe = Fish.new()
		_peixe.model_name = id
		_peixe.cardume = false
		_viewport.add_child(_peixe)
		_peixe.set_process(false)
		_peixe.global_position = Vector3.ZERO
		_peixe._play("Swimming_Normal")
		var caixa := AABB()
		var primeiro := true
		for mi in _peixe.find_children("*", "MeshInstance3D", true, false):
			var a: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
			caixa = a if primeiro else caixa.merge(a)
			primeiro = false
		var meio := caixa.get_center()
		var maior := maxf(caixa.size.z, caixa.size.y * 1.4)
		var longe := maxf(maior, 0.1) * 0.5 / tan(deg_to_rad(_camera.fov) * 0.5) * 1.35
		_camera.look_at_from_position(meio + Vector3(-longe, longe * 0.15, longe * 0.2), meio)

	func _process(delta: float) -> void:
		_t += delta
		if is_instance_valid(_peixe):
			_peixe.rotation.y = sin(_t * 1.3) * 0.35
