class_name TesteFaseNave
extends RefCounted
## Testes da fase final, a Nave Aspiratrão (feita em 2026-11-12), chamados pelo FaiscaSolo:
##   --faisca-fase-nave          confere a fase de ponta a ponta: contagens, o padrão de playgrounds (o brilho do tanque
##                               à vista de cada entrada), o hangar (as luzes de pouso e a escotilha), o tubo, o depósito
##                               (as cápsulas, as bolhas, o ioiô entre as prateleiras, os potes e o monta-carga), as
##                               máquinas (os pinos e o "sem gravidade"), o carrinho, a estufa (os sinos, a coluna com a
##                               pipa e a ponte de luz), o corredor (os guardas, as chaves e a porta) e a luta com o Rei
##                               nas três fases, até o pedido do final
##   --faisca-fase-nave-captura  fotos de cada playground e da luta em tools/capturas/faisca/nave/ (precisa de janela)

var m: Node
var n: FaseNave
var j: Jogador
var final_pedido := false


func _init(main: Node) -> void:
	m = main
	n = main.nivel
	j = main.jogador
	main.testando = true
	n.rapido = true
	n.final_pedido.connect(func() -> void: final_pedido = true)


func rodar() -> void:
	var ok := true
	await m._esperar(0.3)
	ok = m._conferir("de 100 a 170 estrelinhas no caminho e nos bolsos (fora as das Bolotas)", n.estrelas.size() >= 100 and n.estrelas.size() <= 170,
			"(%d soltas, %d com as das Bolotas)" % [n.estrelas.size(), n.total_estrelas()]) and ok
	ok = m._conferir("5 postos, 6 Faisquinhas, 4 corações e o Rei Bolotão no trono", n.postos.size() == 5 and n.faisquinhas.size() == 6
			and n.coracoes.size() == 4 and n.chefe != null, "(%d postos, %d Bolotas, %d corações)" % [n.postos.size(), n.alvos.size(), n.coracoes.size()]) and ok
	var poderes := n.capsulas.map(func(c: CapsulaDePoder) -> String: return c.poder)
	ok = m._conferir("5 cápsulas, uma de cada poder", poderes.size() == 5 and ["chiclete", "ioio", "martelinho", "luva", "pipa"].all(func(p: String) -> bool: return p in poderes),
			"(%s)" % str(poderes)) and ok
	ok = m._conferir("peças: 3 luzes de pouso, 3 potes com trava, 3 motores com pino, 5 caixas, 3 sinos, 3 guardas e 4 viagens",
			n.lampadas_pouso.size() == 3 and n.potes.size() == 3 and n.motores.size() == 3 and n.pinos_dos_motores.size() == 3
			and n.caixas_no_ar.size() == 5 and n.sinos_da_estufa.size() == 3 and n.guardas.size() == 3 and n.caronas.size() == 4) and ok
	await m.get_tree().physics_frame
	var espaco := j.get_world_3d().direct_space_state
	ok = m._conferir("5 playgrounds e 5 saídas", n.playgrounds.size() == 5 and n.saidas.size() == 5, "(%d, %d)" % [n.playgrounds.size(), n.saidas.size()]) and ok
	var cegos := n.playgrounds.filter(func(p: Dictionary) -> bool:
		return not espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p.entrada + Vector3.UP * 2.0, n.brilho_do_marco, 1)).is_empty())
	ok = m._conferir("da entrada de cada playground dá para ver o brilho do Tanque de Estrelas", cegos.is_empty(),
			"(sem ver: %s)" % ", ".join(cegos.map(func(p: Dictionary) -> String: return p.nome))) and ok
	var donos := n.faisquinhas.slice(0, 3).map(func(v: Faisquinha) -> int: return _playground_mais_perto(v.global_position))
	ok = m._conferir("um vaga-lume no bolso do playground 2, do 3 e do 4", donos == [1, 2, 3], "(%s)" % str(donos)) and ok
	for b in n.alvos:
		if b is Bolota:
			b.process_mode = Node.PROCESS_MODE_DISABLED

	m._comecar_fase()
	await m._esperar(4.0)
	ok = m._conferir("desce flutuando e pisa no hangar, embaixo do bocal", j.is_on_floor() and j.controle_ligado and absf(j.global_position.y) < 0.3
			and j.global_position.distance_to(n.inicio) < 1.0) and ok
	ok = await _hangar() and ok
	ok = await _deposito() and ok
	ok = await _maquinas() and ok
	ok = await _estufa() and ok
	ok = await _corredor() and ok
	ok = await _luta() and ok
	print("RESULTADO: " + ("tudo certo" if ok else "com falhas"))
	m.get_tree().quit()


