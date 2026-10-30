class_name Fase11
extends Fase
## 1-1 Pulinhos nas Nuvens (Mundo 1, Ilhas Fofas). A primeira fase: ensina o básico (pular, pulo alto, flutuar,
## golpes e o laser), sem poder da fase. Refeita em 2026-10-29 no padrão de playgrounds (pedido do usuário:
## "reconstrói as fases que já temos para atender o novo design"; docs/level-design/molde-das-fases.html):
## quatro playgrounds em volta do marco, a Torre de Nuvens, subindo em espiral até a arena no topo dela.
##   1 Ilha dos Pulinhos (y 0, ao sul): degraus, pulo alto e esteiras, com chão embaixo de tudo
##   viagem: ponte de esteiras
##   2 Ilhas das Argolas (y 1 a 5, a oeste): flutuar sobre vãos, argolas, duas rotas; V1 numa beirada embaixo (P1)
##   viagem: canhão
##   3 Jardim das Flores (y 8, ao norte): flores que o laser acende abrem o portão da saída; botões levantam a
##     ponte do bolso alto com o V2; coração extra (P2)
##   viagem: plataforma que vai e volta (atalho)
##   4 Subida das Nuvens (y 8 a 19, em volta da torre): nuvens que somem e plataformas que se mexem; V3 no
##     segredo da face norte da torre (P3)
##   Arena no topo da torre (y 22): três Bolotas e o baú, com a coluna de luz que se vê de toda a fase

const TORRE := Vector3(0, 0, -96)


func _montar() -> void:
	nome = "1-1 Pulinhos nas Nuvens"
	inicio = Vector3(0, 0.1, -2)
	limite_queda = -10.0
	farol(Vector3(-80, -14, -390), 2.0)
	_torre_de_nuvens()
	_ilha_dos_pulinhos()
	_ponte_de_esteiras()
	_ilhas_das_argolas()
	_jardim_das_flores()
	_viagem_ate_a_torre()
	_subida_das_nuvens()
	_arena()


## O marco: a Torre de Nuvens, quatro morros empilhados, com a arena em cima.
func _torre_de_nuvens() -> void:
	morro("12x12x8", TORRE + Vector3(0, 8, 0))
	chao_largo("8x8x8", TORRE + Vector3(0, 16, 0), Vector2(1.2, 1.2))
	morro("8x8x4", TORRE + Vector3(0, 20, 0))
	morro("12x12x2", TORRE + Vector3(0, 22, 0))
	for p in [Vector3(6.5, 7.2, 3.0), Vector3(-6.8, 7.4, -2.0), Vector3(2.0, 15.2, 4.6)]:
		enfeite("Bush_2_A_Color1", TORRE + p, 2.4)


## Playground 1 · Ilha dos Pulinhos (apresenta): um chão largo, sem vazio por perto. Degraus de 1,2 m levam a um
## morrinho com estrelinhas (bolso em cima), uma beirada de 1,5 m pede o pulo alto, e as esteiras levam até o
## arco de saída. Mini-marco: o pinheiro rosa gigante (atrás dele, uma roda de estrelinhas). Uma Bolota dorme.
func _ilha_dos_pulinhos() -> void:
	playground("1 · Ilha dos Pulinhos", Vector3(0, 0, -16), 19.0, inicio)
	chao_largo("12x12x4", Vector3(0, 0, -16), Vector2(3.0, 3.0))
	trilha_creme([Vector3(0, 0, -1), Vector3(1, 0, -8), Vector3(-2, 0, -14), Vector3(-6, 0, -19), Vector3(-9, 0, -24), Vector3(-17, 0, -24)])
	trilha(Vector3(0.5, 0.9, -5), Vector3(-1.5, 0.9, -12), 4)
	bolota(Vector3(5, 0, -5), true)

	# Degraus até o morrinho (bolso em cima).
	morro("4x4x2", Vector3(8, 1.2, -9))
	morro("4x4x4", Vector3(10.5, 2.4, -12.5))
	morro("4x4x4", Vector3(13, 3.6, -16))
	roda(Vector3(13, 4.6, -16), 1.2, 5)
	estrelinha(Vector3(8, 2.2, -9))

	# Beirada que pede o pulo alto.
	morro("8x8x4", Vector3(-3, 1.5, -16))
	ponto_de_dica(Vector3(-1.5, 1.0, -10.5), 2.6, "pulo_alto")
	trilha(Vector3(-3, 2.6, -14.5), Vector3(-4.5, 2.6, -18), 2)

	# Esteiras lado a lado: a verde leva para o arco; a vermelha, ao contrário, tem as estrelinhas.
	esteira(Vector3(-11, 1.0, -22), -PI / 2.0, 3.5, "green")
	esteira(Vector3(-11, 1.0, -26.6), PI / 2.0, 2.5, "red")
	trilha(Vector3(-8, 2.1, -26.6), Vector3(-14, 2.1, -26.6), 3)
	arco_de_saida(Vector3(-16.5, 0, -24), PI / 2.0, "yellow")
	for p in [Vector3(-5, 0, -21), Vector3(-6.5, 0, -27.5)]:
		peca("signage_arrow_stand_yellow", p, PI, 1.0, false)

	# Mini-marco e o bolso atrás dele.
	arvore(1, 8, Vector3(10, 0, -26), 2.6)
	roda(Vector3(12, 0.9, -31), 1.6, 6)

	arvore(4, 1, Vector3(-12, 0, -6), 1.3)
	arvore(2, 5, Vector3(14, 0, -3), 1.1)
	arvore(5, 6, Vector3(-14, 0, -33), 1.0)
	for p in [Vector3(4, 0, 1.5), Vector3(-6, 0, 0.5), Vector3(16, 0, -22), Vector3(-16, 0, -14), Vector3(3, 0, -32)]:
		enfeite("Bush_1_A_Color1", p, 3.2, p.x)
	enfeite("Rock_1_A_Color1", Vector3(6, 0, -30), 1.6, 0.4)


