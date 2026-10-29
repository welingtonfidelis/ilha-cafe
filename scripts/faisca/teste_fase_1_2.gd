class_name TesteFase12
extends RefCounted
## Testes da 1-2 Túneis do Morro, chamados pelo FaiscaSolo:
##   --faisca-fase-1-2           confere a fase de ponta a ponta: contagens, descida, dicas, tocha acesa pelo
##                               laser, parede rachada e o nicho do V1, os pulos de verdade nos andaimes, o
##                               P1, as pontes que sobem com as tochas (e o vão que não passa sem elas), a
##                               queda no abismo, a mola do V3, o elevador, a porta das três tochas (com a
##                               tocha dos caixotes acesa subindo de verdade), o baú dourado e a tela de fim
##   --faisca-fase-1-2-captura   fotos de cada trecho em tools/capturas/faisca/fase_1_2/ (precisa de janela)
## Usa as ajudas do FaiscaSolo (_esperar, _botao, _toque, _conferir, _foto).

var m: Node
var n: Fase12
var j: Jogador
## No último `_pular`: o z onde ele desceu abaixo da altura de onde saiu (INF se não desceu).
var _z_ao_descer := INF


func _init(main: Node) -> void:
	m = main
	n = main.nivel
	j = main.jogador
	main.testando = true


