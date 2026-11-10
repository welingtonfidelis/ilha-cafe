class_name PainelAjustes
extends CenterContainer
## Tela de Ajustes (item 1 da lista de melhorias, 2026-11-10), a mesma no menu principal, na pausa da ilha e na
## pausa do Faísca: uma linha por ajuste, com o ícone colorido, o nome, uma barra grossa (música, efeitos e câmera;
## o direcional para os lados muda, para cima e para baixo troca de linha) ou uma chave de Sim e Não (câmera
## invertida, vibração e Modo Fácil), e o Voltar. Cada mudança vale na hora: a música abaixa enquanto se mexe, os efeitos
## tocam um som de amostra e a vibração treme um pouquinho ao ligar. Fechar grava (Ajustes.salvar). Quem abre
## escuta `fechou` e devolve o foco para onde estava; o B ou o Esc de quem abriu chamam `fechar`.

signal fechou

## Chave, nome, ícone e, para as barras, o mínimo e o máximo.
const LINHAS := [
	["musica", "Música", "musica", 0, Ajustes.PASSOS],
	["efeitos", "Efeitos", "som", 0, Ajustes.PASSOS],
	["camera", "Câmera", "camera", Ajustes.CAMERA_MIN, Ajustes.CAMERA_MAX],
	["inverter", "Câmera invertida", "inverter"],
	["vibracao", "Vibração", "vibracao"],
	["facil", "Modo fácil", "facil"],
]

## O controle de cada linha pela chave (HSlider ou CheckButton); os testes mexem por aqui.
var controles := {}
var botao_voltar: Button
var _valores := {}
var _sfx: Node
var _lendo := false


func montar(sfx_parent: Node) -> void:
	_sfx = sfx_parent
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
	topo.add_child(MenuIcon.new("ajustes", MenuKit.ICON_COLORS.ajustes, 44))
	var titulo := Label.new()
	titulo.text = "Ajustes"
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.add_theme_color_override("font_color", MenuKit.GOLD)
	topo.add_child(titulo)
	for spec in LINHAS:
		caixa.add_child(_linha(spec))
	botao_voltar = MenuKit.icon_button("Voltar", "voltar", sfx_parent, 260)
	botao_voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	botao_voltar.pressed.connect(fechar)
	caixa.add_child(botao_voltar)
	# Direcional para cima e para baixo anda pelas linhas, de cima até o Voltar.
	var ordem: Array[Control] = []
	for spec in LINHAS:
		ordem.append(controles[spec[0]])
	ordem.append(botao_voltar)
	for i in ordem.size():
		var c := ordem[i]
		c.focus_neighbor_top = c.get_path_to(ordem[maxi(i - 1, 0)])
		c.focus_neighbor_bottom = c.get_path_to(ordem[mini(i + 1, ordem.size() - 1)])
		if not c is HSlider:
			c.focus_neighbor_left = c.get_path_to(c)
			c.focus_neighbor_right = c.get_path_to(c)


func abrir() -> void:
	_ler()
	show()
	(controles.musica as Control).grab_focus.call_deferred()


func fechar() -> void:
	if not visible:
		return
	Sfx.play(_sfx, "ui_ok", 0.0, 0.0)
	Ajustes.salvar()
	hide()
	fechou.emit()


