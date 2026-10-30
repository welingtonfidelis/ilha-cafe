class_name TesteFase12
extends RefCounted
## Testes da 1-2 Túneis do Morro (refeita em playgrounds em 2026-10-29), chamados pelo FaiscaSolo:
##   --faisca-fase-1-2           confere a fase de ponta a ponta: contagens, o padrão de playgrounds (o brilho do
##                               baú à vista de cada entrada), descida, a porta das três tochas (subindo nos
##                               caixotes de verdade), o carrinho na rampa, a mina (queda, ponte da tocha, tablados,
##                               mola da beiradinha, parede rachada do V1), o elevador, as alavancas (subindo no
##                               caixote), a sala escura, a balsa, os cristais até a arena (pulando de verdade), a
##                               parede rachada do V3, a Bolotona, o baú dourado e a tela de fim
##   --faisca-fase-1-2-captura   fotos de cada playground em tools/capturas/faisca/fase_1_2/ (precisa de janela)
## Usa as ajudas do FaiscaSolo (_esperar, _botao, _toque, _conferir, _foto).

var m: Node
var n: Fase12
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
	ok = m._conferir("de 75 a 110 estrelinhas no caminho e nos bolsos (fora as das Bolotas)", n.estrelas.size() >= 75 and n.estrelas.size() <= 110,
			"(%d soltas, %d com as das Bolotas)" % [n.estrelas.size(), total]) and ok
	var acesas := n.tochas.filter(func(t: Tocha) -> bool: return t.esta_acesa).size()
	ok = m._conferir("3 postos, 3 vaga-lumes, 19 tochas (12 já acesas), 2 paredes rachadas, 1 ponte e 1 porta das tochas",
			n.postos.size() == 3 and n.vaga_lumes.size() == 3 and n.tochas.size() == 19 and acesas == 12 and n.paredes_rachadas.size() == 2
			and n.pontes.size() == 1 and n.portas_das_tochas.size() == 1, "(%d postos, %d tochas, %d acesas)" % [n.postos.size(), n.tochas.size(), acesas]) and ok
	ok = m._conferir("13 Bolotas (com a Bolotona e as 3 filhas) e o baú dourado", n.alvos.size() == 13 and n.bau != null and n.bau.dourado,
			"(%d)" % n.alvos.size()) and ok
	ok = m._conferir("peças: carrinho, 3 alavancas com grade (e a da arena), 3 cristais, a Bolotona, o elevador e a balsa", n.carrinhos.size() == 1
			and n.alavancas.size() == 3 and n.grades.size() == 4 and n.cristais.size() == 3 and n.bolotonas.size() == 1 and n.moveis.size() == 2) and ok

	# O padrão de playgrounds: quatro salas em volta do Poço do Cristal, uma saída em cada uma das três primeiras, o
	# brilho do baú à vista de todas as entradas e um vaga-lume no bolso de cada uma das três últimas.
	await m.get_tree().physics_frame
	var espaco := j.get_world_3d().direct_space_state
	ok = m._conferir("4 playgrounds e 3 saídas (a porta das tochas, o elevador e a grade amarela)", n.playgrounds.size() == 4 and n.saidas.size() == 3) and ok
	var cegos := n.playgrounds.filter(func(p: Dictionary) -> bool:
		return not espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p.entrada + Vector3.UP * 2.0, n.brilho_do_marco, 1)).is_empty())
	ok = m._conferir("da entrada de cada playground dá para ver o brilho do baú no alto do cristal", cegos.is_empty(),
			"(sem ver: %s)" % ", ".join(cegos.map(func(p: Dictionary) -> String: return p.nome))) and ok
	var donos := n.vaga_lumes.map(func(v: VagaLume) -> int: return _playground_mais_perto(v.global_position))
	ok = m._conferir("um vaga-lume no bolso de cada playground: o 2, o 3 e o 4", donos == [1, 2, 3], "(%s)" % str(donos)) and ok
	ok = m._conferir("a arena fica no alto do cristal: o baú é o ponto mais alto do caminho", n.bau.global_position.y > 29.0
			and Vector2(n.bau.global_position.x, n.bau.global_position.z + 66.0).length() < 14.0) and ok
	# As Bolotas ficam paradas no teste (a 1-1 já confere o jeito delas), menos a primeira, que dorme.
	for b in n.alvos.slice(1):
		b.process_mode = Node.PROCESS_MODE_DISABLED

	m._comecar_fase()
	await m._esperar(4.0)
	ok = m._conferir("desce flutuando e pisa na entrada do Salão das Tochas", j.is_on_floor() and j.controle_ligado
			and j.global_position.distance_to(n.inicio) < 1.0, "(%.1f m)" % j.global_position.distance_to(n.inicio)) and ok
	var b0 := n.alvos[0] as Bolota
	j.teleportar(b0.global_position + Vector3(0, 0.1, 1.6))
	j.visual.rotation.y = PI
	await m._esperar(0.3)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.45)
	await m._esperar(0.6)
	ok = m._conferir("a Bolota que dorme no salão apanha e sai quicando", b0.derrotado) and ok
	ok = await _salao_das_tochas() and ok
	ok = await _carrinho() and ok
	ok = await _mina_de_ouro() and ok
	ok = await _elevador_e_alavancas() and ok
	ok = await _balsa_e_cristais() and ok
	ok = await _bolotona() and ok

	# Baú dourado: três golpes, a Estrela Grande e a tela de fim.
	var bau := n.bau
	j.teleportar(bau.global_position + Vector3(0, 0.1, 2.8))
	j.visual.rotation.y = PI
	await m._esperar(0.4)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.5)
	ok = m._conferir("três golpes abrem o baú dourado", bau.derrotado and bau.estrela != null, "(%d golpes)" % bau.golpes) and ok
	await m._esperar(1.2)
	j.teleportar(bau.global_position + Vector3(0, 0.1, 2.4))
	await m._esperar(3.6)
	ok = m._conferir("pegar a Estrela Grande mostra a tela de fim", m.hud.fim_aberto and not j.controle_ligado) and ok
	m._terminar(ok)


