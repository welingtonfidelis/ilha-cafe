extends SceneTree
## Gera as miniaturas coloridas da Lojinha de Blasters: cada blaster (e a granada e o coração das melhorias)
## em três quartos, com luz, fundo transparente, em assets/ui/loja/<id>.png. O cano aponta para a direita.
## Uso (precisa de janela): godot --path . -s res://tools/gerar_miniaturas.gd

const OUT := "res://assets/ui/loja/"
const SIZE := Vector2i(480, 300)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.85, 0.85, 0.95)
	env.environment.ambient_light_energy = 0.9
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -30, 0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	vp.add_child(cam)
	cam.current = true
	for k in 6:
		await process_frame
	var items := []
	for def in Weapons.all():
		items.append([def.id, Weapons.MODEL_DIR % def.modelo])
	items.append(["granada_extra", Weapons.MODEL_DIR % Weapons.GRENADE.modelo])
	items.append(["coracao_extra", ""])
	for item in items:
		var model: Node3D
		if item[1] == "":
			var mi := MeshInstance3D.new()
			mi.mesh = Fx.heart_mesh(0.6, 0.3)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color("#ff5d7a")
			mi.material_override = mat
			model = Node3D.new()
			model.add_child(mi)
		else:
			model = load(item[1]).instantiate()
		# Três quartos: gira para o cano ir para a esquerda e um pouco para o fundo, e inclina de leve.
		var holder := Node3D.new()
		holder.rotation_degrees = Vector3(12, -62, 0) if item[1] != "" else Vector3(0, 0, 0)
		vp.add_child(holder)
		holder.add_child(model)
		await process_frame
		var box := AABB()
		var first := true
		for m in model.find_children("*", "MeshInstance3D", true, false):
			var a: AABB = (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
			box = a if first else box.merge(a)
			first = false
		if model is MeshInstance3D:
			box = (model as MeshInstance3D).global_transform * (model as MeshInstance3D).get_aabb()
		var center := box.get_center()
		cam.position = center + Vector3(0, 0, 6)
		cam.look_at(center)
		cam.size = maxf(box.size.x * SIZE.y / SIZE.x, box.size.y) * 1.15
		for k in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path(OUT + item[0] + ".png"))
		print("miniatura: ", item[0])
		holder.free()
	quit()
