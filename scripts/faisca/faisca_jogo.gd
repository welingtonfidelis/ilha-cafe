class_name FaiscaJogo
extends Node3D
## "Faísca e o Céu Apagado": o jogo de plataforma do Faísca, que o menu principal separou da ilha (pedido do
## usuário em 2026-11-10: "ficou estranho termos o jogo de tiro contra os esqueletos e dentro dele o jogo de
## plataforma com acesso direto"). Antes era a Parte 2, dentro do jogo da ilha. Cuida de:
## - a abertura, na primeira vez: a nave do Rei Bolotão suga as estrelas do céu, o farol acende e o Faísca sai
##   pulando. O farol fica numa ilhota no mar, à noite, sem a ilha em volta;
## - o hub (HubFarol), as portas e as fases, com a descida do céu e a tela de fim;
## - as estrelinhas, as Estrelas Grandes e os Faisquinhas salvos de cada fase, no save próprio (FaiscaSave);
## - os Faisquinhas morando no farol e os prêmios que eles abrem (PREMIOS: o elevador, o trenzinho e o farolete);
## - a tela de início (quem já tem jogo salvo: continuar, novo jogo ou voltar ao menu principal) e a pausa (Start ou
##   Esc): continuar, sair da fase, os Ajustes (PainelAjustes), novo jogo, voltar ao menu principal e sair do jogo. O
##   novo jogo pede confirmação, como a "Nova campanha" da ilha;
## - o DualSense (nó DualSense com o perfil ControleFaisca): gatilhos, barra de luz, LEDs e as tremidinhas de festa;
## - as moedas (a carteira) e a Máquina de Brindes do farol: as figurinhas da estante e as tintas do Faísca.
## As portas abrem com o total de estrelinhas (cada uma conta uma vez, para sempre).
## Testes: --faisca-jogo (confere, ver teste_faisca_jogo.gd), --faisca-jogo-captura e --faisca-farol-captura (fotos,
## precisam de janela).

const CENA := "res://scenes/faisca.tscn"
const MODOS := ["--faisca-jogo", "--faisca-jogo-captura", "--faisca-farol-captura", "--faisca-brindes-captura"]
## As fases, na ordem das portas, com o andar do farol (0 é o térreo; cada andar é um mundo) e o lado da
## parede em graus. "cena" vazia é porta que abre mas ainda mostra "Em breve". Nomes e números das que
## faltam fazer vêm do mapa da seção 11 do doc e mudam quando cada uma for planejada. A porta do chefe de cada andar
## pede as Estrelas Grandes das fases daquele andar, e a da nave, no topo, pede os três chefes vencidos (item 15 da lista
## do Faísca, 2026-11-13; ver `falta_para`).
const FASES := [
	{"id": "1-1", "nome": "Pulinhos nas Nuvens", "tipo": "ceu", "pede": 0, "andar": 0, "lado": 270,
		"cena": "res://scripts/faisca/fases/fase_1_1.gd", "imagem": "res://assets/faisca/portas/fase_1_1.jpg"},
	{"id": "1-2", "nome": "Túneis do Morro", "tipo": "chao", "pede": 30, "andar": 0, "lado": 90,
		"cena": "res://scripts/faisca/fases/fase_1_2.gd", "imagem": "res://assets/faisca/portas/fase_1_2.jpg"},
	{"id": "2-1", "nome": "Cozinha Gigante", "tipo": "chao", "pede": 60, "andar": 1, "lado": 180,
		"cena": "res://scripts/faisca/fases/fase_2_1.gd", "imagem": "res://assets/faisca/portas/fase_2_1.jpg"},
	{"id": "2-2", "nome": "Nuvens de Algodão-Doce", "tipo": "ceu", "pede": 90, "andar": 1, "lado": 270,
		"cena": "res://scripts/faisca/fases/fase_2_2.gd", "imagem": "res://assets/faisca/portas/fase_2_2.jpg"},
	{"id": "2-3", "nome": "Quarto de Brinquedos", "tipo": "chao", "pede": 120, "andar": 1, "lado": 0,
		"cena": "res://scripts/faisca/fases/fase_2_3.gd", "imagem": "res://assets/faisca/portas/fase_2_3.jpg"},
	{"id": "3-1", "nome": "Pico Gelado", "tipo": "ceu", "pede": 150, "andar": 2, "lado": 0,
		"cena": "res://scripts/faisca/fases/fase_3_1.gd", "imagem": "res://assets/faisca/portas/fase_3_1.jpg"},
	{"id": "3-2", "nome": "Fábrica de Blocos", "tipo": "chao", "pede": 180, "andar": 2, "lado": 90,
		"cena": "res://scripts/faisca/fases/fase_3_2.gd", "imagem": "res://assets/faisca/portas/fase_3_2.jpg"},
	{"id": "3-3", "nome": "Moinhos do Vento", "tipo": "ceu", "pede": 210, "andar": 2, "lado": 180,
		"cena": "res://scripts/faisca/fases/fase_3_3.gd", "imagem": "res://assets/faisca/portas/fase_3_3.jpg"},
	# Os chefes de cada andar (item 5 da lista do Faísca): a porta abre com as Estrelas Grandes das fases do andar dele;
	# vencido, ele conta em `chefes`, não nas Estrelas Grandes (e a nave pede os três).
	{"id": "chefe-1", "nome": "Bolotão Fofão", "tipo": "chefe", "pede": 0, "andar": 0, "lado": 30,
		"cena": "res://scripts/faisca/fases/chefe_1.gd", "imagem": "res://assets/faisca/portas/chefe_1.jpg"},
	{"id": "chefe-2", "nome": "Chef Bolotão", "tipo": "chefe", "pede": 0, "andar": 1, "lado": 315,
		"cena": "res://scripts/faisca/fases/chefe_2.gd", "imagem": "res://assets/faisca/portas/chefe_2.jpg"},
	{"id": "chefe-3", "nome": "Pinguinzão do Gelo", "tipo": "chefe", "pede": 0, "andar": 2, "lado": 315,
		"cena": "res://scripts/faisca/fases/chefe_3.gd", "imagem": "res://assets/faisca/portas/chefe_3.jpg"},
	# A fase final (2026-11-12): por dentro da nave, com o Rei Bolotão no topo; vencida, o final lá fora (`_final_da_nave`).
	{"id": "nave", "nome": "Nave Aspiratrão", "tipo": "nave", "pede": 0, "andar": 3, "lado": 270,
		"cena": "res://scripts/faisca/fases/fase_nave.gd", "imagem": "res://assets/faisca/portas/nave.jpg"},
]
## As estrelinhas da escada do farol também contam.
const ID_FAROL := "farol"
## Faisquinhas em cada fase (os três de antes e os três de 2026-11-11).
const FAISQUINHAS_POR_FASE := 6
## O que os Faisquinhas salvos abrem no farol (item 1 da lista do Faísca): com 10, eles consertam o elevador; com 20,
## o trenzinho de brinquedo passa a rodar no térreo; com 30, o farolete do topo acende e gira.
const PREMIOS := [
	{"id": "elevador", "pede": 10, "titulo": "O elevador voltou a funcionar!", "sub": "Os Faisquinhas consertaram o elevador do farol"},
	{"id": "trem", "pede": 20, "titulo": "Piuí! Chegou o trenzinho!", "sub": "Os Faisquinhas montaram o trenzinho de brinquedo"},
	{"id": "farolete", "pede": 30, "titulo": "O farolete acendeu!", "sub": "Com 30 Faisquinhas, a luz do farol gira de novo"},
]

