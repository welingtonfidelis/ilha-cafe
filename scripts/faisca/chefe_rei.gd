class_name ChefeRei
extends CharacterBody3D
## O Rei Bolotão, o chefe final do Faísca, na Sala do Trono da Nave Aspiratrão (FaseNave, 2026-11-12, da maquete
## aprovada pelo usuário: "maquete aprovada"). É o Alien do Cute Monsters, como as Bolotas, em 3,4x (uns 7 m com a
## coroa), com a coroa dourada torta por cima da touca de dormir azul de pompom, a capa roxa de estrelinhas e o
## cetro-aspirador na mão. Luta em três fases; nas duas primeiras ele fica tonto e leva GOLPES socos, como os outros
## chefes, e a última acaba sem golpe:
## 1. Trono voador: em cima do trono (um disco voador pequeno, no meio da sala), joga potes de estrelas onde o Faísca
##    está (o alvo rosa aparece antes). Pelas argolas do ioiô, o Faísca sobe no trono e soca o botão vermelho; o trono
##    engasga e cai, e o Rei fica tonto no chão.
## 2. O aspirador: no chão, liga o cetro e puxa tudo para ele (os riscos brancos mostram para onde; atrás dos pilares
##    não pega), e desliga um pouco para respirar. Com a pipa, as colunas de vento levam aos três filtros, e o soco no
##    ferrolho de cada um entope o aspirador: ele estoura numa nuvem de poeira e o Rei fica tonto.
## 3. O apagão: a poeira apaga as luzes, e ele rola sem ver para onde, chorando ("Tá escuro!"). Cada lâmpada que o
##    laser acende acalma um pouco (rola mais devagar); com as quatro, ele para, senta e chora (`vencido`): a fase faz
##    a cena da estrelinha de bolso.
## Encostar nele (menos tonto, sentado ou no trono, quando quem cuida é o trono) tira um coração. A arena (`arena`)
## cuida do trono, das argolas, dos potes, do puxão, dos filtros e das lâmpadas.

signal fase_mudou(fase: int)
signal vencido

const MODELO := "res://assets/faisca/monstros/Alien.gltf"
const ESCALA := 3.4
const RAIO := 2.5
const ALTURA := 6.2
const GOLPES := 3
const TONTO := 5.5
const GRAVIDADE := 32.0
## Rolando no escuro: a velocidade sem nenhuma lâmpada e o quanto cada lâmpada acesa tira.
const ROLANDO := 8.5
const MENOS_POR_LAMPADA := 1.6
const BEIRA := 19.5
## O cetro liga por LIGADO s e descansa DESLIGADO s.
const LIGADO := 4.2
const DESLIGADO := 2.6

var derrotado := false
var raio_golpe := 2.8
var fase := 0
var estado := "dormindo"
var golpes := 0
var lampadas := 0
var arena: Node
var jogador: Jogador
var anim: AnimationPlayer
var visual: Node3D
var vistos := {}
## Contagens para os testes.
var potes_jogados := 0
var tempo_puxando := 0.0
## O cetro está puxando agora.
var puxando := false

var _t := 0.0
var _dir := Vector3.ZERO
var _imune := 0.0
var _mat: StandardMaterial3D
var _estrelas: Node3D
var _capa: MeshInstance3D
var _jogar := 2.0
var _ciclo := 0.0
var _lagrima := 0.0
var _soluco := 0.0
var _ligado_antes := false
## O tween de agora (cair do trono, pular de volta): a luta recomeçando para ele.
var _tw: Tween
var _manual := true
var _rolando_visual := false


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	collision_layer = 1 | Alvo.CAMADA
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = RAIO
	capsula.height = ALTURA
	cs.shape = capsula
	cs.position.y = ALTURA * 0.5
	add_child(cs)
	visual = Node3D.new()
	add_child(visual)
	var cena: Node3D = load(MODELO).instantiate()
	cena.scale = Vector3.ONE * ESCALA
	visual.add_child(cena)
	for mi: MeshInstance3D in cena.find_children("*", "MeshInstance3D", true, false):
		if _mat == null:
			var original := mi.get_active_material(0) as StandardMaterial3D
			_mat = original.duplicate() as StandardMaterial3D if original else StandardMaterial3D.new()
			_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			_mat.roughness = 0.85
			_mat.emission = Color.WHITE
			_mat.emission_texture = _mat.albedo_texture
			_mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			_mat.emission_enabled = true
			_mat.emission_energy_multiplier = 0.45
		mi.material_override = _mat
	anim = cena.find_children("*", "AnimationPlayer", true, false)[0]
	for nome in ["Idle", "Walk", "Dance", "No"]:
		if anim.has_animation(nome):
			anim.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
	for p in enfeites():
		visual.add_child(p)
	_capa = visual.get_node("Capa") as MeshInstance3D
	_montar_estrelas()
	_animar("Idle", 0.5)


