extends SceneTree
## Foto de cima das peças de rua e de alguns props em rotação 0, com setas de eixo,
## para descobrir para que lado cada peça aponta. Uso (precisa de janela):
## godot --path . -s res://tools/orientacao_pecas.gd

const CITY := "res://assets/env/city/%s.gltf"
const PIECES := ["road_straight", "road_tsplit", "road_corner", "road_junction", "road_corner_curved", "building_A", "building_B", "bench", "car_sedan", "streetlight"]


func _init() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-70, 20, 0)
	world.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.15, 0.16, 0.2)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.7)
	world.add_child(env)
	for i in PIECES.size():
		var n: Node3D = load(CITY % PIECES[i]).instantiate()
		n.position = Vector3((i % 5) * 3.0, 0, (i / 5) * 3.5)
		world.add_child(n)
		var label := Label3D.new()
		label.text = PIECES[i]
		label.font_size = 48
		label.pixel_size = 0.006
		label.rotation_degrees.x = -90
		label.position = n.position + Vector3(0, 0.5, 1.35)
		world.add_child(label)
	# Setas: vermelha = +X, azul = -Z (frente da Godot).
	for spec in [[Vector3(1, 0, 0), Color.RED], [Vector3(0, 0, -1), Color.BLUE]]:
		var arrow := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.2, 0.1, 0.12) if spec[0].x != 0 else Vector3(0.12, 0.1, 1.2)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = spec[1]
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		box.material = mat
		arrow.mesh = box
		arrow.position = Vector3(-2.2, 0.2, 0) + spec[0] * 0.6
		world.add_child(arrow)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 9.5
	cam.position = Vector3(5.5, 20, 2.2)
	cam.rotation_degrees.x = -90
	world.add_child(cam)
	cam.current = true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://tools/capturas/")
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_viewport().get_texture().get_image().save_png(dir + "orientacao_pecas.png")
	print("ok")
	quit()
