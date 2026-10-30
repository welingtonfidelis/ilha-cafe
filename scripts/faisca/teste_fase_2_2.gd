class_name TesteFase22
extends RefCounted
## Testes da 2-2 Nuvens de Algodão-Doce (feita em 2026-10-30), chamados pelo FaiscaSolo:
##   --faisca-fase-2-2           confere a fase de ponta a ponta: contagens, o padrão de playgrounds (o brilho do
##                               baú à vista de cada entrada), o campo (nuvem que quica, pilares e botões, a ponte), a
##                               nuvem-carro, as ilhas de biscoito (quiques sobre o vazio, o V1, as flores e o portão),
##                               o canhão, a praça (a bola de chiclete, o balão até a estação e até o anel do V2), o
##                               teleférico, o Céu de Chiclete (a nuvem que some), a ponte de wafer, a subida do bolo
##                               (cereja, vela, a casinha com o V3, a cereja de volta) e o baú no topo
##   --faisca-fase-2-2-captura   fotos de cada playground em tools/capturas/faisca/fase_2_2/ (precisa de janela)

var m: Node
var n: Fase22
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
	ok = m._conferir("peças: 20 nuvens que quicam (4 somem), 3 botões, 3 flores, o canhão, 2 caronas, 3 cerejas, a vela e a casinha",
			n.nuvens_que_quicam.size() == 20 and n.nuvens_que_quicam.filter(func(x: NuvemQueQuica) -> bool: return x.some).size() == 4
			and n.botoes.size() == 3 and n.flores.size() == 3 and n.canhoes.size() == 1 and n.caronas.size() == 2 and n.cerejas.size() == 3
			and n.velas.size() == 1 and n.paredes_do_bolo.size() == 1) and ok

	# O padrão de playgrounds, já mais longo: cinco em volta do bolo, um arco de saída nos quatro primeiros, o brilho do
	# baú à vista de todas as entradas e um vaga-lume no bolso do 2, do 3 e do 5.
	await m.get_tree().physics_frame
	var espaco := j.get_world_3d().direct_space_state
	ok = m._conferir("5 playgrounds e 4 arcos de saída", n.playgrounds.size() == 5 and n.saidas.size() == 4) and ok
	var cegos := n.playgrounds.filter(func(p: Dictionary) -> bool:
		return not espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p.entrada + Vector3.UP * 2.0, n.brilho_do_marco, 1)).is_empty())
	ok = m._conferir("da entrada de cada playground dá para ver o brilho do baú em cima do bolo", cegos.is_empty(),
			"(sem ver: %s)" % ", ".join(cegos.map(func(p: Dictionary) -> String: return p.nome))) and ok
	var donos := n.vaga_lumes.map(func(v: VagaLume) -> int: return _playground_mais_perto(v.global_position))
	ok = m._conferir("um vaga-lume no bolso do playground 2, do 3 e do 5", donos == [1, 2, 4], "(%s)" % str(donos)) and ok
	ok = m._conferir("a arena fica no topo do bolo: o baú é o ponto mais alto do caminho", n.bau.global_position.y > 39.5
			and Vector2(n.bau.global_position.x, n.bau.global_position.z).length() < 4.0) and ok
	# As Bolotas ficam paradas no teste (a 1-1 já confere o jeito delas), menos a primeira, que dorme.
	for b in n.alvos.slice(1):
		b.process_mode = Node.PROCESS_MODE_DISABLED

	m._comecar_fase()
	await m._esperar(4.0)
	ok = m._conferir("desce flutuando e pisa no campo de algodão", j.is_on_floor() and j.controle_ligado and absf(j.global_position.y) < 0.3
			and j.global_position.distance_to(n.inicio) < 1.0) and ok
	var b0 := n.alvos[0] as Bolota
	j.teleportar(b0.global_position + Vector3(0, 0.1, 1.6))
	j.visual.rotation.y = PI
	await m._esperar(0.3)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.45)
	await m._esperar(0.6)
	ok = m._conferir("a Bolota que dorme no campo apanha e sai quicando", b0.derrotado) and ok
	ok = await _campo() and ok
	ok = await _ilhas() and ok
	ok = await _praca() and ok
	ok = await _ceu_e_bolo() and ok

	# Baú no topo do bolo, a Estrela Grande e a tela de fim.
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


