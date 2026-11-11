extends SceneTree
## Miniaturas dos chapéus da lojinha (Roupas.CHAPEUS): cada chapéu sozinho, de três quartos, com fundo
## transparente, em assets/ui/roupas/<id>.png. Uso (precisa de janela): godot --path . -s res://tools/gerar_roupas.gd

const OUT := "res://assets/ui/roupas/"
const SIZE := Vector2i(256, 256)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.9, 0.9, 1.0)
	env.environment.ambient_light_energy = 0.85
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 35, 0)
	vp.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 28.0
	vp.add_child(cam)
	cam.current = true
	for k in 4:
		await process_frame
	for spec: Dictionary in Roupas.CHAPEUS:
		var c := Roupas.chapeu(spec.id)
		vp.add_child(c)
		await process_frame
		var caixa := AABB()
		var primeiro := true
		for m: MeshInstance3D in c.find_children("*", "MeshInstance3D", true, false):
			var a: AABB = m.global_transform * m.get_aabb()
			caixa = a if primeiro else caixa.merge(a)
			primeiro = false
		var meio := caixa.get_center()
		var maior := maxf(caixa.size.x, maxf(caixa.size.y, caixa.size.z))
		var longe := maior * 0.5 / tan(deg_to_rad(cam.fov) * 0.5) * 1.25
		cam.look_at_from_position(meio + Vector3(0.45, 0.4, 1.0).normalized() * longe, meio)
		for k in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + spec.id + ".png"))
		print("roupa: ", spec.id)
		c.free()
	quit()
