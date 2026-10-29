class_name NuvemQueSome
extends StaticBody3D
## Nuvem lilás que some (pedido do usuário em 2026-10-29, "as fases estão muito curtas"): um instante depois que
## o Faísca pisa nela, ela treme, encolhe e some; três segundos depois volta. Ensina a não parar no caminho. A
## cor lilás diferencia das nuvens brancas, que são firmes. O `topo` é o nó (o meio da parte de cima).

const ANTES := 0.8
const FORA := 3.0

var raio := 1.6
var sumida := false
var _visual: Node3D
var _forma: CollisionShape3D
var _contando := -1.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_visual = Node3D.new()
	add_child(_visual)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("d9c2ff")
	m.roughness = 1.0
	for bola in [[Vector3(0, -0.35, 0), Vector3(raio, 0.5, raio)], [Vector3(raio * 0.5, -0.2, raio * 0.3), Vector3(raio * 0.6, 0.55, raio * 0.6)],
			[Vector3(-raio * 0.45, -0.25, -raio * 0.35), Vector3(raio * 0.65, 0.5, raio * 0.6)], [Vector3(-raio * 0.2, -0.3, raio * 0.5), Vector3(raio * 0.5, 0.45, raio * 0.5)]]:
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
