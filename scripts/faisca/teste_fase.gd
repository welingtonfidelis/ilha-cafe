class_name TesteFase
extends RefCounted
## Testes da fase de verdade (a 1-1), chamados pelo FaiscaSolo:
##   --faisca-fase           confere a fase de ponta a ponta: contagens, descida do céu, Bolotas, vaga-lume,
##                    posto, queda, coração, mola, dica, flores e portão, plataforma que se mexe,
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
	ok = m._conferir("a fase tem umas 65 estrelinhas", total >= 55 and total <= 75, "(%d)" % total) and ok
	ok = m._conferir("2 postos, 3 vaga-lumes, 3 flores e 1 portão", n.postos.size() == 2 and n.vaga_lumes.size() == 3 and n.flores.size() == 3 and n.portoes.size() == 1) and ok
	ok = m._conferir("9 Bolotas e o baú", n.alvos.size() == 9 and n.bau != null, "(%d Bolotas)" % n.alvos.size()) and ok

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
	ok = m._conferir("soco, soco e chute derrotam a Bolota", b0.derrotado, "(vida %d)" % b0.vida) and ok
	ok = m._conferir("ela solta 3 estrelinhas e o total não muda", n.estrelas.size() == antes + 3 and n.total_estrelas() == total,
			"(total %d)" % n.total_estrelas()) and ok
	var pegas := n.pegas
	for e in n.estrelas.slice(antes):
		j.teleportar(e.global_position - Vector3(0, 0.8, 0))
		await m._esperar(0.15)
	ok = m._conferir("pega as estrelinhas da Bolota", n.pegas == pegas + 3 and m.hud._contador.text == str(n.pegas), "(%d)" % n.pegas) and ok

	# V1 atrás da árvore.
	j.teleportar(n.vaga_lumes[0].global_position - Vector3(0, 0.8, 0))
	await m._esperar(0.3)
	ok = m._conferir("encostar no vaga-lume acha", n.achados == 1 and m.hud._luzes[0].aceso) and ok

	# P1: vira o ponto de volta; cair nas nuvens tira um coração e volta lá.
	var p1 := n.postos[0]
	# A área é larga (pedido de 2026-10-29): passar a 3 m da bandeira já acende. Antes precisava chegar a uns
	# 2 m (1,6 da área mais a grossura do Faísca).
	var lado := p1.ponto() - p1.global_position
	lado.y = 0.0
	j.teleportar(p1.global_position + lado.normalized() * 3.0 + Vector3.UP * 0.3)
	await m._esperar(0.12)
	var acendeu := p1.acendido
	j.teleportar(p1.ponto())
	await m._esperar(0.3)
	ok = m._conferir("passar a 3 m do posto, sem encostar na bandeira, já acende", acendeu
			and j.ponto_retorno.distance_to(p1.ponto()) < 0.1) and ok
	j.teleportar(Vector3(30, 0, -50))
	await m._esperar(1.5)
	ok = m._conferir("caiu nas nuvens: perde um coração e volta no posto", j.vida == Jogador.VIDA_MAX - 1
			and j.global_position.distance_to(p1.ponto()) < 1.5 and not m.hud._coracoes[2].cheio, "(vida %d)" % j.vida) and ok
	# E fica lá: o ponto de volta é chão firme, longe da beira (não cai de novo). Pouco tempo, para a Bolota
	# acordada da ilha não chegar.
	var mais_baixo := INF
	for i in int(0.8 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		mais_baixo = minf(mais_baixo, j.global_position.y)
	ok = m._conferir("depois de voltar no posto ele fica de pé lá, sem cair de novo", j.vida == Jogador.VIDA_MAX - 1 and j.is_on_floor()
			and mais_baixo > p1.ponto().y - 0.3, "(vida %d, desceu até %.1f, ponto em %.1f)" % [j.vida, mais_baixo, p1.ponto().y]) and ok
	var espaco := j.get_world_3d().direct_space_state
	var firmes := n.postos.filter(func(p: Posto) -> bool: return Posto.chao_firme(espaco, p.ponto(), p.ponto().y) != Vector3.INF)
	var inicio_firme := Posto.chao_firme(espaco, n.inicio, n.inicio.y) != Vector3.INF
	ok = m._conferir("todos os postos e o começo devolvem o Faísca a %.1f m ou mais de qualquer beira" % Posto.MARGEM,
			firmes.size() == n.postos.size() and inicio_firme, "(%d de %d postos, começo %s)" % [firmes.size(), n.postos.size(), inicio_firme]) and ok

	# Coração extra devolve o coração (logo, antes da Bolota acordada chegar no posto).
	await m._esperar(0.2)
	j.teleportar(n.coracoes[0].global_position - Vector3(0, 0.8, 0))
	await m._esperar(0.3)
	ok = m._conferir("o coração extra devolve um coração", j.vida == Jogador.VIDA_MAX and m.hud._coracoes[2].cheio) and ok

	# Bolota acordada vem e, encostando, tira um coração.
	var b1 := n.alvos[1] as Bolota
	j.teleportar(b1.global_position + Vector3(2.5, 0.1, 0))
	await m._esperar(1.5)
	ok = m._conferir("a Bolota vem até o Faísca e encostar tira um coração", j.vida == Jogador.VIDA_MAX - 1, "(vida %d)" % j.vida) and ok
	await m._esperar(1.8)

	# Mola: cair em cima joga lá para o alto.
	var mola := n.molas[0]
	j.teleportar(mola.global_position + Vector3(0, 2.0, 0))
	var altura: float = await m._altura_maxima(1.4)
	ok = m._conferir("a mola joga para o alto", altura > mola.global_position.y + 4.0, "(%.1f m acima)" % (altura - mola.global_position.y)) and ok

	# Dica do Vovô Farol na beira da Ilha Alta.
	j.teleportar(Vector3(0, 6.1, -66.0))
	await m._esperar(0.3)
	ok = m._conferir("na beira da Ilha Alta o Vovô Farol mostra a dica de flutuar", m.hud.dica_atual == "flutuar") and ok

	# Travessias de verdade, com o controle simulado.
	var chegou := await _travessia(Vector3(0.5, 0.1, -32.4), -35.1, true)
	ok = m._conferir("o último pulo da ponte passa segurando A", chegou.y > 1.3 and chegou.z < -37.4, "(%.1f, %.1f)" % [chegou.y, chegou.z]) and ok
	chegou = await _travessia(Vector3(0, 6.1, -63.0), -67.3, true)
	ok = m._conferir("o vão grande passa flutuando", chegou.y > 4.3 and chegou.z < -76.0, "(%.1f, %.1f)" % [chegou.y, chegou.z]) and ok
	chegou = await _travessia(Vector3(0, 6.1, -63.0), -67.3, false)
	ok = m._conferir("sem flutuar, o vão grande não passa", not (chegou.y > 4.3 and chegou.z < -76.0), "(%.1f, %.1f)" % [chegou.y, chegou.z]) and ok
	j.vida = Jogador.VIDA_MAX
	await m._esperar(1.8)


	# Flores de luz: flutuar em cima acende; com as três, o portão abre. As Bolotas do jardim
	# dormem no teste, para não entrarem embaixo do laser.
	for b in n.alvos.slice(4, 6):
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
	ok = m._conferir("com as três acesas o portão abre", n.portao_aberto(n.portoes[0]) and not n.portoes[0].visible) and ok

	# Plataforma que se mexe leva o Faísca.
	var mv := n.moveis[1]
	j.teleportar(mv.global_position + Vector3(0, 1.2, 0))
	await m._esperar(0.4)
	var x0 := j.global_position.x
	var mx0 := mv.global_position.x
	await m._esperar(0.8)
	ok = m._conferir("a plataforma que se mexe leva o Faísca", j.is_on_floor() and absf((j.global_position.x - x0) - (mv.global_position.x - mx0)) < 0.3
			and absf(mv.global_position.x - mx0) > 0.3) and ok

	# Sem corações: curto e volta no posto com os 3.
	await m._esperar(1.0)
	j.vida = 1
	j.receber_dano(j.global_position + Vector3(1, 0, 0))
	var no_curto := not j.controle_ligado
	await m._esperar(2.0)
	ok = m._conferir("sem corações dá um curto e volta no posto com os 3", no_curto and j.vida == Jogador.VIDA_MAX and j.controle_ligado
			and j.global_position.distance_to(j.ponto_retorno) < 1.5) and ok

	# Baú: as Bolotas de guarda ficam dormindo para o teste; três golpes abrem.
	for b in n.alvos.slice(6):
		(b as Bolota).dormindo = true
	var bau := n.bau
	j.teleportar(bau.global_position + Vector3(0, 0.1, 2.6))
	j.visual.rotation.y = PI
	await m._esperar(0.4)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.5)
	ok = m._conferir("três golpes abrem o baú", bau.derrotado and bau.estrela != null, "(%d golpes)" % bau.golpes) and ok

	# Estrela Grande: pegar termina a fase com a tela de fim; A pede para jogar de novo.
	# A estrela para na frente do baú: chegar perto já encosta nela.
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