## Viagem 1: ponte de esteiras com muretas dos dois lados, do arco do playground 1 até as Ilhas das Argolas.
func _ponte_de_esteiras() -> void:
	for x in [-23.0, -31.0, -39.0]:
		esteira(Vector3(x, 1.0, -24), -PI / 2.0, 3.5, "blue")
		estrelinha(Vector3(x, 2.2, -24))
	for x in [-21.0, -25.0, -29.0, -33.0, -37.0, -41.0]:
		for z in [-26.6, -21.4]:
			peca("barrier_4x1x2_blue", Vector3(x, 0.03, z), 0.0)


## Playground 2 · Ilhas das Argolas (desenvolve): da ilha de chegada, duas rotas até a ilha do meio. Pela direita,
## nuvens firmes com uma argola em cada vão (é preciso flutuar no primeiro); pela esquerda, ilhas de pulo. Na ilha
## do meio, três Bolotas, a mola para o pilar da bandeira (mini-marco, com estrelinhas em cima) e, embaixo dela,
## a beirada com o V1. A ilha da saída tem o arco e o canhão.
func _ilhas_das_argolas() -> void:
	playground("2 · Ilhas das Argolas", Vector3(-56, 3, -48), 22.0, Vector3(-50, 1, -21))
	morro("12x12x4", Vector3(-49.5, 1, -24))
	posto(Vector3(-52, 1, -20))
	ponto_de_dica(Vector3(-50, 1.5, -28.5), 2.6, "flutuar")
	arvore(2, 5, Vector3(-54, 1, -19), 0.9)

	# Rota da direita: nuvens firmes e argolas.
	var nuvens := [Vector3(-50, 1.5, -37), Vector3(-48, 2.0, -44), Vector3(-51, 2.5, -51), Vector3(-49, 3.0, -58)]
	var antes := Vector3(-49.5, 1.0, -30.2)
	var cores := ["red", "yellow", "blue", "green"]
	# Nuvens de 2 m de raio: as plataformas de pouso do caminho têm pelo menos 3 x 3 m (padrão de 2026-10-29).
	for i in nuvens.size():
		nuvem(nuvens[i], 2.0)
		var perto: Vector3 = nuvens[i] + Vector3(0, 0, 2.0)
		var meio := (antes + perto) * 0.5
		argola(Vector3(meio.x, minf(antes.y, perto.y) - 0.4, meio.z), 0.0, cores[i])
		antes = nuvens[i] - Vector3(0, 0, 2.0)
	var ultima: Vector3 = nuvens[nuvens.size() - 1]
	var premio := []
	for i in 8:
		var a := TAU * i / 8.0
		premio.append(ultima + Vector3(cos(a) * 1.2, 1.4 + 0.4 * sin(a * 2.0), sin(a) * 1.2))
	premio_das_argolas(premio)

	# Rota da esquerda: ilhas de pulo.
	morro("8x8x4", Vector3(-63, 2, -32))
	morro("8x8x4", Vector3(-66, 3, -44))
	morro("4x4x4", Vector3(-63, 3.2, -52))
	trilha(Vector3(-63, 3.1, -32), Vector3(-66, 4.1, -44), 3)
	estrelinha(Vector3(-63, 4.3, -52))

	# Ilha do meio.
	morro("12x12x4", Vector3(-58, 3.5, -64))
	bolota(Vector3(-61, 3.5, -61))
	bolota(Vector3(-56, 3.5, -60.5))
	bolota(Vector3(-62, 3.5, -67.5))
	morro("4x4x8", Vector3(-53.5, 8.5, -69))
	peca("flag_A_red", Vector3(-53.5, 8.5, -69), 0.0, 2.5, false)
	mola(Vector3(-55.5, 3.5, -65.5))
	roda(Vector3(-53.5, 9.5, -69), 1.0, 4)
	arvore(4, 7, Vector3(-62.5, 3.5, -59), 0.9)

	# Bolso embaixo da ilha do meio: a beirada com o V1 (o brilho aparece de cima), e uma mola de volta.
	morro("4x4x2", Vector3(-67.5, -1.5, -64))
	vaga_lume(Vector3(-68, -0.4, -65))
	mola(Vector3(-67, -1.5, -62.5), 19.0)
	trilha(Vector3(-64.5, 2.5, -64), Vector3(-66.5, 0.0, -64), 2)

	# Ilha da saída: arco e canhão para o Jardim das Flores.
	morro("8x8x4", Vector3(-48, 5, -76))
	arco_de_saida(Vector3(-48, 5, -77.5), 0.0, "red")
	var c := canhao(Vector3(-48, 5, -79.5), Vector3(-10, 8.2, -137))
	var de := c.to_global(Canhao.BOCA)
	for t in [0.25, 0.45, 0.65, 0.85]:
		estrelinha(Canhao.ponto_do_voo(de, c.destino, t) + Vector3.UP * 1.0)


