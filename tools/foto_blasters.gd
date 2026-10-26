extends SceneTree
## Os blasters de lado, já virados como o jogo segura (todos com o cano para a esquerda), com uma
## esfera amarela no ponto "boca" e uma azul no cabo (onde a mão fica). A seta vermelha aponta a frente.
## Uso (precisa de janela): godot --path . -s res://tools/foto_blasters.gd


func _init() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.16, 0.17, 0.21)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.85)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, -60, 0)
	world.add_child(sun)
	var defs := Weapons.all()
	for i in defs.size():
		var def: Dictionary = defs[i]
		var holder := Node3D.new()
		holder.position = Vector3(0, -i * 0.75 + 1.1, 0)
		world.add_child(holder)
		# Gira como no jogo, menos os 90° do osso: a frente da arma fica para a esquerda da foto.
		var flip := Node3D.new()
		flip.rotation_degrees = Weapons.ROTATION - Vector3(0, 90, 0)
		holder.add_child(flip)
		flip.add_child(load(Weapons.MODEL_DIR % def.modelo).instantiate())
		# Cabo: inverso do pos (pos = -(rot · cabo) · escala), desfazendo a rotação base de 90°.
		var grip := MeshInstance3D.new()
		var gs := SphereMesh.new()
		gs.radius = 0.04
		gs.height = 0.08
		gs.material = Fx.flat_material(Color.DODGER_BLUE)
		grip.mesh = gs
		var base := Basis.from_euler(Weapons.ROTATION * PI / 180.0)
		grip.position = base.inverse() * (-(def.pos as Vector3) / float(def.escala))
		flip.add_child(grip)
		var arrow := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.03, 0.03, 0.5)
		box.material = Fx.flat_material(Color.RED)
		arrow.mesh = box
		arrow.position = Vector3(0, 0.3, 0.25)
		holder.add_child(arrow)
		var tip := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.04
		sphere.height = 0.08
		sphere.material = Fx.flat_material(Color.YELLOW)
		tip.mesh = sphere
		tip.position = def.boca
		flip.add_child(tip)
		var label := Label3D.new()
		label.text = "%s (%s)" % [def.nome, def.modelo]
		label.font_size = 40
		label.pixel_size = 0.004
		label.position = Vector3(0, 0.3, -0.9)
		label.rotation_degrees.y = 90
		holder.add_child(label)
	# Câmera olhando de lado (de +X para -X): +Z aparece à esquerda.
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = defs.size() * 0.78
	cam.position = Vector3(5, 1.1 - (defs.size() - 1) * 0.375, 0.1)
	cam.rotation_degrees.y = 90
	world.add_child(cam)
	cam.current = true
	for k in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://tools/capturas/")
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_viewport().get_texture().get_image().save_png(dir + "blasters_lado.png")
	print("ok")
	quit()
