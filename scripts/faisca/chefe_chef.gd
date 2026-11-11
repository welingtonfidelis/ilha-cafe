class_name ChefeChef
extends CharacterBody3D
## O Chef Bolotão, o chefe do andar 2 (Doces e Brinquedos; item 5 da lista de melhorias do Faísca, 2026-11-11): o
## porquinho das Bolotas (Pig, do Cute Monsters) em 2,6x, com o chapéu branco de cozinheiro. Luta na Cozinha do Chef
## (Chefe2) em três fases, cada uma com o que o Faísca aprendeu no mundo 2; cada fase acaba com GOLPES socos nele tonto:
## 1. Bolinhos: em cima do bolo do meio (7 m), joga bolinhos onde o Faísca está (o alvo rosa aparece no chão antes). As
##    tampas das panelas em volta jogam o Faísca lá em cima; chegando, o Chef se assusta e fica tonto.
## 2. Investidas: pula para o chão e corre reto até o Faísca, como os porquinhos; batendo na beira, no bolo ou na torre,
##    fica tonto.
## 3. Torre de panquecas: pula para o alto da torre (10 m) e volta a jogar bolinhos. A bola de chiclete aparece: com o
##    balão, o Faísca sobe até ele, e ele fica tonto.
## Encostar nele (menos tonto) tira um coração. A arena cuida dos bolinhos, das tampas, da torre e do chiclete.

signal fase_mudou(fase: int)
signal vencido

const MODELO := "res://assets/faisca/monstros/Pig.gltf"
const ESCALA := 2.6
const RAIO := 2.0
const GOLPES := 3
const TONTO := 5.0
const INVESTIDA := 13.0
const GRAVIDADE := 32.0

var derrotado := false
var raio_golpe := 2.2
var fase := 0
var estado := "dormindo"
var golpes := 0
var arena: Node
var jogador: Jogador
var anim: AnimationPlayer
var visual: Node3D
var vistos := {}
## Onde ele fica jogando bolinhos (o alto do bolo ou da torre), e quanto tempo até o próximo.
var poleiro := Vector3.ZERO
var _t := 0.0
var _dir := Vector3.ZERO
var _imune := 0.0
var _mat: StandardMaterial3D
var _estrelas: Node3D
var _jogar := 1.5
var _piscar := 0.0
var _saltando := false


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	collision_layer = 1 | Alvo.CAMADA
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = RAIO
	capsula.height = 4.4
	cs.shape = capsula
	cs.position.y = 2.2
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
			_mat.emission_energy_multiplier = 0.0
		mi.material_override = _mat
	anim = cena.find_children("*", "AnimationPlayer", true, false)[0]
	for nome in ["Idle", "Walk"]:
		if anim.has_animation(nome):
			anim.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
	_montar_chapeu()
	_montar_estrelas()
	_animar("Idle", 0.6)


## O chapéu de cozinheiro: a faixa branca e o "cogumelo" fofo em cima, em três bolas.
func _montar_chapeu() -> void:
	var chapeu := Node3D.new()
	chapeu.position = Vector3(0, 4.15, 0)
	visual.add_child(chapeu)
	var branco := StandardMaterial3D.new()
	branco.albedo_color = Color("fbfbff")
	branco.roughness = 0.7
	var faixa := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.95
	cil.bottom_radius = 0.9
	cil.height = 0.7
	faixa.mesh = cil
	faixa.material_override = branco
	chapeu.add_child(faixa)
	for spec in [[Vector3(0, 0.75, 0), 0.95], [Vector3(-0.55, 0.6, 0.2), 0.6], [Vector3(0.55, 0.6, -0.2), 0.6]]:
		var bola := MeshInstance3D.new()
		var esf := SphereMesh.new()
		esf.radius = spec[1]
		esf.height = spec[1] * 1.6
		bola.mesh = esf
		bola.material_override = branco
		bola.position = spec[0]
		chapeu.add_child(bola)