## Playground 1: as luzes de pouso (o laser acende) abrem a escotilha, e a cápsula do tubo leva ao depósito.
func _hangar() -> bool:
	var ok := true
	var antes := n.escotilha_aberta(n.escotilhas[0])
	for l in n.lampadas_pouso:
		await _flutuar_em_cima(l.global_position + Vector3.UP * 0.1, 1.0)
	ok = m._conferir("o laser acende as três luzes de pouso, e a escotilha abre", not antes and n.lampadas_pouso.all(func(l: Lampada) -> bool: return l.acesa)
			and n.escotilha_aberta(n.escotilhas[0])) and ok
	# Pela escotilha até a cápsula do tubo.
	j.teleportar(Vector3(-26, 0.1, 82))
	await m._esperar(0.3)
	var chegou := await _correr_ate(n.tubo.de, 6.0)
	await _ate(func() -> bool: return n.tubo.estado == "em_ate", 25.0)
	await m._esperar(0.4)
	ok = m._conferir("pela escotilha, a cápsula do tubo leva até o Depósito de Estrelas", chegou and n.tubo.estado == "em_ate"
			and j.global_position.distance_to(n.tubo.ate) < 2.5, "(em %s)" % str(j.global_position.snapped(Vector3.ONE * 0.1))) and ok
	return ok


## Playground 2: as cápsulas, a bolha que quica até a prateleira, o ioiô entre as prateleiras, os potes e o monta-carga.
func _deposito() -> bool:
	var ok := true
	var chiclete: CapsulaDePoder = n.capsulas.filter(func(c: CapsulaDePoder) -> bool: return c.poder == "chiclete")[0]
	await _correr_ate(chiclete.global_position, 6.0)
	await m._esperar(0.3)
	ok = m._conferir("encostando na cápsula, o Faísca ganha o Balão de Chiclete", j.balao_de_chiclete and chiclete.pega_ja) and ok
	# A bolha de chiclete quica até a prateleira de baixo.
	var bolha: NuvemQueQuica = n.nuvens_que_quicam[0]
	var pousou := await _quicar_ate(bolha.global_position, n.em_volta(FaseNave.DEPOSITO, 120.0, 16.5, 16.0))
	ok = m._conferir("a bolha de chiclete joga até a prateleira de baixo", absf(pousou.y - 16.0) < 0.5, "(pousou em y %.1f)" % pousou.y) and ok
	# O ioiô: da ponta da prateleira de baixo, duas argolas levam à de cima.
	j.ioio = true
	j.teleportar(n.em_volta(FaseNave.DEPOSITO, 208.0, 18.0, 16.1))
	j.visual.rotation.y = 0.0
	await m._esperar(0.4)
	var alto := await _ioio_em_fila(2, n.em_volta(FaseNave.DEPOSITO, 247.0, 18.0, 24.0))
	ok = m._conferir("o ioiô nas duas argolas do vão leva da prateleira de baixo à de cima", absf(alto.y - 24.0) < 0.6 and j.is_on_floor(),
			"(parou em %s)" % str(alto.snapped(Vector3.ONE * 0.1))) and ok
	# Os potes: o soco no ferrolho de cada um.
	var travado := n.monta_carga.travada
	for p in n.potes:
		await _socar(p.ferrolho, p.ferrolho.global_position + Vector3.UP * 0.6, true, 1.3)
	ok = m._conferir("o soco no ferrolho de cada pote solta as estrelas, e com os três o monta-carga destrava", travado
			and n.potes.all(func(p: PoteDeEstrelas) -> bool: return p.aberto) and not n.monta_carga.travada,
			"(abertos: %d)" % n.potes.filter(func(p: PoteDeEstrelas) -> bool: return p.aberto).size()) and ok
	j.teleportar(n.monta_carga.de + Vector3.UP * 0.3)
	await _ate(func() -> bool: return n.monta_carga.estado == "em_ate", 25.0)
	await m._esperar(0.4)
	ok = m._conferir("o monta-carga leva da prateleira de cima à Sala de Máquinas", n.monta_carga.estado == "em_ate"
			and j.global_position.distance_to(n.monta_carga.ate) < 2.5) and ok
	return ok


