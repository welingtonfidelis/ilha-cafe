class_name ChefeBolotao
extends CharacterBody3D
## O Bolotão Fofão, o chefe do andar 1 (item 5 da lista de melhorias do Faísca, 2026-11-11): o Alien do Cute
## Monsters (o mesmo das Bolotas) em 3x, uns 6 m, com a coroa de capitão do Rei Bolotão. Luta em três fases, cada uma
## com o que o Faísca aprendeu no mundo 1, como os chefes do Astro Bot; cada fase acaba com GOLPES socos nele tonto:
## 1. Pisões: anda até o Faísca, agacha e pula onde ele está (a sombra aparece no chão); no pouso, uma onda de choque
##    corre pelo chão (pular por cima). Depois de PULOS pisões, cansa e fica tonto.
## 2. Bolotinhas: no meio da arena, cospe Bolotinhas (no máximo 3). Soco nele não adianta (ele faz que não); um soco
##    deixa a Bolotinha tonta, e agarrada e arremessada nele, ele fica tonto.
## 3. Investidas: agacha piscando vermelho e corre reto até a beira; as 4 flores de luz da arena aparecem, e acesas com
##    o laser (flutuando em cima delas), a luz deixa ele tonto.
## Encostar nele (menos tonto) tira um coração. A arena (Chefe1) cuida da onda, da sombra, das Bolotinhas e das flores.
## Fica no grupo dos alvos (os golpes do Faísca acham ele).

signal fase_mudou(fase: int)
signal vencido

const MODELO := "res://assets/faisca/monstros/Alien.gltf"
const ESCALA := 3.0
const RAIO := 2.2
const GOLPES := 3
const PULOS := 3
const TONTO := 5.0
const ANDAR := 3.2
const INVESTIDA := 15.0
const GRAVIDADE := 32.0
## Até onde ele vai na arena (do meio).
const BEIRA := 12.0

## Para os golpes do Faísca (grupo dos alvos).
var derrotado := false
var raio_golpe := 2.4
## 0 antes de começar; 1 a 3 na luta; 4 vencido.
var fase := 0
var estado := "dormindo"
var golpes := 0
var pulos := 0
var arena: Node
var jogador: Jogador
var anim: AnimationPlayer
var visual: Node3D
## Os estados que já passaram (os testes olham).
var vistos := {}
var _t := 0.0
var _alvo := Vector3.ZERO
var _dir := Vector3.ZERO
var _imune := 0.0
var _mat: StandardMaterial3D
var _estrelas: Node3D
var _cuspir := 2.0
var _piscar := 0.0


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	collision_layer = 1 | Alvo.CAMADA
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = RAIO
	capsula.height = 5.4
	cs.shape = capsula
	cs.position.y = 2.7
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
	for nome in ["Idle", "Walk", "Dance"]:
		if anim.has_animation(nome):
			anim.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
	_montar_coroa()
	_montar_estrelas()
	_animar("Idle", 0.6)


## A coroa dourada de capitão em cima da cabeça, com três pontas e bolinhas vermelhas.
func _montar_coroa() -> void:
	var coroa := Node3D.new()
	coroa.position = Vector3(0, 5.55, 0)
	visual.add_child(coroa)
	var ouro := StandardMaterial3D.new()
	ouro.albedo_color = Color("ffc93c")
	ouro.metallic = 0.6
	ouro.roughness = 0.3
	var aro := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.95
	cil.bottom_radius = 0.85
	cil.height = 0.45
	aro.mesh = cil
	aro.material_override = ouro
	coroa.add_child(aro)
	for k in 5:
		var a := TAU * k / 5.0
		var ponta := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.22
		cone.height = 0.55
		ponta.mesh = cone
		ponta.material_override = ouro
		ponta.position = Vector3(cos(a) * 0.85, 0.48, sin(a) * 0.85)
		coroa.add_child(ponta)
		var joia := MeshInstance3D.new()
		var bola := SphereMesh.new()
		bola.radius = 0.1
		bola.height = 0.2
		joia.mesh = bola
		var vermelho := StandardMaterial3D.new()
		vermelho.albedo_color = Color("ff4d6d")
		vermelho.emission_enabled = true
		vermelho.emission = Color("ff4d6d")
		joia.material_override = vermelho
		joia.position = Vector3(cos(a) * 0.95, 0.0, sin(a) * 0.95)
		coroa.add_child(joia)


