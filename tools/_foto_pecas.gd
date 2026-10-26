extends SceneTree
## Peças de pista e de skate vistas de cima, com seta vermelha para +Z e azul para +X.
func _init() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.16, 0.17, 0.21)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.9, 0.9, 0.95)
	world.add_child(env)
	var items := ["pista/road-straight-barrier", "pista/road-bend-barrier", "pista/road-curve-barrier", "pista/road-end-barrier", "skate/half-pipe", "skate/ramp", "skate/bowl-side", "skate/bowl-corner-outer", "skate/slope-smooth", "skate/steps-rail", "skate/structure-platform", "skate/obstacle-box-grind"]
	for i in items.size():
		var m: Node3D = load("res://assets/%s.glb" % items[i]).instantiate()
		m.position = Vector3((i % 4) * 3.0, 0, (i / 4) * 3.0)
		world.add_child(m)
		for axis in [[Vector3(0, 0.3, 0.6), Vector3(0.05, 0.05, 1.2), Color.RED], [Vector3(0.6, 0.3, 0), Vector3(1.2, 0.05, 0.05), Color.DODGER_BLUE]]:
			var b := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = axis[1]
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = axis[2]
			bm.material = mat
			b.mesh = bm
			b.position = m.position + axis[0]
			world.add_child(b)
		var l := Label3D.new()
		l.text = items[i].get_file()
		l.font_size = 40
		l.pixel_size = 0.006
		l.rotation_degrees.x = -90
		l.position = m.position + Vector3(0, 0.5, 1.1)
		world.add_child(l)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 10.0
	world.add_child(cam)
	await process_frame
	cam.look_at_from_position(Vector3(4.5, 20, 3.0), Vector3(4.5, 0, 3.0), Vector3(0, 0, -1))
	cam.current = true
	for k in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tools/capturas/pecas_de_cima.png"))
	print("ok")
	quit()
