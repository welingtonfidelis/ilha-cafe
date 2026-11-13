class_name TesteFase33
extends RefCounted
## Testes da 3-3 Moinhos do Vento (feita em 2026-11-12), chamados pelo FaiscaSolo:
##   --faisca-fase-3-3           confere a fase de ponta a ponta: contagens, o padrão de playgrounds (o brilho no
##                               telhado do Moinho Gigante à vista de cada entrada), a campina (a faixa de vento que leva
##                               por cima do riacho, o voo sem vento, a água que só molha, os cata-ventos e o portão de
##                               feno), o balão, as ilhas (as faixas a favor, as argolas-sino, a nuvem, o V1 pela faixa
##                               que desce e o fardo que quica de volta), a fazenda (a Pipa, a coluna sem e com ela, os
##                               cata-ventos dos silos, o teleférico e o V2 no telhado), o corredor (o freio pela coluna,
##                               o moinho destravado levando na gôndola, as rajadas), a subida (as janelas que soltam as
##                               colunas, a sacada que segura a queda, a parede rachada) e o vendaval até a arena
##   --faisca-fase-3-3-captura   fotos de cada playground em tools/capturas/faisca/fase_3_3/ (precisa de janela)

var m: Node
var n: Fase33
var j: Jogador


func _init(main: Node) -> void:
	m = main
	n = main.nivel
	j = main.jogador
	main.testando = true


func rodar() -> void:
	var ok := true
	await m._esperar(0.3)
	ok = m._conferir("de 100 a 170 estrelinhas no caminho e nos bolsos (fora as das Bolotas)", n.estrelas.size() >= 100 and n.estrelas.size() <= 170,
			"(%d soltas, %d com as das Bolotas)" % [n.estrelas.size(), n.total_estrelas()]) and ok
	ok = m._conferir("4 postos, 6 Faisquinhas, 3 corações e o baú", n.postos.size() == 4 and n.faisquinhas.size() == 6
			and n.coracoes.size() == 3 and n.bau != null, "(%d postos, %d Bolotas, %d corações)" % [n.postos.size(), n.alvos.size(), n.coracoes.size()]) and ok
	ok = m._conferir("peças: 6 cata-ventos, 3 argolas-sino, 3 moinhos com freio, 3 janelas, 3 caronas e a Pipa",
			n.catavento_da_campina.size() == 3 and n.catavento_dos_silos.size() == 3 and n.argolas_sino.size() == 3 and n.moinhos.size() == 3
			and n.freios.size() == 3 and n.janelas.size() == 3 and n.caronas.size() == 3 and n._pipa != null,
			"(%d faixas de vento, %d colunas)" % [n.faixas.size(), n.colunas.size()]) and ok
	await m.get_tree().physics_frame
	var espaco := j.get_world_3d().direct_space_state
	ok = m._conferir("5 playgrounds e 4 arcos de saída", n.playgrounds.size() == 5 and n.saidas.size() == 4) and ok
	var cegos := n.playgrounds.filter(func(p: Dictionary) -> bool:
		return not espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p.entrada + Vector3.UP * 2.0, n.brilho_do_marco, 1)).is_empty())
	ok = m._conferir("da entrada de cada playground dá para ver o brilho no telhado do Moinho Gigante", cegos.is_empty(),
			"(sem ver: %s)" % ", ".join(cegos.map(func(p: Dictionary) -> String: return p.nome))) and ok
	var donos := n.faisquinhas.slice(0, 3).map(func(v: Faisquinha) -> int: return _playground_mais_perto(v.global_position))
	ok = m._conferir("um vaga-lume no bolso do playground 2, do 3 e do 4", donos == [1, 2, 3], "(%s)" % str(donos)) and ok
	ok = m._conferir("a arena fica no topo do Moinho Gigante: o baú é o ponto mais alto do caminho", n.bau.global_position.y > 39.5) and ok
	for b in n.alvos.slice(1):
		b.process_mode = Node.PROCESS_MODE_DISABLED

	m._comecar_fase()
	await m._esperar(4.0)
	ok = m._conferir("desce flutuando e pisa na grama da campina", j.is_on_floor() and j.controle_ligado and absf(j.global_position.y) < 0.3
			and j.global_position.distance_to(n.inicio) < 1.0) and ok
	ok = await _campina() and ok
	ok = await _ilhas() and ok
	ok = await _fazenda() and ok
	ok = await _corredor() and ok
	ok = await _subida() and ok
	print("RESULTADO: " + ("tudo certo" if ok else "com falhas"))
	m.get_tree().quit()


