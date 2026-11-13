class_name TesteChefe1
extends RefCounted
## Confere o chefe do andar 1, o Bolotão Fofão no Ninho das Nuvens (item 5 da lista do Faísca, 2026-11-11):
## - a arena: 12 estrelinhas, o chefe dormindo no meio e a parede invisível da beira;
## - a luta começa quando o Faísca pisa na arena;
## - fase 1: ele pula (com a sombra onde vai cair) e o pouso solta a onda, que acerta quem está no chão e não quem está
##   no ar; depois de 3 pisões fica tonto, e 3 socos passam de fase;
## - fase 2: cospe Bolotinhas (um soco deixa tonta); soco nele não adianta; a Bolotinha arremessada deixa tonto;
## - fase 3: as 4 flores aparecem e ele dá investidas; acesas as flores, fica tonto; vencido, solta moedas e o baú
##   dourado cai do céu; a estrela do baú termina a fase.
## Uso: godot --headless --path . -- --faisca-chefe-1

var m: Node
var n: Chefe1
var j: Jogador
var c: ChefeBolotao
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


## Longe e sem levar dano, enquanto espera o chefe.
func _proteger() -> void:
	j._invencivel = 999.0
	j.vida = Jogador.VIDA_MAX


func rodar() -> void:
	j.controle_ligado = false
	await _esperar(0.4)
	_conferir("a arena: 12 estrelinhas e o chefe dormindo no meio", n.estrelas.size() == 12 and c.fase == 0 and c.estado == "dormindo")
	# A parede da beira: andando para fora, ele fica na arena.
	j.teleportar(Vector3(0, 0.1, Chefe1.RAIO - 2.0))
	j.controle_ligado = true
	j.yaw = 0.0
	j.forcar_direcao = Vector2(0, 1)
	await _esperar(1.6)
	j.forcar_direcao = Vector2.ZERO
	var r := Vector2(j.global_position.x, j.global_position.z).length()
	_conferir("a parede invisível da beira segura o Faísca na arena", r < Chefe1.RAIO + 0.3 and j.global_position.y > -1.0, "(%.1f m do meio)" % r)
	await _ate(func() -> bool: return c.fase == 1, 4.0)
	_conferir("pisando na arena, a luta começa (fase 1)", c.fase == 1)
	_proteger()
	# Fase 1: o pulo com a sombra e a onda.
	var viu_sombra := [false]
	await _ate(func() -> bool:
		viu_sombra[0] = viu_sombra[0] or n.get_node_or_null("Sombra") != null
		return c.estado == "pulando", 8.0)
	await _ate(func() -> bool:
		viu_sombra[0] = viu_sombra[0] or n.get_node_or_null("Sombra") != null
		return not n._ondas.is_empty(), 4.0)
	_conferir("fase 1: ele pula, a sombra mostra onde cai, e o pouso solta a onda", c.vistos.has("pulando") and viu_sombra[0] and not n._ondas.is_empty())
	# A onda acerta quem está no chão: o Faísca a 6 m do pouso, no chão, sem estar invencível.
	await _ate(func() -> bool: return n._ondas.is_empty(), 3.0)
	await _ate(func() -> bool: return c.estado == "pulando", 8.0)
	await _ate(func() -> bool: return not n._ondas.is_empty(), 4.0)
	var centro: Vector3 = n._ondas[0].centro if not n._ondas.is_empty() else Vector3.ZERO
	# Do lado de dentro do pouso (para o meio), para não cair fora da arena.
	var dentro := (Vector3(0, 0, 1) if centro.length() < 0.5 else -centro.normalized())
	j.teleportar(centro + dentro * 6.0 + Vector3.UP * 0.1)
	j.velocity = Vector3.ZERO
	j._invencivel = 0.0
	var acertos := n.ondas_que_acertaram
	await _esperar(1.0)
	_conferir("a onda acerta quem está no chão", n.ondas_que_acertaram == acertos + 1, "(%d)" % (n.ondas_que_acertaram - acertos))
	# E não acerta quem está no ar (pulando por cima): o terceiro pisão, com o Faísca subindo.
	_proteger()
	await _ate(func() -> bool: return n._ondas.is_empty(), 3.0)
	await _ate(func() -> bool: return c.estado == "pulando", 8.0)
	await _ate(func() -> bool: return not n._ondas.is_empty(), 4.0)
	centro = n._ondas[0].centro if not n._ondas.is_empty() else Vector3.ZERO
	dentro = (Vector3(0, 0, 1) if centro.length() < 0.5 else -centro.normalized())
	j.teleportar(centro + dentro * 6.0 + Vector3.UP * 1.5)
	j.velocity = Vector3.UP * 9.0
	j._invencivel = 0.0
	acertos = n.ondas_que_acertaram
	await _esperar(1.0)
	_conferir("e não acerta quem está no ar, pulando por cima", n.ondas_que_acertaram == acertos)
	_proteger()
	await _ate(func() -> bool: return c.estado == "tonto", 14.0)
	_conferir("depois dos 3 pisões, ele cansa e fica tonto", c.estado == "tonto" and c.pulos >= ChefeBolotao.PULOS)
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	_conferir("tonto, 3 socos passam para a fase 2", c.fase == 2)
	# Fase 2: as Bolotinhas.
	await _ate(func() -> bool: return n.bolotinhas_vivas() >= 1 and c.estado == "cuspindo", 8.0)
	var b: BolotaMonstro = n.bolotinhas[0] if not n.bolotinhas.is_empty() else null
	_conferir("fase 2: ele cospe Bolotinhas", b != null)
	c._imune = 0.0
	var levou := c.receber_golpe(1, j.global_position, 6.0, "soco")
	_conferir("soco nele, fora do tonto, não adianta", not levou and c.golpes == 0 and c.estado != "tonto")
	if b:
		await _ate(func() -> bool: return b.is_on_floor(), 3.0)
		b._imune = 0.0
		b.receber_golpe(1, b.global_position + Vector3(0, 0, 1), 1.0, "soco")
		_conferir("um soco deixa a Bolotinha tonta (para agarrar)", b.tonta > 0.0 and not b.derrotado)
	c._imune = 0.0
	c.receber_golpe(1, c.global_position + Vector3(0, 1, 3), 7.0, "arremesso")
	_conferir("a Bolotinha arremessada nele deixa ele tonto", c.estado == "tonto")
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	_conferir("tonto, 3 socos passam para a fase 3, e as Bolotinhas que sobraram somem", c.fase == 3 and n.bolotinhas_vivas() == 0)
	# Fase 3: as flores e as investidas.
	await _ate(func() -> bool: return c.estado == "investida", 6.0)
	_conferir("fase 3: as 4 flores aparecem e ele dá investidas", n.flores_do_chefe.size() == 4 and c.vistos.has("investida"))
	for f in n.flores_do_chefe:
		f.acender()
	_conferir("as 4 flores acesas deixam ele tonto", c.estado == "tonto")
	var moedas_antes := n.get_children().filter(func(x: Node) -> bool: return x is Moeda).size()
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	await _ate(func() -> bool: return n.bau != null, 4.0)
	var moedas := n.get_children().filter(func(x: Node) -> bool: return x is Moeda).size() - moedas_antes
	_conferir("vencido: solta 40 moedas e o baú dourado cai do céu", c.derrotado and n.bau != null and n.bau.dourado and moedas >= 40,
			"(%d moedas)" % moedas)
	var terminou := [false]
	n.estrela_grande_pega.connect(func() -> void: terminou[0] = true)
	await _esperar(1.2)
	var bau := n.bau
	j._invencivel = 0.0
	j.teleportar(bau.global_position + bau.global_basis.z * 2.6)
	await _esperar(0.3)
	for k in 3:
		bau.receber_golpe(1, j.global_position)
		await _esperar(0.35)
	await _ate(func() -> bool: return bau._estrela_pronta, 3.0)
	j.teleportar(bau.estrela.global_position - Vector3(0, 1.2, 0))
	await _ate(func() -> bool: return terminou[0], 3.0)
	_conferir("a estrela do baú termina a luta", terminou[0])
	print("CHEFE 1 OK" if _ok else "CHEFE 1 COM FALHAS")
	m.get_tree().quit()


