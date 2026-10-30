class_name Parte2
extends Node
## Parte 2 da Ilha Cafuné, "Faísca e o Céu Apagado" (seção 11 do doc). Cuida de:
## - o farol na ponta sudeste (FarolIlha), que existe desde o começo, trancado na Parte 1;
## - a abertura, logo depois dos créditos (ou ao carregar uma campanha já terminada): a nave do Rei
##   Bolotão suga as estrelas do céu e o Faísca sai do farol; daí em diante ele está na troca de personagem;
## - o Faísca andando pela ilha: o menino ou a menina fica guardado (invisível, sem colisão, `parked`)
##   acompanhando o Faísca, para moradores, bichos, bandeiras e o "tchibum" continuarem funcionando;
## - dentro do farol: o hub (HubFarol) e as fases. A ilha inteira fica pausada e escondida enquanto isso
##   (os filhos do main, menos a interface, a música e este nó), com o céu dela guardado;
## - as estrelinhas, as Estrelas Grandes e os vaga-lumes de cada fase, que vão para a campanha salva.
## As portas abrem com o total de estrelinhas (cada uma conta uma vez, para sempre).

## As fases, na ordem das portas, com o andar do farol (0 é o térreo; cada andar é um mundo) e o lado da
## parede em graus. "cena" vazia é porta que abre mas ainda mostra "Em breve". Nomes e números das que
## faltam fazer vêm do mapa da seção 11 do doc e mudam quando cada uma for planejada. A nave, no topo,
## pede todas as Estrelas Grandes (`pede_grandes`) em vez de estrelinhas.
const FASES := [
	{"id": "1-1", "nome": "Pulinhos nas Nuvens", "tipo": "ceu", "pede": 0, "andar": 0, "lado": 270,
		"cena": "res://scripts/faisca/fases/fase_1_1.gd", "imagem": "res://assets/faisca/portas/fase_1_1.jpg"},
	{"id": "1-2", "nome": "Túneis do Morro", "tipo": "chao", "pede": 30, "andar": 0, "lado": 90,
		"cena": "res://scripts/faisca/fases/fase_1_2.gd", "imagem": "res://assets/faisca/portas/fase_1_2.jpg"},
	{"id": "2-1", "nome": "Cozinha Gigante", "tipo": "chao", "pede": 60, "andar": 1, "lado": 180,
		"cena": "res://scripts/faisca/fases/fase_2_1.gd", "imagem": "res://assets/faisca/portas/fase_2_1.jpg"},
	{"id": "2-2", "nome": "Nuvens de Algodão-Doce", "tipo": "ceu", "pede": 90, "andar": 1, "lado": 270,
		"cena": "res://scripts/faisca/fases/fase_2_2.gd", "imagem": "res://assets/faisca/portas/fase_2_2.jpg"},
	{"id": "2-3", "nome": "Quarto de Brinquedos", "tipo": "chao", "pede": 120, "andar": 1, "lado": 0, "cena": "", "imagem": ""},
	{"id": "3-1", "nome": "Pico Gelado", "tipo": "ceu", "pede": 150, "andar": 2, "lado": 0, "cena": "", "imagem": ""},
	{"id": "3-2", "nome": "Fábrica de Blocos", "tipo": "chao", "pede": 180, "andar": 2, "lado": 90, "cena": "", "imagem": ""},
	{"id": "3-3", "nome": "Moinhos do Vento", "tipo": "ceu", "pede": 210, "andar": 2, "lado": 180, "cena": "", "imagem": ""},
	{"id": "nave", "nome": "Nave Aspiratrão", "tipo": "nave", "pede": 0, "pede_grandes": 8, "andar": 3, "lado": 270, "cena": "", "imagem": ""},
]
## As estrelinhas da escada do farol também contam.
const ID_FAROL := "farol"
const VOVO_FALA := "O farol? Está fechado desde que eu me aposentei..."