## Onde o Faísca está: "abertura", "hub" ou "fase".
var lugar := ""
var fase_atual := ""
## Nomes das estrelinhas pegas por fase (e no farol), Estrelas Grandes devolvidas e Faisquinhas salvos.
var estrelas := {}
var grandes: Array = []
var faisquinhas := {}
## Prêmios dos Faisquinhas que já tiveram a festa (para ela aparecer uma vez só).
var premios_vistos: Array = []
## Os chefes vencidos (ids das portas deles).
var chefes: Array = []
## Faisquinhas salvos na última fase ("1-1:3"), que chegam caindo do alto quando o Faísca volta ao farol.
var chegando: Array = []
## A carteira (item 4 da lista do Faísca), os brindes que já saíram da máquina e a tinta dele ("" a de fábrica).
var moedas := 0
var brindes: Array = []
var tinta := ""
var _sorteio := RandomNumberGenerator.new()
var abertura_vista := false
## Já viu o final (a nave vencida e as estrelas de volta no céu).
var final_visto := false
## Quantas vezes a luta de um chefe recomeçou do zero (os testes olham).
var luta_recomecou := 0
var faisca: Jogador
var hud: Hud
var hub: HubFarol
var nivel: Fase
## Nos testes: abertura curtinha.
var rapido := false
var menu_aberto := false
## Botões da pausa pela chave ("continuar", "sair_fase", "ajustes", "menu", "sair"); os testes apertam por aqui.
var botoes_pausa := {}
## A tela de início e a confirmação do novo jogo (os testes apertam pelas chaves: "continuar", "novo", "menu";
## "sim", "voltar").
var botoes_inicio := {}
var botoes_confirmar := {}
var tela_inicio: Control
var tela_confirmar: Control
var contador_inicio := {}
## Para onde a confirmação volta ("inicio" ou "pausa").
var _confirmar_volta := ""
var painel_ajustes: PainelAjustes
## A lojinha das tintas (o soco no cabide do farol).
var painel_tintas: PainelTintas
var fade: ColorRect
var dualsense: DualSense
var controle: ControleFaisca

var _camada: CanvasLayer
var _pausa: Control
## O contador da pausa (item 2 da lista do Faísca): estrelinhas, Faisquinhas e Estrelas Grandes, com figura.
var contador_pausa := {}
var _faixa_titulo: Label
var _faixa_sub: Label
var _faixa_tw: Tween
var _em_cena := false
var _trocando := false
var _controle_antes := true
var _teste: TesteFaiscaJogo
## A música do lugar (item 7 da lista do Faísca, 2026-11-11): o tema do farol, o do mundo de cada fase e o dos chefes,
## trocando devagar; as vinhetas tocam por cima, com a música abaixada. Guardados para os testes.
var musica_nome := ""
var vinhetas_tocadas: Array[String] = []
var _musica: AudioStreamPlayer
var _vinheta: AudioStreamPlayer
var _musica_tw: Tween


func _ready() -> void:
	Controles.configurar()
	Sfx.setup_buses()
	tocar_musica("farol")
	var args := OS.get_cmdline_user_args()
	var testando := Array(args).any(func(a: String) -> bool: return a.begins_with("--"))
	Ajustes.carregar(testando)
	FaiscaSave.enabled = not testando
	_montar_interface()
	_criar_faisca()
	controle = ControleFaisca.new(faisca, func() -> bool: return menu_aberto or busy() or hud.fim_aberto or not lugar in ["hub", "fase"])
	dualsense = DualSense.new()
	dualsense.name = "DualSense"
	dualsense.perfil = controle.escolher
	add_child(dualsense)
	if not testando:
		FaiscaSave.migrar()
		carregar(FaiscaSave.ler())
	_sorteio.randomize()
	if "--faisca-jogo" in args:
		_teste = TesteFaiscaJogo.new(self)
		_teste.rodar()
	elif "--faisca-jogo-captura" in args:
		_teste = TesteFaiscaJogo.new(self)
		_teste.capturar()
	elif "--faisca-farol-captura" in args:
		_teste = TesteFaiscaJogo.new(self)
		_teste.capturar_farol()
	elif "--faisca-brindes-captura" in args:
		_teste = TesteFaiscaJogo.new(self)
		_teste.capturar_brindes()
	elif abertura_vista:
		abrir_inicio()
	else:
		abertura()


## Cena ou troca de lugar em andamento (a pausa espera).
func busy() -> bool:
	return _em_cena or _trocando


func total_faisquinhas() -> int:
	var n := 0
	for id in faisquinhas:
		n += (faisquinhas[id] as Array).size()
	return n


## Os prêmios que o total de Faisquinhas já abriu (ids).
func premios_abertos() -> Array:
	var total := total_faisquinhas()
	return PREMIOS.filter(func(p: Dictionary) -> bool: return total >= int(p.pede)).map(func(p: Dictionary) -> String: return p.id)


func total_estrelas() -> int:
	var n := 0
	for id in estrelas:
		n += (estrelas[id] as Array).size()
	return n


# --- interface ---------------------------------------------------------------------------

func _montar_interface() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.visible = false
	_camada = CanvasLayer.new()
	_camada.layer = 20
	_camada.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_camada)
	var faixa := VBoxContainer.new()
	faixa.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	faixa.offset_top = 90
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada.add_child(faixa)
	_faixa_titulo = _rotulo(faixa, 40)
	_faixa_sub = _rotulo(faixa, 22)
	faixa.modulate.a = 0.0
	_pausa = _montar_pausa()
	_camada.add_child(_pausa)
	_pausa.hide()
	tela_inicio = _montar_inicio()
	_camada.add_child(tela_inicio)
	tela_inicio.hide()
	tela_confirmar = _montar_confirmar()
	_camada.add_child(tela_confirmar)
	tela_confirmar.hide()
	painel_ajustes = PainelAjustes.new()
	_camada.add_child(painel_ajustes)
	painel_ajustes.montar(_camada)
	painel_ajustes.hide()
	painel_ajustes.fechou.connect(func() -> void:
		_pausa.show()
		botoes_pausa.ajustes.grab_focus.call_deferred())
	painel_tintas = PainelTintas.new()
	_camada.add_child(painel_tintas)
	painel_tintas.montar(_camada)
	painel_tintas.hide()
	painel_tintas.escolheu.connect(pintar)
	painel_tintas.fechou.connect(_fechar_pausa)
	var escuro := CanvasLayer.new()
	escuro.layer = 30
	add_child(escuro)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 1.0
	escuro.add_child(fade)
	var escuta := Escuta.new()
	escuta.ao_apertar = _entrada
	add_child(escuta)


func _rotulo(pai: Control, tamanho: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_constant_override("outline_size", maxi(8, tamanho / 3))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(l)
	return l


## Faixa grande no alto da tela, com título e subtítulo (a nova toma o lugar da que estava).
func faixa(titulo: String, sub := "", cor := Color("#ffd23f"), segundos := 3.2) -> void:
	_faixa_titulo.text = titulo
	_faixa_titulo.add_theme_color_override("font_color", cor)
	_faixa_sub.text = sub
	var caixa := _faixa_titulo.get_parent() as Control
	if _faixa_tw:
		_faixa_tw.kill()
	_faixa_tw = caixa.create_tween()
	_faixa_tw.tween_property(caixa, "modulate:a", 1.0, 0.25)
	_faixa_tw.tween_interval(segundos)
	_faixa_tw.tween_property(caixa, "modulate:a", 0.0, 0.4)


## O título da faixa do alto (para os testes e as fotos).
func faixa_titulo_texto() -> String:
	return _faixa_titulo.text


func _montar_pausa() -> Control:
	var tela := Control.new()
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.45)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tela.add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tela.add_child(centro)
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", MenuKit.panel_style())
	centro.add_child(painel)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 14)
	painel.add_child(caixa)
	var titulo := Label.new()
	titulo.text = "Pausa"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.add_theme_color_override("font_color", MenuKit.GOLD)
	caixa.add_child(titulo)
	caixa.add_child(_montar_contador(contador_pausa))
	for spec in [["continuar", "Continuar", "continuar", _fechar_pausa], ["sair_fase", "Sair da fase", "casa", _sair_da_fase_pela_pausa],
			["ajustes", "Ajustes", "ajustes", abrir_ajustes], ["novo", "Novo jogo", "nova", func() -> void: _pedir_novo_jogo("pausa")],
			["menu", "Menu principal", "voltar", _ir_ao_menu], ["sair", "Sair do jogo", "sair", _sair_do_jogo]]:
		var b := MenuKit.icon_button(spec[1], spec[2], _camada, 340)
		b.pressed.connect(spec[3])
		caixa.add_child(b)
		botoes_pausa[spec[0]] = b
	return tela


## Uma tela escura por cima do jogo com um painel no meio e o título (a da pausa, a do início e a da confirmação).
func _tela_com_painel(texto: String) -> Array:
	var tela := Control.new()
	tela.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.45)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tela.add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tela.add_child(centro)
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", MenuKit.panel_style())
	centro.add_child(painel)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 14)
	painel.add_child(caixa)
	var titulo := Label.new()
	titulo.text = texto
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.add_theme_color_override("font_color", MenuKit.GOLD)
	caixa.add_child(titulo)
	return [tela, caixa]


