class_name MenuPrincipal
extends Control
## A primeira tela do jogo (pedido do usuário em 2026-11-10: "ficou estranho termos o jogo de tiro contra os
## esqueletos e dentro dele o jogo de plataforma com acesso direto"): dois cartões grandes, cada um com o boneco
## 3D de verdade dando tchau quando marcado, para escolher entre a Festa na Ilha (o tiro contra os esqueletos,
## scenes/main.tscn) e o Faísca (o jogo de plataforma, scenes/faisca.tscn). Cada cartão mostra o progresso
## salvo daquele jogo; embaixo ficam os Ajustes (som, câmera e vibração, PainelAjustes) e o "Sair do jogo". Os dois jogos voltam aqui pela pausa ("Menu principal").
## Também é a porta dos testes: quem roda com --algum-teste vai direto para a cena dele.
## Testes: --menu-principal (confere) e --menu-principal-captura (fotos em tools/capturas/menu/).

const CENA := "res://scenes/menu_principal.tscn"
const ILHA := "res://scenes/main.tscn"
const MODOS := ["--menu-principal", "--menu-principal-captura"]
## Chave, nome, o que faz, o ícone dessa linha (a miniatura de um blaster ou uma estrela), o boneco e a cena.
const CARTOES := [
	["ilha", "Festa na Ilha", "Blasters de doce contra os esqueletos", "res://assets/ui/loja/pacoca.png", "menino", ILHA],
	["faisca", "Faísca", "Pula, voa e acende as estrelas", "estrela", "faisca", FaiscaJogo.CENA],
]
const TAMANHO_CARTAO := Vector2(380, 470)
const TAMANHO_FOTO := Vector2(356, 300)

## Botão de cada cartão, pela chave (os testes apertam por aqui).
var cartoes := {}
var botao_sair: Button
var botao_ajustes: Button
var painel_ajustes: PainelAjustes
## Nos testes, a cena escolhida fica anotada aqui em vez de trocar.
var destino := ""
var testando := false
var _fotos := {}
var _progresso := {}
var _escuro: ColorRect
var _centro: CenterContainer
var _indo := false


func _ready() -> void:
	var args := Array(OS.get_cmdline_user_args())
	if args.any(func(a: String) -> bool: return a in FaiscaJogo.MODOS):
		get_tree().change_scene_to_file.call_deferred(FaiscaJogo.CENA)
		return
	if args.any(func(a: String) -> bool: return a.begins_with("--") and not a in MODOS):
		get_tree().change_scene_to_file.call_deferred(ILHA)
		return
	testando = not args.is_empty()
	Controles.configurar()
	Sfx.setup_buses()
	Ajustes.carregar(testando)
	Sfx.music(self, "tema")
	if not testando:
		# A Parte 2 jogada dentro da ilha vira o save do Faísca antes que a ilha salve a campanha sem ela.
		FaiscaSave.migrar()
	_montar()
	_atualizar_progresso()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	cartoes.ilha.grab_focus.call_deferred()
	if "--menu-principal" in args:
		_testar()
	elif "--menu-principal-captura" in args:
		_fotografar()


