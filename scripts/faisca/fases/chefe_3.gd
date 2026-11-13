class_name Chefe3
extends Fase
## Chefe do andar 3: o Pinguinzão do Gelo no Pico do Pinguinzão (item 5 da lista de melhorias do Faísca, 2026-11-11; a
## porta no 3º andar do farol, a noroeste, abre com 7 Estrelas Grandes). Um platô redondo de neve (RAIO m) no alto
## da montanha, acima das nuvens, com a parede invisível na beira, pinheiros nevados em volta e uma roda de 12
## estrelinhas. A luta (ChefePinguim) tem três fases, e aqui ficam:
## - fase 1: o pilar de gelo do meio (6 m), com ele em cima jogando bolas de neve (o alvo azul antes), e os 3 sinos em
##   colunas de gelo na beira; o Faísca ganha a Luva de Neve, e tocados os três sinos o pilar desmancha;
## - fase 2: a casca de gelo em volta dele, as ondas geladas que saem dela (pular por cima) e os 4 pinos em volta; o
##   Faísca troca a luva pelo Martelinho de Apito, e afundados os quatro pinos a casca quebra;
## - fase 3: o chão congela (escorrega, como o gelo da 3-1) e o Faísca volta a ter a luva, para acertar o Pinguinzão
##   deslizando de barriga;
## - um coração a cada fase nova e, no fim, 40 moedas e o baú dourado.

const ID := "chefe-3"
const RAIO := 16.0
const PILAR := 2.6
const ALTURA_PILAR := 6.0
const SINOS := [60.0, 180.0, 300.0]
const PINOS := [45.0, 135.0, 225.0, 315.0]
const ONDA_ATE := 14.0
const ONDA_TEMPO := 1.5
const VOO_BOLA := 1.3

signal faixa_pedida(titulo: String, sub: String)

var chefe: ChefePinguim
var chao_da_arena: StaticBody3D
var pilar: StaticBody3D
var sinos_do_chefe: Array[Sino] = []
var _colunas: Array[Node3D] = []
var pinos_do_chefe: Array[Pino] = []
var casca: StaticBody3D
var ondas_que_acertaram := 0
var bolas_que_acertaram := 0
var bolas_jogadas := 0
var _ondas: Array[Dictionary] = []
var _comecou := false
var _espera := 1.2


func _montar() -> void:
	nome = "Chefe: Pinguinzão do Gelo"
	superficie = "neve"
	inicio = Vector3(0, 0.1, 12.5)
	limite_queda = -10.0
	farol(Vector3(-80, -14, -300), 2.0)
	_plato()
	_pilar()
	roda(Vector3(0, 1.0, 0), RAIO - 3.0, 12)
	chefe = ChefePinguim.new()
	chefe.name = "Pinguinzao"
	chefe.arena = self
	chefe.position = Vector3(0, ALTURA_PILAR, 0)
	add_child(chefe)
	chefe.fase_mudou.connect(_fase_mudou)
	chefe.vencido.connect(_vitoria)


## O platô: o tampo de neve, a borda de gelo azulado, a pedra por baixo, os pinheiros nevados e a parede invisível.
func _plato() -> void:
	chao_da_arena = StaticBody3D.new()
	add_child(chao_da_arena)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = RAIO + 0.6
	cil.height = 2.0
	cs.shape = cil
	cs.position.y = -1.0
	chao_da_arena.add_child(cs)
	for spec in [[RAIO + 0.6, RAIO + 0.6, 0.6, -0.3, Color("f4fbff")], [RAIO + 0.5, RAIO - 0.6, 1.6, -1.4, Color("bfe3f5")],
			[RAIO - 0.6, 3.0, 9.0, -6.6, Color("8f9bb0")]]:
		var mi := MeshInstance3D.new()
		var forma := CylinderMesh.new()
		forma.top_radius = spec[0]
		forma.bottom_radius = spec[1]
		forma.height = spec[2]
		forma.radial_segments = 48
		mi.mesh = forma
		mi.material_override = _material(spec[4])
		mi.position.y = spec[3]
		add_child(mi)
	var muro := StaticBody3D.new()
	add_child(muro)
	for k in 32:
		var a := TAU * k / 32.0
		var parte := CollisionShape3D.new()
		var caixa := BoxShape3D.new()
		caixa.size = Vector3(2.0 * PI * RAIO / 32.0 + 0.6, 6.0, 0.6)
		parte.shape = caixa
		parte.position = Vector3(sin(a), 0, cos(a)) * (RAIO + 0.2) + Vector3.UP * 3.0
		parte.rotation.y = a
		muro.add_child(parte)
	# Pinheiros nevados na beira (do pacote da festa de fim de ano), de enfeite, longe dos sinos.
	for k in 9:
		var a := TAU * (k + 0.5) / 9.0
		if SINOS.any(func(g: float) -> bool: return absf(angle_difference(a, deg_to_rad(g))) < 0.35) or absf(angle_difference(a, PI)) < 0.4:
			continue
		so_enfeite(peca_de("res://assets/faisca/neve/", "christmas_tree_withoutLights", Vector3(sin(a), 0, cos(a)) * (RAIO - 0.8),
				a, 2.2, false))


