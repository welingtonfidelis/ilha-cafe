extends SceneTree
## Fotos da ilha gerada, de cima e de alguns pontos, para conferir o mapa sem abrir o editor.
## Uso (precisa de janela): godot --path . -s res://tools/foto_ilha.gd
## Saída: tools/capturas/ilha_*.png

const SHOTS := [
	["ilha_cima", "orto", Vector3(0, 300, 0), Vector3(-90, 0, 0), 560.0],
	["ilha_cidade", "persp", Vector3(30, 22, 230), Vector3(-18, 8, 0), 60.0],
	["ilha_praca", "persp", Vector3(-14, 8, 196), Vector3(-14, -20, 0), 65.0],
	["ilha_morro", "persp", Vector3(70, 30, 110), Vector3(-12, 30, 0), 60.0],
	["ilha_topo", "persp", Vector3(16, MORRO_TOP, 30), Vector3(-12, 15, 0), 65.0],
	["ilha_ponte", "persp", Vector3(22, 9, -80), Vector3(-12, 150, 0), 65.0],
	["ilha_mata", "persp", Vector3(-20, 30, -110), Vector3(-20, 200, 0), 65.0],
]
const MORRO_TOP := 34.0


func _init() -> void:
	var world := Node3D.new()
	root.add_child(world)
	world.add_child(load("res://scenes/ilha.tscn").instantiate())
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
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 250.0
	world.add_child(sun)
	var cam := Camera3D.new()
	cam.far = 3000.0
	world.add_child(cam)
	cam.current = true
	var dir := ProjectSettings.globalize_path("res://tools/capturas/")
	DirAccess.make_dir_recursive_absolute(dir)
	for shot in SHOTS:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL if shot[1] == "orto" else Camera3D.PROJECTION_PERSPECTIVE
		cam.position = shot[2]
		cam.rotation_degrees = shot[3]
		if shot[1] == "orto":
			cam.size = shot[4]
		else:
			cam.fov = shot[4]
		for i in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_viewport().get_texture().get_image().save_png(dir + shot[0] + ".png")
		print("foto: ", shot[0])
	quit()