## A coroa torta, a touca de dormir com pompom, a capa de estrelinhas e o cetro-aspirador (também para a cena do
## final, que monta um Rei pequenininho com o mesmo jeito). As medidas são para o Rei em ESCALA.
static func enfeites(escala := 1.0) -> Array[Node3D]:
	var partes: Array[Node3D] = []
	var k := escala
	var ouro := StandardMaterial3D.new()
	ouro.albedo_color = Color("ffd23f")
	ouro.metallic = 0.6
	ouro.roughness = 0.3
	ouro.emission_enabled = true
	ouro.emission = Color("ffb800")
	ouro.emission_energy_multiplier = 0.3
	var coroa := Node3D.new()
	coroa.name = "Coroa"
	coroa.position = Vector3(-0.5, 5.75, 0.25) * k
	coroa.rotation.z = 0.3
	partes.append(coroa)
	var aro := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 1.25 * k
	c.bottom_radius = 1.15 * k
	c.height = 0.7 * k
	c.cap_top = false
	c.cap_bottom = false
	aro.mesh = c
	ouro.cull_mode = BaseMaterial3D.CULL_DISABLED
	aro.material_override = ouro
	coroa.add_child(aro)
	for i in 5:
		var a := TAU * i / 5.0
		var ponta := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.28 * k
		cone.height = 0.8 * k
		ponta.mesh = cone
		ponta.material_override = ouro
		ponta.position = Vector3(cos(a) * 1.2, 0.7, sin(a) * 1.2) * k
		coroa.add_child(ponta)
		var joia := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.14 * k
		s.height = 0.28 * k
		joia.mesh = s
		var m := StandardMaterial3D.new()
		m.albedo_color = [Color("e8333f"), Color("3fd0ee"), Color("4cc27a")][i % 3]
		joia.material_override = m
		joia.position = Vector3(cos(a) * 1.24, 0.0, sin(a) * 1.24) * k
		coroa.add_child(joia)
	# A touca de dormir azul, saindo de dentro da coroa e caída para o lado, com o pompom branco.
	var azul := StandardMaterial3D.new()
	azul.albedo_color = Color("4a7de0")
	azul.roughness = 0.9
	var touca := MeshInstance3D.new()
	touca.name = "Touca"
	var t := CylinderMesh.new()
	t.top_radius = 0.0
	t.bottom_radius = 1.05 * k
	t.height = 2.6 * k
	touca.mesh = t
	touca.material_override = azul
	touca.position = Vector3(0.1, 6.9, 0.1) * k
	touca.rotation.z = -0.9
	partes.append(touca)
	var pompom := MeshInstance3D.new()
	var p := SphereMesh.new()
	p.radius = 0.38 * k
	p.height = 0.76 * k
	pompom.mesh = p
	var branco := StandardMaterial3D.new()
	branco.albedo_color = Color("fff8ee")
	branco.roughness = 1.0
	pompom.material_override = branco
	pompom.position = Vector3(1.3, 7.45, 0.1) * k
	partes.append(pompom)
	# A capa roxa por trás, aberta na frente, com estrelinhas amarelas.
	var roxo := StandardMaterial3D.new()
	roxo.albedo_color = Color("5b2fa0")
	roxo.roughness = 0.8
	roxo.cull_mode = BaseMaterial3D.CULL_DISABLED
	# A capa: um pedaço de cone só nas costas (a frente fica aberta e o corpo aparece), do pescoço até o chão.
	var capa := MeshInstance3D.new()
	capa.name = "Capa"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var de_a := PI * 0.55
	var ate_a := PI * 1.45
	var baixo := Vector2(3.0, 0.35) * k
	var cima := Vector2(1.7, 4.6) * k
	var partes_capa := 18
	for i in partes_capa:
		var a0 := lerpf(de_a, ate_a, float(i) / partes_capa)
		var a1 := lerpf(de_a, ate_a, float(i + 1) / partes_capa)
		var b0 := Vector3(sin(a0) * baixo.x, baixo.y, cos(a0) * baixo.x)
		var b1 := Vector3(sin(a1) * baixo.x, baixo.y, cos(a1) * baixo.x)
		var c0 := Vector3(sin(a0) * cima.x, cima.y, cos(a0) * cima.x)
		var c1 := Vector3(sin(a1) * cima.x, cima.y, cos(a1) * cima.x)
		var nrm := Vector3(sin((a0 + a1) * 0.5), 0.3, cos((a0 + a1) * 0.5)).normalized()
		for v in [b0, b1, c1, b0, c1, c0]:
			st.set_normal(nrm)
			st.add_vertex(v)
	capa.mesh = st.commit()
	capa.material_override = roxo
	partes.append(capa)
	var amarelo := StandardMaterial3D.new()
	amarelo.albedo_color = Color("ffe066")
	amarelo.emission_enabled = true
	amarelo.emission = Color("ffd23f")
	amarelo.emission_energy_multiplier = 1.2
	for i in 9:
		var e := MeshInstance3D.new()
		e.mesh = Forma.estrela(0.26 * k, 0.11 * k, 0.06 * k)
		e.material_override = amarelo
		var a := PI + (i - 4) * 0.3
		var y := (0.9 + (i % 3) * 1.2) * k
		var r := lerpf(baixo.x, cima.x, (y - baixo.y) / (cima.y - baixo.y)) + 0.06 * k
		e.position = Vector3(sin(a) * r, y, cos(a) * r)
		e.rotation.y = a
		partes.append(e)
	# O cetro-aspirador: o cabo escuro e o bocal roxo com a boca rosa.
	var cetro := Node3D.new()
	cetro.name = "Cetro"
	cetro.position = Vector3(2.7, 2.6, 0.9) * k
	cetro.rotation.z = -0.25
	partes.append(cetro)
	var cabo := MeshInstance3D.new()
	var cc := CylinderMesh.new()
	cc.top_radius = 0.12 * k
	cc.bottom_radius = 0.12 * k
	cc.height = 4.2 * k
	cabo.mesh = cc
	var escuro := StandardMaterial3D.new()
	escuro.albedo_color = Color("3a3150")
	escuro.metallic = 0.4
	cabo.material_override = escuro
	cetro.add_child(cabo)
	var bico := MeshInstance3D.new()
	var bc := CylinderMesh.new()
	bc.top_radius = 0.55 * k
	bc.bottom_radius = 0.25 * k
	bc.height = 1.0 * k
	bico.mesh = bc
	var violeta := StandardMaterial3D.new()
	violeta.albedo_color = Color("7b4fd6")
	bico.material_override = violeta
	bico.position.y = 2.4 * k
	cetro.add_child(bico)
	var boca := MeshInstance3D.new()
	var bt := TorusMesh.new()
	bt.inner_radius = 0.38 * k
	bt.outer_radius = 0.58 * k
	boca.mesh = bt
	var rosa := StandardMaterial3D.new()
	rosa.albedo_color = Color("ff8ad8")
	rosa.emission_enabled = true
	rosa.emission = Color("ff5ac8")
	rosa.emission_energy_multiplier = 1.0
	boca.material_override = rosa
	boca.position.y = 2.9 * k
	cetro.add_child(boca)
	return partes


