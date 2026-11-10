class_name EscondeEsconde
extends Node3D
## Esconde-esconde dos esqueletos amigos (item 6 da lista de melhorias, 2026-11-10). Só no pós-jogo: na praia, ao
## lado da entrada do cais, o Ossinho do esconde-esconde fica do lado de um círculo dourado. No círculo, B começa:
## a tela escurece contando 3, 2, 1 e cinco amigos se escondem numa região (a cidade, o sítio ou o pé do Morro,
## uma por rodada, nessa ordem). Os lugares saem das coisas da própria ilha: atrás de prédios, carros, fardos de feno,
## árvores e pedras, do lado de longe do meio da região, com chão firme e espaço livre.
## Para achar: cada amigo toca um sininho de vez em quando (de perto dá para ouvir) e solta um "hihi" quando o
## aventureiro passa perto; no alto da tela, cinco carinhas mostram quantos faltam e o termômetro muda de azul
## (longe) para vermelho (pertinho). Passados 45 s sem achar ninguém (20 s no Modo Fácil), a seta do objetivo aponta
## para o mais perto. Chegar a 3 m acha: o amigo levanta, comemora "Achou!", dá moedas e vai embora de balão.
## Achando os cinco, a rodada dá mais moedas e uma figurinha nova do amigo (seis ao todo), que fica na campanha.

## Onde fica o Ossinho, e o círculo na frente dele (fora do círculo da defesa da praia).
const ANFITRIAO := Vector3(-9.0, 0.0, 198.6)
const CIRCULO := Vector3(-9.0, 0.0, 202.4)
const RAIO_CIRCULO := 1.8
const ACHAR := 3.0
const QUANTOS := 5
const MOEDAS_ACHOU := 3
const MOEDAS_RODADA := 15
const DICA := 45.0
const DICA_FACIL := 20.0
const SINO_LONGE := 26.0
const HIHI_PERTO := 12.0
const CONTAGEM := 3.4
## As regiões, uma por rodada: o meio, até onde vale, onde estão as coisas para se esconder atrás e a distância
## mínima entre dois amigos.
const AREAS := [
	{"id": "cidade", "nome": "na cidade", "centro": Vector2(0, 148), "raio": 72.0, "cobertura": ["Cidade/Predios", "Cidade/Enfeites"],
		"longe": 16.0},
	{"id": "sitio", "nome": "no sítio", "centro": Vector2(-120, -6), "raio": 38.0, "cobertura": ["Pasto"], "longe": 8.0},
	{"id": "morro", "nome": "no pé do Morro", "centro": Vector2(0, 0), "raio": 100.0, "cobertura": ["Morro"], "longe": 18.0},
]
## As figurinhas: um amigo de cada tipo, com o nome e a cor da bolinha.
const FIGURINHAS := [
	{"id": "Skeleton_Minion", "nome": "Ossinho", "cor": Color("#e8e2d0")},
	{"id": "Skeleton_Warrior", "nome": "Guerreiro", "cor": Color("#e07b39")},
	{"id": "Skeleton_Rogue", "nome": "Arqueiro", "cor": Color("#3fa7d6")},
	{"id": "Skeleton_Mage", "nome": "Mago", "cor": Color("#8a5cd6")},
	{"id": "Lobinho", "nome": "Lobinho", "cor": Color("#8a6a4f")},
	{"id": "Conde", "nome": "Conde", "cor": Color("#d64f6a")},
]
const FALAS_ANFITRIAO := ["Vamos brincar de esconde-esconde? Fique no círculo dourado!",
	"Meus amigos adoram se esconder. Escute o sininho deles!"]

enum Estado { PARADO, CONTANDO, BUSCANDO }

var game: Node
var story: Story
var estado := Estado.PARADO
var rodadas := 0
var figurinhas: Array[String] = []
## Os amigos escondidos da rodada (os achados saem da lista quando vão embora de balão).
var escondidos: Array[Townsperson] = []
var achados := 0
var area: Dictionary = {}
var anfitriao: Townsperson
## Nos testes: segundos sem achar ninguém até a seta aparecer (negativo: o de sempre).
var dica_teste := -1.0
## Peças da tela (os testes olham).
var hud: Control
var termometro: MenuIcon
var numero: Label
var cartao: PanelContainer
var cartao_nome: Label
var _icones: Array[MenuIcon] = []
var _tira: Array[Pescaria.Bolinha] = []
var _cartao_titulo: Label
var _cartao_moedas: Label
var _retrato: RetratoAmigo
var _ativo := false
var _circulo: MeshInstance3D
var _placa: Label3D
var _tempo := 0.0
var _sem_achar := 0.0
var _sinos := {}
var _cartao_tempo := 0.0