func _montar() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fundo := TextureRect.new()
	var gradiente := GradientTexture2D.new()
	gradiente.gradient = Gradient.new()
	gradiente.gradient.set_color(0, Color("#2b2163"))
	gradiente.gradient.set_color(1, Color("#0f1638"))
	gradiente.fill_from = Vector2(0.5, 0.0)
	gradiente.fill_to = Vector2(0.5, 1.0)
	fundo.texture = gradiente
	fundo.stretch_mode = TextureRect.STRETCH_SCALE
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	_estrelinhas_do_fundo()
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	_centro = centro
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 18)
	centro.add_child(caixa)
	var titulo := Label.new()
	titulo.text = "Ilha Cafuné"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 64)
	titulo.add_theme_color_override("font_color", MenuKit.GOLD)
	titulo.add_theme_constant_override("outline_size", 14)
	titulo.add_theme_color_override("font_outline_color", Color("#3a1f6b"))
	caixa.add_child(titulo)
	var fileira := HBoxContainer.new()
	fileira.alignment = BoxContainer.ALIGNMENT_CENTER
	fileira.add_theme_constant_override("separation", 40)
	caixa.add_child(fileira)
	for spec in CARTOES:
		_cartao(fileira, spec)
	var folga := Control.new()
	folga.custom_minimum_size = Vector2(0, 8)
	caixa.add_child(folga)
	var embaixo := HBoxContainer.new()
	embaixo.alignment = BoxContainer.ALIGNMENT_CENTER
	embaixo.add_theme_constant_override("separation", 20)
	caixa.add_child(embaixo)
	botao_ajustes = MenuKit.icon_button("Ajustes", "ajustes", self, 230)
	botao_ajustes.pressed.connect(abrir_ajustes)
	embaixo.add_child(botao_ajustes)
	botao_sair = MenuKit.icon_button("Sair do jogo", "sair", self, 230)
	botao_sair.pressed.connect(func() -> void:
		Sfx.play(self, "ui_ok", 0.0, 0.0)
		get_tree().quit())
	embaixo.add_child(botao_sair)
	_ligar_foco()
	painel_ajustes = PainelAjustes.new()
	add_child(painel_ajustes)
	painel_ajustes.montar(self)
	painel_ajustes.hide()
	painel_ajustes.fechou.connect(func() -> void:
		_centro.show()
		botao_ajustes.grab_focus.call_deferred())
	_escuro = ColorRect.new()
	_escuro.color = Color.BLACK
	_escuro.modulate.a = 0.0
	_escuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_escuro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_escuro)


## Pontinhos de estrela espalhados pelo fundo, piscando devagar.
func _estrelinhas_do_fundo() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in 26:
		var e := MenuIcon.new("estrela", Color.WHITE, rng.randf_range(10.0, 22.0))
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		e.anchor_left = rng.randf()
		e.anchor_right = e.anchor_left
		e.anchor_top = rng.randf()
		e.anchor_bottom = e.anchor_top
		e.modulate.a = rng.randf_range(0.15, 0.45)
		add_child(e)
		var tw := e.create_tween().set_loops()
		tw.tween_property(e, "modulate:a", 0.1, rng.randf_range(1.2, 2.6))
		tw.tween_property(e, "modulate:a", rng.randf_range(0.3, 0.6), rng.randf_range(1.2, 2.6))