## Playground 1: a faixa de vento por cima do riacho, o voo sem vento, a água, os cata-ventos e o portão de feno.
func _campina() -> bool:
	var ok := true
	var faixa: FaixaDeVento = n.faixas[0]
	# Sem vento: o mesmo pulo flutuando, de lado, anda bem menos.
	var sem := await _flutuar_de(Vector3(-10, 0.1, 124), Vector3(0, 0, -1), 2.2)
	var com := await _flutuar_de(faixa.de * Vector3(1, 0, 1) + Vector3(0, 0.1, 0), Vector3(0, 0, -1), 4.0)
	ok = m._conferir("flutuando no vento, o Faísca é levado por cima do riacho e pousa do outro lado", com.z < Fase33.RIACHO.x - 1.0
			and n.molhou == 0 and absf(com.y) < 0.4, "(pousou em z %.1f, y %.1f)" % [com.z, com.y]) and ok
	ok = m._conferir("sem vento, o voo sozinho vai bem menos longe", 124.0 - sem.z < 14.0 and (faixa.de.z - com.z) > (124.0 - sem.z) + 5.0,
			"(sem vento %.1f m, com vento %.1f m)" % [124.0 - sem.z, faixa.de.z - com.z]) and ok
	# A água só molha: andando para dentro do riacho, ele não perde coração e sai pelas pedras.
	var vida := j.vida
	j.teleportar(Vector3(-10, 0.1, 113))
	await _andar(Vector3(0, 0, -1), 1.6)
	ok = m._conferir("no riacho ele só se molha (sem perder coração)", n.molhou >= 1 and j.vida == vida, "(molhou %d)" % n.molhou) and ok
	# Os cata-ventos: um soco em cada.
	for c in n.catavento_da_campina:
		await _socar(c, c.global_position)
	ok = m._conferir("um soco em cada cata-vento faz girar, e com os três o portão de feno abre", n.catavento_da_campina.all(func(c: CataVento) -> bool: return c.girando)
			and n.portao_aberto_ja()) and ok
	await m._esperar(1.2)
	# Pelo arco (em linha reta ele batia no poste de um cata-vento) e pela ponte até o balão.
	await _correr_ate(Vector3(-22, 0, 93.5), 8.0)
	var chegou := await _correr_ate(n.balao.de, 8.0)
	await m._esperar(0.3)
	await _ate(func() -> bool: return n.balao.estado == "em_ate", 20.0)
	ok = m._conferir("pelo portão, o balão de ar quente leva até as ilhas do vento", chegou and n.balao.estado == "em_ate"
			and j.global_position.distance_to(n.balao.ate) < 3.0, "(%s)" % n.balao.estado) and ok
	return ok


