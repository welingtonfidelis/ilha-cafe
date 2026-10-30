class_name FaiscaSolo
extends Node3D
## O Faísca sozinho, sem a ilha: era o main do projeto Faísca (Projects/others/faisca), antes de ele virar
## a Parte 2 da Ilha Cafuné. Serve para os testes de movimento e golpes e para a 1-1 de ponta a ponta,
## que rodam bem mais rápido sem montar a ilha. O main da Ilha cria este nó no lugar de tudo com:
##   --faisca-teste          a cena de teste (ilha com degraus, plataformas e inimigos de treino)
##   --faisca-smoke          cena de teste: roda alguns segundos e confere que o robô fica de pé no chão
##   --faisca-controle       cena de teste: joga só com eventos de controle simulados e confere cada
##                           comando (andar, pular, flutuar, câmera, estrela, golpes no lugar, giro,
##                           laser e pisão)
##   --faisca-captura        cena de teste: fotos em tools/capturas/faisca/ (precisa de janela)
##   --faisca-fase           1-1: confere a fase de ponta a ponta (ver scripts/faisca/teste_fase.gd)
##   --faisca-fase-captura   1-1: fotos de cada trecho em tools/capturas/faisca/fase/ (precisa de janela)
##   --faisca-fase-1-2       1-2: confere a fase de ponta a ponta (ver scripts/faisca/teste_fase_1_2.gd)
##   --faisca-fase-1-2-captura  1-2: fotos de cada trecho em tools/capturas/faisca/fase_1_2/
##   --faisca-jogar-1-2      1-2 para jogar direto, sem o farol (para conferir de olho)
##   --faisca-fase-2-1       2-1: confere a fase de ponta a ponta (ver scripts/faisca/teste_fase_2_1.gd)
##   --faisca-fase-2-1-captura  2-1: fotos de cada trecho em tools/capturas/faisca/fase_2_1/
##   --faisca-jogar-2-1      2-1 para jogar direto, sem o farol
##   --faisca-fase-2-2       2-2: confere a fase de ponta a ponta (ver scripts/faisca/teste_fase_2_2.gd)
##   --faisca-fase-2-2-captura  2-2: fotos de cada trecho em tools/capturas/faisca/fase_2_2/
##   --faisca-jogar-2-2      2-2 para jogar direto, sem o farol
##   --faisca-monstro        1-1: confere os monstros do Cute Monsters Pack, as animações e a regra de cada tipo
##                           (ver scripts/faisca/teste_monstro.gd)
##   --faisca-monstro-captura   fotos de cada tipo em ação em tools/capturas/faisca/monstro/ (precisa de janela)
## As ações de controle (pular, golpe, recomecar...) vêm do _setup_input do main.

const MODOS := ["--faisca-teste", "--faisca-smoke", "--faisca-controle", "--faisca-captura", "--faisca-fase", "--faisca-fase-captura",
		"--faisca-fase-1-2", "--faisca-fase-1-2-captura", "--faisca-jogar-1-2", "--faisca-fase-2-1", "--faisca-fase-2-1-captura",
		"--faisca-jogar-2-1", "--faisca-fase-2-2", "--faisca-fase-2-2-captura", "--faisca-jogar-2-2", "--faisca-monstro",
		"--faisca-monstro-captura"]
const PASTA_CAPTURAS := "res://tools/capturas/faisca/"