func _montar_estrelas() -> void:
	_estrelas = Node3D.new()
	_estrelas.position.y = 8.2
	_estrelas.visible = false
	visual.add_child(_estrelas)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("fff1a8")
	m.emission_enabled = true
	m.emission = Color("ffd23f")
	m.emission_energy_multiplier = 2.0
	for k in 5:
		var e := MeshInstance3D.new()
		e.mesh = Forma.estrela(0.4, 0.17, 0.15)
		e.material_override = m
		var a := TAU * k / 5.0
		e.position = Vector3(cos(a) * 1.8, 0, sin(a) * 1.8)
		_estrelas.add_child(e)


func _animar(nome: String, rapidez := 1.0) -> void:
	if anim == null or not anim.has_animation(nome):
		return
	anim.speed_scale = rapidez
	if anim.current_animation != nome:
		anim.play(nome, 0.2)


func _mudar(novo: String) -> void:
	estado = novo
	_t = 0.0
	vistos[novo] = true


## A arena chama quando o Faísca chega: o Rei acorda no trono e a luta começa.
func comecar() -> void:
	if fase != 0:
		return
	_animar("Yes", 0.8)
	_proxima_fase()


func _proxima_fase() -> void:
	fase += 1
	golpes = 0
	_estrelas.visible = false
	fase_mudou.emit(fase)
	match fase:
		1:
			_manual = true
			_mudar("no_trono")
		2:
			_manual = false
			_ciclo = 0.0
			_mudar("aspirando")
		3:
			_manual = false
			_mudar("rolando")
			_enrolar(true)
		_:
			_sentar()


