class_name CabideDeTintas
extends StaticBody3D
## O cabide das tintas do Faísca no térreo do farol (item 4 da lista dele, 2026-11-11): um pé de madeira com seis
## ganchos no alto, cada um com a lata de uma tinta que já saiu da Máquina de Brindes (os outros ficam vazios). O soco
## nele (fica no grupo dos alvos) abre a lojinha das tintas (`abrir`, PainelTintas), onde se escolhe a cor com a
## prévia. Até 2026-11-12 eram chapéus, trocados um a cada soco (o usuário achou que não ficou legal).

signal abrir

var derrotado := false
var raio_golpe := 0.6
var _imune := 0.0
var _ganchos := {}
var _corpo: Node3D


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.35
	cil.height = 2.6
	cs.shape = cil
	cs.position.y = 1.3
	add_child(cs)
	_corpo = Node3D.new()
	add_child(_corpo)
	var madeira := _mat(Color("c98b55"))
	var pe := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 0.45
	disco.bottom_radius = 0.5
	disco.height = 0.12
	pe.mesh = disco
	pe.material_override = madeira
	pe.position.y = 0.06
	_corpo.add_child(pe)
	var haste := MeshInstance3D.new()
	var vara := CylinderMesh.new()
	vara.top_radius = 0.06
	vara.bottom_radius = 0.08
	vara.height = 2.5
	haste.mesh = vara
	haste.material_override = madeira
	haste.position.y = 1.25
	_corpo.add_child(haste)
	var bola := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.12
	esfera.height = 0.24
	bola.mesh = esfera
	bola.material_override = _mat(Color("ff7a22"))
	bola.position.y = 2.55
	_corpo.add_child(bola)
	var ids := Brindes.ids("tinta")
	for i in ids.size():
		var a := TAU * i / ids.size()
		var gancho := Node3D.new()
		gancho.name = "Gancho_" + String(ids[i])
		gancho.position = Vector3(cos(a) * 0.42, 1.95 + (i % 2) * 0.28, sin(a) * 0.42)
		_corpo.add_child(gancho)
		var braco := MeshInstance3D.new()
		var cil2 := CylinderMesh.new()
		cil2.top_radius = 0.025
		cil2.bottom_radius = 0.025
		cil2.height = 0.42
		braco.mesh = cil2
		braco.material_override = madeira
		braco.rotation = Vector3(0, -a, PI / 2.0 - 0.35)
		braco.position = Vector3(-cos(a) * 0.21, -0.05, -sin(a) * 0.21)
		gancho.add_child(braco)
		_ganchos[ids[i]] = gancho


func _process(delta: float) -> void:
	_imune -= delta


## Mostra no gancho de cada uma as latas das tintas que já saíram.
func mostrar(ja_tem: Array) -> void:
	for id in _ganchos:
		var g: Node3D = _ganchos[id]
		var atual := g.get_node_or_null("Lata")
		if id in ja_tem and atual == null:
			var l := Brindes.lata(Brindes.cor_de(id), Brindes.metal(id))
			l.name = "Lata"
			# Pendurada pela alça na ponta do gancho, menor (a lata tem 0,5 m).
			l.scale *= 0.5
			l.position.y = -0.3
			g.add_child(l)
		elif not id in ja_tem and atual:
			atual.queue_free()


func tem_tinta(id: String) -> bool:
	var g: Node3D = _ganchos.get(id)
	return g != null and g.get_node_or_null("Lata") != null


func receber_golpe(_dano: int, de: Vector3, _forca := 6.0, _tipo := "") -> bool:
	if _imune > 0.0:
		return false
	_imune = 0.5
	var lado := signf((global_position - de).x + 0.01)
	var tw := _corpo.create_tween()
	tw.tween_property(_corpo, "rotation:z", -0.12 * lado, 0.07)
	tw.tween_property(_corpo, "rotation:z", 0.06 * lado, 0.1)
	tw.tween_property(_corpo, "rotation:z", 0.0, 0.12)
	abrir.emit()
	return true


func _mat(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.6
	return m