## Playground 2: as faixas a favor (com as argolas-sino), o V1 pela faixa que desce e o fardo que quica, e a nuvem.
func _ilhas() -> bool:
	var ok := true
	j.teleportar(n.postos[0].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P1 acende na chegada das ilhas", n.postos[0].acendido) and ok
	var meio := Vector3(-96, 12, 40)
	# As três faixas: flutuando em cada uma, passa pela argola e chega na ilha seguinte.
	var pousos := []
	for i in 3:
		var f: FaixaDeVento = n.faixas[1 + i]
		var dir := (f.ate - f.de) * Vector3(1, 0, 1)
		var de := f.de - dir.normalized() * 1.5
		var chao := _chao_em(de)
		pousos.append(await _flutuar_de(chao + Vector3.UP * 0.1, dir.normalized(), 6.0))
	var tocadas := n.argolas_sino.filter(func(a: ArgolaSino) -> bool: return a.tocada).size()
	ok = m._conferir("flutuando nas três faixas, ele passa pelas três argolas-sino e chega do outro lado dos vãos", tocadas == 3
			and pousos.all(func(p: Vector3) -> bool: return p.y > 9.0), "(%d argolas, pousos %s)" % [tocadas, str(pousos.map(func(p: Vector3) -> String: return "%.0f" % p.y))]) and ok
	ok = m._conferir("com as três argolas, a nuvem soprada destrava", not n.nuvem_soprada.travada) and ok
	# Contra o vento não dá: da beira do meio, flutuando contra a faixa A, não volta para a chegada.
	var a: FaixaDeVento = n.faixas[1]
	var chegada := Vector3(-68, 10, 58)
	j.teleportar(_chao_em(a.ate + (a.ate - a.de).normalized() * 1.0) + Vector3.UP * 0.1)
	await m._esperar(0.3)
	j.forcar_pulo = true
	var mais_perto := INF
	for k in 240:
		_empurrar_para((a.de - a.ate).normalized() * Vector3(1, 0, 1))
		await m.get_tree().physics_frame
		mais_perto = minf(mais_perto, Vector2(j.global_position.x - chegada.x, j.global_position.z - chegada.z).length())
	j.forcar_pulo = false
	j.forcar_direcao = Vector2.ZERO
	ok = m._conferir("contra o vento, ele não atravessa (fica parado no ar)", mais_perto > 12.0, "(chegou a %.1f m da chegada)" % mais_perto) and ok
	await _ate(func() -> bool: return j.is_on_floor(), 6.0)
	# O V1: a faixa que desce leva até a ilhota; o fardo que quica devolve.
	var d: FaixaDeVento = n.faixas[4]
	j.teleportar(_chao_em(d.de + Vector3(1.0, 0, -1.0)) + Vector3.UP * 0.1)
	await m._esperar(0.3)
	var embaixo := await _flutuar_ate(Vector3(-106, 3, 50), 5.0)
	ok = m._conferir("a faixa que desce leva até a ilhota do V1", embaixo.y < 5.0 and embaixo.y > 2.0 and Vector2(embaixo.x + 106, embaixo.z - 50).length() < 4.0,
			"(%.1f, %.1f, %.1f)" % [embaixo.x, embaixo.y, embaixo.z]) and ok
	var volta := await _quicar_ate(Vector3(-104.4, 3.1, 49.4), meio + Vector3(-7, 0, 6))
	ok = m._conferir("o fardo que quica devolve para a ilha do meio", volta.y > 11.0, "(pousou em y %.1f)" % volta.y) and ok
	# A nuvem leva à fazenda.
	j.teleportar(n.nuvem_soprada.global_position + Vector3(0, 0.3, 0))
	await _ate(func() -> bool: return n.nuvem_soprada.estado == "em_ate", 25.0)
	ok = m._conferir("a nuvem soprada leva até a fazenda", n.nuvem_soprada.estado == "em_ate" and j.global_position.distance_to(n.nuvem_soprada.ate) < 3.0) and ok
	return ok


## Playground 3: a coluna sem pipa e com ela, a Pipa no celeiro, os cata-ventos dos silos, o V2 e o teleférico.
func _fazenda() -> bool:
	var ok := true
	var c0: ColunaDeVento = n.colunas[0]
	# Sem a pipa, a coluna só segura a queda.
	var y_sem := await _pairar_na_coluna(c0, 2.5)
	ok = m._conferir("sem a pipa, a coluna de vento só segura a queda (ele não sobe)", y_sem < c0.global_position.y + 3.0, "(chegou a y %.1f)" % y_sem) and ok
	# A Pipa, na porta do celeiro.
	j.teleportar(n._pipa.global_position + Vector3(0, -1.5, 0))
	await m._esperar(0.5)
	ok = m._conferir("a Pipa fica na porta do celeiro, e o Vovô mostra como usa", n.pipa_pega and j.pipa and m.hud.dica_atual == "pipa") and ok
	var y_com := await _pairar_na_coluna(c0, 4.0)
	ok = m._conferir("com a pipa, a coluna leva até lá no alto, e ele fica pairando", y_com > c0.topo_y - 1.2 and y_com < c0.topo_y + 1.5,
			"(chegou a y %.1f; o topo é %.1f)" % [y_com, c0.topo_y]) and ok
	# Os cata-ventos dos silos: a coluna leva, ele vai para cima do silo e dá o soco.
	for i in 3:
		var c: CataVento = n.catavento_dos_silos[i]
		var col: ColunaDeVento = n.colunas[i]
		await _pairar_na_coluna(col, 3.0, false)
		var em_cima := await _flutuar_ate(c.global_position + ((col.global_position - c.global_position) * Vector3(1, 0, 1)).normalized() * 1.3, 3.0)
		await _socar(c, c.global_position, false)
		if not c.girando:
			print("  silo %d: pousou em %s" % [i, em_cima])
	ok = m._conferir("pela coluna, ele chega no alto de cada silo e o soco faz o cata-vento girar; com os três, o teleférico destrava",
			n.catavento_dos_silos.all(func(c: CataVento) -> bool: return c.girando) and not n.teleferico.travada,
			"(%d girando)" % n.catavento_dos_silos.filter(func(c: CataVento) -> bool: return c.girando).size()) and ok
	# O V2: a coluna atrás do celeiro leva ao telhado.
	var v2 := n.faisquinhas[1]
	var col_v2: ColunaDeVento = n.colunas[3]
	await _pairar_na_coluna(col_v2, 3.0, false)
	await _flutuar_ate(v2.global_position - Vector3.UP * 1.4, 3.0)
	await m._esperar(0.6)
	ok = m._conferir("a coluna atrás do celeiro leva ao telhado, onde está o V2", v2.encontrado, "(%s)" % j.global_position) and ok
	# O teleférico leva ao corredor.
	j.teleportar(n.teleferico.global_position + Vector3(0, 0.3, 0))
	await _ate(func() -> bool: return n.teleferico.estado == "em_ate", 25.0)
	ok = m._conferir("o teleférico leva até o corredor dos moinhos", n.teleferico.estado == "em_ate" and j.global_position.distance_to(n.teleferico.ate) < 3.0) and ok
	return ok


## Playground 4: os moinhos travados, o freio pela coluna, a gôndola levando até a ilha seguinte e as rajadas.
func _corredor() -> bool:
	var ok := true
	j.teleportar(n.postos[2].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P3 acende na primeira ilha do corredor", n.postos[2].acendido) and ok
	var m0 := n.moinhos[0]
	var antes := m0.angulo
	await m._esperar(1.0)
	ok = m._conferir("travado, o moinho não gira", is_equal_approx(m0.angulo, antes) and m0.travado) and ok
	# O freio: a coluna ao lado leva até a janela do eixo; um soco solta.
	for i in 3:
		var col: ColunaDeVento = n.colunas[4 + i]
		await _pairar_na_coluna(col, 3.0, false)
		await _socar(n.freios[i], n.freios[i].global_position, false)
	ok = m._conferir("pela coluna, o soco no freio de cada moinho solta as pás", n.moinhos.all(func(x: MoinhoDeGondolas) -> bool: return not x.travado)) and ok
	await m._esperar(3.0)
	ok = m._conferir("destravado, o moinho gira devagar e as gôndolas andam", m0.angulo < antes - 0.2) and ok
	# A gôndola leva: em cima de uma, ele vai junto (e as gôndolas ficam niveladas).
	var g: AnimatableBody3D = m0.gondolas[0]
	j.forcar_pulo = false
	j.teleportar(g.global_position + Vector3.UP * 0.5)
	await m._esperar(0.4)
	var pe0 := j.global_position
	await m._esperar(3.0)
	ok = m._conferir("em cima da gôndola, ele vai junto com ela (e ela continua nivelada)", j.global_position.distance_to(pe0) > 2.0
			and j.global_position.distance_to(g.global_position) < 2.2 and absf(g.global_rotation.x) < 0.01 and absf(g.global_rotation.z) < 0.01,
			"(andou %.1f m)" % j.global_position.distance_to(pe0)) and ok
	# Da gôndola, no ponto mais perto da ilha seguinte (e mais alta que ela), dá para descer flutuando até lá.
	var g2 := n.no_moinho(22, 40, 28)
	var melhor := [INF, 0.0, 0]
	for k in 160:
		var ang := m0.angulo - k * 0.04
		for i in 4:
			var a := ang + i * PI / 2.0
			var local := Vector3(0, m0.altura_eixo, MoinhoDeGondolas.FRENTE + 1.6) + Vector3(-sin(a), cos(a), 0) * m0.raio_roda + Vector3.DOWN * 1.25
			var p := m0.global_transform * local
			var dist := Vector2(p.x - g2.x, p.z - g2.z).length()
			if p.y > g2.y + 2.0 and dist < melhor[0]:
				melhor = [dist, ang, i]
	m0.travado = true
	m0._velocidade = 0.0
	m0.angulo = melhor[1]
	m0._posicionar()
	await m._esperar(0.2)
	var gondola: AnimatableBody3D = m0.gondolas[melhor[2]]
	j.forcar_pulo = false
	j.teleportar(gondola.global_position + Vector3.UP * 0.5)
	await m._esperar(0.4)
	var pousou := await _flutuar_ate(g2, 4.0)
	ok = m._conferir("da gôndola, no ponto mais perto, ele desce flutuando até a ilha seguinte", Vector2(pousou.x - g2.x, pousou.z - g2.z).length() < 5.0
			and absf(pousou.y - g2.y) < 0.5, "(a %.1f m dela; pousou em %s)" % [melhor[0], pousou]) and ok
	m0.travado = false
	# As rajadas vão e voltam.
	var r: FaixaDeVento = n.faixas.filter(func(f: FaixaDeVento) -> bool: return f.rajada)[0]
	var viu := {}
	for k in 360:
		await m.get_tree().physics_frame
		viu[r.ativa] = true
	ok = m._conferir("as rajadas de lado entre as ilhas sopram e param", viu.size() == 2) and ok
	return ok


## Playground 5: as janelas que soltam as colunas, a sacada que segura a queda, a parede rachada e o vendaval.
func _subida() -> bool:
	var ok := true
	j.teleportar(n.postos[3].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P4 acende na sacada de baixo do Moinho Gigante", n.postos[3].acendido) and ok
	ok = m._conferir("antes das janelas, as colunas da escada estão desligadas", n.colunas_das_janelas.all(func(c: ColunaDeVento) -> bool: return not c.ligada)) and ok
	# Do último degrau de cada trecho: o soco no ferrolho da janela, a coluna, e o voo até o trecho seguinte.
	for k in 2:
		var ultimo := n.degraus[(k + 1) * Fase33.DEGRAUS_POR_TRECHO - 1]
		j.teleportar(ultimo.global_position + Vector3.UP * 0.4)
		await m._esperar(0.4)
		await _socar(n.janelas[k], n.janelas[k].global_position, false)
		var col := n.colunas_das_janelas[k]
		await _pairar_na_coluna(col, 3.0, false)
		var proximo := n.degraus[(k + 1) * Fase33.DEGRAUS_POR_TRECHO]
		await _flutuar_ate(proximo.global_position + Vector3.UP * 0.2, 3.0)
		await m._esperar(0.4)
		ok = m._conferir("trecho %d: o soco na janela solta a coluna, que leva até o trecho seguinte" % (k + 1), col.ligada and j.is_on_floor()
				and absf(j.global_position.y - (proximo.global_position.y + 0.2)) < 0.6, "(y %.1f)" % j.global_position.y) and ok
	# Caindo da escada, a sacada de baixo segura.
	# Do degrau de -176 graus, longe dos pilares da arena (de 30 em 30 graus, a partir de 15).
	j.teleportar(n.degraus[9].global_position + Vector3.UP * 0.4 + n.no_moinho(-140.0 - 3 * 12.0, 1.0, 0) * 2.2)
	# Logo depois de teleportar, o "no chão" ainda é o do degrau: espera ele sair do lugar antes.
	await m._esperar(0.2)
	await _ate(func() -> bool: return j.is_on_floor(), 3.0)
	await m._esperar(0.3)
	ok = m._conferir("quem cai da escada cai na sacada de baixo", j.is_on_floor() and absf(j.global_position.y - Fase33.SACADA_BAIXA) < 0.4) and ok
	# A parede rachada: três golpes abrem a salinha.
	var parede := n.parede_secreta
	for k in 3:
		await _socar(parede, parede.global_position, true, 2.0)
	ok = m._conferir("três golpes abrem a parede rachada da salinha (o coração e o Faisquinha 4)", parede.derrotado) and ok
	# O vendaval: a terceira janela, do último degrau, leva o Faísca voando até a arena.
	var ultimo2 := n.degraus[n.degraus.size() - 1]
	j.teleportar(ultimo2.global_position + Vector3.UP * 0.4)
	await m._esperar(0.4)
	var pegas := n.pegas
	await _socar(n.janelas[2], n.janelas[2].global_position, false)
	ok = m._conferir("a terceira janela acorda o vendaval, que leva o Faísca (sem o controle)", n.vendaval.levando and not j.controle_ligado) and ok
	var alto := 0.0
	for k in 600:
		await m.get_tree().physics_frame
		alto = maxf(alto, j.global_position.y)
		if not n.vendaval.levando:
			break
	await m._esperar(0.5)
	ok = m._conferir("o vendaval leva voando em volta do moinho, pelas estrelinhas, até a arena, e devolve o controle", not n.vendaval.levando
			and j.controle_ligado and j.is_on_floor() and absf(j.global_position.y - Fase33.SACADA_TOPO) < 0.5 and alto > 43.0 and n.pegas >= pegas + 5,
			"(subiu até %.1f, pegou %d estrelinhas)" % [alto, n.pegas - pegas]) and ok
	# De volta no último degrau, o vendaval leva de novo.
	j.teleportar(ultimo2.global_position + Vector3.UP * 0.4)
	await _ate(func() -> bool: return n.vendaval.levando, 2.0)
	ok = m._conferir("depois, o último degrau chama o vendaval de novo", n.vendaval.vezes == 2) and ok
	await _ate(func() -> bool: return not n.vendaval.levando, 10.0)
	await m._esperar(0.5)
	# A arena: o baú.
	var bau := n.bau
	j.teleportar(bau.global_position + bau.global_basis.z * 2.4 + Vector3.UP * 0.1)
	await m._esperar(0.3)
	for k in 3:
		bau.receber_golpe(1, j.global_position)
		await m._esperar(0.35)
	await _ate(func() -> bool: return bau._estrela_pronta, 3.0)
	var fim := [false]
	n.estrela_grande_pega.connect(func() -> void: fim[0] = true)
	j.teleportar(bau.estrela.global_position - Vector3(0, 1.2, 0))
	await _ate(func() -> bool: return fim[0], 3.0)
	ok = m._conferir("três golpes abrem o baú, e a Estrela Grande termina a fase", fim[0]) and ok
	return ok


# --- ajudas ---------------------------------------------------------------------------

func _ate(cond: Callable, segundos: float) -> void:
	var t := 0.0
	while t < segundos and not cond.call():
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second


func _playground_mais_perto(p: Vector3) -> int:
	var melhor := 0
	for i in n.playgrounds.size():
		if p.distance_to(n.playgrounds[i].centro) < p.distance_to(n.playgrounds[melhor].centro):
			melhor = i
	return melhor


## O chão embaixo de `p` (raio de cima).
func _chao_em(p: Vector3, de_cima := 30.0) -> Vector3:
	var batida := j.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * de_cima, p + Vector3.DOWN * 40.0, 1))
	return batida.position if not batida.is_empty() else p


## Corre até `alvo` pelo chão, com o analógico empurrado conforme a câmera. Devolve se chegou.
func _correr_ate(alvo: Vector3, segundos: float) -> bool:
	var t := 0.0
	var chegou := false
	while t < segundos:
		var d := Vector3(alvo.x - j.global_position.x, 0, alvo.z - j.global_position.z)
		if d.length() < 0.7:
			chegou = true
			break
		_empurrar_para(d.normalized())
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.2)
	return chegou


