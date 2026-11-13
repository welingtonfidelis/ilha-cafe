class_name TesteParticulas
extends RefCounted
## Fotos das partículas do Kenney dentro da 1-1 (2026-11-13), chamadas pelo FaiscaSolo:
##   --faisca-particulas-captura   o Faísca socando uma Bolota (o "pow!" e o puf), pegando estrelinha, pulando e pousando
##                                 (a poeira), girando no ar, pegando coração e dando curto, em
##                                 tools/capturas/faisca/particulas/ (precisa de janela)
##   --faisca-giro-captura         os efeitos no jeito do Astro Bot (2026-11-13): a carga (o corpo acendendo azul e os
##                                 brilhinhos rodando), a carga solta (o clarão e a onda no chão), o disco do giro forte,
##                                 a tontura, o "zuim" do soco, o disco do giro no ar e a onda do pouso alto, na mesma pasta

var m: Node
var n: Fase
var j: Jogador


func _init(main: Node) -> void:
	m = main
	n = main.nivel
	j = main.jogador
	main.testando = true


func capturar() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "particulas/"))
	m._comecar_fase()
	await m._esperar(4.0)
	var cam := Camera3D.new()
	cam.fov = 55.0
	m.add_child(cam)
	# O soco numa Bolota (a de mais perto do começo), de lado: o "pow!" e, no segundo, o puf.
	var bolota: Bolota = null
	for a in n.alvos:
		if a is Bolota and not a.derrotado and (bolota == null or a.global_position.distance_to(n.inicio) < bolota.global_position.distance_to(n.inicio)):
			bolota = a
	if bolota:
		bolota.process_mode = Node.PROCESS_MODE_DISABLED
		var fora := ((n.inicio - bolota.global_position) * Vector3(1, 0, 1)).normalized()
		j.teleportar(bolota.global_position + fora * 1.6 + Vector3.UP * 0.1)
		_olhar(bolota.global_position)
		# De lado da linha do soco (atrás do Faísca, ele tapava o "pow!").
		_de_lado(cam, (j.global_position + bolota.global_position) * 0.5 + Vector3.UP * 0.6, fora.cross(Vector3.UP), 3.6)
		await m._esperar(0.5)
		j.forcar_golpe = true
		await _ate_o_efeito("Kenney_soco", 0.6)
		await m._foto("particulas/01_soco")
		bolota.vida = 1
		bolota.process_mode = Node.PROCESS_MODE_INHERIT
		await m._esperar(0.5)
		j.forcar_golpe = true
		await _ate(func() -> bool: return bolota.derrotado, 1.0)
		await m._esperar(0.18)
		await m._foto("particulas/02_bolota_estoura")
	# A estrelinha pega.
	var estrela: Area3D = n.estrelas[n.estrelas.size() / 2]
	j.teleportar(estrela.global_position + Vector3(0, -1.0, 2.5))
	_de_lado(cam, estrela.global_position + Vector3.DOWN * 0.4, Vector3.BACK, 4.0)
	await m._esperar(0.5)
	j.teleportar(estrela.global_position - Vector3(0, 1.0, 0))
	await m._esperar(0.12)
	await m._foto("particulas/03_estrelinha")
	# O pulo e o pouso (a poeira).
	j.teleportar(n.inicio + Vector3(0, 3.0, 0))
	_de_lado(cam, n.inicio + Vector3.UP * 0.8, Vector3.BACK, 4.5)
	# Logo depois de teleportar, o "no chão" ainda vale um instante.
	await m._esperar(0.25)
	var t := 0.0
	while t < 3.0 and not j.is_on_floor():
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
	await m._esperar(0.1)
	await m._foto("particulas/04_poeira_do_pouso")
	# O giro no ar.
	await m._esperar(0.6)
	j.forcar_pulo = true
	await m._esperar(0.2)
	j.forcar_pulo = false
	j.forcar_golpe = true
	await m._esperar(0.12)
	_de_lado(cam, j.global_position + Vector3.UP * 1.0, Vector3.BACK, 4.0)
	await m._esperar(0.04)
	await m._foto("particulas/05_giro")
	await m._esperar(1.0)
	# O coração (com um coração a menos).
	if not n.coracoes.is_empty():
		var c: Area3D = n.coracoes[0]
		j.vida = 2
		j.teleportar(c.global_position + Vector3(0, -1.0, 2.6))
		_de_lado(cam, c.global_position, Vector3.BACK, 4.0)
		await m._esperar(0.5)
		j.teleportar(c.global_position - Vector3(0, 1.0, 0))
		await m._esperar(0.22)
		await m._foto("particulas/06_coracao")
	# O curto (sem corações).
	j.teleportar(n.inicio + Vector3(0, 0.1, 0))
	_de_lado(cam, n.inicio + Vector3.UP * 1.1, Vector3.BACK, 4.0)
	await m._esperar(0.6)
	# Sem o empurrão do dano (que tirava o Faísca do quadro): o último coração vai e vem o curto.
	j.vida = 1
	j._perder_coracao()
	await m._esperar(0.1)
	await m._foto("particulas/07_curto")
	await m._esperar(1.6)
	m.get_tree().quit()


