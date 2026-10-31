class_name TesteFase32
extends RefCounted
## Testes da 3-2 Fábrica de Blocos (feita em 2026-10-31), chamados pelo FaiscaSolo:
##   --faisca-fase-3-2           confere a fase de ponta a ponta: contagens, o padrão de playgrounds (o brilho do
##                               baú à vista de cada entrada), a entrada (a esteira que leva, a expressa que desce, os
##                               blocos que o soco tomba para as esteiras e as luzes, a subida pela expressa, a prateleira
##                               do coração e o nicho), as máquinas (o posto e o monta-carga, o bloco-pisca que some e
##                               volta, a travessia pelos blocos-pisca, as alavancas, a ponte rolante e o cano do V1), a
##                               oficina (o pino que não afunda sem o martelinho, a escada até a caixa de ferramentas, a
##                               pancada em cima e do lado do pino, os pistões que viram escada, a Bolota de capacete e o
##                               pistão alto do V2), a empilhadeira, a pintura (a tinta que conta como cair, a esteira que
##                               leva e a que empurra, os pinos das latas e a ponte de blocos, a lata tombada), a subida da
##                               máquina (a queda no anel, a parede com os pinos, a esteira que sobe, os blocos-pisca e os
##                               pistões, o painel rachado do V3) e o baú no topo
##   --faisca-fase-3-2-captura   fotos de cada playground em tools/capturas/faisca/fase_3_2/ (precisa de janela)

var m: Node
var n: Fase32
var j: Jogador


func _init(main: Node) -> void:
	m = main
	n = main.nivel
	j = main.jogador
	main.testando = true


func rodar() -> void:
	var ok := true
	await m._esperar(0.3)
	ok = m._conferir("de 110 a 160 estrelinhas no caminho e nos bolsos (fora as das Bolotas)", n.estrelas.size() >= 110 and n.estrelas.size() <= 160,
			"(%d soltas, %d com as das Bolotas)" % [n.estrelas.size(), n.total_estrelas()]) and ok
	ok = m._conferir("4 postos, 3 vaga-lumes, 15 Bolotas, 4 corações e o baú", n.postos.size() == 4 and n.vaga_lumes.size() == 3
			and n.alvos.size() == 15 and n.coracoes.size() == 4 and n.bau != null, "(%d postos, %d Bolotas, %d corações)" % [n.postos.size(), n.alvos.size(), n.coracoes.size()]) and ok
	ok = m._conferir("peças: 3 blocos de empurrar, 3 alavancas, 10 pinos, 7 pistões, 16 blocos-pisca, 5 caronas e 23 esteiras",
			n.blocos_da_entrada.size() == 3 and n.alavancas.size() == 3 and n.pinos.size() == 10 and n.pistoes.size() == 7
			and n.blocos_pisca.size() == 16 and n.caronas.size() == 5 and n.esteiras.size() == 23,
			"(%d pinos, %d pistões, %d blocos-pisca, %d caronas, %d esteiras)" % [n.pinos.size(), n.pistoes.size(), n.blocos_pisca.size(), n.caronas.size(), n.esteiras.size()]) and ok

	# O padrão de playgrounds: cinco em volta da máquina, um arco de saída nos quatro primeiros, o brilho do baú à vista
	# de todas as entradas e um vaga-lume no bolso do 2, do 3 e do 5.
	await m.get_tree().physics_frame
	var espaco := j.get_world_3d().direct_space_state
	ok = m._conferir("5 playgrounds e 4 arcos de saída", n.playgrounds.size() == 5 and n.saidas.size() == 4) and ok
	var cegos := n.playgrounds.filter(func(p: Dictionary) -> bool:
		return not espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p.entrada + Vector3.UP * 2.0, n.brilho_do_marco, 1)).is_empty())
	ok = m._conferir("da entrada de cada playground dá para ver o brilho do baú em cima da máquina", cegos.is_empty(),
			"(sem ver: %s)" % ", ".join(cegos.map(func(p: Dictionary) -> String: return p.nome))) and ok
	var donos := n.vaga_lumes.map(func(v: VagaLume) -> int: return _playground_mais_perto(v.global_position))
	ok = m._conferir("um vaga-lume no bolso do playground 2, do 3 e do 5", donos == [1, 2, 4], "(%s)" % str(donos)) and ok
	ok = m._conferir("a arena fica no topo da máquina: o baú é o ponto mais alto do caminho", n.bau.global_position.y > 43.5
			and Vector2(n.bau.global_position.x, n.bau.global_position.z).length() < 4.0) and ok
	# As Bolotas ficam paradas no teste, menos a primeira, que dorme.
	for b in n.alvos.slice(1):
		b.process_mode = Node.PROCESS_MODE_DISABLED

	m._comecar_fase()
	await m._esperar(4.0)
	ok = m._conferir("desce flutuando e pisa no chão da fábrica", j.is_on_floor() and j.controle_ligado and absf(j.global_position.y) < 0.3
			and j.global_position.distance_to(n.inicio) < 1.0) and ok
	var b0 := n.alvos[0] as Bolota
	j.teleportar(b0.global_position + Vector3(0, 0.1, 1.6))
	j.visual.rotation.y = PI
	await m._esperar(0.3)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.45)
	await m._esperar(0.6)
	ok = m._conferir("o cogumelo que dorme na entrada apanha e sai quicando", b0.derrotado) and ok
	ok = await _entrada() and ok
	ok = await _maquinas() and ok
	ok = await _oficina() and ok
	ok = await _pintura() and ok
	ok = await _subida() and ok

	# A Bolota de capacete da arena só cai com a pancada; depois, o baú, a Estrela Grande e a tela de fim.
	var capacete := n.alvos[14] as BolotaMonstro
	ok = m._conferir("na arena, uma das Bolotas usa capacete", capacete.regra == "capacete") and ok
	await _pancada_em(capacete.global_position + Vector3(0.8, 0, 0))
	ok = m._conferir("a pancada derruba a Bolota de capacete da arena", capacete.derrotado) and ok
	var bau := n.bau
	var frente := bau.global_basis.z
	j.teleportar(bau.global_position + frente * 2.8 + Vector3(0, 0.1, 0))
	j.visual.rotation.y = atan2(-frente.x, -frente.z)
	await m._esperar(0.4)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.5)
	ok = m._conferir("três golpes abrem o baú, e a estrela do gancho some", bau.derrotado and bau.estrela != null and not n._estrela_do_gancho.visible,
			"(%d golpes)" % bau.golpes) and ok
	await m._esperar(1.2)
	j.teleportar(bau.global_position + frente * 2.4 + Vector3(0, 0.1, 0))
	await m._esperar(3.6)
	ok = m._conferir("pegar a Estrela Grande mostra a tela de fim", m.hud.fim_aberto and not j.controle_ligado) and ok
	m._terminar(ok)


