class_name Chefe2
extends Fase
## Chefe do andar 2: o Chef Bolotão na Cozinha do Chef (item 5 da lista de melhorias do Faísca, 2026-11-11; a porta no
## 2º andar do farol, a noroeste, abre com 5 Estrelas Grandes, as dos mundos 1 e 2). Uma travessa redonda gigante
## (RAIO m) em cima da mesa de uma cozinha de gigantes, com a parede invisível na beira, os móveis da cozinha ao longe
## (o Restaurant Bits bem grande), o bolo listrado no meio (7 m), a torre de panquecas na beira norte (10 m), as três
## panelas com tampa em volta do bolo e uma roda de 12 estrelinhas. A luta (ChefeChef) tem três fases; aqui ficam os
## bolinhos que ele joga (o alvo rosa no chão, e quem está nele quando cai perde um coração), a bola de chiclete da
## fase 3 (o Balão de Chiclete), um coração a cada fase nova e, no fim, 40 moedas e o baú dourado.

const ID := "chefe-2"
const RAIO := 16.0
const BOLO := 4.5
const ALTURA_BOLO := 7.0
const TORRE := Vector3(0, 0, -11.5)
const RAIO_TORRE := 3.6
const ALTURA_TORRE := 10.0
const PANELAS := [60.0, 180.0, 300.0]
const VOO_BOLINHO := 1.3

signal faixa_pedida(titulo: String, sub: String)

var chefe: ChefeChef
var bola_de_chiclete: Area3D
var bolinhos_que_acertaram := 0
var bolinhos_jogados := 0
var _comecou := false
var _espera := 1.2


func _montar() -> void:
	nome = "Chefe: Chef Bolotão"
	superficie = "madeira"
	inicio = Vector3(0, 0.1, 13.0)
	limite_queda = -10.0
	_travessa()
	_bolo()
	_torre_de_panquecas()
	for g in PANELAS:
		var a := deg_to_rad(g)
		# Força 23: o pulo passa uns 2,5 m acima do bolo, com folga para a criança chegar flutuando.
		panela_com_tampa(Vector3(sin(a), 0, -cos(a)) * (BOLO + 3.0), 23.0, g / 180.0, 4.0)
	_cozinha_ao_longe()
	roda(Vector3(0, 1.0, 0), RAIO - 3.2, 12)
	chefe = ChefeChef.new()
	chefe.name = "Chef"
	chefe.arena = self
	chefe.position = Vector3(0, ALTURA_BOLO, 0)
	chefe.poleiro = chefe.position
	add_child(chefe)
	chefe.fase_mudou.connect(_fase_mudou)
	chefe.vencido.connect(_vitoria)


## A travessa: o tampo branco com a borda azul, embaixo dela a mesa de madeira, e a parede invisível da beira.
func _travessa() -> void:
	var corpo := StaticBody3D.new()
	add_child(corpo)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = RAIO + 0.6
	cil.height = 2.0
	cs.shape = cil
	cs.position.y = -1.0
	corpo.add_child(cs)
	# A louça branca, a faixa azul da borda (um disco um pouco mais baixo que o miolo branco, que cobre o meio) e a
	# base que afina por baixo.
	for spec in [[RAIO + 0.6, RAIO + 0.2, 0.5, -0.27, Color("f7f7fb")], [RAIO + 0.65, RAIO + 0.65, 0.06, -0.01, Color("4a8fe0")],
			[RAIO - 0.9, RAIO - 0.9, 0.06, 0.01, Color("f6efe0")], [RAIO + 0.3, RAIO - 2.0, 1.2, -1.1, Color("e9ebf3")]]:
		var mi := MeshInstance3D.new()
		var forma := CylinderMesh.new()
		forma.top_radius = spec[0]
		forma.bottom_radius = spec[1]
		forma.height = spec[2]
		forma.radial_segments = 64
		mi.mesh = forma
		mi.material_override = _material(spec[4])
		mi.position.y = spec[3]
		add_child(mi)
	# A mesa de madeira lá embaixo, grande, e uma toalha xadrez vermelha.
	var mesa := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(90, 2, 90)
	mesa.mesh = caixa
	mesa.material_override = _material(Color("c98b55"))
	mesa.position.y = -3.0
	add_child(so_enfeite(mesa))
	var toalha := MeshInstance3D.new()
	var plano := BoxMesh.new()
	plano.size = Vector3(44, 0.1, 44)
	toalha.mesh = plano
	toalha.material_override = _material(Color("e25b5b"))
	toalha.position.y = -1.95
	toalha.rotation.y = PI / 4.0
	add_child(so_enfeite(toalha))
	var muro := StaticBody3D.new()
	add_child(muro)
	for k in 36:
		var a := TAU * k / 36.0
		var parte := CollisionShape3D.new()
		var b := BoxShape3D.new()
		b.size = Vector3(2.0 * PI * RAIO / 36.0 + 0.6, 6.0, 0.6)
		parte.shape = b
		parte.position = Vector3(sin(a), 0, cos(a)) * (RAIO + 0.3) + Vector3.UP * 3.0
		parte.rotation.y = a
		muro.add_child(parte)


