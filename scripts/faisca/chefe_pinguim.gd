class_name ChefePinguim
extends CharacterBody3D
## O Pinguinzão do Gelo, o chefe do andar 3 (Frio e Vento; item 5 da lista de melhorias do Faísca, 2026-11-11): o
## pinguim das Bolotas (Penguin, do Cute Monsters) em 2,8x, com o cachecol vermelho e a coroa de cristais de gelo. Luta
## no Pico do Pinguinzão (Chefe3) em três fases, cada uma com o que o Faísca aprendeu no mundo 3; cada fase acaba com
## GOLPES socos nele tonto:
## 1. Pilar de gelo: lá em cima do pilar do meio, joga bolas de neve onde o Faísca está (o alvo azul aparece antes).
##    Com a Luva de Neve, o Faísca toca os 3 sinos da beira; tocados os três, o pilar desmancha e ele cai tonto.
## 2. Casca de gelo: se fecha numa casca e solta ondas geladas pelo chão (pular por cima). Com o Martelinho de Apito, o
##    Faísca afunda os 4 pinos em volta; afundados os quatro, a casca quebra e ele fica tonto.
## 3. Barrigadas: o chão congela (escorrega) e ele desliza de barriga, batendo na beira e voltando. Três bolas de neve
##    da luva nele (a luva mira sozinha) e ele tropeça e fica tonto.
## Encostar nele (menos tonto ou na casca) tira um coração.

signal fase_mudou(fase: int)
signal vencido

const MODELO := "res://assets/faisca/monstros/Penguin.gltf"
const ESCALA := 2.8
const RAIO := 1.9
const GOLPES := 3
const TROPECOS := 3
const TONTO := 5.0
const BARRIGADA := 11.0
const GRAVIDADE := 32.0
const BEIRA := 13.5

var derrotado := false
var raio_golpe := 2.2
var fase := 0
var estado := "dormindo"
var golpes := 0
var tropecos := 0
var arena: Node
var jogador: Jogador
var anim: AnimationPlayer
var visual: Node3D
var vistos := {}
var _t := 0.0
var _dir := Vector3.ZERO
var _imune := 0.0
var _mat: StandardMaterial3D
var _estrelas: Node3D
var _jogar := 1.5
var _onda := 2.0
var _roscado := false


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	# A bola de neve da luva mira nele também (como numa Bolota), no meio do corpo.
	set_meta("alvo_da_luva", true)
	set_meta("altura_do_meio", 2.0)
	collision_layer = 1 | Alvo.CAMADA
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = RAIO
	capsula.height = 4.2
	cs.shape = capsula
	cs.position.y = 2.1
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
	_montar_enfeites()
	_montar_estrelas()
	_animar("Idle", 0.6)


## O cachecol vermelho de listras e a coroa de cristais de gelo.
func _montar_enfeites() -> void:
	var cachecol := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 1.15
	toro.outer_radius = 1.55
	cachecol.mesh = toro
	var vermelho := StandardMaterial3D.new()
	vermelho.albedo_color = Color("e8424f")
	vermelho.roughness = 0.8
	cachecol.material_override = vermelho
	cachecol.position.y = 2.45
	visual.add_child(cachecol)
	var ponta := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(0.5, 1.1, 0.18)
	ponta.mesh = caixa
	ponta.material_override = vermelho
	ponta.position = Vector3(0.7, 1.9, 1.25)
	ponta.rotation.z = 0.2
	visual.add_child(ponta)
	var gelo := StandardMaterial3D.new()
	gelo.albedo_color = Color(0.75, 0.92, 1.0, 0.9)
	gelo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gelo.emission_enabled = true
	gelo.emission = Color("8fd8ff")
	gelo.emission_energy_multiplier = 0.8
	gelo.roughness = 0.1
	var coroa := Node3D.new()
	coroa.position.y = 4.05
	visual.add_child(coroa)
	for k in 6:
		var a := TAU * k / 6.0
		var cristal := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.2
		cone.height = 0.7 if k % 2 == 0 else 0.45
		cristal.mesh = cone
		cristal.material_override = gelo
		cristal.position = Vector3(cos(a) * 0.55, cone.height * 0.5, sin(a) * 0.55)
		coroa.add_child(cristal)


