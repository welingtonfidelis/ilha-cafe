extends SceneTree
## Folha para acertar o celular da lojinha na mão: o menino na pose de segurar o celular, uma linha por
## pose e rotação do celular no osso handslot.r e uma coluna por ângulo de câmera (frente, três quartos, lado).
## Uso (precisa de janela): godot --path . -s res://tools/foto_celular.gd

## Cada linha: animação ("biblioteca/nome"), instante e rotação do celular (a última, a do jogo).
const ROWS := [["ferramentas/Holding_B", 0.5, Vector3(-18.0, -34.8, -71.3)], ["ferramentas/Holding_B", 1.2, Vector3(-18.0, -34.8, -71.3)]]
const VIEWS := [0.0, 40.0, 90.0]


func _init() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(900, 1500)
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
	for row in ROWS.size():
		for col in VIEWS.size():
			var n: Node3D = load(Player.CHARACTERS.menino).instantiate()
			n.position = Vector3((col - 1) * 1.6, -row * 2.6 * 0.62, 0)
			n.rotation_degrees.y = VIEWS[col]
			world.add_child(n)
			var ap := AnimUtil.make_player(n, ["ferramentas", "geral"])
			ap.play(StringName(ROWS[row][0]))
			ap.seek(ROWS[row][1], true)
			ap.pause()
			var sk: Skeleton3D = n.find_child("Skeleton3D", true, false)
			var hand := BoneAttachment3D.new()
			hand.bone_name = "handslot.r"
			sk.add_child(hand)
			var phone := Player.phone_model()
			phone.rotation_degrees = ROWS[row][2]
			phone.position = Player.PHONE_OFFSET
			hand.add_child(phone)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.6 * ROWS.size() * 0.62
	cam.position = Vector3(0, -2.6 * 0.62 * (ROWS.size() - 1) * 0.5 + 1.0, 12)
	world.add_child(cam)
	cam.current = true
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://tools/capturas/")
	DirAccess.make_dir_recursive_absolute(dir)
	vp.get_texture().get_image().save_png(dir + "celular_na_mao.png")
	print("ok")
	quit()