var game: Node
var aberta := false
var faisca_ativo := false
## Onde o Faísca está: "ilha", "hub" ou "fase".
var lugar := "ilha"
var fase_atual := ""
## Nomes das estrelinhas pegas por fase (e no farol), Estrelas Grandes devolvidas e vaga-lumes achados.
var estrelas := {}
var grandes: Array = []
var vaga_lumes := {}
var farol: FarolIlha
var faisca: Jogador
var hud: Hud
var hub: HubFarol
var nivel: Fase
## Nos testes: cena de abertura curtinha.
var rapido := false

var _em_cena := false
var _trocando := false
## Kart com o Faísca: a criança guardada sai vestida de Faísca (Player.set_robo_skin) e ele some até
## ela descer (vestir_crianca).
var _vestida := false
var _guardado := {}
var _ceu_da_ilha: WorldEnvironment
var _controle_antes_do_menu := true


func setup(p_game: Node) -> void:
	game = p_game
	var kid: Player = game.player
	kid.dizzy_started.connect(_tonto_na_ilha)
	kid.respawned.connect(_voltou_na_bandeira)
	farol = FarolIlha.new()
	farol.name = "Farol"
	farol.parte2 = self
	game.add_child(farol)
	farol.entrou.connect(entrar_no_farol)
	var vovo := game.get_node_or_null("Vovo") as Townsperson
	if vovo and not VOVO_FALA in vovo.lines:
		vovo.lines.append(VOVO_FALA)


func _physics_process(delta: float) -> void:
	# O aventureiro guardado acompanha o Faísca pela ilha. Parado, a física dele não corre: o tempo invulnerável
	# depois de um golpe (os corações são divididos) anda aqui.
	if faisca_ativo and lugar == "ilha" and not _em_cena and not _vestida and is_instance_valid(faisca):
		game.player.global_position = faisca.global_position
		game.player.ride_tick(delta)
		faisca.ponto_retorno = game.current_checkpoint.spawn_position()


## Cena ou troca de lugar em andamento (a pausa espera).
func busy() -> bool:
	return _em_cena or _trocando


func total_estrelas() -> int:
	var n := 0
	for id in estrelas:
		n += (estrelas[id] as Array).size()
	return n


## Para onde a seta do objetivo aponta com o Faísca: a porta do farol, na ilha.
func alvo() -> Vector3:
	return farol.porta() + Vector3.UP * 3.0 if lugar == "ilha" else Vector3.INF


# --- o Faísca como personagem ------------------------------------------------------------

func _criar_faisca() -> void:
	if is_instance_valid(faisca):
		return
	faisca = Jogador.new()
	faisca.name = "Faisca"
	add_child(faisca)
	hud = Hud.new()
	add_child(hud)
	hud.hide()
	faisca.vida_mudou.connect(hud.mostrar_vida)
	hud.jogar_de_novo.connect(_fim_aceito)
	_esconder_faisca()


func _esconder_faisca() -> void:
	faisca.visible = false
	faisca.process_mode = Node.PROCESS_MODE_DISABLED


func _mostrar_faisca() -> void:
	faisca.visible = true
	faisca.process_mode = Node.PROCESS_MODE_INHERIT
	faisca.camera.make_current()


## Troca entre o Faísca e o aventureiro (menu de personagem). Só na ilha.
func usar_faisca(ligar: bool) -> void:
	var kid: Player = game.player
	if ligar == faisca_ativo or (ligar and not aberta):
		return
	_criar_faisca()
	if ligar:
		faisca_ativo = true
		faisca.teleportar(kid.global_position + Vector3.UP * 0.1)
		faisca.yaw = kid.get_yaw()
		faisca.visual.rotation.y = faisca.yaw + PI
		_preparar_na_ilha()
		_mostrar_faisca()
		_guardar_aventureiro(true)
		hud.show()
	else:
		faisca_ativo = false
		_ligar_corpo_dividido(false)
		_guardar_aventureiro(false)
		kid.global_position = faisca.global_position
		kid.set_yaw(faisca.yaw)
		_esconder_faisca()
		hud.hide()
	game.set_hud_visible(not ligar)
	if ligar:
		_hud_da_ilha()