## Playground 3 · Jardim das Flores (central): o maior, com o pinheiro rosa no meio (mini-marco). As três flores
## acesas pelo laser abrem o portão do paredão, o único jeito de chegar ao arco de saída. Os três botões levantam a
## ponte até a ilhota do bolso alto, com o V2; uma mola leva a um pilar com estrelinhas. Coração extra e três
## Bolotas (o Vovô mostra o agarrar logo na chegada).
func _jardim_das_flores() -> void:
	playground("3 · Jardim das Flores", Vector3(0, 8, -148), 19.0, Vector3(-10, 8, -137))
	chao_largo("12x12x4", Vector3(0, 8, -148), Vector2(3.0, 2.6))
	posto(Vector3(-13, 8, -138))
	ponto_de_dica(Vector3(-8, 9, -140), 3.0, "agarrar")
	trilha_creme([Vector3(-10, 8, -137), Vector3(-4, 8, -142), Vector3(2, 8, -147), Vector3(8, 8, -150), Vector3(17.5, 8, -150)])
	arvore(1, 8, Vector3(-3, 8, -154), 2.6)
	coracao(Vector3(-13, 9, -143))
	bolota(Vector3(-4, 8, -145))
	bolota(Vector3(5, 8, -142))
	bolota(Vector3(3, 8, -157))

	# Flores e o portão do paredão.
	flor(Vector3(-6, 8, -148))
	flor(Vector3(4, 8, -153))
	flor(Vector3(8, 8, -144))
	ponto_de_dica(Vector3(-2, 8.5, -146), 2.6, "laser")
	for p in [Vector3(-6, 9.7, -148), Vector3(4, 9.7, -153), Vector3(8, 9.7, -144)]:
		estrelinha(p)
	portao(Vector3(13, 8, -150), PI / 2.0)
	for z in [-162.0, -158.0, -154.0, -146.0, -142.0, -138.0, -134.0]:
		morro("4x4x8", Vector3(13, 14, z))
	arco_de_saida(Vector3(17.5, 8, -150), PI / 2.0, "green")
	peca("signage_arrow_stand_green", Vector3(9.5, 8, -147.5), -PI / 2.0, 1.0, false)

	# Botões e a ponte do bolso alto (V2).
	botao(Vector3(-8, 8, -158), "red")
	botao(Vector3(6, 8, -160), "yellow")
	botao(Vector3(-1, 8, -162), "blue")
	ponto_de_dica(Vector3(-1, 8.5, -158), 2.4, "botao")
	for p in [Vector3(-8, 9.1, -158), Vector3(6, 9.1, -160), Vector3(-1, 9.1, -162)]:
		estrelinha(p)
	var degraus := [Vector3(-1, 8.5, -169), Vector3(0.5, 9.0, -174.5), Vector3(-1, 9.5, -180)]
	ponte_dos_botoes(degraus)
	for d: Vector3 in degraus:
		estrelinha(d + Vector3(0, 1.1, 0))
	morro("8x8x4", Vector3(0, 10, -186))
	vaga_lume(Vector3(0, 11.1, -187))
	roda(Vector3(0, 10.9, -186), 2.4, 5)

	# Mola até o pilar das estrelinhas.
	mola(Vector3(-14, 8, -157))
	morro("4x4x4", Vector3(-15.5, 13, -161))
	roda(Vector3(-15.5, 14, -161), 1.0, 4)

	for p in [Vector3(-16, 8, -134), Vector3(10, 8, -134), Vector3(-17, 8, -150)]:
		enfeite("Bush_4_A_Color1", p, 2.6, p.z)
	arvore(2, 1, Vector3(-16, 8, -163), 1.0)


