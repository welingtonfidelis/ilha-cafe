class_name PainelRoupas
extends CenterContainer
## Roupinhas (item 11 da lista de melhorias, 2026-11-10): o guarda-roupa da lojinha, aberto pelo botão "Roupinhas" do
## celular. À esquerda, o retrato de quem joga, que já prova o chapéu marcado; à direita, os cartões dos chapéus
## (a figura, o nome e o preço, ou "é seu" / "usando") e das pinturas dos blasters (a silhueta do blaster na cor).
## A compra o chapéu ou a pintura (se der as moedas) e já veste; no que é seu, A veste ou tira. Os cartões "Sem
## chapéu" e "Sem pintura" tiram. B volta para a lojinha.

signal fechou

const LADO := Vector2(118, 132)

var game: Node
var retrato: Portrait
var cartoes := {}
var mensagem: Label
var _moedas: Label
var _nome: Label
var _sfx: Node
var _voltar: Button


func montar(sfx_parent: Node, jogo: Node) -> void:
	_sfx = sfx_parent
	game = jogo
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", MenuKit.panel_style())
	add_child(painel)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 10)
	painel.add_child(caixa)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 12)
	caixa.add_child(topo)
	topo.add_child(MenuIcon.new("presente", MenuKit.ICON_COLORS.presente, 44))
	var titulo := Label.new()
	titulo.text = "Roupinhas"
	titulo.add_theme_font_size_override("font_size", 32)
	titulo.add_theme_color_override("font_color", MenuKit.GOLD)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	topo.add_child(ShopMenu.CoinIcon.new(28.0))
	_moedas = Label.new()
	_moedas.add_theme_font_size_override("font_size", 28)
	_moedas.add_theme_color_override("font_color", Color("#ffe9a8"))
	topo.add_child(_moedas)
	var meio := HBoxContainer.new()
	meio.add_theme_constant_override("separation", 18)
	caixa.add_child(meio)
	var esquerda := VBoxContainer.new()
	esquerda.add_theme_constant_override("separation", 6)
	meio.add_child(esquerda)
	var moldura := Panel.new()
	moldura.custom_minimum_size = Vector2(240, 300)
	moldura.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	moldura.add_theme_stylebox_override("panel", MenuKit.box(Color.WHITE, 14))
	esquerda.add_child(moldura)
	retrato = Portrait.new(moldura.custom_minimum_size)
	moldura.add_child(retrato)
	retrato.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_nome = Label.new()
	_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nome.custom_minimum_size = Vector2(240, 0)
	_nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_nome.add_theme_font_size_override("font_size", 20)
	esquerda.add_child(_nome)
	var direita := VBoxContainer.new()
	direita.add_theme_constant_override("separation", 8)
	meio.add_child(direita)
	direita.add_child(_rotulo("CHAPÉUS"))
	var chapeus := GridContainer.new()
	chapeus.columns = 6
	chapeus.add_theme_constant_override("h_separation", 8)
	chapeus.add_theme_constant_override("v_separation", 8)
	direita.add_child(chapeus)
	chapeus.add_child(_cartao("sem_chapeu"))
	for c: Dictionary in Roupas.CHAPEUS:
		chapeus.add_child(_cartao(c.id))
	direita.add_child(_rotulo("PINTURA DOS BLASTERS"))
	var pinturas := GridContainer.new()
	pinturas.columns = 6
	pinturas.add_theme_constant_override("h_separation", 8)
	direita.add_child(pinturas)
	pinturas.add_child(_cartao("sem_pintura"))
	for c: Dictionary in Roupas.PINTURAS:
		pinturas.add_child(_cartao(c.id))
	mensagem = Label.new()
	mensagem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mensagem.add_theme_font_size_override("font_size", 20)
	mensagem.add_theme_color_override("font_color", Color("#8ff3ff"))
	caixa.add_child(mensagem)
	_voltar = MenuKit.icon_button("Voltar", "voltar", sfx_parent, 260)
	_voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_voltar.pressed.connect(fechar)
	caixa.add_child(_voltar)