func _ready() -> void:
	_montar_tela()


# --- começar e terminar ------------------------------------------------------------

func _process(delta: float) -> void:
	var fim := story != null and story.stage == "fim"
	if fim != _ativo:
		_ativar(fim)
	if not _ativo:
		return
	_tempo += delta
	match estado:
		Estado.CONTANDO:
			_contando()
		Estado.BUSCANDO:
			_buscando(delta)
	if cartao.visible:
		_cartao_tempo += delta
		if _cartao_tempo > 4.5 or (_cartao_tempo > 1.0 and Input.is_action_just_pressed("pular")):
			cartao.hide()
			if estado == Estado.PARADO:
				hud.hide()
	_circulo.visible = estado == Estado.PARADO
	_placa.visible = estado == Estado.PARADO


func _ativar(on: bool) -> void:
	_ativo = on
	if not on:
		_cancelar()
		if is_instance_valid(anfitriao):
			anfitriao.queue_free()
		if _circulo:
			_circulo.queue_free()
			_placa.queue_free()
			_circulo = null
		return
	var chao: Vector3 = game._ground_point(ANFITRIAO)
	var olhar := CIRCULO - ANFITRIAO
	anfitriao = game.spawn_townsperson({"nome": "OssinhoDoEsconde", "modelo_caminho": SkeletonEnemy.model_path("Skeleton_Minion"),
		"atividade": "parado", "falas": PackedStringArray(FALAS_ANFITRIAO)}, chao, atan2(olhar.x, olhar.z))
	_circulo = MeshInstance3D.new()
	var anel := TorusMesh.new()
	anel.inner_radius = RAIO_CIRCULO - 0.2
	anel.outer_radius = RAIO_CIRCULO
	anel.rings = 40
	anel.ring_segments = 6
	_circulo.mesh = anel
	_circulo.material_override = Fx.glow_material(Color("#ffd23f"), 1.4)
	_circulo.scale = Vector3(1.0, 0.12, 1.0)
	add_child(_circulo)
	_circulo.global_position = game._ground_point(CIRCULO) + Vector3.UP * 0.04
	_placa = Label3D.new()
	_placa.text = "ESCONDE-ESCONDE"
	_placa.font_size = 64
	_placa.outline_size = 14
	_placa.outline_modulate = Color(0.15, 0.08, 0.25)
	_placa.modulate = Color("#ffd23f")
	_placa.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_placa.pixel_size = 0.007
	add_child(_placa)
	_placa.global_position = chao + Vector3.UP * 3.1


func _unhandled_input(event: InputEvent) -> void:
	if not _ativo or game.menu_state != "" or not event.is_action_pressed("interagir"):
		return
	if pode_comecar():
		comecar()
		get_viewport().set_input_as_handled()


func rodando() -> bool:
	return estado != Estado.PARADO


func pode_comecar() -> bool:
	if not _ativo or estado != Estado.PARADO:
		return false
	var p: Player = game.player
	return not p.dizzy and not p.in_vehicle and not p.parked and not p.using_phone and not p.pescando \
			and Vector2(p.global_position.x - CIRCULO.x, p.global_position.z - CIRCULO.z).length() < RAIO_CIRCULO + 0.3


## O aviso de baixo da tela (o main mostra).
func dica(botao: String) -> String:
	if pode_comecar():
		return "Aperte %s para brincar de esconde-esconde" % botao
	return ""


func comecar() -> void:
	if game.in_combat():
		game.show_message("Agora não! Tem esqueleto por perto.", Color("#ff9d9d"), 1.6)
		return
	area = AREAS[rodadas % AREAS.size()]
	var lugares := lugares_para(area)
	if lugares.size() < QUANTOS:
		game.show_message("Os amigos não acharam onde se esconder. Tenta de novo!", Color("#ff9d9d"), 2.0)
		return
	_cancelar()
	estado = Estado.CONTANDO
	_tempo = 0.0
	achados = 0
	Sfx.play(game, "ui_ok", 0.0, 0.0)
	anfitriao.say("Fecha o olho e conta! Eles vão se esconder %s!" % area.nome, 3.5)
	_esconder(lugares)
	for i in QUANTOS:
		_icones[i].modulate = Color(0.4, 0.4, 0.5)
	hud.show()
	cartao.hide()
	numero.show()
	var fade: ColorRect = game.fade
	var tw := fade.create_tween()
	tw.tween_property(fade, "modulate:a", 0.75, 0.3)


