class_name TesteChefe2
extends RefCounted
## Confere o chefe do andar 2, o Chef Bolotão na Cozinha do Chef (item 5 da lista do Faísca, 2026-11-11):
## - a arena: 12 estrelinhas, o bolo do meio, a torre de panquecas, as 3 tampas e o Chef em cima do bolo;
## - fase 1: ele joga bolinhos (o alvo aparece e o bolinho acerta quem está nele); a tampa joga o Faísca até o alto do
##   bolo, e lá o Chef se assusta e fica tonto; 3 socos passam de fase;
## - fase 2: ele pula para o chão e dá investidas; batendo na beira, fica tonto;
## - fase 3: ele sobe na torre, a bola de chiclete aparece e dá o Balão; com o balão o Faísca sobe até ele, que fica
##   tonto; vencido, solta moedas e o baú dourado; a estrela do baú termina a luta.
## Uso: godot --headless --path . -- --faisca-chefe-2

var m: Node
var n: Chefe2
var j: Jogador
var c: ChefeChef
var _ok := true


func _init(solo: Node) -> void:
	m = solo
	n = solo.nivel
	j = solo.jogador
	c = n.chefe


func _conferir(nome: String, cond: bool, extra := "") -> bool:
	print("%s %s %s" % ["OK    " if cond else "FALHOU", nome, extra])
	_ok = _ok and cond
	return cond


func _esperar(s: float) -> void:
	var t := 0.0
	while t < s:
		await m.get_tree().physics_frame
		t += m.get_physics_process_delta_time()


func _ate(cond: Callable, s: float) -> bool:
	var t := 0.0
	while t < s:
		if cond.call():
			return true
		await m.get_tree().physics_frame
		t += m.get_physics_process_delta_time()
	return cond.call()


func _proteger() -> void:
	j._invencivel = 999.0
	j.vida = Jogador.VIDA_MAX


func rodar() -> void:
	j.controle_ligado = false
	await _esperar(0.4)
	_conferir("a arena: 12 estrelinhas, as 3 tampas e o Chef em cima do bolo", n.estrelas.size() == 12 and n.tampas.size() == 3
			and absf(c.global_position.y - Chefe2.ALTURA_BOLO) < 0.4 and c.fase == 0)
	j.teleportar(n.inicio)
	j.controle_ligado = true
	await _ate(func() -> bool: return c.fase == 1, 4.0)
	_conferir("pisando na travessa, a luta começa (fase 1)", c.fase == 1)
	# Os bolinhos: acertam quem está no alvo.
	j._invencivel = 0.0
	var antes := n.bolinhos_que_acertaram
	await _ate(func() -> bool: return n.bolinhos_que_acertaram > antes, 6.0)
	_conferir("fase 1: ele joga bolinhos, e o que cai no alvo do Faísca tira um coração", n.bolinhos_jogados > 0
			and n.bolinhos_que_acertaram > antes, "(%d jogados)" % n.bolinhos_jogados)
	_proteger()
	# A tampa da panela do sul joga o Faísca para o alto, e de lá ele chega ao bolo.
	var tampa: TampaQuePula = n.tampas[1]
	j.teleportar(tampa.global_position + Vector3.UP * 0.4)
	j.velocity = Vector3.ZERO
	var subiu := [0.0]
	await _ate(func() -> bool:
		subiu[0] = maxf(subiu[0], j.global_position.y)
		return subiu[0] > Chefe2.ALTURA_BOLO + 1.0, 6.0)
	_conferir("a tampa joga o Faísca acima do alto do bolo", subiu[0] > Chefe2.ALTURA_BOLO + 1.0, "(%.1f m)" % subiu[0])
	# Em cima do bolo, o Chef se assusta e fica tonto.
	j.teleportar(Vector3(2.5, Chefe2.ALTURA_BOLO + 0.2, 0))
	await _ate(func() -> bool: return c.estado == "tonto", 2.0)
	_conferir("chegando no alto do bolo, o Chef se assusta e fica tonto", c.estado == "tonto")
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	_conferir("tonto, 3 socos passam para a fase 2", c.fase == 2)
	# Fase 2: ele pula para o chão e corre; batendo na beira, fica tonto.
	j.teleportar(Vector3(0, 0.1, 13.0))
	await _ate(func() -> bool: return c.estado == "investida", 6.0)
	_conferir("fase 2: ele pula para o chão e dá investidas", c.vistos.has("investida") and c.global_position.y < 1.0)
	await _ate(func() -> bool: return c.estado == "tonto", 6.0)
	_conferir("batendo na beira (o Faísca saiu da frente), ele fica tonto", c.estado == "tonto")
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	_conferir("tonto, 3 socos passam para a fase 3", c.fase == 3)
	# Fase 3: a torre e o balão.
	await _ate(func() -> bool: return c.estado == "jogando" and n.bola_de_chiclete != null, 4.0)
	_conferir("fase 3: ele sobe na torre de panquecas e a bola de chiclete aparece", c.global_position.y > Chefe2.ALTURA_TORRE - 0.6
			and n.bola_de_chiclete != null)
	j.teleportar(n.bola_de_chiclete.global_position - Vector3(0, 1.0, 0))
	await _esperar(0.3)
	_conferir("a bola de chiclete dá o Balão de Chiclete", j.balao_de_chiclete)
	# Subindo com o balão: pula ao lado da torre, segura o pulo e chega lá em cima.
	var junto := Chefe2.TORRE + Vector3(0, 0.1, Chefe2.RAIO_TORRE + 1.0)
	j.teleportar(junto)
	j.yaw = 0.0
	await _esperar(0.3)
	j.forcar_pulo = true
	var alto := [0.0]
	await _ate(func() -> bool:
		alto[0] = maxf(alto[0], j.global_position.y)
		return alto[0] > Chefe2.ALTURA_TORRE + 0.5, 6.0)
	j.forcar_pulo = false
	_conferir("com o balão, o Faísca sobe acima do alto da torre", alto[0] > Chefe2.ALTURA_TORRE + 0.5, "(%.1f m)" % alto[0])
	j.teleportar(Chefe2.TORRE + Vector3(1.8, Chefe2.ALTURA_TORRE + 0.2, 0))
	await _ate(func() -> bool: return c.estado == "tonto", 2.0)
	_conferir("lá em cima, ele fica tonto", c.estado == "tonto")
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	await _ate(func() -> bool: return n.bau != null, 4.0)
	_conferir("vencido: o baú dourado cai do céu", c.derrotado and n.bau != null and n.bau.dourado)
	var terminou := [false]
	n.estrela_grande_pega.connect(func() -> void: terminou[0] = true)
	await _esperar(1.2)
	var bau := n.bau
	j.teleportar(bau.global_position + bau.global_basis.z * 2.6)
	await _esperar(0.3)
	for k in 3:
		bau.receber_golpe(1, j.global_position)
		await _esperar(0.35)
	await _ate(func() -> bool: return bau._estrela_pronta, 3.0)
	j.teleportar(bau.estrela.global_position - Vector3(0, 1.2, 0))
	await _ate(func() -> bool: return terminou[0], 3.0)
	_conferir("a estrela do baú termina a luta", terminou[0])
	print("CHEFE 2 OK" if _ok else "CHEFE 2 COM FALHAS")
	m.get_tree().quit()