func _preparar_na_ilha() -> void:
	# Na ilha quem cuida da água é o main ("tchibum", sem perder coração) e o Back é o celular.
	faisca.limite_queda = -1000.0
	faisca.pode_recomecar = false
	faisca.controle_ligado = true
	faisca.vida = Jogador.VIDA_MAX
	hud.mostrar_vida(faisca.vida)
	hud.mostrar_estrelas(total_estrelas())
	hud.mostrar_vaga_lumes(0, 0)
	_ligar_corpo_dividido(true)


## Na ilha o Faísca e a criança guardada dividem os corações (pedido do usuário em 2026-10-29: o Faísca luta na
## Festa sem fim): o golpe que chega na criança tira o coração dela e empurra o Faísca, e o tonto dela vale para
## ele. No farol e nas fases ele volta a ter os três corações dele.
func _ligar_corpo_dividido(ligar: bool) -> void:
	var kid: Player = game.player
	kid.stand_in = faisca if ligar else null
	faisca.crianca = kid if ligar else null
	hud.mostrar_coracoes(not ligar)
	if ligar:
		_hud_da_ilha()
	else:
		game.set_hud_visible(not faisca_ativo)


## Com o Faísca na ilha, da interface das crianças ficam os corações (divididos) e a faixa de cima (ondas da Festa
## sem fim e corrida); mira, blasters e moedas somem.
func _hud_da_ilha() -> void:
	game.set_hud_visible(false)
	game.hearts_bar.visible = true
	game.wave_label.visible = true


## A criança guardada ficou tonta (o Faísca levou o último golpe na ilha): ele solta fumacinha e fica parado até
## os dois voltarem na bandeira.
func _tonto_na_ilha() -> void:
	if faisca_ativo and lugar == "ilha" and not _vestida and is_instance_valid(faisca):
		faisca.controle_ligado = false
		faisca.velocity = Vector3.ZERO
		faisca._fumacinha()


func _voltou_na_bandeira() -> void:
	if faisca_ativo and lugar == "ilha" and not _vestida and is_instance_valid(faisca):
		faisca.teleportar(game.player.global_position + Vector3.UP * 0.1)
		faisca.controle_ligado = true


## Kart com o Faísca (pedido do usuário em 2026-10-29): quem dirige é a criança guardada, vestida de
## Faísca (o mesmo esqueleto do KayKit, então o volante funciona igual), e ele some até ela descer.
## Desligar põe o Faísca de volta onde ela desceu.
func vestir_crianca(ligar: bool) -> void:
	if ligar == _vestida or not faisca_ativo or lugar != "ilha":
		return
	var kid: Player = game.player
	_vestida = ligar
	if ligar:
		kid.global_position = faisca.global_position
		kid.set_yaw(faisca.yaw)
		kid.set_robo_skin(true)
		_esconder_faisca()
		_guardar_aventureiro(false)
		kid.stand_in = null
	else:
		kid.set_robo_skin(false)
		faisca.teleportar(kid.global_position + Vector3.UP * 0.1)
		faisca.yaw = kid.get_yaw()
		faisca.visual.rotation.y = faisca.yaw + PI
		_mostrar_faisca()
		_guardar_aventureiro(true)
		kid.stand_in = faisca
		faisca.controle_ligado = not kid.dizzy
		_hud_da_ilha()


func vestida() -> bool:
	return _vestida


func _guardar_aventureiro(guardar: bool) -> void:
	var kid: Player = game.player
	kid.parked = guardar
	kid.input_enabled = not guardar
	kid.visible = not guardar
	kid.set_physics_process(not guardar)
	kid.collision_layer = 0 if guardar else 1 << 1
	kid.velocity = Vector3.ZERO
	if not guardar:
		kid.camera.make_current()


