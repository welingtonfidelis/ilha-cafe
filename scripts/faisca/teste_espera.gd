class_name TesteEspera
extends RefCounted
## As animações de espera do Faísca (2026-11-13), dentro da 1-1, chamadas pelo FaiscaSolo:
##   --faisca-espera          confere: parado ele olha em volta, depois brinca (cada brincadeira começa e termina de
##                            volta no parado), bem parado deita e dorme com os "z", e qualquer mexida no controle acorda
##                            na hora (com cara de surpreso); teleportar também zera a espera
##   --faisca-espera-captura  fotos de cada espera em tools/capturas/faisca/espera/ (precisa de janela)
## Para não esperar meio minuto de verdade, o teste adianta o relógio (Jogador.parado) até perto de cada momento.

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
	await m._comecar_fase()
	j.teleportar(n.inicio + Vector3(0, 0.1, 0))
	await m._esperar(1.0)
	ok = m._conferir("parado há pouco, sem espera: respirando", j.espera == "" and j.robo.animacao_atual() == "geral/Idle_A",
			"(%s, %s)" % [j.espera, j.robo.animacao_atual()]) and ok
	# Olhar em volta.
	j.parado = Espera.OLHAR - 0.05
	await m._esperar(0.2)
	ok = m._conferir("com %d s parado, olha em volta" % int(Espera.OLHAR), j.espera == "olhar" and j.robo.animacao_atual() == "geral/Idle_B",
			"(%s, %s)" % [j.espera, j.robo.animacao_atual()]) and ok
	await _ate(func() -> bool: return j.espera == "", 3.0)
	ok = m._conferir("depois de olhar, volta a respirar", j.robo.animacao_atual() == "geral/Idle_A", "(%s)" % j.robo.animacao_atual()) and ok
	# A primeira brincadeira.
	j.parado = Espera.BRINCAR - 0.05
	await m._esperar(0.2)
	ok = m._conferir("com %d s parado, brinca sozinho" % int(Espera.BRINCAR), j.espera in Jogador.BRINCADEIRAS, "(%s)" % j.espera) and ok
	# Mexer na câmera (o analógico direito) não acorda.
	var brincando := j.espera
	var yaw_antes := j.yaw
	Input.action_press("olhar_direita")
	await m._esperar(0.3)
	Input.action_release("olhar_direita")
	ok = m._conferir("mexer na câmera não para a brincadeira", j.espera == brincando and absf(angle_difference(yaw_antes, j.yaw)) > 0.1,
			"(%s, a câmera girou %.2f rad)" % [j.espera, absf(angle_difference(yaw_antes, j.yaw))]) and ok
	# Mexer no analógico acorda na hora.
	j.forcar_direcao = Vector2(0, -1)
	await m._esperar(0.1)
	j.forcar_direcao = Vector2.ZERO
	ok = m._conferir("mexer no analógico para a brincadeira na hora", j.espera == "" and j.parado < 0.2 and not j.robo._dancando,
			"(%s, %.2f)" % [j.espera, j.parado]) and ok
	await m._esperar(0.6)
	# Cada brincadeira começa, anda e termina de volta no parado.
	for b: String in Jogador.BRINCADEIRAS:
		j.teleportar(n.inicio + Vector3(0, 0.1, 0))
		await m._esperar(0.3)
		j.parado = 12.0
		j._espera.comecar(b)
		var total := 0.0
		for passo: Array in Espera.PASSOS[b]:
			total += float(passo[1])
		var animacoes := {}
		var t := 0.0
		while t < total + 0.4 and j.espera == b:
			animacoes[j.robo.animacao_atual()] = true
			await m.get_tree().physics_frame
			t += 1.0 / Engine.physics_ticks_per_second
		var esperadas: Array = Espera.PASSOS[b].map(func(passo: Array) -> String: return "geral/Idle_A" if passo[0] == "dancinha" else passo[0])
		var todas := esperadas.all(func(a: String) -> bool: return animacoes.has(a))
		ok = m._conferir("a brincadeira \"%s\" toca as animações dela e termina" % b, todas and j.espera == "" and j.is_on_floor(),
				"(%s)" % ", ".join(animacoes.keys())) and ok
		await m._esperar(0.3)
		ok = m._conferir("depois de \"%s\", volta a respirar" % b, j.robo.animacao_atual() == "geral/Idle_A" and not j.robo._dancando,
				"(%s)" % j.robo.animacao_atual()) and ok
	# Acenar vira para a câmera.
	j.teleportar(n.inicio + Vector3(0, 0.1, 0))
	await m._esperar(0.3)
	j.visual.rotation.y = j.yaw
	j._espera.comecar("acenar")
	await m._esperar(1.5)
	var para_camera := j.camera.global_position - j.global_position
	var desvio := absf(angle_difference(j.visual.rotation.y, atan2(para_camera.x, para_camera.z)))
	ok = m._conferir("acenando, ele vira para a câmera", desvio < 0.3, "(%.2f rad)" % desvio) and ok
	# Dormir.
	j.teleportar(n.inicio + Vector3(0, 0.1, 0))
	await m._esperar(0.3)
	# Logo antes do sono, ainda caía numa brincadeira (no jogo, ele deita quando ela acaba).
	j.parado = Espera.DORMIR
	await m._esperar(0.2)
	ok = m._conferir("com %d s parado, deita" % int(Espera.DORMIR), j.espera == "dormir" and j.robo.animacao_atual() == "festa/Lie_Down",
			"(%s, %s)" % [j.espera, j.robo.animacao_atual()]) and ok
	await m._esperar(3.4)
	var zs := m.get_children().filter(func(c: Node) -> bool: return c is Label3D)
	ok = m._conferir("deitado, dorme de olhos fechados e solta os \"z\"", j.robo.animacao_atual() == "festa/Lie_Idle"
			and j.robo.expressao_atual() == "piscando" and not zs.is_empty(), "(%s, %s, %d z)" % [j.robo.animacao_atual(), j.robo.expressao_atual(), zs.size()]) and ok
	await m._esperar(2.0)
	ok = m._conferir("dormindo, continua deitado", j.espera == "dormir" and j.robo.animacao_atual() == "festa/Lie_Idle") and ok
	# Um botão acorda.
	m._botao(JOY_BUTTON_Y, true)
	await m._esperar(0.05)
	m._botao(JOY_BUTTON_Y, false)
	await m._esperar(0.05)
	ok = m._conferir("um botão acorda na hora, com cara de surpreso", j.espera == "" and j.robo.expressao_atual() == "surpreso",
			"(%s, %s)" % [j.espera, j.robo.expressao_atual()]) and ok
	await m._esperar(0.6)
	ok = m._conferir("acordado, de pé de novo", j.robo.animacao_atual() == "geral/Idle_A", "(%s)" % j.robo.animacao_atual()) and ok
	# Teleportar (voltar ao começo, trocar de lugar) também zera.
	j.parado = 20.0
	j.teleportar(n.inicio + Vector3(0, 0.1, 0))
	ok = m._conferir("teleportar zera a espera", j.parado == 0.0 and j.espera == "") and ok
	print("ESPERA OK" if ok else "ESPERA COM FALHAS")
	m._terminar(ok)