func _gelo(alfa := 0.75) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.7, 0.9, 1.0, alfa)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.08
	m.metallic_specular = 1.0
	m.rim_enabled = true
	m.emission_enabled = true
	m.emission = Color("6fc8ff")
	m.emission_energy_multiplier = 0.25
	return m


## O pilar de gelo do meio, com o Pinguinzão em cima, e os 3 sinos novos em colunas de gelo na beira.
func _pilar() -> void:
	pilar = StaticBody3D.new()
	pilar.name = "Pilar"
	add_child(pilar)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = PILAR
	cil.height = ALTURA_PILAR
	cs.shape = cil
	cs.position.y = ALTURA_PILAR * 0.5
	pilar.add_child(cs)
	var mi := MeshInstance3D.new()
	var forma := CylinderMesh.new()
	forma.top_radius = PILAR
	forma.bottom_radius = PILAR + 0.4
	forma.height = ALTURA_PILAR
	forma.radial_segments = 6
	mi.mesh = forma
	mi.material_override = _gelo(0.85)
	mi.position.y = ALTURA_PILAR * 0.5
	pilar.add_child(mi)
	_novos_sinos()


func _novos_sinos() -> void:
	for s in sinos_do_chefe:
		if is_instance_valid(s):
			s.queue_free()
	sinos_do_chefe.clear()
	for c in _colunas:
		if is_instance_valid(c):
			c.queue_free()
	_colunas.clear()
	for g in SINOS:
		var a := deg_to_rad(g)
		var pe := Vector3(sin(a), 0, -cos(a)) * (RAIO - 2.5)
		var coluna := StaticBody3D.new()
		coluna.position = pe
		add_child(coluna)
		_colunas.append(coluna)
		var cs := CollisionShape3D.new()
		var cil := CylinderShape3D.new()
		cil.radius = 0.8
		cil.height = 4.0
		cs.shape = cil
		cs.position.y = 2.0
		coluna.add_child(cs)
		var mi := MeshInstance3D.new()
		var forma := CylinderMesh.new()
		forma.top_radius = 0.7
		forma.bottom_radius = 0.9
		forma.height = 4.0
		forma.radial_segments = 6
		mi.mesh = forma
		mi.material_override = _gelo()
		mi.position.y = 2.0
		coluna.add_child(mi)
		var s := sino(pe + Vector3.UP * 4.0, atan2(-pe.x, -pe.z))
		s.tocou.connect(_sino_tocou)
		sinos_do_chefe.append(s)