func capturar_giro() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "particulas/"))
	m._comecar_fase()
	await m._esperar(4.0)
	var cam := Camera3D.new()
	cam.fov = 55.0
	m.add_child(cam)
	var p := n.inicio + Vector3(0, 0.1, 0)
	j.teleportar(p)
	_alto(cam, p + Vector3.UP * 0.9, 6.0)
	await m._esperar(0.6)
	# A carga: segurando X no chão (o primeiro soco sai antes).
	m._botao(JOY_BUTTON_X, true)
	await _ate(func() -> bool: return j._carga > Jogador.TEMPO_CARGA * 0.7, 2.0)
	await m._foto("particulas/08_carga")
	await _ate(func() -> bool: return j.giro_forte > 0.0, 1.0)
	await m._esperar(0.05)
	await m._foto("particulas/09_carga_solta")
	m._botao(JOY_BUTTON_X, false)
	await m._esperar(0.3)
	await m._foto("particulas/10_giro_forte")
	await _ate(func() -> bool: return j.giro_forte <= 0.0, 1.5)
	await m._esperar(0.2)
	await m._foto("particulas/11_tontura")
	await m._esperar(1.0)
	# O "zuim" do soco, numa Bolota parada.
	var bolota: Bolota = null
	for a in n.alvos:
		if a is Bolota and not a.derrotado and (bolota == null or a.global_position.distance_to(n.inicio) < bolota.global_position.distance_to(n.inicio)):
			bolota = a
	if bolota:
		bolota.process_mode = Node.PROCESS_MODE_DISABLED
		var fora := ((n.inicio - bolota.global_position) * Vector3(1, 0, 1)).normalized()
		j.teleportar(bolota.global_position + fora * 1.7 + Vector3.UP * 0.1)
		_olhar(bolota.global_position)
		# Pela câmera do jogo (atrás e um pouco acima), como a criança vê.
		j.camera.make_current()
		await m._esperar(0.5)
		j.forcar_golpe = true
		# O _golpe_acertou ainda vale do golpe de antes: primeiro espera este começar.
		await _ate(func() -> bool: return j.golpe_atual == 0 and not j._golpe_acertou, 0.3)
		await _ate(func() -> bool: return j._golpe_acertou, 0.6)
		await m._esperar(0.04)
		await m._foto("particulas/12_zuim")
		await _ate(func() -> bool: return j.golpe_atual < 0, 0.6)
		j.forcar_golpe = true
		await m._esperar(0.1)
		j.forcar_golpe = true
		await _ate(func() -> bool: return j.golpe_atual == 2 and j._golpe_acertou, 1.2)
		await m._esperar(0.04)
		await m._foto("particulas/12b_zuim_forte")
		bolota.process_mode = Node.PROCESS_MODE_INHERIT
		await m._esperar(1.0)
	# O giro no ar.
	j.teleportar(p)
	_alto(cam, p + Vector3.UP * 1.6, 6.0)
	await m._esperar(0.6)
	j.forcar_pulo = true
	await m._esperar(0.2)
	j.forcar_pulo = false
	j.forcar_golpe = true
	await m._esperar(0.15)
	await m._foto("particulas/13_giro_no_ar")
	await m._esperar(1.2)
	# O pouso de bem alto.
	j.teleportar(p + Vector3.UP * 9.0)
	_alto(cam, p + Vector3.UP * 0.5, 7.0)
	await m._esperar(0.25)
	await _ate(func() -> bool: return j.is_on_floor(), 4.0)
	await m._esperar(0.12)
	await m._foto("particulas/14_pouso_alto")
	await m._esperar(0.6)
	m.get_tree().quit()