## Depois do "tchibum" do main o aventureiro guardado já voltou para a bandeira: o Faísca vai junto.
func depois_do_tchibum() -> void:
	if faisca_ativo and lugar == "ilha":
		faisca.teleportar(game.player.global_position + Vector3.UP * 0.1)


func menu_abriu() -> void:
	if not is_instance_valid(faisca):
		return
	_controle_antes_do_menu = faisca.controle_ligado
	hud.visible = false


## Fechou o menu: o controle volta um instante depois, para o A que confirmou não virar pulo.
func menu_fechou() -> void:
	if not is_instance_valid(faisca) or not faisca_ativo:
		return
	hud.visible = true
	if _controle_antes_do_menu:
		faisca.controle_ligado = false
		await get_tree().create_timer(0.2).timeout
		if not busy():
			faisca.controle_ligado = true


# --- ilha, farol e fases ----------------------------------------------------------------

## Pausa e esconde a ilha inteira (ou devolve), menos a interface, a música e a Parte 2.
func _ligar_ilha(ligada: bool) -> void:
	if not ligada:
		_guardado.clear()
		for c in game.get_children():
			if c == self or c.process_mode == Node.PROCESS_MODE_ALWAYS:
				continue
			if c is WorldEnvironment:
				_ceu_da_ilha = c
				continue
			_guardado[c] = [c.process_mode, (c as Node3D).visible if c is Node3D else true]
			c.process_mode = Node.PROCESS_MODE_DISABLED
			if c is Node3D:
				(c as Node3D).visible = false
		if _ceu_da_ilha:
			game.remove_child(_ceu_da_ilha)
	else:
		if _ceu_da_ilha and not _ceu_da_ilha.is_inside_tree():
			game.add_child(_ceu_da_ilha)
		for c in _guardado:
			if is_instance_valid(c):
				c.process_mode = _guardado[c][0]
				if c is Node3D:
					(c as Node3D).visible = _guardado[c][1]
		_guardado.clear()


func _escurecer(alfa: float, segundos: float) -> void:
	var fade: ColorRect = game.fade
	var tw := fade.create_tween()
	tw.tween_property(fade, "modulate:a", alfa, segundos)
	await tw.finished


## O Faísca encostou na porta do farol: entra no hub.
func entrar_no_farol() -> void:
	if _trocando or _em_cena or not faisca_ativo or lugar != "ilha":
		return
	_trocando = true
	faisca.controle_ligado = false
	await _escurecer(1.0, 0.35)
	_ligar_ilha(false)
	_ligar_corpo_dividido(false)
	_montar_hub("")
	lugar = "hub"
	_salvar()
	await _escurecer(0.0, 0.45)
	faisca.controle_ligado = true
	_trocando = false


## Pausa > "Voltar para a ilha" (no hub) ou "Sair da fase" (numa fase).
func sair_pela_pausa() -> void:
	if lugar == "fase":
		sair_da_fase()
	elif lugar == "hub":
		voltar_para_ilha()


func voltar_para_ilha() -> void:
	if _trocando or lugar != "hub":
		return
	_trocando = true
	faisca.controle_ligado = false
	await _escurecer(1.0, 0.35)
	hub.queue_free()
	hub = null
	_ligar_ilha(true)
	lugar = "ilha"
	var porta := farol.porta()
	faisca.teleportar(porta + Vector3.UP * 0.2)
	var para_praia := -FarolIlha.DIRECAO
	faisca.yaw = atan2(-para_praia.x, -para_praia.z)
	faisca.visual.rotation.y = faisca.yaw + PI
	faisca.pitch = -0.32
	_preparar_na_ilha()
	game.player.global_position = faisca.global_position
	_salvar()
	await _escurecer(0.0, 0.45)
	faisca.controle_ligado = true
	_trocando = false