## A tela de início (2026-11-12, pedido do usuário: "o jogador consegue iniciar um novo jogo do faisca como temos pra
## ilha cafuné?"): quem já tem jogo salvo entra vendo o farol parado atrás, o resumo do jogo (as mesmas figuras da
## pausa) e Continuar, Novo jogo e Menu principal. Sem jogo salvo, entra direto (a abertura).
func _montar_inicio() -> Control:
	var partes := _tela_com_painel("Faísca e o Céu Apagado")
	var caixa: VBoxContainer = partes[1]
	caixa.add_child(_montar_contador(contador_inicio))
	for spec in [["continuar", "Continuar", "continuar", _continuar_do_inicio], ["novo", "Novo jogo", "nova", func() -> void: _pedir_novo_jogo("inicio")],
			["menu", "Menu principal", "voltar", _ir_ao_menu]]:
		var b := MenuKit.icon_button(spec[1], spec[2], _camada, 340)
		b.pressed.connect(spec[3])
		caixa.add_child(b)
		botoes_inicio[spec[0]] = b
	return partes[0]


## A confirmação do novo jogo: o brilho do "novo", o que vai ser apagado (com as figuras) e as duas escolhas.
func _montar_confirmar() -> Control:
	var partes := _tela_com_painel("Novo jogo")
	var caixa: VBoxContainer = partes[1]
	var icone := MenuIcon.new("nova", MenuKit.ICON_COLORS.nova, 64)
	icone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	caixa.add_child(icone)
	var texto := Label.new()
	texto.text = "Começar do zero? As estrelinhas, as Estrelas Grandes, os Faisquinhas, as moedas, as figurinhas, as tintas e os chefes vencidos serão apagados."
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(420, 0)
	texto.add_theme_font_size_override("font_size", 20)
	caixa.add_child(texto)
	var figuras := _montar_contador({})
	caixa.add_child(figuras)
	for l in figuras.get_children():
		if l is Label:
			(l as Label).text = "0"
	for spec in [["sim", "Sim, começar do zero", "nova", novo_jogo], ["voltar", "Voltar", "voltar", _voltar_da_confirmacao]]:
		var b := MenuKit.icon_button(spec[1], spec[2], _camada, 340)
		b.pressed.connect(spec[3])
		caixa.add_child(b)
		botoes_confirmar[spec[0]] = b
	return partes[0]


## Uma linha com quatro figuras e o número do lado de cada uma: a estrelinha, o Faisquinha, a Estrela Grande e a moeda.
## Os números (e as figuras, com "_icone") ficam em `destino`.
func _montar_contador(destino: Dictionary) -> HBoxContainer:
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 10)
	for qual in ["estrelas", "faisquinhas", "grandes", "moedas"]:
		var icone: Control
		if qual == "faisquinhas":
			var f := Hud.IconeFaisquinha.new()
			f.aceso = true
			icone = f
		elif qual == "moedas":
			icone = Hud.IconeMoeda.new()
		else:
			icone = Hud.IconeEstrela.new()
		icone.custom_minimum_size = Vector2(44, 46) if qual != "estrelas" else Vector2(36, 36)
		icone.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		linha.add_child(icone)
		var numero := Label.new()
		numero.add_theme_font_size_override("font_size", 30)
		numero.add_theme_color_override("font_color", Color.WHITE)
		numero.add_theme_color_override("font_outline_color", Color("2b2140"))
		numero.add_theme_constant_override("outline_size", 8)
		linha.add_child(numero)
		destino[qual] = numero
		destino[qual + "_icone"] = icone
		if qual != "moedas":
			var vao := Control.new()
			vao.custom_minimum_size = Vector2(18, 0)
			linha.add_child(vao)
	return linha


## Na fase: o que tem nela (pegas/total); no farol: o jogo todo.
func _atualizar_contador() -> void:
	if not (lugar == "fase" and is_instance_valid(nivel)):
		_contar_o_jogo(contador_pausa)
		return
	contador_pausa.estrelas.text = "%d/%d" % [nivel.pegas, nivel.total_estrelas()]
	contador_pausa.faisquinhas.text = "%d/%d" % [nivel.achados, nivel.faisquinhas.size()]
	contador_pausa.grandes.text = "%d/1" % (1 if fase_atual in grandes else 0)
	(contador_pausa.grandes_icone as Control).custom_minimum_size = Vector2(46, 46)
	contador_pausa.moedas.text = str(moedas)


## O jogo todo no contador `c` (o do farol na pausa e o da tela de início).
func _contar_o_jogo(c: Dictionary) -> void:
	var feitas := FASES.filter(func(f: Dictionary) -> bool: return f.cena != "" and f.tipo in ["ceu", "chao", "nave"]).size()
	var com_estrela := FASES.filter(func(f: Dictionary) -> bool: return f.tipo in ["ceu", "chao"]).size()
	c.estrelas.text = str(total_estrelas())
	c.faisquinhas.text = "%d/%d" % [total_faisquinhas(), feitas * FAISQUINHAS_POR_FASE]
	c.grandes.text = "%d/%d" % [grandes.size(), com_estrela]
	(c.grandes_icone as Control).custom_minimum_size = Vector2(46, 46)
	c.moedas.text = str(moedas)


func _entrada(event: InputEvent) -> void:
	if tela_confirmar.visible:
		if event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel"):
			_voltar_da_confirmacao()
			get_viewport().set_input_as_handled()
		return
	if tela_inicio.visible:
		# Na tela de início, o B e o Start não fazem nada (ela só sai por uma das escolhas).
		if event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
		return
	if painel_tintas.visible:
		if event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel"):
			painel_tintas.fechar()
			get_viewport().set_input_as_handled()
		return
	if painel_ajustes.visible:
		if event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel"):
			painel_ajustes.fechar()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("menu"):
		if menu_aberto:
			_fechar_pausa()
		elif pode_pausar():
			abrir_pausa()
		get_viewport().set_input_as_handled()
	elif menu_aberto and event.is_action_pressed("ui_cancel"):
		_fechar_pausa()
		get_viewport().set_input_as_handled()


func pode_pausar() -> bool:
	# Na cena do fim da nave (o Rei vencido), a pausa espera: sair da fase no meio da cena quebrava o final.
	var na_cena_da_nave: bool = lugar == "fase" and is_instance_valid(nivel) and nivel.get("vencida") == true
	return not busy() and lugar in ["hub", "fase"] and not hud.fim_aberto and not na_cena_da_nave


func abrir_pausa() -> void:
	menu_aberto = true
	botoes_pausa.sair_fase.visible = lugar == "fase"
	_atualizar_contador()
	_pausa.show()
	hud.visible = false
	_controle_antes = faisca.controle_ligado
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_salvar()
	botoes_pausa.continuar.grab_focus.call_deferred()


## Fecha a pausa. O controle volta um instante depois, para o A que confirmou não virar pulo.
func _fechar_pausa() -> void:
	if not menu_aberto:
		return
	menu_aberto = false
	_pausa.hide()
	painel_ajustes.hide()
	painel_tintas.hide()
	tela_confirmar.hide()
	hud.visible = true
	get_tree().paused = false
	if _controle_antes:
		faisca.controle_ligado = false
		await get_tree().create_timer(0.2).timeout
		if not busy() and not menu_aberto:
			faisca.controle_ligado = true


## O soco no cabide do farol: a lojinha das tintas, com o jogo parado como na pausa (fechando, volta como dela).
func abrir_tintas() -> void:
	if lugar != "hub" or busy() or menu_aberto or hud.fim_aberto:
		return
	menu_aberto = true
	hud.visible = false
	_controle_antes = faisca.controle_ligado
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	painel_tintas.abrir(tinta, brindes)


## Pausa > Ajustes: o painel no lugar da pausa; fechando, a pausa volta com o botão marcado.
func abrir_ajustes() -> void:
	_pausa.hide()
	painel_ajustes.abrir()


func _sair_da_fase_pela_pausa() -> void:
	await _fechar_pausa()
	sair_da_fase()


func _ir_ao_menu() -> void:
	_salvar()
	get_tree().paused = false
	get_tree().change_scene_to_file(MenuPrincipal.CENA)


func _sair_do_jogo() -> void:
	_salvar()
	get_tree().quit()


func _escurecer(alfa: float, segundos: float) -> void:
	var tw := fade.create_tween()
	tw.tween_property(fade, "modulate:a", alfa, segundos)
	await tw.finished


# --- o Faísca, o farol e as fases --------------------------------------------------------

