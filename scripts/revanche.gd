class_name Revanche
extends Node3D
## Revanche dos guardiões (item 9 da lista de melhorias, 2026-11-10). Só no pós-jogo, no gramado do cemitério do
## Morro, ao lado da Festa sem fim: um quadro de madeira com os seis guardiões (as figurinhas do álbum) e, em cima de
## cada um, o troféu da melhor revanche (bronze com 1 estrela, prata com 2, ouro com 3). Na frente, um círculo
## dourado; nele, B abre a escolha (o Painel, com os seis cartões, as estrelas e o melhor tempo). Escolhido, o
## guardião de verdade (a mesma classe da história, com a vida do Modo Fácil quando ligado) sobe no meio do
## gramado, com a barra de vida, e o relógio corre no alto. Vencer dá estrelas pelo tempo (3 até o tempo do guardião,
## 2 até 1,6 vez, 1 depois), moedas (10 mais 10 por estrela) e o troféu; ficar tonto encerra ("Quase! Tenta de
## novo."). Com os seis no ouro, o quadro ganha o troféu grandão. A campanha guarda a melhor de cada um.

## Guardiões na ordem do quadro (região da Story) e o tempo das 3 estrelas, em segundos.
const ORDEM := ["oeste", "leste", "clareira", "ventos", "vila", "cemiterio"]
const TEMPO_3 := {"oeste": 45.0, "leste": 45.0, "clareira": 55.0, "ventos": 60.0, "vila": 60.0, "cemiterio": 90.0}
const TEMPO_2 := 1.6
const CORES := {1: Color("#c98a4f"), 2: Color("#d6dce6"), 3: Color("#ffd23f")}

enum Estado { PARADO, LUTANDO }

var game: Node
var story: Story
var estado := Estado.PARADO
## Melhor de cada região: {"estrelas": n, "tempo": s}.
var melhores := {}
var regiao := ""
var guardiao: Boss
var tempo := 0.0
## O resultado da última luta (os testes olham): estrelas (0 se perdeu) e tempo.
var ultima := {}
var _ativo := false
var _centro := Vector3.ZERO
var _quadro: Node3D
var _circulo: MeshInstance3D
var _trofeus := {}
var _trofeu_grande: Node3D
var _chamados: Array[SkeletonEnemy] = []
## As três estrelas grandes do resultado, no meio da tela (os testes olham).
var estrelas_hud: HBoxContainer


func _ready() -> void:
	game.player.dizzy_started.connect(func() -> void:
		if estado == Estado.LUTANDO:
			_perdeu())
	estrelas_hud = HBoxContainer.new()
	estrelas_hud.alignment = BoxContainer.ALIGNMENT_CENTER
	estrelas_hud.add_theme_constant_override("separation", 16)
	estrelas_hud.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	estrelas_hud.grow_horizontal = Control.GROW_DIRECTION_BOTH
	estrelas_hud.grow_vertical = Control.GROW_DIRECTION_BOTH
	estrelas_hud.offset_top = 40
	estrelas_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	estrelas_hud.visible = false
	for k in 3:
		var e := MenuIcon.new("estrela", MenuKit.GOLD, 96)
		e.pivot_offset = Vector2(48, 48)
		estrelas_hud.add_child(e)
	var camada: CanvasLayer = game.ui_layer
	camada.add_child(estrelas_hud)
	camada.move_child(estrelas_hud, (game.fade as Node).get_index())