func _montar_hub(volta_de: String) -> void:
	hub = HubFarol.new()
	hub.name = "DentroDoFarol"
	hub.volta_de = volta_de
	hub.grandes = grandes.duplicate()
	hub.ja_pegas = _como_dicionario(estrelas.get(ID_FAROL, []))
	var total := total_estrelas()
	for f in FASES:
		var pede_grandes := int(f.get("pede_grandes", 0))
		var falta := maxi(pede_grandes - grandes.size(), 0) if pede_grandes > 0 else maxi(int(f.pede) - total, 0)
		hub.portas.append({"id": f.id, "nome": f.nome, "tipo": f.tipo, "andar": f.andar, "lado": f.lado, "pede": f.pede,
			"pede_grandes": pede_grandes, "falta": falta, "aberta": falta == 0, "feita": f.cena != "", "imagem": f.imagem,
			"grande": f.id in grandes, "achados": (vaga_lumes.get(f.id, []) as Array).size(), "total_vaga_lumes": 3})
	hub.portas.append({"id": "saida", "nome": "Ilha Cafuné", "tipo": "saida", "andar": 0, "lado": 180})
	add_child(hub)
	hub.estrela_pega.connect(func(_pegas: int, _total: int) -> void:
		_juntar(ID_FAROL, hub.novas, estrelas)
		hud.mostrar_estrelas(total_estrelas())
		hub.atualizar_portas(total_estrelas()))
	hub.porta_escolhida.connect(entrar_fase)
	hub.saiu.connect(voltar_para_ilha)
	faisca.teleportar(hub.inicio)
	faisca.yaw = hub.yaw_inicial()
	faisca.visual.rotation.y = faisca.yaw + PI
	faisca.pitch = -0.25
	faisca.limite_queda = hub.limite_queda
	faisca.ponto_retorno = hub.inicio
	faisca.pode_recomecar = false
	hud.mostrar_estrelas(total_estrelas())
	hud.mostrar_vaga_lumes(0, 0)


func entrar_fase(id: String) -> void:
	var dados := _fase(id)
	if _trocando or lugar != "hub" or dados.is_empty() or dados.cena == "" or total_estrelas() < int(dados.pede) \
			or grandes.size() < int(dados.get("pede_grandes", 0)):
		return
	_trocando = true
	faisca.controle_ligado = false
	await _escurecer(1.0, 0.35)
	hub.queue_free()
	hub = null
	nivel = load(dados.cena).new()
	nivel.name = "Fase"
	nivel.ja_pegas = _como_dicionario(estrelas.get(id, []))
	nivel.ja_achados = _como_dicionario(vaga_lumes.get(id, []))
	add_child(nivel)
	lugar = "fase"
	fase_atual = id
	nivel.estrela_pega.connect(func(pegas: int, _total: int) -> void:
		_juntar(id, nivel.novas, estrelas)
		hud.mostrar_estrelas(pegas))
	nivel.vaga_lume_achado.connect(func(achados: int, total: int) -> void:
		_juntar(id, nivel.novos_vaga_lumes, vaga_lumes)
		hud.mostrar_vaga_lumes(achados, total))
	nivel.posto_aceso.connect(func(p: Posto) -> void: faisca.ponto_retorno = p.ponto())
	nivel.dica.connect(hud.mostrar_dica)
	nivel.estrela_grande_pega.connect(_terminar_fase)
	faisca.limite_queda = nivel.limite_queda
	faisca.pode_recomecar = true
	faisca.balao_de_chiclete = false
	faisca.vida = Jogador.VIDA_MAX
	hud.mostrar_vida(faisca.vida)
	hud.mostrar_estrelas(nivel.pegas)
	hud.mostrar_vaga_lumes(nivel.achados, nivel.vaga_lumes.size())
	faisca.yaw = 0.0
	faisca.pitch = -0.32
	faisca.visual.rotation.y = PI
	_escurecer(0.0, 0.5)
	await _comecar_fase()
	_trocando = false


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
	faisca.controle_ligado = false
	faisca.golpe_atual = -1
	faisca.visual.rotation.y = faisca.yaw
	faisca.robo.animar("festa/Cheering", 0.2)
	nivel.bau.estrela_sobe()
	if not fase_atual in grandes:
		grandes.append(fase_atual)
	_salvar()
	await get_tree().create_timer(2.6).timeout
	if is_instance_valid(nivel):
		hud.mostrar_fim(nivel.nome, nivel.pegas, nivel.total_estrelas(), nivel.achados, nivel.vaga_lumes.size())


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
	nivel.queue_free()
	nivel = null
	_montar_hub(fase_atual)
	lugar = "hub"
	# O poder da fase (o Balão de Chiclete da 2-2) fica lá dentro.
	faisca.balao_de_chiclete = false
	faisca.vida = Jogador.VIDA_MAX
	hud.mostrar_vida(faisca.vida)
	faisca.robo.animar("geral/Idle_A", 0.1)
	_salvar()
	await _escurecer(0.0, 0.45)
	faisca.controle_ligado = true
	_trocando = false