func _sino_tocou(_s: Sino) -> void:
	if chefe.fase != 1 or not sinos_do_chefe.all(func(s: Sino) -> bool: return s.tocado):
		return
	# Os três tocaram: o pilar desmancha e ele cai tonto.
	Fx.confetti(self, Vector3(0, ALTURA_PILAR, 0), 60, 5.0)
	Sfx.play(self, "gelo", 4.0, 0.0)
	pilar.process_mode = Node.PROCESS_MODE_DISABLED
	for c in pilar.get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).set_deferred("disabled", true)
	var tw := pilar.create_tween()
	tw.tween_property(pilar, "scale", Vector3(1.2, 0.02, 1.2), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	chefe.cair_do_pilar(Vector3(0, 0, 0))


## Se o tonto passa sem os socos, o pilar volta e os sinos ficam quietos de novo.
func refazer_pilar() -> void:
	pilar.process_mode = Node.PROCESS_MODE_INHERIT
	for c in pilar.get_children():
		if c is CollisionShape3D:
			(c as CollisionShape3D).set_deferred("disabled", false)
	pilar.create_tween().tween_property(pilar, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK)
	_novos_sinos()


func alto_do_pilar() -> Vector3:
	return Vector3(0, ALTURA_PILAR, 0)


func _process(delta: float) -> void:
	super(delta)
	_atualizar_ondas(delta)
	if _comecou:
		return
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j == null or not j.controle_ligado or not j.is_on_floor():
		return
	_espera -= delta
	if _espera <= 0.0:
		comecar_luta()


func comecar_luta() -> void:
	if _comecou:
		return
	_comecou = true
	_dar_poder("luva")
	faixa_pedida.emit("Pinguinzão do Gelo!", "Com a Luva de Neve, toque os 3 sinos")
	dica.emit("luva")
	chefe.comecar()


## Troca o poder do Faísca: a Luva de Neve (fases 1 e 3) ou o Martelinho de Apito (fase 2).
func _dar_poder(qual: String) -> void:
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j == null:
		return
	j.luva_de_neve = qual == "luva"
	j.martelinho = qual == "martelinho"
	j.robo.expressao("feliz", 1.0)
	Particulas.magia(self, j.global_position + Vector3.UP * 1.2, Color("8fd8ff"))
	Sfx.play(self, "bandeira", 0.0, 0.0)


func _fase_mudou(f: int) -> void:
	match f:
		2:
			faixa_pedida.emit("Ele se fechou no gelo!", "Pule e bata com o Martelinho nos 4 pinos")
			_dar_poder("martelinho")
			dica.emit("martelo")
			# O pilar não volta: ele fica no meio, de casca.
			pilar.queue_free()
			for s in sinos_do_chefe:
				if is_instance_valid(s):
					s.queue_free()
			sinos_do_chefe.clear()
			for c in _colunas:
				if is_instance_valid(c):
					c.queue_free()
			_colunas.clear()
			nova_casca()
		3:
			faixa_pedida.emit("O chão congelou!", "Jogue bolas de neve nele enquanto ele desliza")
			_quebrar_casca()
			for p in pinos_do_chefe:
				if is_instance_valid(p):
					p.queue_free()
			pinos_do_chefe.clear()
			chao_da_arena.set_meta("gelo", true)
			superficie = "gelo"
			_dar_poder("luva")
			dica.emit("gelo")
	if f >= 2 and f <= 3:
		coracao(Vector3(0, 1.4, 9.0))


# --- a casca, os pinos e as ondas -------------------------------------------------------

## A casca de gelo em volta dele (sólida: não dá para bater nele lá dentro) e os 4 pinos novos em volta.
func nova_casca() -> void:
	_quebrar_casca(false)
	casca = StaticBody3D.new()
	casca.name = "Casca"
	add_child(casca)
	casca.global_position = Vector3(chefe.global_position.x, 0, chefe.global_position.z)
	var cs := CollisionShape3D.new()
	var esf := SphereShape3D.new()
	esf.radius = 3.3
	cs.shape = esf
	cs.position.y = 2.2
	casca.add_child(cs)
	var mi := MeshInstance3D.new()
	var bola := SphereMesh.new()
	bola.radius = 3.3
	bola.height = 6.6
	mi.mesh = bola
	mi.material_override = _gelo(0.45)
	mi.position.y = 2.2
	casca.add_child(mi)
	# Ele fica dentro da casca: sem isto, o corpo dele era empurrado para fora dela e atravessava o chão.
	chefe.add_collision_exception_with(casca)
	for p in pinos_do_chefe:
		if is_instance_valid(p):
			p.queue_free()
	pinos_do_chefe.clear()
	for g in PINOS:
		var a := deg_to_rad(g)
		var p := pino(Vector3(sin(a), 0, -cos(a)) * 8.5)
		p.batido.connect(_pino_batido)
		pinos_do_chefe.append(p)


func _pino_batido(_p: Pino) -> void:
	Sfx.play(self, "gelo", 0.0, 0.1)
	if casca:
		casca.scale = Vector3.ONE * 1.06
		casca.create_tween().tween_property(casca, "scale", Vector3.ONE, 0.2)
	if chefe.fase == 2 and pinos_do_chefe.all(func(p: Pino) -> bool: return p.batido_ja):
		_quebrar_casca()
		chefe.casca_quebrou()


func _quebrar_casca(barulho := true) -> void:
	if not is_instance_valid(casca):
		return
	if barulho:
		Fx.confetti(self, casca.global_position + Vector3.UP * 2.5, 60, 5.0)
		Sfx.play(self, "gelo", 4.0, 0.0)
	casca.queue_free()
	casca = null


## A onda gelada que sai da casca: um anel azul que cresce pelo chão; acerta quem está no chão quando passa.
func onda_de_gelo(centro: Vector3) -> void:
	var anel := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.75
	toro.outer_radius = 1.0
	toro.rings = 48
	anel.mesh = toro
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.55, 0.85, 1.0, 0.95)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	anel.material_override = m
	add_child(anel)
	anel.global_position = Vector3(centro.x, 0.25, centro.z)
	_ondas.append({"anel": anel, "centro": Vector3(centro.x, 0, centro.z), "t": 0.0, "acertou": false})
	tremer_chao(centro, 0.6)


