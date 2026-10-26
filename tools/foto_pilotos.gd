extends SceneTree
## Folha de poses para o piloto dos carrinhos: o personagem só da cintura para cima (pernas e mochila
## escondidas) em algumas animações do KayKit paradas num instante, de frente e de lado.
## Uso (precisa de janela): godot --path . --resolution 1800x700 -s res://tools/foto_pilotos.gd

const CHAR := "res://assets/characters/protagonists/Protagonist_A.glb"
const POSES := [
	["festa/Sit_Chair_Idle", 0.5], ["tiro/Ranged_2H_Aiming", 0.8], ["ferramentas/Holding_A", 0.5],
	["ferramentas/Holding_C", 0.5], ["geral/Idle_A", 0.5], ["tiro/Ranged_1H_Aiming", 0.6],
]


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
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 30, 0)
	world.add_child(sun)
	for i in POSES.size():
		for view in 2:
			var holder := Node3D.new()
			holder.position = Vector3(i * 2.6 + view * 1.2, 0, 0)
			holder.rotation_degrees.y = 0.0 if view == 0 else 90.0
			world.add_child(holder)
			var m: Node3D = load(CHAR).instantiate()
			holder.add_child(m)
			for mi in m.find_children("*", "MeshInstance3D", true, false):
				var n := String(mi.name)
				(mi as Node3D).visible = not (n.contains("Leg") or n.contains("Backpack"))
			var ap := AnimUtil.make_player(m, ["geral", "festa", "ferramentas", "tiro"])
			ap.play(StringName(POSES[i][0]))
			ap.seek(POSES[i][1], true)
			ap.pause()
		var label := Label3D.new()
		label.text = "%d %s" % [i, String(POSES[i][0]).get_slice("/", 1)]
		label.font_size = 26
		label.pixel_size = 0.004
		label.position = Vector3(i * 2.6 + 0.6, -0.2, 0.6)
		world.add_child(label)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 5.0
	world.add_child(cam)
	await process_frame
	var mid := (POSES.size() - 1) * 2.6 * 0.5 + 0.6
	cam.look_at_from_position(Vector3(mid, 1.4, 10.0), Vector3(mid, 1.0, 0.0))
	cam.current = true
	for k in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://tools/capturas/pilotos_poses.png"))
	print("ok")
	quit()