## Playground 1: a dica da tocha, a porta fechada, duas tochas pelo chão e a terceira em cima dos caixotes.
func _salao_das_tochas() -> bool:
	var ok := true
	j.teleportar(Vector3(-6.0, 0.1, -22.0))
	await m._esperar(0.4)
	ok = m._conferir("o Vovô Farol mostra a dica da tocha", m.hud.dica_atual == "tocha") and ok
	var porta: Dictionary = n.portas_das_tochas[0]
	var da_porta: Array = porta.tochas
	var ta: Tocha = da_porta[0]
	ok = m._conferir("a tocha começa apagada e sem luz", not ta.esta_acesa and not ta._luz.visible) and ok
	j.teleportar(Vector3(-15.0, 0.1, -27.0))
	await _andar(Vector3(-1, 0, 0), 1.0)
	ok = m._conferir("com a porta fechada não se passa", j.global_position.x > -18.6, "(x %.1f)" % j.global_position.x) and ok
	await _acender_com_laser(ta, Vector3(0.6, 0, 0))
	await _acender_com_laser(da_porta[1], Vector3.ZERO)
	ok = m._conferir("o laser acende duas; com duas das três acesas a porta continua fechada", ta.esta_acesa and da_porta[1].esta_acesa
			and not porta.aberta) and ok
	var onde := await _pular(Vector3(-9.0, 0.1, -40.0), Vector3(-1, 0, 0), 1.2, false)
	ok = m._conferir("pula no caixote baixo", absf(onde.y - 1.6) < 0.4, "(altura %.1f)" % onde.y) and ok
	onde = await _pular(Vector3(-11.4, 1.7, -40.0), Vector3(-1, 0, 0), 0.05, false)
	ok = m._conferir("e dele no caixote alto, onde está a última tocha", absf(onde.y - 3.0) < 0.4, "(altura %.1f)" % onde.y) and ok
	var tc: Tocha = da_porta[2]
	j.teleportar(tc.global_position + Vector3(0.9, 0.1, 0.4))
	await m._esperar(0.3)
	j.forcar_pulo = true
	await m._esperar(1.4)
	j.forcar_pulo = false
	await m._esperar(1.6)
	ok = m._conferir("pulando e flutuando em cima do caixote acende a tocha, e as três abrem a porta", tc.esta_acesa and porta.aberta) and ok
	j.teleportar(Vector3(-15.0, 0.1, -27.0))
	await _andar(Vector3(-1, 0, 0), 1.0)
	ok = m._conferir("com a porta aberta se passa para a estação do carrinho", j.global_position.x < -19.6 and j.is_on_floor(),
			"(x %.1f)" % j.global_position.x) and ok
	return ok


