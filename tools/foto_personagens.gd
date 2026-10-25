extends SceneTree
## Foto dos aventureiros lado a lado: em cima como vêm do KayKit, embaixo sem capacete,
## capa, chapéu e aljava. Uso (precisa de janela): godot --path . -s res://tools/foto_personagens.gd

const CHARS := ["Knight", "Barbarian", "Mage", "Ranger", "Rogue", "Rogue_Hooded"]
const MANNEQUIN := "res://vendor_copy/Mannequin_Medium.glb"
const STRIP := ["Helmet", "Visor", "Cape", "Hat", "BearHat", "Quiver", "Mask"]


func _init() -> void:
	var world := Node3D.new()
	root.add_child(world)
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
	for row in 2:
		for i in CHARS.size():
			var n: Node3D = load("res://assets/characters/adventurers/%s.glb" % CHARS[i]).instantiate()
			n.position = Vector3((i - 2.5) * 2.3, row * -2.9, 0)
			world.add_child(n)
			var ap := AnimUtil.make_player(n, ["geral"])
			ap.play(&"geral/Idle_A")
			if row == 1:
				for mi in n.find_children("*", "MeshInstance3D", true, false):
					for s in STRIP:
						if s in mi.name:
							mi.visible = false
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 6.4
	cam.position = Vector3(0, -0.35, 12)
	world.add_child(cam)
	cam.current = true
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://tools/capturas/")
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_viewport().get_texture().get_image().save_png(dir + "personagens.png")
	print("ok")
	quit()