func _criar_faisca() -> void:
	faisca = Jogador.new()
	faisca.name = "Faisca"
	add_child(faisca)
	faisca.vida_mudou.connect(hud.mostrar_vida)
	# Ganhou um coração: piscada rosa (a tremidinha é do Jogador).
	faisca.curou.connect(func() -> void: controle.piscar(Color8(255, 80, 120), 0.8))
	faisca.voltou_do_curto.connect(_depois_do_curto)
	hud.jogar_de_novo.connect(_fim_aceito)
	hud.mostrar_vida(faisca.vida)
	_esconder_faisca()


func _esconder_faisca() -> void:
	faisca.visible = false
	faisca.process_mode = Node.PROCESS_MODE_DISABLED
	faisca.controle_ligado = false


func _mostrar_faisca() -> void:
	faisca.visible = true
	faisca.process_mode = Node.PROCESS_MODE_INHERIT
	faisca.camera.make_current()


## Quem já tem jogo salvo: o farol monta atrás, parado, e a tela de início aparece por cima.
func abrir_inicio() -> void:
	_trocando = true
	fade.modulate.a = 1.0
	_montar_hub("")
	lugar = "hub"
	hud.visible = false
	await _escurecer(0.0, 0.6)
	_trocando = false
	menu_aberto = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_contar_o_jogo(contador_inicio)
	tela_inicio.show()
	botoes_inicio.continuar.grab_focus.call_deferred()


## Continuar: a tela some e o jogo segue no térreo do farol (o controle volta um instante depois, para o A que
## confirmou não virar pulo).
func _continuar_do_inicio() -> void:
	tela_inicio.hide()
	menu_aberto = false
	get_tree().paused = false
	hud.visible = true
	faisca.controle_ligado = false
	await get_tree().create_timer(0.2).timeout
	if not busy() and not menu_aberto:
		faisca.controle_ligado = true
	_festa_no_farol()


## Novo jogo (da tela de início ou da pausa): a confirmação, com o "Voltar" marcado (para um A sem querer não apagar).
func _pedir_novo_jogo(de: String) -> void:
	_confirmar_volta = de
	tela_inicio.hide()
	_pausa.hide()
	tela_confirmar.show()
	botoes_confirmar.voltar.grab_focus.call_deferred()


func _voltar_da_confirmacao() -> void:
	tela_confirmar.hide()
	if _confirmar_volta == "inicio":
		tela_inicio.show()
		botoes_inicio.novo.grab_focus.call_deferred()
	else:
		_pausa.show()
		botoes_pausa.novo.grab_focus.call_deferred()


## Começa do zero, sem recarregar a cena: grava um save zerado (não apaga o arquivo: sem ele, o FaiscaSave.migrar
## traria de volta a Parte 2 guardada na campanha da ilha), desmonta o farol ou a fase, devolve o Faísca como no
## começo (3 corações, sem poder, a cor de fábrica) e toca a abertura de novo. Os Ajustes ficam como estão.
func novo_jogo() -> void:
	tela_confirmar.hide()
	tela_inicio.hide()
	_pausa.hide()
	painel_ajustes.hide()
	painel_tintas.hide()
	menu_aberto = false
	get_tree().paused = false
	_trocando = true
	faisca.controle_ligado = false
	await _escurecer(1.0, 0.4)
	hud.esconder_fim()
	hud.esconder_chefe()
	if is_instance_valid(nivel):
		nivel.queue_free()
	nivel = null
	if is_instance_valid(hub):
		hub.queue_free()
	hub = null
	carregar({})
	chegando.clear()
	fase_atual = ""
	_salvar()
	faisca.tirar_poderes()
	faisca.vida = Jogador.VIDA_MAX
	hud.mostrar_vida(faisca.vida)
	faisca.camera_guiada = {}
	faisca.distancia_camera = Jogador.DISTANCIA_CAMERA
	_esconder_faisca()
	tocar_musica("farol")
	lugar = ""
	_trocando = false
	abertura()


## Quem já viu a abertura começa direto no térreo do farol.
func comecar_no_farol() -> void:
	_trocando = true
	fade.modulate.a = 1.0
	_montar_hub("")
	lugar = "hub"
	await _escurecer(0.0, 0.6)
	faisca.controle_ligado = true
	_trocando = false
	_festa_no_farol()


func _montar_hub(volta_de: String) -> void:
	hub = HubFarol.new()
	hub.name = "DentroDoFarol"
	hub.volta_de = volta_de
	# As constelações do teto: as das Estrelas Grandes e as dos chefes vencidos.
	hub.grandes = grandes + chefes
	hub.chefes = chefes.duplicate()
	hub.ja_pegas = _como_dicionario(estrelas.get(ID_FAROL, []))
	for f in FASES:
		var falta := falta_para(f)
		hub.portas.append({"id": f.id, "nome": f.nome, "tipo": f.tipo, "andar": f.andar, "lado": f.lado, "pede": f.pede,
			"pede_grandes": grandes_pedidas(f).size(), "pede_chefes": chefes_pedidos(f).size(), "falta": falta, "aberta": falta == 0, "feita": f.cena != "", "imagem": f.imagem,
			"grande": f.id in grandes or f.id in chefes or (f.id == "nave" and final_visto), "achados": (faisquinhas.get(f.id, []) as Array).size(),
			"total_faisquinhas": 0 if f.tipo == "chefe" else FAISQUINHAS_POR_FASE})
		for n in faisquinhas.get(f.id, []):
			hub.moradores_dados.append({"fase": f.id, "id": str(n), "andar": int(f.andar), "chegando": "%s:%s" % [f.id, n] in chegando})
	chegando.clear()
	hub.premios = premios_abertos()
	hub.premios_novos = hub.premios.filter(func(p: String) -> bool: return not p in premios_vistos)
	for p in hub.premios_novos:
		premios_vistos.append(p)
	hub.total_faisquinhas = total_faisquinhas()
	hub.brindes = brindes.duplicate()
	add_child(hub)
	hub.maquina.pedido.connect(_pedir_brinde)
	hub.cabide.abrir.connect(abrir_tintas)
	hub.estrela_pega.connect(func(_pegas: int, _total: int) -> void:
		_juntar(ID_FAROL, hub.novas, estrelas)
		hud.mostrar_estrelas(total_estrelas())
		hub.atualizar_portas(total_estrelas()))
	hub.porta_escolhida.connect(entrar_fase)
	tocar_musica("farol")
	_mostrar_faisca()
	faisca.teleportar(hub.inicio)
	faisca.yaw = hub.yaw_inicial()
	faisca.visual.rotation.y = faisca.yaw + PI
	faisca.pitch = -0.25
	faisca.limite_queda = hub.limite_queda
	faisca.ponto_retorno = hub.inicio
	faisca.pode_recomecar = false
	hud.visible = true
	hud.mostrar_estrelas(total_estrelas())
	hud.mostrar_faisquinhas(0, 0)
	hud.mostrar_moedas(moedas)


## As fases cujas Estrelas Grandes a porta `f` pede: a do chefe pede as das fases do andar dele.
func grandes_pedidas(f: Dictionary) -> Array:
	if String(f.get("tipo", "")) != "chefe":
		return []
	return FASES.filter(func(o: Dictionary) -> bool: return o.tipo in ["ceu", "chao"] and int(o.andar) == int(f.andar)).map(
			func(o: Dictionary) -> String: return o.id)


## Os chefes que a porta `f` pede vencidos: a da nave pede os três.
func chefes_pedidos(f: Dictionary) -> Array:
	if String(f.get("tipo", "")) != "nave":
		return []
	return FASES.filter(func(o: Dictionary) -> bool: return o.tipo == "chefe").map(func(o: Dictionary) -> String: return o.id)


## Quanto falta para a porta `f` abrir: Estrelas Grandes do andar (chefe), chefes vencidos (nave) ou estrelinhas (fase).
func falta_para(f: Dictionary) -> int:
	var g := grandes_pedidas(f)
	if not g.is_empty():
		return g.filter(func(id: String) -> bool: return not id in grandes).size()
	var c := chefes_pedidos(f)
	if not c.is_empty():
		return c.filter(func(id: String) -> bool: return not id in chefes).size()
	return maxi(int(f.get("pede", 0)) - total_estrelas(), 0)


func entrar_fase(id: String) -> void:
	var dados := _fase(id)
	if _trocando or lugar != "hub" or dados.is_empty() or dados.cena == "" or falta_para(dados) > 0:
		return
	_trocando = true
	faisca.controle_ligado = false
	await _escurecer(1.0, 0.35)
	hub.queue_free()
	hub = null
	_abrir_fase(id)
	await _esperar_a_fase_assentar()
	_escurecer(0.0, 0.5)
	await _comecar_fase()
	_trocando = false