## O bolo do meio: camadas rosa, branca e de chocolate, velinhas na beira e a cereja (o Chef fica em cima).
func _bolo() -> void:
	var corpo := StaticBody3D.new()
	add_child(corpo)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = BOLO
	cil.height = ALTURA_BOLO
	cs.shape = cil
	cs.position.y = ALTURA_BOLO * 0.5
	corpo.add_child(cs)
	var camadas := [Color("ff8fc8"), Color("fff4f8"), Color("7a4a2e"), Color("fff4f8"), Color("ff8fc8")]
	var alto := ALTURA_BOLO / camadas.size()
	for i in camadas.size():
		var mi := MeshInstance3D.new()
		var forma := CylinderMesh.new()
		forma.top_radius = BOLO
		forma.bottom_radius = BOLO
		forma.height = alto
		forma.radial_segments = 48
		mi.mesh = forma
		mi.material_override = _material(camadas[i])
		mi.position.y = alto * (i + 0.5)
		add_child(mi)
	# A cobertura que escorre na beira de cima.
	for k in 16:
		var a := TAU * k / 16.0
		var pingo := MeshInstance3D.new()
		var esf := SphereMesh.new()
		esf.radius = 0.5
		esf.height = 1.4
		pingo.mesh = esf
		pingo.material_override = _material(Color("fff4f8"))
		pingo.position = Vector3(cos(a) * BOLO, ALTURA_BOLO - 0.4, sin(a) * BOLO)
		add_child(so_enfeite(pingo))
	for k in 8:
		var a := TAU * (k + 0.5) / 8.0
		var vela := MeshInstance3D.new()
		var cv := CylinderMesh.new()
		cv.top_radius = 0.12
		cv.bottom_radius = 0.12
		cv.height = 0.9
		vela.mesh = cv
		vela.material_override = _material(Color("4aa3ff") if k % 2 == 0 else Color("ffd23f"))
		vela.position = Vector3(cos(a) * (BOLO - 0.5), ALTURA_BOLO + 0.45, sin(a) * (BOLO - 0.5))
		add_child(so_enfeite(vela))
		var chama := MeshInstance3D.new()
		var cc := SphereMesh.new()
		cc.radius = 0.12
		cc.height = 0.3
		chama.mesh = cc
		var fogo := StandardMaterial3D.new()
		fogo.albedo_color = Color("ffb347")
		fogo.emission_enabled = true
		fogo.emission = Color("ff8a20")
		fogo.emission_energy_multiplier = 2.0
		chama.material_override = fogo
		chama.position = vela.position + Vector3.UP * 0.6
		add_child(chama)


## A torre de panquecas na beira norte: 10 panquecas douradas, calda escorrendo e um tablete de manteiga em cima.
func _torre_de_panquecas() -> void:
	var corpo := StaticBody3D.new()
	add_child(corpo)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = RAIO_TORRE
	cil.height = ALTURA_TORRE
	cs.shape = cil
	cs.position = TORRE + Vector3.UP * ALTURA_TORRE * 0.5
	corpo.add_child(cs)
	var n := 10
	for i in n:
		var mi := MeshInstance3D.new()
		var forma := CylinderMesh.new()
		forma.top_radius = RAIO_TORRE + (0.15 if i % 2 == 0 else 0.0)
		forma.bottom_radius = forma.top_radius - 0.2
		forma.height = ALTURA_TORRE / n
		forma.radial_segments = 40
		mi.mesh = forma
		mi.material_override = _material(Color("e9b45a") if i % 2 == 0 else Color("d99a3d"))
		mi.position = TORRE + Vector3.UP * (ALTURA_TORRE / n * (i + 0.5))
		add_child(mi)
	var calda := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = RAIO_TORRE + 0.2
	cc.bottom_radius = RAIO_TORRE + 0.2
	cc.height = 0.25
	calda.mesh = cc
	calda.material_override = _material(Color("8a4a1e"))
	calda.position = TORRE + Vector3.UP * (ALTURA_TORRE + 0.05)
	add_child(calda)
	var manteiga := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.4, 0.6, 1.0)
	manteiga.mesh = bm
	manteiga.material_override = _material(Color("fff2a0"))
	manteiga.position = TORRE + Vector3(1.8, ALTURA_TORRE + 0.45, 1.2)
	add_child(so_enfeite(manteiga))