## Fotos (com janela), em tools/capturas/faisca/chefe_2/: a arena, os bolinhos, o Faísca no bolo com o Chef tonto,
## a investida, a torre com o balão e o baú.
func capturar() -> void:
	var dir := ProjectSettings.globalize_path("res://tools/capturas/faisca/chefe_2/")
	DirAccess.make_dir_recursive_absolute(dir)
	var cam := Camera3D.new()
	cam.fov = 62.0
	m.add_child(cam)
	cam.make_current()
	cam.global_position = Vector3(10, 9, 21)
	cam.look_at(Vector3(0, 4.0, -2))
	j.teleportar(n.inicio)
	j.controle_ligado = true
	_proteger()
	await _esperar(1.0)
	await _foto(cam, dir + "d1_arena.png")
	n.comecar_luta()
	await _ate(func() -> bool: return n.bolinhos_jogados >= 2, 6.0)
	await _esperar(0.5)
	await _foto(cam, dir + "d2_bolinhos.png")
	j.teleportar(Vector3(2.5, Chefe2.ALTURA_BOLO + 0.2, 0))
	await _ate(func() -> bool: return c.estado == "tonto", 2.0)
	await _esperar(0.4)
	cam.global_position = Vector3(6, 12, 9)
	cam.look_at(Vector3(0, 8, 0))
	await _foto(cam, dir + "d3_chef_tonto_no_bolo.png")
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	j.teleportar(Vector3(0, 0.1, 13.0))
	await _ate(func() -> bool: return c.estado == "investida", 6.0)
	cam.global_position = Vector3(10, 9, 21)
	cam.look_at(Vector3(0, 2.0, 2))
	await _esperar(0.3)
	await _foto(cam, dir + "d4_investida.png")
	c.cansar()
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	await _ate(func() -> bool: return c.estado == "jogando" and n.bola_de_chiclete != null, 4.0)
	cam.global_position = Vector3(12, 10, 2)
	cam.look_at(Chefe2.TORRE + Vector3.UP * 7.0)
	await _esperar(0.6)
	await _foto(cam, dir + "d5_torre_e_chiclete.png")
	j.teleportar(Chefe2.TORRE + Vector3(1.8, Chefe2.ALTURA_TORRE + 0.2, 0))
	await _ate(func() -> bool: return c.estado == "tonto", 2.0)
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	await _ate(func() -> bool: return n.bau != null, 4.0)
	await _esperar(1.6)
	cam.global_position = Vector3(6, 6, 20)
	cam.look_at(Vector3(0, 1.0, 9))
	await _foto(cam, dir + "d6_bau_dourado.png")
	m.get_tree().quit()


func _foto(cam: Camera3D, caminho: String) -> void:
	cam.make_current()
	await RenderingServer.frame_post_draw
	m.get_viewport().get_texture().get_image().save_png(caminho)
	print("foto: ", caminho.get_file())