## Playground 1 e a esteira expressa.
func _entrada() -> bool:
	var ok := true
	j.teleportar(Vector3(6, 0.1, 117))
	await m._esperar(0.4)
	ok = m._conferir("na entrada o Vovô mostra a esteira", m.hud.dica_atual == "esteira") and ok
	j.teleportar(Vector3(0, 0.3, 104))
	await m._esperar(0.3)
	var antes := j.global_position
	await m._esperar(1.6)
	ok = m._conferir("parado na esteira da entrada, ela leva o Faísca para a recebedora", antes.z - j.global_position.z > 2.5 and j.global_position.y < 0.5,
			"(%.1f m)" % (antes.z - j.global_position.z)) and ok

	# A expressa, antes da tarefa, desce: quem tenta subir andando volta para baixo.
	var e3 := n.expressa[3]
	var topo3 := e3.global_position + e3.global_basis.y * Esteira.ALTURA
	j.teleportar(topo3 + Vector3.UP * 0.4)
	await m._esperar(0.3)
	var longe_antes := Vector2(j.global_position.x - Fase32.EXPRESSA_FIM.x, j.global_position.z - Fase32.EXPRESSA_FIM.z).length()
	await _andar(Vector3(Fase32.EXPRESSA_FIM.x - topo3.x, 0, Fase32.EXPRESSA_FIM.z - topo3.z).normalized(), 2.0)
	var longe_depois := Vector2(j.global_position.x - Fase32.EXPRESSA_FIM.x, j.global_position.z - Fase32.EXPRESSA_FIM.z).length()
	ok = m._conferir("antes da tarefa a esteira expressa desce: andando para cima, o Faísca volta para a entrada", longe_depois > longe_antes + 3.0,
			"(de %.1f para %.1f m do alto)" % [longe_antes, longe_depois]) and ok

	# Os três blocos: dois socos cada, do lado leste, e a esteira leva até a recebedora.
	var tombos := 0
	for d in n.blocos_da_entrada:
		for k in 2:
			j.teleportar(Vector3(d.global_position.x + 2.4, 0.1, d.global_position.z))
			await m._esperar(0.3)
			_virar_para(d.global_position)
			var x_antes := d.global_position.x
			await m._toque(JOY_BUTTON_X)
			await m._esperar(0.8)
			if d.global_position.x < x_antes - 2.0:
				tombos += 1
	ok = m._conferir("cada soco tomba o bloco um lado para oeste, até a esteira", tombos == 6, "(%d de 6)" % tombos) and ok
	ok = m._conferir("em cima da esteira o bloco fica preso nela (não tomba mais)", n.blocos_da_entrada.all(func(d: DadoQueTomba) -> bool: return d.travado)) and ok
	await m._esperar(8.0)
	ok = m._conferir("a esteira leva cada bloco à recebedora, que acende uma luz", n.entregues == 3, "(%d luzes)" % n.entregues) and ok
	ok = m._conferir("com as três luzes a esteira expressa passa a subir", n.expressa_ligada() and n.expressa.all(func(e: Esteira) -> bool: return e.velocidade > 0.0)) and ok

	# Bolso: a escada de caixotes até a prateleira do coração.
	var degraus := [[Vector3(-15.4, 0.1, 125.6), Vector3(-17.5, 1.6, 125.6)], [Vector3(-17.5, 1.7, 125.6), Vector3(-20.1, 3.2, 125.6)],
		[Vector3(-20.1, 3.3, 125.6), Vector3(-25, 4.8, 125.4)]]
	var onde := Vector3.ZERO
	var subiu := true
	for d in degraus:
		onde = await _pular_para(d[0], d[1])
		subiu = subiu and absf(onde.y - d[1].y) < 0.45
	ok = m._conferir("a escada de caixotes sobe pulando até a prateleira do coração", subiu and absf(onde.y - 4.8) < 0.3, "(altura %.1f)" % onde.y) and ok
	# Bolso: a esteira leva para dentro do nicho atrás da torre.
	var pegas := n.pegas
	j.teleportar(Vector3(31.5, 0.1, 92))
	await _andar(Vector3(1, 0, 0), 0.6)
	await m._esperar(3.0)
	var entregue := j.global_position.x > 40.5
	await _andar(Vector3(1, 0, 0), 1.0)
	ok = m._conferir("a esteira atrás da torre leva até a porta do nicho, com as estrelinhas lá dentro", entregue and j.global_position.x > 43.0 and n.pegas >= pegas + 2,
			"(x %.1f, %d estrelinhas)" % [j.global_position.x, n.pegas - pegas]) and ok

	# A viagem: parado no pé da expressa, ela leva até a máquina A.
	var e0 := n.expressa[0]
	j.teleportar(e0.global_position + e0.global_basis.y * Esteira.ALTURA + Vector3.UP * 0.4)
	var chegou := false
	for i in 20:
		await m._esperar(1.0)
		if j.global_position.y > TOPO_A - 0.5 and j.is_on_floor():
			chegou = true
			break
	ok = m._conferir("parado nela, a esteira expressa leva o Faísca até a máquina A, a 8 m", chegou, "(%.1f, %.1f, %.1f)" % [j.global_position.x, j.global_position.y, j.global_position.z]) and ok
	return ok