## Playground 3: o martelinho nos três pinos e o "sem gravidade".
func _maquinas() -> bool:
	var ok := true
	var cap: CapsulaDePoder = n.capsulas.filter(func(c: CapsulaDePoder) -> bool: return c.poder == "martelinho")[0]
	j.teleportar(cap.global_position + Vector3.UP * 0.2)
	await m._esperar(0.4)
	ok = m._conferir("a cápsula dá o Martelinho de Apito", j.martelinho) and ok
	# O pulo de antes, para comparar.
	var pulo_antes := await _altura_do_pulo(Vector3(-52, FaseNave.MAQUINAS.y + 0.1, -68))
	for i in n.motores.size():
		var motor := n.motores[i]
		j.teleportar(motor.topo() + Vector3(1.9, 0.1, 1.9))
		await m._esperar(0.3)
		j.forcar_pulo = true
		await m._esperar(0.12)
		var falta := n.pinos_dos_motores[i].global_position - j.global_position
		j.velocity.x = falta.x * 3.0
		j.velocity.z = falta.z * 3.0
		await m._esperar(0.2)
		j.forcar_golpe = true
		await m._esperar(0.5)
		j.forcar_pulo = false
		await m._esperar(0.4)
	ok = m._conferir("a pancada do martelinho afunda o pino de cada motor, e os motores param", n.pinos_dos_motores.all(func(p: Pino) -> bool: return p.batido_ja)
			and n.motores.all(func(mo: MotorDaNave) -> bool: return mo.parado), "(%d de 3)" % n.pinos_dos_motores.filter(func(p: Pino) -> bool: return p.batido_ja).size()) and ok
	await m._esperar(3.6)
	var no_ar := 0
	for i in n.caixas_no_ar.size():
		if n.caixas_no_ar[i].global_position.distance_to(n._caixas_ar[i]) < 0.6:
			no_ar += 1
	ok = m._conferir("com os três, vem o \"sem gravidade\": as caixas sobem e viram uma escada no ar", n.sem_gravidade and no_ar == 5, "(%d no lugar)" % no_ar) and ok
	var pulo_leve := await _altura_do_pulo(Vector3(-52, FaseNave.MAQUINAS.y + 0.1, -68))
	ok = m._conferir("sem gravidade, o pulo vai bem mais alto", pulo_leve > 5.5 and pulo_leve > pulo_antes * 2.5,
			"(%.1f m antes, %.1f m agora)" % [pulo_antes, pulo_leve]) and ok
	# De caixa em caixa: do chão até a estação.
	var degraus := 0
	j.teleportar(Vector3(-50, FaseNave.MAQUINAS.y + 0.1, -62))
	await m._esperar(0.3)
	for i in n.caixas_no_ar.size():
		var topo := n.caixas_no_ar[i].global_position + Vector3.UP * 1.5
		var pousou := await _pular_para(topo)
		if absf(pousou.y - topo.y) < 0.5:
			degraus += 1
		else:
			j.teleportar(topo + Vector3.UP * 0.1)
			await m._esperar(0.3)
	var estacao := await _pular_para(Vector3(-48, 56, -80))
	ok = m._conferir("pulando de caixa em caixa sem gravidade, o Faísca chega na estação lá no alto", degraus >= 4 and absf(estacao.y - 56.0) < 0.5,
			"(%d de 5 caixas no pulo, estação em y %.1f)" % [degraus, estacao.y]) and ok
	await m._esperar(0.3)
	ok = m._conferir("na estação a gravidade volta", j.gravidade > 20.0 and n.gravidade_ligada) and ok
	await _correr_ate(n.carrinho_do_teto.de, 4.0)
	await _ate(func() -> bool: return n.carrinho_do_teto.estado == "em_ate", 30.0)
	await m._esperar(0.4)
	ok = m._conferir("o carrinho do teto leva até a Estufa Gelada", n.carrinho_do_teto.estado == "em_ate"
			and j.global_position.distance_to(n.carrinho_do_teto.ate) < 2.5) and ok
	return ok


