class_name TesteChefe3
extends RefCounted
## Confere o chefe do andar 3, o Pinguinzão do Gelo no Pico do Pinguinzão (item 5 da lista do Faísca, 2026-11-11):
## - a arena: 12 estrelinhas, o pilar com ele em cima e os 3 sinos;
## - fase 1: o Faísca ganha a Luva de Neve; a bola de neve grande acerta quem está no alvo; as bolas da luva (jogadas de
##   verdade, Jogador.jogar_bola_de_neve) tocam os 3 sinos, o pilar desmancha e ele cai tonto;
## - fase 2: a luva vira o Martelinho; a casca e os 4 pinos aparecem; a onda gelada acerta quem está no chão; afundados os
##   pinos, a casca quebra e ele fica tonto;
## - fase 3: o chão congela, a luva volta e ele desliza de barriga; as bolas da luva nele fazem ele tropeçar; vencido,
##   o baú dourado cai do céu e a estrela termina a luta.
## Uso: godot --headless --path . -- --faisca-chefe-3

var m: Node
var n: Chefe3
var j: Jogador
var c: ChefePinguim
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


## Vira o Faísca para `ponto` e joga uma bola da luva.
func _jogar_em(ponto: Vector3) -> void:
	var d := ponto - j.global_position
	j.visual.rotation.y = atan2(d.x, d.z)
	j.jogar_bola_de_neve()


func rodar() -> void:
	j.controle_ligado = false
	await _esperar(0.4)
	_conferir("a arena: 12 estrelinhas, os 3 sinos e o Pinguinzão em cima do pilar", n.estrelas.size() == 12 and n.sinos_do_chefe.size() == 3
			and absf(c.global_position.y - Chefe3.ALTURA_PILAR) < 0.4 and c.fase == 0)
	j.teleportar(n.inicio)
	j.controle_ligado = true
	await _ate(func() -> bool: return c.fase == 1, 4.0)
	_conferir("pisando no platô, a luta começa e o Faísca ganha a Luva de Neve", c.fase == 1 and j.luva_de_neve and not j.martelinho)
	j._invencivel = 0.0
	var antes := n.bolas_que_acertaram
	await _ate(func() -> bool: return n.bolas_que_acertaram > antes, 6.0)
	_conferir("fase 1: ele joga bolas de neve, e a que cai no alvo do Faísca tira um coração", n.bolas_que_acertaram > antes)
	_proteger()
	# Os 3 sinos com a luva, de verdade: de perto de cada um, virado para ele.
	for s in n.sinos_do_chefe.duplicate():
		var para_o_meio := -Vector3(s.global_position.x, 0, s.global_position.z).normalized()
		j.teleportar(Vector3(s.global_position.x, 0.1, s.global_position.z) + para_o_meio * 5.0)
		await _esperar(0.3)
		_jogar_em(s.ponto())
		await _ate(func() -> bool: return s.tocado, 3.0)
	_conferir("as bolas da luva tocam os 3 sinos", n.sinos_do_chefe.all(func(s: Sino) -> bool: return s.tocado))
	await _ate(func() -> bool: return c.estado == "tonto", 3.0)
	_conferir("tocados os três, o pilar desmancha e ele cai tonto", c.estado == "tonto" and c.global_position.y < 1.0)
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	_conferir("tonto, 3 socos passam para a fase 2", c.fase == 2)
	# Fase 2: a casca, os pinos e a onda.
	await _esperar(0.3)
	_conferir("fase 2: a casca, os 4 pinos, e a luva vira o Martelinho", is_instance_valid(n.casca) and n.pinos_do_chefe.size() == 4
			and j.martelinho and not j.luva_de_neve)
	await _ate(func() -> bool: return not n._ondas.is_empty(), 5.0)
	j.teleportar(Vector3(0, 0.1, 6.5))
	j.velocity = Vector3.ZERO
	j._invencivel = 0.0
	var acertos := n.ondas_que_acertaram
	await _esperar(1.2)
	_conferir("a onda gelada acerta quem está no chão", n.ondas_que_acertaram > acertos)
	_proteger()
	for p in n.pinos_do_chefe:
		p.bater()
	await _ate(func() -> bool: return c.estado == "tonto", 2.0)
	_conferir("afundados os 4 pinos, a casca quebra e ele fica tonto", not is_instance_valid(n.casca) and c.estado == "tonto")
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	_conferir("tonto, 3 socos passam para a fase 3", c.fase == 3)
	# Fase 3: o chão de gelo e as barrigadas.
	await _ate(func() -> bool: return c.estado == "barrigada", 4.0)
	_conferir("fase 3: o chão congela, a luva volta e ele desliza de barriga", n.chao_da_arena.has_meta("gelo") and j.luva_de_neve
			and c.vistos.has("barrigada"))
	j.teleportar(Vector3(0, 0.1, 0))
	await _esperar(0.3)
	for k in 10:
		if c.estado == "tonto":
			break
		_jogar_em(c.global_position + Vector3.UP * 2.0)
		await _esperar(0.7)
	_conferir("as bolas da luva nele fazem ele tropeçar e ficar tonto", c.estado == "tonto", "(%d tropeços)" % c.tropecos)
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	await _ate(func() -> bool: return n.bau != null, 4.0)
	_conferir("vencido: o chão degela e o baú dourado cai do céu", c.derrotado and n.bau != null and not n.chao_da_arena.has_meta("gelo"))
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
	print("CHEFE 3 OK" if _ok else "CHEFE 3 COM FALHAS")
	m.get_tree().quit()


## Fotos (com janela), em tools/capturas/faisca/chefe_3/: a arena, a casca com os pinos e a barrigada.
func capturar() -> void:
	var dir := ProjectSettings.globalize_path("res://tools/capturas/faisca/chefe_3/")
	DirAccess.make_dir_recursive_absolute(dir)
	var cam := Camera3D.new()
	cam.fov = 62.0
	m.add_child(cam)
	cam.make_current()
	cam.global_position = Vector3(10, 9, 21)
	cam.look_at(Vector3(0, 3.5, -2))
	j.teleportar(n.inicio)
	j.controle_ligado = true
	_proteger()
	await _esperar(1.0)
	await _foto(cam, dir + "e1_arena.png")
	n.comecar_luta()
	await _ate(func() -> bool: return n.bolas_jogadas >= 2, 6.0)
	await _esperar(0.5)
	await _foto(cam, dir + "e2_bolas_de_neve.png")
	for s in n.sinos_do_chefe:
		s.tocar()
	await _ate(func() -> bool: return c.estado == "tonto", 3.0)
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	await _ate(func() -> bool: return not n._ondas.is_empty(), 5.0)
	await _esperar(0.5)
	await _foto(cam, dir + "e3_casca_e_pinos.png")
	for p in n.pinos_do_chefe:
		p.bater()
	await _ate(func() -> bool: return c.estado == "tonto", 2.0)
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	await _ate(func() -> bool: return c.estado == "barrigada", 4.0)
	await _esperar(0.6)
	await _foto(cam, dir + "e4_barrigada.png")
	m.get_tree().quit()


func _foto(cam: Camera3D, caminho: String) -> void:
	cam.make_current()
	await RenderingServer.frame_post_draw
	m.get_viewport().get_texture().get_image().save_png(caminho)
	print("foto: ", caminho.get_file())
