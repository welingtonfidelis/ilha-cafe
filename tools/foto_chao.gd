extends SceneTree
## Fotos de antes e depois da textura no chão (item 13 da lista do Faísca): a mesma vista com o desenho e sem ele
## (a força do shader em 0), na ilha e em cada fase do Faísca, de perto e de meia distância.
## Uso (precisa de janela): godot --path . --resolution 1280x720 -s res://tools/foto_chao.gd [-- ilha 1-1 ...]
## Saída: tools/capturas/chao/<vista>_com.png e <vista>_sem.png

const FASES := ["1-1", "1-2", "2-1", "2-2", "2-3", "3-1", "3-2"]
## Vistas da ilha: [nome, posição da câmera, para onde olha].
const ILHA := [
	["ilha_campo", Vector3(-6, 6, 160), Vector3(-14, 0, 140)],
	["ilha_praca", Vector3(4, 7, 112), Vector3(14, 0, 95)],
	["ilha_trilha", Vector3(60, 34, 20), Vector3(40, 26, 10)],
	["ilha_praia", Vector3(150, 6, 60), Vector3(168, 0, 40)],
	["ilha_mata", Vector3(-30, 8, -130), Vector3(-40, 2, -150)],
]

var _cam: Camera3D
var _dir := ""


func _init() -> void:
	await process_frame
	var pedidos := Array(OS.get_cmdline_user_args())
	_dir = ProjectSettings.globalize_path("res://tools/capturas/chao/")
	DirAccess.make_dir_recursive_absolute(_dir)
	_cam = Camera3D.new()
	_cam.far = 3000.0
	_cam.fov = 60.0
	root.add_child(_cam)
	_cam.current = true
	if pedidos.is_empty() or "ilha" in pedidos:
		await _ilha()
	for id in FASES:
		if pedidos.is_empty() or id in pedidos:
			await _fase(id)
	quit()


func _ilha() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	var ilha: Node3D = load("res://scenes/ilha.tscn").instantiate()
	mundo.add_child(ilha)
	TexturaDoChao.na_ilha(ilha)
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#4f9cf0")
	sky_mat.sky_horizon_color = Color("#cfe8ff")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	# A mesma luz da ilha no jogo (main.gd, _build_environment), de dia.
	sky_mat.ground_horizon_color = Color("#cfe8ff")
	sky_mat.ground_bottom_color = Color("#3f9fd8")
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
	# Do jeito que se joga: a câmera atrás do começo, a uns 4 m do chão.
	var inicio := (ilha.get_node("Marcadores/Inicio") as Node3D).global_position
	_cam.global_position = inicio + Vector3(0, 3.6, 7.0)
	_cam.look_at(inicio + Vector3(0, 0.5, -8.0))
	await _par("ilha_inicio")
	# A grama do morro e a da mata, na altura do jogo (o chão achado por raio).
	for spec in [["ilha_grama", Vector2(30, 50), Vector2(1, 0)], ["ilha_campo_perto", Vector2(-60, 20), Vector2(0, 1)],
			["ilha_campo_oeste", Vector2(-100, -40), Vector2(1, 0)], ["ilha_mata_chao", Vector2(-20, -150), Vector2(0, -1)],
			["ilha_mata_funda", Vector2(30, -200), Vector2(-1, 0)]]:
		var xz: Vector2 = spec[1]
		var r := mundo.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
				Vector3(xz.x, 200, xz.y), Vector3(xz.x, -50, xz.y)))
		var chao: Vector3 = r.position if not r.is_empty() else Vector3(xz.x, 0, xz.y)
		var para := Vector3(spec[2].x, 0, spec[2].y)
		_cam.global_position = chao + Vector3.UP * 3.6 - para * 5.0
		_cam.look_at(chao + para * 8.0)
		await _par(spec[0])
	for v in ILHA:
		_cam.global_position = v[1]
		_cam.look_at(v[2])
		await _par(v[0])
	mundo.queue_free()
	await process_frame


func _fase(id: String) -> void:
	var n := TesteFaisquinhas.nova_fase(id)
	n.name = "Fase"
	root.add_child(n)
	for k in 3:
		await physics_frame
	print("%s: %d peças com textura" % [id, n.pecas_com_textura])
	# Perto: da entrada do primeiro playground olhando o chão na frente; meia distância: de cima, para o centro.
	var pg: Dictionary = n.playgrounds[0]
	var entrada: Vector3 = pg.entrada
	var centro: Vector3 = pg.centro
	var para := (centro - entrada)
	para.y = 0.0
	para = para.normalized() if para.length() > 0.1 else Vector3.FORWARD
	_cam.global_position = entrada + Vector3.UP * 2.6 - para * 1.5
	_cam.look_at(entrada + para * 6.0)
	await _par(id + "_perto")
	_cam.global_position = entrada + Vector3.UP * 9.0 - para * 4.0
	_cam.look_at(centro)
	await _par(id + "_meio")
	n.queue_free()
	await process_frame


## A foto com o desenho e a mesma sem ele.
func _par(nome: String) -> void:
	_forca(1.0)
	await _foto(nome + "_com")
	_forca(0.0)
	await _foto(nome + "_sem")
	_forca(1.0)


func _forca(f: float) -> void:
	for m in TexturaDoChao._materiais.values():
		(m as ShaderMaterial).set_shader_parameter("forca", f)


func _foto(nome: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(_dir + nome + ".png")
	print("foto: ", nome)
