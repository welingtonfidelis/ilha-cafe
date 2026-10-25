extends SceneTree
## Gera as silhuetas brancas dos blasters e da granada para o painel de armas:
## assets/ui/icones/<id>.png (fundo transparente, cano apontando para a esquerda).
## Uso (precisa de janela): godot --path . -s res://tools/gerar_icones.gd

const OUT := "res://assets/ui/icones/"
const SIZE := Vector2i(640, 256)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	vp.add_child(env)
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.albedo_color = Color.WHITE
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	vp.add_child(cam)
	cam.current = true
	# Alguns quadros para a SubViewport ficar pronta antes da primeira foto.
	for k in 6:
		await process_frame
	var items := []
	for def in Weapons.DEFS:
		items.append([def.id, def.modelo])
	items.append(["granada", Weapons.GRENADE.modelo])
	for item in items:
		var model: Node3D = load(Weapons.MODEL_DIR % item[1]).instantiate()
		vp.add_child(model)
		var aabb := AABB()
		var first := true
		for mi in model.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = white
			var a: AABB = (mi as MeshInstance3D).get_aabb()
			if mi.get_parent() != model:
				a = (mi.get_parent() as Node3D).transform * a
			aabb = a if first else aabb.merge(a)
			first = false
		var center := aabb.get_center()
		# Câmera do lado -X olhando para +X: o cano (ponta -Z) fica à esquerda.
		cam.position = center + Vector3(-5, 0, 0)
		cam.look_at(center)
		cam.size = maxf(aabb.size.z * SIZE.y / SIZE.x, aabb.size.y) * 1.1
		for k in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img = img.get_region(img.get_used_rect())
		img.save_png(ProjectSettings.globalize_path(OUT + item[0] + ".png"))
		print("ícone: ", item[0], " ", img.get_size())
		model.free()
	quit()
