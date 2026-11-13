class_name Aspiratrao
extends Node3D
## A nave do Rei Bolotão, que suga as estrelas do céu na abertura da Parte 2: um disco roxo e gordinho
## com luzinhas amarelas em volta, a cúpula de vidro com o Rei dentro (uma Bolota grande de coroa torta)
## e o bocal do aspirador embaixo, girando. Feita por código, sem colisão; tem uns 20 m de largura.

## Onde as estrelas entram (espaço do mundo, para os tweens da cena).
var bocal: Node3D
var _luzes: Array[MeshInstance3D] = []
var _redemoinho: Node3D
var _tempo := 0.0


func _ready() -> void:
	var roxo := _material(Color("7a3fd0"), 0.35)
	roxo.emission_enabled = true
	roxo.emission = Color("4a1f8f")
	roxo.emission_energy_multiplier = 0.4
	var corpo := MeshInstance3D.new()
	corpo.mesh = Forma.superelipsoide(Vector3(10, 2.6, 10), 0.55, 1.0)
	corpo.material_override = roxo
	add_child(corpo)
	var aba := MeshInstance3D.new()
	aba.mesh = Forma.superelipsoide(Vector3(11.5, 0.8, 11.5), 0.5, 1.0)
	aba.material_override = _material(Color("a46bf0"), 0.4)
	add_child(aba)
	var amarelo := _material(Color("ffe066"), 0.3)
	amarelo.emission_enabled = true
	amarelo.emission = Color("ffd23f")
	amarelo.emission_energy_multiplier = 2.5
	for k in 14:
		var a := TAU * k / 14.0
		var luz := MeshInstance3D.new()
		var bola := SphereMesh.new()
		bola.radius = 0.45
		bola.height = 0.9
		luz.mesh = bola
		luz.material_override = amarelo
		luz.position = Vector3(cos(a) * 11.3, 0, sin(a) * 11.3)
		add_child(luz)
		_luzes.append(luz)
	# Cúpula de vidro com o Rei Bolotão dentro.
	var vidro := _material(Color(0.85, 0.75, 1.0, 0.35), 0.1)
	vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var cupula := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 4.2
	esfera.height = 4.2
	esfera.is_hemisphere = true
	cupula.mesh = esfera
	cupula.material_override = vidro
	cupula.position.y = 1.8
	add_child(cupula)
	var rei := MeshInstance3D.new()
	rei.mesh = Forma.superelipsoide(Vector3(2.2, 2.0, 2.2), 1.0, 1.0)
	rei.material_override = _material(Color("8a4fe0"), 0.5)
	rei.position.y = 3.6
	add_child(rei)
	var olho := MeshInstance3D.new()
	olho.mesh = Forma.superelipsoide(Vector3(0.8, 0.9, 0.4), 1.0, 1.0)
	olho.material_override = _material(Color.WHITE, 0.3)
	olho.position = Vector3(0, 3.9, 1.9)
	add_child(olho)
	var pupila := MeshInstance3D.new()
	pupila.mesh = Forma.superelipsoide(Vector3(0.35, 0.45, 0.2), 1.0, 1.0)
	pupila.material_override = _material(Color("1b1530"), 0.3)
	pupila.position = Vector3(0, 3.9, 2.25)
	add_child(pupila)
	var coroa := Node3D.new()
	coroa.position = Vector3(0.3, 5.5, 0)
	coroa.rotation.z = -0.25
	add_child(coroa)
	for k in 5:
		var a := TAU * k / 5.0
		var ponta := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.32
		cone.height = 0.9
		ponta.mesh = cone
		ponta.material_override = amarelo
		ponta.position = Vector3(cos(a) * 0.8, 0.3, sin(a) * 0.8)
		coroa.add_child(ponta)
	# Bocal do aspirador embaixo, com um redemoinho girando.
	var bocal_malha := MeshInstance3D.new()
	var funil := CylinderMesh.new()
	funil.top_radius = 2.0
	funil.bottom_radius = 3.6
	funil.height = 3.0
	bocal_malha.mesh = funil
	bocal_malha.material_override = _material(Color("5a2a9f"), 0.4)
	bocal_malha.position.y = -3.4
	add_child(bocal_malha)
	_redemoinho = Node3D.new()
	_redemoinho.position.y = -5.0
	add_child(_redemoinho)
	var rosa := _material(Color("ff8ad8"), 0.3)
	rosa.emission_enabled = true
	rosa.emission = Color("ff5ac8")
	rosa.emission_energy_multiplier = 1.5
	for k in 3:
		var anel := MeshInstance3D.new()
		var toro := TorusMesh.new()
		toro.inner_radius = 1.0 + k * 0.8
		toro.outer_radius = 1.3 + k * 0.8
		anel.mesh = toro
		anel.material_override = rosa
		anel.position.y = -k * 0.3
		_redemoinho.add_child(anel)
	bocal = Node3D.new()
	bocal.position.y = -5.5
	add_child(bocal)


func _process(delta: float) -> void:
	_tempo += delta
	_redemoinho.rotation.y += delta * 6.0
	_redemoinho.scale = Vector3.ONE * (1.0 + sin(_tempo * 8.0) * 0.06)
	for k in _luzes.size():
		_luzes[k].visible = int(_tempo * 6.0 + k) % 3 != 0
	rotation.z = sin(_tempo * 1.3) * 0.04


func _material(cor: Color, rugosidade: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugosidade
	return m