## As estrelinhas de tonto girando em volta da cabeça (escondidas fora do tonto).
func _montar_estrelas() -> void:
	_estrelas = Node3D.new()
	_estrelas.position.y = 6.6
	_estrelas.visible = false
	visual.add_child(_estrelas)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("fff1a8")
	m.emission_enabled = true
	m.emission = Color("ffd23f")
	m.emission_energy_multiplier = 2.0
	for k in 5:
		var e := MeshInstance3D.new()
		e.mesh = Forma.estrela(0.35, 0.15, 0.15)
		e.material_override = m
		var a := TAU * k / 5.0
		e.position = Vector3(cos(a) * 1.6, 0, sin(a) * 1.6)
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


## A arena chama quando a luta começa: acorda e vai para a fase 1.
func comecar() -> void:
	if fase != 0:
		return
	_animar("Yes", 0.8)
	Sfx.play_at(get_parent(), "bolota_ai", global_position + Vector3.UP * 3.0, 6.0, 0.0)
	_proxima_fase()


func _proxima_fase() -> void:
	fase += 1
	golpes = 0
	pulos = 0
	_estrelas.visible = false
	fase_mudou.emit(fase)
	if fase > 3:
		_vencer()
		return
	_mudar("bravo")


func _physics_process(delta: float) -> void:
	_t += delta
	_imune -= delta
	if not is_instance_valid(jogador):
		jogador = get_tree().get_first_node_in_group("jogador") as Jogador
	if not is_on_floor():
		velocity.y -= GRAVIDADE * delta
	var h := Vector3.ZERO
	match estado:
		"bravo":
			# Pulinho de bravo e um grito antes de cada fase.
			_animar("Yes", 1.0)
			if _t > 1.6:
				_mudar(["", "andando", "cuspindo", "preparando"][fase])
		"andando":
			_animar("Walk", 1.0)
			h = _para_o_faisca() * ANDAR
			_virar(h, delta)
			if _t > 2.0:
				_mudar("agachando")
		"agachando":
			_animar("Bite_InPlace", 1.4)
			_virar(_para_o_faisca(), delta)
			if _t > 0.6:
				_pular()
		"pulando":
			h = _dir
			if velocity.y <= 0.0 and is_on_floor() and _t > 0.2:
				_pousar()
		"cuspindo":
			_animar("Idle", 1.0)
			_virar(_para_o_faisca(), delta)
			# Volta para o meio, devagar.
			var meio := -Vector3(global_position.x, 0, global_position.z)
			if meio.length() > 1.0:
				h = meio.normalized() * ANDAR * 0.6
			_cuspir -= delta
			if _cuspir <= 0.0:
				_cuspir = 4.5
				if arena and arena.has_method("bolotinhas_vivas") and arena.bolotinhas_vivas() < 3:
					_animar("Bite_Front", 1.0)
					arena.cuspir_bolotinha(global_position + Vector3.UP * 3.0 + _frente() * 2.6, _frente())
		"preparando":
			_animar("Bite_InPlace", 1.6)
			_virar(_para_o_faisca(), delta * 2.0)
			_piscar += delta
			_mat.emission_energy_multiplier = 0.6 if fmod(_piscar, 0.25) < 0.12 else 0.0
			_mat.emission = Color("ff3030")
			if _t > 0.9:
				_dir = _frente()
				_mat.emission_energy_multiplier = 0.0
				_mudar("investida")
		"investida":
			_animar("Walk", 2.6)
			h = _dir * INVESTIDA
			var depois := global_position + h * delta
			if Vector2(depois.x, depois.z).length() > BEIRA or _t > 2.2:
				h = Vector3.ZERO
				_mudar("parado")
				Sfx.play_at(get_parent(), "bonk", global_position + Vector3.UP * 2.0, 2.0, 0.05)
				if arena and arena.has_method("tremer_chao"):
					arena.tremer_chao(global_position, 0.6)
		"parado":
			_animar("Idle", 1.0)
			if _t > 1.3:
				_mudar("preparando")
		"tonto":
			_animar("HitRecieve" if _t < 0.4 else "Idle", 0.5)
			_estrelas.visible = true
			_estrelas.rotation.y += delta * 3.0
			var dura := TONTO * (1.5 if Ajustes.facil else 1.0)
			if _t > dura:
				_estrelas.visible = false
				_voltar_a_lutar()
		"vencido":
			pass
	velocity.x = h.x
	velocity.z = h.z
	move_and_slide()
	_encostar()
	_brilho(delta)


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


