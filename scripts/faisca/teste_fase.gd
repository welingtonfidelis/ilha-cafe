class_name TesteFase
extends RefCounted
## Testes da fase de verdade (a 1-1), chamados pelo FaiscaSolo:
##   --faisca-fase           confere a fase de ponta a ponta: contagens, descida do céu, Bolotas, vaga-lume,
##                    posto, queda, coração, mola, dica, flores e portão, plataforma que se mexe,
##                    esteiras, argolas, botões, nuvem que some, canhão (os trechos de 2026-10-29),
##                    curto, baú, Estrela Grande, tela de fim e o A para jogar de novo
##   --faisca-fase-captura   fotos de cada trecho em tools/capturas/faisca/fase/ (precisa de janela)
## Usa as ajudas do FaiscaSolo (_esperar, _botao, _toque, _conferir, _foto).

var m: Node
var n: Fase
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
	ok = m._conferir("de 75 a 100 estrelinhas no caminho e nos bolsos (fora as das Bolotas)", n.estrelas.size() >= 75 and n.estrelas.size() <= 100,
			"(%d soltas, %d com as das Bolotas)" % [n.estrelas.size(), total]) and ok
	ok = m._conferir("3 postos, 3 vaga-lumes, 3 flores e 1 portão", n.postos.size() == 3 and n.vaga_lumes.size() == 3 and n.flores.size() == 3 and n.portoes.size() == 1) and ok
	ok = m._conferir("12 Bolotas e o baú", n.alvos.size() == 12 and n.bau != null, "(%d Bolotas)" % n.alvos.size()) and ok
	ok = m._conferir("peças: 5 esteiras, 4 argolas, 3 botões, 5 nuvens que somem, o canhão e 3 plataformas que se mexem", n.esteiras.size() == 5
			and n.argolas.size() == 4 and n.botoes.size() == 3 and n.ponte_botoes.size() == 3 and n.nuvens_que_somem.size() == 5
			and n.canhoes.size() == 1 and n.moveis.size() == 3) and ok

	# O padrão de playgrounds (2026-10-29): quatro playgrounds em volta da Torre de Nuvens, arcos de saída, o brilho
	# do baú à vista de todos e um vaga-lume no bolso de cada um dos três últimos.
	await m.get_tree().physics_frame
	var espaco := j.get_world_3d().direct_space_state
	ok = m._conferir("4 playgrounds e 3 arcos de saída", n.playgrounds.size() == 4 and n.saidas.size() == 3) and ok
	var cegos := n.playgrounds.filter(func(p: Dictionary) -> bool:
		return not espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p.entrada + Vector3.UP * 2.0, n.brilho_do_marco, 1)).is_empty())
	ok = m._conferir("da entrada de cada playground dá para ver o brilho do baú no alto da torre", cegos.is_empty(),
			"(sem ver: %s)" % ", ".join(cegos.map(func(p: Dictionary) -> String: return p.nome))) and ok
	var donos := n.vaga_lumes.map(func(v: VagaLume) -> int: return _playground_mais_perto(v.global_position))
	ok = m._conferir("um vaga-lume no bolso de cada playground: o 2, o 3 e o 4", donos == [1, 2, 3], "(%s)" % str(donos)) and ok
	ok = m._conferir("a arena fica no alto do marco: o baú é o ponto mais alto do caminho", n.bau.global_position.y > 21.0
			and n.bau.global_position.distance_to(Vector3(0, 22, -97.5)) < 1.0) and ok

	# Começo: desce do céu com os jatos e o controle volta quando pisa.
	m._comecar_fase()
	await m._esperar(0.5)
	var descendo := j.flutuando and not j.controle_ligado
	await m._esperar(3.5)
	ok = m._conferir("desce do céu flutuando e pisa no começo", descendo and j.is_on_floor() and j.controle_ligado
			and j.global_position.distance_to(n.inicio) < 1.0, "(descendo %s, no chão %s, controle %s, %.1f m do começo)" % [descendo, j.is_on_floor(), j.controle_ligado, j.global_position.distance_to(n.inicio)]) and ok

	# A primeira Bolota está dormindo; três golpes derrotam e ela solta 3 estrelinhas.
	var b0 := n.alvos[0] as Bolota
	ok = m._conferir("a primeira Bolota dorme", b0.dormindo) and ok
	var antes := n.estrelas.size()
	j.teleportar(b0.global_position + Vector3(0, 0.1, 1.6))
	j.visual.rotation.y = PI
	await m._esperar(0.3)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.45)
	await m._esperar(0.8)
	ok = m._conferir("três socos derrotam a Bolota", b0.derrotado, "(vida %d)" % b0.vida) and ok
	ok = m._conferir("ela solta 3 estrelinhas e o total não muda", n.estrelas.size() == antes + 3 and n.total_estrelas() == total,
			"(total %d)" % n.total_estrelas()) and ok
	var pegas := n.pegas
	for e in n.estrelas.slice(antes):
		j.teleportar(e.global_position - Vector3(0, 0.8, 0))
		await m._esperar(0.15)
	ok = m._conferir("pega as estrelinhas da Bolota", n.pegas == pegas + 3 and m.hud._contador.text == str(n.pegas), "(%d)" % n.pegas) and ok

	# V1, na beirada embaixo da ilha do meio do playground 2.
	j.teleportar(n.vaga_lumes[0].global_position - Vector3(0, 0.8, 0))
	await m._esperar(0.3)
	ok = m._conferir("encostar no vaga-lume acha", n.achados == 1 and m.hud._luzes[0].aceso) and ok

	# P1, na entrada do playground 2: vira o ponto de volta; cair nas nuvens tira um coração e volta lá.
	var p1 := n.postos[0]
	var lado := p1.ponto() - p1.global_position
	lado.y = 0.0
	j.teleportar(p1.global_position + lado.normalized() * 3.0 + Vector3.UP * 0.3)
	await m._esperar(0.12)
	var acendeu := p1.acendido
	j.teleportar(p1.ponto())
	await m._esperar(0.3)
	ok = m._conferir("passar a 3 m do posto, sem encostar na bandeira, já acende", acendeu
			and j.ponto_retorno.distance_to(p1.ponto()) < 0.1) and ok
	j.teleportar(Vector3(30, 0, -60))
	await m._esperar(1.5)
	ok = m._conferir("caiu nas nuvens: perde um coração e volta no posto", j.vida == Jogador.VIDA_MAX - 1
			and j.global_position.distance_to(p1.ponto()) < 1.5 and not m.hud._coracoes[2].cheio, "(vida %d)" % j.vida) and ok
	var mais_baixo := INF
	for i in int(0.8 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		mais_baixo = minf(mais_baixo, j.global_position.y)
	ok = m._conferir("depois de voltar no posto ele fica de pé lá, sem cair de novo", j.vida == Jogador.VIDA_MAX - 1 and j.is_on_floor()
			and mais_baixo > p1.ponto().y - 0.3, "(vida %d, desceu até %.1f, ponto em %.1f)" % [j.vida, mais_baixo, p1.ponto().y]) and ok
	var firmes := n.postos.filter(func(p: Posto) -> bool: return Posto.chao_firme(espaco, p.ponto(), p.ponto().y) != Vector3.INF)
	var inicio_firme := Posto.chao_firme(espaco, n.inicio, n.inicio.y) != Vector3.INF
	ok = m._conferir("todos os postos e o começo devolvem o Faísca a %.1f m ou mais de qualquer beira" % Posto.MARGEM,
			firmes.size() == n.postos.size() and inicio_firme, "(%d de %d postos, começo %s)" % [firmes.size(), n.postos.size(), inicio_firme]) and ok

	# Coração extra (no Jardim das Flores) devolve o coração.
	await m._esperar(0.2)
	j.teleportar(n.coracoes[0].global_position - Vector3(0, 0.8, 0))
	await m._esperar(0.3)
	ok = m._conferir("o coração extra devolve um coração", j.vida == Jogador.VIDA_MAX and m.hud._coracoes[2].cheio) and ok

	# Bolota acordada (ilha do meio do playground 2) vem e, encostando, tira um coração.
	var b1 := n.alvos[1] as Bolota
	j.teleportar(b1.global_position + Vector3(2.5, 0.1, 0))
	await m._esperar(1.5)
	ok = m._conferir("a Bolota vem até o Faísca e encostar tira um coração", j.vida == Jogador.VIDA_MAX - 1, "(vida %d)" % j.vida) and ok
	await m._esperar(1.8)
	b1.ficar_tonta()
	j.teleportar(b1.global_position + Vector3(3.0, 0.1, 0))
	var p_tonta := b1.global_position
	await m._esperar(1.2)
	ok = m._conferir("tonta, a Bolota não vem atrás do Faísca", b1.global_position.distance_to(p_tonta) < 0.1,
			"(andou %.2f m)" % b1.global_position.distance_to(p_tonta)) and ok
	await m._esperar(2.2)

	# Mola: cair em cima joga lá para o alto.
	var mola := n.molas[0]
	j.teleportar(mola.global_position + Vector3(0, 2.0, 0))
	var altura: float = await m._altura_maxima(1.4)
	ok = m._conferir("a mola joga para o alto", altura > mola.global_position.y + 4.0, "(%.1f m acima)" % (altura - mola.global_position.y)) and ok

	# Dica do Vovô Farol na chegada das Ilhas das Argolas.
	j.teleportar(Vector3(-50, 1.6, -28.0))
	await m._esperar(0.3)
	ok = m._conferir("na chegada das Ilhas das Argolas o Vovô Farol mostra a dica de flutuar", m.hud.dica_atual == "flutuar") and ok

	# Travessias de verdade, com o controle simulado.
	# Segurando A até o alto do pulo e soltando: sem voo, ele pousa em cima da beirada (segurando até o fim, flutua
	# por cima dela toda).
	var chegou := await _travessia(Vector3(-3, 0.1, -7.5), -10.2, true, -12.5)
	ok = m._conferir("a beirada do playground 1 sobe segurando A (pulo alto)", chegou.y > 1.3 and chegou.z < -12.3, "(%.1f, %.1f)" % [chegou.y, chegou.z]) and ok
	chegou = await _travessia(Vector3(-3, 0.1, -7.5), -10.2, false)
	ok = m._conferir("com um toque só, não sobe na beirada", chegou.y < 1.0, "(%.1f, %.1f)" % [chegou.y, chegou.z]) and ok
	chegou = await _travessia(Vector3(-49.5, 1.1, -26.0), -29.6, true, -36.5)
	ok = m._conferir("o primeiro vão das argolas passa flutuando", chegou.y > 1.2 and chegou.z < -35.0, "(%.1f, %.1f)" % [chegou.y, chegou.z]) and ok
	chegou = await _travessia(Vector3(-49.5, 1.1, -26.0), -29.6, false)
	ok = m._conferir("sem flutuar, o primeiro vão das argolas não passa", not (chegou.y > 1.2 and chegou.z < -35.0), "(%.1f, %.1f)" % [chegou.y, chegou.z]) and ok
	j.vida = Jogador.VIDA_MAX
	await m._esperar(1.8)

	# Flores de luz: flutuar em cima acende; com as três, o portão abre (as Bolotas do jardim dormem no teste).
	for b in n.alvos.slice(4, 7):
		(b as Bolota).dormindo = true
	for f in n.flores:
		j.teleportar(f.global_position + Vector3(0, 3.2, 0))
		await m._esperar(0.15)
		m._botao(JOY_BUTTON_A, true)
		await m._esperar(0.7)
		m._botao(JOY_BUTTON_A, false)
		await m._esperar(0.6)
	var acesas := n.flores.filter(func(f: FlorDeLuz): return f.esta_acesa).size()
	ok = m._conferir("o laser dos pés acende as flores", acesas == 3, "(%s)" % str(n.flores.map(func(f: FlorDeLuz): return f.esta_acesa))) and ok
	await m._esperar(1.6)
	ok = m._conferir("com as três acesas o portão do paredão abre", n.portao_aberto(n.portoes[0]) and not n.portoes[0].visible) and ok

	# Viagem 3: a plataforma que vai e volta leva o Faísca do Jardim até a torre.
	var mv := n.moveis[0]
	j.teleportar(mv.global_position + Vector3(0, 1.2, 0))
	await m._esperar(0.4)
	var p0 := j.global_position
	var m0 := mv.global_position
	await m._esperar(1.0)
	var andou := (j.global_position - p0) * Vector3(1, 0, 1)
	var mexeu := (mv.global_position - m0) * Vector3(1, 0, 1)
	ok = m._conferir("a plataforma da viagem leva o Faísca junto", j.is_on_floor() and (andou - mexeu).length() < 0.3 and mexeu.length() > 0.3,
			"(robô %.2f m, plataforma %.2f m)" % [andou.length(), mexeu.length()]) and ok

	ok = await _pecas() and ok

	# Subida: da última plataforma, a mola e o voo levam até a arena.
	for b in n.alvos.slice(7):
		(b as Bolota).dormindo = true
	var ultima := n.molas[3]
	var para_arena := (Vector3(0, 0, -96) - ultima.global_position) * Vector3(1, 0, 1)
	j.teleportar(ultima.global_position + Vector3(0, 1.6, 0))
	j.yaw = atan2(-para_arena.x, -para_arena.z)
	await m._esperar(0.2)
	j.forcar_pulo = true
	await m._esperar(0.6)
	j.forcar_direcao = Vector2(0, -1)
	for i in int(3.0 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		if j.is_on_floor() and j.global_position.y > 21.5:
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	await m._esperar(0.3)
	ok = m._conferir("da última plataforma, a mola e o voo levam até a arena", j.is_on_floor() and j.global_position.y > 21.5,
			"(%.1f, %.1f, %.1f)" % [j.global_position.x, j.global_position.y, j.global_position.z]) and ok

	# Sem corações: curto e volta no posto com os 3.
	await m._esperar(1.0)
	j.vida = 1
	j.receber_dano(j.global_position + Vector3(1, 0, 0))
	var no_curto := not j.controle_ligado
	await m._esperar(2.0)
	ok = m._conferir("sem corações dá um curto e volta no posto com os 3", no_curto and j.vida == Jogador.VIDA_MAX and j.controle_ligado
			and j.global_position.distance_to(j.ponto_retorno) < 1.5) and ok

	# Baú: três golpes abrem; pegar a Estrela Grande mostra a tela de fim; A pede para jogar de novo.
	var bau := n.bau
	j.teleportar(bau.global_position + Vector3(0, 0.1, 2.6))
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
	var pediu := [false]
	m.hud.jogar_de_novo.connect(func(): pediu[0] = true)
	await m._toque(JOY_BUTTON_A)
	await m._esperar(0.1)
	ok = m._conferir("A na tela de fim joga de novo", pediu[0]) and ok
	m._terminar(ok)


## Índice do playground com o centro mais perto de `p`.
func _playground_mais_perto(p: Vector3) -> int:
	var melhor := 0
	for i in n.playgrounds.size():
		if p.distance_to(n.playgrounds[i].centro) < p.distance_to(n.playgrounds[melhor].centro):
			melhor = i
	return melhor


## Esteiras (a do playground 1 e a ponte), argolas, botões, nuvem que some e o canhão.
func _pecas() -> bool:
	var ok := true
	# A esteira verde do playground 1 leva quem fica parado em cima até perto do arco, sem travar na ponta.
	var e0 := n.esteiras[0]
	j.teleportar(e0.global_position + Vector3(3.0, 1.2, 0))
	await m._esperar(0.3)
	var x0 := j.global_position.x
	await m._esperar(1.0)
	ok = m._conferir("a esteira verde leva o Faísca parado até o arco", x0 - j.global_position.x > 2.8 and j.is_on_floor(),
			"(andou %.1f m)" % (x0 - j.global_position.x)) and ok
	await m._esperar(2.2)
	ok = m._conferir("e o deixa no chão do playground, sem travar na ponta", j.global_position.x < e0.global_position.x - Esteira.COMPRIMENTO * 0.5
			and j.is_on_floor(), "(x %.1f)" % j.global_position.x) and ok
	# Viagem 1: a ponte de esteiras leva até as Ilhas das Argolas.
	j.teleportar(Vector3(-20, 1.2, -24))
	await m._esperar(9.0)
	ok = m._conferir("a ponte de esteiras leva o Faísca até as Ilhas das Argolas", j.is_on_floor() and j.global_position.x < -43.0
			and j.global_position.y > 0.8, "(%.1f, %.1f)" % [j.global_position.x, j.global_position.y]) and ok
	# Argolas: passar por dentro acende; com as quatro, as estrelinhas do prêmio aparecem.
	for a in n.argolas:
		j.teleportar(a.centro() - Vector3(0, 1.1, 0))
		await m.get_tree().physics_frame
		await m.get_tree().physics_frame
	ok = m._conferir("passar por dentro das argolas acende cada uma", n.argolas.all(func(a: Argola) -> bool: return a.esta_acesa)) and ok
	j.teleportar(Vector3(-58, 3.6, -61))
	await m._esperar(1.5)
	ok = m._conferir("com as quatro acesas, as 8 estrelinhas do prêmio aparecem", n.premio_argolas.size() == 8
			and n.premio_argolas.all(func(e: Area3D) -> bool: return e.visible and e.monitoring)) and ok
	# Botões: cair em cima aperta; com os três, a ponte do bolso alto sobe e dá para pisar nela.
	j.vida = Jogador.VIDA_MAX
	for b in n.botoes:
		j.teleportar(b.global_position + Vector3(0, 1.4, 0))
		await m._esperar(0.8)
	ok = m._conferir("cair em cima dos botões aperta os três", n.botoes.all(func(b: Botao) -> bool: return b.esta_apertado)) and ok
	await m._esperar(2.0)
	var degrau := n.ponte_botoes[1]
	j.teleportar(degrau.global_position + Vector3(0, 1.4, 0))
	await m._esperar(0.6)
	ok = m._conferir("a ponte dos botões sobe e segura o Faísca", n.ponte_dos_botoes_pronta() and j.is_on_floor()
			and j.global_position.y > degrau.global_position.y + 0.8) and ok
	# Nuvem lilás (a primeira da subida): some um instante depois de pisada e volta.
	var nv := n.nuvens_que_somem[0]
	j.teleportar(nv.global_position + Vector3(0, 0.3, 0))
	await m._esperar(0.4)
	var pisou := j.is_on_floor()
	await m._esperar(1.0)
	var sumiu := nv.sumida
	await m._esperar(3.6)
	ok = m._conferir("a nuvem lilás some depois de pisada e volta 3 s depois", pisou and sumiu and not nv.sumida) and ok
	j.vida = Jogador.VIDA_MAX
	# Viagem 2: o canhão lança até o Jardim das Flores, pegando as estrelinhas do voo.
	await m._esperar(1.0)
	var c := n.canhoes[0]
	var pegas := n.pegas
	j.teleportar(c.global_position + Vector3(0, 0.8, 0.6))
	await m._esperar(0.3)
	var disparou := c.voando
	await m._esperar(Canhao.VOO + 1.2)
	ok = m._conferir("o canhão lança o Faísca até o Jardim das Flores, pegando as estrelinhas do voo", disparou and not c.voando
			and j.is_on_floor() and j.controle_ligado and j.global_position.distance_to(c.destino) < 2.5 and n.pegas >= pegas + 4,
			"(%.1f m do destino, %d estrelinhas)" % [j.global_position.distance_to(c.destino), n.pegas - pegas]) and ok
	return ok


## Corre para a frente a partir de `de` e pula quando passa de `beira_z`, segurando A até
## pousar (ou só um toque). Com `soltar_z`, solta A e o analógico quando passa dele (pousa ali, sem
## flutuar adiante). Devolve onde parou.
func _travessia(de: Vector3, beira_z: float, segurar: bool, soltar_z := -INF) -> Vector3:
	j.teleportar(de)
	j.yaw = 0.0
	j.visual.rotation.y = PI
	await m._esperar(0.3)
	j.forcar_direcao = Vector2(0, -1)
	var pulou := -1
	for i in 240:
		await m.get_tree().physics_frame
		if pulou < 0 and j.global_position.z < beira_z:
			j.forcar_pulo = true
			pulou = i
		elif pulou >= 0 and not segurar and i - pulou > 3:
			j.forcar_pulo = false
		elif pulou >= 0 and j.global_position.z < soltar_z:
			j.forcar_pulo = false
			j.forcar_direcao = Vector2.ZERO
		if pulou >= 0 and i - pulou > 12 and (j.is_on_floor() or j.global_position.y < j.limite_queda + 2.0):
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	var onde := j.global_position
	await m._esperar(0.2)
	return onde


## Fotos da 1-1 em playgrounds (precisa de janela): de cima, cada playground de dentro, as viagens e o fim.
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "fase/"))
	m._comecar_fase()
	await m._esperar(4.0)
	await _foto_de_cima(Vector3(150, 120, 60), Vector3(-20, 6, -90), "fase/00_visao_geral")
	await _foto_de_cima(Vector3(-40, 70, 90), Vector3(-20, 6, -70), "fase/00b_de_cima_sul")
	j.yaw = 0.35
	j.pitch = -0.28
	await m._esperar(0.4)
	await m._foto("fase/01_ilha_dos_pulinhos")
	await _foto_de_cima(Vector3(30, 28, 20), Vector3(-2, 0, -18), "fase/01b_playground_1")
	await _foto_em(Vector3(-6, 0.1, -22), -1.2, -0.3, "fase/02_esteiras_e_arco")
	await _foto_de_cima(Vector3(-28, 30, 10), Vector3(-56, 2, -50), "fase/03_ilhas_das_argolas")
	await _foto_em(Vector3(-49.5, 1.1, -27), 0.0, -0.3, "fase/03b_argolas")
	await _foto_em(Vector3(-58, 3.6, -61), 0.4, -0.35, "fase/03c_ilha_do_meio")
	await _foto_de_cima(Vector3(-40, 40, -110), Vector3(0, 8, -150), "fase/04_jardim_das_flores")
	await _foto_em(Vector3(-10, 8.1, -137), 0.9, -0.3, "fase/04b_chegada_no_jardim")
	for f in n.flores:
		f.acender()
	for b in n.botoes:
		b.apertar()
	await m._esperar(2.0)
	await _foto_em(Vector3(5, 8.1, -150), 1.4, -0.25, "fase/04c_portao_aberto")
	await _foto_em(Vector3(-1, 8.1, -164), 0.0, -0.3, "fase/04d_ponte_dos_botoes")
	await _foto_de_cima(Vector3(40, 40, -60), Vector3(0, 14, -96), "fase/05_subida_das_nuvens")
	await _foto_em(Vector3(11, 8.1, -103), -0.4, -0.25, "fase/05b_comeco_da_subida")
	await _foto_em(Vector3(-11, 19.1, -104), 1.2, -0.3, "fase/05c_ultima_plataforma")
	await _foto_em(Vector3(1, 22.1, -92), 0.2, -0.35, "fase/06_arena")
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
