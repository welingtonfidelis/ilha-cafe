class_name ColunaDeVento
extends Area3D
## Coluna de vento da 3-3 Moinhos do Vento (2026-11-12): uma grade escura no chão com o aro laranja, um tubo de ar
## clarinho e fitas brancas subindo em espiral. Com a Pipa (Jogador.pipa), flutuar em cima dela leva o Faísca para o
## alto, até `topo_y`, e ele fica pairando lá enquanto segurar o pulo; sem a pipa, a coluna só segura a queda (desce
## devagar). Desligada (`ligada` falso, as das janelas do Moinho Gigante), some, e `ligar` faz ela subir.

signal ligou

## Altura (y no mundo) até onde ela leva; o nó fica no meio da grade, no chão.
var topo_y := 13.0
var raio := 1.7
var ligada := true

const SOBE := 7.0
## Sem a pipa, a descida devagar (a velocidade de flutuar é 0,4 para cima; somado, uns 0,5 m/s para baixo).
const SEGURA := -0.9
## Lá no alto, com a pipa: parado no ar (a velocidade de flutuar é 0,4 para cima); passando do topo, puxa de volta,
## como uma mola (senão o embalo da subida levava uns 1,5 m acima).
const PAIRA := -0.4
const VOLTA_DO_TOPO := 3.5

var _tempo := 0.0
var _fitas: MultiMeshInstance3D
var _tubo: MeshInstance3D
var _altura := 10.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Fase.CAMADA_JOGADOR
	monitorable = false
	_altura = maxf(topo_y - global_position.y, 2.0)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = raio
	cil.height = _altura + 2.5
	cs.shape = cil
	cs.position.y = cil.height * 0.5 - 0.2
	add_child(cs)
	# A grade no chão (encostada, sem colisão: o Faísca pisa no chão de baixo) e o aro laranja.
	var grade := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = raio
	disco.bottom_radius = raio
	disco.height = 0.1
	grade.mesh = disco
	var escuro := StandardMaterial3D.new()
	escuro.albedo_color = Color("55607a")
	escuro.metallic = 0.4
	escuro.roughness = 0.5
	grade.material_override = escuro
	grade.position.y = 0.06
	add_child(Fase.so_enfeite(grade))
	for k in 5:
		var barra := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(raio * 1.9 * sqrt(1.0 - pow((k - 2) / 2.6, 2.0)), 0.06, 0.12)
		barra.mesh = caixa
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("2b2140")
		barra.material_override = m
		barra.position = Vector3(0, 0.13, (k - 2) * raio * 0.36)
		add_child(Fase.so_enfeite(barra))
	var aro := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = raio - 0.08
	toro.outer_radius = raio + 0.22
	aro.mesh = toro
	var laranja := StandardMaterial3D.new()
	laranja.albedo_color = Color("ff7a22")
	aro.material_override = laranja
	aro.position.y = 0.12
	add_child(Fase.so_enfeite(aro))
	# O tubo de ar e as fitas.
	_tubo = MeshInstance3D.new()
	var tubo := CylinderMesh.new()
	tubo.top_radius = raio * 0.95
	tubo.bottom_radius = raio * 0.95
	tubo.height = _altura
	tubo.cap_top = false
	tubo.cap_bottom = false
	_tubo.mesh = tubo
	var ar := StandardMaterial3D.new()
	ar.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ar.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ar.albedo_color = Color(0.85, 0.95, 1.0, 0.13)
	ar.cull_mode = BaseMaterial3D.CULL_DISABLED
	_tubo.material_override = ar
	_tubo.position.y = _altura * 0.5
	_tubo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(Fase.so_enfeite(_tubo))
	var fita := BoxMesh.new()
	fita.size = Vector3(0.1, 1.1, 0.1)
	var branco := StandardMaterial3D.new()
	branco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	branco.albedo_color = Color("ffffff")
	fita.material = branco
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = fita
	mm.instance_count = 9
	_fitas = MultiMeshInstance3D.new()
	_fitas.multimesh = mm
	_fitas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(Fase.so_enfeite(_fitas))
	_tempo = randf() * 5.0
	_desenhar()
	if not ligada:
		_tubo.scale = Vector3(1, 0.01, 1)
		_fitas.visible = false


## Liga a coluna (as janelas do Moinho Gigante): o tubo cresce do chão e as fitas aparecem.
func ligar() -> void:
	if ligada:
		return
	ligada = true
	_fitas.visible = true
	var tw := create_tween()
	tw.tween_property(_tubo, "scale:y", 1.0, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.confetti(get_parent(), global_position + Vector3.UP * 1.0, 16, 2.5)
	Sfx.play_at(get_parent(), "vento", global_position, 0.0, 0.05)
	ligou.emit()


func _physics_process(_delta: float) -> void:
	if not ligada:
		return
	for corpo in get_overlapping_bodies():
		if corpo is Jogador:
			var j := corpo as Jogador
			if not j.pipa:
				j.soprar(Vector3.UP * SEGURA)
			elif j.global_position.y < topo_y - 0.3:
				j.soprar(Vector3.UP * SOBE)
			else:
				j.soprar(Vector3.UP * (PAIRA - VOLTA_DO_TOPO * maxf(j.global_position.y - topo_y, 0.0)))


func _process(delta: float) -> void:
	_tempo += delta
	if ligada:
		_desenhar()


func _desenhar() -> void:
	var mm := _fitas.multimesh
	for i in mm.instance_count:
		var k := fmod(i / float(mm.instance_count) + _tempo * 0.32, 1.0)
		var a := TAU * i / float(mm.instance_count) + _tempo * 2.2
		var some := clampf(minf(k, 1.0 - k) * 6.0, 0.0, 1.0)
		var b := Basis(Vector3.UP, a).scaled(Vector3(some, some, some))
		mm.set_instance_transform(i, Transform3D(b, Vector3(cos(a) * raio * 0.62, k * _altura, sin(a) * raio * 0.62)))