## Viagem 1: o carrinho sobe a rampa com o Faísca dentro, pegando as estrelinhas; ele pula para fora na chegada.
func _carrinho() -> bool:
	var ok := true
	var c := n.carrinhos[0]
	var pegas := n.pegas
	j.teleportar(c.global_position + Vector3(0, 1.0, 0))
	await m._esperar(0.8)
	ok = m._conferir("pulando dentro, o carrinho sai sozinho", c.estado == "indo") and ok
	var dentro := true
	while c.estado == "indo":
		await m.get_tree().physics_frame
		dentro = dentro and j.global_position.distance_to(c.global_position) < 2.5
	await m._esperar(0.3)
	ok = m._conferir("o carrinho sobe a rampa até a mina (8 m), pegando as estrelinhas", c.estado == "chegou" and dentro
			and c.global_position.distance_to(c.ate) < 0.1 and n.pegas >= pegas + 4, "(dentro o tempo todo %s, %d estrelinhas)" % [dentro, n.pegas - pegas]) and ok
	j.yaw = 0.0
	j.forcar_direcao = Vector2(0, -1)
	j.forcar_pulo = true
	await m._esperar(0.5)
	j.forcar_pulo = false
	await m._esperar(0.5)
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.6)
	ok = m._conferir("pula para fora do carrinho na plataforma da chegada", j.is_on_floor() and absf(j.global_position.y - 8.0) < 0.3
			and j.global_position.z < -47.0, "(%.1f, %.1f)" % [j.global_position.y, j.global_position.z]) and ok
	j.teleportar(n.postos[0].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P1 acende na chegada da mina", n.postos[0].acendido) and ok
	return ok


## Playground 2: cair no abismo, a ponte da tocha, os tablados, a mola da beiradinha e a parede rachada do V1.
func _mina_de_ouro() -> bool:
	var ok := true
	j.vida = Jogador.VIDA_MAX
	j.teleportar(Vector3(-39.0, 8.6, -60.0))
	await m._esperar(2.5)
	ok = m._conferir("cair no abismo da mina tira um coração e volta no P1", j.vida == Jogador.VIDA_MAX - 1
			and j.global_position.distance_to(n.postos[0].ponto()) < 1.5, "(vida %d)" % j.vida) and ok
	j.vida = Jogador.VIDA_MAX
	var ponte: StaticBody3D = n.pontes[0]
	var t1: Tocha = ponte.get_meta("tocha")
	ok = m._conferir("a ponte começa escondida", not ponte.visible and not n.ponte_no_lugar(ponte)) and ok
	await _acender_com_laser(t1, Vector3.ZERO)
	await m._esperar(1.6)
	ok = m._conferir("acender a tocha da beira sobe a ponte do escuro", t1.esta_acesa and n.ponte_no_lugar(ponte)) and ok
	var chegou := await _pular(Vector3(-39.0, 8.1, -52.0), Vector3(0, 0, -1), 99.0, false, -67.0)
	ok = m._conferir("pela ponte se cruza o abismo", absf(chegou.y - 8.0) < 0.3 and chegou.z < -66.5, "(%.1f, %.1f)" % [chegou.y, chegou.z]) and ok
	# Pela esquerda, os dois tablados, pulando de verdade.
	for d in [[Vector3(-50.0, 8.1, -51.0), -56.0, -59.0, "do chão para o 1º tablado"], [Vector3(-50.0, 8.1, -56.4), -61.0, -64.0, "do 1º para o 2º"],
			[Vector3(-50.0, 8.1, -61.4), -66.0, -84.0, "do 2º para o outro lado"]]:
		var onde := await _pular(d[0], Vector3(0, 0, -1), 2.2, false)
		ok = m._conferir("tablados do abismo: pula %s" % d[3], absf(onde.y - 8.0) < 0.3 and onde.z < d[1] and onde.z > d[2],
				"(%.1f, %.1f)" % [onde.y, onde.z]) and ok
	var mola_v: Area3D = n.molas[0]
	j.teleportar(mola_v.global_position + Vector3(0, 1.5, 0))
	var altura: float = await m._altura_maxima(1.2)
	ok = m._conferir("a mola da beiradinha dentro do abismo volta para cima do chão da mina", altura > 9.5, "(%.1f m)" % altura) and ok
	await m._esperar(1.0)
	# A parede rachada do oeste: três golpes quebram e abrem o nicho do V1.
	var parede: ParedeRachada = n.paredes_rachadas[0]
	j.teleportar(Vector3(-52.2, 8.1, -75.0))
	j.visual.rotation.y = -PI / 2.0
	await m._esperar(0.4)
	ok = m._conferir("perto da parede rachada o Vovô mostra o golpe", m.hud.dica_atual == "golpe") and ok
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.45)
	await m._esperar(0.4)
	ok = m._conferir("três golpes quebram a parede rachada", parede.derrotado and parede.collision_layer == 0, "(%d golpes)" % parede.golpes) and ok
	await _andar(Vector3(-1, 0, 0), 1.2)
	ok = m._conferir("a passagem fica livre e o V1 está no nicho", n.achados == 1 and j.global_position.x < -56.0,
			"(x %.1f, vaga-lumes %d)" % [j.global_position.x, n.achados]) and ok
	return ok


