class_name TesteFase31
extends RefCounted
## Testes da 3-1 Pico Gelado (feita em 2026-10-30), chamados pelo FaiscaSolo:
##   --faisca-fase-3-1           confere a fase de ponta a ponta: contagens, o padrão de playgrounds (o brilho do
##                               baú à vista de cada entrada), o lago (o gelo que escorrega, os botões, a ponte de neve,
##                               a pilha de bolas de neve, o iglu oco), o trenó, as ilhas (a ponte de gelo, a bola de
##                               neve que empurra, os pinguins que o laser solta, o canhão desentupido, o V1), a vila (a
##                               Luva de Neve, os sinos que só a bola de neve alcança, o fantasma, o quarto sino que só
##                               se acerta por trás, a escada de gelo e o V2), a cadeirinha, a encosta (a cachoeira que
##                               empurra de volta, os sinos que congelam a água em rampa, o pulo flutuando, a caverna, a
##                               ponte até o anel), a subida (neve fofa, saliências, o pingente que cai, a porta de gelo
##                               e o sino dela, a gruta com o V3, a neve fofa de volta) e o baú no cume
##   --faisca-fase-3-1-captura   fotos de cada playground em tools/capturas/faisca/fase_3_1/ (precisa de janela)

var m: Node
var n: Fase31
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
	ok = m._conferir("peças: 3 botões, 3 pinguins presos, o canhão, 2 caronas, 8 sinos, 3 cachoeiras, 3 bolas de neve, 3 montes de neve fofa e 3 pingentes",
			n.botoes.size() == 3 and n.cubos_de_gelo.size() == 3 and n.canhoes.size() == 1 and n.caronas.size() == 2 and n.sinos.size() == 8
			and n.cachoeiras.size() == 3 and n.bolas_de_neve.size() == 3 and n.nuvens_que_quicam.size() == 3 and n.nuvens_que_somem.size() == 3,
			"(%d sinos, %d bolas)" % [n.sinos.size(), n.bolas_de_neve.size()]) and ok

	# O padrão de playgrounds: cinco em volta do pico, um arco de saída nos quatro primeiros, o brilho do baú à vista de
	# todas as entradas e um vaga-lume no bolso do 2, do 3 e do 5.
	await m.get_tree().physics_frame
	var espaco := j.get_world_3d().direct_space_state
	ok = m._conferir("5 playgrounds e 4 arcos de saída", n.playgrounds.size() == 5 and n.saidas.size() == 4) and ok
	var cegos := n.playgrounds.filter(func(p: Dictionary) -> bool:
		return not espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p.entrada + Vector3.UP * 2.0, n.brilho_do_marco, 1)).is_empty())
	ok = m._conferir("da entrada de cada playground dá para ver o brilho do baú em cima do pico", cegos.is_empty(),
			"(sem ver: %s)" % ", ".join(cegos.map(func(p: Dictionary) -> String: return p.nome))) and ok
	var donos := n.vaga_lumes.map(func(v: VagaLume) -> int: return _playground_mais_perto(v.global_position))
	ok = m._conferir("um vaga-lume no bolso do playground 2, do 3 e do 5", donos == [1, 2, 4], "(%s)" % str(donos)) and ok
	ok = m._conferir("a arena fica no cume: o baú é o ponto mais alto do caminho", n.bau.global_position.y > 45.5
			and Vector2(n.bau.global_position.x, n.bau.global_position.z).length() < 4.0) and ok
	# As Bolotas ficam paradas no teste, menos a primeira, que dorme (e o fantasma, ligado na hora dele).
	for b in n.alvos.slice(1):
		b.process_mode = Node.PROCESS_MODE_DISABLED

	m._comecar_fase()
	await m._esperar(4.0)
	ok = m._conferir("desce flutuando e pisa na neve do lago", j.is_on_floor() and j.controle_ligado and absf(j.global_position.y) < 0.3
			and j.global_position.distance_to(n.inicio) < 1.0) and ok
	var b0 := n.alvos[0] as Bolota
	j.teleportar(b0.global_position + Vector3(0, 0.1, 1.6))
	j.visual.rotation.y = PI
	await m._esperar(0.3)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.45)
	await m._esperar(0.6)
	ok = m._conferir("o pinguim que dorme no lago apanha e sai quicando", b0.derrotado) and ok
	ok = await _lago() and ok
	ok = await _ilhas() and ok
	ok = await _vila() and ok
	ok = await _encosta() and ok
	ok = await _subida() and ok

	# Baú no cume, a Estrela Grande e a tela de fim.
	var bau := n.bau
	var frente := bau.global_basis.z
	j.teleportar(bau.global_position + frente * 2.8 + Vector3(0, 0.1, 0))
	j.visual.rotation.y = atan2(-frente.x, -frente.z)
	await m._esperar(0.4)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.5)
	ok = m._conferir("três golpes abrem o baú", bau.derrotado and bau.estrela != null, "(%d golpes)" % bau.golpes) and ok
	await m._esperar(1.2)
	j.teleportar(bau.global_position + frente * 2.4 + Vector3(0, 0.1, 0))
	await m._esperar(3.6)
	ok = m._conferir("pegar a Estrela Grande mostra a tela de fim", m.hud.fim_aberto and not j.controle_ligado) and ok
	m._terminar(ok)


