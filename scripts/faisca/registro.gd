class_name Registro
extends StaticBody3D
## O registro da água da 2-1 (o momento especial "a cozinha alagando", item 9 da lista do Faísca, 2026-11-11): um
## cano saindo do tampo com a roda vermelha em cima. Um soco (ou o giro) gira a roda duas voltas e solta mais água:
## cada registro é uma etapa da enchente. Fica no grupo dos alvos dos golpes, como a alavanca (o laser e o pisão não
## giram).

signal girado(registro: Registro)

var girado_ja := false
## Para os golpes: girado conta como derrotado (não vira mais alvo).
var derrotado: bool:
	get:
		return girado_ja
var raio_golpe := 1.0
var _roda: Node3D


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	collision_layer = 1
	collision_mask = 0
	var cinza := StandardMaterial3D.new()
	cinza.albedo_color = Color("c6ccd8")
	cinza.metallic = 0.7
	cinza.roughness = 0.25
	var cano := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.28
	cil.bottom_radius = 0.34
	cil.height = 1.3
	cano.mesh = cil
	cano.material_override = cinza
	cano.position.y = 0.65
	add_child(cano)
	var base := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 0.6
	disco.bottom_radius = 0.7
	disco.height = 0.2
	base.mesh = disco
	base.material_override = cinza
	base.position.y = 0.1
	add_child(base)
	# A roda vermelha deitada em cima do cano: o aro, quatro raios e o miolo amarelo.
	_roda = Node3D.new()
	_roda.position.y = 1.4
	add_child(_roda)
	var vermelho := StandardMaterial3D.new()
	vermelho.albedo_color = Color("e2304a")
	vermelho.roughness = 0.45
	var aro := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.62
	toro.outer_radius = 0.86
	toro.rings = 32
	toro.ring_segments = 10
	aro.mesh = toro
	aro.material_override = vermelho
	_roda.add_child(aro)
	for i in 2:
		var raio := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(1.4, 0.14, 0.18)
		raio.mesh = caixa
		raio.material_override = vermelho
		raio.rotation.y = PI / 2.0 * i
		_roda.add_child(raio)
	var miolo := MeshInstance3D.new()
	var bola := SphereMesh.new()
	bola.radius = 0.24
	bola.height = 0.36
	miolo.mesh = bola
	var amarelo := StandardMaterial3D.new()
	amarelo.albedo_color = Color("ffd23f")
	miolo.material_override = amarelo
	miolo.position.y = 0.06
	_roda.add_child(miolo)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 0.8
	forma.height = 1.6
	cs.shape = forma
	cs.position.y = 0.8
	add_child(cs)


func receber_golpe(_dano: int, _de: Vector3, _forca := 6.0, _tipo := "") -> bool:
	if girado_ja:
		return false
	girar()
	return true


## Gira a roda duas voltas, com confete e o chiado da água, e avisa a fase.
func girar() -> void:
	girado_ja = true
	var tw := create_tween()
	tw.tween_property(_roda, "rotation:y", _roda.rotation.y + TAU * 2.0, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	Fx.confetti(get_parent(), global_position + Vector3.UP * 1.6, 16, 2.5)
	Sfx.play_at(get_parent(), "ui_ok", global_position, -2.0)
	Sfx.play_at(get_parent(), "poca", global_position, 0.0)
	girado.emit(self)