## Cena de teste (só nos modos de teste dela).
var fase: FaseTeste
## A fase de verdade.
var nivel: Fase
var jogador: Jogador
var hud: Hud
## Nos testes da fase, o A da tela de fim não recarrega a cena.
var testando := false
var _teste: TesteFase
var _teste12: TesteFase12
var _teste21: TesteFase21
var _teste22: TesteFase22
var _teste_monstro: TesteMonstro


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var cena_de_teste := "--faisca-teste" in args or "--faisca-smoke" in args or "--faisca-controle" in args or "--faisca-captura" in args
	jogador = Jogador.new()
	hud = Hud.new()
	if cena_de_teste:
		fase = FaseTeste.new()
		add_child(fase)
		jogador.position = fase.inicio
		add_child(jogador)
		add_child(hud)
		fase.estrela_pega.connect(_on_estrela_pega)
		hud.mostrar_vaga_lumes(0, 0)
	else:
		var a_1_2 := "--faisca-fase-1-2" in args or "--faisca-fase-1-2-captura" in args or "--faisca-jogar-1-2" in args
		var a_2_1 := "--faisca-fase-2-1" in args or "--faisca-fase-2-1-captura" in args or "--faisca-jogar-2-1" in args
		var a_2_2 := "--faisca-fase-2-2" in args or "--faisca-fase-2-2-captura" in args or "--faisca-jogar-2-2" in args
		nivel = Fase12.new() if a_1_2 else (Fase21.new() if a_2_1 else (Fase22.new() if a_2_2 else Fase11.new()))
		add_child(nivel)
		jogador.position = nivel.inicio
		jogador.limite_queda = nivel.limite_queda
		add_child(jogador)
		add_child(hud)
		nivel.estrela_pega.connect(func(pegas: int, _total: int): hud.mostrar_estrelas(pegas))
		nivel.vaga_lume_achado.connect(hud.mostrar_vaga_lumes)
		nivel.posto_aceso.connect(func(p: Posto): jogador.ponto_retorno = p.ponto())
		nivel.dica.connect(hud.mostrar_dica)
		nivel.estrela_grande_pega.connect(_terminar_fase)
		hud.jogar_de_novo.connect(func():
			if not testando:
				get_tree().reload_current_scene())
		hud.mostrar_vaga_lumes(0, nivel.vaga_lumes.size())
	jogador.vida_mudou.connect(hud.mostrar_vida)
	hud.mostrar_vida(jogador.vida)

	if "--faisca-smoke" in args:
		_rodar_smoke()
	elif "--faisca-controle" in args:
		_rodar_teste_controle()
	elif "--faisca-captura" in args:
		_rodar_captura()
	elif "--faisca-fase" in args:
		_teste = TesteFase.new(self)
		_teste.rodar()
	elif "--faisca-fase-captura" in args:
		_teste = TesteFase.new(self)
		_teste.capturar()
	elif "--faisca-fase-1-2" in args:
		_teste12 = TesteFase12.new(self)
		_teste12.rodar()
	elif "--faisca-fase-1-2-captura" in args:
		_teste12 = TesteFase12.new(self)
		_teste12.capturar()
	elif "--faisca-fase-2-1" in args:
		_teste21 = TesteFase21.new(self)
		_teste21.rodar()
	elif "--faisca-fase-2-1-captura" in args:
		_teste21 = TesteFase21.new(self)
		_teste21.capturar()
	elif "--faisca-fase-2-2" in args:
		_teste22 = TesteFase22.new(self)
		_teste22.rodar()
	elif "--faisca-fase-2-2-captura" in args:
		_teste22 = TesteFase22.new(self)
		_teste22.capturar()
	elif "--faisca-monstro" in args:
		_teste_monstro = TesteMonstro.new(self)
		_teste_monstro.rodar()
	elif "--faisca-monstro-captura" in args:
		_teste_monstro = TesteMonstro.new(self)
		_teste_monstro.capturar()
	elif nivel:
		_comecar_fase()


## O Faísca desce do céu flutuando, com os jatos ligados, e o controle volta quando ele pisa.
func _comecar_fase() -> void:
	jogador.global_position = nivel.inicio + Vector3(0, 7, 0)
	jogador.ponto_retorno = nivel.inicio
	jogador.controle_ligado = false
	jogador.pouso_suave = true
	jogador.robo.animar("mov/Jump_Idle", 0.1)
	while jogador.pouso_suave:
		await get_tree().physics_frame
	jogador.robo.animar("mov/Jump_Land", 0.05)
	await get_tree().create_timer(0.25).timeout
	jogador.controle_ligado = true


## Pegou a Estrela Grande: o Faísca vira para a câmera e comemora, a estrela sobe para o céu e
## aparece a tela de fim.
func _terminar_fase() -> void:
	jogador.controle_ligado = false
	jogador.golpe_atual = -1
	jogador.visual.rotation.y = jogador.yaw
	jogador.robo.animar("festa/Cheering", 0.2)
	nivel.bau.estrela_sobe()
	await get_tree().create_timer(2.6).timeout
	hud.mostrar_fim(nivel.nome, nivel.pegas, nivel.total_estrelas(), nivel.achados, nivel.vaga_lumes.size())