func _linha(spec: Array) -> PanelContainer:
	var chave: String = spec[0]
	var cor: Color = MenuKit.ICON_COLORS[spec[2]]
	var fundo := PanelContainer.new()
	var estilo := MenuKit.box(MenuKit.BUTTON, 16)
	estilo.content_margin_left = 12
	estilo.content_margin_right = 16
	estilo.content_margin_top = 6
	estilo.content_margin_bottom = 6
	fundo.add_theme_stylebox_override("panel", estilo)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	fundo.add_child(fila)
	fila.add_child(MenuIcon.new(spec[2], cor, 40))
	var nome := Label.new()
	nome.text = spec[1]
	nome.custom_minimum_size = Vector2(210, 0)
	nome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nome.add_theme_font_size_override("font_size", 22)
	fila.add_child(nome)
	var valor := Label.new()
	valor.custom_minimum_size = Vector2(70, 0)
	valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	valor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	valor.add_theme_font_size_override("font_size", 20)
	valor.add_theme_color_override("font_color", MenuKit.GOLD)
	_valores[chave] = valor
	if spec.size() > 3:
		var barra := HSlider.new()
		barra.min_value = spec[3]
		barra.max_value = spec[4]
		barra.step = 1
		barra.custom_minimum_size = Vector2(320, 44)
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		barra.add_theme_icon_override("grabber", _bolinha(34, Color.WHITE))
		barra.add_theme_icon_override("grabber_highlight", _bolinha(34, MenuKit.GOLD))
		var trilho := MenuKit.box(Color("#3b3b58"), 10)
		trilho.content_margin_top = 9
		trilho.content_margin_bottom = 9
		barra.add_theme_stylebox_override("slider", trilho)
		var cheio := MenuKit.box(cor, 10)
		cheio.content_margin_top = 9
		cheio.content_margin_bottom = 9
		barra.add_theme_stylebox_override("grabber_area", cheio)
		barra.add_theme_stylebox_override("grabber_area_highlight", cheio)
		barra.add_theme_stylebox_override("focus", MenuKit.focus_style(14, 4))
		barra.value_changed.connect(_mudou.bind(chave))
		MenuKit.focus_on_mouse_move(barra)
		barra.focus_entered.connect(func() -> void: Sfx.play(_sfx, "ui_mover", 0.0, 0.0))
		fila.add_child(barra)
		controles[chave] = barra
	else:
		var chave_sim := CheckButton.new()
		chave_sim.custom_minimum_size = Vector2(320, 44)
		chave_sim.add_theme_font_size_override("font_size", 20)
		chave_sim.add_theme_stylebox_override("focus", MenuKit.focus_style(14, 4))
		chave_sim.toggled.connect(func(ligado: bool) -> void: _mudou(1.0 if ligado else 0.0, chave))
		MenuKit.focus_on_mouse_move(chave_sim)
		chave_sim.focus_entered.connect(func() -> void: Sfx.play(_sfx, "ui_mover", 0.0, 0.0))
		fila.add_child(chave_sim)
		controles[chave] = chave_sim
	fila.add_child(valor)
	return fundo


## Põe nos controles o que está nos Ajustes (sem tocar os sons de mudar).
func _ler() -> void:
	_lendo = true
	(controles.musica as HSlider).value = Ajustes.musica
	(controles.efeitos as HSlider).value = Ajustes.efeitos
	(controles.camera as HSlider).value = Ajustes.camera
	(controles.inverter as CheckButton).button_pressed = Ajustes.inverter
	(controles.vibracao as CheckButton).button_pressed = Ajustes.vibracao
	(controles.facil as CheckButton).button_pressed = Ajustes.facil
	_lendo = false
	for chave in controles:
		_mostrar(chave)


func _mudou(valor: float, chave: String) -> void:
	match chave:
		"musica":
			Ajustes.musica = int(valor)
			Sfx.aplicar_volumes()
		"efeitos":
			Ajustes.efeitos = int(valor)
			Sfx.aplicar_volumes()
		"camera":
			Ajustes.camera = int(valor)
		"inverter":
			Ajustes.inverter = valor > 0.5
		"vibracao":
			Ajustes.vibracao = valor > 0.5
		"facil":
			Ajustes.facil = valor > 0.5
	_mostrar(chave)
	if _lendo:
		return
	# Amostra: os efeitos tocam no volume novo; a vibração, ligando, treme um pouquinho.
	Sfx.play(_sfx, "ui_ok" if chave == "efeitos" else "ui_mover", 0.0, 0.0)
	if chave == "vibracao" and Ajustes.vibracao:
		for d in Input.get_connected_joypads():
			Input.start_joy_vibration(d, 0.4, 0.6, 0.25)


func _mostrar(chave: String) -> void:
	var rotulo: Label = _valores[chave]
	match chave:
		"musica", "efeitos":
			var v := int((controles[chave] as HSlider).value)
			rotulo.text = "Mudo" if v == 0 else str(v)
		"camera":
			rotulo.text = str(int((controles[chave] as HSlider).value))
		_:
			var ligado := (controles[chave] as CheckButton).button_pressed
			(controles[chave] as CheckButton).text = "Sim" if ligado else "Não"
			rotulo.text = ""


## A bolinha que se arrasta na barra.
static func _bolinha(lado: int, cor: Color) -> ImageTexture:
	var img := Image.create(lado, lado, false, Image.FORMAT_RGBA8)
	var meio := (lado - 1) * 0.5
	for y in lado:
		for x in lado:
			var d := Vector2(x - meio, y - meio).length()
			var a := clampf(meio - d + 0.5, 0.0, 1.0)
			var borda := d > meio - 3.0
			img.set_pixel(x, y, Color(Color("#2b2b40") if borda else cor, a))
	return ImageTexture.create_from_image(img)