## Playground 4: a luva nos sinos, a ponte de luz e a coluna com a pipa.
func _estufa() -> bool:
	var ok := true
	for poder in ["luva", "pipa"]:
		var cap: CapsulaDePoder = n.capsulas.filter(func(c: CapsulaDePoder) -> bool: return c.poder == poder)[0]
		j.teleportar(cap.global_position + Vector3.UP * 0.2)
		await m._esperar(0.4)
	ok = m._conferir("as cápsulas dão a Luva de Neve e a Pipa (e os poderes de antes continuam)", j.luva_de_neve and j.pipa and j.martelinho and j.balao_de_chiclete) and ok
	# As Bolotas da estufa ficam longe (perto delas, o soco vira para a Bolota e a bola de neve vai nela).
	for b in n.alvos:
		if b is Bolota and Vector3(b.global_position.x, 0, b.global_position.z).distance_to(Vector3(FaseNave.ESTUFA.x, 0, FaseNave.ESTUFA.z)) < 40.0:
			b.global_position += Vector3.DOWN * 300.0
	for s in n.sinos_da_estufa:
		var pe := Vector3(s.global_position.x, FaseNave.ESTUFA.y, s.global_position.z)
		var para := (Vector3(44, 0, -62) - Vector3(pe.x, 0, pe.z)).normalized()
		j.teleportar(pe + para * 9.0 + Vector3.UP * 0.1)
		await m._esperar(0.3)
		var d := s.global_position - j.global_position
		j.visual.rotation.y = atan2(d.x, d.z)
		j.forcar_golpe = true
		await m._esperar(1.6)
	ok = m._conferir("a bola de neve da luva toca os três sinos, a porta abre e a ponte de luz aparece",
			n.sinos_da_estufa.all(func(s: Sino) -> bool: return s.tocado) and n.escotilha_aberta(n.escotilhas[1]) and n.ponte_de_luz.visible) and ok
	var c: ColunaDeVento = n.colunas[0]
	var alto := await _pairar_na_coluna(c, 5.0)
	j.forcar_pulo = false
	ok = m._conferir("com a pipa, a coluna de vento leva ao alto do tubo maior (o V3)", alto > c.topo_y - 1.5, "(subiu até %.1f)" % alto) and ok
	# Pela ponte de luz até o corredor.
	await m._esperar(1.0)
	j.teleportar(Vector3(74, FaseNave.ESTUFA.y + 0.1, -52))
	await m._esperar(0.4)
	var fim := n.no_corredor(0) - n.frente_do_corredor(0) * 4.0
	# Pelo meio da ponte, até a ponta dela, e então para dentro do corredor.
	var ponta := n.no_corredor(0) - n.frente_do_corredor(0) * 7.6
	await _correr_ate(Vector3(80, 0, -51.6), 4.0)
	await _correr_ate(ponta + (ponta - Vector3(78.6, 0, -52)).normalized() * 0.8, 8.0)
	var chegou := await _correr_ate(fim, 10.0)
	ok = m._conferir("a ponte de luz leva até o Corredor do Trono", chegou and absf(j.global_position.y - 40.0) < 0.5,
			"(em %s)" % str(j.global_position.snapped(Vector3.ONE * 0.1))) and ok
	return ok


