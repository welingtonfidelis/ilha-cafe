extends SceneTree
## Fotos de referência da Bolota para gerar arte de inimigos novos: de frente, de três quartos e ao lado
## do Faísca (escala). Fundo claro e liso, para o gerador de imagem não copiar cenário.
## Precisa de janela (não roda com --headless):
##   godot --path . -s tools/foto_bolota.gd
## Salva em tools/capturas/faisca/bolota/<vista>.png; o docs/inimigos/referencia-bolota.png junta as três.

const PASTA := "res://tools/capturas/faisca/bolota/"
const TAMANHO := Vector2i(800, 800)

const VISTAS := [
	{"nome": "frente", "orto": true, "tamanho": 1.9, "pos": Vector3(0, 0.78, 8), "alvo": Vector3(0, 0.78, 0), "faisca": false},
	{"nome": "tres_quartos", "orto": false, "pos": Vector3(1.9, 1.5, 3.0), "alvo": Vector3(0, 0.7, 0), "faisca": false},
	{"nome": "com_o_faisca", "orto": false, "pos": Vector3(0.4, 1.6, 6.2), "alvo": Vector3(-0.9, 0.95, 0), "faisca": true},
]

var _bolota: Alvo
var _robo: Robo
var _cam: Camera3D
var _q := 0


func _initialize() -> void:
	DisplayServer.window_set_size(TAMANHO)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	_montar_estudio()
	_bolota = Alvo.new()
	root.add_child(_bolota)
	_robo = Robo.new()
	_robo.position = Vector3(-1.9, 0, 0)
	root.add_child(_robo)
	_robo.set("rosto_parado", true)


func _process(_delta: float) -> bool:
	_q += 1
	if _q < 8:
		return false
	var k := (_q - 8) / 12
	var fase := (_q - 8) % 12
	if k >= VISTAS.size():
		return true
	var v: Dictionary = VISTAS[k]
	if fase == 0:
		_arrumar(v)
	elif fase == 11:
		var arquivo := ProjectSettings.globalize_path(PASTA + v.nome + ".png")
		root.get_texture().get_image().save_png(arquivo)
		print("foto: ", arquivo)
	return false


func _arrumar(v: Dictionary) -> void:
	_robo.visible = v.faisca
	_robo.posar("geral/Idle_A", 0.5)
	if _robo.has_method("expressao"):
		_robo.call("expressao", "normal", 0.0, true)
	if v.orto:
		_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		_cam.size = v.tamanho
	else:
		_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		_cam.fov = 36.0
	_cam.look_at_from_position(v.pos, v.alvo, Vector3.UP)


## Estúdio do tools/foto_faisca.gd, com fundo cinza-claro no lugar do lilás.
func _montar_estudio() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("eceaf2")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f0eeff")
	env.ambient_light_energy = 0.5
	env.tonemap_exposure = 0.95
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.ssao_radius = 0.5
	env.ssao_intensity = 1.5
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)

	var chave := DirectionalLight3D.new()
	chave.rotation_degrees = Vector3(-45, -30, 0)
	chave.light_energy = 1.0
	chave.shadow_enabled = true
	chave.light_angular_distance = 3.0
	root.add_child(chave)
	var preenche := DirectionalLight3D.new()
	preenche.rotation_degrees = Vector3(-20, 40, 0)
	preenche.light_energy = 0.35
	root.add_child(preenche)
	var recorte := DirectionalLight3D.new()
	recorte.rotation_degrees = Vector3(-30, 180, 0)
	recorte.light_energy = 0.6
	root.add_child(recorte)

	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(40, 40)
	chao.mesh = plano
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("bdb8cc")
	m.roughness = 1.0
	chao.material_override = m
	root.add_child(chao)
	# Chão de colisão: a Bolota tem gravidade.
	var piso := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = WorldBoundaryShape3D.new()
	piso.add_child(cs)
	root.add_child(piso)

	_cam = Camera3D.new()
	root.add_child(_cam)
	_cam.current = true
