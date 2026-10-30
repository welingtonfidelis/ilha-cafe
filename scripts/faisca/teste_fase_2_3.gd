class_name TesteFase23
extends RefCounted
## Testes da 2-3 Quarto de Brinquedos (feita em 2026-10-30), chamados pelo FaiscaSolo:
##   --faisca-fase-2-3           confere a fase de ponta a ponta: contagens, o padrão de playgrounds (o brilho do
##                               baú à vista de cada entrada), o tapete (o dado que vira degrau até a estação), o
##                               trenzinho, a escada de livros, os três dados do tabuleiro e o avião, a escrivaninha
##                               (o ioiô, a torre de livros, a prateleira do V2, o abajur), o carrinho, o chão que é
##                               lava (cair, a carta que vira, o dado que rola, as alavancas e a ponte levadiça), o
##                               pátio (o dado, a escada de blocos, as argolas até a torre), o bloco rachado com o V3 e
##                               o baú no alto da torre
##   --faisca-fase-2-3-captura   fotos de cada playground em tools/capturas/faisca/fase_2_3/ (precisa de janela)

var m: Node
var n: Fase23
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
			and n.alvos.size() == 15 and n.coracoes.size() == 4 and n.bau != null, "(%d postos, %d Bolotas)" % [n.postos.size(), n.alvos.size()]) and ok
	ok = m._conferir("peças: 6 dados que tombam, 1 que rola, 7 argolas do ioiô, 3 cartas, 3 caronas, 3 alavancas e a ponte levadiça",
			n.dados.size() == 6 and n.dados_rolando.size() == 1 and n.argolas_ioio.size() == 7 and n.cartas.size() == 3
			and n.caronas.size() == 3 and n.alavancas.size() == 3 and n.ponte != null) and ok

	await m.get_tree().physics_frame
	var espaco := j.get_world_3d().direct_space_state
	ok = m._conferir("5 playgrounds e 4 arcos de saída", n.playgrounds.size() == 5 and n.saidas.size() == 4) and ok
	var cegos := n.playgrounds.filter(func(p: Dictionary) -> bool:
		return not espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p.entrada + Vector3.UP * 2.0, n.brilho_do_marco, 1)).is_empty())
	ok = m._conferir("da entrada de cada playground dá para ver o brilho do baú no alto da torre", cegos.is_empty(),
			"(sem ver: %s)" % ", ".join(cegos.map(func(p: Dictionary) -> String: return p.nome))) and ok
	var donos := n.vaga_lumes.map(func(v: VagaLume) -> int: return _playground_mais_perto(v.global_position))
	ok = m._conferir("um vaga-lume no bolso do playground 2, do 3 e do 5", donos == [1, 2, 4], "(%s)" % str(donos)) and ok
	ok = m._conferir("a arena fica no alto da torre do castelo: o baú é o ponto mais alto do caminho", n.bau.global_position.y > 21.5
			and Vector2(n.bau.global_position.x - Fase23.CASTELO.x, n.bau.global_position.z - Fase23.CASTELO.z).length() < 3.0) and ok
	for b in n.alvos.slice(1):
		b.process_mode = Node.PROCESS_MODE_DISABLED

	m._comecar_fase()
	await m._esperar(4.0)
	ok = m._conferir("desce flutuando e pisa no tapete da cidade", j.is_on_floor() and j.controle_ligado and absf(j.global_position.y - 0.1) < 0.3
			and j.global_position.distance_to(n.inicio) < 1.0) and ok
	var b0 := n.alvos[0] as Bolota
	j.teleportar(b0.global_position + Vector3(0, 0.1, 1.6))
	j.visual.rotation.y = PI
	await m._esperar(0.3)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.45)
	await m._esperar(0.6)
	ok = m._conferir("a Bolota que dorme no tapete apanha e sai quicando", b0.derrotado) and ok
	ok = await _tapete_e_mesa() and ok
	ok = await _escrivaninha() and ok
	ok = await _lava() and ok
	ok = await _castelo() and ok

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


