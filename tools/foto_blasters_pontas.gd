extends SceneTree
## Cada blaster visto pelas duas pontas: em cima olhando para a ponta +Z, embaixo para a ponta -Z.
## A ponta com o buraco do cano é a frente. Uso (precisa de janela):
## godot --path . -s res://tools/foto_blasters_pontas.gd


func _init() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.16, 0.17, 0.21)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.85, 0.85, 0.9)
	world.add_child(env)
	var models := ["blaster-a", "blaster-j", "blaster-l", "blaster-e"]
	var dir := ProjectSettings.globalize_path("res://tools/capturas/")
	DirAccess.make_dir_recursive_absolute(dir)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 0.7
	world.add_child(cam)
	cam.current = true
	var light := OmniLight3D.new()
	light.omni_range = 10.0
	world.add_child(light)
	for side in [1.0, -1.0]:
		for i in models.size():
			var n: Node3D = load("res://assets/weapons/%s.glb" % models[i]).instantiate()
			world.add_child(n)
			var aabb := AABB()
			var first := true
			for mi in n.find_children("*", "MeshInstance3D", true, false):
				var a: AABB = (mi as MeshInstance3D).get_aabb()
				aabb = a if first else aabb.merge(a)
				first = false
			var center := aabb.get_center()
			cam.position = Vector3(center.x, center.y, center.z + side * 3.0)
			cam.look_at(center)
			light.position = cam.position
			for k in 3:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_viewport().get_texture().get_image().save_png(dir + "ponta_%s_%s.png" % [models[i], "maisZ" if side > 0 else "menosZ"])
			n.free()
	print("ok")
	quit()