# --- abertura da Parte 2 ---------------------------------------------------------------

## A nave do Rei Bolotão suga as estrelas do céu, o farol acende e o Faísca sai pulando. Depois dos créditos
## a ilha já está de noite e a tela fica escura no fim (o pós-jogo clareia); ao carregar uma campanha já
## terminada, a cena faz a noite e devolve o dia.
func abrir(depois_dos_creditos: bool) -> void:
	if aberta or _em_cena:
		return
	_em_cena = true
	var ending: Ending = game.ending
	var kid: Player = game.player
	var fade: ColorRect = game.fade
	var t := 0.35 if rapido else 1.0
	kid.input_enabled = false
	game.set_hud_visible(false)
	if not depois_dos_creditos:
		fade.modulate.a = 1.0
		ending._set_night(true)
	var cam := Camera3D.new()
	cam.fov = 58.0
	game.add_child(cam)
	cam.make_current()
	# 1. O céu estrelado sobre a praça, e a nave roxa passando.
	cam.global_position = Ending.PLAZA + Vector3(0, 2.5, 30.0)
	cam.look_at(Ending.PLAZA + Vector3(0, 36.0, -24.0))
	var nave := Aspiratrao.new()
	nave.name = "Aspiratrao"
	nave.scale = Vector3.ONE * 1.4
	game.add_child(nave)
	nave.global_position = Ending.PLAZA + Vector3(150, 40, -12)
	var voo := nave.create_tween()
	voo.tween_property(nave, "global_position", Ending.PLAZA + Vector3(-150, 40, -12), 8.0 * t)
	await _escurecer(0.0, 0.8 * t)
	game.banner("Que nave é essa?!", "É o Aspiratrão do Rei Bolotão!", Color("#d9a8ff"), 3.0 * t)
	await get_tree().create_timer(1.8 * t).timeout
	_sugar_estrelas(nave, cam, t)
	await get_tree().create_timer(3.4 * t).timeout
	game.banner("O céu ficou apagado!", "As estrelas caíram pelas ilhas do céu e por lugares aqui embaixo", Color("#ffd23f"), 3.4 * t)
	await get_tree().create_timer(2.8 * t).timeout
	# 2. O farol acende e o Faísca sai pulando.
	await _escurecer(1.0, 0.4 * t)
	nave.queue_free()
	var porta := farol.porta()
	var para_praia := -FarolIlha.DIRECAO
	cam.global_position = porta + para_praia * 11.0 + Vector3.UP * 3.2 + Vector3(para_praia.z, 0, -para_praia.x) * 3.0
	cam.look_at(farol.global_position + Vector3.UP * 7.5)
	await _escurecer(0.0, 0.5 * t)
	await get_tree().create_timer(0.7 * t).timeout
	farol.modelo.acender(true)
	Sfx.play(game, "estouro", 0.0, 0.0)
	Fx.confetti(game, farol.global_position + Vector3.UP * 16.0, 30, 5.0)
	await get_tree().create_timer(0.9 * t).timeout
	_criar_faisca()
	faisca.visible = true
	faisca.process_mode = Node.PROCESS_MODE_INHERIT
	faisca.controle_ligado = false
	faisca.limite_queda = -1000.0
	faisca.teleportar(porta - para_praia * 0.6 + Vector3.UP * 0.1)
	faisca.visual.rotation.y = atan2(para_praia.x, para_praia.z)
	cam.make_current()
	Fx.confetti(game, porta + Vector3.UP * 1.2, 16, 3.0)
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
	game.banner("O Faísca!", "O robozinho que acende as estrelas vai buscar todas de volta", Color("#8ff3ff"), 3.6 * t)
	await get_tree().create_timer(3.4 * t).timeout
	aberta = true
	farol.atualizar()
	await _escurecer(1.0, 0.5 * t)
	_esconder_faisca()
	cam.queue_free()
	kid.camera.make_current()
	_em_cena = false
	if not depois_dos_creditos:
		ending._set_night(false)
		kid.input_enabled = true
		game.set_hud_visible(true)
		anunciar()
		_salvar()
		await _escurecer(0.0, 0.8 * t)