func _contando() -> void:
	var falta := ceili(3.0 - _tempo)
	numero.text = str(falta) if falta > 0 else "Lá vou eu!"
	if _tempo >= CONTAGEM:
		estado = Estado.BUSCANDO
		_sem_achar = 0.0
		numero.hide()
		var fade: ColorRect = game.fade
		var tw := fade.create_tween()
		tw.tween_property(fade, "modulate:a", 0.0, 0.4)
		game.banner("Esconde-esconde!", "Ache os %d amigos escondidos %s. Escute o sininho!" % [QUANTOS, area.nome], Color("#ffd23f"), 4.0)


## Some com os escondidos que sobraram (rodada largada ou pós-jogo desligado).
func _cancelar() -> void:
	for h in escondidos:
		if is_instance_valid(h):
			h.queue_free()
	escondidos.clear()
	_sinos.clear()
	estado = Estado.PARADO
	if hud:
		hud.hide()
		numero.hide()


# --- os escondidos ---------------------------------------------------------------

func _esconder(lugares: Array) -> void:
	var tipos := FIGURINHAS.map(func(f: Dictionary) -> String: return f.id)
	tipos.shuffle()
	for i in QUANTOS:
		var lugar: Dictionary = lugares[i]
		var tipo: String = tipos[i % tipos.size()]
		var olhar: Vector3 = lugar.olhar
		var h: Townsperson = game.spawn_townsperson({"nome": "Escondido%d" % i, "modelo_caminho": SkeletonEnemy.model_path(tipo),
			"atividade": "sentado_chao"}, lugar.pos, atan2(olhar.x, olhar.z))
		var pele: String = SkeletonEnemy.TYPES.get(tipo, {}).get("skin", "")
		if pele != "":
			h._apply_variant(h.visual.get_child(0), load(pele))
		h.set_meta("tipo", tipo)
		h.set_meta("olhar", olhar)
		h.add_to_group(&"escondidos")
		escondidos.append(h)
		_sinos[h] = randf_range(0.5, 3.0)


func _buscando(delta: float) -> void:
	_sem_achar += delta
	var p: Vector3 = game.player.global_position
	var perto := INF
	for h in escondidos.duplicate():
		if not is_instance_valid(h) or h.has_meta("achado"):
			continue
		var d := Vector2(h.global_position.x - p.x, h.global_position.z - p.z).length()
		perto = minf(perto, d)
		if d < ACHAR and absf(h.global_position.y - p.y) < 3.0:
			_achou(h)
			continue
		_sinos[h] = float(_sinos.get(h, 1.0)) - delta
		if _sinos[h] <= 0.0 and d < SINO_LONGE:
			_sinos[h] = randf_range(2.5, 4.0)
			Sfx.play_at(game, "sino", h.global_position + Vector3.UP * 1.2, -6.0)
			if d < HIHI_PERTO:
				Fx.popup_text(game, h.global_position + Vector3.UP * 2.0, "hihi", Color("#ffe9a8"))
	_termometro(perto)


## Azul longe, amarelo no meio, vermelho e pulando pertinho.
func _termometro(perto: float) -> void:
	var t := clampf(1.0 - (perto - ACHAR) / 50.0, 0.0, 1.0)
	var cor := Color("#4aa8ff").lerp(Color("#ffd23f"), clampf(t * 2.0, 0.0, 1.0)) if t < 0.5 \
			else Color("#ffd23f").lerp(Color("#ff4f4f"), (t - 0.5) * 2.0)
	termometro.color = cor
	termometro.scale = Vector2.ONE * (1.0 + (0.12 * sin(_tempo * (6.0 + t * 14.0)) if t > 0.6 else 0.0))
	termometro.queue_redraw()


func calor() -> Color:
	return termometro.color