func _atualizar_ondas(delta: float) -> void:
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	for o in _ondas.duplicate():
		o.t += delta
		var r: float = 3.3 + (ONDA_ATE - 3.3) * o.t / ONDA_TEMPO
		var anel: MeshInstance3D = o.anel
		anel.scale = Vector3(r, 3.0, r)
		(anel.material_override as StandardMaterial3D).albedo_color.a = 0.95 * (1.0 - 0.6 * o.t / ONDA_TEMPO)
		if j and not o.acertou and j.is_on_floor():
			var d := Vector2(j.global_position.x - o.centro.x, j.global_position.z - o.centro.z).length()
			if absf(d - r) < 0.8 and j.global_position.y < 1.2:
				o.acertou = true
				if j.receber_dano(o.centro):
					ondas_que_acertaram += 1
		if o.t >= ONDA_TEMPO:
			anel.queue_free()
			_ondas.erase(o)


func tremer_chao(onde: Vector3, forca: float) -> void:
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j:
		j.tremidinha(forca * clampf(1.0 - j.global_position.distance_to(onde) / 20.0, 0.2, 1.0))


# --- as bolas de neve grandes (fase 1) -------------------------------------------------------

## Uma bola de neve grande que sai de `de` e cai em `alvo` em VOO_BOLA s, com o alvo azul no chão antes.
func jogar_bola_grande(de: Vector3, alvo: Vector3) -> void:
	var espaco := get_world_3d().direct_space_state
	var chao := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(alvo + Vector3.UP * 2.0, alvo + Vector3.DOWN * 20.0, 1))
	var onde: Vector3 = chao.position if not chao.is_empty() else alvo
	bolas_jogadas += 1
	var marca := MeshInstance3D.new()
	var anel := TorusMesh.new()
	anel.inner_radius = 1.2
	anel.outer_radius = 1.6
	marca.mesh = anel
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color(0.4, 0.75, 1.0, 0.9)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marca.material_override = mm
	marca.scale = Vector3(1, 0.3, 1)
	add_child(marca)
	marca.global_position = onde + Vector3.UP * 0.05
	var bola := MeshInstance3D.new()
	var esf := SphereMesh.new()
	esf.radius = 0.7
	esf.height = 1.4
	bola.mesh = esf
	bola.material_override = _material(Color("f4fbff"))
	add_child(bola)
	bola.global_position = de
	var tw := bola.create_tween()
	tw.tween_method(func(k: float) -> void:
		bola.global_position = de.lerp(onde, k) + Vector3.UP * sin(k * PI) * 5.0, 0.0, 1.0, VOO_BOLA)
	tw.tween_callback(func() -> void:
		marca.queue_free()
		bola.queue_free()
		_bola_caiu(onde))


func _bola_caiu(onde: Vector3) -> void:
	Sfx.play_at(self, "gelo", onde, 0.0, 0.15)
	Fx.confetti(self, onde + Vector3.UP * 0.4, 16, 2.5)
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j:
		var d := Vector2(j.global_position.x - onde.x, j.global_position.z - onde.z).length()
		if d < 1.7 and absf(j.global_position.y - onde.y) < 1.6 and j.receber_dano(onde):
			bolas_que_acertaram += 1


# --- a vitória --------------------------------------------------------------------------

func _vitoria() -> void:
	faixa_pedida.emit("Você venceu o Pinguinzão do Gelo!", "Abra o baú dourado")
	chao_da_arena.remove_meta("gelo")
	superficie = "neve"
	soltar_moedas(Vector3(0, 1.0, 8.0), 40, 4.0)
	var b := colocar_bau(Vector3(0, 9.0, 8.0), PI, true)
	var tw := b.create_tween()
	tw.tween_property(b, "position:y", 0.0, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: Fx.confetti(self, b.global_position + Vector3.UP * 1.5, 40, 4.0))