## Corre para a frente a partir de `de` e pula quando passa de `beira_z`, segurando A até
## pousar (ou só um toque). Devolve onde parou.
func _travessia(de: Vector3, beira_z: float, segurar: bool) -> Vector3:
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
		if pulou >= 0 and i - pulou > 12 and (j.is_on_floor() or j.global_position.y < j.limite_queda + 2.0):
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	var onde := j.global_position
	await m._esperar(0.2)
	return onde


## Fotos de cada trecho (precisa de janela).
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "fase/"))
	m._comecar_fase()
	await m._esperar(1.0)
	await m._foto("fase/01_descendo")
	await m._esperar(3.0)
	j.yaw = 0.35
	j.pitch = -0.28
	await m._esperar(0.4)
	await m._foto("fase/02_comeco")
	await _foto_em(Vector3(1.0, 0.1, -19.5), 0.0, -0.3, "fase/03_ponte")
	await _foto_em(Vector3(-3.6, 1.9, -44.0), -0.25, -0.3, "fase/04_ilha_das_molas")
	j.teleportar(n.molas[0].global_position + Vector3(0, 1.6, 0))
	j.yaw = 0.3
	j.pitch = -0.1
	await m._esperar(0.55)
	await m._foto("fase/05_mola")
	await _foto_em(Vector3(-1.0, 6.1, -60.4), 0.6, -0.15, "fase/06_ilha_alta")
	j.teleportar(Vector3(0, 7.6, -69.5))
	j.yaw = 0.0
	j.pitch = -0.35
	j.forcar_direcao = Vector2(0, -1)
	j.forcar_pulo = true
	await m._esperar(0.55)
	await m._foto("fase/07_vao_grande")
	j.forcar_pulo = false
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(1.0)
	j.teleportar(n.flores[0].global_position + Vector3(0, 3.0, 2.0))
	j.yaw = 0.0
	j.pitch = -0.45
	j.forcar_pulo = true
	await m._esperar(0.6)
	await m._foto("fase/08_jardim_de_luz")
	j.forcar_pulo = false
	for f in n.flores:
		f.acender()
	await m._esperar(2.0)
	await _foto_em(Vector3(0, 4.6, -79.5), 0.0, -0.25, "fase/09_portao_aberto")
	await _foto_em(n.moveis[0].global_position + Vector3(0, 1.2, 1.0), -0.2, -0.3, "fase/10_plataformas")
	await _foto_em(Vector3(1.0, 9.1, -119.5), 0.15, -0.3, "fase/11_ilha_do_bau")
	for b in n.alvos.slice(6):
		(b as Bolota).dormindo = true
	j.teleportar(n.bau.global_position + Vector3(0, 0.1, 2.6))
	j.visual.rotation.y = PI
	j.yaw = 0.5
	await m._esperar(0.4)
	for i in 3:
		j.forcar_golpe = true
		await m._esperar(0.5)
	await m._esperar(1.2)
	await m._foto("fase/12_estrela_grande")
	j.teleportar(n.bau.global_position + Vector3(0, 0.1, 2.6))
	j.forcar_pulo = true
	await m._esperar(0.3)
	j.forcar_pulo = false
	await m._esperar(1.4)
	await m._foto("fase/13_comemorando")
	await m._esperar(2.6)
	await m._foto("fase/14_fim")
	m.get_tree().quit()


func _foto_em(pos: Vector3, yaw: float, pitch: float, nome: String) -> void:
	j.teleportar(pos)
	j.yaw = yaw
	j.pitch = pitch
	j.visual.rotation.y = yaw + PI
	await m._esperar(0.8)
	await m._foto(nome)
