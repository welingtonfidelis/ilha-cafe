extends SceneTree
## Folha para conferir as duas pistolas: o menino na pose de mira de duas pistolas (a de uma mão com o braço
## direito espelhado no esquerdo), a Paçoca na mão direita e a Jujuba na esquerda (encaixe de Player.left_grip),
## uma coluna por ângulo de câmera (frente, lado direito, lado esquerdo, de cima).
## Uso (precisa de janela): godot --path . -s res://tools/foto_duas_pistolas.gd

## Uma linha só: o encaixe do jogo (Player.left_grip).
const ROWS := [0]
const VIEWS := [Vector3(0, 0, 0), Vector3(0, 90, 0), Vector3(0, -90, 0), Vector3(90, 0, 0)]


func _init() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1400, 1000)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#cfe8ff")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.75, 0.8)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	world.add_child(sun)
	var right: Dictionary = Weapons.find("pacoca")
	var left: Dictionary = Weapons.find("jujuba")
	for row in ROWS.size():
		var pose_name := "Pose_Dual"
		var rig: Node3D = load(Player.CHARACTERS.menino).instantiate()
		AnimUtil.add_mirrored_pose("tiro", "Ranged_1H_Aiming", Player.AIM_POSE_1H, pose_name, rig.find_child("Skeleton3D", true, false))
		rig.free()
		for col in VIEWS.size():
			var n: Node3D = load(Player.CHARACTERS.menino).instantiate()
			n.position = Vector3((col - 1.5) * 2.0, -row * 2.6, 0)
			n.rotation_degrees = VIEWS[col]
			world.add_child(n)
			var ap := AnimUtil.make_player(n, ["tiro"])
			ap.play(StringName("tiro/" + pose_name))
			ap.seek(0.0, true)
			ap.pause()
			var sk: Skeleton3D = n.find_child("Skeleton3D", true, false)
			for spec in [["handslot.r", right, Weapons.ROTATION, 1.0], ["handslot.l", left, Vector3.ZERO, -1.0]]:
				var hand := BoneAttachment3D.new()
				hand.bone_name = spec[0]
				sk.add_child(hand)
				var def: Dictionary = spec[1]
				var holder := Node3D.new()
				if spec[3] > 0.0:
					holder.rotation_degrees = spec[2]
					holder.position = def.pos
				else:
					holder.transform = Player.left_grip(sk, def)
				hand.add_child(holder)
				holder.add_child(load(Weapons.MODEL_DIR % def.modelo).instantiate())
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.6 * ROWS.size()
	cam.position = Vector3(0, -2.6 * (ROWS.size() - 1) * 0.5 + 1.2, 12)
	world.add_child(cam)
	cam.current = true
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://tools/capturas/")
	DirAccess.make_dir_recursive_absolute(dir)
	vp.get_texture().get_image().save_png(dir + "duas_pistolas.png")
	print("ok")
	quit()
