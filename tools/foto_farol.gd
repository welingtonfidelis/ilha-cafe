extends SceneTree
## Foto do farol (scripts/faisca/farol_modelo.gd) apagado e aceso, de dia e de noite, para conferir sem
## abrir o jogo. Uso: godot --path . -s tools/foto_farol.gd (precisa de janela); sai em
## tools/capturas/farol.png.

var _quadros := 0


func _initialize() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var ceu := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = Color("#1b2a63")
	mat.sky_horizon_color = Color("#4b4f96")
	mat.ground_horizon_color = Color("#4b4f96")
	mat.ground_bottom_color = Color("#0c1a40")
	ceu.sky_material = mat
	env.sky = ceu
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	we.environment = env
	root.add_child.call_deferred(we)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, -35, 0)
	sol.light_energy = 0.5
	root.add_child.call_deferred(sol)
	for k in 2:
		var f := FarolModelo.new()
		f.escala = 4.5
		f.aceso = k == 1
		f.position = Vector3(-7.0 + 14.0 * k, 0, 0)
		root.add_child.call_deferred(f)
	var cam := Camera3D.new()
	cam.fov = 45
	root.add_child.call_deferred(cam)
	cam.set_deferred("position", Vector3(0, 11, 34))


func _process(_delta: float) -> bool:
	_quadros += 1
	if _quadros == 3:
		var cam := root.get_viewport().get_camera_3d()
		cam.look_at(Vector3(0, 9, 0))
	if _quadros == 30:
		root.get_viewport().get_texture().get_image().save_png("res://tools/capturas/farol.png")
		print("foto: tools/capturas/farol.png")
		return true
	return false