func _physics_process(delta: float) -> void:
	_t += delta
	_imune -= delta
	if not is_instance_valid(jogador):
		jogador = get_tree().get_first_node_in_group("jogador") as Jogador
	if estado in ["vencido", "caindo", "voltando", "dormindo_no_trono"]:
		return
	if estado == "dormindo":
		if arena and arena.has_method("trono_topo"):
			global_position = arena.trono_topo()
		_animar("Idle", 0.35)
		return
	if estado == "no_trono":
		_no_trono(delta)
		return
	# No chão: com gravidade, e uma rede de segurança se ele sair da sala.
	var plano := Vector2(global_position.x, global_position.z)
	if global_position.y < FaseNave.ARENA_Y - 4.0 or plano.length() > 23.0:
		global_position = Vector3(0, FaseNave.ARENA_Y + 0.3, 0)
		velocity = Vector3.ZERO
	if not is_on_floor():
		velocity.y -= GRAVIDADE * delta
	var h := Vector3.ZERO
	puxando = false
	match estado:
		"aspirando":
			_ciclo += delta
			var ligado := fmod(_ciclo, LIGADO + DESLIGADO) < LIGADO
			_virar(_para_o_faisca(), delta)
			if ligado and not _ligado_antes:
				Sfx.play_at(get_parent(), "aspirador", global_position + Vector3.UP * 4.0, 4.0, 0.05)
			_ligado_antes = ligado
			if ligado:
				puxando = true
				tempo_puxando += delta
				_animar("Bite_Front", 0.6)
			else:
				_animar("Idle", 1.2)
			if arena and arena.has_method("aspirar"):
				arena.aspirar(self, ligado, delta)
		"rolando":
			var rapidez := maxf(ROLANDO - lampadas * MENOS_POR_LAMPADA, 1.6)
			if _dir.length() < 0.1:
				_dir = _para_o_faisca() if _para_o_faisca().length() > 0.1 else Vector3.FORWARD
			h = _dir * rapidez
			var depois := global_position + h * delta
			if Vector2(depois.x, depois.z).length() > BEIRA:
				# Bate na beira e volta (sem ver), um pouco para o meio.
				var normal := Vector3(depois.x, 0, depois.z).normalized()
				_dir = (_dir - 2.0 * _dir.dot(normal) * normal).normalized()
				_dir = _dir.rotated(Vector3.UP, randf_range(-0.5, 0.5)).normalized()
				h = _dir * rapidez
				Sfx.play_at(get_parent(), "bonk", global_position, 0.0, 0.1)
				if arena and arena.has_method("tremer_chao"):
					arena.tremer_chao(global_position, 0.3)
			visual.rotation.y = atan2(_dir.x, _dir.z)
			visual.rotation.x += rapidez * delta * 0.6
			_chorar(delta)
		"tonto":
			_animar("HitRecieve" if _t < 0.4 else "Idle", 0.5)
			_estrelas.visible = true
			_estrelas.rotation.y += delta * 3.0
			if _t > TONTO * (1.5 if Ajustes.facil else 1.0):
				_estrelas.visible = false
				_voltar_a_lutar()
		"sentado":
			_chorar(delta)
	velocity.x = h.x
	velocity.z = h.z
	move_and_slide()
	_encostar()
	visual.scale = visual.scale.lerp(Vector3.ONE, 1.0 - exp(-8.0 * delta))
	if _mat.emission_energy_multiplier > 0.45:
		_mat.emission_energy_multiplier = maxf(_mat.emission_energy_multiplier - delta * 4.0, 0.45)


