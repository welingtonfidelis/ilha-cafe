class_name CopaKart
extends Node3D
## Copa de Kart (item 10 da lista de melhorias, 2026-11-10). No gramado a oeste das vagas do box fica o pódio (três
## blocos, ouro no meio, prata e bronze dos lados) com a placa "COPA DE KART" e, ao lado, o pedestal com a taça da
## melhor copa (da cor do melhor lugar). Na frente do pódio, um círculo dourado: nele, B (ou E) começa a copa: o
## aventureiro entra num kart do box e corre três corridas de duas voltas contra os dois rivais (a 2ª ao contrário,
## largando virado e com as marcas na ordem inversa). Cada corrida dá pontos (3 para o 1º, 2 para o 2º, 1 para o 3º);
## no fim, quem tiver mais pontos ganha (empate fica com o jogador). Vem a cena do pódio: a tela escurece, o
## aventureiro e os dois rivais sobem nos blocos, a câmera mostra o pódio com confete e fogos, a taça gira em cima
## do campeão e a faixa diz o lugar. Dá moedas (40, 25 ou 15) e guarda a melhor colocação. Descer do kart no meio da
## copa cancela.

## Pista ao contrário em cada corrida, voltas por corrida, pontos por lugar e moedas pelo lugar final.
const CORRIDAS := [false, true, false]
const VOLTAS := 2
const PONTOS := [3, 2, 1]
const MOEDAS := [40, 25, 15]
const ENTRE := 4.5
const CENA := 6.0
## Meio do pódio, no gramado a oeste das vagas, e para onde ele olha (para o box).
const PODIO := Vector3(79.0, 0.0, -13.0)
const FRENTE := Vector3(1, 0, 0)
const CORES := {1: Color("#ffd23f"), 2: Color("#d6dce6"), 3: Color("#c98a4f")}
const NOMES := {"voce": "Você", "0": "", "1": "Mago"}

var game: Node
var story: Story
var kr: KartRace
var rodando := false
var na_cena := false
var corrida := 0
var pontos := {}
## Melhor lugar numa copa (0: nunca terminou).
var melhor := 0
## O resultado da última copa (os testes olham).
var lugar_final := 0
var camera: Camera3D
var _circulo: MeshInstance3D
var _placa: Label3D
var _taca: Node3D
var _taca_campeao: Node3D
var _blocos := {}
var _convidados: Array[Node3D] = []
var _proxima_em := -1.0


func _ready() -> void:
	kr.corrida_terminou.connect(_terminou)
	_montar()


# --- o pódio ---------------------------------------------------------------------

func _chao(p: Vector3) -> Vector3:
	return game._ground_point(p)


func _montar() -> void:
	var base := PODIO
	var lado := FRENTE.cross(Vector3.UP).normalized()
	for spec in [[1, 0.0, 1.2], [2, 2.1, 0.8], [3, -2.1, 0.5]]:
		var lugar: int = spec[0]
		var bloco := StaticBody3D.new()
		bloco.name = "Bloco%d" % lugar
		add_child(bloco)
		var p: Vector3 = base + lado * float(spec[1])
		bloco.position = p
		var malha := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(2.0, spec[2], 2.0)
		malha.mesh = caixa
		var mat := StandardMaterial3D.new()
		mat.albedo_color = CORES[lugar]
		mat.metallic = 0.15
		mat.roughness = 0.5
		malha.material_override = mat
		malha.position.y = float(spec[2]) * 0.5
		bloco.add_child(malha)
		var forma := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = caixa.size
		forma.shape = bx
		forma.position.y = float(spec[2]) * 0.5
		bloco.add_child(forma)
		var numero := Label3D.new()
		numero.text = str(lugar)
		numero.font_size = 96
		numero.outline_size = 16
		numero.modulate = Color.WHITE
		numero.outline_modulate = Color(0.15, 0.08, 0.25)
		numero.pixel_size = 0.008
		numero.position = FRENTE * 1.02 + Vector3.UP * float(spec[2]) * 0.5
		numero.rotation.y = atan2(FRENTE.x, FRENTE.z)
		bloco.add_child(numero)
		_blocos[lugar] = {"no": bloco, "altura": float(spec[2])}
	_placa = Label3D.new()
	_placa.text = "COPA DE KART\n3 corridas"
	_placa.font_size = 72
	_placa.outline_size = 14
	_placa.modulate = Color("#ffd23f")
	_placa.outline_modulate = Color(0.15, 0.08, 0.25)
	_placa.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_placa.pixel_size = 0.008
	add_child(_placa)
	_placa.position = base + Vector3.UP * 4.2
	_circulo = MeshInstance3D.new()
	var anel := TorusMesh.new()
	anel.inner_radius = 1.4
	anel.outer_radius = 1.6
	anel.rings = 40
	anel.ring_segments = 6
	_circulo.mesh = anel
	_circulo.material_override = Fx.glow_material(Color("#ffd23f"), 1.4)
	_circulo.scale = Vector3(1, 0.12, 1)
	add_child(_circulo)
	_circulo.position = base + FRENTE * 4.0 + Vector3.UP * 0.04
	_taca = Revanche.taca(1.0)
	add_child(_taca)
	_taca.position = base - FRENTE * 0.2 + lado * 4.4
	camera = Camera3D.new()
	camera.fov = 50.0
	add_child(camera)
	_assentar.call_deferred()