func _on_estrela_pega(pegas: int, total: int) -> void:
	hud.mostrar_estrelas(pegas)
	if pegas == total and total > 0:
		_comemorar()


## Cena de teste: pegou todas as estrelas, o Faísca para e comemora um pouco.
func _comemorar() -> void:
	jogador.controle_ligado = false
	jogador.robo.animar("festa/Cheering", 0.2)
	await get_tree().create_timer(2.4).timeout
	jogador.controle_ligado = true


# --- testes --------------------------------------------------------------------

func _rodar_smoke() -> void:
	var ok := true
	await _esperar(2.0)
	ok = _conferir("robô de pé no chão", jogador.is_on_floor(), "(y = %.2f)" % jogador.global_position.y) and ok
	ok = _conferir("robô parado respirando", jogador.robo.animacao_atual() == "geral/Idle_A", "(%s)" % jogador.robo.animacao_atual()) and ok
	ok = _conferir("estrelas no cenário", fase.estrelas.size() == 8, "(%d)" % fase.estrelas.size()) and ok
	_terminar(ok)


## Joga só com eventos de controle simulados (como se viessem de um controle de verdade)
## e confere cada comando. Uso: godot --headless --path . -- --controle
func _rodar_teste_controle() -> void:
	var ok := true
	Sfx.logging = true
	await _esperar(0.6)
	ok = _conferir("começa no chão", jogador.is_on_floor()) and ok

	# Analógico esquerdo para a frente: anda (correndo) para longe da câmera.
	var p0 := jogador.global_position
	_eixo(JOY_AXIS_LEFT_Y, -1.0)
	await _esperar(0.5)
	var anim_andando := jogador.robo.animacao_atual()
	await _esperar(0.5)
	_eixo(JOY_AXIS_LEFT_Y, 0.0)
	var andou := (jogador.global_position - p0) * Vector3(1, 0, 1)
	ok = _conferir("analógico esquerdo anda para a frente", andou.length() > 3.0 and andou.z < 0.0, "(%.1f m)" % andou.length()) and ok
	ok = _conferir("corre com o analógico todo inclinado", anim_andando == "mov/Running_A", "(%s)" % anim_andando) and ok
	ok = _conferir("vira para onde anda", absf(angle_difference(jogador.visual.rotation.y, PI)) < 0.2) and ok
	await _esperar(0.6)

	# Toque rápido em A: pulo baixo. Segurando A: pulo alto.
	var y0 := jogador.global_position.y
	_botao(JOY_BUTTON_A, true)
	await _esperar(0.05)
	_botao(JOY_BUTTON_A, false)
	var curto := await _altura_maxima(1.0) - y0
	await _esperar(0.4)
	_botao(JOY_BUTTON_A, true)
	var longo := await _altura_maxima(0.5) - y0
	ok = _conferir("A pula", curto > 0.4, "(%.2f m)" % curto) and ok
	ok = _conferir("segurando A o pulo vai mais alto", longo > curto + 0.5, "(%.2f m)" % longo) and ok

	# Continua segurando: na descida ele flutua, com o laser dos pés (sem jato de fogo desde 2026-10-29).
	await _esperar(0.2)
	ok = _conferir("segurando A na descida flutua", jogador.flutuando and absf(jogador.velocity.y) < 2.0,
			"(vel. vertical %.2f)" % jogador.velocity.y) and ok
	ok = _conferir("flutuando, o laser liga e o jato de fogo não", jogador._feixes[0].visible and not jogador.robo._jatos[0].visible) and ok
	ok = _conferir("flutuando, o zumbido do laser toca (e repete)", jogador._som_laser.playing
			and (jogador._som_laser.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_FORWARD) and ok
	_botao(JOY_BUTTON_A, false)
	await _esperar(1.5)
	ok = _conferir("solta A e pousa", jogador.is_on_floor() and not jogador.flutuando) and ok
	ok = _conferir("pousado, o zumbido do laser para", not jogador._som_laser.playing) and ok

	# Analógico direito gira a câmera.
	var yaw0 := jogador.yaw
	_eixo(JOY_AXIS_RIGHT_X, 1.0)
	await _esperar(0.5)
	_eixo(JOY_AXIS_RIGHT_X, 0.0)
	ok = _conferir("analógico direito gira a câmera", absf(angle_difference(yaw0, jogador.yaw)) > 0.5) and ok

	# Pega uma estrela.
	var antes := fase.pegas
	jogador.global_position = fase.estrelas[0].global_position - Vector3(0, 1.0, 0)
	await _esperar(0.3)
	ok = _conferir("encostar numa estrela pega", fase.pegas == antes + 1 and hud._contador.text == str(antes + 1), "(%s)" % hud._contador.text) and ok

	# Plataforma que vai e volta leva o robô junto.
	jogador.global_position = fase.movel.global_position + Vector3(0, 0.4, 0)
	await _esperar(0.4)
	var x0 := jogador.global_position.x
	var mx0 := fase.movel.global_position.x
	await _esperar(0.8)
	var andou_junto := jogador.global_position.x - x0
	var plataforma_andou := fase.movel.global_position.x - mx0
	ok = _conferir("a plataforma que se mexe leva o robô", jogador.is_on_floor() and absf(andou_junto - plataforma_andou) < 0.3 and absf(plataforma_andou) > 0.3,
			"(robô %.2f m, plataforma %.2f m)" % [andou_junto, plataforma_andou]) and ok

	# Caiu no mar: volta ao começo.
	jogador.global_position = Vector3(60, 5, 60)
	await _esperar(2.5)
	ok = _conferir("caiu da ilha e voltou ao começo", jogador.global_position.distance_to(jogador.ponto_retorno) < 2.0) and ok

	# Back (Share no PlayStation) também volta ao começo.
	jogador.global_position = fase.inicio + Vector3(5, 0, -5)
	await _esperar(0.3)
	await _toque(JOY_BUTTON_BACK)
	ok = _conferir("Back volta ao começo", jogador.global_position.distance_to(jogador.ponto_retorno) < 1.0) and ok

	# X (quadrado): soco direito, soco esquerdo e um direito mais forte derrubam um inimigo de treino (3 de vida).
	# Sem chute desde 2026-10-29 (pedido do usuário: "socos entre braço direito e esquerdo").
	var a0: Alvo = fase.alvos[0]
	jogador.teleportar(a0.global_position + Vector3(0, 0.1, 1.5))
	jogador.visual.rotation.y = PI
	await _esperar(0.3)
	var antes_do_combo := jogador.global_position
	await _toque(JOY_BUTTON_X)
	await _esperar(0.25)
	ok = _conferir("X dá um soco", a0.vida == 2, "(vida %d)" % a0.vida) and ok
	await _toque(JOY_BUTTON_X)
	var anim_esquerdo := jogador.robo.animacao_atual()
	await _esperar(0.02)
	await _toque(JOY_BUTTON_X)
	await _esperar(0.12)
	var anim_forte := jogador.robo.animacao_atual()
	var terceiro := jogador.golpe_atual
	await _esperar(0.4)
	ok = _conferir("o segundo X é o soco do braço esquerdo", anim_esquerdo == "luta/Soco_Esquerdo", "(%s)" % anim_esquerdo) and ok
	ok = _conferir("o terceiro X é o soco forte do braço direito", anim_forte == "luta/Melee_Unarmed_Attack_Punch_A" and terceiro == 2,
			"(%s, golpe %d)" % [anim_forte, terceiro]) and ok
	ok = _conferir("os três socos derrubam o inimigo", a0.derrotado, "(vida %d)" % a0.vida) and ok
	var avanco := Vector2(jogador.global_position.x - antes_do_combo.x, jogador.global_position.z - antes_do_combo.z).length()
	ok = _conferir("o combo é no lugar, sem andar para a frente", avanco < 0.1, "(andou %.2f)" % avanco) and ok

	# X no ar: giro que acerta quem está em volta.
	var a1: Alvo = fase.alvos[1]
	jogador.teleportar(a1.global_position + Vector3(1.2, 0.1, 0))
	await _esperar(0.3)
	_botao(JOY_BUTTON_A, true)
	await _esperar(0.12)
	await _toque(JOY_BUTTON_X)
	var girou := jogador.girando > 0.0
	_botao(JOY_BUTTON_A, false)
	await _esperar(0.5)
	ok = _conferir("X no ar faz o giro", girou) and ok
	ok = _conferir("o giro acerta quem está em volta", a1.vida < a1.vida_max, "(vida %d)" % a1.vida) and ok
	await _esperar(0.8)

	# Segurando A no ar: laser dos pés acerta o inimigo embaixo.
	var a2: Alvo = fase.alvos[2]
	jogador.teleportar(a2.global_position + Vector3(0, 3.6, 0))
	await _esperar(0.2)
	_botao(JOY_BUTTON_A, true)
	await _esperar(0.15)
	var laser_ligado: bool = jogador._feixes[0].visible and jogador._feixes[1].visible
	await _esperar(0.6)
	ok = _conferir("flutuando, os dois lasers ligam", laser_ligado and jogador.flutuando) and ok
	ok = _conferir("o laser acerta o inimigo embaixo", a2.vida < a2.vida_max, "(vida %d)" % a2.vida) and ok
	_botao(JOY_BUTTON_A, false)
	await _esperar(1.0)
	ok = _conferir("sem flutuar, o laser apaga", not jogador._feixes[0].visible) and ok

	# O laser vai dos pés até o chão.
	jogador.teleportar(Vector3(0, 3.5, 6))
	await _esperar(0.2)
	_botao(JOY_BUTTON_A, true)
	await _esperar(0.3)
	var ponta := jogador.ponta_do_laser(0)
	ok = _conferir("o laser vai dos pés até o chão", jogador.flutuando and absf(ponta.y) < 0.15, "(ponta em y = %.2f)" % ponta.y) and ok
	_botao(JOY_BUTTON_A, false)
	await _esperar(1.0)

	# Pedidos de 2026-10-29: no voo sai só o laser (sem o fogo de jato), o voo dura 1 s, e o laser acerta
	# num círculo em volta dele (o anel no chão), não só onde o fio bate.
	jogador.teleportar(Vector3(0, 0.1, 6))
	await _esperar(0.3)
	_botao(JOY_BUTTON_A, true)
	var voo := 0.0
	var so_laser := true
	for i in int(2.5 * Engine.physics_ticks_per_second):
		await get_tree().physics_frame
		if jogador.flutuando:
			voo += 1.0 / Engine.physics_ticks_per_second
			so_laser = so_laser and jogador._feixes[0].visible and jogador._anel_laser.visible \
					and not jogador.robo._jatos.any(func(m: MeshInstance3D) -> bool: return m.visible)
	_botao(JOY_BUTTON_A, false)
	await _esperar(1.0)
	ok = _conferir("no voo aparece só o laser e o anel no chão, sem o fogo de jato", voo > 0.0 and so_laser) and ok
	ok = _conferir("o voo dura 1 s", absf(voo - 1.0) < 0.08, "(%.2f s)" % voo) and ok
	var a4: Alvo = fase.alvos[4]
	jogador.teleportar(a4.global_position + Vector3(1.3, 2.6, 0))
	await _esperar(0.1)
	_botao(JOY_BUTTON_A, true)
	await _esperar(0.6)
	_botao(JOY_BUTTON_A, false)
	await _esperar(1.0)
	ok = _conferir("o laser acerta o inimigo a 1,3 m de lado, sem estar em cima dele", a4.vida < a4.vida_max, "(vida %d)" % a4.vida) and ok

	# Cair em cima de um inimigo: pisão (2 de dano) e quique.
	var a3: Alvo = fase.alvos[3]
	jogador.teleportar(a3.global_position + Vector3(0, 3.0, 0))
	# Ele quica e pode cair de novo no mesmo inimigo (outro pisão): a vida vale no primeiro quique.
	var quicou := false
	var vida_no_quique := a3.vida
	for i in 60:
		await get_tree().physics_frame
		if not quicou and jogador.velocity.y > 5.0:
			quicou = true
			vida_no_quique = a3.vida
	ok = _conferir("cair em cima do inimigo é um pisão", vida_no_quique == a3.vida_max - 2, "(vida %d)" % vida_no_quique) and ok
	ok = _conferir("o pisão quica para o alto", quicou) and ok
	ok = await _movimentos_do_astro() and ok
	# Sons do Faísca (pedido do usuário em 2026-10-29: "faltam sons novos pro faisca lutando, voando, etc").
	var faltando := ["faisca_pulo", "faisca_pouso", "faisca_laser_liga", "faisca_soco", "faisca_soco_forte", "faisca_acerto",
			"faisca_giro", "faisca_pisao", "faisca_carga", "faisca_piao", "faisca_agarra", "faisca_arremesso", "faisca_danca",
			"bolota_ai", "bolota_estoura", "estrelinha"].filter(func(n: String) -> bool: return not n in Sfx.played)
	ok = _conferir("cada ação do Faísca tem o seu som", faltando.is_empty(), "(faltando: %s)" % ", ".join(faltando)) and ok
	_terminar(ok)


## Pedido do usuário em 2026-10-29: giro forte (segurar X), agarrar e arremessar a bolota (Y) e dancinha (seta
## para baixo).
func _movimentos_do_astro() -> bool:
	var ok := true
	await _esperar(0.8)
	# Segurar X no chão: o primeiro soco sai, depois carrega (anel dourado) e gira sozinho acertando em volta.
	var a2: Alvo = fase.alvos[2]
	var a3: Alvo = fase.alvos[3]
	var vivos := fase.alvos.slice(2, 4).filter(func(a: Alvo) -> bool: return not a.derrotado)
	var vidas := vivos.map(func(a: Alvo) -> int: return a.vida)
	jogador.teleportar((a2.global_position + a3.global_position) / 2.0 + Vector3(0, 0.1, 0))
	await _esperar(0.3)
	_botao(JOY_BUTTON_X, true)
	await _esperar(0.55)
	var carregando: bool = jogador._carga > 0.0 and jogador._anel_carga.visible
	var girou := false
	for i in int(1.0 * Engine.physics_ticks_per_second):
		await get_tree().physics_frame
		girou = girou or jogador.giro_forte > 0.0
	_botao(JOY_BUTTON_X, false)
	ok = _conferir("segurando X no chão ele carrega o giro forte", carregando) and ok
	ok = _conferir("com a carga cheia ele gira sozinho", girou) and ok
	var acertou := vivos.size() > 0
	for i in vivos.size():
		acertou = acertou and (vivos[i].derrotado or vivos[i].vida < vidas[i])
	ok = _conferir("o giro forte acerta quem está em volta", acertou, "(%d alvos)" % vivos.size()) and ok
	await _esperar(0.6)
	ok = _conferir("depois do giro forte ele fica tontinho e para de girar", jogador.giro_forte <= 0.0 and jogador.robo.expressao_atual() == "tonto") and ok
	await _esperar(1.0)

	# Y agarra a bolota tonta pela antena, ele gira com ela e, soltando, arremessa: ela estoura no alvo do
	# caminho. Sem estar tonta, não dá para agarrar (pedido do usuário: estava fácil demais).
	var a0: Alvo = fase.alvos[0]
	var a1: Alvo = fase.alvos[1]
	for i in 6 * Engine.physics_ticks_per_second:
		if not a0.derrotado and not a1.derrotado:
			break
		await get_tree().physics_frame
	jogador.teleportar(a0.global_position + Vector3(0, 0.1, 1.4))
	jogador.visual.rotation.y = PI
	await _esperar(0.3)
	await _toque(JOY_BUTTON_Y)
	ok = _conferir("sem estar tonta, a bolota não deixa agarrar (só fecha a mão)", not a0.agarrada and jogador.agarrada == null
			and jogador.robo._mao_fechada > 0.0) and ok
	# Um golpe às vezes deixa tonta; aqui a chance vai a 100% para o teste não depender da sorte.
	a0.chance_tontura = 1.0
	await _toque(JOY_BUTTON_X)
	await _esperar(0.3)
	a0.chance_tontura = 0.25
	ok = _conferir("o golpe às vezes deixa a bolota tonta, com estrelinhas girando", a0.tonta > 0.0 and a0._estrelas_tonta.visible
			and a0.vida == a0.vida_max - 1) and ok
	var para := (a1.global_position - jogador.global_position) * Vector3(1, 0, 1)
	jogador.yaw = atan2(-para.x, -para.z)
	await _esperar(0.1)
	var vida_a1 := a1.vida
	_botao(JOY_BUTTON_Y, true)
	await _esperar(0.1)
	ok = _conferir("Y agarra a bolota tonta pela antena", a0.agarrada and jogador.agarrada == a0 and a0.tonta <= 0.0) and ok
	await _esperar(0.5)
	# O meio do corpo dela (pendurada pela antena, o "para cima" dela aponta para a mão).
	var meio := a0.global_position + a0.visual.global_basis.y * 0.62
	var longe := Vector2(meio.x - jogador.global_position.x, meio.z - jogador.global_position.z).length()
	ok = _conferir("segurando Y ele gira com a bolota pendurada na mão", longe > 1.4 and longe < 2.2 and meio.y > jogador.global_position.y + 0.6,
			"(a %.2f m)" % longe) and ok
	_botao(JOY_BUTTON_Y, false)
	await _esperar(0.05)
	ok = _conferir("soltando Y ele arremessa", a0.voando and jogador.agarrada == null) and ok
	await _esperar(0.8)
	ok = _conferir("a bolota arremessada acerta o alvo do caminho e estoura", a0.derrotado and (a1.derrotado or a1.vida < vida_a1),
			"(alvo com vida %d)" % a1.vida) and ok

	# Seta para baixo: dancinha; andar para.
	jogador.teleportar(Vector3(0, 0.1, 6))
	await _esperar(0.4)
	await _toque(JOY_BUTTON_DPAD_DOWN)
	await _esperar(0.8)
	ok = _conferir("seta para baixo faz a dancinha, com cara feliz", jogador.dancando > 0.0 and jogador.robo._danca > 0.9
			and jogador.robo.expressao_atual() == "feliz") and ok
	_eixo(JOY_AXIS_LEFT_Y, -1.0)
	await _esperar(0.3)
	_eixo(JOY_AXIS_LEFT_Y, 0.0)
	ok = _conferir("andar para a dancinha", jogador.dancando <= 0.0) and ok
	return ok


func _rodar_captura() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA_CAPTURAS))
	await _esperar(1.0)
	await _foto("01_inicio")
	jogador.forcar_direcao = Vector2(-0.35, -1.0)
	await _esperar(0.8)
	await _foto("02_andando")
	jogador.forcar_direcao = Vector2(0, -1.0)
	jogador.forcar_pulo = true
	await _esperar(0.25)
	await _foto("03_pulando")
	await _esperar(0.5)
	await _foto("04_flutuando")
	jogador.forcar_pulo = false
	jogador.forcar_direcao = Vector2.ZERO
	await _esperar(1.2)
	jogador.global_position = Vector3(-6, 2.5, -5)
	jogador.yaw = -1.05
	jogador.pitch = -0.4
	await _esperar(1.0)
	await _foto("05_plataformas")
	jogador.global_position = fase.movel.global_position + Vector3(0, 0.4, 0)
	jogador.yaw = 0.5
	await _esperar(1.0)
	await _foto("06_plataforma_movel")
	# Golpe num inimigo de treino.
	var a0: Alvo = fase.alvos[0]
	jogador.teleportar(a0.global_position + Vector3(0.3, 0.1, 1.6))
	jogador.yaw = -1.45
	jogador.pitch = -0.2
	await _esperar(0.6)
	jogador.forcar_golpe = true
	await _esperar(0.2)
	await _foto("08_golpe")
	await _esperar(0.6)
	# Laser dos pés num inimigo embaixo.
	var a2: Alvo = fase.alvos[2]
	jogador.teleportar(a2.global_position + Vector3(0, 3.6, 0))
	jogador.yaw = 0.2
	jogador.pitch = -0.15
	await _esperar(0.25)
	jogador.forcar_pulo = true
	await _esperar(0.3)
	await _foto("09_laser")
	jogador.forcar_pulo = false
	await _esperar(1.0)
	for e in fase.estrelas.slice(0, 7):
		e.monitoring = false
		e.hide()
	fase.pegas = 7
	jogador.global_position = Vector3(1.5, 5.0, -15.5)
	jogador.yaw = PI
	jogador.visual.rotation.y = 0.0
	await _esperar(0.8)
	await _foto("07_topo")
	await _capturar_movimentos()
	get_tree().quit()