func _montar_estrelas() -> void:
	_estrelas = Node3D.new()
	_estrelas.position.y = 5.2
	_estrelas.visible = false
	visual.add_child(_estrelas)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("fff1a8")
	m.emission_enabled = true
	m.emission = Color("ffd23f")
	m.emission_energy_multiplier = 2.0
	for k in 5:
		var e := MeshInstance3D.new()
		e.mesh = Forma.estrela(0.3, 0.13, 0.13)
		e.material_override = m
		var a := TAU * k / 5.0
		e.position = Vector3(cos(a) * 1.3, 0, sin(a) * 1.3)
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
	tropecos = 0
	_estrelas.visible = false
	_deitar(false)
	fase_mudou.emit(fase)
	match fase:
		1:
			_mudar("no_pilar")
		2:
			_mudar("na_casca")
		3:
			_mudar("bravo")
		_:
			_vencer()


func _physics_process(delta: float) -> void:
	_t += delta
	_imune -= delta
	if not is_instance_valid(jogador):
		jogador = get_tree().get_first_node_in_group("jogador") as Jogador
	if estado in ["vencido", "caindo"]:
		return
	# Rede de segurança: abaixo do platô, volta para o meio.
	if global_position.y < -4.0:
		global_position = Vector3(0, 0.3, 0)
		velocity = Vector3.ZERO
	if not is_on_floor():
		velocity.y -= GRAVIDADE * delta
	var h := Vector3.ZERO
	match estado:
		"no_pilar":
			_animar("Idle", 1.0)
			_virar(_para_o_faisca(), delta)
			_jogar -= delta
			if _jogar <= 0.0:
				_jogar = 1.7
				_animar("Bite_Front", 1.0)
				if arena and arena.has_method("jogar_bola_grande") and is_instance_valid(jogador):
					arena.jogar_bola_grande(global_position + Vector3.UP * 3.0 + _frente() * 1.4, jogador.global_position + jogador.velocity * 0.6)
		"na_casca":
			_animar("Idle", 0.6)
			_virar(_para_o_faisca(), delta)
			_onda -= delta
			if _onda <= 0.0:
				_onda = 3.6
				_animar("Yes", 1.2)
				if arena and arena.has_method("onda_de_gelo"):
					arena.onda_de_gelo(global_position)
		"bravo":
			_animar("Yes", 1.0)
			if _t > 1.4:
				_comecar_barrigada()
		"barrigada":
			h = _dir * BARRIGADA
			var depois := global_position + h * delta
			var plano := Vector2(depois.x, depois.z)
			if plano.length() > BEIRA:
				# Bate na beira e volta, como bola de bilhar, e um pouco na direção do Faísca.
				var normal := Vector3(depois.x, 0, depois.z).normalized()
				_dir = (_dir - 2.0 * _dir.dot(normal) * normal).normalized()
				_dir = _dir.lerp(_para_o_faisca(), 0.35).normalized()
				h = _dir * BARRIGADA
				Sfx.play_at(get_parent(), "gelo", global_position, 2.0, 0.1)
				if arena and arena.has_method("tremer_chao"):
					arena.tremer_chao(global_position, 0.4)
			visual.rotation.y = atan2(_dir.x, _dir.z)
			if _t > 5.0:
				_deitar(false)
				_mudar("descansando")
		"descansando":
			_animar("Idle", 1.4)
			_virar(_para_o_faisca(), delta)
			if _t > 1.8:
				_comecar_barrigada()
		"tonto":
			_animar("HitRecieve" if _t < 0.4 else "Idle", 0.5)
			_estrelas.visible = true
			_estrelas.rotation.y += delta * 3.0
			if _t > TONTO * (1.5 if Ajustes.facil else 1.0):
				_estrelas.visible = false
				_voltar_a_lutar()
	velocity.x = h.x
	velocity.z = h.z
	move_and_slide()
	_encostar()
	visual.scale = visual.scale.lerp(Vector3.ONE, 1.0 - exp(-8.0 * delta))
	if _mat.emission_energy_multiplier > 0.0:
		_mat.emission_energy_multiplier = maxf(_mat.emission_energy_multiplier - delta * 4.0, 0.0)


func _comecar_barrigada() -> void:
	_dir = _para_o_faisca()
	if _dir.length() < 0.1:
		_dir = Vector3.BACK
	_deitar(true)
	_mudar("barrigada")
	Sfx.play_at(get_parent(), "faisca_mola", global_position, 2.0, 0.1)