func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "espera/"))
	await m._comecar_fase()
	var cam := Camera3D.new()
	cam.fov = 50.0
	m.add_child(cam)
	var p := n.inicio + Vector3(0, 0.1, 0)
	var fotos := [["olhar", 1.0], ["acenar", 1.4], ["flexoes", 1.2], ["abdominais", 0.9], ["sentar", 2.5], ["dancinha", 1.3]]
	for k in fotos.size():
		j.teleportar(p)
		await m._esperar(0.4)
		_camera(cam, p)
		_de_frente(cam)
		j.parado = 12.0
		j._espera.comecar(fotos[k][0])
		await m._esperar(fotos[k][1])
		await m._foto("espera/%02d_%s" % [k + 1, fotos[k][0]])
	j.teleportar(p)
	await m._esperar(0.4)
	_camera(cam, p)
	_de_frente(cam)
	j.parado = Espera.DORMIR
	await m._esperar(1.5)
	await m._foto("espera/07_deitando")
	await m._esperar(3.6)
	await m._foto("espera/08_dormindo")
	m.get_tree().quit()


## Vira o Faísca de frente para a câmera da foto (um pouco de lado).
func _de_frente(cam: Camera3D) -> void:
	var d := cam.global_position - j.global_position
	j.visual.rotation.y = atan2(d.x, d.z) + 0.5


## A câmera do lado e um pouco acima, olhando o Faísca de corpo inteiro.
func _camera(cam: Camera3D, p: Vector3) -> void:
	var atras := j.camera.global_position - p
	atras.y = 0.0
	atras = atras.normalized()
	var lado := atras.cross(Vector3.UP)
	cam.global_position = p + (atras * 0.8 + lado * 0.6).normalized() * 4.6 + Vector3.UP * 2.4
	cam.look_at(p + Vector3.UP * 1.0)
	cam.make_current()


func _ate(cond: Callable, segundos: float) -> void:
	var t := 0.0
	while t < segundos and not cond.call():
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