## O analógico empurrado para `d` (no mundo), conforme a câmera.
func _empurrar_para(d: Vector3) -> void:
	var base := j.camera_pivo.global_transform.basis
	var frente := Vector3(-base.z.x, 0.0, -base.z.z).normalized()
	var direita := Vector3(base.x.x, 0.0, base.x.z).normalized()
	j.forcar_direcao = Vector2(d.dot(direita), -d.dot(frente))


func _andar(dir: Vector3, segundos: float) -> void:
	var t := 0.0
	while t < segundos:
		_empurrar_para(dir)
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.3)


## Do chão em `de`, pula segurando o pulo (flutua) com o analógico para `dir` por até `segundos`; devolve onde pousou.
func _flutuar_de(de: Vector3, dir: Vector3, segundos: float) -> Vector3:
	j.teleportar(de)
	await m._esperar(0.3)
	j.forcar_pulo = true
	var t := 0.0
	while t < segundos:
		_empurrar_para(dir)
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		if t > 0.3 and j.is_on_floor():
			break
	j.forcar_pulo = false
	j.forcar_direcao = Vector2.ZERO
	await _ate(func() -> bool: return j.is_on_floor(), 3.0)
	await m._esperar(0.1)
	return j.global_position


## No chão ao pé da coluna: pula e segura (flutua) por `segundos`, sem andar; devolve a altura mais alta. Com
## `do_chao` falso, já começa em cima da grade.
func _pairar_na_coluna(c: ColunaDeVento, segundos: float, _do_chao := true) -> float:
	# Solta o pulo antes (senão o novo pulo não conta como apertado, e o giro no ar já foi gasto).
	j.forcar_pulo = false
	j.forcar_direcao = Vector2.ZERO
	j.teleportar(c.global_position + Vector3.UP * 0.15)
	await m._esperar(0.3)
	j.forcar_pulo = true
	var alto := j.global_position.y
	var t := 0.0
	while t < segundos:
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		alto = maxf(alto, j.global_position.y)
	return alto


