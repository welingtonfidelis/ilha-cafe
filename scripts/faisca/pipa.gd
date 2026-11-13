class_name Pipa
extends Area3D
## A Pipa, o poder da 3-3 Moinhos do Vento (2026-11-12, da maquete aprovada pelo usuário): fica no celeiro da fazenda,
## girando e brilhando. Pega, vale até o fim da fase (Jogador.pipa): flutuando em cima de uma coluna de vento, ela leva
## o Faísca para o alto (sem ela, a coluna só segura a queda). Sem botão novo: é o mesmo flutuar de sempre, e a pipa
## aparece lá em cima, presa pelo fio, enquanto ele voa com ela.

signal pega(j: Jogador)

var _desenho: Node3D


## O desenho da pipa (o nó fica no meio dela): o losango laranja com a metade de cima branca, as varetas, a rabiola de
## lacinhos e o fio descendo até a mão.
static func desenho() -> Array[Node3D]:
	var partes: Array[Node3D] = []
	var laranja := StandardMaterial3D.new()
	laranja.albedo_color = Color("ff7a22")
	laranja.roughness = 0.5
	laranja.cull_mode = BaseMaterial3D.CULL_DISABLED
	var branco := StandardMaterial3D.new()
	branco.albedo_color = Color("fff8ee")
	branco.roughness = 0.5
	branco.cull_mode = BaseMaterial3D.CULL_DISABLED
	var escuro := StandardMaterial3D.new()
	escuro.albedo_color = Color("3a3150")
	# O losango: quatro triângulos (os dois de cima brancos).
	var pontas := [Vector3(0, 0.95, 0), Vector3(0.62, 0.22, 0), Vector3(0, -0.95, 0), Vector3(-0.62, 0.22, 0)]
	for k in 4:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_normal(Vector3.BACK)
		st.add_vertex(Vector3.ZERO + Vector3(0, 0.22, 0))
		st.add_vertex(pontas[k])
		st.add_vertex(pontas[(k + 1) % 4])
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = branco if k in [0, 3] else laranja
		partes.append(mi)
	for spec in [[Vector3(0, 0, 0.02), Vector3(0.05, 1.9, 0.04)], [Vector3(0, 0.22, 0.02), Vector3(1.24, 0.05, 0.04)]]:
		var vareta := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = spec[1]
		vareta.mesh = caixa
		vareta.material_override = escuro
		vareta.position = spec[0]
		partes.append(vareta)
	# A rabiola: um cordão com quatro lacinhos coloridos.
	var cores := [Color("ffd23f"), Color("3fd0ee"), Color("ff5fae"), Color("4cc27a")]
	for i in 4:
		var laco := MeshInstance3D.new()
		var caixa := BoxMesh.new()
		caixa.size = Vector3(0.42, 0.16, 0.04)
		laco.mesh = caixa
		var m := StandardMaterial3D.new()
		m.albedo_color = cores[i]
		laco.material_override = m
		laco.position = Vector3(sin(i * 1.3) * 0.18, -1.25 - i * 0.42, 0)
		partes.append(laco)
	var cordao := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.015
	cil.bottom_radius = 0.015
	cil.height = 1.7
	cordao.mesh = cil
	cordao.material_override = escuro
	cordao.position = Vector3(0, -1.75, 0)
	partes.append(cordao)
	return partes


func _ready() -> void:
	collision_layer = 0
	collision_mask = Fase.CAMADA_JOGADOR
	var forma := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 1.4
	forma.shape = esfera
	add_child(forma)
	_desenho = Node3D.new()
	_desenho.scale = Vector3.ONE * 1.2
	add_child(_desenho)
	for p in desenho():
		_desenho.add_child(p)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ffc28a")
	luz.light_energy = 1.6
	luz.omni_range = 6.0
	add_child(luz)
	var tw := create_tween().set_loops()
	tw.tween_property(_desenho, "position:y", 0.35, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_desenho, "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	var gira := create_tween().set_loops()
	gira.tween_property(_desenho, "rotation:y", TAU, 3.0).from(0.0)
	body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador and visible:
			pegar(corpo))


## O Faísca pega a pipa: vale até o fim da fase.
func pegar(j: Jogador) -> void:
	j.pipa = true
	j.robo.expressao("feliz", 1.2)
	Particulas.magia(get_parent(), global_position, Color("ff7a22"))
	Sfx.play(get_parent(), "bandeira", 0.0, 0.0)
	set_deferred("monitoring", false)
	hide()
	pega.emit(j)
