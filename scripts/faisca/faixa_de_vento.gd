class_name FaixaDeVento
extends Area3D
## Faixa de vento da 3-3 Moinhos do Vento (2026-11-12, da maquete aprovada pelo usuário). O vento se vê: riscos brancos
## correndo para onde ele sopra, num volume clarinho, e birutas laranja e brancas nas pontas. Flutuando dentro dela, o
## Faísca é levado (Jogador.soprar) e o voo não acaba enquanto estiver no vento: passa vãos de 14 a 18 m, que o voo
## sozinho (uns 11) não passa; contra o vento, não avança. Sem flutuar, o vento só empurra um pouquinho.
## A `rajada` sopra RAJADA_LIGA s e para RAJADA_DESLIGA s (no corredor dos moinhos); um pouco antes de voltar, as
## birutas se agitam e as folhas passam: é a deixa para esperar.

signal mudou(ativa: bool)

## De onde o vento vem e para onde vai (o meio da faixa, no ar), a largura e a altura do volume, e a força em m/s.
var de := Vector3.ZERO
var ate := Vector3(0, 0, -10)
var largura := 6.0
var altura := 4.5
var forca := 7.5
var rajada := false
## Defasagem da rajada (s), para duas rajadas vizinhas não soprarem juntas.
var fase_da_rajada := 0.0
var ativa := true
var avisando := false

const RAJADA_LIGA := 2.6
const RAJADA_DESLIGA := 2.4
const AVISO := 1.0

var _dir := Vector3.FORWARD
var _comp := 10.0
var _tempo := 0.0
var _riscos: MultiMeshInstance3D
var _dados := []
var _volume: MeshInstance3D
var _birutas: Array[Node3D] = []
var _visivel := 1.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Fase.CAMADA_JOGADOR
	monitorable = false
	_dir = (ate - de).normalized()
	_comp = de.distance_to(ate)
	global_position = (de + ate) * 0.5
	var acima := Vector3.UP if absf(_dir.y) < 0.95 else Vector3.FORWARD
	global_basis = Basis.looking_at(_dir, acima)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(largura, altura, _comp)
	cs.shape = caixa
	add_child(cs)
	# O volume clarinho, quase invisível (só para ver onde a faixa está).
	_volume = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = caixa.size
	_volume.mesh = bm
	var nevoa := StandardMaterial3D.new()
	nevoa.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	nevoa.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	nevoa.albedo_color = Color(1, 1, 1, 0.07)
	nevoa.cull_mode = BaseMaterial3D.CULL_DISABLED
	nevoa.no_depth_test = false
	_volume.material_override = nevoa
	_volume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(Fase.so_enfeite(_volume))
	# Os riscos brancos correndo de `de` para `ate` (o -Z do nó).
	var n := clampi(int(_comp * largura / 5.0) + 8, 10, 70)
	var risco := BoxMesh.new()
	risco.size = Vector3(0.08, 0.08, 1.0)
	var branco := StandardMaterial3D.new()
	branco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	branco.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	branco.albedo_color = Color(1, 1, 1, 0.85)
	risco.material = branco
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = risco
	mm.instance_count = n
	var g := RandomNumberGenerator.new()
	g.seed = hash(de) ^ hash(ate)
	for i in n:
		_dados.append([g.randf(), g.randf_range(-0.45, 0.45) * largura, g.randf_range(-0.42, 0.42) * altura,
				g.randf_range(0.22, 0.4) * 7.5 / maxf(_comp, 1.0), g.randf_range(1.4, 3.0)])
	_riscos = MultiMeshInstance3D.new()
	_riscos.multimesh = mm
	_riscos.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(Fase.so_enfeite(_riscos))
	_desenhar_riscos()


## Uma biruta laranja e branca em `pe` (no chão), apontando para onde esta faixa sopra; agita nas rajadas.
func biruta_em(pe: Vector3) -> Node3D:
	var b := biruta(get_parent(), pe, _dir)
	_birutas.append(b)
	return b


## Biruta solta (enfeite): o poste escuro e a manga de quatro anéis.
static func biruta(pai: Node, pe: Vector3, para: Vector3) -> Node3D:
	var raiz := Node3D.new()
	pai.add_child(Fase.so_enfeite(raiz))
	raiz.global_position = pe
	var escuro := StandardMaterial3D.new()
	escuro.albedo_color = Color("2b2140")
	var poste := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.09
	cil.bottom_radius = 0.12
	cil.height = 4.0
	poste.mesh = cil
	poste.material_override = escuro
	poste.position.y = 2.0
	raiz.add_child(poste)
	var manga := Node3D.new()
	manga.name = "Manga"
	manga.position.y = 3.8
	raiz.add_child(manga)
	for i in 4:
		var anel := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.5 - i * 0.09
		c.bottom_radius = 0.42 - i * 0.09
		c.height = 0.7
		c.cap_top = false
		c.cap_bottom = false
		anel.mesh = c
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("ff7a22") if i % 2 == 0 else Color("fff8ee")
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		anel.material_override = m
		anel.rotation.x = PI / 2.0
		anel.position.z = -(0.4 + i * 0.68)
		manga.add_child(anel)
	var h := Vector3(para.x, 0, para.z)
	if h.length() > 0.01:
		raiz.rotation.y = atan2(-h.x, -h.z)
	return raiz


func _physics_process(delta: float) -> void:
	_tempo += delta
	if rajada:
		var ciclo := RAJADA_LIGA + RAJADA_DESLIGA
		var t := fmod(_tempo + fase_da_rajada, ciclo)
		var agora := t < RAJADA_LIGA
		avisando = not agora and t > ciclo - AVISO
		if agora != ativa:
			ativa = agora
			mudou.emit(ativa)
	if not ativa:
		return
	for corpo in get_overlapping_bodies():
		if corpo is Jogador:
			(corpo as Jogador).soprar(_dir * forca)


func _process(delta: float) -> void:
	_visivel = move_toward(_visivel, 1.0 if ativa else 0.0, delta * 2.5)
	_riscos.visible = _visivel > 0.02
	_volume.visible = _visivel > 0.02
	_desenhar_riscos()
	# As birutas: esticadas e tremendo no vento, caídas sem vento, agitadas no aviso.
	for b in _birutas:
		var manga := b.get_node("Manga") as Node3D
		var caida := 1.15 * (1.0 - _visivel)
		var treme := sin(_tempo * (22.0 if avisando else 9.0) + b.global_position.x) * (0.18 if avisando else 0.06 * _visivel)
		manga.rotation.x = -caida + treme
		manga.rotation.y = sin(_tempo * 3.0) * 0.08


func _desenhar_riscos() -> void:
	var mm := _riscos.multimesh
	for i in _dados.size():
		var d: Array = _dados[i]
		var k := fmod(float(d[0]) + _tempo * float(d[3]), 1.0)
		var z := _comp * 0.5 - k * _comp
		# Nascem e somem finos nas pontas.
		var ponta := clampf(minf(k, 1.0 - k) * 8.0, 0.0, 1.0) * _visivel
		var t := Transform3D(Basis.from_scale(Vector3(ponta, ponta, float(d[4]) * maxf(ponta, 0.05))), Vector3(d[1], d[2], z))
		mm.set_instance_transform(i, t)