## Quadro a quadro do giro pela câmera do jogo (a carga com a torcida, a volta acelerando e freando, os rastros das
## mãos e o giro no ar), em tools/capturas/faisca/giro/. Uso: godot --path . -- --faisca-giro-quadros
func capturar_giro_quadros() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "giro/"))
	m._comecar_fase()
	await m._esperar(4.0)
	var p := n.inicio + Vector3(0, 0.1, 0)
	j.teleportar(p)
	j.visual.rotation.y = j.yaw + PI
	j.camera.make_current()
	await m._esperar(0.8)
	m._botao(JOY_BUTTON_X, true)
	# A carga começa uns 0,3 s depois de apertar (o primeiro soco sai antes).
	await _ate(func() -> bool: return j._carga > 0.0, 1.0)
	var quadros := [["01_carga", 0.15], ["02_carga_torcendo", 0.4]]
	for q: Array in quadros:
		await _ate(func() -> bool: return j._carga >= float(q[1]) or j.giro_forte > 0.0, 1.0)
		await m._foto("giro/" + q[0])
	await _ate(func() -> bool: return j.giro_forte > 0.0, 1.0)
	m._botao(JOY_BUTTON_X, false)
	var marcas := [0.04, 0.12, 0.22, 0.36, 0.52, 0.7, 0.86, 0.97]
	for k in marcas.size():
		await _ate(func() -> bool: return Jogador.TEMPO_GIRO_FORTE - j.giro_forte >= marcas[k] or j.giro_forte <= 0.0, 1.5)
		await m._foto("giro/%02d_giro_%03d" % [k + 3, int(marcas[k] * 100)])
	await _ate(func() -> bool: return j.giro_forte <= 0.0, 1.5)
	await m._esperar(0.1)
	await m._foto("giro/11_fim")
	await m._esperar(0.3)
	await m._foto("giro/12_tontinho")
	await m._esperar(1.2)
	# O giro no ar.
	j.forcar_pulo = true
	await m._esperar(0.22)
	j.forcar_pulo = false
	j.forcar_golpe = true
	await _ate(func() -> bool: return j.girando > 0.0, 0.3)
	for k in 4:
		await m._esperar(0.08)
		await m._foto("giro/%02d_no_ar" % (13 + k))
	await m._esperar(0.8)
	m.get_tree().quit()


## Fotos do visual do Faísca dentro da 1-1, para comparar antes e depois (2026-11-13, o usuário quer o Faísca mais
## simpático, como o Astro): pela câmera do jogo de costas e de frente, e de perto, de três quartos. Uso:
## godot --path . -- --faisca-visual-captura --prefixo=antes  (em tools/capturas/faisca/visual/)
func capturar_visual() -> void:
	var prefixo := "foto"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--prefixo="):
			prefixo = a.substr(10)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "visual/"))
	m._comecar_fase()
	await m._esperar(4.0)
	var p := n.inicio + Vector3(0, 0.1, 0)
	j.teleportar(p)
	j.camera.make_current()
	j.visual.rotation.y = j.yaw + PI
	await m._esperar(1.0)
	await m._foto("visual/%s_1_jogo_costas" % prefixo)
	var d := j.camera.global_position - j.global_position
	j.visual.rotation.y = atan2(d.x, d.z) + 0.35
	j.robo.expressao("feliz", 3.0)
	await m._esperar(0.6)
	await m._foto("visual/%s_2_jogo_frente" % prefixo)
	var cam := Camera3D.new()
	cam.fov = 40.0
	m.add_child(cam)
	var frente := Vector3(sin(j.visual.rotation.y), 0, cos(j.visual.rotation.y))
	cam.global_position = p + frente * 3.4 + frente.cross(Vector3.UP) * 1.2 + Vector3.UP * 1.9
	cam.look_at(p + Vector3.UP * 1.3)
	cam.make_current()
	j.robo.expressao("normal")
	await m._esperar(0.6)
	await m._foto("visual/%s_3_perto" % prefixo)
	# Parado um tempo: a cabeça inclinando (dois instantes).
	await m._esperar(2.2)
	await m._foto("visual/%s_4_parado_a" % prefixo)
	await m._esperar(1.6)
	await m._foto("visual/%s_5_parado_b" % prefixo)
	# Correndo e parando de repente: a antena balança. Câmera de lado.
	j.teleportar(p)
	await m._esperar(0.3)
	var lado := Vector3(sin(j.yaw), 0, cos(j.yaw)).cross(Vector3.UP)
	cam.global_position = p + Vector3(0, 0, 0) + Vector3(-sin(j.yaw), 0, -cos(j.yaw)) * 3.0 + lado * 5.0 + Vector3.UP * 1.8
	cam.look_at(p + Vector3(-sin(j.yaw), 0, -cos(j.yaw)) * 3.0 + Vector3.UP * 1.3)
	j.forcar_direcao = Vector2(0, -1)
	await m._esperar(0.45)
	await m._foto("visual/%s_6_correndo" % prefixo)
	j.forcar_direcao = Vector2.ZERO
	await m._esperar(0.12)
	await m._foto("visual/%s_7_parando" % prefixo)
	m.get_tree().quit()


