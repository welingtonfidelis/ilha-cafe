class_name TesteFase21
extends RefCounted
## Testes da 2-1 Cozinha Gigante, chamados pelo FaiscaSolo:
##   --faisca-fase-2-1           confere a fase de ponta a ponta
##   --faisca-fase-2-1-captura   fotos de cada trecho em tools/capturas/faisca/fase_2_1/ (precisa de janela)

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
	ok = m._conferir("a fase tem umas 80 estrelinhas", total >= 65 and total <= 100, "(%d)" % total) and ok
	ok = m._conferir("3 postos, 3 vaga-lumes, 10 Bolotas e o baú", n.postos.size() == 3 and n.vaga_lumes.size() == 3 and n.alvos.size() == 10
			and n.bau != null, "(%d postos, %d Bolotas)" % [n.postos.size(), n.alvos.size()]) and ok
	ok = m._conferir("4 tampas que pulam, 4 bocas do fogão, 2 rolos, a pizza e a água da pia", n.tampas.size() == 4 and n.bocas.size() == 4
			and n.rolos.size() == 2 and n.pizzas.size() == 1 and n.aguas.size() == 1) and ok
	ok = m._conferir("o caminho tem uns 230 m, da mesa até o alto da geladeira", n.bau.global_position.z < -215.0 and n.bau.global_position.y > 19.0,
			"(baú em z %.0f, a %.0f m)" % [n.bau.global_position.z, n.bau.global_position.y]) and ok
	# As Bolotas ficam paradas no teste (a 1-1 já confere o jeito delas).
	for b in n.alvos:
		b.process_mode = Node.PROCESS_MODE_DISABLED

	m._comecar_fase()
	await m._esperar(4.0)
	ok = m._conferir("desce flutuando e pisa na mesa do café", j.is_on_floor() and j.controle_ligado and absf(j.global_position.y - 8.0) < 0.3
			and j.global_position.distance_to(n.inicio) < 1.0) and ok
	j.teleportar(n.vaga_lumes[0].global_position - Vector3(0, 0.8, 0))
	await m._esperar(0.3)
	ok = m._conferir("o V1 está atrás do pote grande, no canto da mesa", n.achados == 1) and ok

	# Tampas: a primeira joga lá para o alto; a terceira joga até a prateleira.
	var t1 := n.tampas[0]
	j.teleportar(t1.global_position + Vector3(0, 1.6, 0))
	var altura: float = await m._altura_maxima(3.6)
	ok = m._conferir("em cima da tampa, quando ela pula, o Faísca vai lá para o alto", altura > 18.0, "(%.1f m)" % altura) and ok
	ok = await _tampa_ate_a_prateleira() and ok

	# Fogão: a boca acesa tira um coração.
	var b0 := n.bocas[0]
	while not b0.acesa:
		await m.get_tree().physics_frame
	j.vida = Jogador.VIDA_MAX
	j.teleportar(b0.global_position + Vector3(0, 0.3, 0))
	await m._esperar(0.3)
	ok = m._conferir("a boca do fogão acesa tira um coração", j.vida == Jogador.VIDA_MAX - 1, "(vida %d)" % j.vida) and ok
	# Sai de cima da boca antes de esperar (senão ela tira outro quando a piscada acaba).
	j.teleportar(Vector3(0, 9.0, -106.0))
	await m._esperar(1.8)
	j.vida = Jogador.VIDA_MAX

	# Pia: P2, prato que boia, bolha que estoura e a água.
	var p2 := n.postos[1]
	j.teleportar(p2.ponto())
	await m._esperar(0.4)
	ok = m._conferir("o P2 acende na beirada da pia", p2.acendido) and ok
	var prato: AnimatableBody3D = n.moveis[0]
	j.teleportar(prato.global_position + Vector3(0, 1.4, 0))
	await m._esperar(0.4)
	var y0 := j.global_position.y
	var sobe_desce := 0.0
	for i in int(1.6 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		sobe_desce = maxf(sobe_desce, absf(j.global_position.y - y0))
	ok = m._conferir("o prato boiando segura o Faísca e sobe e desce com ele", j.is_on_floor() and sobe_desce > 0.2, "(%.2f m)" % sobe_desce) and ok
	var bolha: NuvemQueSome = n.nuvens_que_somem[0]
	j.teleportar(bolha.global_position + Vector3(0, 0.3, 0))
	await m._esperar(1.4)
	ok = m._conferir("a bolha de sabão estoura um instante depois de pisada", bolha.sumida) and ok
	await m._esperar(0.6)
	ok = m._conferir("e cair na água da pia é cair: perde um coração e volta no P2", j.vida == Jogador.VIDA_MAX - 1
			and j.global_position.distance_to(p2.ponto()) < 1.5, "(vida %d)" % j.vida) and ok
	j.vida = Jogador.VIDA_MAX
	await m._esperar(3.4)

	# Rolo de macarrão: encostar tira um coração; ele rola de um lado para o outro.
	var r0 := n.rolos[0]
	var x_min := INF
	var x_max := -INF
	for i in int(1.9 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		x_min = minf(x_min, r0.global_position.x)
		x_max = maxf(x_max, r0.global_position.x)
	ok = m._conferir("o rolo de macarrão rola de um lado para o outro", x_max - x_min > 8.0, "(%.1f m)" % (x_max - x_min)) and ok
	j.vida = Jogador.VIDA_MAX
	j.teleportar(r0.global_position + Vector3(0, 0.2, 0.5))
	await m._esperar(0.2)
	ok = m._conferir("encostar no rolo tira um coração", j.vida == Jogador.VIDA_MAX - 1, "(vida %d)" % j.vida) and ok
	j.vida = Jogador.VIDA_MAX
	await m._esperar(1.8)

	# Pizza: quem está em cima gira junto.
	var pz := n.pizzas[0]
	var p3 := n.postos[2]
	j.teleportar(p3.ponto())
	await m._esperar(0.4)
	ok = m._conferir("o P3 acende na mesa da pizza", p3.acendido) and ok
	j.teleportar(pz.global_position + Vector3(5.0, 2.6, 0))
	await m._esperar(0.4)
	var antes := j.global_position
	await m._esperar(2.0)
	var andou := Vector2(j.global_position.x - antes.x, j.global_position.z - antes.z).length()
	ok = m._conferir("em cima da pizza que gira o Faísca vai junto", j.is_on_floor() and andou > 2.0 and j.global_position.y > 10.0, "(%.1f m)" % andou) and ok

	# Sorvete gigante: joga até o alto da geladeira.
	# Da beirada da mesa: pula no sorvete, ele joga lá para cima, e segue para a frente até cair em cima.
	var sorvete: Area3D = n.molas[n.molas.size() - 1]
	j.teleportar(sorvete.global_position + Vector3(0, -1.85, 2.5))
	j.yaw = 0.0
	j.visual.rotation.y = PI
	await m._esperar(0.4)
	j.forcar_direcao = Vector2(0, -1)
	j.forcar_pulo = true
	await m._esperar(0.15)
	j.forcar_pulo = false
	var lancou := false
	for i in int(4.0 * Engine.physics_ticks_per_second):
		await m.get_tree().physics_frame
		if j.velocity.y > 15.0:
			lancou = true
			j.forcar_pulo = true
		if lancou and j.is_on_floor():
			break
	j.forcar_pulo = false
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.5)
	ok = m._conferir("o sorvete gigante joga o Faísca até o alto da geladeira", j.is_on_floor() and j.global_position.y > 19.5,
			"(%.1f, %.1f)" % [j.global_position.y, j.global_position.z]) and ok

	# Baú no alto da geladeira, a Estrela Grande e a tela de fim.
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


## Em cima da terceira tampa, andando para a frente: quando ela pula, o Faísca sobe e cai na prateleira.
func _tampa_ate_a_prateleira() -> bool:
	var t3 := n.tampas[2]
	j.teleportar(t3.global_position + Vector3(0, 1.6, 0))
	j.yaw = 0.0
	j.visual.rotation.y = PI
	await m._esperar(0.3)
	# Espera ela começar a tremer e anda para a frente só depois do pulo.
	while t3.fase_do_ciclo() != "pula":
		await m.get_tree().physics_frame
	await m._esperar(0.25)
	j.forcar_direcao = Vector2(0, -1)
	j.forcar_pulo = true
	await m._esperar(1.6)
	j.forcar_pulo = false
	await m._esperar(0.6)
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.4)
	return m._conferir("a terceira tampa joga o Faísca até a prateleira", j.is_on_floor() and absf(j.global_position.y - 19.0) < 0.4
			and j.global_position.z < -51.0, "(%.1f, %.1f)" % [j.global_position.y, j.global_position.z])