## Ainda segurando o pulo (flutuando), vai até em cima de `alvo` e solta perto; devolve onde pousou.
func _flutuar_ate(alvo: Vector3, segundos: float) -> Vector3:
	j.forcar_pulo = true
	var t := 0.0
	while t < segundos:
		var falta := Vector3(alvo.x - j.global_position.x, 0, alvo.z - j.global_position.z)
		if falta.length() > 0.4:
			_empurrar_para(falta.normalized())
		else:
			j.forcar_direcao = Vector2.ZERO
			if j.global_position.y > alvo.y + 0.3:
				j.forcar_pulo = false
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		if t > 0.3 and j.is_on_floor() and falta.length() < 1.2:
			break
	j.forcar_pulo = false
	j.forcar_direcao = Vector2.ZERO
	await _ate(func() -> bool: return j.is_on_floor(), 3.0)
	await m._esperar(0.1)
	return j.global_position


## Pisa no fardo que quica (a mola em `pe`) e se guia no ar até `alvo`, flutuando na descida; devolve onde pousou.
func _quicar_ate(pe: Vector3, alvo: Vector3) -> Vector3:
	j.teleportar(pe + Vector3.UP * 3.0)
	var subiu := false
	for i in 500:
		await m.get_tree().physics_frame
		var falta := Vector3(alvo.x - j.global_position.x, 0, alvo.z - j.global_position.z)
		if j.global_position.y > pe.y + 4.0:
			subiu = true
		if subiu and falta.length() > 0.8:
			_empurrar_para(falta.normalized())
		else:
			j.forcar_direcao = Vector2.ZERO
		j.forcar_pulo = subiu and j.velocity.y < 0.0
		if subiu and i > 20 and j.is_on_floor():
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	await m._esperar(0.2)
	return j.global_position