## Viagem 3: plataforma que vai e volta do arco do Jardim até o começo da subida (é também o atalho de volta).
func _viagem_ate_a_torre() -> void:
	movel("6x6x1", "blue", Vector3(24, 8, -150), Vector3(-8, 0, 40), 14.0)
	trilha(Vector3(23, 9.2, -142), Vector3(18, 9.2, -118), 4)


## Playground 4 · Subida das Nuvens (reviravolta): começa numa plataforma ao lado da torre e sobe em espiral em volta
## dela: cinco nuvens que somem, uma plataforma que vai e volta, uma plataforma com Bolota, um elevador e a última
## plataforma, com Bolota e a mola para a arena. O segredo é a beiradinha na face norte da torre, com o V3: o
## brilho e uma trilha de estrelinhas descendo mostram onde fica; uma mola forte leva de volta.
func _subida_das_nuvens() -> void:
	var t := TORRE
	playground("4 · Subida das Nuvens", t + Vector3(0, 14, 0), 16.0, t + Vector3(10.5, 8, -7.5))
	plataforma("6x6x1", "green", t + Vector3(11, 8, -9))
	posto(t + Vector3(11, 8, -9))
	var nuvens := [Vector3(12.9, 9, -1.8), Vector3(12.4, 10, 4.0), Vector3(9.2, 11, 9.2), Vector3(4.0, 12, 12.4), Vector3(-2.0, 13, 12.8)]
	for n: Vector3 in nuvens:
		nuvem_que_some(t + n)
		estrelinha(t + n + Vector3(0, 1.2, 0))
	movel("4x4x1", "yellow", t + Vector3(-8, 13.5, 11.5), Vector3(-3.5, 0, -3.5), 5.0)
	plataforma("6x6x1", "red", t + Vector3(-15.5, 15, 4))
	bolota(t + Vector3(-15.5, 15, 4))
	movel("4x4x1", "green", t + Vector3(-14.5, 15, -3), Vector3(0, 4, 0), 4.0, 1.0)
	# A última plataforma encosta na torre, embaixo da beira da arena; a mola fica na ponta de dentro.
	plataforma("6x6x1", "blue", t + Vector3(-9.5, 19, -8.5))
	bolota(t + Vector3(-11, 19, -9.5))
	mola(t + Vector3(-7.5, 19, -6.5))
	trilha(t + Vector3(-7.5, 22, -6.5), t + Vector3(-4, 24.5, -3), 3)

	# Segredo: beiradinha na face norte da torre, com o V3.
	morro("4x4x2", t + Vector3(0, 12, -8.5))
	vaga_lume(t + Vector3(0.5, 13.1, -9))
	mola(t + Vector3(-1.2, 12, -8.2), 21.0)
	trilha(t + Vector3(-7, 18, -11), t + Vector3(-2, 13.4, -9), 3)


## Arena no topo da torre: três Bolotas guardam o baú, e a coluna de luz do baú aparece de toda a fase.
func _arena() -> void:
	var topo := TORRE + Vector3(0, 22, 0)
	colocar_bau(topo + Vector3(0, 0, -1.5))
	brilho_de_marco(topo + Vector3(0, 1.5, -1.5))
	bolota(topo + Vector3(-3.2, 0, 2.2))
	bolota(topo + Vector3(3.2, 0, 1.8))
	bolota(topo + Vector3(0.5, 0, -4.4))
	ponto_de_dica(topo + Vector3(-4, 1, -4), 3.0, "giro_forte")
	roda(topo + Vector3(0, 0.9, -1.5), 3.4, 3)
	arvore(4, 5, topo + Vector3(-5, 0, 4.6), 0.9)
	arvore(1, 6, topo + Vector3(5, 0, 4.4), 0.9)