## As estrelas ganhas aparecem uma a uma, pulando; as que faltam ficam apagadas. Somem em 3,5 s.
func _mostrar_estrelas(n: int) -> void:
	estrelas_hud.show()
	var tw := estrelas_hud.create_tween()
	for k in 3:
		var e := estrelas_hud.get_child(k) as MenuIcon
		e.modulate = Color(0.3, 0.3, 0.4) if k >= n else Color.WHITE
		e.scale = Vector2.ZERO
		tw.tween_property(e, "scale", Vector2.ONE * (1.0 if k < n else 0.8), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if k < n:
			tw.tween_callback(Sfx.play.bind(game, "estrelinha", -4.0, 0.0))
	tw.tween_interval(2.6)
	tw.tween_callback(estrelas_hud.hide)


func _process(delta: float) -> void:
	var fim := story != null and story.stage == "fim"
	if fim != _ativo:
		_ativar(fim)
	if estado == Estado.LUTANDO and game.menu_state == "":
		tempo += delta


func _ativar(on: bool) -> void:
	_ativo = on
	if not on:
		if _quadro:
			_quadro.queue_free()
			_circulo.queue_free()
			_quadro = null
		return
	_centro = story.defenses.cemiterio.center
	_montar_quadro()


# --- o quadro e o círculo --------------------------------------------------------

func ponto_do_circulo() -> Vector3:
	return game._ground_point(_centro + Vector3(-6.5, 0, -5.0))


func _montar_quadro() -> void:
	var base: Vector3 = game._ground_point(_centro + Vector3(-6.5, 0, -8.6))
	_quadro = Node3D.new()
	_quadro.name = "QuadroDaRevanche"
	add_child(_quadro)
	_quadro.global_position = base
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color("#9c6b3f")
	madeira.roughness = 0.85
	for x in [-2.0, 2.0]:
		var pe := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(0.22, 3.6, 0.22)
		pe.mesh = caixa
		pe.material_override = madeira
		pe.position = Vector3(x, 1.8, 0)
		_quadro.add_child(pe)
	var tabua := MeshInstance3D.new()
	var placa := BoxMesh.new()
	placa.size = Vector3(4.6, 2.5, 0.16)
	tabua.mesh = placa
	tabua.material_override = madeira
	tabua.position = Vector3(0, 2.25, 0)
	_quadro.add_child(tabua)
	var titulo := Label3D.new()
	titulo.text = "REVANCHE"
	titulo.font_size = 72
	titulo.outline_size = 14
	titulo.outline_modulate = Color(0.15, 0.08, 0.25)
	titulo.modulate = Color("#ffd23f")
	titulo.pixel_size = 0.008
	titulo.position = Vector3(0, 3.85, 0.1)
	_quadro.add_child(titulo)
	var corpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var cx := BoxShape3D.new()
	cx.size = Vector3(4.6, 3.6, 0.3)
	forma.shape = cx
	forma.position.y = 1.8
	corpo.add_child(forma)
	_quadro.add_child(corpo)
	for i in ORDEM.size():
		var id: String = ORDEM[i]
		var pos := Vector3(-1.45 + (i % 3) * 1.45, 2.85 - (i / 3) * 1.15, 0.09)
		var foto := Sprite3D.new()
		foto.texture = Album._imagem("guardiao_" + id)
		foto.pixel_size = 0.0032
		foto.position = pos
		_quadro.add_child(foto)
		var trofeu := taca(0.45)
		trofeu.position = pos + Vector3(0.42, -0.42, 0.05)
		_quadro.add_child(trofeu)
		_trofeus[id] = trofeu
	_trofeu_grande = taca(1.1)
	_trofeu_grande.position = Vector3(0, 3.95, 0.25)
	_quadro.add_child(_trofeu_grande)
	_circulo = MeshInstance3D.new()
	var anel := TorusMesh.new()
	anel.inner_radius = 1.4
	anel.outer_radius = 1.6
	anel.rings = 40
	anel.ring_segments = 6
	_circulo.mesh = anel
	_circulo.material_override = Fx.glow_material(Color("#ff9d7a"), 1.4)
	_circulo.scale = Vector3(1, 0.12, 1)
	add_child(_circulo)
	_circulo.global_position = ponto_do_circulo() + Vector3.UP * 0.04
	atualizar_trofeus()


## Taça de troféu: copo, alças, haste e base (a cor muda com as estrelas).
static func taca(tamanho: float) -> Node3D:
	var t := Node3D.new()
	var copo := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.16
	cil.bottom_radius = 0.09
	cil.height = 0.2
	copo.mesh = cil
	copo.position.y = 0.28
	t.add_child(copo)
	var haste := MeshInstance3D.new()
	var h := CylinderMesh.new()
	h.top_radius = 0.03
	h.bottom_radius = 0.03
	h.height = 0.14
	haste.mesh = h
	haste.position.y = 0.12
	t.add_child(haste)
	var base := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.22, 0.06, 0.12)
	base.mesh = b
	base.position.y = 0.03
	t.add_child(base)
	for lado in [-1.0, 1.0]:
		var alca := MeshInstance3D.new()
		var toro := TorusMesh.new()
		toro.inner_radius = 0.035
		toro.outer_radius = 0.06
		alca.mesh = toro
		alca.rotation.x = PI / 2.0
		alca.position = Vector3(0.17 * lado, 0.3, 0)
		t.add_child(alca)
	t.scale = Vector3.ONE * tamanho * 2.0
	return t


func atualizar_trofeus() -> void:
	if _quadro == null:
		return
	var ouros := 0
	for id in ORDEM:
		var n: int = int(melhores.get(id, {}).get("estrelas", 0))
		var taca: Node3D = _trofeus[id]
		taca.visible = n > 0
		if n > 0:
			_pintar(taca, CORES[n])
		if n >= 3:
			ouros += 1
	_trofeu_grande.visible = ouros >= ORDEM.size()
	_pintar(_trofeu_grande, CORES[3])