## Monta a fase `id` (vinda do farol, ou de novo, quando a luta de um chefe recomeça): a cena, a música, os sinais e o
## Faísca com os 3 corações e sem poderes.
func _abrir_fase(id: String) -> void:
	var dados := _fase(id)
	nivel = load(dados.cena).new()
	nivel.name = "Fase"
	tocar_musica(musica_da_fase(id))
	nivel.ja_pegas = _como_dicionario(estrelas.get(id, []))
	nivel.ja_achados = _como_dicionario(faisquinhas.get(id, []))
	add_child(nivel)
	lugar = "fase"
	fase_atual = id
	nivel.estrela_pega.connect(func(pegas: int, _total: int) -> void:
		_juntar(id, nivel.novas, estrelas)
		faisca.festa_no_controle("estrelinha")
		hud.mostrar_estrelas(pegas))
	nivel.faisquinha_salvo.connect(func(achados: int, total: int) -> void:
		_juntar(id, nivel.novos_faisquinhas, faisquinhas)
		for n in nivel.novos_faisquinhas:
			if not "%s:%s" % [id, n] in chegando:
				chegando.append("%s:%s" % [id, n])
		faisca.festa_no_controle("faisquinha")
		controle.piscar(Color8(198, 255, 74), 1.2)
		# O tema curto do resgate entra logo depois do "ê!" do Faisquinha.
		get_tree().create_timer(0.3).timeout.connect(func() -> void:
			if lugar == "fase":
				vinheta("vinheta_faisquinha"))
		hud.mostrar_faisquinhas(achados, total))
	nivel.posto_aceso.connect(func(p: Posto) -> void: faisca.ponto_retorno = p.ponto())
	nivel.dica.connect(hud.mostrar_dica)
	nivel.estrela_grande_pega.connect(_terminar_fase)
	nivel.moeda_pega.connect(func(_pegas: int) -> void:
		moedas += 1
		hud.mostrar_moedas(moedas))
	if nivel.has_signal("faixa_pedida"):
		nivel.faixa_pedida.connect(func(titulo: String, sub: String) -> void: faixa(titulo, sub, Color("#ffd23f"), 3.0))
	# A nave: o tema dos chefes quando a luta com o Rei começa, e o final quando ele ganha a estrelinha de bolso.
	if nivel.has_signal("luta_comecou"):
		nivel.luta_comecou.connect(func() -> void: tocar_musica("chefe"))
	if nivel.has_signal("final_pedido"):
		nivel.final_pedido.connect(_final_da_nave)
	hud.esconder_chefe()
	# Os chefes (Chefe1, Chefe2...): os corações deles no alto da tela, um por fase.
	var chefe: Node = nivel.get("chefe")
	var nome_do_chefe: String = nivel.get("nome_do_chefe") if nivel.get("nome_do_chefe") != null else dados.nome
	if chefe and chefe.has_signal("fase_mudou"):
		chefe.fase_mudou.connect(func(f: int) -> void: hud.mostrar_chefe(nome_do_chefe, 4 - f))
	faisca.limite_queda = nivel.limite_queda
	faisca.pode_recomecar = true
	faisca.tirar_poderes()
	faisca.vida = Jogador.VIDA_MAX
	hud.mostrar_vida(faisca.vida)
	hud.mostrar_estrelas(nivel.pegas)
	hud.mostrar_faisquinhas(nivel.achados, nivel.faisquinhas.size())
	hud.mostrar_moedas(moedas)
	faisca.yaw = 0.0
	faisca.pitch = -0.32
	faisca.visual.rotation.y = PI


## Perdeu todos os corações (item 14 da lista do Faísca, 2026-11-13): nas fases, o curto já leva de volta ao último
## posto. Na luta de um chefe, ela recomeça do zero: a arena do chefe do andar monta de novo, com o chefe inteiro (o
## Faísca desce do céu como na chegada); na nave, só a Sala do Trono volta ao começo (`FaseNave.recomecar_luta`).
func _depois_do_curto() -> void:
	if _trocando or lugar != "fase" or not is_instance_valid(nivel):
		return
	if nivel.has_method("recomecar_luta"):
		nivel.recomecar_luta()
		return
	var chefe: Node = nivel.get("chefe")
	if String(_fase(fase_atual).get("tipo", "")) != "chefe" or chefe == null or int(chefe.get("fase")) < 1 or bool(chefe.get("derrotado")):
		return
	_trocando = true
	faisca.controle_ligado = false
	faixa("De novo!", "A luta recomeça do começo", Color("#ff8fd0"), 2.4)
	await _escurecer(1.0, 0.45)
	hud.esconder_chefe()
	nivel.queue_free()
	nivel = null
	_abrir_fase(fase_atual)
	await _esperar_a_fase_assentar()
	_escurecer(0.0, 0.5)
	await _comecar_fase()
	_trocando = false
	luta_recomecou += 1


## Os primeiros quadros de uma fase são os mais pesados: a vegetação e o mundo que reage montam depois do primeiro
## quadro de física, e os shaders compilam quando a fase aparece. Passa por eles com a tela ainda escura e o Faísca
## parado lá no alto (a câmera já olhando o começo), para ele descer com a fase pronta. Antes a tela clareava no meio
## disso: ficava preta, só com o som do laser dos pés, e ele aparecia já no chão (relato do usuário em 2026-11-12).
func _esperar_a_fase_assentar() -> void:
	faisca.teleportar(nivel.inicio + Vector3(0, 7, 0))
	faisca.set_physics_process(false)
	for k in 4:
		await get_tree().physics_frame
		faisca.acompanhar_camera(1.0 / 60.0)
	for k in 2:
		await get_tree().process_frame
	faisca.set_physics_process(true)


# --- a música (item 7) ---------------------------------------------------------------------

const VOLUME_MUSICA := 0.0
const VOLUME_ABAIXADA := -16.0


## O tema da fase: o dos chefes, ou o do mundo dela (o andar do farol: 1 Ilhas Fofas, 2 Doces e Brinquedos, 3 Frio e
## Vento).
func musica_da_fase(id: String) -> String:
	var f := _fase(id)
	if String(f.get("tipo", "")) == "chefe":
		return "chefe"
	if String(f.get("tipo", "")) == "nave":
		return "nave"
	return "mundo_%d" % clampi(int(f.get("andar", 0)) + 1, 1, 3)


## Troca a música devagar: a de antes some em 0,8 s e a nova entra em 1,2 s. Pedindo a mesma que já toca, ela só volta
## ao volume de sempre (depois da fanfarra, por exemplo).
func tocar_musica(nome: String) -> void:
	if nome == musica_nome and is_instance_valid(_musica):
		_volume(VOLUME_MUSICA, 1.0)
		return
	musica_nome = nome
	var velha := _musica
	if is_instance_valid(velha):
		var tw := velha.create_tween()
		tw.tween_property(velha, "volume_db", -40.0, 0.8)
		tw.tween_callback(velha.queue_free)
	_musica = Sfx.music(self, nome)
	_musica.process_mode = Node.PROCESS_MODE_ALWAYS
	_musica.volume_db = -30.0
	_volume(VOLUME_MUSICA, 1.2)


func _volume(db: float, segundos: float) -> void:
	if not is_instance_valid(_musica):
		return
	if _musica_tw and _musica_tw.is_valid():
		_musica_tw.kill()
	_musica_tw = _musica.create_tween()
	_musica_tw.tween_property(_musica, "volume_db", db, segundos)


## Uma vinheta por cima da música, que abaixa enquanto ela toca e volta depois. Com `segura`, a música some e só volta
## quando trocar de lugar (a Estrela Grande, antes da tela de fim).
func vinheta(nome: String, segura := false) -> void:
	vinhetas_tocadas.append(nome)
	if is_instance_valid(_vinheta):
		_vinheta.stop()
		_vinheta.queue_free()
	_vinheta = Sfx.vinheta(self, nome)
	_vinheta.process_mode = Node.PROCESS_MODE_ALWAYS
	_volume(-40.0 if segura else VOLUME_ABAIXADA, 0.25)
	if not segura:
		var era := musica_nome
		_vinheta.finished.connect(func() -> void:
			if musica_nome == era:
				_volume(VOLUME_MUSICA, 1.0))