## Viagem 2 e playground 3: o elevador, o P2, as alavancas (a da saída em cima do caixote), a sala escura e o depósito.
func _elevador_e_alavancas() -> bool:
	var ok := true
	var elev: AnimatableBody3D = n.moveis[0]
	while elev.global_position.y > 8.3:
		await m.get_tree().physics_frame
	j.teleportar(elev.global_position + Vector3(0, 0.6, 0))
	while elev.global_position.y < 15.95:
		await m.get_tree().physics_frame
	await m._esperar(0.2)
	ok = m._conferir("o elevador leva o Faísca até a Sala das Alavancas", j.is_on_floor() and j.global_position.y > 15.0, "(altura %.1f)" % j.global_position.y) and ok
	await _andar(Vector3(0, 0, -1), 0.8)
	ok = m._conferir("e dele se desce no patamar", j.is_on_floor() and absf(j.global_position.y - 16.0) < 0.3 and j.global_position.z < -84.0,
			"(%.1f, %.1f)" % [j.global_position.y, j.global_position.z]) and ok
	j.teleportar(n.postos[1].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P2 acende no patamar", n.postos[1].acendido) and ok
	j.teleportar(Vector3(-18.0, 16.1, -94.5))
	await m._esperar(0.4)
	ok = m._conferir("o Vovô mostra a alavanca", m.hud.dica_atual == "alavanca") and ok
	j.teleportar(Vector3(21.5, 16.1, -93.0))
	await _andar(Vector3(1, 0, 0), 1.0)
	ok = m._conferir("com a grade amarela fechada não se sai da sala", j.global_position.x < 24.2, "(x %.1f)" % j.global_position.x) and ok
	var onde := await _pular(Vector3(20.0, 16.1, -96.0), Vector3(0, 0, -1), 1.6, false)
	ok = m._conferir("pula no caixote da alavanca amarela", absf(onde.y - 17.6) < 0.4, "(altura %.1f)" % onde.y) and ok
	for i in n.alavancas.size():
		var a := n.alavancas[i]
		j.teleportar(a.global_position + Vector3(0, 0.1, 1.4))
		j.visual.rotation.y = PI
		await m._esperar(0.3)
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.6)
	await m._esperar(1.4)
	ok = m._conferir("um soco em cada alavanca abre a grade dela", n.alavancas.all(func(a: Alavanca) -> bool: return a.puxada_ja)
			and n.grades.slice(0, 3).all(func(g: Grade) -> bool: return g.aberta)) and ok
	# Sala escura: a luz baixa ao entrar; a tocha da curva acende com o laser; o V2 no fim; ao sair, volta.
	j.teleportar(Vector3(-9.0, 16.1, -123.0))
	await m._esperar(1.2)
	ok = m._conferir("entrando na sala escura a luz da caverna quase apaga", n.escuro and n._ambiente.ambient_light_energy < 0.15) and ok
	var curvas := n.tochas.filter(func(t: Tocha) -> bool: return t.global_position.z < -129.0 and t.global_position.z > -140.0 and t.global_position.x < 0.0)
	await _acender_com_laser(curvas[0], Vector3.ZERO)
	ok = m._conferir("as 3 tochas das curvas da passarela; a primeira acende com o laser", curvas.size() == 3 and curvas[0].esta_acesa) and ok
	j.teleportar(Vector3(-6.0, 16.1, -134.0))
	await m._esperar(0.6)
	ok = m._conferir("a passarela de tábuas segura o Faísca em cima do buraco", j.is_on_floor() and j.global_position.y > 15.8) and ok
	j.teleportar(Vector3(-11.0, 16.1, -138.5))
	await m._esperar(0.6)
	ok = m._conferir("no fim da passarela está o V2", n.achados == 2, "(%d)" % n.achados) and ok
	j.teleportar(Vector3(-9.0, 16.1, -112.0))
	await m._esperar(1.2)
	ok = m._conferir("saindo da sala a luz volta", not n.escuro and n._ambiente.ambient_light_energy > 0.4) and ok
	j.teleportar(Vector3(15.0, 16.1, -118.0))
	await _andar(Vector3(0, 0, -1), 0.9)
	ok = m._conferir("pela grade azul se entra no depósito", j.global_position.z < -123.0, "(z %.1f)" % j.global_position.z) and ok
	j.teleportar(Vector3(21.5, 16.1, -93.0))
	await _andar(Vector3(1, 0, 0), 0.9)
	ok = m._conferir("com a grade amarela aberta se chega à estação da balsa", j.global_position.x > 26.0 and j.is_on_floor(),
			"(x %.1f)" % j.global_position.x) and ok
	return ok