## Faixa que ensina como jogar com o Faísca (depois da abertura).
func anunciar() -> void:
	game.banner("Parte 2 liberada!", "Na pausa, em Trocar de personagem, escolha o Faísca e entre no farol", Color("#8ff3ff"), 5.0)


## Estrelinhas saem do céu e entram no bocal da nave, e as estrelas pintadas no céu somem.
func _sugar_estrelas(nave: Aspiratrao, cam: Camera3D, t: float) -> void:
	var sky: ProceduralSkyMaterial = game.sky_material
	var tw := create_tween()
	tw.tween_property(sky, "sky_cover_modulate:a", 0.0, 3.5 * t)
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
		game.add_child(e)
		e.global_position = cam.global_position + frente * randf_range(40, 70) + lado * randf_range(-45, 45) + Vector3.UP * randf_range(-10, 25)
		var ida := e.create_tween()
		ida.tween_interval(randf() * 1.6 * t)
		ida.tween_method(func(k2: float) -> void:
			if is_instance_valid(nave):
				e.global_position = e.global_position.lerp(nave.bocal.global_position, k2 * 0.25)
				e.scale = Vector3.ONE * maxf(1.0 - k2, 0.05),
			0.0, 1.0, 1.6 * t)
		ida.tween_callback(e.queue_free)


# --- campanha salva ------------------------------------------------------------------

func snapshot() -> Dictionary:
	return {"aberta": aberta, "faisca": faisca_ativo, "lugar": lugar, "estrelas": estrelas, "grandes": grandes, "vaga_lumes": vaga_lumes}


## Volta ao ponto salvo. Quem salvou dentro do farol volta na porta dele, na ilha. Campanha já terminada sem
## a Parte 2 (salva antes dela existir) ganha a abertura uma vez.
func restore(data: Dictionary) -> void:
	aberta = data.get("aberta", false)
	estrelas = data.get("estrelas", {})
	grandes = data.get("grandes", [])
	vaga_lumes = data.get("vaga_lumes", {})
	farol.atualizar()
	var story: Story = game.story
	if aberta and data.get("faisca", false):
		_ligar_faisca.call_deferred(data.get("lugar", "ilha") != "ilha")
	elif not aberta and story.stage == "fim":
		abrir.call_deferred(false)


func _ligar_faisca(na_porta_do_farol: bool) -> void:
	if na_porta_do_farol:
		game.player.global_position = farol.porta() + Vector3.UP * 0.2
	usar_faisca(true)


func _salvar() -> void:
	var story: Story = game.story
	if story:
		story.save()


func _fase(id: String) -> Dictionary:
	for f in FASES:
		if f.id == id:
			return f
	return {}


## Junta os nomes novos (sem repetir) na lista de `qual` (estrelas ou vaga-lumes) da fase `id`.
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