## Giro forte, agarrar e arremessar, dancinha e os socos alternados (pedidos de 2026-10-29), vistos de lado.
func _capturar_movimentos() -> void:
	var a0: Alvo = fase.alvos[0]
	var a1: Alvo = fase.alvos[1]
	jogador.teleportar(Vector3(0.5, 0.1, 3.5))
	jogador.yaw = -0.9
	jogador.pitch = -0.25
	await _esperar(0.5)
	_botao(JOY_BUTTON_X, true)
	await _esperar(0.65)
	await _foto("10_carregando")
	await _esperar(0.35)
	await _foto("11_giro_forte")
	_botao(JOY_BUTTON_X, false)
	await _esperar(1.5)
	for i in 6 * Engine.physics_ticks_per_second:
		if not a0.derrotado and not a1.derrotado:
			break
		await get_tree().physics_frame
	jogador.teleportar(a0.global_position + Vector3(0, 0.1, 1.4))
	jogador.visual.rotation.y = PI
	var para := (a1.global_position - (a0.global_position + Vector3(0, 0, 1.4))) * Vector3(1, 0, 1)
	jogador.yaw = atan2(-para.x, -para.z) + 0.9
	a0.ficar_tonta()
	await _esperar(0.6)
	await _foto("12a_bolota_tonta")
	_botao(JOY_BUTTON_Y, true)
	await _esperar(0.45)
	await _foto("12_agarrando")
	jogador.yaw -= 0.9
	_botao(JOY_BUTTON_Y, false)
	await _esperar(0.12)
	await _foto("13_arremesso")
	await _esperar(1.0)
	jogador.teleportar(Vector3(0, 0.1, 6))
	jogador.yaw = PI
	jogador.pitch = -0.2
	await _esperar(0.5)
	await _toque(JOY_BUTTON_DPAD_DOWN)
	await _esperar(1.1)
	await _foto("14_danca")
	await _esperar(0.25)
	await _foto("15_danca")
	# Os balões do Vovô com os desenhos novos.
	hud.mostrar_dica("agarrar")
	await _esperar(0.7)
	await _foto("16_dica_agarrar")
	hud.mostrar_dica("giro_forte")
	await _esperar(1.4)
	await _foto("17_dica_giro_forte")


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var arquivo := ProjectSettings.globalize_path(PASTA_CAPTURAS + nome + ".png")
	get_viewport().get_texture().get_image().save_png(arquivo)
	print("foto: ", arquivo)