## Playground 5: os guardas, as chaves-coroa, a porta e o elevador.
func _corredor() -> bool:
	var ok := true
	var travado := n.elevador.travada
	for g in n.guardas:
		g.process_mode = Node.PROCESS_MODE_INHERIT
		g.receber_golpe(3, g.global_position + Vector3.UP * 2.0, 7.0, "pancada")
	await m._esperar(3.5)
	ok = m._conferir("cada guarda vencido solta a chave-coroa, que voa até a porta; com as três, a porta abre e o elevador destrava",
			travado and n.chaves == 3 and not n.elevador.travada, "(%d chaves)" % n.chaves) and ok
	j.teleportar(n.elevador.de + Vector3.UP * 0.3)
	await _ate(func() -> bool: return n.elevador.estado == "em_ate", 40.0)
	await m._esperar(0.3)
	ok = m._conferir("o elevador sobe até a Sala do Trono", n.elevador.estado == "em_ate" and absf(j.global_position.y - FaseNave.ARENA_Y) < 0.6,
			"(em %s)" % str(j.global_position.snapped(Vector3.ONE * 0.1))) and ok
	return ok


## A luta com o Rei Bolotão: o trono, o aspirador e o apagão, até o pedido do final.
func _luta() -> bool:
	var ok := true
	var rei := n.chefe
	await _ate(func() -> bool: return rei.fase == 1, 4.0)
	ok = m._conferir("pisando na Sala do Trono, a luta começa (fase 1, o Rei no trono)", rei.fase == 1 and rei.estado == "no_trono"
			and n.argolas_do_trono.size() == 4) and ok
	await m._esperar(2.6)
	ok = m._conferir("do trono, ele joga potes de estrelas onde o Faísca está", rei.potes_jogados >= 1) and ok
	# Pelas argolas até o trono.
	var argola: ArgolaDeIoio = n.argolas_do_trono[0]
	var de := Vector3(argola.global_position.x, FaseNave.ARENA_Y, argola.global_position.z) * 1.35
	de.y = FaseNave.ARENA_Y + 0.1
	j.teleportar(de)
	j.vida = Jogador.VIDA_MAX
	await m._esperar(0.4)
	var para_fora := Vector3(argola.global_position.x, 0, argola.global_position.z).normalized()
	var pousou := await _ioio_em_fila(2, n.trono_topo() + para_fora * 4.4)
	var no_trono := pousou.y > FaseNave.ARENA_Y + FaseNave.TOPO_TRONO - 0.6 and Vector2(pousou.x, pousou.z).length() < FaseNave.RAIO_TRONO
	ok = m._conferir("o ioiô nas duas argolas leva até em cima do trono", no_trono, "(pousou em %s)" % str(pousou.snapped(Vector3.ONE * 0.1))) and ok
	# Em cima do trono, anda até o botão (ele gira com o trono) e soca.
	var botao := n.botao_do_trono.global_position
	var para_o_botao := Vector3(botao.x - n.trono.global_position.x, 0, botao.z - n.trono.global_position.z).normalized()
	j.teleportar(n.trono_topo() + para_o_botao * 4.0 + Vector3.UP * 0.1)
	await m._esperar(0.2)
	await _socar(n.botao_do_trono, n.botao_do_trono.global_position + Vector3.UP * 0.3, false)
	await m._esperar(1.4)
	ok = m._conferir("o soco no botão vermelho derruba o trono, e o Rei fica tonto no chão", rei.estado == "tonto"
			and absf(rei.global_position.y - FaseNave.ARENA_Y) < 0.8) and ok
	await _tres_socos(rei)
	ok = m._conferir("três socos com ele tonto e vem a fase 2 (o aspirador), com as colunas ligadas e os filtros", rei.fase == 2
			and n.colunas_do_trono.all(func(c: ColunaDeVento) -> bool: return c.ligada) and n.filtros.size() == 3) and ok
	# O puxão: no chão, à vista dele, o Faísca vai sendo puxado; atrás de um pilar, não.
	var longe := n.no_trono(160.0 + 15.0, 17.0, 0.1)
	j.teleportar(longe)
	await _ate(func() -> bool: return rei.puxando, 8.0)
	var antes := Vector2(j.global_position.x, j.global_position.z).length()
	await m._esperar(1.2)
	var depois := Vector2(j.global_position.x, j.global_position.z).length()
	ok = m._conferir("com o cetro ligado, o Faísca no chão é puxado para o Rei", rei.puxando and antes - depois > 1.5, "(%.1f m)" % (antes - depois)) and ok
	var pilar: StaticBody3D = n.pilares[0]
	var atras := Vector3(pilar.global_position.x, 0, pilar.global_position.z).normalized() * 16.0 + Vector3.UP * (FaseNave.ARENA_Y + 0.1)
	j.teleportar(atras)
	await _ate(func() -> bool: return rei.puxando, 8.0)
	var a0 := j.global_position
	await m._esperar(1.0)
	ok = m._conferir("atrás de um pilar o puxão não pega", a0.distance_to(j.global_position) < 0.4, "(%.2f m)" % a0.distance_to(j.global_position)) and ok
	# Os filtros: com a pipa, a coluna leva ao alto, e o soco no ferrolho entope.
	j.vida = Jogador.VIDA_MAX
	for i in n.colunas_do_trono.size():
		var c := n.colunas_do_trono[i]
		await _pairar_na_coluna(c, 3.2)
		if i >= n.filtros.size():
			break
		var f := n.filtros[i]
		var d := f.global_position - j.global_position
		j.visual.rotation.y = atan2(d.x, d.z)
		j.forcar_golpe = true
		await m._esperar(0.5)
		j.forcar_pulo = false
		await _ate(func() -> bool: return j.is_on_floor(), 4.0)
	ok = m._conferir("com a pipa, a coluna leva até cada filtro, e o soco no ferrolho entope o aspirador (ele fica tonto)",
			n.filtros.all(func(f: Ferrolho) -> bool: return f.aberto_ja) and rei.estado == "tonto",
			"(%d filtros, estado %s)" % [n.filtros.filter(func(f: Ferrolho) -> bool: return f.aberto_ja).size(), rei.estado]) and ok
	await _tres_socos(rei)
	ok = m._conferir("três socos e vem a fase 3: o apagão, com o Rei rolando no escuro", rei.fase == 3 and rei.estado == "rolando"
			and n._ambiente.ambient_light_energy < 0.4) and ok
	# As lâmpadas: o laser acende cada uma, e ele vai se acalmando.
	await m._esperar(1.0)
	var rapidez := []
	for l in n.lampadas_do_trono:
		j.vida = Jogador.VIDA_MAX
		await _flutuar_em_cima(l.global_position + Vector3.UP * 2.2, 0.8)
		rapidez.append(rei.lampadas)
	ok = m._conferir("o laser acende as quatro lâmpadas (cada uma acalma o Rei), e com as quatro ele senta e chora", n.lampadas_do_trono.all(func(l: Lampada) -> bool: return l.acesa)
			and rei.derrotado, "(acalmou: %s, estado %s)" % [str(rapidez), rei.estado]) and ok
	await _ate(func() -> bool: return final_pedido, 20.0)
	ok = m._conferir("a cena da estrelinha de bolso: o Rei fica feliz, as estrelas sobem pela cúpula e a fase pede o final", final_pedido
			and rei.estado == "feliz") and ok
	ok = m._conferir("a gravidade de sempre", j.gravidade > 20.0) and ok
	return ok