func rodar() -> void:
	var ok := true
	await m._esperar(0.3)
	var total := n.total_estrelas()
	ok = m._conferir("a fase tem umas 85 estrelinhas", total >= 70 and total <= 100, "(%d)" % total) and ok
	ok = m._conferir("2 postos, 3 vaga-lumes, 16 tochas (5 já acesas), 1 parede rachada, 3 pontes e 1 porta das tochas",
			n.postos.size() == 2 and n.vaga_lumes.size() == 3 and n.tochas.size() == 16
			and n.tochas.filter(func(t: Tocha) -> bool: return t.esta_acesa).size() == 5 and n.paredes_rachadas.size() == 1
			and n.pontes.size() == 3 and n.portas_das_tochas.size() == 1, "(%d tochas)" % n.tochas.size()) and ok
	ok = m._conferir("12 Bolotas e o baú dourado", n.alvos.size() == 12 and n.bau != null and n.bau.dourado, "(%d)" % n.alvos.size()) and ok
	# As Bolotas ficam paradas no teste (a 1-1 já confere o jeito delas), menos a primeira, que dorme.
	for b in n.alvos.slice(1):
		b.process_mode = Node.PROCESS_MODE_DISABLED

	m._comecar_fase()
	await m._esperar(4.0)
	ok = m._conferir("desce flutuando e pisa no começo do túnel", j.is_on_floor() and j.controle_ligado
			and j.global_position.distance_to(n.inicio) < 1.0, "(%.1f m)" % j.global_position.distance_to(n.inicio)) and ok

	# A Bolota que dorme na entrada apanha como na 1-1.
	var b0 := n.alvos[0] as Bolota
	j.teleportar(b0.global_position + Vector3(0, 0.1, 1.6))
	j.visual.rotation.y = PI
	await m._esperar(0.3)
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.45)
	await m._esperar(0.6)
	ok = m._conferir("a Bolota da entrada apanha e sai quicando", b0.derrotado) and ok

	# A primeira tocha: o Vovô mostra o laser na tocha, e flutuar por cima acende.
	j.teleportar(Vector3(0, 0.1, -6.0))
	await m._esperar(0.4)
	ok = m._conferir("o Vovô Farol mostra a dica da tocha", m.hud.dica_atual == "tocha") and ok
	var t0: Tocha = n.tochas[0]
	ok = m._conferir("a tocha começa apagada e sem luz", not t0.esta_acesa and not t0._luz.visible) and ok
	await _acender_com_laser(t0, Vector3(0.6, 0, 0))
	ok = m._conferir("o laser dos pés acende a tocha, mesmo sem acertar bem no meio", t0.esta_acesa and t0._luz.visible) and ok

	# A parede rachada: três golpes quebram e abrem o nicho do V1.
	var parede: ParedeRachada = n.paredes_rachadas[0]
	j.teleportar(Vector3(-4.0, 0.1, -26.2))
	j.visual.rotation.y = -PI / 2.0
	await m._esperar(0.4)
	ok = m._conferir("perto da parede rachada o Vovô mostra o golpe", m.hud.dica_atual == "golpe") and ok
	for i in 3:
		await m._toque(JOY_BUTTON_X)
		await m._esperar(0.45)
	await m._esperar(0.4)
	ok = m._conferir("três golpes quebram a parede rachada", parede.derrotado and parede.collision_layer == 0, "(%d golpes)" % parede.golpes) and ok
	j.yaw = PI / 2.0
	j.forcar_direcao = Vector2(0, -1)
	await m._esperar(1.2)
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.3)
	ok = m._conferir("a passagem fica livre e o V1 está no nicho", n.achados == 1 and j.global_position.x < -8.0,
			"(x %.1f, vaga-lumes %d)" % [j.global_position.x, n.achados]) and ok

	# Os andaimes, pulando de verdade: cada tablado sobe 1,6 m.
	var degraus := [
		[Vector3(6.0, 1.7, -46.0), Vector3(0, 0, -1), 2.2, 3.2, "do 1º para o 2º tablado"],
		[Vector3(7.4, 3.3, -52.5), Vector3(-1, 0, 0), 2.6, 4.8, "do 2º para o 3º"],
		[Vector3(1.9, 4.9, -52.5), Vector3(-1, 0, 0), 2.6, 6.4, "do 3º para o 4º"],
		[Vector3(-5.0, 6.5, -51.0), Vector3(0, 0, -1), 2.6, 8.0, "do 4º para a passarela, na altura da beirada"],
	]
	for d in degraus:
		var onde := await _pular(d[0], d[1], d[2], false)
		ok = m._conferir("andaime: pula %s" % d[4], absf(onde.y - float(d[3])) < 0.4, "(altura %.1f)" % onde.y) and ok
	j.teleportar(Vector3(-5.0, 8.1, -62.0))
	await _andar(Vector3(0.6, 0, -1), 1.2)
	ok = m._conferir("do último tablado se anda para a beirada do abismo, e o P1 acende", j.is_on_floor() and j.global_position.y > 7.8
			and j.global_position.z < -66.0 and n.postos[0].acendido, "(%.1f, %.1f)" % [j.global_position.y, j.global_position.z]) and ok
	var mola_v2: Area3D = n.molas[1]
	j.teleportar(mola_v2.global_position + Vector3(0, 1.5, 0))
	var altura: float = await m._altura_maxima(1.2)
	ok = m._conferir("a mola do canto joga até a altura da viga do V2", altura > 10.5, "(%.1f m)" % altura) and ok

	# O abismo: sem ponte, o vão não passa nem flutuando; cair tira um coração e volta no P1.
	await m._esperar(1.0)
	var t1: Tocha = n.tochas[5]
	var ponte: StaticBody3D = n.pontes[0]
	ok = m._conferir("a ponte começa escondida", not ponte.visible and not n.ponte_no_lugar(ponte)) and ok
	j.vida = Jogador.VIDA_MAX
	await _pular(Vector3(0, 8.1, -68.5), Vector3(0, 0, -1), 3.2, true)
	await m._esperar(0.5)
	ok = m._conferir("sem a ponte, o vão de 14 m não passa nem flutuando: cai, perde um coração e volta no P1", _z_ao_descer > -85.0
			and j.vida == Jogador.VIDA_MAX - 1 and j.global_position.distance_to(n.postos[0].ponto()) < 1.5,
			"(desceu da altura da beirada em z %.1f, o pilar começa em -86; vida %d)" % [_z_ao_descer, j.vida]) and ok
	await _acender_com_laser(t1, Vector3.ZERO)
	await m._esperar(1.6)
	ok = m._conferir("acender a tocha da beirada sobe a ponte do escuro", t1.esta_acesa and ponte.visible and n.ponte_no_lugar(ponte)) and ok
	var chegou := await _pular(Vector3(0, 8.1, -68.5), Vector3(0, 0, -1), 99.0, false, -87.0)
	ok = m._conferir("a ponte leva até o primeiro pilar", absf(chegou.y - 8.0) < 0.3 and chegou.z < -86.5, "(%.1f, %.1f)" % [chegou.y, chegou.z]) and ok
	for k in [6, 7]:
		await _acender_com_laser(n.tochas[k], Vector3.ZERO)
	await m._esperar(1.6)
	ok = m._conferir("as outras duas tochas sobem as outras pontes", n.pontes.all(func(p: StaticBody3D) -> bool: return n.ponte_no_lugar(p))) and ok
	chegou = await _pular(Vector3(0, 8.1, -88.5), Vector3(0, 0, -1), 99.0, false, -122.0)
	ok = m._conferir("pelas pontes se chega à mina de ouro", absf(chegou.y - 8.0) < 0.3 and chegou.z < -120.5, "(%.1f, %.1f)" % [chegou.y, chegou.z]) and ok
	var mola_v3: Area3D = n.molas[2]
	j.teleportar(mola_v3.global_position + Vector3(0, 1.5, 0))
	altura = await m._altura_maxima(1.2)
	ok = m._conferir("a mola da beiradinha do V3 volta para cima da ponte", altura > 8.6, "(%.1f m)" % altura) and ok
	await m._esperar(1.0)

	# Mina e elevador.
	j.teleportar(n.postos[1].global_position + Vector3(0, 0.1, 1.2))
	await m._esperar(0.4)
	ok = m._conferir("o P2 acende na mina de ouro", n.postos[1].acendido) and ok
	var elev: AnimatableBody3D = n.moveis[0]
	while elev.global_position.y > 8.3:
		await m.get_tree().physics_frame
	j.teleportar(elev.global_position + Vector3(0, 0.6, 0))
	await m._esperar(3.0)
	ok = m._conferir("o elevador leva o Faísca lá para cima", j.is_on_floor() and j.global_position.y > 14.0, "(altura %.1f)" % j.global_position.y) and ok

	# A porta: fechada segura; as três tochas (a dos caixotes subindo de verdade) abrem.
	var porta: Dictionary = n.portas_das_tochas[0]
	j.teleportar(Vector3(0, 16.1, -183.0))
	await _andar(Vector3(0, 0, -1), 1.0)
	ok = m._conferir("com a porta fechada não se passa", j.global_position.z > -186.0, "(z %.1f)" % j.global_position.z) and ok
	await _acender_com_laser(n.tochas[11], Vector3.ZERO)
	await _acender_com_laser(n.tochas[12], Vector3.ZERO)
	ok = m._conferir("com duas das três acesas a porta continua fechada", not porta.aberta) and ok
	var onde := await _pular(Vector3(1.6, 16.1, -178.0), Vector3(-1, 0, 0), 1.2, false)
	ok = m._conferir("pula no caixote baixo", absf(onde.y - 17.6) < 0.4, "(altura %.1f)" % onde.y) and ok
	onde = await _pular(Vector3(-0.7, 17.7, -178.0), Vector3(-1, 0, 0), 0.05, false)
	ok = m._conferir("e dele na pilha alta, onde está a última tocha", absf(onde.y - 19.0) < 0.4, "(altura %.1f)" % onde.y) and ok
	var tc: Tocha = n.tochas[13]
	j.teleportar(tc.global_position + Vector3(0.9, 0.1, 0.4))
	await m._esperar(0.3)
	j.forcar_pulo = true
	await m._esperar(1.4)
	j.forcar_pulo = false
	await m._esperar(1.6)
	ok = m._conferir("pulando e flutuando em cima da pilha acende a tocha, e as três abrem a porta", tc.esta_acesa and porta.aberta) and ok
	j.teleportar(Vector3(0, 16.1, -183.0))
	await _andar(Vector3(0, 0, -1), 1.2)
	ok = m._conferir("com a porta aberta se passa para a câmara do baú", j.global_position.z < -188.0, "(z %.1f)" % j.global_position.z) and ok

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
	_z_ao_descer = INF
	for i in 600:
		await m.get_tree().physics_frame
		var andou := (j.global_position - de).dot(dir)
		if _z_ao_descer == INF and j.global_position.y < de.y - 0.6:
			_z_ao_descer = j.global_position.z
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