const TOPO_A := 8.0


## Playground 2 e a ponte rolante.
func _maquinas() -> bool:
	var ok := true
	var p1 := n.postos[0]
	ok = m._conferir("antes do posto P1 o monta-carga das máquinas fica parado", n.montacargas[0].travada) and ok
	j.teleportar(p1.global_position + Vector3(1.0, 0.2, 0))
	await m._esperar(0.5)
	ok = m._conferir("o P1 acende na máquina A, e o monta-carga destrava", p1.acendido and not n.montacargas[0].travada) and ok
	var mc := n.montacargas[0]
	j.teleportar(mc.global_position + Vector3.UP * 0.3)
	await m._esperar(6.0)
	ok = m._conferir("do chão, o monta-carga leva de volta para cima da máquina", j.global_position.y > TOPO_A - 0.5, "(altura %.1f)" % j.global_position.y) and ok
	j.teleportar(Vector3(-66, TOPO_A + 0.2, 64))
	await m._esperar(0.4)
	ok = m._conferir("perto dos blocos lilases o Vovô mostra o bloco-pisca", m.hud.dica_atual == "pisca") and ok

	# Um bloco-pisca: em cima dele quando ele some, o Faísca cai no chão da fábrica (sem perder coração); e ele volta.
	var b := n.blocos_pisca[0]
	await _esperar_ligar(b)
	j.teleportar(b.global_position + Vector3.UP * 0.3)
	var vida := j.vida
	var caiu := false
	for i in 300:
		await m.get_tree().physics_frame
		if j.global_position.y < 1.0 and j.is_on_floor():
			caiu = true
			break
	ok = m._conferir("o bloco-pisca some, e quem está em cima cai no chão, sem perder coração", caiu and j.vida == vida and not b.aceso,
			"(altura %.1f, corações %d de %d)" % [j.global_position.y, j.vida, vida]) and ok
	await _esperar_ligar(b)
	ok = m._conferir("e o bloco-pisca volta", b.aceso) and ok

	# A travessia de A até B pelos dois blocos-pisca, no tempo deles.
	var b1 := n.blocos_pisca[1]
	await _esperar_ligar(b)
	var onde := await _pular_para(Vector3(-69.4, TOPO_A + 0.1, 64.4), b.global_position)
	var no_primeiro := absf(onde.y - TOPO_A) < 0.3
	await _esperar_ligar(b1)
	onde = await _pular_daqui(b1.global_position)
	var no_segundo := absf(onde.y - TOPO_A) < 0.3
	onde = await _pular_daqui(Vector3(-84.5, TOPO_A, 66))
	ok = m._conferir("pulando no tempo dos blocos-pisca, o Faísca atravessa de A até a máquina B", no_primeiro and no_segundo and absf(onde.y - TOPO_A) < 0.3
			and onde.x < -82.0, "(%s, %s, %.1f, %.1f, %.1f)" % [no_primeiro, no_segundo, onde.x, onde.y, onde.z]) and ok

	# As três alavancas e a ponte rolante.
	ok = m._conferir("antes das alavancas, a ponte rolante não sai", n.ponte_rolante.travada) and ok
	for a in n.alavancas:
		var chao := a.global_position + Vector3(0, 0.1, 2.0)
		j.teleportar(chao)
		await m._esperar(0.3)
		_virar_para(a.global_position)
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.6)
	ok = m._conferir("um soco puxa cada alavanca, e com as três a ponte rolante destrava",
			n.alavancas.all(func(a: Alavanca) -> bool: return a.puxada_ja) and not n.ponte_rolante.travada) and ok
	# Bolso: o cano gigante é oco e segura o Faísca lá dentro, com o V1.
	var achados := n.achados
	j.teleportar(Vector3(-126, 14.0, 38.5))
	await _andar(Vector3(-1, 0, 0), 0.8)
	ok = m._conferir("dentro do cano gigante dá para andar, e lá está o V1", n.achados == achados + 1 and absf(j.global_position.y - 13.0) < 0.4,
			"(altura %.1f, vaga-lumes %d)" % [j.global_position.y, n.achados]) and ok
	var pr := n.ponte_rolante
	j.teleportar(pr.global_position + Vector3(0, 0.3, 0))
	await m._esperar(1.0)
	ok = m._conferir("o palete da ponte rolante sai quando o Faísca sobe nele", pr.estado == "indo") and ok
	while pr.estado == "indo":
		await m.get_tree().physics_frame
	await m._esperar(0.3)
	ok = m._conferir("e o leva até a oficina, sem cair", j.global_position.distance_to(pr.ate) < 2.5 and absf(j.global_position.y - Fase32.TOPO_OFICINA) < 0.6,
			"(%.1f m)" % j.global_position.distance_to(pr.ate)) and ok
	return ok


