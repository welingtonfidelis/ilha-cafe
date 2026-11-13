class_name PainelAlbum
extends CenterContainer
## Tela do álbum de figurinhas (item 7 da lista de melhorias, 2026-11-10), aberta pela pausa da ilha. No alto, o
## título e quantas já achou no álbum todo; as abas das cinco páginas (Guardiões, Turma, Esconde-esconde, Peixes e
## Bilhetes), cada uma com o ícone e a conta; no meio, as figurinhas da página (a achada aparece colorida com o nome;
## a que falta, só a sombra com "?"); embaixo, o nome e o texto da figurinha marcada (no bilhete, o bilhete inteiro).
## O direcional anda pelas figurinhas e, para cima, chega nas abas: marcar uma aba já troca a página. B volta.

signal fechou

const COLUNAS := 7
const LADO := Vector2(124, 132)

var game: Node
## A página aberta e as peças (os testes olham).
var pagina := "guardioes"
var abas := {}
var cartas: Array[Button] = []
var titulo_conta: Label
var descricao_nome: Label
var descricao_texto: Label
var _grade: GridContainer
var _sfx: Node
var _figuras: Array = []


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
	topo.alignment = BoxContainer.ALIGNMENT_CENTER
	topo.add_theme_constant_override("separation", 12)
	caixa.add_child(topo)
	topo.add_child(MenuIcon.new("album", MenuKit.ICON_COLORS.album, 44))
	var titulo := Label.new()
	titulo.text = "Álbum de figurinhas"
	titulo.add_theme_font_size_override("font_size", 32)
	titulo.add_theme_color_override("font_color", MenuKit.GOLD)
	topo.add_child(titulo)
	titulo_conta = Label.new()
	titulo_conta.add_theme_font_size_override("font_size", 22)
	titulo_conta.add_theme_color_override("font_color", Color("#8ff3ff"))
	topo.add_child(titulo_conta)
	var fila_abas := HBoxContainer.new()
	fila_abas.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_abas.add_theme_constant_override("separation", 8)
	caixa.add_child(fila_abas)
	for spec in Album.PAGINAS:
		var b := MenuKit.icon_button(spec[1], spec[2], sfx_parent, 186)
		b.add_theme_font_size_override("font_size", 18)
		b.custom_minimum_size.y = 52
		b.focus_entered.connect(_abrir_pagina.bind(spec[0]))
		b.pressed.connect(func() -> void:
			if not cartas.is_empty():
				cartas[0].grab_focus())
		fila_abas.add_child(b)
		abas[spec[0]] = b
	_grade = GridContainer.new()
	_grade.columns = COLUNAS
	_grade.add_theme_constant_override("h_separation", 8)
	_grade.add_theme_constant_override("v_separation", 8)
	_grade.custom_minimum_size = Vector2(COLUNAS * (LADO.x + 8), 3 * (LADO.y + 8))
	caixa.add_child(_grade)
	var desc := PanelContainer.new()
	var estilo := MenuKit.box(Color("#2a2340"), 14)
	estilo.set_content_margin_all(10)
	desc.add_theme_stylebox_override("panel", estilo)
	desc.custom_minimum_size = Vector2(0, 82)
	caixa.add_child(desc)
	var linhas := VBoxContainer.new()
	linhas.add_theme_constant_override("separation", 2)
	desc.add_child(linhas)
	descricao_nome = Label.new()
	descricao_nome.add_theme_font_size_override("font_size", 22)
	descricao_nome.add_theme_color_override("font_color", MenuKit.GOLD)
	linhas.add_child(descricao_nome)
	descricao_texto = Label.new()
	descricao_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descricao_texto.custom_minimum_size = Vector2(COLUNAS * (LADO.x + 8) - 20, 0)
	descricao_texto.add_theme_font_size_override("font_size", 18)
	linhas.add_child(descricao_texto)