## De barriga no chão (deslizando) ou de pé.
func _deitar(sim: bool) -> void:
	if sim == _roscado:
		return
	_roscado = sim
	var tw := visual.create_tween()
	tw.tween_property(visual, "rotation:x", PI / 2.0 if sim else 0.0, 0.25)
	tw.parallel().tween_property(visual, "position:y", 1.6 if sim else 0.0, 0.25)
	_animar("Jump" if sim else "Idle", 0.5)


func _voltar_a_lutar() -> void:
	match fase:
		1:
			# Caiu do pilar: se o tonto passa, sobe de volta num pulo (os sinos voltam a ficar quietos).
			if arena and arena.has_method("refazer_pilar"):
				arena.refazer_pilar()
			_saltar_para(arena.alto_do_pilar() if arena else global_position, "no_pilar")
		2:
			if arena and arena.has_method("nova_casca"):
				arena.nova_casca()
			_mudar("na_casca")
		3:
			_comecar_barrigada()


## A arena chama: tocados os 3 sinos, o pilar desmancha e ele cai tonto.
func cair_do_pilar(chao: Vector3) -> void:
	if fase != 1 or estado != "no_pilar":
		return
	_mudar("caindo")
	_animar("HitRecieve", 0.6)
	var de := global_position
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		global_position = de.lerp(chao, k) + Vector3.UP * sin(k * PI) * 2.0, 0.0, 1.0, 0.8)
	tw.tween_callback(func() -> void:
		velocity = Vector3.ZERO
		if arena and arena.has_method("tremer_chao"):
			arena.tremer_chao(global_position, 0.8)
		cansar())


## A arena chama: afundados os 4 pinos, a casca quebra e ele fica tonto.
func casca_quebrou() -> void:
	if fase == 2 and estado == "na_casca":
		cansar()


func _saltar_para(onde: Vector3, depois: String) -> void:
	_mudar("caindo")
	_animar("Jump", 0.5)
	var de := global_position
	var tw := create_tween()
	tw.tween_method(func(k: float) -> void:
		global_position = de.lerp(onde, k) + Vector3.UP * sin(k * PI) * 5.0, 0.0, 1.0, 1.1)
	tw.tween_callback(func() -> void:
		velocity = Vector3.ZERO
		_mudar(depois))


func cansar() -> void:
	if estado in ["tonto", "vencido"]:
		return
	_deitar(false)
	_dir = Vector3.ZERO
	Sfx.play_at(get_parent(), "tonto", global_position + Vector3.UP * 4.0, 4.0, 0.0)
	_mudar("tonto")


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


## Tonto, os golpes contam. Na fase 3, as bolas de neve da luva (que chegam como arremesso) fazem ele tropeçar.
func receber_golpe(_dano: int, _de: Vector3, _forca := 6.0, tipo := "") -> bool:
	if derrotado or _imune > 0.0:
		return false
	if estado != "tonto":
		if fase == 3 and tipo == "arremesso" and estado in ["barrigada", "descansando"]:
			_imune = 0.25
			tropecos += 1
			_mat.emission = Color("bfe8ff")
			_mat.emission_energy_multiplier = 1.0
			Sfx.play_at(get_parent(), "gelo", global_position + Vector3.UP * 2.0, 2.0, 0.1)
			if tropecos >= (2 if Ajustes.facil else TROPECOS):
				tropecos = 0
				cansar()
			return true
		if tipo in ["soco", "giro"] and estado in ["no_pilar", "descansando", "bravo"]:
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
	if not is_instance_valid(jogador) or estado in ["tonto", "vencido", "dormindo", "caindo", "na_casca"]:
		return
	var d := jogador.global_position - global_position
	var alto := d.y
	d.y = 0.0
	var raio := RAIO + (1.0 if estado == "barrigada" else 0.5)
	if d.length() < raio and alto > -0.5 and alto < 4.4:
		if jogador.receber_dano(global_position):
			var fora := d.normalized() if d.length() > 0.05 else Vector3.BACK
			jogador.velocity = fora * (15.0 if estado == "barrigada" else 10.0) + Vector3.UP * 7.0


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
	tw.tween_property(visual, "position", Vector3(0, 0, -14), 1.6)
	tw.parallel().tween_property(visual, "rotation:y", visual.rotation.y + TAU * 3.0, 1.6)
	tw.tween_callback(hide)