## Viagem 3 e playground 4: a balsa, o P3, a parede rachada do V3 e os três cristais até a arena, pulando de verdade.
func _balsa_e_cristais() -> bool:
	var ok := true
	var balsa: AnimatableBody3D = n.moveis[1]
	while balsa.global_position.z > -87.7:
		await m.get_tree().physics_frame
	j.teleportar(balsa.global_position + Vector3(0, 0.6, 0))
	while balsa.global_position.z < -80.05:
		await m.get_tree().physics_frame
	await m._esperar(0.2)
	await _andar(Vector3(0, 0, 1), 0.8)
	ok = m._conferir("a balsa leva o Faísca até o Poço dos Cristais", j.is_on_floor() and absf(j.global_position.y - 16.0) < 0.3
			and j.global_position.z > -77.5, "(%.1f, %.1f)" % [j.global_position.y, j.global_position.z]) and ok
	j.teleportar(n.postos[2].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P3 acende no Poço dos Cristais", n.postos[2].acendido) and ok
	var parede: ParedeRachada = n.paredes_rachadas[1]
	j.teleportar(Vector3(40.2, 16.1, -63.0))
	j.visual.rotation.y = PI / 2.0
	await m._esperar(0.4)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.45)
	await m._esperar(0.4)
	await _andar(Vector3(1, 0, 0), 1.2)
	ok = m._conferir("três golpes na parede rachada do leste abrem o nicho do V3", parede.derrotado and n.achados == 3 and j.global_position.x > 44.0,
			"(x %.1f, vaga-lumes %d)" % [j.global_position.x, n.achados]) and ok
	var subida := [[0, Vector3(19.5, 21.0, -59.0), "do chão para o 1º tablado"], [1, Vector3(14.0, 25.0, -66.0), "do 1º para o 2º"],
		[2, Vector3(5.0, 30.0, -66.0), "do 2º para a arena no alto do cristal"]]
	for s in subida:
		var onde := await _quicar(n.cristais[s[0]], s[1])
		ok = m._conferir("cristais: quica %s" % s[2], absf(onde.y - (s[1] as Vector3).y) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	return ok


## A Bolotona (que acorda, apanha e vira três) e a grade da alcova do baú.
func _bolotona() -> bool:
	var ok := true
	var grande := n.bolotonas[0]
	grande.process_mode = Node.PROCESS_MODE_INHERIT
	j.vida = Jogador.VIDA_MAX
	j.teleportar(grande.global_position + Vector3(0, 0.1, 2.4))
	j.visual.rotation.y = PI
	await m._esperar(0.4)
	for i in 16:
		if grande.derrotado:
			break
		j.vida = Jogador.VIDA_MAX
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.45)
	await m._esperar(0.4)
	var filhas := grande.filhas
	ok = m._conferir("a Bolotona apanha e se desfaz em três Bolotas", grande.derrotado and filhas.all(func(f: Bolota) -> bool:
			return f.visible and f.process_mode == Node.PROCESS_MODE_INHERIT and not f.derrotado), "(vida %d)" % grande.vida) and ok
	ok = m._conferir("com as filhas ainda de pé, a grade do baú fica fechada", not n.grades[3].aberta) and ok
	# As filhas ficam sem andar (paradas de vez, a imunidade depois de cada golpe não passaria) e o Faísca longe.
	j.teleportar(n.postos[2].ponto())
	for f in filhas:
		f.velocidade = 0.0
		for k in 6:
			f.receber_golpe(1, f.global_position + Vector3(0, 0, 1), 3.0)
			await m._esperar(0.35)
	await m._esperar(0.4)
	ok = m._conferir("vencidas as quatro, a grade abre a alcova do baú", n.bolotona_vencida(grande) and n.grades[3].aberta) and ok
	j.vida = Jogador.VIDA_MAX
	return ok