## O pisão: pula onde o Faísca está agora; a sombra avisa onde vai cair.
func _pular() -> void:
	_alvo = jogador.global_position if is_instance_valid(jogador) else global_position
	_alvo.y = global_position.y
	var plano := _alvo - global_position
	plano.y = 0.0
	if plano.length() > BEIRA * 1.4:
		plano = plano.normalized() * BEIRA * 1.4
	var subida := 15.0
	var voo := 2.0 * subida / GRAVIDADE
	_dir = plano / voo
	velocity.y = subida
	_animar("Jump", 0.6)
	_mudar("pulando")
	if arena and arena.has_method("sombra"):
		arena.sombra(global_position + plano, voo)


func _pousar() -> void:
	_dir = Vector3.ZERO
	pulos += 1
	Sfx.play_at(get_parent(), "faisca_pisao", global_position, 6.0, 0.0)
	if arena and arena.has_method("onda"):
		arena.onda(global_position)
	if pulos >= PULOS:
		cansar()
	else:
		_mudar("andando")


## Cansou (os pisões) ou levou a Bolotinha ou a luz das flores: tonto, e os socos contam.
func cansar() -> void:
	if estado in ["tonto", "vencido"]:
		return
	_dir = Vector3.ZERO
	_mat.emission_energy_multiplier = 0.0
	Sfx.play_at(get_parent(), "tonto", global_position + Vector3.UP * 4.0, 4.0, 0.0)
	_mudar("tonto")


func _voltar_a_lutar() -> void:
	pulos = 0
	match fase:
		1:
			_mudar("andando")
		2:
			_mudar("cuspindo")
		3:
			if arena and arena.has_method("novas_flores"):
				arena.novas_flores()
			_mudar("preparando")


## Tonto, os golpes contam; fora disso, só a Bolotinha arremessada (na fase 2) adianta, e ele faz que não.
func receber_golpe(_dano: int, de: Vector3, _forca := 6.0, tipo := "") -> bool:
	if derrotado or _imune > 0.0:
		return false
	if estado != "tonto":
		if tipo == "arremesso" and fase == 2:
			_imune = 0.3
			cansar()
			return true
		if tipo in ["soco", "giro", "giro_forte"] and estado in ["cuspindo", "parado", "andando"]:
			_imune = 0.5
			_animar("No", 1.2)
			Sfx.play_at(get_parent(), "escudo", global_position + Vector3.UP * 2.0, 0.0, 0.1)
		return false
	_imune = 0.35
	golpes += 1
	_piscar_branco()
	Sfx.play_at(get_parent(), "bolota_ai", global_position + Vector3.UP * 3.0, 4.0, 0.1)
	var empurrao := global_position - de
	empurrao.y = 0.0
	visual.scale = Vector3(1.1, 0.88, 1.1)
	if golpes >= (2 if Ajustes.facil else GOLPES):
		_proxima_fase()
	return true


func _piscar_branco() -> void:
	_mat.emission = Color.WHITE
	_mat.emission_energy_multiplier = 1.0


func _brilho(delta: float) -> void:
	visual.scale = visual.scale.lerp(Vector3.ONE, 1.0 - exp(-8.0 * delta))
	if estado != "preparando" and _mat.emission_energy_multiplier > 0.0:
		_mat.emission_energy_multiplier = maxf(_mat.emission_energy_multiplier - delta * 4.0, 0.0)


## Encostar nele tira um coração (menos tonto ou vencido). Na investida, ele joga o Faísca longe.
func _encostar() -> void:
	if not is_instance_valid(jogador) or estado in ["tonto", "vencido", "dormindo"]:
		return
	var d := jogador.global_position - global_position
	var alto := d.y
	d.y = 0.0
	var raio := RAIO + (1.0 if estado == "investida" else 0.6)
	if d.length() < raio and alto > -0.5 and alto < 5.6:
		if jogador.receber_dano(global_position):
			var fora := d.normalized() if d.length() > 0.05 else Vector3.BACK
			jogador.velocity = fora * (16.0 if estado == "investida" else 11.0) + Vector3.UP * 7.0


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
	# Vira uma bolotinha envergonhada que sai quicando para longe.
	tw.tween_property(visual, "position", Vector3(0, 0, -14), 1.6)
	tw.parallel().tween_property(visual, "rotation:y", visual.rotation.y + TAU * 3.0, 1.6)
	tw.tween_callback(hide)