func _achou(h: Townsperson) -> void:
	h.set_meta("achado", true)
	achados += 1
	_sem_achar = 0.0
	var p: Vector3 = game.player.global_position
	var olhar := p - h.global_position
	h.activity = "parado"
	# Sentado, o modelo fica girado 90° para compensar a animação; em pé, volta.
	(h.visual.get_child(0) as Node3D).rotation.y = 0.0
	h.visual.rotation.y = atan2(olhar.x, olhar.z)
	h.celebrate(2.2, "Achou!")
	Sfx.play(game, "estrelinha", -2.0, 0.0)
	story.add_coins(MOEDAS_ACHOU, h.global_position + Vector3.UP * 2.8)
	_icones[achados - 1].modulate = Color.WHITE
	_vibrar()
	get_tree().create_timer(2.2, false).timeout.connect(func() -> void:
		if is_instance_valid(h):
			escondidos.erase(h)
			Fx.balloon_away(h, h.ap, 2.6))
	if achados >= QUANTOS:
		_terminar()


func _terminar() -> void:
	estado = Estado.PARADO
	rodadas += 1
	var nova := ""
	for f: Dictionary in FIGURINHAS:
		if not f.id in figurinhas:
			nova = f.id
			break
	if nova != "":
		figurinhas.append(nova)
	var p: Vector3 = game.player.global_position
	story.add_coins(MOEDAS_RODADA, p + Vector3.UP * 3.2)
	Fx.confetti(game, p + Vector3.UP * 2.5, 36, 3.5)
	game.banner("Achou todo mundo!", "Fale com o Ossinho na praia do cais para brincar de novo.", Color("#ffd23f"), 4.0)
	_mostrar_cartao(nova)
	story.save()


## Para onde a seta aponta: o escondido mais perto, depois de um tempo sem achar ninguém.
func alvo_da_dica() -> Vector3:
	if estado != Estado.BUSCANDO or _sem_achar < tempo_da_dica():
		return Vector3.INF
	var p: Vector3 = game.player.global_position
	var melhor := Vector3.INF
	for h in escondidos:
		if is_instance_valid(h) and not h.has_meta("achado"):
			if melhor == Vector3.INF or h.global_position.distance_to(p) < melhor.distance_to(p):
				melhor = h.global_position
	return melhor + Vector3.UP * 1.5 if melhor != Vector3.INF else melhor


func tempo_da_dica() -> float:
	if dica_teste >= 0.0:
		return dica_teste
	return DICA_FACIL if Ajustes.facil else DICA


func texto_objetivo() -> String:
	return "Ache os amigos escondidos %s (%d de %d)" % [area.get("nome", ""), achados, QUANTOS]


## A campanha guarda as rodadas e as figurinhas.
func dados_salvos() -> Dictionary:
	return {"rodadas": rodadas, "figurinhas": figurinhas.duplicate()}


func carregar(dados: Dictionary) -> void:
	rodadas = int(dados.get("rodadas", 0))
	figurinhas.clear()
	for id in dados.get("figurinhas", []):
		if FIGURINHAS.any(func(f: Dictionary) -> bool: return f.id == String(id)):
			figurinhas.append(String(id))


func _vibrar() -> void:
	if not Ajustes.vibracao:
		return
	for d in Input.get_connected_joypads():
		Input.start_joy_vibration(d, 0.4, 0.7, 0.25)


# --- os lugares --------------------------------------------------------------------