## Os móveis da cozinha de gigantes ao longe, de enfeite (sem colisão).
func _cozinha_ao_longe() -> void:
	for spec in [["fridge_A", Vector3(-34, -2, -30), 0.6, 16.0], ["stove_multi", Vector3(30, -2, -34), -0.5, 16.0],
			["kitchencounter_straight_A", Vector3(38, -2, 4), -PI / 2.0, 16.0], ["jar_D_large", Vector3(-30, -2, 20), 0.3, 14.0],
			["food_icecream_cone_strawberry", Vector3(26, -2, 26), 0.0, 18.0], ["ketchup", Vector3(-22, -2, 32), 0.4, 14.0],
			["pot_large", Vector3(-40, -2, -4), 0.0, 14.0]]:
		so_enfeite(cozinha(spec[0], spec[1], spec[2], spec[3], false))


func _montar_ceu_e_luz() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("f6e6cc")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff1dc")
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_hdr_threshold = 1.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, 60, 0)
	sol.light_color = Color("fff3dd")
	sol.light_energy = 1.1
	sol.shadow_enabled = true
	sol.shadow_opacity = 0.7
	sol.directional_shadow_max_distance = 80.0
	add_child(sol)


func _montar_nuvens() -> void:
	pass


func _process(delta: float) -> void:
	super(delta)
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
	faixa_pedida.emit("Chef Bolotão!", "Pule nas tampas das panelas para chegar no bolo")
	chefe.comecar()


func _fase_mudou(f: int) -> void:
	if f == 2:
		faixa_pedida.emit("Ele desceu correndo!", "Desvie e deixe ele bater na beira")
	elif f == 3:
		faixa_pedida.emit("Ele subiu na torre de panquecas!", "Pegue o chiclete e suba com o balão")
		_bola_de_chiclete()
	if f >= 2 and f <= 3:
		coracao(Vector3(0, 1.4, 9.0))


## Para onde ele pula do bolo na fase 2: no chão, do lado do Faísca, mas não em cima dele.
func lugar_no_chao(_de: Vector3) -> Vector3:
	var j := get_tree().get_first_node_in_group("jogador") as Node3D
	var a := atan2(j.global_position.x, j.global_position.z) + 1.2 if j else 0.0
	return Vector3(sin(a), 0, cos(a)) * (BOLO + 5.0)


func alto_da_torre() -> Vector3:
	return TORRE + Vector3.UP * ALTURA_TORRE


func tremer_chao(onde: Vector3, forca: float) -> void:
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j:
		j.tremidinha(forca * clampf(1.0 - j.global_position.distance_to(onde) / 20.0, 0.2, 1.0))


# --- os bolinhos ---------------------------------------------------------------------

## Um bolinho (massa rosa, cobertura branca e a cereja) que sai de `de` e cai em `alvo` em VOO_BOLINHO s, com o alvo
## rosa no chão antes. Quem estiver nele quando cai perde um coração.
func jogar_bolinho(de: Vector3, alvo: Vector3) -> void:
	var espaco := get_world_3d().direct_space_state
	var chao := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(alvo + Vector3.UP * 2.0, alvo + Vector3.DOWN * 20.0, 1))
	var onde: Vector3 = chao.position if not chao.is_empty() else alvo
	bolinhos_jogados += 1
	var marca := MeshInstance3D.new()
	var anel := TorusMesh.new()
	anel.inner_radius = 1.2
	anel.outer_radius = 1.6
	marca.mesh = anel
	var mm := StandardMaterial3D.new()
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.albedo_color = Color(1.0, 0.4, 0.7, 0.85)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marca.material_override = mm
	marca.scale = Vector3(1, 0.3, 1)
	add_child(marca)
	marca.global_position = onde + Vector3.UP * 0.05
	var b := _bolinho()
	add_child(b)
	b.global_position = de
	var tw := b.create_tween()
	tw.tween_method(func(k: float) -> void:
		b.global_position = de.lerp(onde, k) + Vector3.UP * sin(k * PI) * 5.0
		b.rotation.x = k * TAU, 0.0, 1.0, VOO_BOLINHO)
	tw.tween_callback(func() -> void:
		marca.queue_free()
		_bolinho_caiu(onde)
		b.queue_free())
	var pulsa := marca.create_tween().set_loops(4)
	pulsa.tween_property(marca, "scale", Vector3(1.15, 0.3, 1.15), VOO_BOLINHO / 8.0)
	pulsa.tween_property(marca, "scale", Vector3(1, 0.3, 1), VOO_BOLINHO / 8.0)


