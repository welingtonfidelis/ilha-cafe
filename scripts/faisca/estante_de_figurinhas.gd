class_name EstanteDeFigurinhas
extends StaticBody3D
## A estante das figurinhas no térreo do farol (item 4 da lista do Faísca, 2026-11-11): duas prateleiras de madeira
## com 6 vagas cada, na ordem de Brindes.ids("figurinha"). A vaga de uma figurinha que já saiu da Máquina de
## Brindes mostra ela (mexendo) num pedestal; a que falta mostra uma cápsula cinza com "?". O nó fica no chão, com
## a frente para +Z.

const LARGURA := 6.6
const PRATELEIRAS := [0.85, 1.95]
const VAGA := 1.05

var _vagas := {}


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(LARGURA + 0.3, 2.9, 0.8)
	cs.shape = caixa
	cs.position = Vector3(0, 1.45, -0.1)
	add_child(cs)
	var madeira := _mat(Color("c98b55"))
	var clara := _mat(Color("dca46c"))
	_caixa(Vector3(LARGURA + 0.3, 2.9, 0.12), Vector3(0, 1.45, -0.42), clara)
	for x in [-1.0, 1.0]:
		_caixa(Vector3(0.15, 2.9, 0.8), Vector3(x * (LARGURA * 0.5 + 0.08), 1.45, -0.1), madeira)
	_caixa(Vector3(LARGURA + 0.3, 0.12, 0.8), Vector3(0, 2.86, -0.1), madeira)
	for y in PRATELEIRAS:
		_caixa(Vector3(LARGURA, 0.1, 0.7), Vector3(0, y - 0.05, -0.1), madeira)
		# A faixa laranja na beira de cada prateleira, como no farol.
		_caixa(Vector3(LARGURA, 0.06, 0.04), Vector3(0, y - 0.06, 0.26), _mat(Color("ff7a22")))
	var ids := Brindes.ids("figurinha")
	for i in ids.size():
		var linha := i / 6
		var coluna := i % 6
		var vaga := Node3D.new()
		vaga.name = "Vaga_" + String(ids[i])
		vaga.position = Vector3((coluna - 2.5) * VAGA, PRATELEIRAS[linha], 0.0)
		add_child(vaga)
		var pedestal := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = 0.28
		cil.bottom_radius = 0.3
		cil.height = 0.08
		pedestal.mesh = cil
		pedestal.material_override = _mat(Color("f3ead8"))
		pedestal.position.y = 0.04
		vaga.add_child(pedestal)
		_vagas[ids[i]] = vaga


## Mostra as figurinhas que já saíram (`ja_tem` são ids de brindes) e o "?" nas outras.
func mostrar(ja_tem: Array) -> void:
	for id in _vagas:
		var vaga: Node3D = _vagas[id]
		var tem: bool = id in ja_tem
		var atual := vaga.get_node_or_null("Figurinha")
		var falta := vaga.get_node_or_null("Falta")
		if tem and atual == null:
			if falta:
				falta.queue_free()
			por(id)
		elif not tem and falta == null:
			if atual:
				atual.queue_free()
			_falta(vaga)


## Põe a figurinha `id` na vaga dela.
func por(id: String) -> void:
	var vaga: Node3D = _vagas.get(id)
	if vaga == null or vaga.get_node_or_null("Figurinha"):
		return
	var falta := vaga.get_node_or_null("Falta")
	if falta:
		falta.free()
	var f := Brindes.figurinha(id)
	if f == null:
		return
	var raiz := Node3D.new()
	raiz.name = "Figurinha"
	raiz.position.y = 0.08
	raiz.add_child(f)
	vaga.add_child(raiz)


## Onde fica a vaga de `id` (para o brinde voar até ela).
func lugar(id: String) -> Vector3:
	var vaga: Node3D = _vagas.get(id)
	return vaga.global_position + Vector3.UP * 0.1 if vaga else global_position + Vector3.UP * 1.5


func tem_figurinha(id: String) -> bool:
	var vaga: Node3D = _vagas.get(id)
	return vaga != null and vaga.get_node_or_null("Figurinha") != null


func _falta(vaga: Node3D) -> void:
	var raiz := Node3D.new()
	raiz.name = "Falta"
	raiz.position.y = 0.3
	vaga.add_child(raiz)
	var cap := MaquinaDeBrindes.capsula(Color("8a8fa6"), 0.2)
	raiz.add_child(cap)
	var l := Label3D.new()
	l.text = "?"
	l.font_size = 48
	l.pixel_size = 0.01
	l.outline_size = 10
	l.outline_modulate = Color(0.08, 0.06, 0.18)
	l.position = Vector3(0, 0.02, 0.22)
	raiz.add_child(l)


func _caixa(tamanho: Vector3, pos: Vector3, material: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tamanho
	mi.mesh = b
	mi.material_override = material
	mi.position = pos
	add_child(mi)


func _mat(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.6
	return m