## Playgrounds 1 e 2: o dado da estação, o trenzinho, a escada de livros, os três dados do tabuleiro e o avião.
func _tapete_e_mesa() -> bool:
	var ok := true
	var d := n.dado_da_estacao
	j.teleportar(d.global_position + Vector3(3.0, -0.8, 1.5))
	await m._esperar(0.4)
	ok = m._conferir("perto do dado o Vovô mostra o soco que tomba", m.hud.dica_atual == "dado") and ok
	var onde := await _pular_para(Vector3(-22.5, 0.2, 44), Vector3(-27, 3.4, 44))
	ok = m._conferir("sem o dado, a estação é alta demais para um pulo", onde.y < 1.0, "(altura %.1f)" % onde.y) and ok
	var x0 := d.global_position.x
	await _socar_dado(d, Vector3(-1, 0, 0), 1)
	ok = m._conferir("um soco tomba o dado um lado inteiro para o lado do golpe", absf(d.global_position.x - (x0 - 1.8)) < 0.05
			and absf(d.global_position.y - 1.0) < 0.05, "(x %.2f, y %.2f)" % [d.global_position.x, d.global_position.y]) and ok
	await _socar_dado(d, Vector3(-1, 0, 0), 4)
	ok = m._conferir("tombado até a estação, ele para encostado (o quinto soco só balança)", absf(d.global_position.x + 23.1) < 0.05,
			"(x %.2f)" % d.global_position.x) and ok
	onde = await _pular_para(Vector3(-20.5, 0.2, 44), d.global_position + Vector3(0, 0.9, 0))
	ok = m._conferir("dá para subir no dado com um pulo", absf(onde.y - 1.9) < 0.3, "(altura %.1f)" % onde.y) and ok
	onde = await _pular_para(onde + Vector3(0, 0.1, 0), Vector3(-27, 3.4, 44))
	ok = m._conferir("e do dado para a estação do trenzinho", absf(onde.y - 3.4) < 0.3, "(altura %.1f)" % onde.y) and ok

	var trem := n.trem
	j.teleportar(trem.global_position + Vector3(0, 0.3, 0))
	await m._esperar(1.0)
	ok = m._conferir("o trenzinho sai quando o Faísca sobe no vagão", trem.estado == "indo") and ok
	while trem.estado == "indo":
		await m.get_tree().physics_frame
	ok = m._conferir("e o leva pela ponte de blocos até o pé da mesa", trem.estado == "em_ate" and j.is_on_floor()
			and j.global_position.distance_to(trem.ate) < 2.0, "(%.1f m)" % j.global_position.distance_to(trem.ate)) and ok
	var de := Vector3(-58, 0.1, 23.5)
	for k in 4:
		onde = await _pular_para(de, Vector3(-58, 1.5 * (k + 1), 20.0 - 3.0 * k))
		de = onde + Vector3(0, 0.1, 0)
	ok = m._conferir("a escada de livros sobe do chão até a mesa", absf(onde.y - 6.0) < 0.3, "(altura %.1f)" % onde.y) and ok
	j.teleportar(n.postos[0].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P1 acende no tabuleiro", n.postos[0].acendido) and ok

	ok = m._conferir("antes dos dados, o avião de papel não está lá", not n.aviao_chegou and not n.aviao.visible) and ok
	var dirs := [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, -1)]
	var vezes := [4, 4, 2]
	for i in 3:
		await _socar_dado(n.dados_do_tabuleiro[i], dirs[i], vezes[i])
	var travados := n.dados_do_tabuleiro.filter(func(x: DadoQueTomba) -> bool: return x.travado).size()
	ok = m._conferir("tombados até as casas brilhantes, os três dados travam no lugar", travados == 3, "(%d travados)" % travados) and ok
	ok = m._conferir("e o avião de papel aparece na beira da mesa", n.aviao_chegou and n.aviao.visible) and ok
	var dc := n.dados_do_tabuleiro[0]
	await _socar_dado(dc, Vector3(0, 0, -1), 1)
	ok = m._conferir("dado travado não tomba mais", absf(dc.global_position.z - n.casas_do_tabuleiro[0].z) < 0.05) and ok

	# Dado que cai da mesa volta para a casa dele (o teste usa o dado da torre de blocos, posto na beira da mesa).
	var solto := n.dados[1]
	var casa := solto.casa
	solto.global_position = Vector3(-39.5, 7.2, 2.0)
	solto.casa = Vector3(-44, 7.2, 2.0)
	solto.tombar(Vector3(1, 0, 0))
	await m._esperar(2.0)
	ok = m._conferir("dado que tomba para fora da mesa cai e volta para a casa dele", solto.global_position.distance_to(solto.casa) < 0.1,
			"(%.1f m da casa)" % solto.global_position.distance_to(solto.casa)) and ok
	solto.casa = casa
	solto.voltar_para_casa()

	var aviao := n.aviao
	j.teleportar(aviao.global_position + Vector3(0, 0.3, 0))
	await m._esperar(1.0)
	ok = m._conferir("o avião sai quando o Faísca sobe nele", aviao.estado == "indo") and ok
	while aviao.estado == "indo":
		await m.get_tree().physics_frame
	ok = m._conferir("e plana até a escrivaninha", aviao.estado == "em_ate" and j.is_on_floor() and j.global_position.distance_to(aviao.ate) < 2.0,
			"(%.1f m)" % j.global_position.distance_to(aviao.ate)) and ok
	j.teleportar(n.vaga_lumes[0].global_position - Vector3(0, 0.8, 0))
	await m._esperar(0.3)
	ok = m._conferir("o V1 está embaixo da mesa", n.achados == 1) and ok
	return ok