## Fotos de cada trecho (precisa de janela).
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "fase_1_2/"))
	# Bolotas paradas (dormindo e sem processar), para não tirarem corações no meio das fotos.
	for b in n.alvos:
		(b as Bolota).dormindo = true
		b.process_mode = Node.PROCESS_MODE_DISABLED
	m._comecar_fase()
	await m._esperar(4.0)
	await _foto_em(n.inicio, 0.2, -0.2, "01_boca_do_tunel")
	n.tochas[0].acender()
	await _foto_em(Vector3(1.0, 0.1, -4.0), 0.25, -0.18, "02_corredor_das_tochas")
	await _foto_em(Vector3(-1.0, 0.1, -22.0), 1.0, -0.2, "03_parede_rachada")
	n.paredes_rachadas[0].receber_golpe(1, Vector3(-3, 0, -27))
	await m._esperar(0.4)
	n.paredes_rachadas[0].receber_golpe(1, Vector3(-3, 0, -27))
	await m._esperar(0.4)
	n.paredes_rachadas[0].receber_golpe(1, Vector3(-3, 0, -27))
	await m._esperar(1.4)
	await _foto_em(Vector3(-3.0, 0.1, -27.0), PI / 2.0, -0.15, "04_nicho_do_v1")
	await _foto_em(Vector3(3.0, 0.1, -43.5), 0.25, 0.02, "05_poco_dos_andaimes")
	await _foto_em(Vector3(1.0, 8.1, -67.0), 0.0, -0.3, "06_abismo_escuro")
	n.tochas[5].acender()
	await m._esperar(0.6)
	await m._foto("fase_1_2/07_ponte_subindo")
	n.tochas[6].acender()
	n.tochas[7].acender()
	await m._esperar(2.0)
	await _foto_em(Vector3(-1.5, 8.1, -87.0), 0.1, -0.3, "08_pontes")
	await _foto_em(Vector3(-2.0, 8.1, -121.5), 0.3, -0.2, "09_mina_de_ouro")
	await _foto_em(Vector3(0.0, 8.1, -151.0), 0.0, 0.25, "10_elevadores")
	await _foto_em(Vector3(1.0, 16.1, -164.0), 0.1, -0.2, "11_porta_fechada")
	for k in [11, 12, 13]:
		n.tochas[k].acender()
	await m._esperar(2.0)
	await _foto_em(Vector3(1.5, 16.1, -181.0), 0.1, -0.15, "12_porta_aberta")
	await _foto_em(Vector3(1.0, 16.1, -189.0), 0.1, -0.25, "13_camara_do_bau")
	m.get_tree().quit()


func _foto_em(pos: Vector3, yaw: float, pitch: float, nome: String) -> void:
	j.teleportar(pos)
	j.yaw = yaw
	j.pitch = pitch
	j.visual.rotation.y = yaw + PI
	await m._esperar(0.8)
	await m._foto("fase_1_2/" + nome)