## Fotos (com janela), em tools/capturas/faisca/chefe_1/: a arena com o chefe, o pulo com a sombra, a onda, o tonto,
## as Bolotinhas, a investida com as flores e o baú dourado.
func capturar() -> void:
	var dir := ProjectSettings.globalize_path("res://tools/capturas/faisca/chefe_1/")
	DirAccess.make_dir_recursive_absolute(dir)
	var cam := Camera3D.new()
	cam.fov = 60.0
	m.add_child(cam)
	cam.make_current()
	cam.global_position = Vector3(9, 7, 17)
	cam.look_at(Vector3(0, 2.5, -2))
	j.controle_ligado = true
	_proteger()
	await _esperar(1.0)
	await _foto(cam, dir + "c1_arena.png")
	n.comecar_luta()
	await _ate(func() -> bool: return c.estado == "pulando" and c.velocity.y < 2.0, 10.0)
	await _foto(cam, dir + "c2_pulo_e_sombra.png")
	await _ate(func() -> bool: return not n._ondas.is_empty(), 4.0)
	await _esperar(0.35)
	await _foto(cam, dir + "c3_onda.png")
	await _ate(func() -> bool: return c.estado == "tonto", 14.0)
	await _esperar(0.5)
	await _foto(cam, dir + "c4_tonto.png")
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	await _ate(func() -> bool: return n.bolotinhas_vivas() >= 2, 12.0)
	await _esperar(0.8)
	await _foto(cam, dir + "c5_bolotinhas.png")
	c.receber_golpe(1, c.global_position + Vector3(0, 1, 3), 7.0, "arremesso")
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	await _ate(func() -> bool: return c.estado == "preparando", 6.0)
	await _esperar(0.5)
	await _foto(cam, dir + "c6_investida_e_flores.png")
	for f in n.flores_do_chefe:
		f.acender()
	for k in 3:
		c._imune = 0.0
		c.receber_golpe(1, j.global_position, 6.0, "soco")
	await _ate(func() -> bool: return n.bau != null, 4.0)
	await _esperar(1.6)
	await _foto(cam, dir + "c7_bau_dourado.png")
	m.get_tree().quit()


func _foto(cam: Camera3D, caminho: String) -> void:
	cam.make_current()
	await RenderingServer.frame_post_draw
	m.get_viewport().get_texture().get_image().save_png(caminho)
	print("foto: ", caminho.get_file())
