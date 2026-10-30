class_name TesteFase21
extends RefCounted
## Testes da 2-1 Cozinha Gigante (refeita em playgrounds em 2026-10-29), chamados pelo FaiscaSolo:
##   --faisca-fase-2-1           confere a fase de ponta a ponta: contagens, o padrão de playgrounds (o brilho do
##                               baú à vista de cada entrada), a mesa (tampa e caixa de cereal), a ponte de tábuas,
##                               a bancada (rolos e a tampa do vão até o V1), os dois pratos que levam, a pizza, as
##                               bocas, a tampa até os livros do V2, a pia (prato, bolha e água), as bolhas de degrau,
##                               o V3 atrás da geladeira, o sorvete até o alto da geladeira, o baú e a tela de fim
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
	ok = m._conferir("de 75 a 110 estrelinhas no caminho e nos bolsos (fora as das Bolotas)", n.estrelas.size() >= 75 and n.estrelas.size() <= 110,
			"(%d soltas, %d com as das Bolotas)" % [n.estrelas.size(), total]) and ok
	ok = m._conferir("3 postos, 3 vaga-lumes, 9 Bolotas e o baú", n.postos.size() == 3 and n.vaga_lumes.size() == 3 and n.alvos.size() == 9
			and n.bau != null, "(%d postos, %d Bolotas)" % [n.postos.size(), n.alvos.size()]) and ok
	ok = m._conferir("peças: 3 tampas, 4 bocas, 2 rolos, a pizza, a pia, 4 pratos que se mexem, 5 bolhas e o sorvete", n.tampas.size() == 3
			and n.bocas.size() == 4 and n.rolos.size() == 2 and n.pizzas.size() == 1 and n.aguas.size() == 1 and n.moveis.size() == 4
			and n.nuvens_que_somem.size() == 5 and n.molas.size() == 1) and ok

	# O padrão de playgrounds: os móveis em volta da geladeira, um arco de saída em cada um dos três primeiros, o
	# brilho do baú à vista de todas as entradas e um vaga-lume no bolso de cada um dos três últimos.
	await m.get_tree().physics_frame
	var espaco := j.get_world_3d().direct_space_state
	ok = m._conferir("4 playgrounds e 3 arcos de saída", n.playgrounds.size() == 4 and n.saidas.size() == 3) and ok
	var cegos := n.playgrounds.filter(func(p: Dictionary) -> bool:
		return not espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p.entrada + Vector3.UP * 2.0, n.brilho_do_marco, 1)).is_empty())
	ok = m._conferir("da entrada de cada playground dá para ver o brilho do baú em cima da geladeira", cegos.is_empty(),
			"(sem ver: %s)" % ", ".join(cegos.map(func(p: Dictionary) -> String: return p.nome))) and ok
	var donos := n.vaga_lumes.map(func(v: VagaLume) -> int: return _playground_mais_perto(v.global_position))
	ok = m._conferir("um vaga-lume no bolso de cada playground: o 2, o 3 e o 4", donos == [1, 2, 3], "(%s)" % str(donos)) and ok
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
	j.teleportar(n.vaga_lumes[0].global_position - Vector3(0, 0.8, 0))
	await m._esperar(0.3)
	ok = m._conferir("o V1 está na prateleira", n.achados == 1) and ok

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
	j.teleportar(n.vaga_lumes[1].global_position - Vector3(0, 0.8, 0))
	await m._esperar(0.3)
	ok = m._conferir("o V2 está em cima dos livros", n.achados == 2) and ok
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


## Playground 4 e a arena: o P3, a pia, as bolhas de degrau, o V3 atrás da geladeira e o sorvete.
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
	# As bolhas de degrau, da bancada do fim até a prateleira, pulando de verdade.
	var degraus := [[Vector3(22.5, 8.1, -45.5), n.nuvens_que_somem[2], "da bancada para a 1ª bolha"],
		[null, n.nuvens_que_somem[3], "para a 2ª"], [null, n.nuvens_que_somem[4], "para a 3ª"]]
	var de: Vector3 = degraus[0][0]
	for d in degraus:
		var b: NuvemQueSome = d[1]
		var onde := await _pular_para(de, b.global_position)
		ok = m._conferir("bolhas de degrau: pula %s" % d[2], absf(onde.y - b.global_position.y) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
		de = onde + Vector3.UP * 0.1
	var na_prateleira := await _pular_para(de, Vector3(12.0, 14.0, -53.0))
	ok = m._conferir("e da última bolha para a prateleira encostada na geladeira", absf(na_prateleira.y - 14.0) < 0.3 and na_prateleira.x < 14.0,
			"(%.1f, %.1f, %.1f)" % [na_prateleira.x, na_prateleira.y, na_prateleira.z]) and ok
	# Segredo: a prateleira continua atrás da geladeira até o V3.
	j.teleportar(Vector3(11.0, 14.1, -79.0))
	await _andar(Vector3(-1, 0, 0), 2.6)
	ok = m._conferir("andando pela prateleira atrás da geladeira se acha o V3", n.achados == 3 and absf(j.global_position.y - 14.0) < 0.3,
			"(x %.1f, vaga-lumes %d)" % [j.global_position.x, n.achados]) and ok
	var sorvete: Area3D = n.molas[0]
	var onde := await _quicar(sorvete, Vector3(3.0, 20.0, -72.0))
	ok = m._conferir("o sorvete joga o Faísca até o alto da geladeira", j.is_on_floor() and absf(onde.y - 20.0) < 0.4, "(%.1f, %.1f, %.1f)" % [onde.x, onde.y, onde.z]) and ok
	return ok


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