## Playground 1 e a nuvem-carro: a nuvem que quica, os três pilares com os botões, a ponte e a viagem.
func _campo() -> bool:
	var ok := true
	j.teleportar(Vector3(7, 0.1, 120.5))
	await m._esperar(0.4)
	ok = m._conferir("perto da primeira nuvem o Vovô mostra o quique", m.hud.dica_atual == "quicar") and ok
	var primeira := n.nuvens_que_quicam[0]
	j.teleportar(primeira.global_position + Vector3(0, 0.6, 0))
	var altura: float = await m._altura_maxima(1.6)
	ok = m._conferir("a nuvem que quica joga o Faísca uns 5 m para o alto", altura > primeira.global_position.y + 4.3,
			"(%.1f m acima)" % (altura - primeira.global_position.y)) and ok
	await m._esperar(0.8)
	ok = m._conferir("antes dos botões, a ponte até a nuvem-carro não existe", not n.ponte_dos_botoes_pronta()) and ok
	var pilares := [Vector3(-18, 4.5, 116), Vector3(0, 4.5, 88), Vector3(18, 4.5, 104)]
	for i in 3:
		var onde := await _quicar(n.nuvens_que_quicam[1 + i], pilares[i] + Vector3(0.9, 0, 0.9))
		ok = m._conferir("quicando na nuvem do lado, o Faísca pousa no pilar %d e aperta o botão" % (i + 1), absf(onde.y - 4.5) < 0.4
				and n.botoes[i].esta_apertado, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	await m._esperar(2.0)
	ok = m._conferir("com os três botões a ponte sobe", n.ponte_dos_botoes_pronta()) and ok
	var onde := await _pular_para(Vector3(-27.5, 0.1, 95.5), Vector3(-31, 0, 94.5))
	ok = m._conferir("da beira do campo se pula na ponte", absf(onde.y) < 0.3, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	var morro := await _quicar(n.nuvens_que_quicam[4], Vector3(14, 5.5, 90))
	ok = m._conferir("a nuvem forte leva ao bolso do morro de algodão", absf(morro.y - 5.5) < 0.4, "(altura %.1f)" % morro.y) and ok

	var nc := n.nuvem_carro
	j.teleportar(nc.global_position + Vector3(0, 0.3, 0))
	await m._esperar(1.0)
	ok = m._conferir("a nuvem-carro sai quando o Faísca sobe nela", nc.estado == "indo") and ok
	while nc.estado == "indo":
		await m.get_tree().physics_frame
	ok = m._conferir("e o leva até a primeira ilha de biscoito", nc.estado == "em_ate" and j.is_on_floor()
			and j.global_position.distance_to(nc.ate) < 2.0, "(%.1f m)" % j.global_position.distance_to(nc.ate)) and ok
	await _andar(Vector3(-70, 0, 56) - Vector3(nc.ate.x, 0, nc.ate.z), 1.2)
	ok = m._conferir("na chegada o Vovô mostra o laser", m.hud.dica_atual == "laser") and ok
	j.teleportar(n.postos[0].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P1 acende na primeira ilha de biscoito", n.postos[0].acendido) and ok
	return ok


## Playground 2 e o canhão: os quiques sobre o vazio, o V1, as flores, o portão e o canhão.
func _ilhas() -> bool:
	var ok := true
	var onde := await _quicar(n.nuvens_que_quicam[5], Vector3(-86, 9, 64))
	ok = m._conferir("da chegada, a nuvem sobre o vazio leva à ilha da direita", absf(onde.y - 9.0) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	onde = await _quicar(n.nuvens_que_quicam[13], Vector3(-103, 14, 17))
	ok = m._conferir("e a última nuvem do meio leva à ilha do alto", absf(onde.y - 14.0) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	j.teleportar(n.vaga_lumes[0].global_position - Vector3(0, 0.8, 0))
	await m._esperar(0.3)
	ok = m._conferir("o V1 está na beirada embaixo da ilha do meio", n.achados == 1) and ok
	onde = await _quicar(n.nuvens_que_quicam[15], Vector3(-100.5, 10, 45))
	ok = m._conferir("e a nuvem da beirada devolve para a ilha do meio", absf(onde.y - 10.0) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok

	ok = m._conferir("antes das flores, o portão do canhão está fechado", not n.portao_aberto(n.portoes[0])) and ok
	for f in n.flores:
		j.teleportar(f.global_position + Vector3(0, 3.2, 0))
		await m._esperar(0.15)
		j.forcar_pulo = true
		await m._esperar(0.7)
		j.forcar_pulo = false
		await m._esperar(0.6)
	var acesas := n.flores.filter(func(f: FlorDeLuz) -> bool: return f.esta_acesa).size()
	ok = m._conferir("o laser acende as três flores, uma em cada ponta das ilhas", acesas == 3) and ok
	await m._esperar(1.6)
	ok = m._conferir("com as três acesas o portão do canhão abre", n.portao_aberto(n.portoes[0]) and not n.portoes[0].visible) and ok

	var c := n.canhoes[0]
	j.teleportar(c.global_position + Vector3(0, 0.8, 0.6))
	await m._esperar(0.3)
	var disparou := c.voando
	await m._esperar(Canhao.VOO + 1.2)
	ok = m._conferir("o canhão lança o Faísca até a Praça do Carrossel", disparou and not c.voando and j.is_on_floor()
			and j.global_position.distance_to(c.destino) < 2.5, "(%.1f m do destino)" % j.global_position.distance_to(c.destino)) and ok
	return ok


## Playground 3 e o teleférico: o P2, a bola de chiclete, o balão até a estação e até o anel do V2, o carrossel.
func _praca() -> bool:
	var ok := true
	j.teleportar(n.postos[1].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P2 acende na praça", n.postos[1].acendido) and ok
	var onde := await _pular_para(Vector3(-66, 16.1, -84), n.carrossel.global_position + Vector3(0, 1.0, 4.0))
	ok = m._conferir("dá para subir no carrossel", absf(onde.y - n.carrossel.topo_base()) < 0.3, "(altura %.1f)" % onde.y) and ok
	var antes := j.global_position
	await m._esperar(2.0)
	ok = m._conferir("e ele leva o Faísca girando", Vector2(j.global_position.x - antes.x, j.global_position.z - antes.z).length() > 0.8) and ok

	onde = await _balao_para(Vector3(-50, 16.1, -75), Vector3(-44, 26, -76))
	ok = m._conferir("sem o balão, não dá para chegar à estação do teleférico", onde.y < 20.0, "(altura %.1f)" % onde.y) and ok
	j.teleportar(n._bola_de_chiclete.global_position)
	await m._esperar(0.4)
	ok = m._conferir("a bola de chiclete da máquina dá o balão e o Vovô mostra como usa", n.balao_pego and j.balao_de_chiclete
			and m.hud.dica_atual == "balao") and ok
	j.teleportar(Vector3(-50, 16.1, -75))
	await m._esperar(0.3)
	j.forcar_pulo = true
	await m._esperar(1.6)
	var subindo := j.no_balao and j.velocity.y > 2.0
	ok = m._conferir("segurando o pulo no ar, o balão enche e o Faísca sobe devagar", subindo, "(vel. %.1f)" % j.velocity.y) and ok
	j.forcar_pulo = false
	await m._esperar(0.1)
	ok = m._conferir("soltando, o balão estoura e ele cai", not j.no_balao) and ok
	await m._esperar(2.0)
	j.teleportar(Vector3(-50, 16.1, -75))
	await m._esperar(0.3)
	j.forcar_pulo = true
	var subiu: float = await m._altura_maxima(4.4)
	j.forcar_pulo = false
	ok = m._conferir("um balão inteiro sobe uns 12 m acima do pulo e estoura sozinho", subiu > 16.0 + 13.0 and not j.no_balao, "(%.1f m)" % (subiu - 16.0)) and ok
	await m._esperar(2.0)
	onde = await _balao_para(Vector3(-50, 16.1, -75), Vector3(-44, 26, -76))
	ok = m._conferir("com o balão, o Faísca chega à estação do teleférico", absf(onde.y - 26.0) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	var v2 := n.vaga_lumes[1]
	onde = await _balao_para(v2.global_position + Vector3(0, -13.0, 5.0), v2.global_position + Vector3(0, -1.1, 1.5))
	await m._esperar(0.3)
	ok = m._conferir("e no anel alto, onde está o V2", n.achados == 2 and absf(onde.y - 28.0) < 0.4, "(altura %.1f, vaga-lumes %d)" % [onde.y, n.achados]) and ok

	var tf := n.teleferico
	j.teleportar(tf.global_position + Vector3(0, 0.3, 0))
	await m._esperar(1.0)
	ok = m._conferir("o teleférico sai quando o Faísca entra", tf.estado == "indo") and ok
	while tf.estado == "indo":
		await m.get_tree().physics_frame
	ok = m._conferir("e o leva até o Céu de Chiclete, sem cair", tf.estado == "em_ate" and j.is_on_floor()
			and j.global_position.distance_to(tf.ate) < 2.0, "(%.1f m)" % j.global_position.distance_to(tf.ate)) and ok
	await _andar(n.no_bolo(70, 40, 14) - tf.ate, 0.6)
	ok = m._conferir("e desce andando na primeira ilha de chiclete", j.is_on_floor() and absf(j.global_position.y - 14.0) < 0.3) and ok
	j.teleportar(n.postos[2].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P3 acende no Céu de Chiclete", n.postos[2].acendido) and ok
	return ok


## Playgrounds 4 e 5: a nuvem que some, o bolso alto, a ponte de wafer, a cereja, a vela, a casinha e a volta.
func _ceu_e_bolo() -> bool:
	var ok := true
	var some := n.nuvens_que_quicam[16]
	var onde := await _quicar(some, n.no_bolo(46, 38, 17) + Vector3(-1.5, 0, 1.0))
	ok = m._conferir("a nuvem lilás joga o Faísca até a ilha de chiclete", absf(onde.y - 17.0) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	ok = m._conferir("e some depois do quique", some.sumida) and ok
	await m._esperar(3.4)
	ok = m._conferir("três segundos depois ela volta", not some.sumida) and ok
	onde = await _balao_para(n.no_bolo(22, 37, 20) + Vector3(0, 0.1, 0), n.no_bolo(30, 44, 27) + Vector3(1, 0, 0))
	ok = m._conferir("com o balão se chega ao bolso alto do coração", absf(onde.y - 27.0) < 0.4, "(altura %.1f)" % onde.y) and ok

	var g4 := n.no_bolo(-26, 34, 26)
	j.teleportar(g4 + Vector3(0, 0.1, 0))
	await _andar(-Vector3(g4.x, 0, g4.z), 2.4)
	ok = m._conferir("a ponte de wafer leva da última ilha até o anel do bolo, sem pular", j.is_on_floor() and absf(j.global_position.y - 26.0) < 0.3
			and Vector2(j.global_position.x, j.global_position.z).length() < 23.5, "(%.1f m do meio)" % Vector2(j.global_position.x, j.global_position.z).length()) and ok
	j.teleportar(n.postos[3].global_position + Vector3(0, 0.1, 1.0))
	await m._esperar(0.4)
	ok = m._conferir("o P4 acende no anel do bolo", n.postos[3].acendido) and ok

	onde = await _quicar(n.cerejas[0], n.no_bolo(-75, 16.2, 30.5))
	ok = m._conferir("a cereja do anel joga até o primeiro biscoito preso no bolo", absf(onde.y - 30.5) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	var v := n.velas[0]
	while v.global_position.y > 30.6:
		await m.get_tree().physics_frame
	j.teleportar(v.global_position + Vector3(0, 0.2, 0))
	while v.global_position.y < 34.9:
		await m.get_tree().physics_frame
	await m._esperar(0.2)
	ok = m._conferir("a vela sobe com o Faísca até a altura do segundo biscoito", j.is_on_floor() and absf(j.global_position.y - 35.0) < 0.3,
			"(altura %.1f)" % j.global_position.y) and ok
	onde = await _pular_para(j.global_position + Vector3(0, 0.1, 0), n.no_bolo(-115, 16.2, 35))
	ok = m._conferir("e da vela se pula no segundo biscoito", absf(onde.y - 35.0) < 0.3, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	var b2 := n.no_bolo(-115, 16.2, 35)
	var b3 := n.no_bolo(-140, 16.2, 35)
	var rumo := (b3 - b2).normalized()
	onde = await _pular_para(b2 + rumo * 1.6 + Vector3(0, 0.1, 0), b3 - rumo * 0.6)
	ok = m._conferir("os biscoitos da fileira ficam a um pulo um do outro (da beirada)", absf(onde.y - 35.0) < 0.3, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok

	# Segredo: a casinha de biscoito no anel. O Vovô mostra o golpe, três golpes abrem a parede e o V3 está dentro.
	var parede := n.paredes_do_bolo[0]
	var frente := parede.global_basis.z
	j.teleportar(n.no_bolo(-120, 20, TOPO_BOLO_TESTE) + Vector3(0, 0.1, 0))
	await m._esperar(0.4)
	ok = m._conferir("perto da casinha o Vovô mostra o golpe", m.hud.dica_atual == "golpe") and ok
	j.teleportar(parede.global_position + frente * 1.8 + Vector3(0, 0.1, 0))
	j.visual.rotation.y = atan2(-frente.x, -frente.z)
	await m._esperar(0.3)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.5)
	await m._esperar(0.6)
	ok = m._conferir("três golpes quebram a parede rachada da casinha", parede.derrotado, "(%d golpes)" % parede.golpes) and ok
	await _andar(-frente, 1.2)
	ok = m._conferir("e o V3 está lá dentro", n.achados == 3, "(vaga-lumes %d)" % n.achados) and ok

	onde = await _quicar(n.cerejas[2], n.no_bolo(-165, 16.2, 35))
	ok = m._conferir("quem cai no anel volta lá para cima pela cereja do outro lado", absf(onde.y - 35.0) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	onde = await _quicar(n.cerejas[1], n.no_bolo(-190, 10.0, 40))
	ok = m._conferir("e a cereja do último biscoito joga até a arena no topo do bolo", absf(onde.y - 40.0) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	return ok


const TOPO_BOLO_TESTE := 26.0


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


## Põe o Faísca em cima da nuvem (ou da cereja) e o guia no ar até em cima de `alvo` (solta o direcional perto; na
## descida flutua se precisar). Devolve onde pousou.
func _quicar(no: Node3D, alvo: Vector3) -> Vector3:
	var area: Area3D = no.area if no is NuvemQueQuica else no
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
		# Na descida, segura o pulo para flutuar se ainda estiver longe.
		j.forcar_pulo = subiu and j.velocity.y < 0.0 and falta.length() > 1.5
		if subiu and i > 20 and j.is_on_floor():
			break
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	await m._esperar(0.2)
	return j.global_position


## Do chão em `de`, pula segurando o botão (com o balão, ele enche e sobe); acima de `alvo`, vai até em cima dele e
## solta o botão (o balão estoura e ele cai lá). Devolve onde pousou.
func _balao_para(de: Vector3, alvo: Vector3) -> Vector3:
	j.teleportar(de)
	await m._esperar(0.3)
	j.forcar_pulo = true
	var acima := false
	for i in 600:
		await m.get_tree().physics_frame
		var falta := Vector3(alvo.x - j.global_position.x, 0, alvo.z - j.global_position.z)
		if j.global_position.y > alvo.y + 1.2:
			acima = true
		if acima and falta.length() > 0.6:
			j.yaw = atan2(-falta.x, -falta.z)
			j.forcar_direcao = Vector2(0, -1)
		else:
			j.forcar_direcao = Vector2.ZERO
		if acima and falta.length() < 1.0:
			j.forcar_pulo = false
		if i > 30 and j.is_on_floor():
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


## Fotos da 2-2 (precisa de janela): de cima, cada playground de cima e de dentro, as viagens e a arena.
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "fase_2_2/"))
	for b in n.alvos:
		(b as Bolota).dormindo = true
		b.process_mode = Node.PROCESS_MODE_DISABLED
	m._comecar_fase()
	await m._esperar(4.0)
	await _foto_de_cima(Vector3(130, 150, 210), Vector3(-30, 8, 10), "fase_2_2/00_visao_geral")
	await _foto_de_cima(Vector3(-200, 120, -170), Vector3(-30, 10, 20), "fase_2_2/00b_de_cima_noroeste")
	await _foto_em(n.inicio, 0.35, -0.12, "fase_2_2/01_campo_de_algodao")
	await _foto_de_cima(Vector3(40, 40, 150), Vector3(-4, 2, 100), "fase_2_2/01b_campo_de_cima")
	await _foto_em(Vector3(-20, 0.1, 99), 1.25, -0.15, "fase_2_2/01c_ponte_e_nuvem_carro")
	await _foto_de_cima(Vector3(-40, 50, 100), Vector3(-92, 9, 40), "fase_2_2/02_ilhas_de_biscoito")
	await _foto_em(Vector3(-68, 7.1, 58), 1.0, -0.1, "fase_2_2/02b_ilhas_de_dentro")
	await _foto_de_cima(Vector3(-130, 60, -20), Vector3(-68, 16, -78), "fase_2_2/03_praca_do_carrossel")
	await _foto_em(Vector3(-77, 16.1, -54), 0.7, -0.05, "fase_2_2/03b_praca_de_dentro")
	await _foto_de_cima(Vector3(-60, 50, -20), Vector3(-15, 20, -60), "fase_2_2/03c_teleferico")
	await _foto_de_cima(Vector3(90, 50, -60), Vector3(30, 20, -10), "fase_2_2/04_ceu_de_chiclete")
	await _foto_em(n.teleferico.ate + Vector3(1, 0.1, 1), -0.6, 0.0, "fase_2_2/04b_ceu_de_dentro")
	await _foto_de_cima(Vector3(-50, 58, 40), Vector3(0, 30, 0), "fase_2_2/05_subida_do_bolo")
	await _foto_em(n.no_bolo(-30, 21, 26.1), 0.9, 0.1, "fase_2_2/05b_anel_do_bolo")
	var de_casinha := n.no_bolo(-112, 21.0, 26.1)
	var para_casinha := n.no_bolo(-135, 17.0, 26.0) - de_casinha
	await _foto_em(de_casinha, atan2(-para_casinha.x, -para_casinha.z), -0.1, "fase_2_2/05c_casinha")
	await _foto_em(Vector3(4, 40.1, 9), 0.4, -0.3, "fase_2_2/06_arena")
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
