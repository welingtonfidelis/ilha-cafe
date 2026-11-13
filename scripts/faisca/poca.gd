class_name Poca
extends Area3D
## Poça que espirra (item 6 da lista do Faísca, 2026-11-11, o "mundo que reage" do Astro Bot): cada passo do Faísca
## dentro dela solta respingos na cor dela e uma rodinha na água, e cair de um pulo (ou de uma pancada do Martelinho)
## espirra alto. Enquanto ele está dentro, o chão do controle é "agua" (a tremida de passo muda) e os passos não
## levantam poeira. Cada mundo tem a sua cor: água, leite e suco na cozinha, calda nas nuvens, tinta no quarto.

const CORES := {
	"agua": Color(0.42, 0.72, 1.0, 0.72), "leite": Color(0.98, 0.97, 0.94, 0.95), "suco": Color(1.0, 0.64, 0.18, 0.88),
	"calda": Color(1.0, 0.5, 0.72, 0.85), "tinta": Color(0.3, 0.55, 1.0, 0.92),
}
const QUEDA_QUE_ESPIRRA := 4.0

var tipo := "agua"
var raio := 1.6
## Quantas vezes espirrou (para os testes).
var espirros := 0
var cor := Color.WHITE
var _jogador: Jogador
var _caindo := false
var _malha_gota: SphereMesh
var _mat_gota: StandardMaterial3D


func _init(qual := "agua", tamanho := 1.6) -> void:
	tipo = qual
	raio = tamanho


func _ready() -> void:
	cor = CORES.get(tipo, CORES.agua)
	collision_layer = 0
	collision_mask = Fase.CAMADA_JOGADOR
	monitorable = false
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = raio
	cil.height = 0.8
	cs.shape = cil
	cs.position.y = 0.3
	add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = _forma()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	mat.roughness = 0.06
	mat.metallic_specular = 0.9
	if cor.a < 0.99:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 0.035
	mi.set_meta("enfeite", true)
	add_child(mi)
	_malha_gota = SphereMesh.new()
	_malha_gota.radius = 0.07
	_malha_gota.height = 0.14
	_malha_gota.radial_segments = 6
	_malha_gota.rings = 3
	_mat_gota = StandardMaterial3D.new()
	_mat_gota.albedo_color = Color(cor, 1.0).lightened(0.15)
	_mat_gota.roughness = 0.1
	body_entered.connect(_entrou)
	body_exited.connect(_saiu)


func _physics_process(_delta: float) -> void:
	if _jogador == null:
		return
	# Caiu de um pulo dentro da poça: o espirro grande.
	if not _jogador.is_on_floor():
		_caindo = _jogador.velocity.y < -QUEDA_QUE_ESPIRRA
	elif _caindo:
		_caindo = false
		espirrar(_jogador.global_position, 1.8)


func _entrou(corpo: Node3D) -> void:
	if corpo is Jogador:
		_jogador = corpo
		_jogador.na_poca = self
		_caindo = not _jogador.is_on_floor() and _jogador.velocity.y < -QUEDA_QUE_ESPIRRA


func _saiu(corpo: Node3D) -> void:
	if corpo == _jogador:
		if _jogador.na_poca == self:
			_jogador.na_poca = null
		_jogador = null


## Respingos em `pos` (no chão da poça): `forca` 1 é um passo, 2 é cair de um pulo. Solta uma rodinha na água.
func espirrar(pos: Vector3, forca := 1.0) -> void:
	espirros += 1
	var no_chao := Vector3(pos.x, global_position.y + 0.06, pos.z)
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = int(6 + 8 * forca)
	p.lifetime = 0.35 + 0.15 * forca
	p.explosiveness = 0.95
	p.direction = Vector3.UP
	p.spread = 40.0
	p.initial_velocity_min = 1.6 * forca
	p.initial_velocity_max = 3.2 * forca
	p.gravity = Vector3(0, -16.0, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0 + 0.3 * forca
	p.mesh = _malha_gota
	p.material_override = _mat_gota
	get_parent().add_child(p)
	p.global_position = no_chao
	p.emitting = true
	p.finished.connect(p.queue_free)
	_rodinha(no_chao, forca)
	if forca >= 1.5:
		Sfx.play_at(get_parent(), "splash", no_chao, -8.0, 0.15)
		if _jogador:
			_jogador.tremidinha(0.35)
	else:
		Sfx.play_at(get_parent(), "poca", no_chao, -12.0, 0.2)


## A rodinha que abre na água e some.
func _rodinha(pos: Vector3, forca: float) -> void:
	var anel := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.24
	toro.outer_radius = 0.3
	toro.rings = 20
	toro.ring_segments = 4
	anel.mesh = toro
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 1, 1, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	anel.material_override = m
	anel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(anel)
	anel.global_position = pos
	anel.scale = Vector3(1, 0.15, 1)
	var tw := anel.create_tween().set_parallel()
	var ate := minf(1.2 + forca, raio * 1.6)
	tw.tween_property(anel, "scale", Vector3(ate, 0.15, ate), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.5)
	tw.chain().tween_callback(anel.queue_free)


## A poça não é redonda certinha: um contorno com ondinhas (sempre o mesmo para a mesma poça).
func _forma() -> ArrayMesh:
	var g := RandomNumberGenerator.new()
	g.seed = hash(Vector2i(roundi(global_position.x * 10.0), roundi(global_position.z * 10.0))) if is_inside_tree() else 7
	var fases := [g.randf() * TAU, g.randf() * TAU, g.randf() * TAU]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 28
	var borda: Array[Vector3] = []
	for i in n:
		var a := TAU * i / n
		var r := raio * (1.0 + 0.1 * sin(2.0 * a + fases[0]) + 0.07 * sin(3.0 * a + fases[1]) + 0.05 * sin(5.0 * a + fases[2]))
		borda.append(Vector3(cos(a) * r, 0, sin(a) * r))
	for i in n:
		# Na ordem da Forma: de cima, a borda no sentido do relógio é a face da frente.
		for v in [Vector3.ZERO, borda[i], borda[(i + 1) % n]]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	return st.commit()
