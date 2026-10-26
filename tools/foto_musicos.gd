extends SceneTree
## Folha de poses para os músicos da banda: cada variante é um modelo numa animação do KayKit (parada
## num instante), com o instrumento preso a um osso numa posição e giro, vista de frente e de lado.
## Uso (precisa de janela): godot --path . --resolution 1800x720 -s res://tools/foto_musicos.gd

const SOLDIER := "res://assets/characters/moradores/ToySoldier.glb"
const BEAR := "res://assets/characters/moradores/Animatronic_Normal.glb"
const TRUMPET := "res://assets/props/moradores/ToySoldier_Trumpet.gltf"
const GUITAR := "res://assets/props/moradores/urso/Guitar.gltf"
## [modelo, animação, instante, instrumento, osso, posição, giro (graus)]
const VARIANTS := [
	[SOLDIER, "tiro/Ranged_2H_Aiming", 0.8, TRUMPET, "head", Vector3(0, 0.05, 0.32), Vector3(0, 0, 0)],
	[SOLDIER, "tiro/Ranged_2H_Aiming", 0.8, TRUMPET, "head", Vector3(0, 0.05, 0.32), Vector3(0, 180, 0)],
	[BEAR, "ferramentas/Holding_C", 0.5, GUITAR, "chest", Vector3(0.25, -0.15, -0.3), Vector3(0, 0, -55)],
	[BEAR, "ferramentas/Holding_C", 0.5, GUITAR, "chest", Vector3(-0.25, -0.15, -0.3), Vector3(0, 0, -55)],
	[BEAR, "ferramentas/Holding_C", 0.5, GUITAR, "chest", Vector3(-0.25, -0.15, -0.3), Vector3(0, 0, 55)],
]


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
	sun.rotation_degrees = Vector3(-30, 30, 0)
	world.add_child(sun)
	for i in VARIANTS.size():
		var v: Array = VARIANTS[i]
		for view in 2:
			var holder := Node3D.new()
			holder.position = Vector3(i * 3.2 + view * 1.5, 0, 0)
			holder.rotation_degrees.y = 0.0 if view == 0 else 90.0
			world.add_child(holder)
			var model: Node3D = load(v[0]).instantiate()
			holder.add_child(model)
			var ap := AnimUtil.make_player(model, ["geral", "festa", "ferramentas", "tiro", "luta"])
			var sk: Skeleton3D = model.find_child("Skeleton3D", true, false)
			var bone := BoneAttachment3D.new()
			bone.bone_name = v[4]
			sk.add_child(bone)
			var prop: Node3D = load(v[3]).instantiate()
			prop.position = v[5]
			prop.rotation_degrees = v[6]
			bone.add_child(prop)
			ap.play(StringName(v[1]))
			ap.seek(v[2], true)
			ap.pause()
		var label := Label3D.new()
		label.text = "%d %s %s %s" % [i, v[4], v[5], v[6]]
		label.font_size = 22
		label.pixel_size = 0.004
		label.position = Vector3(i * 3.2 + 0.75, -0.25, 0.6)
		world.add_child(label)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 6.4
	world.add_child(cam)
	await process_frame
	var mid := (VARIANTS.size() - 1) * 3.2 * 0.5 + 0.75
	cam.look_at_from_position(Vector3(mid, 1.6, 10.0), Vector3(mid, 1.0, 0.0))
	cam.current = true
	for k in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://tools/capturas/")
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_viewport().get_texture().get_image().save_png(dir + "musicos_poses.png")
	print("ok")
	quit()
