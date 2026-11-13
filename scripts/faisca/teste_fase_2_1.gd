class_name TesteFase21
extends RefCounted
## Testes da 2-1 Cozinha Gigante (refeita em playgrounds em 2026-10-29), chamados pelo FaiscaSolo:
##   --faisca-fase-2-1           confere a fase de ponta a ponta: contagens, o padrão de playgrounds (o brilho do
##                               baú à vista de cada entrada), a mesa (tampa e caixa de cereal), a ponte de tábuas,
##                               a bancada (rolos e a tampa do vão até o V1), os dois pratos que levam, a pizza, as
##                               bocas, a tampa até os livros do V2, a pia (prato, bolha e água), a Cozinha Alagando
##                               (o registro da pia, as três etapas da enchente com os pulos de boia em boia, o V3 no
##                               patinho, a torre de potes e a bandeja), o coração atrás da geladeira, o sorvete até o
##                               alto da geladeira, o baú e a tela de fim
##   --faisca-fase-2-1-captura   fotos de cada playground em tools/capturas/faisca/fase_2_1/ (precisa de janela)

var m: Node
var n: Fase21
var j: Jogador


func _init(main: Node) -> void:
	m = main
	n = main.nivel
	j = main.jogador
	main.testando = true


func rodar() -> void:
	var ok := true
	await m._esperar(0.3)
	var total := n.total_estrelas()
	ok = m._conferir("de 95 a 125 estrelinhas soltas, e de 125 a 160 com as das Bolotas", n.estrelas.size() >= 95 and n.estrelas.size() <= 125
			and total >= 125 and total <= 160, "(%d soltas, %d com as das Bolotas)" % [n.estrelas.size(), total]) and ok
	ok = m._conferir("4 postos, 6 Faisquinhas, 10 Bolotas e o baú", n.postos.size() == 4 and n.faisquinhas.size() == 6 and n.alvos.size() == 10
			and n.bau != null, "(%d postos, %d Bolotas)" % [n.postos.size(), n.alvos.size()]) and ok
	ok = m._conferir("peças: 3 tampas, 4 bocas, 2 rolos, a pizza, a pia, 4 pratos e a bandeja que se mexem, 2 bolhas, o sorvete, 3 registros e 9 boias",
			n.tampas.size() == 3 and n.bocas.size() == 4 and n.rolos.size() == 2 and n.pizzas.size() == 1 and n.aguas.size() == 1
			and n.moveis.size() == 5 and n.nuvens_que_somem.size() == 2 and n.molas.size() == 1 and n.registros.size() == 3
			and n.enchente.boias.size() == 9, "(%d móveis, %d bolhas, %d boias)" % [n.moveis.size(), n.nuvens_que_somem.size(), n.enchente.boias.size()]) and ok

	# O padrão de playgrounds: os móveis em volta da geladeira, um arco de saída em cada um dos três primeiros, o
	# brilho do baú à vista de todas as entradas e um vaga-lume no bolso de cada um dos três últimos.
	await m.get_tree().physics_frame
	var espaco := j.get_world_3d().direct_space_state
	ok = m._conferir("5 playgrounds e 4 arcos de saída", n.playgrounds.size() == 5 and n.saidas.size() == 4) and ok
	var cegos := n.playgrounds.filter(func(p: Dictionary) -> bool:
		return not espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p.entrada + Vector3.UP * 2.0, n.brilho_do_marco, 1)).is_empty())
	ok = m._conferir("da entrada de cada playground dá para ver o brilho do baú em cima da geladeira", cegos.is_empty(),
			"(sem ver: %s)" % ", ".join(cegos.map(func(p: Dictionary) -> String: return p.nome))) and ok
	var donos := n.faisquinhas.slice(0, 3).map(func(v: Faisquinha) -> int: return _playground_mais_perto(v.global_position))
	ok = m._conferir("um vaga-lume no bolso do playground 2, do 3 e do 5 (o do 5 nas costas do patinho)", donos == [1, 2, 4], "(%s)" % str(donos)) and ok
	ok = m._conferir("a arena fica em cima da geladeira: o baú é o ponto mais alto do caminho", n.bau.global_position.y > 19.5
			and Vector2(n.bau.global_position.x, n.bau.global_position.z + 70.0).length() < 8.0) and ok
	# As Bolotas ficam paradas no teste (a 1-1 já confere o jeito delas), menos a primeira, que dorme.
	for b in n.alvos.slice(1):
		b.process_mode = Node.PROCESS_MODE_DISABLED

	m._comecar_fase()
	await m._esperar(4.0)
	ok = m._conferir("desce flutuando e pisa na mesa do café", j.is_on_floor() and j.controle_ligado and absf(j.global_position.y - 8.0) < 0.3
			and j.global_position.distance_to(n.inicio) < 1.0) and ok
	var b0 := n.alvos[0] as Bolota
	j.teleportar(b0.global_position + Vector3(0, 0.1, 1.6))
	j.visual.rotation.y = PI
	await m._esperar(0.3)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.45)
	await m._esperar(0.6)
	ok = m._conferir("a Bolota que dorme na mesa apanha e sai quicando", b0.derrotado) and ok
	ok = await _mesa_e_bancada() and ok
	ok = await _pizza_e_fogao() and ok
	ok = await _pia_e_geladeira() and ok

	# Baú em cima da geladeira, a Estrela Grande e a tela de fim.
	var bau := n.bau
	j.teleportar(bau.global_position + Vector3(0, 0.1, 2.8))
	j.visual.rotation.y = PI
	await m._esperar(0.4)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.5)
	ok = m._conferir("três golpes abrem o baú", bau.derrotado and bau.estrela != null, "(%d golpes)" % bau.golpes) and ok
	await m._esperar(1.2)
	j.teleportar(bau.global_position + Vector3(0, 0.1, 2.4))
	await m._esperar(3.6)
	ok = m._conferir("pegar a Estrela Grande mostra a tela de fim", m.hud.fim_aberto and not j.controle_ligado) and ok
	m._terminar(ok)