## Playground 3 e o carrinho: o P2, o giro sem ioiô, a caixa de brinquedos, a torre de livros, a prateleira, o abajur.
func _escrivaninha() -> bool:
	var ok := true
	var e := Fase23.TOPO_ESCRIVANINHA
	j.teleportar(n.postos[1].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P2 acende na escrivaninha", n.postos[1].acendido) and ok
	var onde := await _ioio_para(Vector3(-1, e + 0.1, -56), 1, Vector3(7, 20, -56))
	ok = m._conferir("sem o ioiô, o golpe no ar é o giro e a torre de livros fica alta demais", onde.y < e + 1.0, "(altura %.1f)" % onde.y) and ok
	j.teleportar(n._bola_de_ioio.global_position)
	await m._esperar(0.4)
	ok = m._conferir("a caixa de brinquedos dá o ioiô e o Vovô mostra como usa", n.ioio_pego and j.ioio and m.hud.dica_atual == "ioio") and ok
	var argola := n.argolas_ioio[0]
	j.teleportar(Vector3(-1, e + 0.1, -56))
	await m._esperar(0.4)
	ok = m._conferir("com o ioiô por perto, a argola laranja acende", argola.acesa) and ok
	onde = await _ioio_para(Vector3(-1, e + 0.1, -56), 1, Vector3(7, 20, -56))
	ok = m._conferir("no ar, o golpe joga o ioiô na argola e puxa o Faísca até a torre de livros", absf(onde.y - 20.0) < 0.3,
			"(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	onde = await _ioio_para(Vector3(-28, e + 0.1, -71.5), 3, Vector3(-12, 28.6, -81))
	ok = m._conferir("três argolas em fila levam à prateleira alta", absf(onde.y - 28.6) < 0.3, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	j.teleportar(n.vaga_lumes[1].global_position - Vector3(0, 0.8, 0))
	await m._esperar(0.3)
	ok = m._conferir("o V2 está na prateleira", n.achados == 2) and ok
	onde = await _ioio_para(Vector3(-7.5, e + 4.9, -66), 1, Vector3(0.5, e + 9.45, -66))
	ok = m._conferir("da escadinha de livros, a argola leva ao topo do abajur", absf(onde.y - (e + 9.45)) < 0.3, "(altura %.1f)" % onde.y) and ok

	var c := n.carrinho_de_corda
	j.teleportar(c.global_position + Vector3(0, 0.3, 0))
	await m._esperar(1.0)
	ok = m._conferir("o carrinho de corda sai quando o Faísca entra", c.estado == "indo") and ok
	while c.estado == "indo":
		await m.get_tree().physics_frame
	ok = m._conferir("e desce pela pista laranja até a almofada", c.estado == "em_ate" and j.is_on_floor() and j.global_position.distance_to(c.ate) < 2.0,
			"(%.1f m)" % j.global_position.distance_to(c.ate)) and ok
	return ok


## Playground 4: o P3, a lava, a carta que vira, o dado que rola, as alavancas e a ponte levadiça.
func _lava() -> bool:
	var ok := true
	var p3 := n.postos[2]
	j.teleportar(p3.global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P3 acende na primeira almofada", p3.acendido) and ok
	j.vida = Jogador.VIDA_MAX
	j.teleportar(Vector3(50, 0.3, -40))
	await m._esperar(0.6)
	ok = m._conferir("encostar no tapete de lava é cair: perde um coração e volta no P3", j.vida == Jogador.VIDA_MAX - 1
			and j.global_position.distance_to(p3.ponto()) < 1.5, "(vida %d)" % j.vida) and ok
	j.vida = Jogador.VIDA_MAX
	await m._esperar(1.8)
	var carta := n.cartas[0]
	var giro := carta.rotation.z
	var virou := false
	for i in int(4.5 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		virou = virou or carta.fase_do_ciclo() == "vira"
	ok = m._conferir("a carta treme e vira de ponta-cabeça sozinha", virou and absf(absf(angle_difference(carta.rotation.z, giro)) - PI) < 0.05,
			"(%.2f para %.2f)" % [giro, carta.rotation.z]) and ok
	var r := n.dados_rolando[0]
	while r.progresso() > 0.02:
		await m.get_tree().physics_frame
	j.teleportar(r.global_position + Vector3(0, 1.4, 0))
	var x0 := j.global_position.x
	await m._esperar(2.5)
	ok = m._conferir("o dado que rola leva o Faísca em cima dele", j.is_on_floor() and j.global_position.x > x0 + 3.0 and j.global_position.y > 2.5,
			"(%.1f m)" % (j.global_position.x - x0)) and ok

	ok = m._conferir("com as alavancas em pé, a ponte levadiça tapa o portão", not n.ponte.abaixada) and ok
	for a in n.alavancas:
		j.teleportar(a.global_position + Vector3(-1.6, 0.1, 0))
		j.visual.rotation.y = PI / 2.0
		await m._esperar(0.3)
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.6)
	ok = m._conferir("um soco em cada uma das três alavancas", n.alavancas.all(func(a: Alavanca) -> bool: return a.puxada_ja)) and ok
	await m._esperar(2.4)
	ok = m._conferir("e a ponte levadiça abaixa até a última almofada", n.ponte.no_lugar()) and ok
	return ok


## Playground 5: a ponte, o P4, o dado do pátio, a escada de blocos, as argolas até a torre e o bloco rachado.
func _castelo() -> bool:
	var ok := true
	var c := Fase23.CASTELO
	j.teleportar(Vector3(35, 1.9, -8))
	await _andar(Vector3(-1, 0, 0), 2.2)
	ok = m._conferir("pela ponte levadiça se entra no pátio do castelo", j.is_on_floor() and j.global_position.x < 22.0 and absf(j.global_position.y) < 0.6,
			"(%.1f, %.1f)" % [j.global_position.x, j.global_position.y]) and ok
	j.teleportar(n.postos[3].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P4 acende no pátio", n.postos[3].acendido) and ok
	var d := n.dado_do_patio
	await _socar_dado(d, Vector3(0, 0, -1), 4)
	ok = m._conferir("o dado do pátio, tombado quatro vezes, encosta no primeiro bloco da escada", absf(d.global_position.z - (c.z - 5.6)) < 0.05,
			"(z %.2f)" % d.global_position.z) and ok
	var onde := await _pular_para(d.global_position + Vector3(0, -0.8, 2.2), d.global_position + Vector3(0, 0.9, 0))
	var degraus := [c + Vector3(8, 3.4, -8), c + Vector3(4.5, 5.0, -8), c + Vector3(1, 6.6, -8), c + Vector3(-1, 8.0, -12)]
	for k in degraus.size():
		onde = await _pular_para(onde + Vector3(0, 0.1, 0), degraus[k])
	ok = m._conferir("do dado, a escada de blocos sobe até o alto da muralha", absf(onde.y - 8.0) < 0.3, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	onde = await _ioio_para(c + Vector3(-8, 8.1, -12), 2, c + Vector3(-2, TOPO_TORRE_TESTE, -1))
	ok = m._conferir("do canto da muralha, duas argolas puxam até o alto da torre", absf(onde.y - TOPO_TORRE_TESTE) < 0.3,
			"(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok

	var parede := n.paredes_do_castelo[0]
	var frente := parede.global_basis.z
	j.teleportar(parede.global_position + Vector3(0, 0.1, 4.5))
	await m._esperar(0.4)
	ok = m._conferir("perto do bloco rachado o Vovô mostra o golpe", m.hud.dica_atual == "golpe") and ok
	j.teleportar(parede.global_position + frente * 1.6 + Vector3(0, 0.1, 0))
	j.visual.rotation.y = atan2(-frente.x, -frente.z)
	await m._esperar(0.3)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.5)
	await m._esperar(0.6)
	ok = m._conferir("três golpes quebram o bloco rachado da muralha", parede.derrotado, "(%d golpes)" % parede.golpes) and ok
	await _andar(-frente, 1.0)
	ok = m._conferir("e o V3 está no oco atrás dele", n.achados == 3, "(vaga-lumes %d)" % n.achados) and ok
	return ok


const TOPO_TORRE_TESTE := 22.0


func _playground_mais_perto(p: Vector3) -> int:
	var melhor := 0
	for i in n.playgrounds.size():
		if p.distance_to(n.playgrounds[i].centro) < p.distance_to(n.playgrounds[melhor].centro):
			melhor = i
	return melhor


## Soca o dado `vezes` vezes na direção `dir`, de pé atrás dele (do lado de onde vem o soco).
func _socar_dado(d: DadoQueTomba, dir: Vector3, vezes: int) -> void:
	for i in vezes:
		var chao := d.global_position.y - d.lado * 0.5
		j.teleportar(Vector3(d.global_position.x, chao + 0.1, d.global_position.z) - dir * 2.3)
		j.visual.rotation.y = atan2(dir.x, dir.z)
		j.yaw = atan2(-dir.x, -dir.z)
		await m._esperar(0.25)
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.7)


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


## Do chão em `de`, pula e, no alto do pulo, aperta o golpe `argolas` vezes (uma por argola, emendando no impulso de
## cada uma); depois se guia no ar até em cima de `alvo`, flutuando se precisar. Devolve onde pousou.
func _ioio_para(de: Vector3, argolas: int, alvo: Vector3) -> Vector3:
	j.teleportar(de)
	await m._esperar(0.3)
	j.forcar_pulo = true
	for i in 120:
		await m.get_tree().physics_frame
		if i > 5 and j.velocity.y <= 0.5:
			break
	j.forcar_pulo = false
	for k in argolas:
		j.forcar_golpe = true
		await m.get_tree().physics_frame
		await m.get_tree().physics_frame
		for i in 200:
			if not j.no_ioio:
				break
			await m.get_tree().physics_frame
		if k < argolas - 1:
			for i in 60:
				await m.get_tree().physics_frame
				if j.velocity.y <= 2.0:
					break
	for i in 400:
		await m.get_tree().physics_frame
		var falta := Vector3(alvo.x - j.global_position.x, 0, alvo.z - j.global_position.z)
		if falta.length() > 0.6:
			j.yaw = atan2(-falta.x, -falta.z)
			j.forcar_direcao = Vector2(0, -1)
		else:
			j.forcar_direcao = Vector2.ZERO
		j.forcar_pulo = j.velocity.y < 0.0 and falta.length() > 1.5
		if i > 10 and j.is_on_floor():
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	await m._esperar(0.2)
	return j.global_position


func _andar(dir: Vector3, segundos: float) -> void:
	j.yaw = atan2(-dir.x, -dir.z)
	j.forcar_direcao = Vector2(0, -1)
	await m._esperar(segundos)
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.2)


## Fotos da 2-3 (precisa de janela): de cima, cada playground de cima e de dentro, as viagens e a arena.
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "fase_2_3/"))
	for b in n.alvos:
		(b as Bolota).dormindo = true
		b.process_mode = Node.PROCESS_MODE_DISABLED
	n._chamar_aviao()
	m._comecar_fase()
	await m._esperar(4.0)
	await _foto_de_cima(Vector3(80, 120, 110), Vector3(-10, 4, -6), "fase_2_3/00_visao_geral")
	await _foto_de_cima(Vector3(-80, 90, -80), Vector3(0, 4, 10), "fase_2_3/00b_de_cima_noroeste")
	await _foto_em(n.inicio, 0.5, -0.12, "fase_2_3/01_tapete_da_cidade")
	await _foto_em(Vector3(-12, 0.2, 47), 1.4, -0.1, "fase_2_3/01b_dado_e_estacao")
	await _foto_de_cima(Vector3(-20, 30, 40), Vector3(-56, 6, -4), "fase_2_3/02_tabuleiro_na_mesa")
	await _foto_em(Vector3(-58, 6.4, 4), 0.0, -0.25, "fase_2_3/02b_tabuleiro_de_dentro")
	await _foto_de_cima(Vector3(-10, 44, -20), Vector3(-14, 14, -64), "fase_2_3/03_escrivaninha")
	await _foto_em(Vector3(-32, 12.1, -53), 0.3, -0.05, "fase_2_3/03b_escrivaninha_de_dentro")
	await _foto_de_cima(Vector3(76, 40, 22), Vector3(40, 2, -18), "fase_2_3/04_chao_e_lava")
	await _foto_em(Vector3(40, 1.9, -38), PI, -0.15, "fase_2_3/04b_lava_de_dentro")
	await _foto_de_cima(Vector3(40, 46, 30), Vector3(10, 8, -8), "fase_2_3/05_castelo")
	await _foto_em(Vector3(18, 0.1, 2), 0.0, 0.0, "fase_2_3/05b_patio")
	await _foto_em(Vector3(14, 0.1, 13), 0.0, -0.05, "fase_2_3/05c_bloco_rachado")
	await _foto_em(Vector3(13, 22.1, -3), 0.5, -0.3, "fase_2_3/06_arena")
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