## Índice do playground com o centro mais perto de `p`.
func _playground_mais_perto(p: Vector3) -> int:
	var melhor := 0
	for i in n.playgrounds.size():
		if p.distance_to(n.playgrounds[i].centro) < p.distance_to(n.playgrounds[melhor].centro):
			melhor = i
	return melhor


## Põe o Faísca em cima do cristal e o guia no ar até em cima de `alvo` (solta o direcional perto). Devolve onde pousou.
func _quicar(cristal: Area3D, alvo: Vector3) -> Vector3:
	j.teleportar(cristal.global_position + Vector3(0, 0.4, 0))
	var subiu := false
	for i in 400:
		await m.get_tree().physics_frame
		var falta := Vector3(alvo.x - j.global_position.x, 0, alvo.z - j.global_position.z)
		if j.global_position.y > cristal.global_position.y + 1.5:
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


## Põe o Faísca em cima da tocha (deslocado `ao_lado`) e segura o pulo, para flutuar com o laser.
func _acender_com_laser(t: Tocha, ao_lado: Vector3) -> void:
	j.teleportar(t.ponto_da_chama() + Vector3(0, 1.1, 0) + ao_lado)
	await m._esperar(0.1)
	j.forcar_pulo = true
	await m._esperar(0.9)
	j.forcar_pulo = false
	await m._esperar(0.8)


## Anda na direção `dir` (no chão) por `segundos`.
func _andar(dir: Vector3, segundos: float) -> void:
	j.yaw = atan2(-dir.x, -dir.z)
	j.forcar_direcao = Vector2(0, -1)
	await m._esperar(segundos)
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.2)