## Lugares para se esconder na região: atrás das coisas (do lado de longe do meio), com chão firme fora d'água e
## espaço livre para o amigo sentado, espalhados. Devolve [{pos, olhar}] já sorteados.
func lugares_para(a: Dictionary) -> Array:
	var ilha: Node = game.island
	var candidatos := []
	var meio := Vector3(a.centro.x, 0, a.centro.y)
	for caminho: String in a.cobertura:
		var pai := ilha.get_node_or_null(caminho)
		if pai == null:
			continue
		for coisa in pai.get_children():
			if not coisa is Node3D:
				continue
			if caminho == "Morro" and not (String(coisa.name).begins_with("Tree") or String(coisa.name).begins_with("Rock")):
				continue
			if caminho == "Pasto" and String(coisa.name).begins_with("Cerca"):
				continue
			var caixa := _caixa(coisa)
			if caixa.size == Vector3.ZERO or caixa.size.y < 0.9:
				continue
			var c := caixa.get_center()
			if Vector2(c.x - meio.x, c.z - meio.z).length() > a.raio:
				continue
			var fora := Vector3(c.x - meio.x, 0, c.z - meio.z)
			for lado in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
				if fora.length() > 2.0 and lado.dot(fora.normalized()) < 0.2:
					continue
				var meia := absf(lado.x) * caixa.size.x * 0.5 + absf(lado.z) * caixa.size.z * 0.5
				var p: Vector3 = Vector3(c.x, 0, c.z) + lado * (meia + 0.9)
				var chao := _chao_livre(p, caixa)
				if chao != Vector3.INF:
					candidatos.append({"pos": chao, "olhar": -lado})
	candidatos.shuffle()
	var escolhidos := []
	var longe: float = a.longe
	for tentativa in 3:
		for c: Dictionary in candidatos:
			if escolhidos.size() >= QUANTOS:
				break
			if escolhidos.all(func(e: Dictionary) -> bool: return (e.pos as Vector3).distance_to(c.pos) >= longe):
				escolhidos.append(c)
		longe *= 0.6
	return escolhidos


func _caixa(no: Node) -> AABB:
	var caixa := AABB()
	var primeiro := true
	var malhas := no.find_children("*", "MeshInstance3D", true, false)
	if no is MeshInstance3D:
		malhas.append(no)
	for mi: MeshInstance3D in malhas:
		var a: AABB = mi.global_transform * mi.get_aabb()
		caixa = a if primeiro else caixa.merge(a)
		primeiro = false
	return caixa


## O chão no ponto (fora d'água, perto do pé da coisa) e espaço livre para um amigo sentado; senão, INF.
func _chao_livre(p: Vector3, coisa: AABB) -> Vector3:
	var espaco := get_world_3d().direct_space_state
	var raio := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 40.0, p + Vector3.DOWN * 40.0, 1)
	var hit := espaco.intersect_ray(raio)
	if hit.is_empty() or (hit.normal as Vector3).y < 0.8:
		return Vector3.INF
	var chao: Vector3 = hit.position
	if chao.y < -0.2 or chao.y > coisa.position.y + 1.5:
		return Vector3.INF
	var forma := CapsuleShape3D.new()
	forma.radius = 0.45
	forma.height = 1.4
	var consulta := PhysicsShapeQueryParameters3D.new()
	consulta.shape = forma
	consulta.transform = Transform3D(Basis(), chao + Vector3.UP * 1.1)
	consulta.collision_mask = 1
	if not espaco.intersect_shape(consulta, 1).is_empty():
		return Vector3.INF
	return chao


# --- a tela ------------------------------------------------------------------------

func _montar_tela() -> void:
	hud = Control.new()
	hud.name = "EscondeEsconde"
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.visible = false
	var camada: CanvasLayer = game.ui_layer
	camada.add_child(hud)
	# O número da contagem fica por cima do escurecer; o resto, embaixo dele e dos menus.
	camada.move_child(hud, (game.fade as Node).get_index())
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.anchor_left = 0.5
	fila.anchor_right = 0.5
	fila.offset_top = 18
	fila.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hud.add_child(fila)
	for i in QUANTOS:
		var ic := MenuIcon.new("esconde", MenuKit.ICON_COLORS.esconde, 46)
		fila.add_child(ic)
		_icones.append(ic)
	var vao := Control.new()
	vao.custom_minimum_size = Vector2(14, 0)
	fila.add_child(vao)
	termometro = MenuIcon.new("quente", Color("#4aa8ff"), 58)
	termometro.pivot_offset = Vector2(29, 29)
	fila.add_child(termometro)
	numero = Label.new()
	numero.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	numero.grow_horizontal = Control.GROW_DIRECTION_BOTH
	numero.grow_vertical = Control.GROW_DIRECTION_BOTH
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numero.add_theme_font_size_override("font_size", 120)
	numero.add_theme_color_override("font_color", MenuKit.GOLD)
	numero.add_theme_constant_override("outline_size", 18)
	numero.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.25))
	numero.visible = false
	camada.add_child(numero)
	cartao = PanelContainer.new()
	cartao.add_theme_stylebox_override("panel", MenuKit.panel_style())
	cartao.anchor_left = 1.0
	cartao.anchor_right = 1.0
	cartao.offset_top = 250
	cartao.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	cartao.visible = false
	hud.add_child(cartao)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 10)
	cartao.add_child(caixa)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 18)
	caixa.add_child(topo)
	_retrato = RetratoAmigo.new(Vector2(190, 220))
	topo.add_child(_retrato)
	var lado := VBoxContainer.new()
	lado.alignment = BoxContainer.ALIGNMENT_CENTER
	lado.add_theme_constant_override("separation", 6)
	lado.custom_minimum_size = Vector2(240, 0)
	topo.add_child(lado)
	_cartao_titulo = Label.new()
	_cartao_titulo.add_theme_font_size_override("font_size", 26)
	_cartao_titulo.add_theme_color_override("font_color", MenuKit.GOLD)
	lado.add_child(_cartao_titulo)
	cartao_nome = Label.new()
	cartao_nome.add_theme_font_size_override("font_size", 34)
	lado.add_child(cartao_nome)
	_cartao_moedas = Label.new()
	_cartao_moedas.add_theme_font_size_override("font_size", 22)
	_cartao_moedas.add_theme_color_override("font_color", MenuKit.GOLD)
	lado.add_child(_cartao_moedas)
	var tira := HBoxContainer.new()
	tira.alignment = BoxContainer.ALIGNMENT_CENTER
	tira.add_theme_constant_override("separation", 8)
	caixa.add_child(tira)
	for f: Dictionary in FIGURINHAS:
		var b := Pescaria.Bolinha.new()
		b.cor = f.cor
		tira.add_child(b)
		_tira.append(b)