## Vira para `alvo` e dá um soco (no chão, `no_chao` põe o Faísca a `distancia` m dele antes).
func _socar(quem: Node3D, alvo: Vector3, no_chao := true, distancia := 1.6) -> void:
	if no_chao:
		var fora := (j.global_position - alvo) * Vector3(1, 0, 1)
		if fora.length() < 0.1:
			fora = Vector3(0, 0, 1)
		j.teleportar(_chao_em(alvo + fora.normalized() * distancia, 3.0) + Vector3.UP * 0.1)
		await m._esperar(0.3)
	var d := alvo - j.global_position
	j.visual.rotation.y = atan2(d.x, d.z)
	j.forcar_golpe = true
	await m._esperar(0.6)
	if quem.has_method("receber_golpe") and not bool(quem.get("derrotado")) and quem.get("golpes") == null:
		# Se o golpe de verdade não alcançou (o teste mostra), fica registrado.
		print("  o soco não acertou %s (a %.1f m, dy %.1f)" % [quem.name, Vector2(d.x, d.z).length(), d.y])


## Fotos da 3-3 (precisa de janela): de cima, cada playground de cima e de dentro, as viagens, o vendaval e a arena.
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "fase_3_3/"))
	for b in n.alvos:
		(b as Bolota).dormindo = true
		b.process_mode = Node.PROCESS_MODE_DISABLED
	m._comecar_fase()
	await m._esperar(4.0)
	await _foto_de_cima(Vector3(150, 160, 220), Vector3(-30, 14, 10), "fase_3_3/00_visao_geral")
	await _foto_de_cima(Vector3(-210, 130, -170), Vector3(-30, 14, 20), "fase_3_3/00b_de_cima_noroeste")
	await _foto_em(n.inicio, 0.35, -0.12, "fase_3_3/01_campina")
	await _foto_de_cima(Vector3(40, 40, 150), Vector3(-4, 0, 100), "fase_3_3/01b_campina_de_cima")
	await _foto_em(Vector3(2, 0.1, 118), 0.0, -0.1, "fase_3_3/01c_riacho_e_vento")
	await _foto_em(Vector3(-2, 0.1, 82), -0.6, -0.1, "fase_3_3/01d_cata_ventos")
	await _foto_de_cima(Vector3(-40, 55, 100), Vector3(-90, 12, 40), "fase_3_3/02_ilhas_do_vento")
	await _foto_em(Vector3(-68, 10.1, 58), 0.95, -0.05, "fase_3_3/02b_ilhas_de_dentro")
	await _foto_de_cima(Vector3(-130, 65, -20), Vector3(-68, 18, -78), "fase_3_3/03_fazenda")
	await _foto_em(Vector3(-78, 18.1, -56), 0.9, -0.05, "fase_3_3/03b_fazenda_de_dentro")
	await _foto_de_cima(Vector3(-60, 52, -18), Vector3(-15, 22, -60), "fase_3_3/03c_teleferico")
	await _foto_de_cima(Vector3(95, 62, -60), Vector3(32, 28, -8), "fase_3_3/04_corredor")
	var g0 := n.no_moinho(70, 40, 22) + Vector3(-1.5, 0.1, -1.5)
	var para_g1 := n.no_moinho(46, 40, 25) - g0
	await _foto_em(g0, atan2(-para_g1.x, -para_g1.z), 0.15, "fase_3_3/04b_corredor_de_dentro")
	await _foto_de_cima(Vector3(-50, 66, 48), Vector3(0, 36, 0), "fase_3_3/05_moinho_gigante")
	await _foto_de_cima(n.no_moinho(-20, 34, 44), n.no_moinho(-80, 10, 33), "fase_3_3/05b_escada")
	# O vendaval: as janelas abertas e o Faísca no último degrau; a terceira acorda e leva.
	for f in n.janelas.slice(0, 2):
		f.abrir()
	j.teleportar(n.vendaval.de_onde + Vector3.UP * 0.2)
	await m._esperar(0.5)
	n.janelas[2].abrir()
	await m._esperar(2.2)
	await _foto_de_cima(n.no_moinho(-40, 48, 52), Vector3(0, 36, 0), "fase_3_3/05c_vendaval")
	await m._esperar(1.4)
	await m._foto("fase_3_3/05d_vendaval_de_perto")
	await _ate(func() -> bool: return not n.vendaval.levando, 10.0)
	await m._esperar(0.6)
	await _foto_em(n.vendaval.pouso + Vector3.UP * 0.1, PI, -0.25, "fase_3_3/06_arena")
	# A foto da porta no farol (assets/faisca/portas/fase_3_3.jpg, em 640x360): a campina com o moinho atrás, sem o HUD.
	m.hud.visible = false
	await _foto_de_cima(Vector3(30, 12, 152), Vector3(-2, 22, 50), "fase_3_3/porta")
	m.hud.visible = true
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