## Põe o pódio no chão de verdade (precisa da física pronta).
func _assentar() -> void:
	await get_tree().physics_frame
	var base: Vector3 = _chao(PODIO)
	var dy := base.y - PODIO.y
	for c in get_children():
		if c is Node3D and c != camera:
			(c as Node3D).position.y += dy
	camera.look_at_from_position(base + FRENTE * 7.0 + Vector3.UP * 2.6, base + Vector3.UP * 1.9)
	atualizar_taca()


func atualizar_taca() -> void:
	_taca.visible = melhor > 0
	if melhor > 0:
		Revanche._pintar(_taca, CORES[melhor])


func ponto_do_circulo() -> Vector3:
	return _circulo.global_position


# --- começar, correr e terminar ---------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if game.menu_state != "" or not event.is_action_pressed("interagir"):
		return
	if pode_comecar():
		comecar()
		get_viewport().set_input_as_handled()


func pode_comecar() -> bool:
	if rodando or kr.state != "a_pe" or game.in_combat():
		return false
	var p: Player = game.player
	var c := ponto_do_circulo()
	return not p.dizzy and not p.parked and not p.using_phone and not p.pescando \
			and Vector2(p.global_position.x - c.x, p.global_position.z - c.z).length() < 1.9


func dica(botao: String) -> String:
	if pode_comecar():
		return "Aperte %s para a Copa de Kart: 3 corridas" % botao
	return ""


func comecar() -> bool:
	var livres := kr.vehicles.filter(func(v: Kart) -> bool: return v.is_home())
	if livres.is_empty():
		return false
	rodando = true
	corrida = 0
	pontos = {"voce": 0, "0": 0, "1": 0}
	lugar_final = 0
	kr.copa_ativa = true
	kr.enter(livres[0])
	game.banner("Copa de Kart!", "3 corridas de %d voltas. Cada corrida dá pontos: quem somar mais leva a taça!" % VOLTAS, CORES[1], 3.4)
	_proxima()
	return true


func _proxima() -> void:
	_proxima_em = -1.0
	kr.reverso = CORRIDAS[corrida]
	kr.voltas = VOLTAS
	kr.prefixo = "Copa %d/3" % (corrida + 1) + (" · ao contrário" if kr.reverso else "")
	kr._start_race()
	if corrida > 0:
		game.banner("Corrida %d de 3" % (corrida + 1), "Agora ao contrário!" if kr.reverso else "Valendo a taça!", CORES[1], 2.6)


func _terminou(lugar: int, ordem: Array) -> void:
	if not rodando:
		return
	for i in ordem.size():
		pontos[ordem[i]] = int(pontos.get(ordem[i], 0)) + PONTOS[mini(i, PONTOS.size() - 1)]
	corrida += 1
	game.banner("%dº lugar! +%d pontos" % [lugar, PONTOS[lugar - 1]], "Você tem %d pontos (%s)." % [pontos.voce, placar()], CORES.get(lugar, Color.WHITE), 3.4)
	_proxima_em = ENTRE


## "Você 5 · Ana 4 · Mago 3", do maior para o menor.
func placar() -> String:
	var outro := "Pedro" if game.player.character_name == "menina" else "Ana"
	var nomes := {"voce": "Você", "0": outro, "1": "Mago"}
	var lista := classificacao()
	return " · ".join(lista.map(func(q: String) -> String: return "%s %d" % [nomes[q], pontos[q]]))


## Quem soma mais primeiro; no empate, o jogador fica na frente.
func classificacao() -> Array:
	var lista := ["voce", "0", "1"]
	lista.sort_custom(func(a: String, b: String) -> bool:
		if pontos[a] != pontos[b]:
			return pontos[a] > pontos[b]
		return a == "voce")
	return lista