## Corre de `de` na direção `dir` e pula depois de `antes` metros (segurando A até pousar, se `segurar`).
## Com `ate_z`, só corre (sem pular) até passar desse z. Devolve onde parou.
func _pular(de: Vector3, dir: Vector3, antes: float, segurar: bool, ate_z := INF) -> Vector3:
	j.teleportar(de)
	j.yaw = atan2(-dir.x, -dir.z)
	j.visual.rotation.y = j.yaw + PI
	await m._esperar(0.3)
	j.forcar_direcao = Vector2(0, -1)
	var pulou := -1
	for i in 600:
		await m.get_tree().physics_frame
		var andou := (j.global_position - de).dot(dir)
		if ate_z != INF:
			if j.global_position.z < ate_z or j.global_position.y < j.limite_queda + 2.0:
				break
			continue
		if pulou < 0 and andou > antes:
			j.forcar_pulo = true
			pulou = i
		if pulou >= 0 and i - pulou > 12 and (j.is_on_floor() or j.global_position.y < j.limite_queda + 2.0):
			break
		# Sem segurar, solta o botão no alto do pulo (pulo inteiro, sem flutuar).
		if pulou >= 0 and not segurar and i - pulou > 3 and j.velocity.y <= 0.5:
			j.forcar_pulo = false
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	var onde := j.global_position
	await m._esperar(0.2)
	return onde


## Fotos da 1-2 em playgrounds (precisa de janela): de cima, cada playground de dentro, as viagens e a arena.
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "fase_1_2/"))
	# Bolotas paradas (dormindo e sem processar), para não tirarem corações no meio das fotos.
	for b in n.alvos:
		(b as Bolota).dormindo = true
		b.process_mode = Node.PROCESS_MODE_DISABLED
	m._comecar_fase()
	await m._esperar(4.0)
	await _foto_de_cima(Vector3(70, 75, 10), Vector3(0, 10, -70), "fase_1_2/00_visao_geral")
	await _foto_de_cima(Vector3(-10, 60, -150), Vector3(0, 12, -66), "fase_1_2/00b_de_cima_norte")
	await _foto_em(n.inicio, 0.05, -0.12, "fase_1_2/01_salao_das_tochas")
	await _foto_de_cima(Vector3(20, 26, -6), Vector3(-6, 0, -32), "fase_1_2/01b_salao_de_cima")
	await _foto_em(Vector3(-6.0, 0.1, -36.0), 1.2, -0.2, "fase_1_2/01c_caixotes_e_porta")
	for t in n.portas_das_tochas[0].tochas:
		t.acender()
	await m._esperar(2.0)
	await _foto_em(Vector3(-21.0, 0.1, -25.0), 0.0, 0.05, "fase_1_2/02_carrinho_na_rampa")
	await _foto_de_cima(Vector3(-10, 30, -40), Vector3(-39, 6, -64), "fase_1_2/03_mina_de_ouro")
	await _foto_em(Vector3(-37.0, 8.1, -50.0), 0.3, -0.3, "fase_1_2/03b_abismo_da_mina")
	(n.pontes[0].get_meta("tocha") as Tocha).acender()
	await m._esperar(2.0)
	await _foto_em(Vector3(-37.0, 8.1, -50.0), 0.3, -0.3, "fase_1_2/03c_ponte_da_tocha")
	await _foto_de_cima(Vector3(10, 38, -80), Vector3(0, 16, -108), "fase_1_2/04_sala_das_alavancas")
	await _foto_em(Vector3(-20.0, 16.1, -92.0), -1.0, -0.15, "fase_1_2/04b_alavancas_de_dentro")
	for a in n.alavancas:
		a.puxar()
	await m._esperar(1.8)
	await _foto_em(Vector3(-9.0, 16.1, -123.0), 0.3, -0.3, "fase_1_2/04c_sala_escura")
	await _foto_de_cima(Vector3(50, 34, -96), Vector3(30, 18, -66), "fase_1_2/05_poco_dos_cristais")
	await _foto_em(Vector3(30.0, 16.1, -70.0), 2.38, 0.3, "fase_1_2/05b_cristais_de_baixo")
	n.bolotonas[0].process_mode = Node.PROCESS_MODE_INHERIT
	await _foto_em(Vector3(7.0, 30.1, -60.0), 0.6, -0.25, "fase_1_2/06_arena")
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