static func _pintar(t: Node3D, cor: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	mat.metallic = 0.8
	mat.roughness = 0.3
	for m: MeshInstance3D in t.find_children("*", "MeshInstance3D", true, false):
		m.material_override = mat


# --- começar, vencer e perder ----------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not _ativo or game.menu_state != "" or not event.is_action_pressed("interagir"):
		return
	if pode_comecar():
		game.open_menu("revanche")
		get_viewport().set_input_as_handled()


func rodando() -> bool:
	return estado == Estado.LUTANDO


func pode_comecar() -> bool:
	if not _ativo or estado != Estado.PARADO or game.in_combat():
		return false
	var p: Player = game.player
	var c := ponto_do_circulo()
	return not p.dizzy and not p.in_vehicle and not p.parked and not p.using_phone \
			and Vector2(p.global_position.x - c.x, p.global_position.z - c.z).length() < 1.9 and absf(p.global_position.y - c.y) < 2.0


func dica(botao: String) -> String:
	if pode_comecar():
		return "Aperte %s para escolher a revanche" % botao
	return ""


func comecar(id: String) -> void:
	if estado != Estado.PARADO:
		return
	regiao = id
	estado = Estado.LUTANDO
	tempo = 0.0
	ultima = {}
	var p: Player = game.player
	var de := _centro + Vector3(0, 0, 9.0)
	p.global_position = game._ground_point(de) + Vector3.UP * 0.3
	p.velocity = Vector3.ZERO
	p.set_yaw(atan2(0.0, 1.0))
	p.visual.rotation.y = PI
	var script: GDScript = Story.GUARDIANS[Album.GUARDIOES[id].guardiao]
	guardiao = script.new()
	guardiao.arena_center = _centro
	guardiao.arena_radius = story.defenses.cemiterio.radius * 0.7
	guardiao.defeated.connect(func(_b: Boss) -> void: _venceu())
	guardiao.summon_requested.connect(func(tipo: String, pos: Vector3) -> void:
		var e: SkeletonEnemy = game.spawn_wave_enemy(tipo, pos)
		_chamados.append(e))
	game.add_boss(guardiao, game._ground_point(_centro + Vector3(0, 0, 4.5)))
	game.show_guardian(guardiao)
	Sfx.play(game, "alerta", 0.0, 0.0)


func hud_text() -> String:
	var nome: String = Album.GUARDIOES.get(regiao, {}).get("nome", "")
	return "Revanche: %s · %s" % [nome, relogio(tempo)]


static func relogio(s: float) -> String:
	return "%d:%02d" % [int(s) / 60, int(s) % 60]


static func estrelas_para(id: String, s: float) -> int:
	var par: float = TEMPO_3.get(id, 60.0)
	return 3 if s <= par else (2 if s <= par * TEMPO_2 else 1)


func _venceu() -> void:
	if estado != Estado.LUTANDO:
		return
	estado = Estado.PARADO
	var n := estrelas_para(regiao, tempo)
	ultima = {"estrelas": n, "tempo": tempo}
	var antes: Dictionary = melhores.get(regiao, {})
	if n > int(antes.get("estrelas", 0)) or (n == int(antes.get("estrelas", 0)) and tempo < float(antes.get("tempo", INF))):
		melhores[regiao] = {"estrelas": n, "tempo": tempo}
	story.add_coins(10 + 10 * n, game.player.global_position + Vector3.UP * 3.0)
	var palavras := ["", "1 estrela", "2 estrelas", "3 estrelas!"]
	game.banner("Revanche vencida!", "%s em %s" % [palavras[n], relogio(tempo)], CORES[n], 4.0)
	_mostrar_estrelas(n)
	_limpar(4.5)
	atualizar_trofeus()
	story.save()


func _perdeu() -> void:
	estado = Estado.PARADO
	ultima = {"estrelas": 0, "tempo": tempo}
	game.show_message("Quase! Tenta de novo.", Color("#ffe9a8"), 2.4)
	_limpar(0.0)


## Tira o guardião (o Mestre fica sentado: sai alguns segundos depois) e os esqueletos que ele chamou.
func _limpar(depois: float) -> void:
	game.hide_guardian()
	for e in _chamados:
		if is_instance_valid(e) and not e.derrotado:
			e.sink_away()
	_chamados.clear()
	var g := guardiao
	guardiao = null
	if not is_instance_valid(g):
		return
	if depois <= 0.0:
		Fx.confetti(game, g.global_position + Vector3.UP * 2.0, 40, 4.0)
		g.queue_free()
		return
	get_tree().create_timer(depois, false).timeout.connect(func() -> void:
		if is_instance_valid(g) and g is BossMestre:
			Fx.confetti(game, g.global_position + Vector3.UP * 2.0, 40, 4.0)
			g.queue_free())


func dados_salvos() -> Dictionary:
	return melhores.duplicate(true)


func carregar(dados: Dictionary) -> void:
	melhores.clear()
	for id in dados:
		if String(id) in ORDEM:
			var d: Dictionary = dados[id]
			melhores[String(id)] = {"estrelas": clampi(int(d.get("estrelas", 0)), 0, 3), "tempo": float(d.get("tempo", 0.0))}
	atualizar_trofeus()


## A escolha da revanche: os seis guardiões em cartões grandes (a figurinha, o nome, as três estrelas da melhor e o
## melhor tempo). A escolhe; B volta.
class Painel:
	extends CenterContainer
	signal escolheu(id: String)
	signal fechou
	var cartoes := {}
	var _sfx: Node
	var _revanche: Revanche

	func montar(sfx_parent: Node, r: Revanche) -> void:
		_sfx = sfx_parent
		_revanche = r
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var painel := PanelContainer.new()
		painel.add_theme_stylebox_override("panel", MenuKit.panel_style())
		add_child(painel)
		var caixa := VBoxContainer.new()
		caixa.add_theme_constant_override("separation", 12)
		painel.add_child(caixa)
		var topo := HBoxContainer.new()
		topo.alignment = BoxContainer.ALIGNMENT_CENTER
		topo.add_theme_constant_override("separation", 12)
		caixa.add_child(topo)
		topo.add_child(MenuIcon.new("mestre", MenuKit.ICON_COLORS.mestre, 44))
		var titulo := Label.new()
		titulo.text = "Revanche dos guardiões"
		titulo.add_theme_font_size_override("font_size", 32)
		titulo.add_theme_color_override("font_color", MenuKit.GOLD)
		topo.add_child(titulo)
		var grade := GridContainer.new()
		grade.columns = 3
		grade.add_theme_constant_override("h_separation", 12)
		grade.add_theme_constant_override("v_separation", 12)
		caixa.add_child(grade)
		for id in ORDEM:
			var b := Button.new()
			b.custom_minimum_size = Vector2(250, 220)
			var normal := MenuKit.box(MenuKit.BUTTON, 16)
			b.add_theme_stylebox_override("normal", normal)
			b.add_theme_stylebox_override("hover", MenuKit.box(MenuKit.BUTTON_HOVER, 16))
			b.add_theme_stylebox_override("pressed", normal)
			b.add_theme_stylebox_override("focus", MenuKit.focus_style(16, 5))
			MenuKit.focus_on_mouse_move(b)
			b.focus_entered.connect(func() -> void: Sfx.play(_sfx, "ui_mover", 0.0, 0.0))
			b.pressed.connect(func() -> void:
				Sfx.play(_sfx, "ui_ok", 0.0, 0.0)
				escolheu.emit(id))
			var dentro := VBoxContainer.new()
			dentro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			dentro.offset_top = 6
			dentro.offset_bottom = -8
			dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dentro.add_theme_constant_override("separation", 2)
			b.add_child(dentro)
			var foto := TextureRect.new()
			foto.texture = Album._imagem("guardiao_" + id)
			foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			foto.size_flags_vertical = Control.SIZE_EXPAND_FILL
			foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dentro.add_child(foto)
			var nome := Label.new()
			nome.text = Album.GUARDIOES[id].nome
			nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nome.add_theme_font_size_override("font_size", 20)
			nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dentro.add_child(nome)
			var linha := HBoxContainer.new()
			linha.alignment = BoxContainer.ALIGNMENT_CENTER
			linha.add_theme_constant_override("separation", 4)
			linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dentro.add_child(linha)
			var estrelas: Array[MenuIcon] = []
			for k in 3:
				var e := MenuIcon.new("estrela", MenuKit.GOLD, 28)
				linha.add_child(e)
				estrelas.append(e)
			var melhor := Label.new()
			melhor.add_theme_font_size_override("font_size", 16)
			melhor.add_theme_color_override("font_color", Color("#8ff3ff"))
			melhor.mouse_filter = Control.MOUSE_FILTER_IGNORE
			linha.add_child(melhor)
			grade.add_child(b)
			cartoes[id] = {"botao": b, "estrelas": estrelas, "melhor": melhor}
		var voltar := MenuKit.icon_button("Voltar", "voltar", sfx_parent, 260)
		voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		voltar.pressed.connect(fechar)
		caixa.add_child(voltar)

	func abrir() -> void:
		for id in ORDEM:
			var c: Dictionary = cartoes[id]
			var m: Dictionary = _revanche.melhores.get(id, {})
			var n := int(m.get("estrelas", 0))
			for k in 3:
				(c.estrelas[k] as MenuIcon).modulate = Color.WHITE if k < n else Color(0.3, 0.3, 0.4)
			(c.melhor as Label).text = " " + Revanche.relogio(float(m.get("tempo", 0.0))) if n > 0 else ""
		show()
		(cartoes[ORDEM[0]].botao as Button).grab_focus.call_deferred()

	func fechar() -> void:
		if not visible:
			return
		Sfx.play(_sfx, "ui_ok", 0.0, 0.0)
		hide()
		fechou.emit()