## Playground 3 e a empilhadeira.
func _oficina() -> bool:
	var ok := true
	var t := Fase32.TOPO_OFICINA
	var p2 := n.postos[1]
	j.teleportar(p2.global_position + Vector3(1.0, 0.2, 0))
	await m._esperar(0.5)
	ok = m._conferir("o P2 acende na oficina", p2.acendido) and ok
	# Sem o martelinho, o pino não afunda (nem pulando em cima, nem no soco).
	var p0 := n.pinos_da_oficina[0]
	j.teleportar(p0.global_position + Vector3(0, Pino.ALTURA + 2.0, 0))
	await m._esperar(1.0)
	j.teleportar(p0.global_position + Vector3(2.4, 0.1, 0))
	await m._esperar(0.3)
	_virar_para(p0.global_position)
	await m._toque(JOY_BUTTON_X)
	await m._esperar(0.6)
	ok = m._conferir("sem o martelinho, pular em cima e socar não afundam o pino", not p0.batido_ja) and ok

	# A escada de caixotes até a caixa de ferramentas, e o martelinho lá em cima.
	var degraus := [[Vector3(-72.6, t + 0.1, -67.2), Vector3(-70.2, t + 1.6, -67.2)], [Vector3(-70.2, t + 1.7, -67.2), Vector3(-67.6, t + 3.2, -67.2)],
		[Vector3(-67.6, t + 3.3, -67.2), Vector3(-65.0, t + 4.8, -67.2)], [Vector3(-65.0, t + 4.9, -67.2), Vector3(-60.5, t + 5.0, -67.5)]]
	var onde := Vector3.ZERO
	for d in degraus:
		onde = await _pular_para(d[0], d[1])
	await _andar(Vector3(1, 0, 0), 0.4)
	ok = m._conferir("a escada de caixotes sobe até a caixa de ferramentas (5 m)", absf(onde.y - (t + 5.0)) < 0.3, "(altura %.1f)" % onde.y) and ok
	ok = m._conferir("em cima da caixa está o Martelinho de Apito, e o Vovô mostra como usa", n.martelinho_pego and j.martelinho
			and m.hud.dica_atual == "martelo") and ok

	# A pancada: em cima do primeiro pino, ao lado do segundo e do terceiro; cada uma sobe um pistão.
	await _pancada_em(p0.global_position + Vector3(0, Pino.ALTURA, 0))
	ok = m._conferir("no ar, o golpe vira pancada: o Faísca desce reto e o pino afunda", p0.batido_ja) and ok
	await m._esperar(1.0)
	ok = m._conferir("e o pistão do pino sobe", n.pistoes_da_oficina[0].no_alto()) and ok
	for i in [1, 2]:
		await _pancada_em(n.pinos_da_oficina[i].global_position + Vector3(1.6, 0, 0))
	await m._esperar(1.2)
	ok = m._conferir("a pancada bem do lado do pino também afunda", n.pinos_da_oficina.all(func(p: Pino) -> bool: return p.batido_ja)
			and n.pistoes_da_oficina.all(func(p: Pistao) -> bool: return p.no_alto())) and ok
	degraus = [[Vector3(-61.6, t + 0.1, -94), Vector3(-59, t + 1.6, -94)], [Vector3(-59, t + 1.7, -94), Vector3(-55.5, t + 3.2, -94)],
		[Vector3(-55.5, t + 3.3, -94), Vector3(-52, t + 4.8, -94)], [Vector3(-52, t + 4.9, -94), Vector3(-48.5, t + 6.0, -94)]]
	var subiu := true
	for d in degraus:
		onde = await _pular_para(d[0], d[1])
		subiu = subiu and absf(onde.y - d[1].y) < 0.45
	ok = m._conferir("os três pistões viram a escada até a estante da empilhadeira (6 m)", subiu and absf(onde.y - (t + 6.0)) < 0.3, "(altura %.1f)" % onde.y) and ok

	# A Bolota de capacete: o soco bate no capacete; a pancada derruba.
	var capacete := n.alvos[6] as BolotaMonstro
	j.teleportar(capacete.global_position + Vector3(0, 0.1, 2.0))
	await m._esperar(0.3)
	_virar_para(capacete.global_position)
	await m._toque(JOY_BUTTON_X)
	await m._esperar(0.6)
	ok = m._conferir("o soco bate no capacete e não derruba a Bolota de capacete", capacete.regra == "capacete" and not capacete.derrotado) and ok
	await _pancada_em(capacete.global_position + Vector3(0.8, 0, 0))
	ok = m._conferir("a pancada do martelinho derruba", capacete.derrotado) and ok

	# Bolso alto: o quarto pino liga o pistão alto, que sobe e desce até a prateleira do V2.
	await _pancada_em(n.pino_secreto.global_position)
	ok = m._conferir("o quarto pino, atrás da caixa, liga o pistão alto", n.pino_secreto.batido_ja and n.pistao_alto.ligado) and ok
	var achados := n.achados
	var no_alto := false
	for tentativa in 3:
		while n.pistao_alto.position.y > t + 0.3:
			await m.get_tree().physics_frame
		j.teleportar(n.pistao_alto.global_position + Vector3(0, Pistao.PLACA + 0.2, 0))
		for i in 600:
			await m.get_tree().physics_frame
			if j.global_position.y > t + 8.2:
				no_alto = true
				break
		if no_alto:
			break
	await _andar(Vector3(0, 0, -1), 0.7)
	ok = m._conferir("em cima dele se chega à prateleira alta, onde está o V2", no_alto and n.achados == achados + 1,
			"(altura %.1f, vaga-lumes %d)" % [j.global_position.y, n.achados]) and ok

	var emp := n.empilhadeira
	j.teleportar(emp.global_position + Vector3(0, 0.3, 0))
	await m._esperar(1.0)
	ok = m._conferir("a empilhadeira sai quando o Faísca sobe no palete", emp.estado == "indo") and ok
	while emp.estado == "indo":
		await m.get_tree().physics_frame
	await m._esperar(0.3)
	ok = m._conferir("e o leva pela passarela até o andar da pintura, sem cair", j.global_position.distance_to(emp.ate) < 2.5,
			"(%.1f m)" % j.global_position.distance_to(emp.ate)) and ok
	return ok