## O Faísca desce do céu flutuando, com os jatos ligados, e o controle volta quando ele pisa.
func _comecar_fase() -> void:
	faisca.teleportar(nivel.inicio + Vector3(0, 7, 0))
	faisca.ponto_retorno = nivel.inicio
	faisca.controle_ligado = false
	faisca.pouso_suave = true
	faisca.robo.animar("mov/Jump_Idle", 0.1)
	while faisca.pouso_suave and is_instance_valid(nivel):
		await get_tree().physics_frame
	faisca.robo.animar("mov/Jump_Land", 0.05)
	await get_tree().create_timer(0.25).timeout
	faisca.controle_ligado = true


## Pegou a Estrela Grande: o Faísca comemora, a estrela sobe e aparece a tela de fim.
func _terminar_fase() -> void:
	# A fanfarra da Estrela Grande: a música da fase some e só volta com a do farol.
	vinheta("vinheta_estrela", true)
	faisca.festa_no_controle("estrela_grande")
	controle.piscar(Color8(255, 200, 40), 3.0)
	faisca.controle_ligado = false
	faisca.golpe_atual = -1
	faisca.visual.rotation.y = faisca.yaw
	faisca.robo.animar("festa/Cheering", 0.2)
	nivel.bau.estrela_sobe()
	if String(_fase(fase_atual).get("tipo", "")) == "chefe":
		if not fase_atual in chefes:
			chefes.append(fase_atual)
	elif not fase_atual in grandes:
		grandes.append(fase_atual)
	_salvar()
	await get_tree().create_timer(2.6).timeout
	if is_instance_valid(nivel):
		hud.mostrar_fim(nivel.nome, nivel.pegas, nivel.total_estrelas(), nivel.achados, nivel.faisquinhas.size())


## A na tela de fim: volta para o farol, na frente da porta da fase.
func _fim_aceito() -> void:
	hud.esconder_fim()
	sair_da_fase()


func sair_da_fase() -> void:
	if _trocando or lugar != "fase":
		return
	_trocando = true
	faisca.controle_ligado = false
	faisca.pouso_suave = false
	await _escurecer(1.0, 0.35)
	hud.esconder_fim()
	hud.esconder_chefe()
	nivel.queue_free()
	nivel = null
	_montar_hub(fase_atual)
	lugar = "hub"
	# O poder da fase (o Balão de Chiclete da 2-2, o Ioiô da 2-3, a Luva de Neve da 3-1) fica lá dentro.
	faisca.tirar_poderes()
	faisca.vida = Jogador.VIDA_MAX
	hud.mostrar_vida(faisca.vida)
	faisca.robo.animar("geral/Idle_A", 0.1)
	_salvar()
	await _escurecer(0.0, 0.45)
	faisca.controle_ligado = true
	_trocando = false
	_festa_no_farol()


## O soco no botão da Máquina de Brindes: paga PRECO moedas e solta um brinde novo (a figurinha vai para a estante;
## a tinta voa até o Faísca e já pinta ele, e a lata vai para o cabide). Sem moedas, ou já com todos, a máquina balança que não.
func _pedir_brinde() -> void:
	if lugar != "hub" or not is_instance_valid(hub) or hub.maquina.ocupada:
		return
	var id := Brindes.sortear(brindes, _sorteio)
	if id == "":
		hub.maquina.negar()
		faixa("Você já tem todos os brindes!", "As figurinhas estão na estante e as tintas no cabide", Color("#ffd23f"), 3.0)
		return
	if moedas < Brindes.PRECO:
		hub.maquina.negar()
		faixa("Faltam %d moedas" % (Brindes.PRECO - moedas), "Vença as Bolotas e salve os Faisquinhas para ganhar moedas",
				Color("#ffd23f"), 2.6)
		return
	moedas -= Brindes.PRECO
	hud.mostrar_moedas(moedas)
	brindes.append(id)
	_salvar()
	var maquina := hub.maquina
	var dados := Brindes.dados(id)
	var e_tinta: bool = dados.tipo == "tinta"
	maquina.revelado.connect(func(_id: String) -> void:
		faixa("Tinta nova!" if e_tinta else "Figurinha nova!", String(dados.nome), Color("#8ff3ff"), 2.6)
		faisca.festa_no_controle("premio")
		controle.piscar(Color8(255, 200, 40), 1.5), CONNECT_ONE_SHOT)
	maquina.entregue.connect(func(_id: String) -> void:
		if not is_instance_valid(hub):
			return
		if e_tinta:
			pintar(id)
			hub.cabide.mostrar(brindes)
			Fx.confetti(self, faisca.global_position + Vector3.UP * 1.6, 24, 2.5)
			faisca.robo.expressao("coracao", 1.2)
		else:
			hub.estante.por(id), CONNECT_ONE_SHOT)
	var destino := func() -> Vector3:
		if e_tinta:
			return faisca.global_position + Vector3.UP * 1.6
		return hub.estante.lugar(id) if is_instance_valid(hub) else Vector3.ZERO
	maquina.soltar(id, destino)


## Pinta o Faísca com a tinta `id` (uma tinta da máquina, ou "" para a de fábrica) e guarda.
func pintar(id: String) -> void:
	tinta = id
	faisca.robo.pintar(Brindes.cor_de(id), Brindes.metal(id))
	_salvar()


## Chegando no farol: a faixa dos Faisquinhas que acabaram de chegar (eles caem do alto) e a festa de cada prêmio
## novo, uma vez só (faixa, confete no prêmio e os Faisquinhas pulando).
func _festa_no_farol() -> void:
	var este := hub
	if not is_instance_valid(este):
		return
	var chegaram := este.moradores.filter(func(f: Faisquinha) -> bool: return f.has_meta("chegando")).size()
	await get_tree().create_timer(0.9).timeout
	if chegaram > 0 and is_instance_valid(este) and hub == este:
		faixa("Faisquinha%s no farol!" % ("s" if chegaram > 1 else ""),
				"Agora são %d Faisquinhas morando aqui" % total_faisquinhas(), Color("#8ff3ff"), 2.6)
		await get_tree().create_timer(3.2).timeout
	for id in este.premios_novos if is_instance_valid(este) else []:
		if not is_instance_valid(este) or hub != este:
			return
		var dados: Dictionary = PREMIOS.filter(func(p: Dictionary) -> bool: return p.id == id)[0]
		faixa(dados.titulo, dados.sub, Color("#ffd23f"), 3.4)
		Fx.confetti(este, este.lugar_do_premio(id), 50, 5.0)
		Sfx.play(self, "faisquinha_salvo")
		faisca.festa_no_controle("premio")
		controle.piscar(Color8(255, 200, 40), 2.5)
		este.festa()
		await get_tree().create_timer(4.2).timeout


# --- abertura ----------------------------------------------------------------------------