func _montar_estrelas() -> void:
	_estrelas = Node3D.new()
	_estrelas.position.y = 6.3
	_estrelas.visible = false
	visual.add_child(_estrelas)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("fff1a8")
	m.emission_enabled = true
	m.emission = Color("ffd23f")
	m.emission_energy_multiplier = 2.0
	for k in 5:
		var e := MeshInstance3D.new()
		e.mesh = Forma.estrela(0.32, 0.14, 0.14)
		e.material_override = m
		var a := TAU * k / 5.0
		e.position = Vector3(cos(a) * 1.4, 0, sin(a) * 1.4)
		_estrelas.add_child(e)


func _animar(nome: String, rapidez := 1.0) -> void:
	if anim == null or not anim.has_animation(nome):
		return
	anim.speed_scale = rapidez
	if anim.current_animation != nome:
		anim.play(nome, 0.15)


func _mudar(novo: String) -> void:
	estado = novo
	_t = 0.0
	vistos[novo] = true


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
			_mudar("jogando")
		2:
			_saltar_para(arena.lugar_no_chao(global_position) if arena else Vector3(0, 0, 9), "bravo")
		3:
			_saltar_para(arena.alto_da_torre() if arena else global_position, "jogando")
		_:
			_vencer()


## Pulo em arco (sem física) até `onde`; chegando, vai para `depois`.
func _saltar_para(onde: Vector3, depois: String) -> void:
	_saltando = true
	_mudar("saltando")
	_animar("Jump", 0.5)
	var de := global_position
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		global_position = de.lerp(onde, k) + Vector3.UP * sin(k * PI) * 6.0, 0.0, 1.0, 1.2)
	tw.tween_callback(func() -> void:
		_saltando = false
		velocity = Vector3.ZERO
		poleiro = onde
		Sfx.play_at(get_parent(), "faisca_pisao", global_position, 4.0, 0.0)
		if arena and arena.has_method("tremer_chao"):
			arena.tremer_chao(global_position, 0.7)
		_mudar(depois))


func _physics_process(delta: float) -> void:
	_t += delta
	_imune -= delta
	if not is_instance_valid(jogador):
		jogador = get_tree().get_first_node_in_group("jogador") as Jogador
	if _saltando or estado == "vencido":
		return
	if not is_on_floor():
		velocity.y -= GRAVIDADE * delta
	var h := Vector3.ZERO
	match estado:
		"jogando":
			_animar("Idle", 1.0)
			_virar(_para_o_faisca(), delta)
			_jogar -= delta
			if _jogar <= 0.0:
				_jogar = 1.6 if fase == 1 else 1.3
				_animar("Bite_Front", 1.0)
				if arena and arena.has_method("jogar_bolinho") and is_instance_valid(jogador):
					arena.jogar_bolinho(global_position + Vector3.UP * 3.2 + _frente() * 1.5, jogador.global_position + jogador.velocity * 0.6)
			# O Faísca chegou aqui em cima: susto, e fica tonto.
			if _faisca_no_poleiro():
				Sfx.play_at(get_parent(), "bolota_ai", global_position + Vector3.UP * 3.0, 6.0, 0.0)
				cansar()
		"bravo":
			_animar("Yes", 1.0)
			if _t > 1.2:
				_mudar("preparando")
		"preparando":
			_animar("Bite_InPlace", 1.6)
			_virar(_para_o_faisca(), delta * 2.5)
			_piscar += delta
			_mat.emission = Color("ff3030")
			_mat.emission_energy_multiplier = 0.6 if fmod(_piscar, 0.25) < 0.12 else 0.0
			if _t > 0.9:
				_dir = _frente()
				_mat.emission_energy_multiplier = 0.0
				_mudar("investida")
		"investida":
			_animar("Walk", 2.6)
			h = _dir * INVESTIDA
			if _t > 0.15 and _bateu():
				Sfx.play_at(get_parent(), "bonk", global_position + Vector3.UP * 2.0, 4.0, 0.0)
				if arena and arena.has_method("tremer_chao"):
					arena.tremer_chao(global_position, 0.8)
				h = Vector3.ZERO
				cansar()
			elif _t > 2.6:
				h = Vector3.ZERO
				_mudar("preparando")
		"tonto":
			_animar("HitRecieve" if _t < 0.4 else "Idle", 0.5)
			_estrelas.visible = true
			_estrelas.rotation.y += delta * 3.0
			if _t > TONTO * (1.5 if Ajustes.facil else 1.0):
				_estrelas.visible = false
				_mudar("jogando" if fase != 2 else "preparando")
	velocity.x = h.x
	velocity.z = h.z
	move_and_slide()
	_encostar()
	visual.scale = visual.scale.lerp(Vector3.ONE, 1.0 - exp(-8.0 * delta))
	if estado != "preparando" and _mat.emission_energy_multiplier > 0.0:
		_mat.emission_energy_multiplier = maxf(_mat.emission_energy_multiplier - delta * 4.0, 0.0)