func _process(delta: float) -> void:
	_placa.visible = not rodando
	_circulo.visible = not rodando
	if is_instance_valid(_taca_campeao):
		_taca_campeao.rotate_y(delta * 1.5)
	if not rodando or na_cena:
		return
	# Desceu do kart (ou caiu no mar, ou ficou tonto) no meio da copa: cancela.
	if kr.state == "a_pe":
		cancelar()
		return
	if _proxima_em >= 0.0 and game.menu_state == "":
		_proxima_em -= delta
		if _proxima_em <= 0.0:
			if corrida < CORRIDAS.size():
				_proxima()
			else:
				_final()


func cancelar() -> void:
	rodando = false
	kr.copa_ativa = false
	kr.reverso = false
	kr.voltas = KartRace.LAPS
	kr.prefixo = ""
	_proxima_em = -1.0
	game.show_message("Copa cancelada. Volte ao círculo do pódio para começar de novo.", Color("#ffe9a8"), 2.6)


## Fim da copa: moedas, a melhor colocação e a cena do pódio.
func _final() -> void:
	_proxima_em = -1.0
	var ordem := classificacao()
	lugar_final = ordem.find("voce") + 1
	if melhor == 0 or lugar_final < melhor:
		melhor = lugar_final
	story.add_coins(MOEDAS[lugar_final - 1], game.player.global_position + Vector3.UP * 3.0)
	story.save()
	await _cena_do_podio(ordem)
	rodando = false
	kr.copa_ativa = false
	kr.reverso = false
	kr.voltas = KartRace.LAPS
	kr.prefixo = ""
	atualizar_taca()


func _cena_do_podio(ordem: Array) -> void:
	na_cena = true
	var p: Player = game.player
	var fade: ColorRect = game.fade
	var tw := fade.create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.4)
	await tw.finished
	kr.leave(true)
	p.input_enabled = false
	var outro := "menino" if p.character_name == "menina" else "menina"
	var modelos := {"0": Player.CHARACTERS[outro], "1": KartRace.RIVAL_PILOTS[0]}
	for i in ordem.size():
		var bloco: Dictionary = _blocos[i + 1]
		var topo: Vector3 = (bloco.no as Node3D).global_position + Vector3.UP * float(bloco.altura)
		if ordem[i] == "voce":
			p.global_position = topo + Vector3.UP * 0.1
			p.velocity = Vector3.ZERO
			p.visual.rotation.y = atan2(FRENTE.x, FRENTE.z)
		else:
			var t: Townsperson = game.spawn_townsperson({"nome": "Podio%d" % i, "modelo_caminho": modelos[ordem[i]], "atividade": "torcendo"},
				topo, atan2(FRENTE.x, FRENTE.z))
			_convidados.append(t)
	var topo1: Vector3 = (_blocos[1].no as Node3D).global_position + Vector3.UP * (float(_blocos[1].altura) + 2.6)
	_taca_campeao = Revanche.taca(0.9)
	add_child(_taca_campeao)
	_taca_campeao.global_position = topo1
	Revanche._pintar(_taca_campeao, CORES[1])
	camera.make_current()
	game.set_hud_visible(false)
	tw = fade.create_tween()
	tw.tween_property(fade, "modulate:a", 0.0, 0.5)
	var palavras := {1: "Campeão da Copa de Kart!", 2: "2º lugar na Copa de Kart!", 3: "3º lugar na Copa de Kart!"}
	game.banner(palavras[lugar_final], "Pontos: %s. +%d moedas" % [placar(), MOEDAS[lugar_final - 1]], CORES[lugar_final], CENA - 1.0)
	Sfx.play(game, "estrelinha", 0.0, 0.0)
	for k in 4:
		Fx.confetti(game, topo1 + Vector3(randf_range(-2, 2), 0.5, randf_range(-2, 2)), 40, 4.0)
		Fx.firework(game, PODIO + FRENTE * -6.0 + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6)), 12.0, CORES[1 + k % 3])
		await get_tree().create_timer(CENA / 4.0, false).timeout
	tw = fade.create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.4)
	await tw.finished
	for t in _convidados:
		if is_instance_valid(t):
			t.queue_free()
	_convidados.clear()
	if is_instance_valid(_taca_campeao):
		_taca_campeao.queue_free()
	p.global_position = ponto_do_circulo() + FRENTE * 2.0 + Vector3.UP * 0.3
	p.set_yaw(atan2(FRENTE.x, FRENTE.z))
	p.camera.make_current()
	game.set_hud_visible(true)
	p.input_enabled = true
	tw = fade.create_tween()
	tw.tween_property(fade, "modulate:a", 0.0, 0.5)
	na_cena = false


func dados_salvos() -> Dictionary:
	return {"melhor": melhor}


func carregar(dados: Dictionary) -> void:
	melhor = clampi(int(dados.get("melhor", 0)), 0, 3)
	atualizar_taca()