## Playground 4 e a ponte de blocos.
func _pintura() -> bool:
	var ok := true
	var t := Fase32.TOPO_PINTURA
	var p3 := n.postos[2]
	j.teleportar(p3.global_position + Vector3(1.0, 0.2, 0))
	await m._esperar(0.5)
	ok = m._conferir("o P3 acende na faixa de entrada da pintura", p3.acendido and not n.montacargas[2].travada) and ok
	j.teleportar(Vector3(100, t + 0.2, -44))
	await m._esperar(0.4)
	ok = m._conferir("perto da tinta o Vovô mostra que não pode encostar nela", m.hud.dica_atual == "tinta") and ok
	var vida := j.vida
	j.teleportar(Vector3(95, t + 1.5, -36))
	await m._esperar(2.0)
	ok = m._conferir("cair na tinta conta como cair: perde um coração e volta no posto", j.vida == vida - 1
			and j.global_position.distance_to(p3.ponto()) < 2.5, "(corações %d, %.1f m do posto)" % [j.vida, j.global_position.distance_to(p3.ponto())]) and ok

	j.teleportar(Vector3(102, t + 0.3, -41))
	await m._esperar(0.3)
	var antes := j.global_position
	await m._esperar(2.0)
	ok = m._conferir("a esteira da entrada leva até a primeira lata", j.global_position.z - antes.z > 3.5 and absf(j.global_position.y - t) < 0.4) and ok
	j.teleportar(Vector3(82, t + 0.3, -17.5))
	await m._esperar(0.3)
	antes = j.global_position
	await m._esperar(1.2)
	ok = m._conferir("a esteira larga empurra para o lado, para a tinta", j.global_position.x - antes.x > 2.0, "(%.1f m)" % (j.global_position.x - antes.x)) and ok
	j.teleportar(p3.ponto())
	await m._esperar(0.3)

	ok = m._conferir("antes dos pinos, a ponte de blocos espera no chão", not n.ponte_pronta()) and ok
	for p in n.pinos_da_pintura:
		await _pancada_em(p.global_position + Vector3(0, Pino.ALTURA, 0))
	await m._esperar(3.0)
	ok = m._conferir("a pancada no pino de cada lata sobe um vão da ponte de blocos", n.pinos_da_pintura.all(func(p: Pino) -> bool: return p.batido_ja)
			and n.ponte_pronta()) and ok

	# Bolso: a lata tombada é oca, com o coração e estrelinhas lá dentro.
	var pegas := n.pegas
	j.teleportar(Vector3(107, t + 0.4, -5.0))
	await m._esperar(0.3)
	await _andar(Vector3(0, 0, 1), 1.2)
	ok = m._conferir("dá para entrar na lata tombada e pegar as estrelinhas dela", j.global_position.z > -4.0 and absf(j.global_position.y - t) < 0.6
			and n.pegas >= pegas + 2, "(%.1f, %.1f, %d estrelinhas)" % [j.global_position.y, j.global_position.z, n.pegas - pegas]) and ok

	# A ponte, degrau por degrau, até o anel da máquina.
	var degraus := [[Vector3(58, t + 0.1, Fase32.PONTE_Z), Vector3(53.5, 21.5, Fase32.PONTE_Z)], [Vector3(46, 21.6, Fase32.PONTE_Z), Vector3(40.5, 23.0, Fase32.PONTE_Z)],
		[Vector3(33, 23.1, Fase32.PONTE_Z), Vector3(27.5, 24.5, Fase32.PONTE_Z)], [Vector3(20, 24.6, Fase32.PONTE_Z), Vector3(14.5, Fase32.ANEL, Fase32.PONTE_Z)]]
	var onde := Vector3.ZERO
	var subiu := true
	for d in degraus:
		onde = await _pular_para(d[0], d[1])
		subiu = subiu and absf(onde.y - d[1].y) < 0.45
	ok = m._conferir("pela ponte de blocos se sobe, degrau por degrau, até o anel da máquina", subiu and absf(onde.y - Fase32.ANEL) < 0.3,
			"(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	return ok


## Playground 5: a subida pela parede da máquina, o painel rachado e a chegada ao topo.
func _subida() -> bool:
	var ok := true
	var a := Fase32.ANEL
	var p4 := n.postos[3]
	j.teleportar(p4.global_position + Vector3(0, 0.2, 1.0))
	await m._esperar(0.5)
	ok = m._conferir("o P4 acende no anel", p4.acendido) and ok
	var vida := j.vida
	j.teleportar(Vector3(-11.7, 39.5, 1.5))
	await m._esperar(2.5)
	ok = m._conferir("quem cai da parede cai no anel, sem perder coração", absf(j.global_position.y - a) < 0.3 and j.vida == vida,
			"(altura %.1f)" % j.global_position.y) and ok

	# Segredo: três golpes no painel rachado, e o V3 lá dentro.
	var achados := n.achados
	j.teleportar(Vector3(-13.6, a + 0.1, 4))
	await m._esperar(0.3)
	_virar_para(Vector3(-10, a + 1, 4))
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.5)
	await m._esperar(0.8)
	await _andar(Vector3(1, 0, 0), 1.0)
	ok = m._conferir("três golpes abrem o painel rachado, e o V3 está na salinha", n.parede_secreta.derrotado and n.achados == achados + 1,
			"(vaga-lumes %d)" % n.achados) and ok

	# A parede: leste, o pino do canto sudeste e o pistão; a esteira que sobe; o pino do canto sudoeste.
	var onde := await _pular_para(Vector3(14.5, a + 0.1, 7), Vector3(11.7, 27.6, 7))
	onde = await _pular_daqui(Vector3(11.9, 29.2, 11.4))
	ok = m._conferir("do anel, a saliência e o canto sudeste ficam a um pulo de 1,6 m", absf(onde.y - 29.2) < 0.3, "(altura %.1f)" % onde.y) and ok
	await _pancada_em(n.pinos_da_subida[0].global_position + Vector3(0, Pino.ALTURA, 0))
	await m._esperar(1.0)
	onde = await _pular_para(Vector3(10.2, 29.3, 11.7), Vector3(6.5, 30.8, 11.7))
	ok = m._conferir("o pino do canto sobe o pistão, que vira degrau", n.pistoes_da_subida[0].no_alto() and absf(onde.y - 30.8) < 0.3, "(altura %.1f)" % onde.y) and ok
	onde = await _pular_daqui(Vector3(3.0, 32.6, 11.7))
	var subiu := false
	for i in 300:
		await m.get_tree().physics_frame
		if j.global_position.y > 33.8 and j.global_position.x < -2.5:
			subiu = true
			break
	ok = m._conferir("a esteira da parede sul leva o Faísca para cima", subiu, "(%.1f, %.1f)" % [j.global_position.x, j.global_position.y]) and ok
	onde = await _pular_daqui(Vector3(-6.6, 34.0, 11.7))
	onde = await _pular_daqui(Vector3(-11.9, 35.6, 11.4))
	ok = m._conferir("e de lá se chega ao canto sudoeste", absf(onde.y - 35.6) < 0.3, "(altura %.1f)" % onde.y) and ok
	await _pancada_em(n.pinos_da_subida[1].global_position + Vector3(0, Pino.ALTURA, 0))

	# Os blocos-pisca da parede oeste, no tempo deles, até o pistão do lado oeste.
	var bp := n.blocos_pisca.slice(14)
	j.teleportar(Vector3(-11.9, 35.7, 10.8))
	await m._esperar(0.3)
	await _esperar_ligar(bp[0])
	onde = await _pular_daqui(bp[0].global_position)
	var no_primeiro := absf(onde.y - 37.2) < 0.3
	await _esperar_ligar(bp[1])
	onde = await _pular_daqui(bp[1].global_position)
	var no_segundo := absf(onde.y - 38.8) < 0.3
	onde = await _pular_daqui(Vector3(-11.7, 40.4, -0.6))
	ok = m._conferir("pelos blocos-pisca se chega ao pistão do lado oeste, já de pé", no_primeiro and no_segundo and n.pistoes_da_subida[1].no_alto()
			and absf(onde.y - 40.4) < 0.3, "(%s, %s, altura %.1f)" % [no_primeiro, no_segundo, onde.y]) and ok
	onde = await _pular_daqui(Vector3(-11.7, 42.0, -4.5))
	onde = await _pular_daqui(Vector3(-11.9, 42.0, -11.4))
	ok = m._conferir("do pistão se sobe ao canto noroeste", absf(onde.y - 42.0) < 0.3, "(altura %.1f)" % onde.y) and ok
	await _pancada_em(n.pinos_da_subida[2].global_position + Vector3(0, Pino.ALTURA, 0))
	var grande := n.pistoes_da_subida[2]
	while grande.position.y > grande._base_y + 0.1:
		await m.get_tree().physics_frame
	onde = await _pular_para(Vector3(-11.0, 42.1, -12.0), Vector3(-5.2, 42.0, -12.2))
	var subiu_nele := false
	for i in 600:
		await m.get_tree().physics_frame
		if j.global_position.y > 45.0:
			subiu_nele = true
			break
	await _andar(Vector3(0, 0, 1), 1.0)
	ok = m._conferir("o último pino liga o pistão grande, que sobe acima do corrimão; dele se desce no topo da máquina",
			grande.ligado and subiu_nele and absf(j.global_position.y - Fase32.TOPO) < 0.3 and j.global_position.z > -9.5,
			"(%.1f, %.1f, %.1f)" % [j.global_position.x, j.global_position.y, j.global_position.z]) and ok
	return ok