## Fase 1: em pé no trono (quem leva é o trono), virado para o Faísca, jogando potes de estrelas.
func _no_trono(delta: float) -> void:
	if arena and arena.has_method("trono_topo"):
		global_position = arena.trono_topo()
	velocity = Vector3.ZERO
	_virar(_para_o_faisca(), delta)
	_animar("Idle", 0.8)
	_jogar -= delta
	if _jogar <= 0.0 and is_instance_valid(jogador) and jogador.controle_ligado:
		_jogar = 2.8 if Ajustes.facil else 2.2
		_animar("Bite_Front", 1.0)
		potes_jogados += 1
		if arena and arena.has_method("jogar_pote"):
			arena.jogar_pote(global_position + Vector3.UP * 4.5 + _frente() * 2.0, jogador.global_position + jogador.velocity * 0.5)


## A arena chama: o botão vermelho do trono foi apertado. O trono engasga e cai, e ele fica tonto no chão.
func cair_do_trono(chao: Vector3) -> void:
	if fase != 1 or estado != "no_trono":
		return
	_mudar("caindo")
	_animar("HitRecieve", 0.6)
	var de := global_position
	var tw := create_tween()
	_tw = tw
	tw.tween_method(func(k: float) -> void:
		global_position = de.lerp(chao, k) + Vector3.UP * sin(k * PI) * 2.5, 0.0, 1.0, 0.9)
	tw.tween_callback(func() -> void:
		velocity = Vector3.ZERO
		_manual = false
		if arena and arena.has_method("tremer_chao"):
			arena.tremer_chao(global_position, 0.8)
		cansar())


## A arena chama: os três filtros entupiram, o aspirador estoura e ele fica tonto.
func entupir() -> void:
	if fase == 2 and estado == "aspirando":
		puxando = false
		cansar()


## A arena chama: mais uma lâmpada acesa no apagão. Com as quatro, ele senta e chora (a luta acaba).
func acalmar(acesas: int) -> void:
	lampadas = acesas
	if fase != 3 or estado != "rolando":
		return
	Sfx.play_at(get_parent(), "bolota_ai", global_position + Vector3.UP * 3.0, 2.0, 0.1)
	if lampadas >= 4:
		_proxima_fase()


func cansar() -> void:
	if estado in ["tonto", "vencido", "sentado"]:
		return
	_dir = Vector3.ZERO
	Sfx.play_at(get_parent(), "tonto", global_position + Vector3.UP * 5.0, 4.0, 0.0)
	_mudar("tonto")


func _voltar_a_lutar() -> void:
	match fase:
		1:
			# Se o tonto passa sem os socos, ele pula de volta no trono, que se arruma.
			if arena and arena.has_method("refazer_trono"):
				arena.refazer_trono()
			_manual = true
			_mudar("voltando")
			_animar("Jump", 0.5)
			var de := global_position
			var tw := create_tween()
			_tw = tw
			tw.tween_method(func(k: float) -> void:
				var alvo: Vector3 = arena.trono_topo() if arena else de
				global_position = de.lerp(alvo, k) + Vector3.UP * sin(k * PI) * 4.0, 0.0, 1.0, 1.2)
			tw.tween_callback(func() -> void: _mudar("no_trono"))
		2:
			if arena and arena.has_method("refazer_filtros"):
				arena.refazer_filtros()
			_ciclo = 0.0
			_mudar("aspirando")


## Fase 3: enrolado na capa, rolando (a capa cresce em volta dele) ou de pé de novo.
func _enrolar(sim: bool) -> void:
	_rolando_visual = sim
	var tw := visual.create_tween()
	tw.tween_property(_capa, "scale", Vector3(1.5, 1.3, 1.5) if sim else Vector3.ONE, 0.4)
	if not sim:
		tw.parallel().tween_property(visual, "rotation:x", 0.0, 0.4)
	_animar("No" if sim else "Idle", 0.6)


## As quatro lâmpadas acesas: ele para, desenrola e senta chorando. A luta acaba (sem golpe).
func _sentar() -> void:
	_mudar("sentado")
	derrotado = true
	_dir = Vector3.ZERO
	collision_layer = 1
	remove_from_group(Alvo.GRUPO)
	_enrolar(false)
	_animar("No", 0.35)
	vencido.emit()