func _tres_socos(rei: ChefeRei) -> void:
	var antes := rei.fase
	for k in 4:
		if rei.fase != antes or rei.estado != "tonto":
			break
		j.vida = Jogador.VIDA_MAX
		await _socar(rei, rei.global_position + Vector3.UP * 0.5, true, ChefeRei.RAIO + 1.2)
		await m._esperar(0.3)
	await m._esperar(0.6)


# --- ajudantes ---

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


func _chao_em(p: Vector3, de_cima := 30.0) -> Vector3:
	var batida := j.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * de_cima, p + Vector3.DOWN * 40.0, 1))
	return batida.position if not batida.is_empty() else p


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


func _empurrar_para(d: Vector3) -> void:
	var base := j.camera_pivo.global_transform.basis
	var frente := Vector3(-base.z.x, 0.0, -base.z.z).normalized()
	var direita := Vector3(base.x.x, 0.0, base.x.z).normalized()
	j.forcar_direcao = Vector2(d.dot(direita), -d.dot(frente))


## Flutua parado em cima de `onde` (o laser dos pés aponta para baixo) por `segundos`.
func _flutuar_em_cima(onde: Vector3, segundos: float) -> void:
	j.forcar_pulo = false
	j.forcar_direcao = Vector2.ZERO
	j.teleportar(onde + Vector3.UP * 2.6)
	j.velocity = Vector3.ZERO
	await m._esperar(0.05)
	j.forcar_pulo = true
	await m._esperar(segundos)
	j.forcar_pulo = false
	await _ate(func() -> bool: return j.is_on_floor(), 3.0)
	await m._esperar(0.2)