func _playground_mais_perto(p: Vector3) -> int:
	var melhor := 0
	for i in n.playgrounds.size():
		if p.distance_to(n.playgrounds[i].centro) < p.distance_to(n.playgrounds[melhor].centro):
			melhor = i
	return melhor


## Vira o Faísca (o corpo, que é a frente do golpe) para `alvo`.
func _virar_para(alvo: Vector3) -> void:
	var d := alvo - j.global_position
	j.visual.rotation.y = atan2(d.x, d.z)


## Põe o Faísca 3 m acima de `chao` e dá o golpe no ar: a pancada do martelinho desce reto até ali.
func _pancada_em(chao: Vector3) -> void:
	j.teleportar(chao + Vector3.UP * 3.0)
	await m._esperar(0.1)
	await m._toque(JOY_BUTTON_X)
	await m._esperar(1.0)


## Espera o bloco-pisca acabar de aparecer (o começo da vez dele).
func _esperar_ligar(b: BlocoPisca) -> void:
	for i in 600:
		await m.get_tree().physics_frame
		if fposmod(n._tempo + b.grupo * BlocoPisca.CICLO * 0.5, BlocoPisca.CICLO) < 0.1:
			return


## Do chão em `de`, pula (o pulo inteiro, sem flutuar) e se guia no ar até em cima de `alvo`. Devolve onde pousou.
func _pular_para(de: Vector3, alvo: Vector3) -> Vector3:
	j.teleportar(de)
	await m._esperar(0.3)
	return await _pular_daqui(alvo)


