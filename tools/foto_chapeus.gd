extends SceneTree
## Fotos de conferência dos chapéus da lojinha (Roupas.CHAPEUS) no menino e na menina: tools/capturas/chapeus_*.png
## Uso (precisa de janela): godot --path . -s res://tools/foto_chapeus.gd

const SIZE := Vector2i(300, 300)


func _init() -> void:
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#8fd0ff")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.9, 0.9, 1.0)
	env.environment.ambient_light_energy = 0.8
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	vp.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 30.0
	vp.add_child(cam)
	cam.current = true
	for k in 4:
		await process_frame
	var dir := ProjectSettings.globalize_path("res://tools/capturas/")
	for quem in ["menino", "menina"]:
		for spec: Dictionary in Roupas.CHAPEUS:
			var modelo: Node3D = load(Player.CHARACTERS[quem]).instantiate()
			vp.add_child(modelo)
			var ap := AnimUtil.make_player(modelo, ["geral"])
			ap.play(&"geral/Idle_A")
			ap.seek(0.3, true)
			var sk: Skeleton3D = modelo.find_child("Skeleton3D", true, false)
			var osso := BoneAttachment3D.new()
			osso.bone_name = "head"
			sk.add_child(osso)
			var c := Roupas.chapeu(spec.id)
			if c:
				osso.add_child(c)
			await process_frame
			await process_frame
			var cabeca := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("head"))
			var alvo := cabeca.origin + Vector3.UP * 0.55
			cam.look_at_from_position(alvo + Vector3(0.9, 0.35, 2.6), alvo)
			for k in 3:
				await process_frame
			await RenderingServer.frame_post_draw
			vp.get_texture().get_image().save_png(dir + "chapeus_%s_%s.png" % [quem, spec.id])
			print("chapéu: ", quem, " ", spec.id, " ", "ok" if c else "SEM MALHA")
			modelo.free()
	quit()
