class_name FaseTeste
extends Node3D
## Cenário de teste: ilha de grama no meio do mar, degraus, plataformas no ar, uma rampa,
## uma plataforma que vai e volta, estrelas para pegar e inimigos de treino. Tudo montado por código, com os
## blocos de quina redonda da Forma (cara de brinquedo, como os pacotes do KayKit).

signal estrela_pega(pegas: int, total: int)

const ROSA := Color("ff9fc4")
const AMARELO := Color("ffd166")
const LILAS := Color("b8a1ff")
const AZUL := Color("7fd8ff")
const GRAMA := Color("8fd694")

var inicio := Vector3(0, 0.1, 9)
var estrelas: Array[Area3D] = []
var alvos: Array[Alvo] = []
var pegas := 0
var movel: AnimatableBody3D

var _movel_origem := Vector3.ZERO
var _movel_caminho := Vector3(-3.5, 0, 0)
var _movel_periodo := 4.0
var _tempo := 0.0
var _mat_estrela: StandardMaterial3D


func _ready() -> void:
	_montar_ceu_e_luz()
	_bloco(Vector3(0, -1, 0), Vector3(40, 2, 40), GRAMA, 0.6)
	var mar := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(400, 400)
	mar.mesh = plano
	mar.position.y = -2.5
	mar.material_override = _material(Color("6ec3f5"), 0.15)
	add_child(mar)

	# Degraus subindo à esquerda do começo.
	_bloco(Vector3(-6, 0.4, 2), Vector3(3, 0.8, 3), ROSA)
	_bloco(Vector3(-6, 0.8, -1.5), Vector3(3, 1.6, 3), AMARELO)
	_bloco(Vector3(-6, 1.2, -5), Vector3(3, 2.4, 3), LILAS)
	# Plataformas no ar, cada uma um pouco mais alta.
	_bloco(Vector3(-2, 2.75, -8), Vector3(2.6, 0.5, 2.6), AZUL)
	_bloco(Vector3(2.2, 3.35, -9), Vector3(2.6, 0.5, 2.6), ROSA)
	_bloco(Vector3(6.5, 3.95, -7.5), Vector3(2.6, 0.5, 2.6), AMARELO)
	# Plataforma que vai e volta até o topo.
	movel = AnimatableBody3D.new()
	_movel_origem = Vector3(6.5, 3.95, -12.5)
	movel.position = _movel_origem
	_vestir(movel, Vector3(2.8, 0.5, 2.8), LILAS, 0.18)
	add_child(movel)
	_bloco(Vector3(1.5, 4.6, -17), Vector3(5, 0.6, 4), AZUL)
	# Rampa à direita, subindo para trás até um bloco.
	var rampa := _bloco(Vector3(7, 0.64, 4), Vector3(3, 0.3, 6.5), AMARELO)
	rampa.rotation.x = deg_to_rad(14)
	_bloco(Vector3(7, 0.8, -0.45), Vector3(3, 1.6, 2.6), ROSA)

	for p in [Vector3(-3, 1.0, 6), Vector3(-6, 3.3, -5), Vector3(-2, 3.9, -8), Vector3(4.4, 5.0, -8.3),
			Vector3(6.5, 5.1, -7.5), Vector3(4.0, 5.1, -12.5), Vector3(1.5, 5.8, -17), Vector3(7, 2.5, -0.45)]:
		_estrela(p)

	# Inimigos de treino (a ordem é usada pelo teste --controle).
	for p in [Vector3(3.5, 0, 2), Vector3(-3, 0, 0.5), Vector3(2.5, 0, -4.5), Vector3(-2, 0, -4), Vector3(1.5, 4.9, -17.8)]:
		var alvo := Alvo.new()
		alvo.position = p
		add_child(alvo)
		alvos.append(alvo)

	for p in [Vector3(-15, 0, 12), Vector3(14, 0, 13), Vector3(-16, 0, -10), Vector3(15, 0, -14), Vector3(-10, 0, -16), Vector3(13, 0, 6)]:
		_arvore(p)


func _physics_process(delta: float) -> void:
	_tempo += delta
	movel.position = _movel_origem + _movel_caminho * (0.5 - 0.5 * cos(TAU * _tempo / _movel_periodo))


func _process(delta: float) -> void:
	for e in estrelas:
		if e.visible:
			e.rotation.y += delta * 2.0
			e.get_child(1).position.y = sin(_tempo * 3.0 + e.position.x) * 0.12


func _bloco(centro: Vector3, tamanho: Vector3, cor: Color, raio := 0.18) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = centro
	_vestir(corpo, tamanho, cor, raio)
	add_child(corpo)
	return corpo


## Malha arredondada e colisão de caixa do mesmo tamanho.
func _vestir(corpo: PhysicsBody3D, tamanho: Vector3, cor: Color, raio: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Forma.caixa_redonda(tamanho, raio)
	mi.material_override = _material(cor)
	corpo.add_child(mi)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = tamanho
	cs.shape = caixa
	corpo.add_child(cs)


func _estrela(pos: Vector3) -> void:
	if _mat_estrela == null:
		_mat_estrela = _material(Color("ffd23f"), 0.3)
		_mat_estrela.emission_enabled = true
		_mat_estrela.emission = Color("ffb800")
		_mat_estrela.emission_energy_multiplier = 0.6
	var area := Area3D.new()
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 1 << 1
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.7
	cs.shape = esfera
	area.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = Forma.estrela(0.45, 0.2, 0.22)
	mi.material_override = _mat_estrela
	area.add_child(mi)
	area.body_entered.connect(_pegar.bind(area))
	add_child(area)
	estrelas.append(area)


func _pegar(corpo: Node3D, area: Area3D) -> void:
	if not corpo is Jogador or not area.monitoring:
		return
	area.set_deferred("monitoring", false)
	pegas += 1
	estrela_pega.emit(pegas, estrelas.size())
	Sfx.play(self, "estrelinha", 0.0, 0.1)
	var tw := create_tween()
	tw.tween_property(area, "scale", Vector3.ONE * 1.6, 0.12)
	tw.tween_property(area, "scale", Vector3.ONE * 0.01, 0.15)
	tw.tween_callback(area.hide)


func _arvore(pos: Vector3) -> void:
	var tronco := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.28
	cil.bottom_radius = 0.38
	cil.height = 1.6
	tronco.mesh = cil
	tronco.position = pos + Vector3(0, 0.8, 0)
	tronco.material_override = _material(Color("b07a52"))
	add_child(tronco)
	var copa := MeshInstance3D.new()
	copa.mesh = Forma.superelipsoide(Vector3(1.5, 1.3, 1.5), 0.9, 0.9)
	copa.position = pos + Vector3(0, 2.6, 0)
	copa.material_override = _material(Color("5fbf6a"))
	add_child(copa)


func _montar_ceu_e_luz() -> void:
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color("6fa8ff")
	ceu.sky_horizon_color = Color("dcd6ff")
	ceu.ground_horizon_color = Color("dcd6ff")
	ceu.ground_bottom_color = Color("9a8fd8")
	var sky := Sky.new()
	sky.sky_material = ceu
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	# Luz ambiente quase neutra: com a cor do céu as sombras saíam azuis, parecendo buracos.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dcd8ee")
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_hdr_threshold = 1.3
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -35, 0)
	sol.light_energy = 1.0
	sol.shadow_enabled = true
	sol.shadow_opacity = 0.75
	sol.light_angular_distance = 1.5
	sol.directional_shadow_max_distance = 60.0
	add_child(sol)


func _material(cor: Color, rugosidade := 0.55) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugosidade
	return m