func _rotulo(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	return l


func abrir() -> void:
	retrato.show_character(game.player.character_name)
	retrato.vestir(game.player.chapeu)
	mensagem.text = ""
	atualizar()
	show()
	var primeiro: String = game.player.chapeu if game.player.chapeu != "" else "sem_chapeu"
	(cartoes[primeiro].botao as Button).grab_focus.call_deferred()


func fechar() -> void:
	if not visible:
		return
	Sfx.play(_sfx, "ui_ok", 0.0, 0.0)
	hide()
	fechou.emit()


func _tem(id: String) -> bool:
	return id in ["sem_chapeu", "sem_pintura"] or id in game.story.roupas


func _usando(id: String) -> bool:
	var p: Player = game.player
	match id:
		"sem_chapeu":
			return p.chapeu == ""
		"sem_pintura":
			return p.pintura == ""
	return p.chapeu == id or p.pintura == id


func atualizar() -> void:
	_moedas.text = str(game.story.coins)
	for id in cartoes:
		var c: Dictionary = cartoes[id]
		var estado: Label = c.estado
		var moeda: Control = c.moeda
		if _usando(id):
			estado.text = "usando"
			estado.add_theme_color_override("font_color", Color("#c9f7a0"))
			moeda.visible = false
		elif _tem(id):
			estado.text = "é seu"
			estado.add_theme_color_override("font_color", Color("#9fdcff"))
			moeda.visible = false
		else:
			estado.text = str(Roupas.dados(id).preco)
			estado.add_theme_color_override("font_color", Color.WHITE)
			moeda.visible = true
		var borda: StyleBoxFlat = (c.botao as Button).get_theme_stylebox("normal")
		borda.border_color = Color("#c9f7a0") if _usando(id) else Color.TRANSPARENT


func _cartao(id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = LADO
	var normal := MenuKit.box(MenuKit.BUTTON, 14, Color.TRANSPARENT, 3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", normal)
	b.add_theme_stylebox_override("focus", MenuKit.focus_style(14, 4))
	MenuKit.focus_on_mouse_move(b)
	var dentro := VBoxContainer.new()
	dentro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dentro.offset_top = 4
	dentro.offset_bottom = -4
	dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_theme_constant_override("separation", 0)
	b.add_child(dentro)
	var figura := TextureRect.new()
	figura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	figura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	figura.size_flags_vertical = Control.SIZE_EXPAND_FILL
	figura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var spec := Roupas.dados(id)
	if Roupas.e_chapeu(id):
		figura.texture = load("res://assets/ui/roupas/%s.png" % id)
	elif spec.has("cor"):
		figura.texture = load("res://assets/ui/icones/pacoca.png")
		figura.modulate = spec.cor
	dentro.add_child(figura)
	if id in ["sem_chapeu", "sem_pintura"]:
		var x := Label.new()
		x.text = "Sem chapéu" if id == "sem_chapeu" else "Sem pintura"
		x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		x.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		x.size_flags_vertical = Control.SIZE_EXPAND_FILL
		x.add_theme_font_size_override("font_size", 17)
		x.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dentro.remove_child(figura)
		figura.queue_free()
		dentro.add_child(x)
	var nome := Label.new()
	nome.text = spec.get("nome", "")
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.clip_text = true
	nome.add_theme_font_size_override("font_size", 14)
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_child(nome)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_child(linha)
	var moeda := ShopMenu.CoinIcon.new(15.0)
	linha.add_child(moeda)
	var estado := Label.new()
	estado.add_theme_font_size_override("font_size", 16)
	estado.mouse_filter = Control.MOUSE_FILTER_IGNORE
	linha.add_child(estado)
	b.focus_entered.connect(func() -> void:
		Sfx.play(_sfx, "ui_mover", 0.0, 0.0)
		_provar(id))
	b.pressed.connect(escolher.bind(id))
	cartoes[id] = {"botao": b, "estado": estado, "moeda": moeda}
	return b


## Marcar um chapéu já prova no retrato.
func _provar(id: String) -> void:
	if Roupas.e_chapeu(id):
		retrato.vestir(id)
	elif id == "sem_chapeu":
		retrato.vestir("")
	else:
		retrato.vestir(game.player.chapeu)
	var spec := Roupas.dados(id)
	_nome.text = spec.get("nome", "Sem chapéu" if id == "sem_chapeu" else "Sem pintura" if id == "sem_pintura" else "")


## A: compra (se der) e veste; no que é seu, veste ou tira.
func escolher(id: String) -> void:
	var p: Player = game.player
	var story: Story = game.story
	if not _tem(id):
		var preco: int = Roupas.dados(id).preco
		if not story.spend_coins(preco):
			mensagem.text = "Faltam %d moedas!" % (preco - story.coins)
			Sfx.play(_sfx, "sem_municao", 0.0, 0.0)
			return
		story.roupas.append(id)
		Sfx.play(_sfx, "municao", 0.0, 0.0)
		mensagem.text = "Comprou: %s!" % Roupas.dados(id).nome
	else:
		Sfx.play(_sfx, "ui_ok", 0.0, 0.0)
		mensagem.text = ""
	match id:
		"sem_chapeu":
			p.vestir_chapeu("")
		"sem_pintura":
			p.pintar_blasters("")
		_:
			if Roupas.e_chapeu(id):
				p.vestir_chapeu("" if p.chapeu == id and mensagem.text == "" else id)
			else:
				p.pintar_blasters("" if p.pintura == id and mensagem.text == "" else id)
	retrato.vestir(p.chapeu)
	atualizar()
	story.save()