func _mostrar_cartao(nova: String) -> void:
	var id: String = nova
	if id == "":
		id = String(escondidos[0].get_meta("tipo")) if not escondidos.is_empty() else String(FIGURINHAS[0].id)
	var spec: Dictionary = FIGURINHAS.filter(func(f: Dictionary) -> bool: return f.id == id)[0]
	_cartao_titulo.text = "Figurinha nova!" if nova != "" else "Achou todo mundo!"
	cartao_nome.text = spec.nome
	_cartao_moedas.text = "+%d moedas" % (MOEDAS_RODADA + MOEDAS_ACHOU * QUANTOS)
	for i in FIGURINHAS.size():
		_tira[i].pego = FIGURINHAS[i].id in figurinhas
		_tira[i].destaque = FIGURINHAS[i].id == nova
		_tira[i].queue_redraw()
	_retrato.mostrar(id)
	cartao.reset_size()
	cartao.offset_right = -24
	cartao.offset_left = -24 - cartao.get_combined_minimum_size().x
	cartao.show()
	_cartao_tempo = 0.0


## O amigo da figurinha: o modelo de verdade num mundinho próprio, comemorando.
class RetratoAmigo:
	extends SubViewportContainer
	var _viewport: SubViewport
	var _camera: Camera3D
	var _modelo: Node3D

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
		env.background_color = Color("#ffd9a8")
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.95, 0.92, 1.0)
		env.ambient_light_energy = 0.8
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		mundo.environment = env
		_viewport.add_child(mundo)
		var sol := DirectionalLight3D.new()
		sol.rotation_degrees = Vector3(-35, 30, 0)
		sol.light_energy = 1.1
		_viewport.add_child(sol)
		_camera = Camera3D.new()
		_camera.fov = 30.0
		_viewport.add_child(_camera)
		_camera.position = Vector3(0, 1.25, 5.4)
		_camera.rotation.x = -0.02

	func mostrar(tipo: String) -> void:
		if is_instance_valid(_modelo):
			_modelo.queue_free()
		_modelo = load(SkeletonEnemy.model_path(tipo)).instantiate()
		_modelo.rotation.y = 0.35
		_viewport.add_child(_modelo)
		var pele: String = SkeletonEnemy.TYPES.get(tipo, {}).get("skin", "")
		if pele != "":
			var tex: Texture2D = load(pele)
			for mi in _modelo.find_children("*", "MeshInstance3D", true, false):
				var mesh: Mesh = mi.mesh
				for i in mesh.get_surface_count():
					var mat := mesh.surface_get_material(i)
					if mat is StandardMaterial3D:
						var copia: StandardMaterial3D = mat.duplicate()
						copia.albedo_texture = tex
						mi.set_surface_override_material(i, copia)
		var ap := AnimUtil.make_player(_modelo, ["geral", "festa"])
		ap.play(&"festa/Cheering")