## Na investida, bateu de frente em alguma coisa (a parede da beira, o bolo, a torre).
func _bateu() -> bool:
	for k in get_slide_collision_count():
		var col := get_slide_collision(k)
		if absf(col.get_normal().y) < 0.5 and col.get_normal().dot(_dir) < -0.4:
			return true
	return false


func _faisca_no_poleiro() -> bool:
	if not is_instance_valid(jogador):
		return false
	var d := jogador.global_position - poleiro
	return jogador.is_on_floor() and d.y > -0.6 and d.y < 2.0 and Vector2(d.x, d.z).length() < 4.6


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
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(para.x, para.z), 1.0 - exp(-5.0 * delta))


func cansar() -> void:
	if estado in ["tonto", "vencido", "saltando"]:
		return
	_mat.emission_energy_multiplier = 0.0
	Sfx.play_at(get_parent(), "tonto", global_position + Vector3.UP * 4.0, 4.0, 0.0)
	_mudar("tonto")


func receber_golpe(_dano: int, de: Vector3, _forca := 6.0, tipo := "") -> bool:
	if derrotado or _imune > 0.0:
		return false
	if estado != "tonto":
		if tipo in ["soco", "giro"] and estado in ["jogando", "preparando", "bravo"]:
			_imune = 0.5
			_animar("No", 1.2)
			Sfx.play_at(get_parent(), "escudo", global_position + Vector3.UP * 2.0, 0.0, 0.1)
		return false
	_imune = 0.35
	golpes += 1
	_mat.emission = Color.WHITE
	_mat.emission_energy_multiplier = 1.0
	Sfx.play_at(get_parent(), "bolota_ai", global_position + Vector3.UP * 3.0, 4.0, 0.1)
	visual.scale = Vector3(1.1, 0.88, 1.1)
	if golpes >= (2 if Ajustes.facil else GOLPES):
		_proxima_fase()
	return true


func _encostar() -> void:
	if not is_instance_valid(jogador) or estado in ["tonto", "vencido", "dormindo", "saltando"]:
		return
	var d := jogador.global_position - global_position
	var alto := d.y
	d.y = 0.0
	var raio := RAIO + (1.0 if estado == "investida" else 0.5)
	if d.length() < raio and alto > -0.5 and alto < 4.6:
		if jogador.receber_dano(global_position):
			var fora := d.normalized() if d.length() > 0.05 else Vector3.BACK
			jogador.velocity = fora * (16.0 if estado == "investida" else 10.0) + Vector3.UP * 7.0


func _vencer() -> void:
	derrotado = true
	_mudar("vencido")
	collision_layer = 0
	remove_from_group(Alvo.GRUPO)
	_animar("Death", 0.5)
	Sfx.play_at(get_parent(), "bolota_estoura", global_position + Vector3.UP * 3.0, 6.0, 0.0)
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(visual, "scale", Vector3.ONE * 0.15, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		Fx.confetti(get_parent(), global_position + Vector3.UP * 1.0, 60, 6.0)
		vencido.emit())
	tw.tween_property(visual, "position", Vector3(0, -6, -12), 1.6)
	tw.parallel().tween_property(visual, "rotation:y", visual.rotation.y + TAU * 3.0, 1.6)
	tw.tween_callback(hide)
