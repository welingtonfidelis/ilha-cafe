class_name NuvemQueSome
extends StaticBody3D
## Nuvem lilás que some (pedido do usuário em 2026-10-29, "as fases estão muito curtas"): um instante depois que
## o Faísca pisa nela, ela treme, encolhe e some; três segundos depois volta. Ensina a não parar no caminho. A
## cor lilás diferencia das nuvens brancas, que são firmes. O `topo` é o nó (o meio da parte de cima).

const ANTES := 0.8
const FORA := 3.0

var raio := 1.6
## Bolha de sabão (a pia da 2-1) em vez de nuvem: a mesma coisa, só o desenho muda.
var bolha := false
## Pingente de gelo lilás deitado (a parede do Pico Gelado, 3-1): a placa em cima e a ponta para baixo.
var pingente := false
var sumida := false
var _visual: Node3D
## A bolha de sabão (desenho e espuma) balança devagar dentro do _visual (que treme quando ela vai estourar).
var _bolha: Node3D
var _tempo := 0.0
var _forma: CollisionShape3D
var _contando := -1.0


func _ready() -> void:
	set_meta("superficie", "nuvem")
	collision_layer = 1
	collision_mask = 0
	_visual = Node3D.new()
	add_child(_visual)
	if bolha:
		# Bem visível para criança (2026-11-13): a película de arco-íris (bolha_sabao.gdshader), mais alta, um brilho
		# branco em cima e um anel de espuma branca na linha da água, marcando onde a bolha está. Antes era uma esfera
		# azul clarinha, quase transparente, que sumia contra a água.
		_bolha = Node3D.new()
		_visual.add_child(_bolha)
		var b := ShaderMaterial.new()
		b.shader = preload("res://scripts/faisca/bolha_sabao.gdshader")
		var esfera := MeshInstance3D.new()
		esfera.mesh = Forma.superelipsoide(Vector3(raio, raio * 0.72, raio), 1.0, 1.0)
		esfera.material_override = b
		esfera.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		esfera.position.y = -raio * 0.62
		_bolha.add_child(esfera)
		var reflexo := StandardMaterial3D.new()
		reflexo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		reflexo.albedo_color = Color(1, 1, 1, 0.9)
		reflexo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var brilho := MeshInstance3D.new()
		brilho.mesh = Forma.superelipsoide(Vector3(raio * 0.22, raio * 0.08, raio * 0.12), 1.0, 1.0)
		brilho.material_override = reflexo
		brilho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		brilho.position = Vector3(-raio * 0.38, raio * 0.02, raio * 0.3)
		brilho.rotation = Vector3(0.3, 0.6, 0.35)
		_bolha.add_child(brilho)
		var espuma := StandardMaterial3D.new()
		espuma.albedo_color = Color("fbfdff")
		espuma.roughness = 0.75
		for k in 12:
			var a := TAU * k / 12.0
			var tufo := MeshInstance3D.new()
			var r := raio * (0.3 + 0.06 * sin(a * 3.0))
			tufo.mesh = Forma.superelipsoide(Vector3(r, r * 0.6, r), 1.0, 1.0)
			tufo.material_override = espuma
			tufo.position = Vector3(cos(a) * raio * 0.95, -raio * 0.74, sin(a) * raio * 0.95)
			_bolha.add_child(tufo)
	if pingente:
		var gelo := StandardMaterial3D.new()
		gelo.albedo_color = Color(0.82, 0.72, 1.0, 0.85)
		gelo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gelo.roughness = 0.1
		gelo.rim_enabled = true
		gelo.rim = 0.7
		gelo.emission_enabled = true
		gelo.emission = Color("c9a8ff")
		gelo.emission_energy_multiplier = 0.25
		var placa := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = raio
		cil.bottom_radius = raio * 0.92
		cil.height = 0.6
		placa.mesh = cil
		placa.material_override = gelo
		placa.position.y = -0.3
		_visual.add_child(placa)
		var ponta := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = raio * 0.85
		cone.bottom_radius = 0.0
		cone.height = 2.4
		ponta.mesh = cone
		ponta.material_override = gelo
		ponta.position.y = -1.8
		# A ponta fica embaixo da placa, onde ninguém pisa.
		_visual.add_child(Fase.so_enfeite(ponta))
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("d9c2ff")
	m.roughness = 1.0
	for bola in ([] if bolha or pingente else [[Vector3(0, -0.35, 0), Vector3(raio, 0.5, raio)], [Vector3(raio * 0.5, -0.2, raio * 0.3), Vector3(raio * 0.6, 0.55, raio * 0.6)],
			[Vector3(-raio * 0.45, -0.25, -raio * 0.35), Vector3(raio * 0.65, 0.5, raio * 0.6)], [Vector3(-raio * 0.2, -0.3, raio * 0.5), Vector3(raio * 0.5, 0.45, raio * 0.5)]]):
		var mi := MeshInstance3D.new()
		mi.mesh = Forma.superelipsoide(bola[1], 1.0, 1.0)
		mi.material_override = m
		mi.position = bola[0]
		_visual.add_child(mi)
	_forma = CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = raio
	cil.height = 0.7
	_forma.shape = cil
	_forma.position.y = -0.35
	add_child(_forma)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = Fase.CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var topo := CylinderShape3D.new()
	topo.radius = raio
	topo.height = 0.6
	cs.shape = topo
	cs.position.y = 0.3
	area.add_child(cs)
	add_child(area)
	area.body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador and not sumida and _contando < 0.0:
			_contando = ANTES)


func _physics_process(delta: float) -> void:
	if _bolha:
		# Balança de leve, chamando o olho (cada bolha num tempo, pela posição).
		_tempo += delta
		_bolha.position.y = sin(_tempo * 2.2 + position.x + position.z * 0.7) * 0.06
	if _contando < 0.0:
		return
	_contando -= delta
	# Tremendo enquanto conta.
	_visual.position = Vector3(randf_range(-0.06, 0.06), 0, randf_range(-0.06, 0.06))
	if _contando <= 0.0:
		_contando = -1.0
		_sumir()


func _sumir() -> void:
	sumida = true
	_visual.position = Vector3.ZERO
	_forma.set_deferred("disabled", true)
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3.ONE * 0.05, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(_visual.hide)
	tw.tween_interval(FORA)
	tw.tween_callback(_voltar)


func _voltar() -> void:
	sumida = false
	_visual.show()
	_forma.set_deferred("disabled", false)
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