func _esperar(segundos: float) -> void:
	for i in int(segundos * Engine.physics_ticks_per_second):
		await get_tree().physics_frame


func _altura_maxima(segundos: float) -> float:
	var maior := -INF
	for i in int(segundos * Engine.physics_ticks_per_second):
		await get_tree().physics_frame
		maior = maxf(maior, jogador.global_position.y)
	return maior


func _eixo(eixo: JoyAxis, valor: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.device = 0
	ev.axis = eixo
	ev.axis_value = valor
	Input.parse_input_event(ev)


func _botao(botao: JoyButton, apertado: bool) -> void:
	var ev := InputEventJoypadButton.new()
	ev.device = 0
	ev.button_index = botao
	ev.pressed = apertado
	Input.parse_input_event(ev)


func _toque(botao: JoyButton) -> void:
	_botao(botao, true)
	await _esperar(0.05)
	_botao(botao, false)
	await _esperar(0.05)


func _conferir(rotulo: String, ok: bool, detalhe := "") -> bool:
	print("%s %s %s" % ["OK    " if ok else "FALHOU", rotulo, detalhe])
	return ok


func _terminar(ok: bool) -> void:
	print("RESULTADO: ", "tudo certo" if ok else "com falhas")
	get_tree().quit(0 if ok else 1)