## Pula de onde está e se guia no ar até em cima de `alvo` (segura o pulo até começar a cair). Devolve onde pousou.
func _pular_daqui(alvo: Vector3) -> Vector3:
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


## Anda na direção `dir` (no chão) por `segundos`.
func _andar(dir: Vector3, segundos: float) -> void:
	j.yaw = atan2(-dir.x, -dir.z)
	j.forcar_direcao = Vector2(0, -1)
	await m._esperar(segundos)
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.2)


## Fotos da 3-2 (precisa de janela): de cima, cada playground de cima e de dentro, as viagens e a arena.
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "fase_3_2/"))
	for b in n.alvos:
		(b as Bolota).dormindo = true
		b.process_mode = Node.PROCESS_MODE_DISABLED
	m._comecar_fase()
	await m._esperar(4.0)
	await _foto_de_cima(Vector3(120, 150, 210), Vector3(-10, 10, 0), "fase_3_2/00_visao_geral")
	await _foto_de_cima(Vector3(-110, 110, -110), Vector3(10, 14, 20), "fase_3_2/00b_de_cima_noroeste")
	await _foto_em(n.inicio, 0.3, -0.12, "fase_3_2/01_esteiras_da_entrada")
	await _foto_de_cima(Vector3(40, 36, 150), Vector3(0, 2, 100), "fase_3_2/01b_entrada_de_cima")
	await _foto_em(Vector3(-24, 0.1, 108), 0.85, 0.05, "fase_3_2/01c_esteira_expressa")
	await _foto_de_cima(Vector3(-40, 46, 96), Vector3(-92, 8, 40), "fase_3_2/02_blocos_pisca")
	await _foto_em(Vector3(-62, 8.1, 63), 1.35, -0.05, "fase_3_2/02b_maquinas_de_dentro")
	await _foto_de_cima(Vector3(-20, 60, -30), Vector3(-70, 14, -82), "fase_3_2/03_oficina")
	await _foto_em(Vector3(-82, 14.1, -61), 0.55, 0.0, "fase_3_2/03b_oficina_de_dentro")
	await _foto_em(Vector3(-70, 14.1, -86), -1.6, 0.05, "fase_3_2/03c_pistoes_e_estante")
	await _foto_de_cima(Vector3(20, 50, -40), Vector3(10, 20, -84), "fase_3_2/03d_passarela")
	await _foto_de_cima(Vector3(44, 60, 40), Vector3(88, 18, -18), "fase_3_2/04_andar_da_pintura")
	await _foto_em(Vector3(96, 20.1, -44), 2.6, -0.1, "fase_3_2/04b_pintura_de_dentro")
	await _foto_de_cima(Vector3(60, 40, 36), Vector3(30, 18, 4), "fase_3_2/04c_ponte_de_blocos")
	await _foto_de_cima(Vector3(40, 56, 48), Vector3(0, 34, 2), "fase_3_2/05_subida_da_maquina")
	await _foto_em(Vector3(14, 26.1, 6), -0.2, 0.35, "fase_3_2/05b_anel")
	await _foto_em(Vector3(4, 44.1, 8), 0.3, -0.25, "fase_3_2/06_arena")
	# A foto da porta no farol (assets/faisca/portas/fase_3_2.jpg, em 640x360): a entrada com a máquina atrás, sem o HUD.
	m.hud.visible = false
	await _foto_de_cima(Vector3(30, 12, 146), Vector3(-2, 20, 50), "fase_3_2/porta")
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
