extends SceneTree
## Uma foto de cada monstro de assets/faisca/monstros/ ao lado do Faísca, para escolher quais entram no jogo
## (pedido do usuário em 2026-10-30). Cada um é uma `BolotaMonstro` parada, com a luz e o brilho do jogo.
## Precisa de janela (não roda com --headless):
##   godot --path . -s tools/foto_monstros.gd
## Salva em tools/capturas/faisca/monstros/<Nome>.png.

const ORIGEM := "res://assets/faisca/monstros/"
const PASTA := "res://tools/capturas/faisca/monstros/"
const TAMANHO := Vector2i(640, 640)
## Quadros para cada foto (o primeiro troca o monstro, o último fotografa).
const QUADROS := 24

var _modelos: Array[String] = []
var _monstro: BolotaMonstro
var _robo: Robo
var _cam: Camera3D
var _q := 0


func _initialize() -> void:
	DisplayServer.window_set_size(TAMANHO)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PASTA))
	for arquivo in DirAccess.get_files_at(ORIGEM):
		if arquivo.ends_with(".gltf"):
			_modelos.append(ORIGEM + arquivo)
	_montar_estudio()
	_robo = Robo.new()
	_robo.position = Vector3(-1.5, 0, -0.3)
	root.add_child(_robo)
	_robo.set("rosto_parado", true)


func _process(_delta: float) -> bool:
	_q += 1
	if _q < 8:
		return false
	var k := (_q - 8) / QUADROS
	var quadro := (_q - 8) % QUADROS
	if k >= _modelos.size():
		return true
	if quadro == 0:
		_trocar(_modelos[k])
	elif quadro == QUADROS - 1:
		var arquivo := ProjectSettings.globalize_path(PASTA + _modelos[k].get_file().get_basename() + ".png")
		root.get_texture().get_image().save_png(arquivo)
		print("foto: ", arquivo)
	return false


func _trocar(modelo: String) -> void:
	if _monstro:
		_monstro.queue_free()
	_monstro = BolotaMonstro.new(modelo)
	root.add_child(_monstro)
	_robo.posar("geral/Idle_A", 0.5)
	if _robo.has_method("expressao"):
		_robo.call("expressao", "normal", 0.0, true)
	_cam.look_at_from_position(Vector3(1.4, 1.9, 5.2), Vector3(-0.55, 0.85, 0), Vector3.UP)


## Estúdio do tools/foto_bolota.gd.
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
	# Chão de colisão: o monstro tem gravidade.
	var piso := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = WorldBoundaryShape3D.new()
	piso.add_child(cs)
	root.add_child(piso)

	_cam = Camera3D.new()
	_cam.fov = 36.0
	root.add_child(_cam)
	_cam.current = true