func _bolinho_caiu(onde: Vector3) -> void:
	Sfx.play_at(self, "estouro", onde, -2.0, 0.15)
	Fx.confetti(self, onde + Vector3.UP * 0.4, 14, 2.5)
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j:
		var d := Vector2(j.global_position.x - onde.x, j.global_position.z - onde.z).length()
		if d < 1.7 and absf(j.global_position.y - onde.y) < 1.6 and j.receber_dano(onde):
			bolinhos_que_acertaram += 1
	# A mancha de cobertura no chão, sumindo.
	var mancha := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 1.3
	disco.bottom_radius = 1.3
	disco.height = 0.03
	mancha.mesh = disco
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.75, 0.88, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mancha.material_override = m
	add_child(mancha)
	mancha.global_position = onde + Vector3.UP * 0.03
	var tw := mancha.create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.8)
	tw.tween_callback(mancha.queue_free)


func _bolinho() -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "Bolinho"
	var forma := MeshInstance3D.new()
	var copo := CylinderMesh.new()
	copo.top_radius = 0.55
	copo.bottom_radius = 0.4
	copo.height = 0.6
	forma.mesh = copo
	forma.material_override = _material(Color("ff8fc8"))
	raiz.add_child(forma)
	var cobertura := MeshInstance3D.new()
	var esf := SphereMesh.new()
	esf.radius = 0.6
	esf.height = 0.8
	cobertura.mesh = esf
	cobertura.material_override = _material(Color("fff4f8"))
	cobertura.position.y = 0.4
	raiz.add_child(cobertura)
	var cereja := MeshInstance3D.new()
	var ce := SphereMesh.new()
	ce.radius = 0.18
	ce.height = 0.36
	cereja.mesh = ce
	cereja.material_override = _material(Color("e2304a"))
	cereja.position.y = 0.85
	raiz.add_child(cereja)
	return raiz


# --- o chiclete e a vitória -------------------------------------------------------------

## A bola de chiclete da fase 3, na frente da torre: encostar dá o Balão de Chiclete (segurar o pulo no ar enche).
func _bola_de_chiclete() -> void:
	if bola_de_chiclete:
		return
	bola_de_chiclete = Area3D.new()
	bola_de_chiclete.name = "BolaDeChiclete"
	bola_de_chiclete.collision_layer = 0
	bola_de_chiclete.collision_mask = CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var esf := SphereShape3D.new()
	esf.radius = 1.2
	cs.shape = esf
	bola_de_chiclete.add_child(cs)
	var mi := MeshInstance3D.new()
	var bola := SphereMesh.new()
	bola.radius = 0.9
	bola.height = 1.8
	mi.mesh = bola
	var m := _material(Color("ff6fb5"))
	m.emission_enabled = true
	m.emission = Color("ff3f9a")
	m.emission_energy_multiplier = 0.5
	mi.material_override = m
	bola_de_chiclete.add_child(mi)
	add_child(bola_de_chiclete)
	bola_de_chiclete.position = TORRE + Vector3(0, 1.4, RAIO_TORRE + 2.6)
	Fx.confetti(self, bola_de_chiclete.global_position, 30, 3.0)
	bola_de_chiclete.body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador and not (corpo as Jogador).balao_de_chiclete:
			pegar_balao(corpo as Jogador))
	dica.emit("balao")


func pegar_balao(j: Jogador) -> void:
	j.balao_de_chiclete = true
	j.robo.expressao("feliz", 1.2)
	Fx.confetti(self, bola_de_chiclete.global_position, 40, 4.0)
	Sfx.play(self, "bandeira", 0.0, 0.0)
	bola_de_chiclete.set_deferred("monitoring", false)
	bola_de_chiclete.hide()


func _vitoria() -> void:
	faixa_pedida.emit("Você venceu o Chef Bolotão!", "Abra o baú dourado")
	soltar_moedas(Vector3(0, 1.0, 9.0), 40, 4.0)
	var b := colocar_bau(Vector3(0, 9.0, 9.0), PI, true)
	var tw := b.create_tween()
	tw.tween_property(b, "position:y", 0.0, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: Fx.confetti(self, b.global_position + Vector3.UP * 1.5, 40, 4.0))