## Fotos de cada trecho (precisa de janela). As Bolotas ficam paradas.
func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "fase_2_1/"))
	for b in n.alvos:
		(b as Bolota).dormindo = true
		b.process_mode = Node.PROCESS_MODE_DISABLED
	m._comecar_fase()
	await m._esperar(4.0)
	await _foto_em(n.inicio, 0.0, -0.25, "01_mesa_do_cafe")
	await _foto_em(Vector3(0, 9.3, -10.0), 0.0, -0.2, "02_tabua")
	await _foto_em(Vector3(-2.0, 10.5, -21.5), 0.1, -0.25, "03_panelas")
	await _foto_em(Vector3(-1.5, 19.1, -52.5), 0.1, -0.2, "04_prateleira")
	await _foto_em(Vector3(-3.0, 19.1, -96.0), 0.0, -0.55, "05_fogao")
	await _foto_em(Vector3(-4.0, 8.1, -116.5), 0.15, -0.25, "06_pia")
	await _foto_em(Vector3(0.0, 8.1, -150.0), 0.0, -0.2, "07_massa")
	await _foto_em(Vector3(0.0, 8.1, -186.5), 0.0, -0.25, "08_pizza")
	await _foto_em(Vector3(-5.5, 8.1, -188.5), -0.3, 0.3, "09_geladeira")
	await _foto_em(Vector3(1.5, 20.1, -214.5), 0.1, -0.25, "10_em_cima_da_geladeira")
	# A tampa pulando com o Faísca em cima.
	var t1 := n.tampas[0]
	j.teleportar(t1.global_position + Vector3(0, 1.6, 0))
	j.yaw = 0.6
	j.pitch = -0.1
	while t1.fase_do_ciclo() != "pula":
		await m.get_tree().physics_frame
	await m._esperar(0.45)
	await m._foto("fase_2_1/03b_tampa_pulando")
	m.get_tree().quit()


func _foto_em(pos: Vector3, yaw: float, pitch: float, nome: String) -> void:
	j.teleportar(pos)
	j.yaw = yaw
	j.pitch = pitch
	j.visual.rotation.y = yaw + PI
	await m._esperar(0.8)
	await m._foto("fase_2_1/" + nome)