## A altura do pulo de `de` (o pulo inteiro, segurando).
func _altura_do_pulo(de: Vector3) -> float:
	j.forcar_pulo = false
	j.teleportar(de)
	await m._esperar(0.3)
	var y0 := j.global_position.y
	var alto := y0
	j.forcar_pulo = true
	var t := 0.0
	while t < 3.5:
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
		alto = maxf(alto, j.global_position.y)
		if t > 0.3 and j.is_on_floor():
			break
		# Só o pulo: soltando no alto, sem o voo do laser.
		if j.velocity.y < 0.0:
			j.forcar_pulo = false
	j.forcar_pulo = false
	await _ate(func() -> bool: return j.is_on_floor(), 6.0)
	await m._esperar(0.2)
	return alto - y0


## Pula de onde está para `alvo` (o topo de uma caixa), guiando no ar e flutuando na descida; devolve onde pousou.
func _pular_para(alvo: Vector3) -> Vector3:
	j.forcar_pulo = false
	await m._esperar(0.1)
	j.forcar_pulo = true
	var subiu := false
	for i in 600:
		await m.get_tree().physics_frame
		var falta := Vector3(alvo.x - j.global_position.x, 0, alvo.z - j.global_position.z)
		if j.global_position.y > alvo.y + 0.6:
			subiu = true
		if (subiu or j.global_position.y > alvo.y - 1.0) and falta.length() > 0.6:
			_empurrar_para(falta.normalized())
		else:
			j.forcar_direcao = Vector2.ZERO
		if i > 15 and j.is_on_floor():
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	await m._esperar(0.3)
	return j.global_position


## Pisa na mola (ou bolha) em `pe` e se guia no ar até `alvo`, flutuando na descida; devolve onde pousou.
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


## Pula e, no ar, dá o golpe perto de cada argola, `quantas` vezes (o ioiô puxa e joga para cima), e cai guiando até
## `alvo`; devolve onde pousou.
func _ioio_em_fila(quantas: int, alvo: Vector3) -> Vector3:
	j.forcar_pulo = false
	await m._esperar(0.1)
	j.forcar_pulo = true
	await m._esperar(0.25)
	for k in quantas:
		var argola := j.argola_de_ioio_perto()
		if argola == null:
			print("  sem argola perto (em %s)" % str(j.global_position.snapped(Vector3.ONE * 0.1)))
			break
		j.forcar_golpe = true
		await m.get_tree().physics_frame
		await _ate(func() -> bool: return not j.no_ioio, 2.5)
		await m._esperar(0.22)
	# Solta o pulo (segurando, com o chiclete, o balão encheria) e se guia até o `alvo`, como quem joga.
	j.forcar_pulo = false
	var t := 0.0
	while t < 4.0 and not j.is_on_floor():
		var falta := Vector3(alvo.x - j.global_position.x, 0, alvo.z - j.global_position.z)
		if falta.length() > 0.5:
			_empurrar_para(falta.normalized())
		else:
			j.forcar_direcao = Vector2.ZERO
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.3)
	return j.global_position