func abrir() -> void:
	var total := Album.contagem(game)
	titulo_conta.text = "%d de %d" % [total.x, total.y]
	for spec in Album.PAGINAS:
		var conta := Album.contagem(game, spec[0])
		(abas[spec[0]] as Button).text = "%s %d/%d" % [_curto(spec[1]), conta.x, conta.y]
	show()
	_abrir_pagina(pagina, true)
	(abas[pagina] as Button).grab_focus.call_deferred()


func fechar() -> void:
	if not visible:
		return
	Sfx.play(_sfx, "ui_ok", 0.0, 0.0)
	hide()
	fechou.emit()


static func _curto(nome: String) -> String:
	return "Esconde" if nome == "Esconde-esconde" else nome


func _abrir_pagina(chave: String, sempre := false) -> void:
	if chave == pagina and not sempre and not cartas.is_empty():
		return
	pagina = chave
	for c in _grade.get_children():
		c.queue_free()
	cartas.clear()
	_figuras = Album.figurinhas(chave, game)
	for i in _figuras.size():
		var f: Dictionary = _figuras[i]
		var b := _carta(f)
		b.focus_entered.connect(_descrever.bind(i))
		_grade.add_child(b)
		cartas.append(b)
	# Para cima, da primeira fileira, volta para a aba da página.
	for i in mini(COLUNAS, cartas.size()):
		cartas[i].focus_neighbor_top = cartas[i].get_path_to(abas[chave])
	(abas[chave] as Button).focus_neighbor_bottom = (abas[chave] as Button).get_path_to(cartas[0]) if not cartas.is_empty() else NodePath()
	_descrever(-1)


func _descrever(i: int) -> void:
	if i < 0 or i >= _figuras.size():
		var conta := Album.contagem(game, pagina)
		descricao_nome.text = "%d de %d nesta página" % [conta.x, conta.y]
		descricao_texto.text = "Mexa o direcional para ver cada figurinha."
		return
	var f: Dictionary = _figuras[i]
	if f.achada:
		descricao_nome.text = f.nome
		descricao_texto.text = f.texto
	else:
		descricao_nome.text = "???"
		descricao_texto.text = "Ainda falta achar esta figurinha."


## Uma figurinha: o retrato (ou o desenho do bilhete) num cartão colorido com o nome; a que falta, apagada com "?".
func _carta(f: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = LADO
	b.focus_mode = Control.FOCUS_ALL
	var cor := Color("#3a3358") if f.achada else Color("#24233a")
	if f.get("brilho", false) and f.achada:
		cor = Color("#5a4420")
	var normal := MenuKit.box(cor, 12, MenuKit.GOLD if f.get("brilho", false) and f.achada else Color.TRANSPARENT, 3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", normal)
	b.add_theme_stylebox_override("focus", MenuKit.focus_style(12, 4))
	MenuKit.focus_on_mouse_move(b)
	b.focus_entered.connect(func() -> void: Sfx.play(_sfx, "ui_mover", 0.0, 0.0))
	var dentro := VBoxContainer.new()
	dentro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dentro.offset_top = 4
	dentro.offset_bottom = -4
	dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_theme_constant_override("separation", 0)
	b.add_child(dentro)
	var imagem: Texture2D = f.get("imagem")
	if imagem:
		var tr := TextureRect.new()
		tr.texture = imagem
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not f.achada:
			tr.modulate = Color(0.05, 0.05, 0.1, 0.85)
		dentro.add_child(tr)
	else:
		var centro := CenterContainer.new()
		centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
		centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dentro.add_child(centro)
		var ic := MenuIcon.new(f.get("icone", "bilhete"), MenuKit.ICON_COLORS.get(f.get("icone", "bilhete"), Color.GRAY), 72)
		if not f.achada:
			ic.modulate = Color(0.3, 0.3, 0.4)
		centro.add_child(ic)
	var nome := Label.new()
	nome.text = f.nome if f.achada else "?"
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.clip_text = true
	nome.add_theme_font_size_override("font_size", 15 if f.achada else 24)
	nome.add_theme_color_override("font_color", Color.WHITE if f.achada else Color(1, 1, 1, 0.5))
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_child(nome)
	return b