## Playground 1, a ponte de tábuas e o playground 2 (até o prato que leva para a pizza).
func _mesa_e_bancada() -> bool:
	var ok := true
	j.teleportar(Vector3(5.0, 8.1, -22.5))
	await m._esperar(0.4)
	ok = m._conferir("perto da primeira panela o Vovô mostra a tampa", m.hud.dica_atual == "tampa") and ok
	var t0 := n.tampas[0]
	j.teleportar(t0.global_position + Vector3(0, 1.6, 0))
	var altura: float = await m._altura_maxima(4.0)
	ok = m._conferir("em cima da tampa, quando ela pula, o Faísca vai até a roda de estrelinhas", altura > 14.0, "(%.1f m)" % altura) and ok
	await m._esperar(1.0)
	var onde := await _pular_para(Vector3(-10.0, 8.1, -23.5), Vector3(-10.0, 9.6, -29.0))
	ok = m._conferir("a caixa de cereal sobe segurando o pulo", absf(onde.y - 9.6) < 0.3, "(altura %.1f)" % onde.y) and ok
	j.teleportar(Vector3(-12.0, 8.1, -26.0))
	await _andar(Vector3(-1, 0, 0), 3.4)
	ok = m._conferir("a ponte de tábuas leva da mesa até a bancada, sem pular", j.is_on_floor() and absf(j.global_position.y - 8.0) < 0.3
			and j.global_position.x < -31.0, "(%.1f, %.1f)" % [j.global_position.x, j.global_position.y]) and ok
	j.teleportar(n.postos[0].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P1 acende na bancada das panelas", n.postos[0].acendido) and ok

	# Rolos de macarrão: rolam de um lado para o outro; encostar tira um coração.
	var r0 := n.rolos[0]
	var x_min := INF
	var x_max := -INF
	for i in int(2.6 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		x_min = minf(x_min, r0.global_position.x)
		x_max = maxf(x_max, r0.global_position.x)
	ok = m._conferir("o rolo de macarrão rola de um lado para o outro da bancada", x_max - x_min > 16.0, "(%.1f m)" % (x_max - x_min)) and ok
	j.vida = Jogador.VIDA_MAX
	j.teleportar(r0.global_position + Vector3(0, 0.2, 0.5))
	await m._esperar(0.2)
	ok = m._conferir("encostar no rolo tira um coração", j.vida == Jogador.VIDA_MAX - 1, "(vida %d)" % j.vida) and ok
	j.teleportar(Vector3(-36.0, 8.1, -22.0))
	await m._esperar(1.8)
	j.vida = Jogador.VIDA_MAX

	# O vão: a tampa da panela no banquinho joga até a prateleira do V1.
	onde = await _tampa_para(n.tampas[1], Vector3(-61.0, 16.0, -29.0))
	ok = m._conferir("a tampa do vão joga o Faísca até a prateleira da parede", absf(onde.y - 16.0) < 0.4 and onde.x < -58.0,
			"(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	j.teleportar(n.faisquinhas[0].global_position - Vector3(0, 0.8, 0))
	await m._esperar(0.3)
	ok = m._conferir("o V1 está na prateleira", n.faisquinhas[0].encontrado) and ok

	# Viagem 2: o prato leva da ponta da bancada até a mesa da pizza.
	var prato: AnimatableBody3D = n.moveis[0]
	while prato.global_position.z < -54.4:
		await m.get_tree().physics_frame
	j.teleportar(prato.global_position + Vector3(0, 1.4, 0))
	while prato.global_position.z > -66.15:
		await m.get_tree().physics_frame
	await _andar(Vector3(0, 0, -1), 1.2)
	ok = m._conferir("o prato leva o Faísca até a beirada da mesa da pizza", j.is_on_floor() and absf(j.global_position.y - 8.0) < 0.3
			and j.global_position.z < -70.5, "(%.1f, %.1f)" % [j.global_position.y, j.global_position.z]) and ok
	return ok


## Playground 3: o P2, a pizza que gira, a boca acesa, a tampa até os livros do V2 e o prato de trás da geladeira.
func _pizza_e_fogao() -> bool:
	var ok := true
	j.teleportar(n.postos[1].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P2 acende na mesa da pizza", n.postos[1].acendido) and ok
	var pz := n.pizzas[0]
	var onde := await _pular_para(Vector3(-38.0, 8.1, -72.5), pz.global_position + Vector3(0, 1.8, 3.5))
	ok = m._conferir("da beirada da mesa se pula na pizza", absf(onde.y - 9.2) < 0.3, "(altura %.1f)" % onde.y) and ok
	var antes := j.global_position
	await m._esperar(2.0)
	var andou := Vector2(j.global_position.x - antes.x, j.global_position.z - antes.z).length()
	ok = m._conferir("em cima da pizza que gira o Faísca vai junto", j.is_on_floor() and andou > 1.5, "(%.1f m)" % andou) and ok
	var b0 := n.bocas[0]
	while not b0.acesa:
		await m.get_tree().physics_frame
	j.vida = Jogador.VIDA_MAX
	j.teleportar(b0.global_position + Vector3(0, 0.3, 0))
	await m._esperar(0.3)
	ok = m._conferir("a boca do fogão acesa tira um coração", j.vida == Jogador.VIDA_MAX - 1, "(vida %d)" % j.vida) and ok
	# Sai de cima da boca antes de esperar (senão ela tira outro quando a piscada acaba).
	j.teleportar(Vector3(-38.0, 8.1, -98.0))
	await m._esperar(1.8)
	j.vida = Jogador.VIDA_MAX
	onde = await _tampa_para(n.tampas[2], Vector3(-55.0, 15.0, -106.5))
	ok = m._conferir("a tampa da bancada joga o Faísca em cima dos livros de receitas", absf(onde.y - 15.0) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	j.teleportar(n.faisquinhas[1].global_position - Vector3(0, 0.8, 0))
	await m._esperar(0.3)
	ok = m._conferir("o V2 está em cima dos livros", n.faisquinhas[1].encontrado) and ok
	# Viagem 3: o prato de trás da geladeira, da ponta do fogão até a bancada da pia.
	var prato: AnimatableBody3D = n.moveis[1]
	while prato.global_position.x > -10.0:
		await m.get_tree().physics_frame
	j.teleportar(Vector3(-15.0, 9.0, -100.0))
	await _andar(Vector3(1, 0, 0), 0.5)
	ok = m._conferir("da ponta do fogão se desce no prato", j.is_on_floor() and absf(j.global_position.y - 8.0) < 0.3, "(%.1f, %.1f)" % [j.global_position.x, j.global_position.y]) and ok
	while prato.global_position.x < 10.15:
		await m.get_tree().physics_frame
	await _andar(Vector3(1, 0, 0), 1.4)
	ok = m._conferir("o prato leva o Faísca por trás da geladeira até a bancada da pia", j.is_on_floor() and j.global_position.x > 14.5
			and absf(j.global_position.y - 8.0) < 0.3, "(%.1f, %.1f)" % [j.global_position.x, j.global_position.y]) and ok
	return ok


## Playground 4, a Cozinha Alagando e a arena: o P3, a pia, o registro da saída, as três etapas da enchente (pulando
## de boia em boia de verdade), o V3 no patinho, a torre de potes, a bandeja, o coração atrás da geladeira e o sorvete.
func _pia_e_geladeira() -> bool:
	var ok := true
	var p3 := n.postos[2]
	j.teleportar(p3.global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P3 acende na bancada da pia", p3.acendido) and ok
	var prato: AnimatableBody3D = n.moveis[2]
	j.teleportar(prato.global_position + Vector3(0, 1.4, 0))
	await m._esperar(0.4)
	var y0 := j.global_position.y
	var sobe_desce := 0.0
	for i in int(1.6 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		sobe_desce = maxf(sobe_desce, absf(j.global_position.y - y0))
	ok = m._conferir("o prato boiando segura o Faísca e sobe e desce com ele", j.is_on_floor() and sobe_desce > 0.2, "(%.2f m)" % sobe_desce) and ok
	j.vida = Jogador.VIDA_MAX
	var bolha: NuvemQueSome = n.nuvens_que_somem[0]
	j.teleportar(bolha.global_position + Vector3(0, 0.3, 0))
	await m._esperar(1.4)
	ok = m._conferir("a bolha de sabão estoura um instante depois de pisada", bolha.sumida) and ok
	await m._esperar(0.6)
	ok = m._conferir("e cair na água da pia é cair: perde um coração e volta no P3", j.vida == Jogador.VIDA_MAX - 1
			and j.global_position.distance_to(p3.ponto()) < 1.5, "(vida %d)" % j.vida) and ok
	j.vida = Jogador.VIDA_MAX
	await m._esperar(3.4)
	ok = await _cozinha_alagando() and ok
	# Da bandeja para a prateleira atrás da geladeira: o coração e, andando até a outra, o sorvete.
	j.vida = Jogador.VIDA_MAX - 1
	j.teleportar(Vector3(11.0, 14.1, -79.6))
	await _andar(Vector3(-1, 0, 0), 2.8)
	ok = m._conferir("andando pela prateleira atrás da geladeira se acha o coração", j.vida == Jogador.VIDA_MAX and absf(j.global_position.y - 14.0) < 0.3,
			"(x %.1f, vida %d)" % [j.global_position.x, j.vida]) and ok
	var sorvete: Area3D = n.molas[0]
	var onde := await _quicar(sorvete, Vector3(3.0, 20.0, -72.0))
	ok = m._conferir("o sorvete joga o Faísca até o alto da geladeira", j.is_on_floor() and absf(onde.y - 20.0) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	return ok


## A Cozinha Alagando (item 9 da lista, 2026-11-11): da bancada da pia até a bandeja que leva para a prateleira.
func _cozinha_alagando() -> bool:
	var ok := true
	var e := n.enchente
	var boias := n.boias_do_caminho
	var seca := e.etapa == 0 and e.nivel < 0.0 and boias.all(func(b: Boia) -> bool: return b.global_position.y < n.limite_queda)
	ok = m._conferir("antes do registro a água fica embaixo do chão e o que boia fica deitado no chão (abaixo da queda)", seca,
			"(etapa %d, nível %.1f)" % [e.etapa, e.nivel]) and ok
	# Sem a água, da bancada não se chega à escadinha: o pulo mais longo, flutuando até o fim, cai no chão (que é lava).
	j.vida = Jogador.VIDA_MAX
	var p3 := n.postos[2]
	var longe := await _pular_longe(Vector3(29.0, 8.1, -46.0), Vector3(53.0, 4.5, -42.0))
	ok = m._conferir("sem a água, da bancada não se chega à escadinha (o pulo mais longo cai no chão)", j.vida == Jogador.VIDA_MAX - 1
			and j.global_position.distance_to(p3.ponto()) < 1.5, "(chegou a x %.1f)" % longe.x) and ok
	j.vida = Jogador.VIDA_MAX
	# O registro da saída da pia.
	j.teleportar(Vector3(23.5, 8.1, -50.5))
	await m._esperar(0.5)
	ok = m._conferir("perto do registro o Vovô mostra a dica dele", m.hud.dica_atual == "registro", "(%s)" % m.hud.dica_atual) and ok
	if not await _girar(n.registros[0]):
		ok = m._conferir("um soco gira o registro da pia", false) and ok
	await m._esperar(0.3)
	ok = m._conferir("o soco gira o registro, a pia transborda e a água começa a subir", n.registros[0].girado_ja and e.etapa == 1 and e.subindo_agora) and ok
	await _ate(func() -> bool: return not e.subindo_agora, 10.0)
	ok = m._conferir("a água para na etapa 1 (3,1 m) e o que boia sobe junto", absf(e.nivel - 3.1) < 0.05
			and boias.all(func(b: Boia) -> bool: return b.boiando()), "(nível %.2f)" % e.nivel) and ok
	# Etapa 1: da bancada pulando de boia em boia até a escadinha, e subindo os degraus até o P4.
	var de := Vector3(29.0, 8.1, -46.5)
	for i in 3:
		var b: Boia = boias[i]
		var onde := await _pular_para(_na_beira(de, b.global_position, boias[i - 1] if i > 0 else null), b.global_position)
		ok = m._conferir("etapa 1: pula %s (%s)" % ["da bancada na 1ª boia" if i == 0 else "para a %dª boia" % (i + 1), b.tipo],
				absf(onde.y - b.global_position.y) < 0.4 and Vector2(onde.x - b.global_position.x, onde.z - b.global_position.z).length() < 2.6,
				"(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
		de = onde + Vector3.UP * 0.1
	de = _na_beira(de, Vector3(50.5, 4.5, -42.0), boias[2])
	for degrau in [Vector3(50.5, 4.5, -42.0), Vector3(51.0, 6.5, -46.0), Vector3(52.0, 8.5, -50.0)]:
		var onde := await _pular_para(de, degrau)
		ok = m._conferir("etapa 1: pula no degrau de %.1f m da escadinha" % degrau.y, absf(onde.y - degrau.y) < 0.3,
				"(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
		de = onde + Vector3.UP * 0.1
	var p4 := n.postos[3]
	await m._esperar(0.3)
	ok = m._conferir("o P4 acende em cima da escadinha", p4.acendido) and ok
	# Cair na água é cair, como na pia.
	j.teleportar(Vector3(44.0, 6.0, -60.0))
	await m._esperar(1.4)
	ok = m._conferir("e cair na água da enchente é cair: perde um coração e volta no P4", j.vida == Jogador.VIDA_MAX - 1
			and j.global_position.distance_to(p4.ponto()) < 1.5, "(vida %d, %.1f, %.1f, %.1f)" % [j.vida, j.global_position.x, j.global_position.y, j.global_position.z]) and ok
	j.vida = Jogador.VIDA_MAX
	# Etapa 2: o registro da escadinha.
	if not await _girar(n.registros[1]):
		ok = m._conferir("um soco gira o registro da escadinha", false) and ok
	await _ate(func() -> bool: return e.etapa == 2 and not e.subindo_agora, 10.0)
	ok = m._conferir("o registro da escadinha sobe a água para a etapa 2 (5,2 m), cobrindo o degrau de baixo", absf(e.nivel - 5.2) < 0.05
			and e.nivel > 4.5, "(nível %.2f)" % e.nivel) and ok
	de = n.escadinha_topo + Vector3(0, 0.1, -2.5)
	for i in range(3, 5):
		var b: Boia = boias[i]
		var onde := await _pular_para(_na_beira(de, b.global_position, boias[i - 1] if i > 3 else null), b.global_position)
		ok = m._conferir("etapa 2: pula para a %dª boia (%s)" % [i - 2, b.tipo], absf(onde.y - b.global_position.y) < 0.4,
				"(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
		de = onde + Vector3.UP * 0.1
	# O bolso: o patinho de lado, com o V3 nas costas.
	var costas := n.patinho.global_position + n.patinho.global_basis * Vector3(0, 0, 0.6)
	var no_patinho := await _pular_para(_na_beira(de, costas, boias[4]), costas)
	var v3 := n.faisquinhas[2]
	await _andar(Vector3(v3.global_position.x - j.global_position.x, 0, v3.global_position.z - j.global_position.z), 0.35)
	no_patinho = j.global_position
	await m._esperar(0.4)
	ok = m._conferir("etapa 2: do prato se pula nas costas do patinho e acha o V3", n.faisquinhas[2].encontrado,
			"(%.1f, %.1f, %.1f)" % [no_patinho.x, no_patinho.y, no_patinho.z]) and ok
	var volta := await _pular_para(no_patinho + Vector3.UP * 0.1, boias[4].global_position)
	de = volta + Vector3.UP * 0.1
	var onde5 := await _pular_para(_na_beira(de, boias[5].global_position, boias[4]), boias[5].global_position)
	ok = m._conferir("etapa 2: volta ao prato e pula para a 3ª boia", absf(onde5.y - boias[5].global_position.y) < 0.4,
			"(%.1f, %.1f, %.1f)" % [onde5.x, onde5.y, onde5.z]) and ok
	var no_balde := await _pular_para(_na_beira(onde5 + Vector3.UP * 0.1, n.balde_topo, boias[5]), n.balde_topo + Vector3(-1.2, 0, 1.4))
	ok = m._conferir("etapa 2: e da boia para cima do balde", absf(no_balde.y - n.balde_topo.y) < 0.3,
			"(%.1f, %.1f, %.1f)" % [no_balde.x, no_balde.y, no_balde.z]) and ok
	# Etapa 3: o registro do balde.
	if not await _girar(n.registros[2]):
		ok = m._conferir("um soco gira o registro do balde", false) and ok
	await _ate(func() -> bool: return e.etapa == 3 and not e.subindo_agora, 10.0)
	ok = m._conferir("o registro do balde sobe a água para a etapa 3 (7,2 m), abaixo dos tampos", absf(e.nivel - 7.2) < 0.05,
			"(nível %.2f)" % e.nivel) and ok
	de = n.balde_topo + Vector3(-1.5, 0.1, 0.5)
	for i in range(6, 8):
		var b: Boia = boias[i]
		var onde := await _pular_para(_na_beira(de, b.global_position, boias[i - 1] if i > 6 else null), b.global_position)
		ok = m._conferir("etapa 3: pula para %s" % ("o prato" if i == 6 else "o pote de sorvete (alto)"), absf(onde.y - b.global_position.y) < 0.4,
				"(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
		de = onde + Vector3.UP * 0.1
	de = _na_beira(de, Vector3(34.3, 11.1, -79.5), boias[7])
	for alto in [Vector3(34.3, 11.1, -79.5), Vector3(33.8, 13.0, -84.0)]:
		var onde := await _pular_para(de, alto)
		ok = m._conferir("etapa 3: sobe na torre de potes (%.1f m)" % alto.y, absf(onde.y - alto.y) < 0.3,
				"(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
		# Do degrau, pula da beirada que dá para o alto.
		de = Vector3(33.8, 11.2, -81.2)
	# A bandeja: espera ela encostar na torre, pula nela, vai até a prateleira e desce.
	var bandeja := n.bandeja
	await _ate(func() -> bool: return bandeja.global_position.x > 27.2, 14.0)
	var na_bandeja := await _pular_para(de, bandeja.global_position + Vector3(0, 0.8, 0))
	await _ate(func() -> bool: return bandeja.global_position.x < 18.2, 14.0)
	await _andar(Vector3(-1, 0, 0), 1.4)
	ok = m._conferir("a bandeja leva da torre de potes até a prateleira atrás da geladeira", absf(na_bandeja.y - 13.0) < 0.4
			and absf(j.global_position.y - 14.0) < 0.3 and j.global_position.x < 14.0, "(%.1f, %.1f, %.1f)" % [j.global_position.x, j.global_position.y, j.global_position.z]) and ok
	return ok


## Onde pular na boia `em` (ou no chão firme, sem ela) para alcançar `alvo`: perto da beirada dela, na direção do
## alvo, como faz quem joga. Sem `em`, fica em `de`.
func _na_beira(de: Vector3, alvo: Vector3, em: Boia) -> Vector3:
	if em == null:
		return de
	var raio: float = {"esponja": 1.1, "prato": 2.7, "patinho": 1.0, "pote": 1.4}[em.tipo]
	var dir := Vector3(alvo.x - em.global_position.x, 0, alvo.z - em.global_position.z).normalized()
	return em.global_position + dir * raio + Vector3.UP * 0.1


## Soca o registro (de frente para ele, do lado de dentro do tampo, que nos três fica para -x e +z). Devolve se girou.
func _girar(r: Registro) -> bool:
	var frente := Vector3(-1, 0, 1).normalized() * 1.4
	j.teleportar(r.global_position + frente + Vector3.UP * 0.1)
	j.visual.rotation.y = atan2(-frente.x, -frente.z)
	await m._esperar(0.4)
	await m._toque(JOY_BUTTON_X)
	await m._esperar(0.8)
	return r.girado_ja


## Espera `cond` ficar verdade (até `segundos`).
func _ate(cond: Callable, segundos: float) -> void:
	var t := 0.0
	while t < segundos and not cond.call():
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second


## O pulo mais longo de `de` na direção de `alvo`: correndo, segurando o pulo até o fim (flutua) e o laser. Devolve o
## ponto mais longe que alcançou (em direção ao alvo) antes de cair ou pousar.
func _pular_longe(de: Vector3, alvo: Vector3) -> Vector3:
	var dir := Vector3(alvo.x - de.x, 0, alvo.z - de.z).normalized()
	j.teleportar(de - dir * 3.0)
	await m._esperar(0.3)
	j.yaw = atan2(-dir.x, -dir.z)
	j.forcar_direcao = Vector2(0, -1)
	var mais_longe := j.global_position
	var pulou := false
	for i in 400:
		await m.get_tree().physics_frame
		if not pulou and (j.global_position - de).dot(dir) > -0.3:
			j.forcar_pulo = true
			pulou = true
		if (j.global_position - de).dot(dir) > (mais_longe - de).dot(dir):
			mais_longe = j.global_position
		if pulou and i > 30 and (j.is_on_floor() or j.global_position.y < n.limite_queda + 0.5):
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	await m._esperar(1.2)
	return mais_longe


## Índice do playground com o centro mais perto de `p`.
func _playground_mais_perto(p: Vector3) -> int:
	var melhor := 0
	for i in n.playgrounds.size():
		if p.distance_to(n.playgrounds[i].centro) < p.distance_to(n.playgrounds[melhor].centro):
			melhor = i
	return melhor


## Do chão em `de`, pula (o pulo inteiro, sem flutuar) e se guia no ar até em cima de `alvo`. Devolve onde pousou.
func _pular_para(de: Vector3, alvo: Vector3) -> Vector3:
	j.teleportar(de)
	await m._esperar(0.3)
	j.forcar_pulo = true
	for i in 300:
		await m.get_tree().physics_frame
		var falta := Vector3(alvo.x - j.global_position.x, 0, alvo.z - j.global_position.z)
		if falta.length() > 0.6:
			j.yaw = atan2(-falta.x, -falta.z)
			j.forcar_direcao = Vector2(0, -1)
		else:
			j.forcar_direcao = Vector2.ZERO
		if i > 3 and j.velocity.y <= 0.5:
			j.forcar_pulo = false
		if i > 12 and j.is_on_floor():
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	var onde := j.global_position
	await m._esperar(0.1)
	return onde


## Em cima da tampa, espera ela pular e se guia no ar (flutuando) até em cima de `alvo`. Devolve onde pousou.
func _tampa_para(t: TampaQuePula, alvo: Vector3) -> Vector3:
	j.teleportar(t.global_position + Vector3(0, 1.6, 0))
	await m._esperar(0.3)
	while t.fase_do_ciclo() != "pula":
		await m.get_tree().physics_frame
	var subiu := false
	for i in 500:
		await m.get_tree().physics_frame
		if j.global_position.y > t.global_position.y + 3.0:
			subiu = true
			j.forcar_pulo = true
		var falta := Vector3(alvo.x - j.global_position.x, 0, alvo.z - j.global_position.z)
		if subiu and falta.length() > 0.8:
			j.yaw = atan2(-falta.x, -falta.z)
			j.forcar_direcao = Vector2(0, -1)
		else:
			j.forcar_direcao = Vector2.ZERO
		if subiu and i > 20 and j.is_on_floor():
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	await m._esperar(0.2)
	return j.global_position


## Põe o Faísca em cima da mola e o guia no ar até em cima de `alvo` (solta o direcional perto). Devolve onde pousou.
func _quicar(mola_: Area3D, alvo: Vector3) -> Vector3:
	j.teleportar(mola_.global_position + Vector3(0, 0.4, 0))
	var subiu := false
	for i in 400:
		await m.get_tree().physics_frame
		var falta := Vector3(alvo.x - j.global_position.x, 0, alvo.z - j.global_position.z)
		if j.global_position.y > mola_.global_position.y + 1.5:
			subiu = true
		if subiu and falta.length() > 0.8:
			j.yaw = atan2(-falta.x, -falta.z)
			j.forcar_direcao = Vector2(0, -1)
		else:
			j.forcar_direcao = Vector2.ZERO
		if subiu and i > 20 and j.is_on_floor():
			break
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.2)
	return j.global_position


## Anda na direção `dir` (no chão) por `segundos`.
func _andar(dir: Vector3, segundos: float) -> void:
	j.yaw = atan2(-dir.x, -dir.z)
	j.forcar_direcao = Vector2(0, -1)
	await m._esperar(segundos)
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.2)


## Fotos da 2-1 em playgrounds (precisa de janela): de cima, cada playground de dentro, as viagens e a arena.
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "fase_2_1/"))
	for b in n.alvos:
		(b as Bolota).dormindo = true
		b.process_mode = Node.PROCESS_MODE_DISABLED
	m._comecar_fase()
	await m._esperar(4.0)
	await _foto_de_cima(Vector3(60, 70, 20), Vector3(-8, 8, -62), "fase_2_1/00_visao_geral")
	await _foto_de_cima(Vector3(-50, 60, -130), Vector3(0, 8, -55), "fase_2_1/00b_de_cima_norte")
	await _foto_em(n.inicio, 0.0, -0.12, "fase_2_1/01_mesa_do_cafe")
	await _foto_em(Vector3(-6.0, 8.1, -18.0), 1.25, -0.2, "fase_2_1/01b_ponte_de_tabuas")
	await _foto_de_cima(Vector3(-20, 30, 0), Vector3(-46, 8, -36), "fase_2_1/02_bancada_das_panelas")
	await _foto_em(Vector3(-34.0, 8.1, -22.0), 0.6, -0.15, "fase_2_1/02b_bancada_de_dentro")
	await _foto_de_cima(Vector3(-10, 34, -60), Vector3(-38, 8, -92), "fase_2_1/03_fogao_e_pizza")
	await _foto_em(Vector3(-40.0, 8.1, -71.5), 0.1, -0.2, "fase_2_1/03b_pizza")
	await _foto_de_cima(Vector3(44, 34, -110), Vector3(16, 8, -70), "fase_2_1/04_pia_e_prateleira")
	await _foto_em(Vector3(22.0, 8.1, -95.0), 0.0, -0.25, "fase_2_1/04b_pia_de_dentro")
	await _foto_em(Vector3(11.0, 14.1, -48.0), 0.0, 0.1, "fase_2_1/04c_prateleira")
	await _foto_em(Vector3(4.0, 20.1, -64.0), 0.4, -0.3, "fase_2_1/05_em_cima_da_geladeira")
	# A Cozinha Alagando: seca, e depois de cada etapa da enchente.
	await _foto_de_cima(Vector3(10, 30, -20), Vector3(46, 4, -62), "fase_2_1/06_cozinha_seca")
	await _foto_em(Vector3(27.0, 8.1, -47.0), -PI / 2.0 + 0.15, -0.25, "fase_2_1/06b_registro_e_arco")
	n.enchente.encher_ate(1)
	await m._esperar(0.4)
	await _foto_de_cima(Vector3(10, 30, -20), Vector3(46, 4, -62), "fase_2_1/07_etapa_1")
	await _foto_em(Vector3(27.0, 8.1, -47.0), -PI / 2.0 + 0.15, -0.3, "fase_2_1/07b_etapa_1_da_bancada")
	await _foto_de_cima(Vector3(48, 18, -40), Vector3(30, 5, -74), "fase_2_1/07c_cascata")
	n.enchente.encher_ate(2)
	await m._esperar(0.4)
	await _foto_em(n.escadinha_topo + Vector3(0, 0.1, 2.0), 0.0, -0.3, "fase_2_1/08_etapa_2_da_escadinha")
	await _foto_em(n.patinho.global_position + Vector3(-5, 0.6, 3), -0.9, -0.25, "fase_2_1/08b_patinho")
	n.enchente.encher_ate(3)
	await m._esperar(0.4)
	await _foto_em(n.balde_topo + Vector3(0, 0.1, 1.0), PI / 2.0 - 0.1, -0.2, "fase_2_1/09_etapa_3_do_balde")
	await _foto_de_cima(Vector3(60, 26, -60), Vector3(28, 10, -82), "fase_2_1/09b_torre_e_bandeja")
	await _foto_de_cima(Vector3(10, 70, 0), Vector3(30, 4, -64), "fase_2_1/09c_cozinha_alagada")
	m.get_tree().quit()


## Foto de longe, com uma câmera solta em `de` olhando para `para` (a do Faísca volta depois).
func _foto_de_cima(de: Vector3, para: Vector3, nome: String) -> void:
	var cam := Camera3D.new()
	cam.fov = 55.0
	cam.far = 1500.0
	m.add_child(cam)
	cam.look_at_from_position(de, para, Vector3.UP)
	cam.current = true
	await m._esperar(0.3)
	await m._foto(nome)
	cam.queue_free()
	j.camera.current = true


func _foto_em(pos: Vector3, yaw: float, pitch: float, nome: String) -> void:
	j.teleportar(pos)
	j.yaw = yaw
	j.pitch = pitch
	j.visual.rotation.y = yaw + PI
	await m._esperar(0.8)
	await m._foto(nome)
