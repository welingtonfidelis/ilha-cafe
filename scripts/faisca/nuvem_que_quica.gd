class_name NuvemQueQuica
extends StaticBody3D
## Nuvem de algodão-doce que quica, a novidade da 2-2 Nuvens de Algodão-Doce (2026-10-30): quem cai em cima vai
## para o alto, como na mola (a `forca` é a mesma conta: 16 dá uns 4,9 m), e ela amassa e volta. Segurando o pulo
## na descida, ele flutua como sempre. Com `some`, a nuvem é lilás (a cor do "cuidado, some") e some logo depois
## de jogar o Faísca para cima, voltando três segundos depois: não dá para quicar duas vezes nela. O nó fica no
## meio da parte de cima, onde ele pisa. Com `neve` (3-1 Pico Gelado, 2026-10-30), é um monte de neve fofa: branco, com
## o aro laranja de "isto faz alguma coisa" na beira, para não confundir com a neve firme.

const FORA := 3.0

var raio := 2.2
var forca := 16.0
var some := false
var neve := false
var sumida := false
var area: AreaDeMola
var _visual: Node3D
var _forma: CollisionShape3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_visual = Node3D.new()
	add_child(_visual)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("c4a6ff") if some else (Color("f8fbff") if neve else Color("ff8cc6"))
	m.roughness = 1.0
	m.rim_enabled = true
	m.rim = 0.3
	if neve:
		var aro := MeshInstance3D.new()
		var toro := TorusMesh.new()
		toro.inner_radius = raio - 0.18
		toro.outer_radius = raio + 0.12
		toro.rings = 32
		aro.mesh = toro
		var laranja := StandardMaterial3D.new()
		laranja.albedo_color = Color("ff7a22")
		laranja.roughness = 0.5
		aro.material_override = laranja
		aro.position.y = -0.55
		_visual.add_child(aro)
	var bolas := [[Vector3(0, -0.4, 0), Vector3(raio, 0.55, raio)], [Vector3(raio * 0.55, -0.25, raio * 0.25), Vector3(raio * 0.6, 0.6, raio * 0.6)],
			[Vector3(-raio * 0.5, -0.3, -raio * 0.3), Vector3(raio * 0.62, 0.55, raio * 0.62)], [Vector3(-raio * 0.15, -0.3, raio * 0.5), Vector3(raio * 0.5, 0.5, raio * 0.5)],
			[Vector3(raio * 0.2, -0.3, -raio * 0.55), Vector3(raio * 0.48, 0.5, raio * 0.48)]]
	if neve:
		bolas = [[Vector3(0, -0.45, 0), Vector3(raio * 0.95, 0.5, raio * 0.95)]]
	for bola in bolas:
		var mi := MeshInstance3D.new()
		mi.mesh = Forma.superelipsoide(bola[1], 1.0, 1.0)
		mi.material_override = m
		mi.position = bola[0]
		_visual.add_child(mi)
	_forma = CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = raio
	cil.height = 0.8
	_forma.shape = cil
	_forma.position.y = -0.4
	add_child(_forma)
	area = AreaDeMola.new()
	area.forca = forca
	area.visual = _visual
	area.amassado = Vector3(1.2, 0.65, 1.2)
	var cs := CollisionShape3D.new()
	var topo := CylinderShape3D.new()
	topo.radius = raio * 0.92
	topo.height = 1.0
	cs.shape = topo
	cs.position.y = 0.4
	area.add_child(cs)
	add_child(area)
	if some:
		area.lancou.connect(func(_j: Jogador) -> void: _sumir())


func _sumir() -> void:
	if sumida:
		return
	sumida = true
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_callback(func() -> void:
		_forma.set_deferred("disabled", true)
		area.set_deferred("monitoring", false))
	tw.tween_property(_visual, "scale", Vector3.ONE * 0.05, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(_visual.hide)
	tw.tween_interval(FORA)
	tw.tween_callback(_voltar)


func _voltar() -> void:
	_visual.show()
	_forma.set_deferred("disabled", false)
	area.set_deferred("monitoring", true)
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: sumida = false)