## O cartão entra na fileira antes de montar: o retrato precisa estar na árvore para mostrar o boneco.
func _cartao(fileira: HBoxContainer, spec: Array) -> void:
	var chave: String = spec[0]
	var boneco: String = spec[4]
	var cor: Color = Portrait.BACKGROUNDS[boneco]
	var b := Button.new()
	b.name = chave
	fileira.add_child(b)
	b.custom_minimum_size = TAMANHO_CARTAO
	var normal := MenuKit.box(MenuKit.CARD, 26, cor.darkened(0.15), 3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("hover_pressed", normal)
	b.add_theme_stylebox_override("pressed", MenuKit.box(MenuKit.BUTTON_PRESSED, 26, cor, 3))
	b.add_theme_stylebox_override("focus", MenuKit.focus_style(28, 6))
	var caixa := VBoxContainer.new()
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_theme_constant_override("separation", 8)
	b.add_child(caixa)
	caixa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	var moldura := Panel.new()
	moldura.custom_minimum_size = TAMANHO_FOTO
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moldura.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	moldura.add_theme_stylebox_override("panel", MenuKit.box(cor, 18))
	caixa.add_child(moldura)
	var foto := Portrait.new(TAMANHO_FOTO)
	moldura.add_child(foto)
	foto.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	foto.show_character(boneco)
	_fotos[chave] = foto
	var nome := Label.new()
	nome.text = spec[1]
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.add_theme_font_size_override("font_size", 36)
	caixa.add_child(nome)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 8)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(linha)
	if spec[3] == "estrela":
		linha.add_child(MenuIcon.new("estrela", Color.WHITE, 24))
	else:
		var pic := TextureRect.new()
		pic.texture = load(spec[3])
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.custom_minimum_size = Vector2(42, 26)
		linha.add_child(pic)
	var oque := Label.new()
	oque.text = spec[2]
	oque.add_theme_font_size_override("font_size", 17)
	oque.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	linha.add_child(oque)
	var progresso := Label.new()
	progresso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progresso.add_theme_font_size_override("font_size", 18)
	progresso.add_theme_color_override("font_color", MenuKit.GOLD)
	caixa.add_child(progresso)
	_progresso[chave] = progresso
	b.resized.connect(func() -> void: b.pivot_offset = b.size * 0.5)
	b.focus_entered.connect(func() -> void:
		Sfx.play(self, "ui_mover", 0.0, 0.0)
		botao_sair.focus_neighbor_top = botao_sair.get_path_to(b)
		botao_ajustes.focus_neighbor_top = botao_ajustes.get_path_to(b)
		foto.cheer(true)
		b.create_tween().tween_property(b, "scale", Vector2.ONE * 1.05, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	b.focus_exited.connect(func() -> void:
		foto.cheer(false)
		b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.1))
	MenuKit.focus_on_mouse_move(b)
	b.pressed.connect(escolher.bind(spec[5]))
	cartoes[chave] = b


## Direcional: os lados andam entre os cartões (sem dar a volta), para baixo vai aos Ajustes (e dali ao Sair) e de lá
## volta ao cartão.
func _ligar_foco() -> void:
	var ilha: Button = cartoes.ilha
	var faisca: Button = cartoes.faisca
	ilha.focus_neighbor_left = ilha.get_path_to(ilha)
	ilha.focus_neighbor_right = ilha.get_path_to(faisca)
	faisca.focus_neighbor_left = faisca.get_path_to(ilha)
	faisca.focus_neighbor_right = faisca.get_path_to(faisca)
	for b: Button in [ilha, faisca]:
		b.focus_neighbor_top = b.get_path_to(b)
		b.focus_neighbor_bottom = b.get_path_to(botao_ajustes)
	for b: Button in [botao_ajustes, botao_sair]:
		b.focus_neighbor_top = b.get_path_to(ilha)
		b.focus_neighbor_bottom = b.get_path_to(b)
	botao_ajustes.focus_neighbor_left = botao_ajustes.get_path_to(botao_ajustes)
	botao_ajustes.focus_neighbor_right = botao_ajustes.get_path_to(botao_sair)
	botao_sair.focus_neighbor_left = botao_sair.get_path_to(botao_ajustes)
	botao_sair.focus_neighbor_right = botao_sair.get_path_to(botao_sair)


## Embaixo de cada cartão, onde parou: a etapa da campanha da ilha e as estrelinhas do Faísca.
func _atualizar_progresso() -> void:
	var ilha: Label = _progresso.ilha
	ilha.text = "Continuar · " + SaveGame.stage_label(SaveGame.read().get("etapa", "prologo")) if SaveGame.exists() else "Começar"
	var faisca: Label = _progresso.faisca
	var dados := FaiscaSave.ler()
	var n := 0
	for id in dados.get("estrelas", {}):
		n += (dados.estrelas[id] as Array).size()
	var grandes := (dados.get("grandes", []) as Array).size()
	faisca.text = "Começar" if not FaiscaSave.tem_progresso(dados) else "%d %s · %d %s" % [n, "estrelinha" if n == 1 else "estrelinhas",
			grandes, "Estrela Grande" if grandes == 1 else "Estrelas Grandes"]


func abrir_ajustes() -> void:
	Sfx.play(self, "ui_ok", 0.0, 0.0)
	_centro.hide()
	painel_ajustes.abrir()


## B ou Esc fecham os Ajustes.
func _unhandled_input(event: InputEvent) -> void:
	if painel_ajustes and painel_ajustes.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu")):
		painel_ajustes.fechar()
		get_viewport().set_input_as_handled()


func escolher(cena: String) -> void:
	if _indo:
		return
	_indo = true
	Sfx.play(self, "ui_ok", 0.0, 0.0)
	if testando:
		destino = cena
		_indo = false
		return
	var tw := _escuro.create_tween()
	tw.tween_property(_escuro, "modulate:a", 1.0, 0.3)
	await tw.finished
	get_tree().change_scene_to_file(cena)


# --- testes ------------------------------------------------------------------------------

func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout


func _botao(botao: JoyButton) -> void:
	for apertado in [true, false]:
		var ev := InputEventJoypadButton.new()
		ev.button_index = botao
		ev.pressed = apertado
		Input.parse_input_event(ev)
		await get_tree().process_frame


func _conferir(rotulo: String, ok: bool, detalhe := "") -> bool:
	print("%s %s %s" % ["OK    " if ok else "FALHOU", rotulo, detalhe])
	return ok


## Os dois cartões com o boneco, o direcional andando entre eles e até o Sair, e cada um levando à cena certa.
func _testar() -> void:
	var ok := true
	await _esperar(0.6)
	var foco := get_viewport().gui_get_focus_owner()
	ok = _conferir("abre com dois cartões e o da ilha marcado", cartoes.size() == 2 and foco == cartoes.ilha and _fotos.ilha.key == "menino"
			and _fotos.faisca.key == "faisca") and ok
	await _botao(JOY_BUTTON_DPAD_RIGHT)
	await _esperar(0.2)
	ok = _conferir("o direcional passa para o cartão do Faísca, que cresce", get_viewport().gui_get_focus_owner() == cartoes.faisca
			and cartoes.faisca.scale.x > 1.01) and ok
	await _botao(JOY_BUTTON_DPAD_RIGHT)
	await _esperar(0.1)
	ok = _conferir("na ponta, não dá a volta", get_viewport().gui_get_focus_owner() == cartoes.faisca) and ok
	await _botao(JOY_BUTTON_DPAD_DOWN)
	await _esperar(0.1)
	ok = _conferir("para baixo vai aos Ajustes", get_viewport().gui_get_focus_owner() == botao_ajustes) and ok
	await _botao(JOY_BUTTON_DPAD_RIGHT)
	await _esperar(0.1)
	ok = _conferir("e para o lado, ao Sair do jogo", get_viewport().gui_get_focus_owner() == botao_sair) and ok
	await _botao(JOY_BUTTON_DPAD_UP)
	await _esperar(0.1)
	ok = _conferir("e para cima volta ao cartão de antes", get_viewport().gui_get_focus_owner() == cartoes.faisca) and ok
	await _botao(JOY_BUTTON_A)
	await _esperar(0.2)
	ok = _conferir("A no cartão do Faísca leva ao jogo do Faísca", destino == FaiscaJogo.CENA, "(%s)" % destino) and ok
	cartoes.ilha.grab_focus()
	await _esperar(0.1)
	await _botao(JOY_BUTTON_A)
	await _esperar(0.2)
	ok = _conferir("A no cartão da ilha leva à Festa na Ilha", destino == ILHA, "(%s)" % destino) and ok
	ok = await _testar_ajustes() and ok
	# Saves de teste, em outros arquivos (nunca os de quem joga): sem nada, os dois cartões dizem Começar.
	SaveGame.path = "user://teste_menu_campanha.json"
	FaiscaSave.path = "user://teste_menu_faisca.json"
	FaiscaSave.enabled = true
	SaveGame.erase()
	FaiscaSave.apagar()
	_atualizar_progresso()
	ok = _conferir("sem save, os dois cartões dizem Começar", _progresso.ilha.text == "Começar" and _progresso.faisca.text == "Começar",
			"(%s | %s)" % [_progresso.ilha.text, _progresso.faisca.text]) and ok
	SaveGame.write({"etapa": "cidade"})
	FaiscaSave.gravar({"estrelas": {"1-1": ["a", "b", "c"], "farol": ["f"]}, "grandes": ["1-1"]})
	_atualizar_progresso()
	ok = _conferir("com save, cada cartão mostra onde parou", _progresso.ilha.text == "Continuar · Lanternas da cidade"
			and _progresso.faisca.text == "4 estrelinhas · 1 Estrela Grande", "(%s | %s)" % [_progresso.ilha.text, _progresso.faisca.text]) and ok
	SaveGame.erase()
	FaiscaSave.apagar()
	print("RESULTADO: ", "tudo certo" if ok else "com falhas")
	get_tree().quit(0 if ok else 1)


## Os Ajustes: o botão abre o painel por cima dos cartões, o direcional muda a música (o canal abaixa na hora) e
## liga a câmera invertida, e o B fecha gravando num arquivo de teste e volta ao botão.
func _testar_ajustes() -> bool:
	var ok := true
	Ajustes.path = "user://teste_menu_ajustes.json"
	Ajustes.enabled = true
	Ajustes.padrao()
	if FileAccess.file_exists(Ajustes.path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Ajustes.path))
	var canal := AudioServer.get_bus_index(Sfx.BUS_MUSIC)
	var antes := AudioServer.get_bus_volume_db(canal)
	botao_ajustes.grab_focus()
	await _esperar(0.1)
	await _botao(JOY_BUTTON_A)
	await _esperar(0.3)
	ok = _conferir("o botão Ajustes abre o painel, com a Música marcada", painel_ajustes.visible and not _centro.visible
			and get_viewport().gui_get_focus_owner() == painel_ajustes.controles.musica) and ok
	await _botao(JOY_BUTTON_DPAD_LEFT)
	await _botao(JOY_BUTTON_DPAD_LEFT)
	await _botao(JOY_BUTTON_DPAD_LEFT)
	await _esperar(0.1)
	ok = _conferir("o direcional para o lado abaixa a música na hora", Ajustes.musica == Ajustes.PASSOS - 3
			and AudioServer.get_bus_volume_db(canal) < antes - 2.0, "(%d, %.1f dB -> %.1f dB)" % [Ajustes.musica, antes, AudioServer.get_bus_volume_db(canal)]) and ok
	# A distância da câmera (2026-11-13) fica logo abaixo da rapidez: o direcional para o lado afasta.
	for i in 3:
		await _botao(JOY_BUTTON_DPAD_DOWN)
	await _esperar(0.1)
	var na_distancia: bool = get_viewport().gui_get_focus_owner() == painel_ajustes.controles.distancia
	await _botao(JOY_BUTTON_DPAD_RIGHT)
	await _esperar(0.1)
	ok = _conferir("três para baixo chega na distância da câmera, e o direcional para o lado afasta", na_distancia
			and Ajustes.distancia == Ajustes.DISTANCIA_PADRAO + 1 and Ajustes.distancia_camera() > 1.1, "(%d)" % Ajustes.distancia) and ok
	await _botao(JOY_BUTTON_DPAD_DOWN)
	await _esperar(0.1)
	var na_chave: bool = get_viewport().gui_get_focus_owner() == painel_ajustes.controles.inverter
	await _botao(JOY_BUTTON_A)
	await _esperar(0.1)
	ok = _conferir("para baixo chega na câmera invertida, e o A liga", na_chave and Ajustes.inverter and Ajustes.sinal_vertical() < 0.0) and ok
	await _botao(JOY_BUTTON_B)
	await _esperar(0.2)
	var gravado: Variant = JSON.parse_string(FileAccess.get_file_as_string(Ajustes.path)) if FileAccess.file_exists(Ajustes.path) else null
	ok = _conferir("o B fecha, volta ao botão Ajustes e grava", not painel_ajustes.visible and _centro.visible
			and get_viewport().gui_get_focus_owner() == botao_ajustes and gravado is Dictionary and int(gravado.musica) == Ajustes.PASSOS - 3
			and gravado.inverter and int(gravado.get("distancia", 0)) == Ajustes.DISTANCIA_PADRAO + 1) and ok
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Ajustes.path))
	Ajustes.padrao()
	return ok


## Fotos do menu (precisa de janela): com o cartão da ilha e com o do Faísca marcado.
func _fotografar() -> void:
	var pasta := "res://tools/capturas/menu/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pasta))
	Input.warp_mouse(Vector2.ZERO)
	for chave in ["ilha", "faisca"]:
		(cartoes[chave] as Button).grab_focus()
		await _esperar(1.4)
		await _salvar_foto(pasta + "m_%s.png" % chave)
	abrir_ajustes()
	await _esperar(0.6)
	await _salvar_foto(pasta + "m_ajustes.png")
	get_tree().quit()


func _salvar_foto(caminho: String) -> void:
	await RenderingServer.frame_post_draw
	var arquivo := ProjectSettings.globalize_path(caminho)
	get_viewport().get_texture().get_image().save_png(arquivo)
	print("foto: ", arquivo)
