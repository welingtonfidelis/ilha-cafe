extends SceneTree
## Folha para escolher o que os inimigos seguram no lugar das armas cortantes (pedido do usuário em
## 2026-10-28: o tema deve ser mais infantil): as armas antigas na primeira linha e os brinquedos escolhidos
## na segunda (os outros candidatos, rolo de massa, colher, taco, pino de malabares e cachorro de balão, não
## ficaram no projeto), todos em pé, na mesma escala, com o tamanho impresso no terminal.
## Uso (precisa de janela): godot --path . -s res://tools/folha_brinquedos.gd

const ROWS := [
	["res://assets/weapons/inimigos/Vampire_Sword.gltf", "res://assets/weapons/inimigos/Monstrosity_Pitchfork_Large.gltf",
		"res://assets/weapons/inimigos/FrostGolem_Axe_Large.gltf", "res://assets/weapons/skeleton/Skeleton_Axe.gltf",
		"res://assets/weapons/planta/PlantWarrior_Spear.gltf"],
	["res://assets/weapons/brinquedos/candycane_large.gltf", "res://assets/weapons/brinquedos/clown_hammer.gltf",
		"res://assets/weapons/brinquedos/mallet.gltf", "res://assets/weapons/brinquedos/Hammer.gltf"],
]


func _init() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1800, 900)
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
		for col in ROWS[row].size():
			var path: String = ROWS[row][col]
			var n: Node3D = load(path).instantiate()
			n.position = Vector3((col - 4.5) * 0.9, -row * 1.6, 0)
			world.add_child(n)
			var box := _aabb(n, Transform3D.IDENTITY)
			print("%s  tamanho %s  base %s" % [path.get_file(), box.size, box.position])
			var label := Label3D.new()
			label.text = path.get_file().get_basename()
			label.font_size = 28
			label.pixel_size = 0.004
			label.modulate = Color.BLACK
			label.outline_size = 0
			label.position = n.position + Vector3(0, -0.2, 0.2)
			world.add_child(label)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 3.6
	cam.position = Vector3(0, -0.2, 10)
	world.add_child(cam)
	cam.current = true
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://tools/capturas/")
	DirAccess.make_dir_recursive_absolute(dir)
	vp.get_texture().get_image().save_png(dir + "brinquedos_candidatos.png")
	print("ok")
	quit()


func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t: Transform3D = xf * ((n as Node3D).transform if n is Node3D else Transform3D.IDENTITY)
	if n is MeshInstance3D:
		out = t * (n as MeshInstance3D).mesh.get_aabb()
		first = false
	for c in n.get_children():
		var b := _aabb(c, t)
		if b.size != Vector3.ZERO:
			out = b if first else out.merge(b)
			first = false
	return out