## As bolhas de sabão da pia (2-1), pela câmera do jogo, saindo do P3, e de lado mais perto (2026-11-13: as crianças
## tinham dificuldade de ver as bolhas). Uso: godot --path . -- --faisca-bolhas-captura --prefixo=antes
## (em tools/capturas/faisca/bolhas/)
func capturar_bolhas() -> void:
	var prefixo := "foto"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--prefixo="):
			prefixo = a.substr(10)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(m.PASTA_CAPTURAS + "bolhas/"))
	m._comecar_fase()
	await m._esperar(4.0)
	j.teleportar(Vector3(21.5, 8.1, -94.0))
	j.yaw = PI
	j.pitch = -0.32
	j.visual.rotation.y = 0.0
	j.camera.make_current()
	await m._esperar(1.5)
	await m._foto("bolhas/%s_1_saindo_do_posto" % prefixo)
	j.teleportar(Vector3(22.5, 8.9, -80.0))
	j.yaw = PI
	await m._esperar(1.5)
	await m._foto("bolhas/%s_2_no_prato" % prefixo)
	var cam := Camera3D.new()
	cam.fov = 50.0
	m.add_child(cam)
	cam.global_position = Vector3(12.0, 13.0, -80.0)
	cam.look_at(Vector3(21.0, 8.0, -76.0))
	cam.make_current()
	await m._esperar(0.5)
	await m._foto("bolhas/%s_3_de_lado" % prefixo)
	m.get_tree().quit()


## Câmera de cima e de lado (uns 35 graus), a `longe` m de `meio`, do lado `para`.
func _alto(cam: Camera3D, meio: Vector3, longe: float, para := Vector3.BACK) -> void:
	var lado := para.cross(Vector3.UP).normalized()
	cam.global_position = meio + (para.normalized() * 0.75 + lado * 0.35).normalized() * longe * 0.82 + Vector3.UP * longe * 0.57
	cam.look_at(meio)
	cam.make_current()


## Câmera de lado, a `longe` m de `meio`, do lado `para` (mais um pouco para a direita e para cima).
func _de_lado(cam: Camera3D, meio: Vector3, para: Vector3, longe: float) -> void:
	var lado := para.cross(Vector3.UP).normalized()
	cam.global_position = meio + para.normalized() * longe + lado * longe * 0.5 + Vector3.UP * 1.0
	cam.look_at(meio)
	cam.make_current()


## Espera aparecer um efeito de partícula novo (o golpe solta no pai do Faísca, que aqui é o FaiscaSolo), até `segundos`.
func _ate_o_efeito(_nome: String, segundos: float) -> void:
	var pai := j.get_parent()
	var antes := pai.get_children().filter(func(c: Node) -> bool: return c is CPUParticles3D).size()
	await _ate(func() -> bool: return pai.get_children().filter(func(c: Node) -> bool: return c is CPUParticles3D).size() > antes, segundos)
	await m._esperar(0.03)


func _ate(cond: Callable, segundos: float) -> void:
	var t := 0.0
	while t < segundos and not cond.call():
		await m.get_tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second


## Vira o Faísca para `alvo`.
func _olhar(alvo: Vector3) -> void:
	var d := alvo - j.global_position
	j.visual.rotation.y = atan2(d.x, d.z)
	j.yaw = atan2(-d.x, -d.z)
	j.pitch = -0.2