## Na primeira vez: à noite, no mar, a nave do Rei Bolotão passa sobre o farol e suga as estrelas do céu;
## depois a lâmpada do farol acende e o Faísca sai pulando pela porta. Termina no térreo do farol.
func abertura() -> void:
	if _em_cena:
		return
	_em_cena = true
	lugar = "abertura"
	hud.visible = false
	var t := 0.35 if rapido else 1.0
	fade.modulate.a = 1.0
	var cena := Node3D.new()
	cena.name = "Abertura"
	add_child(cena)
	var ceu := _noite(cena)
	_mar(cena)
	var farol := FarolIlha.new()
	cena.add_child(farol)
	var porta := farol.porta()
	var para_praia := -FarolIlha.DIRECAO
	var lado := Vector3(para_praia.z, 0, -para_praia.x)
	var cam := Camera3D.new()
	cam.fov = 58.0
	cena.add_child(cam)
	cam.make_current()
	# 1. O céu estrelado sobre o farol, e a nave roxa passando.
	cam.global_position = porta + para_praia * 26.0 + lado * 6.0 + Vector3.UP * 2.0
	cam.look_at(farol.global_position + Vector3.UP * 30.0)
	var nave := Aspiratrao.new()
	nave.name = "Aspiratrao"
	nave.scale = Vector3.ONE * 1.4
	cena.add_child(nave)
	var rota := farol.global_position + Vector3.UP * 42.0 - para_praia * 12.0
	nave.global_position = rota + lado * 150.0
	nave.create_tween().tween_property(nave, "global_position", rota - lado * 150.0, 8.0 * t)
	await _escurecer(0.0, 0.8 * t)
	faixa("Que nave é essa?!", "É o Aspiratrão do Rei Bolotão!", Color("#d9a8ff"), 3.0 * t)
	await get_tree().create_timer(1.8 * t).timeout
	_sugar_estrelas(cena, nave, cam, ceu, t)
	await get_tree().create_timer(3.4 * t).timeout
	faixa("O céu ficou apagado!", "As estrelas caíram pelas ilhas do céu e por lugares aqui embaixo", Color("#ffd23f"), 3.4 * t)
	await get_tree().create_timer(2.8 * t).timeout
	# 2. O farol acende e o Faísca sai pulando.
	await _escurecer(1.0, 0.4 * t)
	nave.queue_free()
	cam.global_position = porta + para_praia * 11.0 + lado * 3.0 + Vector3.UP * 3.2
	cam.look_at(farol.global_position + Vector3.UP * 7.5)
	await _escurecer(0.0, 0.5 * t)
	await get_tree().create_timer(0.7 * t).timeout
	farol.aberto = true
	farol.atualizar()
	Sfx.play(self, "estouro", 0.0, 0.0)
	Fx.confetti(cena, farol.global_position + Vector3.UP * 16.0, 30, 5.0)
	await get_tree().create_timer(0.9 * t).timeout
	_mostrar_faisca()
	faisca.limite_queda = -1000.0
	faisca.teleportar(porta - para_praia * 0.6 + Vector3.UP * 0.1)
	faisca.visual.rotation.y = atan2(para_praia.x, para_praia.z)
	cam.make_current()
	Fx.confetti(cena, porta + Vector3.UP * 1.2, 16, 3.0)
	faisca.robo.animar("mov/Jump_Start", 0.05)
	var pulo := faisca.create_tween()
	var chegada := porta + para_praia * 2.6 + Vector3.UP * 0.1
	pulo.tween_method(func(k: float) -> void:
		faisca.global_position = (porta - para_praia * 0.6).lerp(chegada, k) + Vector3.UP * (0.1 + 2.2 * 4.0 * k * (1.0 - k)),
		0.0, 1.0, 0.7 * maxf(t, 0.6))
	await pulo.finished
	faisca.robo.animar("mov/Jump_Land", 0.05)
	await get_tree().create_timer(0.3 * t).timeout
	var olhar := cam.global_position - faisca.global_position
	faisca.visual.rotation.y = atan2(olhar.x, olhar.z)
	faisca.robo.animar("festa/Cheering", 0.2)
	faixa("O Faísca!", "O robozinho que acende as estrelas vai buscar todas de volta", Color("#8ff3ff"), 3.6 * t)
	await get_tree().create_timer(3.4 * t).timeout
	await _escurecer(1.0, 0.5 * t)
	cena.queue_free()
	abertura_vista = true
	_montar_hub("")
	lugar = "hub"
	faisca.robo.animar("geral/Idle_A", 0.1)
	_salvar()
	await _escurecer(0.0, 0.6 * t)
	_em_cena = false
	faisca.controle_ligado = true
	faixa("Faísca e o Céu Apagado", "Junte estrelinhas para abrir as portas do farol", Color("#8ff3ff"), 4.0 * t)


## O céu da noite da ilha (o mesmo do Ending): estrelas pintadas no céu e a lua azulada.
func _noite(cena: Node3D) -> ProceduralSkyMaterial:
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color("#0f1a4d")
	ceu.sky_horizon_color = Color("#3d3f86")
	ceu.ground_horizon_color = Color("#3d3f86")
	ceu.ground_bottom_color = Color("#0c1a40")
	ceu.sky_cover = DayNight.stars_texture()
	ceu.sky_cover_modulate = Color(1, 1, 1, 0.95)
	var sky := Sky.new()
	sky.sky_material = ceu
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#7884c8")
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_hdr_threshold = 0.9
	var mundo := WorldEnvironment.new()
	mundo.environment = env
	cena.add_child(mundo)
	var lua := DirectionalLight3D.new()
	lua.light_color = Color("#aab8ff")
	lua.light_energy = 0.35
	lua.rotation_degrees = Vector3(-38, 160, 0)
	lua.shadow_enabled = true
	cena.add_child(lua)
	return ceu


## O mar em volta da ilhota do farol, liso e escuro, refletindo o céu.
func _mar(cena: Node3D) -> void:
	var agua := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(900, 900)
	agua.mesh = plano
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#1b2d6b")
	mat.roughness = 0.12
	mat.metallic = 0.25
	agua.material_override = mat
	cena.add_child(agua)
	agua.global_position = FarolIlha.CENTRO + Vector3.DOWN * 0.05


## Estrelinhas saem do céu e entram no bocal da nave, e as estrelas pintadas no céu somem.
func _sugar_estrelas(cena: Node3D, nave: Aspiratrao, cam: Camera3D, ceu: ProceduralSkyMaterial, t: float) -> void:
	create_tween().tween_property(ceu, "sky_cover_modulate:a", 0.0, 3.5 * t)
	var brilho := StandardMaterial3D.new()
	brilho.albedo_color = Color("fff1a8")
	brilho.emission_enabled = true
	brilho.emission = Color("ffd23f")
	brilho.emission_energy_multiplier = 3.0
	var frente := -cam.global_basis.z
	var lado := cam.global_basis.x
	for k in 26:
		var e := MeshInstance3D.new()
		e.mesh = Forma.estrela(0.9, 0.4, 0.3)
		e.material_override = brilho
		cena.add_child(e)
		e.global_position = cam.global_position + frente * randf_range(40, 70) + lado * randf_range(-45, 45) + Vector3.UP * randf_range(-10, 25)
		var ida := e.create_tween()
		ida.tween_interval(randf() * 1.6 * t)
		ida.tween_method(func(k2: float) -> void:
			if is_instance_valid(nave):
				e.global_position = e.global_position.lerp(nave.bocal.global_position, k2 * 0.25)
				e.scale = Vector3.ONE * maxf(1.0 - k2, 0.05),
			0.0, 1.0, 1.6 * t)
		ida.tween_callback(e.queue_free)


# --- o final -----------------------------------------------------------------------------

## A nave vencida (o Rei ganhou a estrelinha de bolso, FaseNave): lá fora, à noite, as estrelas saem do bocal do
## Aspiratrão e voltam para o céu, com fogos em cima do farol; depois, a festa na porta do farol (o Faísca, o Rei
## pequenininho com a estrelinha e as Bolotas dançando), a frase da história ("Às vezes falta só um convite") e o "Fim!".
## Termina no farol, de volta ao jogo (dá para continuar juntando o que faltou).
func _final_da_nave() -> void:
	if _em_cena:
		return
	_em_cena = true
	_trocando = true
	final_visto = true
	_salvar()
	var t := 0.35 if rapido else 1.0
	faisca.controle_ligado = false
	await _escurecer(1.0, 0.6 * t)
	hud.esconder_chefe()
	if is_instance_valid(nivel):
		nivel.queue_free()
	nivel = null
	lugar = "final"
	hud.visible = false
	faisca.tirar_poderes()
	_esconder_faisca()
	tocar_musica("final")
	var cena := Node3D.new()
	cena.name = "Final"
	add_child(cena)
	var ceu := _noite(cena)
	ceu.sky_cover_modulate = Color(1, 1, 1, 0.0)
	_mar(cena)
	var farol := FarolIlha.new()
	cena.add_child(farol)
	farol.aberto = true
	farol.atualizar()
	var porta := farol.porta()
	var para_praia := -FarolIlha.DIRECAO
	var lado := Vector3(para_praia.z, 0, -para_praia.x)
	var cam := Camera3D.new()
	cam.fov = 58.0
	cena.add_child(cam)
	cam.make_current()
	cam.global_position = porta + para_praia * 34.0 + lado * 8.0 + Vector3.UP * 4.0
	cam.look_at(farol.global_position + Vector3.UP * 30.0)
	var nave := Aspiratrao.new()
	nave.name = "Aspiratrao"
	nave.scale = Vector3.ONE * 1.4
	cena.add_child(nave)
	nave.global_position = farol.global_position + Vector3.UP * 44.0 - para_praia * 10.0
	await _escurecer(0.0, 0.8 * t)
	# 1. As estrelas saem do bocal e voltam para o céu.
	_devolver_estrelas(cena, nave, cam, ceu, t)
	faixa("As estrelas voltaram pro céu!", "O céu da Ilha Cafuné acendeu de novo", Color("#ffd23f"), 3.6 * t)
	await get_tree().create_timer(4.0 * t).timeout
	# 2. Os fogos em cima do farol.
	for k in 6:
		var onde := farol.global_position + Vector3.UP * randf_range(30.0, 46.0) + lado * randf_range(-18.0, 18.0) - para_praia * randf_range(-6.0, 6.0)
		Fx.confetti(cena, onde, 50, 7.0)
		Sfx.play(self, "estouro", -2.0, 0.1)
		faisca.festa_no_controle("premio")
		await get_tree().create_timer(0.45 * t).timeout
	await get_tree().create_timer(1.2 * t).timeout
	# 3. A festa na porta do farol.
	await _escurecer(1.0, 0.4 * t)
	nave.queue_free()
	_festa_do_final(cena, porta, para_praia, lado)
	_mostrar_faisca()
	faisca.controle_ligado = false
	faisca.limite_queda = -1000.0
	faisca.teleportar(porta + para_praia * 4.0 + Vector3.UP * 0.1)
	cam.global_position = porta + para_praia * 15.0 + lado * 4.0 + Vector3.UP * 4.0
	cam.look_at(porta + para_praia * 4.0 + Vector3.UP * 1.6)
	cam.make_current()
	var olhar := cam.global_position - faisca.global_position
	faisca.visual.rotation.y = atan2(olhar.x, olhar.z)
	faisca.robo.animar("festa/Cheering", 0.2)
	faisca.robo.expressao("feliz", 8.0)
	await _escurecer(0.0, 0.5 * t)
	faixa("Às vezes falta só um convite.", "O Rei e as Bolotas vieram pra festa no farol", Color("#8ff3ff"), 4.2 * t)
	await get_tree().create_timer(4.6 * t).timeout
	faixa("Fim!", "Obrigado por jogar Faísca e o Céu Apagado", Color("#ffd23f"), 3.6 * t)
	await get_tree().create_timer(4.0 * t).timeout
	await _escurecer(1.0, 0.6 * t)
	cena.queue_free()
	fase_atual = "nave"
	_montar_hub("nave")
	lugar = "hub"
	hud.visible = true
	faisca.robo.animar("geral/Idle_A", 0.1)
	faisca.vida = Jogador.VIDA_MAX
	hud.mostrar_vida(faisca.vida)
	_salvar()
	await _escurecer(0.0, 0.6 * t)
	_em_cena = false
	_trocando = false
	faisca.controle_ligado = true