## Playground 1 e o trenó: o gelo, os botões no lago, a ponte de neve, a pilha de bolas de neve, o iglu e a viagem.
func _lago() -> bool:
	var ok := true
	j.teleportar(Vector3(14, 0.1, 118))
	await m._esperar(0.4)
	ok = m._conferir("perto do lago o Vovô mostra o gelo", m.hud.dica_atual == "gelo") and ok
	var na_neve := await _deslizar(Vector3(16, 0.1, 124), Vector3(-1, 0, 0))
	var no_gelo := await _deslizar(Vector3(6, 0.2, 110), Vector3(-1, 0, 0))
	ok = m._conferir("no gelo o Faísca demora a parar e escorrega bem mais que na neve", no_gelo > 2.0 and na_neve < 1.0 and j.no_gelo,
			"(%.1f m no gelo, %.1f m na neve)" % [no_gelo, na_neve]) and ok

	ok = m._conferir("antes dos botões, a ponte até o trenó não existe", not n.ponte_dos_botoes_pronta()) and ok
	# O primeiro botão se aperta escorregando até ele; os outros, caindo em cima.
	var b0 := n.botoes[0]
	j.teleportar(b0.global_position + Vector3(4.0, 0.2, 0))
	await m._esperar(0.3)
	await _andar(Vector3(-1, 0, 0), 0.7)
	ok = m._conferir("escorregando pelo gelo, o Faísca passa no botão e ele afunda", b0.esta_apertado) and ok
	for b in n.botoes.slice(1):
		j.teleportar(b.global_position + Vector3(0, 0.9, 0))
		await m._esperar(0.4)
	await m._esperar(2.0)
	ok = m._conferir("com os três botões a ponte de neve sobe", n.botoes.all(func(x: Botao) -> bool: return x.esta_apertado) and n.ponte_dos_botoes_pronta()) and ok
	var onde := await _pular_para(Vector3(-27.5, 0.1, 95.5), Vector3(-31, 0, 94.5))
	ok = m._conferir("da beira do lago se pula na ponte", absf(onde.y) < 0.3, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok

	# Bolso: a pilha de bolas de neve até o monte do coração.
	var degraus := [[Vector3(-22, 0.1, 105.5), Vector3(-24.5, 1.6, 108)], [Vector3(-24.5, 1.7, 108), Vector3(-26.5, 3.2, 111.5)],
		[Vector3(-26.5, 3.3, 111.5), Vector3(-27.5, 4.6, 115)], [Vector3(-27.5, 4.7, 115), Vector3(-26, 6.0, 118.5)]]
	var subiu := true
	for d in degraus:
		onde = await _pular_para(d[0], d[1])
		subiu = subiu and absf(onde.y - d[1].y) < 0.45
	ok = m._conferir("a pilha de bolas de neve sobe pulando até o monte do coração", subiu and absf(onde.y - 6.0) < 0.3, "(altura %.1f)" % onde.y) and ok

	# Bolso: o iglu pequeno é oco, e as estrelinhas estão lá dentro.
	var iglu := Vector3(-19, 0, 123)
	var porta := Vector3(sin(PI * 0.3), 0, cos(PI * 0.3))
	var antes := n.pegas
	j.teleportar(iglu + porta * 8.0 + Vector3(0, 0.1, 0))
	await _andar(-porta, 1.6)
	ok = m._conferir("dá para entrar no iglu pequeno pela porta e pegar as estrelinhas dele",
			Vector2(j.global_position.x - iglu.x, j.global_position.z - iglu.z).length() < 2.5 and n.pegas > antes, "(%d estrelinhas)" % (n.pegas - antes)) and ok

	var t := n.treno
	j.teleportar(t.global_position + Vector3(0, 0.3, 0))
	await m._esperar(1.0)
	ok = m._conferir("o trenó dos pinguins sai quando o Faísca sobe nele", t.estado == "indo") and ok
	while t.estado == "indo":
		await m.get_tree().physics_frame
	ok = m._conferir("e o leva voando até a primeira ilha de gelo", t.estado == "em_ate" and j.is_on_floor()
			and j.global_position.distance_to(t.ate) < 2.0, "(%.1f m)" % j.global_position.distance_to(t.ate)) and ok
	await _andar(Vector3(-70, 0, 56) - Vector3(t.ate.x, 0, t.ate.z), 1.2)
	ok = m._conferir("na chegada o Vovô mostra o laser", m.hud.dica_atual == "laser") and ok
	j.teleportar(n.postos[0].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P1 acende na primeira ilha", n.postos[0].acendido) and ok
	return ok


## Playground 2 e o canhão: a ponte de gelo, a bola de neve, os pinguins, o canhão desentupido e o V1.
func _ilhas() -> bool:
	var ok := true
	j.teleportar(Vector3(-73.5, 7.1, 59.8))
	await m._esperar(0.3)
	await _andar(Vector3(-82.5, 9, 64) - Vector3(-73.5, 7, 59.8), 2.6)
	ok = m._conferir("a ponte estreita de gelo leva da chegada até a ilha da direita", j.is_on_floor() and absf(j.global_position.y - 9.0) < 0.3,
			"(%.1f, %.1f, %.1f)" % [j.global_position.x, j.global_position.y, j.global_position.z]) and ok

	# A bola de neve do forte empurra quem fica no caminho.
	var bola := n.bolas_de_neve[0]
	var meio_caminho := (bola.de + bola.ate) * 0.5 - Vector3.UP * bola.raio
	var esperou := 0
	while bola.global_position.distance_to(bola.de) > 0.5 and esperou < 600:
		await m.get_tree().physics_frame
		esperou += 1
	j.teleportar(meio_caminho + Vector3(0, 0.1, 0))
	var mais_longe := 0.0
	for i in 240:
		await m.get_tree().physics_frame
		mais_longe = maxf(mais_longe, Vector2(j.global_position.x - meio_caminho.x, j.global_position.z - meio_caminho.z).length())
	ok = m._conferir("a bola de neve rolando empurra o Faísca para longe, sem tirar coração", mais_longe > 2.5 and j.vida == Jogador.VIDA_MAX,
			"(%.1f m)" % mais_longe) and ok

	ok = m._conferir("antes dos pinguins, o canhão está entupido de neve", not n.canhao_pronto()) and ok
	for c in n.cubos_de_gelo:
		j.teleportar(c.global_position + Vector3(0, CuboDeGelo.ALTO + 3.0, 0))
		await m._esperar(0.15)
		j.forcar_pulo = true
		await m._esperar(0.7)
		j.forcar_pulo = false
		await m._esperar(0.6)
	var soltos := n.cubos_de_gelo.filter(func(c: CuboDeGelo) -> bool: return c.derretido).size()
	ok = m._conferir("o laser derrete os três cubos de gelo dos pinguins, um em cada ponta", soltos == 3) and ok
	await m._esperar(1.2)
	ok = m._conferir("com os três pinguins soltos, o monte de neve sai de cima do canhão", n.canhao_pronto()) and ok

	j.teleportar(n.vaga_lumes[0].global_position - Vector3(0, 0.8, 0))
	await m._esperar(0.3)
	ok = m._conferir("o V1 está na beirada embaixo da ilha do meio", n.achados == 1) and ok
	var onde := await _quicar(n.nuvens_que_quicam[0], Vector3(-100.5, 10, 44))
	ok = m._conferir("e a neve fofa da beirada devolve para a ilha do meio", absf(onde.y - 10.0) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	onde = await _pular_para(Vector3(-98, 10.1, 33), Vector3(-98, 11, 29))
	ok = m._conferir("os degraus de neve sobem da ilha do meio para a do alto", absf(onde.y - 11.0) < 0.3, "(altura %.1f)" % onde.y) and ok

	var c := n.canhoes[0]
	j.teleportar(c.global_position + Vector3(0, 0.8, 0.6))
	await m._esperar(0.3)
	var disparou := c.voando
	await m._esperar(Canhao.VOO + 1.2)
	ok = m._conferir("o canhão de neve lança o Faísca até a Vila do Iglu", disparou and not c.voando and j.is_on_floor()
			and j.global_position.distance_to(c.destino) < 2.5, "(%.1f m do destino)" % j.global_position.distance_to(c.destino)) and ok
	return ok


## Playground 3 e a cadeirinha: a luva, os três sinos, o fantasma, o quarto sino, a escada de gelo e o V2.
func _vila() -> bool:
	var ok := true
	j.teleportar(n.postos[1].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P2 acende na vila", n.postos[1].acendido) and ok
	var s0 := n.sinos_da_vila[0]
	await _jogar_de(s0, 7.0)
	ok = m._conferir("sem a luva, o golpe não alcança o sino lá no alto", not s0.tocado) and ok

	var iglu := Vector3(-58, 18, -73)
	var porta := Vector3(sin(atan2(3.0, 8.5)), 0, cos(atan2(3.0, 8.5)))
	j.teleportar(iglu + porta * 10.0 + Vector3(0, 0.1, 0))
	await _andar(-porta, 2.2)
	ok = m._conferir("a Luva de Neve está dentro do iglu grande, e o Vovô mostra como usa", n.luva_pega and j.luva_de_neve
			and m.hud.dica_atual == "luva") and ok
	ok = m._conferir("com a luva, os sinos ao alcance balançam e brilham", true) and ok

	var antes := n.cadeirinha.global_position
	j.teleportar(n.cadeirinha.global_position + Vector3(0, 0.3, 0))
	await m._esperar(1.2)
	ok = m._conferir("antes dos sinos, a cadeirinha não sai", n.cadeirinha.estado == "em_de" and n.cadeirinha.global_position.distance_to(antes) < 0.1) and ok
	for s in n.sinos_da_vila:
		await _jogar_de(s, 8.0)
	var tocados := n.sinos_da_vila.filter(func(s: Sino) -> bool: return s.tocado).size()
	ok = m._conferir("cada golpe com a luva joga uma bola de neve que toca o sino da coluna", tocados == 3, "(%d de 3)" % tocados) and ok
	ok = m._conferir("com os três sinos a cadeirinha destrava", not n.cadeirinha.travada) and ok

	# O fantasma: o soco atravessa, a bola de neve acerta.
	var fantasma := n.alvos.filter(func(a: Alvo) -> bool: return a is BolotaMonstro and (a as BolotaMonstro).regra == "fantasma")[0] as Bolota
	fantasma.process_mode = Node.PROCESS_MODE_INHERIT
	j.luva_de_neve = false
	j.teleportar(fantasma.global_position + Vector3(1.6, 0.1, 0))
	j.visual.rotation.y = -PI * 0.5
	await m._esperar(0.3)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.45)
	ok = m._conferir("o soco atravessa o fantasma", not fantasma.derrotado) and ok
	j.luva_de_neve = true
	await m._esperar(1.0)
	for i in 4:
		if fantasma.derrotado:
			break
		j.teleportar(fantasma.global_position + Vector3(6.0, 0.1, 0))
		j.visual.rotation.y = -PI * 0.5
		await m._esperar(0.25)
		await m._toque(JOY_BUTTON_X)
		await m._esperar(1.2)
	ok = m._conferir("e a bola de neve da luva acerta o fantasma", fantasma.derrotado) and ok

	# O quarto sino: pela frente o iglu tapa; por trás, acerta, e a escada de gelo aparece até o V2.
	var s4 := n.sino_da_escada
	j.teleportar(iglu + porta * 10.0 + Vector3(0, 0.1, 0))
	_virar_para(s4.ponto())
	await m._esperar(0.3)
	await m._toque(JOY_BUTTON_X)
	await m._esperar(1.5)
	ok = m._conferir("pela frente do iglu, a bola de neve não alcança o quarto sino", not s4.tocado) and ok
	await _jogar_de(s4, 9.0, -porta)
	ok = m._conferir("por trás da chaminé, acerta", s4.tocado) and ok
	await m._esperar(2.0)
	ok = m._conferir("e a escada de gelo aparece em volta da pedra alta", n.escada_pronta()) and ok
	var degraus := n.degraus_de_gelo
	var subiu := true
	var onde := Vector3.ZERO
	for i in degraus.size() - 1:
		onde = await _pular_para(degraus[i].global_position + Vector3(0, 0.1, 0), degraus[i + 1].global_position)
		subiu = subiu and absf(onde.y - degraus[i + 1].global_position.y) < 0.3
	ok = m._conferir("os degraus de gelo sobem 1,6 m de cada vez", subiu, "(altura %.1f)" % onde.y) and ok
	var v2 := n.vaga_lumes[1]
	onde = await _pular_para(degraus[-1].global_position + Vector3(0, 0.1, 0), v2.global_position - Vector3(0, 1.4, 0))
	await _andar(v2.global_position - j.global_position, 0.3)
	ok = m._conferir("e do último degrau se chega à pedra alta, onde está o V2", n.achados == 2 and absf(onde.y - 30.0) < 0.3,
			"(altura %.1f, vaga-lumes %d)" % [onde.y, n.achados]) and ok

	var cad := n.cadeirinha
	j.teleportar(cad.global_position + Vector3(0, 0.3, 0))
	await m._esperar(1.0)
	ok = m._conferir("a cadeirinha sai quando o Faísca senta", cad.estado == "indo") and ok
	while cad.estado == "indo":
		await m.get_tree().physics_frame
	ok = m._conferir("e o leva até a Encosta das Avalanches, sem cair", cad.estado == "em_ate" and j.is_on_floor()
			and j.global_position.distance_to(cad.ate) < 2.0, "(%.1f m)" % j.global_position.distance_to(cad.ate)) and ok
	await _andar(n.no_pico(70, 40, 22) - cad.ate, 0.7)
	ok = m._conferir("e desce andando na primeira plataforma", j.is_on_floor() and absf(j.global_position.y - 22.0) < 0.3) and ok
	j.teleportar(n.postos[2].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P3 acende na encosta", n.postos[2].acendido) and ok
	return ok


## Playground 4: a cachoeira que empurra, os sinos que congelam a água em rampa, o vão flutuando, a caverna e a ponte.
func _encosta() -> bool:
	var ok := true
	var c0 := n.cachoeiras[0]
	var rumo := Vector3(c0.ate.x - c0.de.x, 0, c0.ate.z - c0.de.z).normalized()
	# O fantasma da vila pode ter tirado um coração: conta a partir de agora.
	var vida := j.vida
	j.teleportar(c0.de - rumo * 1.5 + Vector3(0, 0.1, 0))
	await _andar(rumo, 1.2)
	await m._esperar(1.0)
	ok = m._conferir("a cachoeira empurra de volta quem tenta passar, e ele fica na plataforma", j.is_on_floor()
			and absf(j.global_position.y - c0.de.y) < 0.3 and j.vida == vida, "(altura %.1f, corações %d de %d)" % [j.global_position.y, j.vida, vida]) and ok
	var congeladas := 0
	var subidas := 0
	for i in 3:
		var c := n.cachoeiras[i]
		var r := Vector3(c.ate.x - c.de.x, 0, c.ate.z - c.de.z).normalized()
		j.teleportar(c.de - r * 1.5 + Vector3(0, 0.1, 0))
		_virar_para(n.sinos_das_cachoeiras[i].ponto())
		await m._esperar(0.3)
		await m._toque(JOY_BUTTON_X)
		await m._esperar(1.8)
		if c.rampa_pronta():
			congeladas += 1
		j.teleportar(c.de - r * 0.5 + Vector3(0, 0.1, 0))
		await _andar(r, 2.6)
		if j.is_on_floor() and absf(j.global_position.y - c.ate.y) < 0.4:
			subidas += 1
	ok = m._conferir("a bola de neve toca o sino de cada cachoeira, e a água congela numa rampa de gelo", congeladas == 3, "(%d de 3)" % congeladas) and ok
	ok = m._conferir("e pelas três rampas se sobe até a quarta plataforma", subidas == 3, "(%d de 3)" % subidas) and ok

	var g3 := n.no_pico(-2, 36, 31)
	var g4 := n.no_pico(-26, 33, 31)
	var rumo4 := (g4 - g3).normalized()
	var onde := await _pular_flutuando(g3 + rumo4 * 3.8 + Vector3(0, 0.1, 0), g4 - rumo4 * 2.0)
	ok = m._conferir("o vão até a última plataforma se passa pulando e flutuando", absf(onde.y - 31.0) < 0.3, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok

	var g1 := n.no_pico(46, 38, 25)
	var cav := n.no_pico(34, 31, 26.5)
	var para_cav := Vector3(cav.x - g1.x, 0, cav.z - g1.z).normalized()
	onde = await _pular_flutuando(g1 + para_cav * 3.8 + Vector3(0, 0.1, 0), cav + para_cav * 0.5)
	ok = m._conferir("a caverna atrás da segunda cachoeira é um bolso a um pulo da plataforma", absf(onde.y - 26.5) < 0.3,
			"(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok

	j.teleportar(g4 + Vector3(0, 0.1, 0))
	await _andar(-Vector3(g4.x, 0, g4.z), 2.4)
	var raio := Vector2(j.global_position.x, j.global_position.z).length()
	ok = m._conferir("a ponte de gelo leva da última plataforma até o anel do pico, sem pular", j.is_on_floor() and absf(j.global_position.y - 30.0) < 0.3
			and raio < 25.5, "(%.1f m do meio)" % raio) and ok
	j.teleportar(n.postos[3].global_position + Vector3(0, 0.1, 1.0))
	await m._esperar(0.4)
	ok = m._conferir("o P4 acende no anel do pico", n.postos[3].acendido) and ok
	return ok


## Playground 5: a neve fofa, as saliências, o pingente que cai, a porta de gelo e o sino dela, a gruta e a volta.
func _subida() -> bool:
	var ok := true
	var alvo1 := n.no_pico(-80, n.raio_do_pico(33.6) + 1.8, 33.6)
	var onde := await _quicar(n.nuvens_que_quicam[1], alvo1)
	ok = m._conferir("a neve fofa do anel joga até a primeira saliência", absf(onde.y - 33.6) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	# A subida: [graus, altura] de cada degrau, saliência ou pingente, até o degrau na frente da porta.
	var subida := [[-80.0, 33.6, 1.8], [-97.0, 35.2, 1.8], [-114.0, 36.8, 1.6], [-130.0, 38.4, 1.6], [-146.0, 40.0, 1.8], [-162.0, 41.6, 1.6],
		[-178.0, 43.2, 1.8], [-194.0, 44.6, 1.8]]
	var subiu := true
	var falhou := ""
	for i in subida.size() - 1:
		var a: Array = subida[i]
		var b: Array = subida[i + 1]
		var de := n.no_pico(a[0], n.raio_do_pico(a[1]) + a[2], a[1])
		var para := n.no_pico(b[0], n.raio_do_pico(b[1]) + b[2], b[1])
		onde = await _pular_para(de + Vector3(0, 0.1, 0), para)
		if absf(onde.y - b[1]) > 0.35:
			subiu = false
			falhou = "%d (%.1f)" % [i + 1, onde.y]
	ok = m._conferir("pela parede do pico, cada saliência e pingente fica a um pulo de 1,6 m do outro", subiu, falhou) and ok
	var p := n.nuvens_que_somem[0]
	var vida := j.vida
	j.teleportar(p.global_position + Vector3(0, 0.2, 0))
	await m._esperar(1.4)
	ok = m._conferir("o pingente lilás cai um instante depois de pisado, e o Faísca cai no anel", p.sumida and j.global_position.y < p.global_position.y - 1.0) and ok
	await m._esperar(2.5)
	ok = m._conferir("sem perder coração (cai no anel)", j.vida == vida and j.is_on_floor() and absf(j.global_position.y - 30.0) < 0.5,
			"(altura %.1f, corações %d de %d)" % [j.global_position.y, j.vida, vida]) and ok

	# A porta de gelo do cume: fechada, segura o Faísca; o sino de cima abre.
	var degrau := n.no_pico(-194, n.raio_do_pico(44.6) + 1.8, 44.6)
	var dentro := n.no_pico(-194, 7.0, 46.0)
	onde = await _pular_para(degrau + Vector3(0, 0.1, 0), dentro)
	ok = m._conferir("com a porta fechada, não se entra no cume", onde.y < 45.5, "(altura %.1f)" % onde.y) and ok
	j.teleportar(degrau + Vector3(0, 0.1, 0))
	_virar_para(n.sino_da_porta.ponto())
	await m._esperar(0.3)
	await m._toque(JOY_BUTTON_X)
	await m._esperar(2.0)
	ok = m._conferir("a bola de neve toca o sino da porta, e a porta de gelo afunda", n.sino_da_porta.tocado and n.porta_aberta()) and ok
	onde = await _pular_para(degrau + Vector3(0, 0.1, 0), dentro)
	ok = m._conferir("e do degrau se entra no cume", absf(onde.y - 46.0) < 0.3 and Vector2(onde.x, onde.z).length() < RAIO_DENTRO_DO_MURO,
			"(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok

	# Segredo: a gruta de gelo no anel. O Vovô mostra o golpe, três golpes abrem a parede e o V3 está dentro.
	var parede := n.paredes_do_pico[0]
	var frente := parede.global_basis.z
	j.teleportar(n.no_pico(-112, 22.5, 30.0) + Vector3(0, 0.1, 0))
	await m._esperar(0.4)
	ok = m._conferir("perto da gruta o Vovô mostra o golpe", m.hud.dica_atual == "golpe") and ok
	j.luva_de_neve = false
	j.teleportar(parede.global_position + frente * 1.8 + Vector3(0, 0.1, 0))
	j.visual.rotation.y = atan2(-frente.x, -frente.z)
	await m._esperar(0.3)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.5)
	await m._esperar(0.6)
	ok = m._conferir("três golpes quebram a parede rachada da gruta", parede.derrotado, "(%d golpes)" % parede.golpes) and ok
	await _andar(-frente, 1.2)
	ok = m._conferir("e o V3 está lá dentro", n.achados == 3, "(vaga-lumes %d)" % n.achados) and ok
	j.luva_de_neve = true

	onde = await _quicar(n.nuvens_que_quicam[2], n.no_pico(-146, n.raio_do_pico(40.0) + 1.8, 40.0))
	ok = m._conferir("quem cai no anel volta lá para cima pela neve fofa do outro lado", absf(onde.y - 40.0) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	return ok


## Do meio do cume até a face de dentro do muro de gelo.
const RAIO_DENTRO_DO_MURO := 10.6


## Índice do playground com o centro mais perto de `p`.
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


## Põe o Faísca no chão a `distancia` m do pé do sino (do lado `lado`, ou do lado do meio da vila), virado para ele, e
## dá um golpe.
func _jogar_de(s: Sino, distancia: float, lado := Vector3.ZERO) -> void:
	var pe := s.global_position
	var fora := lado if lado != Vector3.ZERO else Vector3(Fase31.VILA.x - pe.x, 0, Fase31.VILA.z - pe.z).normalized()
	var chao := Vector3(pe.x, 0, pe.z) + fora * distancia
	var batida := j.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(chao + Vector3.UP * 60.0, chao + Vector3.DOWN * 20.0, 1))
	j.teleportar((batida.position if not batida.is_empty() else chao) + Vector3(0, 0.1, 0))
	await m._esperar(0.3)
	_virar_para(s.ponto())
	await m._toque(JOY_BUTTON_X)
	await m._esperar(1.8)


## Do chão em `de`, anda `segundos` para `dir` e solta: devolve quanto ele andou depois de soltar.
func _deslizar(de: Vector3, dir: Vector3) -> float:
	j.teleportar(de)
	await m._esperar(0.3)
	j.yaw = atan2(-dir.x, -dir.z)
	j.forcar_direcao = Vector2(0, -1)
	await m._esperar(1.2)
	j.forcar_direcao = Vector2.ZERO
	var solto := j.global_position
	await m._esperar(1.5)
	return Vector2(j.global_position.x - solto.x, j.global_position.z - solto.z).length()


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


## Como `_pular_para`, mas segurando o pulo o tempo todo (flutua na descida).
func _pular_flutuando(de: Vector3, alvo: Vector3) -> Vector3:
	j.teleportar(de)
	await m._esperar(0.3)
	j.forcar_pulo = true
	for i in 400:
		await m.get_tree().physics_frame
		var falta := Vector3(alvo.x - j.global_position.x, 0, alvo.z - j.global_position.z)
		if falta.length() > 0.6:
			j.yaw = atan2(-falta.x, -falta.z)
			j.forcar_direcao = Vector2(0, -1)
		else:
			j.forcar_direcao = Vector2.ZERO
		if i > 12 and j.is_on_floor():
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	var onde := j.global_position
	await m._esperar(0.1)
	return onde


## Põe o Faísca em cima do monte de neve fofa e o guia no ar até em cima de `alvo` (solta o direcional perto; na
## descida flutua se precisar). Devolve onde pousou.
func _quicar(no: NuvemQueQuica, alvo: Vector3) -> Vector3:
	var area: Area3D = no.area
	j.teleportar(area.global_position + Vector3(0, 0.2, 0))
	var subiu := false
	for i in 500:
		await m.get_tree().physics_frame
		var falta := Vector3(alvo.x - j.global_position.x, 0, alvo.z - j.global_position.z)
		if j.global_position.y > area.global_position.y + 1.5:
			subiu = true
		if subiu and falta.length() > 0.8:
			j.yaw = atan2(-falta.x, -falta.z)
			j.forcar_direcao = Vector2(0, -1)
		else:
			j.forcar_direcao = Vector2.ZERO
		j.forcar_pulo = subiu and j.velocity.y < 0.0 and falta.length() > 1.5
		if subiu and i > 20 and j.is_on_floor():
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	await m._esperar(0.2)
	return j.global_position


## Anda na direção `dir` (no chão) por `segundos`.
func _andar(dir: Vector3, segundos: float) -> void:
	j.yaw = atan2(-dir.x, -dir.z)
	j.forcar_direcao = Vector2(0, -1)
	await m._esperar(segundos)
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.2)


## Fotos da 3-1 (precisa de janela): de cima, cada playground de cima e de dentro, as viagens e a arena.
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "fase_3_1/"))
	for b in n.alvos:
		(b as Bolota).dormindo = true
		b.process_mode = Node.PROCESS_MODE_DISABLED
	m._comecar_fase()
	await m._esperar(4.0)
	await _foto_de_cima(Vector3(130, 150, 210), Vector3(-30, 8, 10), "fase_3_1/00_visao_geral")
	await _foto_de_cima(Vector3(-200, 120, -170), Vector3(-30, 10, 20), "fase_3_1/00b_de_cima_noroeste")
	await _foto_em(n.inicio, 0.35, -0.12, "fase_3_1/01_lago_congelado")
	await _foto_de_cima(Vector3(40, 40, 150), Vector3(-4, 2, 100), "fase_3_1/01b_lago_de_cima")
	await _foto_em(Vector3(-20, 0.1, 99), 1.25, -0.15, "fase_3_1/01c_ponte_e_treno")
	await _foto_de_cima(Vector3(-40, 50, 100), Vector3(-92, 9, 40), "fase_3_1/02_ilhas_de_gelo")
	await _foto_em(Vector3(-68, 7.1, 58), 1.0, -0.1, "fase_3_1/02b_ilhas_de_dentro")
	await _foto_de_cima(Vector3(-130, 60, -20), Vector3(-68, 18, -78), "fase_3_1/03_vila_do_iglu")
	await _foto_em(Vector3(-77, 18.1, -54), 0.7, -0.05, "fase_3_1/03b_vila_de_dentro")
	await _foto_em(Vector3(-55, 18.1, -62), 0.3, 0.15, "fase_3_1/03c_iglu_grande")
	await _foto_de_cima(Vector3(-60, 50, -20), Vector3(-15, 22, -60), "fase_3_1/03d_cadeirinha")
	await _foto_de_cima(Vector3(90, 55, -60), Vector3(30, 24, -10), "fase_3_1/04_encosta")
	var g0 := n.no_pico(70, 40, 22) + Vector3(-1.5, 0.1, -1.5)
	var para_g1 := n.no_pico(46, 38, 25) - g0
	await _foto_em(g0, atan2(-para_g1.x, -para_g1.z), 0.15, "fase_3_1/04b_encosta_de_dentro")
	await _foto_de_cima(Vector3(-50, 64, 40), Vector3(0, 36, 0), "fase_3_1/05_subida_do_pico")
	await _foto_em(n.no_pico(-30, 23, 30.1), 0.9, 0.2, "fase_3_1/05b_anel_do_pico")
	var degrau := n.no_pico(-194, n.raio_do_pico(44.6) + 3.0, 44.7)
	await _foto_em(degrau, atan2(degrau.x, degrau.z), 0.25, "fase_3_1/05c_porta_do_cume")
	await _foto_em(Vector3(4, 46.1, 7), 0.4, -0.3, "fase_3_1/06_arena")
	# A foto da porta no farol (assets/faisca/portas/fase_3_1.jpg, em 640x360): o lago com o pico atrás, sem o HUD.
	m.hud.visible = false
	await _foto_de_cima(Vector3(30, 11, 150), Vector3(-4, 17, 62), "fase_3_1/porta")
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