## A luta recomeça do zero (o Faísca perdeu todos os corações, item 14): de volta ao trono, dormindo, inteiro.
func reiniciar() -> void:
	if _tw and _tw.is_valid():
		_tw.kill()
	fase = 0
	golpes = 0
	lampadas = 0
	derrotado = false
	puxando = false
	_ciclo = 0.0
	_jogar = 2.0
	_dir = Vector3.ZERO
	_manual = true
	velocity = Vector3.ZERO
	collision_layer = 1 | Alvo.CAMADA
	if not is_in_group(Alvo.GRUPO):
		add_to_group(Alvo.GRUPO)
	_estrelas.visible = false
	visual.rotation = Vector3.ZERO
	visual.scale = Vector3.ONE
	_capa.scale = Vector3.ONE
	_mudar("dormindo")
	_animar("Idle", 0.35)
	if arena and arena.has_method("trono_topo"):
		global_position = arena.trono_topo()


## Ganhou a estrelinha de bolso: para de chorar e dança, contente.
func alegrar() -> void:
	_mudar("feliz")
	_animar("Dance", 0.8)


## Lágrimas azuis caindo do olho, de vez em quando.
func _chorar(delta: float) -> void:
	_soluco -= delta
	if _soluco <= 0.0:
		_soluco = 3.0
		Sfx.play_at(get_parent(), "choro", global_position + Vector3.UP * 5.0, 4.0, 0.05)
	_lagrima -= delta
	if _lagrima > 0.0:
		return
	_lagrima = 0.35
	var gota := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.22
	s.height = 0.44
	gota.mesh = s
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("8fd8ff")
	m.emission_enabled = true
	m.emission = Color("6fc8ff")
	m.emission_energy_multiplier = 0.8
	gota.material_override = m
	get_parent().add_child(gota)
	var lado := visual.global_basis.x.normalized() * (0.9 if randf() < 0.5 else -0.9)
	var de := global_position + Vector3.UP * 4.6 + _frente() * 1.9 + lado
	gota.global_position = de
	var tw := gota.create_tween()
	tw.tween_property(gota, "global_position", de + lado * 0.8 + Vector3.DOWN * 4.4, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(gota.queue_free)


func _para_o_faisca() -> Vector3:
	if not is_instance_valid(jogador):
		return Vector3.ZERO
	var d := jogador.global_position - global_position
	d.y = 0.0
	return d.normalized() if d.length() > 0.5 else Vector3.ZERO


func _frente() -> Vector3:
	return visual.global_basis.z.normalized()


func _virar(para: Vector3, delta: float) -> void:
	if para.length() < 0.1:
		return
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(para.x, para.z), 1.0 - exp(-4.0 * delta))


## Tonto, os golpes contam; senão, o soco bate e volta.
func receber_golpe(_dano: int, _de: Vector3, _forca := 6.0, tipo := "") -> bool:
	if derrotado or _imune > 0.0:
		return false
	if estado != "tonto":
		if tipo in ["soco", "giro"] and estado in ["aspirando", "rolando", "no_trono"]:
			_imune = 0.5
			_animar("No", 1.2)
			Sfx.play_at(get_parent(), "escudo", global_position + Vector3.UP * 3.0, 0.0, 0.1)
		return false
	_imune = 0.35
	golpes += 1
	_mat.emission_energy_multiplier = 1.6
	Sfx.play_at(get_parent(), "bolota_ai", global_position + Vector3.UP * 4.0, 4.0, 0.1)
	visual.scale = Vector3(1.1, 0.88, 1.1)
	if golpes >= (2 if Ajustes.facil else GOLPES):
		_proxima_fase()
	return true


func _encostar() -> void:
	if not is_instance_valid(jogador) or estado in ["tonto", "vencido", "dormindo", "caindo", "voltando", "sentado", "feliz", "no_trono"]:
		return
	var d := jogador.global_position - global_position
	var alto := d.y
	d.y = 0.0
	var raio := RAIO + (1.0 if estado == "rolando" else 0.6)
	if d.length() < raio and alto > -0.5 and alto < ALTURA:
		if jogador.receber_dano(global_position):
			var fora := d.normalized() if d.length() > 0.05 else Vector3.BACK
			jogador.velocity = fora * 12.0 + Vector3.UP * 7.0