## Estrelinhas saem do bocal da nave e voam para o céu, e as estrelas pintadas no céu voltam (o contrário da abertura).
func _devolver_estrelas(cena: Node3D, nave: Aspiratrao, cam: Camera3D, ceu: ProceduralSkyMaterial, t: float) -> void:
	create_tween().tween_property(ceu, "sky_cover_modulate:a", 0.95, 3.5 * t)
	var brilho := StandardMaterial3D.new()
	brilho.albedo_color = Color("fff1a8")
	brilho.emission_enabled = true
	brilho.emission = Color("ffd23f")
	brilho.emission_energy_multiplier = 3.0
	var frente := -cam.global_basis.z
	var lado := cam.global_basis.x
	for k in 30:
		var e := MeshInstance3D.new()
		e.mesh = Forma.estrela(0.9, 0.4, 0.3)
		e.material_override = brilho
		cena.add_child(e)
		var de := nave.bocal.global_position
		var ate := cam.global_position + frente * randf_range(50, 80) + lado * randf_range(-50, 50) + Vector3.UP * randf_range(10, 40)
		e.global_position = de
		e.scale = Vector3.ONE * 0.05
		var ida := e.create_tween()
		ida.tween_interval(randf() * 1.6 * t)
		ida.tween_method(func(k2: float) -> void:
			e.global_position = de.lerp(ate, k2) + Vector3.UP * sin(k2 * PI) * 6.0
			e.scale = Vector3.ONE * (minf(k2 * 4.0, 1.0) * (1.0 - maxf(k2 - 0.8, 0.0) * 4.0) + 0.02),
			0.0, 1.0, 2.0 * t)
		ida.tween_callback(e.queue_free)


## A festa na porta do farol: o Rei pequenininho (o mesmo jeito do chefe: a coroa torta, a touca e a capa) segurando a
## estrelinha de bolso, e as Bolotas dançando em meia-roda atrás do Faísca.
func _festa_do_final(cena: Node3D, porta: Vector3, para_praia: Vector3, lado: Vector3) -> void:
	var meio := porta + para_praia * 4.0
	var rei := Node3D.new()
	cena.add_child(rei)
	rei.global_position = meio + lado * 3.4 + Vector3.UP * 0.05
	rei.rotation.y = atan2(para_praia.x, para_praia.z)
	var corpo: Node3D = load(BolotaMonstro.ALIEN).instantiate()
	corpo.scale = Vector3.ONE * 1.4
	rei.add_child(corpo)
	for parte in ChefeRei.enfeites(1.4 / ChefeRei.ESCALA):
		if parte.name == "Cetro":
			continue
		rei.add_child(parte)
	var estrela := MeshInstance3D.new()
	estrela.mesh = Forma.estrela(0.35, 0.15, 0.14)
	var ouro := StandardMaterial3D.new()
	ouro.albedo_color = Color("fff1a8")
	ouro.emission_enabled = true
	ouro.emission = Color("ffd23f")
	ouro.emission_energy_multiplier = 3.0
	estrela.material_override = ouro
	estrela.position = Vector3(0.9, 1.5, 0.7)
	rei.add_child(estrela)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ffd86a")
	luz.light_energy = 1.6
	luz.omni_range = 4.0
	estrela.add_child(luz)
	_dancar(corpo)
	var turma := ["Alien", "Mushroom", "Pig", "Penguin", "Cactus", "Bee"]
	for k in turma.size():
		var b: Node3D = load(BolotaMonstro.PASTA + turma[k] + ".gltf").instantiate()
		b.scale = Vector3.ONE * BolotaMonstro.ESCALA
		cena.add_child(b)
		var a := lerpf(-1.1, 1.1, k / float(turma.size() - 1))
		var atras := -para_praia.rotated(Vector3.UP, a)
		b.global_position = meio + atras * 3.6 + Vector3.UP * (1.2 if turma[k] == "Bee" else 0.05)
		b.rotation.y = atan2(-atras.x, -atras.z)
		_dancar(b)


func _dancar(modelo: Node3D) -> void:
	var achados := modelo.find_children("*", "AnimationPlayer", true, false)
	if achados.is_empty():
		return
	var ap := achados[0] as AnimationPlayer
	for nome in ["Dance", "Flying", "Yes"]:
		if ap.has_animation(nome):
			ap.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
			ap.play(nome)
			return


# --- save --------------------------------------------------------------------------------

func carregar(dados: Dictionary) -> void:
	estrelas = dados.get("estrelas", {})
	grandes = dados.get("grandes", [])
	# Até 2026-11-11 a chave era "vaga_lumes" (os três de cada fase eram vaga-lumes).
	faisquinhas = dados.get("faisquinhas", dados.get("vaga_lumes", {}))
	premios_vistos = dados.get("premios", [])
	chefes = dados.get("chefes", [])
	moedas = int(dados.get("moedas", 0))
	# Até 2026-11-12 saíam chapéus no lugar das tintas: quem já tinha ganha as tintas (e volta à cor de fábrica).
	brindes = Brindes.migrar(dados.get("brindes", []))
	tinta = String(dados.get("tinta", ""))
	if not tinta in brindes:
		tinta = ""
	if is_instance_valid(faisca) and faisca.robo:
		faisca.robo.pintar(Brindes.cor_de(tinta), Brindes.metal(tinta))
	abertura_vista = dados.get("abertura", false)
	final_visto = dados.get("final", false)


func dados_salvos() -> Dictionary:
	return {"estrelas": estrelas, "grandes": grandes, "faisquinhas": faisquinhas, "premios": premios_vistos, "chefes": chefes, "moedas": moedas,
		"brindes": brindes, "tinta": tinta, "abertura": abertura_vista, "final": final_visto}


func _salvar() -> void:
	FaiscaSave.gravar(dados_salvos())


func _fase(id: String) -> Dictionary:
	for f in FASES:
		if f.id == id:
			return f
	return {}


## Junta os nomes novos (sem repetir) na lista de `qual` (estrelas ou Faisquinhas) da fase `id`.
func _juntar(id: String, novos: Array, qual: Dictionary) -> void:
	var lista: Array = qual.get(id, [])
	for n in novos:
		if not n in lista:
			lista.append(n)
	qual[id] = lista


func _como_dicionario(lista: Array) -> Dictionary:
	var d := {}
	for n in lista:
		d[str(n)] = true
	return d


## Recebe a entrada da pausa mesmo com o jogo pausado.
class Escuta:
	extends Node
	var ao_apertar: Callable

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _unhandled_input(event: InputEvent) -> void:
		if ao_apertar.is_valid():
			ao_apertar.call(event)
