extends SceneTree
## Fotos da vegetação da ilha (pedido do usuário em 2026-11-11: "algo mais abundante de vegetação"): as mesmas vistas
## na altura do jogo, com as plantas e sem elas, e a contagem de plantas de cada tipo na tela.
## Uso (precisa de janela): godot --path . --resolution 1280x720 -s res://tools/foto_vegetacao.gd
## Saída: tools/capturas/vegetacao/<vista>_com.png e <vista>_sem.png

## [nome, ponto do chão (x, z), para onde olha (x, z), altura da câmera]
const VISTAS := [
	["campo", Vector2(30, 50), Vector2(1, 0), 3.2],
	["campo_morro", Vector2(-60, 20), Vector2(0, 1), 3.2],
	["campo_oeste", Vector2(-100, -40), Vector2(1, 0), 3.2],
	["mata", Vector2(-20, -150), Vector2(0, -1), 3.2],
	["mata_praia", Vector2(30, -200), Vector2(-1, 0), 3.2],
	["campo_de_cima", Vector2(20, 40), Vector2(0.6, 0.8), 9.0],
]

var _cam: Camera3D
var _veg: VegetacaoIlha


func _init() -> void:
	await process_frame
	var dir := ProjectSettings.globalize_path("res://tools/capturas/vegetacao/")
	DirAccess.make_dir_recursive_absolute(dir)
	var mundo := Node3D.new()
	root.add_child(mundo)
	var ilha: Node3D = load("res://scenes/ilha.tscn").instantiate()
	mundo.add_child(ilha)
	TexturaDoChao.na_ilha(ilha)
	_luz(mundo)
	_cam = Camera3D.new()
	_cam.far = 3000.0
	_cam.fov = 60.0
	mundo.add_child(_cam)
	_cam.current = true
	_veg = VegetacaoIlha.new()
	_veg.terreno = ilha.get_node("Terreno")
	mundo.add_child(_veg)
	var espaco := mundo.get_world_3d().direct_space_state
	for v in VISTAS:
		var xz: Vector2 = v[1]
		var r := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(xz.x, 200, xz.y), Vector3(xz.x, -50, xz.y)))
		var chao: Vector3 = r.position if not r.is_empty() else Vector3(xz.x, 0, xz.y)
		var para := Vector3(v[2].x, 0, v[2].y).normalized()
		_cam.global_position = chao + Vector3.UP * float(v[3]) - para * 5.0
		_cam.look_at(chao + para * 8.0)
		for k in 3:
			await physics_frame
		while not _veg.pronta():
			await physics_frame
		_veg.show()
		var com := await _tempo_gpu()
		await _foto(dir + v[0] + "_com.png")
		_veg.hide()
		var sem := await _tempo_gpu()
		await _foto(dir + v[0] + "_sem.png")
		_veg.show()
		print("%s: %s | quadro %.2f ms com, %.2f ms sem" % [v[0], _veg.plantas, com, sem])
	quit()


## A mesma luz da ilha no jogo (main.gd, _build_environment), de dia.
func _luz(mundo: Node3D) -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#4f9cf0")
	sky_mat.sky_horizon_color = Color("#cfe8ff")
	sky_mat.ground_horizon_color = Color("#cfe8ff")
	sky_mat.ground_bottom_color = Color("#3f9fd8")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	env.fog_enabled = true
	env.fog_light_color = Color("#cfe8ff")
	env.fog_density = 0.0016
	env.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = env
	mundo.add_child(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, -35, 0)
	sol.light_color = Color("#fff4e0")
	sol.light_energy = 1.2
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 110.0
	mundo.add_child(sol)


## Tempo médio de um quadro inteiro, sem esperar a tela (vsync desligado), em 60 quadros: a placa do Mac não mede
## só a parte dela.
func _tempo_gpu() -> float:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	for i in 10:
		await process_frame
	var comeco := Time.get_ticks_usec()
	for i in 60:
		await process_frame
	return (Time.get_ticks_usec() - comeco) / 60.0 / 1000.0


func _foto(caminho: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(caminho)
	print("foto: ", caminho.get_file())
