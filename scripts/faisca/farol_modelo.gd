class_name FarolModelo
extends Node3D
## O farol da ilha, a casa do Faísca: duas torres redondas do Medieval Hexagon do KayKit empilhadas
## (a `building_tower_base` embaixo e a `building_tower_B`, a de varanda com telhado cônico, em cima),
## com faixas laranja e branca (as cores do Faísca) tapando a emenda e a porta da torre de cima. Na
## varanda, a lâmpada ciano (a cor dos olhos dele) e dois fachos de luz girando. As medidas de dentro
## estão na escala do pacote (a torre de baixo tem 1,5 de altura); `escala` amplia tudo. A porta fica
## virada para +Z. Usado na ilha (scripts/faisca/farol_ilha.gd) e ao longe nas fases (Fase.farol).

const PASTA := "res://assets/faisca/farol/"
## Altura da emenda entre as torres e o meio da varanda da torre de cima (escala do pacote).
const EMENDA := 1.5
const VARANDA := 3.27
const RAIO_FAIXA := 0.61
const LARANJA := Color("ff7a22")
const BRANCO := Color("f4f4f6")
const LUZ := Color("8ff3ff")

@export var escala := 1.0
## Com colisão (na ilha); ao longe nas fases não precisa.
@export var solido := false

var aceso := false
var _lampada: MeshInstance3D
var _mat_lampada: StandardMaterial3D
var _luz: OmniLight3D
var _fachos: Node3D


func _ready() -> void:
	scale = Vector3.ONE * escala
	var base: Node3D = load(PASTA + "building_tower_base_red.gltf").instantiate()
	add_child(base)
	var torre: Node3D = load(PASTA + "building_tower_B_red.gltf").instantiate()
	torre.position.y = EMENDA
	add_child(torre)
	if solido:
		for mi in find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).create_trimesh_collision()
	for i in 3:
		var anel := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.radial_segments = 8
		cil.top_radius = RAIO_FAIXA
		cil.bottom_radius = RAIO_FAIXA
		cil.height = 0.17
		anel.mesh = cil
		anel.material_override = _plastico(LARANJA if i % 2 == 0 else BRANCO)
		# As torres do pacote são octógonos com uma face virada para a frente.
		anel.rotation.y = PI / 8.0
		anel.position.y = EMENDA + 0.085 + i * 0.17
		add_child(anel)
	# Lâmpada: um vidro ciano em volta da salinha da varanda, que brilha pelas janelas.
	_mat_lampada = StandardMaterial3D.new()
	_mat_lampada.albedo_color = Color(0.75, 0.97, 1.0, 0.85)
	_mat_lampada.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_lampada.emission_enabled = true
	_mat_lampada.emission = LUZ
	_lampada = MeshInstance3D.new()
	var vidro := CylinderMesh.new()
	vidro.radial_segments = 8
	vidro.top_radius = 0.43
	vidro.bottom_radius = 0.43
	vidro.height = 0.34
	_lampada.mesh = vidro
	_lampada.material_override = _mat_lampada
	_lampada.rotation.y = PI / 8.0
	_lampada.position.y = VARANDA
	_lampada.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_lampada)
	_luz = OmniLight3D.new()
	_luz.light_color = LUZ
	_luz.omni_range = 2.5
	_luz.position.y = VARANDA
	add_child(_luz)
	_fachos = Node3D.new()
	_fachos.position.y = VARANDA
	add_child(_fachos)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	# O facho some aos poucos longe da lâmpada (o v da textura corre ao longo do cone).
	var degrade := Gradient.new()
	degrade.set_color(0, Color(0.55, 0.9, 1.0, 0.3))
	degrade.set_color(1, Color(0.55, 0.9, 1.0, 0.0))
	var textura := GradientTexture2D.new()
	textura.gradient = degrade
	textura.fill_from = Vector2(0, 0)
	textura.fill_to = Vector2(0, 1)
	m.albedo_texture = textura
	for lado in [-1.0, 1.0]:
		var facho := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.05
		cone.bottom_radius = 0.7
		cone.height = 6.0
		cone.cap_top = false
		cone.cap_bottom = false
		facho.mesh = cone
		facho.material_override = m
		facho.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# A ponta fina (o topo do cilindro) fica na lâmpada.
		facho.rotation = Vector3(0, 0, PI / 2.0 * lado)
		facho.position = Vector3(3.45 * lado, 0, 0)
		_fachos.add_child(facho)
	acender(aceso)


func _process(delta: float) -> void:
	if aceso:
		_fachos.rotation.y += delta * 0.9


## Lâmpada acesa (fachos girando) ou apagada (o vidro fica escuro).
func acender(ligado: bool) -> void:
	aceso = ligado
	if _lampada == null:
		return
	_mat_lampada.emission_energy_multiplier = 3.0 if ligado else 0.0
	_mat_lampada.albedo_color = Color(0.75, 0.97, 1.0, 0.85) if ligado else Color(0.25, 0.3, 0.4, 0.9)
	_luz.light_energy = 2.5 if ligado else 0.0
	_fachos.visible = ligado


## Meio da porta, no chão, um passo para fora (espaço do mundo).
func porta() -> Vector3:
	return to_global(Vector3(0, 0, 0.62))


func _plastico(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.6
	return m