## No pé da coluna: pula e segura (flutua) por `segundos`; devolve a altura mais alta.
func _pairar_na_coluna(c: ColunaDeVento, segundos: float) -> float:
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


## Fotos da nave (precisa de janela): de cima, cada playground, o sem gravidade e a luta.
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "nave/"))
	for b in n.alvos:
		if b is Bolota:
			(b as Bolota).dormindo = true
			b.process_mode = Node.PROCESS_MODE_DISABLED
	m._comecar_fase()
	await m._esperar(4.0)
	# As câmeras de longe ficam dentro do casco (raio 128) e abaixo do teto (72): de fora, só se vê o casco.
	await _foto_de_cima(Vector3(-78, 66, 82), Vector3(0, 16, 0), "nave/00_visao_geral")
	await _foto_em(n.inicio, 0.0, -0.1, "nave/01_hangar")
	await _foto_de_cima(Vector3(32, 30, 114), Vector3(-2, 2, 84), "nave/01b_hangar_de_cima")
	await _foto_de_cima(Vector3(-40, 40, 60), Vector3(-82, 14, 18), "nave/02_deposito")
	await _foto_em(Vector3(-72, 8.1, 34), 0.9, 0.15, "nave/02b_deposito_de_dentro")
	await _foto_de_cima(Vector3(-20, 60, -20), Vector3(-60, 30, -68), "nave/03_maquinas")
	n.ligar_sem_gravidade()
	await m._esperar(4.0)
	await _foto_de_cima(Vector3(-24, 52, -40), Vector3(-58, 40, -66), "nave/03b_sem_gravidade")
	await _foto_de_cima(Vector3(90, 60, -20), Vector3(54, 40, -66), "nave/04_estufa")
	await _foto_em(Vector3(42, 34.1, -66), 2.6, 0.1, "nave/04b_estufa_de_dentro")
	await _foto_de_cima(Vector3(60, 70, 40), Vector3(100, 42, 0), "nave/05_corredor")
	var c1 := n.no_corredor(0.2)
	var para := n.no_corredor(2.0) - c1
	await _foto_em(c1 + Vector3.UP * 0.1, atan2(-para.x, -para.z), 0.05, "nave/05b_corredor_de_dentro")
	await _foto_de_cima(Vector3(36, 72, 40), Vector3(0, 58, 0), "nave/06_sala_do_trono")
	# A luta: o Rei no trono, o aspirador e o apagão.
	j.teleportar(n.entrada_do_trono + Vector3.UP * 0.1)
	n.comecar_luta()
	await m._esperar(1.0)
	await _foto_de_cima(n.no_trono(200.0, 19.0, 9.0), n.trono_topo() + Vector3.UP * 3.0, "nave/07_rei_no_trono")
	n.chefe.cair_do_trono(Vector3(0, FaseNave.ARENA_Y + 0.1, 0))
	n._trono_caido = true
	n.trono.hide()
	await m._esperar(1.2)
	n.chefe._proxima_fase()
	await m._esperar(2.0)
	await _foto_em(n.no_trono(200.0, 17.0, 0.1), deg_to_rad(-110.0), 0.15, "nave/08_aspirador")
	n.chefe._proxima_fase()
	await m._esperar(1.5)
	await _foto_em(n.no_trono(200.0, 17.0, 0.1), deg_to_rad(-110.0), 0.15, "nave/09_apagao")
	# A foto da porta no farol (assets/faisca/portas/nave.jpg, em 640x360): o tanque e o hangar, sem o HUD.
	m.hud.visible = false
	await _foto_de_cima(Vector3(-78, 66, 82), Vector3(0, 16, 0), "nave/porta")
	m.hud.visible = true
	m.get_tree().quit()


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
